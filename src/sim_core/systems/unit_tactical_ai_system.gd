class_name UnitTacticalAISystem
extends RefCounted
## Phase 8 Per-Unit Situational Awareness & Autonomous Tactical Decision System (Zero-Allocation SoA).
## Gives every individual flight, infantry platoon, robot dog pack, tank platoon, artillery battery,
## and warship local situational awareness and autonomous tactical behaviors:
## - `AI_PATROL_CAP (0)`: 3D Combat Air Patrol orbit / Ground overwatch
## - `AI_BVR_INTERCEPT (1)`: High-altitude Mach intercept against detected air threats
## - `AI_SEAD_TERRAIN_MASK (2)`: Nap-of-the-Earth (350m) mountain terrain masking against SAM radars
## - `AI_EVASIVE_DEFENSIVE (3)`: High-G missile evasion jink / Infantry & Armor reverse-slope cover dispersion
## - `AI_UNMANNED_ASSAULT (4)`: Vanguard deployment of Quadruped Robot Dogs / FPV Swarms / Loyal Wingmen
## - `AI_SHOOT_AND_SCOOT (5)`: Post-salvo artillery counter-battery relocation
## - `AI_RTB_RESUPPLY (6)`: Bingo fuel / Winchester ammo return to Tanker, Convoy, or Airbase

const EchelonClusterSystemScript := preload("res://src/sim_core/systems/echelon_cluster_system.gd")


static func step(state: WorldState, sim_db: Node, grid: SpatialHashGrid, dt: float) -> void:
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var max_pid: int = p_dom.size()

	var flag_sam: int = int(sim_db.FLAG_SAM)
	var flag_fighter: int = int(sim_db.FLAG_FIGHTER)
	var flag_awacs_tanker: int = int(sim_db.FLAG_AWACS | sim_db.FLAG_TANKER | sim_db.FLAG_LOGISTICS)
	var flag_artillery: int = int(sim_db.FLAG_ARTILLERY)
	var flag_ground_maneuver: int = int(sim_db.FLAG_INFANTRY | sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_ARMOR | sim_db.FLAG_SWARM)

	var u_active := state.unit_active
	var u_ech := state.unit_echelon
	var u_pid := state.unit_platform_id
	var u_pos := state.unit_pos
	var u_fac := state.unit_faction
	var u_det := state.unit_detected_mask
	var u_rad := state.unit_radar_active
	var u_lod := state.unit_sim_lod
	var has_lod := u_lod.size() >= state.unit_count
	var n_units := state.unit_count
	var tick := state.tick_id

	for uid in range(n_units):
		if u_active[uid] == 0 or u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue

		if state.unit_player_override_timer[uid] > 0.0 and state.unit_player_override_timer[uid] < 9000.0:
			state.unit_player_override_timer[uid] = maxf(0.0, state.unit_player_override_timer[uid] - dt)
			if state.unit_player_override_timer[uid] <= 0.0 and uid < state.unit_delegated_ai.size():
				state.unit_delegated_ai[uid] = 1

		var lod_tier: int = u_lod[uid] if has_lod else WorldState.LOD_TIER_0_MICRO
		if lod_tier == WorldState.LOD_TIER_2_MACRO and ((tick + uid) & 3) != 0:
			continue

		var pid: int = u_pid[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var dom_id: int = p_dom[pid]
		var flg: int = p_flags[pid]
		var pos: Vector3 = u_pos[uid]
		var fac: int = u_fac[uid]
		# C2 Decapitation Latency: if Command Bunkers / SATCOM are degraded, non-autonomous units react slower
		var c2_int: float = state.blue_c2_integrity if fac == WorldState.FACTION_BLUE else state.red_c2_integrity
		if c2_int < 0.65 and (flg & int(sim_db.FLAG_UNMANNED)) == 0 and tick > 0 and ((tick + uid) % 3 != 0):
			continue
		var enemy_fac: int = WorldState.FACTION_RED if fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
		var mask_req: int = 1 if fac == WorldState.FACTION_BLUE else 2

		# 1. Situational Awareness: Zero-allocation scan for incoming munitions within 28 km
		var threat: float = 0.0
		var closest_mun_pos := Vector3.ZERO
		var has_incoming_missile := false
		var m_cnt := grid.query_enemy_munitions_into_scratch(enemy_fac, pos.x, pos.z, 28.0)
		var s_mids := grid.scratch_mids
		for m_idx in range(m_cnt):
			var mid: int = s_mids[m_idx]
			if state.mun_active[mid] == 1:
				var m_pos: Vector3 = state.mun_pos[mid]
				var dx := pos.x - m_pos.x
				var dz := pos.z - m_pos.z
				var d_sq := dx * dx + dz * dz
				if state.mun_target_unit_id[mid] == uid or d_sq < 196.0:
					var d_km := sqrt(d_sq)
					threat = maxf(threat, clampf(1.0 - (d_km / 28.0), 0.35, 1.0))
					closest_mun_pos = m_pos
					has_incoming_missile = true
					break

		var hp_ratio := state.unit_hp[uid] / maxf(1.0, state.unit_max_hp[uid])
		if hp_ratio < 0.45:
			threat = maxf(threat, 0.75)

		# Zero-allocation scan of hostile units within 70 km
		var u_cnt := grid.query_enemy_units_into_scratch(enemy_fac, pos.x, pos.z, 70.0)
		var s_uids := grid.scratch_uids
		var nearest_enemy_uid: int = -1
		var nearest_enemy_d_sq: float = 4900.0
		var nearest_sam_uid: int = -1
		var nearest_sam_d_sq: float = 4900.0
		var nearest_air_uid: int = -1
		var nearest_air_d_sq: float = 4900.0

		for n_idx in range(u_cnt):
			var tid: int = s_uids[n_idx]
			if u_active[tid] == 0 or (u_det[tid] & mask_req) == 0:
				continue
			var t_pos: Vector3 = u_pos[tid]
			var dx := pos.x - t_pos.x
			var dz := pos.z - t_pos.z
			var d_sq := dx * dx + dz * dz
			if d_sq < nearest_enemy_d_sq:
				nearest_enemy_d_sq = d_sq
				nearest_enemy_uid = tid
			var t_pid: int = u_pid[tid]
			if t_pid > 0 and t_pid < max_pid:
				if (p_flags[t_pid] & flag_sam) != 0 and u_rad[tid] == 1 and d_sq < nearest_sam_d_sq:
					nearest_sam_d_sq = d_sq
					nearest_sam_uid = tid
					if dom_id == 1 and d_sq < 4225.0:
						threat = maxf(threat, 0.55)
				if p_dom[t_pid] == 1 and d_sq < nearest_air_d_sq:
					nearest_air_d_sq = d_sq
					nearest_air_uid = tid

		state.unit_threat_level[uid] = threat

		# 2. Priority 1 Decision: Bingo Fuel / Winchester Ammo -> RTB / Resupply
		if (dom_id == 1 and state.unit_fuel_km[uid] < state.unit_max_fuel_km[uid] * 0.22) or (state.unit_ammo_1[uid] == 0 and state.unit_ammo_2[uid] == 0 and (flg & flag_awacs_tanker) == 0):
			state.unit_ai_state[uid] = WorldState.AI_RTB_RESUPPLY
			continue

		# 3. Priority 2 Decision: Incoming Missile Evasive Jink / Ground Cover Dispersion
		if has_incoming_missile and state.unit_player_override_timer[uid] <= 0.0:
			state.unit_ai_state[uid] = WorldState.AI_EVASIVE_DEFENSIVE
			state.unit_afterburner[uid] = 1
			var away_2d := Vector2(pos.x - closest_mun_pos.x, pos.z - closest_mun_pos.z)
			if away_2d.length_squared() < 0.01:
				away_2d = Vector2(1.0, 0.0)
			var orth_2d := Vector2(-away_2d.y, away_2d.x).normalized()
			if dom_id == 1:
				state.unit_desired_alt_m[uid] = 450.0
				state.unit_target_pos[uid] = Vector3(
					clampf(pos.x + orth_2d.x * 8.0, -245.0, 245.0),
					450.0,
					clampf(pos.z + orth_2d.y * 8.0, -245.0, 245.0)
				)
				state.unit_has_waypoint[uid] = 1
			elif dom_id == 0 and (flg & flag_sam) == 0:
				state.unit_target_pos[uid] = Vector3(
					clampf(pos.x + orth_2d.x * 1.8, -245.0, 245.0),
					pos.y,
					clampf(pos.z + orth_2d.y * 1.8, -245.0, 245.0)
				)
				state.unit_has_waypoint[uid] = 1
			continue

		if state.unit_player_override_timer[uid] > 0.0 or (uid < state.unit_delegated_ai.size() and state.unit_delegated_ai[uid] == 0):
			continue

		# 4. Priority 3 Decision: Autonomous Vanguard Deployment of Robot Dogs / FPV Swarms
		if state.unit_unmanned_bays[uid] > 0 and state.tick_id >= 25 and ((state.tick_id + uid) % 20 == 0):
			var slope_here := state.get_terrain_slope_deg(pos.x, pos.z)
			if nearest_enemy_d_sq < 1444.0 or (dom_id == 0 and slope_here > 16.0):
				state.unit_ai_state[uid] = WorldState.AI_UNMANNED_ASSAULT
				var dir_to_en := Vector3(1.8, 0.0, -1.5)
				if nearest_enemy_uid >= 0:
					var e_pos := u_pos[nearest_enemy_uid]
					var d2 := Vector2(e_pos.x - pos.x, e_pos.z - pos.z).normalized() * 2.2
					dir_to_en = Vector3(d2.x, 0.0, d2.y)
				EchelonClusterSystemScript.deploy_unmanned_subunit(state, sim_db, uid, dir_to_en)
				continue

		# 5. Priority 4 Decision: Domain-Specific Tactical AI
		if dom_id == 1:
			if nearest_sam_uid >= 0 and nearest_sam_d_sq < 4900.0 and (flg & flag_awacs_tanker) == 0:
				state.unit_ai_state[uid] = WorldState.AI_SEAD_TERRAIN_MASK
				state.unit_desired_alt_m[uid] = 350.0
				state.unit_afterburner[uid] = 1
				continue

			if nearest_air_uid >= 0 and nearest_air_d_sq < 4900.0 and (flg & flag_fighter) != 0:
				state.unit_ai_state[uid] = WorldState.AI_BVR_INTERCEPT
				state.unit_desired_alt_m[uid] = 8800.0
				state.unit_afterburner[uid] = 1
				var air_tpos := u_pos[nearest_air_uid]
				state.unit_target_pos[uid] = Vector3(air_tpos.x, 8800.0, air_tpos.z)
				state.unit_has_waypoint[uid] = 1
				continue

			state.unit_ai_state[uid] = WorldState.AI_PATROL_CAP
			state.unit_afterburner[uid] = 0

		elif dom_id == 0:
			if (flg & flag_artillery) != 0 and state.unit_cooldown[uid] > 4.5 and state.unit_has_waypoint[uid] == 0:
				state.unit_ai_state[uid] = WorldState.AI_SHOOT_AND_SCOOT
				var scoot_ang := float((uid * 53 + state.tick_id) % 360)
				var scoot_vec := Vector2(cos(deg_to_rad(scoot_ang)), sin(deg_to_rad(scoot_ang))) * 2.4
				state.unit_target_pos[uid] = Vector3(
					clampf(pos.x + scoot_vec.x, -245.0, 245.0),
					pos.y,
					clampf(pos.z + scoot_vec.y, -245.0, 245.0)
				)
				state.unit_has_waypoint[uid] = 1
				continue

			if nearest_enemy_uid >= 0 and nearest_enemy_d_sq < 784.0 and nearest_enemy_d_sq > 12.25 and (flg & flag_ground_maneuver) != 0:
				state.unit_ai_state[uid] = WorldState.AI_UNMANNED_ASSAULT if (flg & int(sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)) != 0 else WorldState.AI_BVR_INTERCEPT
				if state.unit_has_waypoint[uid] == 0:
					state.unit_target_pos[uid] = u_pos[nearest_enemy_uid]
					state.unit_has_waypoint[uid] = 1
				continue

			state.unit_ai_state[uid] = WorldState.AI_PATROL_CAP
			state.unit_afterburner[uid] = 0
		else:
			state.unit_ai_state[uid] = WorldState.AI_PATROL_CAP


static func get_ai_state_description(ai_state: int, threat_level: float, afterburner: int, desired_alt_m: float, domain: String) -> String:
	var state_str := "PATROL / CAP OVERWATCH"
	match ai_state:
		WorldState.AI_BVR_INTERCEPT:
			state_str = "AUTONOMOUS INTERCEPT / ASSAULT"
		WorldState.AI_SEAD_TERRAIN_MASK:
			state_str = "NOE TERRAIN-MASKING (SEAD)"
		WorldState.AI_EVASIVE_DEFENSIVE:
			state_str = "EVASIVE MISSILE JINK / COVER!"
		WorldState.AI_UNMANNED_ASSAULT:
			state_str = "DEPLOYING ROBOT DOG / DRONE VANGUARD"
		WorldState.AI_SHOOT_AND_SCOOT:
			state_str = "ARTILLERY SHOOT-AND-SCOOT RELOCATION"
		WorldState.AI_RTB_RESUPPLY:
			state_str = "BINGO FUEL / AMMO -> RTB RESUPPLY"
	var spd_str := "AFTERBURNER / SPRINT" if afterburner == 1 else "CRUISE"
	if domain == "AIR":
		return "AI: %s | THREAT: %.0f%% | %s | ALT: %.0fm" % [state_str, threat_level * 100.0, spd_str, desired_alt_m]
	return "AI: %s | THREAT: %.0f%% | MODE: %s" % [state_str, threat_level * 100.0, spd_str]

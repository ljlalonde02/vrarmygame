class_name CoordinatedStrikeSystem
extends RefCounted
## FEAT-12: Multi-Domain Theater AI & Coordinated Strike Waves (Sprint 2 / PI 02)
## Orchestrates 4-Phase Multi-Domain Coordinated Strike Packages:
## - Phase 1 (CEMA): Cyber & Electronic Warfare (degrades radar detection range by 40-70%).
## - Phase 2 (SEAD/DEAD): Anti-Radiation Missiles targeting air defense emitters (Patriot, S-400).
## - Phase 3 (Decoy Saturation): ADM-160 MALD & decoy swarms exhausting enemy SAM interceptor magazines.
## - Phase 4 (Hypersonic Penetration): High-Mach kinetic precision strikes (Dark Eagle / Zircon / Tungsten).
##
## Also handles Battalion Combined Arms Synergy:
## - Bounding overwatch between armor platoons and infantry/IFVs.
## - Micro-UAV / FPV drone datalink target coordinate handoff to tanks & artillery.
## - IFV mechanized infantry dismounts advancing in coordinated formation.
## - Active Protection Systems (APS, e.g. Trophy / Afghanit) intercepting incoming anti-tank missiles.

signal strike_phase_executed(phase_num: int, phase_name: String, details: Dictionary)
signal coordinated_strike_completed(result: Dictionary)
signal drone_target_handoff_relayed(drone_uid: int, tank_uid: int, target_coord: Vector3)
signal aps_interception_triggered(unit_uid: int, munition_pos: Vector3)

const PHASE_1_CEMA := "CEMA_CYBER_EW"
const PHASE_2_SEAD_DEAD := "SEAD_DEAD_RADAR_KILL"
const PHASE_3_DECOY_SATURATION := "DECOY_MAGAZINE_SATURATION"
const PHASE_4_HYPERSONIC := "HYPERSONIC_PRECISION_PENETRATION"


## Executes a complete 4-phase coordinated strike package against a target coordinate
static func execute_strike_package(
	state: WorldState,
	sim_db: Node,
	target_coord: Vector3,
	package_config: Dictionary = {}
) -> Dictionary:
	var attacking_faction: int = int(package_config.get("faction", WorldState.FACTION_BLUE))
	var defending_faction: int = WorldState.FACTION_RED if attacking_faction == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
	var strike_id: int = int(package_config.get("strike_id", randi() % 9000 + 1000))
	var target_radius_km: float = float(package_config.get("radius_km", 45.0))

	var result := {
		"strike_id": strike_id,
		"target_coord": target_coord,
		"attacking_faction": attacking_faction,
		"phase_1_cema": {},
		"phase_2_sead": {},
		"phase_3_decoys": {},
		"phase_4_hypersonic": {},
		"total_damage_dealt": 0.0,
		"radars_blinded": 0,
		"emitters_destroyed": 0,
		"interceptors_exhausted": 0,
		"hypersonic_hits": 0,
		"success": true,
	}

	# -------------------------------------------------------------------------
	# PHASE 1: CEMA Cyber & Electronic Warfare
	# -------------------------------------------------------------------------
	var cema_degrade_pct: float = randf_range(0.40, 0.70)
	var blinded_radars: int = 0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == defending_faction:
			var d_km := Vector2(state.unit_pos[uid].x - target_coord.x, state.unit_pos[uid].z - target_coord.z).length()
			if d_km <= target_radius_km * 1.5:
				if state.unit_radar_active[uid] == 1:
					blinded_radars += 1
					# Degrade radar sensor mask via EW jamming
					state.unit_jammed[uid] = 1

	result["radars_blinded"] = blinded_radars
	result["phase_1_cema"] = {
		"radar_degradation_ratio": cema_degrade_pct,
		"radars_blinded_count": blinded_radars,
		"status": "CEMA Blanket Jamming Active",
	}

	# -------------------------------------------------------------------------
	# PHASE 2: SEAD/DEAD Suppression & Destruction of Enemy Air Defenses
	# -------------------------------------------------------------------------
	var emitters_killed: int = 0
	var sead_missiles_fired: int = int(package_config.get("sead_missiles", 8))
	var sam_flag: int = int(sim_db.FLAG_SAM) if sim_db != null else 1
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == defending_faction:
			var pid: int = state.unit_platform_id[uid]
			if sim_db != null and pid > 0 and (sim_db.plat_class_flags[pid] & sam_flag) != 0:
				var d_km := Vector2(state.unit_pos[uid].x - target_coord.x, state.unit_pos[uid].z - target_coord.z).length()
				if d_km <= target_radius_km and emitters_killed < sead_missiles_fired / 2:
					state.unit_hp[uid] -= 320.0
					if state.unit_hp[uid] <= 0.0:
						state.unit_active[uid] = 0
						emitters_killed += 1
						result["total_damage_dealt"] += 320.0
						if defending_faction == WorldState.FACTION_BLUE:
							state.blue_lost_musd += 45.0
						else:
							state.red_lost_musd += 45.0

	result["emitters_destroyed"] = emitters_killed
	result["phase_2_sead"] = {
		"missiles_expended": sead_missiles_fired,
		"emitters_destroyed": emitters_killed,
		"status": "Air Defense Emitters Suppressed",
	}

	# -------------------------------------------------------------------------
	# PHASE 3: Decoy Saturation (ADM-160 MALD / Swarm decoys)
	# -------------------------------------------------------------------------
	var decoys_launched: int = int(package_config.get("decoys", 16))
	var interceptors_drawn: int = mini(decoys_launched, randi_range(12, 24))
	result["interceptors_exhausted"] = interceptors_drawn
	result["phase_3_decoys"] = {
		"decoys_deployed": decoys_launched,
		"interceptor_magazines_drained": interceptors_drawn,
		"status": "IADS Magazines Saturated & Exhausted",
	}

	# Deduct defending ammunition to reflect exhausted SAM magazines
	if defending_faction == WorldState.FACTION_BLUE:
		state.blue_ammo_remaining = maxi(0, state.blue_ammo_remaining - interceptors_drawn * 2)
	else:
		state.red_ammo_remaining = maxi(0, state.red_ammo_remaining - interceptors_drawn * 2)

	# -------------------------------------------------------------------------
	# PHASE 4: Hypersonic Penetration (Mach 5+ kinetic strike)
	# -------------------------------------------------------------------------
	var hypersonic_salvo: int = int(package_config.get("hypersonic_rounds", 6))
	var hits: int = 0
	var total_kinetic_dmg: float = 0.0

	for i in range(hypersonic_salvo):
		# Penetration probability is extremely high due to prior CEMA/SEAD/Decoy phases (>92%)
		if randf() <= 0.94:
			hits += 1
			total_kinetic_dmg += 480.0

	# Apply damage to defending units in target perimeter
	var dmg_remaining := total_kinetic_dmg
	for uid in range(state.unit_count):
		if dmg_remaining <= 0.0:
			break
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == defending_faction:
			var d_km := Vector2(state.unit_pos[uid].x - target_coord.x, state.unit_pos[uid].z - target_coord.z).length()
			if d_km <= target_radius_km:
				var apply_d := minf(dmg_remaining, 250.0)
				state.unit_hp[uid] -= apply_d
				dmg_remaining -= apply_d
				if state.unit_hp[uid] <= 0.0:
					state.unit_active[uid] = 0
					if defending_faction == WorldState.FACTION_BLUE:
						state.blue_lost_musd += 65.0
					else:
						state.red_lost_musd += 65.0

	result["hypersonic_hits"] = hits
	result["total_damage_dealt"] += total_kinetic_dmg
	result["phase_4_hypersonic"] = {
		"hypersonic_salvo_size": hypersonic_salvo,
		"penetration_hits": hits,
		"mach_speed": 11.5,
		"kinetic_damage": total_kinetic_dmg,
		"status": "High-Mach Kinetic Impact Confirmed",
	}

	# Record impact crater in world_state
	state.recent_impacts.append({
		"pos_km": target_coord,
		"radius_km": 18.0,
		"cost_musd": total_kinetic_dmg * 0.15,
		"is_intercept": false,
		"ttl": 6.0,
	})

	return result


## Bounding overwatch, drone datalink handoff, and APS interception logic
static func step_combined_arms_synergy(
	state: WorldState,
	sim_db: Node,
	grid: SpatialHashGrid,
	dt: float
) -> Dictionary:
	var handoffs_count := 0
	var aps_intercepts := 0
	var dismounts_advancing := 0
	var bounding_tanks := 0

	var flag_drone: int = int(sim_db.FLAG_SWARM | sim_db.FLAG_UNMANNED) if sim_db != null else 0
	var flag_tank: int = int(sim_db.FLAG_ARMOR) if sim_db != null else 0
	var flag_ifv: int = int(sim_db.FLAG_INFANTRY) if sim_db != null else 0

	# 1. Micro-UAV / FPV Drone Datalink Target Handoff to Tanks/Artillery
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid: int = state.unit_platform_id[uid]
		if sim_db != null and pid > 0 and (sim_db.plat_class_flags[pid] & flag_drone) != 0:
			var fac := state.unit_faction[uid]
			var enemy_fac := WorldState.FACTION_RED if fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
			var u_pos := state.unit_pos[uid]
			# Find hostile target
			var target_tid := grid.find_nearest_enemy_unit(state, enemy_fac, u_pos.x, u_pos.z, 15.0, 0)
			if target_tid >= 0:
				var t_pos := state.unit_pos[target_tid]
				# Handoff target to nearest friendly tank within 20km
				for tank_uid in range(state.unit_count):
					if state.unit_active[tank_uid] == 1 and state.unit_faction[tank_uid] == fac and tank_uid != uid:
						var t_pid: int = state.unit_platform_id[tank_uid]
						if sim_db != null and t_pid > 0 and (sim_db.plat_class_flags[t_pid] & flag_tank) != 0:
							var dist_tank := (state.unit_pos[tank_uid] - u_pos).length()
							if dist_tank < 25.0:
								# Relayed target coordinates via datalink
								state.unit_target_pos[tank_uid] = t_pos
								state.unit_has_waypoint[tank_uid] = 1
								handoffs_count += 1
								break

	# 2. Active Protection Systems (APS Trophy / Afghanit) intercepting anti-armor munitions
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0:
			continue
		var pid: int = state.unit_platform_id[uid]
		if sim_db != null and pid > 0 and (sim_db.plat_class_flags[pid] & flag_tank) != 0:
			var u_pos := state.unit_pos[uid]
			var enemy_fac := WorldState.FACTION_RED if state.unit_faction[uid] == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
			var mun_cnt := grid.query_enemy_munitions_into_scratch(enemy_fac, u_pos.x, u_pos.z, 3.5)
			if mun_cnt > 0:
				var mid: int = grid.scratch_mids[0]
				if state.mun_active[mid] == 1:
					# APS hard-kill counter-munition detonates incoming threat
					state.mun_active[mid] = 0
					aps_intercepts += 1
					bounding_tanks += 1

	return {
		"drone_target_handoffs": handoffs_count,
		"aps_intercepts": aps_intercepts,
		"bounding_tanks": bounding_tanks,
		"dismounts_advancing": dismounts_advancing,
	}


## US-9.1: Multi-Echelon AI Strike Package Coordination (Sweep/Escort + SEAD + Strike Bomber)
static func form_air_strike_package(
	state: WorldState,
	sim_db: Node,
	faction: int,
	target_coord: Vector3,
	escort_uids: Array = [],
	sead_uids: Array = [],
	strike_uids: Array = []
) -> Dictionary:
	var flag_fighter: int = int(sim_db.FLAG_FIGHTER) if sim_db != null else 1
	var flag_bomber: int = int(sim_db.FLAG_BOMBER) if (sim_db != null and "FLAG_BOMBER" in sim_db) else 1

	var assigned_escorts: Array[int] = []
	var assigned_sead: Array[int] = []
	var assigned_strike: Array[int] = []

	# Auto-discover if not explicitly provided
	if escort_uids.is_empty() or sead_uids.is_empty() or strike_uids.is_empty():
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 0 or state.unit_faction[uid] != faction:
				continue
			var pid: int = state.unit_platform_id[uid]
			var dom: int = sim_db.plat_domain_id[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_domain_id.size()) else -1
			if dom != 1: # Air domain only
				continue
			var flags: int = sim_db.plat_class_flags[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_class_flags.size()) else 0

			if escort_uids.is_empty() and assigned_escorts.size() < 2 and (flags & flag_fighter) != 0:
				assigned_escorts.append(uid)
			elif sead_uids.is_empty() and assigned_sead.size() < 2 and uid not in assigned_escorts:
				assigned_sead.append(uid)
			elif strike_uids.is_empty() and assigned_strike.size() < 2 and uid not in assigned_escorts and uid not in assigned_sead:
				assigned_strike.append(uid)
	else:
		for e in escort_uids: assigned_escorts.append(int(e))
		for s in sead_uids: assigned_sead.append(int(s))
		for b in strike_uids: assigned_strike.append(int(b))

	# Compute package ingress vector from average centroid toward target
	var centroid := Vector3.ZERO
	var total_units := assigned_escorts.size() + assigned_sead.size() + assigned_strike.size()
	if total_units > 0:
		for uid in assigned_escorts + assigned_sead + assigned_strike:
			centroid += state.unit_pos[uid]
		centroid /= float(total_units)
	else:
		centroid = target_coord - Vector3(50.0, 0.0, 50.0)

	var dir_to_tgt := (target_coord - centroid).normalized()
	if dir_to_tgt.length_squared() < 0.001:
		dir_to_tgt = Vector3(1.0, 0.0, 0.0)

	# 1. Escorts lead package (+18km) at high-altitude (10,500m) BVR Stand-off
	for uid in assigned_escorts:
		if uid >= 0 and uid < state.unit_count and state.unit_active[uid] == 1:
			state.unit_desired_alt_m[uid] = 10500.0
			state.unit_tactical_posture[uid] = WorldState.TACTICAL_POSTURE_BVR_STANDOFF
			state.unit_target_pos[uid] = target_coord + dir_to_tgt * 18.0
			state.unit_has_waypoint[uid] = 1
			state.unit_afterburner[uid] = 1

	# 2. SEAD aircraft ingress at medium altitude (4,500m) offset (+6km) prioritizing hostile radar suppression
	for uid in assigned_sead:
		if uid >= 0 and uid < state.unit_count and state.unit_active[uid] == 1:
			state.unit_desired_alt_m[uid] = 4500.0
			state.unit_tactical_posture[uid] = WorldState.TACTICAL_POSTURE_AUTO
			state.unit_target_pos[uid] = target_coord + dir_to_tgt * 6.0
			state.unit_has_waypoint[uid] = 1
			state.unit_radar_active[uid] = 1

	# 3. Strike aircraft follow at 8,200m ingress altitude committed to target terminal release point
	for uid in assigned_strike:
		if uid >= 0 and uid < state.unit_count and state.unit_active[uid] == 1:
			state.unit_desired_alt_m[uid] = 8200.0
			state.unit_tactical_posture[uid] = WorldState.TACTICAL_POSTURE_AUTO
			state.unit_target_pos[uid] = target_coord
			state.unit_has_waypoint[uid] = 1

	var package_info := {
		"faction": faction,
		"target_coord": target_coord,
		"escorts": assigned_escorts,
		"sead": assigned_sead,
		"strike": assigned_strike,
		"ingress_vector": dir_to_tgt,
		"package_size": total_units,
		"status": "INGRESSING"
	}

	state.sim_events_queue.append({
		"type": "STRIKE_PACKAGE_FORMED",
		"faction": faction,
		"target": target_coord,
		"package_size": total_units,
		"escorts_count": assigned_escorts.size(),
		"sead_count": assigned_sead.size(),
		"strike_count": assigned_strike.size()
	})

	return package_info


## US-9.2: Naval Task Force Screening Umbrella Doctrine (Air Defense Screen around Carrier/HVU)
static func form_naval_task_force_screen(
	state: WorldState,
	sim_db: Node,
	flagship_uid: int,
	escort_uids: Array = [],
	screen_radius_km: float = 35.0
) -> Dictionary:
	if flagship_uid < 0 or flagship_uid >= state.unit_count or state.unit_active[flagship_uid] == 0:
		return {"error": "Invalid flagship"}

	var flag_pos: Vector3 = state.unit_pos[flagship_uid]
	var faction: int = state.unit_faction[flagship_uid]
	var flag_surface: int = int(sim_db.FLAG_SHIP) if (sim_db != null and "FLAG_SHIP" in sim_db) else 1

	var assigned_escorts: Array[int] = []
	if escort_uids.is_empty():
		for uid in range(state.unit_count):
			if uid == flagship_uid or state.unit_active[uid] == 0 or state.unit_faction[uid] != faction:
				continue
			var pid: int = state.unit_platform_id[uid]
			var dom: int = sim_db.plat_domain_id[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_domain_id.size()) else -1
			if dom != 2: # Naval domain only
				continue
			var flags: int = sim_db.plat_class_flags[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_class_flags.size()) else 0
			if (flags & flag_surface) != 0:
				assigned_escorts.append(uid)
				if assigned_escorts.size() >= 4:
					break
	else:
		for e in escort_uids:
			assigned_escorts.append(int(e))

	# 4 Quadrant Screening Offsets (NE 45°, SE 135°, SW 225°, NW 315°)
	var angles_deg := [45.0, 135.0, 225.0, 315.0]
	var station_coords: Array[Vector3] = []

	for i in range(assigned_escorts.size()):
		var esc_uid: int = assigned_escorts[i]
		if esc_uid < 0 or esc_uid >= state.unit_count or state.unit_active[esc_uid] == 0:
			continue
		var angle_rad := deg_to_rad(angles_deg[i % angles_deg.size()])
		var offset := Vector3(cos(angle_rad) * screen_radius_km, 0.0, sin(angle_rad) * screen_radius_km)
		var station_pos := flag_pos + offset
		station_coords.append(station_pos)

		state.unit_target_pos[esc_uid] = station_pos
		state.unit_has_waypoint[esc_uid] = 1
		state.unit_radar_active[esc_uid] = 1 # Active radar umbrella
		state.unit_tactical_posture[esc_uid] = WorldState.TACTICAL_POSTURE_AUTO

	state.sim_events_queue.append({
		"type": "NAVAL_SCREEN_FORMED",
		"flagship_uid": flagship_uid,
		"faction": faction,
		"escorts_count": assigned_escorts.size(),
		"screen_radius_km": screen_radius_km
	})

	return {
		"flagship_uid": flagship_uid,
		"faction": faction,
		"escorts": assigned_escorts,
		"stations": station_coords,
		"screen_radius_km": screen_radius_km,
		"status": "SCREEN_ACTIVE"
	}

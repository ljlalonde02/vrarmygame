class_name SalvoCombatSystem
extends RefCounted
## High-Performance Data-Oriented Combat & Intercept Engine:
## - Uses Pre-Compiled `SimDB` SoA LUTs (`plat_de_kw`, `weap_speed_km_s`, `weap_nez_km`, `plat_armor_mitigation`)
## - Uses Zero-Allocation `SpatialHashGrid` Intrusive Linked-List Scratch Queries (`scratch_uids`, `scratch_mids`)
## - Resolves Alpha Strike Salvos, Mach-scaled parabolic trajectories, Patriot/S-400 SAM intercepts,
##   Directed Energy Lasers (`Iron Beam` 100kW) & 30° HPM Microwave Cones (`Epirus Leonidas`),
##   Airbase Runway Cratering, and real-time `$ Millions USD` economic war damage accounting.

const LogisticsSystemScript := preload("res://src/sim_core/systems/logistics_system.gd")
const MACH_TO_KM_PER_SEC := 0.343
const MUNITION_PACE_MULT := 1.0 # 1.0 = True 1:1 Real-Time Missile Physics (Mach 1 = 0.343 km/s)


static func launch_strike_salvo(
	state: WorldState,
	sim_db: Node,
	attacker_uid: int,
	target_uid: int,
	target_pos_km: Vector3,
	weapon_slot: int = 1,
	salvo_qty: int = 2
) -> int:
	if attacker_uid < 0 or attacker_uid >= state.unit_count or state.unit_active[attacker_uid] == 0:
		return 0
	var pid := state.unit_platform_id[attacker_uid]
	if pid <= 0 or pid >= sim_db.plat_w1_id.size():
		return 0

	var wid: int = sim_db.plat_w1_id[pid] if weapon_slot == 1 else sim_db.plat_w2_id[pid]
	var avail_ammo: int = state.unit_ammo_1[attacker_uid] if weapon_slot == 1 else state.unit_ammo_2[attacker_uid]
	if wid <= 0 or avail_ammo <= 0:
		wid = sim_db.plat_w2_id[pid]
		avail_ammo = state.unit_ammo_2[attacker_uid]
		weapon_slot = 2
	if wid <= 0 or avail_ammo <= 0:
		return 0

	var w_def: Dictionary = sim_db.get_weapon(wid)
	if w_def.is_empty():
		return 0

	var actual_shots := mini(salvo_qty, avail_ammo)
	var start_pos := state.unit_pos[attacker_uid]
	var final_target_pos := target_pos_km
	if target_uid >= 0 and target_uid < state.unit_count and state.unit_active[target_uid] == 1:
		final_target_pos = state.unit_pos[target_uid]

	var profile := String(w_def.get("flight_profile", "LOFTED_BALLISTIC"))
	var launched := 0
	for s in range(actual_shots):
		var spread := Vector3(float(s - actual_shots / 2) * 0.25, 0.0, float(s % 2) * 0.25)
		var mid := state.spawn_munition(
			state.unit_faction[attacker_uid],
			wid,
			attacker_uid,
			target_uid,
			start_pos + spread,
			final_target_pos,
			profile
		)
		if mid >= 0:
			launched += 1

	if weapon_slot == 1:
		state.unit_ammo_1[attacker_uid] -= launched
	else:
		state.unit_ammo_2[attacker_uid] -= launched

	if launched > 0:
		if state.unit_faction[attacker_uid] == WorldState.FACTION_BLUE:
			state.blue_munitions_expended += launched
		else:
			state.red_munitions_expended += launched
		state.sim_events_queue.append({
			"type": "salvo_launched",
			"attacker_id": attacker_uid,
			"target_id": target_uid,
			"weapon_id": wid,
			"pos_km": start_pos,
		})
		if target_uid >= 0 and target_uid < state.unit_count and state.unit_active[target_uid] == 1:
			UnitTacticalAISystem.trigger_rwr_warning(state, sim_db, target_uid, attacker_uid)

		# Sprint 7: Unit interaction & weapon effects
		if sim_db:
			var att_pid: int = state.unit_platform_id[attacker_uid] if attacker_uid < state.unit_platform_id.size() else 0
			var att_flg: int = sim_db.plat_class_flags[att_pid] if (att_pid > 0 and att_pid < sim_db.plat_class_flags.size()) else 0
			if (att_flg & int(sim_db.FLAG_UUV_SUB)) != 0:
				state.spawn_sonar_ping(attacker_uid, start_pos, state.unit_faction[attacker_uid], 45.0)
			if (att_flg & int(sim_db.FLAG_ARMOR)) != 0:
				state.sim_events_queue.append({
					"type": "tank_muzzle_flash",
					"attacker_id": attacker_uid,
					"pos_km": start_pos,
					"target_pos_km": final_target_pos,
					"faction": state.unit_faction[attacker_uid],
				})
	return launched


static func commit_queued_strikes(state: WorldState, sim_db: Node, faction: int) -> int:
	var total_launched := 0
	var remaining: Array[Dictionary] = []
	for pkg in state.queued_strikes:
		var pkg_fac: int = int(pkg.get("faction", faction))
		if pkg_fac != faction:
			remaining.append(pkg)
			continue
		var attackers: Array = pkg.get("attacker_ids", [])
		var target_uid: int = int(pkg.get("target_unit_id", -1))
		var target_pos: Vector3 = pkg.get("target_pos_km", Vector3.ZERO)
		var w_slot: int = int(pkg.get("weapon_slot", 1))
		var salvo_per_unit: int = int(pkg.get("salvo_per_unit", 2))
		for a_id in attackers:
			total_launched += launch_strike_salvo(state, sim_db, int(a_id), target_uid, target_pos, w_slot, salvo_per_unit)

	state.queued_strikes = remaining
	state.sim_events_queue.append({
		"type": "alpha_strike_committed",
		"faction": faction,
		"total_missiles_launched": total_launched,
	})
	return total_launched


static func step(state: WorldState, sim_db: Node, grid: SpatialHashGrid, dt: float) -> void:
	var p_de_kw: PackedFloat32Array = sim_db.plat_de_kw
	var p_de_cone_deg: PackedFloat32Array = sim_db.plat_de_cone_deg
	var p_de_cone_cos: PackedFloat32Array = sim_db.plat_de_cone_cos
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var p_w1_id: PackedInt32Array = sim_db.plat_w1_id
	var max_pid: int = p_de_kw.size()

	var w_speed_km_s: PackedFloat32Array = sim_db.weap_speed_km_s
	var w_nez_km: PackedFloat32Array = sim_db.weap_nez_km
	var w_dmg: PackedFloat32Array = sim_db.weap_damage
	var w_pk: PackedFloat32Array = sim_db.weap_base_pk
	var w_cost: PackedFloat32Array = sim_db.weap_cost_musd
	var w_interceptable: PackedByteArray = sim_db.weap_is_interceptable
	var max_wid: int = w_speed_km_s.size()

	var intercept_mask: int = int(sim_db.FLAG_SAM | sim_db.FLAG_SHIP | sim_db.FLAG_CUAS_GUN)
	var swarm_mask: int = int(sim_db.FLAG_SWARM)

	# 1. Age and prune transient Directed Energy beams & shockwave rings
	for i in range(state.active_beams.size() - 1, -1, -1):
		state.active_beams[i]["ttl"] = float(state.active_beams[i]["ttl"]) - dt
		if float(state.active_beams[i]["ttl"]) <= 0.0:
			state.active_beams.remove_at(i)

	for i in range(state.recent_impacts.size() - 1, -1, -1):
		state.recent_impacts[i]["ttl"] = float(state.recent_impacts[i]["ttl"]) - dt
		if float(state.recent_impacts[i]["ttl"]) <= 0.0:
			state.recent_impacts.remove_at(i)

	# Sprint 6: Age and simulate active countermeasure flares
	for i in range(state.active_countermeasures.size() - 1, -1, -1):
		state.active_countermeasures[i]["ttl_sec"] = float(state.active_countermeasures[i]["ttl_sec"]) - dt
		state.active_countermeasures[i]["pos_km"] += state.active_countermeasures[i]["vel_km_s"] * dt
		if float(state.active_countermeasures[i]["ttl_sec"]) <= 0.0:
			state.active_countermeasures.remove_at(i)

	# Sprint 6: Age and prune active radar illumination tracking cones
	for i in range(state.active_radar_tracks.size() - 1, -1, -1):
		state.active_radar_tracks[i]["ttl_sec"] = float(state.active_radar_tracks[i]["ttl_sec"]) - dt
		if float(state.active_radar_tracks[i]["ttl_sec"]) <= 0.0:
			state.active_radar_tracks.remove_at(i)

	# Sprint 7: Age and expand underwater active sonar acoustic pings
	for i in range(state.active_sonar_pings.size() - 1, -1, -1):
		state.active_sonar_pings[i]["ttl_sec"] = float(state.active_sonar_pings[i]["ttl_sec"]) - dt
		var cur_r: float = float(state.active_sonar_pings[i]["current_radius_km"])
		var max_r: float = float(state.active_sonar_pings[i]["max_radius_km"])
		var dur: float = maxf(0.01, float(state.active_sonar_pings[i]["duration_sec"]))
		state.active_sonar_pings[i]["current_radius_km"] = minf(max_r, cur_r + (max_r / dur) * dt)
		if float(state.active_sonar_pings[i]["ttl_sec"]) <= 0.0:
			state.active_sonar_pings.remove_at(i)

	# Sprint 7: Evaluate tactical match objectives and win/loss state periodically
	if (state.tick_id % 10) == 0:
		state.evaluate_match_conditions()

	var u_active := state.unit_active
	var u_ech := state.unit_echelon
	var u_pid := state.unit_platform_id
	var u_pos := state.unit_pos
	var u_fac := state.unit_faction
	var u_cap := state.unit_energy_cap
	var u_cd := state.unit_cooldown
	var u_roe := state.unit_roe
	var u_ammo1 := state.unit_ammo_1
	var u_rad_act := state.unit_radar_active
	var u_lod := state.unit_sim_lod
	var has_lod := u_lod.size() >= state.unit_count
	var n_units := state.unit_count
	var tick := state.tick_id

	# 2. Recharge Directed Energy thermal capacitors & process Laser / HPM / SAM air defense
	for uid in range(n_units):
		if u_active[uid] == 0 or u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue
		var fac_r := u_fac[uid]
		var rech_mult: float = state.blue_laser_recharge_mult if fac_r == WorldState.FACTION_BLUE else state.red_laser_recharge_mult
		u_cap[uid] = minf(100.0, u_cap[uid] + 10.0 * rech_mult * dt)

		var lod_tier: int = u_lod[uid] if has_lod else WorldState.LOD_TIER_0_MICRO
		if lod_tier == WorldState.LOD_TIER_2_MACRO and ((tick + uid) & 3) != 0:
			continue

		var pid := u_pid[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var de_kw := p_de_kw[pid]
		var pos := u_pos[uid]
		var fac := u_fac[uid]
		var enemy_fac := WorldState.FACTION_RED if fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE

		# A) Directed Energy Point Defense (Iron Beam 100kW Laser & Epirus Leonidas 30 deg HPM Cone)
		if de_kw > 0.0 and u_cap[uid] >= 15.0 and u_cd[uid] <= 0.0:
			var de_cone_deg := p_de_cone_deg[pid]
			if de_cone_deg > 0.0:
				var de_range_km := 8.5
				var de_range_sq := de_range_km * de_range_km
				var cos_half_cone := p_de_cone_cos[pid]
				var killed_in_cone := 0
				var cone_target_pos := Vector3.ZERO
				var cone_dir_2d := Vector2.ZERO

				var m_cnt := grid.query_enemy_munitions_into_scratch(enemy_fac, pos.x, pos.z, de_range_km)
				var s_mids := grid.scratch_mids
				for m_idx in range(m_cnt):
					var mid := s_mids[m_idx]
					if state.mun_active[mid] == 0:
						continue
					var m_wid := state.mun_weapon_id[mid]
					if w_interceptable[m_wid] == 0:
						continue
					var m_pos := state.mun_pos[mid]
					var dx := m_pos.x - pos.x
					var dz := m_pos.z - pos.z
					var d_sq := dx * dx + dz * dz
					if d_sq <= de_range_sq and d_sq > 0.0001:
						var inv_d := 1.0 / sqrt(d_sq)
						var dir_n := Vector2(dx * inv_d, dz * inv_d)
						if cone_dir_2d == Vector2.ZERO:
							cone_dir_2d = dir_n
							cone_target_pos = m_pos
						if cone_dir_2d.dot(dir_n) >= cos_half_cone:
							state.mun_active[mid] = 0
							killed_in_cone += 1
							if fac == WorldState.FACTION_BLUE:
								state.blue_munitions_intercepted += 1
							else:
								state.red_munitions_intercepted += 1

				var u_cnt := grid.query_enemy_units_into_scratch(enemy_fac, pos.x, pos.z, de_range_km)
				var s_uids := grid.scratch_uids
				for u_idx in range(u_cnt):
					var tid := s_uids[u_idx]
					if u_active[tid] == 0:
						continue
					if (p_flags[u_pid[tid]] & swarm_mask) == 0:
						continue
					var t_pos := u_pos[tid]
					var dx := t_pos.x - pos.x
					var dz := t_pos.z - pos.z
					var d_sq := dx * dx + dz * dz
					if d_sq <= de_range_sq and d_sq > 0.0001:
						var inv_d := 1.0 / sqrt(d_sq)
						var dir_n := Vector2(dx * inv_d, dz * inv_d)
						if cone_dir_2d == Vector2.ZERO:
							cone_dir_2d = dir_n
							cone_target_pos = t_pos
						if cone_dir_2d.dot(dir_n) >= cos_half_cone:
							_apply_damage_to_unit(state, sim_db, tid, 95.0)
							killed_in_cone += 1

				if killed_in_cone > 0:
					u_cap[uid] = maxf(0.0, u_cap[uid] - 24.0)
					u_cd[uid] = 1.5
					state.active_beams.append({
						"shooter_pos": pos,
						"target_pos": cone_target_pos,
						"is_hpm_cone": true,
						"cone_deg": de_cone_deg,
						"faction": fac,
						"ttl": 1.2,
					})
					state.sim_events_queue.append({
						"type": "directed_energy_fired",
						"shooter_id": uid,
						"target_pos_km": cone_target_pos,
						"is_hpm_cone": true,
						"de_kw": de_kw,
					})
			else:
				# High-Energy Laser Beam (Iron Beam 100kW / DDG-51 HELIOS): O(1) nearest munition lookup
				# Phase 24: Optical laser beam range & dwell time are attenuated by Typhoon clouds/rain/sandstorms!
				var eff_laser_range_km := 14.0 * state.weather_laser_mult
				var hit_mid := grid.find_nearest_enemy_munition(state, enemy_fac, pos.x, pos.z, eff_laser_range_km, w_interceptable) if eff_laser_range_km >= 3.5 else -1
				if hit_mid >= 0:
					var m_pos := state.mun_pos[hit_mid]
					var m_wid := state.mun_weapon_id[hit_mid]
					state.mun_active[hit_mid] = 0
					u_cap[uid] = maxf(0.0, u_cap[uid] - 15.0)
					u_cd[uid] = 0.8 / maxf(0.25, state.weather_laser_mult)
					if fac == WorldState.FACTION_BLUE:
						state.blue_munitions_intercepted += 1
					else:
						state.red_munitions_intercepted += 1
					state.active_beams.append({
						"shooter_pos": pos,
						"target_pos": m_pos,
						"is_hpm_cone": false,
						"cone_deg": 0.0,
						"faction": fac,
						"ttl": 0.9,
					})
					state.recent_impacts.append({
						"pos_km": m_pos,
						"radius_km": 1.5,
						"cost_musd": w_cost[m_wid],
						"is_intercept": true,
						"ttl": 1.5,
					})
					state.sim_events_queue.append({
						"type": "directed_energy_fired",
						"shooter_id": uid,
						"target_pos_km": m_pos,
						"is_hpm_cone": false,
						"de_kw": de_kw,
					})

		# B) Autonomous SAM / AAM / Tactical ROE Engagement
		if u_roe[uid] >= 1 and u_cd[uid] <= 0.0 and u_ammo1[uid] > 0:
			var w1_id := p_w1_id[pid]
			if w1_id > 0 and w1_id < max_wid:
				var u_flg := p_flags[pid]
				if (u_flg & intercept_mask) != 0 and u_rad_act[uid] == 1:
					var intercept_range := minf(w_nez_km[w1_id], 65.0)
					var int_mid := grid.find_nearest_enemy_munition(state, enemy_fac, pos.x, pos.z, intercept_range, w_interceptable)
					if int_mid >= 0:
						var m_pos := state.mun_pos[int_mid]
						var m_wid := state.mun_weapon_id[int_mid]
						u_ammo1[uid] -= 1
						u_cd[uid] = 2.5
						state.mun_active[int_mid] = 0
						if fac == WorldState.FACTION_BLUE:
							state.blue_munitions_expended += 1
							state.blue_munitions_intercepted += 1
						else:
							state.red_munitions_expended += 1
							state.red_munitions_intercepted += 1
						state.recent_impacts.append({
							"pos_km": m_pos,
							"radius_km": 2.5,
							"cost_musd": w_cost[m_wid],
							"is_intercept": true,
							"ttl": 1.8,
						})

					# Sprint 6: Ground Radar Tracking Illumination Cone onto approaching aircraft
					var mask_req_radar := 1 if fac == WorldState.FACTION_BLUE else 2
					var air_track_uid := grid.find_nearest_enemy_unit(state, enemy_fac, pos.x, pos.z, 70.0, mask_req_radar)
					if air_track_uid >= 0:
						var t_pos: Vector3 = state.unit_pos[air_track_uid]
						state.active_radar_tracks.append({
							"radar_uid": uid,
							"target_uid": air_track_uid,
							"radar_pos": pos,
							"target_pos": t_pos,
							"cone_deg": 16.0,
							"ttl_sec": 0.85,
							"faction": fac
						})

				# Close-range ground/air engagement if enemy detected within NEZ (unless Red Phone Ceasefire active!)
				if u_cd[uid] <= 0.0 and u_roe[uid] == 2 and state.hotline_ceasefire_timer_sec <= 0.0:
					var nez_km := minf(w_nez_km[w1_id], 35.0)
					var mask_req := 1 if fac == WorldState.FACTION_BLUE else 2
					var tid := grid.find_nearest_enemy_unit(state, enemy_fac, pos.x, pos.z, nez_km, mask_req)
					if tid >= 0:
						launch_strike_salvo(state, sim_db, uid, tid, u_pos[tid], 1, 1)
						u_cd[uid] = 8.0 / maxf(0.35, state.weather_air_sortie_mult)

	# 3. Advance all active munitions along parabolic / cruise trajectories
	var m_active := state.mun_active
	var m_wid_arr := state.mun_weapon_id
	var m_tid_arr := state.mun_target_unit_id
	var m_tpos_arr := state.mun_target_pos
	var m_spos_arr := state.mun_start_pos
	var m_pos_arr := state.mun_pos
	var m_vel_arr := state.mun_vel
	var m_prog_arr := state.mun_flight_progress
	var m_dist_arr := state.mun_total_dist_km
	var m_apex_arr := state.mun_apex_alt_m
	var m_fac_arr := state.mun_faction
	var inv_dt := 1.0 / maxf(dt, 0.001)
	var b_in_flight := 0
	var r_in_flight := 0

	for mid in range(state.mun_count):
		if m_active[mid] == 0:
			continue
		var wid := m_wid_arr[mid]
		if wid <= 0 or wid >= max_wid:
			m_active[mid] = 0
			continue

		var m_fac := m_fac_arr[mid]
		if m_fac == WorldState.FACTION_BLUE:
			b_in_flight += 1
		else:
			r_in_flight += 1

		var tid := m_tid_arr[mid]
		if tid >= 0 and tid < n_units and u_active[tid] == 1:
			m_tpos_arr[mid] = u_pos[tid]

		var spd_mult: float = state.blue_missile_speed_mult if m_fac == WorldState.FACTION_BLUE else state.red_missile_speed_mult
		var speed_km_s := w_speed_km_s[wid] * spd_mult
		var total_dist := maxf(0.25, m_dist_arr[mid])
		var next_prog := m_prog_arr[mid] + (speed_km_s * dt) / total_dist

		var start_p := m_spos_arr[mid]
		var end_p := m_tpos_arr[mid]
		var clamped_t := clampf(next_prog, 0.0, 1.0)
		var x_km := lerpf(start_p.x, end_p.x, clamped_t)
		var z_km := lerpf(start_p.z, end_p.z, clamped_t)
		var base_alt := lerpf(start_p.y, end_p.y, clamped_t)
		var arc_boost := 4.0 * clamped_t * (1.0 - clamped_t) * maxf(0.0, m_apex_arr[mid] - maxf(start_p.y, end_p.y))
		# Authentic Cold/Hot Vertical SAM Launch Profile: Rockets vertically out of canister before pitching over
		var vert_boost := sin(clamped_t * (PI / 0.22)) * 1400.0 if (start_p.y <= 120.0 and clamped_t < 0.22) else 0.0
		var cur_pos := Vector3(x_km, base_alt + arc_boost + vert_boost, z_km)
		var prev_pos := m_pos_arr[mid]
		m_vel_arr[mid] = Vector3(
			(cur_pos.x - prev_pos.x) * inv_dt,
			((cur_pos.y - prev_pos.y) * 0.001) * inv_dt,
			(cur_pos.z - prev_pos.z) * inv_dt
		)
		m_pos_arr[mid] = cur_pos
		m_prog_arr[mid] = next_prog

		if next_prog >= 1.0:
			m_active[mid] = 0
			var dmg_mult: float = state.blue_warhead_damage_mult if m_fac == WorldState.FACTION_BLUE else state.red_warhead_damage_mult
			var pk_bon: float = state.blue_pk_bonus if m_fac == WorldState.FACTION_BLUE else state.red_pk_bonus
			var dmg := w_dmg[wid] * dmg_mult
			var base_pk := clampf(w_pk[wid] + pk_bon, 0.10, 0.99)

			if tid >= 0 and tid < n_units and u_active[tid] == 1:
				var roll := fmod(float((mid * 73 + state.tick_id * 31) % 100) * 0.01, 1.0)
				var effective_dmg := dmg if roll <= base_pk else dmg * 0.30
				_apply_damage_to_unit(state, sim_db, tid, effective_dmg)
			else:
				var enemy_fac := WorldState.FACTION_RED if m_fac_arr[mid] == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
				var splash_uid := grid.find_nearest_enemy_unit(state, enemy_fac, end_p.x, end_p.z, 3.0, 0)
				if splash_uid >= 0:
					_apply_damage_to_unit(state, sim_db, splash_uid, dmg * 0.7)

			if dmg >= 85.0:
				LogisticsSystemScript.crater_airbase_near(state, end_p, 16.0, 90.0)

			# Phase 11 Dynamic War Destruction: crater roads, collapse bridges/buildings, sever rails & char forests
			if dmg >= 15.0:
				state.inject_war_destruction(end_p.x, end_p.z, clampf(dmg * 0.14, 6.0, 18.0), clampf(dmg / 120.0, 0.25, 0.85))

			# Physical Civilian Density Field (civ/m^2) Blast Exposure & Evacuation Shockwave
			var civ_rho := state.sample_civilian_density_m2(end_p.x, end_p.z)
			if civ_rho > 0.0001:
				var blast_r_m := clampf(dmg * 1.35, 6.0, 140.0)
				var blast_area_m2 := PI * blast_r_m * blast_r_m
				var exposed_civs := blast_area_m2 * civ_rho
				state.estimated_civilian_casualties += exposed_civs * 0.18
				if exposed_civs >= 1.5:
					state.collateral_incidents_count += 1
				state.inject_civilian_combat_shock(end_p.x, end_p.z, 24.0, clampf(dmg / 40.0, 0.5, 2.5))

			state.recent_impacts.append({
				"pos_km": end_p,
				"radius_km": 3.5,
				"cost_musd": w_cost[wid],
				"is_intercept": false,
				"ttl": 2.2,
			})

	state.blue_munitions_in_flight = b_in_flight
	state.red_munitions_in_flight = r_in_flight


static func _apply_damage_to_unit(state: WorldState, sim_db: Node, uid: int, raw_damage: float) -> void:
	if uid < 0 or uid >= state.unit_count or state.unit_active[uid] == 0:
		return
	var pid := state.unit_platform_id[uid]
	var mitigation: float = sim_db.plat_armor_mitigation[pid] if (pid > 0 and pid < sim_db.plat_armor_mitigation.size()) else 0.85
	# Sprint 7: Fortified ambush entrenchment gives 40% damage reduction
	if uid < state.unit_posture.size() and state.unit_posture[uid] == WorldState.TACTICAL_POSTURE_HOLD_AMBUSH:
		mitigation *= 0.60
	var cover_mult := 1.0
	if pid > 0 and pid < sim_db.plat_domain_id.size() and sim_db.plat_domain_id[pid] == 0:
		var is_foot_or_dog: bool = (sim_db.plat_class_flags[pid] & int(sim_db.FLAG_CLIMB_SLOPES | sim_db.FLAG_INFANTRY | sim_db.FLAG_ROBOT_DOG)) != 0
		var up := state.unit_pos[uid]
		cover_mult = state.get_terrain_cover_damage_mult(up.x, up.z, is_foot_or_dog)
	var final_dmg := maxf(5.0, raw_damage * mitigation * cover_mult)

	state.unit_hp[uid] -= final_dmg
	# Sprint 7: Unit suppression accumulation under fire
	if uid < state.unit_suppression_level.size():
		state.unit_suppression_level[uid] = clampf(state.unit_suppression_level[uid] + 0.35, 0.0, 1.0)
	var unit_cost: float = sim_db.plat_cost_musd[pid] if (pid > 0 and pid < sim_db.plat_cost_musd.size()) else 10.0
	var max_hp := maxf(1.0, state.unit_max_hp[uid])
	var dmg_ratio := clampf(final_dmg / max_hp, 0.0, 1.0)
	# Cap tactical salvo loss-ledger attribution per company/element so supercarriers ($13B) don't instantly trigger theater defeat from a single salvo
	var capped_cost := minf(unit_cost, 120.0)
	var proportional_loss := capped_cost * dmg_ratio

	# Compute realistic personnel KIA & WIA from crew complement (0 for unmanned Robot Dogs / Drones!)
	var crew_comp: int = sim_db.plat_crew_complement[pid] if (pid > 0 and pid < sim_db.plat_crew_complement.size()) else 12
	var kia_delta: int = int(ceil(float(crew_comp) * dmg_ratio * 0.32)) if crew_comp > 0 else 0
	var wia_delta: int = int(ceil(float(crew_comp) * dmg_ratio * 0.58)) if crew_comp > 0 else 0

	var is_blue := (state.unit_faction[uid] == WorldState.FACTION_BLUE)
	if is_blue:
		state.blue_lost_musd += proportional_loss
		state.blue_personnel_kia += kia_delta
		state.blue_personnel_wia += wia_delta
	else:
		state.red_lost_musd += proportional_loss
		state.red_personnel_kia += kia_delta
		state.red_personnel_wia += wia_delta

	if state.unit_hp[uid] <= 0.0:
		state.unit_hp[uid] = 0.0
		state.unit_active[uid] = 0
		var dom_id: int = sim_db.plat_domain_id[pid] if (pid > 0 and pid < sim_db.plat_domain_id.size()) else 0
		var flg: int = sim_db.plat_class_flags[pid] if (pid > 0 and pid < sim_db.plat_class_flags.size()) else 0
		var is_unmanned: bool = (flg & int(sim_db.FLAG_UNMANNED | sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)) != 0
		if is_blue:
			state.blue_units_destroyed += 1
			if is_unmanned:
				state.blue_unmanned_lost += 1
			elif dom_id == 1:
				state.blue_aircraft_lost += 1
			elif dom_id == 2:
				state.blue_ships_lost += 1
			else:
				state.blue_armor_lost += 1
		else:
			state.red_units_destroyed += 1
			if is_unmanned:
				state.red_unmanned_lost += 1
			elif dom_id == 1:
				state.red_aircraft_lost += 1
			elif dom_id == 2:
				state.red_ships_lost += 1
			else:
				state.red_armor_lost += 1
		state.sim_events_queue.append({
			"type": "unit_destroyed",
			"unit_id": uid,
			"platform_id": pid,
			"faction": state.unit_faction[uid],
			"pos_km": state.unit_pos[uid],
			"unit_cost_musd": unit_cost,
		})
	else:
		state.sim_events_queue.append({
			"type": "unit_damaged",
			"unit_id": uid,
			"damage": final_dmg,
			"pos_km": state.unit_pos[uid],
			"cost_musd": proportional_loss,
		})

class_name StrategicMddSystem
extends RefCounted
## Phase 10 Multi-Domain Deterrence & Space/Cyber/PsyOp/Environmental Hazard System:
## 1. Global 3D Orbiting Space Force Constellation (LEO SAR Recon, Starshield SatCom, MEO GPS/PNT, SBIRS Early Warning)
## 2. Anti-Satellite (ASAT) Direct-Ascent Interceptors & Orbital Laser Dazzlers (`[7]`)
## 3. Offensive Cyber / Computer Network Operations (CNO) against IADS Radars & Drone C2 (`[8]`)
## 4. Cognitive / Psychological Warfare (Unit Morale Suppression & Humanitarian Civilian Evacuation Broadcasts) (`[9]`)
## 5. 2D Wind-Advected Environmental Hazard Plumes & CBRN MOPP-4 Sealed Protection (`[0]`)


const EARTH_RADIUS_KM := 6371.0
const EARTH_MU_KM3_S2 := 398600.44


static func seed_orbital_constellation(state: WorldState) -> void:
	state.sat_count = WorldState.MAX_SATELLITES
	if state.sat_speed_km_s.size() < state.sat_count:
		state.sat_speed_km_s.resize(WorldState.MAX_SATELLITES)
	for s in range(state.sat_count):
		var fac := WorldState.FACTION_BLUE if (s < 12) else WorldState.FACTION_RED
		var local_idx := s % 12
		var role := local_idx % 4 # 0=RECON_SAR (525km LEO), 1=SATCOM_LEO (550km Starshield), 2=PNT_GPS (20,200km MEO), 3=EARLY_WARN (1,200km SDA Tracking)
		state.sat_active[s] = 1
		state.sat_faction[s] = fac
		state.sat_role[s] = role
		state.sat_inclination_rad[s] = deg_to_rad(42.0 + float((local_idx * 17) % 52))
		state.sat_raan_rad[s] = float(local_idx) * (TAU / 12.0) + (0.25 if fac == WorldState.FACTION_RED else 0.0)
		state.sat_phase_rad[s] = float(local_idx) * (TAU / 6.0) + (0.6 if fac == WorldState.FACTION_RED else 0.0)

		var alt_km := 525.0
		if role == 1:
			alt_km = 550.0
		elif role == 2:
			alt_km = 20200.0
		elif role == 3:
			alt_km = 1200.0
		state.sat_alt_km[s] = alt_km

		# True Keplerian circular orbital velocity v = sqrt(mu / (R_earth + h)) in km/s (~7.59 km/s LEO, ~3.87 km/s MEO)
		var v_orb_km_s := sqrt(EARTH_MU_KM3_S2 / (EARTH_RADIUS_KM + alt_km))
		state.sat_speed_km_s[s] = v_orb_km_s
		# Angular rate so ground-track velocity across the 363 km theater projection equals true `v_orb_km_s` (7.59 km/s)
		state.sat_angular_vel[s] = v_orb_km_s / 363.0
		state.sat_dazzled_timer[s] = 0.0

	_update_satellite_positions_and_factors(state, 0.0)


static func _update_satellite_positions_and_factors(state: WorldState, dt: float) -> void:
	var blue_satcom_ok := 0
	var red_satcom_ok := 0
	var blue_pnt_ok := 0
	var red_pnt_ok := 0

	for s in range(state.sat_count):
		if state.sat_active[s] == 0:
			continue
		if state.sat_dazzled_timer[s] > 0.0:
			state.sat_dazzled_timer[s] = maxf(0.0, state.sat_dazzled_timer[s] - dt)

		var phase := wrapf(state.sat_phase_rad[s] + state.sat_angular_vel[s] * dt, 0.0, TAU)
		state.sat_phase_rad[s] = phase
		var inc := state.sat_inclination_rad[s]
		var raan := state.sat_raan_rad[s]
		var alt_km := state.sat_alt_km[s]

		# 3D Keplerian spherical orbital projection with true physical altitude in meters (`alt_km * 1000.0`)
		var orbit_radius_km := 1650.0
		var x_orb := orbit_radius_km * (cos(raan) * cos(phase) - sin(raan) * sin(phase) * cos(inc))
		var z_orb := orbit_radius_km * (sin(raan) * cos(phase) + cos(raan) * sin(phase) * cos(inc))
		var y_alt_m := alt_km * 1000.0
		state.sat_pos_km[s] = Vector3(x_orb * 0.22, y_alt_m, z_orb * 0.22)

		var is_operational := (state.sat_dazzled_timer[s] <= 0.0)
		if is_operational:
			var fac := state.sat_faction[s]
			var role := state.sat_role[s]
			if role == WorldState.SAT_ROLE_SATCOM_LEO:
				if fac == WorldState.FACTION_BLUE:
					blue_satcom_ok += 1
				else:
					red_satcom_ok += 1
			elif role == WorldState.SAT_ROLE_PNT_GPS:
				if fac == WorldState.FACTION_BLUE:
					blue_pnt_ok += 1
				else:
					red_pnt_ok += 1

	state.blue_satcom_factor = clampf(float(blue_satcom_ok) / 3.0, 0.20, 1.0)
	state.red_satcom_factor = clampf(float(red_satcom_ok) / 3.0, 0.20, 1.0)
	state.blue_pnt_factor = clampf(float(blue_pnt_ok) / 3.0, 0.25, 1.0)
	state.red_pnt_factor = clampf(float(red_pnt_ok) / 3.0, 0.25, 1.0)


static func step(state: WorldState, sim_db: Node, cs_kernel: Object, dt: float) -> void:
	if dt <= 0.0:
		return

	# 1. Propagate 3D Space Force Satellite Orbits & Overhead SAR Recon Passes
	_update_satellite_positions_and_factors(state, dt)

	for s in range(state.sat_count):
		if state.sat_active[s] == 0 or state.sat_dazzled_timer[s] > 0.0:
			continue
		if state.sat_role[s] == WorldState.SAT_ROLE_RECON_SAR:
			var spos := state.sat_pos_km[s]
			if absf(spos.x) <= 260.0 and absf(spos.z) <= 260.0:
				var s_fac := state.sat_faction[s]
				var det_bit := 1 if s_fac == WorldState.FACTION_BLUE else 2
				var swath_sq := 95.0 * 95.0
				for uid in range(state.unit_count):
					if state.unit_active[uid] == 1 and state.unit_faction[uid] != s_fac:
						var up := state.unit_pos[uid]
						var d_sq := (up.x - spos.x) * (up.x - spos.x) + (up.z - spos.z) * (up.z - spos.z)
						if d_sq <= swath_sq:
							state.unit_detected_mask[uid] |= det_bit

	# 2. Step 2D Wind-Advected Environmental Hazard Plume PDE via C# Multi-Threaded SIMD Kernel
	var g := WorldState.CIV_GRID_SIZE
	var total_cells := g * g
	if state.hazard_density.size() == total_cells:
		var cell_km := 500.0 / float(g - 1)
		var wx_cells := state.wind_vec_km_s.x / cell_km
		var wz_cells := state.wind_vec_km_s.y / cell_km
		if cs_kernel != null and cs_kernel.has_method("StepHazardPlumeFieldParallel"):
			var next_h: PackedFloat32Array = cs_kernel.call(
				"StepHazardPlumeFieldParallel",
				state.hazard_density,
				g,
				wx_cells,
				wz_cells,
				0.18,
				0.008,
				dt
			)
			if next_h.size() == total_cells:
				state.hazard_density = next_h

		var active_h := 0
		for i in range(total_cells):
			var h_val := state.hazard_density[i]
			if h_val > 0.02:
				active_h += 1
				# Civilian population flees drifting environmental hazard plumes
				state.civ_threat_field[i] = maxf(state.civ_threat_field[i], h_val * 2.8)
		state.active_hazard_cells_count = active_h

	# 3. Apply Cyber CNO Timers, Cognitive Morale Recovery & Environmental Hazard Attrition to Units
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var max_pid: int = p_dom.size()
	var flag_unmanned: int = int(sim_db.FLAG_UNMANNED | sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)
	var flag_armor: int = int(sim_db.FLAG_ARMOR)

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid := state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var flg := p_flags[pid]

		# A) Cyber CNO Intrusion Timer
		if state.unit_cyber_timer[uid] > 0.0:
			state.unit_cyber_timer[uid] = maxf(0.0, state.unit_cyber_timer[uid] - dt)
			state.unit_radar_active[uid] = 0
			state.unit_jammed[uid] = 1

		# B) Cognitive / Psychological Morale Recovery & Suppression
		if (flg & flag_unmanned) != 0:
			state.unit_morale[uid] = 1.0 # Autonomous AI Robot Dogs & Drones are immune to psychological suppression
		else:
			if state.unit_morale[uid] < 1.0:
				state.unit_morale[uid] = minf(1.0, state.unit_morale[uid] + 0.012 * dt)
			if state.unit_morale[uid] < 0.45:
				state.unit_ai_state[uid] = WorldState.AI_EVASIVE_DEFENSIVE
				state.unit_cooldown[uid] = maxf(state.unit_cooldown[uid], 2.5)

		# C) Environmental Hazard Plume Exposure on Land Units
		if state.active_hazard_cells_count > 0 and p_dom[pid] == 0 and (flg & flag_unmanned) == 0:
			var up := state.unit_pos[uid]
			var h_intensity := state.sample_hazard_density(up.x, up.z)
			if h_intensity > 0.05:
				var is_sealed := (state.unit_cbrn_mopp[uid] == 1) or ((flg & flag_armor) != 0)
				var protection := 0.12 if is_sealed else 1.0
				var h_dmg := h_intensity * 6.5 * protection * dt
				state.unit_hp[uid] = maxf(5.0, state.unit_hp[uid] - h_dmg)
				if not is_sealed:
					state.unit_morale[uid] = maxf(0.20, state.unit_morale[uid] - 0.15 * dt)


## [7] Launches an ASAT Interceptor / High-Energy Orbital Dazzler against the nearest overhead hostile satellite
static func execute_asat_strike(state: WorldState, faction: int, focus_xz: Vector2) -> int:
	var best_sat := -1
	var best_dist_sq := 1e12
	for s in range(state.sat_count):
		if state.sat_active[s] == 1 and state.sat_faction[s] != faction and state.sat_dazzled_timer[s] <= 5.0:
			var sp := state.sat_pos_km[s]
			var d_sq := (sp.x - focus_xz.x) * (sp.x - focus_xz.x) + (sp.z - focus_xz.y) * (sp.z - focus_xz.y)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_sat = s

	if best_sat < 0:
		return 0

	# Find a friendly launcher/emitter to fire the upward ASAT interceptor / dazzler beam
	var shooter_pos := Vector3(focus_xz.x, 100.0, focus_xz.y)
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			shooter_pos = state.unit_pos[uid]
			break

	state.sat_dazzled_timer[best_sat] = 45.0
	state.asat_intercepts_count += 1
	var sat_pos := state.sat_pos_km[best_sat]
	state.active_beams.append({
		"shooter_pos": shooter_pos,
		"target_pos": sat_pos,
		"is_hpm_cone": false,
		"cone_deg": 0.0,
		"faction": faction,
		"ttl": 2.4,
	})
	state.recent_impacts.append({
		"pos_km": sat_pos,
		"radius_km": 8.0,
		"cost_musd": 150.0,
		"is_intercept": true,
		"ttl": 2.5,
	})
	return 1


## [7B] US-11.2: Launches a Direct-Ascent Kinetic ASAT Interceptor (SM-3 Block IIA / Nudol) physically destroying an enemy satellite
static func execute_counter_space_kinetic_asat(state: WorldState, faction: int, focus_xz: Vector2) -> Dictionary:
	var best_sat := -1
	var best_dist_sq := 1e12
	for s in range(state.sat_count):
		if state.sat_active[s] == 1 and state.sat_faction[s] != faction:
			var sp := state.sat_pos_km[s]
			var d_sq := (sp.x - focus_xz.x) * (sp.x - focus_xz.x) + (sp.z - focus_xz.y) * (sp.z - focus_xz.y)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_sat = s

	if best_sat < 0:
		return {"success": false, "reason": "No active enemy satellite in orbital engagement range"}

	var shooter_pos := Vector3(focus_xz.x, 100.0, focus_xz.y)
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			shooter_pos = state.unit_pos[uid]
			break

	var sat_pos := state.sat_pos_km[best_sat]
	var role: int = state.sat_role[best_sat]
	var enemy_fac: int = state.sat_faction[best_sat]

	# Physically destroy the satellite
	state.sat_active[best_sat] = 0
	state.asat_intercepts_count += 1

	state.active_beams.append({
		"shooter_pos": shooter_pos,
		"target_pos": sat_pos,
		"is_hpm_cone": false,
		"cone_deg": 0.0,
		"faction": faction,
		"ttl": 3.0,
	})
	state.recent_impacts.append({
		"pos_km": sat_pos,
		"radius_km": 25.0,
		"cost_musd": 350.0,
		"is_intercept": true,
		"is_kinetic_asat": true,
		"ttl": 4.0,
	})

	# Recalculate degraded C4ISR / SATCOM / PNT factors
	_update_satellite_positions_and_factors(state, 0.0)

	state.sim_events_queue.append({
		"type": "KINETIC_ASAT_DESTROYED_SATELLITE",
		"sat_id": best_sat,
		"role": role,
		"enemy_faction": enemy_fac,
		"pos_km": sat_pos,
		"shooter_faction": faction
	})

	return {
		"success": true,
		"destroyed_sat_id": best_sat,
		"sat_role": role,
		"enemy_faction": enemy_fac,
		"blue_satcom_factor": state.blue_satcom_factor,
		"red_satcom_factor": state.red_satcom_factor,
		"blue_pnt_factor": state.blue_pnt_factor,
		"red_pnt_factor": state.red_pnt_factor,
	}


## [8] Launches an Offensive Cyber CNO Strike against enemy IADS radars & C2 nodes in the sector
static func execute_cyber_cno_strike(state: WorldState, sim_db: Node, faction: int, target_xz: Vector2, radius_km: float = 110.0) -> int:
	var affected := 0
	var rad_sq := radius_km * radius_km
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var max_pid: int = p_flags.size()

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] != faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var up := state.unit_pos[uid]
			var d_sq := (up.x - target_xz.x) * (up.x - target_xz.x) + (up.z - target_xz.y) * (up.z - target_xz.y)
			if d_sq <= rad_sq:
				var pid := state.unit_platform_id[uid]
				if pid > 0 and pid < max_pid:
					state.unit_cyber_timer[uid] = 32.0
					state.unit_radar_active[uid] = 0
					state.unit_jammed[uid] = 1
					affected += 1

	state.cyber_strikes_count += 1
	state.inject_civilian_combat_shock(target_xz.x, target_xz.y, 28.0, 1.4)
	return maxi(1, affected)


## [9] Broadcasts Cognitive PsyOp Suppression & Humanitarian Civilian Evacuation Orders into a sector
static func execute_psyop_evac_broadcast(state: WorldState, sim_db: Node, faction: int, target_xz: Vector2, radius_km: float = 95.0) -> int:
	var affected := 0
	var rad_sq := radius_km * radius_km
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var flag_unmanned: int = int(sim_db.FLAG_UNMANNED | sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)
	var max_pid: int = p_flags.size()

	# 1. Accelerate civilian evacuation out of target city before kinetic strikes
	state.inject_civilian_combat_shock(target_xz.x, target_xz.y, radius_km * 0.45, 2.6)

	# 2. Suppress enemy human unit morale in sector (autonomous robot dogs are immune)
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] != faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var up := state.unit_pos[uid]
			var d_sq := (up.x - target_xz.x) * (up.x - target_xz.x) + (up.z - target_xz.y) * (up.z - target_xz.y)
			if d_sq <= rad_sq:
				var pid := state.unit_platform_id[uid]
				if pid > 0 and pid < max_pid and (p_flags[pid] & flag_unmanned) == 0:
					state.unit_morale[uid] = maxf(0.22, state.unit_morale[uid] - 0.42)
					state.unit_ai_state[uid] = WorldState.AI_EVASIVE_DEFENSIVE
					affected += 1

	state.psyop_broadcasts_count += 1
	return maxi(1, affected)


## [0] Toggles CBRN MOPP-4 Sealed Protection on friendly units & optionally deploys a Wind-Advected Hazard Plume
static func execute_cbrn_mopp_and_hazard(state: WorldState, faction: int, target_xz: Vector2, deploy_plume: bool = true) -> int:
	var toggled := 0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			state.unit_cbrn_mopp[uid] = 1 if state.unit_cbrn_mopp[uid] == 0 else 0
			toggled += 1

	if deploy_plume:
		state.inject_hazard_plume(target_xz.x, target_xz.y, 26.0, 0.92)
	return maxi(1, toggled)

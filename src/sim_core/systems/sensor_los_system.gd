class_name SensorLoSSystem
extends RefCounted
## Implements authentic Radar Horizon equation, 8-step terrain heightmap raymarching with
## High-Altitude Ceiling O(1) Short-Circuit, and Pre-Compiled Fourth-Root Radar Cross Section (RCS) LUTs:
##   EffectiveRangeKm = BaseRadarRangeKm * pow(TargetRCS_m2 / 5.0, 0.25)
## Also generates the `fow_threat_map` Image (R = Blue Radar LoS, G = Red SAM Threat).

const SENSOR_ACTIVE_RADAR := 0
const SENSOR_PASSIVE_ESM := 1
const SENSOR_IR_EO := 2
const SENSOR_LIDAR_CV := 3
const SENSOR_ACOUSTIC_SONAR := 4
const SENSOR_SAT_SAR_EO := 5
const FLAG_SAM := 1 << 0
const FLAG_SEAD := 1 << 2
const FLAG_AWACS := 1 << 3
const FLAG_EW_JAMMER := 1 << 6
const FLAG_RF_DATALINK := 1 << 14
const FLAG_UUV_SUB := 1 << 17


## Fourth-root radar range scaling against non-standard RCS targets (reference = 5.0 m^2).
static func compute_effective_detection_range_km(base_range_km: float, target_rcs_m2: float) -> float:
	var clamped_rcs := maxf(target_rcs_m2, 0.00005)
	return base_range_km * pow(clamped_rcs / 5.0, 0.25)


## Radar Horizon in kilometers due to Earth curvature: 4.12 * (sqrt(h1_m) + sqrt(h2_m))
static func compute_radar_horizon_km(radar_alt_m: float, target_alt_m: float) -> float:
	var h1 := maxf(2.0, radar_alt_m)
	var h2 := maxf(2.0, target_alt_m)
	return 4.12 * (sqrt(h1) + sqrt(h2))


## Checks both Earth radar horizon and adaptive-step terrain heightmap raymarch between observer and target.
## When `allow_valley_diffraction` is true (Acoustic & Sonar sensors), sound waves diffract over valley ridges up to +450m.
static func has_radar_los(state: WorldState, observer_pos: Vector3, target_pos: Vector3, allow_valley_diffraction: bool = false, is_submerged_uuv: bool = false, precalc_dist_km: float = -1.0, skip_horizon_calc: bool = false) -> bool:
	var dx := observer_pos.x - target_pos.x
	var dz := observer_pos.z - target_pos.z
	var dist_km := precalc_dist_km if precalc_dist_km >= 0.0 else sqrt(dx * dx + dz * dz)
	if not skip_horizon_calc:
		var max_horizon_km := compute_radar_horizon_km(observer_pos.y, target_pos.y)
		if not allow_valley_diffraction and dist_km > max_horizon_km:
			return false

	if is_submerged_uuv:
		return true

	# O(1) High-Altitude Ceiling Short-Circuit: if both endpoints are above max mountain height (3800m),
	# the straight ray can never intersect the terrain heightmap!
	if observer_pos.y > 3820.0 and target_pos.y > 3820.0:
		return true

	var h_arr := state.heightmap_elev_m
	if h_arr.is_empty():
		return true
	var h_sz := state.heightmap_size
	var inv_sz := float(h_sz - 1) / 500.0
	var ridge_tol_m := 450.0 if allow_valley_diffraction else 15.0

	# Adaptive raymarching steps: 2 intermediate samples for close-range (<8km), 4 for medium (<30km), 7 for long range
	var num_steps := 3 if dist_km < 8.0 else (5 if dist_km < 30.0 else 8)
	var inv_steps := 1.0 / float(num_steps)

	for s in range(1, num_steps):
		var t := float(s) * inv_steps
		var ray_alt_m := lerpf(observer_pos.y, target_pos.y, t)
		if ray_alt_m > 3820.0:
			continue
		var sample_x := lerpf(observer_pos.x, target_pos.x, t)
		var sample_z := lerpf(observer_pos.z, target_pos.z, t)
		var ix := clampi(int((sample_x + 250.0) * inv_sz), 0, h_sz - 1)
		var iy := clampi(int((sample_z + 250.0) * inv_sz), 0, h_sz - 1)
		var terrain_alt_m := h_arr[iy * h_sz + ix]
		if terrain_alt_m > ray_alt_m + ridge_tol_m:
			return false
	return true



## Evaluates the 6-Spectrum Sensor Fusion Matrix between a specific observer unit and target unit.
## Returns `{detected: bool, eff_range_km: float, dist_km: float, spectrum: String, allow_diffraction: bool}`
static func evaluate_pair_detection_spectrum(state: WorldState, sim_db: Node, obs_uid: int, target_uid: int) -> Dictionary:
	var obs_pid: int = state.unit_platform_id[obs_uid]
	var t_pid: int = state.unit_platform_id[target_uid]
	var obs_pos: Vector3 = state.unit_pos[obs_uid]
	var t_pos: Vector3 = state.unit_pos[target_uid]
	var obs_fac: int = state.unit_faction[obs_uid]
	var t_fac: int = state.unit_faction[target_uid]
	var radar_mult: float = state.blue_radar_range_mult if obs_fac == WorldState.FACTION_BLUE else state.red_radar_range_mult
	var rcs_tech_mult: float = pow(maxf(0.1, state.blue_rcs_mult if t_fac == WorldState.FACTION_BLUE else state.red_rcs_mult), 0.25)
	var base_r: float = sim_db.plat_sensor_range_km[obs_pid] * radar_mult
	var obs_stype: int = sim_db.plat_sensor_type_id[obs_pid]
	var obs_has_esm: int = sim_db.plat_has_passive_esm[obs_pid]
	var obs_rad_on: bool = state.unit_radar_active[obs_uid] == 1

	var rcs_factor: float = sim_db.plat_rcs_factor[t_pid] * rcs_tech_mult
	var ir_factor: float = sim_db.plat_ir_factor[t_pid]
	var ac_factor: float = sim_db.plat_acoustic_factor[t_pid]
	var t_flags: int = sim_db.plat_class_flags[t_pid]
	var is_submerged_uuv: bool = (t_flags & FLAG_UUV_SUB) != 0
	var t_stype: int = sim_db.plat_sensor_type_id[t_pid]
	var target_emitting_radar: bool = (state.unit_radar_active[target_uid] == 1 and t_stype == SENSOR_ACTIVE_RADAR)
	var target_emitting_rf_link: bool = (t_flags & FLAG_RF_DATALINK) != 0
	var target_radar_range: float = sim_db.plat_sensor_range_km[t_pid]
	var target_afterburner: bool = state.unit_afterburner[target_uid] == 1

	var eff_r: float = 0.0
	var allow_diffraction: bool = false
	var spectrum_label: String = "NONE"

	# 1. ACTIVE RADAR (Spectrum 0)
	if obs_stype == SENSOR_ACTIVE_RADAR and obs_rad_on and not is_submerged_uuv:
		eff_r = base_r * rcs_factor
		spectrum_label = "ACTIVE_RADAR"
	# 2. IR / ELECTRO-OPTICAL IRST & FLIR (Spectrum 2: attenuated by cloud cover, typhoon rain, or sandstorms)
	elif obs_stype == SENSOR_IR_EO and not is_submerged_uuv:
		var plume_mult := 1.85 if target_afterburner else 1.0
		eff_r = base_r * ir_factor * plume_mult * state.weather_ir_eo_mult
		spectrum_label = "IR_EO"
	# 3. 3D LIDAR & COMPUTER VISION (Spectrum 3: Quadruped Robot Dogs & Autonomous UGVs)
	elif obs_stype == SENSOR_LIDAR_CV and not is_submerged_uuv:
		eff_r = base_r * maxf(0.55, state.weather_ir_eo_mult)
		spectrum_label = "LIDAR_CV"
	# 4. ACOUSTIC & SONAR (Spectrum 4: C-UAS Valley Acoustic Array & Naval Towed Sonar)
	elif obs_stype == SENSOR_ACOUSTIC_SONAR:
		if is_submerged_uuv or t_pos.y <= 25.0 or base_r >= 30.0:
			eff_r = base_r * ac_factor
			allow_diffraction = true
			spectrum_label = "ACOUSTIC_SONAR"
		elif t_pos.y <= 3800.0:
			eff_r = base_r * ac_factor
			allow_diffraction = true
			spectrum_label = "ACOUSTIC_SONAR"
	# 5. ORBITAL SAT_SAR_EO (Spectrum 5)
	elif obs_stype == SENSOR_SAT_SAR_EO and not is_submerged_uuv:
		eff_r = base_r
		spectrum_label = "SAT_SAR_EO"

	# 6. PASSIVE ESM / ELINT TRIANGULATION (Spectrum 1: 1.6x range vs active radar emitters!)
	if (obs_stype == SENSOR_PASSIVE_ESM or obs_has_esm == 1) and not is_submerged_uuv:
		if target_emitting_radar:
			var esm_range := maxf(base_r * 1.15, target_radar_range * 1.60)
			if esm_range > eff_r:
				eff_r = esm_range
				spectrum_label = "PASSIVE_ESM"
		elif target_emitting_rf_link:
			var rf_link_range := minf(maxf(base_r, 35.0), 55.0)
			if rf_link_range > eff_r:
				eff_r = rf_link_range
				spectrum_label = "PASSIVE_ESM"

	var dx := obs_pos.x - t_pos.x
	var dz := obs_pos.z - t_pos.z
	var dist_km := sqrt(dx * dx + dz * dz)
	var detected := false
	if eff_r > 0.05 and dist_km <= eff_r:
		detected = has_radar_los(state, obs_pos, t_pos, allow_diffraction, is_submerged_uuv)

	return {
		"detected": detected,
		"eff_range_km": eff_r,
		"dist_km": dist_km,
		"spectrum": spectrum_label,
		"allow_diffraction": allow_diffraction,
	}


static func step(state: WorldState, sim_db: Node, grid: SpatialHashGrid, cs_kernel: Object = null) -> void:
	if cs_kernel != null and cs_kernel.has_method("StepSensorDetectionParallel"):
		var det_out: PackedByteArray = cs_kernel.call(
			"StepSensorDetectionParallel",
			state.unit_pos,
			state.unit_active,
			state.unit_echelon,
			state.unit_faction,
			state.unit_platform_id,
			state.unit_radar_active,
			state.unit_afterburner,
			state.unit_detected_mask,
			state.unit_sim_lod,
			sim_db.plat_sensor_type_id,
			sim_db.plat_has_passive_esm,
			sim_db.plat_sensor_range_km,
			sim_db.plat_rcs_factor,
			sim_db.plat_ir_factor,
			sim_db.plat_acoustic_factor,
			sim_db.plat_class_flags,
			state.heightmap_elev_m,
			state.heightmap_size,
			state.unit_count,
			state.tick_id
		)
		if det_out.size() >= state.unit_count:
			for u in range(state.unit_count):
				state.unit_detected_mask[u] = det_out[u]
			return

	var p_stype: PackedByteArray = sim_db.plat_sensor_type_id
	var p_has_esm: PackedByteArray = sim_db.plat_has_passive_esm
	var p_sensor_rng: PackedFloat32Array = sim_db.plat_sensor_range_km
	var p_rcs_fac: PackedFloat32Array = sim_db.plat_rcs_factor
	var p_ir_fac: PackedFloat32Array = sim_db.plat_ir_factor
	var p_ac_fac: PackedFloat32Array = sim_db.plat_acoustic_factor
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var max_pid: int = p_sensor_rng.size()


	var u_active := state.unit_active
	var u_ech := state.unit_echelon
	var u_fac := state.unit_faction
	var u_pid := state.unit_platform_id
	var u_rad_act := state.unit_radar_active
	var u_ab := state.unit_afterburner
	var u_pos := state.unit_pos
	var u_det := state.unit_detected_mask
	var u_lod := state.unit_sim_lod
	var has_lod := u_lod.size() >= state.unit_count
	var n_units := state.unit_count
	var tick := state.tick_id

	var blue_air_obs := PackedInt32Array()
	var blue_surf_obs := PackedInt32Array()
	var red_air_obs := PackedInt32Array()
	var red_surf_obs := PackedInt32Array()
	var blue_emitters := PackedInt32Array()
	var red_emitters := PackedInt32Array()
	var scanned_parent_groups := {}

	# Initialize friendly detection mask for all units and collect observers + active emitters
	for uid in range(n_units):
		if u_active[uid] == 0:
			continue
		var fac := u_fac[uid]
		u_det[uid] = (1 if fac == WorldState.FACTION_BLUE else 2)
		if u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid := u_pid[uid]
		if pid <= 0 or pid >= max_pid:
			continue

		var stype := p_stype[pid]
		var has_esm := p_has_esm[pid]
		var has_radar_hardware := (stype == SENSOR_ACTIVE_RADAR)
		var rad_on := (u_rad_act[uid] == 1 and has_radar_hardware)
		var t_flags: int = p_flags[pid]
		var is_rf: bool = (t_flags & FLAG_RF_DATALINK) != 0

		if rad_on or is_rf:
			if fac == WorldState.FACTION_BLUE:
				blue_emitters.append(uid)
			else:
				red_emitters.append(uid)

		# Filter theater sensor observers: Air platforms, SAM / IADS / EW batteries,
		# major naval combatants with radar/SAM suites, or platforms with active radar currently radiating.
		# Ground line infantry, armor platoons, and supply trucks rely on the shared C4ISR network.
		var dom_id := p_dom[pid]
		var is_theater_sensor := rad_on or (dom_id == 1) or ((t_flags & (FLAG_SAM | FLAG_AWACS | FLAG_SEAD | FLAG_EW_JAMMER)) != 0)
		if not is_theater_sensor:
			continue

		# Group-level radar deconfliction: Only 1 sensor observer per parent battalion/flight/flotilla
		# scans the sector. Battery launchers/wingmen/platoons share the shared C4ISR datalink.
		var par_id := state.unit_parent_id[uid]
		if par_id >= 0:
			var group_key: int = (fac << 24) | par_id
			if scanned_parent_groups.has(group_key):
				continue
			scanned_parent_groups[group_key] = true

		var is_air_sat := (dom_id == 1) or (stype == SENSOR_SAT_SAR_EO)
		if fac == WorldState.FACTION_BLUE:
			if is_air_sat:
				blue_air_obs.append(uid)
			else:
				blue_surf_obs.append(uid)
		else:
			if is_air_sat:
				red_air_obs.append(uid)
			else:
				red_surf_obs.append(uid)

	# High-altitude observers execute first to populate u_det, enabling O(1) skip for surface observers
	var blue_obs_uids := PackedInt32Array()
	blue_obs_uids.append_array(blue_air_obs)
	blue_obs_uids.append_array(blue_surf_obs)

	var red_obs_uids := PackedInt32Array()
	red_obs_uids.append_array(red_air_obs)
	red_obs_uids.append_array(red_surf_obs)


	# Alternate faction scans across ticks: Blue on even ticks, Red on odd ticks (both on initial tick 0)
	var do_blue := (tick == 0) or ((tick & 1) == 0)
	var do_red := (tick == 0) or ((tick & 1) == 1)

	# Process Blue Observers detecting Red targets
	if do_blue:
		var blue_rad_mult: float = state.blue_radar_range_mult
		var red_rcs_tech_mult: float = pow(maxf(0.1, state.red_rcs_mult), 0.25)
		_detect_enemies_spatial(
			state, grid, blue_obs_uids, red_emitters, WorldState.FACTION_RED, 1,
			blue_rad_mult, red_rcs_tech_mult,
			p_stype, p_has_esm, p_sensor_rng, p_rcs_fac, p_ir_fac, p_ac_fac, p_flags, max_pid,
			u_active, u_ech, u_pid, u_rad_act, u_ab, u_pos, u_det, u_lod, has_lod, tick
		)

	# Process Red Observers detecting Blue targets
	if do_red:
		var red_rad_mult: float = state.red_radar_range_mult
		var blue_rcs_tech_mult: float = pow(maxf(0.1, state.blue_rcs_mult), 0.25)
		_detect_enemies_spatial(
			state, grid, red_obs_uids, blue_emitters, WorldState.FACTION_BLUE, 2,
			red_rad_mult, blue_rcs_tech_mult,
			p_stype, p_has_esm, p_sensor_rng, p_rcs_fac, p_ir_fac, p_ac_fac, p_flags, max_pid,
			u_active, u_ech, u_pid, u_rad_act, u_ab, u_pos, u_det, u_lod, has_lod, tick
		)



static func _detect_enemies_spatial(
	state: WorldState,
	grid: SpatialHashGrid,
	obs_uids: PackedInt32Array,
	enemy_emitters: PackedInt32Array,
	enemy_faction: int,
	detect_bit: int,
	obs_rad_mult: float,
	t_rcs_tech_mult: float,
	p_stype: PackedByteArray,
	p_has_esm: PackedByteArray,
	p_sensor_rng: PackedFloat32Array,
	p_rcs_fac: PackedFloat32Array,
	p_ir_fac: PackedFloat32Array,
	p_ac_fac: PackedFloat32Array,
	p_flags: PackedInt32Array,
	max_pid: int,
	u_active: PackedByteArray,
	u_ech: PackedByteArray,
	u_pid: PackedInt32Array,
	u_rad_act: PackedByteArray,
	u_ab: PackedByteArray,
	u_pos: PackedVector3Array,
	u_det: PackedByteArray,
	u_lod: PackedByteArray,
	has_lod: bool,
	tick: int
) -> void:
	if grid == null:
		return

	var n_obs := obs_uids.size()
	var n_emitters := enemy_emitters.size()
	var total_cands := 0
	var total_los_calls := 0
	var t_start_grp := Time.get_ticks_usec()


	for i in range(n_obs):
		var obs_uid := obs_uids[i]
		var obs_pid := u_pid[obs_uid]
		var obs_pos := u_pos[obs_uid]
		var base_r := p_sensor_rng[obs_pid] * obs_rad_mult
		var obs_stype := p_stype[obs_pid]
		var obs_has_esm := p_has_esm[obs_pid]
		var obs_rad_on := u_rad_act[obs_uid] == 1

		# Alternating tick stagger for all sensor observers when tick > 0 (2.5 Hz scan cycle, cuts work in half)
		if tick > 0 and ((obs_uid + (tick >> 1)) & 1) != 0:
			continue

		# Stagger short-range ground optical observers (base_r <= 15km) by LOD tier
		if base_r <= 15.0 and tick > 0:
			var obs_lod: int = u_lod[obs_uid] if has_lod else WorldState.LOD_TIER_0_MICRO
			if obs_lod == WorldState.LOD_TIER_2_MACRO:
				if ((tick + obs_uid) & 7) != 0:
					continue
			elif obs_lod == WorldState.LOD_TIER_1_OPERATIONAL:
				if ((tick + obs_uid) & 3) != 0:
					continue
			elif ((tick + obs_uid) & 1) != 0:
				continue

		var obs_horiz_part := 4.12 * sqrt(maxf(2.0, obs_pos.y))

		# 1. Physical Direct Sensor Detection (Active Radar, IR/EO, Sonar, LIDAR)
		# Search radius is bounded by physical sensor reach
		var physical_max_r := 0.0
		if obs_stype == SENSOR_ACTIVE_RADAR and obs_rad_on:
			physical_max_r = base_r * 1.85 * t_rcs_tech_mult
		elif obs_stype == SENSOR_IR_EO:
			physical_max_r = base_r * 1.85
		elif obs_stype == SENSOR_LIDAR_CV:
			physical_max_r = base_r
		elif obs_stype == SENSOR_ACOUSTIC_SONAR:
			physical_max_r = base_r * 1.5
		elif obs_stype == SENSOR_SAT_SAR_EO:
			physical_max_r = base_r

		# Cap query radius by horizon geometry: surface radar cannot see beyond 160 km; high altitude capped at 260 km
		if obs_pos.y < 500.0:
			physical_max_r = minf(physical_max_r, 160.0)
		else:
			physical_max_r = minf(physical_max_r, 260.0)

		# Distribute long-range radar scans across 4 ticks (2.5 Hz update, prevents micro-stutters)
		if base_r > 50.0 and tick > 0 and ((obs_uid + tick) & 3) != 0:
			continue

		if physical_max_r > 0.1:
			var cand_cnt := grid.query_enemy_units_into_scratch(enemy_faction, obs_pos.x, obs_pos.z, physical_max_r)
			var scratch := grid.scratch_uids
			for c_i in range(cand_cnt):
				var target_uid := scratch[c_i]
				# O(1) Short-circuit: already detected by this faction
				if (u_det[target_uid] & detect_bit) != 0:
					continue
				if u_active[target_uid] == 0 or u_ech[target_uid] != WorldState.ECHELON_COMPANY:
					continue

				var lod_tier: int = u_lod[target_uid] if has_lod else WorldState.LOD_TIER_0_MICRO
				if tick > 0:
					if lod_tier == WorldState.LOD_TIER_2_MACRO and ((tick + target_uid) & 3) != 0:
						continue
					elif lod_tier == WorldState.LOD_TIER_1_OPERATIONAL and ((tick + target_uid) & 1) != 0:
						continue

				var t_pid := u_pid[target_uid]
				if t_pid <= 0 or t_pid >= max_pid:
					continue

				var t_pos := u_pos[target_uid]
				var dx := obs_pos.x - t_pos.x
				var dz := obs_pos.z - t_pos.z
				var dist_sq := dx * dx + dz * dz

				# O(1) Earth Curvature Horizon: Surface/sea observer <= 60m cannot see ground target <= 30m beyond 48 km
				if obs_pos.y <= 60.0 and t_pos.y <= 30.0 and dist_sq > 2304.0:
					continue

				var t_flags: int = p_flags[t_pid]

				var is_submerged_uuv: bool = (t_flags & FLAG_UUV_SUB) != 0
				var eff_r := 0.0
				var allow_diffraction := false

				if obs_stype == SENSOR_ACTIVE_RADAR and obs_rad_on and not is_submerged_uuv:
					eff_r = base_r * p_rcs_fac[t_pid] * t_rcs_tech_mult
				elif obs_stype == SENSOR_IR_EO and not is_submerged_uuv:
					eff_r = base_r * p_ir_fac[t_pid] * (1.85 if u_ab[target_uid] == 1 else 1.0)
				elif obs_stype == SENSOR_LIDAR_CV and not is_submerged_uuv:
					eff_r = base_r
				elif obs_stype == SENSOR_ACOUSTIC_SONAR:
					if is_submerged_uuv or t_pos.y <= 25.0 or base_r >= 30.0 or t_pos.y <= 3800.0:
						eff_r = base_r * p_ac_fac[t_pid]
						allow_diffraction = true
				elif obs_stype == SENSOR_SAT_SAR_EO and not is_submerged_uuv:
					eff_r = base_r

				if eff_r <= 0.05 or dist_sq > eff_r * eff_r:
					continue

				if not allow_diffraction and dist_sq > 2304.0:
					var max_horiz := obs_horiz_part + 4.12 * sqrt(maxf(2.0, t_pos.y))
					if dist_sq > max_horiz * max_horiz:
						continue

				total_los_calls += 1
				var d_km := sqrt(dist_sq)
				if has_radar_los(state, obs_pos, t_pos, allow_diffraction, is_submerged_uuv, d_km, true):
					u_det[target_uid] |= detect_bit


		# 2. Passive ESM Triangulation against active enemy radar/RF emitters ONLY
		if (obs_stype == SENSOR_PASSIVE_ESM or obs_has_esm == 1) and n_emitters > 0:
			for em_i in range(n_emitters):
				var target_uid := enemy_emitters[em_i]
				if (u_det[target_uid] & detect_bit) != 0:
					continue
				if u_active[target_uid] == 0:
					continue
				var t_pid := u_pid[target_uid]
				if t_pid <= 0 or t_pid >= max_pid:
					continue

				var t_pos := u_pos[target_uid]
				var dx := obs_pos.x - t_pos.x
				var dz := obs_pos.z - t_pos.z
				var dist_sq := dx * dx + dz * dz

				var t_flags: int = p_flags[t_pid]
				var is_submerged_uuv: bool = (t_flags & FLAG_UUV_SUB) != 0
				if is_submerged_uuv:
					continue

				var t_stype: int = p_stype[t_pid]
				var target_emitting_radar: bool = (u_rad_act[target_uid] == 1 and t_stype == SENSOR_ACTIVE_RADAR)
				var target_emitting_rf: bool = (t_flags & FLAG_RF_DATALINK) != 0
				var esm_eff_r := 0.0
				if target_emitting_radar:
					esm_eff_r = maxf(base_r * 1.15, p_sensor_rng[t_pid] * 1.60)
				elif target_emitting_rf:
					esm_eff_r = minf(maxf(base_r, 35.0), 55.0)

				if esm_eff_r <= 0.05 or dist_sq > esm_eff_r * esm_eff_r:
					continue
				total_los_calls += 1
				if has_radar_los(state, obs_pos, t_pos, false, false):
					u_det[target_uid] |= detect_bit







## Generates a compact RGBA8 Image representing:
## R = Blue Radar Coverage, G = Red SAM Threat Domes, B = Spreading Civilian Density (civ/m^2), A = Evacuation Flux
static func build_fow_threat_image(state: WorldState, sim_db: Node, tex_size: int = 128) -> Image:
	var p_sensor_rng: PackedFloat32Array = sim_db.plat_sensor_range_km
	var max_pid: int = p_sensor_rng.size()

	var em_x := PackedFloat32Array()
	var em_z := PackedFloat32Array()
	var em_r := PackedFloat32Array()
	var em_fac := PackedByteArray()

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		if state.unit_radar_active[uid] == 0:
			continue
		var pid := state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var r_km := p_sensor_rng[pid]
		if r_km < 140.0:
			continue
		em_x.append(state.unit_pos[uid].x)
		em_z.append(state.unit_pos[uid].z)
		em_r.append(minf(r_km * 0.55, 140.0))
		em_fac.append(state.unit_faction[uid])
		if em_x.size() >= 28:
			break

	var n_em := em_x.size()
	var buf := PackedByteArray()
	buf.resize(tex_size * tex_size * 4)
	var idx := 0
	var inv_size := 500.0 / float(max(1, tex_size - 1))
	var civ_g := WorldState.CIV_GRID_SIZE
	var has_civ := state.civ_density_m2.size() == civ_g * civ_g

	for py in range(tex_size):
		var z_km := float(py) * inv_size - 250.0
		var cy := clampi(int(float(py) * float(civ_g - 1) / float(max(1, tex_size - 1))), 0, civ_g - 1)
		for px in range(tex_size):
			var x_km := float(px) * inv_size - 250.0
			var blue_cov := 0.08
			var red_threat := 0.0
			for i in range(n_em):
				var dx := x_km - em_x[i]
				var dz := z_km - em_z[i]
				var rad := em_r[i]
				var d_sq := dx * dx + dz * dz
				if d_sq < rad * rad:
					var d := sqrt(d_sq)
					var falloff := 1.0 - (d / rad)
					var ring := 0.45 if absf(d - rad * 0.92) < 5.0 else 0.0
					if em_fac[i] == WorldState.FACTION_BLUE:
						blue_cov = maxf(blue_cov, falloff * 0.75 + ring)
					else:
						red_threat = maxf(red_threat, falloff * 0.80 + ring)

			var civ_norm := 0.0
			var haz_or_flux := 0.0
			if has_civ:
				var cx := clampi(int(float(px) * float(civ_g - 1) / float(max(1, tex_size - 1))), 0, civ_g - 1)
				var c_idx := cy * civ_g + cx
				var rho := state.civ_density_m2[c_idx]
				if rho > 0.0001:
					civ_norm = sqrt(clampf(rho / 0.042, 0.0, 1.0))
				var haz := state.hazard_density[c_idx] if c_idx < state.hazard_density.size() else 0.0
				haz_or_flux = clampf(maxf(haz, state.civ_flux_activity[c_idx] * 0.35), 0.0, 1.0)

			buf[idx] = clampi(int(blue_cov * 255.0), 0, 255)
			buf[idx + 1] = clampi(int(red_threat * 255.0), 0, 255)
			buf[idx + 2] = clampi(int(civ_norm * 255.0), 0, 255)
			buf[idx + 3] = clampi(int(haz_or_flux * 255.0), 0, 255)
			idx += 4

	return Image.create_from_data(tex_size, tex_size, false, Image.FORMAT_RGBA8, buf)

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


## Checks both Earth radar horizon and 8-step terrain heightmap raymarch between observer and target.
## When `allow_valley_diffraction` is true (Acoustic & Sonar sensors), sound waves diffract over valley ridges up to +450m.
static func has_radar_los(state: WorldState, observer_pos: Vector3, target_pos: Vector3, allow_valley_diffraction: bool = false, is_submerged_uuv: bool = false) -> bool:
	var dx := observer_pos.x - target_pos.x
	var dz := observer_pos.z - target_pos.z
	var dist_km := sqrt(dx * dx + dz * dz)
	var max_horizon_km := compute_radar_horizon_km(observer_pos.y, target_pos.y)
	if not allow_valley_diffraction and dist_km > max_horizon_km:
		return false

	if is_submerged_uuv:
		return true

	# O(1) High-Altitude Ceiling Short-Circuit: if both endpoints are above max mountain height (3800m),
	# the straight ray can never intersect the terrain heightmap!
	if observer_pos.y > 3820.0 and target_pos.y > 3820.0:
		return true

	var ridge_tol_m := 450.0 if allow_valley_diffraction else 15.0
	var steps := 8
	for s in range(1, steps):
		var t := float(s) * 0.125
		var sample_x := lerpf(observer_pos.x, target_pos.x, t)
		var sample_z := lerpf(observer_pos.z, target_pos.z, t)
		var ray_alt_m := lerpf(observer_pos.y, target_pos.y, t)
		if ray_alt_m > 3820.0:
			continue
		var terrain_alt_m := state.get_terrain_elevation_m(sample_x, sample_z)
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


static func step(state: WorldState, sim_db: Node, _grid: SpatialHashGrid, cs_kernel: Object = null) -> void:
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

	var blue_obs_uids := PackedInt32Array()
	var red_obs_uids := PackedInt32Array()

	for uid in range(n_units):
		if u_active[uid] == 0:
			continue
		var fac := u_fac[uid]
		if u_ech[uid] != WorldState.ECHELON_COMPANY:
			u_det[uid] = (1 if fac == WorldState.FACTION_BLUE else 2)
			continue
		var pid := u_pid[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var stype := p_stype[pid]
		var has_esm := p_has_esm[pid]
		if stype == SENSOR_ACTIVE_RADAR and u_rad_act[uid] == 0 and has_esm == 0:
			continue
		if fac == WorldState.FACTION_BLUE:
			blue_obs_uids.append(uid)
		else:
			red_obs_uids.append(uid)

	var n_blue := blue_obs_uids.size()
	var n_red := red_obs_uids.size()

	for target_uid in range(n_units):
		if u_active[target_uid] == 0 or u_ech[target_uid] != WorldState.ECHELON_COMPANY:
			continue
		var lod_tier: int = u_lod[target_uid] if has_lod else WorldState.LOD_TIER_0_MICRO
		if tick > 0:
			if lod_tier == WorldState.LOD_TIER_2_MACRO and ((tick + target_uid) & 3) != 0:
				continue
			elif lod_tier == WorldState.LOD_TIER_1_OPERATIONAL and ((tick + target_uid) & 1) != 0:
				continue

		var fac := u_fac[target_uid]
		u_det[target_uid] = (1 if fac == WorldState.FACTION_BLUE else 2)
		var t_pid := u_pid[target_uid]
		if t_pid <= 0 or t_pid >= max_pid:
			continue
		var t_pos := u_pos[target_uid]
		var rcs_factor := p_rcs_fac[t_pid]
		var ir_factor := p_ir_fac[t_pid]
		var ac_factor := p_ac_fac[t_pid]
		var t_flags: int = p_flags[t_pid]
		var is_submerged_uuv: bool = (t_flags & FLAG_UUV_SUB) != 0
		var t_stype: int = p_stype[t_pid]
		var target_emitting_radar: bool = (u_rad_act[target_uid] == 1 and t_stype == SENSOR_ACTIVE_RADAR)
		var target_emitting_rf: bool = (t_flags & FLAG_RF_DATALINK) != 0
		var target_radar_rng := p_sensor_rng[t_pid]
		var target_ab: bool = u_ab[target_uid] == 1

		var obs_uids := blue_obs_uids if fac == WorldState.FACTION_RED else red_obs_uids
		var n_obs := n_blue if fac == WorldState.FACTION_RED else n_red
		var detect_bit := 1 if fac == WorldState.FACTION_RED else 2
		var obs_rad_mult: float = state.blue_radar_range_mult if fac == WorldState.FACTION_RED else state.red_radar_range_mult
		var t_rcs_tech_mult: float = pow(maxf(0.1, state.red_rcs_mult if fac == WorldState.FACTION_RED else state.blue_rcs_mult), 0.25)

		for i in range(n_obs):
			var obs_uid := obs_uids[i]
			var obs_pid := u_pid[obs_uid]
			var obs_pos := u_pos[obs_uid]
			var base_r := p_sensor_rng[obs_pid] * obs_rad_mult
			var obs_stype := p_stype[obs_pid]
			var obs_has_esm := p_has_esm[obs_pid]
			var obs_rad_on := u_rad_act[obs_uid] == 1

			var eff_r := 0.0
			var allow_diffraction := false
			if obs_stype == SENSOR_ACTIVE_RADAR and obs_rad_on and not is_submerged_uuv:
				eff_r = base_r * rcs_factor * t_rcs_tech_mult
			elif obs_stype == SENSOR_IR_EO and not is_submerged_uuv:
				eff_r = base_r * ir_factor * (1.85 if target_ab else 1.0)
			elif obs_stype == SENSOR_LIDAR_CV and not is_submerged_uuv:
				eff_r = base_r
			elif obs_stype == SENSOR_ACOUSTIC_SONAR:
				if is_submerged_uuv or t_pos.y <= 25.0 or base_r >= 30.0 or t_pos.y <= 3800.0:
					eff_r = base_r * ac_factor
					allow_diffraction = true
			elif obs_stype == SENSOR_SAT_SAR_EO and not is_submerged_uuv:
				eff_r = base_r

			if (obs_stype == SENSOR_PASSIVE_ESM or obs_has_esm == 1) and not is_submerged_uuv:
				if target_emitting_radar:
					eff_r = maxf(eff_r, maxf(base_r * 1.15, target_radar_rng * 1.60))
				elif target_emitting_rf:
					eff_r = maxf(eff_r, minf(maxf(base_r, 35.0), 55.0))

			if eff_r <= 0.05:
				continue
			var dx := obs_pos.x - t_pos.x
			var dz := obs_pos.z - t_pos.z
			if dx * dx + dz * dz <= eff_r * eff_r:
				if has_radar_los(state, obs_pos, t_pos, allow_diffraction, is_submerged_uuv):
					u_det[target_uid] |= detect_bit
					break


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

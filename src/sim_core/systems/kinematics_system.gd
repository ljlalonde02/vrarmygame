class_name KinematicsSystem
extends RefCounted
## High-Performance SoA 3D Kinematics & Tacview Aerobatic Flight Engine:
## - Uses pre-compiled `SimDB` SoA LUTs (`plat_domain_id`, `plat_cruise_km_s`, `plat_max_km_s`, `plat_class_flags`)
## - Computes smooth 3D Heading (`unit_heading_rad`), Pitch (`unit_pitch_rad`), and Banking Roll (`unit_roll_rad`)
##   so aircraft bank up to 72° into turns, pitch up/down during climbs/dives/loops, and trace smooth Tacview ribbons!
## - Enforces steep mountain slope penalties (>25 deg) while granting `FLAG_CLIMB_SLOPES`
##   (Quadruped Robot Dogs & Mountain SpecOps) full mobility on sheer mountain cliffs.


static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var p_cruise: PackedFloat32Array = sim_db.plat_cruise_km_s
	var p_max_spd: PackedFloat32Array = sim_db.plat_max_km_s
	var p_max_alt: PackedFloat32Array = sim_db.plat_max_alt_m
	var p_op_alt: PackedFloat32Array = sim_db.plat_cruise_alt_m
	var max_pid: int = p_dom.size()

	var flag_rf_link: int = int(sim_db.FLAG_RF_DATALINK)
	var flag_climb: int = int(sim_db.FLAG_CLIMB_SLOPES)
	var flag_fighter: int = int(sim_db.FLAG_FIGHTER)
	var flag_mobile_ground: int = int(sim_db.FLAG_INFANTRY) | int(sim_db.FLAG_ROBOT_DOG) | int(sim_db.FLAG_ARMOR)

	var u_active := state.unit_active
	var u_ech := state.unit_echelon
	var u_cd := state.unit_cooldown
	var u_pid := state.unit_platform_id
	var u_jam := state.unit_jammed
	var u_pos := state.unit_pos
	var u_vel := state.unit_vel
	var u_ab := state.unit_afterburner
	var u_has_wp := state.unit_has_waypoint
	var u_tpos := state.unit_target_pos
	var u_des_alt := state.unit_desired_alt_m
	var u_hdg := state.unit_heading_rad
	var u_pitch := state.unit_pitch_rad
	var u_roll := state.unit_roll_rad
	var u_ai := state.unit_ai_state
	var u_lod := state.unit_sim_lod
	var has_lod := u_lod.size() >= state.unit_count
	var inv_dt := 1.0 / maxf(dt, 0.001)

	for uid in range(state.unit_count):
		if u_active[uid] == 0 or u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue

		if u_cd[uid] > 0.0:
			u_cd[uid] = maxf(0.0, u_cd[uid] - dt)

		var lod_tier: int = u_lod[uid] if has_lod else WorldState.LOD_TIER_0_MICRO

		var pid: int = u_pid[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var flg: int = p_flags[pid]

		# Jammed RF_DATALINK drones lose C2 navigation control and loiter/drift in place (unless Photonic Mesh C2 unlocked!)
		var u_fac_k: int = state.unit_faction[uid]
		var jam_immune: bool = (state.blue_ew_jam_immunity == 1 if u_fac_k == WorldState.FACTION_BLUE else state.red_ew_jam_immunity == 1)
		if u_jam[uid] == 1 and (flg & flag_rf_link) != 0 and not jam_immune:
			u_vel[uid] = Vector3.ZERO
			continue

		var pos: Vector3 = u_pos[uid]
		var dom_id: int = p_dom[pid]
		var speed_km_s: float = p_max_spd[pid] if u_ab[uid] == 1 else p_cruise[pid]
		if (flg & flag_climb) != 0:
			speed_km_s *= (state.blue_dog_speed_mult if u_fac_k == WorldState.FACTION_BLUE else state.red_dog_speed_mult)
		# Phase 24: Surface kamikaze USVs (Sea Baby / Magura V5) slow down in high Beaufort Sea State waves; submerged XLUUVs are unaffected
		if dom_id == 2 and (flg & int(sim_db.FLAG_UUV_SUB)) == 0 and (flg & int(sim_db.FLAG_SWARM)) != 0:
			speed_km_s *= state.weather_usv_speed_mult

		# Sprint 7: Tactical Posture Overrides (HOLD/AMBUSH & RETREAT)
		var post_val: int = state.unit_tactical_posture[uid] if uid < state.unit_tactical_posture.size() else 0
		if post_val == WorldState.TACTICAL_POSTURE_HOLD_AMBUSH:
			u_vel[uid] = Vector3.ZERO
			u_pitch[uid] = 0.0
			u_roll[uid] = 0.0
			continue
		elif post_val == WorldState.TACTICAL_POSTURE_RETREAT:
			var home_dir := -1.0 if u_fac_k == WorldState.FACTION_BLUE else 1.0
			var ret_x := clampf(pos.x + home_dir * 35.0, -235.0, 235.0)
			u_tpos[uid] = Vector3(ret_x, pos.y, pos.z)
			u_has_wp[uid] = 1

		if u_has_wp[uid] == 0:
			if dom_id == 1:
				if lod_tier == WorldState.LOD_TIER_2_MACRO and ((state.tick_id + uid) & 1) == 1:
					continue
				var is_ftr: bool = (flg & flag_fighter) != 0
				var turn_rate := (0.09 if is_ftr else 0.045) * (1.0 if (uid & 1) == 0 else -1.0)
				var next_hdg := wrapf(u_hdg[uid] + turn_rate * dt, -PI, PI)
				u_hdg[uid] = next_hdg
				var target_bank := clampf(-turn_rate * 4.5, -1.15, 1.15)
				u_roll[uid] = lerpf(u_roll[uid], target_bank, clampf(dt * 4.0, 0.0, 1.0))

				var cap_speed := maxf(0.05, speed_km_s)
				var vx := cos(next_hdg) * cap_speed
				var vz := sin(next_hdg) * cap_speed
				var nx := clampf(pos.x + vx * dt, -246.0, 246.0)
				var nz := clampf(pos.z + vz * dt, -246.0, 246.0)
				var ny := pos.y
				if lod_tier == WorldState.LOD_TIER_0_MICRO:
					var terrain_below := maxf(0.0, state.get_terrain_elevation_m(nx, nz))
					var is_heli: bool = (pid < p_op_alt.size() and p_op_alt[pid] <= 250.0 and p_op_alt[pid] > 20.0)
					var target_alt := u_des_alt[uid]
					if target_alt < 20.0:
						target_alt = p_op_alt[pid] if (pid < p_op_alt.size() and p_op_alt[pid] > 20.0) else clampf(p_max_alt[pid] * 0.75, 2400.0, 14800.0)
						u_des_alt[uid] = target_alt
					var loop_wave := 0.0 if is_heli else (sin(state.sim_time_sec * 0.75 + float(uid) * 0.9) * (480.0 if is_ftr else 140.0))
					var min_clearance := 45.0 if is_heli else 250.0
					var desired_y := maxf(target_alt + loop_wave, terrain_below + min_clearance)
					ny = lerpf(pos.y, desired_y, clampf(dt * 2.5, 0.0, 1.0))
					var dy_m := (ny - pos.y) * inv_dt
					u_pitch[uid] = lerpf(u_pitch[uid], clampf(dy_m * 0.0012, -0.65, 0.65), clampf(dt * 4.0, 0.0, 1.0))
				var next_pos := Vector3(nx, ny, nz)
				u_vel[uid] = (next_pos - pos) * inv_dt
				u_pos[uid] = next_pos
			elif dom_id == 0 and (flg & flag_mobile_ground) != 0:
				# Mobile Infantry, Snipers, Commandos, Robot Dogs & Armor automatically conduct continuous tactical patrols & infiltration marches
				var pat_phase := float((uid * 37 + int(state.sim_time_sec * 0.25)) % 8) * (TAU / 8.0)
				var adv_dir := -1.0 if u_fac_k == WorldState.FACTION_BLUE else 1.0
				var wp_x := clampf(pos.x + adv_dir * 9.5 + cos(pat_phase) * 14.0, -235.0, 235.0)
				var wp_z := clampf(pos.z + sin(pat_phase) * 16.0, -235.0, 235.0)
				if state.get_terrain_elevation_m(wp_x, wp_z) > 2.0:
					u_tpos[uid] = Vector3(wp_x, pos.y, wp_z)
					u_has_wp[uid] = 1
				else:
					u_tpos[uid] = Vector3(clampf(pos.x - adv_dir * 12.0, -235.0, 235.0), pos.y, clampf(pos.z + sin(pat_phase) * 12.0, -235.0, 235.0))
					u_has_wp[uid] = 1
			else:
				u_vel[uid] = Vector3.ZERO
				u_pitch[uid] = 0.0
				u_roll[uid] = 0.0
			continue

		var target: Vector3 = u_tpos[uid]
		var to_target_xz := Vector2(target.x - pos.x, target.z - pos.z)
		var dist_km := to_target_xz.length()
		var arrive_thresh := maxf(0.08 if dom_id == 0 else 0.35, speed_km_s * dt * 1.15)

		if dist_km < arrive_thresh:
			if state.unit_waypoint_queues.has(uid) and state.unit_waypoint_queues[uid].size() > 0:
				var next_wp: Vector3 = state.unit_waypoint_queues[uid].pop_front()
				u_tpos[uid] = next_wp
				target = next_wp
				to_target_xz = Vector2(target.x - pos.x, target.z - pos.z)
				dist_km = to_target_xz.length()
			else:
				u_has_wp[uid] = 0
				if dom_id != 1:
					u_vel[uid] = Vector3.ZERO
				continue

		# Terrain slope mobility physics, Roads/Rivers/Bridges/Rubble/Forests & Civilian Density congestion for LAND units
		if dom_id == 0:
			# Realistic kinematic pace: Infantry @ ~10-18 km/h, Tanks/IFVs @ ~50-70 km/h, scaling with terrain and infrastructure
			var is_foot_or_dog: bool = (flg & flag_climb) != 0
			if not is_foot_or_dog and lod_tier != WorldState.LOD_TIER_2_MACRO:
				var slope_deg := state.get_terrain_slope_deg(pos.x, pos.z)
				if slope_deg > 25.0:
					speed_km_s *= 0.18

			# Apply Phase 11 Infrastructure Mobility (1.45x on intact Highways, 1.25x on intact Bridges, 0.16x on unbridged/blown Rivers, 0.25x in Rubble for vehicles vs 0.92x for Robot Dogs)
			speed_km_s *= state.get_ground_mobility_multiplier(pos.x, pos.z, is_foot_or_dog)

			if not is_foot_or_dog:
				# Wheeled/tracked vehicles suffer road-march congestion inside dense urban/refugee corridors
				var civ_rho := state.sample_civilian_density_m2(pos.x, pos.z)
				if civ_rho > 0.004:
					speed_km_s *= clampf(1.0 - (civ_rho / 0.045) * 0.35, 0.65, 1.0)

			# Sprint 7: Pinned infantry & mechanized units slow down under suppressive fire
			if uid < state.unit_suppression_level.size() and state.unit_suppression_level[uid] > 0.05:
				speed_km_s *= clampf(1.0 - state.unit_suppression_level[uid] * 0.60, 0.25, 1.0)
				state.unit_suppression_level[uid] = maxf(0.0, state.unit_suppression_level[uid] - dt * 0.12)

		var desired_hdg := atan2(to_target_xz.y, to_target_xz.x)
		var hdg_diff := wrapf(desired_hdg - u_hdg[uid], -PI, PI)

		if dom_id == 1:
			# Smooth Tacview aircraft banking turn + climb/dive pitch
			var max_turn_step := 1.85 * dt
			var applied_turn := clampf(hdg_diff, -max_turn_step, max_turn_step)
			u_hdg[uid] = wrapf(u_hdg[uid] + applied_turn, -PI, PI)
			var bank_target := clampf(-(applied_turn * inv_dt) * 0.72, -1.25, 1.25)
			if u_ai[uid] == WorldState.AI_EVASIVE_DEFENSIVE:
				bank_target = sin(state.sim_time_sec * 3.2 + float(uid)) * 1.22
			u_roll[uid] = lerpf(u_roll[uid], bank_target, clampf(dt * 5.0, 0.0, 1.0))
		else:
			u_hdg[uid] = desired_hdg
			u_roll[uid] = 0.0
			# Sprint 7: Tank Turret Azimuth Tracking
			if (flg & int(sim_db.FLAG_ARMOR)) != 0 and uid < state.unit_turret_hdg_rad.size():
				state.unit_turret_hdg_rad[uid] = lerp_angle(state.unit_turret_hdg_rad[uid], desired_hdg, clampf(dt * 4.0, 0.0, 1.0))

		var step_km := minf(dist_km, speed_km_s * dt)
		var dir_xz := to_target_xz / maxf(dist_km, 0.0001)
		var new_x := clampf(pos.x + dir_xz.x * step_km, -248.0, 248.0)
		var new_z := clampf(pos.z + dir_xz.y * step_km, -248.0, 248.0)
		var new_y := pos.y

		if dom_id == 0:
			new_y = maxf(0.0, state.get_terrain_elevation_m(new_x, new_z)) + 5.0
			var dy_land := new_y - pos.y
			u_pitch[uid] = clampf(atan2(dy_land, maxf(step_km * 1000.0, 1.0)), -0.45, 0.45)
		elif dom_id == 2:
			# Naval Bathymetry & Draft Enforcement:
			var p_dict: Dictionary = sim_db.platforms_by_id[pid] if (sim_db != null and pid < sim_db.platforms_by_id.size()) else {}
			var p_slug: String = String(p_dict.get("slug", ""))
			var req_draft: float = state.get_ship_required_draft_m(pid, flg, p_slug)
			var dest_water_depth: float = state.get_water_depth_m(new_x, new_z)

			# Ships cannot enter dry land or water shallower than their required draft
			# If shallow water is encountered, steer along deep-water bathymetric contour:
			if dest_water_depth < req_draft:
				var probe_dist := 1.5
				var d_east := state.get_water_depth_m(pos.x + probe_dist, pos.z)
				var d_west := state.get_water_depth_m(pos.x - probe_dist, pos.z)
				var d_north := state.get_water_depth_m(pos.x, pos.z + probe_dist)
				var d_south := state.get_water_depth_m(pos.x, pos.z - probe_dist)
				var grad_x := (d_east - d_west) / (probe_dist * 2.0)
				var grad_z := (d_north - d_south) / (probe_dist * 2.0)
				var deep_dir := Vector2(grad_x, grad_z).normalized()
				if deep_dir.length_squared() > 0.01:
					var move_vec := Vector2(dir_xz.x, dir_xz.y)
					var tangent := Vector2(-deep_dir.y, deep_dir.x)
					if tangent.dot(move_vec) < 0.0:
						tangent = -tangent
					var deflect_dir := (tangent * 0.75 + deep_dir * 0.45).normalized()
					var alt_x := clampf(pos.x + deflect_dir.x * step_km, -248.0, 248.0)
					var alt_z := clampf(pos.z + deflect_dir.y * step_km, -248.0, 248.0)
					if state.get_water_depth_m(alt_x, alt_z) >= req_draft:
						new_x = alt_x
						new_z = alt_z
						u_hdg[uid] = atan2(deflect_dir.x, deflect_dir.y)
					else:
						new_x = pos.x
						new_z = pos.z
				else:
					new_x = pos.x
					new_z = pos.z
				dest_water_depth = state.get_water_depth_m(new_x, new_z)

			if (flg & int(sim_db.FLAG_UUV_SUB)) != 0:
				var sub_depth := p_op_alt[pid] if (pid < p_op_alt.size() and p_op_alt[pid] < -5.0) else -180.0
				var pref_depth := u_des_alt[uid] if u_des_alt[uid] < -5.0 else sub_depth
				# Submarine depth is clamped above seafloor (-dest_water_depth + 4.0m) and below surface (-8.0m)
				var max_dive := -maxf(10.0, dest_water_depth - 4.0)
				new_y = clampf(pref_depth, max_dive, -8.0)
			else:
				new_y = 0.0
			u_pitch[uid] = 0.0

		elif dom_id == 1:
			var terrain_below := maxf(0.0, state.get_terrain_elevation_m(new_x, new_z))
			var is_heli: bool = (pid < p_op_alt.size() and p_op_alt[pid] <= 250.0 and p_op_alt[pid] > 20.0)
			var pref_alt := u_des_alt[uid]
			if pref_alt < 20.0:
				pref_alt = p_op_alt[pid] if (pid < p_op_alt.size() and p_op_alt[pid] > 20.0) else maxf(target.y, 8500.0)
			var loop_offset := 0.0
			if (flg & flag_fighter) != 0 and not is_heli and u_ai[uid] in [WorldState.AI_BVR_INTERCEPT, WorldState.AI_EVASIVE_DEFENSIVE]:
				loop_offset = sin(state.sim_time_sec * 1.8 + float(uid)) * 650.0
			var min_clearance := 45.0 if is_heli else 250.0
			var desired_alt := maxf(pref_alt + loop_offset, terrain_below + min_clearance)
			new_y = lerpf(pos.y, desired_alt, clampf(dt * 2.8, 0.0, 1.0))
			var dy_air := (new_y - pos.y) * inv_dt
			u_pitch[uid] = lerpf(u_pitch[uid], clampf(dy_air * 0.0014, -0.75, 0.75), clampf(dt * 4.5, 0.0, 1.0))

		var new_pos := Vector3(new_x, new_y, new_z)
		u_vel[uid] = (new_pos - pos) * inv_dt
		u_pos[uid] = new_pos

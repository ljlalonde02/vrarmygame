class_name EchelonClusterSystem
extends RefCounted
## Maintains the Brigade (2) -> Battalion (1) -> Company/Flight/Robot Dog Pack (0) hierarchy
## in two linear O(N) passes!


static func deploy_unmanned_subunit(state: WorldState, sim_db: Node, parent_uid: int, deploy_offset_km: Vector3 = Vector3(1.5, 0.0, -1.5)) -> int:
	if parent_uid < 0 or parent_uid >= state.unit_count or state.unit_active[parent_uid] == 0:
		return -1

	if state.unit_echelon[parent_uid] > WorldState.ECHELON_COMPANY:
		var spawned_any := -1
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				var p1 := state.unit_parent_id[uid]
				var p2 := state.unit_parent_id[p1] if p1 >= 0 else -1
				if p1 == parent_uid or p2 == parent_uid:
					if state.unit_unmanned_bays[uid] > 0:
						var child_id := deploy_unmanned_subunit(state, sim_db, uid, deploy_offset_km)
						if child_id >= 0:
							spawned_any = child_id
		return spawned_any

	if state.unit_unmanned_bays[parent_uid] <= 0:
		return -1

	var pid := state.unit_platform_id[parent_uid]
	var p_def: Dictionary = sim_db.get_platform(pid)
	var sub_pid: int = int(p_def.get("carrier_sub_platform_id", 0))
	if sub_pid <= 0:
		var sub_slug := String(p_def.get("carrier_sub_platform_slug", ""))
		sub_pid = sim_db.get_platform_id(sub_slug)
	if sub_pid <= 0:
		return -1

	var sub_def: Dictionary = sim_db.get_platform(sub_pid)
	state.unit_unmanned_bays[parent_uid] -= 1

	var parent_pos := state.unit_pos[parent_uid]
	var spawn_pos := Vector3(parent_pos.x + deploy_offset_km.x * 0.35, parent_pos.y, parent_pos.z + deploy_offset_km.z * 0.35)
	var battalion_parent := state.unit_parent_id[parent_uid]
	var child_uid := state.spawn_unit(
		state.unit_faction[parent_uid],
		sub_pid,
		spawn_pos,
		WorldState.ECHELON_COMPANY,
		battalion_parent,
		sub_def
	)
	if child_uid >= 0:
		var wp_pos := Vector3(
			parent_pos.x + deploy_offset_km.x,
			maxf(0.0, state.get_terrain_elevation_m(parent_pos.x + deploy_offset_km.x, parent_pos.z + deploy_offset_km.z)) + 5.0,
			parent_pos.z + deploy_offset_km.z
		)
		state.unit_target_pos[child_uid] = wp_pos
		state.unit_has_waypoint[child_uid] = 1
		state.sim_events_queue.append({
			"type": "unmanned_deployed",
			"parent_unit_id": parent_uid,
			"child_unit_id": child_uid,
			"sub_platform_id": sub_pid,
			"pos_km": spawn_pos,
		})
	return child_uid


static func propagate_move_order(state: WorldState, root_uid: int, target_pos_km: Vector3) -> void:
	if root_uid < 0 or root_uid >= state.unit_count or state.unit_active[root_uid] == 0:
		return
	var ech := state.unit_echelon[root_uid]
	if ech == WorldState.ECHELON_COMPANY:
		var dest_y := target_pos_km.y
		if state.unit_pos[root_uid].y > 180.0 and dest_y < 150.0:
			dest_y = maxf(state.unit_desired_alt_m[root_uid], state.unit_pos[root_uid].y)
		state.unit_target_pos[root_uid] = Vector3(target_pos_km.x, dest_y, target_pos_km.z)
		state.unit_has_waypoint[root_uid] = 1
		state.unit_player_override_timer[root_uid] = 180.0
		if root_uid < state.unit_delegated_ai.size():
			state.unit_delegated_ai[root_uid] = 0
		return

	state.unit_target_pos[root_uid] = target_pos_km
	state.unit_has_waypoint[root_uid] = 1
	var center_pos := state.unit_pos[root_uid]
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var p1 := state.unit_parent_id[uid]
		var p2 := state.unit_parent_id[p1] if p1 >= 0 else -1
		if p1 == root_uid or p2 == root_uid:
			var offset := state.unit_pos[uid] - center_pos
			offset.x = clampf(offset.x, -12.0, 12.0)
			offset.z = clampf(offset.z, -12.0, 12.0)
			var dest_y := target_pos_km.y
			if state.unit_pos[uid].y > 180.0 and dest_y < 150.0:
				dest_y = maxf(state.unit_desired_alt_m[uid], state.unit_pos[uid].y)
			var dest := Vector3(target_pos_km.x + offset.x, dest_y, target_pos_km.z + offset.z)
			state.unit_target_pos[uid] = dest
			state.unit_has_waypoint[uid] = 1
			state.unit_player_override_timer[uid] = 180.0
			if uid < state.unit_delegated_ai.size():
				state.unit_delegated_ai[uid] = 0
			if p1 >= 0 and p1 < state.unit_count:
				state.unit_target_pos[p1] = target_pos_km
				state.unit_has_waypoint[p1] = 1


## Returns all active leaf Company/Flight/Battery units belonging to `root_uid` (or `[root_uid]` if already a Company).
static func get_subordinate_leaf_units(state: WorldState, root_uid: int) -> Array[int]:
	var res: Array[int] = []
	if root_uid < 0 or root_uid >= state.unit_count or state.unit_active[root_uid] == 0:
		return res
	if state.unit_echelon[root_uid] == WorldState.ECHELON_COMPANY:
		res.append(root_uid)
		return res
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var p1 := state.unit_parent_id[uid]
			var p2 := state.unit_parent_id[p1] if p1 >= 0 else -1
			if p1 == root_uid or p2 == root_uid:
				res.append(uid)
	return res


## Returns the parent Battalion ID for any Company, Battalion, or Brigade unit.
static func get_battalion_id_for_unit(state: WorldState, uid: int) -> int:
	if uid < 0 or uid >= state.unit_count or state.unit_active[uid] == 0:
		return -1
	var ech := state.unit_echelon[uid]
	if ech == WorldState.ECHELON_BATTALION:
		return uid
	elif ech == WorldState.ECHELON_COMPANY:
		var p1 := state.unit_parent_id[uid]
		if p1 >= 0 and p1 < state.unit_count and state.unit_echelon[p1] == WorldState.ECHELON_BATTALION:
			return p1
		return uid
	else:
		# For a Brigade, return its first active Battalion
		for sub in range(state.unit_count):
			if state.unit_active[sub] == 1 and state.unit_echelon[sub] == WorldState.ECHELON_BATTALION and state.unit_parent_id[sub] == uid:
				return sub
		return uid


## Returns the parent Brigade ID for any Company, Battalion, or Brigade unit.
static func get_brigade_id_for_unit(state: WorldState, uid: int) -> int:
	if uid < 0 or uid >= state.unit_count or state.unit_active[uid] == 0:
		return -1
	var ech := state.unit_echelon[uid]
	if ech == WorldState.ECHELON_BRIGADE:
		return uid
	elif ech == WorldState.ECHELON_BATTALION:
		var p1 := state.unit_parent_id[uid]
		return p1 if (p1 >= 0 and p1 < state.unit_count) else uid
	else:
		var p1 := state.unit_parent_id[uid]
		if p1 >= 0 and p1 < state.unit_count:
			var p2 := state.unit_parent_id[p1]
			if p2 >= 0 and p2 < state.unit_count:
				return p2
			return p1
		return uid


## Returns a clear human-readable description of a unit's place in the 3-Tier Military Hierarchy.
static func get_hierarchy_status_string(state: WorldState, uid: int) -> String:
	if uid < 0 or uid >= state.unit_count or state.unit_active[uid] == 0:
		return "NO UNIT SELECTED"
	var ech := state.unit_echelon[uid]
	var bn_id := get_battalion_id_for_unit(state, uid)
	var bde_id := get_brigade_id_for_unit(state, uid)
	var leaf_cnt := get_subordinate_leaf_units(state, uid).size()
	if ech == WorldState.ECHELON_BRIGADE:
		return "ORG: BRIGADE / WING [#%d] (%d Active Companies/Flights)" % [uid, leaf_cnt]
	elif ech == WorldState.ECHELON_BATTALION:
		return "ORG: BATTALION / SQDN [#%d] (%d Companies) -> BDE #%d" % [uid, leaf_cnt, bde_id]
	var bn_leaves := get_subordinate_leaf_units(state, bn_id).size() if bn_id >= 0 else 1
	var bde_leaves := get_subordinate_leaf_units(state, bde_id).size() if bde_id >= 0 else 1
	return "ORG: COMPANY [#%d] -> BN #%d (%d Cos) -> BDE #%d (%d Cos)" % [uid, bn_id, bn_leaves, bde_id, bde_leaves]


static func step(state: WorldState) -> void:
	var n := state.unit_count
	var child_counts := PackedInt32Array()
	child_counts.resize(n)
	child_counts.fill(0)

	# Reset Battalion (1) and Brigade (2) accumulators
	for uid in range(n):
		if state.unit_echelon[uid] > WorldState.ECHELON_COMPANY:
			state.unit_pos[uid] = Vector3.ZERO
			state.unit_vel[uid] = Vector3.ZERO
			state.unit_hp[uid] = 0.0
			state.unit_max_hp[uid] = 0.0
			state.unit_ammo_1[uid] = 0
			state.unit_ammo_2[uid] = 0
			state.unit_unmanned_bays[uid] = 0
			state.unit_detected_mask[uid] = 0

	# Linear Pass 1: Accumulate Companies (0) -> Battalions (1) & Live Ammunition Totals
	var b_ammo_rem := 0
	var r_ammo_rem := 0
	for uid in range(n):
		if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var u_ammo := state.unit_ammo_1[uid] + state.unit_ammo_2[uid]
			if state.unit_faction[uid] == WorldState.FACTION_BLUE:
				b_ammo_rem += u_ammo
			else:
				r_ammo_rem += u_ammo
			var bn_id := state.unit_parent_id[uid]
			if bn_id >= 0 and bn_id < n:
				state.unit_pos[bn_id] += state.unit_pos[uid]
				state.unit_vel[bn_id] += state.unit_vel[uid]
				state.unit_hp[bn_id] += state.unit_hp[uid]
				state.unit_max_hp[bn_id] += state.unit_max_hp[uid]
				state.unit_ammo_1[bn_id] += state.unit_ammo_1[uid]
				state.unit_ammo_2[bn_id] += state.unit_ammo_2[uid]
				state.unit_unmanned_bays[bn_id] += state.unit_unmanned_bays[uid]
				state.unit_detected_mask[bn_id] |= state.unit_detected_mask[uid]
				child_counts[bn_id] += 1

	state.blue_ammo_remaining = b_ammo_rem
	state.red_ammo_remaining = r_ammo_rem
	if state.blue_ammo_initial_total < b_ammo_rem:
		state.blue_ammo_initial_total = b_ammo_rem
	if state.red_ammo_initial_total < r_ammo_rem:
		state.red_ammo_initial_total = r_ammo_rem

	# Finalize Battalions & Accumulate Battalions (1) -> Brigades (2)
	for bn_id in range(n):
		if state.unit_echelon[bn_id] == WorldState.ECHELON_BATTALION:
			var c := child_counts[bn_id]
			if c > 0:
				state.unit_active[bn_id] = 1
				state.unit_pos[bn_id] /= float(c)
				state.unit_vel[bn_id] /= float(c)
				var bde_id := state.unit_parent_id[bn_id]
				if bde_id >= 0 and bde_id < n:
					state.unit_pos[bde_id] += state.unit_pos[bn_id]
					state.unit_vel[bde_id] += state.unit_vel[bn_id]
					state.unit_hp[bde_id] += state.unit_hp[bn_id]
					state.unit_max_hp[bde_id] += state.unit_max_hp[bn_id]
					state.unit_ammo_1[bde_id] += state.unit_ammo_1[bn_id]
					state.unit_ammo_2[bde_id] += state.unit_ammo_2[bn_id]
					state.unit_unmanned_bays[bde_id] += state.unit_unmanned_bays[bn_id]
					state.unit_detected_mask[bde_id] |= state.unit_detected_mask[bn_id]
					child_counts[bde_id] += 1
			else:
				state.unit_active[bn_id] = 0

	# Finalize Brigades (2)
	for bde_id in range(n):
		if state.unit_echelon[bde_id] == WorldState.ECHELON_BRIGADE:
			var c := child_counts[bde_id]
			if c > 0:
				state.unit_active[bde_id] = 1
				state.unit_pos[bde_id] /= float(c)
				state.unit_vel[bde_id] /= float(c)
			else:
				state.unit_active[bde_id] = 0

	# Evaluate 4-Tier Hierarchical C2 Integrity (Command Bunkers + AWACS + SATCOM)
	var blue_bunkers_total := 0
	var blue_bunkers_intact := 0
	var red_bunkers_total := 0
	var red_bunkers_intact := 0
	for st in state.active_sites:
		if String(st.get("site_type", "")) == "COMMAND_BUNKER":
			var is_intact: bool = float(st.get("crater_timer_sec", 0.0)) <= 0.0 and float(st.get("hp", 500.0)) > 0.0
			if String(st.get("faction_owner", "")) == "BLUE":
				blue_bunkers_total += 1
				if is_intact:
					blue_bunkers_intact += 1
			elif String(st.get("faction_owner", "")) == "RED":
				red_bunkers_total += 1
				if is_intact:
					red_bunkers_intact += 1

	var blue_bunker_ratio := float(blue_bunkers_intact) / float(max(1, blue_bunkers_total)) if blue_bunkers_total > 0 else 1.0
	var red_bunker_ratio := float(red_bunkers_intact) / float(max(1, red_bunkers_total)) if red_bunkers_total > 0 else 1.0
	state.blue_c2_integrity = clampf(0.25 + 0.45 * blue_bunker_ratio + 0.30 * state.blue_satcom_factor, 0.15, 1.0)
	state.red_c2_integrity = clampf(0.25 + 0.45 * red_bunker_ratio + 0.30 * state.red_satcom_factor, 0.15, 1.0)

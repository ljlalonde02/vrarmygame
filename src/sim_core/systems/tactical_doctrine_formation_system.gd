class_name TacticalDoctrineFormationSystem
extends RefCounted
## Computes realistic, doctrinally sound tactical military formations adapted to terrain.
## Real modern militaries (US Army FM 3-90, NATO ATP-3.2.1, PLA Combined Arms) do NOT form straight geometric lines.
## Formations:
## - FORMATION_WEDGE: Tactical Spearhead for open advance (lead scout at point, flanks stepped back at 45-60 deg).
## - FORMATION_DEFILE_COLUMN: Staggered Column along mountain defiles, river valleys, and roads.
## - FORMATION_RIDGE_HULL_DOWN: Hull-Down Military Crest defense dispersed along elevated ridgelines.
## - FORMATION_CSG_RING: Naval Carrier Strike Group 360-degree protective screen around the high-value unit (HVU).
## - FORMATION_AIR_FINGER_FOUR: Tactical 4-ship flight with stepped altitudes and lateral offsets.

enum FormationType {
	WEDGE = 0,
	DEFILE_COLUMN = 1,
	RIDGE_HULL_DOWN = 2,
	CSG_RING = 3,
	AIR_FINGER_FOUR = 4,
	BOUNDING_OVERWATCH = 5,
	FLANKING_PINCER = 6
}


## Determines optimal formation type based on domain, posture, and terrain slope
static func select_formation_for_group(
	domain_id: int,
	posture: int,
	is_carrier_group: bool,
	avg_elevation_m: float,
	terrain_slope_deg: float
) -> int:
	if domain_id == 2: # SEA
		if is_carrier_group:
			return FormationType.CSG_RING
		return FormationType.WEDGE

	if domain_id == 1: # AIR
		return FormationType.AIR_FINGER_FOUR

	# LAND domain
	if terrain_slope_deg > 14.0 or avg_elevation_m > 750.0:
		if posture == WorldState.TACTICAL_POSTURE_HOLD_AMBUSH:
			return FormationType.RIDGE_HULL_DOWN
		return FormationType.DEFILE_COLUMN

	if posture == WorldState.TACTICAL_POSTURE_HOLD_AMBUSH:
		return FormationType.RIDGE_HULL_DOWN

	return FormationType.WEDGE


## Computes local offset (in km) for a unit within its group according to doctrinal geometry
static func compute_formation_offset(
	formation_type: int,
	unit_idx: int,
	group_size: int,
	facing_heading_rad: float,
	spacing_scale: float = 1.0
) -> Vector3:
	var local_offset := Vector3.ZERO
	match formation_type:
		FormationType.WEDGE:
			if unit_idx == 0:
				local_offset = Vector3.ZERO # Point element / scout
			else:
				var rank := int((unit_idx + 1) / 2)
				var is_right := (unit_idx % 2 == 0)
				var side_sign := 1.0 if is_right else -1.0
				var lateral := side_sign * float(rank) * 2.8 * spacing_scale
				var longitudinal := -float(rank) * 2.4 * spacing_scale
				local_offset = Vector3(lateral, 0.0, longitudinal)

		FormationType.DEFILE_COLUMN:
			var side_sign := 1.0 if (unit_idx % 2 == 1) else -1.0
			var lateral := side_sign * 0.95 * spacing_scale
			var longitudinal := -float(unit_idx) * 3.4 * spacing_scale
			local_offset = Vector3(lateral, 0.0, longitudinal)

		FormationType.RIDGE_HULL_DOWN:
			var center_off := float(unit_idx) - float(group_size - 1) * 0.5
			var lateral := center_off * 3.2 * spacing_scale
			var depth := (float(unit_idx % 2) - 0.5) * 1.4 * spacing_scale # Staggered forward/reverse slope
			local_offset = Vector3(lateral, 0.0, depth)

		FormationType.CSG_RING:
			if unit_idx == 0:
				local_offset = Vector3.ZERO # High-Value Unit (CVN Supercarrier)
			else:
				var escorts_count := maxi(1, group_size - 1)
				var angle := (float(unit_idx - 1) / float(escorts_count)) * TAU
				var ring_radius_km := 24.0 * spacing_scale
				local_offset = Vector3(sin(angle) * ring_radius_km, 0.0, cos(angle) * ring_radius_km)

		FormationType.AIR_FINGER_FOUR:
			match unit_idx % 4:
				0: # Flight Lead
					local_offset = Vector3(0.0, 0.0, 0.0)
				1: # Wingman #2 (Stepped back left, +250m)
					local_offset = Vector3(-2.2 * spacing_scale, 250.0, -1.8 * spacing_scale)
				2: # Element Lead #3 (Stepped right, +450m)
					local_offset = Vector3(2.6 * spacing_scale, 450.0, -1.2 * spacing_scale)
				3: # Element Wingman #4 (Stepped back right, +700m)
					local_offset = Vector3(4.5 * spacing_scale, 700.0, -3.2 * spacing_scale)

		FormationType.BOUNDING_OVERWATCH:
			# Alternating Base of Fire (trailing stationary element) and Bounding Element (pushed forward)
			var is_bounding := (unit_idx % 2 == 1)
			var side_sign := 1.0 if (unit_idx % 4 < 2) else -1.0
			var lat := side_sign * (2.4 + float(unit_idx / 2) * 1.8) * spacing_scale
			var lon := (3.8 if is_bounding else -2.2) * spacing_scale
			local_offset = Vector3(lat, 0.0, lon)

		FormationType.FLANKING_PINCER:
			# Unit 0 is pinning center, Unit 1 is left hook, Unit 2 is right hook, subsequent follow flanks
			if unit_idx == 0:
				local_offset = Vector3(0.0, 0.0, 0.0)
			else:
				var is_right_pincer := (unit_idx % 2 == 0)
				var hook_x := (5.8 * spacing_scale) if is_right_pincer else (-5.8 * spacing_scale)
				var hook_z := (2.5 - float(unit_idx / 2) * 1.5) * spacing_scale
				local_offset = Vector3(hook_x, 0.0, hook_z)

	# Rotate horizontal offset by group facing heading
	var rotated_x := local_offset.x * cos(facing_heading_rad) + local_offset.z * sin(facing_heading_rad)
	var rotated_z := -local_offset.x * sin(facing_heading_rad) + local_offset.z * cos(facing_heading_rad)
	return Vector3(rotated_x, local_offset.y, rotated_z)


## Applies terrain-aware doctrinal formations to subordinate units of a battalion or brigade
static func apply_doctrinal_formation_to_battalion(
	state: WorldState,
	sim_db: Node,
	parent_uid: int,
	formation_type: int = FormationType.WEDGE
) -> void:
	if parent_uid < 0 or parent_uid >= state.unit_count or state.unit_active[parent_uid] == 0:
		return

	var center_pos := state.unit_pos[parent_uid]
	var heading := state.unit_heading_rad[parent_uid]

	var children: Array[int] = []
	for u in range(state.unit_count):
		if state.unit_active[u] == 1 and state.unit_parent_id[u] == parent_uid:
			children.append(u)

	if children.is_empty():
		return

	var n_children := children.size()
	for i in range(n_children):
		var child_uid := children[i]
		var offset := compute_formation_offset(formation_type, i, n_children, heading, 1.0)
		var new_x := center_pos.x + offset.x
		var new_z := center_pos.z + offset.z
		var ground_elev := maxf(0.0, state.get_terrain_elevation_m(new_x, new_z))
		var new_y := ground_elev + offset.y
		if state.unit_pos[child_uid].y > 300.0:
			new_y = state.unit_pos[child_uid].y + offset.y

		state.unit_pos[child_uid] = Vector3(new_x, new_y, new_z)
		state.unit_heading_rad[child_uid] = heading

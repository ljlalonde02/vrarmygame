class_name StrikePreviewRenderer
extends Node3D
## Renders live dashed parabolic strike preview arcs, Time-on-Target (TOT) telemetry,
## and SAM exposure warnings when the player drags an attack vector on the War Table.

var war_table: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _immediate: ImmediateMesh = null
var _tot_label: Label3D = null
var _reticle_ring_mi: MeshInstance3D = null
var _reticle_ring_mat: StandardMaterial3D = null
var _reticle_beam_mi: MeshInstance3D = null
var _reticle_beam_mat: StandardMaterial3D = null
var is_preview_active: bool = false


func _ready() -> void:
	if _mesh_instance != null:
		return
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "StrikePreviewLines"
	_immediate = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	_mesh_instance.mesh = _immediate
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# 3D Holographic Spatial Targeting Ring (TorusMesh) & Vertical Orbital Beam (CylinderMesh)
	_reticle_ring_mi = MeshInstance3D.new()
	_reticle_ring_mi.name = "SpatialTargetRing3D"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.085
	torus.outer_radius = 0.105
	torus.rings = 32
	torus.ring_segments = 12
	_reticle_ring_mat = StandardMaterial3D.new()
	_reticle_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_reticle_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reticle_ring_mat.albedo_color = Color(0.2, 1.0, 0.55, 0.88)
	_reticle_ring_mat.no_depth_test = true
	torus.material = _reticle_ring_mat
	_reticle_ring_mi.mesh = torus
	_reticle_ring_mi.visible = false
	add_child(_reticle_ring_mi)

	_reticle_beam_mi = MeshInstance3D.new()
	_reticle_beam_mi.name = "SpatialTargetBeam3D"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.018
	cyl.height = 0.22
	_reticle_beam_mat = StandardMaterial3D.new()
	_reticle_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_reticle_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reticle_beam_mat.albedo_color = Color(0.2, 1.0, 0.55, 0.45)
	_reticle_beam_mat.no_depth_test = true
	cyl.material = _reticle_beam_mat
	_reticle_beam_mi.mesh = cyl
	_reticle_beam_mi.visible = false
	add_child(_reticle_beam_mi)

	_tot_label = Label3D.new()
	_tot_label.name = "TOTPreviewLabel"
	_tot_label.font_size = 22
	_tot_label.pixel_size = 0.00075
	_tot_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tot_label.no_depth_test = true
	_tot_label.modulate = TacticalTheme.COL_UNMANNED_GOLD
	_tot_label.visible = false
	add_child(_tot_label)


func show_strike_preview(start_km: Vector3, target_km: Vector3, weapon_mach: float = 3.5, weapon_name: String = "STRIKE SALVO") -> void:
	if war_table == null:
		return
	is_preview_active = true
	_immediate.clear_surfaces()
	_immediate.surface_begin(Mesh.PRIMITIVE_LINES)

	var dist_km := Vector2(start_km.x, start_km.z).distance_to(Vector2(target_km.x, target_km.z))
	var apex_m := maxf(start_km.y, target_km.y) + clampf(dist_km * 120.0, 1500.0, 24000.0)
	var segments := 24

	for i in range(segments):
		if i % 2 == 1:
			continue # Dashed arc
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)

		var p0_km := Vector3(
			lerpf(start_km.x, target_km.x, t0),
			lerpf(start_km.y, target_km.y, t0) + 4.0 * t0 * (1.0 - t0) * apex_m,
			lerpf(start_km.z, target_km.z, t0)
		)
		var p1_km := Vector3(
			lerpf(start_km.x, target_km.x, t1),
			lerpf(start_km.y, target_km.y, t1) + 4.0 * t1 * (1.0 - t1) * apex_m,
			lerpf(start_km.z, target_km.z, t1)
		)

		var loc0: Vector3 = war_table.theater_km_to_table_local(p0_km)
		var loc1: Vector3 = war_table.theater_km_to_table_local(p1_km)
		_immediate.surface_set_color(TacticalTheme.COL_UNMANNED_GOLD)
		_immediate.surface_add_vertex(loc0)
		_immediate.surface_add_vertex(loc1)

	_immediate.surface_end()

	var speed_km_s := maxf(0.2, weapon_mach * 0.343)
	var tot_sec := int(round(dist_km / speed_km_s))
	var apex_km := Vector3(
		(start_km.x + target_km.x) * 0.5,
		apex_m * 0.65,
		(start_km.z + target_km.z) * 0.5
	)
	var apex_local: Vector3 = war_table.theater_km_to_table_local(apex_km)
	_tot_label.position = apex_local + Vector3(0.0, 0.03, 0.0)
	_tot_label.text = "%s | RANGE: %.0f km | TOT: T+%ds" % [weapon_name, dist_km, tot_sec]
	_tot_label.visible = true


func show_spatial_target_reticle(
	target_km: Vector3,
	radius_km: float = 35.0,
	tool_label: String = "SPATIAL TARGETING",
	reticle_color: Color = Color(0.0, 0.95, 1.0, 0.95),
	origin_km: Vector3 = Vector3.INF
) -> void:
	if war_table == null or _immediate == null:
		return
	is_preview_active = true
	_immediate.clear_surfaces()
	_immediate.surface_begin(Mesh.PRIMITIVE_LINES)

	var ground_target_km := Vector3(target_km.x, 0.0, target_km.z)
	var ring_segments := 36
	var inner_r := maxf(4.0, radius_km * 0.28)
	var center_local: Vector3 = war_table.theater_km_to_table_local(ground_target_km) + Vector3(0.0, 0.010, 0.0)

	# 1. Outer Blast / Drop / Effect Radius Ring & Inner Crosshair Ring
	for i in range(ring_segments):
		var a0 := (float(i) / float(ring_segments)) * TAU
		var a1 := (float(i + 1) / float(ring_segments)) * TAU
		var p0_km := ground_target_km + Vector3(cos(a0) * radius_km, 0.0, sin(a0) * radius_km)
		var p1_km := ground_target_km + Vector3(cos(a1) * radius_km, 0.0, sin(a1) * radius_km)
		var loc0: Vector3 = war_table.theater_km_to_table_local(p0_km) + Vector3(0.0, 0.010, 0.0)
		var loc1: Vector3 = war_table.theater_km_to_table_local(p1_km) + Vector3(0.0, 0.010, 0.0)
		_immediate.surface_set_color(reticle_color)
		_immediate.surface_add_vertex(loc0)
		_immediate.surface_add_vertex(loc1)

		if i % 2 == 0:
			var ip0_km := ground_target_km + Vector3(cos(a0) * inner_r, 0.0, sin(a0) * inner_r)
			var ip1_km := ground_target_km + Vector3(cos(a1) * inner_r, 0.0, sin(a1) * inner_r)
			var iloc0: Vector3 = war_table.theater_km_to_table_local(ip0_km) + Vector3(0.0, 0.011, 0.0)
			var iloc1: Vector3 = war_table.theater_km_to_table_local(ip1_km) + Vector3(0.0, 0.011, 0.0)
			_immediate.surface_set_color(reticle_color.lightened(0.28))
			_immediate.surface_add_vertex(iloc0)
			_immediate.surface_add_vertex(iloc1)

	# 2. Cardinal Crosshair Ticks + Vertical Orbital/Airborne Targeting Spire
	var cross_r := maxf(8.0, radius_km * 1.18)
	var ew0: Vector3 = war_table.theater_km_to_table_local(ground_target_km + Vector3(-cross_r, 0.0, 0.0)) + Vector3(0.0, 0.011, 0.0)
	var ew1: Vector3 = war_table.theater_km_to_table_local(ground_target_km + Vector3(cross_r, 0.0, 0.0)) + Vector3(0.0, 0.011, 0.0)
	var ns0: Vector3 = war_table.theater_km_to_table_local(ground_target_km + Vector3(0.0, 0.0, -cross_r)) + Vector3(0.0, 0.011, 0.0)
	var ns1: Vector3 = war_table.theater_km_to_table_local(ground_target_km + Vector3(0.0, 0.0, cross_r)) + Vector3(0.0, 0.011, 0.0)
	_immediate.surface_set_color(reticle_color.lightened(0.2))
	_immediate.surface_add_vertex(ew0)
	_immediate.surface_add_vertex(ew1)
	_immediate.surface_add_vertex(ns0)
	_immediate.surface_add_vertex(ns1)

	var spire_top := center_local + Vector3(0.0, 0.14, 0.0)
	_immediate.surface_set_color(reticle_color)
	_immediate.surface_add_vertex(center_local)
	_immediate.surface_add_vertex(spire_top)

	# 3. Optional Dashed Inbound Arc from Origin / HQ Bunker
	if origin_km.x < 1e6:
		var ground_orig_km := Vector3(origin_km.x, 0.0, origin_km.z)
		var dist_km := Vector2(ground_orig_km.x, ground_orig_km.z).distance_to(Vector2(ground_target_km.x, ground_target_km.z))
		var apex_m := clampf(dist_km * 28.0, 1200.0, 6500.0)
		var arc_segs := 20
		for s in range(arc_segs):
			if s % 2 == 1:
				continue
			var t0 := float(s) / float(arc_segs)
			var t1 := float(s + 1) / float(arc_segs)
			var a0_km := Vector3(
				lerpf(ground_orig_km.x, ground_target_km.x, t0),
				4.0 * t0 * (1.0 - t0) * apex_m,
				lerpf(ground_orig_km.z, ground_target_km.z, t0)
			)
			var a1_km := Vector3(
				lerpf(ground_orig_km.x, ground_target_km.x, t1),
				4.0 * t1 * (1.0 - t1) * apex_m,
				lerpf(ground_orig_km.z, ground_target_km.z, t1)
			)
			_immediate.surface_set_color(reticle_color.lightened(0.15))
			_immediate.surface_add_vertex(war_table.theater_km_to_table_local(a0_km))
			_immediate.surface_add_vertex(war_table.theater_km_to_table_local(a1_km))

	_immediate.surface_end()

	# Position and scale the 3D Holographic Ring & Vertical Targeting Beam
	var ring_scale := clampf((radius_km / 25.0) * float(war_table.get("zoom_scale")), 0.65, 3.2)
	if _reticle_ring_mi != null:
		_reticle_ring_mi.position = center_local + Vector3(0.0, 0.015, 0.0)
		_reticle_ring_mi.scale = Vector3(ring_scale, 1.0, ring_scale)
		if _reticle_ring_mat != null:
			_reticle_ring_mat.albedo_color = Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.90)
		_reticle_ring_mi.visible = true
	if _reticle_beam_mi != null:
		_reticle_beam_mi.position = center_local + Vector3(0.0, 0.12, 0.0)
		if _reticle_beam_mat != null:
			_reticle_beam_mat.albedo_color = Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.48)
		_reticle_beam_mi.visible = true

	if _tot_label != null:
		_tot_label.modulate = reticle_color.lightened(0.28)
		_tot_label.font_size = 20
		_tot_label.pixel_size = 0.00068
		_tot_label.position = center_local + Vector3(0.0, 0.25, 0.0)
		_tot_label.text = "[ %s ]\nTARGET GRID: (%.0f, %.0f km) | BLAST/DROP RADIUS: %.0f km\n>> LEFT-CLICK MAP TO EXECUTE | RIGHT-CLICK TO CANCEL <<" % [
			tool_label, target_km.x, target_km.z, radius_km
		]
		_tot_label.visible = true


func clear_preview() -> void:
	is_preview_active = false
	if _immediate != null:
		_immediate.clear_surfaces()
	if _reticle_ring_mi != null:
		_reticle_ring_mi.visible = false
	if _reticle_beam_mi != null:
		_reticle_beam_mi.visible = false
	if _tot_label != null:
		_tot_label.visible = false

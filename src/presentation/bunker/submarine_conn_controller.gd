class_name SubmarineConnController
extends Node3D
## Phase 35: 688(I) Los Angeles / Virginia-Class Nuclear Attack Submarine VR & Desktop Sim Station:
## - Builds a 3D VR Submarine Control Room ("Conn") with physical Attack Periscope column & handles,
##   Broadband Sonar Waterfall console, Helm/Dive/Ballast Blow levers, and Torpedo/VLS Weapons panel.
## - Runs a dedicated 3D Ocean & Warships Periscope `SubViewport` (`periscope_ocean.gdshader`) with rolling
##   waves, 3D enemy Destroyers/Carriers/Submarines on the horizon, and 120m torpedo water geyser plumes.
## - Provides a full interactive 688(I) Submarine Conn & Periscope Eyepiece HUD (`toggle_sub_sim_active()`).

var sim_server: Node = null
var war_table: Node3D = null
var radio_synth: Node = null

var is_sub_sim_active: bool = false
var periscope_updates_count: int = 0

# 3D Ocean Periscope SubViewport & Scene Nodes
var _ocean_viewport: SubViewport = null
var _ocean_world_root: Node3D = null
var _ocean_camera: Camera3D = null
var _ocean_mesh_instance: MeshInstance3D = null
var _ocean_shader_mat: ShaderMaterial = null
var _sky_dome_mat: StandardMaterial3D = null
var _ship_nodes: Array[Node3D] = []
var _plume_nodes: Array[MeshInstance3D] = []

# 3D VR Submarine Control Room ("Conn") Nodes inside Bunker
var _conn_room_3d: Node3D = null
var _periscope_column_3d: Node3D = null
var _periscope_screen_3d: Sprite3D = null
var _conn_status_label_3d: Label3D = null

# 2D Interactive 688(I) Submarine Conn & Periscope Eyepiece HUD
var _hud_layer: CanvasLayer = null
var _hud_panel: PanelContainer = null
var _periscope_tex_rect: TextureRect = null
var _reticle_overlay_label: Label = null
var _telemetry_rich_label: RichTextLabel = null
var _sonar_waterfall_label: RichTextLabel = null
var _status_banner_label: Label = null
var _wave_time: float = 0.0


func _ready() -> void:
	if _ocean_viewport != null:
		return
	_build_3d_periscope_ocean_viewport()
	_build_3d_vr_submarine_conn_room()
	_build_2d_submarine_conn_hud()
	set_sub_sim_active(false)


func setup(p_sim_server: Node, p_war_table: Node3D, p_radio_synth: Node = null) -> void:
	sim_server = p_sim_server
	war_table = p_war_table
	radio_synth = p_radio_synth


func toggle_sub_sim_active() -> bool:
	set_sub_sim_active(not is_sub_sim_active)
	return is_sub_sim_active


func set_sub_sim_active(active: bool) -> void:
	is_sub_sim_active = active
	if sim_server != null and sim_server.world_state != null:
		sim_server.world_state.sub_sim_active = active
		if active and sim_server.has_method("ensure_player_submarine"):
			sim_server.call("ensure_player_submarine")
	if _conn_room_3d != null:
		_conn_room_3d.visible = active
	if _hud_panel != null:
		_hud_panel.visible = active
	if _ocean_viewport != null:
		_ocean_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if active:
		update_submarine_station(0.016)


func _build_3d_periscope_ocean_viewport() -> void:
	_ocean_viewport = SubViewport.new()
	_ocean_viewport.name = "PeriscopeOceanSubViewport"
	_ocean_viewport.size = Vector2i(640, 360)
	_ocean_viewport.own_world_3d = true
	_ocean_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_ocean_viewport)

	_ocean_world_root = Node3D.new()
	_ocean_world_root.name = "PeriscopeOceanWorld3D"
	_ocean_viewport.add_child(_ocean_world_root)

	# 1. Sky / Horizon Dome inside Periscope World
	var sky_mi := MeshInstance3D.new()
	var sky_sph := SphereMesh.new()
	sky_sph.radius = 140.0
	sky_sph.height = 280.0
	_sky_dome_mat = StandardMaterial3D.new()
	_sky_dome_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sky_dome_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	_sky_dome_mat.albedo_color = Color(0.18, 0.36, 0.54, 1.0)
	sky_sph.material = _sky_dome_mat
	sky_mi.mesh = sky_sph
	_ocean_world_root.add_child(sky_mi)

	# 2. Rolling 3D Gerstner Ocean Waves Mesh (`periscope_ocean.gdshader`)
	_ocean_mesh_instance = MeshInstance3D.new()
	_ocean_mesh_instance.name = "RollingOceanWavesMesh3D"
	var ocean_plane := PlaneMesh.new()
	ocean_plane.size = Vector2(220.0, 220.0)
	ocean_plane.subdivide_width = 96
	ocean_plane.subdivide_depth = 96
	_ocean_shader_mat = ShaderMaterial.new()
	_ocean_shader_mat.shader = load("res://src/presentation/war_table/shaders/periscope_ocean.gdshader")
	ocean_plane.material = _ocean_shader_mat
	_ocean_mesh_instance.mesh = ocean_plane
	_ocean_world_root.add_child(_ocean_mesh_instance)

	# 3. Periscope Eyepiece Camera3D (sits just above the rolling waves!)
	_ocean_camera = Camera3D.new()
	_ocean_camera.name = "PeriscopeEyepieceCamera3D"
	_ocean_camera.position = Vector3(0.0, 1.45, 0.0)
	_ocean_camera.fov = 48.0
	_ocean_world_root.add_child(_ocean_camera)

	# 4. Pool of 8 3D Warships / Carriers / Submarines visible on the ocean waves!
	for i in range(8):
		var ship_node := _create_3d_ocean_warship_node(i)
		ship_node.visible = false
		_ocean_world_root.add_child(ship_node)
		_ship_nodes.append(ship_node)

	# 5. Pool of 4 3D 120-Meter Torpedo Impact Water Plume Geysers!
	for p_i in range(4):
		var pl_mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 2.6
		cyl.bottom_radius = 0.8
		cyl.height = 14.0
		var p_mat := StandardMaterial3D.new()
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		p_mat.albedo_color = Color(0.92, 0.98, 1.0, 0.92)
		cyl.material = p_mat
		pl_mi.mesh = cyl
		pl_mi.visible = false
		_ocean_world_root.add_child(pl_mi)
		_plume_nodes.append(pl_mi)


func _create_3d_ocean_warship_node(idx: int) -> Node3D:
	var root := Node3D.new()
	root.name = "PeriscopeTargetShip3D_%d" % idx

	# Hull
	var hull_mi := MeshInstance3D.new()
	var hull_box := BoxMesh.new()
	hull_box.size = Vector3(2.4, 1.1, 9.5)
	var hull_mat := StandardMaterial3D.new()
	hull_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hull_mat.albedo_color = Color(0.28, 0.34, 0.40) if (idx % 2 == 0) else Color(0.36, 0.30, 0.28)
	hull_box.material = hull_mat
	hull_mi.mesh = hull_box
	hull_mi.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(hull_mi)

	# Superstructure Bridge & Mast
	var bridge_mi := MeshInstance3D.new()
	var br_box := BoxMesh.new()
	br_box.size = Vector3(1.6, 1.8, 2.8)
	var br_mat := StandardMaterial3D.new()
	br_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	br_mat.albedo_color = Color(0.45, 0.52, 0.58)
	br_box.material = br_mat
	bridge_mi.mesh = br_box
	bridge_mi.position = Vector3(0.0, 1.55, -0.8)
	root.add_child(bridge_mi)

	# White Foam Bow/Stern Wake
	var wake_mi := MeshInstance3D.new()
	var wake_plane := PlaneMesh.new()
	wake_plane.size = Vector2(3.6, 13.0)
	var wake_mat := StandardMaterial3D.new()
	wake_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wake_mat.albedo_color = Color(0.85, 0.96, 1.0, 0.75)
	wake_plane.material = wake_mat
	wake_mi.mesh = wake_plane
	wake_mi.position = Vector3(0.0, 0.08, 1.2)
	root.add_child(wake_mi)

	# Floating 3D Target Designation Label above ship in Periscope view
	var lbl := Label3D.new()
	lbl.name = "ShipLabel3D"
	lbl.text = "OPFOR WARSHIP"
	lbl.font_size = 28
	lbl.pixel_size = 0.015
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1.0, 0.32, 0.38, 0.96)
	lbl.position = Vector3(0.0, 3.6, 0.0)
	root.add_child(lbl)

	return root


func _build_3d_vr_submarine_conn_room() -> void:
	_conn_room_3d = Node3D.new()
	_conn_room_3d.name = "SubmarineConnRoom3D"
	_conn_room_3d.position = Vector3(0.0, 0.88, -0.35)
	add_child(_conn_room_3d)

	# 1. Central Attack Periscope Column & VR Grab Handles
	_periscope_column_3d = Node3D.new()
	_periscope_column_3d.name = "AttackPeriscopeColumn3D"
	_conn_room_3d.add_child(_periscope_column_3d)

	var post_mi := MeshInstance3D.new()
	var post_cyl := CylinderMesh.new()
	post_cyl.top_radius = 0.045
	post_cyl.bottom_radius = 0.055
	post_cyl.height = 1.65
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.18, 0.22, 0.26)
	post_mat.metallic = 0.85
	post_mat.roughness = 0.25
	post_cyl.material = post_mat
	post_mi.mesh = post_cyl
	post_mi.position = Vector3(0.0, 0.45, 0.0)
	_periscope_column_3d.add_child(post_mi)

	# Left & Right Periscope Brass/Steel Grab Handles for VR
	for side in [-1.0, 1.0]:
		var h_mi := MeshInstance3D.new()
		var h_box := BoxMesh.new()
		h_box.size = Vector3(0.18, 0.025, 0.025)
		h_box.material = post_mat
		h_mi.mesh = h_box
		h_mi.position = Vector3(side * 0.11, 0.32, 0.06)
		_periscope_column_3d.add_child(h_mi)

	# 2. 3D Holographic Periscope Viewport Screen mounted on the Conn Periscope Station
	_periscope_screen_3d = Sprite3D.new()
	_periscope_screen_3d.name = "PeriscopeOpticsScreen3D"
	_periscope_screen_3d.texture = _ocean_viewport.get_texture()
	_periscope_screen_3d.pixel_size = 0.0012
	_periscope_screen_3d.position = Vector3(0.0, 0.42, 0.08)
	_conn_room_3d.add_child(_periscope_screen_3d)

	_conn_status_label_3d = Label3D.new()
	_conn_status_label_3d.name = "SubConnStatusLabel3D"
	_conn_status_label_3d.text = "SSN-688(I) USS CHEYENNE // PERISCOPE DEPTH 58 FT"
	_conn_status_label_3d.font_size = 22
	_conn_status_label_3d.pixel_size = 0.00085
	_conn_status_label_3d.modulate = Color(0.20, 1.0, 0.65)
	_conn_status_label_3d.position = Vector3(0.0, 0.72, 0.08)
	_conn_room_3d.add_child(_conn_status_label_3d)


func _build_2d_submarine_conn_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "SubmarineConnHUDLayer"
	_hud_layer.layer = 8
	add_child(_hud_layer)

	var theme := TacticalTheme.create_theme()
	_hud_panel = PanelContainer.new()
	_hud_panel.name = "SubmarineConnMainPanel"
	_hud_panel.theme = theme
	_hud_panel.anchor_left = 0.5
	_hud_panel.anchor_right = 0.5
	_hud_panel.anchor_top = 0.5
	_hud_panel.anchor_bottom = 0.5
	_hud_panel.offset_left = -560.0
	_hud_panel.offset_right = 560.0
	_hud_panel.offset_top = -330.0
	_hud_panel.offset_bottom = 330.0
	_hud_layer.add_child(_hud_panel)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 6)
	_hud_panel.add_child(root_vb)

	# 1. Header Bar: Submarine Name + Return to Bunker War Table Button
	var hdr_hb := HBoxContainer.new()
	root_vb.add_child(hdr_hb)

	var title_lbl := Label.new()
	title_lbl.text = "● 688(I) NUCLEAR ATTACK SUBMARINE VR CONN // USS CHEYENNE (SSN-773) — LIVE WAR TABLE INTEGRATION"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	hdr_hb.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "[RETURN TO BUNKER WAR TABLE (;)]"
	close_btn.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	close_btn.pressed.connect(func(): set_sub_sim_active(false))
	hdr_hb.add_child(close_btn)

	# 2. Center Split: Left = 3D Periscope Ocean & Ships Viewport | Right = Broadband Sonar Waterfall & Gauges
	var mid_hb := HBoxContainer.new()
	mid_hb.add_theme_constant_override("separation", 10)
	mid_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(mid_hb)

	var scope_panel := PanelContainer.new()
	scope_panel.custom_minimum_size = Vector2(620.0, 350.0)
	mid_hb.add_child(scope_panel)

	_periscope_tex_rect = TextureRect.new()
	_periscope_tex_rect.name = "PeriscopeOceanTextureRect"
	_periscope_tex_rect.texture = _ocean_viewport.get_texture()
	_periscope_tex_rect.custom_minimum_size = Vector2(612.0, 342.0)
	_periscope_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_periscope_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scope_panel.add_child(_periscope_tex_rect)

	_reticle_overlay_label = Label.new()
	_reticle_overlay_label.text = "       [ 000° ]       \n          |          \n   --- ( + ) ---   \n          |          "
	_reticle_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reticle_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reticle_overlay_label.add_theme_color_override("font_color", Color(0.15, 1.0, 0.45, 0.88))
	scope_panel.add_child(_reticle_overlay_label)

	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)
	mid_hb.add_child(right_vb)

	_telemetry_rich_label = RichTextLabel.new()
	_telemetry_rich_label.bbcode_enabled = true
	_telemetry_rich_label.custom_minimum_size = Vector2(450.0, 165.0)
	right_vb.add_child(_telemetry_rich_label)

	_sonar_waterfall_label = RichTextLabel.new()
	_sonar_waterfall_label.bbcode_enabled = true
	_sonar_waterfall_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sonar_waterfall_label.custom_minimum_size = Vector2(450.0, 175.0)
	right_vb.add_child(_sonar_waterfall_label)

	# 3. Tactile 688(I) Submarine Control Consoles (Helm, Depth/Thermocline, Periscope, Torpedoes & VLS)
	var row1_hb := HBoxContainer.new()
	row1_hb.add_theme_constant_override("separation", 5)
	root_vb.add_child(row1_hb)

	var cmds_row1 := [
		["PERISCOPE DEPTH (58 FT)", "SUB_SET_DEPTH_PERISCOPE", 0.0, TacticalTheme.COL_NATO_BLUE],
		["BELOW THERMOCLINE (420 FT)", "SUB_SET_DEPTH_THERMOCLINE", 0.0, TacticalTheme.COL_FLIR_GREEN],
		["DEEP SILENT (950 FT)", "SUB_SET_DEPTH_DEEP", 0.0, TacticalTheme.COL_CONTOUR_EMERALD],
		["! EMERGENCY BLOW (0 FT) !", "SUB_EMERGENCY_BLOW", 0.0, TacticalTheme.COL_OPFOR_RED],
		["THROTTLE (0..33 KT)", "SUB_CYCLE_THROTTLE", 0.0, TacticalTheme.COL_UNMANNED_GOLD],
		["SILENT RUNNING", "SUB_TOGGLE_SILENT_RUNNING", 0.0, TacticalTheme.COL_NATO_BLUE],
	]
	for c1 in cmds_row1:
		var btn := Button.new()
		btn.text = String(c1[0])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_color_override("font_color", c1[3])
		var code := String(c1[1])
		var prm := float(c1[2])
		btn.pressed.connect(func(): execute_sub_action(code, prm))
		row1_hb.add_child(btn)

	var row2_hb := HBoxContainer.new()
	row2_hb.add_theme_constant_override("separation", 5)
	root_vb.add_child(row2_hb)

	var cmds_row2 := [
		["<< PAN SCOPE -20°", "SUB_PAN_PERISCOPE", -20.0, TacticalTheme.COL_NATO_BLUE],
		["PAN SCOPE +20° >>", "SUB_PAN_PERISCOPE", 20.0, TacticalTheme.COL_NATO_BLUE],
		["UP/DOWN SCOPE", "SUB_TOGGLE_PERISCOPE", 0.0, TacticalTheme.COL_FLIR_GREEN],
		["OPTICS: EO/NVG/FLIR", "SUB_CYCLE_OPTICS", 0.0, TacticalTheme.COL_UNMANNED_GOLD],
		["LOCK NEXT SONAR TARGET", "SUB_CYCLE_TARGET", 0.0, TacticalTheme.COL_FLIR_GREEN],
		["FIRE MK 48 TORPEDO!", "SUB_FIRE_TORPEDO", 0.0, TacticalTheme.COL_OPFOR_RED],
		["LAUNCH VLS TOMAHAWK!", "SUB_LAUNCH_VLS_TOMAHAWK", 0.0, TacticalTheme.COL_UNMANNED_GOLD],
		["MOSS DECOY", "SUB_LAUNCH_DECOY", 0.0, TacticalTheme.COL_DIRECTED_ENERGY],
	]
	for c2 in cmds_row2:
		var btn2 := Button.new()
		btn2.text = String(c2[0])
		btn2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn2.add_theme_color_override("font_color", c2[3])
		var code2 := String(c2[1])
		var prm2 := float(c2[2])
		btn2.pressed.connect(func(): execute_sub_action(code2, prm2))
		row2_hb.add_child(btn2)

	_status_banner_label = Label.new()
	_status_banner_label.text = "CONN, SONAR: Steady at Periscope Depth (58 ft). Towed array active."
	_status_banner_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	root_vb.add_child(_status_banner_label)


func execute_sub_action(cmd_code: String, param: float = 0.0) -> Dictionary:
	if sim_server == null or not sim_server.has_method("execute_submarine_command"):
		return {"ok": false}
	var res: Dictionary = sim_server.call("execute_submarine_command", cmd_code, param)
	update_submarine_station(0.016)
	return res


func _process(delta: float) -> void:
	if is_sub_sim_active:
		update_submarine_station(delta)


func update_submarine_station(delta: float) -> void:
	if sim_server == null or sim_server.world_state == null:
		return
	var ws: WorldState = sim_server.world_state
	_wave_time += delta
	periscope_updates_count += 1

	# 1. Update Ocean Shader (Submerged depth factor, FLIR mode & wave chop)
	var sub_factor := clampf((ws.sub_depth_ft - 65.0) / 180.0, 0.0, 1.0)
	if not ws.sub_periscope_raised:
		sub_factor = maxf(sub_factor, 0.75)
	if _ocean_shader_mat != null:
		_ocean_shader_mat.set_shader_parameter("submerged_factor", sub_factor)
		_ocean_shader_mat.set_shader_parameter("flir_mode", ws.sub_periscope_flir_mode)
		_ocean_shader_mat.set_shader_parameter("wave_height", 0.55 + float(ws.sea_state_beaufort) * 0.12)

	if _sky_dome_mat != null:
		if ws.sub_periscope_flir_mode == 1:
			_sky_dome_mat.albedo_color = Color(0.03, 0.28, 0.09)
		elif ws.sub_periscope_flir_mode == 2:
			_sky_dome_mat.albedo_color = Color(0.22, 0.22, 0.22)
		elif sub_factor > 0.4:
			_sky_dome_mat.albedo_color = Color(0.01, 0.09, 0.18)
		else:
			_sky_dome_mat.albedo_color = Color(0.22, 0.44, 0.66)

	# 2. Orient Periscope Camera3D along `sub_periscope_bearing_deg` with gentle wave bob
	if _ocean_camera != null:
		var bob_y := sin(_wave_time * 2.2) * 0.18 * (1.0 - sub_factor * 0.7)
		_ocean_camera.position = Vector3(0.0, 1.55 + bob_y, 0.0)
		var yaw_rad := deg_to_rad(-ws.sub_periscope_bearing_deg)
		_ocean_camera.rotation = Vector3(sin(_wave_time * 1.6) * 0.02, yaw_rad, cos(_wave_time * 1.4) * 0.02)
		_ocean_camera.fov = clampf(48.0 / maxf(1.0, sqrt(ws.sub_periscope_zoom_x)), 14.0, 52.0)

	# 3. Position 3D Enemy Warships & Submarines on the rolling ocean waves around the Periscope!
	var contacts: Array[Dictionary] = ws.sub_sonar_contacts
	for i in range(_ship_nodes.size()):
		var snode := _ship_nodes[i]
		if i < contacts.size():
			var c: Dictionary = contacts[i]
			var brg_rad := deg_to_rad(float(c["bearing_deg"]))
			var vis_dist_m := clampf(float(c["range_km"]) * 2.4, 18.0, 82.0)
			var sx := sin(brg_rad) * vis_dist_m
			var sz := -cos(brg_rad) * vis_dist_m
			var wave_y := sin(sx * 0.45 + sz * 0.25 + _wave_time * 1.8) * 0.35
			var is_sub_contact := bool(c.get("is_sub", false))
			snode.position = Vector3(sx, (-2.2 if is_sub_contact else wave_y), sz)
			snode.rotation = Vector3(sin(_wave_time * 1.9 + float(i)) * 0.05, brg_rad + PI * 0.5, cos(_wave_time * 1.5 + float(i)) * 0.06)
			snode.visible = true
			var lbl := snode.get_node_or_null("ShipLabel3D") as Label3D
			if lbl != null:
				lbl.text = "[%s] %.1f KM (%03d°)" % [String(c["name"]).substr(0, 20), float(c["range_km"]), int(c["bearing_deg"])]
		else:
			snode.visible = false

	# 4. Render 3D 120-Meter Torpedo Impact Water Plume Geysers in Periscope View!
	for p_i in range(_plume_nodes.size()):
		var pl_node := _plume_nodes[p_i]
		if p_i < ws.sub_water_plumes.size():
			var brg_rad_p := deg_to_rad(ws.sub_locked_target_bearing_deg)
			var p_dist := clampf(ws.sub_locked_target_range_km * 2.4, 20.0, 65.0)
			pl_node.position = Vector3(sin(brg_rad_p) * p_dist, 6.0, -cos(brg_rad_p) * p_dist)
			pl_node.visible = true
		else:
			pl_node.visible = false

	# 5. Update 2D / VR Periscope Reticle, Gauges & Broadband Sonar Waterfall
	if _reticle_overlay_label != null:
		var scope_state := "UP SCOPE (CLEAR WAVE HORIZON)" if (ws.sub_periscope_raised and ws.sub_depth_ft <= 75.0) else "SUBMERGED DEEP ABYSS VIEW"
		_reticle_overlay_label.text = (
			"[ BRG %03d° | ZOOM %.0fx | %s | TARGET: %s (%.1f KM) ]\n\n" % [
				int(ws.sub_periscope_bearing_deg), ws.sub_periscope_zoom_x, scope_state,
				ws.sub_locked_target_name.substr(0, 24), ws.sub_locked_target_range_km
			]
			+ "                  |                  \n"
			+ "          ---  (  +  )  ---          \n"
			+ "                  |                  "
		)

	if _telemetry_rich_label != null:
		var therm_state := "[color=#00FF9D]BELOW 280 FT THERMOCLINE (SONAR MASKED)[/color]" if ws.sub_depth_ft >= ws.sub_thermocline_depth_ft else "[color=#FFD940]SHALLOW / PERISCOPE LAYER[/color]"
		var cav_state := "[color=#FF2A54]CAVITATING! (LOUD SCREW)[/color]" if ws.sub_cavitating else "[color=#00FF9D]QUIET PROPULSION[/color]"
		_telemetry_rich_label.text = (
			"[b][color=#00D8FF]688(I) HULL, REACTOR & DIVING TELEMETRY:[/color][/b]\n"
			+ "Depth: [b]%.0f ft[/b] (Ordered: %.0f ft) | %s\n" % [ws.sub_depth_ft, ws.sub_target_depth_ft, therm_state]
			+ "Course: [b]%03d°[/b] | Speed: [b]%.1f kts[/b] | Noise: [b]%.0f dB[/b] (%s)\n" % [
				int(ws.sub_heading_deg), ws.sub_speed_kts, ws.sub_own_noise_db, cav_state
			]
			+ "Mk 48 ADCAP Torpedoes: [b][color=#00FF9D]%d[/color][/b] (Fired: %d | Ships Sunk: %d)\n" % [
				ws.sub_torpedoes_remaining, ws.sub_torpedoes_fired_count, ws.sub_ships_sunk_count
			]
			+ "VLS Tomahawk / Cruise Missiles: [b][color=#FFD940]%d[/color][/b] | MOSS Decoys: [b]%d[/b]" % [
				ws.sub_vls_tomahawks_remaining, ws.sub_decoys_remaining
			]
		)

	if _sonar_waterfall_label != null:
		var sb := "[b][color=#00FF9D]AN/BQQ-5 BROADBAND / TOWED ARRAY SONAR WATERFALL:[/color][/b]\n"
		if contacts.is_empty():
			sb += "[color=#88AA99]No hostile acoustic signatures within 120 km.[/color]\n"
		else:
			for c in contacts:
				var is_locked := (int(c["uid"]) == ws.sub_locked_target_uid)
				var tag := ">>> [LOCKED] " if is_locked else "    "
				var cls_tag := "SSN-SUB" if bool(c["is_sub"]) else "WARSHIP"
				var col_hex := "#FF2A54" if is_locked else "#00FF9D"
				sb += "[color=%s]%sBRG %03d° | %5.1f KM | %.0f dB | [%s] %s[/color]\n" % [
					col_hex, tag, int(c["bearing_deg"]), float(c["range_km"]), float(c["noise_db"]),
					cls_tag, String(c["name"]).substr(0, 26)
				]
		_sonar_waterfall_label.text = sb

	if _status_banner_label != null:
		_status_banner_label.text = ws.sub_status_log
	if _conn_status_label_3d != null:
		_conn_status_label_3d.text = "%s // DEPTH %.0f FT // SPD %.0f KT // %s" % [
			ws.sub_hull_name, ws.sub_depth_ft, ws.sub_speed_kts, ws.sub_locked_target_name.substr(0, 22)
		]

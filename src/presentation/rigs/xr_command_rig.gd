class_name XRCommandRig
extends XROrigin3D
## OpenXR Meta Quest 3 / PCVR Command Rig + Desktop VR Hand Simulator (`[F11]`).
## Provides full feature parity between VR and Desktop:
## - Two-handed holographic War Table pinch-zoom (`0.15x` Planetary Globe -> `25.0x` Tactical Valley) & grab-pan
## - Single-hand grab-pan on the War Table and 3D Planetary Globe rotation
## - Dual 3D Tactical Gauntlets with dynamic color-coded 3D Laser Pointers & Target Reticle Rings
## - 3D Laser Unit Picking, 3D Holographic Sphere Volume Group Selection, and 1-Button Battalion/Brigade Escalation (`A` button)
## - 3D Laser Waypoint & Strike Salvo Order Issuing (`Left Trigger` / `Right B` button)
## - Physical 3D Hand Poke & Laser Actuation of all 10 switches/buttons on `TactileConsole`
## - Diegetic 3D Left-Wrist C4ISR Command Tablet displaying live Casualties (`KIA`/`WIA`), Ammunition Stocks, and Force Organization

var xr_camera: XRCamera3D = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null

var war_table: Node3D = null
var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null
var tactile_console: Node3D = null
var desktop_rig: Node3D = null
var main_menu: Node = null

var is_xr_active: bool = false
var vr_simulator_mode: bool = false

# 3D Hand Models, Laser Beams, Reticles, Selection Sphere & Left-Wrist C4ISR Tablet
var _left_hand_visual: Node3D = null
var _right_hand_visual: Node3D = null
var _left_laser_beam: MeshInstance3D = null
var _right_laser_beam: MeshInstance3D = null
var _left_reticle: MeshInstance3D = null
var _right_reticle: MeshInstance3D = null
var _vr_selection_sphere: MeshInstance3D = null
var _wrist_tablet_root: Node3D = null
var _wrist_label_3d: Label3D = null
var _wrist_buttons: Dictionary = {}
var tri_command_ref: Node3D = null
var _current_tactical_posture_idx: int = 0
const POSTURE_NAMES: Array[String] = ["AUTO", "BVR", "PURSUIT", "BREAK"]
const POSTURE_VALUES: Array[int] = [
	WorldState.TACTICAL_POSTURE_AUTO,
	WorldState.TACTICAL_POSTURE_BVR_STANDOFF,
	WorldState.TACTICAL_POSTURE_AGGRESSIVE_PURSUIT,
	WorldState.TACTICAL_POSTURE_DEFENSIVE_BREAK
]

# Controller State Tracking
var _two_hand_initial_dist: float = 0.0
var _two_hand_initial_zoom: float = 1.0
var _two_hand_initial_mid: Vector3 = Vector3.ZERO
var _two_hand_initial_pan_km: Vector2 = Vector2.ZERO
var _single_grip_hand: String = ""
var _single_grip_start_pos: Vector3 = Vector3.ZERO
var _single_grip_start_pan_km: Vector2 = Vector2.ZERO

var _prev_r_trigger: bool = false
var _prev_l_trigger: bool = false
var _prev_r_ax: bool = false
var _prev_r_by: bool = false
var _prev_l_ax: bool = false
var _prev_l_by: bool = false

var _r_trig_press_world: Vector3 = Vector3.ZERO
var _r_trig_dragging_sphere: bool = false
var _echelon_cycle_stage: int = 0
var haptic_pulses_triggered: int = 0
var designated_target_uid: int = -1
var _wrist_update_accum: float = 99.0
var _laser_hover_frame: int = 0


func _ready() -> void:
	if xr_camera != null:
		return
	xr_camera = XRCamera3D.new()
	xr_camera.name = "XRCamera3D"
	xr_camera.position = Vector3(0.0, 1.65, 0.95)
	add_child(xr_camera)

	left_controller = XRController3D.new()
	left_controller.name = "LeftHandController"
	left_controller.tracker = &"left_hand"
	left_controller.position = Vector3(-0.34, 1.16, 0.72)
	left_controller.rotation_degrees = Vector3(-28.0, 12.0, 0.0)
	add_child(left_controller)

	right_controller = XRController3D.new()
	right_controller.name = "RightHandController"
	right_controller.tracker = &"right_hand"
	right_controller.position = Vector3(0.32, 1.16, 0.72)
	right_controller.rotation_degrees = Vector3(-32.0, -10.0, 0.0)
	add_child(right_controller)

	_build_vr_hand_and_wrist_visuals()
	_update_vr_visuals_visibility()


func setup(p_war_table: Node3D, p_sim_server: Node, p_cmd_bus: Node, p_sig_bus: Node, p_console: Node3D, p_desktop_rig: Node3D = null, p_main_menu: Node = null) -> void:
	war_table = p_war_table
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	tactile_console = p_console
	desktop_rig = p_desktop_rig
	main_menu = p_main_menu


func _build_vr_hand_and_wrist_visuals() -> void:
	# 1. Left & Right 3D Tactical Gauntlets + Laser Pointers + Reticles
	_left_hand_visual = _create_hand_gauntlet("LeftGauntlet3D", TacticalTheme.COL_NATO_BLUE)
	left_controller.add_child(_left_hand_visual)
	_left_laser_beam = _create_laser_beam("LeftLaserBeam3D", Color(0.0, 0.88, 1.0, 0.55))
	left_controller.add_child(_left_laser_beam)
	_left_reticle = _create_laser_reticle("LeftLaserReticle3D", TacticalTheme.COL_NATO_BLUE)
	add_child(_left_reticle)

	_right_hand_visual = _create_hand_gauntlet("RightGauntlet3D", TacticalTheme.COL_UNMANNED_GOLD)
	right_controller.add_child(_right_hand_visual)
	_right_laser_beam = _create_laser_beam("RightLaserBeam3D", Color(1.0, 0.82, 0.22, 0.65))
	right_controller.add_child(_right_laser_beam)
	_right_reticle = _create_laser_reticle("RightLaserReticle3D", TacticalTheme.COL_UNMANNED_GOLD)
	add_child(_right_reticle)

	# 2. 3D Holographic Sphere Volume Selector (expands when dragging Right Trigger in VR)
	_vr_selection_sphere = MeshInstance3D.new()
	_vr_selection_sphere.name = "VRSelectionVolumeSphere3D"
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	var s_mat := StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(0.0, 0.88, 1.0, 0.24)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sph.material = s_mat
	_vr_selection_sphere.mesh = sph
	_vr_selection_sphere.visible = false
	add_child(_vr_selection_sphere)

	# 3. Diegetic 3D Left-Wrist C4ISR Holographic Command Tablet
	_wrist_tablet_root = Node3D.new()
	_wrist_tablet_root.name = "LeftWristC4ISRTablet3D"
	_wrist_tablet_root.position = Vector3(0.06, 0.055, -0.04)
	_wrist_tablet_root.rotation_degrees = Vector3(-35.0, -18.0, 12.0)
	left_controller.add_child(_wrist_tablet_root)

	var tablet_glass := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(0.26, 0.145, 0.008)
	var t_mat := StandardMaterial3D.new()
	t_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	t_mat.albedo_color = Color(0.02, 0.07, 0.13, 0.84)
	t_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	t_box.material = t_mat
	tablet_glass.mesh = t_box
	_wrist_tablet_root.add_child(tablet_glass)

	var tablet_rim := MeshInstance3D.new()
	var r_box := BoxMesh.new()
	r_box.size = Vector3(0.268, 0.152, 0.004)
	var r_mat := StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = Color(0.0, 0.85, 1.0, 0.45)
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_box.material = r_mat
	tablet_rim.mesh = r_box
	tablet_rim.position = Vector3(0.0, 0.0, -0.003)
	_wrist_tablet_root.add_child(tablet_rim)

	_wrist_label_3d = Label3D.new()
	_wrist_label_3d.name = "WristTelemetryLabel3D"
	_wrist_label_3d.text = "VR C4ISR WRIST DISPLAY // READY"
	_wrist_label_3d.font_size = 11
	_wrist_label_3d.pixel_size = 0.00035
	_wrist_label_3d.position = Vector3(0.0, 0.022, 0.006)
	_wrist_label_3d.modulate = TacticalTheme.COL_NATO_BLUE
	_wrist_tablet_root.add_child(_wrist_label_3d)

	# 4. Interactive Virtual Smartwatch Buttons (Floor Mode, AI Posture, Time Compression, SSBN, Alpha Strike, Unit Tactical Trial)
	_create_wrist_button("btn_floor", "FLOOR\nOFF", -0.100, -0.046, TacticalTheme.COL_CONTOUR_EMERALD)
	_create_wrist_button("btn_posture", "AI POST\nAUTO", -0.060, -0.046, TacticalTheme.COL_NATO_BLUE)
	_create_wrist_button("btn_time", "TIME\n1x", -0.020, -0.046, TacticalTheme.COL_UNMANNED_GOLD)
	_create_wrist_button("btn_ssbn", "SSBN\nOFF", 0.020, -0.046, TacticalTheme.COL_FLIR_GREEN)
	_create_wrist_button("btn_strike", "ALPHA\nSTRIKE", 0.060, -0.046, TacticalTheme.COL_OPFOR_RED)
	_create_wrist_button("btn_trial", "TRIAL\nARENA", 0.100, -0.046, TacticalTheme.COL_NATO_BLUE)
	# FEAT-10: Tri-Command Headquarters (BKR / SSBN / E-4B)
	_create_wrist_button("btn_hq", "HQ:\nBKR", -0.060, -0.076, TacticalTheme.COL_FLIR_GREEN)
	# US-11.3: C4ISR SITREP, DEFCON Threat Monitor & Theater Mode Toggle
	_create_wrist_button("btn_sitrep", "C4ISR\nSITREP", -0.020, -0.076, TacticalTheme.COL_NATO_BLUE)
	_create_wrist_button("btn_defcon", "DEFCON\nSTAT", 0.020, -0.076, TacticalTheme.COL_UNMANNED_GOLD)
	_create_wrist_button("btn_theater", "THEATER\nMAP", 0.060, -0.076, TacticalTheme.COL_CONTOUR_EMERALD)


func _create_wrist_button(id: String, label_text: String, local_x: float, local_y: float, col: Color, half_w: float = 0.018, half_h: float = 0.012) -> void:
	var btn_node := Node3D.new()
	btn_node.name = "WristBtn_" + id
	btn_node.position = Vector3(local_x, local_y, 0.006)
	_wrist_tablet_root.add_child(btn_node)

	var bg_mi := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(half_w * 2.0, half_h * 2.0, 0.006)
	var b_mat := StandardMaterial3D.new()
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.9)
	bg_mi.mesh = b_box
	btn_node.add_child(bg_mi)

	var border_mi := MeshInstance3D.new()
	var border_box := BoxMesh.new()
	border_box.size = Vector3(half_w * 2.0 + 0.002, half_h * 2.0 + 0.002, 0.002)
	var border_mat := StandardMaterial3D.new()
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.albedo_color = col
	border_mi.mesh = border_box
	border_mi.position = Vector3(0.0, 0.0, -0.002)
	btn_node.add_child(border_mi)

	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.text = label_text
	lbl.font_size = 9
	lbl.pixel_size = 0.00035
	lbl.position = Vector3(0.0, 0.0, 0.004)
	lbl.modulate = col
	btn_node.add_child(lbl)

	_wrist_buttons[id] = {
		"node": btn_node,
		"label": lbl,
		"bg": bg_mi,
		"col": col,
		"center_x": local_x,
		"center_y": local_y,
		"half_w": half_w,
		"half_h": half_h
	}


func pick_wrist_button_by_ray(orig: Vector3, dir: Vector3) -> String:
	if _wrist_tablet_root == null or not _wrist_tablet_root.is_inside_tree() or not _wrist_tablet_root.visible:
		return ""
	var tablet_trans: Transform3D = _wrist_tablet_root.global_transform
	var normal: Vector3 = tablet_trans.basis.z.normalized()
	var center: Vector3 = tablet_trans.origin
	var d := normal.dot(dir)
	if absf(d) < 0.0001:
		return ""
	var t := normal.dot(center - orig) / d
	if t <= 0.0 or t > 3.0:
		return ""
	var hit_world: Vector3 = orig + dir * t
	var inv_trans: Transform3D = tablet_trans.affine_inverse()
	var local_hit: Vector3 = inv_trans * hit_world

	for btn_id in _wrist_buttons:
		var btn: Dictionary = _wrist_buttons[btn_id]
		var dx := absf(local_hit.x - float(btn["center_x"]))
		var dy := absf(local_hit.y - float(btn["center_y"]))
		if dx <= float(btn["half_w"]) and dy <= float(btn["half_h"]):
			return btn_id
	return ""


func get_wrist_tablet_transform() -> Transform3D:
	if _wrist_tablet_root == null:
		return Transform3D.IDENTITY
	return _wrist_tablet_root.global_transform if _wrist_tablet_root.is_inside_tree() else _wrist_tablet_root.transform


## US-11.3: Direct physical finger touch proximity check for smartwatch buttons
func pick_wrist_button_by_touch(touch_world_pos: Vector3, touch_margin: float = 0.01) -> String:
	if _wrist_tablet_root == null or not _wrist_tablet_root.visible:
		return ""
	var tablet_trans: Transform3D = get_wrist_tablet_transform()
	var inv_trans: Transform3D = tablet_trans.affine_inverse()
	var local_hit: Vector3 = inv_trans * touch_world_pos

	if absf(local_hit.z) > 0.035:
		return ""

	var best_btn := ""
	var best_dist_sq := 1e9

	for btn_id in _wrist_buttons:
		var btn: Dictionary = _wrist_buttons[btn_id]
		var dx := absf(local_hit.x - float(btn["center_x"]))
		var dy := absf(local_hit.y - float(btn["center_y"]))
		if dx <= (float(btn["half_w"]) + touch_margin) and dy <= (float(btn["half_h"]) + touch_margin):
			var d_sq := dx * dx + dy * dy
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_btn = btn_id
	return best_btn


func actuate_wrist_button(btn_id: String) -> String:
	match btn_id:
		"btn_floor":
			if war_table != null and war_table.has_method("toggle_floor_mode"):
				var is_fl: bool = war_table.toggle_floor_mode()
				if _wrist_buttons.has("btn_floor"):
					_wrist_buttons["btn_floor"]["label"].text = "FLOOR\nON" if is_fl else "FLOOR\nOFF"
				return "FLOOR_MODE_%s" % ("ON" if is_fl else "OFF")
		"btn_posture":
			_current_tactical_posture_idx = (_current_tactical_posture_idx + 1) % POSTURE_VALUES.size()
			var posture: int = POSTURE_VALUES[_current_tactical_posture_idx]
			var p_name: String = POSTURE_NAMES[_current_tactical_posture_idx]
			if _wrist_buttons.has("btn_posture"):
				_wrist_buttons["btn_posture"]["label"].text = "AI POST\n" + p_name
			if command_bus != null:
				var uids: Array[int] = []
				if desktop_rig != null and not desktop_rig.selected_unit_ids.is_empty():
					uids = desktop_rig.selected_unit_ids.duplicate()
				elif sim_server != null:
					var st: WorldState = sim_server.world_state
					for u in range(st.unit_count):
						if st.unit_active[u] == 1 and st.unit_faction[u] == WorldState.FACTION_BLUE:
							var pdef: Dictionary = sim_server.sim_db_ref.get_platform(st.unit_platform_id[u])
							if pdef.get("domain", "") == "AIR":
								uids.append(u)
				if not uids.is_empty():
					command_bus.enqueue_set_tactical_posture(uids, posture)
			return "POSTURE_" + p_name
		"btn_time":
			var new_scale := vr_cycle_time_scale()
			if _wrist_buttons.has("btn_time"):
				_wrist_buttons["btn_time"]["label"].text = "TIME\n%.0fx" % new_scale
			return "TIME_%.0fX" % new_scale
		"btn_ssbn":
			if desktop_rig != null and desktop_rig.submarine_conn_ref != null:
				var active: bool = desktop_rig.submarine_conn_ref.toggle_sub_sim_active()
				if _wrist_buttons.has("btn_ssbn"):
					_wrist_buttons["btn_ssbn"]["label"].text = "SSBN\nON" if active else "SSBN\nOFF"
				return "SSBN_%s" % ("ON" if active else "OFF")
		"btn_strike":
			if tactile_console != null:
				var sel_uid: int = desktop_rig.selected_unit_id if desktop_rig != null else -1
				tactile_console.actuate_control("alpha_strike", sel_uid)
				return "ALPHA_STRIKE"
		"btn_trial":
			var trial_res := launch_selected_unit_trial()
			return "TRIAL_LAUNCHED_" + String(trial_res.get("trial_title", "OK"))
		"btn_hq":
			if tri_command_ref != null and tri_command_ref.has_method("cycle_next_station"):
				var next_st: int = tri_command_ref.cycle_next_station()
				var s_name: String = tri_command_ref.get_station_short_name(next_st)
				if _wrist_buttons.has("btn_hq"):
					_wrist_buttons["btn_hq"]["label"].text = "HQ:\n" + s_name
				return "HQ_SWITCHED_" + s_name
			return "HQ_SWITCHED_OK"
		"btn_story_tree":
			if war_table != null and war_table.has_method("toggle_display_mode"):
				war_table.toggle_display_mode()
				var is_tree: bool = war_table.is_story_tree_active()
				if _wrist_buttons.has("btn_story_tree"):
					_wrist_buttons["btn_story_tree"]["label"].text = "TREE:\nON" if is_tree else "TREE:\nOFF"
				return "STORY_TREE_" + ("ON" if is_tree else "OFF")
		"btn_sitrep":
			if sim_server != null and _wrist_label_3d != null:
				var st: WorldState = sim_server.world_state
				var air_cnt := 0
				var sea_cnt := 0
				for u in range(st.unit_count):
					if st.unit_active[u] == 1 and st.unit_faction[u] == WorldState.FACTION_BLUE:
						var dom: int = int(sim_server.sim_db_ref.plat_domain_id[st.unit_platform_id[u]]) if (sim_server.sim_db_ref != null and st.unit_platform_id[u] < sim_server.sim_db_ref.plat_domain_id.size()) else -1
						if dom == 1:
							air_cnt += 1
						elif dom == 2 or dom == 3:
							sea_cnt += 1
				_wrist_label_3d.text = "C4ISR SITREP // BLUE C2: %.0f%% | SATCOM: %.0f%%\nACTIVE AIR: %d SQRNS | MARITIME: %d VESSELS\nDEFCON: %d | INTEL ACCURACY: HIGH" % [st.blue_c2_integrity * 100.0, st.blue_satcom_factor * 100.0, air_cnt, sea_cnt, st.defcon_level]
			return "C4ISR_SITREP_OK"
		"btn_defcon":
			if sim_server != null and _wrist_label_3d != null:
				var st: WorldState = sim_server.world_state
				var def_names := ["", "COCKED PISTOL", "FAST PACE", "ROUND HOUSE", "DOUBLE TAKE", "FADE OUT"]
				var d_name: String = def_names[clamp(st.defcon_level, 1, 5)]
				_wrist_label_3d.text = "DEFCON STATUS // ALERT LEVEL %d [%s]\nESCALATION: %.1f%% | STRATEGIC RETALIATION: AUTHORIZED\nINTERCEPTORS READY | SILOS SPOOLING" % [st.defcon_level, d_name, st.global_escalation_score]
			return "DEFCON_STATUS_OK"
		"btn_theater":
			if war_table != null and war_table.has_method("toggle_display_mode"):
				war_table.toggle_display_mode()
				var is_tree: bool = war_table.is_story_tree_active()
				if _wrist_buttons.has("btn_theater"):
					_wrist_buttons["btn_theater"]["label"].text = "THEATER\nTREE" if is_tree else "THEATER\nMAP"
				return "THEATER_MODE_" + ("STORY_TREE" if is_tree else "TACTICAL_MAP")
			return "THEATER_TOGGLED"
	return ""


## Launches the dedicated tactical trial proving ground for the currently selected unit,
## or defaults to the F-35A Lightning II trial if no unit is selected.
func launch_selected_unit_trial() -> Dictionary:
	var slug := ""
	if desktop_rig != null and desktop_rig.selected_unit_id >= 0 and sim_server != null:
		var uid: int = desktop_rig.selected_unit_id
		var st: WorldState = sim_server.world_state
		if uid >= 0 and uid < st.unit_count and st.unit_active[uid] == 1:
			var pid: int = st.unit_platform_id[uid]
			var pdef: Dictionary = sim_server.sim_db_ref.get_platform(pid)
			slug = String(pdef.get("slug", ""))
	if slug.is_empty():
		slug = "f_35a_lightning"
	if sim_server != null and sim_server.has_method("load_unit_trial"):
		return sim_server.load_unit_trial(slug)
	return {}


func _create_hand_gauntlet(node_name: String, accent_col: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name

	var palm := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.055, 0.032, 0.11)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.06, 0.09, 0.14, 1.0)
	p_mat.metallic = 0.78
	p_mat.roughness = 0.25
	p_box.material = p_mat
	palm.mesh = p_box
	root.add_child(palm)

	var emitter := MeshInstance3D.new()
	var e_sph := SphereMesh.new()
	e_sph.radius = 0.012
	e_sph.height = 0.024
	var e_mat := StandardMaterial3D.new()
	e_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	e_mat.albedo_color = accent_col
	e_sph.material = e_mat
	emitter.mesh = e_sph
	emitter.position = Vector3(0.0, 0.0, -0.06)
	root.add_child(emitter)
	return root


func _create_laser_beam(node_name: String, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0018
	cyl.bottom_radius = 0.0028
	cyl.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl.material = mat
	mi.mesh = cyl
	mi.rotation_degrees.x = -90.0
	mi.position = Vector3(0.0, 0.0, -0.5)
	return mi


func _create_laser_reticle(node_name: String, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var torus := TorusMesh.new()
	torus.inner_radius = 0.014
	torus.outer_radius = 0.022
	torus.rings = 24
	torus.ring_segments = 8
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	torus.material = mat
	mi.mesh = torus
	return mi


func try_initialize_openxr() -> bool:
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface != null:
		if not xr_interface.is_initialized() and not DisplayServer.get_name().contains("headless"):
			if OS.get_cmdline_args().has("--xr-mode") or OS.get_cmdline_user_args().has("--xr-mode") or OS.get_name() == "Android" or OS.has_feature("android"):
				xr_interface.initialize()
		if xr_interface.is_initialized():
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			get_viewport().use_xr = true
			is_xr_active = true
			_update_vr_visuals_visibility()
			return true
	is_xr_active = false
	_update_vr_visuals_visibility()
	return false


## Enables or disables Desktop VR Hand Simulator Mode (`[F11]` or `[VR HANDS SIM]` button)
## so players and automated tests can use all 3D VR Hand, Laser, Wrist C4ISR & TactileConsole interactions on Desktop.
func set_vr_simulator_mode(enabled: bool) -> void:
	vr_simulator_mode = enabled
	_update_vr_visuals_visibility()


func toggle_vr_simulator_mode() -> bool:
	set_vr_simulator_mode(not vr_simulator_mode)
	return vr_simulator_mode


func _update_vr_visuals_visibility() -> void:
	var show_vr := is_xr_active or vr_simulator_mode
	if left_controller != null:
		left_controller.visible = show_vr
	if right_controller != null:
		right_controller.visible = show_vr
	if _left_reticle != null:
		_left_reticle.visible = show_vr
	if _right_reticle != null:
		_right_reticle.visible = show_vr
	if not show_vr and _vr_selection_sphere != null:
		_vr_selection_sphere.visible = false


func trigger_haptic_click(hand: String = "right", amplitude: float = 0.55, duration_sec: float = 0.045) -> void:
	haptic_pulses_triggered += 1
	if not is_xr_active:
		return
	var ctrl := right_controller if hand == "right" else left_controller
	if ctrl != null:
		ctrl.trigger_haptic_pulse("haptic", 120.0, amplitude, duration_sec, 0.0)


func _get_ctrl_world_pos(ctrl: Node3D) -> Vector3:
	if ctrl == null:
		return position
	return ctrl.global_position if ctrl.is_inside_tree() else (position + ctrl.position)


func get_controller_ray(hand: String = "right") -> Dictionary:
	var ctrl := right_controller if hand == "right" else left_controller
	if ctrl == null:
		return {"origin": position, "dir": Vector3.FORWARD}
	var orig := _get_ctrl_world_pos(ctrl)
	var dir := (-ctrl.global_transform.basis.z).normalized() if ctrl.is_inside_tree() else (-ctrl.transform.basis.z).normalized()
	return {"origin": orig, "dir": dir}


## Aim a VR controller directly at a 3D world position (useful for VR Simulator & headless testing).
func aim_controller_at_world_pos(hand: String, target_world: Vector3) -> void:
	var ctrl := right_controller if hand == "right" else left_controller
	if ctrl != null:
		var cpos := _get_ctrl_world_pos(ctrl)
		if cpos.distance_squared_to(target_world) > 0.0001:
			ctrl.transform.basis = Basis.looking_at(target_world - cpos, Vector3.UP)


## Primary VR Right-Trigger / Laser Action:
## 1. Actuates any 3D switch/button on `TactileConsole` hit by the laser.
## 2. If the 3D Planetary Globe is active, selects & hot-switches to any of the 7 Global Flashpoint Beacons.
## 3. Otherwise selects the 3D airborne/surface unit under the laser on the War Table.
func vr_laser_select_or_actuate(hand: String = "right", additive: bool = false) -> Dictionary:
	var ray := get_controller_ray(hand)
	var orig: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]

	# 0. Check Virtual Smartwatch / C4ISR Wrist Tablet Interactive Buttons
	var hit_wrist_btn: String = pick_wrist_button_by_ray(orig, dir)
	if not hit_wrist_btn.is_empty():
		var res: String = actuate_wrist_button(hit_wrist_btn)
		trigger_haptic_click(hand, 0.75, 0.05)
		return {"type": "WRIST_BUTTON", "target": hit_wrist_btn, "result": res}

	# 1. Check 3D TactileConsole physical switches & buttons
	if tactile_console != null and tactile_console.has_method("pick_control_by_ray"):
		var hit_ctrl: String = tactile_console.pick_control_by_ray(orig, dir)
		if not hit_ctrl.is_empty():
			var sel_uid: int = desktop_rig.selected_unit_id if desktop_rig != null else -1
			tactile_console.actuate_control(hit_ctrl, sel_uid)
			trigger_haptic_click(hand, 0.75, 0.06)
			return {"type": "CONSOLE_CONTROL", "target": hit_ctrl}

	# 1.5. Check 3D War Table Campaign Story Tree Nodes & Nation Flags (when in STORY_TREE mode)
	if war_table != null and war_table.has_method("is_story_tree_active") and war_table.is_story_tree_active():
		var hit_tree: Dictionary = war_table.pick_story_tree_node_by_ray(orig, dir)
		if not hit_tree.is_empty():
			trigger_haptic_click(hand, 0.75, 0.05)
			return hit_tree

	if war_table == null or sim_server == null:
		return {"type": "NONE"}

	# 2. Check 3D Planetary Globe Flashpoints if in Orbital View (`zoom_scale < 0.42`)
	if war_table.has_method("is_planetary_globe_visible") and war_table.is_planetary_globe_visible():
		var fp_slug: String = war_table.pick_flashpoint_on_globe_by_ray(orig, dir)
		if not fp_slug.is_empty():
			if main_menu != null and main_menu.has_method("launch_scenario"):
				main_menu.launch_scenario(fp_slug, 1.0, Vector2.ZERO)
			else:
				sim_server.load_scenario(fp_slug)
				war_table.bind_sim_server(sim_server)
				war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
			trigger_haptic_click(hand, 0.85, 0.08)
			return {"type": "GLOBE_FLASHPOINT", "target": fp_slug}

	# 3. Check 3D Ray Unit Selection (airborne 3D jets + ground/sea tokens)
	var picked_uid: int = war_table.pick_unit_by_ray(orig, dir)
	if picked_uid < 0:
		var table_y: float = war_table.global_position.y if war_table.is_inside_tree() else war_table.position.y
		var plane := Plane(Vector3.UP, table_y)
		var hit = plane.intersects_ray(orig, dir)
		if hit != null:
			var hit_km: Vector3 = war_table.world_to_theater_km(hit)
			picked_uid = war_table.pick_unit_at_theater_km(hit_km.x, hit_km.z, 25.0)

	if picked_uid >= 0:
		var st: WorldState = sim_server.world_state
		if st.unit_faction[picked_uid] != WorldState.FACTION_BLUE:
			designated_target_uid = picked_uid
			if desktop_rig != null:
				desktop_rig.designated_target_uid = picked_uid
				if desktop_rig.has_signal("designated_target_changed"):
					desktop_rig.designated_target_changed.emit(picked_uid)
			if war_table != null and war_table.visual_sync != null and "designated_target_uid" in war_table.visual_sync:
				war_table.visual_sync.designated_target_uid = picked_uid
			if signal_bus != null and signal_bus.has_signal("target_designated"):
				signal_bus.emit_signal("target_designated", picked_uid)
			trigger_haptic_click(hand, 0.75, 0.05)
			return {"type": "ENEMY_TARGET", "unit_id": picked_uid}
		if desktop_rig != null:
			if additive and not desktop_rig.selected_unit_ids.is_empty():
				var list: Array[int] = desktop_rig.selected_unit_ids.duplicate()
				if not list.has(picked_uid):
					list.append(picked_uid)
				desktop_rig.select_unit_group(list, picked_uid)
			else:
				desktop_rig.select_unit(picked_uid)
		trigger_haptic_click(hand, 0.55, 0.04)
		return {"type": "UNIT", "unit_id": picked_uid}

	return {"type": "NONE"}


## VR 3D Sphere Volume Group Selection: selects all friendly leaf units inside a 3D sphere on the War Table.
func vr_sphere_volume_select(center_world: Vector3, radius_m: float, additive: bool = false) -> int:
	if war_table == null or desktop_rig == null or sim_server == null:
		return 0
	var inside: Array[int] = war_table.pick_units_in_sphere_world(center_world, maxf(0.06, radius_m))
	if inside.is_empty():
		return 0
	var st: WorldState = sim_server.world_state
	var friendly_inside: Array[int] = []
	for u in inside:
		if u >= 0 and u < st.unit_count and st.unit_active[u] == 1:
			if st.unit_faction[u] == WorldState.FACTION_BLUE:
				friendly_inside.append(u)
			else:
				designated_target_uid = u
				if desktop_rig != null:
					desktop_rig.designated_target_uid = u
	if friendly_inside.is_empty():
		return 0
	if additive and not desktop_rig.selected_unit_ids.is_empty():
		var combined: Array[int] = desktop_rig.selected_unit_ids.duplicate()
		for uid in friendly_inside:
			if not combined.has(uid):
				combined.append(uid)
		desktop_rig.select_unit_group(combined, friendly_inside[0])
	else:
		desktop_rig.select_unit_group(friendly_inside, friendly_inside[0])
	trigger_haptic_click("right", 0.70, 0.06)
	return desktop_rig.selected_unit_ids.size()


## VR Laser Waypoint / Strike Salvo Order Issuing (`Left Trigger` or `Right B/Y` Button):
## Orders the currently selected Company, Battalion, or Brigade to move to the laser point (or strike an enemy unit).
func vr_laser_issue_order(hand: String = "right", append_waypoint: bool = false) -> bool:
	if war_table == null or sim_server == null or command_bus == null or desktop_rig == null:
		return false
	var sel_list: Array[int] = desktop_rig._get_active_selection_list()
	var lead_uid: int = desktop_rig.selected_unit_id
	if sel_list.is_empty() or lead_uid < 0 or lead_uid >= sim_server.world_state.unit_count:
		return false

	var ray := get_controller_ray(hand)
	var orig: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]

	var table_y: float = war_table.global_position.y if war_table.is_inside_tree() else war_table.position.y
	var plane := Plane(Vector3.UP, table_y)
	var hit = plane.intersects_ray(orig, dir)
	var hit_km := Vector3.ZERO
	if hit != null:
		hit_km = war_table.world_to_theater_km(hit)

	var target_uid: int = war_table.pick_unit_by_ray(orig, dir)
	if target_uid < 0 and hit != null:
		target_uid = war_table.pick_unit_at_theater_km(hit_km.x, hit_km.z, 25.0)

	var st: WorldState = sim_server.world_state
	if target_uid >= 0 and st.unit_faction[target_uid] != st.unit_faction[lead_uid]:
		designated_target_uid = target_uid
		if desktop_rig != null:
			desktop_rig.designated_target_uid = target_uid
			if desktop_rig.has_signal("designated_target_changed"):
				desktop_rig.designated_target_changed.emit(target_uid)
		if war_table != null and war_table.visual_sync != null and "designated_target_uid" in war_table.visual_sync:
			war_table.visual_sync.designated_target_uid = target_uid
		if signal_bus != null and signal_bus.has_signal("target_designated"):
			signal_bus.emit_signal("target_designated", target_uid)
		command_bus.enqueue_strike(sel_list, target_uid, st.unit_pos[target_uid], 1, 2)
		war_table.strike_preview.show_strike_preview(st.unit_pos[lead_uid], st.unit_pos[target_uid], 3.8, "VR STRIKE ORDER (%d UNITS)" % sel_list.size())
		trigger_haptic_click(hand, 0.90, 0.08)
		return true
	elif hit != null:
		var sel_pos: Vector3 = st.unit_pos[lead_uid]
		var wp := Vector3(hit_km.x, sel_pos.y if sel_pos.y > 200.0 else hit_km.y, hit_km.z)
		var wp_array: Array = [wp]
		if append_waypoint and st.unit_has_waypoint[lead_uid] == 1:
			wp_array = [st.unit_target_pos[lead_uid], wp]
		command_bus.enqueue_move_waypoints(sel_list, wp_array)
		war_table.strike_preview.show_strike_preview(sel_pos, wp, 1.5, "VR WAYPOINT ORDER (%d UNITS)" % sel_list.size())
		trigger_haptic_click(hand, 0.65, 0.05)
		return true
	return false


## Cycles Echelon Grouping in VR (`Company -> Battalion [6 Cos] -> Brigade [36 Cos]`).
func vr_cycle_echelon_selection() -> int:
	if desktop_rig == null or sim_server == null or desktop_rig.selected_unit_id < 0:
		return 0
	_echelon_cycle_stage = (_echelon_cycle_stage + 1) % 3
	if _echelon_cycle_stage == 1:
		desktop_rig.select_battalion_of_current()
	elif _echelon_cycle_stage == 2:
		desktop_rig.select_brigade_of_current()
	else:
		var lead: int = desktop_rig.selected_unit_id
		desktop_rig.select_unit(lead)
	trigger_haptic_click("right", 0.60, 0.05)
	return desktop_rig.selected_unit_ids.size()


func vr_cycle_time_scale() -> float:
	if tactile_console == null:
		return 1.0
	var sc: float = tactile_console.cycle_time_compression()
	trigger_haptic_click("left", 0.60, 0.05)
	return sc


func vr_deploy_unmanned_subunit() -> int:
	if tactile_console == null:
		return 0
	var sel_uid: int = desktop_rig.selected_unit_id if desktop_rig != null else -1
	var count: int = tactile_console.press_deploy_unmanned(sel_uid)
	trigger_haptic_click("left", 0.70, 0.06)
	return count


func _process(delta: float) -> void:
	var active_mode := is_xr_active or vr_simulator_mode
	if not active_mode or war_table == null:
		return

	# In Desktop VR Simulator Mode, smoothly track the mouse cursor with the Right VR Hand & Laser!
	if vr_simulator_mode and not is_xr_active and is_inside_tree() and desktop_rig != null and desktop_rig.camera != null:
		var mpos := get_viewport().get_mouse_position()
		var r_orig: Vector3 = desktop_rig.camera.project_ray_origin(mpos)
		var r_dir: Vector3 = desktop_rig.camera.project_ray_normal(mpos)
		var plane := Plane(Vector3.UP, war_table.global_position.y)
		var hit = plane.intersects_ray(r_orig, r_dir)
		var aim_pt: Vector3 = hit if hit != null else (r_orig + r_dir * 1.5)
		right_controller.global_position = desktop_rig.camera.global_position + desktop_rig.camera.global_transform.basis.x * 0.24 - desktop_rig.camera.global_transform.basis.y * 0.18 - desktop_rig.camera.global_transform.basis.z * 0.38
		aim_controller_at_world_pos("right", aim_pt)
		left_controller.global_position = desktop_rig.camera.global_position - desktop_rig.camera.global_transform.basis.x * 0.26 - desktop_rig.camera.global_transform.basis.y * 0.19 - desktop_rig.camera.global_transform.basis.z * 0.40
		left_controller.rotation = desktop_rig.camera.rotation + Vector3(deg_to_rad(-18.0), deg_to_rad(15.0), 0.0)

	# Update 3D Laser Beams & Target Reticles for both hands
	_laser_hover_frame += 1
	_update_hand_laser_and_reticle("left", _left_laser_beam, _left_reticle)
	_update_hand_laser_and_reticle("right", _right_laser_beam, _right_reticle)

	# Update 3D Left-Wrist C4ISR Holographic Tablet Telemetry (throttled to 4 Hz to avoid Label3D glyph reshaping every frame)
	_wrist_update_accum += delta
	if _wrist_update_accum >= 0.25:
		_wrist_update_accum = 0.0
		_update_wrist_c4isr_tablet()

	# Check physical 3D hand proximity poke on `TactileConsole`
	if tactile_console != null and tactile_console.has_method("check_hand_proximity_actuation"):
		var sel_uid: int = desktop_rig.selected_unit_id if desktop_rig != null else -1
		if not tactile_console.check_hand_proximity_actuation(_get_ctrl_world_pos(right_controller), sel_uid).is_empty():
			trigger_haptic_click("right", 0.75, 0.05)
		if not tactile_console.check_hand_proximity_actuation(_get_ctrl_world_pos(left_controller), sel_uid).is_empty():
			trigger_haptic_click("left", 0.75, 0.05)

	if not is_xr_active:
		return

	# --- OpenXR Hardware Controller Input Polling ---
	var l_grip := left_controller.is_button_pressed("grip_click")
	var r_grip := right_controller.is_button_pressed("grip_click")

	# 1. Two-Handed Pinch-to-Zoom & Grab-Pan
	if l_grip and r_grip:
		_single_grip_hand = ""
		var dist := left_controller.global_position.distance_to(right_controller.global_position)
		var mid := (left_controller.global_position + right_controller.global_position) * 0.5
		if _two_hand_initial_dist <= 0.001:
			_two_hand_initial_dist = maxf(0.05, dist)
			_two_hand_initial_zoom = war_table.target_zoom_scale
			_two_hand_initial_mid = mid
			_two_hand_initial_pan_km = war_table.target_pan_offset_km
		else:
			var ratio := dist / _two_hand_initial_dist
			var new_zoom := clampf(_two_hand_initial_zoom * ratio, 0.15, 25.0)
			var delta_world := mid - _two_hand_initial_mid
			var km_per_m := 500.0 / (1.80 * maxf(0.5, new_zoom))
			var new_pan := _two_hand_initial_pan_km - Vector2(delta_world.x, delta_world.z) * km_per_m
			war_table.set_zoom_and_pan(new_zoom, new_pan)
	else:
		_two_hand_initial_dist = 0.0
		# 2. Single-Hand Grip Grab-Pan
		if r_grip or l_grip:
			var active_h := "right" if r_grip else "left"
			var ctrl := right_controller if r_grip else left_controller
			if _single_grip_hand != active_h:
				_single_grip_hand = active_h
				_single_grip_start_pos = ctrl.global_position
				_single_grip_start_pan_km = war_table.target_pan_offset_km
			else:
				var d_pos := ctrl.global_position - _single_grip_start_pos
				var km_per_m := 500.0 / (1.80 * maxf(0.5, war_table.target_zoom_scale))
				war_table.set_zoom_and_pan(war_table.target_zoom_scale, _single_grip_start_pan_km - Vector2(d_pos.x, d_pos.z) * km_per_m)
		else:
			_single_grip_hand = ""

	# 3. Thumbstick Smooth Pan & Zoom (`primary` Vector2 axis)
	var l_stick := left_controller.get_vector2("primary")
	var r_stick := right_controller.get_vector2("primary")
	if l_stick.length() > 0.15:
		var pan_spd := (140.0 / maxf(1.0, war_table.zoom_scale)) * delta
		war_table.set_zoom_and_pan(war_table.target_zoom_scale, war_table.target_pan_offset_km + Vector2(l_stick.x, -l_stick.y) * pan_spd)
	if absf(r_stick.y) > 0.20:
		var z_factor := 1.0 + r_stick.y * 1.4 * delta
		war_table.set_zoom_and_pan(war_table.target_zoom_scale * z_factor, war_table.target_pan_offset_km)

	# 4. Right Trigger: Tap to Select/Actuate OR Hold-Drag to Expand 3D Selection Sphere
	var r_trig := right_controller.is_button_pressed("trigger_click")
	var ray_r := get_controller_ray("right")
	var plane := Plane(Vector3.UP, war_table.global_position.y)
	var hit_r = plane.intersects_ray(ray_r["origin"], ray_r["dir"])

	if r_trig and not _prev_r_trigger:
		if hit_r != null:
			_r_trig_press_world = hit_r
		_r_trig_dragging_sphere = false
	elif r_trig and _prev_r_trigger and hit_r != null:
		var drag_d := _r_trig_press_world.distance_to(hit_r)
		if drag_d > 0.075:
			_r_trig_dragging_sphere = true
			if _vr_selection_sphere != null:
				_vr_selection_sphere.visible = true
				_vr_selection_sphere.global_position = _r_trig_press_world
				_vr_selection_sphere.scale = Vector3.ONE * clampf(drag_d, 0.08, 0.85)
	elif not r_trig and _prev_r_trigger:
		if _vr_selection_sphere != null:
			_vr_selection_sphere.visible = false
		if _r_trig_dragging_sphere and hit_r != null:
			vr_sphere_volume_select(_r_trig_press_world, _r_trig_press_world.distance_to(hit_r), false)
		else:
			vr_laser_select_or_actuate("right", false)
		_r_trig_dragging_sphere = false
	_prev_r_trigger = r_trig

	# 5. Left Trigger or Right B/Y Button: Issue Move Waypoint or Strike Salvo Order
	var l_trig := left_controller.is_button_pressed("trigger_click")
	if l_trig and not _prev_l_trigger:
		vr_laser_issue_order("left", false)
	_prev_l_trigger = l_trig

	var r_by := right_controller.is_button_pressed("by_button")
	if r_by and not _prev_r_by:
		vr_laser_issue_order("right", false)
	_prev_r_by = r_by

	# 6. Right A/X Button: Cycle Echelon Selection (Company -> Battalion -> Brigade)
	var r_ax := right_controller.is_button_pressed("ax_button")
	if r_ax and not _prev_r_ax:
		vr_cycle_echelon_selection()
	_prev_r_ax = r_ax

	# 7. Left X/A Button: Cycle Time Compression (0x PAUSE .. 900x)
	var l_ax := left_controller.is_button_pressed("ax_button")
	if l_ax and not _prev_l_ax:
		vr_cycle_time_scale()
	_prev_l_ax = l_ax

	# 8. Left Y/B Button: Deploy Unmanned Robot Dogs / FPV Swarms
	var l_by := left_controller.is_button_pressed("by_button")
	if l_by and not _prev_l_by:
		vr_deploy_unmanned_subunit()
	_prev_l_by = l_by


func _update_hand_laser_and_reticle(hand: String, beam_mi: MeshInstance3D, reticle_mi: MeshInstance3D) -> void:
	if beam_mi == null or reticle_mi == null or war_table == null:
		return
	var ray := get_controller_ray(hand)
	var orig: Vector3 = ray["origin"]
	var dir: Vector3 = ray["dir"]

	var hit_pos := orig + dir * 1.45
	var ret_col := TacticalTheme.COL_NATO_BLUE if hand == "left" else TacticalTheme.COL_UNMANNED_GOLD

	var hit_wrist := pick_wrist_button_by_ray(orig, dir)
	if not hit_wrist.is_empty():
		ret_col = TacticalTheme.COL_FLIR_GREEN

	if tactile_console != null and tactile_console.has_method("pick_control_by_ray"):
		var cname: String = tactile_console.pick_control_by_ray(orig, dir)
		if not cname.is_empty():
			ret_col = TacticalTheme.COL_FLIR_GREEN

	var table_y: float = war_table.global_position.y if war_table.is_inside_tree() else war_table.position.y
	var plane := Plane(Vector3.UP, table_y)
	var plane_hit = plane.intersects_ray(orig, dir)
	if plane_hit != null:
		var local_hit: Vector3 = war_table.world_to_table_local(plane_hit)
		if absf(local_hit.x) <= 0.95 and absf(local_hit.z) <= 0.95:
			hit_pos = plane_hit + Vector3(0.0, 0.008, 0.0)
			ret_col = TacticalTheme.COL_CONTOUR_EMERALD

	var picked_u: int = -1
	if not OS.has_feature("android") or (hand == "right" and (_laser_hover_frame % 3) == 0):
		picked_u = war_table.pick_unit_by_ray(orig, dir)
	if picked_u >= 0 and sim_server != null:
		var u_lpos: Vector3 = war_table.theater_km_to_table_local(sim_server.world_state.unit_pos[picked_u])
		hit_pos = war_table.table_local_to_world(u_lpos + Vector3(0.0, 0.012, 0.0))
		ret_col = TacticalTheme.COL_NATO_BLUE if sim_server.world_state.unit_faction[picked_u] == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED

	var beam_len := clampf(orig.distance_to(hit_pos), 0.10, 2.50)
	beam_mi.scale = Vector3(1.0, beam_len, 1.0)
	beam_mi.position = Vector3(0.0, 0.0, -beam_len * 0.5)
	if reticle_mi.is_inside_tree():
		reticle_mi.global_position = hit_pos
	else:
		reticle_mi.position = hit_pos
	if reticle_mi.mesh != null and reticle_mi.mesh.material is StandardMaterial3D:
		(reticle_mi.mesh.material as StandardMaterial3D).albedo_color = ret_col


func _update_wrist_c4isr_tablet() -> void:
	if _wrist_label_3d == null or sim_server == null:
		return
	var st: WorldState = sim_server.world_state
	var sel_uid: int = desktop_rig.selected_unit_id if desktop_rig != null else -1
	var sel_cnt: int = maxi(1, desktop_rig.selected_unit_ids.size()) if desktop_rig != null else 1
	var org_str := "NO UNIT SELECTED"
	if sel_uid >= 0 and sel_uid < st.unit_count and st.unit_active[sel_uid] == 1:
		org_str = "%s (%d UNITS)" % [EchelonClusterSystem.get_hierarchy_status_string(st, sel_uid), sel_cnt]

	var b_pct := int(round((float(st.blue_ammo_remaining) / float(maxi(1, st.blue_ammo_initial_total))) * 100.0))
	var r_pct := int(round((float(st.red_ammo_remaining) / float(maxi(1, st.red_ammo_initial_total))) * 100.0))
	var floor_str := "FLOOR:ON" if (war_table != null and war_table.has_method("is_floor_mode") and war_table.is_floor_mode) else "FLOOR:OFF"
	var posture_name: String = POSTURE_NAMES[_current_tactical_posture_idx]
	var sub_str := "SSBN:ON" if (desktop_rig != null and desktop_rig.submarine_conn_ref != null and desktop_rig.submarine_conn_ref.is_sub_sim_active) else "SSBN:OFF"

	var defcon_codename := "FADE OUT"
	var defcon_col: Color = TacticalTheme.COL_NATO_BLUE
	match st.defcon_level:
		1:
			defcon_codename = "COCKED PISTOL"
			defcon_col = Color(1.0, 0.22, 0.22)
		2:
			defcon_codename = "FAST PACE"
			defcon_col = Color(1.0, 0.45, 0.12)
		3:
			defcon_codename = "ROUND HOUSE"
			defcon_col = Color(1.0, 0.82, 0.15)
		4:
			defcon_codename = "DOUBLE TAKE"
			defcon_col = Color(0.18, 0.95, 0.55)
		5:
			defcon_codename = "FADE OUT"
			defcon_col = Color(0.25, 0.65, 1.0)

	_wrist_label_3d.modulate = defcon_col

	var hq_str := "BKR"
	if tri_command_ref != null and tri_command_ref.has_method("get_station_short_name"):
		hq_str = tri_command_ref.get_station_short_name()

	var next_txt := (
		"VR C4ISR WRIST // DEFCON %d (%s) // ESC: %.0f%% // HQ:%s\n" % [st.defcon_level, defcon_codename, st.global_escalation_score, hq_str] +
		"%s | TIME: %.0fx | BUDGET: $%.0fM\n" % [org_str, st.time_scale, st.blue_budget_musd] +
		"BLUE KIA:%d WIA:%d | AMMO:%d (%d%%) || RED KIA:%d AMMO:%d (%d%%)\n" % [st.blue_personnel_kia, st.blue_personnel_wia, st.blue_ammo_remaining, b_pct, st.red_personnel_kia, st.red_ammo_remaining, r_pct] +
		"POSTURE: %s | %s | %s\n" % [posture_name, floor_str, sub_str] +
		"[R-Trig:Laser/WristBtn/Sphere | B:Move/Strike | A:Bn/Bde]"
	)
	if _wrist_label_3d.text != next_txt:
		_wrist_label_3d.text = next_txt

	# Sync smartwatch button states
	if _wrist_buttons.has("btn_floor") and war_table != null:
		var is_fl: bool = war_table.has_method("is_floor_mode") and war_table.is_floor_mode
		_wrist_buttons["btn_floor"]["label"].text = "FLOOR\nON" if is_fl else "FLOOR\nOFF"
	if _wrist_buttons.has("btn_posture"):
		_wrist_buttons["btn_posture"]["label"].text = "AI POST\n" + posture_name
	if _wrist_buttons.has("btn_time"):
		_wrist_buttons["btn_time"]["label"].text = "TIME\n%.0fx" % st.time_scale
	if _wrist_buttons.has("btn_ssbn") and desktop_rig != null and desktop_rig.submarine_conn_ref != null:
		var is_sub: bool = desktop_rig.submarine_conn_ref.is_sub_sim_active
		_wrist_buttons["btn_ssbn"]["label"].text = "SSBN\nON" if is_sub else "SSBN\nOFF"
	if _wrist_buttons.has("btn_hq"):
		_wrist_buttons["btn_hq"]["label"].text = "HQ:\n" + hq_str
	if _wrist_buttons.has("btn_trial"):
		if sel_uid >= 0 and sel_uid < st.unit_count and st.unit_active[sel_uid] == 1:
			var pid: int = st.unit_platform_id[sel_uid]
			var pdef: Dictionary = sim_server.sim_db_ref.get_platform(pid)
			var s_name := String(pdef.get("short_name", pdef.get("slug", "TRIAL")))
			_wrist_buttons["btn_trial"]["label"].text = "TRIAL\n" + s_name.substr(0, 5).to_upper()
		else:
			_wrist_buttons["btn_trial"]["label"].text = "TRIAL\nARENA"

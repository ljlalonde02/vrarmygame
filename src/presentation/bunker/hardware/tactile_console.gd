class_name TactileConsole
extends Node3D
## Interactive 3D "Heavy Hardware" Bunker Console mounted along the front bezel of the War Table.
## Features physical 3D switches, notched time-compression throttle, and guarded red Alpha Strike button
## operable via VR hand controllers, Desktop mouse clicks, or Tactical HUD hotkeys.

var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null
var radio_synth: Node = null

var master_iads_active: bool = true
var current_time_scale: float = 1.0
var alpha_guard_open: bool = false
var recon_photo_mode: bool = false
var force_all_tokens: bool = false
var true_sight_mode: bool = false

# US-12.2: Nuclear Two-Man Rule Key Interlock
var nuclear_key_alpha_turned: bool = false
var nuclear_key_bravo_turned: bool = false
var key_alpha_turn_time_sec: float = -999.0
var key_bravo_turn_time_sec: float = -999.0
var nuclear_interlock_unlocked: bool = false

var _key_alpha_pivot: Node3D = null
var _key_bravo_pivot: Node3D = null
var _key_alpha_lbl: Label3D = null
var _key_bravo_lbl: Label3D = null

var _iads_lever_pivot: Node3D = null
var _throttle_pivot: Node3D = null
var _guard_cover_pivot: Node3D = null
var _alpha_button_mesh: MeshInstance3D = null
var _unmanned_button_mesh: MeshInstance3D = null
var _recon_switch_pivot: Node3D = null
var _echelon_switch_pivot: Node3D = null
var _bn_button_mesh: MeshInstance3D = null
var _bde_button_mesh: MeshInstance3D = null
var _globe_button_mesh: MeshInstance3D = null
var _theater_button_mesh: MeshInstance3D = null
var _red_phone_mesh: MeshInstance3D = null
var _red_phone_mat: StandardMaterial3D = null
var _status_label_3d: Label3D = null
var _holo_board_label_3d: Label3D = null

var war_table_ref: Node3D = null
var desktop_rig_ref: Node3D = null
var main_menu_ref: Node = null
var _interactive_controls: Array[Dictionary] = []
var _last_poke_msec: int = 0
var _active_theater_cycle_idx: int = 0


func _ready() -> void:
	if _iads_lever_pivot != null:
		return
	_build_console_3d_hardware()


func setup(p_sim_server: Node, p_cmd_bus: Node, p_sig_bus: Node, p_radio: Node = null) -> void:
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	radio_synth = p_radio


func _build_console_3d_hardware() -> void:
	# Angled metallic console housing at the front of the War Table
	var bezel := MeshInstance3D.new()
	bezel.name = "ConsoleBezelMesh"
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.76, 0.08, 0.24)
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.04, 0.06, 0.09, 1.0)
	b_mat.metallic = 0.82
	b_mat.roughness = 0.28
	b_box.material = b_mat
	bezel.mesh = b_box
	bezel.rotation_degrees = Vector3(18.0, 0.0, 0.0)
	add_child(bezel)

	# 1. Master IADS Lever (x = -0.68)
	_iads_lever_pivot = _create_switch_assembly("MasterIADSLever", Vector3(-0.68, 0.05, 0.0), "IADS RADAR\n[ACTIVE]", TacticalTheme.COL_NATO_BLUE)

	# 2. Notched Time-Compression Throttle (x = -0.38)
	_throttle_pivot = _create_switch_assembly("TimeScaleThrottle", Vector3(-0.38, 0.05, 0.0), "TIME SCALE\n[1x REALTIME]", TacticalTheme.COL_CONTOUR_EMERALD)

	# 3. Guarded Red Safety Cover + EXECUTE ALPHA STRIKE Button (x = 0.0)
	_guard_cover_pivot = Node3D.new()
	_guard_cover_pivot.name = "AlphaStrikeGuardPivot"
	_guard_cover_pivot.position = Vector3(0.0, 0.06, -0.04)
	add_child(_guard_cover_pivot)

	var guard_mesh := MeshInstance3D.new()
	var g_box := BoxMesh.new()
	g_box.size = Vector3(0.20, 0.025, 0.12)
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.85, 0.12, 0.18, 0.78)
	g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g_box.material = g_mat
	guard_mesh.mesh = g_box
	guard_mesh.position = Vector3(0.0, 0.01, 0.04)
	_guard_cover_pivot.add_child(guard_mesh)

	_alpha_button_mesh = MeshInstance3D.new()
	_alpha_button_mesh.name = "ExecuteAlphaStrikeButton3D"
	var a_cyl := CylinderMesh.new()
	a_cyl.top_radius = 0.065
	a_cyl.bottom_radius = 0.072
	a_cyl.height = 0.035
	var a_mat := StandardMaterial3D.new()
	a_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	a_mat.albedo_color = TacticalTheme.COL_OPFOR_RED
	a_cyl.material = a_mat
	_alpha_button_mesh.mesh = a_cyl
	_alpha_button_mesh.position = Vector3(0.0, 0.048, 0.0)
	add_child(_alpha_button_mesh)

	var alpha_lbl := Label3D.new()
	alpha_lbl.text = "EXECUTE ALPHA STRIKE"
	alpha_lbl.font_size = 20
	alpha_lbl.pixel_size = 0.0007
	alpha_lbl.position = Vector3(0.0, 0.095, -0.05)
	alpha_lbl.modulate = TacticalTheme.COL_OPFOR_RED
	add_child(alpha_lbl)

	# US-12.2: Dual Nuclear Key Turn Assemblies (Two-Man Rule Protocol)
	_key_alpha_pivot = _create_key_assembly("NuclearKeyAlpha3D", Vector3(-0.16, 0.052, 0.0), "KEY ALPHA\n[SAFE]", TacticalTheme.COL_UNMANNED_GOLD)
	_key_bravo_pivot = _create_key_assembly("NuclearKeyBravo3D", Vector3(0.16, 0.052, 0.0), "KEY BRAVO\n[SAFE]", TacticalTheme.COL_OPFOR_RED)

	# 4. DEPLOY UNMANNED (ROBOT DOGS / FPV SWARMS) Button (x = +0.34)
	_unmanned_button_mesh = MeshInstance3D.new()
	_unmanned_button_mesh.name = "DeployUnmannedButton3D"
	var u_box := BoxMesh.new()
	u_box.size = Vector3(0.18, 0.035, 0.09)
	var u_mat := StandardMaterial3D.new()
	u_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	u_mat.albedo_color = TacticalTheme.COL_UNMANNED_GOLD
	u_box.material = u_mat
	_unmanned_button_mesh.mesh = u_box
	_unmanned_button_mesh.position = Vector3(0.34, 0.048, 0.0)
	add_child(_unmanned_button_mesh)

	var u_lbl := Label3D.new()
	u_lbl.text = "DEPLOY ROBOT DOGS / FPV"
	u_lbl.font_size = 18
	u_lbl.pixel_size = 0.0007
	u_lbl.position = Vector3(0.34, 0.095, -0.05)
	u_lbl.modulate = TacticalTheme.COL_UNMANNED_GOLD
	add_child(u_lbl)

	# 5. RECON PHOTO MODE Switch (x = +0.58)
	_recon_switch_pivot = _create_switch_assembly("ReconPhotoSwitch", Vector3(0.58, 0.05, 0.0), "RECON PHOTOS\n[WIKI CARD]", TacticalTheme.COL_NATO_BLUE)

	# 6. Semantic Echelon Override Switch (x = +0.76)
	_echelon_switch_pivot = _create_switch_assembly("EchelonOverrideSwitch", Vector3(0.76, 0.05, 0.0), "ECHELON\n[AUTO STACK]", TacticalTheme.COL_CONTOUR_EMERALD)

	# 7. Lower Row VR/Desktop Physical Pushbuttons: [B] BATTALION, [V] BRIGADE, [O] GLOBE, [NEXT THEATER], plus 3D RED PHONE HOTLINE
	_bn_button_mesh = _create_pushbutton_3d("SelectBattalionButton3D", Vector3(-0.54, 0.042, 0.075), "[B] BATTALION", TacticalTheme.COL_NATO_BLUE)
	_bde_button_mesh = _create_pushbutton_3d("SelectBrigadeButton3D", Vector3(-0.22, 0.042, 0.075), "[V] BRIGADE", TacticalTheme.COL_UNMANNED_GOLD)
	_globe_button_mesh = _create_pushbutton_3d("PlanetaryGlobeButton3D", Vector3(0.22, 0.042, 0.075), "[O] ORBIT GLOBE", TacticalTheme.COL_DIRECTED_ENERGY)
	_theater_button_mesh = _create_pushbutton_3d("NextTheaterButton3D", Vector3(0.54, 0.042, 0.075), "CYCLE 7 THEATERS", TacticalTheme.COL_CONTOUR_EMERALD)

	# Phase 25: Physical 3D Encrypted Red Hotline Phone (Moscow-Beijing-Washington Direct Line) at x = -0.82
	_red_phone_mesh = MeshInstance3D.new()
	_red_phone_mesh.name = "RedPhoneHotline3D"
	var rp_box := BoxMesh.new()
	rp_box.size = Vector3(0.11, 0.055, 0.095)
	_red_phone_mat = StandardMaterial3D.new()
	_red_phone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_red_phone_mat.albedo_color = Color(0.88, 0.08, 0.12, 1.0)
	rp_box.material = _red_phone_mat
	_red_phone_mesh.mesh = rp_box
	_red_phone_mesh.position = Vector3(-0.82, 0.055, 0.03)
	add_child(_red_phone_mesh)

	var rp_lbl := Label3D.new()
	rp_lbl.text = "[Y] RED PHONE\nHOTLINE"
	rp_lbl.font_size = 15
	rp_lbl.pixel_size = 0.00062
	rp_lbl.position = Vector3(-0.82, 0.105, 0.01)
	rp_lbl.modulate = Color(1.0, 0.25, 0.25, 1.0)
	add_child(rp_lbl)

	_interactive_controls = [
		{"name": "MasterIADSLever", "node": _iads_lever_pivot, "radius": 0.085},
		{"name": "TimeScaleThrottle", "node": _throttle_pivot, "radius": 0.085},
		{"name": "ExecuteAlphaStrikeButton3D", "node": _alpha_button_mesh, "radius": 0.095},
		{"name": "NuclearKeyAlpha3D", "node": _key_alpha_pivot, "radius": 0.075},
		{"name": "NuclearKeyBravo3D", "node": _key_bravo_pivot, "radius": 0.075},
		{"name": "DeployUnmannedButton3D", "node": _unmanned_button_mesh, "radius": 0.095},
		{"name": "ReconPhotoSwitch", "node": _recon_switch_pivot, "radius": 0.080},
		{"name": "EchelonOverrideSwitch", "node": _echelon_switch_pivot, "radius": 0.080},
		{"name": "SelectBattalionButton3D", "node": _bn_button_mesh, "radius": 0.075},
		{"name": "SelectBrigadeButton3D", "node": _bde_button_mesh, "radius": 0.075},
		{"name": "PlanetaryGlobeButton3D", "node": _globe_button_mesh, "radius": 0.075},
		{"name": "NextTheaterButton3D", "node": _theater_button_mesh, "radius": 0.075},
		{"name": "RedPhoneHotline3D", "node": _red_phone_mesh, "radius": 0.085},
	]

	_status_label_3d = Label3D.new()
	_status_label_3d.name = "ConsoleTelemetryLabel3D"
	_status_label_3d.text = "IADS: ACTIVE | TIME: 1x | READY FOR ALPHA STRIKE"
	_status_label_3d.font_size = 20
	_status_label_3d.pixel_size = 0.00075
	_status_label_3d.position = Vector3(0.0, 0.135, -0.08)
	_status_label_3d.modulate = TacticalTheme.COL_NATO_BLUE
	add_child(_status_label_3d)

	# 8. Diegetic 3D Floating Holographic C4ISR Status & Casualties Board (Visible in VR & Desktop above rear of War Table)
	var holo_board_root := Node3D.new()
	holo_board_root.name = "DiegeticHoloSitrepBoard3D"
	holo_board_root.position = Vector3(0.0, 0.88, -1.92)
	add_child(holo_board_root)

	var board_glass := MeshInstance3D.new()
	var bg_quad := BoxMesh.new()
	bg_quad.size = Vector3(1.84, 0.34, 0.012)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = Color(0.02, 0.06, 0.11, 0.72)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_quad.material = bg_mat
	board_glass.mesh = bg_quad
	holo_board_root.add_child(board_glass)

	_holo_board_label_3d = Label3D.new()
	_holo_board_label_3d.name = "HoloBoardTelemetryLabel3D"
	_holo_board_label_3d.text = "JOC 3D C4ISR HOLOGRAM // 1,000,000 GLOBAL ORBAT UNITS // REAL-TIME 1:1 SPEEDS"
	_holo_board_label_3d.font_size = 22
	_holo_board_label_3d.pixel_size = 0.00078
	_holo_board_label_3d.position = Vector3(0.0, 0.0, 0.012)
	_holo_board_label_3d.modulate = TacticalTheme.COL_NATO_BLUE
	holo_board_root.add_child(_holo_board_label_3d)


func _create_pushbutton_3d(node_name: String, pos: Vector3, label_text: String, col: Color) -> MeshInstance3D:
	var btn_mi := MeshInstance3D.new()
	btn_mi.name = node_name
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.024, 0.052)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col * Color(0.85, 0.85, 0.85, 1.0)
	box.material = mat
	btn_mi.mesh = box
	btn_mi.position = pos
	add_child(btn_mi)

	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 15
	lbl.pixel_size = 0.00062
	lbl.position = pos + Vector3(0.0, 0.026, 0.0)
	lbl.modulate = col
	add_child(lbl)
	return btn_mi


func _create_key_assembly(node_name: String, pos: Vector3, label_text: String, col: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pos
	add_child(pivot)

	var tumbler := MeshInstance3D.new()
	var t_cyl := CylinderMesh.new()
	t_cyl.top_radius = 0.016
	t_cyl.bottom_radius = 0.018
	t_cyl.height = 0.025
	var t_mat := StandardMaterial3D.new()
	t_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	t_mat.albedo_color = Color(0.25, 0.28, 0.32)
	tumbler.mesh = t_cyl
	tumbler.position = Vector3(0.0, 0.012, 0.0)
	pivot.add_child(tumbler)

	var key_grip := MeshInstance3D.new()
	var k_box := BoxMesh.new()
	k_box.size = Vector3(0.008, 0.045, 0.024)
	var k_mat := StandardMaterial3D.new()
	k_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	k_mat.albedo_color = col
	key_grip.mesh = k_box
	key_grip.position = Vector3(0.0, 0.038, 0.0)
	pivot.add_child(key_grip)

	var lbl := Label3D.new()
	lbl.name = "KeyLabel"
	lbl.text = label_text
	lbl.font_size = 14
	lbl.pixel_size = 0.00060
	lbl.position = pos + Vector3(0.0, 0.065, -0.04)
	lbl.modulate = col
	add_child(lbl)
	if node_name == "NuclearKeyAlpha3D":
		_key_alpha_lbl = lbl
	else:
		_key_bravo_lbl = lbl
	return pivot


func _create_switch_assembly(node_name: String, pos: Vector3, label_text: String, col: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pos
	add_child(pivot)

	var handle := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(0.025, 0.075, 0.025)
	var h_mat := StandardMaterial3D.new()
	h_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	h_mat.albedo_color = col
	h_box.material = h_mat
	handle.mesh = h_box
	handle.position = Vector3(0.0, 0.035, 0.0)
	pivot.add_child(handle)

	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 17
	lbl.pixel_size = 0.00068
	lbl.position = pos + Vector3(0.0, 0.06, -0.05)
	lbl.modulate = col
	add_child(lbl)
	return pivot


func _process(delta: float) -> void:
	var damp := 1.0 - exp(-12.0 * delta)
	if _iads_lever_pivot != null:
		var target_rot_x := -28.0 if master_iads_active else 28.0
		_iads_lever_pivot.rotation_degrees.x = lerpf(_iads_lever_pivot.rotation_degrees.x, target_rot_x, damp)
	if _throttle_pivot != null:
		var t_norm := clampf(log(maxf(1.0, current_time_scale)) / log(900.0), 0.0, 1.0) if current_time_scale > 0.0 else 0.0
		var target_thr_x := lerpf(32.0, -38.0, t_norm)
		_throttle_pivot.rotation_degrees.x = lerpf(_throttle_pivot.rotation_degrees.x, target_thr_x, damp)
	if _guard_cover_pivot != null:
		var target_guard_x := -78.0 if alpha_guard_open else 0.0
		_guard_cover_pivot.rotation_degrees.x = lerpf(_guard_cover_pivot.rotation_degrees.x, target_guard_x, damp)
	if _recon_switch_pivot != null:
		var target_rec_x := -25.0 if recon_photo_mode else 25.0
		_recon_switch_pivot.rotation_degrees.x = lerpf(_recon_switch_pivot.rotation_degrees.x, target_rec_x, damp)
	if _echelon_switch_pivot != null:
		var target_ech_x := -25.0 if force_all_tokens else 25.0
		_echelon_switch_pivot.rotation_degrees.x = lerpf(_echelon_switch_pivot.rotation_degrees.x, target_ech_x, damp)
	if _key_alpha_pivot != null:
		var target_ka := 90.0 if nuclear_key_alpha_turned else 0.0
		_key_alpha_pivot.rotation_degrees.z = lerpf(_key_alpha_pivot.rotation_degrees.z, target_ka, damp)
	if _key_bravo_pivot != null:
		var target_kb := -90.0 if nuclear_key_bravo_turned else 0.0
		_key_bravo_pivot.rotation_degrees.z = lerpf(_key_bravo_pivot.rotation_degrees.z, target_kb, damp)

	# Pulse the physical 3D Red Hotline Phone crimson/gold when ringing!
	if _red_phone_mat != null and sim_server != null and sim_server.world_state != null:
		if sim_server.world_state.hotline_is_ringing:
			var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.014)
			_red_phone_mat.albedo_color = Color(1.0, 0.15 + 0.65 * pulse, 0.12, 1.0)
		else:
			_red_phone_mat.albedo_color = Color(0.82, 0.08, 0.12, 1.0)

	if sim_server != null and _holo_board_label_3d != null:
		var st: WorldState = sim_server.world_state
		var hrs := int(st.sim_time_sec) / 3600
		var mins := (int(st.sim_time_sec) % 3600) / 60
		var secs := int(st.sim_time_sec) % 60
		var b_pct := int(round((float(st.blue_ammo_remaining) / float(maxi(1, st.blue_ammo_initial_total))) * 100.0))
		var r_pct := int(round((float(st.red_ammo_remaining) / float(maxi(1, st.red_ammo_initial_total))) * 100.0))
		_holo_board_label_3d.text = (
			"3D C4ISR BUNKER HOLOGRAM // DEFCON %d (ESC:%.0f%%) // BUDGET: $%.0fM (+$%.0fM/m) // TECHS: %d/15 // T+%02d:%02d:%02d [%.0fx]\n" % [
				st.defcon_level, st.global_escalation_score, st.blue_budget_musd, st.blue_income_musd_per_min, st.blue_unlocked_techs.size(), hrs, mins, secs, st.time_scale
			] +
			"BLUE CASUALTIES: KIA %d | WIA %d ($%.1fM) | AMMO: %d (%d%%)  ||  RED: KIA %d | WIA %d ($%.1fM) | AMMO: %d (%d%%)\n" % [
				st.blue_personnel_kia, st.blue_personnel_wia, st.blue_lost_musd, st.blue_ammo_remaining, b_pct,
				st.red_personnel_kia, st.red_personnel_wia, st.red_lost_musd, st.red_ammo_remaining, r_pct
			] +
			"%s" % st.latest_presidential_declaration.substr(0, 118)
		)


func get_control_world_pos(node: Node3D) -> Vector3:
	if node == null:
		return position
	return node.global_position if node.is_inside_tree() else (position + node.position)


## Raycasts against all 10 physical 3D switches & buttons on the TactileConsole (for Desktop Mouse & VR Laser).
func pick_control_by_ray(ray_origin_world: Vector3, ray_dir_world: Vector3) -> String:
	var dir_n := ray_dir_world.normalized()
	var best_name := ""
	var best_dist := 0.085
	for ctrl in _interactive_controls:
		var node: Node3D = ctrl.get("node", null)
		if node == null:
			continue
		var wpos := get_control_world_pos(node)
		var to_pt := wpos - ray_origin_world
		var proj := to_pt.dot(dir_n)
		if proj <= 0.05:
			continue
		var closest := ray_origin_world + dir_n * proj
		var perp := wpos.distance_to(closest)
		var rad := float(ctrl.get("radius", 0.085))
		if perp <= rad and perp < best_dist:
			best_dist = perp
			best_name = String(ctrl.get("name", ""))
	return best_name


## Checks if a physical VR hand controller is touching/poking any 3D console control.
func check_hand_proximity_actuation(hand_world_pos: Vector3, selected_uid: int = -1) -> String:
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_poke_msec < 450:
		return ""
	for ctrl in _interactive_controls:
		var node: Node3D = ctrl.get("node", null)
		if node == null:
			continue
		var d := hand_world_pos.distance_to(get_control_world_pos(node))
		if d <= float(ctrl.get("radius", 0.085)):
			_last_poke_msec = now_ms
			var cname := String(ctrl.get("name", ""))
			actuate_control(cname, selected_uid)
			return cname
	return ""


## Actuates a named 3D console control and returns true if handled.
func actuate_control(control_name: String, selected_uid: int = -1) -> bool:
	match control_name:
		"MasterIADSLever":
			toggle_master_iads()
			return true
		"TimeScaleThrottle":
			cycle_time_compression()
			return true
		"ExecuteAlphaStrikeButton3D":
			press_execute_alpha_strike()
			return true
		"NuclearKeyAlpha3D":
			turn_nuclear_key_alpha()
			return true
		"NuclearKeyBravo3D":
			turn_nuclear_key_bravo()
			return true
		"DeployUnmannedButton3D":
			press_deploy_unmanned(selected_uid)
			return true
		"ReconPhotoSwitch":
			toggle_recon_photo_mode()
			return true
		"EchelonOverrideSwitch":
			toggle_semantic_echelon_override()
			return true
		"SelectBattalionButton3D":
			if desktop_rig_ref != null and desktop_rig_ref.has_method("select_battalion_of_current"):
				if radio_synth != null:
					radio_synth.play_switch_clunk()
				desktop_rig_ref.select_battalion_of_current()
			return true
		"SelectBrigadeButton3D":
			if desktop_rig_ref != null and desktop_rig_ref.has_method("select_brigade_of_current"):
				if radio_synth != null:
					radio_synth.play_switch_clunk()
				desktop_rig_ref.select_brigade_of_current()
			return true
		"PlanetaryGlobeButton3D":
			if war_table_ref != null and war_table_ref.has_method("cycle_macro_space_zoom"):
				if radio_synth != null:
					radio_synth.play_switch_clunk()
				war_table_ref.cycle_macro_space_zoom()
			return true
		"NextTheaterButton3D":
			cycle_next_global_theater()
			return true
		"RedPhoneHotline3D":
			press_red_phone_hotline()
			return true
	return false


func press_red_phone_hotline() -> void:
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if sim_server != null and sim_server.has_method("trigger_red_phone_hotline"):
		if not sim_server.world_state.hotline_is_ringing:
			sim_server.trigger_red_phone_hotline("CONSOLE_RED_PHONE_PICKUP")
	if main_menu_ref != null and main_menu_ref.has_method("open_red_phone_tab"):
		main_menu_ref.open_red_phone_tab()


func cycle_next_global_theater() -> String:
	var scenarios := [
		"op_pacific_shield_2028",
		"op_ukraine_donbas_2028",
		"op_baltic_shield_suwalki",
		"op_himalayan_sentinel_lac",
		"op_korean_thunder_dmz",
		"op_mexico_rio_grande_2028",
		"op_red_strait_swarm",
	]
	_active_theater_cycle_idx = (_active_theater_cycle_idx + 1) % scenarios.size()
	var next_slug: String = scenarios[_active_theater_cycle_idx]
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if main_menu_ref != null and main_menu_ref.has_method("launch_scenario"):
		main_menu_ref.launch_scenario(next_slug, 1.0, Vector2.ZERO)
	elif sim_server != null:
		sim_server.load_scenario(next_slug)
		if war_table_ref != null:
			war_table_ref.bind_sim_server(sim_server)
	_refresh_status_label()
	return next_slug


func toggle_master_iads() -> bool:
	master_iads_active = not master_iads_active
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if command_bus != null:
		command_bus.enqueue_set_master_iads(WorldState.FACTION_BLUE, master_iads_active)
	_refresh_status_label()
	return master_iads_active


func set_time_compression(new_scale: float) -> void:
	current_time_scale = clampf(new_scale, 0.0, 1800.0)
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if command_bus != null:
		command_bus.enqueue_set_time_scale(current_time_scale)
	elif sim_server != null:
		sim_server.world_state.time_scale = current_time_scale
	_refresh_status_label()


func cycle_time_compression() -> float:
	var notches := [0.0, 1.0, 10.0, 60.0, 300.0, 900.0]
	var next_idx := 0
	for i in range(notches.size()):
		if absf(current_time_scale - notches[i]) < 0.1:
			next_idx = (i + 1) % notches.size()
			break
	set_time_compression(notches[next_idx])
	return current_time_scale


func flip_alpha_strike_guard_cover(open: bool) -> void:
	alpha_guard_open = open
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	_refresh_status_label()


func press_execute_alpha_strike() -> void:
	alpha_guard_open = true
	if radio_synth != null:
		radio_synth.play_alpha_strike_klaxon()
	if nuclear_interlock_unlocked and sim_server != null:
		# US-12.1: Two-Man Rule Key Interlock Unlocked -> Launch Strategic Triad SIOP Salvo!
		var StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")
		StrategicMddSystemScript.execute_strategic_triad_siop(sim_server.world_state, sim_server.sim_db_ref, WorldState.FACTION_BLUE)
	elif command_bus != null:
		command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)
	_refresh_status_label()


## US-12.2: Dual Nuclear Key Turn Assemblies (Two-Man Rule Protocol)
func turn_nuclear_key_alpha() -> bool:
	nuclear_key_alpha_turned = not nuclear_key_alpha_turned
	key_alpha_turn_time_sec = float(Time.get_ticks_msec()) * 0.001
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if _key_alpha_lbl != null:
		_key_alpha_lbl.text = "KEY ALPHA\n[ARMED]" if nuclear_key_alpha_turned else "KEY ALPHA\n[SAFE]"
		_key_alpha_lbl.modulate = TacticalTheme.COL_OPFOR_RED if nuclear_key_alpha_turned else TacticalTheme.COL_UNMANNED_GOLD
	check_two_man_rule_interlock()
	return nuclear_key_alpha_turned


func turn_nuclear_key_bravo() -> bool:
	nuclear_key_bravo_turned = not nuclear_key_bravo_turned
	key_bravo_turn_time_sec = float(Time.get_ticks_msec()) * 0.001
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if _key_bravo_lbl != null:
		_key_bravo_lbl.text = "KEY BRAVO\n[ARMED]" if nuclear_key_bravo_turned else "KEY BRAVO\n[SAFE]"
		_key_bravo_lbl.modulate = TacticalTheme.COL_OPFOR_RED if nuclear_key_bravo_turned else TacticalTheme.COL_OPFOR_RED_DIM
	check_two_man_rule_interlock()
	return nuclear_key_bravo_turned


func check_two_man_rule_interlock() -> bool:
	if nuclear_key_alpha_turned and nuclear_key_bravo_turned:
		var time_diff := absf(key_alpha_turn_time_sec - key_bravo_turn_time_sec)
		if time_diff <= 5.0:
			nuclear_interlock_unlocked = true
			if radio_synth != null and radio_synth.has_method("play_defcon_klaxon"):
				radio_synth.play_defcon_klaxon()
			_refresh_status_label()
			return true
	nuclear_interlock_unlocked = false
	_refresh_status_label()
	return false


func press_deploy_unmanned(selected_uid: int = -1) -> int:
	if radio_synth != null:
		radio_synth.play_servo_deploy_chirp()
	if sim_server == null or command_bus == null:
		return 0

	var target_carriers: Array[int] = []
	var state: WorldState = sim_server.world_state
	if selected_uid >= 0 and selected_uid < state.unit_count and state.unit_active[selected_uid] == 1:
		target_carriers.append(selected_uid)
	else:
		# Find up to 4 friendly carriers with available Robot Dog / FPV bays
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				if state.unit_unmanned_bays[uid] > 0:
					target_carriers.append(uid)
					if target_carriers.size() >= 4:
						break

	if target_carriers.size() > 0:
		command_bus.enqueue_deploy_unmanned(target_carriers, Vector3(-2.5, 0.0, -1.5))
	_refresh_status_label()
	return target_carriers.size()


func toggle_recon_photo_mode() -> bool:
	recon_photo_mode = not recon_photo_mode
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if signal_bus != null:
		signal_bus.recon_photo_mode_toggled.emit(recon_photo_mode)
	_refresh_status_label()
	return recon_photo_mode


func toggle_semantic_echelon_override() -> bool:
	force_all_tokens = not force_all_tokens
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if signal_bus != null:
		signal_bus.semantic_override_toggled.emit(force_all_tokens)
	_refresh_status_label()
	return force_all_tokens


func toggle_true_sight() -> bool:
	true_sight_mode = not true_sight_mode
	if radio_synth != null:
		radio_synth.play_switch_clunk()
	if signal_bus != null:
		signal_bus.true_sight_toggled.emit(true_sight_mode)
	_refresh_status_label()
	return true_sight_mode


func _refresh_status_label() -> void:
	if _status_label_3d == null:
		return
	var iads_str := "ACTIVE" if master_iads_active else "EMCON DARK"
	var photo_str := "WIKI PHOTOS ON" if recon_photo_mode else "NATO SYMBOLOGY"
	var nuke_str := "AUTH UNLOCKED" if nuclear_interlock_unlocked else ("ARMED: 1/2" if (nuclear_key_alpha_turned or nuclear_key_bravo_turned) else "SAFE")
	_status_label_3d.text = "IADS: %s | TIME: %.0fx | KEYS: %s | VIEW: %s" % [iads_str, current_time_scale, nuke_str, photo_str]

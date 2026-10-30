class_name FpvTargetingPodController
extends Node3D
## Phase 22: First-Person "Cockpit / Drone / Satellite / Robot Dog / Missile" Live Feed Camera (`PiP Helmet & FLIR Targeting Pod View`).
## Renders a live 3D First-Person FLIR / HUD Targeting Pod Camera feed (`SubViewport` + `Camera3D`)
## attached to any selected unit (`F-35A` at 12,500m, `Vision 60 Robot Dog` on a mountain ridge,
## `FPV Kamikaze Drone` at 120m), any in-flight `Mach-24 Orbital Rod / Hypersonic Missile`,
## or an overhead `550 km LEO Recon Satellite`.

const MODE_SELECTED_UNIT: int = 0
const MODE_IN_FLIGHT_MUNITION: int = 1
const MODE_ORBITAL_SATELLITE: int = 2

const PALETTE_WHITE_HOT_FLIR: int = 0
const PALETTE_GREEN_NVG: int = 1
const PALETTE_COLOR_EO: int = 2

var sim_server: Node = null
var war_table: Node3D = null
var signal_bus: Node = null

var is_pod_active: bool = true
var is_expanded_fullscreen: bool = false
var current_mode: int = MODE_SELECTED_UNIT
var current_palette: int = PALETTE_GREEN_NVG
var tracked_unit_id: int = -1
var tracked_munition_id: int = -1

# Telemetry state exposed for HUD & automated verification tests
var telemetry_callsign: String = "NO LOCK"
var telemetry_platform: String = "STANDBY"
var telemetry_alt_m: float = 0.0
var telemetry_speed_kmh: float = 0.0
var telemetry_mach: float = 0.0
var telemetry_heading_deg: float = 0.0
var telemetry_mode_label: String = "COCKPIT / DRONE FPV"
var camera_updates_count: int = 0

var sub_viewport: SubViewport = null
var pod_camera: Camera3D = null
var monitor_3d_root: Node3D = null
var monitor_3d_label: Label3D = null

var hud_layer: CanvasLayer = null
var hud_panel: PanelContainer = null
var feed_texture_rect: TextureRect = null
var tint_overlay: ColorRect = null
var telemetry_header_lbl: Label = null
var telemetry_footer_lbl: Label = null
var crosshair_center_lbl: Label = null


func _ready() -> void:
	_build_subviewport_and_3d_monitor()
	_build_pip_hud_overlay()
	set_pod_active(not OS.has_feature("android"))


func setup_references(p_sim_server: Node, p_war_table: Node3D, p_signal_bus: Node = null) -> void:
	sim_server = p_sim_server
	war_table = p_war_table
	signal_bus = p_signal_bus
	if get_viewport() != null and sub_viewport != null and sub_viewport.world_3d == null:
		sub_viewport.world_3d = get_viewport().world_3d


func _build_subviewport_and_3d_monitor() -> void:
	sub_viewport = SubViewport.new()
	sub_viewport.name = "FpvPodSubViewport"
	sub_viewport.size = Vector2i(420, 250)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub_viewport)

	pod_camera = Camera3D.new()
	pod_camera.name = "FpvPodCamera3D"
	pod_camera.fov = 52.0
	pod_camera.near = 0.015
	pod_camera.far = 25.0
	pod_camera.position = Vector3(0.0, 1.15, 0.0)
	sub_viewport.add_child(pod_camera)

	# 3D Floating Holographic Targeting Pod Monitor Screen on the right side of the War Table
	monitor_3d_root = Node3D.new()
	monitor_3d_root.name = "FpvPodMonitor3D"
	monitor_3d_root.position = Vector3(1.12, 1.34, -0.32)
	monitor_3d_root.rotation_degrees = Vector3(-8.0, -28.0, 0.0)
	add_child(monitor_3d_root)

	var frame_mi := MeshInstance3D.new()
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(0.54, 0.34, 0.018)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.03, 0.06, 0.09, 1.0)
	frame_mat.metallic = 0.85
	frame_mat.roughness = 0.25
	frame_box.material = frame_mat
	frame_mi.mesh = frame_box
	monitor_3d_root.add_child(frame_mi)

	var screen_mi := MeshInstance3D.new()
	var screen_quad := QuadMesh.new()
	screen_quad.size = Vector2(0.50, 0.28)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mat.albedo_color = Color(0.75, 1.0, 0.82, 1.0)
	screen_mat.albedo_texture = sub_viewport.get_texture()
	screen_quad.material = screen_mat
	screen_mi.mesh = screen_quad
	screen_mi.position = Vector3(0.0, 0.01, 0.011)
	monitor_3d_root.add_child(screen_mi)

	monitor_3d_label = Label3D.new()
	monitor_3d_label.text = "LIVE FPV TARGETING POD // STANDBY"
	monitor_3d_label.font_size = 18
	monitor_3d_label.pixel_size = 0.0011
	monitor_3d_label.modulate = Color(0.25, 1.0, 0.55, 1.0)
	monitor_3d_label.position = Vector3(0.0, -0.145, 0.014)
	monitor_3d_root.add_child(monitor_3d_label)


func _build_pip_hud_overlay() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "FpvTargetingPodHUD"
	hud_layer.layer = 14
	add_child(hud_layer)

	hud_panel = PanelContainer.new()
	hud_panel.name = "FpvPodPanel"
	hud_panel.position = Vector2(12.0, 740.0)
	hud_panel.custom_minimum_size = Vector2(308.0, 210.0)
	hud_panel.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.04, 0.92)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.2, 0.95, 0.45, 0.9)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	hud_panel.add_theme_stylebox_override("panel", sb)
	hud_layer.add_child(hud_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	hud_panel.add_child(vbox)

	telemetry_header_lbl = Label.new()
	telemetry_header_lbl.text = "FPV TARGETING POD [Z] // COCKPIT FEED"
	telemetry_header_lbl.clip_text = true
	telemetry_header_lbl.add_theme_font_size_override("font_size", 10)
	telemetry_header_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	vbox.add_child(telemetry_header_lbl)

	var view_holder := Control.new()
	view_holder.custom_minimum_size = Vector2(292.0, 136.0)
	view_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(view_holder)

	feed_texture_rect = TextureRect.new()
	feed_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	feed_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feed_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if sub_viewport != null:
		feed_texture_rect.texture = sub_viewport.get_texture()
	view_holder.add_child(feed_texture_rect)

	tint_overlay = ColorRect.new()
	tint_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint_overlay.color = Color(0.1, 0.95, 0.35, 0.16)
	view_holder.add_child(tint_overlay)

	crosshair_center_lbl = Label.new()
	crosshair_center_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	crosshair_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair_center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair_center_lbl.text = "- - [ + ] - -\nLRF DESIGNATOR"
	crosshair_center_lbl.add_theme_font_size_override("font_size", 11)
	crosshair_center_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55, 0.82))
	view_holder.add_child(crosshair_center_lbl)

	telemetry_footer_lbl = Label.new()
	telemetry_footer_lbl.text = "ALT: 0 m | SPD: 0 km/h | HDG: 000 | NVG"
	telemetry_footer_lbl.clip_text = true
	telemetry_footer_lbl.add_theme_font_size_override("font_size", 10)
	telemetry_footer_lbl.add_theme_color_override("font_color", Color(0.75, 0.98, 0.80))
	vbox.add_child(telemetry_footer_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 3)
	vbox.add_child(btn_row)

	var btn_mode := Button.new()
	btn_mode.text = "MODE"
	btn_mode.add_theme_font_size_override("font_size", 10)
	btn_mode.pressed.connect(func(): cycle_pod_mode())
	btn_row.add_child(btn_mode)

	var btn_pal := Button.new()
	btn_pal.text = "FLIR/NVG"
	btn_pal.add_theme_font_size_override("font_size", 10)
	btn_pal.pressed.connect(func(): cycle_flir_palette())
	btn_row.add_child(btn_pal)

	var btn_next := Button.new()
	btn_next.text = "NEXT TGT"
	btn_next.add_theme_font_size_override("font_size", 10)
	btn_next.pressed.connect(func(): cycle_next_unit())
	btn_row.add_child(btn_next)

	var btn_exp := Button.new()
	btn_exp.text = "EXPAND"
	btn_exp.add_theme_font_size_override("font_size", 10)
	btn_exp.pressed.connect(func(): toggle_expand_fullscreen())
	btn_row.add_child(btn_exp)


var is_modal_suppressed: bool = false


func set_modal_suppressed(suppressed: bool) -> void:
	is_modal_suppressed = suppressed
	if hud_layer != null:
		hud_layer.visible = is_pod_active and not is_modal_suppressed


func set_pod_active(active: bool) -> void:
	is_pod_active = active
	if sub_viewport != null:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if hud_layer != null:
		hud_layer.visible = active and not is_modal_suppressed
	if monitor_3d_root != null:
		monitor_3d_root.visible = active
	if signal_bus != null and signal_bus.has_signal("fpv_targeting_pod_toggled"):
		signal_bus.fpv_targeting_pod_toggled.emit(active, telemetry_mode_label, tracked_unit_id)


func toggle_pod_active() -> bool:
	set_pod_active(not is_pod_active)
	return is_pod_active


func toggle_expand_fullscreen() -> bool:
	is_expanded_fullscreen = not is_expanded_fullscreen
	if hud_panel != null:
		if is_expanded_fullscreen:
			hud_panel.position = Vector2(340.0, 95.0)
			hud_panel.custom_minimum_size = Vector2(860.0, 520.0)
		else:
			hud_panel.position = Vector2(12.0, 740.0)
			hud_panel.custom_minimum_size = Vector2(308.0, 210.0)
	return is_expanded_fullscreen


func set_pod_mode(mode_id: int) -> void:
	current_mode = clampi(mode_id, MODE_SELECTED_UNIT, MODE_ORBITAL_SATELLITE)
	match current_mode:
		MODE_SELECTED_UNIT:
			telemetry_mode_label = "COCKPIT / DRONE FPV"
		MODE_IN_FLIGHT_MUNITION:
			telemetry_mode_label = "MISSILE / ROD SEEKER CAM"
		MODE_ORBITAL_SATELLITE:
			telemetry_mode_label = "550KM LEO SATELLITE NADIR"
	step_camera_tracking(0.1)


func cycle_pod_mode() -> int:
	set_pod_mode((current_mode + 1) % 3)
	return current_mode


func cycle_flir_palette() -> int:
	current_palette = (current_palette + 1) % 3
	if tint_overlay != null:
		match current_palette:
			PALETTE_WHITE_HOT_FLIR:
				tint_overlay.color = Color(0.92, 0.96, 1.0, 0.22)
			PALETTE_GREEN_NVG:
				tint_overlay.color = Color(0.10, 0.95, 0.35, 0.18)
			PALETTE_COLOR_EO:
				tint_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	return current_palette


func attach_to_unit(uid: int) -> void:
	tracked_unit_id = uid
	current_mode = MODE_SELECTED_UNIT
	telemetry_mode_label = "COCKPIT / DRONE FPV"
	step_camera_tracking(0.1)


func attach_to_munition(mid: int) -> void:
	tracked_munition_id = mid
	current_mode = MODE_IN_FLIGHT_MUNITION
	telemetry_mode_label = "MISSILE / ROD SEEKER CAM"
	step_camera_tracking(0.1)


func cycle_next_unit() -> int:
	if sim_server == null or sim_server.world_state == null:
		return -1
	var state: WorldState = sim_server.world_state
	if state.unit_count <= 0:
		return -1
	var start_idx: int = maxi(0, tracked_unit_id + 1)
	for offset in range(state.unit_count):
		var cand: int = (start_idx + offset) % state.unit_count
		if state.unit_active[cand] == 1 and state.unit_echelon[cand] == WorldState.ECHELON_COMPANY:
			tracked_unit_id = cand
			state.selected_unit_id = cand
			step_camera_tracking(0.1)
			return cand
	return -1


func _process(delta: float) -> void:
	if not is_pod_active:
		return
	step_camera_tracking(delta)


func step_camera_tracking(_dt: float) -> void:
	if sim_server == null or sim_server.world_state == null or pod_camera == null:
		return
	if get_viewport() != null and sub_viewport != null and sub_viewport.world_3d == null:
		sub_viewport.world_3d = get_viewport().world_3d

	var state: WorldState = sim_server.world_state
	var sim_db: Node = sim_server.sim_db_ref
	camera_updates_count += 1

	if current_mode == MODE_IN_FLIGHT_MUNITION:
		_track_in_flight_munition(state, sim_db)
	elif current_mode == MODE_ORBITAL_SATELLITE:
		_track_orbital_satellite(state)
	else:
		_track_selected_or_active_unit(state, sim_db)

	_refresh_hud_labels(state)


func _track_selected_or_active_unit(state: WorldState, sim_db: Node) -> void:
	if state.selected_unit_id >= 0 and state.selected_unit_id < state.unit_count and state.unit_active[state.selected_unit_id] == 1:
		tracked_unit_id = state.selected_unit_id

	if tracked_unit_id < 0 or tracked_unit_id >= state.unit_count or state.unit_active[tracked_unit_id] == 0:
		# Pick an interesting active air/robot-dog/drone company unit
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				tracked_unit_id = uid
				break

	if tracked_unit_id < 0 or tracked_unit_id >= state.unit_count or state.unit_active[tracked_unit_id] == 0:
		telemetry_callsign = "NO UNIT"
		telemetry_platform = "NO SIGNAL"
		return

	var u_pos: Vector3 = state.unit_pos[tracked_unit_id]
	var pid: int = state.unit_platform_id[tracked_unit_id]
	var p_def: Dictionary = sim_db.get_platform(pid) if (sim_db != null and sim_db.has_method("get_platform")) else {}
	var p_name: String = String(p_def.get("display_name", "UNIT-%d" % tracked_unit_id))
	var hdg_rad: float = state.unit_heading_rad[tracked_unit_id]
	var pitch_rad: float = state.unit_pitch_rad[tracked_unit_id]
	var vel_kms: Vector3 = state.unit_vel[tracked_unit_id]
	var spd_kms: float = vel_kms.length()
	if spd_kms < 0.001 and pid > 0 and sim_db != null and pid < sim_db.plat_cruise_km_s.size():
		spd_kms = sim_db.plat_cruise_km_s[pid]

	telemetry_callsign = "%s #%d" % [ ("BLUE" if state.unit_faction[tracked_unit_id] == WorldState.FACTION_BLUE else "RED"), tracked_unit_id ]
	telemetry_platform = p_name
	telemetry_alt_m = u_pos.y
	telemetry_speed_kmh = spd_kms * 3600.0
	telemetry_mach = telemetry_speed_kmh / 1225.0
	telemetry_heading_deg = fposmod(rad_to_deg(hdg_rad), 360.0)

	if war_table != null and war_table.has_method("theater_km_to_table_local"):
		var local_pos: Vector3 = war_table.theater_km_to_table_local(u_pos)
		var world_pos: Vector3 = war_table.table_local_to_world(local_pos + Vector3(0.0, 0.025, 0.0))
		var fwd_dir := Vector3(cos(hdg_rad), sin(pitch_rad) - 0.18, sin(hdg_rad)).normalized()
		var look_target: Vector3 = world_pos + fwd_dir * 0.45
		_orient_pod_camera(world_pos, look_target, Vector3.UP)


func _track_in_flight_munition(state: WorldState, sim_db: Node) -> void:
	var active_mid: int = -1
	if tracked_munition_id >= 0 and tracked_munition_id < state.mun_count and state.mun_active[tracked_munition_id] == 1:
		active_mid = tracked_munition_id
	else:
		for mid in range(state.mun_count):
			if state.mun_active[mid] == 1:
				active_mid = mid
				tracked_munition_id = mid
				break

	if active_mid < 0:
		# Fallback to unit camera if no missile is currently in flight
		_track_selected_or_active_unit(state, sim_db)
		telemetry_mode_label = "SEEKER STANDBY (UNIT CAM)"
		return

	telemetry_mode_label = "MISSILE / ROD SEEKER CAM"
	var m_pos: Vector3 = state.mun_pos[active_mid]
	var t_pos: Vector3 = state.mun_target_pos[active_mid]
	var wid: int = state.mun_weapon_id[active_mid]
	var w_def: Dictionary = sim_db.get_weapon(wid) if (sim_db != null and sim_db.has_method("get_weapon")) else {}
	var w_name: String = String(w_def.get("display_name", "MUNITION-%d" % wid))
	var spd_kms: float = sim_db.weap_speed_km_s[wid] if (sim_db != null and wid > 0 and wid < sim_db.weap_speed_km_s.size()) else 1.2

	telemetry_callsign = "MSL-%d" % active_mid
	telemetry_platform = w_name
	telemetry_alt_m = m_pos.y
	telemetry_speed_kmh = spd_kms * 3600.0
	telemetry_mach = telemetry_speed_kmh / 1225.0
	var dx: float = t_pos.x - m_pos.x
	var dz: float = t_pos.z - m_pos.z
	telemetry_heading_deg = fposmod(rad_to_deg(atan2(dz, dx)), 360.0)

	if war_table != null and war_table.has_method("theater_km_to_table_local"):
		var world_m: Vector3 = war_table.table_local_to_world(war_table.theater_km_to_table_local(m_pos) + Vector3(0.0, 0.03, 0.0))
		var world_t: Vector3 = war_table.table_local_to_world(war_table.theater_km_to_table_local(t_pos) + Vector3(0.0, 0.005, 0.0))
		_orient_pod_camera(world_m, world_t, Vector3.UP)


func _track_orbital_satellite(state: WorldState) -> void:
	telemetry_mode_label = "550KM LEO SATELLITE NADIR"
	telemetry_callsign = "USA-348 // KH-13 SAR"
	telemetry_platform = "LEO RECON SATELLITE (550 KM)"
	telemetry_alt_m = 550000.0
	telemetry_speed_kmh = 27324.0 # 7.59 km/s orbital velocity
	telemetry_mach = 22.3
	telemetry_heading_deg = fposmod(state.sim_time_sec * 4.5, 360.0)

	if war_table != null:
		var base_pos: Vector3 = war_table.global_position if war_table.is_inside_tree() else war_table.position
		var sat_world := base_pos + Vector3(0.0, 1.35, 0.02)
		var nadir_target := base_pos + Vector3(0.0, 0.0, 0.0)
		_orient_pod_camera(sat_world, nadir_target, Vector3.FORWARD)


func _orient_pod_camera(world_pos: Vector3, look_target: Vector3, up_vec: Vector3 = Vector3.UP) -> void:
	if pod_camera == null:
		return
	if pod_camera.is_inside_tree():
		pod_camera.global_position = world_pos
		if world_pos.distance_squared_to(look_target) > 0.0001:
			pod_camera.look_at_from_position(world_pos, look_target, up_vec)
	else:
		pod_camera.position = world_pos
		if world_pos.distance_squared_to(look_target) > 0.0001:
			pod_camera.transform = Transform3D(Basis.looking_at(look_target - world_pos, up_vec), world_pos)


func _refresh_hud_labels(state: WorldState) -> void:
	var pal_name: String = "NVG"
	if current_palette == PALETTE_WHITE_HOT_FLIR:
		pal_name = "WH-FLIR"
	elif current_palette == PALETTE_COLOR_EO:
		pal_name = "EO-COLOR"

	if telemetry_header_lbl != null:
		telemetry_header_lbl.text = "FPV POD [Z] // %s // %s (%s)" % [
			telemetry_mode_label, telemetry_platform.substr(0, mini(24, telemetry_platform.length())), telemetry_callsign
		]
	if telemetry_footer_lbl != null:
		telemetry_footer_lbl.text = "ALT: %.0fm | SPD: %.0f km/h (M%.1f) | HDG: %03.0f° | WX: %s | %s" % [
			telemetry_alt_m, telemetry_speed_kmh, telemetry_mach, telemetry_heading_deg, state.weather_condition_code, pal_name
		]
	if monitor_3d_label != null:
		monitor_3d_label.text = "%s // %s // ALT %.0fm // M%.1f" % [
			telemetry_mode_label, telemetry_callsign, telemetry_alt_m, telemetry_mach
		]

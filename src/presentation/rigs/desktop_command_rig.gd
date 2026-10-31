class_name DesktopCommandRig
extends Node3D
## Desktop Mouse & Keyboard Orbital + Tacview 3D Follow Command Rig & JOC Staff HUD.
## Controls:
## - `WASD`: Pan across the 500km x 500km Holographic War Table
## - `Mouse Wheel` / `Q` & `E`: Smooth Zoom (`1.0x` Theater -> `4.0x` Squad/Wingman -> `12.0x+` Individual Soldiers & Robot Dogs)
## - `Left Click`: True 3D Ray Selection (selects 3D aircraft in the sky, warships, tanks, robot dogs & infantry)
## - `Right Click (Tap)`: Issue 3D Move Waypoint or Strike Salvo Vector with live `StrikePreviewRenderer`
## - `Right-Mouse Drag`: Free 3D Tacview Camera Orbit & Pitch (`-12°` low-angle Tacview view to `-82°` overhead)
## - `C`: Toggle Tacview 3D Follow Camera on selected unit | `1`–`6`: Unit Military Mission Orders | `F1`–`F3`: AI Subordinate COAs

const SubordinateStaffAIScript := preload("res://src/ai/advisor/subordinate_staff_ai.gd")

var war_table: Node3D = null
var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null
var tactile_console: Node3D = null
var main_menu: Node = null
var theater_director: Node = null
var subordinate_staff: Node = null
var tutorial_controller: Node = null
var story_director_ref: Node = null
var fpv_pod_ref: Node = null
var submarine_conn_ref: Node = null
var tri_command_ref: Node = null
var xr_rig_ref: Node3D = null
var radio_synth_ref: Node = null

var camera: Camera3D = null
var hud_layer: CanvasLayer = null
var _audio_mute_btn: Button = null
var _style_mode_btn: Button = null
var _hud_mode_btn: Button = null
var _left_hud_card: PanelContainer = null
var _bottom_cmd_bar: PanelContainer = null
var _tab_sitrep_vb: VBoxContainer = null
var _tab_orbat_vb: VBoxContainer = null
var _tab_strategic_vb: VBoxContainer = null
var _left_tab_btns: Array[Button] = []
var active_left_hud_tab: int = 0
var hud_layout_mode: int = 0
var is_modal_suppressed: bool = false
var _sniper_cycle_idx: int = 0

var active_spatial_tool: String = ""
var _spatial_tool_status_label: Label = null

const SPATIAL_TOOL_SPECS: Dictionary = {
	"AIRBORNE_PARATROOP_DROP": {"label": "C-17 AIRBORNE PARATROOP & ROBOT DOG DROP", "radius_km": 22.0, "color": Color(0.20, 1.0, 0.55, 0.95)},
	"DEPLOY_SMART_MINEFIELD": {"label": "SCATTERABLE SMART ANTI-ARMOR MINEFIELD", "radius_km": 18.0, "color": Color(1.0, 0.78, 0.20, 0.95)},
	"BUNKER_BUSTER_MOP": {"label": "B-21 GBU-57 MOP DEEP BUNKER-BUSTER STRIKE", "radius_km": 14.0, "color": Color(1.0, 0.45, 0.85, 0.95)},
	"CEMA_DRONE_HIJACK": {"label": "CEMA CYBER-EW SWARM HIJACK & SCADA BLACKOUT", "radius_km": 48.0, "color": Color(0.0, 0.95, 1.0, 0.95)},
	"STRIKE_TACTICAL_CBRN": {"label": "TACTICAL CBRN AEROSOL CONTAMINATION PLUME", "radius_km": 32.0, "color": Color(0.65, 1.0, 0.15, 0.95)},
	"STRIKE_HEMP_EMP": {"label": "HIGH-ALTITUDE ELECTROMAGNETIC PULSE (HEMP)", "radius_km": 85.0, "color": Color(0.25, 0.85, 1.0, 0.95)},
	"STRIKE_ORBITAL_RODS": {"label": "MACH-24 ORBITAL TUNGSTEN KINETIC ROD STRIKE", "radius_km": 28.0, "color": Color(1.0, 0.88, 0.30, 0.95)},
	"STRIKE_THERMONUCLEAR": {"label": "DEFCON 1 THERMONUCLEAR TRIAD MIRV DETONATION", "radius_km": 65.0, "color": Color(1.0, 0.18, 0.28, 0.98)},
}

const HUD_LAYOUT_NAMES: Array[String] = [
	"FULL JOC STAFF HUD",
	"COMPACT TACTICAL HUD",
	"CLEAN CINEMATIC WAR TABLE",
]

var selected_unit_id: int = -1
var selected_unit_ids: Array[int] = []
var control_groups: Dictionary = {1: [], 2: [], 3: []}
var follow_selected_unit_cam: bool = false
var _orbit_yaw_deg: float = 0.0
var _orbit_pitch_deg: float = -33.0
var _camera_dist_m: float = 1.84
var _camera_look_target: Vector3 = Vector3(0.0, 0.88, 0.06)
var _rmb_pressed: bool = false
var _rmb_press_pos: Vector2 = Vector2.ZERO
var _rmb_dragged: bool = false
var _lmb_pressed: bool = false
var _lmb_press_pos: Vector2 = Vector2.ZERO
var _lmb_dragged: bool = false
var _selection_box_panel: Panel = null

var _top_ledger_label: Label = null
var _frago_banner_label: Label = null
var _staff_sitrep_label: Label = null
var _live_casualty_ammo_label: Label = null
var _selection_org_label: Label = null
var _budget_defcon_label: Label = null
var _world_news_label: Label = null
var _tv_news_video_rect: TextureRect = null
var _tv_news_stream_player: VideoStreamPlayer = null
var _tv_news_header_label: Label = null
var _tv_news_chyron_label: Label = null
var _tv_news_anim_time: float = 0.0
var _tv_channel_index: int = 0
var _zoom_echelon_label: Label = null
var _time_status_btn: Button = null


func _ready() -> void:
	if camera != null:
		return
	_setup_camera()
	_build_tactical_hud()


func setup(p_war_table: Node3D, p_sim_server: Node, p_cmd_bus: Node, p_sig_bus: Node, p_console: Node3D, p_menu: Node, p_director: Node, p_staff: Node = null, p_tutorial: Node = null) -> void:
	war_table = p_war_table
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	tactile_console = p_console
	main_menu = p_menu
	theater_director = p_director
	subordinate_staff = p_staff
	tutorial_controller = p_tutorial
	if signal_bus != null and not signal_bus.frago_received.is_connected(_on_frago_received):
		signal_bus.frago_received.connect(_on_frago_received)


func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "DesktopCommandCamera3D"
	camera.fov = 56.0
	add_child(camera)
	_update_camera_transform()


func _update_camera_transform() -> void:
	if camera == null:
		return
	var yaw_rad := deg_to_rad(_orbit_yaw_deg)
	var pitch_rad := deg_to_rad(_orbit_pitch_deg)
	var horiz := cos(-pitch_rad) * _camera_dist_m
	var vert := sin(-pitch_rad) * _camera_dist_m
	var cam_pos := _camera_look_target + Vector3(sin(yaw_rad) * horiz, vert, cos(yaw_rad) * horiz)
	camera.look_at_from_position(cam_pos, _camera_look_target, Vector3.UP)


func _build_tactical_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "DesktopTacticalHUD"
	hud_layer.layer = 4
	add_child(hud_layer)

	var theme := TacticalTheme.create_theme()

	# 1. Top Telemetry & Economic War Ledger Bar (Strictly fits 1920px width with zero overflow)
	var top_bar := PanelContainer.new()
	top_bar.theme = theme
	top_bar.clip_contents = true
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 12.0
	top_bar.offset_right = -12.0
	top_bar.offset_top = 6.0
	top_bar.offset_bottom = 44.0
	hud_layer.add_child(top_bar)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hb)

	var menu_btn := Button.new()
	menu_btn.text = "[MENU / SCENARIOS (ESC)]"
	menu_btn.add_theme_font_size_override("font_size", 11)
	menu_btn.pressed.connect(func():
		if main_menu != null:
			main_menu.set_menu_visible(not main_menu.is_menu_open)
	)
	top_hb.add_child(menu_btn)

	var tut_btn := Button.new()
	tut_btn.text = "[BOOT-CAMP (H)]"
	tut_btn.add_theme_font_size_override("font_size", 11)
	tut_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	tut_btn.pressed.connect(func():
		if tutorial_controller != null and tutorial_controller.has_method("toggle_bootcamp"):
			tutorial_controller.call("toggle_bootcamp")
	)
	top_hb.add_child(tut_btn)

	var story_btn := Button.new()
	story_btn.text = "[CAMPAIGN (P)]"
	story_btn.add_theme_font_size_override("font_size", 11)
	story_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.25))
	story_btn.pressed.connect(func():
		if story_director_ref != null and story_director_ref.has_method("toggle_story_campaign"):
			story_director_ref.call("toggle_story_campaign")
	)
	top_hb.add_child(story_btn)

	var tech_top_btn := Button.new()
	tech_top_btn.text = "[TECH & BUDGET (K)]"
	tech_top_btn.add_theme_font_size_override("font_size", 11)
	tech_top_btn.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	tech_top_btn.pressed.connect(func():
		if main_menu != null and main_menu.has_method("open_tech_tree_tab"):
			main_menu.call("open_tech_tree_tab")
	)
	top_hb.add_child(tech_top_btn)

	_audio_mute_btn = Button.new()
	_audio_mute_btn.text = "[AUDIO: ON (M)]"
	_audio_mute_btn.add_theme_font_size_override("font_size", 11)
	_audio_mute_btn.add_theme_color_override("font_color", TacticalTheme.COL_CONTOUR_EMERALD)
	_audio_mute_btn.pressed.connect(func():
		if radio_synth_ref != null and radio_synth_ref.has_method("toggle_audio_mute"):
			var muted: bool = radio_synth_ref.call("toggle_audio_mute")
			_audio_mute_btn.text = "[AUDIO: MUTED (M)]" if muted else "[AUDIO: ON (M)]"
	)
	top_hb.add_child(_audio_mute_btn)

	_style_mode_btn = Button.new()
	_style_mode_btn.text = "[STYLE: HOLO (F12)]"
	_style_mode_btn.add_theme_font_size_override("font_size", 11)
	_style_mode_btn.add_theme_color_override("font_color", TacticalTheme.COL_DIRECTED_ENERGY)
	_style_mode_btn.pressed.connect(func():
		cycle_graphic_style()
	)
	top_hb.add_child(_style_mode_btn)

	_hud_mode_btn = Button.new()
	_hud_mode_btn.text = "[HUD: FULL (BKSP)]"
	_hud_mode_btn.add_theme_font_size_override("font_size", 11)
	_hud_mode_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	_hud_mode_btn.pressed.connect(func():
		cycle_hud_layout_mode()
	)
	top_hb.add_child(_hud_mode_btn)

	var sub_top_btn := Button.new()
	sub_top_btn.text = "[⚓ 688 SUB SIM (;)]"
	sub_top_btn.add_theme_font_size_override("font_size", 11)
	sub_top_btn.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
	sub_top_btn.pressed.connect(func():
		if submarine_conn_ref != null and submarine_conn_ref.has_method("toggle_sub_sim_active"):
			submarine_conn_ref.call("toggle_sub_sim_active")
	)
	top_hb.add_child(sub_top_btn)

	_top_ledger_label = Label.new()
	_top_ledger_label.text = "BLUE LOST: $0.0M | RED DESTROYED: $0.0M | INTERCEPTS: 0"
	_top_ledger_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_ledger_label.clip_text = true
	_top_ledger_label.add_theme_font_size_override("font_size", 11)
	_top_ledger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_ledger_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	top_hb.add_child(_top_ledger_label)

	_zoom_echelon_label = Label.new()
	_zoom_echelon_label.custom_minimum_size = Vector2(210.0, 0.0)
	_zoom_echelon_label.clip_text = true
	_zoom_echelon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_zoom_echelon_label.add_theme_font_size_override("font_size", 11)
	_zoom_echelon_label.text = "ZOOM: 1.0x [3D TACVIEW]"
	_zoom_echelon_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	top_hb.add_child(_zoom_echelon_label)

	# 2. Compact 3-Tab Left Tactical Strip (308px wide, x=12..320, y=50..660 — zero overlap with FpvPodPanel at y=740..950!)
	var left_card := PanelContainer.new()
	_left_hud_card = left_card
	left_card.theme = theme
	left_card.clip_contents = true
	left_card.custom_minimum_size = Vector2(308.0, 560.0)
	left_card.offset_left = 12.0
	left_card.offset_right = 320.0
	left_card.offset_top = 50.0
	left_card.offset_bottom = 655.0
	hud_layer.add_child(left_card)

	var left_vb := VBoxContainer.new()
	left_vb.add_theme_constant_override("separation", 4)
	left_card.add_child(left_vb)

	# Always-visible DEFCON, Budget & HQ Bunker Header
	_budget_defcon_label = Label.new()
	_budget_defcon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_budget_defcon_label.add_theme_font_size_override("font_size", 10)
	_budget_defcon_label.text = "■ DEFCON 4 (ESC: 22%) | BUDGET: $2850M (+$120M/m)\n★ HQ BUNKER: HENGSHAN (100% HP)"
	_budget_defcon_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	left_vb.add_child(_budget_defcon_label)

	# 3-Tab Mode Switcher Bar
	var tab_switch_hb := HBoxContainer.new()
	tab_switch_hb.add_theme_constant_override("separation", 3)
	left_vb.add_child(tab_switch_hb)

	_left_tab_btns.clear()
	var tab_titles := ["1. TV & SITREP", "2. ORBAT/STAFF", "3. WMD/GLOBE"]
	for t_i in range(tab_titles.size()):
		var tbtn := Button.new()
		tbtn.text = tab_titles[t_i]
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.add_theme_font_size_override("font_size", 10)
		var captured_idx := t_i
		tbtn.pressed.connect(func(): switch_left_hud_tab(captured_idx))
		tab_switch_hb.add_child(tbtn)
		_left_tab_btns.append(tbtn)

	# ========================================================================
	# TAB 0: LIVE TV NEWS MONITOR, WORLD WIRE, FRAGO & CASUALTY/AMMO LEDGER
	# ========================================================================
	_tab_sitrep_vb = VBoxContainer.new()
	_tab_sitrep_vb.add_theme_constant_override("separation", 4)
	left_vb.add_child(_tab_sitrep_vb)

	var tv_hb := HBoxContainer.new()
	tv_hb.add_theme_constant_override("separation", 5)
	_tab_sitrep_vb.add_child(tv_hb)

	var tv_screen_panel := PanelContainer.new()
	tv_screen_panel.custom_minimum_size = Vector2(124.0, 74.0)
	tv_hb.add_child(tv_screen_panel)

	_tv_news_video_rect = TextureRect.new()
	_tv_news_video_rect.name = "LiveTvNewsVideoRect"
	_tv_news_video_rect.custom_minimum_size = Vector2(120.0, 70.0)
	_tv_news_video_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tv_news_video_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tv_screen_panel.add_child(_tv_news_video_rect)

	_tv_news_stream_player = VideoStreamPlayer.new()
	_tv_news_stream_player.name = "LiveTvNewsStreamPlayer"
	_tv_news_stream_player.expand = true
	_tv_news_stream_player.volume_db = -18.0
	_tv_news_stream_player.visible = false
	tv_screen_panel.add_child(_tv_news_stream_player)

	var tv_info_vb := VBoxContainer.new()
	tv_info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv_info_vb.add_theme_constant_override("separation", 2)
	tv_hb.add_child(tv_info_vb)

	_tv_news_header_label = Label.new()
	_tv_news_header_label.clip_text = true
	_tv_news_header_label.add_theme_font_size_override("font_size", 10)
	_tv_news_header_label.text = "● LIVE TV // GNN WAR DESK"
	_tv_news_header_label.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	tv_info_vb.add_child(_tv_news_header_label)

	_tv_news_chyron_label = Label.new()
	_tv_news_chyron_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tv_news_chyron_label.add_theme_font_size_override("font_size", 9)
	_tv_news_chyron_label.text = "BREAKING: MISSILE SALVO LAUNCHED ACROSS THEATER"
	_tv_news_chyron_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	tv_info_vb.add_child(_tv_news_chyron_label)

	var tv_btns_hb := HBoxContainer.new()
	tv_btns_hb.add_theme_constant_override("separation", 3)
	tv_info_vb.add_child(tv_btns_hb)

	var btn_ai_news := Button.new()
	btn_ai_news.text = "[J] AI TV"
	btn_ai_news.add_theme_font_size_override("font_size", 9)
	btn_ai_news.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ai_news.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_ai_news.pressed.connect(func(): trigger_live_ai_tv_report())
	tv_btns_hb.add_child(btn_ai_news)

	var btn_next_ch := Button.new()
	btn_next_ch.text = "NEXT >>"
	btn_next_ch.add_theme_font_size_override("font_size", 9)
	btn_next_ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_next_ch.pressed.connect(func(): cycle_tv_news_channel())
	tv_btns_hb.add_child(btn_next_ch)

	var btn_tv_studio := Button.new()
	btn_tv_studio.text = "STUDIO"
	btn_tv_studio.add_theme_font_size_override("font_size", 9)
	btn_tv_studio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tv_studio.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_tv_studio.pressed.connect(func():
		if main_menu != null and main_menu.has_method("open_news_video_studio_tab"):
			main_menu.call("open_news_video_studio_tab")
	)
	tv_btns_hb.add_child(btn_tv_studio)

	_world_news_label = Label.new()
	_world_news_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_world_news_label.add_theme_font_size_override("font_size", 10)
	_world_news_label.text = "[WORLD NEWS WIRE] UN Security Council convenes emergency session as 7 global flashpoints mobilize."
	_world_news_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	_tab_sitrep_vb.add_child(_world_news_label)

	_frago_banner_label = Label.new()
	_frago_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_frago_banner_label.add_theme_font_size_override("font_size", 10)
	_frago_banner_label.text = "OPORD // LMB-Click or Box-Drag to select units. [B] Battalion, [V] Brigade. RMB to issue Waypoints/Strikes."
	_frago_banner_label.add_theme_color_override("font_color", TacticalTheme.COL_TEXT_PRIMARY)
	_tab_sitrep_vb.add_child(_frago_banner_label)

	var stat_hdr := Label.new()
	stat_hdr.text = "LIVE CASUALTIES & AMMUNITION LEDGER:"
	stat_hdr.add_theme_font_size_override("font_size", 10)
	stat_hdr.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	_tab_sitrep_vb.add_child(stat_hdr)

	_live_casualty_ammo_label = Label.new()
	_live_casualty_ammo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_live_casualty_ammo_label.add_theme_font_size_override("font_size", 10)
	_live_casualty_ammo_label.text = "BLUE: KIA 0 | WIA 0 | AMMO 100%\nRED:  KIA 0 | WIA 0 | AMMO 100%"
	_live_casualty_ammo_label.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	_tab_sitrep_vb.add_child(_live_casualty_ammo_label)

	var quick_coa_hb := HBoxContainer.new()
	quick_coa_hb.add_theme_constant_override("separation", 3)
	_tab_sitrep_vb.add_child(quick_coa_hb)

	var q_snipers := Button.new()
	q_snipers.text = "[I] SNIPERS"
	q_snipers.add_theme_font_size_override("font_size", 10)
	q_snipers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_snipers.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	q_snipers.pressed.connect(func(): select_and_focus_snipers_and_commandos())
	quick_coa_hb.add_child(q_snipers)

	var q_ammo := Button.new()
	q_ammo.text = "+AMMO $250M"
	q_ammo.add_theme_font_size_override("font_size", 10)
	q_ammo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_ammo.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	q_ammo.pressed.connect(func():
		if sim_server != null and sim_server.has_method("procure_ammo_airlift"):
			sim_server.procure_ammo_airlift(1)
	)
	quick_coa_hb.add_child(q_ammo)

	var q_globe := Button.new()
	q_globe.text = "[O] 3D GLOBE"
	q_globe.add_theme_font_size_override("font_size", 10)
	q_globe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_globe.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	q_globe.pressed.connect(func():
		if war_table != null and war_table.has_method("cycle_macro_space_zoom"):
			war_table.cycle_macro_space_zoom()
	)
	quick_coa_hb.add_child(q_globe)

	# ========================================================================
	# TAB 1: FORCE ORGANIZATION, TIME ACCELERATION & AI SUBORDINATE STAFF COAs
	# ========================================================================
	_tab_orbat_vb = VBoxContainer.new()
	_tab_orbat_vb.visible = false
	_tab_orbat_vb.add_theme_constant_override("separation", 4)
	left_vb.add_child(_tab_orbat_vb)

	_selection_org_label = Label.new()
	_selection_org_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_org_label.add_theme_font_size_override("font_size", 10)
	_selection_org_label.text = "FORCE ORG (BRIGADE [2] -> BATTALION [1] -> COMPANY [0]):"
	_selection_org_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	_tab_orbat_vb.add_child(_selection_org_label)

	var sel_grid := GridContainer.new()
	sel_grid.columns = 3
	sel_grid.add_theme_constant_override("h_separation", 3)
	sel_grid.add_theme_constant_override("v_separation", 3)
	_tab_orbat_vb.add_child(sel_grid)

	var btn_bn := Button.new()
	btn_bn.text = "[B] BATTALION"
	btn_bn.add_theme_font_size_override("font_size", 10)
	btn_bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bn.pressed.connect(func(): select_battalion_of_current())
	sel_grid.add_child(btn_bn)

	var btn_bde := Button.new()
	btn_bde.text = "[V] BRIGADE"
	btn_bde.add_theme_font_size_override("font_size", 10)
	btn_bde.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bde.pressed.connect(func(): select_brigade_of_current())
	sel_grid.add_child(btn_bde)

	var btn_snipers := Button.new()
	btn_snipers.text = "[I] SNIPERS"
	btn_snipers.add_theme_font_size_override("font_size", 10)
	btn_snipers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_snipers.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_snipers.pressed.connect(func(): select_and_focus_snipers_and_commandos())
	sel_grid.add_child(btn_snipers)

	var btn_air := Button.new()
	btn_air.text = "ALL AIR"
	btn_air.add_theme_font_size_override("font_size", 10)
	btn_air.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_air.pressed.connect(func(): select_domain_units("AIR"))
	sel_grid.add_child(btn_air)

	var btn_arm := Button.new()
	btn_arm.text = "ALL LAND"
	btn_arm.add_theme_font_size_override("font_size", 10)
	btn_arm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_arm.pressed.connect(func(): select_domain_units("LAND"))
	sel_grid.add_child(btn_arm)

	var btn_sea := Button.new()
	btn_sea.text = "ALL SEA"
	btn_sea.add_theme_font_size_override("font_size", 10)
	btn_sea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sea.pressed.connect(func(): select_domain_units("SEA"))
	sel_grid.add_child(btn_sea)

	var time_hdr := Label.new()
	time_hdr.text = "SIMULATION TIME ACCELERATION:"
	time_hdr.add_theme_font_size_override("font_size", 10)
	time_hdr.add_theme_color_override("font_color", TacticalTheme.COL_CONTOUR_EMERALD)
	_tab_orbat_vb.add_child(time_hdr)

	var time_hb := HBoxContainer.new()
	time_hb.add_theme_constant_override("separation", 2)
	_tab_orbat_vb.add_child(time_hb)

	var time_presets := [
		["0x", 0.0],
		["1x", 1.0],
		["10x", 10.0],
		["60x", 60.0],
		["300x", 300.0],
		["900x", 900.0],
	]
	for tp in time_presets:
		var t_btn := Button.new()
		t_btn.text = String(tp[0])
		t_btn.add_theme_font_size_override("font_size", 10)
		t_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sc_val := float(tp[1])
		t_btn.pressed.connect(func(): set_sim_time_scale(sc_val))
		time_hb.add_child(t_btn)

	_staff_sitrep_label = Label.new()
	_staff_sitrep_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_staff_sitrep_label.add_theme_font_size_override("font_size", 10)
	_staff_sitrep_label.text = "JOC AI SUBORDINATE STAFF SITREP: Analyzing theater sensors..."
	_staff_sitrep_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	_tab_orbat_vb.add_child(_staff_sitrep_label)

	var coa_hdr := Label.new()
	coa_hdr.text = "AI SUBORDINATE COURSES OF ACTION (F1-F4):"
	coa_hdr.add_theme_font_size_override("font_size", 10)
	coa_hdr.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	_tab_orbat_vb.add_child(coa_hdr)

	var coa_grid := GridContainer.new()
	coa_grid.columns = 2
	coa_grid.add_theme_constant_override("h_separation", 3)
	coa_grid.add_theme_constant_override("v_separation", 3)
	_tab_orbat_vb.add_child(coa_grid)

	var btn_coa1 := Button.new()
	btn_coa1.text = "[F1] JFACC AIR SWEEP"
	btn_coa1.add_theme_font_size_override("font_size", 10)
	btn_coa1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_coa1.pressed.connect(func():
		if subordinate_staff != null:
			subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFACC_AIR_SUPERIORITY)
	)
	coa_grid.add_child(btn_coa1)

	var btn_coa2 := Button.new()
	btn_coa2.text = "[F2] JFLCC DOG/MECH"
	btn_coa2.add_theme_font_size_override("font_size", 10)
	btn_coa2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_coa2.pressed.connect(func():
		if subordinate_staff != null:
			subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFLCC_GROUND_VANGUARD)
	)
	coa_grid.add_child(btn_coa2)

	var btn_coa3 := Button.new()
	btn_coa3.text = "[F3] JOINT TOT SALVO"
	btn_coa3.add_theme_font_size_override("font_size", 10)
	btn_coa3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_coa3.pressed.connect(func():
		if subordinate_staff != null:
			subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFC_JOINT_TOT_STRIKE)
	)
	coa_grid.add_child(btn_coa3)

	var btn_f4_scale := Button.new()
	btn_f4_scale.text = "[F4] REINFORCE +6.5K"
	btn_f4_scale.add_theme_font_size_override("font_size", 10)
	btn_f4_scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_f4_scale.pressed.connect(func():
		if sim_server != null and sim_server.has_method("spawn_army_group_reinforcements"):
			sim_server.spawn_army_group_reinforcements(6500)
	)
	coa_grid.add_child(btn_f4_scale)

	# ========================================================================
	# TAB 2: STRATEGIC DETERRENCE, SPACE/CYBER & 7 GLOBAL THEATERS
	# ========================================================================
	_tab_strategic_vb = VBoxContainer.new()
	_tab_strategic_vb.visible = false
	_tab_strategic_vb.add_theme_constant_override("separation", 4)
	left_vb.add_child(_tab_strategic_vb)

	var wmd_hdr := Label.new()
	wmd_hdr.text = "STRATEGIC DETERRENCE & HQ COMMAND:"
	wmd_hdr.add_theme_font_size_override("font_size", 10)
	wmd_hdr.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	_tab_strategic_vb.add_child(wmd_hdr)

	var wmd_grid := GridContainer.new()
	wmd_grid.columns = 2
	wmd_grid.add_theme_constant_override("h_separation", 3)
	wmd_grid.add_theme_constant_override("v_separation", 3)
	_tab_strategic_vb.add_child(wmd_grid)

	var btn_tech := Button.new()
	btn_tech.text = "[K] R&D TECH TREE"
	btn_tech.add_theme_font_size_override("font_size", 10)
	btn_tech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tech.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_tech.pressed.connect(func():
		if main_menu != null and main_menu.has_method("open_tech_tree_tab"):
			main_menu.call("open_tech_tree_tab")
	)
	wmd_grid.add_child(btn_tech)

	var btn_reloc_hq := Button.new()
	btn_reloc_hq.text = "[R] RELOCATE HQ"
	btn_reloc_hq.add_theme_font_size_override("font_size", 10)
	btn_reloc_hq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_reloc_hq.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	btn_reloc_hq.pressed.connect(func():
		if sim_server != null and sim_server.has_method("relocate_bunker"):
			sim_server.relocate_bunker()
	)
	wmd_grid.add_child(btn_reloc_hq)

	var btn_cbrn_wmd := Button.new()
	btn_cbrn_wmd.text = "🎯 TARGET CBRN"
	btn_cbrn_wmd.add_theme_font_size_override("font_size", 10)
	btn_cbrn_wmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cbrn_wmd.pressed.connect(func(): arm_spatial_targeting_tool("STRIKE_TACTICAL_CBRN"))
	wmd_grid.add_child(btn_cbrn_wmd)

	var btn_hemp_wmd := Button.new()
	btn_hemp_wmd.text = "🎯 TARGET HEMP"
	btn_hemp_wmd.add_theme_font_size_override("font_size", 10)
	btn_hemp_wmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hemp_wmd.pressed.connect(func(): arm_spatial_targeting_tool("STRIKE_HEMP_EMP"))
	wmd_grid.add_child(btn_hemp_wmd)

	var btn_rods_wmd := Button.new()
	btn_rods_wmd.text = "🎯 ORBITAL RODS"
	btn_rods_wmd.add_theme_font_size_override("font_size", 10)
	btn_rods_wmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rods_wmd.pressed.connect(func(): arm_spatial_targeting_tool("STRIKE_ORBITAL_RODS"))
	wmd_grid.add_child(btn_rods_wmd)

	var btn_nuke_wmd := Button.new()
	btn_nuke_wmd.text = "🎯 [N] THERMONUCLEAR"
	btn_nuke_wmd.add_theme_font_size_override("font_size", 10)
	btn_nuke_wmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_nuke_wmd.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	btn_nuke_wmd.pressed.connect(func(): arm_spatial_targeting_tool("STRIKE_THERMONUCLEAR"))
	wmd_grid.add_child(btn_nuke_wmd)

	var mdd_hdr := Label.new()
	mdd_hdr.text = "SPACE / CYBER / PSYOP ([O], [7]-[0]):"
	mdd_hdr.add_theme_font_size_override("font_size", 10)
	mdd_hdr.add_theme_color_override("font_color", TacticalTheme.COL_DIRECTED_ENERGY)
	_tab_strategic_vb.add_child(mdd_hdr)

	var mdd_hb := HBoxContainer.new()
	mdd_hb.add_theme_constant_override("separation", 2)
	_tab_strategic_vb.add_child(mdd_hb)

	var btn_orb := Button.new()
	btn_orb.text = "[O] GLOBE"
	btn_orb.add_theme_font_size_override("font_size", 10)
	btn_orb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_orb.pressed.connect(func():
		if war_table != null and war_table.has_method("cycle_macro_space_zoom"):
			war_table.cycle_macro_space_zoom()
	)
	mdd_hb.add_child(btn_orb)

	var btn_asat := Button.new()
	btn_asat.text = "[7] ASAT"
	btn_asat.add_theme_font_size_override("font_size", 10)
	btn_asat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_asat.pressed.connect(func():
		if sim_server != null and sim_server.has_method("execute_mdd_action"):
			sim_server.execute_mdd_action("ORDER_ASAT_STRIKE", selected_unit_id)
	)
	mdd_hb.add_child(btn_asat)

	var btn_cyber := Button.new()
	btn_cyber.text = "[8] CYBER"
	btn_cyber.add_theme_font_size_override("font_size", 10)
	btn_cyber.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cyber.pressed.connect(func():
		if sim_server != null and sim_server.has_method("execute_mdd_action"):
			sim_server.execute_mdd_action("ORDER_CYBER_CNO", selected_unit_id)
	)
	mdd_hb.add_child(btn_cyber)

	var btn_psyop := Button.new()
	btn_psyop.text = "[9] PSYOP"
	btn_psyop.add_theme_font_size_override("font_size", 10)
	btn_psyop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_psyop.pressed.connect(func():
		if sim_server != null and sim_server.has_method("execute_mdd_action"):
			sim_server.execute_mdd_action("ORDER_PSYOP_EVAC", selected_unit_id)
	)
	mdd_hb.add_child(btn_psyop)

	var th_hdr := Label.new()
	th_hdr.text = "7 GLOBAL FLASHPOINT THEATERS:"
	th_hdr.add_theme_font_size_override("font_size", 10)
	th_hdr.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	_tab_strategic_vb.add_child(th_hdr)

	var th_grid := GridContainer.new()
	th_grid.columns = 4
	th_grid.add_theme_constant_override("h_separation", 2)
	th_grid.add_theme_constant_override("v_separation", 2)
	_tab_strategic_vb.add_child(th_grid)

	var quick_theaters := [
		["CHN/TWN", "op_pacific_shield_2028"],
		["UKRAINE", "op_ukraine_donbas_2028"],
		["NATO/RUS", "op_baltic_shield_suwalki"],
		["INDIA/LAC", "op_himalayan_sentinel_lac"],
		["KOREA", "op_korean_thunder_dmz"],
		["US/MEX", "op_mexico_rio_grande_2028"],
		["HORMUZ", "op_red_strait_swarm"],
	]
	for qt in quick_theaters:
		var q_btn := Button.new()
		q_btn.text = String(qt[0])
		q_btn.add_theme_font_size_override("font_size", 9)
		q_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var q_slug := String(qt[1])
		q_btn.pressed.connect(func():
			if main_menu != null and main_menu.has_method("launch_scenario"):
				main_menu.launch_scenario(q_slug, 1.0, Vector2.ZERO)
		)
		th_grid.add_child(q_btn)

	switch_left_hud_tab(0)

	# 3. Bottom Diegetic Console & Interactive Spatial Map Targeting Deck (2 compact rows, strictly 1896px max width, zero overflow)
	var bot_bar := PanelContainer.new()
	_bottom_cmd_bar = bot_bar
	bot_bar.theme = theme
	bot_bar.clip_contents = true
	bot_bar.anchor_left = 0.0
	bot_bar.anchor_right = 1.0
	bot_bar.anchor_top = 1.0
	bot_bar.anchor_bottom = 1.0
	bot_bar.offset_left = 12.0
	bot_bar.offset_right = -12.0
	bot_bar.offset_top = -78.0
	bot_bar.offset_bottom = -6.0
	hud_layer.add_child(bot_bar)

	var bot_vb := VBoxContainer.new()
	bot_vb.add_theme_constant_override("separation", 3)
	bot_bar.add_child(bot_vb)

	# Row 1: Core Console Controls & Camera/Time
	var bot_hb := HBoxContainer.new()
	bot_hb.add_theme_constant_override("separation", 4)
	bot_vb.add_child(bot_hb)

	var btn_iads := Button.new()
	btn_iads.text = "IADS [ON/DARK]"
	btn_iads.add_theme_font_size_override("font_size", 10)
	btn_iads.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_iads.pressed.connect(func():
		if tactile_console != null:
			tactile_console.toggle_master_iads()
	)
	bot_hb.add_child(btn_iads)

	var btn_time := Button.new()
	btn_time.text = "TIME [1x]"
	btn_time.add_theme_font_size_override("font_size", 10)
	btn_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_status_btn = btn_time
	btn_time.pressed.connect(func():
		if tactile_console != null:
			var sc: float = tactile_console.cycle_time_compression()
			btn_time.text = "TIME [%.0fx]" % sc
	)
	bot_hb.add_child(btn_time)

	var btn_alpha := Button.new()
	btn_alpha.text = "ALPHA STRIKE [SPACE]"
	btn_alpha.add_theme_font_size_override("font_size", 10)
	btn_alpha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_alpha.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	btn_alpha.pressed.connect(func():
		if tactile_console != null:
			tactile_console.press_execute_alpha_strike()
	)
	bot_hb.add_child(btn_alpha)

	var btn_dogs := Button.new()
	btn_dogs.text = "DEPLOY DOGS [U]"
	btn_dogs.add_theme_font_size_override("font_size", 10)
	btn_dogs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_dogs.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_dogs.pressed.connect(func():
		if tactile_console != null:
			tactile_console.press_deploy_unmanned(selected_unit_id)
	)
	bot_hb.add_child(btn_dogs)

	var btn_cam := Button.new()
	btn_cam.text = "TACVIEW CAM [C]"
	btn_cam.add_theme_font_size_override("font_size", 10)
	btn_cam.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cam.pressed.connect(func():
		toggle_tacview_follow_cam()
		btn_cam.text = "TACVIEW: ON [C]" if follow_selected_unit_cam else "TACVIEW CAM [C]"
	)
	bot_hb.add_child(btn_cam)

	var btn_photos := Button.new()
	btn_photos.text = "WIKI PHOTOS [TAB]"
	btn_photos.add_theme_font_size_override("font_size", 10)
	btn_photos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_photos.pressed.connect(func():
		if tactile_console != null:
			tactile_console.toggle_recon_photo_mode()
	)
	bot_hb.add_child(btn_photos)

	var btn_echelon := Button.new()
	btn_echelon.text = "SQUAD DETAIL [F]"
	btn_echelon.add_theme_font_size_override("font_size", 10)
	btn_echelon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_echelon.pressed.connect(func():
		if tactile_console != null:
			tactile_console.toggle_semantic_echelon_override()
	)
	bot_hb.add_child(btn_echelon)

	var btn_fpv := Button.new()
	btn_fpv.text = "FPV POD [Z]"
	btn_fpv.add_theme_font_size_override("font_size", 10)
	btn_fpv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_fpv.add_theme_color_override("font_color", TacticalTheme.COL_CONTOUR_EMERALD)
	btn_fpv.pressed.connect(func():
		if fpv_pod_ref != null and fpv_pod_ref.has_method("toggle_pod_active"):
			fpv_pod_ref.call("toggle_pod_active")
	)
	bot_hb.add_child(btn_fpv)

	var btn_subsim := Button.new()
	btn_subsim.text = "⚓ 688 SUB [;]"
	btn_subsim.add_theme_font_size_override("font_size", 10)
	btn_subsim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_subsim.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
	btn_subsim.pressed.connect(func():
		if submarine_conn_ref != null and submarine_conn_ref.has_method("toggle_sub_sim_active"):
			submarine_conn_ref.call("toggle_sub_sim_active")
	)
	bot_hb.add_child(btn_subsim)

	var btn_wx := Button.new()
	btn_wx.text = "WX [F6]"
	btn_wx.add_theme_font_size_override("font_size", 10)
	btn_wx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_wx.pressed.connect(func():
		if sim_server != null and sim_server.has_method("cycle_weather_condition"):
			var nw: String = sim_server.call("cycle_weather_condition")
			btn_wx.text = "WX:%s" % nw.substr(0, 5)
	)
	bot_hb.add_child(btn_wx)

	var btn_hotline := Button.new()
	btn_hotline.text = "RED PHONE [Y]"
	btn_hotline.add_theme_font_size_override("font_size", 10)
	btn_hotline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hotline.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	btn_hotline.pressed.connect(func():
		if tactile_console != null and tactile_console.has_method("press_red_phone_hotline"):
			tactile_console.call("press_red_phone_hotline")
	)
	bot_hb.add_child(btn_hotline)

	var btn_save := Button.new()
	btn_save.text = "SAVE [F5]"
	btn_save.add_theme_font_size_override("font_size", 10)
	btn_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_save.pressed.connect(func():
		if sim_server != null and sim_server.has_method("save_campaign_state"):
			sim_server.call("save_campaign_state", "slot_1")
	)
	bot_hb.add_child(btn_save)

	var btn_load := Button.new()
	btn_load.text = "LOAD [F9]"
	btn_load.add_theme_font_size_override("font_size", 10)
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.pressed.connect(func():
		if sim_server != null and sim_server.has_method("load_campaign_state"):
			sim_server.call("load_campaign_state", "slot_1")
	)
	bot_hb.add_child(btn_load)

	# Row 2: Interactive Spatial Map Targeting Tools (Click tool -> Aim 3D reticle on War Table -> LMB to execute!)
	var spatial_hb := HBoxContainer.new()
	spatial_hb.add_theme_constant_override("separation", 4)
	bot_vb.add_child(spatial_hb)

	_spatial_tool_status_label = Label.new()
	_spatial_tool_status_label.text = "🎯 MAP TARGETING:"
	_spatial_tool_status_label.add_theme_font_size_override("font_size", 10)
	_spatial_tool_status_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	spatial_hb.add_child(_spatial_tool_status_label)

	var spatial_buttons := [
		["🎯 PARA DROP [X]", "AIRBORNE_PARATROOP_DROP", TacticalTheme.COL_FLIR_GREEN],
		["🎯 SMART MINES", "DEPLOY_SMART_MINEFIELD", TacticalTheme.COL_UNMANNED_GOLD],
		["🎯 GBU-57 MOP [F8]", "BUNKER_BUSTER_MOP", Color(1.0, 0.55, 0.90)],
		["🎯 CYBER CEMA [F10]", "CEMA_DRONE_HIJACK", TacticalTheme.COL_DIRECTED_ENERGY],
		["🎯 CBRN PLUME [0]", "STRIKE_TACTICAL_CBRN", Color(0.65, 1.0, 0.25)],
		["🎯 HEMP EMP", "STRIKE_HEMP_EMP", TacticalTheme.COL_NATO_BLUE],
		["🎯 ORBITAL RODS", "STRIKE_ORBITAL_RODS", TacticalTheme.COL_UNMANNED_GOLD],
		["🎯 THERMONUCLEAR [N]", "STRIKE_THERMONUCLEAR", TacticalTheme.COL_OPFOR_RED],
	]
	for sb_def in spatial_buttons:
		var sbtn := Button.new()
		sbtn.text = String(sb_def[0])
		sbtn.add_theme_font_size_override("font_size", 10)
		sbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sbtn.add_theme_color_override("font_color", sb_def[2])
		var tool_code := String(sb_def[1])
		sbtn.pressed.connect(func(): arm_spatial_targeting_tool(tool_code))
		spatial_hb.add_child(sbtn)

	var btn_evac := Button.new()
	btn_evac.text = "EVAC/VBSS [F7]"
	btn_evac.add_theme_font_size_override("font_size", 10)
	btn_evac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_evac.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_evac.pressed.connect(func():
		if sim_server != null:
			sim_server.call("declare_humanitarian_corridor")
			sim_server.call("execute_maritime_interdiction")
	)
	spatial_hb.add_child(btn_evac)

	var btn_subsea := Button.new()
	btn_subsea.text = "SUBSEA/ROE"
	btn_subsea.add_theme_font_size_override("font_size", 10)
	btn_subsea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_subsea.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	btn_subsea.pressed.connect(func():
		if sim_server != null:
			sim_server.call("execute_undersea_operation", "UNDERSEA_SABOTAGE_ENEMY_CABLE")
			sim_server.call("execute_homefront_action", "HOMEFRONT_ENFORCE_SURGICAL_ROE")
	)
	spatial_hb.add_child(btn_subsea)

	# 4. 2D Marquee Box-Drag Selection Overlay Panel
	_selection_box_panel = Panel.new()
	_selection_box_panel.name = "MarqueeSelectionBox"
	_selection_box_panel.visible = false
	_selection_box_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_box_panel.add_theme_stylebox_override("panel", TacticalTheme.create_panel_style(TacticalTheme.COL_NATO_BLUE, Color(0.0, 0.85, 1.0, 0.18), 2))
	hud_layer.add_child(_selection_box_panel)


func switch_left_hud_tab(tab_idx: int) -> void:
	active_left_hud_tab = clampi(tab_idx, 0, 2)
	if _tab_sitrep_vb != null:
		_tab_sitrep_vb.visible = (active_left_hud_tab == 0)
	if _tab_orbat_vb != null:
		_tab_orbat_vb.visible = (active_left_hud_tab == 1)
	if _tab_strategic_vb != null:
		_tab_strategic_vb.visible = (active_left_hud_tab == 2)
	for i in range(_left_tab_btns.size()):
		var b := _left_tab_btns[i]
		if b != null:
			b.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN if i == active_left_hud_tab else TacticalTheme.COL_TEXT_PRIMARY)


func set_modal_suppressed(suppressed: bool) -> void:
	is_modal_suppressed = suppressed
	if _left_hud_card != null:
		_left_hud_card.visible = (hud_layout_mode == 0) and not is_modal_suppressed
	if _bottom_cmd_bar != null:
		_bottom_cmd_bar.visible = (hud_layout_mode != 2) and not is_modal_suppressed


func arm_spatial_targeting_tool(tool_code: String, initial_preview_km: Vector3 = Vector3(0.0, 0.0, 0.0)) -> void:
	if not SPATIAL_TOOL_SPECS.has(tool_code):
		return
	active_spatial_tool = tool_code
	var spec: Dictionary = SPATIAL_TOOL_SPECS[tool_code]
	if _spatial_tool_status_label != null:
		_spatial_tool_status_label.text = "🎯 ARMED: %s (LMB Map)" % String(spec["label"]).substr(0, 22)
		_spatial_tool_status_label.add_theme_color_override("font_color", spec["color"])
	preview_spatial_tool_at_km(tool_code, initial_preview_km)


func preview_spatial_tool_at_km(tool_code: String, target_km: Vector3) -> void:
	if war_table == null or war_table.strike_preview == null or not SPATIAL_TOOL_SPECS.has(tool_code):
		return
	var spec: Dictionary = SPATIAL_TOOL_SPECS[tool_code]
	var origin_km := Vector3.INF
	if sim_server != null and sim_server.world_state != null:
		origin_km = sim_server.world_state.bunker_pos_km
	war_table.strike_preview.show_spatial_target_reticle(
		target_km,
		float(spec["radius_km"]),
		String(spec["label"]),
		spec["color"],
		origin_km
	)


func cancel_spatial_targeting_tool() -> void:
	active_spatial_tool = ""
	if _spatial_tool_status_label != null:
		_spatial_tool_status_label.text = "🎯 MAP TARGETING:"
		_spatial_tool_status_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	if war_table != null and war_table.strike_preview != null:
		war_table.strike_preview.clear_preview()


func execute_spatial_tool_at_km(target_km: Vector3) -> Dictionary:
	if active_spatial_tool.is_empty() or sim_server == null:
		return {}
	var code := active_spatial_tool
	preview_spatial_tool_at_km(code, target_km)
	var res: Dictionary = {}
	match code:
		"AIRBORNE_PARATROOP_DROP", "DEPLOY_SMART_MINEFIELD":
			res = sim_server.execute_engineering_or_airborne_op(code, target_km)
		"BUNKER_BUSTER_MOP":
			res = sim_server.execute_tunnel_operation("BUNKER_BUSTER_MOP", -1)
		"CEMA_DRONE_HIJACK":
			res = sim_server.execute_cema_operation("CEMA_DRONE_HIJACK")
		"STRIKE_TACTICAL_CBRN", "STRIKE_HEMP_EMP", "STRIKE_ORBITAL_RODS", "STRIKE_THERMONUCLEAR":
			res = sim_server.execute_escalated_strike(code, target_km, WorldState.FACTION_BLUE)
	active_spatial_tool = ""
	if _spatial_tool_status_label != null:
		_spatial_tool_status_label.text = "🎯 EXECUTED @ (%.0f, %.0fkm)" % [target_km.x, target_km.z]
		_spatial_tool_status_label.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	return res


func toggle_tacview_follow_cam() -> void:
	follow_selected_unit_cam = not follow_selected_unit_cam
	if follow_selected_unit_cam:
		_orbit_pitch_deg = -22.0
		_camera_dist_m = 0.52
		if war_table != null and war_table.target_zoom_scale < 4.5:
			war_table.set_zoom_and_pan(5.5, war_table.target_pan_offset_km)
	else:
		_orbit_pitch_deg = -33.0
		_camera_dist_m = 1.84
		_camera_look_target = Vector3(0.0, 0.88, 0.06)
	_update_camera_transform()


func _on_frago_received(headline: String, body: String) -> void:
	if _frago_banner_label != null:
		_frago_banner_label.text = "[%s]\n%s" % [headline, body]


func _unhandled_input(event: InputEvent) -> void:
	if war_table == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if main_menu != null:
					main_menu.set_menu_visible(not main_menu.is_menu_open)
			KEY_SPACE:
				if tactile_console != null:
					tactile_console.press_execute_alpha_strike()
			KEY_U:
				if tactile_console != null:
					tactile_console.press_deploy_unmanned(selected_unit_id)
			KEY_C:
				toggle_tacview_follow_cam()
			KEY_TAB:
				if tactile_console != null:
					tactile_console.toggle_recon_photo_mode()
			KEY_F:
				if tactile_console != null:
					tactile_console.toggle_semantic_echelon_override()
			KEY_E:
				war_table.set_zoom_and_pan(war_table.target_zoom_scale * 1.35, war_table.target_pan_offset_km)
			KEY_Q:
				war_table.set_zoom_and_pan(war_table.target_zoom_scale / 1.35, war_table.target_pan_offset_km)
			KEY_1:
				if event.ctrl_pressed:
					save_control_group(1)
				elif event.alt_pressed:
					recall_control_group(1)
				elif command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "ORDER_ASSAULT_SEIZE")
			KEY_2:
				if event.ctrl_pressed:
					save_control_group(2)
				elif event.alt_pressed:
					recall_control_group(2)
				elif command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "ORDER_SEAD_SUPPRESS")
			KEY_3:
				if event.ctrl_pressed:
					save_control_group(3)
				elif event.alt_pressed:
					recall_control_group(3)
				elif command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "ORDER_CAP_OVERWATCH")
			KEY_4:
				if command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "ORDER_PRECISION_FIRE_TOT")
			KEY_5:
				if command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "CYCLE_ALTITUDE")
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "TOGGLE_AFTERBURNER")
			KEY_6:
				if command_bus != null and not _get_active_selection_list().is_empty():
					command_bus.enqueue_unit_ability(_get_active_selection_list(), "DEPLOY_SUBUNIT")
			KEY_B:
				select_battalion_of_current()
			KEY_V:
				select_brigade_of_current()
			KEY_T:
				if tactile_console != null:
					var sc: float = tactile_console.cycle_time_compression()
					if _time_status_btn != null:
						_time_status_btn.text = "TIME [%.0fx]" % sc
			KEY_COMMA, KEY_MINUS:
				set_sim_time_scale(1.0)
			KEY_PERIOD, KEY_EQUAL:
				set_sim_time_scale(60.0)
			KEY_7:
				if sim_server != null and sim_server.has_method("execute_mdd_action"):
					sim_server.execute_mdd_action("ORDER_ASAT_STRIKE", selected_unit_id)
			KEY_8:
				if sim_server != null and sim_server.has_method("execute_mdd_action"):
					sim_server.execute_mdd_action("ORDER_CYBER_CNO", selected_unit_id)
			KEY_9:
				if sim_server != null and sim_server.has_method("execute_mdd_action"):
					sim_server.execute_mdd_action("ORDER_PSYOP_EVAC", selected_unit_id)
			KEY_0:
				if sim_server != null and sim_server.has_method("execute_mdd_action"):
					sim_server.execute_mdd_action("ORDER_CBRN_MOPP", selected_unit_id)
			KEY_O:
				if war_table != null and war_table.has_method("cycle_macro_space_zoom"):
					war_table.cycle_macro_space_zoom()
			KEY_H:
				if tutorial_controller != null and tutorial_controller.has_method("toggle_bootcamp"):
					tutorial_controller.call("toggle_bootcamp")
			KEY_P:
				if story_director_ref != null and story_director_ref.has_method("toggle_story_campaign"):
					story_director_ref.call("toggle_story_campaign")
			KEY_L:
				if command_bus != null and selected_unit_id >= 0:
					command_bus.enqueue_unit_ability([selected_unit_id], "TOGGLE_AI_DELEGATION")
			KEY_F1:
				if subordinate_staff != null:
					subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFACC_AIR_SUPERIORITY)
			KEY_F2:
				if subordinate_staff != null:
					subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFLCC_GROUND_VANGUARD)
			KEY_F3:
				if subordinate_staff != null:
					subordinate_staff.execute_coa(SubordinateStaffAIScript.COA_JFC_JOINT_TOT_STRIKE)
			KEY_F4:
				if sim_server != null and sim_server.has_method("spawn_army_group_reinforcements"):
					sim_server.spawn_army_group_reinforcements(6500)
			KEY_K:
				if main_menu != null and main_menu.has_method("open_tech_tree_tab"):
					main_menu.call("open_tech_tree_tab")
			KEY_N:
				if sim_server != null and sim_server.has_method("execute_escalated_strike"):
					sim_server.execute_escalated_strike("STRIKE_THERMONUCLEAR", Vector3.ZERO, 1)
			KEY_R:
				if sim_server != null and sim_server.has_method("relocate_bunker"):
					sim_server.relocate_bunker()
			KEY_M:
				if radio_synth_ref != null and radio_synth_ref.has_method("toggle_audio_mute"):
					var muted: bool = radio_synth_ref.call("toggle_audio_mute")
					if _audio_mute_btn != null:
						_audio_mute_btn.text = "[AUDIO/VOICE: MUTED (M)]" if muted else "[AUDIO/VOICE: ON (M)]"
			KEY_G:
				if sim_server != null and sim_server.has_method("execute_diplomacy"):
					sim_server.call("execute_diplomacy", "DIPLO_MILITARY_ALLIANCE", "", WorldState.FACTION_BLUE)
			KEY_J:
				trigger_live_ai_tv_report()
			KEY_Z:
				if fpv_pod_ref != null and fpv_pod_ref.has_method("toggle_pod_active"):
					fpv_pod_ref.call("toggle_pod_active")
			KEY_Y:
				if tactile_console != null and tactile_console.has_method("press_red_phone_hotline"):
					tactile_console.call("press_red_phone_hotline")
			KEY_F5:
				if sim_server != null and sim_server.has_method("save_campaign_state"):
					sim_server.call("save_campaign_state", "slot_1")
			KEY_F6:
				if sim_server != null and sim_server.has_method("cycle_weather_condition"):
					sim_server.call("cycle_weather_condition")
			KEY_F7:
				if sim_server != null and sim_server.has_method("declare_humanitarian_corridor"):
					sim_server.call("declare_humanitarian_corridor")
					sim_server.call("execute_maritime_interdiction")
			KEY_F8:
				if sim_server != null and sim_server.has_method("execute_tunnel_operation"):
					sim_server.call("execute_tunnel_operation", "TUNNEL_GPR_SCAN", -1)
					sim_server.call("execute_tunnel_operation", "BUNKER_BUSTER_MOP", -1)
			KEY_F9:
				if sim_server != null and sim_server.has_method("load_campaign_state"):
					sim_server.call("load_campaign_state", "slot_1")
			KEY_F10:
				if sim_server != null and sim_server.has_method("execute_cema_operation"):
					sim_server.call("execute_cema_operation", "CEMA_DRONE_HIJACK")
			KEY_F11:
				if xr_rig_ref != null and xr_rig_ref.has_method("toggle_vr_simulator_mode"):
					xr_rig_ref.call("toggle_vr_simulator_mode")
			KEY_F12:
				cycle_graphic_style()
			KEY_I:
				select_and_focus_snipers_and_commandos()
			KEY_BACKSPACE:
				cycle_hud_layout_mode()
			KEY_X:
				if sim_server != null and sim_server.has_method("execute_engineering_or_airborne_op"):
					sim_server.call("execute_engineering_or_airborne_op", "AIRBORNE_PARATROOP_DROP")
			KEY_SEMICOLON:
				if submarine_conn_ref != null and submarine_conn_ref.has_method("toggle_sub_sim_active"):
					submarine_conn_ref.call("toggle_sub_sim_active")

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			war_table.set_zoom_and_pan(war_table.target_zoom_scale * 1.22, war_table.target_pan_offset_km)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			war_table.set_zoom_and_pan(war_table.target_zoom_scale / 1.22, war_table.target_pan_offset_km)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_lmb_pressed = true
				_lmb_press_pos = event.position
				_lmb_dragged = false
			else:
				_lmb_pressed = false
				if _selection_box_panel != null:
					_selection_box_panel.visible = false
				if _lmb_dragged:
					var rect := Rect2(_lmb_press_pos, event.position - _lmb_press_pos).abs()
					_perform_box_selection(rect, event.shift_pressed)
				else:
					_handle_table_mouse_click(event.position, false, event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_rmb_pressed = true
				_rmb_press_pos = event.position
				_rmb_dragged = false
			else:
				_rmb_pressed = false
				if not _rmb_dragged:
					_handle_table_mouse_click(event.position, true, event.shift_pressed)

	elif event is InputEventMouseMotion:
		if not active_spatial_tool.is_empty() and camera != null and war_table != null:
			var m_orig := camera.project_ray_origin(event.position)
			var m_dir := camera.project_ray_normal(event.position)
			var m_plane := Plane(Vector3.UP, war_table.global_position.y)
			var m_hit = m_plane.intersects_ray(m_orig, m_dir)
			if m_hit != null:
				var m_km: Vector3 = war_table.world_to_theater_km(m_hit)
				preview_spatial_tool_at_km(active_spatial_tool, m_km)
		if _lmb_pressed:
			if event.position.distance_to(_lmb_press_pos) > 8.0:
				_lmb_dragged = true
			if _lmb_dragged and _selection_box_panel != null:
				var r := Rect2(_lmb_press_pos, event.position - _lmb_press_pos).abs()
				_selection_box_panel.position = r.position
				_selection_box_panel.size = r.size
				_selection_box_panel.visible = true
		elif _rmb_pressed:
			if event.position.distance_to(_rmb_press_pos) > 6.0:
				_rmb_dragged = true
			if _rmb_dragged:
				_orbit_yaw_deg = wrapf(_orbit_yaw_deg - event.relative.x * 0.35, -180.0, 180.0)
				_orbit_pitch_deg = clampf(_orbit_pitch_deg - event.relative.y * 0.28, -82.0, -12.0)
				_update_camera_transform()


func _get_active_selection_list() -> Array[int]:
	if not selected_unit_ids.is_empty():
		return selected_unit_ids
	if selected_unit_id >= 0:
		return [selected_unit_id]
	return []


func set_sim_time_scale(new_scale: float) -> void:
	if tactile_console != null:
		tactile_console.set_time_compression(new_scale)
	elif command_bus != null:
		command_bus.enqueue_set_time_scale(new_scale)
	if _time_status_btn != null:
		_time_status_btn.text = "TIME [%.0fx]" % new_scale


func cycle_tv_news_channel() -> String:
	if sim_server == null or sim_server.sim_db_ref == null:
		return ""
	var clips: Array = sim_server.sim_db_ref.news_video_clips
	if clips.is_empty():
		sim_server.sim_db_ref.reload_news_videos_manifest()
		clips = sim_server.sim_db_ref.news_video_clips
	if clips.is_empty():
		return ""
	_tv_channel_index = (_tv_channel_index + 1) % clips.size()
	var slug := String(clips[_tv_channel_index].get("slug", "missile_alpha_strike"))
	sim_server.trigger_news_video_broadcast(slug, "Commander switched bunker satellite TV feed", false, false)
	return slug


func trigger_live_ai_tv_report() -> void:
	if sim_server == null or sim_server.world_state == null:
		return
	var cur_slug: String = String(sim_server.world_state.active_news_video_slug)
	sim_server.trigger_news_video_broadcast(cur_slug, "Live AI War Correspondent Report requested from Command Bunker", true, false)


func _perform_box_selection(screen_rect: Rect2, additive: bool = false) -> void:
	if camera == null or war_table == null or sim_server == null:
		return
	var st: WorldState = sim_server.world_state
	var newly_selected: Array[int] = selected_unit_ids.duplicate() if additive else []
	for uid in range(st.unit_count):
		if st.unit_active[uid] == 0 or st.unit_faction[uid] != WorldState.FACTION_BLUE or st.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var local_pos: Vector3 = war_table.theater_km_to_table_local(st.unit_pos[uid])
		if absf(local_pos.x) > 0.90 or absf(local_pos.z) > 0.90:
			continue
		var world_pos: Vector3 = war_table.to_global(local_pos + Vector3(0.0, 0.01, 0.0))
		if camera.is_position_behind(world_pos):
			continue
		var scr_pt: Vector2 = camera.unproject_position(world_pos)
		if screen_rect.has_point(scr_pt) and not newly_selected.has(uid):
			newly_selected.append(uid)
	if not newly_selected.is_empty():
		select_unit_group(newly_selected)


func select_battalion_of_current() -> void:
	if sim_server == null or selected_unit_id < 0:
		return
	var st: WorldState = sim_server.world_state
	var bn_id := EchelonClusterSystem.get_battalion_id_for_unit(st, selected_unit_id)
	if bn_id >= 0:
		var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, bn_id)
		select_unit_group(leaves if not leaves.is_empty() else [bn_id], bn_id)
	if story_director_ref != null and story_director_ref.has_method("notify_capability_event"):
		story_director_ref.call("notify_capability_event", "BRIGADE_OR_BATTALION_SELECTED")


func select_brigade_of_current() -> void:
	if sim_server == null or selected_unit_id < 0:
		return
	var st: WorldState = sim_server.world_state
	var bde_id := EchelonClusterSystem.get_brigade_id_for_unit(st, selected_unit_id)
	if bde_id >= 0:
		var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, bde_id)
		select_unit_group(leaves if not leaves.is_empty() else [bde_id], bde_id)
	if story_director_ref != null and story_director_ref.has_method("notify_capability_event"):
		story_director_ref.call("notify_capability_event", "BRIGADE_OR_BATTALION_SELECTED")


func select_domain_units(domain_code: String) -> void:
	if sim_server == null or sim_server.sim_db_ref == null:
		return
	var st: WorldState = sim_server.world_state
	var sdb: Node = sim_server.sim_db_ref
	var dom_target := 1 if domain_code == "AIR" else (2 if domain_code == "SEA" else 0)
	var list: Array[int] = []
	for uid in range(st.unit_count):
		if st.unit_active[uid] == 1 and st.unit_faction[uid] == WorldState.FACTION_BLUE and st.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var pid: int = st.unit_platform_id[uid]
			if pid > 0 and pid < sdb.plat_domain_id.size() and sdb.plat_domain_id[pid] == dom_target:
				list.append(uid)
				if list.size() >= 64:
					break
	if not list.is_empty():
		select_unit_group(list, list[0])


func cycle_graphic_style() -> String:
	if war_table == null or not war_table.has_method("cycle_graphic_style_mode"):
		return ""
	var sname: String = war_table.call("cycle_graphic_style_mode")
	if _style_mode_btn != null:
		_style_mode_btn.text = "[STYLE: %s (F12)]" % sname.substr(0, 18)
	return sname


func cycle_hud_layout_mode() -> String:
	hud_layout_mode = posmod(hud_layout_mode + 1, HUD_LAYOUT_NAMES.size())
	if _left_hud_card != null:
		_left_hud_card.visible = (hud_layout_mode == 0)
	if _bottom_cmd_bar != null:
		_bottom_cmd_bar.visible = (hud_layout_mode != 2)
	var mname: String = HUD_LAYOUT_NAMES[hud_layout_mode]
	if _hud_mode_btn != null:
		_hud_mode_btn.text = "[HUD: %s (BKSP)]" % mname.substr(0, 14)
	return mname


func select_and_focus_snipers_and_commandos() -> int:
	if sim_server == null or not sim_server.has_method("get_active_sniper_and_commando_units"):
		return -1
	var spec_uids: Array[int] = sim_server.call("get_active_sniper_and_commando_units", 0)
	if spec_uids.is_empty():
		return -1
	_sniper_cycle_idx = (_sniper_cycle_idx + 1) % spec_uids.size()
	var focus_uid: int = spec_uids[_sniper_cycle_idx]
	select_unit_group(spec_uids, focus_uid)
	if war_table != null and focus_uid >= 0 and focus_uid < sim_server.world_state.unit_count:
		var upos: Vector3 = sim_server.world_state.unit_pos[focus_uid]
		war_table.set_zoom_and_pan(6.8, Vector2(upos.x, upos.z), true)
	return focus_uid


func select_unit_group(uids: Array[int], primary_uid: int = -1) -> void:
	if sim_server == null or uids.is_empty():
		return
	selected_unit_ids = uids.duplicate()
	var lead := primary_uid if primary_uid >= 0 else uids[0]
	selected_unit_id = lead
	if war_table != null and war_table.visual_sync != null:
		war_table.visual_sync.selected_unit_ids = selected_unit_ids.duplicate()
		war_table.visual_sync.selected_unit_id = lead
	var pid: int = sim_server.world_state.unit_platform_id[lead]
	var fac: int = sim_server.world_state.unit_faction[lead]
	if fpv_pod_ref != null and fpv_pod_ref.has_method("attach_to_unit"):
		fpv_pod_ref.call("attach_to_unit", lead)
	if signal_bus != null:
		signal_bus.unit_selected.emit(lead, pid, fac)


func save_control_group(group_idx: int) -> void:
	control_groups[group_idx] = _get_active_selection_list().duplicate()


func recall_control_group(group_idx: int) -> int:
	var grp: Array = control_groups.get(group_idx, [])
	if grp.is_empty():
		return 0
	var typed_grp: Array[int] = []
	for u in grp:
		typed_grp.append(int(u))
	select_unit_group(typed_grp, typed_grp[0])
	return typed_grp.size()


func _handle_table_mouse_click(screen_pos: Vector2, is_right_click: bool, shift_held: bool = false) -> void:
	if camera == null or war_table == null or sim_server == null:
		return
	var ray_orig := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)

	if not is_right_click:
		# 1. Check physical 3D switches & buttons on TactileConsole
		if tactile_console != null and tactile_console.has_method("pick_control_by_ray"):
			var hit_ctrl: String = tactile_console.pick_control_by_ray(ray_orig, ray_dir)
			if not hit_ctrl.is_empty():
				tactile_console.actuate_control(hit_ctrl, selected_unit_id)
				return

		# 2. If in Planetary Globe view (`zoom_scale < 0.42`), check 7 Global Flashpoint Beacons
		if war_table.has_method("is_planetary_globe_visible") and war_table.is_planetary_globe_visible():
			var fp_slug: String = war_table.pick_flashpoint_on_globe_by_ray(ray_orig, ray_dir)
			if not fp_slug.is_empty():
				if main_menu != null and main_menu.has_method("launch_scenario"):
					main_menu.launch_scenario(fp_slug, 1.0, Vector2.ZERO)
				else:
					sim_server.load_scenario(fp_slug)
					war_table.bind_sim_server(sim_server)
					war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
				return

		# 3. Try true 3D ray picking (hits 3D jets in the air & miniatures on mountains!)
		var picked_3d: int = war_table.pick_unit_by_ray(ray_orig, ray_dir)
		if picked_3d >= 0:
			if shift_held and not selected_unit_ids.is_empty():
				if not selected_unit_ids.has(picked_3d):
					selected_unit_ids.append(picked_3d)
				select_unit_group(selected_unit_ids, picked_3d)
			else:
				select_unit(picked_3d)
			return

	var plane := Plane(Vector3.UP, war_table.global_position.y)
	var hit = plane.intersects_ray(ray_orig, ray_dir)
	if hit == null:
		return

	var hit_km: Vector3 = war_table.world_to_theater_km(hit)
	if not active_spatial_tool.is_empty():
		if is_right_click:
			cancel_spatial_targeting_tool()
		else:
			execute_spatial_tool_at_km(hit_km)
		return
	if not is_right_click:
		var picked_uid: int = war_table.pick_unit_at_theater_km(hit_km.x, hit_km.z, 25.0)
		if picked_uid >= 0:
			if shift_held and not selected_unit_ids.is_empty():
				if not selected_unit_ids.has(picked_uid):
					selected_unit_ids.append(picked_uid)
				select_unit_group(selected_unit_ids, picked_uid)
			else:
				select_unit(picked_uid)
	else:
		var sel_list := _get_active_selection_list()
		if not sel_list.is_empty() and selected_unit_id >= 0 and selected_unit_id < sim_server.world_state.unit_count:
			var target_uid: int = war_table.pick_unit_by_ray(ray_orig, ray_dir)
			if target_uid < 0:
				target_uid = war_table.pick_unit_at_theater_km(hit_km.x, hit_km.z, 25.0)
			if target_uid >= 0 and sim_server.world_state.unit_faction[target_uid] != sim_server.world_state.unit_faction[selected_unit_id]:
				command_bus.enqueue_strike(sel_list, target_uid, sim_server.world_state.unit_pos[target_uid], 1, 2)
				war_table.strike_preview.show_strike_preview(sim_server.world_state.unit_pos[selected_unit_id], sim_server.world_state.unit_pos[target_uid], 3.8, "ENGAGING TARGET (%d UNITS)" % sel_list.size())
			else:
				var sel_pos: Vector3 = sim_server.world_state.unit_pos[selected_unit_id]
				var wp := Vector3(hit_km.x, sel_pos.y if sel_pos.y > 200.0 else hit_km.y, hit_km.z)
				var wp_array: Array = [wp]
				if shift_held and sim_server.world_state.unit_has_waypoint[selected_unit_id] == 1:
					wp_array = [sim_server.world_state.unit_target_pos[selected_unit_id], wp]
				command_bus.enqueue_move_waypoints(sel_list, wp_array)
				war_table.strike_preview.show_strike_preview(sel_pos, wp, 1.5, "WAYPOINT ORDER (%d UNITS)" % sel_list.size())


func select_unit(uid: int) -> void:
	if sim_server == null or uid < 0 or uid >= sim_server.world_state.unit_count:
		return
	var st: WorldState = sim_server.world_state
	if st.unit_echelon[uid] > WorldState.ECHELON_COMPANY:
		var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, uid)
		selected_unit_ids = leaves if not leaves.is_empty() else [uid]
	else:
		selected_unit_ids = [uid]
	selected_unit_id = uid
	if war_table != null and war_table.visual_sync != null:
		war_table.visual_sync.selected_unit_ids = selected_unit_ids.duplicate()
		war_table.visual_sync.selected_unit_id = uid
	var pid: int = st.unit_platform_id[uid]
	var fac: int = st.unit_faction[uid]
	if signal_bus != null:
		signal_bus.unit_selected.emit(uid, pid, fac)


func _process(delta: float) -> void:
	if war_table != null:
		var pan_speed := (120.0 / maxf(1.0, war_table.zoom_scale)) * delta
		var pan_delta := Vector2.ZERO
		if Input.is_key_pressed(KEY_W):
			pan_delta.y -= pan_speed
		if Input.is_key_pressed(KEY_S):
			pan_delta.y += pan_speed
		if Input.is_key_pressed(KEY_A):
			pan_delta.x -= pan_speed
		if Input.is_key_pressed(KEY_D):
			pan_delta.x += pan_speed
		if pan_delta != Vector2.ZERO:
			follow_selected_unit_cam = false
			war_table.set_zoom_and_pan(war_table.target_zoom_scale, war_table.target_pan_offset_km + pan_delta)

		# Tacview 3D Follow Camera tracks the selected unit in 3D space!
		if follow_selected_unit_cam and sim_server != null and selected_unit_id >= 0 and selected_unit_id < sim_server.world_state.unit_count:
			if sim_server.world_state.unit_active[selected_unit_id] == 1:
				var upos_km: Vector3 = sim_server.world_state.unit_pos[selected_unit_id]
				war_table.set_zoom_and_pan(war_table.target_zoom_scale, Vector2(upos_km.x, upos_km.z))
				var local_u: Vector3 = war_table.theater_km_to_table_local(upos_km)
				var world_u: Vector3 = war_table.to_global(local_u + Vector3(0.0, 0.02, 0.0))
				_camera_look_target = _camera_look_target.lerp(world_u, clampf(delta * 8.0, 0.0, 1.0))
				_update_camera_transform()

		var ech: int = war_table.get_active_semantic_echelon()
		var ech_str := "INDIVIDUAL SOLDIERS / DOGS / 4-SHIP WINGS" if ech == 0 else ("BATTALION / SQUADRON + 3D MINIATURES" if ech == 1 else "THEATER + 3D TACVIEW MINIATURES")
		if war_table.has_method("get_active_zoom_tier_name"):
			ech_str = String(war_table.get_active_zoom_tier_name())
		if _zoom_echelon_label != null:
			_zoom_echelon_label.text = "ZOOM: %.2fx [%s]" % [war_table.zoom_scale, ech_str]

	if subordinate_staff != null and _staff_sitrep_label != null:
		_staff_sitrep_label.text = subordinate_staff.last_sitrep_text

	if sim_server != null and _top_ledger_label != null:
		var st: WorldState = sim_server.world_state
		var g_tot_k := float(st.global_total_units_active) / 1000.0
		var g_blue_k := float(st.global_blue_units_active) / 1000.0
		var g_red_k := float(st.global_red_units_active) / 1000.0
		var hrs := int(st.sim_time_sec) / 3600
		var mins := (int(st.sim_time_sec) % 3600) / 60
		var secs := int(st.sim_time_sec) % 60
		var clk_str := "T+%02d:%02d:%02d [%.0fx]" % [hrs, mins, secs, st.time_scale]
		_top_ledger_label.text = "DEFCON %d | BUDGET: $%.0fM (+$%.0fM/m) | %s | 1M ORBAT: %.0fk (B:%.0fk/R:%.0fk) | KIA B:%d R:%d | AMMO B:%d R:%d" % [
			st.defcon_level, st.blue_budget_musd, st.blue_income_musd_per_min,
			clk_str, g_tot_k, g_blue_k, g_red_k,
			st.blue_personnel_kia, st.red_personnel_kia,
			st.blue_ammo_remaining, st.red_ammo_remaining
		]
		if _budget_defcon_label != null:
			var b_hp_pct := clampf((st.bunker_hp / maxf(1.0, st.bunker_max_hp)) * 100.0, 0.0, 100.0)
			_budget_defcon_label.text = "■ DEFCON %d (ESC:%.0f%%) | BUDGET:$%.0fM (+$%.0fM/m) | ALLIES B:%d R:%d (AIR B:%d/R:%d) [G:Diplomacy]\n★ HQ BUNKER: %s (%.0f,%.0fkm) | HP:%.0f%% | CAP:%.0f%% | %s [R:Relocate]" % [
				st.defcon_level, st.global_escalation_score,
				st.blue_budget_musd, st.blue_income_musd_per_min + st.blue_allied_income_musd_per_min,
				st.blue_allied_nations_count, st.red_allied_nations_count,
				st.blue_airspace_treaties_count, st.red_airspace_treaties_count,
				st.bunker_base_name.substr(0, 28), st.bunker_pos_km.x, st.bunker_pos_km.z, b_hp_pct, st.bunker_capture_progress, st.bunker_status_code
			]
			if st.defcon_level <= 2 or st.bunker_status_code in ["BREACH_IN_PROGRESS", "UNDER_ATTACK", "LOST"]:
				_budget_defcon_label.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
			else:
				_budget_defcon_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
		if _world_news_label != null:
			_world_news_label.text = "[%s] \"%s\"\n%s" % [
				st.latest_officer_callsign.substr(0, 42), st.latest_officer_transcript.substr(0, 90),
				st.latest_world_news_headline.substr(0, 128)
			]
		if _tv_news_video_rect != null and sim_server.sim_db_ref != null and sim_server.sim_db_ref.has_method("get_news_video_frame_textures"):
			_tv_news_anim_time += delta
			var frames: Array = sim_server.sim_db_ref.get_news_video_frame_textures(st.active_news_video_slug)
			if not frames.is_empty():
				var f_idx := int(_tv_news_anim_time * 6.0) % frames.size()
				_tv_news_video_rect.texture = frames[f_idx]
			if _tv_news_header_label != null:
				_tv_news_header_label.text = "● LIVE // %s [DEFCON %d]" % [st.active_news_video_network.substr(0, 26), st.defcon_level]
			if _tv_news_chyron_label != null:
				_tv_news_chyron_label.text = "%s\n%s" % [
					st.active_news_video_headline.substr(0, 62),
					st.active_news_video_sub_chyron.substr(0, 68)
				]
		if _live_casualty_ammo_label != null:
			var b_ammo_pct := int(round((float(st.blue_ammo_remaining) / float(maxi(1, st.blue_ammo_initial_total))) * 100.0))
			var r_ammo_pct := int(round((float(st.red_ammo_remaining) / float(maxi(1, st.red_ammo_initial_total))) * 100.0))
			_live_casualty_ammo_label.text = (
				"BLUE CASUALTIES: KIA %d | WIA %d | Lost: %d Air, %d Land, %d Sea, %d Drone ($%.1fM)\n" % [
					st.blue_personnel_kia, st.blue_personnel_wia, st.blue_aircraft_lost, st.blue_armor_lost, st.blue_ships_lost, st.blue_unmanned_lost, st.blue_lost_musd
				] +
				"RED CASUALTIES:  KIA %d | WIA %d | Lost: %d Air, %d Land, %d Sea, %d Drone ($%.1fM)\n" % [
					st.red_personnel_kia, st.red_personnel_wia, st.red_aircraft_lost, st.red_armor_lost, st.red_ships_lost, st.red_unmanned_lost, st.red_lost_musd
				] +
				"BLUE AMMO: %d (%d%%) | Fired: %d | In-Air: %d | Int: %d  ||  RED AMMO: %d (%d%%) | Fired: %d | In-Air: %d | Int: %d" % [
					st.blue_ammo_remaining, b_ammo_pct, st.blue_munitions_expended, st.blue_munitions_in_flight, st.blue_munitions_intercepted,
					st.red_ammo_remaining, r_ammo_pct, st.red_munitions_expended, st.red_munitions_in_flight, st.red_munitions_intercepted
				]
			)
		if _selection_org_label != null and selected_unit_id >= 0 and selected_unit_id < st.unit_count:
			var org_s := EchelonClusterSystem.get_hierarchy_status_string(st, selected_unit_id)
			_selection_org_label.text = "%s | SELECTED: %d UNITS (LMB-Drag / [B] Bn / [V] Bde)" % [org_s, maxi(1, selected_unit_ids.size())]

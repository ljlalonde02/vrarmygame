class_name BunkerMainMenu
extends CanvasLayer
## Diegetic Command Bunker Main Menu:
## - Tab 1: Dynamic Global Campaign Mode (6 Operations across 5 Global 2028 Flashpoint Theaters)
## - Tab 2: 6 Global Flashpoint Scenarios, OPFOR AI Doctrine Selector & Custom Sandbox Spawner
## - Tab 3: Wikipedia Real-Photo Armory & Encyclopedia Browser (49 Platforms + 27 Munitions = 76 Real Photos)
## - Tab 4: Victory/Defeat After-Action Report (AAR) & Tacview Timeline Scrubber Slider
## - Tab 5: Interactive Boot-Camp Tutorial & Commander's Field Manual (`wargame.db` + `docs/GAME_MANUAL.md`)

var sim_db: Node = null
var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null
var war_table: Node3D = null
var recon_dossier: Node = null
var opfor_commander: Node = null
var tutorial_controller: Node = null
var story_director: Node = null
var fpv_pod_controller: Node = null

var campaign_stage_index: int = 0
var campaign_cumulative_blue_lost_musd: float = 0.0
var campaign_cumulative_red_lost_musd: float = 0.0
var is_menu_open: bool = false
var current_tutorial_step_index: int = 0

var _modal_root: PanelContainer = null
var _tab_container: TabContainer = null
var _campaign_status_label: RichTextLabel = null
var _encyclopedia_photo_rect: TextureRect = null
var _encyclopedia_title_label: Label = null
var _encyclopedia_specs_label: Label = null
var _encyclopedia_summary_label: RichTextLabel = null
var _aar_summary_label: RichTextLabel = null
var _replay_slider: HSlider = null
var _replay_status_label: Label = null
var _manual_rich_label: RichTextLabel = null
var _budget_header_label: RichTextLabel = null
var _tech_tree_list_vb: VBoxContainer = null
var _news_feed_rich_label: RichTextLabel = null
var _studio_video_rect: TextureRect = null
var _studio_info_rich_label: RichTextLabel = null
var _studio_channels_vb: VBoxContainer = null
var _studio_anim_time: float = 0.0
var _red_phone_rich_label: RichTextLabel = null
var _defcon_status_label: Label = null

const UnitTacticalTrialsSystemScript := preload("res://src/sim_core/systems/unit_tactical_trials_system.gd")

var _trials_list_vb: VBoxContainer = null
var _trials_title_label: RichTextLabel = null
var _trials_threat_label: RichTextLabel = null
var _trials_move_label: RichTextLabel = null
var _trials_fight_label: RichTextLabel = null
var _trials_defend_label: RichTextLabel = null
var _trials_trick_label: RichTextLabel = null
var _trials_swarm_label: RichTextLabel = null
var _trials_all_label: RichTextLabel = null
var _trials_launch_btn: Button = null
var _selected_trial_slug: String = "f_35a_lightning"
var _trials_filter_domain: String = "ALL"


func _ready() -> void:
	if _modal_root != null:
		return
	layer = 10
	_build_menu_ui()
	set_menu_visible(false)


func setup(p_sim_db: Node, p_sim_server: Node, p_cmd_bus: Node, p_sig_bus: Node, p_war_table: Node3D = null, p_dossier: Node = null, p_opfor: Node = null, p_tutorial: Node = null) -> void:
	sim_db = p_sim_db
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	war_table = p_war_table
	recon_dossier = p_dossier
	opfor_commander = p_opfor
	tutorial_controller = p_tutorial
	if signal_bus != null and not signal_bus.battle_concluded.is_connected(_on_battle_concluded):
		signal_bus.battle_concluded.connect(_on_battle_concluded)
	_populate_encyclopedia_entries()
	_populate_trials_entries()
	_refresh_campaign_view()
	_refresh_manual_and_tutorial_view()
	_refresh_tech_tree_and_budget_view()
	_refresh_trials_view()


func open_tech_tree_tab() -> void:
	set_menu_visible(true)
	if _tab_container != null and _tab_container.get_tab_count() >= 6:
		_tab_container.current_tab = 5
	_refresh_tech_tree_and_budget_view()


func open_news_video_studio_tab() -> void:
	set_menu_visible(true)
	if _tab_container != null and _tab_container.get_tab_count() >= 7:
		_tab_container.current_tab = 6
	_refresh_news_video_studio_view()


func open_red_phone_tab() -> void:
	set_menu_visible(true)
	if _tab_container != null and _tab_container.get_tab_count() >= 8:
		_tab_container.current_tab = 7
	_refresh_red_phone_and_save_view()


func open_tactical_trials_tab(select_slug: String = "") -> void:
	set_menu_visible(true)
	if _tab_container != null and _tab_container.get_tab_count() >= 9:
		_tab_container.current_tab = 8
	if not select_slug.is_empty():
		_select_trial(select_slug)
	else:
		_refresh_trials_view()


func set_menu_visible(vis: bool) -> void:
	is_menu_open = vis
	if _modal_root != null:
		_modal_root.visible = vis
	# Coordinate modal suppression with background floating HUD layers so zero panels overlap BunkerMainMenuModal
	var p := get_parent()
	if p != null:
		var fpv: Variant = p.get("fpv_pod_controller")
		if fpv != null and fpv.has_method("set_modal_suppressed"):
			fpv.set_modal_suppressed(vis)
		var tc: Variant = p.get("tutorial_controller")
		if tc != null:
			tc.visible = bool(tc.get("is_active")) and not vis
		var sd: Variant = p.get("story_director")
		if sd != null:
			sd.visible = bool(sd.get("is_active")) and not vis
		var rig: Variant = p.get("desktop_rig")
		if rig != null and rig.has_method("set_modal_suppressed"):
			rig.set_modal_suppressed(vis)
		var rd: Variant = p.get("recon_dossier")
		if rd != null and rd.get("root_panel") != null:
			rd.root_panel.visible = not vis
		var wc: Variant = p.get("welcome_controller")
		if wc != null and wc.has_method("set_visible_briefing") and vis:
			wc.call("set_visible_briefing", false)
	if vis:
		update_defcon_badge()
		_refresh_campaign_view()
		_refresh_aar_view(true, "THEATER COMMANDER INSPECTION")
		_refresh_manual_and_tutorial_view()
		_refresh_tech_tree_and_budget_view()
		_refresh_news_video_studio_view()
		_refresh_red_phone_and_save_view()
		_refresh_trials_view()


func update_defcon_badge() -> void:
	if _defcon_status_label == null or sim_server == null:
		return
	var st: WorldState = sim_server.world_state
	var dc: int = st.defcon_level
	var codename := "FADE OUT"
	var col: Color = TacticalTheme.COL_NATO_BLUE
	match dc:
		1:
			codename = "COCKED PISTOL"
			col = Color(1.0, 0.2, 0.2)
		2:
			codename = "FAST PACE"
			col = Color(1.0, 0.45, 0.1)
		3:
			codename = "ROUND HOUSE"
			col = Color(1.0, 0.8, 0.1)
		4:
			codename = "DOUBLE TAKE"
			col = Color(0.2, 0.9, 0.5)
		5:
			codename = "FADE OUT"
			col = Color(0.2, 0.6, 1.0)

	var pal_str := "AUTHORIZED" if (sim_server.has_method("verify_pal_code") and sim_server.defcon_escalation_system != null and sim_server.defcon_escalation_system.pal_authorized) else "STANDBY"
	_defcon_status_label.text = "■ DEFCON %d: %s // TENSION: %.1f%% // PAL AUTH: %s // ESCALATION WATCH" % [
		dc, codename, st.global_escalation_score, pal_str
	]
	_defcon_status_label.add_theme_color_override("font_color", col)


func _build_menu_ui() -> void:
	var theme := TacticalTheme.create_theme()

	_modal_root = PanelContainer.new()
	_modal_root.name = "BunkerMainMenuModal"
	_modal_root.theme = theme
	_modal_root.anchor_left = 0.5
	_modal_root.anchor_right = 0.5
	_modal_root.anchor_top = 0.5
	_modal_root.anchor_bottom = 0.5
	_modal_root.offset_left = -540.0
	_modal_root.offset_right = 540.0
	_modal_root.offset_top = -350.0
	_modal_root.offset_bottom = 350.0
	add_child(_modal_root)

	var main_vb := VBoxContainer.new()
	main_vb.add_theme_constant_override("separation", 10)
	_modal_root.add_child(main_vb)

	# Title Banner + Close Button
	var top_hb := HBoxContainer.new()
	main_vb.add_child(top_hb)

	var banner := Label.new()
	banner.text = "CLASSIFIED COMMAND BUNKER // 2028 GLOBAL THEATER WARGAME SIMULATOR (VR & PC)"
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	top_hb.add_child(banner)

	var resume_btn := Button.new()
	resume_btn.text = "[RESUME WAR TABLE (ESC)]"
	resume_btn.pressed.connect(func(): set_menu_visible(false))
	top_hb.add_child(resume_btn)

	# 5-Style Graphic Shader Selector Bar (Phase 29 Visual & UX Polish)
	var style_hb := HBoxContainer.new()
	style_hb.add_theme_constant_override("separation", 6)
	main_vb.add_child(style_hb)

	var style_lbl := Label.new()
	style_lbl.text = "WAR TABLE GRAPHIC STYLE [F12]:"
	style_lbl.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	style_hb.add_child(style_lbl)

	var style_defs := [
		[0, "1: HOLO C4ISR OBSIDIAN", TacticalTheme.COL_NATO_BLUE],
		[1, "2: SATELLITE TRUE-EARTH", Color(0.35, 0.92, 0.55)],
		[2, "3: NIGHT-VISION FLIR GREEN", TacticalTheme.COL_FLIR_GREEN],
		[3, "4: RETRO NORAD WOPR AMBER", TacticalTheme.COL_UNMANNED_GOLD],
		[4, "5: NATO TOPOGRAPHIC MAP", Color(0.95, 0.90, 0.72)],
	]
	for sd in style_defs:
		var s_idx: int = int(sd[0])
		var s_btn := Button.new()
		s_btn.text = String(sd[1])
		s_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s_btn.add_theme_color_override("font_color", sd[2])
		s_btn.pressed.connect(func():
			if war_table != null and war_table.has_method("set_graphic_style_mode"):
				war_table.call("set_graphic_style_mode", s_idx)
		)
		style_hb.add_child(s_btn)

	# FEAT-09: Dynamic DEFCON Status Banner
	_defcon_status_label = Label.new()
	_defcon_status_label.text = "■ DEFCON 5: FADE OUT // TENSION: 10% // DUAL-KEY PAL ARMED"
	_defcon_status_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	main_vb.add_child(_defcon_status_label)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(_tab_container)

	# TAB 1: DYNAMIC CAMPAIGN MODE
	var camp_tab := VBoxContainer.new()
	camp_tab.name = "1. DYNAMIC CAMPAIGN"
	camp_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(camp_tab)

	_campaign_status_label = RichTextLabel.new()
	_campaign_status_label.bbcode_enabled = true
	_campaign_status_label.custom_minimum_size = Vector2(960.0, 220.0)
	_campaign_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	camp_tab.add_child(_campaign_status_label)

	var camp_btns_hb := HBoxContainer.new()
	camp_btns_hb.add_theme_constant_override("separation", 12)
	camp_tab.add_child(camp_btns_hb)

	var start_camp_btn := Button.new()
	start_camp_btn.text = "LAUNCH / RESTART GLOBAL CAMPAIGN"
	start_camp_btn.pressed.connect(func(): start_campaign_operation(0))
	camp_btns_hb.add_child(start_camp_btn)

	var next_camp_btn := Button.new()
	next_camp_btn.text = "ADVANCE TO NEXT CAMPAIGN OPERATION >>"
	next_camp_btn.pressed.connect(func(): advance_campaign_next_operation())
	camp_btns_hb.add_child(next_camp_btn)

	var story_chronicle_btn := Button.new()
	story_chronicle_btn.text = "★ LAUNCH 8-MISSION STORY CHRONICLE & VEO 3.1 CAPABILITIES TOUR [P]"
	story_chronicle_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	story_chronicle_btn.pressed.connect(func():
		set_menu_visible(false)
		if story_director != null and story_director.has_method("start_story_campaign"):
			story_director.call("start_story_campaign", 0)
	)
	camp_btns_hb.add_child(story_chronicle_btn)

	var story_missions_hb := HBoxContainer.new()
	story_missions_hb.add_theme_constant_override("separation", 4)
	camp_tab.add_child(story_missions_hb)

	var mission_short_labels := [
		"M1: IADS & Brigades",
		"M2: Robot Dogs & FPV",
		"M3: Naval USV Salvo",
		"M4: AI Diplomacy [G]",
		"M5: R&D Tech Tree [K]",
		"M6: Space ASAT/HEMP",
		"M7: Bunker Siege [R]",
		"M8: Rods & Nuke [N]",
	]
	for m_i in range(mission_short_labels.size()):
		var m_btn := Button.new()
		m_btn.text = mission_short_labels[m_i]
		m_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cap_idx := m_i
		m_btn.pressed.connect(func():
			set_menu_visible(false)
			if story_director != null and story_director.has_method("start_story_campaign"):
				story_director.call("start_story_campaign", cap_idx)
		)
		story_missions_hb.add_child(m_btn)

	# TAB 2: 6 GLOBAL FLASHPOINT SCENARIOS, AI DOCTRINE & CUSTOM SANDBOX WAR BUILDER
	var scen_tab := VBoxContainer.new()
	scen_tab.name = "2. SCENARIOS & SANDBOX"
	scen_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(scen_tab)

	var scen_lbl := Label.new()
	scen_lbl.text = "SELECT PLAYABLE 2028 FLASHPOINT OPERATION (8 SCENARIOS // 7 2,000x2,000 KM THEATERS // 1,000,000 GLOBAL UNITS):"
	scen_lbl.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	scen_tab.add_child(scen_lbl)

	var scen_hb1 := HBoxContainer.new()
	scen_hb1.add_theme_constant_override("separation", 8)
	scen_tab.add_child(scen_hb1)

	var btn_op1 := Button.new()
	btn_op1.text = "OP 1: PACIFIC SHIELD (CHINA / TAIWAN — 220k UNITS)"
	btn_op1.pressed.connect(func(): launch_scenario("op_pacific_shield_2028", 1.0, Vector2.ZERO))
	scen_hb1.add_child(btn_op1)

	var btn_op2 := Button.new()
	btn_op2.text = "OP 2: IRON HOUND (YUSHAN RIDGE ROBOT DOGS)"
	btn_op2.pressed.connect(func(): launch_scenario("op_iron_hound_ridge", 7.5, Vector2(128.0, 22.0)))
	scen_hb1.add_child(btn_op2)

	var btn_op3 := Button.new()
	btn_op3.text = "OP 3: HORMUZ SWARM (PERSIAN GULF — 50k UNITS)"
	btn_op3.pressed.connect(func(): launch_scenario("op_red_strait_swarm", 3.5, Vector2(0.0, 0.0)))
	scen_hb1.add_child(btn_op3)

	var btn_op4 := Button.new()
	btn_op4.text = "OP 4: KOREAN THUNDER (DMZ — 110k UNITS)"
	btn_op4.pressed.connect(func(): launch_scenario("op_korean_thunder_dmz", 2.5, Vector2(-10.0, 15.0)))
	scen_hb1.add_child(btn_op4)

	var scen_hb2 := HBoxContainer.new()
	scen_hb2.add_theme_constant_override("separation", 8)
	scen_tab.add_child(scen_hb2)

	var btn_op5 := Button.new()
	btn_op5.text = "OP 5: BALTIC SHIELD (NATO vs RUS — 160k UNITS)"
	btn_op5.pressed.connect(func(): launch_scenario("op_baltic_shield_suwalki", 2.5, Vector2(20.0, 10.0)))
	scen_hb2.add_child(btn_op5)

	var btn_op6 := Button.new()
	btn_op6.text = "OP 6: HIMALAYAN SENTINEL (IND vs CHN/PAK — 150k UNITS)"
	btn_op6.pressed.connect(func(): launch_scenario("op_himalayan_sentinel_lac", 2.8, Vector2(0.0, 0.0)))
	scen_hb2.add_child(btn_op6)

	var btn_op7 := Button.new()
	btn_op7.text = "OP 7: UKRAINE DONBAS & AZOV (UKR vs RUS — 240k UNITS)"
	btn_op7.pressed.connect(func(): launch_scenario("op_ukraine_donbas_2028", 1.8, Vector2(0.0, 0.0)))
	scen_hb2.add_child(btn_op7)

	var btn_op8 := Button.new()
	btn_op8.text = "OP 8: RIO BRAVO (US vs MEXICO SIERRA MADRE — 70k UNITS)"
	btn_op8.pressed.connect(func(): launch_scenario("op_mexico_rio_grande_2028", 1.8, Vector2(0.0, 0.0)))
	scen_hb2.add_child(btn_op8)

	var btn_op9 := Button.new()
	btn_op9.text = "★ OP 9: DOOMSDAY CLOCK 2028 (8-CHAPTER STORY & VEO TV TOUR)"
	btn_op9.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_op9.pressed.connect(func():
		launch_scenario("op_global_escalation_chronicle_2028", 1.25, Vector2.ZERO)
	)
	scen_hb2.add_child(btn_op9)

	# FEAT-11: 2028 Dynamic Crisis Scenarios
	var crisis_lbl := Label.new()
	crisis_lbl.text = "2028 GEOPOLITICAL CRISIS SCENARIOS (FEAT-11):"
	crisis_lbl.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	scen_tab.add_child(crisis_lbl)

	var scen_hb3 := HBoxContainer.new()
	scen_hb3.add_theme_constant_override("separation", 8)
	scen_tab.add_child(scen_hb3)

	var btn_cr1 := Button.new()
	btn_cr1.text = "CRISIS 1: TAIWAN STRAIT BLOCKADE"
	btn_cr1.pressed.connect(func(): launch_scenario("taiwan_strait_blockade_2028", 1.8, Vector2(10.0, 5.0)))
	scen_hb3.add_child(btn_cr1)

	var btn_cr2 := Button.new()
	btn_cr2.text = "CRISIS 2: SUWALKI CORRIDOR BREACH"
	btn_cr2.pressed.connect(func(): launch_scenario("suwalki_corridor_breach_2028", 2.2, Vector2(15.0, 0.0)))
	scen_hb3.add_child(btn_cr2)

	var btn_cr3 := Button.new()
	btn_cr3.text = "CRISIS 3: SECOND THOMAS SHOAL"
	btn_cr3.pressed.connect(func(): launch_scenario("second_thomas_shoal_clash_2028", 2.4, Vector2(0.0, 10.0)))
	scen_hb3.add_child(btn_cr3)

	var btn_cr4 := Button.new()
	btn_cr4.text = "CRISIS 4: GIUK ARCTIC BASTION"
	btn_cr4.pressed.connect(func(): launch_scenario("giuk_arctic_bastion_2028", 2.0, Vector2(0.0, 0.0)))
	scen_hb3.add_child(btn_cr4)

	var doc_lbl := Label.new()
	doc_lbl.text = "SELECT OPFOR RED COMMANDER AI DOCTRINE:"
	doc_lbl.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	scen_tab.add_child(doc_lbl)

	var doc_hb := HBoxContainer.new()
	doc_hb.add_theme_constant_override("separation", 8)
	scen_tab.add_child(doc_hb)

	var doc_opts := [
		["DOCTRINE: IADS RADAR AMBUSH (EMCON CYCLING)", "IADS_AMBUSH"],
		["DOCTRINE: DRONE & ROBOT DOG SWARM SATURATION", "SWARM_SATURATION"],
		["DOCTRINE: HYPERSONIC C2/AIRBASE DECAPITATION", "HYPERSONIC_DECAPITATION"],
	]
	for d_entry in doc_opts:
		var d_btn := Button.new()
		d_btn.text = String(d_entry[0])
		var doc_code := String(d_entry[1])
		d_btn.pressed.connect(func():
			if opfor_commander != null and opfor_commander.has_method("set_doctrine"):
				opfor_commander.set_doctrine(doc_code)
		)
		doc_hb.add_child(d_btn)

	var sb_lbl := Label.new()
	sb_lbl.text = "CUSTOM SANDBOX REINFORCEMENT SPAWNER (INSTANTLY DEPLOY TO WAR TABLE):"
	sb_lbl.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	scen_tab.add_child(sb_lbl)

	var sb_hb := HBoxContainer.new()
	sb_hb.add_theme_constant_override("separation", 6)
	scen_tab.add_child(sb_hb)

	var sandbox_units := [
		["+ BLUE F-35A", 1, "f_35a_lightning", Vector3(60.0, 6000.0, 0.0)],
		["+ BLUE KC-46 Tanker", 1, "kc_46_pegasus", Vector3(90.0, 8500.0, 0.0)],
		["+ BLUE HEMTT Convoy", 1, "hemtt_supply_convoy", Vector3(110.0, 0.0, 10.0)],
		["+ BLUE Vision 60 Dogs", 1, "vision_60_q_ugv", Vector3(132.0, 0.0, 22.0)],
		["+ BLUE Leonidas HPM", 1, "epirus_leonidas_hpm", Vector3(95.0, 0.0, -15.0)],
		["+ RED J-20 Flight", 2, "j_20_mighty_dragon", Vector3(-60.0, 6500.0, 0.0)],
		["+ RED Unitree B2-W Dogs", 2, "unitree_b2w_armed", Vector3(122.0, 0.0, 22.0)],
	]
	for s_entry in sandbox_units:
		var s_btn := Button.new()
		s_btn.text = String(s_entry[0])
		var fac: int = int(s_entry[1])
		var slug: String = String(s_entry[2])
		var pos: Vector3 = s_entry[3]
		s_btn.pressed.connect(func():
			if command_bus != null:
				command_bus.enqueue_spawn_sandbox_unit(fac, slug, pos)
		)
		sb_hb.add_child(s_btn)

	# TAB 3: WIKIPEDIA ARMORY & REAL PHOTO ENCYCLOPEDIA
	var enc_tab := HBoxContainer.new()
	enc_tab.name = "3. WIKIPEDIA PHOTO ARMORY"
	enc_tab.add_theme_constant_override("separation", 12)
	_tab_container.add_child(enc_tab)

	var enc_scroll := ScrollContainer.new()
	enc_scroll.custom_minimum_size = Vector2(360.0, 500.0)
	enc_tab.add_child(enc_scroll)

	var enc_list_vb := VBoxContainer.new()
	enc_list_vb.name = "EncyclopediaListVBox"
	enc_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enc_scroll.add_child(enc_list_vb)

	var enc_detail_vb := VBoxContainer.new()
	enc_detail_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enc_detail_vb.add_theme_constant_override("separation", 8)
	enc_tab.add_child(enc_detail_vb)

	_encyclopedia_title_label = Label.new()
	_encyclopedia_title_label.text = "SELECT ANY PLATFORM OR MUNITION"
	_encyclopedia_title_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	enc_detail_vb.add_child(_encyclopedia_title_label)

	_encyclopedia_photo_rect = TextureRect.new()
	_encyclopedia_photo_rect.custom_minimum_size = Vector2(540.0, 260.0)
	_encyclopedia_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_encyclopedia_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	enc_detail_vb.add_child(_encyclopedia_photo_rect)

	_encyclopedia_specs_label = Label.new()
	_encyclopedia_specs_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	enc_detail_vb.add_child(_encyclopedia_specs_label)

	_encyclopedia_summary_label = RichTextLabel.new()
	_encyclopedia_summary_label.bbcode_enabled = true
	_encyclopedia_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enc_detail_vb.add_child(_encyclopedia_summary_label)

	# TAB 4: VICTORY / DEFEAT, AFTER-ACTION REPORT (AAR) & TACVIEW TIMELINE SCRUBBER
	var aar_tab := VBoxContainer.new()
	aar_tab.name = "4. AAR & TACVIEW REPLAY"
	aar_tab.add_theme_constant_override("separation", 10)
	_tab_container.add_child(aar_tab)

	_aar_summary_label = RichTextLabel.new()
	_aar_summary_label.bbcode_enabled = true
	_aar_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aar_tab.add_child(_aar_summary_label)

	var scrub_hb := HBoxContainer.new()
	scrub_hb.add_theme_constant_override("separation", 10)
	aar_tab.add_child(scrub_hb)

	_replay_status_label = Label.new()
	_replay_status_label.text = "TACVIEW TIMELINE SCRUBBER (LIVE):"
	_replay_status_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	scrub_hb.add_child(_replay_status_label)

	_replay_slider = HSlider.new()
	_replay_slider.min_value = 0.0
	_replay_slider.max_value = 1.0
	_replay_slider.step = 0.01
	_replay_slider.value = 1.0
	_replay_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_replay_slider.value_changed.connect(_on_replay_slider_changed)
	scrub_hb.add_child(_replay_slider)

	var live_btn := Button.new()
	live_btn.text = "[RETURN TO LIVE BATTLE]"
	live_btn.pressed.connect(func():
		if sim_server != null:
			sim_server.resume_live_from_replay()
			_replay_status_label.text = "TACVIEW TIMELINE SCRUBBER (LIVE):"
	)
	scrub_hb.add_child(live_btn)

	# TAB 5: INTERACTIVE BOOT-CAMP TUTORIAL & FIELD MANUAL
	var man_tab := VBoxContainer.new()
	man_tab.name = "5. TUTORIAL & FIELD MANUAL"
	man_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(man_tab)

	var tut_hb := HBoxContainer.new()
	tut_hb.add_theme_constant_override("separation", 10)
	man_tab.add_child(tut_hb)

	var prev_tut_btn := Button.new()
	prev_tut_btn.text = "<< PREVIOUS TRAINING STEP"
	prev_tut_btn.pressed.connect(func():
		current_tutorial_step_index = maxi(0, current_tutorial_step_index - 1)
		_refresh_manual_and_tutorial_view()
	)
	tut_hb.add_child(prev_tut_btn)

	var next_tut_btn := Button.new()
	next_tut_btn.text = "NEXT TRAINING STEP >>"
	next_tut_btn.pressed.connect(func():
		var max_steps: int = max(1, sim_db.tutorial_steps.size() if sim_db != null else 1)
		current_tutorial_step_index = (current_tutorial_step_index + 1) % max_steps
		_refresh_manual_and_tutorial_view()
	)
	tut_hb.add_child(next_tut_btn)

	var launch_live_tut_btn := Button.new()
	launch_live_tut_btn.text = "LAUNCH LIVE INTERACTIVE 5-STEP BOOT-CAMP ON WAR TABLE [H]"
	launch_live_tut_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	launch_live_tut_btn.pressed.connect(func():
		set_menu_visible(false)
		if tutorial_controller != null and tutorial_controller.has_method("start_bootcamp"):
			tutorial_controller.call("start_bootcamp", true)
	)
	tut_hb.add_child(launch_live_tut_btn)

	_manual_rich_label = RichTextLabel.new()
	_manual_rich_label.bbcode_enabled = true
	_manual_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	man_tab.add_child(_manual_rich_label)

	# TAB 6: DEFENSE BUDGET, 5-BRANCH R&D TECH TREE, TASK FORCE PROCUREMENT & DEFCON ESCALATION (K)
	var tech_tab := VBoxContainer.new()
	tech_tab.name = "6. BUDGET, R&D TECH TREE & DEFCON (K)"
	tech_tab.add_theme_constant_override("separation", 6)
	_tab_container.add_child(tech_tab)

	_budget_header_label = RichTextLabel.new()
	_budget_header_label.bbcode_enabled = true
	_budget_header_label.custom_minimum_size = Vector2(980.0, 96.0)
	tech_tab.add_child(_budget_header_label)

	# Task Force Procurement & Emergency Resupply Bar
	var proc_hb := HBoxContainer.new()
	proc_hb.add_theme_constant_override("separation", 6)
	tech_tab.add_child(proc_hb)

	var proc_items := [
		["[+AMMO AIRLIFT $250M]", "AMMO"],
		["[+STEALTH AIR WING $450M]", "TF_STEALTH_AIR"],
		["[+ROBOT DOG ARMOR TF $280M]", "TF_ROBOT_ARMOR"],
		["[+LASER/PATRIOT IADS $380M]", "TF_LASER_IADS"],
		["[+HYPERSONIC NAVAL TF $650M]", "TF_NAVAL_STRIKE"],
	]
	for p_item in proc_items:
		var p_btn := Button.new()
		p_btn.text = String(p_item[0])
		p_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
		var p_code := String(p_item[1])
		p_btn.pressed.connect(func():
			if sim_server != null:
				if p_code == "AMMO":
					sim_server.procure_ammo_airlift(1)
				else:
					sim_server.procure_task_force(p_code, 1)
				_refresh_tech_tree_and_budget_view()
		)
		proc_hb.add_child(p_btn)

	# NBC / HEMP / Orbital Rod / Thermonuclear Escalation Strike Bar
	var esc_hb := HBoxContainer.new()
	esc_hb.add_theme_constant_override("separation", 6)
	tech_tab.add_child(esc_hb)

	var esc_items := [
		["[RELOCATE HQ BUNKER $200M (R)]", "RELOCATE_HQ", Color(0.25, 0.95, 1.0)],
		["[CBRN AEROSOL STRIKE $180M]", "STRIKE_TACTICAL_CBRN", Color(0.65, 1.0, 0.25)],
		["[HEMP EMP SUPER-BURST $250M]", "STRIKE_HEMP_EMP", Color(0.35, 0.95, 1.0)],
		["[ORBITAL TUNGSTEN RODS $220M]", "STRIKE_ORBITAL_RODS", Color(1.0, 0.85, 0.25)],
		["[PEAD-99 THERMONUCLEAR SALVO $350M (N)]", "STRIKE_THERMONUCLEAR", Color(1.0, 0.28, 0.28)],
		["[DIPLO: AIRSPACE TREATY $150M]", "DIPLO_AIRSPACE_ACCESS", Color(0.25, 0.95, 0.85)],
		["[DIPLO: ALLIED AID +$M]", "DIPLO_REQUEST_ALLY_AID", Color(0.35, 1.0, 0.55)],
		["[DIPLO: DEFENSE PACT (G)]", "DIPLO_MILITARY_ALLIANCE", Color(0.25, 0.85, 1.0)],
	]
	for e_item in esc_items:
		var e_btn := Button.new()
		e_btn.text = String(e_item[0])
		e_btn.add_theme_color_override("font_color", e_item[2])
		var s_code := String(e_item[1])
		e_btn.pressed.connect(func():
			if sim_server != null:
				if s_code == "RELOCATE_HQ":
					sim_server.relocate_bunker()
				elif s_code.begins_with("DIPLO_"):
					sim_server.execute_diplomacy(s_code, "", 1)
				else:
					sim_server.execute_escalated_strike(s_code, Vector3.ZERO, 1)
				_refresh_tech_tree_and_budget_view()
		)
		esc_hb.add_child(e_btn)

	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 10)
	tech_tab.add_child(split_hb)

	var tech_scroll := ScrollContainer.new()
	tech_scroll.custom_minimum_size = Vector2(610.0, 340.0)
	tech_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_child(tech_scroll)

	_tech_tree_list_vb = VBoxContainer.new()
	_tech_tree_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tech_tree_list_vb.add_theme_constant_override("separation", 4)
	tech_scroll.add_child(_tech_tree_list_vb)

	_news_feed_rich_label = RichTextLabel.new()
	_news_feed_rich_label.bbcode_enabled = true
	_news_feed_rich_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_news_feed_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_child(_news_feed_rich_label)

	# TAB 7: LIVE TV NEWS & GOOGLE VEO 3.1 VIDEO BROADCAST STUDIO
	var studio_tab := VBoxContainer.new()
	studio_tab.name = "7. LIVE TV NEWS & VEO STUDIO"
	studio_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(studio_tab)

	var studio_top_hb := HBoxContainer.new()
	studio_top_hb.add_theme_constant_override("separation", 8)
	studio_tab.add_child(studio_top_hb)

	var btn_gen_gemini := Button.new()
	btn_gen_gemini.text = "[GENERATE LIVE GEMINI 2.5 FLASH TV REPORT (J)]"
	btn_gen_gemini.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_gen_gemini.pressed.connect(func():
		if sim_server != null:
			sim_server.trigger_news_video_broadcast(sim_server.world_state.active_news_video_slug, "Commander live press briefing from bunker", true, false)
			_refresh_news_video_studio_view()
	)
	studio_top_hb.add_child(btn_gen_gemini)

	var btn_gen_veo := Button.new()
	btn_gen_veo.text = "[SYNTHESIZE NEW GOOGLE VEO 3.1 FAST AI WAR VIDEO]"
	btn_gen_veo.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_gen_veo.pressed.connect(func():
		if sim_server != null:
			sim_server.trigger_news_video_broadcast(sim_server.world_state.active_news_video_slug, "Custom Veo 3.1 Fast war footage generation", true, true)
			_refresh_news_video_studio_view()
	)
	studio_top_hb.add_child(btn_gen_veo)

	var studio_split_hb := HBoxContainer.new()
	studio_split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	studio_split_hb.add_theme_constant_override("separation", 10)
	studio_tab.add_child(studio_split_hb)

	var ch_scroll := ScrollContainer.new()
	ch_scroll.custom_minimum_size = Vector2(360.0, 420.0)
	ch_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	studio_split_hb.add_child(ch_scroll)

	_studio_channels_vb = VBoxContainer.new()
	_studio_channels_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_studio_channels_vb.add_theme_constant_override("separation", 4)
	ch_scroll.add_child(_studio_channels_vb)

	var monitor_vb := VBoxContainer.new()
	monitor_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	monitor_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	monitor_vb.add_theme_constant_override("separation", 6)
	studio_split_hb.add_child(monitor_vb)

	_studio_video_rect = TextureRect.new()
	_studio_video_rect.custom_minimum_size = Vector2(560.0, 300.0)
	_studio_video_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_video_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monitor_vb.add_child(_studio_video_rect)

	_studio_info_rich_label = RichTextLabel.new()
	_studio_info_rich_label.bbcode_enabled = true
	_studio_info_rich_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_studio_info_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	monitor_vb.add_child(_studio_info_rich_label)

	# TAB 8: RED PHONE HOTLINE, DYNAMIC WEATHER & CAMPAIGN SAVE/LOAD (Phases 22-25)
	var rp_tab := VBoxContainer.new()
	rp_tab.name = "8. RED PHONE, WEATHER & SAVE/LOAD"
	rp_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(rp_tab)

	_red_phone_rich_label = RichTextLabel.new()
	_red_phone_rich_label.bbcode_enabled = true
	_red_phone_rich_label.custom_minimum_size = Vector2(960.0, 220.0)
	_red_phone_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rp_tab.add_child(_red_phone_rich_label)

	var rp_hb := HBoxContainer.new()
	rp_hb.add_theme_constant_override("separation", 6)
	rp_tab.add_child(rp_hb)

	var btn_ring := Button.new()
	btn_ring.text = "RING RED PHONE HOTLINE [Y]"
	btn_ring.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	btn_ring.pressed.connect(func():
		if sim_server != null:
			sim_server.trigger_red_phone_hotline("MANUAL_HOTLINE_CALL")
			_refresh_red_phone_and_save_view()
	)
	rp_hb.add_child(btn_ring)

	var hotline_choices := [
		["ACCEPT 45s CEASEFIRE (-18% ESC)", "HOTLINE_ACCEPT_CEASEFIRE"],
		["$400M CONCESSION TREATY (-28% ESC)", "HOTLINE_BRIBE_DEESCALATE"],
		["THREATEN ORBITAL STRIKE (+8% Pk)", "HOTLINE_BLUFF_DETERRENCE"],
		["SLAM DOWN PHONE (+$500M WAR BUDGET)", "HOTLINE_REJECT_ESCALATE"],
	]
	for hc in hotline_choices:
		var c_btn := Button.new()
		c_btn.text = String(hc[0])
		c_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_code: String = String(hc[1])
		c_btn.pressed.connect(func():
			if sim_server != null:
				sim_server.resolve_red_phone_hotline(c_code)
				_refresh_red_phone_and_save_view()
		)
		rp_hb.add_child(c_btn)

	var wx_hb := HBoxContainer.new()
	wx_hb.add_theme_constant_override("separation", 6)
	rp_tab.add_child(wx_hb)

	for wx_code in ["CLEAR", "OVERCAST", "TYPHOON_STORM", "SANDSTORM", "ARCTIC_BLIZZARD"]:
		var w_btn := Button.new()
		w_btn.text = "WEATHER: " + String(wx_code)
		w_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cap_wx: String = String(wx_code)
		w_btn.pressed.connect(func():
			if sim_server != null:
				sim_server.set_weather_condition(cap_wx)
				_refresh_red_phone_and_save_view()
		)
		wx_hb.add_child(w_btn)

	var sl_hb := HBoxContainer.new()
	sl_hb.add_theme_constant_override("separation", 8)
	rp_tab.add_child(sl_hb)

	var btn_save1 := Button.new()
	btn_save1.text = "SAVE CAMPAIGN SLOT 1 [F5]"
	btn_save1.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_save1.pressed.connect(func():
		if sim_server != null:
			sim_server.save_campaign_state("slot_1")
			_refresh_red_phone_and_save_view()
	)
	sl_hb.add_child(btn_save1)

	var btn_load1 := Button.new()
	btn_load1.text = "LOAD CAMPAIGN SLOT 1 [F9]"
	btn_load1.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	btn_load1.pressed.connect(func():
		if sim_server != null:
			sim_server.load_campaign_state("slot_1")
			_refresh_red_phone_and_save_view()
	)
	sl_hb.add_child(btn_load1)

	var btn_export_scen := Button.new()
	btn_export_scen.text = "EXPORT CUSTOM SCENARIO JSON"
	btn_export_scen.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_export_scen.pressed.connect(func():
		if sim_server != null:
			sim_server.export_custom_scenario("op_custom_user_theater", "Custom Commander Scenario")
			_refresh_red_phone_and_save_view()
	)
	sl_hb.add_child(btn_export_scen)

	# Phases 26, 27 & 28 Action Row (Humanitarian Corridors, Subterranean Tunnel Ops & CEMA Cyber-EW)
	var p26_hb := HBoxContainer.new()
	p26_hb.add_theme_constant_override("separation", 6)
	rp_tab.add_child(p26_hb)

	var btn_corridor := Button.new()
	btn_corridor.text = "EVAC CORRIDOR [F7] (+$200M)"
	btn_corridor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_corridor.pressed.connect(func():
		if sim_server != null:
			sim_server.declare_humanitarian_corridor()
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_corridor)

	var btn_vbss := Button.new()
	btn_vbss.text = "MARITIME VBSS SEIZE (+$180M)"
	btn_vbss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_vbss.pressed.connect(func():
		if sim_server != null:
			sim_server.execute_maritime_interdiction()
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_vbss)

	var btn_mop := Button.new()
	btn_mop.text = "GBU-57 MOP TUNNEL STRIKE [F8]"
	btn_mop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mop.pressed.connect(func():
		if sim_server != null:
			sim_server.execute_tunnel_operation("BUNKER_BUSTER_MOP", -1)
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_mop)

	var btn_dog_breach := Button.new()
	btn_dog_breach.text = "ROBOT DOG TUNNEL BREACH"
	btn_dog_breach.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_dog_breach.pressed.connect(func():
		if sim_server != null:
			sim_server.execute_tunnel_operation("ROBOT_DOG_TUNNEL_BREACH", -1)
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_dog_breach)

	var btn_hijack := Button.new()
	btn_hijack.text = "CEMA DRONE HIJACK [F10]"
	btn_hijack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hijack.pressed.connect(func():
		if sim_server != null:
			sim_server.execute_cema_operation("CEMA_DRONE_HIJACK")
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_hijack)

	var btn_blackout := Button.new()
	btn_blackout.text = "SCADA GRID BLACKOUT"
	btn_blackout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_blackout.pressed.connect(func():
		if sim_server != null:
			sim_server.execute_cema_operation("CEMA_GRID_BLACKOUT")
			_refresh_red_phone_and_save_view()
	)
	p26_hb.add_child(btn_blackout)

	# TAB 9: ÉPREUVES TACTIQUES (67 MISSIONS)
	var trials_tab := VBoxContainer.new()
	trials_tab.name = "9. ÉPREUVES TACTIQUES (67 MISSIONS)"
	trials_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(trials_tab)

	# Domain Filter Buttons
	var filter_hb := HBoxContainer.new()
	filter_hb.add_theme_constant_override("separation", 6)
	trials_tab.add_child(filter_hb)

	var filter_lbl := Label.new()
	filter_lbl.text = "DOMAINE TACTIQUE :"
	filter_lbl.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	filter_hb.add_child(filter_lbl)

	var btn_all := Button.new()
	btn_all.text = "TOUT (67)"
	btn_all.pressed.connect(func(): _set_trials_domain_filter("ALL"))
	filter_hb.add_child(btn_all)

	var btn_air := Button.new()
	btn_air.text = "AIR (20)"
	btn_air.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	btn_air.pressed.connect(func(): _set_trials_domain_filter("AIR"))
	filter_hb.add_child(btn_air)

	var btn_land := Button.new()
	btn_land.text = "TERRE (28)"
	btn_land.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	btn_land.pressed.connect(func(): _set_trials_domain_filter("LAND"))
	filter_hb.add_child(btn_land)

	var btn_sea := Button.new()
	btn_sea.text = "MER / SSBN (19)"
	btn_sea.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	btn_sea.pressed.connect(func(): _set_trials_domain_filter("SEA"))
	filter_hb.add_child(btn_sea)

	# Main Split Container: Left Scroll List, Right Detail Panel
	var main_split := HBoxContainer.new()
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_theme_constant_override("separation", 10)
	trials_tab.add_child(main_split)

	# Left: Scrollable List of Platforms
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(360.0, 420.0)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(list_scroll)

	_trials_list_vb = VBoxContainer.new()
	_trials_list_vb.name = "TrialsListVBox"
	_trials_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_trials_list_vb)

	# Right: Detail Panel
	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 6)
	main_split.add_child(right_panel)

	# Title & Domain badge
	_trials_title_label = RichTextLabel.new()
	_trials_title_label.bbcode_enabled = true
	_trials_title_label.fit_content = true
	_trials_title_label.custom_minimum_size = Vector2(0.0, 32.0)
	right_panel.add_child(_trials_title_label)

	# Nemesis Threat & Wingman Partner
	_trials_threat_label = RichTextLabel.new()
	_trials_threat_label.bbcode_enabled = true
	_trials_threat_label.fit_content = true
	_trials_threat_label.custom_minimum_size = Vector2(0.0, 44.0)
	right_panel.add_child(_trials_threat_label)

	# Dynamic Detail Tabs (Sub-TabContainer)
	var detail_tabs := TabContainer.new()
	detail_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(detail_tabs)

	_trials_all_label = RichTextLabel.new()
	_trials_all_label.name = "VUE D'ENSEMBLE"
	_trials_all_label.bbcode_enabled = true
	_trials_all_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_all_label)

	_trials_move_label = RichTextLabel.new()
	_trials_move_label.name = "Comportement & Déplacement"
	_trials_move_label.bbcode_enabled = true
	_trials_move_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_move_label)

	_trials_fight_label = RichTextLabel.new()
	_trials_fight_label.name = "Attaque & Doctrine"
	_trials_fight_label.bbcode_enabled = true
	_trials_fight_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_fight_label)

	_trials_defend_label = RichTextLabel.new()
	_trials_defend_label.name = "Défense & Contre-mesures"
	_trials_defend_label.bbcode_enabled = true
	_trials_defend_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_defend_label)

	_trials_trick_label = RichTextLabel.new()
	_trials_trick_label.name = "Atout Technologique"
	_trials_trick_label.bbcode_enabled = true
	_trials_trick_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_trick_label)

	_trials_swarm_label = RichTextLabel.new()
	_trials_swarm_label.name = "Intégration Alliée & Essaim"
	_trials_swarm_label.bbcode_enabled = true
	_trials_swarm_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_tabs.add_child(_trials_swarm_label)

	# Prominent Tactical Launch Button
	_trials_launch_btn = Button.new()
	_trials_launch_btn.text = "[LANCER L'ÉPREUVE TACTIQUE DANS L'ARÈNE]"
	_trials_launch_btn.custom_minimum_size = Vector2(0.0, 44.0)
	_trials_launch_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	_trials_launch_btn.pressed.connect(func():
		if sim_server != null and sim_server.has_method("load_unit_trial"):
			sim_server.load_unit_trial(_selected_trial_slug)
			set_menu_visible(false)
	)
	right_panel.add_child(_trials_launch_btn)


func _on_replay_slider_changed(val: float) -> void:
	if sim_server == null:
		return
	sim_server.scrub_replay_ratio(val)
	if war_table != null and war_table.visual_sync != null:
		war_table.visual_sync.sync_visuals()
	var kf_cnt: int = int(sim_server.replay_recorder.get_keyframe_count())
	var kf_idx: int = int(sim_server.replay_recorder.active_keyframe_index)
	_replay_status_label.text = "TACVIEW REPLAY KEYFRAME %d / %d:" % [kf_idx + 1, max(1, kf_cnt)]


func _populate_encyclopedia_entries() -> void:
	if sim_db == null or _tab_container == null:
		return
	var enc_tab := _tab_container.get_child(2)
	var scroll := enc_tab.get_child(0) as ScrollContainer
	var list_vb := scroll.get_child(0) as VBoxContainer
	for c in list_vb.get_children():
		c.queue_free()

	for pid in range(1, sim_db.platforms_by_id.size()):
		var p: Dictionary = sim_db.platforms_by_id[pid]
		if p.is_empty():
			continue
		var btn := Button.new()
		btn.text = "[%s] %s ($%.1fM)" % [String(p.get("country_origin", "")), String(p.get("display_name", "")), float(p.get("unit_cost_musd", 0.0))]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var captured_pid := pid
		btn.pressed.connect(func(): show_encyclopedia_platform(captured_pid))
		list_vb.add_child(btn)

	for wid in range(1, sim_db.weapons_by_id.size()):
		var w: Dictionary = sim_db.weapons_by_id[wid]
		if w.is_empty():
			continue
		var btn := Button.new()
		btn.text = "[MUNITION] %s ($%.2fM)" % [String(w.get("display_name", "")), float(w.get("round_cost_musd", 0.0))]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var captured_wid := wid
		btn.pressed.connect(func(): show_encyclopedia_weapon(captured_wid))
		list_vb.add_child(btn)

	show_encyclopedia_platform(1)


func show_encyclopedia_platform(pid: int) -> void:
	if sim_db == null:
		return
	var p: Dictionary = sim_db.get_platform(pid)
	if p.is_empty():
		return
	_encyclopedia_title_label.text = "%s (%s - %d)" % [String(p.get("display_name", "")), String(p.get("country_origin", "")), int(p.get("service_year", 2026))]
	_encyclopedia_photo_rect.texture = sim_db.get_wiki_photo_texture(String(p.get("image_res_path", "")))
	_encyclopedia_specs_label.text = "CLASS: %s | AUTONOMY: %s | RCS: %.4f m² | SPEED: %.0f kts | COST: $%.1fM" % [
		String(p.get("unit_class", "")),
		String(p.get("autonomy_level", "MANNED")),
		float(p.get("rcs_m2", 1.0)),
		float(p.get("max_speed_knots", 0.0)),
		float(p.get("unit_cost_musd", 0.0)),
	]
	_encyclopedia_summary_label.text = "%s\n\n[color=#00D8FF]%s[/color]" % [String(p.get("wiki_summary", "")), String(p.get("wiki_url", ""))]


func show_encyclopedia_weapon(wid: int) -> void:
	if sim_db == null:
		return
	var w: Dictionary = sim_db.get_weapon(wid)
	if w.is_empty():
		return
	_encyclopedia_title_label.text = "[MUNITION] %s" % String(w.get("display_name", ""))
	_encyclopedia_photo_rect.texture = sim_db.get_wiki_photo_texture(String(w.get("image_res_path", "")))
	_encyclopedia_specs_label.text = "GUIDANCE: %s | SPEED: Mach %.1f | RANGE: %.1f km | Pk: %.0f%% | SHOT COST: $%.3fM" % [
		String(w.get("guidance_type", "")),
		float(w.get("speed_mach", 1.0)),
		float(w.get("max_range_km", 10.0)),
		float(w.get("base_pk", 0.8)) * 100.0,
		float(w.get("round_cost_musd", 0.01)),
	]
	_encyclopedia_summary_label.text = "%s\n\n[color=#00D8FF]%s[/color]" % [String(w.get("wiki_summary", "")), String(w.get("wiki_url", ""))]


## Verifies that every platform and weapon in `SimDB` loads a valid `Texture2D` from `res://assets/wiki_images/`.
func verify_all_encyclopedia_photos_load() -> int:
	if sim_db == null:
		return 0
	var count := 0
	for pid in range(1, sim_db.platforms_by_id.size()):
		var p: Dictionary = sim_db.platforms_by_id[pid]
		var tex: Texture2D = sim_db.get_wiki_photo_texture(String(p.get("image_res_path", "")))
		assert(tex != null, "Missing Wikipedia photo texture for platform: " + String(p.get("slug", "")))
		count += 1
	for wid in range(1, sim_db.weapons_by_id.size()):
		var w: Dictionary = sim_db.weapons_by_id[wid]
		var tex: Texture2D = sim_db.get_wiki_photo_texture(String(w.get("image_res_path", "")))
		assert(tex != null, "Missing Wikipedia photo texture for weapon: " + String(w.get("slug", "")))
		count += 1
	return count


func launch_scenario(scenario_slug: String, initial_zoom: float = 1.0, initial_pan_km: Vector2 = Vector2.ZERO) -> void:
	if sim_server != null:
		sim_server.load_scenario(scenario_slug)
	if war_table != null:
		war_table.bind_sim_server(sim_server)
		war_table.set_zoom_and_pan(initial_zoom, initial_pan_km, true)
	set_menu_visible(false)
	if scenario_slug == "op_global_escalation_chronicle_2028" and story_director != null and story_director.has_method("start_story_campaign"):
		story_director.call("start_story_campaign", 0)


func start_campaign_operation(stage_idx: int = 0) -> void:
	if sim_db == null or sim_db.scenarios_list.is_empty():
		return
	campaign_stage_index = clampi(stage_idx, 0, sim_db.scenarios_list.size() - 1)
	if stage_idx == 0:
		campaign_cumulative_blue_lost_musd = 0.0
		campaign_cumulative_red_lost_musd = 0.0
	var sc: Dictionary = sim_db.scenarios_list[campaign_stage_index]
	var slug := String(sc.get("slug", "op_pacific_shield_2028"))
	var zoom := 7.5 if slug == "op_iron_hound_ridge" else (3.5 if slug == "op_red_strait_swarm" else 1.0)
	var pan := Vector2(128.0, 22.0) if slug == "op_iron_hound_ridge" else Vector2.ZERO
	launch_scenario(slug, zoom, pan)


func advance_campaign_next_operation() -> void:
	if sim_server != null:
		campaign_cumulative_blue_lost_musd += sim_server.world_state.blue_lost_musd
		campaign_cumulative_red_lost_musd += sim_server.world_state.red_lost_musd
	var total_scens: int = max(1, int(sim_db.scenarios_list.size()))
	var next_stage: int = (campaign_stage_index + 1) % total_scens
	start_campaign_operation(next_stage)


func _refresh_campaign_view() -> void:
	if _campaign_status_label == null or sim_db == null or sim_db.scenarios_list.is_empty():
		return
	var sc: Dictionary = sim_db.scenarios_list[clampi(campaign_stage_index, 0, sim_db.scenarios_list.size() - 1)]
	var orbat_lines := ""
	if sim_server != null and not sim_server.world_state.global_theaters.is_empty():
		var ws: WorldState = sim_server.world_state
		orbat_lines = "\n\n[b][color=#FFD940]LIVE 1,000,000-UNIT GLOBAL MULTI-THEATER ORDER OF BATTLE (7 x 2,000km THEATERS):[/color][/b]\n"
		orbat_lines += "Planet-Wide Active Combat Units: [color=#00D8FF]%d Total[/color] ([color=#00D8FF]Blue Allied: %d[/color] vs [color=#FF2A54]Red OpFor: %d[/color])\n" % [
			ws.global_total_units_active, ws.global_blue_units_active, ws.global_red_units_active
		]
		for t_key in ws.global_theaters.keys():
			var td: Dictionary = ws.global_theaters[t_key]
			var b_act := int(td.get("blue_active", 0))
			var r_act := int(td.get("red_active", 0))
			orbat_lines += "• [b]%s (%s)[/b] — [color=#00D8FF]%dk Blue[/color] vs [color=#FF2A54]%dk Red[/color] (%dk total) | [i]%s[/i]\n" % [
				String(td.get("short_name", t_key)),
				String(td.get("actors", "")),
				b_act / 1000,
				r_act / 1000,
				(b_act + r_act) / 1000,
				String(td.get("carrier_flagship", "")),
			]
	_campaign_status_label.text = (
		"[b][color=#00D8FF]2028 GLOBAL FLASHPOINT — 8-OPERATION MULTI-THEATER DYNAMIC CAMPAIGN[/color][/b]\n"
		+ "Current Campaign Stage: [color=#FFB800]Operation %d of %d — %s[/color]\n" % [campaign_stage_index + 1, sim_db.scenarios_list.size(), String(sc.get("display_name", ""))]
		+ "Cumulative Theater Ledger: [color=#00D8FF]NATO Blue Lost: $%.1fM[/color] | [color=#FF2A54]OPFOR Red Destroyed: $%.1fM[/color]\n\n" % [campaign_cumulative_blue_lost_musd, campaign_cumulative_red_lost_musd]
		+ "[b]OPERATION ORDER (OPORD):[/b]\n%s%s" % [String(sc.get("briefing_opord", "")), orbat_lines]
	)


func _on_battle_concluded(victory_blue: bool, reason: String, _blue_lost: float, _red_lost: float) -> void:
	_refresh_aar_view(victory_blue, reason)
	_tab_container.current_tab = 3
	set_menu_visible(true)


func _refresh_aar_view(victory_blue: bool, reason: String) -> void:
	if _aar_summary_label == null or sim_server == null:
		return
	var st: WorldState = sim_server.world_state
	var replay_cnt: int = int(command_bus.get_replay_log().size()) if command_bus != null else 0
	var kf_cnt: int = int(sim_server.replay_recorder.get_keyframe_count())
	var outcome := "[color=#00D8FF]DECISIVE NATO BLUE VICTORY[/color]" if victory_blue else "[color=#FF2A54]GAME OVER // COMMAND BUNKER LOST / WITHDRAWAL[/color]"
	var bunker_stat := "HQ BUNKER: %s (Hull: %.0f%% | Capture: %.0f%% | Status: %s | Relocations: %d)" % [
		st.bunker_base_name, (st.bunker_hp / maxf(1.0, st.bunker_max_hp)) * 100.0, st.bunker_capture_progress, st.bunker_status_code, st.bunker_relocations_count
	]
	_aar_summary_label.text = (
		"[b]AFTER-ACTION REPORT (AAR) // %s[/b]\n" % outcome
		+ "Status: %s | Active Theater: [color=#00D8FF]%s[/color] | DEFCON: [color=#FF2A54]%d[/color]\n" % [reason, st.active_theater_slug, st.defcon_level]
		+ "• [color=#00FF9D]Command Bunker Integrity:[/color] %s\n" % bunker_stat
		+ "• [color=#00D8FF]Friendly Casualties & Equipment Losses:[/color] KIA %d | WIA %d | $%.2fM USD (%d units lost)\n" % [st.blue_personnel_kia, st.blue_personnel_wia, st.blue_lost_musd, st.blue_units_destroyed]
		+ "• [color=#FF2A54]Hostile OPFOR Casualties & Destroyed:[/color] KIA %d | WIA %d | $%.2fM USD (%d units destroyed)\n" % [st.red_personnel_kia, st.red_personnel_wia, st.red_lost_musd, st.red_units_destroyed]
		+ "• [color=#B84DFF]Directed Energy (Iron Beam Laser / Leonidas HPM) & SAM Intercepts:[/color] %d hostile drones/missiles neutralized\n" % st.blue_munitions_intercepted
		+ "• [color=#FFB800]Logistics & Airbase Operations:[/color] %d Aerial Refuelings | %d Convoy Resupplies | %d Runway Craters Inflicted\n" % [st.refuel_events_count, st.resupply_events_count, st.craters_inflicted_count]
		+ "• [color=#00D8FF]Tacview Deterministic Replay Buffer:[/color] %d recorded commands / %d timeline keyframes." % [replay_cnt, kf_cnt]
	)


func _refresh_manual_and_tutorial_view() -> void:
	if _manual_rich_label == null or sim_db == null:
		return
	var txt := "[b][color=#FFB800]INTERACTIVE BOOT-CAMP TRAINING STEP:[/color][/b]\n"
	if not sim_db.tutorial_steps.is_empty():
		var idx := clampi(current_tutorial_step_index, 0, sim_db.tutorial_steps.size() - 1)
		var step_d: Dictionary = sim_db.tutorial_steps[idx]
		var callsign := String(step_d.get("instructor_callsign", step_d.get("prompt_key", "MAGIC 1-1")))
		var prompt_body := String(step_d.get("prompt_text", step_d.get("instruction", "")))
		var tip := String(step_d.get("reward_tip", ""))
		txt += "[color=#00D8FF]%s[/color] — [b]%s[/b]\n%s\n[color=#00FF9D]Doctrine Tip: %s[/color]\n\n" % [
			String(step_d.get("title", "")),
			callsign,
			prompt_body,
			tip,
		]
	txt += "[b][color=#00D8FF]COMMANDER'S TACTICAL FIELD MANUAL (FROM WARGAME.DB & DOCS/GAME_MANUAL.MD):[/color][/b]\n\n"
	for sec in sim_db.manual_sections:
		var body_md := String(sec.get("markdown_body", sec.get("body_markdown", "")))
		txt += "[b][color=#FFB800]■ %s[/color][/b]\n%s\n\n" % [
			String(sec.get("title", "")),
			body_md,
		]
	_manual_rich_label.text = txt


func _refresh_tech_tree_and_budget_view() -> void:
	if _budget_header_label == null or _tech_tree_list_vb == null or sim_server == null or sim_db == null:
		return
	var ws: WorldState = sim_server.world_state
	var defcon_col := "#00FF9D"
	if ws.defcon_level == 4:
		defcon_col = "#00D8FF"
	elif ws.defcon_level == 3:
		defcon_col = "#FFB800"
	elif ws.defcon_level == 2:
		defcon_col = "#FF6A00"
	elif ws.defcon_level <= 1:
		defcon_col = "#FF2A54"

	_budget_header_label.text = (
		"[b][color=%s]■ DEFCON %d — GLOBAL ESCALATION: %.0f%% (Nukes: %d | HEMP: %d | Orbital Rods: %d | CBRN: %d)[/color][/b]\n" % [
			defcon_col, ws.defcon_level, ws.global_escalation_score,
			ws.nuclear_detonations_count, ws.hemp_emp_strikes_count, ws.orbital_rod_strikes_count, ws.cbrn_strikes_count
		]
		+ "[b][color=#00D8FF]BLUE DEFENSE BUDGET: $%.0fM USD[/color][/b] (+$%.0fM/min Wartime Appropriation | Spent: $%.0fM | R&D Techs: %d/15)   |   [color=#FF2A54]RED BUDGET: $%.0fM (+$%.0fM/min | Techs: %d/15)[/color]\n" % [
			ws.blue_budget_musd, ws.blue_income_musd_per_min, ws.blue_budget_spent_musd, ws.blue_unlocked_techs.size(),
			ws.red_budget_musd, ws.red_income_musd_per_min, ws.red_unlocked_techs.size()
		]
		+ "[b][color=#00FF9D]★ HQ COMMAND BUNKER:[/color][/b] %s (%.0f, %.0f km) | Hull: %.0f%% | Capture: %.0f%% | Status: [color=%s]%s[/color] (Relocations: %d)\n" % [
			ws.bunker_base_name, ws.bunker_pos_km.x, ws.bunker_pos_km.z, (ws.bunker_hp / maxf(1.0, ws.bunker_max_hp)) * 100.0, ws.bunker_capture_progress, defcon_col, ws.bunker_status_code, ws.bunker_relocations_count
		]
		+ "[color=#FFD940]%s[/color]" % ws.latest_presidential_declaration
	)

	for ch in _tech_tree_list_vb.get_children():
		ch.queue_free()

	for t_node in sim_db.tech_tree_nodes:
		var slug := String(t_node.get("slug", ""))
		var branch := String(t_node.get("branch", ""))
		var tier := int(t_node.get("tier", 1))
		var dname := String(t_node.get("display_name", slug))
		var cost := float(t_node.get("cost_musd", 250.0))
		var prereq := String(t_node.get("prereq_slug", ""))
		var summary := String(t_node.get("effect_summary", ""))
		var is_unlocked := ws.blue_unlocked_techs.has(slug)
		var prereq_ok := prereq.is_empty() or ws.blue_unlocked_techs.has(prereq)

		var row_hb := HBoxContainer.new()
		row_hb.add_theme_constant_override("separation", 6)
		_tech_tree_list_vb.add_child(row_hb)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(215.0, 28.0)
		if is_unlocked:
			btn.text = "[✓ UNLOCKED] T%d $%.0fM" % [tier, cost]
			btn.disabled = true
			btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
		elif not prereq_ok:
			btn.text = "[LOCKED: REQ T%d] $%.0fM" % [tier - 1, cost]
			btn.disabled = true
		else:
			btn.text = "[UNLOCK T%d — $%.0fM]" % [tier, cost]
			btn.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
			var cap_slug := slug
			btn.pressed.connect(func():
				if sim_server != null:
					sim_server.unlock_tech(cap_slug, 1)
					_refresh_tech_tree_and_budget_view()
			)
		row_hb.add_child(btn)

		var desc_lbl := Label.new()
		desc_lbl.text = "[%s] %s — %s" % [branch.substr(0, 10), dname, summary]
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_unlocked:
			desc_lbl.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
		row_hb.add_child(desc_lbl)

	if _news_feed_rich_label != null:
		var feed_txt := "[b][color=#00FF9D]AI GEOPOLITICAL DIPLOMACY, SOVEREIGN AIRSPACE & ALLIED FINANCE (Allies B:%d / R:%d | Airspace B:%d / R:%d | Aid B:+$%.0fM / R:+$%.0fM):[/color][/b]\n" % [
			ws.blue_allied_nations_count, ws.red_allied_nations_count,
			ws.blue_airspace_treaties_count, ws.red_airspace_treaties_count,
			ws.blue_allied_aid_received_musd, ws.red_allied_aid_received_musd
		]
		for nat in ws.active_nations:
			var n_iso := String(nat.get("iso_code", "UN"))
			var n_name := String(nat.get("country_name", ""))
			var n_stat := String(nat.get("status", "NEUTRAL"))
			var n_align := float(nat.get("alignment", 0.0))
			var ncol := "#FFD940"
			if n_align >= 35.0:
				ncol = "#00D8FF"
			elif n_align <= -35.0:
				ncol = "#FF2A54"
			feed_txt += "• [color=%s][b][%s] %s[/b] — %s (%+.0f) | Grant:$%.0fM (+$%.0fM/m)[/color]\n" % [
				ncol, n_iso, n_name.substr(0, 34), n_stat, n_align, float(nat.get("grant_package_musd", 350.0)), float(nat.get("aid_musd_per_min", 20.0))
			]
		feed_txt += "\n[b][color=#00D8FF]LIVE WORLD NEWS WIRE & PRESIDENTIAL DIRECTIVES:[/color][/b]\n\n"
		for n_item in ws.world_news_feed:
			var ag := String(n_item.get("agency", "REUTERS"))
			var hl := String(n_item.get("headline", ""))
			var dc := int(n_item.get("defcon", 5))
			var col_ag := "#FFB800" if ag.find("PRESIDENT") != -1 or ag.find("STRATCOM") != -1 else "#00D8FF"
			if dc <= 2:
				col_ag = "#FF2A54"
			feed_txt += "[b][color=%s][%s // DEFCON %d][/color][/b]\n%s\n\n" % [col_ag, ag, dc, hl]
		_news_feed_rich_label.text = feed_txt


func _process(delta: float) -> void:
	if is_menu_open and _studio_video_rect != null and sim_server != null and sim_db != null and sim_db.has_method("get_news_video_frame_textures"):
		_studio_anim_time += delta
		var frames: Array = sim_db.get_news_video_frame_textures(sim_server.world_state.active_news_video_slug)
		if not frames.is_empty():
			var f_idx := int(_studio_anim_time * 6.0) % frames.size()
			_studio_video_rect.texture = frames[f_idx]


func _refresh_news_video_studio_view() -> void:
	if _studio_channels_vb == null or _studio_info_rich_label == null or sim_db == null or sim_server == null:
		return
	if sim_db.news_video_clips.is_empty():
		sim_db.reload_news_videos_manifest()

	for ch in _studio_channels_vb.get_children():
		ch.queue_free()

	for clip in sim_db.news_video_clips:
		var slug := String(clip.get("slug", ""))
		var cat := String(clip.get("category", slug))
		var net := String(clip.get("network", "GNN"))
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "● [%s] %s" % [cat, net]
		if slug == sim_server.world_state.active_news_video_slug:
			btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
		var cap_slug := slug
		btn.pressed.connect(func():
			if sim_server != null:
				sim_server.trigger_news_video_broadcast(cap_slug, "Selected from Bunker TV Broadcast Studio", false, false)
				_refresh_news_video_studio_view()
		)
		_studio_channels_vb.add_child(btn)

	var ws: WorldState = sim_server.world_state
	var frames: Array = sim_db.get_news_video_frame_textures(ws.active_news_video_slug)
	if not frames.is_empty() and _studio_video_rect != null:
		_studio_video_rect.texture = frames[0]

	_studio_info_rich_label.text = (
		"[b][color=#FF2A54]● LIVE BROADCAST // %s [DEFCON %d] (Broadcasts: %d | AI Gemini Bulletins: %d)[/color][/b]\n" % [
			ws.active_news_video_network, ws.defcon_level, ws.news_video_broadcasts_count, ws.live_ai_gemini_bulletins_count
		]
		+ "[b][color=#FFFFFF]%s[/color][/b]\n" % ws.active_news_video_headline
		+ "[color=#00D8FF]%s[/color]\n" % ws.active_news_video_sub_chyron
		+ "[color=#FFD940]Reporting Live: %s | Video Asset: res://assets/videos/news/%s.mp4 (.ogv / 24-frame Sheet)[/color]\n" % [
			ws.active_news_video_correspondent, ws.active_news_video_slug
		]
		+ "[i]%s[/i]" % ws.active_news_video_anchor_script
	)


func verify_all_news_video_assets_load() -> int:
	if sim_db == null:
		return 0
	sim_db.reload_news_videos_manifest()
	var count := 0
	for clip in sim_db.news_video_clips:
		var slug := String(clip.get("slug", ""))
		var frames: Array = sim_db.get_news_video_frame_textures(slug)
		assert(frames.size() >= 12, "Missing 24-frame filmstrip textures for war news video clip: " + slug)
		var mp4_global := ProjectSettings.globalize_path(String(clip.get("mp4_res_path", "")))
		var ogv_global := ProjectSettings.globalize_path(String(clip.get("ogv_res_path", "")))
		assert(FileAccess.file_exists(mp4_global), "Missing MP4 video file for: " + slug)
		assert(FileAccess.file_exists(ogv_global), "Missing OGV video file for: " + slug)
		count += 1
	return count


func _refresh_red_phone_and_save_view() -> void:
	if _red_phone_rich_label == null or sim_server == null or sim_server.world_state == null:
		return
	var ws: WorldState = sim_server.world_state
	var ring_status := "[color=#FF2A54]● INCOMING ENCRYPTED RED PHONE CALL RINGING![/color]" if ws.hotline_is_ringing else "[color=#00FF9D]● STANDBY (PICK UP 3D RED PHONE OR PRESS [Y])[/color]"
	_red_phone_rich_label.text = (
		"[b][color=#FF2A54]MOSCOW / BEIJING / PYONGYANG / TEHRAN DIRECT RED PHONE HOTLINE:[/color][/b] %s\n" % ring_status
		+ "Opposing Leader: [b][color=#FFD940]%s[/color][/b] (%s)\n" % [ws.hotline_leader_name, ws.hotline_leader_title]
		+ "[b]%s[/b]\n%s\n" % [ws.hotline_demand_headline, ws.hotline_demand_body]
		+ "Active Ceasefire Timer: [color=#00D8FF]%.1fs[/color] | Calls Received: %d | Negotiations Resolved: %d\n\n" % [
			ws.hotline_ceasefire_timer_sec, ws.hotline_calls_received_count, ws.hotline_negotiations_resolved_count
		]
		+ "[b][color=#00D8FF]THEATER METEOROLOGY, SOLAR TERMINATOR & SEA-STATE PHYSICS:[/color][/b]\n"
		+ "Condition: [b]%s[/b] | Cloud Cover: %.0f%% | Beaufort Sea State: [b]%d[/b] | Solar UTC: [b]%02.1f:00Z[/b] (%s)\n" % [
			ws.weather_condition_code, ws.weather_cloud_cover * 100.0, ws.sea_state_beaufort, ws.solar_hour_utc, ("NIGHT" if ws.is_night_cycle else "DAY")
		]
		+ "Multipliers — IR/EO Range: [color=#FFD940]%.2fx[/color] | 100kW Laser Range/Dwell: [color=#FFD940]%.2fx[/color] | USV Speed: [color=#FFD940]%.2fx[/color] | Sortie Rate: [color=#FFD940]%.2fx[/color]\n\n" % [
			ws.weather_ir_eo_mult, ws.weather_laser_mult, ws.weather_usv_speed_mult, ws.weather_air_sortie_mult
		]
		+ "[b][color=#00FF9D]CAMPAIGN PERSISTENCE & CUSTOM SCENARIO EXPORTER:[/color][/b]\n"
		+ "Saves Performed: %d | Loads Performed: %d | Custom Scenarios Exported: %d | Last Slot Path: %s\n\n" % [
			ws.saves_performed_count, ws.loads_performed_count, ws.custom_scenarios_exported_count, ws.last_saved_slot_path
		]
		+ "[b][color=#FFD940]HIGHWAY TRAFFIC, EVACUATION CONVOYS & MARITIME SHIPPING LANES:[/color][/b]\n"
		+ "Active Convoys/Tankers: [b]%d[/b] | Humanitarian Corridor: [b]%s[/b] (%.0fs) | Evac Completed: %d | VBSS Tankers Seized: %d\n\n" % [
			ws.convoy_count, ("ACTIVE" if ws.humanitarian_corridor_active else "STANDBY"), ws.humanitarian_corridor_timer_sec,
			ws.evacuated_convoys_completed_count, ws.maritime_tankers_interdicted_count
		]
		+ "[b][color=#FF66FF]SUBTERRANEAN TUNNEL NETWORKS, GBU-57 MOP & ROBOT DOG TUNNEL BREACH:[/color][/b]\n"
		+ "Subterranean Complexes: [b]%d[/b] | GPR Scans: %d | GBU-57 MOP Strikes: %d |Collapsed: %d | Captured by Robot Dogs: %d\n\n" % [
			ws.tunnel_complexes.size(), ws.gpr_seismic_scans_count, ws.bunker_buster_strikes_count, ws.tunnels_collapsed_count, ws.tunnels_captured_count
		]
		+ "[b][color=#00FFFF]STRATEGIC CEMA CYBER-EW, SCADA BLACKOUTS & DRONE SWARM HIJACKING:[/color][/b]\n"
		+ "Blue Grid: [b]%.0f%%[/b] vs Red Grid: [b]%.0f%%[/b] | Enemy UAVs Hijacked: [b]%d[/b] | DRFM Ghost Decoys: [b]%d[/b]\n%s\n\n" % [
			ws.blue_power_grid_pct, ws.red_power_grid_pct, ws.units_hijacked_count, ws.ghost_decoy_positions_km.size(), ws.latest_cema_status
		]
		+ "[b][color=#00FF9D]AIRBORNE DROPS, MINEFIELDS, UNDERSEA CABLES & HOMEFRONT WAR ECONOMY:[/color][/b]\n"
		+ "Airborne Drops: [b]%d[/b] | Minefields: [b]%d[/b] | Engineer Rebuilds: [b]%d[/b] | Subsea Cables Severed: [b]%d[/b] (SOSUS=%d)\n" % [
			ws.airborne_drops_executed_count, ws.minefields.size(), ws.engineer_breaches_rebuilds_count, ws.cables_sabotaged_count, ws.sosus_barriers_active_count
		]
		+ "%s" % ws.latest_homefront_status
	)


func _populate_trials_entries() -> void:
	if _trials_list_vb == null:
		return
	for c in _trials_list_vb.get_children():
		_trials_list_vb.remove_child(c)
		c.queue_free()

	var data: Dictionary = UnitTacticalTrialsSystemScript.TRIALS_DATA
	var sorted_slugs := data.keys()
	sorted_slugs.sort()

	for slug_raw in sorted_slugs:
		var slug: String = String(slug_raw)
		var trial: Dictionary = data[slug]
		var dom: String = String(trial.get("domain", "LAND"))

		# Domain filter check: "ALL", "AIR", "LAND", "SEA"
		if _trials_filter_domain != "ALL" and dom != _trials_filter_domain:
			continue

		var btn := Button.new()
		var badge := "[%s]" % dom
		var clean_title := String(trial.get("title", slug)).split(":")[0].strip_edges()
		btn.text = "%s %s" % [badge, clean_title]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		match dom:
			"AIR":
				btn.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
			"SEA":
				btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
			"LAND":
				btn.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)

		var captured_slug := slug
		btn.pressed.connect(func(): _select_trial(captured_slug))
		_trials_list_vb.add_child(btn)

	if not data.has(_selected_trial_slug) and not sorted_slugs.is_empty():
		_selected_trial_slug = String(sorted_slugs[0])
	_select_trial(_selected_trial_slug)


func _select_trial(slug: String) -> void:
	_selected_trial_slug = slug
	var trial: Dictionary = UnitTacticalTrialsSystemScript.get_trial_info(slug)
	var title: String = String(trial.get("title", slug.capitalize()))
	var dom: String = String(trial.get("domain", "LAND"))
	var opp: String = String(trial.get("opposing_threat", "Unknown Threat"))
	var opp_cat: String = String(trial.get("enemy_category", "Ennemi de théâtre"))
	var partner: String = String(trial.get("friendly_partner", "Unknown Partner"))
	var move_act: String = String(trial.get("move_act", ""))
	var fight: String = String(trial.get("fight", ""))
	var defend: String = String(trial.get("defend", ""))
	var trick: String = String(trial.get("special_trick", ""))
	var swarm: String = String(trial.get("friendly_integration", ""))

	var col_hex := "#00e5ff" if dom == "AIR" else ("#00ff66" if dom == "SEA" else "#ffd940")

	if _trials_title_label != null:
		_trials_title_label.text = "[b][color=%s][%s][/color][/b] [b][color=#ffffff]%s[/color][/b]" % [col_hex, dom, title]

	if _trials_threat_label != null:
		_trials_threat_label.text = (
			"[b][color=#ff4444]OPPOSING NEMESIS THREAT:[/color][/b] [color=#ffbbbb]%s[/color] [i](%s)[/i]\n" % [opp.replace("_", " ").to_upper(), opp_cat] +
			"[b][color=#00ccff]WINGMAN / ALLIED PARTNER:[/color][/b] [color=#bbffff]%s[/color]" % [partner.replace("_", " ").to_upper()]
		)

	if _trials_move_label != null:
		_trials_move_label.text = "[b][color=#ffd940]COMPORTEMENT & DÉPLACEMENT (Mach / Knots / Profil) :[/color][/b]\n\n%s" % move_act
	if _trials_fight_label != null:
		_trials_fight_label.text = "[b][color=#ff4444]ATTAQUE & DOCTRINE D'ENGAGEMENT (BVR, Top Attack, Salves) :[/color][/b]\n\n%s" % fight
	if _trials_defend_label != null:
		_trials_defend_label.text = "[b][color=#00ff66]DÉFENSE & CONTRE-MESURES (APS, DIRCM, Furtivité) :[/color][/b]\n\n%s" % defend
	if _trials_trick_label != null:
		_trials_trick_label.text = "[b][color=#ff66ff]ATOUT TECHNOLOGIQUE (\"SPECIAL TRICK\") :[/color][/b]\n\n%s" % trick
	if _trials_swarm_label != null:
		_trials_swarm_label.text = "[b][color=#00e5ff]INTÉGRATION ALLIÉE & INTELLIGENCE EN ESSAIM (MADL, CEC) :[/color][/b]\n\n%s" % swarm

	if _trials_all_label != null:
		_trials_all_label.text = (
			"[b][color=#ffd940]1. COMPORTEMENT & DÉPLACEMENT :[/color][/b]\n%s\n\n" % move_act +
			"[b][color=#ff4444]2. ATTAQUE & DOCTRINE :[/color][/b]\n%s\n\n" % fight +
			"[b][color=#00ff66]3. DÉFENSE & CONTRE-MESURES :[/color][/b]\n%s\n\n" % defend +
			"[b][color=#ff66ff]4. ATOUT TECHNOLOGIQUE (\"SPECIAL TRICK\") :[/color][/b]\n%s\n\n" % trick +
			"[b][color=#00e5ff]5. INTÉGRATION ALLIÉE & ESSAIM :[/color][/b]\n%s" % swarm
		)

	if _trials_launch_btn != null:
		_trials_launch_btn.text = "⚔ [LANCER L'ÉPREUVE TACTIQUE DANS L'ARÈNE : %s]" % slug.replace("_", " ").to_upper()


func _set_trials_domain_filter(domain: String) -> void:
	_trials_filter_domain = domain
	_populate_trials_entries()


func _refresh_trials_view() -> void:
	if _trials_list_vb != null and _trials_list_vb.get_child_count() == 0:
		_populate_trials_entries()
	else:
		_select_trial(_selected_trial_slug)


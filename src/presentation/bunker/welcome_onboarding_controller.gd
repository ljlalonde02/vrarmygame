class_name WelcomeOnboardingController
extends CanvasLayer
## First-Time Commander Welcome & Onboarding Briefing Dialog.
## Provides an immediate, clear, high-contrast tactical briefing for new users on Desktop & VR:
## - Explains the 3D Holographic Sand Table concepts (500km macro to 15km tactical valleys)
## - Lists Desktop keyboard/mouse controls & OpenXR VR gestures
## - Offers 1-click access to the Interactive 5-Step Bootcamp Tutorial, Direct War Table Play,
##   Global Campaign Theaters, or the Wikipedia Armor & Munitions Field Manual.

signal welcome_dismissed()
signal start_tutorial_requested()
signal open_campaign_requested()
signal open_manual_requested()

var modal_root: PanelContainer = null
var is_visible: bool = false

var _title_label: Label = null
var _briefing_text: RichTextLabel = null
var _controls_text: RichTextLabel = null
var _btn_tutorial: Button = null
var _btn_play: Button = null
var _btn_campaign: Button = null
var _btn_manual: Button = null
var _chk_dont_show: CheckBox = null

var radio_synth_ref: Node = null


func _ready() -> void:
	if modal_root != null:
		return
	layer = 25
	_build_welcome_ui()
	set_visible_briefing(false)


func setup(p_radio_synth: Node = null) -> void:
	radio_synth_ref = p_radio_synth


func set_visible_briefing(vis: bool) -> void:
	is_visible = vis
	if modal_root != null:
		modal_root.visible = vis
	visible = vis
	if vis:
		var p := get_parent()
		if p != null:
			var tc: Variant = p.get("tutorial_controller")
			if tc != null and tc.has_method("stop_bootcamp") and bool(tc.get("is_active")):
				tc.stop_bootcamp()
			var mm: Variant = p.get("main_menu")
			if mm != null and mm.has_method("set_menu_visible") and bool(mm.get("is_menu_open")):
				mm.set_menu_visible(false)
		if radio_synth_ref != null and radio_synth_ref.has_method("play_tactical_posture_actuate"):
			radio_synth_ref.call("play_tactical_posture_actuate")


func is_briefing_open() -> bool:
	return is_visible


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var vp := get_viewport()
		match event.keycode:
			KEY_ESCAPE, KEY_ENTER, KEY_SPACE:
				set_visible_briefing(false)
				welcome_dismissed.emit()
				if vp != null:
					vp.set_input_as_handled()
			KEY_H:
				set_visible_briefing(false)
				start_tutorial_requested.emit()
				if vp != null:
					vp.set_input_as_handled()
			KEY_P:
				set_visible_briefing(false)
				open_campaign_requested.emit()
				if vp != null:
					vp.set_input_as_handled()


func _build_welcome_ui() -> void:
	var theme := TacticalTheme.create_theme()

	modal_root = PanelContainer.new()
	modal_root.name = "WelcomeBriefingModal"
	modal_root.theme = theme
	modal_root.anchor_left = 0.5
	modal_root.anchor_right = 0.5
	modal_root.anchor_top = 0.5
	modal_root.anchor_bottom = 0.5
	modal_root.offset_left = -580.0
	modal_root.offset_right = 580.0
	modal_root.offset_top = -360.0
	modal_root.offset_bottom = 360.0
	add_child(modal_root)

	var main_vb := VBoxContainer.new()
	main_vb.add_theme_constant_override("separation", 10)
	modal_root.add_child(main_vb)

	# --- 1. Top Header Banner ---
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 12)
	main_vb.add_child(top_hb)

	var status_dot := Label.new()
	status_dot.text = "● ONLINE"
	status_dot.add_theme_font_size_override("font_size", 13)
	status_dot.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	top_hb.add_child(status_dot)

	_title_label = Label.new()
	_title_label.text = "NORAD C4ISR STRATEGIC DEFENSE BUNKER // DEFCON 2028 WARGAME"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	top_hb.add_child(_title_label)

	var close_x := Button.new()
	close_x.text = "[ X CLOSE ]"
	close_x.add_theme_font_size_override("font_size", 11)
	close_x.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	close_x.pressed.connect(func():
		set_visible_briefing(false)
		welcome_dismissed.emit()
	)
	top_hb.add_child(close_x)

	# Subtitle
	var sub_lbl := Label.new()
	sub_lbl.text = "SUPREME THEATER COMMANDER ONBOARDING & OPERATIONAL BRIEFING"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	main_vb.add_child(sub_lbl)

	var sep := HSeparator.new()
	main_vb.add_child(sep)

	# --- 2. Two-Column Briefing Grid ---
	var cols_hb := HBoxContainer.new()
	cols_hb.add_theme_constant_override("separation", 16)
	cols_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(cols_hb)

	# Left Column: Operational Concept & Environment
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 6)
	cols_hb.add_child(left_vb)

	var left_hdr := Label.new()
	left_hdr.text = "1. OPERATIONAL DOCTRINE & THEATER"
	left_hdr.add_theme_font_size_override("font_size", 12)
	left_hdr.add_theme_color_override("font_color", TacticalTheme.COL_CONTOUR_EMERALD)
	left_vb.add_child(left_hdr)

	_briefing_text = RichTextLabel.new()
	_briefing_text.bbcode_enabled = true
	_briefing_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_briefing_text.add_theme_font_size_override("normal_font_size", 11)
	_briefing_text.text = """[color=#8fe2ff]Welcome to the Strategic Command Facility, Commander.[/color]

You are standing in an underground brutalist command bunker overlooking a [b]2,000 km × 2,000 km[/b] real-time multi-domain theater on a 3D holographic sand table.

[b]KEY WARFARE MECHANICS:[/b]
• [b]Multi-Domain Battle:[/b] Air squadrons (F-35, J-20), carrier strike groups (CVN-78, Type 055), and mechanized spearheads (M1A2, Robot Dogs).
• [b]Realistic Ballistics:[/b] 155mm shells, cruise missiles, hypersonic waveriders, and ballistic missiles track true Mach-scaled parabolic flight curves.
• [b]Electronic Warfare & CBRN:[/b] Deploy AN/ALE-50 towed decoys, dispense chaff corridors, activate GPS denial bubbles, and counter chemical/HEMP hazards.
• [b]DEFCON Escalation:[/b] Starts at DEFCON 5 (Peace). As battles escalate, sirens sound and alert levels plunge toward DEFCON 1 (Full Nuclear Release)."""
	left_vb.add_child(_briefing_text)

	# Right Column: Controls & Ergonomics
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)
	cols_hb.add_child(right_vb)

	var right_hdr := Label.new()
	right_hdr.text = "2. COMMAND CONTROLS (DESKTOP & OPENXR VR)"
	right_hdr.add_theme_font_size_override("font_size", 12)
	right_hdr.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	right_vb.add_child(right_hdr)

	_controls_text = RichTextLabel.new()
	_controls_text.bbcode_enabled = true
	_controls_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_controls_text.add_theme_font_size_override("normal_font_size", 11)
	_controls_text.text = """[b]DESKTOP MOUSE & KEYBOARD:[/b]
• [color=#ffd700]Left-Click Drag:[/color] Pan across the holographic war table
• [color=#ffd700]Mouse Scroll Wheel:[/color] Zoom from 500km macro to 15km mountain valleys
• [color=#ffd700]Right-Click Drag / Mid-Click:[/color] Rotate 3D perspective around the table
• [color=#ffd700]Left-Click Token:[/color] Select unit & view Wikipedia photo intelligence
• [color=#ffd700]Right-Click Ground:[/color] Issue movement orders or 3D strike vectors
• [color=#ffd700]Spacebar:[/color] Execute Alpha Strike salvo • [color=#ffd700]H:[/color] Bootcamp Tutorial
• [color=#ffd700]ESC:[/color] Open Command Menu • [color=#ffd700]F12:[/color] Cycle Visual Graphic Styles

[b]OPENXR VR HEADSET (META QUEST 3 / PCVR):[/b]
• Look naturally around the full underground bunker room
• Aim laser pointers or reach out with 3D tactical gauntlets
• Pull trigger to select units or grab and rotate the holographic table
• Two-hand pinch and spread to zoom table scale dynamically
• Push switches and slam the red Alpha Strike button on the front tactile console!"""
	right_vb.add_child(_controls_text)

	var sep2 := HSeparator.new()
	main_vb.add_child(sep2)

	# --- 3. Bottom Action Buttons Bar ---
	var btns_hb := HBoxContainer.new()
	btns_hb.add_theme_constant_override("separation", 10)
	main_vb.add_child(btns_hb)

	_btn_tutorial = Button.new()
	_btn_tutorial.text = "★ START BOOTCAMP TUTORIAL (5 GUIDED LESSONS) [H]"
	_btn_tutorial.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_tutorial.add_theme_font_size_override("font_size", 12)
	_btn_tutorial.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	_btn_tutorial.pressed.connect(func():
		set_visible_briefing(false)
		start_tutorial_requested.emit()
	)
	btns_hb.add_child(_btn_tutorial)

	_btn_play = Button.new()
	_btn_play.text = "🚀 ENTER WAR ROOM (OP PACIFIC SHIELD)"
	_btn_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_play.add_theme_font_size_override("font_size", 12)
	_btn_play.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	_btn_play.pressed.connect(func():
		set_visible_briefing(false)
		welcome_dismissed.emit()
	)
	btns_hb.add_child(_btn_play)

	_btn_campaign = Button.new()
	_btn_campaign.text = "🌐 CAMPAIGN & THEATERS [P]"
	_btn_campaign.add_theme_font_size_override("font_size", 12)
	_btn_campaign.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	_btn_campaign.pressed.connect(func():
		set_visible_briefing(false)
		open_campaign_requested.emit()
	)
	btns_hb.add_child(_btn_campaign)

	_btn_manual = Button.new()
	_btn_manual.text = "📖 FIELD MANUAL & SPECS"
	_btn_manual.add_theme_font_size_override("font_size", 12)
	_btn_manual.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
	_btn_manual.pressed.connect(func():
		set_visible_briefing(false)
		open_manual_requested.emit()
	)
	btns_hb.add_child(_btn_manual)

	# --- 4. Sub-footer with Don't Show Again & Tip ---
	var sub_hb := HBoxContainer.new()
	sub_hb.add_theme_constant_override("separation", 10)
	main_vb.add_child(sub_hb)

	_chk_dont_show = CheckBox.new()
	_chk_dont_show.text = "Remember commander authorization (you can reopen this briefing anytime via [?] BRIEFING top bar button)"
	_chk_dont_show.add_theme_font_size_override("font_size", 10)
	sub_hb.add_child(_chk_dont_show)

	var foot_spacer := Control.new()
	foot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_hb.add_child(foot_spacer)

	var ver_lbl := Label.new()
	ver_lbl.text = "v17.0 MIL-SPEC Forward Mobile"
	ver_lbl.add_theme_font_size_override("font_size", 10)
	ver_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.65))
	sub_hb.add_child(ver_lbl)

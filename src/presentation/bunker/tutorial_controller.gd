class_name TutorialController
extends CanvasLayer
## Live Event-Driven 5-Step Bunker Boot-Camp Tutorial Coach (Section 13.3 of ARCHITECTURE.md).
## Reads `tutorial_steps` from `SimDB` (`data/wargame.db`), displays a non-intrusive holographic
## Instructor HUD Banner (`MAGIC 1-1`, `HOUND ACTUAL`, `INTEL DIRECTOR`, `STRIKE MARSHAL`),
## projects a pulsing 3D holographic target beacon onto the War Table / Tactile Console,
## and automatically advances steps when the player performs each action!

signal tutorial_step_changed(step_index: int, step_slug: String)
signal tutorial_completed()

var sim_db: Node = null
var signal_bus: Node = null
var command_bus: Node = null
var war_table: Node3D = null

var steps: Array[Dictionary] = []
var current_step_index: int = 0
var is_active: bool = false
var is_completed: bool = false

var banner_panel: PanelContainer
var step_badge_label: Label
var callsign_label: Label
var title_label: Label
var prompt_label: RichTextLabel
var reward_label: Label
var progress_bar: ProgressBar
var action_hint_btn: Button
var next_btn: Button
var close_btn: Button

var beacon_3d: MeshInstance3D = null
var _pulse_time: float = 0.0


func _ready() -> void:
	if banner_panel != null:
		return
	layer = 18
	_build_ui()
	_build_3d_beacon()


func setup(p_sim_db: Node, p_sig_bus: Node, p_cmd_bus: Node, p_war_table: Node3D) -> void:
	sim_db = p_sim_db
	signal_bus = p_sig_bus
	command_bus = p_cmd_bus
	war_table = p_war_table

	if sim_db != null:
		sim_db.load_database()
		steps = sim_db.tutorial_steps.duplicate(true)

	if signal_bus != null:
		if not signal_bus.master_iads_toggled.is_connected(_on_master_iads_toggled):
			signal_bus.master_iads_toggled.connect(_on_master_iads_toggled)
		if not signal_bus.unmanned_deployed.is_connected(_on_unmanned_deployed):
			signal_bus.unmanned_deployed.connect(_on_unmanned_deployed)
		if not signal_bus.recon_photo_mode_toggled.is_connected(_on_recon_photo_toggled):
			signal_bus.recon_photo_mode_toggled.connect(_on_recon_photo_toggled)
		if not signal_bus.unit_selected.is_connected(_on_unit_selected):
			signal_bus.unit_selected.connect(_on_unit_selected)
		if not signal_bus.alpha_strike_committed.is_connected(_on_alpha_strike_committed):
			signal_bus.alpha_strike_committed.connect(_on_alpha_strike_committed)
		if not signal_bus.salvo_launched.is_connected(_on_salvo_launched):
			signal_bus.salvo_launched.connect(_on_salvo_launched)

	if war_table != null and beacon_3d != null and beacon_3d.get_parent() == null:
		war_table.add_child(beacon_3d)

	_refresh_step_ui()


func start_bootcamp(from_beginning: bool = true) -> void:
	if steps.is_empty() and sim_db != null:
		steps = sim_db.tutorial_steps.duplicate(true)
	if from_beginning or is_completed:
		current_step_index = 0
		is_completed = false
	# Enforce mutual exclusivity with Story Campaign & Main Menu modal
	var p := get_parent()
	if p != null:
		var sd: Variant = p.get("story_director")
		if sd != null and sd.has_method("stop_story_campaign"):
			sd.stop_story_campaign()
		var mm: Variant = p.get("main_menu")
		if mm != null and mm.has_method("set_menu_visible") and bool(mm.get("is_menu_open")):
			mm.set_menu_visible(false)
	is_active = true
	visible = true
	if beacon_3d != null:
		beacon_3d.visible = true
	_refresh_step_ui()


func stop_bootcamp() -> void:
	is_active = false
	visible = false
	if beacon_3d != null:
		beacon_3d.visible = false


func toggle_bootcamp() -> void:
	if is_active:
		stop_bootcamp()
	else:
		start_bootcamp(false)


func _process(delta: float) -> void:
	if not is_active:
		return
	_pulse_time += delta * 3.5

	# Check Step 1 live completion condition: War Table zoomed into tactical view (>= 4.0x)
	if not is_completed and current_step_index < steps.size():
		var cond := String(steps[current_step_index].get("completion_signal_or_cmd", ""))
		if cond == "ZOOM_TACTICAL_REACHED" and war_table != null and float(war_table.get("zoom_scale")) >= 3.8:
			notify_event("ZOOM_TACTICAL_REACHED")

	# Animate 3D Holographic Beacon on the War Table / Console
	if beacon_3d != null and beacon_3d.visible:
		var s := 1.0 + 0.18 * sin(_pulse_time)
		beacon_3d.scale = Vector3(s, 1.0, s)
		beacon_3d.rotation.y += delta * 1.4


func notify_event(event_code: String) -> void:
	if not is_active or is_completed or current_step_index >= steps.size():
		return
	var expected := String(steps[current_step_index].get("completion_signal_or_cmd", ""))
	if expected == event_code:
		advance_step()


func advance_step() -> void:
	if steps.is_empty():
		return
	if current_step_index + 1 < steps.size():
		current_step_index += 1
		_refresh_step_ui()
		tutorial_step_changed.emit(current_step_index, String(steps[current_step_index].get("slug", "")))
	else:
		is_completed = true
		_refresh_step_ui()
		tutorial_completed.emit()


func prev_step() -> void:
	if current_step_index > 0:
		is_completed = false
		current_step_index -= 1
		_refresh_step_ui()


func perform_current_step_demo_action() -> void:
	if is_completed or current_step_index >= steps.size():
		stop_bootcamp()
		return
	var cond := String(steps[current_step_index].get("completion_signal_or_cmd", ""))
	match cond:
		"ZOOM_TACTICAL_REACHED":
			if war_table != null and war_table.has_method("set_zoom_and_pan"):
				war_table.call("set_zoom_and_pan", 5.5, Vector2.ZERO)
			notify_event("ZOOM_TACTICAL_REACHED")
		"CMD_SET_MASTER_IADS":
			if command_bus != null:
				command_bus.enqueue_set_master_iads(1, true)
			notify_event("CMD_SET_MASTER_IADS")
		"CMD_DEPLOY_UNMANNED_SUBUNIT":
			if command_bus != null:
				command_bus.enqueue_deploy_unmanned([1, 2, 3, 4, 5, 6, 7, 8])
			notify_event("CMD_DEPLOY_UNMANNED_SUBUNIT")
		"RECON_PHOTO_TOGGLED":
			if signal_bus != null:
				signal_bus.recon_photo_mode_toggled.emit(true)
			notify_event("RECON_PHOTO_TOGGLED")
		"CMD_COMMIT_ALPHA_STRIKE":
			if command_bus != null:
				command_bus.enqueue_commit_alpha_strike(1)
			notify_event("CMD_COMMIT_ALPHA_STRIKE")


func _on_master_iads_toggled(_faction: int, _enabled: bool) -> void:
	notify_event("CMD_SET_MASTER_IADS")


func _on_unmanned_deployed(_parent_id: int, _child_id: int, _sub_pid: int, _pos: Vector3) -> void:
	notify_event("CMD_DEPLOY_UNMANNED_SUBUNIT")


func _on_recon_photo_toggled(_enabled: bool) -> void:
	notify_event("RECON_PHOTO_TOGGLED")


func _on_unit_selected(_uid: int, _pid: int, _fac: int) -> void:
	notify_event("RECON_PHOTO_TOGGLED")


func _on_alpha_strike_committed(_faction: int, _count: int) -> void:
	notify_event("CMD_COMMIT_ALPHA_STRIKE")


func _on_salvo_launched(_att_id: int, _tgt_id: int, _wid: int, _pos: Vector3) -> void:
	notify_event("CMD_COMMIT_ALPHA_STRIKE")


func _refresh_step_ui() -> void:
	if banner_panel == null:
		return
	if steps.is_empty():
		title_label.text = "BOOT-CAMP TUTORIAL"
		return

	if is_completed:
		step_badge_label.text = "BOOT-CAMP COMPLETE (5 / 5)"
		callsign_label.text = "C4ISR COMMAND ACADEMY"
		title_label.text = "ALL 5 TACTICAL QUALIFICATION LESSONS COMPLETED!"
		prompt_label.text = "You are now qualified on Semantic Echelon Zoom, 6-Spectrum Sensor Fusion, Quadruped Robot Dog & Fiber-Optic FPV Deployment, Real Wikipedia Recon Dossiers, and Coordinated Alpha Strikes."
		reward_label.text = "TIP: Press [1]-[6] for Unit Tactical Orders, [7]-[0] for Space/Cyber/PsyOp/CBRN Deterrence, or [M] for Campaign & Field Manual."
		progress_bar.value = 100.0
		action_hint_btn.text = "FINISH BOOT-CAMP"
		if beacon_3d != null:
			beacon_3d.visible = false
		return

	var st: Dictionary = steps[current_step_index]
	var total := steps.size()
	var order_num := int(st.get("step_order", current_step_index + 1))
	step_badge_label.text = "BOOT-CAMP STEP %d / %d" % [order_num, total]
	callsign_label.text = String(st.get("instructor_callsign", "MAGIC 1-1"))
	title_label.text = String(st.get("title", "Lesson"))
	prompt_label.text = String(st.get("prompt_text", st.get("prompt_key", "")))
	reward_label.text = "DOCTRINE TIP: " + String(st.get("reward_tip", ""))
	progress_bar.value = float(current_step_index) / float(max(1, total)) * 100.0
	action_hint_btn.text = "EXECUTE LESSON ACTION NOW"

	_update_beacon_position(String(st.get("ui_highlight_target", "WAR_TABLE_ZOOM")))


func _update_beacon_position(target_code: String) -> void:
	if beacon_3d == null:
		return
	beacon_3d.visible = is_active and not is_completed
	match target_code:
		"WAR_TABLE_ZOOM":
			beacon_3d.position = Vector3(0.0, 0.09, 0.0)
		"CONSOLE_MASTER_IADS":
			beacon_3d.position = Vector3(-0.78, 0.05, 1.12)
		"CONSOLE_DEPLOY_UNMANNED":
			beacon_3d.position = Vector3(0.0, 0.05, 1.12)
		"CONSOLE_RECON_PHOTO":
			beacon_3d.position = Vector3(0.38, 0.05, 1.12)
		"CONSOLE_ALPHA_STRIKE":
			beacon_3d.position = Vector3(0.78, 0.05, 1.12)
		_:
			beacon_3d.position = Vector3(0.0, 0.09, 0.0)


func _build_3d_beacon() -> void:
	beacon_3d = MeshInstance3D.new()
	beacon_3d.name = "TutorialTargetBeacon3D"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.08
	torus.outer_radius = 0.115
	torus.rings = 24
	torus.ring_segments = 12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.78, 0.10, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = mat
	beacon_3d.mesh = torus
	beacon_3d.visible = false


func _build_ui() -> void:
	visible = false
	var theme := TacticalTheme.create_theme()
	banner_panel = PanelContainer.new()
	banner_panel.theme = theme
	banner_panel.clip_contents = true
	banner_panel.anchor_left = 0.20
	banner_panel.anchor_right = 0.78
	banner_panel.anchor_top = 0.055
	banner_panel.anchor_bottom = 0.23
	add_child(banner_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	banner_panel.add_child(vbox)

	var header_hb := HBoxContainer.new()
	header_hb.add_theme_constant_override("separation", 12)
	vbox.add_child(header_hb)

	step_badge_label = Label.new()
	step_badge_label.text = "BOOT-CAMP STEP 1 / 5"
	step_badge_label.add_theme_font_size_override("font_size", 12)
	step_badge_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	header_hb.add_child(step_badge_label)

	callsign_label = Label.new()
	callsign_label.text = "MAGIC 1-1 (AWACS INSTRUCTOR)"
	callsign_label.add_theme_font_size_override("font_size", 12)
	callsign_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	header_hb.add_child(callsign_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hb.add_child(spacer)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(140, 14)
	progress_bar.max_value = 100.0
	progress_bar.value = 20.0
	header_hb.add_child(progress_bar)

	title_label = Label.new()
	title_label.text = "Lesson 1: Holographic Table & Semantic Echelon Zoom"
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)

	prompt_label = RichTextLabel.new()
	prompt_label.bbcode_enabled = true
	prompt_label.fit_content = false
	prompt_label.scroll_active = false
	prompt_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prompt_label.custom_minimum_size = Vector2(0, 44)
	prompt_label.add_theme_font_size_override("normal_font_size", 12)
	prompt_label.add_theme_color_override("default_color", Color.WHITE)
	vbox.add_child(prompt_label)

	var footer_hb := HBoxContainer.new()
	footer_hb.add_theme_constant_override("separation", 8)
	vbox.add_child(footer_hb)

	reward_label = Label.new()
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.clip_text = true
	reward_label.add_theme_font_size_override("font_size", 11)
	reward_label.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	footer_hb.add_child(reward_label)

	var prev_btn := Button.new()
	prev_btn.text = "< PREV"
	prev_btn.pressed.connect(prev_step)
	footer_hb.add_child(prev_btn)

	action_hint_btn = Button.new()
	action_hint_btn.text = "EXECUTE LESSON ACTION NOW"
	action_hint_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	action_hint_btn.pressed.connect(perform_current_step_demo_action)
	footer_hb.add_child(action_hint_btn)

	next_btn = Button.new()
	next_btn.text = "SKIP / NEXT >"
	next_btn.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	next_btn.pressed.connect(advance_step)
	footer_hb.add_child(next_btn)

	close_btn = Button.new()
	close_btn.text = "HIDE [H]"
	close_btn.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	close_btn.pressed.connect(stop_bootcamp)
	footer_hb.add_child(close_btn)

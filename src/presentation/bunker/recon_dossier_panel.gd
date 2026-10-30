class_name ReconDossierPanel
extends CanvasLayer
## Diegetic & HUD Wikipedia Recognition Dossier + Unit AI & Military Mission Order Panel.
## Displays:
## - Real downloaded Wikipedia photograph of the selected platform + Primary & Secondary Weapons
## - Live Unit Situational Awareness & Autonomous AI State (`PATROL/CAP`, `BVR INTERCEPT`, `NOE SEAD MASKING`, `EVASIVE JINK`, `ROBOT DOG VANGUARD`)
## - 6 Interactive Military Mission Order & Unit Ability Buttons (`[1]`–`[6]`):
##     [1] ASSAULT / SEIZE   [2] SEAD / SUPPRESS   [3] CAP / OVERWATCH
##     [4] FIRE SALVO (TOT)  [5] 3D ALT / SPRINT   [6] EMCON / UNPACK DOGS

const UnitTacticalAISystemScript := preload("res://src/sim_core/systems/unit_tactical_ai_system.gd")
const GlobalOrbatSystemScript := preload("res://src/sim_core/systems/global_orbat_system.gd")

var sim_db: Node = null
var sim_server: Node = null
var signal_bus: Node = null
var command_bus: Node = null

var current_unit_id: int = -1
var selected_unit_ids: Array[int] = []
var current_platform_id: int = 1
var flir_green_tint_enabled: bool = false

var root_panel: PanelContainer = null
var title_label: Label = null
var specs_badge_label: Label = null
var hierarchy_org_label: Label = null
var ai_status_label: Label = null
var platform_photo_rect: TextureRect = null
var weapon1_photo_rect: TextureRect = null
var weapon2_photo_rect: TextureRect = null
var weapon1_label: Label = null
var weapon2_label: Label = null
var wiki_summary_label: RichTextLabel = null
var telemetry_status_label: Label = null
var tint_toggle_btn: Button = null


func _ready() -> void:
	if root_panel != null:
		return
	layer = 5
	_build_dossier_ui()


func setup(p_sim_db: Node, p_sim_server: Node, p_signal_bus: Node, p_cmd_bus: Node = null) -> void:
	sim_db = p_sim_db
	sim_server = p_sim_server
	signal_bus = p_signal_bus
	command_bus = p_cmd_bus if p_cmd_bus != null else (sim_server.command_bus_ref if sim_server != null else null)
	if signal_bus != null and not signal_bus.unit_selected.is_connected(_on_unit_selected):
		signal_bus.unit_selected.connect(_on_unit_selected)
	inspect_platform_by_slug("f_35a_lightning")


func _process(_delta: float) -> void:
	if current_unit_id >= 0 and sim_server != null and sim_db != null:
		var st: WorldState = sim_server.world_state
		if current_unit_id < st.unit_count and st.unit_active[current_unit_id] == 1:
			var pid: int = st.unit_platform_id[current_unit_id]
			var p_def: Dictionary = sim_db.get_platform(pid)
			var dom := String(p_def.get("domain", "LAND"))
			var ai_st: int = st.unit_ai_state[current_unit_id]
			var thr: float = st.unit_threat_level[current_unit_id]
			var ab: int = st.unit_afterburner[current_unit_id]
			var alt_m: float = st.unit_pos[current_unit_id].y
			if ai_status_label != null:
				ai_status_label.text = UnitTacticalAISystemScript.get_ai_state_description(ai_st, thr, ab, alt_m, dom)
			if telemetry_status_label != null:
				var hp_pct := (st.unit_hp[current_unit_id] / maxf(1.0, st.unit_max_hp[current_unit_id])) * 100.0
				var rad_str := "RADAR ON" if st.unit_radar_active[current_unit_id] == 1 else "EMCON SILENT"
				telemetry_status_label.text = "HP: %.0f%% | %s | AMMO: %d/%d | FUEL: %.0fkm | BAYS: %d" % [
					hp_pct, rad_str, st.unit_ammo_1[current_unit_id], st.unit_ammo_2[current_unit_id],
					st.unit_fuel_km[current_unit_id], st.unit_unmanned_bays[current_unit_id]
				]


func _build_dossier_ui() -> void:
	var theme := TacticalTheme.create_theme()

	root_panel = PanelContainer.new()
	root_panel.name = "ReconDossierCard"
	root_panel.theme = theme
	root_panel.custom_minimum_size = Vector2(330.0, 620.0)
	root_panel.clip_contents = true
	root_panel.anchor_left = 1.0
	root_panel.anchor_right = 1.0
	root_panel.anchor_top = 0.0
	root_panel.anchor_bottom = 0.0
	root_panel.offset_left = -342.0
	root_panel.offset_right = -12.0
	root_panel.offset_top = 50.0
	root_panel.offset_bottom = 685.0
	add_child(root_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	root_panel.add_child(vbox)

	# Header Bar
	var header_hb := HBoxContainer.new()
	header_hb.add_theme_constant_override("separation", 4)
	vbox.add_child(header_hb)

	title_label = Label.new()
	title_label.text = "[WIKIPEDIA RECON DOSSIER]"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	header_hb.add_child(title_label)

	tint_toggle_btn = Button.new()
	tint_toggle_btn.text = "FLIR: OFF"
	tint_toggle_btn.add_theme_font_size_override("font_size", 10)
	tint_toggle_btn.pressed.connect(toggle_flir_tint)
	header_hb.add_child(tint_toggle_btn)

	# Framed Real Wikipedia Platform Photograph
	var photo_frame := PanelContainer.new()
	photo_frame.add_theme_stylebox_override("panel", TacticalTheme.create_panel_style(TacticalTheme.COL_NATO_BLUE, Color(0.02, 0.03, 0.05, 1.0), 2))
	vbox.add_child(photo_frame)

	platform_photo_rect = TextureRect.new()
	platform_photo_rect.custom_minimum_size = Vector2(304.0, 130.0)
	platform_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	platform_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo_frame.add_child(platform_photo_rect)

	specs_badge_label = Label.new()
	specs_badge_label.text = "RCS: 0.0015 m² | SPD: 1060 kts | RAD: 1090 km | $320.0M"
	specs_badge_label.clip_text = true
	specs_badge_label.add_theme_font_size_override("font_size", 10)
	specs_badge_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	vbox.add_child(specs_badge_label)

	ai_status_label = Label.new()
	ai_status_label.text = "AI: PATROL / CAP OVERWATCH | THREAT: 0% | CRUISE"
	ai_status_label.clip_text = true
	ai_status_label.add_theme_font_size_override("font_size", 10)
	ai_status_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	vbox.add_child(ai_status_label)

	telemetry_status_label = Label.new()
	telemetry_status_label.text = "AUTONOMY: MANNED | HP: 100% | UNMANNED BAYS: 0"
	telemetry_status_label.clip_text = true
	telemetry_status_label.add_theme_font_size_override("font_size", 10)
	telemetry_status_label.add_theme_color_override("font_color", TacticalTheme.COL_TEXT_PRIMARY)
	vbox.add_child(telemetry_status_label)

	hierarchy_org_label = Label.new()
	hierarchy_org_label.text = "ORG: COMPANY [0] -> BATTALION [1] -> BRIGADE [2]"
	hierarchy_org_label.clip_text = true
	hierarchy_org_label.add_theme_font_size_override("font_size", 10)
	hierarchy_org_label.add_theme_color_override("font_color", TacticalTheme.COL_CONTOUR_EMERALD)
	vbox.add_child(hierarchy_org_label)

	var ech_sel_hb := HBoxContainer.new()
	ech_sel_hb.add_theme_constant_override("separation", 3)
	vbox.add_child(ech_sel_hb)

	var btn_sel_bn := Button.new()
	btn_sel_bn.text = "[B] BATTALION"
	btn_sel_bn.add_theme_font_size_override("font_size", 10)
	btn_sel_bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sel_bn.pressed.connect(func(): select_parent_battalion())
	ech_sel_hb.add_child(btn_sel_bn)

	var btn_sel_bde := Button.new()
	btn_sel_bde.text = "[V] BRIGADE"
	btn_sel_bde.add_theme_font_size_override("font_size", 10)
	btn_sel_bde.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sel_bde.pressed.connect(func(): select_parent_brigade())
	ech_sel_hb.add_child(btn_sel_bde)

	var btn_sel_cos := Button.new()
	btn_sel_cos.text = "SUB-UNITS"
	btn_sel_cos.add_theme_font_size_override("font_size", 10)
	btn_sel_cos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sel_cos.pressed.connect(func(): select_subordinate_companies())
	ech_sel_hb.add_child(btn_sel_cos)

	# ====================================================================
	# 6 INTERACTIVE MILITARY MISSION ORDERS & UNIT ABILITIES (`[1]` - `[6]`)
	# ====================================================================
	var orders_hdr := Label.new()
	orders_hdr.text = "UNIT MISSION ORDERS & TACTICAL ABILITIES (KEYS 1-6):"
	orders_hdr.clip_text = true
	orders_hdr.add_theme_font_size_override("font_size", 10)
	orders_hdr.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	vbox.add_child(orders_hdr)

	var grid_orders := GridContainer.new()
	grid_orders.columns = 3
	grid_orders.add_theme_constant_override("h_separation", 3)
	grid_orders.add_theme_constant_override("v_separation", 3)
	vbox.add_child(grid_orders)

	var order_defs := [
		["[1] ASSAULT", "ORDER_ASSAULT_SEIZE"],
		["[2] SEAD/NOE", "ORDER_SEAD_SUPPRESS"],
		["[3] CAP/WATCH", "ORDER_CAP_OVERWATCH"],
		["[4] FIRE TOT", "ORDER_PRECISION_FIRE_TOT"],
		["[5] ALT/SPD", "CYCLE_ALTITUDE"],
		["[6] EMCON/DOG", "DEPLOY_SUBUNIT"],
	]
	for od in order_defs:
		var obtn := Button.new()
		obtn.text = String(od[0])
		obtn.add_theme_font_size_override("font_size", 10)
		obtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var code := String(od[1])
		obtn.pressed.connect(func(): issue_selected_unit_ability(code))
		grid_orders.add_child(obtn)

	# Wikipedia Encyclopedia Summary Extract
	wiki_summary_label = RichTextLabel.new()
	wiki_summary_label.custom_minimum_size = Vector2(304.0, 84.0)
	wiki_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wiki_summary_label.bbcode_enabled = true
	vbox.add_child(wiki_summary_label)

	# Equipped Weapons Real Wikipedia Photographs Row
	var w_header := Label.new()
	w_header.text = "EQUIPPED MUNITIONS (WIKIPEDIA RECON PHOTOS):"
	w_header.clip_text = true
	w_header.add_theme_font_size_override("font_size", 10)
	w_header.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	vbox.add_child(w_header)

	var weapons_hb := HBoxContainer.new()
	weapons_hb.add_theme_constant_override("separation", 6)
	vbox.add_child(weapons_hb)

	var w1_vb := VBoxContainer.new()
	w1_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapons_hb.add_child(w1_vb)

	weapon1_photo_rect = TextureRect.new()
	weapon1_photo_rect.custom_minimum_size = Vector2(144.0, 58.0)
	weapon1_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon1_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	w1_vb.add_child(weapon1_photo_rect)

	weapon1_label = Label.new()
	weapon1_label.text = "WPN 1"
	weapon1_label.add_theme_font_size_override("font_size", 10)
	weapon1_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w1_vb.add_child(weapon1_label)

	var w2_vb := VBoxContainer.new()
	w2_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapons_hb.add_child(w2_vb)

	weapon2_photo_rect = TextureRect.new()
	weapon2_photo_rect.custom_minimum_size = Vector2(144.0, 58.0)
	weapon2_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon2_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	w2_vb.add_child(weapon2_photo_rect)

	weapon2_label = Label.new()
	weapon2_label.text = "WPN 2"
	weapon2_label.add_theme_font_size_override("font_size", 10)
	weapon2_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w2_vb.add_child(weapon2_label)


func issue_selected_unit_ability(ability_code: String) -> void:
	if command_bus == null and sim_server != null:
		command_bus = sim_server.command_bus_ref
	if command_bus == null or current_unit_id < 0:
		return
	var target_list: Array[int] = selected_unit_ids.duplicate()
	if target_list.is_empty():
		target_list = [current_unit_id]
	command_bus.enqueue_unit_ability(target_list, ability_code)
	if ability_code == "CYCLE_ALTITUDE":
		command_bus.enqueue_unit_ability(target_list, "TOGGLE_AFTERBURNER")
	elif ability_code == "DEPLOY_SUBUNIT":
		command_bus.enqueue_unit_ability(target_list, "TOGGLE_RADAR_EMCON")


func select_parent_battalion() -> void:
	if sim_server == null or current_unit_id < 0:
		return
	var st: WorldState = sim_server.world_state
	var bn_id := EchelonClusterSystem.get_battalion_id_for_unit(st, current_unit_id)
	if bn_id >= 0:
		var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, bn_id)
		selected_unit_ids = leaves if not leaves.is_empty() else [bn_id]
		if signal_bus != null:
			signal_bus.unit_selected.emit(bn_id, st.unit_platform_id[bn_id], st.unit_faction[bn_id])


func select_parent_brigade() -> void:
	if sim_server == null or current_unit_id < 0:
		return
	var st: WorldState = sim_server.world_state
	var bde_id := EchelonClusterSystem.get_brigade_id_for_unit(st, current_unit_id)
	if bde_id >= 0:
		var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, bde_id)
		selected_unit_ids = leaves if not leaves.is_empty() else [bde_id]
		if signal_bus != null:
			signal_bus.unit_selected.emit(bde_id, st.unit_platform_id[bde_id], st.unit_faction[bde_id])


func select_subordinate_companies() -> void:
	if sim_server == null or current_unit_id < 0:
		return
	var st: WorldState = sim_server.world_state
	var leaves := EchelonClusterSystem.get_subordinate_leaf_units(st, current_unit_id)
	if not leaves.is_empty():
		selected_unit_ids = leaves
		var first_u := leaves[0]
		if signal_bus != null:
			signal_bus.unit_selected.emit(first_u, st.unit_platform_id[first_u], st.unit_faction[first_u])


func _on_unit_selected(unit_id: int, platform_id: int, _faction: int) -> void:
	current_unit_id = unit_id
	inspect_platform(platform_id, unit_id)


func inspect_platform_by_slug(slug: String) -> void:
	if sim_db == null:
		return
	var pid: int = sim_db.get_platform_id(slug)
	if pid > 0:
		inspect_platform(pid, -1)


func inspect_platform(platform_id: int, unit_id: int = -1) -> void:
	if sim_db == null:
		return
	current_platform_id = platform_id
	current_unit_id = unit_id

	var p_def: Dictionary = sim_db.get_platform(platform_id)
	if p_def.is_empty():
		return

	var dname := String(p_def.get("display_name", "Unknown Platform"))
	var country := String(p_def.get("country_origin", "USA"))
	title_label.text = "[%s] %s" % [country, dname.to_upper()]

	var rcs := float(p_def.get("rcs_m2", 1.0))
	var spd := float(p_def.get("max_speed_knots", 0.0))
	var spd_kmh := spd * 1.852
	var rad := float(p_def.get("combat_radius_km", 0.0))
	var cost := float(p_def.get("unit_cost_musd", 0.0))
	var sensor_type_str := String(p_def.get("sensor_type", "ACTIVE_RADAR"))
	specs_badge_label.text = "RCS: %.4f m² | %s | SPD: %.0f kts (%.0f km/h) | RAD: %.0f km | $%.1fM" % [rcs, sensor_type_str, spd, spd_kmh, rad, cost]

	if hierarchy_org_label != null and sim_server != null and unit_id >= 0 and unit_id < sim_server.world_state.unit_count:
		var org_str := EchelonClusterSystem.get_hierarchy_status_string(sim_server.world_state, unit_id)
		var grp_cnt := maxi(1, selected_unit_ids.size())
		hierarchy_org_label.text = "%s | GROUP: %d UNITS" % [org_str, grp_cnt]

	var autonomy := String(p_def.get("autonomy_level", "MANNED"))
	var climb := "YES" if int(p_def.get("can_climb_steep_slopes", 0)) == 1 else "STD"
	var bays := int(p_def.get("carrier_sub_count", 0))
	var hp_pct := 100.0
	var civ_rho := 0.0
	var lod_str := "T0-MICRO"
	var c2_mode_str := "DELEGATED BDE/BN AI"
	var c2_int_pct := 100.0
	if unit_id >= 0 and sim_server != null and unit_id < sim_server.world_state.unit_count:
		var ws: WorldState = sim_server.world_state
		bays = ws.unit_unmanned_bays[unit_id]
		hp_pct = (ws.unit_hp[unit_id] / maxf(1.0, ws.unit_max_hp[unit_id])) * 100.0
		var u_p: Vector3 = ws.unit_pos[unit_id]
		civ_rho = ws.sample_civilian_density_m2(u_p.x, u_p.z)
		var u_lod: int = ws.unit_sim_lod[unit_id] if unit_id < ws.unit_sim_lod.size() else 0
		lod_str = "T0-MICRO" if u_lod == 0 else ("T1-OPER" if u_lod == 1 else "T2-MACRO")
		var is_del: bool = (unit_id >= ws.unit_delegated_ai.size() or ws.unit_delegated_ai[unit_id] == 1) and ws.unit_player_override_timer[unit_id] <= 0.0
		c2_mode_str = "DELEGATED AI [G]" if is_del else "DIRECT OVERRIDE [G]"
		c2_int_pct = (ws.blue_c2_integrity if ws.unit_faction[unit_id] == WorldState.FACTION_BLUE else ws.red_c2_integrity) * 100.0
	telemetry_status_label.text = "%s | C2: %.0f%% | LINK: %s | CLIFF: %s | HP: %.0f%% | BAYS: %d | %s | CIV: %.4f/m²" % [
		c2_mode_str, c2_int_pct, autonomy, climb, hp_pct, bays, lod_str, civ_rho
	]

	var summary := String(p_def.get("wiki_summary", ""))
	var wiki_url := String(p_def.get("wiki_url", ""))
	var auth_unit_line := ""
	if unit_id >= 0 and sim_server != null and unit_id < sim_server.world_state.unit_count:
		var ws_u: WorldState = sim_server.world_state
		var auth_desig := GlobalOrbatSystemScript.get_authentic_unit_designation(
			ws_u.active_theater_slug,
			ws_u.unit_faction[unit_id],
			String(p_def.get("domain", "LAND")),
			String(p_def.get("unit_class", "ARMOR")),
			unit_id
		)
		auth_unit_line = "[color=#FFD940]UNIT ORBAT: %s[/color]\n" % auth_desig
	wiki_summary_label.text = "%s%s\n\n[color=#00D8FF]Source: %s[/color]" % [auth_unit_line, summary, wiki_url]

	var img_path := String(p_def.get("image_res_path", ""))
	platform_photo_rect.texture = sim_db.get_wiki_photo_texture(img_path)

	var w1_id := int(p_def.get("weapon_1_id", 0))
	var w1_qty := int(p_def.get("weapon_1_qty", 0))
	if unit_id >= 0 and sim_server != null and unit_id < sim_server.world_state.unit_count:
		w1_qty = sim_server.world_state.unit_ammo_1[unit_id]
	if w1_id > 0:
		var w1_def: Dictionary = sim_db.get_weapon(w1_id)
		weapon1_photo_rect.texture = sim_db.get_wiki_photo_texture(String(w1_def.get("image_res_path", "")))
		weapon1_label.text = "%s (x%d)\nMach %.1f | %.0fkm | $%.2fM" % [
			String(w1_def.get("display_name", "Weapon 1")),
			w1_qty,
			float(w1_def.get("speed_mach", 1.0)),
			float(w1_def.get("max_range_km", 10.0)),
			float(w1_def.get("round_cost_musd", 0.1))
		]
	else:
		weapon1_photo_rect.texture = null
		weapon1_label.text = "No Primary Munition"

	var w2_id := int(p_def.get("weapon_2_id", 0))
	var w2_qty := int(p_def.get("weapon_2_qty", 0))
	if unit_id >= 0 and sim_server != null and unit_id < sim_server.world_state.unit_count:
		w2_qty = sim_server.world_state.unit_ammo_2[unit_id]
	if w2_id > 0:
		var w2_def: Dictionary = sim_db.get_weapon(w2_id)
		weapon2_photo_rect.texture = sim_db.get_wiki_photo_texture(String(w2_def.get("image_res_path", "")))
		weapon2_label.text = "%s (x%d)\nMach %.1f | %.0fkm | $%.2fM" % [
			String(w2_def.get("display_name", "Weapon 2")),
			w2_qty,
			float(w2_def.get("speed_mach", 1.0)),
			float(w2_def.get("max_range_km", 10.0)),
			float(w2_def.get("round_cost_musd", 0.1))
		]
	else:
		weapon2_photo_rect.texture = null
		weapon2_label.text = "Secondary Bay Empty"

	_apply_photo_tint()


func toggle_flir_tint() -> void:
	flir_green_tint_enabled = not flir_green_tint_enabled
	tint_toggle_btn.text = "FLIR FILTER: ON" if flir_green_tint_enabled else "FLIR FILTER: OFF"
	_apply_photo_tint()


func _apply_photo_tint() -> void:
	var col := TacticalTheme.COL_FLIR_GREEN if flir_green_tint_enabled else Color.WHITE
	if platform_photo_rect != null:
		platform_photo_rect.modulate = col
	if weapon1_photo_rect != null:
		weapon1_photo_rect.modulate = col
	if weapon2_photo_rect != null:
		weapon2_photo_rect.modulate = col

class_name NationSelectorConsole3D
extends Node3D
## Sprint 14: Diegetic 3D Superpower Nation Selector Pedestal inside the Command Bunker.
## Allows VR 6DOF ray/touch and desktop raycast picking to cycle and select playable nations
## (USA, China, Russia, Taiwan, Poland, Ukraine, South Korea) without 2D HUD menus.

signal nation_selected(nation_slug: String, nation_data: Dictionary)
signal nation_browsed(nation_slug: String, nation_data: Dictionary)

var sim_db: Node = null
var current_nation_index: int = 0
var available_nations: Array[Dictionary] = []

# 3D Node references
var _pedestal_mesh: MeshInstance3D = null
var _slate_root: Node3D = null
var _country_name_label: Label3D = null
var _doctrine_label: Label3D = null
var _doctrine_summary_label: Label3D = null
var _specs_label: Label3D = null
var _btn_prev: Area3D = null
var _btn_next: Area3D = null
var _btn_confirm: Area3D = null
var _btn_prev_mesh: MeshInstance3D = null
var _btn_next_mesh: MeshInstance3D = null
var _btn_confirm_mesh: MeshInstance3D = null


func _ready() -> void:
	_build_pedestal_and_controls()
	_load_nations_from_db()
	_update_holographic_dossier()


func setup(p_sim_db: Node) -> void:
	sim_db = p_sim_db
	_load_nations_from_db()
	_update_holographic_dossier()


func _load_nations_from_db() -> void:
	if sim_db == null:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree and main_loop.root != null:
			sim_db = main_loop.root.get_node_or_null("SimDB")
			if sim_db == null:
				sim_db = main_loop.root.get_node_or_null("/root/SimDB")

	if sim_db != null and sim_db.has_method("get_campaign_nations"):
		available_nations = sim_db.get_campaign_nations()

	if available_nations.is_empty():
		# Fallback superpower definitions
		available_nations = [
			{
				"slug": "usa",
				"country_name": "United States of America",
				"iso_code": "USA",
				"doctrine_label": "Global Rapid Expeditionary Strike",
				"doctrine_summary": "Carrier Strike Groups, B-21 Raiders & 5th-Gen Stealth Air Superiority.",
				"flagship_platform_slug": "f35a_lightning",
				"budget_musd": 4500
			},
			{
				"slug": "china",
				"country_name": "People's Republic of China",
				"iso_code": "CHN",
				"doctrine_label": "Anti-Access / Area Denial (A2/AD)",
				"doctrine_summary": "DF-21D/DF-26 Anti-Ship Ballistic Missiles & Hypersonic Gliders.",
				"flagship_platform_slug": "j20_mighty_dragon",
				"budget_musd": 3200
			},
			{
				"slug": "russia",
				"country_name": "Russian Federation",
				"iso_code": "RUS",
				"doctrine_label": "Deep Battle & Hypersonic Interdiction",
				"doctrine_summary": "Iskander-M batteries, S-400 Triumf & Armored Breakthrough Echelons.",
				"flagship_platform_slug": "su57_felon",
				"budget_musd": 2100
			}
		]


func _build_pedestal_and_controls() -> void:
	# 1. Physical Pedestal Pillar
	_pedestal_mesh = MeshInstance3D.new()
	_pedestal_mesh.name = "PedestalPillar3D"
	var col_cyl := CylinderMesh.new()
	col_cyl.top_radius = 0.22
	col_cyl.bottom_radius = 0.28
	col_cyl.height = 0.88
	var col_mat := StandardMaterial3D.new()
	col_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	col_mat.albedo_color = Color(0.08, 0.11, 0.16)
	col_mat.roughness = 0.35
	col_mat.metallic = 0.85
	col_cyl.material = col_mat
	_pedestal_mesh.mesh = col_cyl
	_pedestal_mesh.position = Vector3(0.0, 0.44, 0.0)
	add_child(_pedestal_mesh)

	# 2. Control Plate Surface (Angled at 30 degrees toward user)
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.04, 0.42)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.05, 0.08, 0.12)
	p_mat.roughness = 0.25
	p_mat.metallic = 0.9
	plate.mesh = box
	plate.material_override = p_mat
	plate.position = Vector3(0.0, 0.88, 0.0)
	plate.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	add_child(plate)

	# 3. Interactive Buttons on Plate
	_btn_prev = _create_button("BtnPrevNation3D", Vector3(-0.16, 0.03, 0.12), Vector3(0.12, 0.035, 0.06), "◄ PREV", Color(0.2, 0.7, 1.0))
	plate.add_child(_btn_prev)

	_btn_next = _create_button("BtnNextNation3D", Vector3(0.16, 0.03, 0.12), Vector3(0.12, 0.035, 0.06), "NEXT ►", Color(0.2, 0.7, 1.0))
	plate.add_child(_btn_next)

	_btn_confirm = _create_button("BtnConfirmNation3D", Vector3(0.0, 0.03, 0.12), Vector3(0.16, 0.038, 0.065), "COMMENCE", Color(0.2, 1.0, 0.55))
	plate.add_child(_btn_confirm)

	# 4. Holographic Nation Dossier Slate
	_slate_root = Node3D.new()
	_slate_root.name = "HolographicNationSlate3D"
	_slate_root.position = Vector3(0.0, 0.22, -0.06)
	plate.add_child(_slate_root)

	var slate_back := MeshInstance3D.new()
	var s_mesh := BoxMesh.new()
	s_mesh.size = Vector3(0.52, 0.28, 0.008)
	var s_mat := StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(0.02, 0.05, 0.09, 0.92)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slate_back.mesh = s_mesh
	slate_back.material_override = s_mat
	_slate_root.add_child(slate_back)

	_country_name_label = Label3D.new()
	_country_name_label.position = Vector3(0.0, 0.09, 0.006)
	_country_name_label.font_size = 20
	_country_name_label.pixel_size = 0.00075
	_country_name_label.modulate = Color(1.0, 0.85, 0.25)
	_country_name_label.text = "UNITED STATES OF AMERICA"
	_slate_root.add_child(_country_name_label)

	_doctrine_label = Label3D.new()
	_doctrine_label.position = Vector3(0.0, 0.045, 0.006)
	_doctrine_label.font_size = 14
	_doctrine_label.pixel_size = 0.00062
	_doctrine_label.modulate = Color(0.35, 0.88, 1.0)
	_doctrine_label.text = "DOCTRINE: Global Rapid Expeditionary Strike"
	_slate_root.add_child(_doctrine_label)

	_doctrine_summary_label = Label3D.new()
	_doctrine_summary_label.position = Vector3(0.0, -0.01, 0.006)
	_doctrine_summary_label.font_size = 12
	_doctrine_summary_label.pixel_size = 0.00055
	_doctrine_summary_label.modulate = Color(0.85, 0.92, 0.98, 0.9)
	_doctrine_summary_label.text = "Carrier Strike Groups, B-21 Raiders & 5th-Gen Stealth Air Superiority."
	_doctrine_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_doctrine_summary_label.width = 480.0
	_slate_root.add_child(_doctrine_summary_label)

	_specs_label = Label3D.new()
	_specs_label.position = Vector3(0.0, -0.08, 0.006)
	_specs_label.font_size = 12
	_specs_label.pixel_size = 0.00055
	_specs_label.modulate = Color(0.2, 1.0, 0.6)
	_specs_label.text = "BUDGET: $4500M | FLAGSHIP: F-35A LIGHTNING II | THEATER: PACIFIC"
	_slate_root.add_child(_specs_label)


func _create_button(btn_name: String, pos: Vector3, sz: Vector3, label_text: String, col: Color) -> Area3D:
	var area := Area3D.new()
	area.name = btn_name
	area.position = pos

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = sz
	col_shape.shape = box_shape
	area.add_child(col_shape)

	var mi := MeshInstance3D.new()
	mi.name = btn_name + "Mesh"
	var bm := BoxMesh.new()
	bm.size = sz
	var b_mat := StandardMaterial3D.new()
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = col
	mi.mesh = bm
	mi.material_override = b_mat
	area.add_child(mi)

	var lbl := Label3D.new()
	lbl.position = Vector3(0.0, sz.y * 0.55, 0.0)
	lbl.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lbl.font_size = 11
	lbl.pixel_size = 0.00065
	lbl.modulate = Color(0.05, 0.08, 0.12)
	lbl.text = label_text
	area.add_child(lbl)

	return area


func cycle_nation(step: int) -> void:
	if available_nations.is_empty():
		return
	current_nation_index = (current_nation_index + step + available_nations.size()) % available_nations.size()
	_update_holographic_dossier()
	var nat := get_current_nation()
	nation_browsed.emit(String(nat.get("slug", "")), nat)


func select_nation_by_slug(slug: String) -> bool:
	for i in range(available_nations.size()):
		if String(available_nations[i].get("slug", "")) == slug:
			current_nation_index = i
			_update_holographic_dossier()
			var nat := get_current_nation()
			nation_browsed.emit(slug, nat)
			return true
	return false


func get_current_nation() -> Dictionary:
	if available_nations.is_empty():
		return {}
	return available_nations[current_nation_index]


func confirm_nation_selection() -> Dictionary:
	var nat := get_current_nation()
	var slug := String(nat.get("slug", "usa"))
	nation_selected.emit(slug, nat)
	return nat


func actuate_control(control_name: String) -> void:
	if control_name.contains("BtnPrev"):
		cycle_nation(-1)
	elif control_name.contains("BtnNext"):
		cycle_nation(1)
	elif control_name.contains("BtnConfirm"):
		confirm_nation_selection()


func _update_holographic_dossier() -> void:
	var nat := get_current_nation()
	if nat.is_empty():
		return

	if _country_name_label != null:
		_country_name_label.text = String(nat.get("country_name", "UNKNOWN NATION")).to_upper()
	if _doctrine_label != null:
		_doctrine_label.text = "DOCTRINE: %s" % String(nat.get("doctrine_label", "Standard Defense"))
	if _doctrine_summary_label != null:
		_doctrine_summary_label.text = String(nat.get("doctrine_summary", "Strategic operational capabilities."))
	if _specs_label != null:
		var budget := int(nat.get("budget_musd", 3000))
		var platform := String(nat.get("flagship_platform_slug", "GENERIC")).to_upper()
		var theater := String(nat.get("theater_slug", "GLOBAL")).to_upper()
		_specs_label.text = "BUDGET: $%dM | FLAGSHIP: %s | THEATER: %s" % [budget, platform, theater]

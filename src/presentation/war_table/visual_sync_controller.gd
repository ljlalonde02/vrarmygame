class_name VisualSyncController
extends Node3D

const PlatformMeshArmoryScript := preload("res://src/presentation/war_table/platform_mesh_armory.gd")
## 90 Hz Tacview-Style 3D Miniature & Ribbon Presentation Synchronizer.
## Renders little 3D miniature units for ALL domains (Air, Sea, Land Vehicles, Robot Dogs, Infantry Soldiers, Missiles)
## at ALL zoom levels (expanding into full 4-ship flights, 4-tank platoons, 8-dog packs, and 12-man infantry squads on zoom)
## plus true 3D banked Tacview Wingtip/Wake Ribbon Strips (`ribbons_mesh_instance` via `PRIMITIVE_TRIANGLES`)!

const MAX_VISIBLE_TOKENS := 1024
const MAX_VISIBLE_JETS := 1536
const MAX_VISIBLE_SHIPS := 512
const MAX_VISIBLE_SOLDIERS := 4096
const MAX_VISIBLE_VEHICLES := 2048
const MAX_VISIBLE_CIVILIANS := 1024
const MAX_VISIBLE_STEMS := 1024
const MAX_VISIBLE_MUNITIONS := 1024
const MAX_VISIBLE_SATELLITES := 32
const MAX_VISIBLE_BUILDINGS := 6144
const MAX_VISIBLE_TRAIN_CARS := 256
const MAX_FLOATING_PHOTO_CARDS := 16
const MAX_VISIBLE_FLAGSHIP := 256
const MAX_VISIBLE_FLARES := 512

var sim_server: Node = null
var sim_db: Node = null
var war_table: Node3D = null

var unit_tokens_mmi: MultiMeshInstance3D = null
var air_jets_mmi: MultiMeshInstance3D = null
var naval_ships_mmi: MultiMeshInstance3D = null
var soldiers_mmi: MultiMeshInstance3D = null
var vehicles_mmi: MultiMeshInstance3D = null
var civilian_dots_mmi: MultiMeshInstance3D = null
var altitude_stems_mmi: MultiMeshInstance3D = null
var active_munitions_mmi: MultiMeshInstance3D = null
var orbital_satellites_mmi: MultiMeshInstance3D = null
var urban_buildings_mmi: MultiMeshInstance3D = null
var rail_trains_mmi: MultiMeshInstance3D = null
var beams_mesh_instance: MeshInstance3D = null
var beams_immediate: ImmediateMesh = null
var ribbons_mesh_instance: MeshInstance3D = null
var ribbons_immediate: ImmediateMesh = null

var f35_mmi: MultiMeshInstance3D = null
var j20_mmi: MultiMeshInstance3D = null
var su57_mmi: MultiMeshInstance3D = null
var b21_mmi: MultiMeshInstance3D = null
var cvn78_mmi: MultiMeshInstance3D = null
var type055_mmi: MultiMeshInstance3D = null
var m1a2_mmi: MultiMeshInstance3D = null
var robot_dog_mmi: MultiMeshInstance3D = null
var flares_mmi: MultiMeshInstance3D = null

# Sprint 16: Specialized 3D Munition MultiMesh Layers
var artillery_mmi: MultiMeshInstance3D = null
var cruise_mmi: MultiMeshInstance3D = null
var ballistic_mmi: MultiMeshInstance3D = null
var drone_mmi: MultiMeshInstance3D = null
var hypersonic_mmi: MultiMeshInstance3D = null

var last_visible_f35_count: int = 0
var last_visible_j20_count: int = 0
var last_visible_su57_count: int = 0
var last_visible_b21_count: int = 0
var last_visible_cvn78_count: int = 0
var last_visible_type055_count: int = 0
var last_visible_m1a2_count: int = 0
var last_visible_dog_count: int = 0
var last_visible_flare_count: int = 0
var last_visible_artillery_count: int = 0
var last_visible_cruise_count: int = 0
var last_visible_ballistic_count: int = 0
var last_visible_drone_count: int = 0
var last_visible_hypersonic_count: int = 0

var _city_labels_root: Node3D = null
var _city_labels: Array[Label3D] = []


var _nuke_mesh_root: Node3D = null
var _nuke_fireball_mi: MeshInstance3D = null
var _nuke_stem_mi: MeshInstance3D = null
var _nuke_cap_mi: MeshInstance3D = null
var _nuke_shockwave_mi: MeshInstance3D = null

var selected_unit_id: int = -1
var selected_unit_ids: Array[int] = []
var designated_target_uid: int = -1
var force_all_tokens: bool = false
var true_sight_enabled: bool = false
var recon_photo_mode: bool = false

var last_visible_token_count: int = 0
var last_visible_jet_count: int = 0
var last_visible_ship_count: int = 0
var last_visible_soldier_count: int = 0
var last_visible_vehicle_count: int = 0
var last_visible_civilian_dot_count: int = 0
var last_active_civilian_cells_count: int = 0
var last_visible_munition_count: int = 0
var last_visible_satellite_count: int = 0
var last_visible_building_count: int = 0
var last_visible_train_car_count: int = 0
var last_active_sniper_commando_beams_count: int = 0

var _photo_cards_root: Node3D = null
var _photo_card_sprites: Array[Sprite3D] = []
var _photo_card_labels: Array[Label3D] = []

# Sprint 7: Diegetic 3D Radial Command Menu & Hostile Target Reticle
var _command_radial_root: Node3D = null
var _radial_posture_labels: Array[Label3D] = []
var _target_reticle_root: Node3D = null
var _target_reticle_label: Label3D = null

# Tacview 3D Ribbon History: uid -> Array of {pos_km: Vector3, right_vec: Vector3}
var _ribbon_history: Dictionary = {}
var _trail_frame_counter: int = 0
var _last_civ_tick_id: int = -1
var _last_bldg_zoom: float = -1.0
var _last_bldg_pan: Vector2 = Vector2(99999.0, 99999.0)
var _last_bldg_destr_count: int = -1
var _last_bldg_total_count: int = -1
var _last_bldg_globe: bool = false
var _last_bldg_theater: String = ""


func _ready() -> void:
	if unit_tokens_mmi == null:
		_setup_multimesh_layers()
	if _photo_cards_root == null:
		_setup_floating_photo_cards()
	if _command_radial_root == null:
		_setup_command_radial_menu()
	if _city_labels_root == null:
		_setup_real_city_labels()
	var sig_bus: Node = get_node_or_null("/root/SignalBus") if is_inside_tree() else null
	if sig_bus != null:
		sig_bus.recon_photo_mode_toggled.connect(func(enabled: bool): recon_photo_mode = enabled)
		sig_bus.semantic_override_toggled.connect(func(force_all: bool): force_all_tokens = force_all)
		sig_bus.true_sight_toggled.connect(func(enabled: bool): true_sight_enabled = enabled)
		sig_bus.unit_selected.connect(func(uid: int, _pid: int, _fac: int):
			selected_unit_id = uid
			if selected_unit_ids.is_empty() or not selected_unit_ids.has(uid):
				selected_unit_ids.clear()
				if uid >= 0:
					selected_unit_ids.append(uid)
		)


## Builds a sleek 3D Tacview swept-wing fighter jet mesh oriented along -Z forward, +Y up.
func _create_swept_jet_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.017)
	var tail := Vector3(0.0, 0.001, 0.012)
	var wing_l := Vector3(-0.015, 0.0, 0.008)
	var wing_r := Vector3(0.015, 0.0, 0.008)
	var spine := Vector3(0.0, 0.0045, 0.002)
	var fin_top := Vector3(0.0, 0.009, 0.011)

	st.add_vertex(nose); st.add_vertex(wing_l); st.add_vertex(spine)
	st.add_vertex(nose); st.add_vertex(spine); st.add_vertex(wing_r)
	st.add_vertex(spine); st.add_vertex(wing_l); st.add_vertex(tail)
	st.add_vertex(spine); st.add_vertex(tail); st.add_vertex(wing_r)
	st.add_vertex(nose); st.add_vertex(wing_r); st.add_vertex(wing_l)
	st.add_vertex(tail); st.add_vertex(wing_l); st.add_vertex(wing_r)
	st.add_vertex(spine); st.add_vertex(fin_top); st.add_vertex(tail)
	st.add_vertex(spine); st.add_vertex(tail); st.add_vertex(fin_top)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## Builds a 3D miniature warship hull + superstructure mast oriented along -Z forward, +Y up.
func _create_warship_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var bow := Vector3(0.0, 0.003, -0.026)
	var stern_l := Vector3(-0.0055, 0.003, 0.022)
	var stern_r := Vector3(0.0055, 0.003, 0.022)
	var mid_l := Vector3(-0.0065, 0.003, -0.005)
	var mid_r := Vector3(0.0065, 0.003, -0.005)
	var mast_top := Vector3(0.0, 0.012, -0.002)

	# Deck
	st.add_vertex(bow); st.add_vertex(mid_l); st.add_vertex(mid_r)
	st.add_vertex(mid_l); st.add_vertex(stern_l); st.add_vertex(stern_r)
	st.add_vertex(mid_l); st.add_vertex(stern_r); st.add_vertex(mid_r)
	# Superstructure pyramid mast
	st.add_vertex(bow * 0.5); st.add_vertex(mid_l * 0.7); st.add_vertex(mast_top)
	st.add_vertex(bow * 0.5); st.add_vertex(mast_top); st.add_vertex(mid_r * 0.7)
	st.add_vertex(mid_l * 0.7); st.add_vertex(stern_l * 0.6); st.add_vertex(mast_top)
	st.add_vertex(mid_r * 0.7); st.add_vertex(mast_top); st.add_vertex(stern_r * 0.6)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## Builds a 3D miniature tactical soldier / sniper / commando with helmet, armored torso, striding legs, and forward rifle barrel (-Z forward).
## Realistic miniature scale: ~3.6mm height, ~1.6mm shoulder width (realistic proportion to 5.5mm tall, 11mm long armored tanks).
func _create_tactical_soldier_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Boots / Striding Legs base -> Torso -> Helmet peak
	var foot_l := Vector3(-0.0006, 0.0, 0.0005)
	var foot_r := Vector3(0.0006, 0.0, -0.0005)
	var sh_fl := Vector3(-0.0008, 0.0024, -0.0006)
	var sh_fr := Vector3(0.0008, 0.0024, -0.0006)
	var sh_bl := Vector3(-0.0008, 0.0024, 0.0007)
	var sh_br := Vector3(0.0008, 0.0024, 0.0007)
	var helmet_top := Vector3(0.0, 0.0036, -0.0001)
	var rifle_tip := Vector3(0.0003, 0.0022, -0.0032)

	# Lower body & torso facets
	st.add_vertex(foot_l); st.add_vertex(foot_r); st.add_vertex(sh_fl)
	st.add_vertex(foot_r); st.add_vertex(sh_fr); st.add_vertex(sh_fl)
	st.add_vertex(foot_l); st.add_vertex(sh_bl); st.add_vertex(foot_r)
	st.add_vertex(foot_r); st.add_vertex(sh_bl); st.add_vertex(sh_br)
	st.add_vertex(foot_l); st.add_vertex(sh_fl); st.add_vertex(sh_bl)
	st.add_vertex(foot_r); st.add_vertex(sh_br); st.add_vertex(sh_fr)

	# Helmet / Head pyramid
	st.add_vertex(sh_fl); st.add_vertex(sh_fr); st.add_vertex(helmet_top)
	st.add_vertex(sh_fr); st.add_vertex(sh_br); st.add_vertex(helmet_top)
	st.add_vertex(sh_br); st.add_vertex(sh_bl); st.add_vertex(helmet_top)
	st.add_vertex(sh_bl); st.add_vertex(sh_fl); st.add_vertex(helmet_top)

	# Forward Rifle / .50 BMG Sniper Barrel wedge pointing -Z
	st.add_vertex(rifle_tip); st.add_vertex(sh_fl * 0.65); st.add_vertex(helmet_top * 0.72)
	st.add_vertex(rifle_tip); st.add_vertex(helmet_top * 0.72); st.add_vertex(sh_fr * 0.65)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## Builds a 3D miniature armored vehicle / tank with turret & forward gun barrel (-Z forward).
## Realistic miniature scale: ~5.5mm height, ~5.6mm width, ~11mm length (comfortably fitting on road segments and next to village houses).
func _create_tank_turret_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var fl := Vector3(-0.0028, 0.0022, -0.0055)
	var fr := Vector3(0.0028, 0.0022, -0.0055)
	var bl := Vector3(-0.0028, 0.0022, 0.0055)
	var br := Vector3(0.0028, 0.0022, 0.0055)
	var turret_top := Vector3(0.0, 0.0055, 0.0005)
	var gun_tip := Vector3(0.0, 0.0038, -0.0095)

	st.add_vertex(fl); st.add_vertex(bl); st.add_vertex(turret_top)
	st.add_vertex(fr); st.add_vertex(turret_top); st.add_vertex(br)
	st.add_vertex(fl); st.add_vertex(turret_top); st.add_vertex(fr)
	st.add_vertex(bl); st.add_vertex(br); st.add_vertex(turret_top)
	# Gun barrel wedge
	st.add_vertex(gun_tip); st.add_vertex(fl * 0.45); st.add_vertex(turret_top)
	st.add_vertex(gun_tip); st.add_vertex(turret_top); st.add_vertex(fr * 0.45)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## Builds a 3D miniature orbiting Space Force spacecraft with central bus + solar array wings.
func _create_satellite_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var b_fl := Vector3(-0.004, 0.004, -0.005)
	var b_fr := Vector3(0.004, 0.004, -0.005)
	var b_bl := Vector3(-0.004, 0.004, 0.005)
	var b_br := Vector3(0.004, 0.004, 0.005)
	var dish_nadir := Vector3(0.0, -0.005, 0.0)

	# Spacecraft body pyramid pointing nadir
	st.add_vertex(b_fl); st.add_vertex(b_fr); st.add_vertex(dish_nadir)
	st.add_vertex(b_fr); st.add_vertex(b_br); st.add_vertex(dish_nadir)
	st.add_vertex(b_br); st.add_vertex(b_bl); st.add_vertex(dish_nadir)
	st.add_vertex(b_bl); st.add_vertex(b_fl); st.add_vertex(dish_nadir)

	# Solar Array Wings (-X and +X)
	var wl1 := Vector3(-0.022, 0.002, -0.004)
	var wl2 := Vector3(-0.005, 0.002, -0.004)
	var wl3 := Vector3(-0.005, 0.002, 0.004)
	var wl4 := Vector3(-0.022, 0.002, 0.004)
	st.add_vertex(wl1); st.add_vertex(wl2); st.add_vertex(wl3)
	st.add_vertex(wl1); st.add_vertex(wl3); st.add_vertex(wl4)

	var wr1 := Vector3(0.005, 0.002, -0.004)
	var wr2 := Vector3(0.022, 0.002, -0.004)
	var wr3 := Vector3(0.022, 0.002, 0.004)
	var wr4 := Vector3(0.005, 0.002, 0.004)
	st.add_vertex(wr1); st.add_vertex(wr2); st.add_vertex(wr3)
	st.add_vertex(wr1); st.add_vertex(wr3); st.add_vertex(wr4)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


func _setup_multimesh_layers() -> void:
	var token_shader: Shader = load("res://src/presentation/war_table/shaders/hologram_token.gdshader")
	var token_mat := ShaderMaterial.new()
	token_mat.shader = token_shader

	# 1. UnitTokensMultiMesh
	unit_tokens_mmi = get_node_or_null("UnitTokensMultiMesh") as MultiMeshInstance3D
	if unit_tokens_mmi == null:
		unit_tokens_mmi = MultiMeshInstance3D.new()
		unit_tokens_mmi.name = "UnitTokensMultiMesh"
		add_child(unit_tokens_mmi)

	var quad := QuadMesh.new()
	quad.size = Vector2(0.028, 0.028)
	quad.orientation = PlaneMesh.FACE_Y
	quad.material = token_mat

	var token_mm := MultiMesh.new()
	token_mm.transform_format = MultiMesh.TRANSFORM_3D
	token_mm.use_colors = true
	token_mm.use_custom_data = true
	token_mm.mesh = quad
	token_mm.instance_count = MAX_VISIBLE_TOKENS
	token_mm.visible_instance_count = 0
	unit_tokens_mmi.multimesh = token_mm

	# 2. AirJetsMultiMesh (3D Swept-Wing Tacview Aircraft & Wingman Formations)
	air_jets_mmi = get_node_or_null("AirJetsMultiMesh") as MultiMeshInstance3D
	if air_jets_mmi == null:
		air_jets_mmi = MultiMeshInstance3D.new()
		air_jets_mmi.name = "AirJetsMultiMesh"
		add_child(air_jets_mmi)

	var jet_mat := StandardMaterial3D.new()
	jet_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	jet_mat.vertex_color_use_as_albedo = true
	jet_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var jet_mm := MultiMesh.new()
	jet_mm.transform_format = MultiMesh.TRANSFORM_3D
	jet_mm.use_colors = true
	jet_mm.mesh = _create_swept_jet_mesh(jet_mat)
	jet_mm.instance_count = MAX_VISIBLE_JETS
	jet_mm.visible_instance_count = 0
	air_jets_mmi.multimesh = jet_mm

	# 3. NavalShipsMultiMesh (3D Miniature Warships, Destroyers, USVs & Submarines)
	naval_ships_mmi = get_node_or_null("NavalShipsMultiMesh") as MultiMeshInstance3D
	if naval_ships_mmi == null:
		naval_ships_mmi = MultiMeshInstance3D.new()
		naval_ships_mmi.name = "NavalShipsMultiMesh"
		add_child(naval_ships_mmi)

	var ship_mat := StandardMaterial3D.new()
	ship_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ship_mat.vertex_color_use_as_albedo = true
	ship_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var ship_mm := MultiMesh.new()
	ship_mm.transform_format = MultiMesh.TRANSFORM_3D
	ship_mm.use_colors = true
	ship_mm.mesh = _create_warship_mesh(ship_mat)
	ship_mm.instance_count = MAX_VISIBLE_SHIPS
	ship_mm.visible_instance_count = 0
	naval_ships_mmi.multimesh = ship_mm

	# 4. IndividualSoldiersMultiMesh (3D Infantry Squads on Terrain)
	soldiers_mmi = get_node_or_null("IndividualSoldiersMultiMesh") as MultiMeshInstance3D
	if soldiers_mmi == null:
		soldiers_mmi = MultiMeshInstance3D.new()
		soldiers_mmi.name = "IndividualSoldiersMultiMesh"
		add_child(soldiers_mmi)

	var soldier_mat := StandardMaterial3D.new()
	soldier_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	soldier_mat.vertex_color_use_as_albedo = true
	soldier_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var soldier_mm := MultiMesh.new()
	soldier_mm.transform_format = MultiMesh.TRANSFORM_3D
	soldier_mm.use_colors = true
	soldier_mm.mesh = _create_tactical_soldier_mesh(soldier_mat)
	soldier_mm.instance_count = MAX_VISIBLE_SOLDIERS
	soldier_mm.visible_instance_count = 0
	soldiers_mmi.multimesh = soldier_mm

	# 5. IndividualVehiclesMultiMesh (3D Tanks, IFVs, SAM TELs & Quadruped Robot Dogs)
	vehicles_mmi = get_node_or_null("IndividualVehiclesMultiMesh") as MultiMeshInstance3D
	if vehicles_mmi == null:
		vehicles_mmi = MultiMeshInstance3D.new()
		vehicles_mmi.name = "IndividualVehiclesMultiMesh"
		add_child(vehicles_mmi)

	var veh_mat := StandardMaterial3D.new()
	veh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	veh_mat.vertex_color_use_as_albedo = true
	veh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var veh_mm := MultiMesh.new()
	veh_mm.transform_format = MultiMesh.TRANSFORM_3D
	veh_mm.use_colors = true
	veh_mm.mesh = _create_tank_turret_mesh(veh_mat)
	veh_mm.instance_count = MAX_VISIBLE_VEHICLES
	veh_mm.visible_instance_count = 0
	vehicles_mmi.multimesh = veh_mm

	# 5b. CivilianDotsMultiMesh (Neutral Maritime AIS Shipping, Urban Highway Streams & Civil Air Transponders)
	civilian_dots_mmi = get_node_or_null("CivilianDotsMultiMesh") as MultiMeshInstance3D
	if civilian_dots_mmi == null:
		civilian_dots_mmi = MultiMeshInstance3D.new()
		civilian_dots_mmi.name = "CivilianDotsMultiMesh"
		add_child(civilian_dots_mmi)

	var civ_mat := StandardMaterial3D.new()
	civ_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	civ_mat.vertex_color_use_as_albedo = true
	civ_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var civ_box := BoxMesh.new()
	civ_box.size = Vector3(0.0028, 0.0024, 0.0038)
	civ_box.material = civ_mat

	var civ_mm := MultiMesh.new()
	civ_mm.transform_format = MultiMesh.TRANSFORM_3D
	civ_mm.use_colors = true
	civ_mm.mesh = civ_box
	civ_mm.instance_count = MAX_VISIBLE_CIVILIANS
	civ_mm.visible_instance_count = 0
	civilian_dots_mmi.multimesh = civ_mm

	# 6. AltitudeStemsMultiMesh
	altitude_stems_mmi = get_node_or_null("AltitudeStemsMultiMesh") as MultiMeshInstance3D
	if altitude_stems_mmi == null:
		altitude_stems_mmi = MultiMeshInstance3D.new()
		altitude_stems_mmi.name = "AltitudeStemsMultiMesh"
		add_child(altitude_stems_mmi)

	var stem_mat := StandardMaterial3D.new()
	stem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stem_mat.vertex_color_use_as_albedo = true
	stem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var stem_box := BoxMesh.new()
	stem_box.size = Vector3(0.0016, 1.0, 0.0016)
	stem_box.material = stem_mat

	var stem_mm := MultiMesh.new()
	stem_mm.transform_format = MultiMesh.TRANSFORM_3D
	stem_mm.use_colors = true
	stem_mm.mesh = stem_box
	stem_mm.instance_count = MAX_VISIBLE_STEMS
	stem_mm.visible_instance_count = 0
	altitude_stems_mmi.multimesh = stem_mm

	# 7. ActiveMunitionsMultiMesh
	active_munitions_mmi = get_node_or_null("ActiveMunitionsMultiMesh") as MultiMeshInstance3D
	if active_munitions_mmi == null:
		active_munitions_mmi = MultiMeshInstance3D.new()
		active_munitions_mmi.name = "ActiveMunitionsMultiMesh"
		add_child(active_munitions_mmi)

	var mun_mat := StandardMaterial3D.new()
	mun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mun_mat.vertex_color_use_as_albedo = true
	var mun_prism := BoxMesh.new()
	mun_prism.size = Vector3(0.0055, 0.0055, 0.018)
	mun_prism.material = mun_mat

	var mun_mm := MultiMesh.new()
	mun_mm.transform_format = MultiMesh.TRANSFORM_3D
	mun_mm.use_colors = true
	mun_mm.mesh = mun_prism
	mun_mm.instance_count = MAX_VISIBLE_MUNITIONS
	mun_mm.visible_instance_count = 0
	active_munitions_mmi.multimesh = mun_mm

	# 7b. OrbitalSatellitesMultiMesh (3D Space Force Constellation in Upper Orbital Dome / Planetary Globe)
	orbital_satellites_mmi = get_node_or_null("OrbitalSatellitesMultiMesh") as MultiMeshInstance3D
	if orbital_satellites_mmi == null:
		orbital_satellites_mmi = MultiMeshInstance3D.new()
		orbital_satellites_mmi.name = "OrbitalSatellitesMultiMesh"
		add_child(orbital_satellites_mmi)

	var sat_mat := StandardMaterial3D.new()
	sat_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sat_mat.vertex_color_use_as_albedo = true
	sat_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var sat_mm := MultiMesh.new()
	sat_mm.transform_format = MultiMesh.TRANSFORM_3D
	sat_mm.use_colors = true
	sat_mm.mesh = _create_satellite_mesh(sat_mat)
	sat_mm.instance_count = MAX_VISIBLE_SATELLITES
	sat_mm.visible_instance_count = 0
	orbital_satellites_mmi.multimesh = sat_mm

	# 7c. UrbanBuildingsMultiMesh (Procedural 3D City Skyscrapers, Town/Village Cubes, Airport Runways/Hangars & Bridges)
	urban_buildings_mmi = get_node_or_null("UrbanBuildingsMultiMesh") as MultiMeshInstance3D
	if urban_buildings_mmi == null:
		urban_buildings_mmi = MultiMeshInstance3D.new()
		urban_buildings_mmi.name = "UrbanBuildingsMultiMesh"
		add_child(urban_buildings_mmi)

	var bldg_mat := StandardMaterial3D.new()
	bldg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bldg_mat.vertex_color_use_as_albedo = true
	var bldg_box := BoxMesh.new()
	bldg_box.size = Vector3.ONE
	bldg_box.material = bldg_mat

	var bldg_mm := MultiMesh.new()
	bldg_mm.transform_format = MultiMesh.TRANSFORM_3D
	bldg_mm.use_colors = true
	bldg_mm.mesh = bldg_box
	bldg_mm.instance_count = MAX_VISIBLE_BUILDINGS
	bldg_mm.visible_instance_count = 0
	urban_buildings_mmi.multimesh = bldg_mm

	# 7d. RailTrainsMultiMesh (3D Military Echelon Logistics Trains on Strategic Railways)
	rail_trains_mmi = get_node_or_null("RailTrainsMultiMesh") as MultiMeshInstance3D
	if rail_trains_mmi == null:
		rail_trains_mmi = MultiMeshInstance3D.new()
		rail_trains_mmi.name = "RailTrainsMultiMesh"
		add_child(rail_trains_mmi)

	var train_mat := StandardMaterial3D.new()
	train_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	train_mat.vertex_color_use_as_albedo = true
	var train_box := BoxMesh.new()
	train_box.size = Vector3(0.0042, 0.0038, 0.0105)
	train_box.material = train_mat

	var train_mm := MultiMesh.new()
	train_mm.transform_format = MultiMesh.TRANSFORM_3D
	train_mm.use_colors = true
	train_mm.mesh = train_box
	train_mm.instance_count = MAX_VISIBLE_TRAIN_CARS
	train_mm.visible_instance_count = 0
	rail_trains_mmi.multimesh = train_mm

	# 8. TacviewRibbonsMesh (PRIMITIVE_TRIANGLES 3D banked flight ribbons & ship wakes)
	ribbons_mesh_instance = get_node_or_null("TacviewRibbonsMesh") as MeshInstance3D
	if ribbons_mesh_instance == null:
		ribbons_mesh_instance = MeshInstance3D.new()
		ribbons_mesh_instance.name = "TacviewRibbonsMesh"
		add_child(ribbons_mesh_instance)

	ribbons_immediate = ImmediateMesh.new()
	var rib_mat := StandardMaterial3D.new()
	rib_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rib_mat.vertex_color_use_as_albedo = true
	rib_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rib_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbons_mesh_instance.mesh = ribbons_immediate
	ribbons_mesh_instance.material_override = rib_mat

	# 9. LaserHpmBeamsMesh (PRIMITIVE_LINES for lasers, HPM cones, shockwaves & waypoints)
	beams_mesh_instance = get_node_or_null("LaserHpmBeamsMesh") as MeshInstance3D
	if beams_mesh_instance == null:
		beams_mesh_instance = MeshInstance3D.new()
		beams_mesh_instance.name = "LaserHpmBeamsMesh"
		add_child(beams_mesh_instance)

	beams_immediate = ImmediateMesh.new()
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.vertex_color_use_as_albedo = true
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beams_mesh_instance.mesh = beams_immediate
	beams_mesh_instance.material_override = beam_mat

	# 10. ThermonuclearDetonationFX (3D Volumetric Mesh Explosion: Core, Stem, Toroidal Cap, Shockwave)
	_setup_nuke_detonation_meshes()
	_setup_flagship_multimeshes()
	_setup_munition_multimeshes()



func _setup_nuke_detonation_meshes() -> void:
	_nuke_mesh_root = Node3D.new()
	_nuke_mesh_root.name = "ThermonuclearDetonationFX"
	_nuke_mesh_root.visible = false
	add_child(_nuke_mesh_root)

	# 1. Incandescent Fireball Core (Sphere)
	_nuke_fireball_mi = MeshInstance3D.new()
	var fb_sphere := SphereMesh.new()
	fb_sphere.radius = 0.08
	fb_sphere.height = 0.16
	var fb_mat := StandardMaterial3D.new()
	fb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fb_mat.albedo_color = Color(1.0, 0.88, 0.35, 0.95)
	fb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_nuke_fireball_mi.mesh = fb_sphere
	_nuke_fireball_mi.material_override = fb_mat
	_nuke_mesh_root.add_child(_nuke_fireball_mi)

	# 2. Convective Columnar Stem (Cylinder)
	_nuke_stem_mi = MeshInstance3D.new()
	var stem_cyl := CylinderMesh.new()
	stem_cyl.top_radius = 0.045
	stem_cyl.bottom_radius = 0.02
	stem_cyl.height = 0.16
	var stem_mat := StandardMaterial3D.new()
	stem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stem_mat.albedo_color = Color(0.98, 0.45, 0.12, 0.90)
	stem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_nuke_stem_mi.mesh = stem_cyl
	_nuke_stem_mi.material_override = stem_mat
	_nuke_mesh_root.add_child(_nuke_stem_mi)

	# 3. Toroidal Mushroom Cap (Torus)
	_nuke_cap_mi = MeshInstance3D.new()
	var cap_torus := TorusMesh.new()
	cap_torus.inner_radius = 0.04
	cap_torus.outer_radius = 0.13
	var cap_mat := StandardMaterial3D.new()
	cap_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cap_mat.albedo_color = Color(0.88, 0.32, 0.10, 0.92)
	cap_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_nuke_cap_mi.mesh = cap_torus
	_nuke_cap_mi.material_override = cap_mat
	_nuke_mesh_root.add_child(_nuke_cap_mi)

	# 4. Supersonic Ground Blast Shockwave (Torus Ring)
	_nuke_shockwave_mi = MeshInstance3D.new()
	var shock_cyl := TorusMesh.new()
	shock_cyl.inner_radius = 0.18
	shock_cyl.outer_radius = 0.20
	var shock_mat := StandardMaterial3D.new()
	shock_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shock_mat.albedo_color = Color(1.0, 0.72, 0.25, 0.75)
	shock_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_nuke_shockwave_mi.mesh = shock_cyl
	_nuke_shockwave_mi.material_override = shock_mat
	_nuke_mesh_root.add_child(_nuke_shockwave_mi)


func _setup_flagship_multimeshes() -> void:
	var unshaded_mat := StandardMaterial3D.new()
	unshaded_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unshaded_mat.vertex_color_use_as_albedo = true
	unshaded_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var flagships: Array[Dictionary] = [
		{"name": "F35MultiMesh", "prop": "f35_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_F35},
		{"name": "J20MultiMesh", "prop": "j20_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_J20},
		{"name": "Su57MultiMesh", "prop": "su57_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_SU57},
		{"name": "B21MultiMesh", "prop": "b21_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_B21},
		{"name": "Cvn78MultiMesh", "prop": "cvn78_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_CVN78},
		{"name": "Type055MultiMesh", "prop": "type055_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_TYPE055},
		{"name": "M1A2MultiMesh", "prop": "m1a2_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_M1A2},
		{"name": "RobotDogMultiMesh", "prop": "robot_dog_mmi", "slug": PlatformMeshArmoryScript.FLAGSHIP_VISION60},
	]

	for cfg in flagships:
		var node_name: String = cfg["name"]
		var prop_name: String = cfg["prop"]
		var slug: String = cfg["slug"]
		var mmi: MultiMeshInstance3D = get_node_or_null(node_name) as MultiMeshInstance3D
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.name = node_name
			add_child(mmi)
		set(prop_name, mmi)

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = PlatformMeshArmoryScript.get_mesh_for_platform(slug, unshaded_mat)
		mm.instance_count = MAX_VISIBLE_FLAGSHIP
		mm.visible_instance_count = 0
		mmi.multimesh = mm

	# Defensive Countermeasure Flare Particles MultiMesh
	flares_mmi = get_node_or_null("FlaresMultiMesh") as MultiMeshInstance3D
	if flares_mmi == null:
		flares_mmi = MultiMeshInstance3D.new()
		flares_mmi.name = "FlaresMultiMesh"
		add_child(flares_mmi)

	var flare_box := BoxMesh.new()
	flare_box.size = Vector3(0.0035, 0.0035, 0.0035)
	flare_box.material = unshaded_mat

	var flare_mm := MultiMesh.new()
	flare_mm.transform_format = MultiMesh.TRANSFORM_3D
	flare_mm.use_colors = true
	flare_mm.mesh = flare_box
	flare_mm.instance_count = MAX_VISIBLE_FLARES
	flare_mm.visible_instance_count = 0
	flares_mmi.multimesh = flare_mm


func _setup_munition_multimeshes() -> void:
	var unshaded_mat := StandardMaterial3D.new()
	unshaded_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unshaded_mat.vertex_color_use_as_albedo = true
	unshaded_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mun_configs: Array[Dictionary] = [
		{"name": "ArtilleryMultiMesh", "prop": "artillery_mmi", "mesh": PlatformMeshArmoryScript.create_artillery_shell_mesh(unshaded_mat)},
		{"name": "CruiseMissileMultiMesh", "prop": "cruise_mmi", "mesh": PlatformMeshArmoryScript.create_cruise_missile_mesh(unshaded_mat)},
		{"name": "BallisticMissileMultiMesh", "prop": "ballistic_mmi", "mesh": PlatformMeshArmoryScript.create_ballistic_missile_mesh(unshaded_mat)},
		{"name": "LoiteringDroneMultiMesh", "prop": "drone_mmi", "mesh": PlatformMeshArmoryScript.create_loitering_drone_mesh(unshaded_mat)},
		{"name": "HypersonicGlideMultiMesh", "prop": "hypersonic_mmi", "mesh": PlatformMeshArmoryScript.create_hypersonic_glide_mesh(unshaded_mat)},
	]

	for cfg in mun_configs:
		var node_name: String = cfg["name"]
		var prop_name: String = cfg["prop"]
		var mmi: MultiMeshInstance3D = get_node_or_null(node_name) as MultiMeshInstance3D
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.name = node_name
			add_child(mmi)
		set(prop_name, mmi)

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = cfg["mesh"]
		mm.instance_count = MAX_VISIBLE_MUNITIONS
		mm.visible_instance_count = 0
		mmi.multimesh = mm


func _setup_real_city_labels() -> void:
	_city_labels_root = Node3D.new()
	_city_labels_root.name = "RealCityHologramLabels"
	add_child(_city_labels_root)

	for i in range(16):
		var lbl := Label3D.new()
		lbl.font_size = 18
		lbl.pixel_size = 0.0006
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.modulate = Color(0.45, 0.95, 1.0, 0.92) # Cyan holographic label
		lbl.outline_modulate = Color(0.0, 0.12, 0.25, 0.95)
		lbl.outline_size = 4
		lbl.visible = false
		_city_labels_root.add_child(lbl)
		_city_labels.append(lbl)


func _setup_floating_photo_cards() -> void:

	_photo_cards_root = Node3D.new()
	_photo_cards_root.name = "FloatingReconPhotoCards"
	add_child(_photo_cards_root)
	for i in range(MAX_FLOATING_PHOTO_CARDS):
		var sp := Sprite3D.new()
		sp.pixel_size = 0.00032
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.visible = false
		_photo_cards_root.add_child(sp)
		_photo_card_sprites.append(sp)

		var lbl := Label3D.new()
		lbl.font_size = 22
		lbl.pixel_size = 0.0008
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0.0, 0.036, 0.0)
		lbl.modulate = TacticalTheme.COL_NATO_BLUE
		sp.add_child(lbl)
		_photo_card_labels.append(lbl)


func _setup_command_radial_menu() -> void:
	_command_radial_root = Node3D.new()
	_command_radial_root.name = "DiegeticCommandRadial"
	_command_radial_root.visible = false
	add_child(_command_radial_root)

	var posture_names := [
		"MOVE",           # 0
		"ATTACK",         # 1
		"PATROL",         # 2
		"RECON",          # 3
		"HOLD / AMBUSH",  # 4
		"RETREAT"         # 5
	]

	var angles_deg := [90.0, 30.0, 330.0, 270.0, 210.0, 150.0]
	var radius_m := 0.052

	for i in range(posture_names.size()):
		var lbl := Label3D.new()
		lbl.font_size = 20
		lbl.pixel_size = 0.00062
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var rad := deg_to_rad(angles_deg[i])
		lbl.position = Vector3(cos(rad) * radius_m, 0.006, -sin(rad) * radius_m)
		lbl.text = "[ " + posture_names[i] + " ]"
		lbl.modulate = TacticalTheme.COL_NATO_BLUE
		lbl.outline_size = 3
		lbl.outline_modulate = Color.BLACK
		_command_radial_root.add_child(lbl)
		_radial_posture_labels.append(lbl)

	# Setup 3D Target Reticle for Hostile Designated Target
	_target_reticle_root = Node3D.new()
	_target_reticle_root.name = "DiegeticTargetReticle"
	_target_reticle_root.visible = false
	add_child(_target_reticle_root)

	_target_reticle_label = Label3D.new()
	_target_reticle_label.font_size = 18
	_target_reticle_label.pixel_size = 0.0006
	_target_reticle_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_target_reticle_label.position = Vector3(0.0, 0.038, 0.0)
	_target_reticle_label.modulate = Color(1.0, 0.22, 0.25, 0.98)
	_target_reticle_label.outline_size = 3
	_target_reticle_label.outline_modulate = Color.BLACK
	_target_reticle_label.text = "TARGET LOCK"
	_target_reticle_root.add_child(_target_reticle_label)


## Tests 6DOF raycast collision with the radial menu wedges
## Returns posture index (0..5) if hit, or -1 if missed
func check_radial_ray_intersection(ray_origin: Vector3, ray_dir: Vector3) -> int:
	if _command_radial_root == null or not _command_radial_root.visible:
		return -1
	var center := _command_radial_root.global_position if _command_radial_root.is_inside_tree() else _command_radial_root.position
	var denom := ray_dir.dot(Vector3.UP)
	if absf(denom) < 0.001:
		return -1
	var t := (center.y - ray_origin.y) / denom
	if t < 0.0 or t > 4.0:
		return -1
	var hit_pos := ray_origin + ray_dir * t
	var local_hit := hit_pos - center
	var dist := Vector2(local_hit.x, local_hit.z).length()
	if dist < 0.015 or dist > 0.075:
		return -1

	var hit_ang_deg := wrapf(rad_to_deg(atan2(-local_hit.z, local_hit.x)), 0.0, 360.0)
	var angles_deg := [90.0, 30.0, 330.0, 270.0, 210.0, 150.0]
	var best_idx := -1
	var min_diff := 999.0
	for i in range(angles_deg.size()):
		var diff := absf(wrapf(hit_ang_deg - angles_deg[i], -180.0, 180.0))
		if diff < min_diff and diff < 32.0:
			min_diff = diff
			best_idx = i
	return best_idx


## Actuates a posture command on currently selected units
func actuate_radial_posture(posture_idx: int) -> void:
	if posture_idx < 0 or posture_idx > 5:
		return
	var uids: Array = selected_unit_ids.duplicate()
	if uids.is_empty() and selected_unit_id >= 0:
		uids.append(selected_unit_id)
	if uids.is_empty():
		return
	var cmd_bus: Node = get_node_or_null("/root/CommandBus") if is_inside_tree() else null
	if cmd_bus != null:
		cmd_bus.enqueue_set_tactical_posture(uids, posture_idx)
	elif sim_server != null:
		for u in uids:
			if u >= 0 and u < sim_server.world_state.unit_count:
				sim_server.world_state.unit_tactical_posture[u] = posture_idx


func _process(_delta: float) -> void:
	sync_visuals()


func sync_visuals() -> void:
	if sim_server == null or war_table == null:
		return
	if sim_db == null:
		sim_db = sim_server.sim_db_ref
	if sim_db == null:
		return

	var pair: Array = sim_server.snapshot_buffer.get_read_pair()
	var prev_snap: RenderSnapshot.SnapshotData = pair[0]
	var curr_snap: RenderSnapshot.SnapshotData = pair[1]
	if curr_snap.unit_count == 0:
		return

	var elapsed_usec: int = Time.get_ticks_usec() - int(sim_server.snapshot_buffer.last_commit_usec)
	var alpha: float = clampf(float(elapsed_usec) / 100000.0, 0.0, 1.0)

	var active_echelon: int = war_table.get_active_semantic_echelon()
	var zoom: float = war_table.zoom_scale
	var expand_squads: bool = (zoom >= 2.8 or force_all_tokens)

	var token_mm := unit_tokens_mmi.multimesh
	var jet_mm := air_jets_mmi.multimesh
	var ship_mm := naval_ships_mmi.multimesh
	var soldier_mm := soldiers_mmi.multimesh
	var veh_mm := vehicles_mmi.multimesh
	var stem_mm := altitude_stems_mmi.multimesh
	var mun_mm := active_munitions_mmi.multimesh

	var token_idx := 0
	var jet_idx := 0
	var ship_idx := 0
	var soldier_idx := 0
	var veh_idx := 0
	var stem_idx := 0
	var photo_idx := 0

	var f35_idx := 0
	var j20_idx := 0
	var su57_idx := 0
	var b21_idx := 0
	var cvn78_idx := 0
	var type055_idx := 0
	var m1a2_idx := 0
	var dog_idx := 0
	var flare_idx := 0


	var platforms: Array = sim_db.platforms_by_id
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var p_de_kw: PackedFloat32Array = sim_db.plat_de_kw
	var max_pid: int = platforms.size()

	_trail_frame_counter += 1
	var record_trail_now: bool = (_trail_frame_counter % 2 == 0)

	beams_immediate.clear_surfaces()
	beams_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	var drew_any_line := false

	ribbons_immediate.clear_surfaces()
	ribbons_immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var drew_any_ribbon := false

	var has_orient_arrays := curr_snap.unit_heading_rad.size() >= curr_snap.unit_count
	var is_globe_mode: bool = (zoom < 0.42)
	var loop_unit_count: int = 0 if is_globe_mode else curr_snap.unit_count
	var sniper_commando_beam_idx: int = 0

	for uid in range(loop_unit_count):
		if curr_snap.unit_active[uid] == 0:
			continue

		var pid: int = curr_snap.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var dom_id: int = p_dom[pid]
		var flg: int = p_flags[pid]
		var ech: int = curr_snap.unit_echelon[uid]
		var fac: int = curr_snap.unit_faction[uid]

		if fac == WorldState.FACTION_RED and not true_sight_enabled:
			if (curr_snap.unit_detected_mask[uid] & 1) == 0 and ech == WorldState.ECHELON_COMPANY:
				continue

		var pos_curr: Vector3 = curr_snap.unit_pos[uid]
		var pos_prev: Vector3 = prev_snap.unit_pos[uid] if uid < prev_snap.unit_count else pos_curr
		var interp_km := pos_prev.lerp(pos_curr, alpha)

		var local_pos: Vector3 = war_table.theater_km_to_table_local(interp_km)
		if absf(local_pos.x) > 0.92 or absf(local_pos.z) > 0.92:
			continue

		var col := TacticalTheme.COL_NATO_BLUE if fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
		if (flg & int(sim_db.FLAG_UNMANNED | sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)) != 0:
			col = col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.48)
		elif p_de_kw[pid] > 0.0:
			col = col.lerp(TacticalTheme.COL_DIRECTED_ENERGY, 0.45)

		# Compute 3D Tacview Attitude Basis (Heading + Climb/Dive Pitch + Banking Roll)
		var attitude_basis := Basis()
		if has_orient_arrays:
			var hdg := curr_snap.unit_heading_rad[uid]
			var pitch := curr_snap.unit_pitch_rad[uid]
			var roll := curr_snap.unit_roll_rad[uid]
			attitude_basis = Basis.from_euler(Vector3(pitch, -hdg - PI * 0.5, roll))

		# ====================================================================
		# 1. RENDER LITTLE 3D TACVIEW MINIATURES FOR LEAF UNITS
		# At Macro Zoom (zoom < 2.2), only render core vanguard elements (uid < 260) or selected unit
		# so the 3D War Table stays clean and readable instead of a 2,500-mesh neon hairball!
		# ====================================================================
		var show_leaf_miniature: bool = (ech == WorldState.ECHELON_COMPANY) and (zoom >= 2.2 or force_all_tokens or uid < 260 or uid == selected_unit_id)
		if show_leaf_miniature:
			var unit_scale := clampf(1.0 + (zoom - 1.0) * 0.07, 1.0, 2.2)
			if uid == selected_unit_id:
				unit_scale *= 1.38

			if dom_id == 1:
				# AIR: 3D Tactical Jet / Bomber with Flagship Mesh Recognition & Defensive Flares!
				var jet_pos := local_pos + Vector3(0.0, 0.012, 0.0)
				var slug := String(platforms[pid].get("slug", ""))
				var is_f35: bool = (slug == PlatformMeshArmoryScript.FLAGSHIP_F35)
				var is_j20: bool = (slug == PlatformMeshArmoryScript.FLAGSHIP_J20)
				var is_su57: bool = (slug == PlatformMeshArmoryScript.FLAGSHIP_SU57)
				var is_b21: bool = (slug == PlatformMeshArmoryScript.FLAGSHIP_B21)
				var jet_col := col.lightened(0.28) if uid == selected_unit_id else col
				var jet_xform := Transform3D(attitude_basis.scaled(Vector3.ONE * unit_scale), jet_pos)

				if is_f35 and f35_idx < MAX_VISIBLE_FLAGSHIP and f35_mmi != null:
					f35_mmi.multimesh.set_instance_transform(f35_idx, jet_xform)
					f35_mmi.multimesh.set_instance_color(f35_idx, jet_col)
					f35_idx += 1
				elif is_j20 and j20_idx < MAX_VISIBLE_FLAGSHIP and j20_mmi != null:
					j20_mmi.multimesh.set_instance_transform(j20_idx, jet_xform)
					j20_mmi.multimesh.set_instance_color(j20_idx, jet_col)
					j20_idx += 1
				elif is_su57 and su57_idx < MAX_VISIBLE_FLAGSHIP and su57_mmi != null:
					su57_mmi.multimesh.set_instance_transform(su57_idx, jet_xform)
					su57_mmi.multimesh.set_instance_color(su57_idx, jet_col)
					su57_idx += 1
				elif is_b21 and b21_idx < MAX_VISIBLE_FLAGSHIP and b21_mmi != null:
					b21_mmi.multimesh.set_instance_transform(b21_idx, jet_xform)
					b21_mmi.multimesh.set_instance_color(b21_idx, jet_col)
					b21_idx += 1
				elif jet_idx < MAX_VISIBLE_JETS:
					jet_mm.set_instance_transform(jet_idx, jet_xform)
					jet_mm.set_instance_color(jet_idx, jet_col)
					jet_idx += 1

				# Tactical Countermeasure Flares deployed during evasive maneuvers (US-15.1)
				if curr_snap.unit_ai_state[uid] == WorldState.AI_EVASIVE_DEFENSIVE and flare_idx < MAX_VISIBLE_FLARES and flares_mmi != null:
					var flare_pos := jet_pos - attitude_basis.z * 0.018 + Vector3(0.0, -0.003, 0.0)
					flares_mmi.multimesh.set_instance_transform(flare_idx, Transform3D(Basis().scaled(Vector3.ONE * 1.8), flare_pos))
					flares_mmi.multimesh.set_instance_color(flare_idx, Color(1.0, 0.88, 0.35, 0.95))
					flare_idx += 1

				# 4-Ship Finger-Four Wingman Formation when zoomed in or selected
				if (expand_squads or uid == selected_unit_id) and (flg & int(sim_db.FLAG_TANKER | sim_db.FLAG_AWACS)) == 0:
					var wing_offsets := [
						Vector3(-0.015, -0.002, 0.013),
						Vector3(0.015, -0.002, 0.013),
						Vector3(0.030, -0.004, 0.026),
					]
					for w_off in wing_offsets:
						if jet_idx >= MAX_VISIBLE_JETS:
							break
						var w_off_v: Vector3 = w_off
						var w_pos: Vector3 = jet_pos + (attitude_basis * w_off_v)
						jet_mm.set_instance_transform(jet_idx, Transform3D(attitude_basis.scaled(Vector3.ONE * (unit_scale * 0.80)), w_pos))
						jet_mm.set_instance_color(jet_idx, col)
						jet_idx += 1

				# Banked 3D Tacview Ribbon Strip (`PRIMITIVE_TRIANGLES`) behind aircraft wings
				var wing_right := (attitude_basis.x).normalized() * (0.0085 * unit_scale)
				if record_trail_now:
					var hist: Array = _ribbon_history.get(uid, [])
					hist.append({"km": interp_km, "right": wing_right})
					if hist.size() > 10:
						hist.pop_front()
					_ribbon_history[uid] = hist

				if _ribbon_history.has(uid):
					var hist: Array = _ribbon_history[uid]
					var n_pts := hist.size()
					if n_pts >= 2:
						var prev_c := jet_pos
						var prev_r := wing_right
						for ri in range(n_pts - 1, -1, -1):
							var pt_d: Dictionary = hist[ri]
							var cur_c: Vector3 = war_table.theater_km_to_table_local(pt_d["km"]) + Vector3(0.0, 0.012, 0.0)
							var cur_r: Vector3 = pt_d["right"]
							if prev_c.distance_squared_to(cur_c) < 0.06:
								var fade := float(ri + 1) / float(n_pts + 1)
								var r_col := Color(col.r, col.g, col.b, 0.48 * fade)
								var p_l := prev_c - prev_r * fade
								var p_r := prev_c + prev_r * fade
								var c_l := cur_c - cur_r * (fade * 0.85)
								var c_r := cur_c + cur_r * (fade * 0.85)
								ribbons_immediate.surface_set_color(r_col)
								ribbons_immediate.surface_add_vertex(p_l)
								ribbons_immediate.surface_add_vertex(p_r)
								ribbons_immediate.surface_add_vertex(c_l)
								ribbons_immediate.surface_add_vertex(p_r)
								ribbons_immediate.surface_add_vertex(c_r)
								ribbons_immediate.surface_add_vertex(c_l)
								drew_any_ribbon = true
							prev_c = cur_c
							prev_r = cur_r

				# Vertical laser altitude stem for airborne units
				if stem_idx < MAX_VISIBLE_STEMS:
					var ground_local: Vector3 = war_table.theater_km_to_table_local(Vector3(interp_km.x, 0.0, interp_km.z))
					var stem_h := maxf(0.005, jet_pos.y - ground_local.y)
					var mid_y := ground_local.y + stem_h * 0.5
					var stem_xform := Transform3D(Basis().scaled(Vector3(1.0, stem_h, 1.0)), Vector3(jet_pos.x, mid_y, jet_pos.z))
					stem_mm.set_instance_transform(stem_idx, stem_xform)
					stem_mm.set_instance_color(stem_idx, Color(col.r, col.g, col.b, 0.35))
					stem_idx += 1

			elif dom_id == 2:
				# SEA: 3D Miniature Flagship Supercarrier / Cruiser / Generic Warship Hull
				var s_slug := String(platforms[pid].get("slug", ""))
				var is_cvn78: bool = (s_slug == PlatformMeshArmoryScript.FLAGSHIP_CVN78 or s_slug.find("carrier") != -1)
				var is_type055: bool = (s_slug == PlatformMeshArmoryScript.FLAGSHIP_TYPE055 or s_slug.find("type_055") != -1)
				var ship_pos := local_pos + Vector3(0.0, 0.002, 0.0)
				var ship_xform := Transform3D(attitude_basis.scaled(Vector3.ONE * unit_scale), ship_pos)
				var ship_col := col.lightened(0.20) if uid == selected_unit_id else col

				if is_cvn78 and cvn78_idx < MAX_VISIBLE_FLAGSHIP and cvn78_mmi != null:
					cvn78_mmi.multimesh.set_instance_transform(cvn78_idx, ship_xform)
					cvn78_mmi.multimesh.set_instance_color(cvn78_idx, ship_col)
					cvn78_idx += 1
				elif is_type055 and type055_idx < MAX_VISIBLE_FLAGSHIP and type055_mmi != null:
					type055_mmi.multimesh.set_instance_transform(type055_idx, ship_xform)
					type055_mmi.multimesh.set_instance_color(type055_idx, ship_col)
					type055_idx += 1
				elif ship_idx < MAX_VISIBLE_SHIPS:
					ship_mm.set_instance_transform(ship_idx, ship_xform)
					ship_mm.set_instance_color(ship_idx, ship_col)
					ship_idx += 1


			else:
				# LAND: Little 3D Soldiers, Snipers, Commandos, Quadruped Robot Dogs, Tanks, IFVs, Artillery & SAMs!
				var threat_disp: float = 1.0 + (curr_snap.unit_threat_level[uid] * 0.85 if uid < curr_snap.unit_threat_level.size() else 0.0)
				var march_phase := float(curr_snap.timestamp_sec) * 4.8 + float(uid) * 0.7
				var slug := String(platforms[pid].get("slug", ""))
				var is_sniper_or_commando: bool = slug in ["tier1_sniper_recon_team", "navy_seal_commando_squad", "specops_mountain_team", "spetsnaz_sniper_commando"]

				# A) Infantry Squads / Snipers / Commandos / Mech Dismounts -> 2 soldiers at macro zoom, 12 individual soldiers when zoomed in!
				if (flg & int(sim_db.FLAG_INFANTRY)) != 0 or is_sniper_or_commando or slug in ["m2a4_mech_company", "btr_4_bucephalus_co", "fpv_fiber_swarm", "switchblade_600_team", "lancet_3_team"]:
					var num_soldiers := 12 if (expand_squads or uid == selected_unit_id) else (4 if zoom >= 2.2 else 2)
					var soldier_col: Color = col.lightened(0.28)
					if is_sniper_or_commando:
						# High-contrast SpecOps Emerald-Lime for BLUE Snipers/SEALs, SpecOps Amber-Crimson for RED Spetsnaz
						soldier_col = Color(0.18, 1.0, 0.62, 1.0) if fac == WorldState.FACTION_BLUE else Color(1.0, 0.56, 0.14, 1.0)
					var s_scale := clampf(unit_scale * (1.10 if is_sniper_or_commando else 0.95), 0.75, 1.45)
					for s_i in range(num_soldiers):
						if soldier_idx >= MAX_VISIBLE_SOLDIERS:
							break
						var row := int(s_i / 4)
						var col_i := (s_i % 4) - 1.5
						var stride_z := sin(march_phase + float(s_i) * 1.1) * 0.0012
						var stride_bob := absf(cos(march_phase + float(s_i) * 1.1)) * 0.0006
						var s_off := Vector3(col_i * 0.0030 * threat_disp, 0.0008 + stride_bob, (float(row) * 0.0032 + absf(col_i) * 0.0012) * threat_disp + stride_z)
						var s_pos := local_pos + (attitude_basis * s_off)
						var s_basis := attitude_basis.scaled(Vector3.ONE * s_scale)
						soldier_mm.set_instance_transform(soldier_idx, Transform3D(s_basis, s_pos))
						soldier_mm.set_instance_color(soldier_idx, soldier_col)
						soldier_idx += 1

					# Live 3D Sniper .50 BMG Shots, JTAC Laser Target Designator Beams & Infantry Small-Arms Tracer Fire!
					var forward_dir := (-attitude_basis.z).normalized()
					var muzzle_origin := local_pos + Vector3(0.0, 0.0085, 0.0) + forward_dir * 0.008
					if is_sniper_or_commando:
						# Continuous pulsed JTAC Laser Target Designator beam + .50 BMG / Commando tracer streak
						var beam_len_m := clampf(0.055 * zoom, 0.024, 0.18) if zoom >= 2.0 else 0.022
						var sway_x := sin(march_phase * 0.35) * 0.012
						var laser_end := muzzle_origin + (forward_dir + attitude_basis.x * sway_x).normalized() * beam_len_m
						laser_end.y = maxf(local_pos.y + 0.003, laser_end.y - 0.002)
						var laser_col := Color(0.15, 1.0, 0.52, 0.82) if fac == WorldState.FACTION_BLUE else Color(1.0, 0.22, 0.32, 0.82)
						beams_immediate.surface_set_color(laser_col)
						beams_immediate.surface_add_vertex(muzzle_origin)
						beams_immediate.surface_add_vertex(laser_end)
						# High-velocity .50 BMG / Suppressed Commando tracer pulse traveling along the sightline
						var pulse_t := fmod(float(curr_snap.timestamp_sec) * 2.8 + float(uid) * 0.37, 1.0)
						var tr_a := muzzle_origin.lerp(laser_end, pulse_t * 0.78)
						var tr_b := muzzle_origin.lerp(laser_end, minf(1.0, pulse_t * 0.78 + 0.22))
						beams_immediate.surface_set_color(Color(1.0, 0.96, 0.55, 0.96))
						beams_immediate.surface_add_vertex(tr_a)
						beams_immediate.surface_add_vertex(tr_b)
						drew_any_line = true
						sniper_commando_beam_idx += 1
					elif zoom >= 2.2 and ((int(curr_snap.timestamp_sec * 4.0) + uid) % 3) == 0:
						# Periodic infantry small-arms suppressive tracer burst when zoomed in
						var burst_t := fmod(float(curr_snap.timestamp_sec) * 3.6 + float(uid) * 0.5, 1.0)
						var burst_end := muzzle_origin + forward_dir * clampf(0.032 * zoom, 0.028, 0.11)
						var b_a := muzzle_origin.lerp(burst_end, burst_t * 0.70)
						var b_b := muzzle_origin.lerp(burst_end, minf(1.0, burst_t * 0.70 + 0.25))
						var tr_col := Color(0.45, 0.95, 1.0, 0.85) if fac == WorldState.FACTION_BLUE else Color(1.0, 0.42, 0.22, 0.85)
						beams_immediate.surface_set_color(tr_col)
						beams_immediate.surface_add_vertex(b_a)
						beams_immediate.surface_add_vertex(b_b)
						drew_any_line = true
						sniper_commando_beam_idx += 1

				# B) Quadruped Robot Dog Packs -> 1 dog at macro zoom, 8 individual Robot Dogs when zoomed in!
				if (flg & int(sim_db.FLAG_ROBOT_DOG)) != 0 or slug == PlatformMeshArmoryScript.FLAGSHIP_VISION60:
					if robot_dog_mmi != null and dog_idx < MAX_VISIBLE_FLAGSHIP:
						var dog_xform := Transform3D(attitude_basis.scaled(Vector3.ONE * (unit_scale * 1.35)), local_pos + Vector3(0.0, 0.001, 0.0))
						robot_dog_mmi.multimesh.set_instance_transform(dog_idx, dog_xform)
						robot_dog_mmi.multimesh.set_instance_color(dog_idx, TacticalTheme.COL_UNMANNED_GOLD if fac == WorldState.FACTION_BLUE else col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.5))
						dog_idx += 1

					var num_dogs := 8 if (expand_squads or uid == selected_unit_id) else (3 if zoom >= 2.2 else 1)
					for d_i in range(num_dogs):
						if veh_idx >= MAX_VISIBLE_VEHICLES:
							break
						var d_row := int(d_i / 4)
						var d_col := (d_i % 4) - 1.5
						var bound_y := absf(sin(march_phase * 1.4 + float(d_i))) * 0.0010
						var d_off := Vector3(d_col * 0.0036 * threat_disp, 0.0010 + bound_y, float(d_row) * 0.0040 * threat_disp)
						var d_pos := local_pos + (attitude_basis * d_off)
						var dog_basis := attitude_basis.scaled(Vector3(0.45, 0.45, 0.55) * unit_scale)
						veh_mm.set_instance_transform(veh_idx, Transform3D(dog_basis, d_pos))
						veh_mm.set_instance_color(veh_idx, TacticalTheme.COL_UNMANNED_GOLD if fac == WorldState.FACTION_BLUE else col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.5))
						veh_idx += 1

				# C) Tanks / IFVs / Artillery / SAM TELs / Logistics -> 1 vehicle at macro zoom, 4 vehicles when zoomed in!
				elif (flg & int(sim_db.FLAG_INFANTRY)) == 0:
					var is_armor: bool = (flg & int(sim_db.FLAG_ARMOR)) != 0
					var turret_basis := attitude_basis
					if is_armor and uid < curr_snap.unit_turret_hdg_rad.size():
						var t_hdg: float = curr_snap.unit_turret_hdg_rad[uid]
						turret_basis = Basis.from_euler(Vector3(0.0, -t_hdg - PI * 0.5, 0.0))

					# Dedicated M1A2 SEPv3 Abrams 3D Mesh
					var is_m1a2: bool = (slug == PlatformMeshArmoryScript.FLAGSHIP_M1A2)
					if is_m1a2 and m1a2_mmi != null and m1a2_idx < MAX_VISIBLE_FLAGSHIP:
						var m1_xform := Transform3D(turret_basis.scaled(Vector3.ONE * unit_scale), local_pos + Vector3(0.0, 0.0014, 0.0))
						m1a2_mmi.multimesh.set_instance_transform(m1a2_idx, m1_xform)
						m1a2_mmi.multimesh.set_instance_color(m1a2_idx, col)
						m1a2_idx += 1

					var num_vehs := 4 if (expand_squads or uid == selected_unit_id) else (2 if zoom >= 2.2 else 1)
					for v_i in range(num_vehs):
						if veh_idx >= MAX_VISIBLE_VEHICLES:
							break
						var vx := (float(v_i) - 1.5) * 0.0065 * threat_disp
						var vz := absf(float(v_i) - 1.5) * 0.0045 * threat_disp
						var v_pos := local_pos + (attitude_basis * Vector3(vx, 0.0014, vz))
						# Lead tank uses turret-tracking orientation, wingmen follow hull heading
						var v_basis := turret_basis if (is_armor and v_i == 0) else attitude_basis
						veh_mm.set_instance_transform(veh_idx, Transform3D(v_basis.scaled(Vector3.ONE * unit_scale), v_pos))
						veh_mm.set_instance_color(veh_idx, col)
						veh_idx += 1

					# Combined arms tank 120mm APFSDS cannon fire tracer bursts along turret azimuth
					if zoom >= 2.0 and is_armor and ((int(curr_snap.timestamp_sec * 2.5) + uid) % 4) == 0:
						var fwd := (-turret_basis.z).normalized()
						var canon_orig := local_pos + Vector3(0.0, 0.006, 0.0) + fwd * 0.012
						var canon_end := canon_orig + fwd * clampf(0.05 * zoom, 0.03, 0.15)
						var pulse_t := fmod(float(curr_snap.timestamp_sec) * 4.0 + float(uid) * 0.5, 1.0)
						var c_a := canon_orig.lerp(canon_end, pulse_t * 0.8)
						var c_b := canon_orig.lerp(canon_end, minf(1.0, pulse_t * 0.8 + 0.2))
						beams_immediate.surface_set_color(Color(1.0, 0.85, 0.3, 0.95))
						beams_immediate.surface_add_vertex(c_a)
						beams_immediate.surface_add_vertex(c_b)
						drew_any_line = true

					# Ground SAM Radar Search & Lock-On Beam (US-15.2)
					if (flg & int(sim_db.FLAG_SAM)) != 0:
						var radar_hdg := fmod(float(curr_snap.timestamp_sec) * 1.5 + float(uid), TAU)
						var beam_len := 0.09 * unit_scale
						var beam_end := local_pos + Vector3(cos(radar_hdg) * beam_len, 0.055, sin(radar_hdg) * beam_len)
						var sam_beam_col := Color(1.0, 0.75, 0.20, 0.65) if fac == WorldState.FACTION_BLUE else Color(1.0, 0.25, 0.20, 0.65)
						beams_immediate.surface_set_color(sam_beam_col)
						beams_immediate.surface_add_vertex(local_pos + Vector3(0.0, 0.005, 0.0))
						beams_immediate.surface_add_vertex(beam_end)
						drew_any_line = true


		# ====================================================================
		# 2. RENDER HOLOGRAPHIC NATO TOKEN PLAQUES (FOR ACTIVE SEMANTIC ECHELON)
		# ====================================================================
		var render_plaque: bool = (ech == active_echelon) or (force_all_tokens and ech == WorldState.ECHELON_COMPANY) or (uid == selected_unit_id)
		if render_plaque and token_idx < MAX_VISIBLE_TOKENS:
			var scale_mult := 1.0
			if ech == WorldState.ECHELON_BRIGADE:
				scale_mult = 1.45
			elif ech == WorldState.ECHELON_BATTALION:
				scale_mult = 1.15
			elif dom_id == 1:
				scale_mult = 0.72

			var xform := Transform3D(Basis().scaled(Vector3.ONE * scale_mult), local_pos + Vector3(0.0, 0.006, 0.0))
			token_mm.set_instance_transform(token_idx, xform)
			token_mm.set_instance_color(token_idx, col)

			var hp_ratio := clampf(curr_snap.unit_hp[uid] / maxf(1.0, curr_snap.unit_max_hp[uid]), 0.0, 1.0)
			var ech_norm := float(ech) * 0.5
			var sym_code := 0.25
			if dom_id == 1:
				sym_code = 0.05
			elif (flg & int(sim_db.FLAG_SAM)) != 0 or p_de_kw[pid] > 0.0:
				sym_code = 0.50
			elif (flg & int(sim_db.FLAG_ROBOT_DOG | sim_db.FLAG_SWARM)) != 0:
				sym_code = 0.75
			elif dom_id == 2:
				sym_code = 0.95

			var sel_flag := 0.0
			if uid == selected_unit_id:
				sel_flag = 1.0
			elif curr_snap.unit_unmanned_bays[uid] > 0:
				sel_flag = 0.5
			token_mm.set_instance_custom_data(token_idx, Color(hp_ratio, ech_norm, sym_code, sel_flag))
			token_idx += 1

		# Waypoint vector line on table
		if curr_snap.unit_has_waypoint[uid] == 1 and (uid == selected_unit_id or ech >= WorldState.ECHELON_BATTALION):
			var wp_local: Vector3 = war_table.theater_km_to_table_local(curr_snap.unit_target_pos[uid])
			if absf(wp_local.x) <= 0.92 and absf(wp_local.z) <= 0.92:
				beams_immediate.surface_set_color(Color(col.r, col.g, col.b, 0.65))
				beams_immediate.surface_add_vertex(local_pos + Vector3(0.0, 0.006, 0.0))
				beams_immediate.surface_add_vertex(wp_local + Vector3(0.0, 0.006, 0.0))
				drew_any_line = true

		# Floating Real Wikipedia Photo Card when `recon_photo_mode` is ON or unit is selected
		if (recon_photo_mode or uid == selected_unit_id) and photo_idx < MAX_FLOATING_PHOTO_CARDS:
			var p_def: Dictionary = platforms[pid]
			var img_path := String(p_def.get("image_res_path", ""))
			var tex: Texture2D = sim_db.get_wiki_photo_texture(img_path)
			if tex != null:
				var sp := _photo_card_sprites[photo_idx]
				sp.texture = tex
				sp.position = local_pos + Vector3(0.0, 0.068, 0.0)
				sp.visible = true
				var lbl := _photo_card_labels[photo_idx]
				lbl.text = String(p_def.get("display_name", "")).substr(0, 22)
				lbl.modulate = TacticalTheme.COL_NATO_BLUE if fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
				photo_idx += 1

	for i in range(photo_idx, MAX_FLOATING_PHOTO_CARDS):
		_photo_card_sprites[i].visible = false

	token_mm.visible_instance_count = token_idx
	jet_mm.visible_instance_count = jet_idx
	ship_mm.visible_instance_count = ship_idx
	soldier_mm.visible_instance_count = soldier_idx
	veh_mm.visible_instance_count = veh_idx

	if f35_mmi != null and f35_mmi.multimesh != null:
		f35_mmi.multimesh.visible_instance_count = f35_idx
	if j20_mmi != null and j20_mmi.multimesh != null:
		j20_mmi.multimesh.visible_instance_count = j20_idx
	if su57_mmi != null and su57_mmi.multimesh != null:
		su57_mmi.multimesh.visible_instance_count = su57_idx
	if b21_mmi != null and b21_mmi.multimesh != null:
		b21_mmi.multimesh.visible_instance_count = b21_idx
	if cvn78_mmi != null and cvn78_mmi.multimesh != null:
		cvn78_mmi.multimesh.visible_instance_count = cvn78_idx
	if type055_mmi != null and type055_mmi.multimesh != null:
		type055_mmi.multimesh.visible_instance_count = type055_idx
	if m1a2_mmi != null and m1a2_mmi.multimesh != null:
		m1a2_mmi.multimesh.visible_instance_count = m1a2_idx
	if robot_dog_mmi != null and robot_dog_mmi.multimesh != null:
		robot_dog_mmi.multimesh.visible_instance_count = dog_idx
	if flares_mmi != null and flares_mmi.multimesh != null:
		flares_mmi.multimesh.visible_instance_count = flare_idx

	last_visible_token_count = token_idx
	last_visible_jet_count = jet_idx
	last_visible_ship_count = ship_idx
	last_visible_soldier_count = soldier_idx
	last_visible_vehicle_count = veh_idx
	last_visible_f35_count = f35_idx
	last_visible_j20_count = j20_idx
	last_visible_su57_count = su57_idx
	last_visible_b21_count = b21_idx
	last_visible_cvn78_count = cvn78_idx
	last_visible_type055_count = type055_idx
	last_visible_m1a2_count = m1a2_idx
	last_visible_dog_count = dog_idx
	last_visible_flare_count = flare_idx
	last_active_sniper_commando_beams_count = sniper_commando_beam_idx


	# ====================================================================
	# 3. SPREADING CIVILIAN DENSITY FIELD (civ/m^2 ON TERRAIN SHADER + ISO-DENSITY CONTOURS)
	# ====================================================================
	var civ_mm := civilian_dots_mmi.multimesh
	civ_mm.visible_instance_count = 0 # Replaced discrete dots with continuous spreading civ/m^2 terrain shader field

	var is_mobile_vr := OS.has_feature("android")
	var civ_tick_step := 10 if is_mobile_vr else 1
	if _last_civ_tick_id < 0 or absi(curr_snap.tick_id - _last_civ_tick_id) >= civ_tick_step:
		_last_civ_tick_id = curr_snap.tick_id
		var active_civ_cells := 0
		var civ_arr: PackedFloat32Array = sim_server.world_state.civ_density_m2
		for c_i in range(civ_arr.size()):
			if civ_arr[c_i] > 0.0005:
				active_civ_cells += 1
		last_active_civilian_cells_count = active_civ_cells
		last_visible_civilian_dot_count = active_civ_cells

	# Draw expanding 3D Holographic Iso-Density Evacuation Contours around populated urban hubs
	var sites: Array = sim_server.world_state.active_sites
	var evac_ratio := clampf(curr_snap.total_displaced_civilians / maxf(1.0, curr_snap.total_theater_civilians), 0.0, 0.65)
	if not is_globe_mode:
		for s_i in range(sites.size()):
			var st_d: Dictionary = sites[s_i]
			var sx := float(st_d.get("x_km", 0.0))
			var sz := float(st_d.get("z_km", 0.0))
			var local_rho: float = sim_server.world_state.sample_civilian_density_m2(sx, sz)
			if local_rho > 0.002:
				var spread_r_km := 14.0 + evac_ratio * 38.0
				var c_center: Vector3 = war_table.theater_km_to_table_local(Vector3(sx, 0.0, sz)) + Vector3(0.0, 0.003, 0.0)
				if absf(c_center.x) <= 0.88 and absf(c_center.z) <= 0.88:
					var ring_r_m := (spread_r_km / WarTable.THEATER_SIZE_KM) * WarTable.TABLE_SIZE_M * zoom
					var ring_segs := 16
					beams_immediate.surface_set_color(Color(1.0, 0.74, 0.18, 0.42))
					for rs in range(ring_segs):
						var a0 := float(rs) * TAU / float(ring_segs)
						var a1 := float(rs + 1) * TAU / float(ring_segs)
						beams_immediate.surface_add_vertex(c_center + Vector3(cos(a0) * ring_r_m, 0.0, sin(a0) * ring_r_m))
						beams_immediate.surface_add_vertex(c_center + Vector3(cos(a1) * ring_r_m, 0.0, sin(a1) * ring_r_m))
					drew_any_line = true

	# Update Active Munitions MultiMesh + 3D Tacview Parabolic Smoke Ribbons
	var mun_idx := 0
	var art_idx := 0
	var crm_idx := 0
	var bal_idx := 0
	var drn_idx := 0
	var hyp_idx := 0

	if not is_globe_mode:
		for mid in range(curr_snap.mun_count):
			if curr_snap.mun_active[mid] == 0:
				continue
			var m_curr := curr_snap.mun_pos[mid]
			var m_prev := prev_snap.mun_pos[mid] if (mid < prev_snap.mun_count and prev_snap.mun_active[mid] == 1) else m_curr
			var m_interp := m_prev.lerp(m_curr, alpha)
			var m_local: Vector3 = war_table.theater_km_to_table_local(m_interp)
			if absf(m_local.x) > 0.92 or absf(m_local.z) > 0.92:
				continue

			var m_fac := curr_snap.mun_faction[mid]
			var m_col := TacticalTheme.COL_NATO_BLUE if m_fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
			m_col = m_col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.35)

			# Sprint 16: Analytical tangent velocity orientation basis
			var m_hdg: float = curr_snap.mun_heading_rad[mid] if mid < curr_snap.mun_heading_rad.size() else 0.0
			var m_pitch: float = curr_snap.mun_pitch_rad[mid] if mid < curr_snap.mun_pitch_rad.size() else 0.0
			var cls_id: int = curr_snap.mun_class_id[mid] if mid < curr_snap.mun_class_id.size() else 0

			var m_basis := Basis()
			m_basis = m_basis.rotated(Vector3.UP, m_hdg)
			m_basis = m_basis.rotated(m_basis.x, m_pitch)
			var m_xform := Transform3D(m_basis, m_local)

			match cls_id:
				1: # 155mm Artillery Shell
					if artillery_mmi != null and art_idx < MAX_VISIBLE_MUNITIONS:
						artillery_mmi.multimesh.set_instance_transform(art_idx, m_xform)
						artillery_mmi.multimesh.set_instance_color(art_idx, m_col)
						art_idx += 1
				2: # Cruise Missile
					if cruise_mmi != null and crm_idx < MAX_VISIBLE_MUNITIONS:
						cruise_mmi.multimesh.set_instance_transform(crm_idx, m_xform)
						cruise_mmi.multimesh.set_instance_color(crm_idx, m_col)
						crm_idx += 1
				3: # Ballistic Missile / MRBM
					if ballistic_mmi != null and bal_idx < MAX_VISIBLE_MUNITIONS:
						ballistic_mmi.multimesh.set_instance_transform(bal_idx, m_xform)
						ballistic_mmi.multimesh.set_instance_color(bal_idx, m_col)
						bal_idx += 1
				4: # Loitering Drone
					if drone_mmi != null and drn_idx < MAX_VISIBLE_MUNITIONS:
						drone_mmi.multimesh.set_instance_transform(drn_idx, m_xform)
						drone_mmi.multimesh.set_instance_color(drn_idx, m_col)
						drn_idx += 1
				5: # Hypersonic Glide Vehicle
					if hypersonic_mmi != null and hyp_idx < MAX_VISIBLE_MUNITIONS:
						hypersonic_mmi.multimesh.set_instance_transform(hyp_idx, m_xform)
						hypersonic_mmi.multimesh.set_instance_color(hyp_idx, m_col)
						hyp_idx += 1
				_: # Generic fallback
					if mun_idx < MAX_VISIBLE_MUNITIONS:
						mun_mm.set_instance_transform(mun_idx, m_xform)
						mun_mm.set_instance_color(mun_idx, m_col)
						mun_idx += 1

			var s_pos := curr_snap.mun_start_pos[mid]
			var e_pos := curr_snap.mun_target_pos[mid]
			var prog := curr_snap.mun_flight_progress[mid]
			var tail_t := maxf(0.0, prog - 0.22)
			var tail_base_y := lerpf(s_pos.y, e_pos.y, tail_t)
			var tail_arc := 4.0 * tail_t * (1.0 - tail_t) * maxf(0.0, curr_snap.mun_apex_alt_m[mid] - maxf(s_pos.y, e_pos.y))
			var tail_km := Vector3(lerpf(s_pos.x, e_pos.x, tail_t), tail_base_y + tail_arc, lerpf(s_pos.z, e_pos.z, tail_t))
			var tail_local: Vector3 = war_table.theater_km_to_table_local(tail_km)
			var m_right := m_basis.x * 0.0045
			ribbons_immediate.surface_set_color(Color(m_col.r, m_col.g, m_col.b, 0.72))
			ribbons_immediate.surface_add_vertex(m_local - m_right)
			ribbons_immediate.surface_add_vertex(m_local + m_right)
			ribbons_immediate.surface_add_vertex(tail_local)
			drew_any_ribbon = true

			beams_immediate.surface_set_color(Color(m_col.r, m_col.g, m_col.b, 0.88))
			beams_immediate.surface_add_vertex(tail_local)
			beams_immediate.surface_add_vertex(m_local)
			drew_any_line = true

	mun_mm.visible_instance_count = mun_idx
	if artillery_mmi != null and artillery_mmi.multimesh != null:
		artillery_mmi.multimesh.visible_instance_count = art_idx
		last_visible_artillery_count = art_idx
	if cruise_mmi != null and cruise_mmi.multimesh != null:
		cruise_mmi.multimesh.visible_instance_count = crm_idx
		last_visible_cruise_count = crm_idx
	if ballistic_mmi != null and ballistic_mmi.multimesh != null:
		ballistic_mmi.multimesh.visible_instance_count = bal_idx
		last_visible_ballistic_count = bal_idx
	if drone_mmi != null and drone_mmi.multimesh != null:
		drone_mmi.multimesh.visible_instance_count = drn_idx
		last_visible_drone_count = drn_idx
	if hypersonic_mmi != null and hypersonic_mmi.multimesh != null:
		hypersonic_mmi.multimesh.visible_instance_count = hyp_idx
		last_visible_hypersonic_count = hyp_idx

	stem_mm.visible_instance_count = stem_idx
	last_visible_munition_count = mun_idx + art_idx + crm_idx + bal_idx + drn_idx + hyp_idx

	# ====================================================================
	# 4. 3D ORBITING SPACE FORCE SATELLITE CONSTELLATION (PLANETARY GLOBE & CONTINENTAL DOME)
	# ====================================================================
	var sat_mm := orbital_satellites_mmi.multimesh
	var sat_idx := 0
	var sat_cnt: int = curr_snap.sat_count
	for sid in range(sat_cnt):
		if curr_snap.sat_active[sid] == 0:
			continue
		var s_fac: int = curr_snap.sat_faction[sid]
		var s_role: int = curr_snap.sat_role[sid]
		var s_pos_km: Vector3 = curr_snap.sat_pos_km[sid]
		var s_dazzled: float = curr_snap.sat_dazzled_timer[sid]

		var s_local: Vector3 = Vector3.ZERO
		var nadir_local: Vector3 = Vector3.ZERO
		if is_globe_mode:
			# Level 1 Planetary Orbital Globe Mode: True 3D Keplerian spherical orbit around Earth hologram at (0, 0.42, 0)
			var inc_g := deg_to_rad(42.0 + float((sid * 19) % 55))
			var raan_g := float(sid) * (TAU / 12.0)
			var ph_g := float(curr_snap.timestamp_sec) * (0.28 if (sid % 2 == 0) else 0.19) + float(sid) * 0.52
			var dx := cos(raan_g) * cos(ph_g) - sin(raan_g) * sin(ph_g) * cos(inc_g)
			var dy := sin(ph_g) * sin(inc_g)
			var dz := sin(raan_g) * cos(ph_g) + cos(raan_g) * sin(ph_g) * cos(inc_g)
			var dir_3d := Vector3(dx, dy, dz).normalized()
			var orbit_r_m: float = 0.53 + float(sid % 4) * 0.025
			s_local = Vector3(0.0, 0.42, 0.0) + dir_3d * orbit_r_m
			nadir_local = Vector3(0.0, 0.42, 0.0) + dir_3d * 0.44
		else:
			# Level 2 Continental Curved Space & Theater Modes: Satellites fly in the Upper Orbital Dome above the table
			var scale_div: float = 2000.0 if zoom < 1.0 else 950.0
			var sx_m: float = clampf((s_pos_km.x / scale_div) * (WarTable.TABLE_SIZE_M * 0.5), -0.86, 0.86)
			var sz_m: float = clampf((s_pos_km.z / scale_div) * (WarTable.TABLE_SIZE_M * 0.5), -0.86, 0.86)
			var sy_m: float = 0.28 + clampf((s_pos_km.y - 450.0) / 20000.0, 0.0, 0.20)
			s_local = Vector3(sx_m, sy_m, sz_m)
			nadir_local = Vector3(sx_m, 0.01, sz_m)

		var s_col := TacticalTheme.COL_NATO_BLUE if s_fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
		if s_dazzled > 0.0:
			s_col = Color(1.0, 0.55, 0.15, 0.95)
		elif s_role == WorldState.SAT_ROLE_PNT_GPS:
			s_col = s_col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.45)
		elif s_role == WorldState.SAT_ROLE_RECON_SAR:
			s_col = s_col.lerp(TacticalTheme.COL_DIRECTED_ENERGY, 0.45)

		if sat_idx < MAX_VISIBLE_SATELLITES:
			var yaw_spin: float = float(curr_snap.timestamp_sec) * 0.8 + float(sid) * 0.5
			var sat_scale: float = 2.15 if is_globe_mode else (1.35 if zoom < 1.0 else 1.0)
			var sat_basis := Basis.from_euler(Vector3(0.0, yaw_spin, 0.0)).scaled(Vector3.ONE * sat_scale)
			sat_mm.set_instance_transform(sat_idx, Transform3D(sat_basis, s_local))
			sat_mm.set_instance_color(sat_idx, s_col)
			sat_idx += 1

		# Draw downward SAR Recon / SatCom / GPS Nadir Sensor Beam when in Continental or Planetary mode (or overhead)
		if zoom < 1.2 or (absf(s_local.x) < 0.55 and absf(s_local.z) < 0.55):
			var beam_alpha: float = 0.22 if s_dazzled > 0.0 else (0.58 if zoom < 1.0 else 0.28)
			beams_immediate.surface_set_color(Color(s_col.r, s_col.g, s_col.b, beam_alpha))
			beams_immediate.surface_add_vertex(s_local)
			beams_immediate.surface_add_vertex(nadir_local)
			drew_any_line = true

	sat_mm.visible_instance_count = sat_idx
	last_visible_satellite_count = sat_idx

	# ====================================================================
	# 5. PROCEDURAL 3D CITIES, TOWNS, VILLAGES, AIRPORTS/AIRFIELDS, BRIDGES & 3D LOGISTICS TRAINS
	# ====================================================================
	var bldg_mm := urban_buildings_mmi.multimesh
	var train_mm := rail_trains_mmi.multimesh
	var bldg_idx := last_visible_building_count
	var train_car_idx := 0

	if not is_globe_mode and zoom >= 0.65:
		var ws_ref: WorldState = sim_server.world_state
		var b_cnt: int = ws_ref.bldg_count
		var cur_pan: Vector2 = war_table.pan_offset_km
		var cur_destr_cnt: int = ws_ref.active_destroyed_cells_count
		var cur_theater: String = ws_ref.active_theater_slug
		var need_bldg_rebuild: bool = (
			absf(zoom - _last_bldg_zoom) > 0.002
			or cur_pan.distance_squared_to(_last_bldg_pan) > 0.002
			or cur_destr_cnt != _last_bldg_destr_count
			or b_cnt != _last_bldg_total_count
			or is_globe_mode != _last_bldg_globe
			or cur_theater != _last_bldg_theater
		)

		if need_bldg_rebuild:
			_last_bldg_zoom = zoom
			_last_bldg_pan = cur_pan
			_last_bldg_destr_count = cur_destr_cnt
			_last_bldg_total_count = b_cnt
			_last_bldg_globe = is_globe_mode
			_last_bldg_theater = cur_theater
			bldg_idx = 0

			var b_pos_arr: PackedVector3Array = ws_ref.bldg_pos_km
			var b_scl_arr: PackedVector3Array = ws_ref.bldg_scale_m
			var b_yaw_arr: PackedFloat32Array = ws_ref.bldg_yaw_rad
			var b_typ_arr: PackedByteArray = ws_ref.bldg_type
			var b_cell_arr: PackedInt32Array = ws_ref.bldg_cell_idx
			var destr_arr: PackedFloat32Array = curr_snap.destruction_level if curr_snap.destruction_level.size() > 0 else ws_ref.destruction_level
			var destr_len: int = destr_arr.size()
			var bldg_zoom_mult: float = clampf(0.85 + (zoom - 1.0) * 0.14, 0.75, 2.4)

			for bi in range(b_cnt):
				if bldg_idx >= MAX_VISIBLE_BUILDINGS:
					break
				var b_km: Vector3 = b_pos_arr[bi]
				var b_loc: Vector3 = war_table.theater_km_to_table_local(b_km)
				if absf(b_loc.x) > 0.89 or absf(b_loc.z) > 0.89:
					continue

				var b_type: int = b_typ_arr[bi]
				var c_idx: int = b_cell_arr[bi]
				var d_lvl: float = destr_arr[c_idx] if (c_idx >= 0 and c_idx < destr_len) else 0.0
				var scl: Vector3 = b_scl_arr[bi] * bldg_zoom_mult
				var yaw: float = b_yaw_arr[bi]
				var pitch_tilt := 0.0
				var b_col := Color(0.12, 0.68, 0.72, 1.0)

				if b_type == WorldState.BLDG_LANDMARK_SKYSCRAPER:
					b_col = Color(0.25, 1.0, 0.65, 1.0) # Radiant Emerald / Iconic City Spire
				elif b_type == WorldState.BLDG_PORT_CONTAINER_CRANE:
					b_col = Color(1.0, 0.58, 0.18, 1.0) # High-visibility Industrial Maritime Crane
				elif b_type == WorldState.BLDG_URBAN_TOWER:
					b_col = Color(0.18, 0.82, 0.95, 1.0)
				elif b_type == WorldState.BLDG_VILLAGE_HOUSE:
					b_col = Color(0.85, 0.68, 0.28, 1.0)
				elif b_type == WorldState.BLDG_AIRPORT_RUNWAY:
					b_col = Color(0.22, 0.95, 1.0, 1.0)
				elif b_type == WorldState.BLDG_AIRPORT_HANGAR:
					b_col = Color(0.35, 0.78, 0.88, 1.0)
				elif b_type == WorldState.BLDG_BRIDGE_SPAN:
					b_col = Color(1.0, 0.78, 0.22, 1.0)
				elif b_type == WorldState.BLDG_ROAD_AVENUE:
					b_col = Color(0.98, 0.86, 0.42, 1.0)

				# Dynamic War Destruction: buildings collapse in height, tilt, and turn into smoldering rubble!
				if d_lvl > 0.15:
					var collapse: float = clampf(1.0 - d_lvl * 0.68, 0.22, 1.0)
					scl.y *= collapse
					if b_type != WorldState.BLDG_AIRPORT_RUNWAY and b_type != WorldState.BLDG_ROAD_AVENUE:
						pitch_tilt = d_lvl * 0.28 * (1.0 if (bi & 1) == 0 else -1.0)
					var rubble_col := Color(0.78, 0.22, 0.10, 1.0) if d_lvl > 0.5 else Color(0.45, 0.24, 0.16, 1.0)
					b_col = b_col.lerp(rubble_col, clampf(d_lvl * 1.25, 0.0, 1.0))

				var b_basis := Basis.from_euler(Vector3(pitch_tilt, yaw, 0.0)).scaled(scl)
				var b_pos_final := b_loc + Vector3(0.0, scl.y * 0.5, 0.0)
				bldg_mm.set_instance_transform(bldg_idx, Transform3D(b_basis, b_pos_final))
				bldg_mm.set_instance_color(bldg_idx, b_col)
				bldg_idx += 1

			bldg_mm.visible_instance_count = bldg_idx
			last_visible_building_count = bldg_idx

		# Render 3D Terrain-Hugging Inter-City Highway Network (`road_segments_km`) & Metropolitan Street Grids (`city_hubs_km`)
		if not is_mobile_vr:
			var hwy_col := Color(1.0, 0.86, 0.36, 0.68)
			var street_col := Color(0.55, 0.94, 1.0, 0.58)
			for seg4 in ws_ref.road_segments_km:
				var a_km2 := Vector2(seg4.x, seg4.y)
				var b_km2 := Vector2(seg4.z, seg4.w)
				var sub_steps := 8
				for s_i in range(sub_steps):
					var t0 := float(s_i) / float(sub_steps)
					var t1 := float(s_i + 1) / float(sub_steps)
					var p0_2 := a_km2.lerp(b_km2, t0)
					var p1_2 := a_km2.lerp(b_km2, t1)
					var l0: Vector3 = war_table.theater_km_to_table_local(Vector3(p0_2.x, 0.0, p0_2.y)) + Vector3(0.0, 0.0024, 0.0)
					var l1: Vector3 = war_table.theater_km_to_table_local(Vector3(p1_2.x, 0.0, p1_2.y)) + Vector3(0.0, 0.0024, 0.0)
					if absf(l0.x) <= 0.89 and absf(l0.z) <= 0.89 and absf(l1.x) <= 0.89 and absf(l1.z) <= 0.89:
						beams_immediate.surface_set_color(hwy_col)
						beams_immediate.surface_add_vertex(l0)
						beams_immediate.surface_add_vertex(l1)
						drew_any_line = true

			for hub3 in ws_ref.city_hubs_km:
				var cx_km := hub3.x
				var cz_km := hub3.y
				var r_km := hub3.z
				var c_loc: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km, 0.0, cz_km)) + Vector3(0.0, 0.0026, 0.0)
				if absf(c_loc.x) > 0.88 or absf(c_loc.z) > 0.88:
					continue
				# Draw 3D Urban Ring Road + Parallel City Block Street Grid around each city hub
				var ring_segs := 12
				beams_immediate.surface_set_color(hwy_col)
				for rs in range(ring_segs):
					var a0 := float(rs) * TAU / float(ring_segs)
					var a1 := float(rs + 1) * TAU / float(ring_segs)
					var rp0: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km + cos(a0) * r_km * 0.65, 0.0, cz_km + sin(a0) * r_km * 0.65)) + Vector3(0.0, 0.0026, 0.0)
					var rp1: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km + cos(a1) * r_km * 0.65, 0.0, cz_km + sin(a1) * r_km * 0.65)) + Vector3(0.0, 0.0026, 0.0)
					beams_immediate.surface_add_vertex(rp0)
					beams_immediate.surface_add_vertex(rp1)
				var grid_lines: Array[float] = [-0.55, 0.0, 0.55]
				for g_line in grid_lines:
					var off_km: float = float(g_line) * r_km
					beams_immediate.surface_set_color(hwy_col if g_line == 0.0 else street_col)
					var ns0: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km + off_km, 0.0, cz_km - r_km * 0.85)) + Vector3(0.0, 0.0026, 0.0)
					var ns1: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km + off_km, 0.0, cz_km + r_km * 0.85)) + Vector3(0.0, 0.0026, 0.0)
					var ew0: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km - r_km * 0.85, 0.0, cz_km + off_km)) + Vector3(0.0, 0.0026, 0.0)
					var ew1: Vector3 = war_table.theater_km_to_table_local(Vector3(cx_km + r_km * 0.85, 0.0, cz_km + off_km)) + Vector3(0.0, 0.0026, 0.0)
					beams_immediate.surface_add_vertex(ns0)
					beams_immediate.surface_add_vertex(ns1)
					beams_immediate.surface_add_vertex(ew0)
					beams_immediate.surface_add_vertex(ew1)
				drew_any_line = true

			# Real Named City 3D Holographic Badges (OpenStreetMap GIS Integration)
			var real_cities := CivilianDensitySystem.get_theater_real_cities(ws_ref.active_theater_slug)
			for c_i in range(_city_labels.size()):
				var lbl: Label3D = _city_labels[c_i]
				if c_i < real_cities.size() and zoom >= 0.75:
					var rc_d: Dictionary = real_cities[c_i]
					var rc_x: float = float(rc_d.get("x_km", 0.0))
					var rc_z: float = float(rc_d.get("z_km", 0.0))
					var rc_loc: Vector3 = war_table.theater_km_to_table_local(Vector3(rc_x, 0.0, rc_z))
					if absf(rc_loc.x) <= 0.88 and absf(rc_loc.z) <= 0.88:
						lbl.text = String(rc_d.get("name", "CITY"))
						lbl.position = rc_loc + Vector3(0.0, 0.052, 0.0)
						lbl.visible = true
					else:
						lbl.visible = false
				else:
					lbl.visible = false

		# Render 3D Multi-Car Military Echelon Logistics Trains along Strategic Railways

		var t_cnt: int = curr_snap.train_count
		var train_scale: float = clampf(1.0 + (zoom - 1.0) * 0.10, 0.9, 2.0)
		for tid in range(t_cnt):
			if curr_snap.train_active[tid] == 0:
				continue
			var t_pos_km: Vector3 = curr_snap.train_pos_km[tid]
			var t_loc: Vector3 = war_table.theater_km_to_table_local(t_pos_km)
			if absf(t_loc.x) > 0.88 or absf(t_loc.z) > 0.88:
				continue

			var t_fac: int = curr_snap.train_faction[tid]
			var t_hdg: float = curr_snap.train_heading_rad[tid]
			var is_derailed: bool = (curr_snap.train_derailed[tid] == 1)
			var t_col := TacticalTheme.COL_NATO_BLUE if t_fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
			t_col = t_col.lerp(TacticalTheme.COL_UNMANNED_GOLD, 0.55)
			if is_derailed:
				t_col = Color(0.95, 0.25, 0.12, 1.0)

			var t_basis := Basis.from_euler(Vector3(0.0, -t_hdg - PI * 0.5, 0.25 if is_derailed else 0.0)).scaled(Vector3.ONE * train_scale)
			var forward_dir := Vector3(cos(t_hdg), 0.0, sin(t_hdg))
			# Render 4 coupled cars per train (Locomotive + 3 Armored Flatcars)
			for car_i in range(4):
				if train_car_idx >= MAX_VISIBLE_TRAIN_CARS:
					break
				var car_off_m: Vector3 = -forward_dir * (float(car_i) * 0.0125 * train_scale)
				var car_pos: Vector3 = t_loc + car_off_m + Vector3(0.0, 0.0028, 0.0)
				train_mm.set_instance_transform(train_car_idx, Transform3D(t_basis, car_pos))
				train_mm.set_instance_color(train_car_idx, t_col.lightened(0.22) if car_i == 0 else t_col)
				train_car_idx += 1

		# Phase 26: Render Live 3D Highway Traffic Convoys, Refugee Evacuation Columns & Commercial Maritime Tankers
		var c_cnt: int = ws_ref.convoy_count
		for cid in range(c_cnt):
			if ws_ref.convoy_active[cid] == 0:
				continue
			var c_pos_km: Vector3 = ws_ref.convoy_pos_km[cid]
			var c_loc: Vector3 = war_table.theater_km_to_table_local(c_pos_km)
			if absf(c_loc.x) > 0.88 or absf(c_loc.z) > 0.88:
				continue
			var c_type: int = ws_ref.convoy_type[cid]
			var c_hdg: float = ws_ref.convoy_heading_rad[cid]
			var c_fac: int = ws_ref.convoy_faction[cid]
			var c_col := Color(0.98, 0.92, 0.55, 0.95)
			if c_type == WorldState.CONVOY_REFUGEE_EVAC:
				c_col = Color(0.25, 1.0, 0.65, 0.98) if ws_ref.humanitarian_corridor_active else Color(1.0, 0.78, 0.22, 0.95)
			elif c_type == WorldState.CONVOY_MILITARY_SUPPLY:
				c_col = TacticalTheme.COL_NATO_BLUE if c_fac == WorldState.FACTION_BLUE else TacticalTheme.COL_OPFOR_RED
			elif c_type == WorldState.CONVOY_MARITIME_TANKER:
				c_col = Color(0.35, 0.95, 0.85, 0.95) if c_fac == WorldState.FACTION_BLUE else Color(1.0, 0.52, 0.25, 0.95)

			var c_scale := train_scale * (1.25 if c_type == WorldState.CONVOY_MARITIME_TANKER else 0.68)
			var c_basis := Basis.from_euler(Vector3(0.0, -c_hdg - PI * 0.5, 0.0)).scaled(Vector3.ONE * c_scale)
			var c_fwd := Vector3(cos(c_hdg), 0.0, sin(c_hdg))
			var num_vehicles := 1 if c_type == WorldState.CONVOY_MARITIME_TANKER else 2
			for v_k in range(num_vehicles):
				if train_car_idx >= MAX_VISIBLE_TRAIN_CARS:
					break
				var v_off: Vector3 = -c_fwd * (float(v_k) * 0.0085 * train_scale)
				train_mm.set_instance_transform(train_car_idx, Transform3D(c_basis, c_loc + v_off + Vector3(0.0, 0.0024, 0.0)))
				train_mm.set_instance_color(train_car_idx, c_col)
				train_car_idx += 1

		# Phase 27: Render 3D Subterranean Underground Tunnel Networks & Portal Entrances
		for tc in ws_ref.tunnel_complexes:
			var is_disc: bool = bool(tc.get("discovered_by_blue", false)) or true_sight_enabled
			if not is_disc:
				continue
			var pa_km: Vector3 = tc.get("portal_a_km", Vector3.ZERO)
			var pb_km: Vector3 = tc.get("portal_b_km", Vector3.ZERO)
			var pa_loc: Vector3 = war_table.theater_km_to_table_local(pa_km) + Vector3(0.0, 0.004, 0.0)
			var pb_loc: Vector3 = war_table.theater_km_to_table_local(pb_km) + Vector3(0.0, 0.004, 0.0)
			if absf(pa_loc.x) > 0.89 or absf(pa_loc.z) > 0.89:
				continue
			var is_col: bool = bool(tc.get("collapsed", false))
			var t_owner: int = int(tc.get("faction_owner", WorldState.FACTION_RED))
			var tun_col := Color(0.45, 0.45, 0.45, 0.55) if is_col else (Color(0.25, 0.95, 1.0, 0.85) if t_owner == WorldState.FACTION_BLUE else Color(0.95, 0.35, 0.95, 0.85))
			beams_immediate.surface_set_color(tun_col)
			beams_immediate.surface_add_vertex(pa_loc)
			beams_immediate.surface_add_vertex(pb_loc)
			var p_rad := 0.012
			for ps in range(6):
				var pa0 := float(ps) * TAU / 6.0
				var pa1 := float(ps + 1) * TAU / 6.0
				beams_immediate.surface_add_vertex(pa_loc + Vector3(cos(pa0) * p_rad, 0.0, sin(pa0) * p_rad))
				beams_immediate.surface_add_vertex(pa_loc + Vector3(cos(pa1) * p_rad, 0.0, sin(pa1) * p_rad))
				beams_immediate.surface_add_vertex(pb_loc + Vector3(cos(pa0) * p_rad, 0.0, sin(pa0) * p_rad))
				beams_immediate.surface_add_vertex(pb_loc + Vector3(cos(pa1) * p_rad, 0.0, sin(pa1) * p_rad))
			drew_any_line = true

		# Phase 28: Render 3D DRFM Holographic Phantom Radar Ghost Decoys (`ghost_decoy_positions_km`)
		for g_km in ws_ref.ghost_decoy_positions_km:
			var g_loc: Vector3 = war_table.theater_km_to_table_local(g_km)
			var g_gnd: Vector3 = war_table.theater_km_to_table_local(Vector3(g_km.x, 0.0, g_km.z))
			if absf(g_loc.x) <= 0.88 and absf(g_loc.z) <= 0.88:
				var d_sz := 0.014
				beams_immediate.surface_set_color(Color(0.35, 1.0, 0.95, 0.85))
				beams_immediate.surface_add_vertex(g_gnd)
				beams_immediate.surface_add_vertex(g_loc)
				beams_immediate.surface_add_vertex(g_loc + Vector3(-d_sz, 0.0, 0.0))
				beams_immediate.surface_add_vertex(g_loc + Vector3(0.0, 0.0, d_sz))
				beams_immediate.surface_add_vertex(g_loc + Vector3(0.0, 0.0, d_sz))
				beams_immediate.surface_add_vertex(g_loc + Vector3(d_sz, 0.0, 0.0))
				beams_immediate.surface_add_vertex(g_loc + Vector3(d_sz, 0.0, 0.0))
				beams_immediate.surface_add_vertex(g_loc + Vector3(0.0, 0.0, -d_sz))
				beams_immediate.surface_add_vertex(g_loc + Vector3(0.0, 0.0, -d_sz))
				beams_immediate.surface_add_vertex(g_loc + Vector3(-d_sz, 0.0, 0.0))
				drew_any_line = true
	else:
		bldg_idx = 0
		_last_bldg_zoom = -1.0

	bldg_mm.visible_instance_count = bldg_idx
	train_mm.visible_instance_count = train_car_idx
	last_visible_building_count = bldg_idx
	last_visible_train_car_count = train_car_idx

	# Draw Directed Energy Beams (Iron Beam 100kW Laser & Epirus Leonidas 30° HPM Cones)
	for b in curr_snap.active_beams:
		var s_loc: Vector3 = war_table.theater_km_to_table_local(b["shooter_pos"]) + Vector3(0.0, 0.01, 0.0)
		var t_loc: Vector3 = war_table.theater_km_to_table_local(b["target_pos"]) + Vector3(0.0, 0.01, 0.0)
		var is_hpm: bool = bool(b.get("is_hpm_cone", false))
		if is_hpm:
			beams_immediate.surface_set_color(TacticalTheme.COL_DIRECTED_ENERGY)
			var dir_xz := Vector2(t_loc.x - s_loc.x, t_loc.z - s_loc.z)
			var base_ang := dir_xz.angle()
			var r_len := maxf(0.04, dir_xz.length())
			for c_step in range(-3, 4):
				var ang := base_ang + deg_to_rad(float(c_step) * 5.0)
				var fan_pt := s_loc + Vector3(cos(ang) * r_len, 0.015, sin(ang) * r_len)
				beams_immediate.surface_add_vertex(s_loc)
				beams_immediate.surface_add_vertex(fan_pt)
			drew_any_line = true
		else:
			beams_immediate.surface_set_color(Color(0.45, 0.95, 1.0, 0.98))
			beams_immediate.surface_add_vertex(s_loc)
			beams_immediate.surface_add_vertex(t_loc)
			drew_any_line = true

	# Draw Expanding Holographic Shockwave Rings at missile impact / intercept points
	for imp in curr_snap.recent_impacts:
		var imp_loc: Vector3 = war_table.theater_km_to_table_local(imp["pos_km"]) + Vector3(0.0, 0.008, 0.0)
		var ttl: float = float(imp.get("ttl", 1.0))
		var is_int: bool = bool(imp.get("is_intercept", false))
		var ring_col := TacticalTheme.COL_NATO_BLUE if is_int else TacticalTheme.COL_UNMANNED_GOLD
		var ring_r := clampf((2.2 - ttl) * 0.028, 0.005, 0.06)
		var segs := 12
		beams_immediate.surface_set_color(Color(ring_col.r, ring_col.g, ring_col.b, clampf(ttl * 0.5, 0.1, 0.9)))
		for s in range(segs):
			var a0 := float(s) * TAU / float(segs)
			var a1 := float(s + 1) * TAU / float(segs)
			beams_immediate.surface_add_vertex(imp_loc + Vector3(cos(a0) * ring_r, 0.0, sin(a0) * ring_r))
			beams_immediate.surface_add_vertex(imp_loc + Vector3(cos(a1) * ring_r, 0.0, sin(a1) * ring_r))
		drew_any_line = true

	# Draw Sprint 16 Special Weapons CBRN & Electromagnetic Hazards
	for hz in curr_snap.active_cbrn_hazards:
		var hz_type: String = String(hz.get("type", "CHEMICAL"))
		var hz_pos: Vector3 = hz.get("pos_km", Vector3.ZERO)
		var hz_rad: float = float(hz.get("radius_km", 14.0))
		var hz_loc: Vector3 = war_table.theater_km_to_table_local(hz_pos)
		if absf(hz_loc.x) > 0.92 or absf(hz_loc.z) > 0.92:
			continue

		var tbl_r := (hz_rad / WarTable.THEATER_SIZE_KM) * WarTable.TABLE_SIZE_M * zoom
		match hz_type:
			"CHEMICAL":
				beams_immediate.surface_set_color(Color(0.72, 0.88, 0.15, 0.65))
				for seg in range(16):
					var a0 := float(seg) * TAU / 16.0
					var a1 := float(seg + 1) * TAU / 16.0
					var p0 := hz_loc + Vector3(cos(a0) * tbl_r, 0.003, sin(a0) * tbl_r)
					var p1 := hz_loc + Vector3(cos(a1) * tbl_r, 0.003, sin(a1) * tbl_r)
					beams_immediate.surface_add_vertex(p0)
					beams_immediate.surface_add_vertex(p1)
					var p0_in := hz_loc + Vector3(cos(a0) * tbl_r * 0.55, 0.004, sin(a0) * tbl_r * 0.55)
					var p1_in := hz_loc + Vector3(cos(a1) * tbl_r * 0.55, 0.004, sin(a1) * tbl_r * 0.55)
					beams_immediate.surface_add_vertex(p0_in)
					beams_immediate.surface_add_vertex(p1_in)
				drew_any_line = true

			"BIOLOGICAL":
				beams_immediate.surface_set_color(Color(0.75, 0.40, 0.95, 0.70))
				for seg in range(24):
					var a0 := float(seg) * TAU / 24.0
					var a1 := float(seg + 1) * TAU / 24.0
					var p0 := hz_loc + Vector3(cos(a0) * tbl_r, 0.006, sin(a0) * tbl_r)
					var p1 := hz_loc + Vector3(cos(a1) * tbl_r, 0.006, sin(a1) * tbl_r)
					beams_immediate.surface_add_vertex(p0)
					beams_immediate.surface_add_vertex(p1)
				drew_any_line = true

			"ELECTROMAGNETIC":
				beams_immediate.surface_set_color(Color(0.20, 0.85, 1.0, 0.90))
				for seg in range(20):
					var a0 := float(seg) * TAU / 20.0
					var a1 := float(seg + 1) * TAU / 20.0
					var p0 := hz_loc + Vector3(cos(a0) * tbl_r, 0.008, sin(a0) * tbl_r)
					var p1 := hz_loc + Vector3(cos(a1) * tbl_r, 0.008, sin(a1) * tbl_r)
					beams_immediate.surface_add_vertex(p0)
					beams_immediate.surface_add_vertex(p1)
					var p0_m := hz_loc + Vector3(cos(a0) * tbl_r, sin(a0) * tbl_r * 0.65, sin(a0) * tbl_r * 0.35)
					var p1_m := hz_loc + Vector3(cos(a1) * tbl_r, sin(a1) * tbl_r * 0.65, sin(a1) * tbl_r * 0.35)
					beams_immediate.surface_add_vertex(p0_m)
					beams_immediate.surface_add_vertex(p1_m)
				drew_any_line = true

	# Sprint 17: Draw EW Countermeasures (Towed Decoys, Chaff Clouds, GPS Denial Zones)
	for dec in curr_snap.active_towed_decoys:
		if not bool(dec.get("active", false)):
			continue
		var h_uid: int = int(dec.get("host_uid", -1))
		var d_pos: Vector3 = dec.get("pos_km", Vector3.ZERO)
		var d_loc: Vector3 = war_table.theater_km_to_table_local(d_pos)
		if absf(d_loc.x) > 0.95 or absf(d_loc.z) > 0.95:
			continue
		if h_uid >= 0 and h_uid < curr_snap.unit_count and curr_snap.unit_active[h_uid] == 1:
			var h_loc: Vector3 = war_table.theater_km_to_table_local(curr_snap.unit_pos[h_uid])
			# Tether line
			beams_immediate.surface_set_color(Color(1.0, 0.85, 0.25, 0.70))
			beams_immediate.surface_add_vertex(h_loc)
			beams_immediate.surface_add_vertex(d_loc)
			# Decoy cross-beacon
			beams_immediate.surface_set_color(Color(0.35, 1.0, 0.85, 0.95))
			beams_immediate.surface_add_vertex(d_loc + Vector3(-0.006, 0.0, 0.0))
			beams_immediate.surface_add_vertex(d_loc + Vector3(0.006, 0.0, 0.0))
			beams_immediate.surface_add_vertex(d_loc + Vector3(0.0, -0.006, 0.0))
			beams_immediate.surface_add_vertex(d_loc + Vector3(0.0, 0.006, 0.0))
			drew_any_line = true

	for ch in curr_snap.active_chaff_clouds:
		var ch_loc: Vector3 = war_table.theater_km_to_table_local(ch.get("pos_km", Vector3.ZERO))
		if absf(ch_loc.x) > 0.95 or absf(ch_loc.z) > 0.95:
			continue
		var ch_r := (float(ch.get("radius_km", 3.5)) / WarTable.THEATER_SIZE_KM) * WarTable.TABLE_SIZE_M * zoom
		beams_immediate.surface_set_color(Color(0.88, 0.92, 1.0, 0.55))
		for seg in range(12):
			var a0 := float(seg) * TAU / 12.0
			var a1 := float(seg + 1) * TAU / 12.0
			beams_immediate.surface_add_vertex(ch_loc + Vector3(cos(a0) * ch_r, 0.002, sin(a0) * ch_r))
			beams_immediate.surface_add_vertex(ch_loc + Vector3(cos(a1) * ch_r, 0.002, sin(a1) * ch_r))
		drew_any_line = true

	for gz in curr_snap.active_gps_denial_zones:
		var gz_loc: Vector3 = war_table.theater_km_to_table_local(gz.get("pos_km", Vector3.ZERO))
		if absf(gz_loc.x) > 0.95 or absf(gz_loc.z) > 0.95:
			continue
		var gz_r := (float(gz.get("radius_km", 35.0)) / WarTable.THEATER_SIZE_KM) * WarTable.TABLE_SIZE_M * zoom
		beams_immediate.surface_set_color(Color(1.0, 0.70, 0.15, 0.75))
		for seg in range(24):
			var a0 := float(seg) * TAU / 24.0
			var a1 := float(seg + 1) * TAU / 24.0
			beams_immediate.surface_add_vertex(gz_loc + Vector3(cos(a0) * gz_r, 0.004, sin(a0) * gz_r))
			beams_immediate.surface_add_vertex(gz_loc + Vector3(cos(a1) * gz_r, 0.004, sin(a1) * gz_r))
		drew_any_line = true

	# Draw Sprint 6 Active Countermeasure Flares (blooming decoy stars behind aircraft)
	if not is_globe_mode and sim_server != null:
		for cm in sim_server.world_state.active_countermeasures:
			var cm_loc: Vector3 = war_table.theater_km_to_table_local(cm.get("pos_km", Vector3.ZERO))
			if absf(cm_loc.x) > 0.95 or absf(cm_loc.z) > 0.95:
				continue
			var ttl_c: float = float(cm.get("ttl_sec", 1.0))
			var max_ttl_c: float = float(cm.get("max_ttl_sec", 4.0))
			var flare_prog := clampf(ttl_c / max_ttl_c, 0.0, 1.0)
			var flare_sz := 0.007 * flare_prog
			beams_immediate.surface_set_color(Color(1.0, 0.94, 0.55, 0.95 * flare_prog))
			# 4-point cross star
			beams_immediate.surface_add_vertex(cm_loc + Vector3(-flare_sz, 0.0, 0.0))
			beams_immediate.surface_add_vertex(cm_loc + Vector3(flare_sz, 0.0, 0.0))
			beams_immediate.surface_add_vertex(cm_loc + Vector3(0.0, 0.0, -flare_sz))
			beams_immediate.surface_add_vertex(cm_loc + Vector3(0.0, 0.0, flare_sz))
			beams_immediate.surface_add_vertex(cm_loc + Vector3(0.0, -flare_sz * 0.7, 0.0))
			beams_immediate.surface_add_vertex(cm_loc + Vector3(0.0, flare_sz * 0.7, 0.0))
			# Trailing smoke/spark tail
			var vel_cm: Vector3 = cm.get("vel_km_s", Vector3.ZERO)
			var tail_loc: Vector3 = war_table.theater_km_to_table_local(cm.get("pos_km", Vector3.ZERO) - vel_cm * 0.12)
			beams_immediate.surface_set_color(Color(0.85, 0.55, 0.22, 0.45 * flare_prog))
			beams_immediate.surface_add_vertex(cm_loc)
			beams_immediate.surface_add_vertex(tail_loc)
			drew_any_line = true

	# Draw Sprint 6 Ground Radar Tracking Illumination Scanning Cones (IADS)
	if not is_globe_mode and sim_server != null:
		for trk in sim_server.world_state.active_radar_tracks:
			var r_loc: Vector3 = war_table.theater_km_to_table_local(trk.get("radar_pos", Vector3.ZERO)) + Vector3(0.0, 0.005, 0.0)
			var t_loc: Vector3 = war_table.theater_km_to_table_local(trk.get("target_pos", Vector3.ZERO))
			if absf(r_loc.x) > 0.95 or absf(r_loc.z) > 0.95 or absf(t_loc.x) > 0.95 or absf(t_loc.z) > 0.95:
				continue
			var fac_trk: int = int(trk.get("faction", 1))
			var radar_col := Color(0.05, 0.92, 1.0, 0.85) if fac_trk == WorldState.FACTION_BLUE else Color(1.0, 0.35, 0.12, 0.85)
			var radar_alpha := clampf(float(trk.get("ttl_sec", 0.5)) * 1.5, 0.25, 0.85)
			beams_immediate.surface_set_color(Color(radar_col.r, radar_col.g, radar_col.b, radar_alpha))
			beams_immediate.surface_add_vertex(r_loc)
			beams_immediate.surface_add_vertex(t_loc)
			var cone_spread := 0.022
			var p_corners: Array[Vector3] = [
				t_loc + Vector3(-cone_spread, 0.0, -cone_spread),
				t_loc + Vector3(cone_spread, 0.0, -cone_spread),
				t_loc + Vector3(cone_spread, 0.0, cone_spread),
				t_loc + Vector3(-cone_spread, 0.0, cone_spread)
			]
			for ci in range(4):
				beams_immediate.surface_add_vertex(r_loc)
				beams_immediate.surface_add_vertex(p_corners[ci])
				beams_immediate.surface_add_vertex(p_corners[ci])
				beams_immediate.surface_add_vertex(p_corners[(ci + 1) % 4])
			drew_any_line = true

	# Draw Sprint 6 True Multi-Stage 3D Thermonuclear Detonation (Thermal Flash, Expanding Fireball, Ground Shockwave, Toroidal Mushroom Cloud, EMP Blackout)
	var active_nuke_found := false
	if not is_globe_mode and sim_server != null:
		for fb in sim_server.world_state.active_nuclear_fireballs:
			var fb_loc: Vector3 = war_table.theater_km_to_table_local(fb.get("pos_km", Vector3.ZERO))
			if absf(fb_loc.x) > 0.95 or absf(fb_loc.z) > 0.95:
				continue
			var fb_type := String(fb.get("type", "NUKE"))
			var fb_ttl := float(fb.get("ttl_sec", fb.get("timer_sec", 10.0)))
			var fb_max_ttl := maxf(1.0, float(fb.get("max_ttl_sec", 32.0)))
			var fb_prog := clampf(1.0 - (fb_ttl / fb_max_ttl), 0.02, 1.0)
			var fb_r_km := float(fb.get("radius_km", 28.0))
			# Scale thermonuclear fireball & shockwave to dramatic tactical proportions (12cm to 45cm on table)
			var base_r_m := clampf((fb_r_km / 90.0) * WarTable.TABLE_SIZE_M * (0.35 + fb_prog * 0.75), 0.14, 0.48)

			if fb_type == "NUKE":
				active_nuke_found = true
				if _nuke_mesh_root != null:
					_nuke_mesh_root.visible = true
					_nuke_mesh_root.position = fb_loc
					var stem_h := clampf(0.06 + fb_prog * 0.18, 0.06, 0.24)
					var cap_r := clampf(0.06 + fb_prog * 0.14, 0.06, 0.20)
					var shock_r := clampf(0.12 + fb_prog * 0.38, 0.12, 0.48)
					var core_s := clampf(0.35 + (1.0 - fb_prog) * 0.30, 0.30, 0.65)

					if _nuke_fireball_mi != null:
						_nuke_fireball_mi.position = Vector3(0.0, 0.03 + stem_h * 0.30, 0.0)
						_nuke_fireball_mi.scale = Vector3.ONE * core_s
					if _nuke_stem_mi != null:
						_nuke_stem_mi.position = Vector3(0.0, stem_h * 0.5, 0.0)
						_nuke_stem_mi.scale = Vector3(1.1 + fb_prog * 0.4, stem_h / 0.16, 1.1 + fb_prog * 0.4)
					if _nuke_cap_mi != null:
						_nuke_cap_mi.position = Vector3(0.0, stem_h, 0.0)
						_nuke_cap_mi.scale = Vector3(cap_r / 0.13, 0.85, cap_r / 0.13)
					if _nuke_shockwave_mi != null:
						_nuke_shockwave_mi.position = Vector3(0.0, 0.006, 0.0)
						_nuke_shockwave_mi.scale = Vector3(shock_r / 0.20, 1.0, shock_r / 0.20)

				# STAGE 1: Blinding Thermal Flash (Initial 1.5s / fb_prog < 0.12)
				if fb_prog < 0.12:
					var flash_alpha := (1.0 - (fb_prog / 0.12)) * 0.98
					var flash_r := base_r_m * 2.2
					beams_immediate.surface_set_color(Color(1.0, 1.0, 1.0, flash_alpha))
					for fs in range(16):
						var fa0 := float(fs) * TAU / 16.0
						var fa1 := float(fs + 1) * TAU / 16.0
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(fa0) * flash_r, 0.015, sin(fa0) * flash_r))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(fa1) * flash_r, 0.015, sin(fa1) * flash_r))
						if fs % 4 == 0:
							beams_immediate.surface_add_vertex(fb_loc + Vector3(0.0, 0.015, 0.0))
							beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(fa0) * flash_r, 0.015, sin(fa0) * flash_r))

				# STAGE 2: Expanding Incandescent Fireball Sphere (Hot Core Gradient)
				var fb_core_r := base_r_m * (0.85 if fb_prog < 0.25 else clampf(1.0 - (fb_prog - 0.25) * 0.6, 0.35, 0.85))
				var core_col := Color(1.0, 0.92, 0.45, 0.98) if fb_prog < 0.25 else Color(1.0, 0.42, 0.08, 0.90)
				beams_immediate.surface_set_color(core_col)
				for cs in range(16):
					var ca0 := float(cs) * TAU / 16.0
					var ca1 := float(cs + 1) * TAU / 16.0
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ca0) * fb_core_r, 0.025, sin(ca0) * fb_core_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ca1) * fb_core_r, 0.025, sin(ca1) * fb_core_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ca0) * fb_core_r, 0.025 + sin(ca0) * fb_core_r, 0.0))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ca1) * fb_core_r, 0.025 + sin(ca1) * fb_core_r, 0.0))

				# STAGE 3: Supersonic Ground Blast Shockwave Ring with Trailing Dust Front
				var shock_r := base_r_m * (1.1 + fb_prog * 1.8)
				var dust_r := shock_r * 0.88
				var shock_alpha := clampf((1.0 - fb_prog) * 0.95, 0.15, 0.95)
				beams_immediate.surface_set_color(Color(1.0, 0.75, 0.30, shock_alpha))
				for ss in range(24):
					var sa0 := float(ss) * TAU / 24.0
					var sa1 := float(ss + 1) * TAU / 24.0
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(sa0) * shock_r, 0.008, sin(sa0) * shock_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(sa1) * shock_r, 0.008, sin(sa1) * shock_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(sa0) * dust_r, 0.005, sin(sa0) * dust_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(sa1) * dust_r, 0.005, sin(sa1) * dust_r))

				# STAGE 4: Convective Columnar Stem & Rising Toroidal Mushroom Cloud Cap
				var stem_h := clampf(0.04 + fb_prog * 0.22, 0.04, 0.26)
				var stem_r_bot := base_r_m * 0.28
				var stem_r_top := base_r_m * 0.45
				var cap_torus_r := base_r_m * (0.65 + fb_prog * 0.55)
				var cap_inner_r := cap_torus_r * 0.62
				var cap_crown_h := stem_h + 0.035
				var cap_col := Color(1.0, 0.38, 0.05, 0.92) if fb_prog < 0.45 else Color(0.28, 0.22, 0.20, 0.88)
				beams_immediate.surface_set_color(cap_col)
				for ms in range(20):
					var ma0 := float(ms) * TAU / 20.0
					var ma1 := float(ms + 1) * TAU / 20.0
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * cap_torus_r, stem_h, sin(ma0) * cap_torus_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma1) * cap_torus_r, stem_h, sin(ma1) * cap_torus_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * cap_inner_r, stem_h - 0.015, sin(ma0) * cap_inner_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma1) * cap_inner_r, stem_h - 0.015, sin(ma1) * cap_inner_r))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * (cap_torus_r * 0.8), cap_crown_h, sin(ma0) * (cap_torus_r * 0.8)))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma1) * (cap_torus_r * 0.8), cap_crown_h, sin(ma1) * (cap_torus_r * 0.8)))
					if ms % 2 == 0:
						beams_immediate.surface_set_color(Color(0.85, 0.40, 0.10, 0.80) if fb_prog < 0.4 else Color(0.25, 0.18, 0.16, 0.75))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * stem_r_bot, 0.005, sin(ma0) * stem_r_bot))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * stem_r_top, stem_h, sin(ma0) * stem_r_top))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * cap_inner_r, stem_h - 0.015, sin(ma0) * cap_inner_r))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ma0) * cap_torus_r, stem_h, sin(ma0) * cap_torus_r))

				# STAGE 5: High-Altitude EMP Ionization Blackout Wave
				var emp_r := base_r_m * (1.6 + fb_prog * 2.8)
				var emp_alpha := clampf((1.0 - fb_prog * 0.8) * 0.75, 0.1, 0.75)
				beams_immediate.surface_set_color(Color(0.25, 0.88, 1.0, emp_alpha))
				for es in range(16):
					var ea0 := float(es) * TAU / 16.0
					var ea1 := float(es + 1) * TAU / 16.0
					if es % 2 == 0:
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ea0) * emp_r, 0.035, sin(ea0) * emp_r))
						beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(ea1) * emp_r, 0.035, sin(ea1) * emp_r))

			else:
				var other_col := Color(0.35, 0.92, 1.0, 0.85) if fb_type == "HEMP" else (Color(0.55, 1.0, 0.18, 0.85) if fb_type == "CHEM" else Color(1.0, 0.88, 0.32, 0.95))
				beams_immediate.surface_set_color(other_col)
				if fb_type == "ORBITAL":
					beams_immediate.surface_add_vertex(fb_loc + Vector3(0.0, 0.34, 0.0))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(0.0, 0.005, 0.0))
				for s in range(16):
					var a0 := float(s) * TAU / 16.0
					var a1 := float(s + 1) * TAU / 16.0
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(a0) * base_r_m, 0.006, sin(a0) * base_r_m))
					beams_immediate.surface_add_vertex(fb_loc + Vector3(cos(a1) * base_r_m, 0.006, sin(a1) * base_r_m))

			drew_any_line = true

	# Draw Sprint 7 Underwater Acoustic Sonar Waves
	if not is_globe_mode and sim_server != null:
		for ping in sim_server.world_state.active_sonar_pings:
			var p_loc: Vector3 = war_table.theater_km_to_table_local(ping.get("pos_km", Vector3.ZERO))
			if absf(p_loc.x) > 0.95 or absf(p_loc.z) > 0.95:
				continue
			var cur_r: float = float(ping.get("current_radius_km", 10.0))
			var ttl: float = float(ping.get("ttl_sec", 1.0))
			var dur: float = maxf(0.01, float(ping.get("duration_sec", 3.0)))
			var alpha_ping: float = clampf(ttl / dur, 0.05, 0.9)
			var r_table: float = clampf((cur_r / 60.0) * 0.16, 0.015, 0.38)
			var ping_col := Color(0.08, 0.82, 1.0, alpha_ping * 0.75) if int(ping.get("faction", 1)) == WorldState.FACTION_BLUE else Color(1.0, 0.30, 0.15, alpha_ping * 0.75)
			beams_immediate.surface_set_color(ping_col)
			for ring in range(2):
				var r_sub := r_table * (1.0 - float(ring) * 0.25)
				if r_sub <= 0.005:
					continue
				for seg in range(16):
					var a0 := float(seg) * TAU / 16.0
					var a1 := float(seg + 1) * TAU / 16.0
					beams_immediate.surface_add_vertex(p_loc + Vector3(cos(a0) * r_sub, -0.001, sin(a0) * r_sub))
					beams_immediate.surface_add_vertex(p_loc + Vector3(cos(a1) * r_sub, -0.001, sin(a1) * r_sub))
			drew_any_line = true

		# Draw Sprint 7 Tank Cannon APFSDS Kinetic Tracers & Muzzle Flashes
		for evt in sim_server.world_state.sim_events_queue:
			if evt.get("type", "") == "tank_muzzle_flash":
				var m_from: Vector3 = war_table.theater_km_to_table_local(evt.get("pos_km", Vector3.ZERO)) + Vector3(0.0, 0.004, 0.0)
				var m_to: Vector3 = war_table.theater_km_to_table_local(evt.get("target_pos_km", Vector3.ZERO)) + Vector3(0.0, 0.004, 0.0)
				if absf(m_from.x) <= 0.92 and absf(m_from.z) <= 0.92:
					beams_immediate.surface_set_color(Color(1.0, 0.95, 0.40, 0.95))
					beams_immediate.surface_add_vertex(m_from)
					beams_immediate.surface_add_vertex(m_to)
					var mf_r := 0.008
					beams_immediate.surface_set_color(Color(1.0, 0.65, 0.15, 0.98))
					for mfs in range(8):
						var mfa0 := float(mfs) * TAU / 8.0
						var mfa1 := float(mfs + 1) * TAU / 8.0
						beams_immediate.surface_add_vertex(m_from + Vector3(cos(mfa0) * mf_r, 0.002, sin(mfa0) * mf_r))
						beams_immediate.surface_add_vertex(m_from + Vector3(cos(mfa1) * mf_r, 0.002, sin(mfa1) * mf_r))
					drew_any_line = true

	if not active_nuke_found and _nuke_mesh_root != null:
		_nuke_mesh_root.visible = false

	# ====================================================================
	# 6. SELECTED UNITS, BATTALION/BRIGADE HIERARCHY TETHERS & LIVE 3D WAYPOINT ORDER VECTORS
	# ====================================================================
	if not is_globe_mode and sim_server != null:
		var ws_sel: WorldState = sim_server.world_state

		# Sprint 7: Position and update Diegetic 3D Command Radial Menu
		var radial_active := false
		if selected_unit_id >= 0 and selected_unit_id < ws_sel.unit_count and ws_sel.unit_active[selected_unit_id] == 1:
			var sel_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[selected_unit_id]) + Vector3(0.0, 0.024, 0.0)
			if absf(sel_loc.x) <= 0.92 and absf(sel_loc.z) <= 0.92:
				radial_active = true
				if _command_radial_root != null:
					_command_radial_root.visible = true
					_command_radial_root.position = sel_loc
					var active_posture: int = ws_sel.unit_posture[selected_unit_id] if selected_unit_id < ws_sel.unit_posture.size() else 0
					var p_names := ["MOVE", "ATTACK", "PATROL", "RECON", "HOLD / AMBUSH", "RETREAT"]
					for pi in range(_radial_posture_labels.size()):
						var plbl := _radial_posture_labels[pi]
						if pi == active_posture:
							plbl.modulate = Color(1.0, 0.92, 0.22, 1.0)
							plbl.text = "> " + p_names[pi] + " <"
						else:
							plbl.modulate = Color(0.20, 0.85, 1.0, 0.70)
							plbl.text = "[ " + p_names[pi] + " ]"
				var rad_r := 0.052
				beams_immediate.surface_set_color(Color(0.20, 0.88, 1.0, 0.82))
				for seg in range(24):
					var sa0 := float(seg) * TAU / 24.0
					var sa1 := float(seg + 1) * TAU / 24.0
					beams_immediate.surface_add_vertex(sel_loc + Vector3(cos(sa0) * rad_r, 0.002, sin(sa0) * rad_r))
					beams_immediate.surface_add_vertex(sel_loc + Vector3(cos(sa1) * rad_r, 0.002, sin(sa1) * rad_r))
				var sp_angles_deg := [90.0, 30.0, 330.0, 270.0, 210.0, 150.0]
				for sp_deg in sp_angles_deg:
					var sp_rad := deg_to_rad(sp_deg)
					beams_immediate.surface_add_vertex(sel_loc + Vector3(0.0, 0.002, 0.0))
					beams_immediate.surface_add_vertex(sel_loc + Vector3(cos(sp_rad) * rad_r, 0.002, -sin(sp_rad) * rad_r))
				drew_any_line = true

		if not radial_active and _command_radial_root != null:
			_command_radial_root.visible = false

		var draw_uids: Array[int] = selected_unit_ids.duplicate()
		if draw_uids.is_empty() and selected_unit_id >= 0:
			draw_uids.append(selected_unit_id)

		for s_uid in draw_uids:
			if s_uid < 0 or s_uid >= ws_sel.unit_count or ws_sel.unit_active[s_uid] == 0:
				continue
			var u_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[s_uid]) + Vector3(0.0, 0.006, 0.0)
			if absf(u_loc.x) <= 0.92 and absf(u_loc.z) <= 0.92:
				var sel_r := 0.026 if ws_sel.unit_echelon[s_uid] > 0 else 0.016
				beams_immediate.surface_set_color(Color(1.0, 0.88, 0.22, 0.95))
				for rs in range(12):
					var ra0 := float(rs) * TAU / 12.0
					var ra1 := float(rs + 1) * TAU / 12.0
					beams_immediate.surface_add_vertex(u_loc + Vector3(cos(ra0) * sel_r, 0.0, sin(ra0) * sel_r))
					beams_immediate.surface_add_vertex(u_loc + Vector3(cos(ra1) * sel_r, 0.0, sin(ra1) * sel_r))
				drew_any_line = true

			# Draw C2 Hierarchy Tether Line to parent Battalion / Brigade so organization is visible
			var par_id: int = ws_sel.unit_parent_id[s_uid]
			if par_id >= 0 and par_id < ws_sel.unit_count and ws_sel.unit_active[par_id] == 1:
				var p_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[par_id]) + Vector3(0.0, 0.010, 0.0)
				if absf(p_loc.x) <= 0.92 and absf(p_loc.z) <= 0.92:
					beams_immediate.surface_set_color(Color(1.0, 0.84, 0.25, 0.55))
					beams_immediate.surface_add_vertex(u_loc)
					beams_immediate.surface_add_vertex(p_loc)
					drew_any_line = true

			# If a Battalion or Brigade is selected, also highlight its subordinate Companies & their active orders
			var leaf_list: Array[int] = [s_uid]
			if ws_sel.unit_echelon[s_uid] > WorldState.ECHELON_COMPANY:
				leaf_list = EchelonClusterSystem.get_subordinate_leaf_units(ws_sel, s_uid)
				for sub_u in leaf_list:
					var sub_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[sub_u]) + Vector3(0.0, 0.005, 0.0)
					if absf(sub_loc.x) <= 0.92 and absf(sub_loc.z) <= 0.92:
						beams_immediate.surface_set_color(Color(0.25, 0.95, 1.0, 0.52))
						beams_immediate.surface_add_vertex(u_loc)
						beams_immediate.surface_add_vertex(sub_loc)
						drew_any_line = true

			for l_uid in leaf_list:
				if l_uid >= 0 and l_uid < ws_sel.unit_count and ws_sel.unit_active[l_uid] == 1 and ws_sel.unit_has_waypoint[l_uid] == 1:
					var from_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[l_uid]) + Vector3(0.0, 0.007, 0.0)
					var to_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_target_pos[l_uid]) + Vector3(0.0, 0.007, 0.0)
					if absf(from_loc.x) <= 0.92 and absf(from_loc.z) <= 0.92:
						var wp_col := Color(0.20, 1.0, 0.58, 0.88) if ws_sel.unit_ai_state[l_uid] != WorldState.AI_BVR_INTERCEPT else Color(1.0, 0.35, 0.35, 0.92)
						beams_immediate.surface_set_color(wp_col)
						beams_immediate.surface_add_vertex(from_loc)
						beams_immediate.surface_add_vertex(to_loc)
						var d_sz := 0.009
						beams_immediate.surface_add_vertex(to_loc + Vector3(-d_sz, 0.0, 0.0))
						beams_immediate.surface_add_vertex(to_loc + Vector3(d_sz, 0.0, 0.0))
						beams_immediate.surface_add_vertex(to_loc + Vector3(0.0, 0.0, -d_sz))
						beams_immediate.surface_add_vertex(to_loc + Vector3(0.0, 0.0, d_sz))
						drew_any_line = true

		# Draw Hostile Designated Target Reticle
		var reticle_active := false
		if designated_target_uid >= 0 and designated_target_uid < ws_sel.unit_count and ws_sel.unit_active[designated_target_uid] == 1:
			var t_loc: Vector3 = war_table.theater_km_to_table_local(ws_sel.unit_pos[designated_target_uid]) + Vector3(0.0, 0.008, 0.0)
			if absf(t_loc.x) <= 0.92 and absf(t_loc.z) <= 0.92:
				reticle_active = true
				if _target_reticle_root != null:
					_target_reticle_root.visible = true
					_target_reticle_root.position = t_loc
					if _target_reticle_label != null:
						var t_pid: int = ws_sel.unit_platform_id[designated_target_uid]
						var t_hp: int = int(ws_sel.unit_hp[designated_target_uid])
						var p_name: String = String(platforms[t_pid].get("name", "TARGET")) if t_pid < platforms.size() else "TARGET"
						_target_reticle_label.text = "LOCK: " + p_name + "\nHP: " + str(t_hp)
				var ret_r := 0.022
				beams_immediate.surface_set_color(Color(1.0, 0.15, 0.20, 0.95))
				for rs in range(8):
					var ra0 := float(rs) * TAU / 8.0
					var ra1 := float(rs + 1) * TAU / 8.0
					beams_immediate.surface_add_vertex(t_loc + Vector3(cos(ra0) * ret_r, 0.0, sin(ra0) * ret_r))
					beams_immediate.surface_add_vertex(t_loc + Vector3(cos(ra1) * ret_r, 0.0, sin(ra1) * ret_r))
				beams_immediate.surface_add_vertex(t_loc + Vector3(-ret_r * 1.4, 0.0, 0.0))
				beams_immediate.surface_add_vertex(t_loc + Vector3(ret_r * 1.4, 0.0, 0.0))
				beams_immediate.surface_add_vertex(t_loc + Vector3(0.0, 0.0, -ret_r * 1.4))
				beams_immediate.surface_add_vertex(t_loc + Vector3(0.0, 0.0, ret_r * 1.4))
				drew_any_line = true

		if not reticle_active and _target_reticle_root != null:
			_target_reticle_root.visible = false

		# Render 3D HQ Command Bunker Citadel Pyramid & Perimeter Security Ring at `ws_sel.bunker_pos_km`
		var b_loc_hq: Vector3 = war_table.theater_km_to_table_local(ws_sel.bunker_pos_km)
		if absf(b_loc_hq.x) <= 0.90 and absf(b_loc_hq.z) <= 0.90:
			var hq_col := Color(0.0, 1.0, 0.85, 0.95)
			if ws_sel.bunker_is_lost or ws_sel.bunker_status_code in ["BREACH_IN_PROGRESS", "UNDER_ATTACK"]:
				hq_col = Color(1.0, 0.22, 0.22, 0.98)
			elif ws_sel.bunker_status_code == "PERIMETER_ALERT":
				hq_col = Color(1.0, 0.78, 0.20, 0.95)
			var hq_r := 0.032
			var hq_apex := b_loc_hq + Vector3(0.0, 0.055, 0.0)
			beams_immediate.surface_set_color(hq_col)
			for hs in range(12):
				var ha0 := float(hs) * TAU / 12.0
				var ha1 := float(hs + 1) * TAU / 12.0
				var p0 := b_loc_hq + Vector3(cos(ha0) * hq_r, 0.006, sin(ha0) * hq_r)
				var p1 := b_loc_hq + Vector3(cos(ha1) * hq_r, 0.006, sin(ha1) * hq_r)
				beams_immediate.surface_add_vertex(p0)
				beams_immediate.surface_add_vertex(p1)
				if hs % 3 == 0:
					beams_immediate.surface_add_vertex(p0)
					beams_immediate.surface_add_vertex(hq_apex)
			drew_any_line = true

		# Render 3D Sovereign Nation Airspace & Territory Corridors (`active_nations`)
		for nat in ws_sel.active_nations:
			var n_rect: Rect2 = nat.get("airspace_rect_km", Rect2())
			if n_rect.size.x <= 1.0:
				continue
			var b_open := bool(nat.get("blue_airspace_open", false))
			var r_open := bool(nat.get("red_airspace_open", false))
			var n_col := Color(0.95, 0.78, 0.25, 0.36) # Neutral Sovereign Airspace (Amber)
			if b_open:
				n_col = Color(0.18, 0.92, 0.75, 0.45)  # Blue Coalition Open Airspace (Cyan-Green)
			elif r_open:
				n_col = Color(1.0, 0.28, 0.35, 0.45)   # Enemy Red Pact Open Airspace (Crimson)
			var c0: Vector3 = war_table.theater_km_to_table_local(Vector3(n_rect.position.x, 1200.0, n_rect.position.y))
			var c1: Vector3 = war_table.theater_km_to_table_local(Vector3(n_rect.position.x + n_rect.size.x, 1200.0, n_rect.position.y))
			var c2: Vector3 = war_table.theater_km_to_table_local(Vector3(n_rect.position.x + n_rect.size.x, 1200.0, n_rect.position.y + n_rect.size.y))
			var c3: Vector3 = war_table.theater_km_to_table_local(Vector3(n_rect.position.x, 1200.0, n_rect.position.y + n_rect.size.y))
			c0.x = clampf(c0.x, -0.89, 0.89); c0.z = clampf(c0.z, -0.89, 0.89)
			c1.x = clampf(c1.x, -0.89, 0.89); c1.z = clampf(c1.z, -0.89, 0.89)
			c2.x = clampf(c2.x, -0.89, 0.89); c2.z = clampf(c2.z, -0.89, 0.89)
			c3.x = clampf(c3.x, -0.89, 0.89); c3.z = clampf(c3.z, -0.89, 0.89)
			beams_immediate.surface_set_color(n_col)
			beams_immediate.surface_add_vertex(c0); beams_immediate.surface_add_vertex(c1)
			beams_immediate.surface_add_vertex(c1); beams_immediate.surface_add_vertex(c2)
			beams_immediate.surface_add_vertex(c2); beams_immediate.surface_add_vertex(c3)
			beams_immediate.surface_add_vertex(c3); beams_immediate.surface_add_vertex(c0)
			drew_any_line = true

		# Phase 31: Render Descending 3D Paratrooper & Robot Dog Parachute Canopies (`parachute_drops`) & Minefields (`minefields`)
		for drop in ws_sel.parachute_drops:
			var d_pos_km: Vector3 = drop["pos_km"]
			var d_alt_m: float = float(drop.get("alt_m", 1200.0))
			var ground_pt: Vector3 = war_table.theater_km_to_table_local(d_pos_km)
			var canopy_pt: Vector3 = war_table.theater_km_to_table_local(Vector3(d_pos_km.x, d_pos_km.y + d_alt_m, d_pos_km.z)) + Vector3(0.0, 0.018, 0.0)
			if absf(canopy_pt.x) <= 0.90 and absf(canopy_pt.z) <= 0.90:
				var c_rad := 0.014
				beams_immediate.surface_set_color(Color(0.35, 1.0, 0.72, 0.92))
				for ps in range(8):
					var pa0 := float(ps) * TAU / 8.0
					var pa1 := float(ps + 1) * TAU / 8.0
					var rim0 := canopy_pt + Vector3(cos(pa0) * c_rad, 0.0, sin(pa0) * c_rad)
					var rim1 := canopy_pt + Vector3(cos(pa1) * c_rad, 0.0, sin(pa1) * c_rad)
					beams_immediate.surface_add_vertex(rim0)
					beams_immediate.surface_add_vertex(rim1)
					if ps % 2 == 0:
						beams_immediate.surface_add_vertex(rim0)
						beams_immediate.surface_add_vertex(ground_pt + Vector3(0.0, 0.008, 0.0))
				drew_any_line = true

		for mf in ws_sel.minefields:
			if not bool(mf.get("active", false)):
				continue
			var mf_pos_km: Vector3 = mf["pos_km"]
			var mf_loc: Vector3 = war_table.theater_km_to_table_local(mf_pos_km) + Vector3(0.0, 0.005, 0.0)
			if absf(mf_loc.x) <= 0.90 and absf(mf_loc.z) <= 0.90:
				var mf_fac: int = int(mf.get("faction", WorldState.FACTION_BLUE))
				var mf_col := Color(0.20, 0.95, 1.0, 0.75) if mf_fac == WorldState.FACTION_BLUE else Color(1.0, 0.32, 0.18, 0.75)
				var mf_r_m := (float(mf.get("radius_km", 18.0)) / WarTable.THEATER_SIZE_KM) * WarTable.TABLE_SIZE_M * zoom
				beams_immediate.surface_set_color(mf_col)
				for ms in range(6):
					var ma0 := float(ms) * TAU / 6.0
					var ma1 := float(ms + 1) * TAU / 6.0
					beams_immediate.surface_add_vertex(mf_loc + Vector3(cos(ma0) * mf_r_m, 0.0, sin(ma0) * mf_r_m))
					beams_immediate.surface_add_vertex(mf_loc + Vector3(cos(ma1) * mf_r_m, 0.0, sin(ma1) * mf_r_m))
				drew_any_line = true

		# Phase 32: Render Seabed Subsea Fiber-Optic Trunk Cables & Offshore Gas Pipelines (`undersea_cables`)
		for cb in ws_sel.undersea_cables:
			var cb_a: Vector3 = war_table.theater_km_to_table_local(cb["start_km"]) + Vector3(0.0, 0.002, 0.0)
			var cb_b: Vector3 = war_table.theater_km_to_table_local(cb["end_km"]) + Vector3(0.0, 0.002, 0.0)
			cb_a.x = clampf(cb_a.x, -0.89, 0.89); cb_a.z = clampf(cb_a.z, -0.89, 0.89)
			cb_b.x = clampf(cb_b.x, -0.89, 0.89); cb_b.z = clampf(cb_b.z, -0.89, 0.89)
			var is_sev := bool(cb.get("severed", false))
			var is_blue_cb := String(cb.get("faction_owner", "BLUE")) == "BLUE"
			var cb_col := Color(1.0, 0.15, 0.25, 0.90) if is_sev else (Color(0.15, 0.95, 0.82, 0.68) if is_blue_cb else Color(1.0, 0.62, 0.18, 0.68))
			beams_immediate.surface_set_color(cb_col)
			beams_immediate.surface_add_vertex(cb_a)
			beams_immediate.surface_add_vertex(cb_b)
			drew_any_line = true

	if not drew_any_ribbon:
		ribbons_immediate.surface_set_color(Color(0, 0, 0, 0))
		ribbons_immediate.surface_add_vertex(Vector3.ZERO)
		ribbons_immediate.surface_add_vertex(Vector3.ZERO)
		ribbons_immediate.surface_add_vertex(Vector3.ZERO)
	ribbons_immediate.surface_end()

	if not drew_any_line:
		beams_immediate.surface_set_color(Color(0, 0, 0, 0))
		beams_immediate.surface_add_vertex(Vector3.ZERO)
		beams_immediate.surface_add_vertex(Vector3.ZERO)
	beams_immediate.surface_end()

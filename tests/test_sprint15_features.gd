extends SceneTree
## Sprint 15 Automated Adversarial Feature Verification Suite.
## Validates:
## 1. Flagship 3D Procedural Mesh Pack in PlatformMeshArmory (F-35A, J-20, Su-57, B-21, Type 055, CVN-78, M1A2, Vision 60).
## 2. Naval Bathymetry & Draft Enforcement in WorldState and KinematicsSystem.
## 3. Physical Relative Speeds for Units, Munitions, and Drones.
## 4. Real Named City OpenStreetMap Layouts & Holographic Labels in VisualSyncController.

const PlatformMeshArmoryScript := preload("res://src/presentation/war_table/platform_mesh_armory.gd")

var total_tests := 0
var passed_tests := 0


func _init() -> void:
	print("==================================================================")
	print("  RUNNING SPRINT 15 FEATURE VERIFICATION SUITE")
	print("==================================================================")

	test_platform_mesh_armory_flagships()
	test_naval_bathymetry_and_draft_enforcement()
	test_relative_speeds_and_munition_physics()
	test_real_named_cities_and_visual_sync()

	print("==================================================================")
	print("  SPRINT 15 TEST RESULTS: %d / %d PASSED (%.1f%%)" % [passed_tests, total_tests, float(passed_tests) / float(max(1, total_tests)) * 100.0])
	print("==================================================================")

	if passed_tests == total_tests:
		print(">> ALL SPRINT 15 FEATURES VERIFIED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SPRINT 15 TEST FAILURES DETECTED! <<")
		quit(1)


func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)


func test_platform_mesh_armory_flagships() -> void:
	print("\n--- Test Suite 1: Flagship 3D Procedural Meshes ---")
	var mat := StandardMaterial3D.new()

	var flagships := [
		PlatformMeshArmoryScript.FLAGSHIP_F35,
		PlatformMeshArmoryScript.FLAGSHIP_J20,
		PlatformMeshArmoryScript.FLAGSHIP_SU57,
		PlatformMeshArmoryScript.FLAGSHIP_B21,
		PlatformMeshArmoryScript.FLAGSHIP_TYPE055,
		PlatformMeshArmoryScript.FLAGSHIP_CVN78,
		PlatformMeshArmoryScript.FLAGSHIP_M1A2,
		PlatformMeshArmoryScript.FLAGSHIP_VISION60,
	]

	for slug in flagships:
		var mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(slug, mat)
		assert_true(mesh != null, "Flagship mesh '%s' successfully generated" % slug)
		if mesh != null:
			var arrays: Array = mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			assert_true(verts.size() >= 12, "Mesh '%s' has valid vertex count (%d verts)" % [slug, verts.size()])
			assert_true(normals.size() == verts.size(), "Mesh '%s' has generated normals matching vertices" % slug)


func test_naval_bathymetry_and_draft_enforcement() -> void:
	print("\n--- Test Suite 2: Naval Bathymetry & Draft Enforcement ---")
	var ws := WorldState.new()


	# Mock elevation grid: ocean at (50, 50) with depth 120m, shoal at (20, 20) with depth 3m, land at (-50, -50) with elev +250m
	ws.heightmap_size = 128
	ws.heightmap_elev_m.resize(128 * 128)
	ws.heightmap_elev_m.fill(0.0)

	# Center ocean cell
	var ocean_u := (50.0 + 250.0) / 500.0
	var ocean_v := (50.0 + 250.0) / 500.0
	var ix := clampi(int(ocean_u * 127.0), 0, 127)
	var iy := clampi(int(ocean_v * 127.0), 0, 127)
	ws.heightmap_elev_m[iy * 128 + ix] = -120.0

	# Test get_water_depth_m
	var deep_depth := ws.get_water_depth_m(50.0, 50.0)
	assert_true(deep_depth > 100.0, "Deep ocean depth is ~120m (got %.1f m)" % deep_depth)

	var land_depth := ws.get_water_depth_m(-50.0, -50.0)
	assert_true(land_depth == 0.0, "Dry land water depth is 0.0m")

	# Test get_ship_required_draft_m
	var cvn_draft := ws.get_ship_required_draft_m(70, 0, "cvn_78_gerald_r_ford")
	assert_true(cvn_draft == 12.0, "CVN-78 required draft is 12.0m")

	var ddg_draft := ws.get_ship_required_draft_m(36, 0, "type_055_renhai")
	assert_true(ddg_draft == 7.5, "Type 055 required draft is 7.5m")

	var usv_draft := ws.get_ship_required_draft_m(38, 1 << 11, "sea_baby_usv")
	assert_true(usv_draft == 1.2, "Sea Baby USV required draft is 1.2m")

	var sub_draft := ws.get_ship_required_draft_m(40, 1 << 17, "ssn_688i_los_angeles")
	assert_true(sub_draft == 15.0, "SSN Submarine required draft is 15.0m")

	# Test Kinematics draft enforcement: Ship trying to drive onto land is blocked
	var sdb = load("res://src/autoloads/sim_db.gd").new()
	sdb.load_database()

	# Spawn ship at deep ocean (50, 50)
	var uid := ws.spawn_unit(WorldState.FACTION_BLUE, 70, Vector3(50.0, 0.0, 50.0), WorldState.ECHELON_COMPANY)
	ws.unit_has_waypoint[uid] = 1
	# Waypoint directed into dry land (-50, -50)
	ws.unit_target_pos[uid] = Vector3(-50.0, 0.0, -50.0)

	# Step kinematics
	KinematicsSystem.step(ws, sdb, 1.0)
	var post_pos := ws.unit_pos[uid]
	var post_depth := ws.get_water_depth_m(post_pos.x, post_pos.z)
	assert_true(post_depth >= 12.0 or post_pos.x == 50.0, "Supercarrier draft enforced: ship refused entry to dry land/shallows")


func test_relative_speeds_and_munition_physics() -> void:
	print("\n--- Test Suite 3: Relative Speeds & Munition Physics ---")
	var sdb = load("res://src/autoloads/sim_db.gd").new()
	sdb.load_database()

	var p_f35_id := int(sdb.platform_id_by_slug.get("f_35a_lightning", 1))
	var p_abrams_id := int(sdb.platform_id_by_slug.get("m1a2_sepv3_platoon", 27))
	var p_cvn_id := int(sdb.platform_id_by_slug.get("cvn_78_gerald_r_ford", 70))
	var p_dog_id := int(sdb.platform_id_by_slug.get("vision_60_q_ugv", 12))

	var f35_spd: float = sdb.plat_cruise_km_s[p_f35_id]
	var abrams_spd: float = sdb.plat_cruise_km_s[p_abrams_id]
	var cvn_spd: float = sdb.plat_cruise_km_s[p_cvn_id]
	var dog_spd: float = sdb.plat_cruise_km_s[p_dog_id]

	assert_true(f35_spd > abrams_spd * 10.0, "F-35A cruise speed (%.3f km/s) is > 10x tank speed (%.4f km/s)" % [f35_spd, abrams_spd])
	assert_true(abrams_spd > dog_spd, "M1A2 Tank speed (%.4f km/s) is faster than Robot Dog (%.4f km/s)" % [abrams_spd, dog_spd])
	assert_true(cvn_spd > 0.005 and cvn_spd < 0.025, "Carrier speed (%.4f km/s) is within realistic 20-32 kt naval range" % cvn_spd)


func test_real_named_cities_and_visual_sync() -> void:
	print("\n--- Test Suite 4: Real Named Cities & VisualSync ---")
	var civ_sys := preload("res://src/sim_core/systems/civilian_density_system.gd")
	var strait_cities: Array[Dictionary] = civ_sys.get_theater_real_cities("strait_theater")
	assert_true(strait_cities.size() >= 5, "Strait theater has %d real named cities" % strait_cities.size())

	var found_taipei := false
	var found_kaohsiung := false
	for c in strait_cities:
		var cname: String = String(c.get("name", ""))
		if cname.find("TAIPEI") != -1:
			found_taipei = true
		if cname.find("KAOHSIUNG") != -1:
			found_kaohsiung = true

	assert_true(found_taipei, "Real named city 'TAIPEI METROPOLIS' present in GIS catalog")
	assert_true(found_kaohsiung, "Real named city 'KAOHSIUNG' present in GIS catalog")

	# Test VisualSyncController flagship MultiMeshes
	var root_node := Node3D.new()
	var vsc := VisualSyncController.new()
	root_node.add_child(vsc)
	vsc._ready()

	assert_true(vsc.f35_mmi != null, "F-35 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.j20_mmi != null, "J-20 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.su57_mmi != null, "Su-57 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.b21_mmi != null, "B-21 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.cvn78_mmi != null, "CVN-78 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.type055_mmi != null, "Type 055 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.m1a2_mmi != null, "M1A2 MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.robot_dog_mmi != null, "Robot Dog MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc.flares_mmi != null, "Defensive Flares MultiMeshInstance3D initialized in VisualSyncController")
	assert_true(vsc._city_labels.size() > 0, "Real City 3D Holographic Labels initialized (%d labels)" % vsc._city_labels.size())

	root_node.free()

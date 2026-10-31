extends SceneTree
## Sprint 19 Automated Adversarial Feature Verification Suite.
## Validates:
## 1. Naval Draft & Bathymetric Routing Enforcement (US-19.1).
## 2. Real-World Named Metropolitan Cities & OpenStreetMap Landmarks (US-19.2).
## 3. Featured 3D Platform Meshes & Low-Poly Optimization (F-35A, J-20, Su-57, B-21, Type 055, CVN-78) (US-19.3).

const CivilianDensitySystemScript := preload("res://src/sim_core/systems/civilian_density_system.gd")
const TerrainInfrastructureSystemScript := preload("res://src/sim_core/systems/terrain_infrastructure_system.gd")
const PlatformMeshArmoryScript := preload("res://src/presentation/war_table/platform_mesh_armory.gd")
const KinematicsSystemScript := preload("res://src/sim_core/systems/kinematics_system.gd")
const SimDBScript := preload("res://src/autoloads/sim_db.gd")

var total_tests := 0
var passed_tests := 0


func _init() -> void:
	print("==================================================================")
	print("  RUNNING SPRINT 19 FEATURE VERIFICATION SUITE")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	sim_db.load_database()

	test_naval_draft_and_bathymetry(sim_db)
	test_real_world_cities_and_landmarks()
	test_featured_platform_3d_meshes()

	print("==================================================================")
	print("  SPRINT 19 TEST RESULTS: %d / %d PASSED (%.1f%%)" % [passed_tests, total_tests, float(passed_tests) / float(max(1, total_tests)) * 100.0])
	print("==================================================================")

	if passed_tests == total_tests:
		print(">> ALL SPRINT 19 FEATURES VERIFIED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SPRINT 19 TEST FAILURES DETECTED! <<")
		quit(1)


func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)


func test_naval_draft_and_bathymetry(sim_db: Node) -> void:
	print("\n--- Test Suite 1: Naval Draft & Bathymetric Routing (US-19.1) ---")
	var ws := WorldState.new()

	# 1. Test required draft deduction across naval classes
	var cvn_draft := ws.get_ship_required_draft_m(1, 0, "cvn_78_gerald_r_ford")
	assert_true(cvn_draft >= 11.5, "CVN-78 Supercarrier requires deep draft (>= 11.5m, got %.1fm)" % cvn_draft)

	var type055_draft := ws.get_ship_required_draft_m(2, 0, "type_055_renhai")
	assert_true(type055_draft >= 7.0 and type055_draft <= 8.5, "Type 055 Cruiser requires intermediate draft (7.0m-8.5m, got %.1fm)" % type055_draft)

	var usv_draft := ws.get_ship_required_draft_m(3, int(sim_db.FLAG_SWARM), "sea_baby_kamikaze_usv")
	assert_true(usv_draft <= 2.5, "Kamikaze USV has shallow littoral draft (<= 2.5m, got %.1fm)" % usv_draft)

	var sub_draft := ws.get_ship_required_draft_m(4, int(sim_db.FLAG_UUV_SUB), "virginia_ssn")
	assert_true(sub_draft >= 14.0, "Nuclear Submarine requires deep water (>= 14.0m, got %.1fm)" % sub_draft)

	# 2. Test bathymetric water depth query
	# Setup heightmap with deep ocean on left (elev = -80m) and shallow coastal shelf on right (elev = -5m)
	ws.heightmap_size = 128
	ws.heightmap_elev_m.resize(128 * 128)
	for y in range(128):
		for x in range(128):
			var idx := y * 128 + x
			if x < 40:
				ws.heightmap_elev_m[idx] = -85.0 # Deep open ocean (depth 85m)
			elif x < 70:
				ws.heightmap_elev_m[idx] = -8.0  # Shallow coastal shelf (depth 8m)
			else:
				ws.heightmap_elev_m[idx] = 15.0  # Dry land (elevation +15m)

	var deep_depth := ws.get_water_depth_m(-180.0, 0.0)
	assert_true(deep_depth > 50.0, "Deep ocean query returns deep bathymetric depth (> 50m, got %.1fm)" % deep_depth)

	var shallow_depth := ws.get_water_depth_m(-20.0, 0.0)
	assert_true(shallow_depth > 0.0 and shallow_depth < 10.0, "Shallow shelf query returns littoral depth (< 10m, got %.1fm)" % shallow_depth)

	var land_depth := ws.get_water_depth_m(120.0, 0.0)
	assert_true(land_depth == 0.0, "Dry land query returns 0.0m water depth")

	# 3. Test KinematicsSystem bathymetric contour sliding:
	# Spawn CVN-78 in deep water at (-120.0, 0, 0) ordered to move straight into shallow coast at (50.0, 0, 0)
	var cvn_uid := ws.spawn_unit(WorldState.FACTION_BLUE, 1, Vector3(-120.0, 0.0, 0.0), WorldState.ECHELON_COMPANY)
	ws.unit_target_pos[cvn_uid] = Vector3(50.0, 0.0, 0.0)
	ws.unit_has_waypoint[cvn_uid] = 1

	# Step kinematics across multiple frames
	for _f in range(20):
		KinematicsSystemScript.step(ws, sim_db, 0.5)

	var end_pos := ws.unit_pos[cvn_uid]
	var end_water_depth := ws.get_water_depth_m(end_pos.x, end_pos.z)
	assert_true(end_water_depth >= cvn_draft, "CVN-78 remains in deep water meeting draft requirement (Depth: %.1fm >= Draft: %.1fm)" % [end_water_depth, cvn_draft])
	assert_true(end_pos.x < 0.0, "CVN-78 deflected along deep-water bathymetric contour without beaching on land")


func test_real_world_cities_and_landmarks() -> void:
	print("\n--- Test Suite 2: Real-World Cities & OpenStreetMap Landmarks (US-19.2) ---")
	var ws := WorldState.new()
	ws.active_theater_slug = "strait_theater"

	# 1. Verify real named cities list for Taiwan Strait theater
	var strait_cities: Array[Dictionary] = CivilianDensitySystemScript.get_theater_real_cities("strait_theater")
	assert_true(strait_cities.size() >= 7, "Taiwan Strait theater contains at least 7 major named real cities")

	var city_names: Array[String] = []
	for c in strait_cities:
		city_names.append(String(c.get("name", "")))

	var has_taipei := false
	var has_kaohsiung := false
	var has_xiamen := false
	var has_taichung := false
	for n in city_names:
		if n.contains("TAIPEI"): has_taipei = true
		if n.contains("KAOHSIUNG"): has_kaohsiung = true
		if n.contains("XIAMEN"): has_xiamen = true
		if n.contains("TAICHUNG"): has_taichung = true

	assert_true(has_taipei, "City registry contains TAIPEI METROPOLIS")
	assert_true(has_kaohsiung, "City registry contains KAOHSIUNG / TAINAN METRO")
	assert_true(has_xiamen, "City registry contains XIAMEN / ZHANGZHOU METRO")
	assert_true(has_taichung, "City registry contains TAICHUNG BASIN")

	# 2. Seed terrain infrastructure and check 3D landmark structures
	# Setup sample elevation map
	ws.heightmap_size = 128
	ws.heightmap_elev_m.resize(128 * 128)
	ws.heightmap_elev_m.fill(25.0) # Flat ground

	TerrainInfrastructureSystemScript.seed_theater_infrastructure(ws)
	assert_true(ws.bldg_count > 0, "Terrain infrastructure seeded 3D buildings (Count: %d)" % ws.bldg_count)

	var has_landmark_skyscraper := false
	var has_port_crane := false
	for bi in range(ws.bldg_count):
		var b_type: int = ws.bldg_type[bi]
		if b_type == WorldState.BLDG_LANDMARK_SKYSCRAPER:
			has_landmark_skyscraper = true
		elif b_type == WorldState.BLDG_PORT_CONTAINER_CRANE:
			has_port_crane = true

	assert_true(has_landmark_skyscraper, "Seeded 3D Landmark Skyscrapers for recognized metropolitan centers (Taipei 101 / Kaohsiung 85)")
	assert_true(has_port_crane, "Seeded 3D Maritime Port Container Cranes along harbor quays")


func test_featured_platform_3d_meshes() -> void:
	print("\n--- Test Suite 3: Featured Platform 3D Meshes & Low-Poly Optimization (US-19.3) ---")
	var dummy_mat := StandardMaterial3D.new()

	# 1. F-35A Lightning II
	var f35_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_F35, dummy_mat)
	assert_true(f35_mesh != null, "F-35A procedural 3D mesh generated")
	assert_true(f35_mesh.get_surface_count() > 0, "F-35A mesh has valid surface array")
	var f35_verts: int = f35_mesh.surface_get_array_len(0)
	assert_true(f35_verts >= 24 and f35_verts <= 250, "F-35A mesh is optimized low-poly (< 250 vertices, got %d)" % f35_verts)

	# 2. J-20 Mighty Dragon
	var j20_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_J20, dummy_mat)
	assert_true(j20_mesh != null, "J-20 procedural 3D mesh generated")
	var j20_verts: int = j20_mesh.surface_get_array_len(0)
	assert_true(j20_verts >= 24 and j20_verts <= 250, "J-20 mesh is optimized low-poly (< 250 vertices, got %d)" % j20_verts)

	# 3. Su-57 Felon
	var su57_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_SU57, dummy_mat)
	assert_true(su57_mesh != null, "Su-57 procedural 3D mesh generated")
	var su57_verts: int = su57_mesh.surface_get_array_len(0)
	assert_true(su57_verts >= 24 and su57_verts <= 250, "Su-57 mesh is optimized low-poly (< 250 vertices, got %d)" % su57_verts)

	# 4. B-21 Raider
	var b21_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_B21, dummy_mat)
	assert_true(b21_mesh != null, "B-21 procedural 3D mesh generated")
	var b21_verts: int = b21_mesh.surface_get_array_len(0)
	assert_true(b21_verts >= 15 and b21_verts <= 200, "B-21 mesh is optimized low-poly (< 200 vertices, got %d)" % b21_verts)

	# 5. Type 055 Renhai Cruiser
	var type055_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_TYPE055, dummy_mat)
	assert_true(type055_mesh != null, "Type 055 Cruiser procedural 3D mesh generated")
	var t055_verts: int = type055_mesh.surface_get_array_len(0)
	assert_true(t055_verts >= 24 and t055_verts <= 350, "Type 055 mesh is optimized low-poly (< 350 vertices, got %d)" % t055_verts)

	# 6. CVN-78 Gerald R. Ford Supercarrier
	var cvn78_mesh: ArrayMesh = PlatformMeshArmoryScript.get_mesh_for_platform(PlatformMeshArmoryScript.FLAGSHIP_CVN78, dummy_mat)
	assert_true(cvn78_mesh != null, "CVN-78 Supercarrier procedural 3D mesh generated")
	var cvn_verts: int = cvn78_mesh.surface_get_array_len(0)
	assert_true(cvn_verts >= 24 and cvn_verts <= 350, "CVN-78 mesh is optimized low-poly (< 350 vertices, got %d)" % cvn_verts)

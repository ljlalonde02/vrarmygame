extends SceneTree
## Sprint 16 Automated Adversarial Feature Verification Suite.
## Validates:
## 1. Ballistic Munition Flight Dynamics & Tangent Parabolic Orientations (US-16.1).
## 2. Distinct Munition 3D Procedural Meshes (US-16.2).
## 3. Special CBRN & Electromagnetic Weapons Simulation (US-16.3).
## 4. Doctrinal Military Formations Engine (US-16.4).

const PlatformMeshArmoryScript := preload("res://src/presentation/war_table/platform_mesh_armory.gd")
const TacticalDoctrineFormationSystemScript := preload("res://src/sim_core/systems/tactical_doctrine_formation_system.gd")
const SimDBScript := preload("res://src/autoloads/sim_db.gd")

var total_tests := 0
var passed_tests := 0


func _init() -> void:
	print("==================================================================")
	print("  RUNNING SPRINT 16 FEATURE VERIFICATION SUITE")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	sim_db.load_database()
	var grid := SpatialHashGrid.new()

	test_ballistic_tangent_dynamics_and_orientations(sim_db, grid)
	test_munition_3d_procedural_meshes()
	test_special_cbrn_and_electromagnetic_weapons(sim_db, grid)
	test_doctrinal_military_formations()

	print("==================================================================")
	print("  SPRINT 16 TEST RESULTS: %d / %d PASSED (%.1f%%)" % [passed_tests, total_tests, float(passed_tests) / float(max(1, total_tests)) * 100.0])
	print("==================================================================")

	if passed_tests == total_tests:
		print(">> ALL SPRINT 16 FEATURES VERIFIED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SPRINT 16 TEST FAILURES DETECTED! <<")
		quit(1)


func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)


func test_ballistic_tangent_dynamics_and_orientations(sim_db: Node, grid: SpatialHashGrid) -> void:
	print("\n--- Test Suite 1: Ballistic Munition Dynamics & Tangent Pitch ---")
	var ws := WorldState.new()

	# Spawn Ballistic Missile: from (0, 0, 0) to (0, 0, 200) with dist_km = 200.0 (> 120km)
	var start_pos := Vector3(0.0, 10.0, 0.0)
	var target_pos := Vector3(0.0, 10.0, 200.0)
	var mid := ws.spawn_munition(0, 1, 0, 1, start_pos, target_pos, "LOFTED_BALLISTIC")

	assert_true(mid >= 0, "Ballistic missile munition spawned successfully (id: %d)" % mid)
	assert_true(ws.mun_class_id[mid] == 3, "Munition class deduced as Ballistic Missile (class_id == 3)")

	# Check initial launch pitch: should be positive climbing angle (> +0.4 rad / ~23 deg)
	var initial_pitch := ws.mun_pitch_rad[mid]
	assert_true(initial_pitch > 0.4, "Initial launch pitch is steeply positive (+%.2f rad / +%.1f deg)" % [initial_pitch, rad_to_deg(initial_pitch)])

	# Simulate to apogee (progress ~ 0.5)
	ws.mun_flight_progress[mid] = 0.5
	SalvoCombatSystem.step(ws, sim_db, grid, 0.001)
	var apogee_pitch := ws.mun_pitch_rad[mid]
	assert_true(absf(apogee_pitch) < 0.1, "Apogee pitch is flat/horizontal (~0.0 rad, got %.3f rad / %.1f deg)" % [apogee_pitch, rad_to_deg(apogee_pitch)])

	# Simulate to terminal plunge (progress ~ 0.95)
	ws.mun_flight_progress[mid] = 0.95
	SalvoCombatSystem.step(ws, sim_db, grid, 0.001)
	var terminal_pitch := ws.mun_pitch_rad[mid]
	assert_true(terminal_pitch < -0.3, "Terminal plunge pitch is steeply negative (-%.2f rad / -%.1f deg)" % [absf(terminal_pitch), rad_to_deg(terminal_pitch)])

	# Test Artillery Shell dynamics (dist_km <= 50km -> class_id == 1)
	var art_mid := ws.spawn_munition(0, 1, 0, 1, Vector3(-10.0, 20.0, -10.0), Vector3(15.0, 20.0, 15.0), "LOFTED_BALLISTIC")
	assert_true(ws.mun_class_id[art_mid] == 1, "Munition class deduced as Artillery Shell (class_id == 1)")
	assert_true(ws.mun_pitch_rad[art_mid] > 0.1, "Artillery shell has positive launch pitch")

	# Test Cruise Missile dynamics (SEA_SKIM_TERCOM -> class_id == 2)
	var cruise_mid := ws.spawn_munition(0, 1, 0, 1, Vector3(-50.0, 15.0, 0.0), Vector3(50.0, 15.0, 0.0), "SEA_SKIM_TERCOM")
	assert_true(ws.mun_class_id[cruise_mid] == 2, "Munition class deduced as Cruise Missile (class_id == 2)")

	# Test Loitering Drone dynamics (DIRECT -> class_id == 4)
	var drone_mid := ws.spawn_munition(0, 1, 0, 1, Vector3(0.0, 100.0, 0.0), Vector3(10.0, 50.0, 10.0), "DIRECT")
	assert_true(ws.mun_class_id[drone_mid] == 4, "Munition class deduced as Loitering Drone (class_id == 4)")


func test_munition_3d_procedural_meshes() -> void:
	print("\n--- Test Suite 2: Distinct Munition 3D Procedural Meshes ---")
	var mat := StandardMaterial3D.new()

	# 1. Artillery Shell Mesh
	var shell_mesh: ArrayMesh = PlatformMeshArmoryScript.create_artillery_shell_mesh(mat)
	assert_true(shell_mesh != null, "Artillery shell mesh generated successfully")
	var shell_verts: PackedVector3Array = shell_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(shell_verts.size() >= 24, "Shell mesh has realistic ogive geometry (%d verts)" % shell_verts.size())

	# 2. Cruise Missile Mesh
	var cruise_mesh: ArrayMesh = PlatformMeshArmoryScript.create_cruise_missile_mesh(mat)
	assert_true(cruise_mesh != null, "Cruise missile mesh generated successfully")
	var cruise_verts: PackedVector3Array = cruise_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(cruise_verts.size() >= 18, "Cruise missile mesh has fuselage + wings (%d verts)" % cruise_verts.size())

	# 3. Ballistic Missile Mesh
	var ballistic_mesh: ArrayMesh = PlatformMeshArmoryScript.create_ballistic_missile_mesh(mat)
	assert_true(ballistic_mesh != null, "Ballistic missile booster + MIRV mesh generated successfully")
	var ballistic_verts: PackedVector3Array = ballistic_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(ballistic_verts.size() >= 18, "Ballistic missile mesh has high-fineness stage (%d verts)" % ballistic_verts.size())

	# 4. Loitering Drone Mesh
	var drone_mesh: ArrayMesh = PlatformMeshArmoryScript.create_loitering_drone_mesh(mat)
	assert_true(drone_mesh != null, "Loitering drone delta-wing mesh generated successfully")
	var drone_verts: PackedVector3Array = drone_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(drone_verts.size() >= 12, "Drone mesh has delta wing + fins (%d verts)" % drone_verts.size())

	# 5. Hypersonic Waverider Mesh
	var hypersonic_mesh: ArrayMesh = PlatformMeshArmoryScript.create_hypersonic_glide_mesh(mat)
	assert_true(hypersonic_mesh != null, "Hypersonic waverider wedge mesh generated successfully")
	var hypersonic_verts: PackedVector3Array = hypersonic_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(hypersonic_verts.size() >= 18, "Hypersonic waverider mesh has compression ramp (%d verts)" % hypersonic_verts.size())


func test_special_cbrn_and_electromagnetic_weapons(sim_db: Node, grid: SpatialHashGrid) -> void:
	print("\n--- Test Suite 3: Special CBRN & Electromagnetic Weapons ---")
	var ws := WorldState.new()

	# 1. Chemical Hazard
	var chem_pos := Vector3(12.0, 0.0, -18.0)
	ws.spawn_chemical_hazard(chem_pos, 8.5, 45.0, 0)
	assert_true(ws.active_cbrn_hazards.size() == 1, "Chemical hazard spawned into WorldState")
	var chem_h: Dictionary = ws.active_cbrn_hazards[0]
	assert_true(chem_h["type"] == "CHEMICAL", "Hazard type is 'CHEMICAL'")
	assert_true(chem_h["radius_km"] == 8.5, "Hazard radius is 8.5 km")
	assert_true(chem_h["ttl_sec"] == 45.0, "Hazard initial TTL is 45.0 seconds")

	# 2. Biological Hazard (expanding spore mist)
	var bio_pos := Vector3(-30.0, 0.0, 40.0)
	ws.spawn_biological_hazard(bio_pos, 5.0, 60.0, 0)
	assert_true(ws.active_cbrn_hazards.size() == 2, "Biological hazard spawned into WorldState")
	var bio_h: Dictionary = ws.active_cbrn_hazards[1]
	assert_true(bio_h["type"] == "BIOLOGICAL", "Hazard type is 'BIOLOGICAL'")

	# 3. Electromagnetic HEMP Hazard
	var emp_pos := Vector3(0.0, 25.0, 0.0)
	ws.spawn_electromagnetic_hazard(emp_pos, 25.0, 15.0, 0)
	assert_true(ws.active_cbrn_hazards.size() == 3, "Electromagnetic HEMP hazard spawned into WorldState")
	var emp_h: Dictionary = ws.active_cbrn_hazards[2]
	assert_true(emp_h["type"] == "ELECTROMAGNETIC", "Hazard type is 'ELECTROMAGNETIC'")

	# Simulate 1 second of decay and propagation
	SalvoCombatSystem.step(ws, sim_db, grid, 1.0)
	assert_true(ws.active_cbrn_hazards[0]["ttl_sec"] == 44.0, "Chemical hazard TTL decrements properly (44.0s)")
	assert_true(ws.active_cbrn_hazards[1]["radius_km"] > 5.0, "Biological pathogen radius expands dynamically over time")
	assert_true(ws.active_cbrn_hazards[2]["ttl_sec"] == 14.0, "Electromagnetic flux ring TTL decrements properly")


func test_doctrinal_military_formations() -> void:
	print("\n--- Test Suite 4: Doctrinal Military Formations Engine ---")

	# 1. Formation Selection Logic
	var naval_csg_fmt := TacticalDoctrineFormationSystemScript.select_formation_for_group(2, 0, true, -100.0, 0.0)
	assert_true(naval_csg_fmt == TacticalDoctrineFormationSystemScript.FormationType.CSG_RING, "Carrier Task Group selects CSG_RING formation")

	var air_fmt := TacticalDoctrineFormationSystemScript.select_formation_for_group(1, 0, false, 2500.0, 0.0)
	assert_true(air_fmt == TacticalDoctrineFormationSystemScript.FormationType.AIR_FINGER_FOUR, "Air squadron selects AIR_FINGER_FOUR formation")

	var defile_fmt := TacticalDoctrineFormationSystemScript.select_formation_for_group(0, 0, false, 850.0, 18.0)
	assert_true(defile_fmt == TacticalDoctrineFormationSystemScript.FormationType.DEFILE_COLUMN, "Steep valley/defile selects DEFILE_COLUMN formation")

	var ridge_fmt := TacticalDoctrineFormationSystemScript.select_formation_for_group(0, WorldState.TACTICAL_POSTURE_HOLD_AMBUSH, false, 400.0, 5.0)
	assert_true(ridge_fmt == TacticalDoctrineFormationSystemScript.FormationType.RIDGE_HULL_DOWN, "Defensive ambush posture selects RIDGE_HULL_DOWN formation")

	var wedge_fmt := TacticalDoctrineFormationSystemScript.select_formation_for_group(0, WorldState.TACTICAL_POSTURE_AGGRESSIVE_PURSUIT, false, 150.0, 2.0)
	assert_true(wedge_fmt == TacticalDoctrineFormationSystemScript.FormationType.WEDGE, "Open ground assault selects tactical WEDGE spearhead")

	# 2. Geometric Offsets Calculation
	var w0 := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.WEDGE, 0, 5, 0.0)
	var w1 := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.WEDGE, 1, 5, 0.0)
	var w2 := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.WEDGE, 2, 5, 0.0)
	assert_true(w0 == Vector3.ZERO, "Wedge lead element is at center origin (0, 0, 0)")
	assert_true(w1.x < 0.0 and w1.z < 0.0, "Wedge left wingman is stepped left (-X) and back (-Z)")
	assert_true(w2.x > 0.0 and w2.z < 0.0, "Wedge right wingman is stepped right (+X) and back (-Z)")

	# Defile column: staggered left/right along -Z axis
	var d0 := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.DEFILE_COLUMN, 0, 4, 0.0)
	var d1 := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.DEFILE_COLUMN, 1, 4, 0.0)
	assert_true(d0.x < 0.0 and d1.x > 0.0, "Defile column alternates sides (staggered left/right)")
	assert_true(d1.z < d0.z, "Defile column units trail longitudinally in depth")

	# CSG Ring: radius ~24km surrounding carrier
	var csg_lead := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.CSG_RING, 0, 5, 0.0)
	var csg_escort := TacticalDoctrineFormationSystemScript.compute_formation_offset(TacticalDoctrineFormationSystemScript.FormationType.CSG_RING, 1, 5, 0.0)
	assert_true(csg_lead == Vector3.ZERO, "CSG Supercarrier is at center sanctum")
	assert_true(absf(csg_escort.length() - 24.0) < 0.1, "CSG Escort is on defensive ring radius (~24 km)")

	# 3. Apply Doctrinal Formation to Battalion Hierarchy
	var ws_form := WorldState.new()
	ws_form.unit_count = 5
	ws_form.unit_active.resize(5)
	ws_form.unit_active.fill(1)
	ws_form.unit_pos.resize(5)
	ws_form.unit_heading_rad.resize(5)
	ws_form.unit_heading_rad.fill(0.0)
	ws_form.unit_parent_id.resize(5)

	# Unit 0 is parent HQ at (100, 0, 100), units 1..4 are subordinates
	ws_form.unit_pos[0] = Vector3(100.0, 0.0, 100.0)
	ws_form.unit_parent_id[0] = -1
	for i in range(1, 5):
		ws_form.unit_pos[i] = Vector3(100.0, 0.0, 100.0) # all start at same point
		ws_form.unit_parent_id[i] = 0

	TacticalDoctrineFormationSystemScript.apply_doctrinal_formation_to_battalion(
		ws_form, null, 0, TacticalDoctrineFormationSystemScript.FormationType.WEDGE
	)

	# Verify subordinates are now spaced apart doctrinally rather than clustered
	var dispersed := (ws_form.unit_pos[1] != ws_form.unit_pos[2]) and (ws_form.unit_pos[1] != Vector3(100.0, 0.0, 100.0))
	assert_true(dispersed, "Subordinate units dispersed into tactical wedge formation around battalion center")

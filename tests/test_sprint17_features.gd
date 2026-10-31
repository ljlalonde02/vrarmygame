extends SceneTree
## Sprint 17 Automated Adversarial Feature Verification Suite.
## Validates:
## 1. Multi-Tier Electronic Warfare Countermeasures: Towed Radar Decoys (US-17.1).
## 2. Dispensed Chaff Corridors & Radar Clutter Decay (US-17.1).
## 3. GPS Denial Bubbles & Munition Guidance Jamming (US-17.1).
## 4. AI Tactical Bounding Overwatch & Flanking Pincer Formations (US-17.2).

const TacticalDoctrineFormationSystemScript := preload("res://src/sim_core/systems/tactical_doctrine_formation_system.gd")
const SimDBScript := preload("res://src/autoloads/sim_db.gd")

var total_tests := 0
var passed_tests := 0


func _init() -> void:
	print("==================================================================")
	print("  RUNNING SPRINT 17 FEATURE VERIFICATION SUITE")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	sim_db.load_database()
	var grid := SpatialHashGrid.new()

	test_ew_towed_radar_decoys(sim_db, grid)
	test_ew_chaff_corridors(sim_db, grid)
	test_ew_gps_denial_zones(sim_db, grid)
	test_ai_tactical_bounding_and_pincer_formations()

	print("==================================================================")
	print("  SPRINT 17 TEST RESULTS: %d / %d PASSED (%.1f%%)" % [passed_tests, total_tests, float(passed_tests) / float(max(1, total_tests)) * 100.0])
	print("==================================================================")

	if passed_tests == total_tests:
		print(">> ALL SPRINT 17 FEATURES VERIFIED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SPRINT 17 TEST FAILURES DETECTED! <<")
		quit(1)


func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)


func test_ew_towed_radar_decoys(sim_db: Node, grid: SpatialHashGrid) -> void:
	print("\n--- Test Suite 1: Towed Radar Decoy (AN/ALE-50) Dynamics ---")
	var ws := WorldState.new()

	# Spawn Blue F-35A host aircraft at (20, 8000, 30) heading North (0 rad)
	var host_uid := ws.spawn_unit(WorldState.FACTION_BLUE, 1, Vector3(20.0, 8000.0, 30.0), WorldState.ECHELON_COMPANY)
	ws.unit_heading_rad[host_uid] = 0.0

	var decoy_idx := ws.deploy_towed_decoy(host_uid, 150.0, 55.0)
	assert_true(decoy_idx >= 0, "Towed radar decoy successfully deployed for host unit")
	assert_true(ws.active_towed_decoys.size() == 1, "WorldState active_towed_decoys has 1 active element")

	var dec: Dictionary = ws.active_towed_decoys[0]
	assert_true(dec["host_uid"] == host_uid, "Decoy correctly references host aircraft uid")
	assert_true(dec["rcs_sqm"] == 55.0, "Decoy amplifies radar cross section (55.0 m^2)")

	# Verify decoy trails behind aircraft: for heading 0 (North), trail is behind in -Z direction
	var dpos: Vector3 = dec["pos_km"]
	assert_true(dpos.z < ws.unit_pos[host_uid].z, "Decoy trails behind host aircraft (Z: %.4f vs host Z: %.4f)" % [dpos.z, ws.unit_pos[host_uid].z])

	# Advance host aircraft in simulation and verify decoy tracks behind host
	ws.unit_pos[host_uid] = Vector3(20.0, 8000.0, 35.0)
	SalvoCombatSystem.step(ws, sim_db, grid, 0.1)
	var new_dpos: Vector3 = ws.active_towed_decoys[0]["pos_km"]
	assert_true(new_dpos.z > dpos.z, "Towed decoy kinematically follows host aircraft forward progress")

	# Destroy/deactivate host aircraft and verify decoy deactivates
	ws.unit_active[host_uid] = 0
	SalvoCombatSystem.step(ws, sim_db, grid, 0.1)
	assert_true(not bool(ws.active_towed_decoys[0]["active"]), "Decoy deactivates when host aircraft is destroyed")


func test_ew_chaff_corridors(sim_db: Node, grid: SpatialHashGrid) -> void:
	print("\n--- Test Suite 2: Chaff Corridors & Clutter Decay ---")
	var ws := WorldState.new()

	var chaff_pos := Vector3(-40.0, 5000.0, 10.0)
	ws.deploy_chaff_cloud(chaff_pos, 4.2, 30.0, 0)
	assert_true(ws.active_chaff_clouds.size() == 1, "Chaff radar clutter cloud successfully deployed")

	var ch: Dictionary = ws.active_chaff_clouds[0]
	assert_true(ch["radius_km"] == 4.2, "Chaff cloud coverage radius is 4.2 km")
	assert_true(ch["ttl_sec"] == 30.0, "Chaff initial TTL is 30.0 seconds")
	assert_true(ch["rcs_clutter_sqm"] == 85.0, "Chaff creates dense dipole radar clutter (85 m^2)")

	# Step 5 seconds
	SalvoCombatSystem.step(ws, sim_db, grid, 5.0)
	assert_true(absf(ws.active_chaff_clouds[0]["ttl_sec"] - 25.0) < 0.1, "Chaff TTL decrements to 25.0s")

	# Step remaining 26 seconds to trigger expiration
	SalvoCombatSystem.step(ws, sim_db, grid, 26.0)
	assert_true(ws.active_chaff_clouds.is_empty(), "Expired chaff cloud pruned from WorldState")


func test_ew_gps_denial_zones(sim_db: Node, grid: SpatialHashGrid) -> void:
	print("\n--- Test Suite 3: GPS Denial Perimeters & PGM Jamming ---")
	var ws := WorldState.new()

	var denial_pos := Vector3(0.0, 0.0, 0.0)
	ws.deploy_gps_denial_zone(denial_pos, 25.0, 180.0, 1) # Red EW station covers 25km radius
	assert_true(ws.active_gps_denial_zones.size() == 1, "GPS denial zone deployed into WorldState")

	var gz: Dictionary = ws.active_gps_denial_zones[0]
	assert_true(gz["radius_km"] == 25.0, "GPS denial bubble radius is 25.0 km")

	# Spawn cruise missile inside GPS denial bubble at (10, 100, 10)
	var mid_in := ws.spawn_munition(0, 1, 0, 1, Vector3(10.0, 100.0, 10.0), Vector3(12.0, 100.0, 12.0), "SEA_SKIM_TERCOM")
	# Spawn cruise missile outside GPS denial bubble at (50, 100, 50)
	var mid_out := ws.spawn_munition(0, 1, 0, 1, Vector3(50.0, 100.0, 50.0), Vector3(55.0, 100.0, 55.0), "SEA_SKIM_TERCOM")

	assert_true(ws.mun_jammed[mid_in] == 0, "Munition inside bubble begins unjammed prior to simulation step")

	# Step simulation
	SalvoCombatSystem.step(ws, sim_db, grid, 0.1)

	assert_true(ws.mun_jammed[mid_in] == 1, "Munition inside GPS denial bubble is jammed with guidance drift")
	assert_true(ws.mun_jammed[mid_out] == 0, "Munition outside GPS denial bubble retains nominal guidance")


func test_ai_tactical_bounding_and_pincer_formations() -> void:
	print("\n--- Test Suite 4: Tactical Bounding Overwatch & Flanking Pincer ---")

	# 1. AI State constants
	assert_true(WorldState.AI_BOUNDING_OVERWATCH == 7, "AI_BOUNDING_OVERWATCH state defined as 7")
	assert_true(WorldState.AI_FLANKING_PINCER == 8, "AI_FLANKING_PINCER state defined as 8")

	# 2. Bounding Overwatch Offsets
	var b_lead := TacticalDoctrineFormationSystemScript.compute_formation_offset(
		TacticalDoctrineFormationSystemScript.FormationType.BOUNDING_OVERWATCH, 0, 4, 0.0
	)
	var b_bound := TacticalDoctrineFormationSystemScript.compute_formation_offset(
		TacticalDoctrineFormationSystemScript.FormationType.BOUNDING_OVERWATCH, 1, 4, 0.0
	)
	assert_true(b_lead.z < 0.0, "Bounding overwatch base-of-fire element provides stationary rear overwatch (-Z)")
	assert_true(b_bound.z > 0.0, "Bounding overwatch maneuver element leaps forward (+Z)")

	# 3. Flanking Pincer Offsets
	var p_center := TacticalDoctrineFormationSystemScript.compute_formation_offset(
		TacticalDoctrineFormationSystemScript.FormationType.FLANKING_PINCER, 0, 3, 0.0
	)
	var p_left := TacticalDoctrineFormationSystemScript.compute_formation_offset(
		TacticalDoctrineFormationSystemScript.FormationType.FLANKING_PINCER, 1, 3, 0.0
	)
	var p_right := TacticalDoctrineFormationSystemScript.compute_formation_offset(
		TacticalDoctrineFormationSystemScript.FormationType.FLANKING_PINCER, 2, 3, 0.0
	)
	assert_true(p_center == Vector3.ZERO, "Flanking pincer pinning element is center origin")
	assert_true(p_left.x < -4.0 and p_left.z > 0.0, "Flanking left hook wingman swings wide left (-X) and forward (+Z)")
	assert_true(p_right.x > 4.0 and p_right.z > 0.0, "Flanking right hook wingman swings wide right (+X) and forward (+Z)")

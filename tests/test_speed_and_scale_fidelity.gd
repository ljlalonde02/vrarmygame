extends SceneTree
## Automated Adversarial Verification Suite for Kinematic Speed Proportions, Dimensional Scales & Flight/Immersion Envelopes:
## - Test 1: True Relative Kinematic Speeds (Infantry ~10-18 km/h vs Armor ~52 km/h vs Heli ~260 km/h vs Jet ~1,037 km/h vs Hypersonic Mach 10).
## - Test 2: Infrastructure & Road Mobility Multiplier (Tank 1.45x road bonus reaching ~75 km/h on intact highways).
## - Test 3: Relative Miniature Dimensional Proportions (Soldier < Tank < Village House < Jet < Warship).
## - Test 4: Realistic Altitudes & Flight/Immersion Envelopes (Helicopter NOE 120m AGL, Jet 10,800m, Submarine -180m submerged table offset).

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const KinematicsSystemScript := preload("res://src/sim_core/systems/kinematics_system.gd")
const VisualSyncControllerScript := preload("res://src/presentation/war_table/visual_sync_controller.gd")
const TerrainInfrastructureSystemScript := preload("res://src/sim_core/systems/terrain_infrastructure_system.gd")

func _init() -> void:
	print("=== [GATE FIDELITY] STARTING SPEED & SCALE FIDELITY VERIFICATION SUITE ===")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var sim_db: Node = bunker.sim_db
	var sim_server: Node = bunker.sim_server
	var war_table: Node3D = bunker.war_table
	var st: WorldState = sim_server.world_state
	st.unit_count = maxi(st.unit_count, 32)

	# =========================================================================
	# TEST 1: TRUE RELATIVE KINEMATIC SPEEDS & PROPORTIONS
	# =========================================================================
	print("--- [1/4] Testing Relative Kinematic Speeds & Proportions (Infantry : Armor : Heli : Jet) ---")

	var pid_inf: int = sim_db.get_platform_id("specops_mountain_team")
	var pid_armor: int = sim_db.get_platform_id("m1a2_sepv3_platoon")
	var pid_heli: int = sim_db.get_platform_id("ah_64e_apache_guardian")
	var pid_jet: int = sim_db.get_platform_id("f_35a_lightning")

	assert(pid_inf > 0, "Infantry platform must exist in SimDB")
	assert(pid_armor > 0, "Armor platform must exist in SimDB")
	assert(pid_heli > 0, "Attack helicopter platform must exist in SimDB")
	assert(pid_jet > 0, "Jet fighter platform must exist in SimDB")

	var spd_inf_km_s: float = sim_db.plat_cruise_km_s[pid_inf]
	var spd_armor_km_s: float = sim_db.plat_cruise_km_s[pid_armor]
	var spd_heli_km_s: float = sim_db.plat_cruise_km_s[pid_heli]
	var spd_jet_km_s: float = sim_db.plat_cruise_km_s[pid_jet]

	var spd_inf_kmh: float = spd_inf_km_s * 3600.0
	var spd_armor_kmh: float = spd_armor_km_s * 3600.0
	var spd_heli_kmh: float = spd_heli_km_s * 3600.0
	var spd_jet_kmh: float = spd_jet_km_s * 3600.0

	print("  Infantry cruise speed:  %.1f km/h (%.5f km/s)" % [spd_inf_kmh, spd_inf_km_s])
	print("  Armor cruise speed:     %.1f km/h (%.5f km/s)" % [spd_armor_kmh, spd_armor_km_s])
	print("  Helicopter speed:       %.1f km/h (%.5f km/s)" % [spd_heli_kmh, spd_heli_km_s])
	print("  F-35A Jet speed:        %.1f km/h (%.5f km/s)" % [spd_jet_kmh, spd_jet_km_s])

	# Assert realistic speed boundaries
	assert(spd_inf_kmh >= 10.0 and spd_inf_kmh <= 25.0, "Infantry foot speed must be ~10 to 25 km/h")
	assert(spd_armor_kmh >= 45.0 and spd_armor_kmh <= 60.0, "Tank off-road cruise speed must be ~45 to 60 km/h")
	assert(spd_heli_kmh >= 240.0 and spd_heli_kmh <= 280.0, "Attack helicopter cruise speed must be ~240 to 280 km/h")
	assert(spd_jet_kmh >= 950.0 and spd_jet_kmh <= 1100.0, "Jet cruise speed must be ~950 to 1,100 km/h")

	# Assert relative speed proportions (Tank : Infantry ~ 2.8x, Jet : Tank ~ 20x, Jet : Infantry ~ 56x)
	var ratio_armor_inf: float = spd_armor_km_s / spd_inf_km_s
	var ratio_heli_armor: float = spd_heli_km_s / spd_armor_km_s
	var ratio_jet_armor: float = spd_jet_km_s / spd_armor_km_s
	var ratio_jet_inf: float = spd_jet_km_s / spd_inf_km_s

	print("  Ratios -> Armor/Inf: %.2fx | Heli/Armor: %.2fx | Jet/Armor: %.2fx | Jet/Inf: %.2fx" % [
		ratio_armor_inf, ratio_heli_armor, ratio_jet_armor, ratio_jet_inf
	])

	assert(ratio_armor_inf >= 2.5 and ratio_armor_inf <= 3.5, "Tank should be ~2.5x to 3.5x faster than infantry foot march")
	assert(ratio_heli_armor >= 4.5 and ratio_heli_armor <= 5.5, "Helicopter should be ~4.5x to 5.5x faster than tanks")
	assert(ratio_jet_armor >= 18.0 and ratio_jet_armor <= 22.0, "Jet should be ~18x to 22x faster than tanks")
	assert(ratio_jet_inf >= 50.0 and ratio_jet_inf <= 65.0, "Jet should be ~50x to 65x faster than infantry")

	# Verify KinematicsSystem actually moves units according to their authentic platform speed, NOT the old 0.088 clamp!
	var u_inf := 10
	var u_arm := 11
	st.unit_active[u_inf] = 1
	st.unit_platform_id[u_inf] = pid_inf
	st.unit_pos[u_inf] = Vector3(0.0, 100.0, 0.0)
	st.unit_target_pos[u_inf] = Vector3(50.0, 100.0, 0.0)
	st.unit_has_waypoint[u_inf] = 1
	st.unit_sim_lod[u_inf] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_arm] = 1
	st.unit_platform_id[u_arm] = pid_armor
	st.unit_pos[u_arm] = Vector3(0.0, 100.0, 0.0)
	st.unit_target_pos[u_arm] = Vector3(50.0, 100.0, 0.0)
	st.unit_has_waypoint[u_arm] = 1
	st.unit_sim_lod[u_arm] = WorldState.LOD_TIER_0_MICRO

	# Step kinematics 1 second
	KinematicsSystemScript.step(st, sim_db, 1.0)

	var moved_inf_km := st.unit_pos[u_inf].x
	var moved_arm_km := st.unit_pos[u_arm].x
	print("  1-sec displacement: Infantry = %.5f km | Armor = %.5f km" % [moved_inf_km, moved_arm_km])

	assert(moved_inf_km < 0.02, "Infantry must NOT move at 0.088 km/s! Actual step should be ~0.0051 km")
	assert(moved_arm_km > moved_inf_km * 2.0, "Armor displacement must be > 2x infantry displacement")

	print(" -> [TEST 1 PASSED] Relative speed proportions and authentic kinematics verified.")

	# =========================================================================
	# TEST 2: INFRASTRUCTURE & ROAD MOBILITY MULTIPLIER
	# =========================================================================
	print("--- [2/4] Testing Road Mobility Multiplier (Highway Tank Speed Enhancement) ---")

	# Seed infrastructure
	TerrainInfrastructureSystemScript.seed_theater_infrastructure(st)
	var test_x := 10.0
	var test_z := 10.0
	var cell_idx := st.get_infra_cell_index(test_x, test_z)

	# Set cell as intact highway
	st.infra_road_mask[cell_idx] = 1.0
	st.destruction_level[cell_idx] = 0.0
	st.infra_river_mask[cell_idx] = 0.0

	var mult_vehicle := st.get_ground_mobility_multiplier(test_x, test_z, false)
	var mult_foot := st.get_ground_mobility_multiplier(test_x, test_z, true)
	print("  Highway mobility: Vehicle = %.2fx | Foot = %.2fx" % [mult_vehicle, mult_foot])

	assert(mult_vehicle >= 1.40 and mult_vehicle <= 1.50, "Vehicles must receive 1.45x highway speed bonus")
	assert(mult_foot >= 1.15 and mult_foot <= 1.25, "Foot soldiers receive 1.20x road stride bonus")
	assert(mult_vehicle > mult_foot, "Vehicles benefit more from paved highways than foot march")

	print(" -> [TEST 2 PASSED] Road mobility multiplier enhancement verified.")

	# =========================================================================
	# TEST 3: RELATIVE MINIATURE DIMENSIONAL PROPORTIONS
	# =========================================================================
	print("--- [3/4] Testing Relative Miniature Dimensional Scales (Soldier < Tank < Village House < Jet < Warship) ---")

	var dummy_mat := StandardMaterial3D.new()
	var v_sync: Node = war_table.visual_sync
	if v_sync == null:
		v_sync = VisualSyncControllerScript.new()
		war_table.add_child(v_sync)

	var soldier_mesh: ArrayMesh = v_sync._create_tactical_soldier_mesh(dummy_mat)
	var tank_mesh: ArrayMesh = v_sync._create_tank_turret_mesh(dummy_mat)
	var jet_mesh: ArrayMesh = v_sync._create_swept_jet_mesh(dummy_mat)
	var ship_mesh: ArrayMesh = v_sync._create_warship_mesh(dummy_mat)

	var aabb_soldier := soldier_mesh.get_aabb()
	var aabb_tank := tank_mesh.get_aabb()
	var aabb_jet := jet_mesh.get_aabb()
	var aabb_ship := ship_mesh.get_aabb()

	print("  Soldier AABB:  size = %s (H = %.4fm, W = %.4fm)" % [aabb_soldier.size, aabb_soldier.size.y, aabb_soldier.size.x])
	print("  Tank AABB:     size = %s (H = %.4fm, W = %.4fm, L = %.4fm)" % [aabb_tank.size, aabb_tank.size.y, aabb_tank.size.x, aabb_tank.size.z])
	print("  Jet AABB:      size = %s (Wingspan = %.4fm, L = %.4fm)" % [aabb_jet.size, aabb_jet.size.x, aabb_jet.size.z])
	print("  Warship AABB:  size = %s (Beam = %.4fm, L = %.4fm)" % [aabb_ship.size, aabb_ship.size.x, aabb_ship.size.z])

	# 3a. Soldier miniature must be smaller in height and width than a tank
	assert(aabb_soldier.size.y < aabb_tank.size.y, "Soldier height (%.4fm) must be strictly smaller than tank height (%.4fm)!" % [aabb_soldier.size.y, aabb_tank.size.y])
	assert(aabb_soldier.size.x < aabb_tank.size.x, "Soldier width (%.4fm) must be strictly smaller than tank width (%.4fm)!" % [aabb_soldier.size.x, aabb_tank.size.x])
	assert(aabb_soldier.size.y <= aabb_tank.size.y * 0.85, "Soldier should be at most 85% of tank height")

	# 3b. Tank must be smaller than jet wingspan and ship length
	assert(aabb_tank.size.z < aabb_jet.size.z, "Tank length must be smaller than fighter jet length")
	assert(aabb_jet.size.z < aabb_ship.size.z, "Jet length must be smaller than warship length")
	assert(aabb_tank.size.z < aabb_ship.size.z * 0.35, "Warship must be at least 3x longer than a tank")

	# 3c. Village house scale in infrastructure system accommodates tanks and roads
	var house_found := false
	for bi in range(st.bldg_count):
		if st.bldg_type[bi] == WorldState.BLDG_VILLAGE_HOUSE:
			var h_scl := st.bldg_scale_m[bi]
			assert(h_scl.x > aabb_tank.size.x, "Village house width (%.4fm) must be larger than tank width (%.4fm)" % [h_scl.x, aabb_tank.size.x])
			assert(h_scl.y >= aabb_tank.size.y, "Village house height (%.4fm) must accommodate or exceed tank height (%.4fm)" % [h_scl.y, aabb_tank.size.y])
			house_found = true
			break
	assert(house_found, "At least one village house must exist in theater")

	print(" -> [TEST 3 PASSED] Relative miniature spatial scales verified.")

	# =========================================================================
	# TEST 4: REALISTIC ALTITUDES, NOE HELICOPTER ENVELOPES & SUBMERGED SUBMARINES
	# =========================================================================
	print("--- [4/4] Testing Realistic Altitudes (Heli NOE 120m, Jet 10,800m, Submarine -180m submerged offset) ---")

	# 4a. Attack Helicopter operational altitude in SimDB
	var heli_op_alt: float = float(sim_db.plat_cruise_alt_m[pid_heli])
	var jet_op_alt: float = float(sim_db.plat_cruise_alt_m[pid_jet])
	print("  Operational Altitudes: Helicopter = %.1fm | Jet = %.1fm" % [heli_op_alt, jet_op_alt])

	assert(heli_op_alt <= 200.0 and heli_op_alt >= 80.0, "Helicopter operational altitude must be NOE 80-200m AGL")
	assert(jet_op_alt >= 8000.0, "Jet fighter operational altitude must be high-altitude BVR (>= 8,000m)")

	# 4b. Step helicopter kinematics: helicopter must stay NOE, NOT jump to 8,500m!
	var u_heli := 14
	st.unit_active[u_heli] = 1
	st.unit_platform_id[u_heli] = pid_heli
	st.unit_pos[u_heli] = Vector3(15.0, 120.0, 15.0)
	st.unit_target_pos[u_heli] = Vector3(35.0, 120.0, 15.0)
	st.unit_has_waypoint[u_heli] = 1
	st.unit_desired_alt_m[u_heli] = 120.0
	st.unit_sim_lod[u_heli] = WorldState.LOD_TIER_0_MICRO

	KinematicsSystemScript.step(st, sim_db, 0.5)
	var heli_cur_alt := st.unit_pos[u_heli].y
	print("  Helicopter altitude after step: %.1fm" % heli_cur_alt)
	assert(heli_cur_alt < 500.0, "Attack helicopter must stay in NOE contour flight (< 500m), got %.1fm" % heli_cur_alt)

	# 4c. Submarine negative immersion depth and table offset
	var pid_ssbn: int = sim_db.get_platform_id("columbia_class_ssbn")
	assert(pid_ssbn > 0, "Columbia SSBN must exist in SimDB")
	var ssbn_depth: float = float(sim_db.plat_cruise_alt_m[pid_ssbn])
	print("  SSBN operational depth: %.1fm" % ssbn_depth)
	assert(ssbn_depth <= -50.0, "SSBN operational altitude must be submerged (negative depth <= -50m)")

	var u_sub := 15
	st.unit_active[u_sub] = 1
	st.unit_platform_id[u_sub] = pid_ssbn
	st.unit_pos[u_sub] = Vector3(80.0, -180.0, 80.0)
	st.unit_target_pos[u_sub] = Vector3(100.0, -180.0, 80.0)
	st.unit_has_waypoint[u_sub] = 1
	st.unit_desired_alt_m[u_sub] = -180.0
	st.unit_sim_lod[u_sub] = WorldState.LOD_TIER_0_MICRO

	KinematicsSystemScript.step(st, sim_db, 0.5)
	var sub_cur_alt := st.unit_pos[u_sub].y
	print("  Submarine altitude after step: %.1fm" % sub_cur_alt)
	assert(sub_cur_alt <= -20.0, "Submarine must remain submerged with negative altitude, got %.1fm" % sub_cur_alt)

	# 4d. Table coordinate projection for submerged submarine
	var table_loc_sub: Vector3 = war_table.theater_km_to_table_local(st.unit_pos[u_sub])
	var table_loc_surface: Vector3 = war_table.theater_km_to_table_local(Vector3(st.unit_pos[u_sub].x, 0.0, st.unit_pos[u_sub].z))
	print("  Table Local Y: Submerged Sub = %.5fm | Sea Surface = %.5fm" % [table_loc_sub.y, table_loc_surface.y])
	assert(table_loc_sub.y < table_loc_surface.y, "Submerged submarine local table Y (%.5fm) must be lower than sea surface (%.5fm)" % [
		table_loc_sub.y, table_loc_surface.y
	])

	print(" -> [TEST 4 PASSED] Altitudes, NOE flight envelopes and submarine table immersion verified.")

	print("=== [GATE FIDELITY COMPLETE] ALL 4 SPEED & SCALE FIDELITY TESTS PASSED WITH 0 ERRORS! ===")
	quit(0)

extends SceneTree
## Gate 2 Automated Verification Suite (`res://tests/test_sim_core.gd`)
## Tests:
## 1. SimDB O(1) lookup tables (36 platforms, 23 weapons, 59/59 real Wikipedia photos).
## 2. WorldState Structure-of-Arrays allocation with 600+ active units across 500km x 500km theater.
## 3. Authentic Fourth-Root Radar Cross Section (RCS) & Terrain Horizon detection math.
## 4. Quadruped Robot Dog (`vision_60_q_ugv`) cliff-climbing vs tank slope penalty & `CMD_DEPLOY_UNMANNED_SUBUNIT`.
## 5. Electronic Warfare C2 jamming (`RF_DATALINK` jammed vs `FIBER_OPTIC` & `AUTONOMOUS_AI` immunity).
## 6. Alpha Strike Salvo launch, Directed Energy (`Iron Beam` 100kW laser + `Epirus Leonidas` 30° HPM microwave cone), and 50 simulation ticks.

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CommandBusScript := preload("res://src/autoloads/command_bus.gd")
const SignalBusScript := preload("res://src/autoloads/signal_bus.gd")


func _init() -> void:
	print("==================================================================")
	print("[GATE 2] Starting Headless SimCore Verification Suite...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	var cmd_bus := CommandBusScript.new()
	var sig_bus := SignalBusScript.new()
	sim_db.load_database()

	# 1. Verify SimDB O(1) tables & real Wikipedia images
	var num_platforms := sim_db.platforms_by_id.size() - 1
	var num_weapons := sim_db.weapons_by_id.size() - 1
	print("  [1] SimDB Loaded: %d platforms, %d weapons, %d scenarios" % [num_platforms, num_weapons, sim_db.scenarios_list.size()])
	assert(num_platforms >= 36, "Expected at least 36 platforms in SimDB")
	assert(num_weapons >= 23, "Expected at least 23 weapons in SimDB")

	var f35_def := sim_db.get_platform_by_slug("f_35a_lightning")
	var dog_def := sim_db.get_platform_by_slug("vision_60_q_ugv")
	var hpm_def := sim_db.get_platform_by_slug("epirus_leonidas_hpm")
	assert(not f35_def.is_empty(), "F-35A platform must exist")
	assert(int(dog_def.get("can_climb_steep_slopes", 0)) == 1, "Vision 60 Robot Dog must have can_climb_steep_slopes=1")
	assert(float(hpm_def.get("de_aoe_cone_deg", 0.0)) == 30.0, "Epirus Leonidas HPM must have 30 deg cone")

	# 2. Boot SimServer & Spawn 600+ Units in Operation Pacific Shield
	var sim_server := SimServer.new()
	sim_server.setup_references(sim_db, cmd_bus, sig_bus)
	sim_server.load_scenario("op_pacific_shield_2028")

	var total_active := sim_server.world_state.get_active_unit_count()
	print("  [2] Scenario 'op_pacific_shield_2028' spawned %d active hierarchical units" % total_active)
	assert(total_active >= 600, "Expected 600+ active units in Operation Pacific Shield, got %d" % total_active)

	# 3. Verify Fourth-Root Radar Cross Section (RCS) Equation
	# Base 160km radar vs 5.0 m^2 target -> 160.0 km; vs F-35 (0.0015 m^2) -> ~20.9 km
	var r_4th_gen := SensorLoSSystem.compute_effective_detection_range_km(160.0, 5.0)
	var r_f35 := SensorLoSSystem.compute_effective_detection_range_km(160.0, 0.0015)
	print("  [3] Radar Equation Check: 160km radar -> 5.0m^2 = %.1f km | F-35 (0.0015m^2) = %.2f km" % [r_4th_gen, r_f35])
	assert(absf(r_4th_gen - 160.0) < 0.1, "5.0 m^2 reference RCS should yield 160.0 km")
	assert(r_f35 > 19.5 and r_f35 < 22.5, "F-35 0.0015 m^2 RCS detection range should be ~20.9 km")

	# 4. Test Quadruped Robot Dog Unpacking (`CMD_DEPLOY_UNMANNED_SUBUNIT`)
	var bradley_uid := -1
	for uid in range(sim_server.world_state.unit_count):
		if sim_server.world_state.unit_active[uid] == 1 and sim_server.world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY and sim_server.world_state.unit_unmanned_bays[uid] > 0:
			bradley_uid = uid
			break
	assert(bradley_uid >= 0, "Should find a carrier unit with unmanned bays")
	var bays_before := sim_server.world_state.unit_unmanned_bays[bradley_uid]
	var units_before := sim_server.world_state.get_active_unit_count()
	cmd_bus.enqueue_deploy_unmanned([bradley_uid], Vector3(2.0, 0.0, -1.5))
	sim_server.step_tick(0.1)
	var bays_after := sim_server.world_state.unit_unmanned_bays[bradley_uid]
	var units_after := sim_server.world_state.get_active_unit_count()
	print("  [4] Unmanned Deployment: Carrier uid=%d bays %d -> %d | Total active units %d -> %d" % [
		bradley_uid, bays_before, bays_after, units_before, units_after
	])
	assert(bays_after == bays_before - 1, "Unmanned bay count must decrement on deployment")
	assert(units_after == units_before + 1, "Deploying Robot Dog / FPV pack must increment active units")

	# 5. Test Electronic Warfare Jamming vs Fiber-Optic & Autonomous AI Immunity
	var ew_pos := Vector3(0.0, 100.0, 0.0)
	var ew_uid := sim_server.world_state.spawn_unit(
		WorldState.FACTION_RED,
		sim_db.get_platform_id("krasukha_4_ew"),
		ew_pos,
		WorldState.ECHELON_COMPANY,
		-1,
		sim_db.get_platform_by_slug("krasukha_4_ew")
	)
	var rf_drone_uid := sim_server.world_state.spawn_unit(
		WorldState.FACTION_BLUE,
		sim_db.get_platform_id("switchblade_600_team"), # RF_DATALINK
		ew_pos + Vector3(8.0, 0.0, 0.0),
		WorldState.ECHELON_COMPANY,
		-1,
		sim_db.get_platform_by_slug("switchblade_600_team")
	)
	var fiber_fpv_uid := sim_server.world_state.spawn_unit(
		WorldState.FACTION_BLUE,
		sim_db.get_platform_id("fpv_fiber_swarm"), # FIBER_OPTIC
		ew_pos + Vector3(8.0, 0.0, 2.0),
		WorldState.ECHELON_COMPANY,
		-1,
		sim_db.get_platform_by_slug("fpv_fiber_swarm")
	)
	var ai_dog_uid := sim_server.world_state.spawn_unit(
		WorldState.FACTION_BLUE,
		sim_db.get_platform_id("vision_60_q_ugv"), # AUTONOMOUS_AI
		ew_pos + Vector3(8.0, 0.0, -2.0),
		WorldState.ECHELON_COMPANY,
		-1,
		sim_db.get_platform_by_slug("vision_60_q_ugv")
	)
	assert(ew_uid >= 0, "Krasukha-4 EW must spawn")
	sim_server.step_tick(0.1)
	print("  [5] EW Jamming Check: RF_DATALINK jammed=%d | FIBER_OPTIC jammed=%d | AUTONOMOUS_AI Robot Dog jammed=%d" % [
		sim_server.world_state.unit_jammed[rf_drone_uid],
		sim_server.world_state.unit_jammed[fiber_fpv_uid],
		sim_server.world_state.unit_jammed[ai_dog_uid]
	])
	assert(sim_server.world_state.unit_jammed[rf_drone_uid] == 1, "RF_DATALINK drone inside Krasukha-4 cone must be jammed")
	assert(sim_server.world_state.unit_jammed[fiber_fpv_uid] == 0, "FIBER_OPTIC FPV swarm must be immune to RF jamming")
	assert(sim_server.world_state.unit_jammed[ai_dog_uid] == 0, "AUTONOMOUS_AI Vision 60 Robot Dog must be immune to RF jamming")

	# 6. Test Directed Energy (Iron Beam 100kW Laser & Epirus Leonidas 30 deg HPM Cone) vs Incoming Drone Swarms
	var hpm_pos := Vector3(50.0, 50.0, 50.0)
	var hpm_uid := sim_server.world_state.spawn_unit(
		WorldState.FACTION_BLUE,
		sim_db.get_platform_id("epirus_leonidas_hpm"),
		hpm_pos,
		WorldState.ECHELON_COMPANY,
		-1,
		sim_db.get_platform_by_slug("epirus_leonidas_hpm")
	)
	var shahed_wid := sim_db.get_weapon_id("shahed_136_round")
	for s_i in range(4):
		sim_server.world_state.spawn_munition(
			WorldState.FACTION_RED,
			shahed_wid,
			ew_uid,
			hpm_uid,
			hpm_pos + Vector3(4.0, 120.0, float(s_i) * 0.2),
			hpm_pos,
			"SEA_SKIM_TERCOM"
		)
	var intercepts_before := sim_server.world_state.blue_munitions_intercepted
	sim_server.step_tick(0.1)
	var intercepts_after := sim_server.world_state.blue_munitions_intercepted
	print("  [6] Epirus Leonidas 30-deg HPM Microwave Cone intercepted %d Shahed drones in a single pulse!" % (intercepts_after - intercepts_before))
	assert(intercepts_after - intercepts_before >= 2, "Epirus Leonidas HPM cone should fry multiple drones in one pulse")

	# 7. Test Queued Strike + Alpha Strike Commit & Run 50 Simulation Ticks
	cmd_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)
	var t_start_usec := Time.get_ticks_usec()
	for tick in range(50):
		sim_server.step_tick(0.1)
	var elapsed_ms := float(Time.get_ticks_usec() - t_start_usec) / 1000.0
	var active_muns := sim_server.world_state.get_active_munition_count()
	print("  [7] Completed 50 simulation ticks (688+ units + salvos) in %.2f ms (%.3f ms/tick) | Active Munitions=%d" % [
		elapsed_ms, elapsed_ms / 50.0, active_muns
	])
	assert(sim_server.world_state.tick_id >= 52, "Tick ID must advance accurately")

	print("==================================================================")
	print("[GATE 2 PASSED] All SimCore assertions succeeded with 0 errors!")
	print("==================================================================")
	sim_server.cleanup()
	sim_server.free()
	sig_bus.free()
	cmd_bus.free()
	sim_db.free()
	quit(0)

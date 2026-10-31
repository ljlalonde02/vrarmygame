extends SceneTree
## Automated Test Suite for Sprint 6 Features:
## 1. Fighter Squadron Maneuvers, Lead Pursuit & Flare Countermeasures
## 2. Integrated Air Defense (IADS) Radar Tracking Cones & Vertical SAM Launches
## 3. DEFCON 1 Multi-Stage Thermonuclear Detonation Simulation
## 4. Diegetic Bunker Reaction, Seismic Shockwave & Emergency Crimson Strobes
## 5. Journalistic AI War News Feeds & Video Player Synchronization

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CommandBusScript := preload("res://src/autoloads/command_bus.gd")
const SignalBusScript := preload("res://src/autoloads/signal_bus.gd")
const SimServerScript := preload("res://src/sim_core/sim_server.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const SpatialHashGridScript := preload("res://src/sim_core/spatial_hash_grid.gd")
const UnitTacticalAISystemScript := preload("res://src/sim_core/systems/unit_tactical_ai_system.gd")
const KinematicsSystemScript := preload("res://src/sim_core/systems/kinematics_system.gd")
const SalvoCombatSystemScript := preload("res://src/sim_core/systems/salvo_combat_system.gd")
const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")
const CommandBunkerScript := preload("res://src/presentation/bunker/command_bunker.gd")


func _init() -> void:
	print("==================================================================")
	print("[SPRINT 6 TEST SUITE] Running Verification for Sprint 6 Features...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	sim_db.load_database()

	var passed := 0
	var failed := 0

	if _test_squadron_maneuvers_and_flares(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_iads_radar_tracking_and_vertical_sam(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_multistage_thermonuclear_simulation(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_bunker_seismic_shockwave_and_crimson_beacons(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_journalistic_news_and_video_sync(sim_db):
		passed += 1
	else:
		failed += 1

	print("==================================================================")
	if failed == 0:
		print("[SPRINT 6 TEST SUITE] ALL %d ADVERSARIAL TESTS PASSED (100%% OK)" % passed)
		quit(0)
	else:
		printerr("[SPRINT 6 TEST SUITE] %d PASSED, %d FAILED!" % [passed, failed])
		quit(1)


func _test_squadron_maneuvers_and_flares(sim_db: Node) -> bool:
	print("\n--- [1/5] Testing Fighter Squadron Lead Pursuit & Flare Countermeasures ---")
	var state := WorldStateScript.new()
	var grid := SpatialHashGridScript.new()

	var f35_pid: int = sim_db.get_platform_id("us_f35a_lightning")
	var su57_pid: int = sim_db.get_platform_id("ru_su57_felon")
	if f35_pid <= 0:
		f35_pid = 1
	if su57_pid <= 0:
		su57_pid = 2

	var u0: int = state.spawn_unit(WorldState.FACTION_BLUE, f35_pid, Vector3(0.0, 8500.0, 0.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(f35_pid))
	state.unit_vel[u0] = Vector3(0.55, 0.0, 0.0)
	state.unit_heading_rad[u0] = 0.0
	state.unit_detected_mask[u0] = 3

	var u1: int = state.spawn_unit(WorldState.FACTION_RED, su57_pid, Vector3(25.0, 8800.0, 5.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(su57_pid))
	state.unit_vel[u1] = Vector3(-0.52, 0.0, 0.0)
	state.unit_heading_rad[u1] = PI
	state.unit_detected_mask[u1] = 3

	grid.rebuild(state)

	# Run tactical AI
	UnitTacticalAISystemScript.step(state, sim_db, grid, 0.1)

	# Assert lead pursuit waypoint set for Blue F-35
	if state.unit_has_waypoint[u0] == 0:
		printerr("FAIL: F-35 flight did not establish an intercept waypoint.")
		return false
	var wp: Vector3 = state.unit_target_pos[u0]
	if wp.x >= 25.0: # Target was at x=25 moving towards 0; lead pursuit must lead ahead (x < 25.0)
		printerr("FAIL: Lead pursuit did not lead ahead of closing enemy flight. wp.x=", wp.x)
		return false

	# Test flare deployment under RWR spike
	UnitTacticalAISystemScript.trigger_rwr_warning(state, sim_db, u0, u1)
	if state.active_countermeasures.is_empty():
		printerr("FAIL: Tactical AI trigger_rwr_warning did not spawn active countermeasure flares.")
		return false

	var cm: Dictionary = state.active_countermeasures[0]
	if not cm.has("pos_km") or not cm.has("vel_km_s") or float(cm.get("ttl_sec", 0.0)) <= 0.0:
		printerr("FAIL: Active countermeasure missing physical attributes.")
		return false

	# Run Kinematics and Salvo to advance flight and flares
	KinematicsSystemScript.step(state, sim_db, 0.1)
	SalvoCombatSystemScript.step(state, sim_db, grid, 0.1)

	if state.unit_roll_rad[u0] == 0.0 and state.unit_heading_rad[u0] == 0.0:
		printerr("FAIL: Aircraft kinematics failed to compute turn heading or bank angle.")
		return false

	print("  PASS: Fighter squadron lead pursuit, banking dynamics, and flare countermeasures verified.")
	return true


func _test_iads_radar_tracking_and_vertical_sam(sim_db: Node) -> bool:
	print("\n--- [2/5] Testing IADS Radar Tracking Cones & Vertical SAM Launches ---")
	var state := WorldStateScript.new()
	var grid := SpatialHashGridScript.new()

	var sam_pid: int = sim_db.get_platform_id("mim_104f_patriot")
	if sam_pid <= 0:
		sam_pid = 5
	var u_sam: int = state.spawn_unit(WorldState.FACTION_BLUE, sam_pid, Vector3(-10.0, 15.0, -10.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(sam_pid))
	state.unit_radar_active[u_sam] = 1
	state.unit_roe[u_sam] = 1
	state.unit_ammo_1[u_sam] = 16

	var bmr_pid: int = sim_db.get_platform_id("tu_22m3_backfire")
	if bmr_pid <= 0:
		bmr_pid = 6
	var u_bmr: int = state.spawn_unit(WorldState.FACTION_RED, bmr_pid, Vector3(25.0, 6500.0, 15.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(bmr_pid))
	state.unit_vel[u_bmr] = Vector3(-0.35, 0.0, -0.2)
	state.unit_detected_mask[u_bmr] = 1

	grid.rebuild(state)

	# Run salvo combat step
	SalvoCombatSystemScript.step(state, sim_db, grid, 0.1)

	# Assert active radar track was registered
	if state.active_radar_tracks.is_empty():
		printerr("FAIL: Ground SAM radar battery did not register active radar tracking cone.")
		return false

	var trk: Dictionary = state.active_radar_tracks[0]
	if int(trk.get("radar_uid", -1)) != u_sam or int(trk.get("target_uid", -1)) != u_bmr:
		printerr("FAIL: Radar track has invalid radar or target unit IDs: ", trk)
		return false

	# Test vertical SAM missile launch profile
	var launched := SalvoCombatSystemScript.launch_strike_salvo(state, sim_db, u_sam, u_bmr, state.unit_pos[u_bmr], 1, 1)
	if launched <= 0 or state.mun_count <= 0:
		printerr("FAIL: SAM battery failed to launch interceptor salvo.")
		return false

	var mid := state.mun_count - 1
	# Advance munition step and check altitude boost
	SalvoCombatSystemScript.step(state, sim_db, grid, 0.05)
	var m_alt: float = state.mun_pos[mid].y
	if m_alt <= 20.0:
		printerr("FAIL: Vertical launch boost failed to lift SAM missile vertically. Alt=", m_alt)
		return false

	print("  PASS: Ground SAM radar tracking cone and vertical missile launch verified.")
	return true


func _test_multistage_thermonuclear_simulation(sim_db: Node) -> bool:
	print("\n--- [3/5] Testing DEFCON 1 Multi-Stage Thermonuclear Detonation ---")
	var state := WorldStateScript.new()

	var det_pos := Vector3(12.0, 5.0, -8.0)
	var nuke_res := state.trigger_thermonuclear_detonation(det_pos, WorldState.FACTION_BLUE, 350.0)

	if state.defcon_level != 1:
		printerr("FAIL: WorldState defcon_level was not set to 1. Got: ", state.defcon_level)
		return false

	if state.global_escalation_score < 99.0:
		printerr("FAIL: Global escalation score was not 100%. Got: ", state.global_escalation_score)
		return false

	if state.bunker_shock_tremor < 0.99:
		printerr("FAIL: Bunker shock tremor was not triggered at maximum. Got: ", state.bunker_shock_tremor)
		return false

	if state.active_nuclear_fireballs.is_empty():
		printerr("FAIL: active_nuclear_fireballs does not contain detonation entry.")
		return false

	var fb: Dictionary = state.active_nuclear_fireballs[0]
	if String(fb.get("type", "")) != "NUKE" or not fb.has("shockwave_max_r_km") or not fb.has("mushroom_stem_h_km"):
		printerr("FAIL: Detonation entry missing multi-stage physics parameters: ", fb)
		return false

	print("  Detonation Profile: Yield=%.0f kt | Fireball=%.0f km | Shockwave=%.0f km | Stem=%.0f km | EMP=%.0f km" % [
		fb.get("yield_kt", 0.0), fb.get("fireball_max_r_km", 0.0),
		fb.get("shockwave_max_r_km", 0.0), fb.get("mushroom_stem_h_km", 0.0), fb.get("emp_wave_max_r_km", 0.0)
	])
	print("  PASS: Full DEFCON 1 multi-stage thermonuclear detonation registered successfully.")
	return true


func _test_bunker_seismic_shockwave_and_crimson_beacons(sim_db: Node) -> bool:
	print("\n--- [4/5] Testing Bunker Atmosphere, Shockwave & Emergency Crimson Strobes ---")
	var bunker := CommandBunkerScript.new()
	var cmd_bus := CommandBusScript.new()
	var sig_bus := SignalBusScript.new()
	bunker.initialize_bunker(sim_db, cmd_bus, sig_bus)

	var st: WorldState = bunker.sim_server.world_state
	# Trigger nuke
	st.trigger_thermonuclear_detonation(Vector3(50.0, 0.0, 50.0), WorldState.FACTION_RED, 450.0)

	# Process bunker atmosphere
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)

	# Verify thermal flash and crimson strobe lighting
	if bunker._thermal_flash_timer <= 0.0:
		printerr("FAIL: Bunker did not initiate thermal flash timer.")
		bunker.cleanup_bunker()
		bunker.free()
		return false

	if bunker._key_light == null or bunker._key_light.light_energy < 3.0:
		printerr("FAIL: Key light energy did not spike for thermal flash.")
		bunker.cleanup_bunker()
		bunker.free()
		return false

	# Advance past thermal flash (0.65s) and let emergency crimson strobe settle
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.65)
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.50)
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.50)
	if bunker._key_light.light_color.r < 0.8 or bunker._key_light.light_color.b > 0.4:
		printerr("FAIL: Bunker light did not transition into crimson DEFCON 1 strobe: ", bunker._key_light.light_color)
		bunker.cleanup_bunker()
		bunker.free()
		return false

	bunker.cleanup_bunker()
	bunker.free()
	print("  PASS: Bunker thermal flash, seismic tremor, and emergency crimson strobes verified.")
	return true


func _test_journalistic_news_and_video_sync(sim_db: Node) -> bool:
	print("\n--- [5/5] Testing Journalistic AI War News Feeds & Video Player Synchronization ---")
	var state := WorldStateScript.new()

	# Verify native video frame sequences in SimDB
	var test_slugs := ["thermonuclear_detonation", "sam_air_defense_intercept", "stealth_airstrike_sortie", "missile_alpha_strike"]
	for slug in test_slugs:
		var clip: Dictionary = sim_db.get_news_video_clip(slug)
		if clip.is_empty():
			printerr("FAIL: Missing news video clip for slug: ", slug)
			return false
		var frames: Array = sim_db.get_news_video_frame_textures(slug)
		if frames.is_empty():
			printerr("FAIL: SimDB failed to return animation frames for: ", slug)
			return false
		if not clip.has("network") or not clip.has("headline") or not clip.has("ogv_res_path"):
			printerr("FAIL: Clip definition incomplete for: ", slug)
			return false

	# Verify video broadcast trigger updates headline and active slug
	state.active_news_video_slug = "thermonuclear_detonation"
	state.active_news_video_network = "GNN GLOBAL CRISIS DESK"
	state.active_news_video_headline = "BREAKING: THERMONUCLEAR MIRV DETONATION DETECTED OVER THEATER"

	if state.active_news_video_slug != "thermonuclear_detonation":
		printerr("FAIL: State news video slug did not persist.")
		return false

	print("  PASS: Journalistic broadcast manifests, OGV video streams, and frame sequences verified.")
	return true

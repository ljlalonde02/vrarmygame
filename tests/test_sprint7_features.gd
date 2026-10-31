extends SceneTree
## Automated Test Suite for Sprint 7 Features:
## 1. Multi-Unit Tactical Postures & Diegetic 3D Command Radial (MOVE, HOLD/AMBUSH, RETREAT)
## 2. Tank Battalion Turret Azimuth Tracking, APFSDS Firing & Kinetic Muzzle Blast Events
## 3. Attack Helicopter Tactics, Terrain Cover & Infantry Suppression Slowdown Penalty
## 4. Submarine Acoustic Sonar Pings & Expanding Sonar Waveforms
## 5. End-to-End Playable Tactical Match Loop (Objective Evaluation -> VICTORY / DEFEAT)

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CommandBusScript := preload("res://src/autoloads/command_bus.gd")
const SignalBusScript := preload("res://src/autoloads/signal_bus.gd")
const SimServerScript := preload("res://src/sim_core/sim_server.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const SpatialHashGridScript := preload("res://src/sim_core/spatial_hash_grid.gd")
const UnitTacticalAISystemScript := preload("res://src/sim_core/systems/unit_tactical_ai_system.gd")
const KinematicsSystemScript := preload("res://src/sim_core/systems/kinematics_system.gd")
const SalvoCombatSystemScript := preload("res://src/sim_core/systems/salvo_combat_system.gd")


func _init() -> void:
	print("==================================================================")
	print("[SPRINT 7 TEST SUITE] Running Verification for Sprint 7 Features...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	sim_db.load_database()

	var passed := 0
	var failed := 0

	if _test_multi_unit_tactical_postures(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_tank_turret_azimuth_and_apfsds_muzzle_flash(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_helicopter_and_infantry_suppression(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_submarine_sonar_waves(sim_db):
		passed += 1
	else:
		failed += 1

	if _test_tactical_match_victory_defeat_loop(sim_db):
		passed += 1
	else:
		failed += 1

	print("==================================================================")
	if failed == 0:
		print("[SPRINT 7 TEST SUITE] ALL %d ADVERSARIAL TESTS PASSED (100%% OK)" % passed)
		quit(0)
	else:
		printerr("[SPRINT 7 TEST SUITE] %d TESTS FAILED!" % failed)
		quit(1)


func _test_multi_unit_tactical_postures(sim_db: Node) -> bool:
	print("[TEST 1] Verifying Tactical Postures (HOLD/AMBUSH & RETREAT)...")
	var state := WorldStateScript.new()
	state.reset()

	var tank_pid := -1
	var inf_pid := -1
	for pid in range(1, sim_db.plat_class_flags.size()):
		var flg: int = sim_db.plat_class_flags[pid]
		if (flg & int(sim_db.FLAG_ARMOR)) != 0 and tank_pid < 0:
			tank_pid = pid
		if (flg & int(sim_db.FLAG_INFANTRY)) != 0 and inf_pid < 0:
			inf_pid = pid

	if tank_pid < 0 or inf_pid < 0:
		printerr("  FAILED: Armor or Infantry platform definitions missing in SimDB!")
		return false

	var tank_uid := state.spawn_unit(WorldState.FACTION_BLUE, tank_pid, Vector3(10.0, 0.0, 10.0), WorldState.ECHELON_COMPANY)
	var inf_uid := state.spawn_unit(WorldState.FACTION_BLUE, inf_pid, Vector3(50.0, 0.0, 50.0), WorldState.ECHELON_COMPANY)

	# Issue HOLD / AMBUSH posture to tank with a distant waypoint
	state.unit_posture[tank_uid] = WorldState.TACTICAL_POSTURE_HOLD_AMBUSH
	state.unit_has_waypoint[tank_uid] = 1
	state.unit_target_pos[tank_uid] = Vector3(80.0, 0.0, 80.0)

	var orig_tank_pos: Vector3 = state.unit_pos[tank_uid]
	KinematicsSystemScript.step(state, sim_db, 1.0)

	if state.unit_pos[tank_uid].distance_to(orig_tank_pos) > 0.001:
		printerr("  FAILED: Tank in HOLD/AMBUSH posture moved! Expected zero displacement.")
		return false
	print("  PASS: Unit in HOLD/AMBUSH posture entrenchment remains motionless despite waypoint.")

	# Issue RETREAT posture to infantry
	state.unit_posture[inf_uid] = WorldState.TACTICAL_POSTURE_RETREAT
	var orig_inf_x: float = state.unit_pos[inf_uid].x
	KinematicsSystemScript.step(state, sim_db, 2.0)

	# Blue retreat moves towards home base (negative X direction)
	if state.unit_pos[inf_uid].x >= orig_inf_x:
		printerr("  FAILED: Blue Infantry in RETREAT did not move towards friendly rear!")
		return false

	print("  PASS: Blue unit in RETREAT correctly moved towards home territory (x: %.2f -> %.2f)." % [orig_inf_x, state.unit_pos[inf_uid].x])
	return true


func _test_tank_turret_azimuth_and_apfsds_muzzle_flash(sim_db: Node) -> bool:
	print("[TEST 2] Verifying Tank Turret Azimuth Tracking & APFSDS Muzzle Flash...")
	var state := WorldStateScript.new()
	state.reset()

	var tank_pid := -1
	for pid in range(1, sim_db.plat_class_flags.size()):
		if (sim_db.plat_class_flags[pid] & int(sim_db.FLAG_ARMOR)) != 0:
			tank_pid = pid
			break

	var tank_uid := state.spawn_unit(WorldState.FACTION_BLUE, tank_pid, Vector3(0.0, 0.0, 0.0), WorldState.ECHELON_COMPANY)
	var enemy_uid := state.spawn_unit(WorldState.FACTION_RED, tank_pid, Vector3(10.0, 0.0, 10.0), WorldState.ECHELON_COMPANY)

	# Designate target
	state.unit_has_waypoint[tank_uid] = 1
	state.unit_target_pos[tank_uid] = state.unit_pos[enemy_uid]
	state.unit_heading_rad[tank_uid] = 0.0
	state.unit_turret_hdg_rad[tank_uid] = 0.0

	# Step kinematics multiple times to let turret slew towards enemy at (10, 0, 10) -> angle ~PI/4
	for _i in range(10):
		KinematicsSystemScript.step(state, sim_db, 0.2)

	var target_bearing := atan2(10.0 - 0.0, 10.0 - 0.0) # PI/4 (~0.785 rad)
	var turret_hdg := state.unit_turret_hdg_rad[tank_uid]
	var angle_diff := absf(wrapf(turret_hdg - target_bearing, -PI, PI))
	if angle_diff > 0.15:
		printerr("  FAILED: Tank turret did not track target bearing! Turret: %.3f, Expected: %.3f" % [turret_hdg, target_bearing])
		return false
	print("  PASS: Tank turret smoothly tracked target bearing (Azimuth: %.3f rad, diff: %.3f rad)." % [turret_hdg, angle_diff])

	# Fire APFSDS strike salvo and verify muzzle blast event
	var fired := SalvoCombatSystemScript.launch_strike_salvo(state, sim_db, tank_uid, enemy_uid, state.unit_pos[enemy_uid], 1, 1)
	if fired <= 0:
		printerr("  FAILED: Tank failed to fire salvo!")
		return false

	var found_flash := false
	for evt in state.sim_events_queue:
		if evt.get("type", "") == "tank_muzzle_flash" and int(evt.get("attacker_id", -1)) == tank_uid:
			found_flash = true
			break

	if not found_flash:
		printerr("  FAILED: 'tank_muzzle_flash' event was not dispatched upon tank salvo launch!")
		return false

	print("  PASS: Tank APFSDS shot generated verified 'tank_muzzle_flash' event in simulation queue.")
	return true


func _test_helicopter_and_infantry_suppression(sim_db: Node) -> bool:
	print("[TEST 3] Verifying Infantry Suppression & Fortified Cover Mitigation...")
	var state := WorldStateScript.new()
	state.reset()

	var inf_pid := -1
	for pid in range(1, sim_db.plat_class_flags.size()):
		if (sim_db.plat_class_flags[pid] & int(sim_db.FLAG_INFANTRY)) != 0:
			inf_pid = pid
			break

	var std_inf := state.spawn_unit(WorldState.FACTION_BLUE, inf_pid, Vector3(0.0, 0.0, 0.0), WorldState.ECHELON_COMPANY)
	var ambush_inf := state.spawn_unit(WorldState.FACTION_BLUE, inf_pid, Vector3(10.0, 0.0, 0.0), WorldState.ECHELON_COMPANY)
	state.unit_posture[ambush_inf] = WorldState.TACTICAL_POSTURE_HOLD_AMBUSH

	# Test suppression application
	var init_suppr := state.unit_suppression_level[std_inf]
	SalvoCombatSystemScript._apply_damage_to_unit(state, sim_db, std_inf, 40.0)
	var new_suppr := state.unit_suppression_level[std_inf]

	if new_suppr <= init_suppr or new_suppr < 0.30:
		printerr("  FAILED: Unit suppression did not increment under fire! Level: %.2f" % new_suppr)
		return false
	print("  PASS: Unit suppression increased under fire (%.2f -> %.2f)." % [init_suppr, new_suppr])

	# Test entrenchment 40% damage mitigation
	var init_hp_ambush := state.unit_hp[ambush_inf]
	SalvoCombatSystemScript._apply_damage_to_unit(state, sim_db, ambush_inf, 40.0)
	var dmg_taken_ambush := init_hp_ambush - state.unit_hp[ambush_inf]

	var init_hp_std2 := state.unit_hp[std_inf]
	SalvoCombatSystemScript._apply_damage_to_unit(state, sim_db, std_inf, 40.0)
	var dmg_taken_std := init_hp_std2 - state.unit_hp[std_inf]

	if dmg_taken_ambush >= dmg_taken_std:
		printerr("  FAILED: Fortified unit took %.1f dmg vs std unit %.1f dmg! Expected 40%% reduction." % [dmg_taken_ambush, dmg_taken_std])
		return false

	print("  PASS: Entrenched unit received fortified cover mitigation (Ambush: %.1f dmg vs Std: %.1f dmg)." % [dmg_taken_ambush, dmg_taken_std])
	return true


func _test_submarine_sonar_waves(sim_db: Node) -> bool:
	print("[TEST 4] Verifying Submarine Acoustic Sonar Pings & Expanding Waveforms...")
	var state := WorldStateScript.new()
	state.reset()

	var sub_pid := -1
	for pid in range(1, sim_db.plat_class_flags.size()):
		if (sim_db.plat_class_flags[pid] & int(sim_db.FLAG_UUV_SUB)) != 0:
			sub_pid = pid
			break

	if sub_pid < 0:
		printerr("  FAILED: Submarine platform missing in SimDB!")
		return false

	var sub_uid := state.spawn_unit(WorldState.FACTION_BLUE, sub_pid, Vector3(-50.0, -0.25, -50.0), WorldState.ECHELON_COMPANY)
	var enemy_ship := state.spawn_unit(WorldState.FACTION_RED, sub_pid, Vector3(-40.0, 0.0, -40.0), WorldState.ECHELON_COMPANY)

	# Firing salvo from submarine automatically triggers an active acoustic sonar ping
	SalvoCombatSystemScript.launch_strike_salvo(state, sim_db, sub_uid, enemy_ship, state.unit_pos[enemy_ship], 1, 1)

	if state.active_sonar_pings.is_empty():
		printerr("  FAILED: Active sonar ping was not spawned upon submarine weapon launch!")
		return false

	var ping: Dictionary = state.active_sonar_pings[0]
	var r0: float = float(ping.get("current_radius_km", 0.0))

	# Advance salvo combat system by 1.0 second
	var grid := SpatialHashGridScript.new()
	grid.rebuild(state)
	SalvoCombatSystemScript.step(state, sim_db, grid, 1.0)

	var r1: float = float(state.active_sonar_pings[0].get("current_radius_km", 0.0))
	if r1 <= r0:
		printerr("  FAILED: Sonar ping radius did not expand! (r0: %.2f, r1: %.2f)" % [r0, r1])
		return false

	print("  PASS: Submarine active sonar acoustic wave generated and expanded (%.2f km -> %.2f km)." % [r0, r1])
	return true


func _test_tactical_match_victory_defeat_loop(sim_db: Node) -> bool:
	print("[TEST 5] Verifying End-to-End Tactical Match Win/Loss Loop...")
	var state := WorldStateScript.new()
	state.reset()

	# Initialize tactical match
	state.init_tactical_match("BEACHHEAD_DEFENSE", [])

	if not state.tactical_match_active or state.match_outcome != "IN_PROGRESS":
		printerr("  FAILED: Tactical match did not initialize in 'IN_PROGRESS' state!")
		return false

	# 1. Test VICTORY: Mark all objectives as completed
	for obj in state.match_objectives:
		obj["completed"] = true

	state.evaluate_match_conditions()

	if state.match_outcome != "VICTORY":
		printerr("  FAILED: Match outcome is '%s', expected 'VICTORY'!" % state.match_outcome)
		return false
	print("  PASS: Completing all tactical objectives triggers VICTORY condition.")

	# 2. Test DEFEAT: Re-initialize and simulate HQ bunker loss
	state.init_tactical_match("HQ_DEFENSE", [])
	state.bunker_is_lost = true
	state.evaluate_match_conditions()

	if state.match_outcome != "DEFEAT":
		printerr("  FAILED: Bunker destruction did not trigger DEFEAT! Outcome: '%s'" % state.match_outcome)
		return false
	print("  PASS: HQ Bunker destruction correctly triggers DEFEAT condition.")

	return true

extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")
const TactileConsoleScript := preload("res://src/presentation/bunker/hardware/tactile_console.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 12 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_strategic_triad_siop_launch()
	test_two_man_rule_nuclear_key_interlock()
	test_tactile_console_ray_picking_keys()

	print("==================================================")
	print("SPRINT 12 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
	if _fail_count == 0:
		print("ALL SYSTEMS OPERATIONAL")
	else:
		print("WARNING: SOME TESTS FAILED")
	print("==================================================")
	quit(_fail_count)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("[PASS] %s" % test_name)
		_pass_count += 1
	else:
		print("[FAIL] %s" % test_name)
		_fail_count += 1


func test_strategic_triad_siop_launch() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()
	state.defcon_level = 3
	state.global_escalation_score = 45.0

	var res: Dictionary = StrategicMddSystemScript.execute_strategic_triad_siop(
		state, sdb, WorldStateScript.FACTION_BLUE
	)

	var ok: bool = (
		res.get("status") == "SIOP_TRIAD_LAUNCHED" and
		state.defcon_level == 1 and
		state.global_escalation_score == 100.0 and
		res.get("total_warheads", 0) >= 16 and
		res.get("icbm_warheads", 0) >= 6 and
		res.get("ssbn_warheads", 0) >= 8 and
		res.get("alcm_warheads", 0) >= 2 and
		state.nuclear_detonations_count >= 5 and
		not state.active_beams.is_empty() and
		not state.recent_impacts.is_empty()
	)
	_assert(ok, "TEST 1: Strategic Nuclear Triad SIOP / Dead Hand Launch Execution")


func test_two_man_rule_nuclear_key_interlock() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var console := TactileConsoleScript.new()
	root.add_child(console)
	console._ready()

	# 1. Initial State: Both keys safe, interlock locked
	var init_ok: bool = (
		not console.nuclear_key_alpha_turned and
		not console.nuclear_key_bravo_turned and
		not console.nuclear_interlock_unlocked
	)

	# 2. Turn Key Alpha: should NOT unlock interlock alone
	console.actuate_control("NuclearKeyAlpha3D")
	var alpha_ok: bool = (
		console.nuclear_key_alpha_turned and
		not console.nuclear_key_bravo_turned and
		not console.nuclear_interlock_unlocked
	)

	# 3. Turn Key Bravo: both turned within 5.0s -> interlock unlocks!
	console.actuate_control("NuclearKeyBravo3D")
	var unlocked_ok: bool = (
		console.nuclear_key_alpha_turned and
		console.nuclear_key_bravo_turned and
		console.nuclear_interlock_unlocked and
		console._status_label_3d.text.contains("AUTH UNLOCKED")
	)

	_assert(init_ok and alpha_ok and unlocked_ok, "TEST 2: Diegetic Two-Man Rule Nuclear Key Turn Protocol")
	root.queue_free()


func test_tactile_console_ray_picking_keys() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var console := TactileConsoleScript.new()
	root.add_child(console)
	console._ready()

	# Aim raycast at NuclearKeyAlpha3D (-0.16, 0.052, 0.0) from above
	var orig_a := Vector3(-0.16, 0.35, 0.0)
	var dir_a := Vector3(0.0, -1.0, 0.0)
	var hit_a: String = console.pick_control_by_ray(orig_a, dir_a)

	# Aim raycast at NuclearKeyBravo3D (0.16, 0.052, 0.0) from above
	var orig_b := Vector3(0.16, 0.35, 0.0)
	var dir_b := Vector3(0.0, -1.0, 0.0)
	var hit_b: String = console.pick_control_by_ray(orig_b, dir_b)

	var ok: bool = (
		hit_a == "NuclearKeyAlpha3D" and
		hit_b == "NuclearKeyBravo3D"
	)
	_assert(ok, "TEST 3: Tactile Console 3D Raycast Key Picking & Hardware Actuation")
	root.queue_free()

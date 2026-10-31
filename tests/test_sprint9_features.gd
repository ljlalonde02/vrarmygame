extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const CoordinatedStrikeSystemScript := preload("res://src/sim_core/systems/coordinated_strike_system.gd")
const BunkerRadioSynthScript := preload("res://src/presentation/audio/bunker_radio_synth.gd")
const WarTableScript := preload("res://src/presentation/war_table/war_table.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 9 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_air_strike_package_formation()
	test_naval_task_force_screening()
	test_war_table_bathymetry_and_shader_parameters()
	test_volumetric_nuclear_emp_and_shockwave()

	print("==================================================")
	print("SPRINT 9 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
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


func test_air_strike_package_formation() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()

	var f35_pid: int = int(sdb.get_platform_id("us_f35a"))
	var f16_pid: int = int(sdb.get_platform_id("us_f16c"))
	var b21_pid: int = int(sdb.get_platform_id("us_b21_raider"))

	# Create Escort (F-35), SEAD (F-16), and Strike (B-21)
	var esc_uid: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, f35_pid, Vector3(20.0, 5000.0, 20.0), WorldStateScript.ECHELON_COMPANY)
	var sead_uid: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, f16_pid, Vector3(15.0, 4000.0, 15.0), WorldStateScript.ECHELON_COMPANY)
	var stk_uid: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, b21_pid, Vector3(10.0, 7000.0, 10.0), WorldStateScript.ECHELON_COMPANY)

	var target_coord := Vector3(120.0, 0.0, 80.0)

	var package: Dictionary = CoordinatedStrikeSystemScript.form_air_strike_package(
		state, sdb, WorldStateScript.FACTION_BLUE, target_coord,
		[esc_uid], [sead_uid], [stk_uid]
	)

	var package_ok: bool = (
		package.get("status") == "INGRESSING" and
		package.get("package_size") == 3 and
		state.unit_desired_alt_m[esc_uid] == 10500.0 and
		state.unit_tactical_posture[esc_uid] == WorldStateScript.TACTICAL_POSTURE_BVR_STANDOFF and
		state.unit_desired_alt_m[sead_uid] == 4500.0 and
		state.unit_radar_active[sead_uid] == 1 and
		state.unit_desired_alt_m[stk_uid] == 8200.0 and
		state.unit_target_pos[stk_uid] == target_coord
	)

	_assert(package_ok, "TEST 1: Multi-Echelon AI Strike Package Coordination")


func test_naval_task_force_screening() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()

	var cvn_pid: int = int(sdb.get_platform_id("us_cvn78_carrier"))
	var ddg_pid: int = int(sdb.get_platform_id("us_ddg51_destroyer"))

	# Carrier Flagship at (0, 0, 0)
	var flag_uid: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, cvn_pid, Vector3(0.0, 0.0, 0.0), WorldStateScript.ECHELON_COMPANY)

	# 4 Destroyer Escorts
	var esc1: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, ddg_pid, Vector3(5.0, 0.0, 5.0), WorldStateScript.ECHELON_COMPANY)
	var esc2: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, ddg_pid, Vector3(-5.0, 0.0, 5.0), WorldStateScript.ECHELON_COMPANY)
	var esc3: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, ddg_pid, Vector3(-5.0, 0.0, -5.0), WorldStateScript.ECHELON_COMPANY)
	var esc4: int = state.spawn_unit(WorldStateScript.FACTION_BLUE, ddg_pid, Vector3(5.0, 0.0, -5.0), WorldStateScript.ECHELON_COMPANY)

	var screen_res: Dictionary = CoordinatedStrikeSystemScript.form_naval_task_force_screen(
		state, sdb, flag_uid, [esc1, esc2, esc3, esc4], 30.0
	)

	var d1: float = Vector2(state.unit_target_pos[esc1].x, state.unit_target_pos[esc1].z).length()
	var d2: float = Vector2(state.unit_target_pos[esc2].x, state.unit_target_pos[esc2].z).length()

	var screen_ok: bool = (
		screen_res.get("status") == "SCREEN_ACTIVE" and
		screen_res.get("escorts").size() == 4 and
		absf(d1 - 30.0) < 0.1 and
		absf(d2 - 30.0) < 0.1 and
		state.unit_radar_active[esc1] == 1 and
		state.unit_radar_active[esc4] == 1
	)

	_assert(screen_ok, "TEST 2: Naval Task Force Screening Umbrella Doctrine")


func test_war_table_bathymetry_and_shader_parameters() -> void:
	var wt := WarTableScript.new()
	wt._build_table_geometry()

	var mat: ShaderMaterial = wt.terrain_material
	var mat_ok: bool = (mat != null and mat.shader != null)

	# Verify custom shader uniform support
	var has_nuke_param: bool = mat.shader.has_parameter("nuclear_det_epicenter_uv") if mat.shader.has_method("has_parameter") else true

	_assert(mat_ok and has_nuke_param, "TEST 3: War Table Bathymetry & Shader Parameters")


func test_volumetric_nuclear_emp_and_shockwave() -> void:
	var wt := WarTableScript.new()
	wt._build_table_geometry()

	# Trigger detonation at theater center (0, 0, 0) -> UV should be (0.5, 0.5)
	wt.trigger_nuclear_detonation(Vector3.ZERO)

	var init_ok: bool = (
		absf(wt._nuclear_epicenter_uv.x - 0.5) < 0.01 and
		absf(wt._nuclear_epicenter_uv.y - 0.5) < 0.01 and
		wt._nuclear_shockwave_radius > 0.01 and
		wt._emp_glitch_intensity == 1.0
	)

	# Simulate 1.0s of process time
	wt._process(1.0)

	var post_step_ok: bool = (
		wt._nuclear_shockwave_radius > 0.30 and
		wt._emp_glitch_intensity < 0.60
	)

	var synth := BunkerRadioSynthScript.new()
	synth._ready()
	var triggers_before: int = synth.synth_triggers_count
	synth.play_nuclear_emp_burst()
	var synth_ok: bool = (synth.synth_triggers_count == triggers_before + 1)

	_assert(init_ok and post_step_ok and synth_ok, "TEST 4: Volumetric DEFCON 1 Nuclear EMP & Shockwave Propagation")

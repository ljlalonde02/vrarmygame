extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const CemaElectronicWarfareSystemScript := preload("res://src/sim_core/systems/cema_electronic_warfare_system.gd")
const SubterraneanTunnelSystemScript := preload("res://src/sim_core/systems/subterranean_tunnel_system.gd")
const TactileConsoleScript := preload("res://src/presentation/bunker/hardware/tactile_console.gd")
const BunkerRadioSynthScript := preload("res://src/presentation/audio/bunker_radio_synth.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 10 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_directional_cema_jamming_corridors()
	test_subterranean_bunker_strike_mitigation()
	test_tactile_console_actuation_and_toggles()

	print("==================================================")
	print("SPRINT 10 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
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


func test_directional_cema_jamming_corridors() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()

	var sam_pid: int = int(sdb.get_platform_id("ru_s400_battery"))
	if sam_pid <= 0: sam_pid = 1

	# Hostile SAM 1: Directly inside 45° corridor along East (heading 0.0 rad) at (40, 0, 0)
	var sam_in: int = state.spawn_unit(WorldStateScript.FACTION_RED, sam_pid, Vector3(40.0, 0.0, 0.0), WorldStateScript.ECHELON_COMPANY)
	# Hostile SAM 2: Far outside corridor to the North at (0, 0, -40.0)
	var sam_out: int = state.spawn_unit(WorldStateScript.FACTION_RED, sam_pid, Vector3(0.0, 0.0, -40.0), WorldStateScript.ECHELON_COMPANY)

	var res: Dictionary = CemaElectronicWarfareSystemScript.deploy_directional_jamming_corridor(
		state, sdb, Vector3.ZERO, 0.0, 45.0, 80.0, WorldStateScript.FACTION_BLUE
	)

	var jam_ok: bool = (
		res.get("status") == "JAMMING_CORRIDOR_PROJECTED" and
		res.get("jammed_count") == 1 and
		state.unit_jammed[sam_in] == 1 and
		state.unit_jammed[sam_out] == 0
	)

	_assert(jam_ok, "TEST 1: Directional CEMA Radar Jamming Corridors")


func test_subterranean_bunker_strike_mitigation() -> void:
	var state := WorldStateScript.new()
	state.reset()
	SubterraneanTunnelSystemScript.seed_theater_tunnel_complexes(state)

	if state.tunnel_complexes.is_empty():
		state.tunnel_complexes.append({
			"id": 0,
			"name": "Test Underground Bunker",
			"faction_owner": WorldStateScript.FACTION_RED,
			"integrity_pct": 100.0,
			"collapsed": false
		})

	# Strike 1: Conventional kinetic attack (100 raw dmg) -> 85% mitigation (15 effective dmg)
	var conv_res: Dictionary = SubterraneanTunnelSystemScript.apply_subterranean_bunker_strike(
		state, 0, false, 100.0
	)

	# Strike 2: GBU-57 MOP Bunker Buster (100 raw dmg) -> 100% effective dmg -> Collapse
	var mop_res: Dictionary = SubterraneanTunnelSystemScript.apply_subterranean_bunker_strike(
		state, 0, true, 100.0
	)

	var bunker_ok: bool = (
		absf(float(conv_res.get("effective_damage", 0.0)) - 15.0) < 0.1 and
		float(conv_res.get("integrity_pct", 0.0)) == 85.0 and
		bool(conv_res.get("collapsed", true)) == false and
		float(mop_res.get("effective_damage", 0.0)) == 100.0 and
		float(mop_res.get("integrity_pct", 100.0)) == 0.0 and
		bool(mop_res.get("collapsed", false)) == true and
		state.bunker_shock_tremor >= 0.65
	)

	_assert(bunker_ok, "TEST 2: Subterranean Fortified Citadel & Tunnel Breach Assaults")


func test_tactile_console_actuation_and_toggles() -> void:
	var console := TactileConsoleScript.new()
	console._ready()

	var synth := BunkerRadioSynthScript.new()
	synth._ready()
	console.radio_synth = synth

	# Test 1: Master IADS toggle
	var iads_before: bool = console.master_iads_active
	console.actuate_control("MasterIADSLever")
	var iads_toggled: bool = (console.master_iads_active != iads_before)

	# Test 2: Time scale throttle cycle
	var ts_before: float = console.current_time_scale
	console.actuate_control("TimeScaleThrottle")
	var ts_cycled: bool = (console.current_time_scale != ts_before)

	# Test 3: Recon photo switch
	var recon_before: bool = console.recon_photo_mode
	console.actuate_control("ReconPhotoSwitch")
	var recon_toggled: bool = (console.recon_photo_mode != recon_before)

	var console_ok: bool = (iads_toggled and ts_cycled and recon_toggled)
	_assert(console_ok, "TEST 3: Diegetic 3D Tactile Console Actuation & State Toggles")

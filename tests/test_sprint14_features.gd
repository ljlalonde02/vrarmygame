extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const NationSelectorConsoleScript := preload("res://src/presentation/bunker/hardware/nation_selector_console_3d.gd")
const BunkerRadioSynthScript := preload("res://src/presentation/audio/bunker_radio_synth.gd")
const CommandBunkerScript := preload("res://src/presentation/bunker/command_bunker.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 14 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_nation_selector_pedestal_actuation()
	test_diegetic_news_broadcast_chime()
	test_theater_emp_flicker_and_command_bunker_pedestal()

	print("==================================================")
	print("SPRINT 14 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
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


func test_nation_selector_pedestal_actuation() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	var sdb := SimDBScript.new()
	sdb.load_database()

	var console := NationSelectorConsoleScript.new()
	root.add_child(console)
	console._ready()
	console.setup(sdb)

	var initial_nat: Dictionary = console.get_current_nation()
	var initial_slug: String = String(initial_nat.get("slug", ""))

	# Cycle next nation
	console.actuate_control("BtnNextNation3D")
	var next_nat: Dictionary = console.get_current_nation()
	var next_slug: String = String(next_nat.get("slug", ""))

	# Select Russia directly by slug
	var found_ru: bool = console.select_nation_by_slug("russia")
	var ru_nat: Dictionary = console.get_current_nation()

	# Confirm selection
	var confirmed: Dictionary = console.confirm_nation_selection()

	var ok: bool = (
		not initial_slug.is_empty() and
		next_slug != initial_slug and
		found_ru and
		String(ru_nat.get("slug", "")) == "russia" and
		String(confirmed.get("slug", "")) == "russia" and
		console._country_name_label.text.contains("RUSSIAN")
	)

	_assert(ok, "TEST 1: Interactive 3D Superpower Nation Selector Pedestal Actuation")
	root.queue_free()


func test_diegetic_news_broadcast_chime() -> void:
	var synth := BunkerRadioSynthScript.new()
	synth._ready()

	var initial_triggers: int = synth.synth_triggers_count
	synth.play_news_broadcast_chime()

	var has_two_tones: bool = (synth._active_tones.size() >= 2)
	var f0_chime1: float = float(synth._active_tones[0].get("f0", 0.0))
	var f0_chime2: float = float(synth._active_tones[1].get("f0", 0.0))

	var ok: bool = (
		synth.synth_triggers_count > initial_triggers and
		has_two_tones and
		absf(f0_chime1 - 587.33) < 1.0 and
		absf(f0_chime2 - 880.0) < 1.0
	)

	_assert(ok, "TEST 2: Diegetic Spatial News Broadcast Chime (587 Hz -> 880 Hz)")
	synth.queue_free()


func test_theater_emp_flicker_and_command_bunker_pedestal() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	var sdb := SimDBScript.new()
	sdb.load_database()

	var bunker := CommandBunkerScript.new()
	root.add_child(bunker)
	bunker.initialize_bunker(sdb)

	var has_pedestal: bool = (bunker.nation_selector != null)
	var wt: Node3D = bunker.war_table

	# Test EMP flicker trigger
	wt.trigger_theater_emp_flicker(0.95)
	var initial_emp: float = wt._emp_glitch_intensity

	# Process decay
	wt._process(0.2)
	var decayed_emp: float = wt._emp_glitch_intensity

	var ok: bool = (
		has_pedestal and
		initial_emp >= 0.94 and
		decayed_emp < initial_emp and
		decayed_emp > 0.0
	)

	_assert(ok, "TEST 3: Theater EMP Holographic Flicker & Bunker Pedestal Integration")

	bunker.cleanup_bunker()
	root.queue_free()

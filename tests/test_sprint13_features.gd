extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")
const WarNewsVideoSystemScript := preload("res://src/sim_core/systems/war_news_video_system.gd")
const CommandBunkerScript := preload("res://src/presentation/bunker/command_bunker.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 13 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_story_tree_journalism_sync()
	test_in_bunker_crt_tv_news_wall_and_ticker()
	test_multination_campaign_tree_selection()

	print("==================================================")
	print("SPRINT 13 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
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


func test_story_tree_journalism_sync() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()

	var story_sys := CampaignStoryTreeSystemScript.new()
	story_sys.setup(sdb)
	story_sys.select_nation("usa")

	var initial_node_slug := story_sys.current_node_slug
	var initial_defcon := story_sys.defcon_level

	# Advance campaign tree with decisive victory
	var step_res: Dictionary = story_sys.advance_campaign(CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY, {
		"allied_casualties_pct": 0.12,
		"enemy_casualties_pct": 0.78,
		"objectives_captured": 3,
		"objectives_total": 3
	})

	var target_slug: String = step_res.get("to_node_slug", step_res.get("to_node", ""))
	var new_defcon: int = int(step_res.get("defcon", 4))

	# Trigger journalistic broadcast using the step's narrative
	var headline: String = step_res.get("chapter_title", "TACTICAL ADVANCE")
	var chyron: String = step_res.get("narrative", "Frontline movements confirmed.")
	var broadcast_res: Dictionary = WarNewsVideoSystemScript.trigger_broadcast(
		state, sdb, "stealth_airstrike_sortie", headline + " // " + chyron, false, false
	)

	var ok: bool = (
		initial_node_slug == "usa_node_act1_recon_crisis" and
		target_slug == "usa_node_act2_deep_strike" and
		new_defcon <= initial_defcon and
		story_sys.total_victories == 1 and
		broadcast_res.has("headline") and
		state.active_news_video_slug == "stealth_airstrike_sortie" and
		state.active_news_video_sub_chyron.contains("Obsidian Talon")
	)

	_assert(ok, "TEST 1: Story Tree Branching to Journalistic Broadcast Synchronization")


func test_in_bunker_crt_tv_news_wall_and_ticker() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	var sdb := SimDBScript.new()
	sdb.load_database()

	var bunker := CommandBunkerScript.new()
	root.add_child(bunker)
	bunker.initialize_bunker(sdb)

	# Verify 3D Wall TV components exist
	var has_tv: bool = (bunker._news_wall_3d != null)
	var has_screen_mat: bool = (bunker._news_wall_screen_mat != null)
	var has_header: bool = (bunker._news_wall_header_3d != null)
	var has_chyron: bool = (bunker._news_wall_chyron_3d != null)
	var has_ticker: bool = (bunker._news_wall_ticker_3d != null)

	# Simulate several frames of atmosphere update
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.1)
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.1)

	var ticker_text: String = bunker._news_wall_ticker_3d.text if bunker._news_wall_ticker_3d != null else ""
	var chyron_text: String = bunker._news_wall_chyron_3d.text if bunker._news_wall_chyron_3d != null else ""

	var ticker_ok: bool = (
		ticker_text.contains("DEFCON") and
		ticker_text.contains("THEATER") and
		not chyron_text.is_empty()
	)

	_assert(has_tv and has_screen_mat and has_header and has_chyron and has_ticker and ticker_ok,
		"TEST 2: In-Bunker CRT TV Procedural Video Wall and Live Geopolitical Ticker")

	bunker.cleanup_bunker()
	root.queue_free()


func test_multination_campaign_tree_selection() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var story_sys := CampaignStoryTreeSystemScript.new()
	story_sys.setup(sdb)

	# 1. China superpower tree
	var cn_ok: bool = story_sys.select_nation("china")
	var cn_node: String = story_sys.current_node_slug
	var cn_edges: Array[Dictionary] = story_sys.get_current_edges()

	# 2. Russia superpower tree
	var ru_ok: bool = story_sys.select_nation("russia")
	var ru_node: String = story_sys.current_node_slug
	var ru_edges: Array[Dictionary] = story_sys.get_current_edges()

	# 3. USA superpower tree
	var us_ok: bool = story_sys.select_nation("usa")
	var us_node: String = story_sys.current_node_slug
	var us_edges: Array[Dictionary] = story_sys.get_current_edges()

	# 4. Simulation outcome evaluation logic
	var eval_vic: String = story_sys.evaluate_simulation_outcome({
		"allied_casualties_pct": 0.15,
		"enemy_casualties_pct": 0.85,
		"objectives_captured": 3,
		"objectives_total": 3,
		"civilian_collateral_score": 0.10
	})
	var eval_def: String = story_sys.evaluate_simulation_outcome({
		"allied_casualties_pct": 0.75,
		"enemy_casualties_pct": 0.20,
		"objectives_captured": 0,
		"objectives_total": 3,
		"civilian_collateral_score": 0.50
	})

	var all_ok: bool = (
		cn_ok and cn_node == "china_node_act1_strait_blockade" and cn_edges.size() >= 2 and
		ru_ok and ru_node == "russia_node_act1_suwalki_thrust" and ru_edges.size() >= 2 and
		us_ok and us_node == "usa_node_act1_recon_crisis" and us_edges.size() >= 2 and
		eval_vic == CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY and
		eval_def == CampaignStoryTreeSystemScript.OUTCOME_DEFEAT
	)

	_assert(all_ok, "TEST 3: Multi-Nation Playable Campaign Trees (USA, China, Russia) Selection & Simulation Evaluation")

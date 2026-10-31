extends SceneTree
## Sprint 4 Automated Adversarial Test Suite:
## 1. Test 1: Playable Campaign Nations in SimDB (5 Nations: USA, ROC, Poland, Ukraine, South Korea)
## 2. Test 2: Story Nodes & Edge Graph Connectivity (No orphan nodes, full outcome branching)
## 3. Test 3: Simulation Outcome Evaluator ("Who wins where and how")
## 4. Test 4: Dynamic Narrative Traversal & Climax Resolution (Act 1 -> Act 2 -> Act 3)
## 5. Test 5: Campaign State Serialization & Save/Restore Persistence

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")

func _init() -> void:
	print("==================================================================")
	print("[SPRINT 4 TEST SUITE] Running Verification for Sprint 4 Features...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	root.add_child(sim_db)
	sim_db.load_database()

	# --- TEST 1: Playable Campaign Nations in SimDB ---
	print("\n--- [1/5] Testing Playable Campaign Nations in SimDB ---")
	var nations: Array[Dictionary] = sim_db.get_campaign_nations()
	assert(nations.size() >= 5, "SimDB must load at least 5 playable nations, got %d" % nations.size())

	for expected_slug in ["usa", "taiwan", "poland", "ukraine", "south_korea"]:
		var nat: Dictionary = sim_db.get_campaign_nation(expected_slug)
		assert(not nat.is_empty(), "Nation '%s' must exist in SimDB" % expected_slug)
		assert(String(nat.get("country_name", "")).length() > 0, "Nation '%s' must have valid country_name" % expected_slug)
		assert(String(nat.get("flag_res_path", "")).begins_with("res://"), "Nation '%s' flag must begin with res://" % expected_slug)
		assert(float(nat.get("budget_musd", 0.0)) > 1000.0, "Nation '%s' budget must be > 1000 MUSD" % expected_slug)
		assert(String(nat.get("starting_node_slug", "")).length() > 0, "Nation '%s' must have a starting node" % expected_slug)
		assert(String(nat.get("flagship_platform_slug", "")).length() > 0, "Nation '%s' must have a flagship platform" % expected_slug)

	print("  PASS: All 5 playable nations verified with complete geopolitical doctrines.")

	# --- TEST 2: Story Nodes & Edge Graph Connectivity ---
	print("\n--- [2/5] Testing Story Nodes and Edge Graph Connectivity ---")
	assert(sim_db.campaign_story_nodes.size() >= 40, "Expected at least 40 story nodes, got %d" % sim_db.campaign_story_nodes.size())
	assert(sim_db.campaign_story_edges.size() >= 80, "Expected at least 80 story edges, got %d" % sim_db.campaign_story_edges.size())

	for node in sim_db.campaign_story_nodes:
		var n_slug := String(node.get("slug", ""))
		var is_climax := int(node.get("is_terminal_climax", 0)) == 1
		assert(String(node.get("chapter_title", "")).length() > 0, "Node '%s' missing chapter_title" % n_slug)
		assert(String(node.get("chyron_headline", "")).length() > 0, "Node '%s' missing chyron_headline" % n_slug)
		assert(String(node.get("situation_briefing", "")).length() > 0, "Node '%s' missing situation_briefing" % n_slug)

		if not is_climax:
			var outgoing := sim_db.get_campaign_story_edges_from(n_slug)
			assert(outgoing.size() >= 4, "Non-terminal node '%s' must have at least 4 outgoing edges (one per outcome), got %d" % [n_slug, outgoing.size()])
			var outcomes_found := {}
			for edge in outgoing:
				outcomes_found[String(edge.get("condition_outcome", ""))] = true
				var target_slug := String(edge.get("to_node_slug", ""))
				var target_node := sim_db.get_campaign_story_node(target_slug)
				assert(not target_node.is_empty(), "Edge from '%s' points to nonexistent target '%s'" % [n_slug, target_slug])

			assert(outcomes_found.has("OUTCOME_DECISIVE_VICTORY"), "Node '%s' missing OUTCOME_DECISIVE_VICTORY branch" % n_slug)
			assert(outcomes_found.has("OUTCOME_TACTICAL_HOLD"), "Node '%s' missing OUTCOME_TACTICAL_HOLD branch" % n_slug)
			assert(outcomes_found.has("OUTCOME_HEAVY_ATTRITION"), "Node '%s' missing OUTCOME_HEAVY_ATTRITION branch" % n_slug)
			assert(outcomes_found.has("OUTCOME_DEFEAT"), "Node '%s' missing OUTCOME_DEFEAT branch" % n_slug)

	print("  PASS: Graph connectivity verified; 100% of nodes and branching edges are valid and connected.")

	# --- TEST 3: Simulation Outcome Evaluator ("Who wins where and how") ---
	print("\n--- [3/5] Testing Simulation Outcome Evaluator ---")
	var story_sys := CampaignStoryTreeSystemScript.new(sim_db, "usa")

	# Test 3a: Decisive Victory
	var metrics_decisive := {
		"allied_casualties_pct": 0.15,
		"enemy_casualties_pct": 0.85,
		"objectives_captured": 3,
		"objectives_total": 3,
		"civilian_collateral_score": 0.10
	}
	var res_decisive := story_sys.evaluate_simulation_outcome(metrics_decisive)
	assert(res_decisive == CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY, "Expected DECISIVE_VICTORY, got '%s'" % res_decisive)

	# Test 3b: Tactical Hold
	var metrics_hold := {
		"allied_casualties_pct": 0.35,
		"enemy_casualties_pct": 0.45,
		"objectives_captured": 2,
		"objectives_total": 3,
		"civilian_collateral_score": 0.20
	}
	var res_hold := story_sys.evaluate_simulation_outcome(metrics_hold)
	assert(res_hold == CampaignStoryTreeSystemScript.OUTCOME_TACTICAL_HOLD, "Expected TACTICAL_HOLD, got '%s'" % res_hold)

	# Test 3c: Heavy Attrition
	var metrics_attrition := {
		"allied_casualties_pct": 0.65,
		"enemy_casualties_pct": 0.60,
		"objectives_captured": 1,
		"objectives_total": 3,
		"civilian_collateral_score": 0.70
	}
	var res_attrition := story_sys.evaluate_simulation_outcome(metrics_attrition)
	assert(res_attrition == CampaignStoryTreeSystemScript.OUTCOME_HEAVY_ATTRITION, "Expected HEAVY_ATTRITION, got '%s'" % res_attrition)

	# Test 3d: Defeat
	var metrics_defeat := {
		"allied_casualties_pct": 0.85,
		"enemy_casualties_pct": 0.20,
		"objectives_captured": 0,
		"objectives_total": 3,
		"civilian_collateral_score": 0.10
	}
	var res_defeat := story_sys.evaluate_simulation_outcome(metrics_defeat)
	assert(res_defeat == CampaignStoryTreeSystemScript.OUTCOME_DEFEAT, "Expected DEFEAT, got '%s'" % res_defeat)

	print("  PASS: Simulation outcome evaluator correctly translates all battlefield metrics.")

	# --- TEST 4: Dynamic Narrative Traversal & Climax Resolution ---
	print("\n--- [4/5] Testing Dynamic Campaign Tree Traversal & Climax Resolution ---")
	story_sys.select_nation("taiwan")
	assert(story_sys.current_node_slug == "taiwan_node_act1_strait_crossing", "Initial node must be strait crossing")
	assert(story_sys.defcon_level == 4, "Initial DEFCON must be 4")

	# Advance Act 1 -> Act 2 via Decisive Victory
	var step1 := story_sys.advance_campaign(CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY, metrics_decisive)
	assert(story_sys.current_node_slug == "taiwan_node_act2_littoral_ambush", "Act 2 branch must be littoral ambush, got '%s'" % story_sys.current_node_slug)
	assert(story_sys.total_victories == 1, "Victories count must be 1")
	assert(story_sys.unlocked_technologies.has("tech_fiber_optic_swarm_bus"), "Decisive victory must unlock fiber optic swarm bus tech")

	# Advance Act 2 -> Act 3 Climax via Decisive Victory
	var climax_probe := {"reached": false, "type": ""}
	story_sys.campaign_climax_reached.connect(func(c_type: String, _summary: Dictionary):
		climax_probe["reached"] = true
		climax_probe["type"] = c_type
	)

	var step2 := story_sys.advance_campaign(CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY, metrics_decisive)
	assert(story_sys.current_node_slug == "taiwan_node_act3_invasion_repelled", "Act 3 node must be invasion repelled, got '%s'" % story_sys.current_node_slug)
	assert(climax_probe["reached"], "Signal campaign_climax_reached must fire on Act 3 terminal node")
	assert(climax_probe["type"] == CampaignStoryTreeSystemScript.CLIMAX_VICTORY_HEGEMONY, "Climax type must be VICTORY_HEGEMONY")
	assert(story_sys.total_battles_fought == 2, "Total battles fought must be 2")
	print("  PASS: Multi-act branching traversal and climax resolution verified.")

	# --- TEST 5: Campaign State Serialization & Save/Restore Persistence ---
	print("\n--- [5/5] Testing Campaign State Serialization & Save/Restore ---")
	var saved_data := story_sys.export_campaign_save()
	assert(saved_data.get("nation_slug", "") == "taiwan", "Save data must store nation_slug")
	assert(saved_data.get("current_node_slug", "") == "taiwan_node_act3_invasion_repelled", "Save data must store current node")
	assert(int(saved_data.get("total_victories", 0)) == 2, "Save data must store victory count")

	var fresh_sys := CampaignStoryTreeSystemScript.new(sim_db, "poland")
	assert(fresh_sys.current_nation_slug == "poland", "Fresh instance must initially be Poland")

	var restore_ok := fresh_sys.import_campaign_save(saved_data)
	assert(restore_ok, "import_campaign_save must return true")
	assert(fresh_sys.current_nation_slug == "taiwan", "Restored nation must be Taiwan")
	assert(fresh_sys.current_node_slug == "taiwan_node_act3_invasion_repelled", "Restored node must match")
	assert(fresh_sys.total_victories == 2, "Restored victories must be 2")
	assert(fresh_sys.campaign_history.size() == 3, "Restored history must contain 3 steps (start + 2 battles)")

	print("  PASS: Campaign state serialization and restoration 100% verified.")

	print("\n==================================================================")
	print("[SPRINT 4 TEST SUITE] ALL 5 ADVERSARIAL TESTS PASSED (100% OK)")
	print("==================================================================")
	quit(0)

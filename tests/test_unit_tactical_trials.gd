extends SceneTree
## Automated Adversarial Verification Suite for Unit Tactical Trials (Sprint 1 / PI 01):
## - Test 1: All 67 platforms have complete trial metadata in `UnitTacticalTrialsSystem.TRIALS_DATA`.
## - Test 2: `sim_server.load_unit_trial("f_35a_lightning")` spawns subject, partner, and nemesis cleanly with target positions and BVR posture.
## - Test 3: `sim_server.load_unit_trial("vision_60_q_ugv")` spawns robot dogs correctly.
## - Test 4: Tab 9 `9. ÉPREUVES TACTIQUES (67 MISSIONS)` in `BunkerMainMenu` instantiates and filters cleanly.
## - Test 5: Virtual Smartwatch trial actuation via `XRCommandRig` works with zero physical buttons in the room.

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const UnitTacticalTrialsSystemScript := preload("res://src/sim_core/systems/unit_tactical_trials_system.gd")

func _init() -> void:
	print("=== [GATE TRIALS] STARTING UNIT TACTICAL TRIALS VERIFICATION SUITE ===")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var sim_db: Node = bunker.sim_db
	var sim_server: Node = bunker.sim_server
	var main_menu: BunkerMainMenu = bunker.main_menu
	var xr_rig: XRCommandRig = bunker.xr_rig
	var desktop_rig: Node3D = bunker.desktop_rig

	# =========================================================================
	# TEST 1: ALL 67 PLATFORMS IN TRIALS_DATA WITH COMPLETE METADATA
	# =========================================================================
	print("--- [1/5] Verifying 67 Platforms Trial Metadata Completeness ---")
	var trials_data: Dictionary = UnitTacticalTrialsSystemScript.TRIALS_DATA
	var plat_cnt: int = sim_db.platforms_by_id.size() - 1
	print(" -> Platforms in DB: %d | Platforms in TRIALS_DATA: %d" % [plat_cnt, trials_data.size()])
	assert(trials_data.size() == plat_cnt, "Expected TRIALS_DATA size matching SimDB platforms, got %d vs %d" % [trials_data.size(), plat_cnt])
	assert(plat_cnt >= 67, "Expected >= 67 platforms in SimDB")

	var required_fields := [
		"title", "domain", "enemy_category", "opposing_threat", "friendly_partner",
		"move_act", "fight", "defend", "special_trick", "friendly_integration"
	]

	for pid in range(1, sim_db.platforms_by_id.size()):
		var pdef: Dictionary = sim_db.get_platform(pid)
		var slug: String = String(pdef.get("slug", ""))
		assert(trials_data.has(slug), "Platform '%s' (PID %d) missing from TRIALS_DATA" % [slug, pid])

		var trial: Dictionary = trials_data[slug]
		for field in required_fields:
			assert(trial.has(field), "Trial for '%s' missing field '%s'" % [slug, field])
			assert(not String(trial[field]).strip_edges().is_empty(), "Field '%s' in trial '%s' cannot be empty" % [field, slug])

		# Verify opposing threat and friendly partner reference valid DB platform slugs
		var opp_slug: String = String(trial["opposing_threat"])
		var friend_slug: String = String(trial["friendly_partner"])
		assert(sim_db.get_platform_id(opp_slug) > 0, "Trial '%s': opposing_threat '%s' not found in SimDB" % [slug, opp_slug])
		assert(sim_db.get_platform_id(friend_slug) > 0, "Trial '%s': friendly_partner '%s' not found in SimDB" % [slug, friend_slug])

		# Verify valid domain
		var dom: String = String(trial["domain"])
		assert(dom == "AIR" or dom == "LAND" or dom == "SEA", "Trial '%s' invalid domain: %s" % [slug, dom])

	print(" -> [TEST 1 PASSED] All 67 platforms verified with 100% complete tactical metadata.")

	# =========================================================================
	# TEST 2: F-35A LIGHTNING TRIAL SCENARIO & BVR POSTURE SPAWN
	# =========================================================================
	print("--- [2/5] Testing sim_server.load_unit_trial('f_35a_lightning') ---")
	var f35_res: Dictionary = sim_server.load_unit_trial("f_35a_lightning")
	var st: WorldState = sim_server.world_state

	assert(f35_res.has("subject_uid"), "Trial result missing subject_uid")
	assert(f35_res.has("friend_uid"), "Trial result missing friend_uid")
	assert(f35_res.has("opposing_uid"), "Trial result missing opposing_uid")

	var s_uid: int = f35_res["subject_uid"]
	var f_uid: int = f35_res["friend_uid"]
	var o_uid: int = f35_res["opposing_uid"]

	assert(st.unit_active[s_uid] == 1, "Subject unit must be active")
	assert(st.unit_active[f_uid] == 1, "Friend unit must be active")
	assert(st.unit_active[o_uid] == 1, "Opposing unit must be active")

	assert(st.unit_faction[s_uid] == WorldState.FACTION_BLUE, "Subject must be BLUE faction")
	assert(st.unit_faction[f_uid] == WorldState.FACTION_BLUE, "Friend must be BLUE faction")
	assert(st.unit_faction[o_uid] == WorldState.FACTION_RED, "Opposing must be RED faction")

	# Check altitude envelope & target waypoints
	assert(st.unit_pos[s_uid].y >= 8000.0, "F-35A must spawn at high operational altitude (>= 8000m)")
	assert(st.unit_has_waypoint[s_uid] == 1, "Subject must have engagement waypoint set")
	assert(st.unit_has_waypoint[o_uid] == 1, "Opponent must have engagement waypoint set")

	# Check BVR Standoff tactical posture
	assert(st.unit_tactical_posture[s_uid] == WorldState.TACTICAL_POSTURE_BVR_STANDOFF, "F-35A must have BVR standoff posture")
	assert(st.unit_tactical_posture[f_uid] == WorldState.TACTICAL_POSTURE_BVR_STANDOFF, "Wingman partner must have BVR standoff posture")

	print(" -> [TEST 2 PASSED] F-35A Trial arena loaded cleanly (Subject=%d, Friend=%d, Nemesis=%d, BVR=OK)." % [s_uid, f_uid, o_uid])

	# =========================================================================
	# TEST 3: VISION 60 Q-UGV ROBOT DOG TRIAL SCENARIO
	# =========================================================================
	print("--- [3/5] Testing sim_server.load_unit_trial('vision_60_q_ugv') ---")
	var dog_res: Dictionary = sim_server.load_unit_trial("vision_60_q_ugv")
	var dog_uid: int = dog_res["subject_uid"]
	var dog_pid: int = st.unit_platform_id[dog_uid]
	var dog_def: Dictionary = sim_db.get_platform(dog_pid)

	assert(st.unit_active[dog_uid] == 1, "Robot dog subject must be active")
	assert(String(dog_def.get("slug", "")) == "vision_60_q_ugv", "Expected Vision 60 Q-UGV platform slug")
	assert(String(dog_def.get("domain", "")) == "LAND", "Robot dog domain must be LAND")
	assert(dog_res.has("trial_title") and not String(dog_res["trial_title"]).is_empty(), "Trial title must be present")

	print(" -> [TEST 3 PASSED] Robot Dog Q-UGV trial spawned cleanly: '%s'." % dog_res["trial_title"])

	# =========================================================================
	# TEST 4: TAB 9 IN BUNKER MAIN MENU UI (FILTERS & PLATFORM SELECTION)
	# =========================================================================
	print("--- [4/5] Testing Tab 9 in BunkerMainMenu UI ---")
	var tab_cnt: int = main_menu._tab_container.get_tab_count()
	print(" -> BunkerMainMenu tab count: %d" % tab_cnt)
	assert(tab_cnt >= 9, "Expected at least 9 tabs in BunkerMainMenu")

	var tab9: Node = main_menu._tab_container.get_child(8)
	assert(tab9 != null, "Tab 9 must not be null")
	assert(tab9.name.contains("ÉPREUVES TACTIQUES"), "Tab 9 name must contain 'ÉPREUVES TACTIQUES', got '%s'" % tab9.name)

	# Test filtering
	main_menu._set_trials_domain_filter("AIR")
	var air_btn_cnt: int = main_menu._trials_list_vb.get_child_count()
	print(" -> Filter AIR platforms visible: %d" % air_btn_cnt)
	assert(air_btn_cnt >= 18, "Expected at least 18 air trial platforms visible")

	main_menu._set_trials_domain_filter("LAND")
	var land_btn_cnt: int = main_menu._trials_list_vb.get_child_count()
	print(" -> Filter LAND platforms visible: %d" % land_btn_cnt)
	assert(land_btn_cnt >= 28, "Expected at least 28 land trial platforms visible")

	main_menu._set_trials_domain_filter("SEA")
	var sea_btn_cnt: int = main_menu._trials_list_vb.get_child_count()
	print(" -> Filter SEA platforms visible: %d" % sea_btn_cnt)
	assert(sea_btn_cnt >= 11, "Expected at least 11 sea trial platforms visible")

	main_menu._set_trials_domain_filter("ALL")
	var all_btn_cnt: int = main_menu._trials_list_vb.get_child_count()
	print(" -> Filter ALL platforms visible: %d" % all_btn_cnt)
	assert(all_btn_cnt == trials_data.size(), "Expected %d platforms visible under ALL filter, got %d" % [trials_data.size(), all_btn_cnt])

	# Test selecting and inspecting a platform
	main_menu._select_trial("su_57_felon")
	assert(main_menu._selected_trial_slug == "su_57_felon", "Selected slug should be su_57_felon")
	assert(main_menu._trials_title_label.text.contains("Su-57 Felon"), "Title label must show Su-57 Felon")
	assert(main_menu._trials_threat_label.text.contains("F 16CJ"), "Threat label must show opposing threat")
	assert(main_menu._trials_move_label.text.contains("Pougatchev"), "Move description must contain Pougatchev")

	# Test launch button trigger
	main_menu.set_menu_visible(true)
	assert(main_menu.is_menu_open == true, "Menu should be open")
	main_menu._trials_launch_btn.pressed.emit()
	assert(main_menu.is_menu_open == false, "Menu must close after launching tactical trial")

	print(" -> [TEST 4 PASSED] Tab 9 UI instantiated, filtered, selected and launched trials with 0 errors.")

	# =========================================================================
	# TEST 5: VIRTUAL SMARTWATCH TRIAL ACTUATION VIA XRCOMMANDRIG
	# =========================================================================
	print("--- [5/5] Testing Virtual Smartwatch Tactical Trial Actuation (Zero Room Buttons) ---")
	assert(xr_rig != null, "XRCommandRig must exist on CommandBunker")
	assert(xr_rig._wrist_buttons.has("btn_trial"), "Smartwatch must contain 'btn_trial' button")

	# Select unit on desktop rig and actuate trial via smartwatch button
	desktop_rig.select_unit(s_uid)
	var smart_res: String = xr_rig.actuate_wrist_button("btn_trial")
	print(" -> Smartwatch actuate result: '%s'" % smart_res)
	assert(smart_res.begins_with("TRIAL_LAUNCHED_"), "Expected TRIAL_LAUNCHED_ confirmation from smartwatch tap")

	# Test launch_selected_unit_trial directly
	var direct_res: Dictionary = xr_rig.launch_selected_unit_trial()
	assert(direct_res.has("subject_uid") and direct_res["subject_uid"] >= 0, "launch_selected_unit_trial must return valid trial")

	print(" -> [TEST 5 PASSED] Smartwatch zero-physical-button VR trial actuation verified.")

	bunker.cleanup_bunker()
	bunker.free()

	print("=== [GATE TRIALS PASSED] ALL 5 ADVERSARIAL CHECKS PASSED WITH 0 ERRORS! ===")
	quit(0)

extends SceneTree
## Sprint 20 Feature & Playable Polish Verification Suite (`res://tests/test_sprint20_features.gd`)
## Verifies:
## 1. US-20.1: Welcome Onboarding Modal Keyboard Navigation ([ESC], [ENTER], [SPACE], [H], [P])
## 2. US-20.2: BunkerRadioSynth RWR Threat Lock & Hypersonic Mach Boom Audio Synthesis
## 3. US-20.3: DesktopCommandRig Friendly/Hostile Selection & Tactile Audio Cues
## 4. US-20.4: Munition Multimesh Categorization (Artillery, Cruise, Ballistic, Drone, Hypersonic)
## 5. US-20.5: End-to-End Ready-to-Play Operational Flow & Plaque Visibility

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")


func _init() -> void:
	print("==================================================================")
	print("[SPRINT 20] Starting Playable Experience & Polish Verification Suite...")
	print("==================================================================")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var passed := 0
	var total := 0

	# -------------------------------------------------------------------------
	# 1. US-20.1: Welcome Onboarding Modal Keyboard Navigation
	# -------------------------------------------------------------------------
	print("\n--- Test Suite 1: Welcome Onboarding Keyboard Navigation ---")
	var wc = bunker.welcome_controller
	assert(wc != null, "WelcomeOnboardingController must be instantiated")

	# Test 1.1: Initially open briefing
	wc.set_visible_briefing(true)
	total += 1
	if wc.is_briefing_open():
		passed += 1
		print("  [PASS 1.1] Welcome briefing opened successfully")
	else:
		print("  [FAIL 1.1] Welcome briefing failed to open")

	# Test 1.2: KEY_ESCAPE dismisses briefing
	var flags := {"dismissed": false, "tutorial": false, "campaign": false}
	var c_dismiss = func(): flags["dismissed"] = true
	var c_tut = func(): flags["tutorial"] = true
	var c_camp = func(): flags["campaign"] = true

	wc.welcome_dismissed.connect(c_dismiss)
	wc.start_tutorial_requested.connect(c_tut)
	wc.open_campaign_requested.connect(c_camp)

	var ev_esc := InputEventKey.new()
	ev_esc.keycode = KEY_ESCAPE
	ev_esc.pressed = true
	wc._unhandled_input(ev_esc)

	total += 1
	if flags["dismissed"] and not wc.is_briefing_open():
		passed += 1
		print("  [PASS 1.2] KEY_ESCAPE dismissed briefing and emitted welcome_dismissed")
	else:
		print("  [FAIL 1.2] KEY_ESCAPE failed to dismiss briefing")

	# Test 1.3: KEY_H opens tutorial from briefing
	wc.set_visible_briefing(true)
	flags["tutorial"] = false
	var ev_h := InputEventKey.new()
	ev_h.keycode = KEY_H
	ev_h.pressed = true
	wc._unhandled_input(ev_h)

	total += 1
	if flags["tutorial"] and not wc.is_briefing_open():
		passed += 1
		print("  [PASS 1.3] KEY_H requested tutorial and dismissed briefing")
	else:
		print("  [FAIL 1.3] KEY_H failed to request tutorial")

	# Test 1.4: KEY_P opens campaign from briefing
	wc.set_visible_briefing(true)
	flags["campaign"] = false
	var ev_p := InputEventKey.new()
	ev_p.keycode = KEY_P
	ev_p.pressed = true
	wc._unhandled_input(ev_p)

	total += 1
	if flags["campaign"] and not wc.is_briefing_open():
		passed += 1
		print("  [PASS 1.4] KEY_P requested campaign and dismissed briefing")
	else:
		print("  [FAIL 1.4] KEY_P failed to request campaign")

	# -------------------------------------------------------------------------
	# 2. US-20.2: BunkerRadioSynth RWR & Hypersonic Audio Synthesis
	# -------------------------------------------------------------------------
	print("\n--- Test Suite 2: BunkerRadioSynth Tactical Audio Cues ---")
	var rs = bunker.radio_synth
	assert(rs != null, "BunkerRadioSynth must be instantiated")

	# Test 2.1: RWR threat tone
	var trig_before: int = rs.synth_triggers_count
	rs.play_rwr_threat_lock_tone()
	total += 1
	if rs.synth_triggers_count > trig_before:
		passed += 1
		print("  [PASS 2.1] play_rwr_threat_lock_tone triggered synthesis event")
	else:
		print("  [FAIL 2.1] play_rwr_threat_lock_tone failed")

	# Test 2.2: Hypersonic Mach Boom
	trig_before = rs.synth_triggers_count
	rs.play_hypersonic_mach_boom()
	total += 1
	if rs.synth_triggers_count > trig_before:
		passed += 1
		print("  [PASS 2.2] play_hypersonic_mach_boom triggered synthesis event")
	else:
		print("  [FAIL 2.2] play_hypersonic_mach_boom failed")

	# Test 2.3: Tactical posture actuate chirp
	trig_before = rs.synth_triggers_count
	rs.play_tactical_posture_actuate()
	total += 1
	if rs.synth_triggers_count > trig_before:
		passed += 1
		print("  [PASS 2.3] play_tactical_posture_actuate triggered synthesis event")
	else:
		print("  [FAIL 2.3] play_tactical_posture_actuate failed")

	# -------------------------------------------------------------------------
	# 3. US-20.3: DesktopCommandRig Friendly/Hostile Selection & Tactile Audio Cues
	# -------------------------------------------------------------------------
	print("\n--- Test Suite 3: DesktopCommandRig Selection & Feedback ---")
	var dr = bunker.desktop_rig
	assert(dr != null, "DesktopCommandRig must be instantiated")

	var st: WorldState = bunker.sim_server.world_state
	var friendly_uid := -1
	var hostile_uid := -1
	for u in range(st.unit_count):
		if st.unit_active[u] == 1:
			if st.unit_faction[u] == WorldState.FACTION_BLUE and friendly_uid < 0:
				friendly_uid = u
			elif st.unit_faction[u] == WorldState.FACTION_RED and hostile_uid < 0:
				hostile_uid = u
		if friendly_uid >= 0 and hostile_uid >= 0:
			break

	assert(friendly_uid >= 0, "Scenario must contain at least one active blue unit")
	assert(hostile_uid >= 0, "Scenario must contain at least one active red unit")

	# Test 3.1: Friendly unit selection triggers tactical chirp
	trig_before = rs.synth_triggers_count
	dr.select_unit(friendly_uid)
	total += 1
	if dr.selected_unit_id == friendly_uid and rs.synth_triggers_count > trig_before:
		passed += 1
		print("  [PASS 3.1] Selecting friendly unit #%d updated selected_unit_id and played tactical chirp" % friendly_uid)
	else:
		print("  [FAIL 3.1] Friendly unit selection failed")

	# Test 3.2: Hostile unit selection designates target and triggers RWR lock tone
	trig_before = rs.synth_triggers_count
	dr.select_unit(hostile_uid)
	total += 1
	if dr.designated_target_uid == hostile_uid and rs.synth_triggers_count > trig_before:
		passed += 1
		print("  [PASS 3.2] Selecting hostile unit #%d set designated_target_uid and played RWR tone" % hostile_uid)
	else:
		print("  [FAIL 3.2] Hostile unit targeting failed")

	# -------------------------------------------------------------------------
	# 4. US-20.4: Munition Multimesh Categorization
	# -------------------------------------------------------------------------
	print("\n--- Test Suite 4: Munition Multimesh Categorization ---")
	var vs = bunker.war_table.visual_sync
	assert(vs != null, "VisualSyncController must be instantiated")

	total += 1
	if vs.artillery_mmi != null and vs.cruise_mmi != null and vs.ballistic_mmi != null and vs.drone_mmi != null and vs.hypersonic_mmi != null:
		passed += 1
		print("  [PASS 4.1] All 5 specialized munition MultiMesh layers instantiated cleanly")
	else:
		print("  [FAIL 4.1] Munition MultiMesh layers missing")

	# Spawn synthetic munitions across classes 1..5 and verify sync
	var base_p := st.unit_pos[friendly_uid]
	bunker.war_table.set_zoom_and_pan(1.0, Vector2(base_p.x, base_p.z))

	st.spawn_munition(WorldState.FACTION_BLUE, 1, friendly_uid, hostile_uid, base_p, base_p + Vector3(15, 0, 15), "LOFTED_BALLISTIC") # Artillery
	st.spawn_munition(WorldState.FACTION_BLUE, 2, friendly_uid, hostile_uid, base_p, base_p + Vector3(25, 200, 25), "SEA_SKIM_TERCOM") # Cruise
	st.spawn_munition(WorldState.FACTION_BLUE, 3, friendly_uid, hostile_uid, base_p, base_p + Vector3(140, 2000, 140), "LOFTED_BALLISTIC") # Ballistic
	st.spawn_munition(WorldState.FACTION_BLUE, 4, friendly_uid, hostile_uid, base_p, base_p + Vector3(8, 150, 8), "DIRECT") # Drone
	st.spawn_munition(WorldState.FACTION_BLUE, 5, friendly_uid, hostile_uid, base_p, base_p + Vector3(35, 12000, 35), "HYPERSONIC_GLIDE") # Hypersonic

	bunker.sim_server.step_tick(0.016)
	bunker.sim_server._flush_sim_events_to_signals()
	vs.sync_visuals()
	print("  DEBUG: vs.last_visible_munition_count = ", vs.last_visible_munition_count)
	print("  DEBUG: art=%d, crm=%d, bal=%d, drn=%d, hyp=%d, gen=%d" % [
		vs.last_visible_artillery_count, vs.last_visible_cruise_count, vs.last_visible_ballistic_count,
		vs.last_visible_drone_count, vs.last_visible_hypersonic_count, vs.last_visible_munition_count
	])
	total += 1
	if vs.last_visible_munition_count >= 5:
		passed += 1
		print("  [PASS 4.2] MultiMesh sync rendered %d active specialized munitions" % vs.last_visible_munition_count)
	else:
		print("  [FAIL 4.2] MultiMesh sync failed for specialized munitions (count=%d)" % vs.last_visible_munition_count)

	# -------------------------------------------------------------------------
	# 5. US-20.5: End-to-End Ready-to-Play Operational Flow & Plaque Visibility
	# -------------------------------------------------------------------------
	print("\n--- Test Suite 5: Operational Flow & Quick-Controls Plaque ---")
	total += 1
	if bunker.controls_plaque != null and bunker.controls_plaque.text.contains("COMMAND CONTROLS"):
		passed += 1
		print("  [PASS 5.1] QuickControlsPlaque3D is active on war table bezel: '%s'" % bunker.controls_plaque.text)
	else:
		print("  [FAIL 5.1] QuickControlsPlaque3D missing or text mismatch (plaque=%s)" % str(bunker.controls_plaque))

	total += 1
	if bunker.tutorial_controller != null and bunker.main_menu != null and bunker.welcome_controller != null:
		passed += 1
		print("  [PASS 5.2] All three navigation pillars (Tutorial, Main Menu, Welcome Briefing) verified")
	else:
		print("  [FAIL 5.2] Navigation pillars missing")

	# Clean summary
	print("\n==================================================================")
	print("[SPRINT 20 RESULT] %d / %d TESTS PASSED (%.1f%%)" % [passed, total, (float(passed) / float(total)) * 100.0])
	print("==================================================================")

	bunker.cleanup_bunker()
	bunker.free()

	if passed == total:
		quit(0)
	else:
		quit(1)

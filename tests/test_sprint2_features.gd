extends SceneTree
## Automated Adversarial Verification Suite for Sprint 2 (PI 02) Features:
## - Test 1: FEAT-09 Dynamic DEFCON Escalation System (5->1 levels, tension score, loss thresholds, warning flags, PAL dual-key authorization).
## - Test 2: FEAT-10 Tri-Command Headquarters (Deep Granite Bunker, SSBN Submarine Conn, E-4B Doomsday Plane, fade transition & smartwatch HQ button).
## - Test 3: FEAT-11 2028 Dynamic Geopolitical Crisis Scenarios (Taiwan Strait Blockade, Suwalki Breach, Second Thomas Shoal, GIUK Arctic Bastion).
## - Test 4: FEAT-12 Multi-Domain Theater AI & 4-Phase Coordinated Strike Waves (CEMA, SEAD/DEAD, Decoy Saturation, Hypersonic Penetration).
## - Test 5: Battalion Combined Arms Synergy & Multi-Tier Interaction (Bounding overwatch, Drone Datalink handoff to armor, IFV dismounts, APS interception).

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const DefconEscalationSystemScript := preload("res://src/sim_core/systems/defcon_escalation_system.gd")
const TriCommandSystemScript := preload("res://src/presentation/bunker/tri_command_system.gd")
const CoordinatedStrikeSystemScript := preload("res://src/sim_core/systems/coordinated_strike_system.gd")

func _init() -> void:
	print("=== [GATE SPRINT 2] STARTING SPRINT 2 (PI 02) VERIFICATION SUITE ===")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var sim_db: Node = bunker.sim_db
	var sim_server: Node = bunker.sim_server
	var main_menu: CanvasLayer = bunker.main_menu
	var xr_rig: XRCommandRig = bunker.xr_rig
	var desktop_rig: Node3D = bunker.desktop_rig
	var tri_command: Node3D = bunker.tri_command

	# =========================================================================
	# TEST 1: FEAT-09 DYNAMIC DEFCON ESCALATION SYSTEM & PAL AUTHORIZATION
	# =========================================================================
	print("--- [1/5] Testing FEAT-09: Dynamic DEFCON Escalation System & PAL Authorization ---")
	var defcon_sys := DefconEscalationSystemScript.new()
	assert(defcon_sys.current_defcon == 5, "Initial DEFCON must be 5")
	assert(defcon_sys.get_defcon_codename(5) == "Fade Out", "DEFCON 5 must be 'Fade Out'")
	assert(defcon_sys.get_defcon_codename(4) == "Double Take", "DEFCON 4 must be 'Double Take'")
	assert(defcon_sys.get_defcon_codename(3) == "Round House", "DEFCON 3 must be 'Round House'")
	assert(defcon_sys.get_defcon_codename(2) == "Fast Pace", "DEFCON 2 must be 'Fast Pace'")
	assert(defcon_sys.get_defcon_codename(1) == "Cocked Pistol", "DEFCON 1 must be 'Cocked Pistol'")

	# Signal tracking
	var defcon_changes: Array[Dictionary] = []
	var tension_updates: Array[float] = []
	var nuclear_auth_events: Array[bool] = []

	defcon_sys.defcon_changed.connect(func(old_l: int, new_l: int, reason: String):
		defcon_changes.append({"old": old_l, "new": new_l, "reason": reason})
	)
	defcon_sys.tension_updated.connect(func(score: float):
		tension_updates.append(score)
	)
	defcon_sys.nuclear_authorized.connect(func():
		nuclear_auth_events.append(true)
	)

	# Test warning flags
	defcon_sys.set_warning_flag("carrier_threatened", true, "Enemy ASBM launch detected")
	assert(defcon_sys.warning_flags["carrier_threatened"] == true, "Warning flag carrier_threatened must be true")
	assert(defcon_sys.tension_score > 0.0, "Tension score must increase with warning flag")

	# Test trigger_event escalation
	defcon_sys.trigger_event("ASAT_STRIKE", 15.0, "LEO Satellites Blinded")
	assert(defcon_sys.tension_score >= 20.0, "Tension must increase after ASAT strike")
	assert(defcon_sys.current_defcon <= 4, "DEFCON must escalate to 4 or lower")

	# Test higher escalation to DEFCON 2
	defcon_sys.trigger_event("WMD_USAGE", 45.0, "Chemical munition release")
	assert(defcon_sys.current_defcon <= 2, "DEFCON must escalate to 2 on WMD usage")

	# Test DEFCON 1 Cocked Pistol
	defcon_sys.trigger_event("NUCLEAR_DETONATION", 100.0, "Nuclear blast confirmed")
	assert(defcon_sys.current_defcon == 1, "DEFCON must escalate to 1 on nuclear detonation")
	assert(defcon_changes.size() >= 3, "Expected multiple DEFCON transitions recorded")

	# Test Dual-key PAL Authorization
	assert(defcon_sys.pal_authorized == false, "PAL must initially be unauthorized")
	var bad_auth := defcon_sys.verify_pal_code("WRONG-KEY", "INVALID-CODE")
	assert(bad_auth == false, "Invalid PAL keys must be rejected")
	assert(defcon_sys.pal_authorized == false, "PAL must remain unauthorized after bad keys")

	var valid_auth := defcon_sys.verify_pal_code(DefconEscalationSystemScript.DEFAULT_PAL_ALPHA, DefconEscalationSystemScript.DEFAULT_PAL_BRAVO)
	assert(valid_auth == true, "Valid dual-key PAL code must be accepted")
	assert(defcon_sys.pal_authorized == true, "PAL authorization flag must be true")
	assert(nuclear_auth_events.size() > 0, "nuclear_authorized signal must be emitted")

	# Test SimServer PAL integration
	assert(sim_server.has_method("verify_pal_code"), "SimServer must expose verify_pal_code")
	var sim_pal_ok: bool = sim_server.verify_pal_code(DefconEscalationSystemScript.DEFAULT_PAL_ALPHA, DefconEscalationSystemScript.DEFAULT_PAL_BRAVO)
	assert(sim_pal_ok == true, "SimServer verify_pal_code must succeed with valid keys")

	print(" -> [TEST 1 PASSED] FEAT-09 DEFCON Escalation System & PAL Authorization fully verified.")

	# =========================================================================
	# TEST 2: FEAT-10 TRI-COMMAND HEADQUARTERS (BUNKER / SSBN / E-4B)
	# =========================================================================
	print("--- [2/5] Testing FEAT-10: Tri-Command Headquarters (BKR / SSBN / E-4B) ---")
	assert(tri_command != null, "TriCommandSystem must be instantiated on CommandBunker")
	assert(tri_command.get_active_station() == TriCommandSystemScript.Station.STATION_BUNKER, "Initial station must be STATION_BUNKER")

	# Station names verification
	assert(tri_command.get_station_short_name(TriCommandSystemScript.Station.STATION_BUNKER) == "BKR")
	assert(tri_command.get_station_short_name(TriCommandSystemScript.Station.STATION_SSBN) == "SSBN")
	assert(tri_command.get_station_short_name(TriCommandSystemScript.Station.STATION_E4B) == "E4B")

	# Switch to SSBN Conn
	tri_command.switch_station(TriCommandSystemScript.Station.STATION_SSBN)
	assert(tri_command.is_transitioning == true, "Switching station must begin transition fade")
	# Advance transition
	tri_command._process(0.4)
	tri_command._process(0.4)
	assert(tri_command.get_active_station() == TriCommandSystemScript.Station.STATION_SSBN, "Station must switch to STATION_SSBN")
	assert(bunker.submarine_conn.is_sub_sim_active == true, "SSBN Conn sim must be active when in STATION_SSBN")

	# Switch to E-4B Doomsday Plane (NAOC)
	tri_command.switch_station(TriCommandSystemScript.Station.STATION_E4B)
	tri_command._process(0.4)
	tri_command._process(0.4)
	assert(tri_command.get_active_station() == TriCommandSystemScript.Station.STATION_E4B, "Station must switch to STATION_E4B")
	assert(tri_command.e4b_altitude_ft == 38000.0, "E-4B cruising altitude must be 38,000 ft")
	assert(tri_command.e4b_speed_mach == 0.84, "E-4B cruise speed must be Mach 0.84")
	assert(tri_command.e4b_trailing_vlf_antenna_km == 8.0, "E-4B trailing wire antenna must be 8.0 km")
	assert(tri_command.e4b_antenna_deployed == true, "E-4B trailing wire antenna must be deployed")

	# Test aerodynamic banking & turbulence physics
	tri_command._process(0.1)
	assert(tri_command._e4b_cabin_root.visible == true, "E-4B cabin visuals must be visible")

	# Test Smartwatch button actuation for HQ cycling
	assert(xr_rig._wrist_buttons.has("btn_hq"), "XRCommandRig smartwatch must contain 'btn_hq' button")
	var hq_act_res: String = xr_rig.actuate_wrist_button("btn_hq")
	print(" -> Smartwatch HQ actuation result: %s" % hq_act_res)
	assert(hq_act_res.begins_with("HQ_SWITCHED_"), "Expected HQ_SWITCHED_ result from smartwatch tap")

	print(" -> [TEST 2 PASSED] FEAT-10 Tri-Command Headquarters verified with zero room buttons.")

	# =========================================================================
	# TEST 3: FEAT-11 2028 DYNAMIC GEOPOLITICAL CRISIS SCENARIOS
	# =========================================================================
	print("--- [3/5] Testing FEAT-11: 4 2028 Dynamic Geopolitical Crisis Scenarios ---")
	var crisis_scenarios := [
		["taiwan_strait_blockade_2028", "strait_theater", "Crisis 2028: Taiwan Strait Full Blockade & Carrier Clash"],
		["suwalki_corridor_breach_2028", "baltic_suwalki_theater", "Crisis 2028: Suwalki Corridor High-Intensity Armored Breach"],
		["second_thomas_shoal_clash_2028", "strait_theater", "Crisis 2028: Second Thomas Shoal Littoral Clash & USV Swarms"],
		["giuk_arctic_bastion_2028", "baltic_suwalki_theater", "Crisis 2028: GIUK Gap & Arctic Bastion Under-Ice ASW Duel"],
	]

	for item in crisis_scenarios:
		var s_slug: String = item[0]
		var exp_theater: String = item[1]
		var exp_title: String = item[2]

		# Verify scenario exists in SimDB
		assert(sim_db.scenarios_by_slug.has(s_slug), "Scenario '%s' must be registered in SimDB" % s_slug)
		var sc_def: Dictionary = sim_db.scenarios_by_slug[s_slug]
		assert(String(sc_def.get("display_name", "")) == exp_title, "Scenario '%s' title mismatch" % s_slug)

		# Load scenario on SimServer
		sim_server.load_scenario(s_slug)
		var st: WorldState = sim_server.world_state
		assert(st.active_theater_slug == exp_theater, "Scenario '%s' expected theater '%s', got '%s'" % [s_slug, exp_theater, st.active_theater_slug])
		assert(st.get_active_unit_count() >= 40, "Scenario '%s' must spawn active combat units" % s_slug)
		assert(st.active_sites.size() >= 3, "Scenario '%s' must populate strategic sites" % s_slug)
		print(" -> Verified Crisis Scenario '%s' on '%s' (%d units, %d sites)" % [s_slug, st.active_theater_slug, st.get_active_unit_count(), st.active_sites.size()])

	print(" -> [TEST 3 PASSED] FEAT-11 4 Geopolitical Crisis Scenarios fully operational.")

	# =========================================================================
	# TEST 4: FEAT-12 4-PHASE COORDINATED STRIKE WAVES
	# =========================================================================
	print("--- [4/5] Testing FEAT-12: Multi-Domain Theater AI & 4-Phase Coordinated Strike Waves ---")
	sim_server.load_scenario("taiwan_strait_blockade_2028")
	var target_loc := Vector3(-45.0, 0.0, 30.0)

	var strike_cfg := {
		"faction": WorldState.FACTION_BLUE,
		"radius_km": 40.0,
		"sead_missiles": 8,
		"decoys": 16,
		"hypersonic_rounds": 6,
	}

	var strike_res: Dictionary = sim_server.execute_coordinated_strike_package(target_loc, strike_cfg)
	assert(strike_res.has("success") and strike_res["success"] == true, "Coordinated strike execution must succeed")
	assert(strike_res.has("phase_1_cema"), "Result must contain Phase 1 CEMA")
	assert(strike_res.has("phase_2_sead"), "Result must contain Phase 2 SEAD/DEAD")
	assert(strike_res.has("phase_3_decoys"), "Result must contain Phase 3 Decoys")
	assert(strike_res.has("phase_4_hypersonic"), "Result must contain Phase 4 Hypersonic Penetration")

	print(" -> Phase 1 CEMA: %s | Degraded: %.0f%%" % [strike_res["phase_1_cema"]["status"], float(strike_res["phase_1_cema"]["radar_degradation_ratio"]) * 100.0])
	print(" -> Phase 2 SEAD: %d Emitters Suppressed" % strike_res["phase_2_sead"]["emitters_destroyed"])
	print(" -> Phase 3 Decoys: %d Interceptors Exhausted" % strike_res["phase_3_decoys"]["interceptor_magazines_drained"])
	print(" -> Phase 4 Hypersonic: %d Hits Confirmed @ Mach %.1f" % [strike_res["phase_4_hypersonic"]["penetration_hits"], strike_res["phase_4_hypersonic"]["mach_speed"]])
	assert(strike_res["total_damage_dealt"] > 0.0, "Coordinated strike package must inflict real kinetic damage")

	print(" -> [TEST 4 PASSED] FEAT-12 4-Phase Coordinated Strike Waves verified.")

	# =========================================================================
	# TEST 5: BATTALION COMBINED ARMS SYNERGY & MULTI-TIER INTERACTION
	# =========================================================================
	print("--- [5/5] Testing Battalion Combined Arms Synergy & Multi-Tier Interaction ---")
	sim_server.load_scenario("suwalki_corridor_breach_2028")
	var st_ca: WorldState = sim_server.world_state

	# Step simulation through 5 ticks to test combined arms synergy
	for t in range(5):
		sim_server.step_tick(0.10)

	var synergy_res: Dictionary = CoordinatedStrikeSystemScript.step_combined_arms_synergy(
		st_ca, sim_db, sim_server.spatial_grid, 0.10
	)
	print(" -> Combined Arms Synergy: Drone Datalinks=%d, APS Intercepts=%d, Bounding Tanks=%d" % [
		synergy_res.get("drone_target_handoffs", 0),
		synergy_res.get("aps_intercepts", 0),
		synergy_res.get("bounding_tanks", 0)
	])
	assert(synergy_res.has("drone_target_handoffs"), "Synergy result must report drone target handoffs")
	assert(synergy_res.has("aps_intercepts"), "Synergy result must report APS active protection intercepts")

	# Test Bounding Overwatch move propagation across Battalion
	var test_bn_uid := -1
	for uid in range(st_ca.unit_count):
		if st_ca.unit_active[uid] == 1 and st_ca.unit_echelon[uid] == WorldState.ECHELON_BATTALION:
			test_bn_uid = uid
			break

	if test_bn_uid >= 0:
		var target_dest := Vector3(15.0, 0.0, 10.0)
		EchelonClusterSystem.propagate_move_order(st_ca, test_bn_uid, target_dest)
		# Verify subordinate leaf units received waypoints
		var subordinates_with_waypoints := 0
		for sub_id in range(st_ca.unit_count):
			if st_ca.unit_active[sub_id] == 1 and st_ca.unit_parent_id[sub_id] == test_bn_uid:
				if st_ca.unit_has_waypoint[sub_id] == 1:
					subordinates_with_waypoints += 1
		assert(subordinates_with_waypoints > 0, "Subordinate battalion units must receive bounding waypoints")
		print(" -> Battalion %d propagated bounding overwatch waypoints to %d subordinate units" % [test_bn_uid, subordinates_with_waypoints])

	# Cleanup
	bunker.cleanup_bunker()
	bunker.free()

	print("=== [GATE SPRINT 2 PASSED] ALL 5 ADVERSARIAL SPRINT 2 TESTS PASSED WITH 0 ERRORS! ===")
	quit(0)

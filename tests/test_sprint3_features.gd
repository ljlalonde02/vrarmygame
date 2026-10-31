extends SceneTree
## Sprint 3 Automated Adversarial Test Suite:
## 1. Test 1: Strategic Airlifters & Logistics Convoys in SimDB (C-17, Il-76, HEMTT, KamAZ)
## 2. Test 2: Combat Airborne Airdrop System (`CombatEngineeringAirborneSystem`)
## 3. Test 3: XR Command Rig (VR OpenXR 6DOF Table Grab, Zoom & Diegetic Smartwatch)
## 4. Test 4: Autonomous AI Playtester Bot (`SimPlaytesterBot`)
## 5. Test 5: AI Video Generation Manifest & 4 Tactical Feeds

const SimServerScript := preload("res://src/sim_core/sim_server.gd")
const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const PlaytesterBotScript := preload("res://src/sim_core/ai/sim_playtester_bot.gd")
const XRCommandRigScript := preload("res://src/presentation/rigs/xr_command_rig.gd")
const WarTableScript := preload("res://src/presentation/war_table/war_table.gd")
const TacticalConsoleScript := preload("res://src/presentation/bunker/hardware/tactile_console.gd")

func _init() -> void:
	print("==================================================================")
	print("[SPRINT 3 TEST SUITE] Running Verification for Sprint 3 User Stories...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	root.add_child(sim_db)
	sim_db.load_database()

	var sim_server := SimServerScript.new()
	root.add_child(sim_server)
	sim_server.sim_db_ref = sim_db
	sim_server._ready()

	# --- TEST 1: Strategic Airlifters & Logistics Convoys ---
	print("\n--- [1/5] Testing Strategic Airlifters & Logistics Convoys in SimDB ---")
	var pid_c17: int = sim_db.get_platform_id("c17_globemaster_iii")
	var pid_il76: int = sim_db.get_platform_id("il76_candid")
	var pid_hemtt: int = sim_db.get_platform_id("hemtt_supply_convoy")
	var pid_kamaz: int = sim_db.get_platform_id("kamaz_resupply_truck")

	assert(pid_c17 > 0, "C-17 Globemaster III platform ID must exist in SimDB")
	assert(pid_il76 > 0, "Il-76 Candid platform ID must exist in SimDB")
	assert(pid_hemtt > 0, "HEMTT supply convoy must exist in SimDB")
	assert(pid_kamaz > 0, "KamAZ supply truck must exist in SimDB")

	var def_c17 := sim_db.get_platform(pid_c17)
	assert(String(def_c17.get("domain", "")) == "AIR", "C-17 must belong to AIR domain")
	assert(int(def_c17.get("cruise_speed_knots", 0)) >= 400, "C-17 cruise speed must be >= 400 kts")
	print("  PASS: Strategic Airlifters and Logistics Convoys verified in SimDB.")

	# --- TEST 2: Airborne Paratrooper & Supply Airdrop ---
	print("\n--- [2/5] Testing Airborne Airdrop System ---")
	var st: WorldState = sim_server.world_state
	var drop_res := CombatEngineeringAirborneSystem.execute_engineering_or_airborne_op(
		st, sim_db, CombatEngineeringAirborneSystem.AIRBORNE_PARATROOP_DROP, Vector3(22.0, 0.0, -18.0)
	)
	assert(st.parachute_drops.size() > 0, "Parachute drops must be registered in WorldState")
	assert(st.airborne_drops_executed_count >= 1, "Airborne drop count must increment")
	print("  PASS: Airborne Airdrop correctly spawned descending parachute pallets.")

	# --- TEST 3: XR Command Rig (VR OpenXR & Diegetic Smartwatch) ---
	print("\n--- [3/5] Testing XR Command Rig (VR OpenXR 6DOF & Smartwatch) ---")
	var wt := WarTableScript.new()
	root.add_child(wt)
	wt.sim_server = sim_server

	var console := TacticalConsoleScript.new()
	root.add_child(console)

	var xr_rig := XRCommandRigScript.new()
	root.add_child(xr_rig)
	if xr_rig.xr_camera == null:
		xr_rig._ready()
	xr_rig.setup(wt, sim_server, sim_server.command_bus_ref, sim_server.signal_bus_ref, console)

	assert(xr_rig.xr_camera != null, "XRCamera3D must be initialized")
	assert(xr_rig.left_controller != null, "Left controller must be initialized")
	assert(xr_rig.right_controller != null, "Right controller must be initialized")
	assert(xr_rig._wrist_tablet_root != null, "Diegetic left-wrist smartwatch HUD must exist")
	print("  PASS: XR Command Rig verified with diegetic wrist smartwatch and OpenXR controllers.")

	# --- TEST 4: Autonomous Playtester Bot ---
	print("\n--- [4/5] Testing Autonomous Playtester Bot ---")
	var bot := PlaytesterBotScript.new()
	bot.setup(sim_server, sim_db)
	var audit_res := bot.run_autonomous_playtest_session("trial:vision_60_q_ugv", 2.0, 0.20)

	assert(audit_res.has("orders_issued"), "Audit report must track orders issued")
	assert(audit_res.has("playability_score_pct"), "Audit report must compute playability score")
	assert(float(audit_res.get("playability_score_pct", 0.0)) > 0.0, "Playability score must be positive")
	print("  PASS: Playtester Bot evaluated scenario: Playability Score = %.1f%%" % [audit_res["playability_score_pct"]])

	# --- TEST 5: Tactical Action Video Manifest ---
	print("\n--- [5/5] Testing AI Video Manifest & 4 Tactical Feeds ---")
	var manifest_path := "res://assets/videos/units/unit_video_manifest.json"
	assert(FileAccess.file_exists(manifest_path), "Video manifest JSON must exist on disk")
	var m_text := FileAccess.get_file_as_string(manifest_path)
	var m_json = JSON.parse_string(m_text)
	assert(typeof(m_json) == TYPE_DICTIONARY, "Video manifest must parse as Dictionary")
	assert(m_json.has("f_35a_lightning"), "F-35A must be in video manifest")
	assert(m_json["f_35a_lightning"]["prompts"].has("atk"), "F-35A must have ATK prompt")
	assert(m_json["f_35a_lightning"]["prompts"].has("def"), "F-35A must have DEF prompt")
	assert(m_json["f_35a_lightning"]["prompts"].has("win"), "F-35A must have WIN prompt")
	assert(m_json["f_35a_lightning"]["prompts"].has("loss"), "F-35A must have LOSS prompt")
	print("  PASS: AI Tactical Video Manifest verified for all 4 combat states.")

	print("\n==================================================================")
	print("[SPRINT 3 TEST SUITE] ALL 5 TESTS PASSED WITH 100% SUCCESS!")
	print("==================================================================")
	quit(0)

extends SceneTree
## Automated Adversarial Verification Suite for Interactive Gameplay Fixes & Platform Fidelity:
## - Test 1: Strict Friendly vs Enemy Selection Segregation (Desktop & XR Command Rigs + Server Movement Rejection).
## - Test 2: RWR Warning Spike & Immediate OPFOR Tactical Counter-Reaction (NOE dive to 350m, afterburner, chaff/flares).
## - Test 3: Authentic Attack Helicopters & Strategic SSBNs in SimDB (AH-64E, Ka-52, Columbia SSBN, Type 094 Jin).
## - Test 4: Infantry Suppression & Reverse-Slope Cover Fallback against Superior Hostile Armor (2.5 km envelope).

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const UnitTacticalAISystemScript := preload("res://src/sim_core/systems/unit_tactical_ai_system.gd")
const CemaElectronicWarfareSystemScript := preload("res://src/sim_core/systems/cema_electronic_warfare_system.gd")

func _init() -> void:
	print("=== [GATE GAMEPLAY] STARTING GAMEPLAY FIXES & FIDELITY VERIFICATION SUITE ===")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var sim_db: Node = bunker.sim_db
	var sim_server: Node = bunker.sim_server
	var desktop_rig: Node3D = bunker.desktop_rig
	var st: WorldState = sim_server.world_state
	st.unit_count = maxi(st.unit_count, 16)

	# =========================================================================
	# TEST 1: STRICT FRIENDLY VS ENEMY SELECTION SEGREGATION & REJECTION
	# =========================================================================
	print("--- [1/4] Testing Friendly vs Enemy Selection Segregation & Order Rejection ---")
	# Spawn a Blue unit and a Red unit
	var blue_uid := 0
	var red_uid := 1
	st.unit_active[blue_uid] = 1
	st.unit_faction[blue_uid] = WorldState.FACTION_BLUE
	st.unit_echelon[blue_uid] = WorldState.ECHELON_COMPANY
	st.unit_pos[blue_uid] = Vector3(10.0, 500.0, 10.0)

	st.unit_active[red_uid] = 1
	st.unit_faction[red_uid] = WorldState.FACTION_RED
	st.unit_echelon[red_uid] = WorldState.ECHELON_COMPANY
	st.unit_pos[red_uid] = Vector3(30.0, 500.0, 30.0)

	# 1a. Selecting friendly unit
	desktop_rig.select_unit(blue_uid)
	assert(desktop_rig.selected_unit_id == blue_uid, "Friendly unit must be selected")
	assert(desktop_rig.selected_unit_ids.has(blue_uid), "Friendly unit must be in selected_unit_ids")

	# 1b. Selecting enemy unit must NOT add it to selected_unit_ids, but set designated_target_uid
	desktop_rig.select_unit(red_uid)
	assert(not desktop_rig.selected_unit_ids.has(red_uid), "Enemy unit must NEVER be in selected_unit_ids!")
	assert(desktop_rig.designated_target_uid == red_uid, "Enemy unit must be set as designated_target_uid")

	# 1c. select_unit_group with mixed units: must only keep friendly and designate enemy
	var mixed_group: Array[int] = [blue_uid, red_uid]
	desktop_rig.select_unit_group(mixed_group, blue_uid)
	assert(desktop_rig.selected_unit_ids.has(blue_uid), "Friendly unit must remain selected")
	assert(not desktop_rig.selected_unit_ids.has(red_uid), "Enemy unit must be filtered out of selected_unit_ids")
	assert(desktop_rig.designated_target_uid == red_uid, "Enemy unit in group must update designated_target_uid")

	# 1d. Server movement rejection: Try to issue movement order to enemy unit
	var forbidden_dest := Vector3(100.0, 500.0, 100.0)
	sim_server._apply_command({
		"type": "CMD_MOVE_WAYPOINTS",
		"unit_ids": [red_uid],
		"waypoints_km": [forbidden_dest],
		"faction": WorldState.FACTION_BLUE
	})
	assert(st.unit_target_pos[red_uid] != forbidden_dest, "Server MUST reject movement orders for enemy units")
	assert(st.unit_has_waypoint[red_uid] == 0, "Enemy unit must not get waypoint from player command")

	print(" -> [TEST 1 PASSED] Friendly vs Enemy selection segregation and movement rejection verified.")

	# =========================================================================
	# TEST 2: RWR WARNING & IMMEDIATE OPFOR TACTICAL COUNTER-REACTION
	# =========================================================================
	print("--- [2/4] Testing RWR Warning Spike & Immediate OPFOR Counter-Reaction ---")
	var target_jet := 2
	st.unit_active[target_jet] = 1
	st.unit_faction[target_jet] = WorldState.FACTION_RED
	st.unit_platform_id[target_jet] = sim_db.get_platform_id("su_57_felon")
	st.unit_pos[target_jet] = Vector3(50.0, 8000.0, 50.0)
	st.unit_ai_state[target_jet] = WorldState.AI_PATROL_CAP
	st.unit_threat_level[target_jet] = 0.0
	st.unit_afterburner[target_jet] = 0

	# Fire RWR warning spike from attacker (blue_uid)
	CemaElectronicWarfareSystemScript.trigger_rwr_warning(st, sim_db, target_jet, blue_uid)

	assert(st.unit_threat_level[target_jet] >= 0.85, "Threat level must jump to at least 0.85 upon RWR spike")
	assert(st.unit_ai_state[target_jet] == WorldState.AI_EVASIVE_DEFENSIVE, "AI state must switch to AI_EVASIVE_DEFENSIVE")
	assert(st.unit_afterburner[target_jet] == 1, "Afterburner must engage immediately")
	assert(st.unit_desired_alt_m[target_jet] == 350.0, "Desired altitude must dive to 350m NOE terrain deck")
	assert(st.unit_has_waypoint[target_jet] == 1, "Evasive waypoint must be assigned")

	# Check countermeasure event queued
	var cm_event_found := false
	for ev in st.sim_events_queue:
		if ev.get("type") == "COUNTERMEASURE_DEPLOYED" and ev.get("unit_id") == target_jet:
			cm_event_found = true
			break
	assert(cm_event_found, "Countermeasures deployed event must be emitted into sim_events_queue")
	print(" -> [TEST 2 PASSED] RWR radar warning spike & immediate OPFOR counter-reaction verified.")

	# =========================================================================
	# TEST 3: AUTHENTIC ATTACK HELICOPTERS & STRATEGIC SSBNS IN SIMDB
	# =========================================================================
	print("--- [3/4] Testing Attack Helicopters & Strategic SSBNs in SimDB ---")
	var ah64_id: int = sim_db.get_platform_id("ah_64e_apache_guardian")
	var ka52_id: int = sim_db.get_platform_id("ka_52_alligator")
	var columbia_id: int = sim_db.get_platform_id("columbia_class_ssbn")
	var type094_id: int = sim_db.get_platform_id("type_094_jin_ssbn")

	assert(ah64_id > 0, "AH-64E Apache Guardian platform ID must be > 0")
	assert(ka52_id > 0, "Ka-52 Alligator platform ID must be > 0")
	assert(columbia_id > 0, "Columbia SSBN platform ID must be > 0")
	assert(type094_id > 0, "Type 094 Jin SSBN platform ID must be > 0")

	var ah64_def: Dictionary = sim_db.get_platform(ah64_id)
	assert(String(ah64_def.get("domain", "")) == "AIR", "AH-64E domain must be AIR")
	assert(String(ah64_def.get("unit_class", "")) == "HELICOPTER", "AH-64E class must be HELICOPTER")
	assert(float(ah64_def.get("cruise_speed_knots", 0.0)) >= 135.0, "AH-64E cruise speed must be realistic")
	assert(float(ah64_def.get("unit_cost_musd", 0.0)) == 38.0, "AH-64E unit cost must be $38M")

	var columbia_def: Dictionary = sim_db.get_platform(columbia_id)
	assert(String(columbia_def.get("domain", "")) == "SEA", "Columbia domain must be SEA")
	assert(String(columbia_def.get("unit_class", "")) == "SSBN", "Columbia class must be SSBN")
	assert(float(columbia_def.get("unit_cost_musd", 0.0)) == 3800.0, "Columbia unit cost must be $3,800M")

	# Check weapon loading
	var hellfire_id: int = sim_db.get_weapon_id("agm_114_hellfire")
	assert(hellfire_id > 0, "AGM-114 Hellfire weapon ID must be > 0")
	var trident_id: int = sim_db.get_weapon_id("trident_ii_d5_slbm")
	assert(trident_id > 0, "Trident II D5 weapon ID must be > 0")

	print(" -> [TEST 3 PASSED] Attack helicopters & Strategic SSBN platforms and weapons verified in SimDB.")

	# =========================================================================
	# TEST 4: INFANTRY SUPPRESSION & TACTICAL COVER FALLBACK
	# =========================================================================
	print("--- [4/4] Testing Infantry Suppression & Tactical Cover Fallback ---")
	var inf_uid := 3
	var tank_uid := 4

	st.unit_active[inf_uid] = 1
	st.unit_faction[inf_uid] = WorldState.FACTION_BLUE
	st.unit_platform_id[inf_uid] = sim_db.get_platform_id("specops_mountain_team")
	st.unit_echelon[inf_uid] = WorldState.ECHELON_COMPANY
	st.unit_pos[inf_uid] = Vector3(0.0, 10.0, 0.0)
	st.unit_sim_lod[inf_uid] = WorldState.LOD_TIER_0_MICRO
	st.unit_ai_state[inf_uid] = WorldState.AI_PATROL_CAP
	st.unit_afterburner[inf_uid] = 0

	# Spawn enemy T-90M tank platoon within 1.2 km (well within 2.5 km envelope)
	st.unit_active[tank_uid] = 1
	st.unit_faction[tank_uid] = WorldState.FACTION_RED
	st.unit_platform_id[tank_uid] = sim_db.get_platform_id("t_90m_platoon")
	st.unit_echelon[tank_uid] = WorldState.ECHELON_COMPANY
	st.unit_pos[tank_uid] = Vector3(1.2, 10.0, 0.0)
	st.unit_detected_mask[tank_uid] = 1

	# Execute UnitTacticalAISystem step
	UnitTacticalAISystemScript.step(st, sim_db, bunker.sim_server.spatial_grid, 0.1)

	assert(st.unit_ai_state[inf_uid] == WorldState.AI_EVASIVE_DEFENSIVE, "Suppressed infantry must transition to AI_EVASIVE_DEFENSIVE")
	assert(st.unit_threat_level[inf_uid] >= 0.85, "Suppressed infantry threat level must jump >= 0.85")
	assert(st.unit_afterburner[inf_uid] == 1, "Suppressed infantry must sprint (+40% afterburner flag)")
	assert(st.unit_has_waypoint[inf_uid] == 1, "Suppressed infantry must have assigned fallback waypoint")
	# Target position must move away from the tank (tank is at x=1.2, inf at x=0, fallback should have x < 0)
	assert(st.unit_target_pos[inf_uid].x < 0.0, "Infantry must fallback in opposite direction of hostile armor")

	print(" -> [TEST 4 PASSED] Infantry suppression & reverse-slope cover fallback verified.")

	print("=== [GATE GAMEPLAY PASSED] ALL 4 ADVERSARIAL PLAYABILITY CHECKS PASSED WITH 0 ERRORS! ===")
	quit(0)

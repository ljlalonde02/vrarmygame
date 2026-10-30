class_name UnderseaWarfareSystem
extends RefCounted
## Phase 32: Submarine Undersea Cable Sabotage, SOSUS Seabed Hydrophone Arrays & Anti-Submarine Warfare (ASW):
## - Seeds authentic Subsea Fiber-Optic Internet Trunk Cables & Offshore Gas Pipelines across all 7 theaters (`undersea_cables`).
## - `UNDERSEA_DEPLOY_SOSUS_BARRIER`: Deploys SOSUS seabed acoustic arrays & P-8A sonobuoys (`sosus_barriers_active_count`), revealing all submerged `FLAG_UUV_SUB` submarines and boosting Blue C2.
## - `UNDERSEA_SABOTAGE_ENEMY_CABLE`: Dispatches `Orca XLUUV` / Navy SEAL SDVs to tap & sever OPFOR subsea optical/energy trunks (`cables_sabotaged_count`), degrading `red_c2_integrity` and `red_power_grid_pct`.
## - `UNDERSEA_REPAIR_CABLE_SHIP`: Dispatches Cable Repair Vessels to splice severed Allied subsea trunks (`cables_repaired_count`), restoring `blue_c2_integrity` to 100%.

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const UNDERSEA_DEPLOY_SOSUS_BARRIER := "UNDERSEA_DEPLOY_SOSUS_BARRIER"
const UNDERSEA_SABOTAGE_ENEMY_CABLE := "UNDERSEA_SABOTAGE_ENEMY_CABLE"
const UNDERSEA_REPAIR_CABLE_SHIP := "UNDERSEA_REPAIR_CABLE_SHIP"


static func seed_theater_undersea_cables(state: WorldState) -> void:
	state.undersea_cables.clear()
	state.sosus_barriers_active_count = 1
	state.cables_sabotaged_count = 0
	state.cables_repaired_count = 0

	var t_slug := state.active_theater_slug
	if t_slug.find("baltic") != -1 or t_slug.find("suwalki") != -1:
		state.undersea_cables = [
			{"id": 0, "name": "Balticconnector & C-Lion1 Subsea Fiber/Gas Trunk", "faction_owner": "BLUE", "start_km": Vector3(-165.0, -45.0, -120.0), "end_km": Vector3(45.0, -45.0, 95.0), "severed": false},
			{"id": 1, "name": "Kaliningrad-St. Petersburg Baltika Subsea Optical Cable", "faction_owner": "RED", "start_km": Vector3(-140.0, -50.0, -85.0), "end_km": Vector3(130.0, -50.0, -165.0), "severed": false},
			{"id": 2, "name": "Nordic-Polish Subsea High-Voltage HVDC Interconnector", "faction_owner": "BLUE", "start_km": Vector3(-95.0, -40.0, -150.0), "end_km": Vector3(-60.0, -40.0, 145.0), "severed": false},
		]
	elif t_slug.find("hormuz") != -1:
		state.undersea_cables = [
			{"id": 0, "name": "FALCON / SEA-ME-WE-5 Persian Gulf Subsea Fiber Trunk", "faction_owner": "BLUE", "start_km": Vector3(-180.0, -60.0, 65.0), "end_km": Vector3(175.0, -60.0, 95.0), "severed": false},
			{"id": 1, "name": "IRGC Bandar Abbas-Qeshm-Kish Subsea C2 & Gas Pipeline", "faction_owner": "RED", "start_km": Vector3(-95.0, -50.0, -110.0), "end_km": Vector3(85.0, -50.0, -75.0), "severed": false},
		]
	else:
		# Default: Taiwan Strait / Indo-Pacific (`APG`, `TPE`, `Cross-Strait Optical`)
		state.undersea_cables = [
			{"id": 0, "name": "Trans-Pacific Express (TPE) & APG Toucheng-Okinawa Subsea Fiber", "faction_owner": "BLUE", "start_km": Vector3(115.0, -65.0, -75.0), "end_km": Vector3(215.0, -65.0, -185.0), "severed": false},
			{"id": 1, "name": "Taiwan-Penghu-Kinmen (TPK) Subsea C4ISR Optical Trunk", "faction_owner": "BLUE", "start_km": Vector3(68.0, -55.0, 35.0), "end_km": Vector3(-18.0, -55.0, 15.0), "severed": false},
			{"id": 2, "name": "PLA Eastern Theater Fuzhou-Pingtan-Xiamen Subsea Military Fiber", "faction_owner": "RED", "start_km": Vector3(-135.0, -55.0, -85.0), "end_km": Vector3(-125.0, -55.0, 95.0), "severed": false},
		]


static func execute_undersea_operation(state: WorldState, sim_db: Node, op_code: String) -> Dictionary:
	if state.undersea_cables.is_empty():
		seed_theater_undersea_cables(state)

	if op_code == UNDERSEA_DEPLOY_SOSUS_BARRIER:
		state.sosus_barriers_active_count += 1
		var subs_detected := 0
		var p_flags: PackedInt32Array = sim_db.plat_class_flags
		var flag_sub := int(sim_db.FLAG_UUV_SUB) | int(sim_db.FLAG_SHIP)
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED:
				var pid := state.unit_platform_id[uid]
				if pid > 0 and pid < p_flags.size() and (p_flags[pid] & flag_sub) != 0:
					state.unit_detected_mask[uid] |= 1
					subs_detected += 1
		BudgetTechSystemScript.add_escalation(state, sim_db, 3.0,
			"SOSUS SEABED HYDROPHONE & P-8A SONOBUOY BARRIER ACTIVE: %d OPFOR submarines/surface vessels acoustically localized!" % subs_detected,
			"COMSUBPAC / IUSS SOSUS DESK: 'Seabed low-frequency acoustic arrays locked onto hostile undersea signatures across the strait.'")
		return {
			"ok": true,
			"op_code": op_code,
			"sosus_barriers": state.sosus_barriers_active_count,
			"subs_detected": subs_detected,
		}

	elif op_code == UNDERSEA_SABOTAGE_ENEMY_CABLE:
		var target_cable_name := "OPFOR Subsea Military Fiber"
		for i in range(state.undersea_cables.size()):
			var cb: Dictionary = state.undersea_cables[i]
			if String(cb.get("faction_owner", "")) == "RED" and not bool(cb.get("severed", false)):
				cb["severed"] = true
				target_cable_name = String(cb.get("name", target_cable_name))
				state.undersea_cables[i] = cb
				break
		state.cables_sabotaged_count += 1
		state.red_c2_integrity = clampf(state.red_c2_integrity - 0.22, 0.25, 1.0)
		state.red_power_grid_pct = maxf(15.0, state.red_power_grid_pct - 18.0)
		BudgetTechSystemScript.add_escalation(state, sim_db, 6.5,
			"SUBSEA CABLE SABOTAGE: Orca XLUUV & SEAL SDV swimmers severed '%s' on the seabed (-22%% Red C2)!" % target_cable_name,
			"TASK FORCE 69 UNDERSEA WARFARE: 'Seabed optical trunk and offshore energy pipeline severed; enemy C4ISR bandwidth crippled.'")
		return {
			"ok": true,
			"op_code": op_code,
			"cable_name": target_cable_name,
			"cables_sabotaged": state.cables_sabotaged_count,
			"red_c2_integrity": state.red_c2_integrity,
		}

	elif op_code == UNDERSEA_REPAIR_CABLE_SHIP:
		for i in range(state.undersea_cables.size()):
			var cb: Dictionary = state.undersea_cables[i]
			if String(cb.get("faction_owner", "")) == "BLUE" and bool(cb.get("severed", false)):
				cb["severed"] = false
				state.undersea_cables[i] = cb
		state.cables_repaired_count += 1
		state.blue_c2_integrity = 1.0
		state.blue_power_grid_pct = minf(100.0, state.blue_power_grid_pct + 20.0)
		BudgetTechSystemScript.add_escalation(state, sim_db, -2.0,
			"SUBSEA FIBER TRUNK REPAIRED: Allied Cable Repair Ship spliced trans-oceanic optical trunk (Blue C2 100%)!",
			"COALITION MARITIME C4ISR: 'Subsea fiber-optic repeaters spliced and pressurized; full trans-oceanic terabit telemetry restored.'")
		return {
			"ok": true,
			"op_code": op_code,
			"cables_repaired": state.cables_repaired_count,
			"blue_c2_integrity": state.blue_c2_integrity,
		}

	return {"ok": false, "reason": "Unknown undersea op_code"}

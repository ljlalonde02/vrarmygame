class_name HomefrontEconomySystem
extends RefCounted
## Phase 33: Domestic Homefront Stability, War Economy Inflation, Brent Crude Oil ($/bbl),
## Defense Industrial Stock Index & UN / ICC War Crimes Tribunal ROE:
## - Tracks `blue_public_support_pct`, `global_oil_price_bbl`, `defense_industrial_index`, and `un_war_crimes_investigation_level`.
## - `HOMEFRONT_ISSUE_WAR_BONDS`: Issues Defense Victory War Bonds & Defense Production Act surge (+$450M budget, +85 Defense Index).
## - `HOMEFRONT_ENFORCE_SURGICAL_ROE`: Enforces Strict Surgical Precision ROE (`M82A1` Snipers / `GBU-57`), clearing UN War Crimes scrutiny, boosting public support (+14%) & granting +$220M Coalition legitimacy aid.
## - `HOMEFRONT_STRATEGIC_PETRO_RESERVE`: Releases Strategic Petroleum Reserve (`SPR`), dropping Brent Crude by -$32/bbl and adding +$25M/min economic stability income.

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const HOMEFRONT_ISSUE_WAR_BONDS := "HOMEFRONT_ISSUE_WAR_BONDS"
const HOMEFRONT_ENFORCE_SURGICAL_ROE := "HOMEFRONT_ENFORCE_SURGICAL_ROE"
const HOMEFRONT_STRATEGIC_PETRO_RESERVE := "HOMEFRONT_STRATEGIC_PETRO_RESERVE"


static func step(state: WorldState, dt: float) -> void:
	# Global oil price responds to DEFCON escalation & collateral shipping hits
	var target_oil := 84.0 + (5.0 - float(state.defcon_level)) * 22.0 + float(state.collateral_convoy_hits_count) * 8.0
	if state.spr_releases_count > 0:
		target_oil = maxf(68.0, target_oil - float(state.spr_releases_count) * 24.0)
	state.global_oil_price_bbl = lerpf(state.global_oil_price_bbl, clampf(target_oil, 65.0, 245.0), clampf(dt * 0.15, 0.0, 1.0))

	# UN War Crimes Tribunal check based on collateral incidents & WMD usage unless Surgical ROE enforced
	if state.surgical_roe_enforced:
		state.un_war_crimes_investigation_level = 0
	elif state.nuclear_detonations_count > 0 or state.cbrn_strikes_count > 1:
		state.un_war_crimes_investigation_level = 2
	elif state.collateral_incidents_count > 5:
		state.un_war_crimes_investigation_level = 1

	var roe_str := "SURGICAL PRECISION" if state.surgical_roe_enforced else ("UN TRIBUNAL L" + str(state.un_war_crimes_investigation_level))
	state.latest_homefront_status = "HOMEFRONT: Support %d%% | Brent Crude $%.0f/bbl | Defense Index %.0f | ROE: %s" % [
		int(state.blue_public_support_pct), state.global_oil_price_bbl, state.defense_industrial_index, roe_str
	]


static func execute_homefront_action(state: WorldState, sim_db: Node, action_code: String) -> Dictionary:
	if action_code == HOMEFRONT_ISSUE_WAR_BONDS:
		state.war_bonds_issued_count += 1
		state.blue_budget_available_musd += 450.0
		state.defense_industrial_index += 85.0
		state.blue_auto_ammo_per_min += 4
		BudgetTechSystemScript.add_escalation(state, sim_db, 2.0,
			"DEFENSE VICTORY WAR BONDS & DPA SURGE: Treasury raised +$450M warchest; Defense Industrial Index surged to %.0f!" % state.defense_industrial_index,
			"TREASURY / PENTAGON ACQUISITION: 'Defense Production Act Title III invoked; Lockheed, Anduril, and Rheinmetall assembly lines running 24/7 triple shifts.'")
		step(state, 0.0)
		return {
			"ok": true,
			"action_code": action_code,
			"budget_musd": state.blue_budget_available_musd,
			"defense_industrial_index": state.defense_industrial_index,
		}

	elif action_code == HOMEFRONT_ENFORCE_SURGICAL_ROE:
		state.surgical_roe_enforced = true
		state.un_war_crimes_investigation_level = 0
		state.blue_public_support_pct = clampf(state.blue_public_support_pct + 14.0, 0.0, 99.0)
		state.blue_budget_available_musd += 220.0
		BudgetTechSystemScript.add_escalation(state, sim_db, -6.0,
			"STRICT SURGICAL PRECISION ROE ENFORCED: UN War Crimes Tribunal cleared; Domestic Support rose to %d%% (+$220M Allied Grant)!" % int(state.blue_public_support_pct),
			"JAG / WHITE HOUSE NSC: 'All theater strikes restricted to verified military targets using Tier-1 Snipers, GBU-57 MOPs, and precision JDAMs.'")
		step(state, 0.0)
		return {
			"ok": true,
			"action_code": action_code,
			"blue_public_support_pct": state.blue_public_support_pct,
			"un_war_crimes_level": state.un_war_crimes_investigation_level,
		}

	elif action_code == HOMEFRONT_STRATEGIC_PETRO_RESERVE:
		state.spr_releases_count += 1
		state.global_oil_price_bbl = maxf(68.0, state.global_oil_price_bbl - 32.0)
		state.blue_income_musd_per_min += 25.0
		state.blue_public_support_pct = clampf(state.blue_public_support_pct + 6.0, 0.0, 99.0)
		BudgetTechSystemScript.add_escalation(state, sim_db, -3.0,
			"STRATEGIC PETROLEUM RESERVE RELEASED: Brent Crude cooled to $%.0f/bbl; Coalition economic output +$25M/min!" % state.global_oil_price_bbl,
			"DEPT OF ENERGY / IEA: 'Coordinated 60-million-barrel SPR release stabilized global energy markets and shipping insurance rates.'")
		step(state, 0.0)
		return {
			"ok": true,
			"action_code": action_code,
			"global_oil_price_bbl": state.global_oil_price_bbl,
			"blue_income_musd_per_min": state.blue_income_musd_per_min,
		}

	return {"ok": false, "reason": "Unknown homefront action_code"}

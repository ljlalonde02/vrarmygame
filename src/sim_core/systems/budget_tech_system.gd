class_name BudgetTechSystem
extends RefCounted
## Phase 17: Defense Budget Economy, 5-Branch R&D Technology Tree (15 Technologies),
## DEFCON 5 -> DEFCON 1 Doomsday Escalation Loop, Simulated World News & Presidential Emergency Declarations,
## and New/Apocalyptic Warfare Types (`STRIKE_TACTICAL_CBRN`, `STRIKE_HEMP_EMP`, `STRIKE_ORBITAL_RODS`, `STRIKE_THERMONUCLEAR`).

const TerrainInfrastructureSystemScript := preload("res://src/sim_core/systems/terrain_infrastructure_system.gd")

const THEATER_BUNKER_SITES := {
	"strait_theater": [
		{"name": "Hengshan Underground Command Center (Taipei)", "pos": Vector3(136.0, 0.0, -45.0)},
		{"name": "Hualien Chiashan Cavern Airbase Bunker", "pos": Vector3(154.0, 0.0, 12.0)},
		{"name": "USS Gerald R. Ford (CVN-78) Flagship CIC", "pos": Vector3(185.0, 0.0, -20.0)},
	],
	"ukraine_donbas_theater": [
		{"name": "Kyiv Bankova / Dnipro Forward Command Bunker", "pos": Vector3(-72.0, 0.0, -32.0)},
		{"name": "Lviv Carpathian Deep Underground Citadel", "pos": Vector3(-165.0, 0.0, -45.0)},
		{"name": "Odesa Black Sea Maritime Command Bunker", "pos": Vector3(-95.0, 0.0, 85.0)},
	],
	"baltic_suwalki_theater": [
		{"name": "Suwalki Multinational Corps NE Forward Bunker", "pos": Vector3(-35.0, 0.0, 52.0)},
		{"name": "Warsaw Citadel National Defense Command", "pos": Vector3(-95.0, 0.0, 110.0)},
		{"name": "Vilnius Allied Joint Force Underground HQ", "pos": Vector3(18.0, 0.0, 82.0)},
	],
	"himalaya_lac_theater": [
		{"name": "Leh XIV Corps 'Fire & Fury' Mountain Bunker", "pos": Vector3(-55.0, 0.0, 28.0)},
		{"name": "Udhampur Northern Command Underground Citadel", "pos": Vector3(-115.0, 0.0, 85.0)},
		{"name": "Daulat Beg Oldi High-Altitude Cavern Post", "pos": Vector3(-28.0, 0.0, -15.0)},
	],
	"korean_dmz_theater": [
		{"name": "Command Post TANGO (Granite Mountain Bunker, Seoul)", "pos": Vector3(-12.0, 0.0, 68.0)},
		{"name": "Gyeryongdae Tri-Service Underground HQ", "pos": Vector3(-18.0, 0.0, 135.0)},
		{"name": "Busan ROK Fleet Maritime Command Citadel", "pos": Vector3(65.0, 0.0, 175.0)},
	],
	"mexico_rio_grande_theater": [
		{"name": "Fort Cavazos III Armored Corps Command Bunker", "pos": Vector3(-42.0, 0.0, -82.0)},
		{"name": "USNORTHCOM San Antonio Joint Command Post", "pos": Vector3(-85.0, 0.0, -135.0)},
		{"name": "Fort Bliss 1st Armored Division Citadel", "pos": Vector3(-145.0, 0.0, -95.0)},
	],
	"hormuz_theater": [
		{"name": "NSA Bahrain / Al Udeid Combined Air Ops Bunker", "pos": Vector3(32.0, 0.0, -45.0)},
		{"name": "USS Abraham Lincoln (CVN-72) Flagship CIC", "pos": Vector3(85.0, 0.0, 15.0)},
		{"name": "Muscat Khasab Strait Overwatch Citadel", "pos": Vector3(48.0, 0.0, 62.0)},
	],
}


static func initialize_scenario_economy(state: WorldState, sim_db: Node, scenario_slug: String) -> void:
	var sc_info: Dictionary = sim_db.scenarios_by_slug.get(scenario_slug, {}) if sim_db != null else {}
	state.blue_budget_available_musd = float(sc_info.get("blue_budget_musd", 4500.0))
	state.red_budget_available_musd = float(sc_info.get("red_budget_musd", 4500.0))
	state.blue_income_musd_per_min = 48.0
	state.red_income_musd_per_min = 48.0
	state.blue_spent_rd_musd = 0.0
	state.blue_spent_procurement_musd = 0.0
	state.red_spent_rd_musd = 0.0
	state.red_spent_procurement_musd = 0.0
	state.blue_unlocked_techs.clear()
	state.red_unlocked_techs.clear()
	_recompute_faction_tech_modifiers(state, sim_db, WorldState.FACTION_BLUE)
	_recompute_faction_tech_modifiers(state, sim_db, WorldState.FACTION_RED)

	state.defcon_level = 4
	state.global_escalation_score = 22.0
	state.nuclear_detonations_count = 0
	state.cbrn_strikes_count = 0
	state.hemp_emp_strikes_count = 0
	state.orbital_rod_strikes_count = 0
	state.active_nuclear_fireballs.clear()
	state.world_news_feed.clear()
	_initialize_bunker_base_for_theater(state)

	var th_name := _get_theater_display_short(state.active_theater_slug)
	state.latest_presidential_declaration = (
		"PRESIDENTIAL EMERGENCY DIRECTIVE // DEFCON 4 [%s]: 'Hostile forces have initiated combat operations. Congress has authorized $%.0fM in Defense Budget funding. Unlock R&D technologies and hold the line.'" % [
			th_name, state.blue_budget_available_musd
		]
	)
	state.latest_world_news_headline = (
		"BREAKING [REUTERS / GNN]: High-intensity air, sea, and drone warfare erupts across %s; 1,000,000 global combat units placed on wartime alert." % th_name
	)
	_push_news_item(state, "REUTERS", state.latest_world_news_headline, state.defcon_level)


static func add_escalation(state: WorldState, _sim_db: Node, delta_esc: float, news_headline: String, pres_decl: String) -> void:
	state.global_escalation_score = clampf(state.global_escalation_score + delta_esc, 0.0, 100.0)
	if not news_headline.is_empty():
		state.latest_world_news_headline = news_headline
		_push_news_item(state, "GNN / C4ISR FLASH", news_headline, state.defcon_level)
	if not pres_decl.is_empty():
		state.latest_presidential_declaration = pres_decl


static func step(state: WorldState, sim_db: Node, dt_sec: float) -> void:
	if dt_sec <= 0.0:
		return

	# 1. Continuous Wartime Defense Budget Income + Combat Kill Bounties
	var mins := dt_sec / 60.0
	state.blue_budget_available_musd += state.blue_income_musd_per_min * mins
	state.red_budget_available_musd += state.red_income_musd_per_min * mins

	# 2. Automated 3D-Printed Smart Ammo Factories (`tech_automated_ammo_factories`)
	if state.blue_auto_ammo_per_min > 0 and (state.tick_id % 10 == 0):
		var add_rounds := maxi(1, int(round(float(state.blue_auto_ammo_per_min) * (dt_sec / 6.0))))
		state.blue_ammo_remaining += add_rounds
		_replenish_faction_unit_ammo(state, sim_db, WorldState.FACTION_BLUE, 2)
	if state.red_auto_ammo_per_min > 0 and (state.tick_id % 10 == 0):
		var add_r := maxi(1, int(round(float(state.red_auto_ammo_per_min) * (dt_sec / 6.0))))
		state.red_ammo_remaining += add_r
		_replenish_faction_unit_ammo(state, sim_db, WorldState.FACTION_RED, 2)

	# 3. Step Active 3D Nuclear / EMP / Orbital Fireballs & Fallout Plumes
	for i in range(state.active_nuclear_fireballs.size() - 1, -1, -1):
		var fb: Dictionary = state.active_nuclear_fireballs[i]
		var rem: float = float(fb.get("timer_sec", 0.0)) - dt_sec
		if rem <= 0.0:
			state.active_nuclear_fireballs.remove_at(i)
		else:
			fb["timer_sec"] = rem
			var max_r: float = float(fb.get("max_radius_km", 45.0))
			var cur_r: float = float(fb.get("radius_km", 5.0))
			fb["radius_km"] = lerpf(cur_r, max_r, clampf(dt_sec * 1.8, 0.0, 1.0))
			state.active_nuclear_fireballs[i] = fb

	# 4. Evaluate Conflict Escalation Pressure & DEFCON 5 -> 1 Transitions
	var combat_casualties := float(state.blue_personnel_kia + state.red_personnel_kia) * 0.002
	var combat_losses := (state.blue_lost_musd + state.red_lost_musd) * 0.002
	var space_cyber_pressure := float(state.asat_intercepts_count * 6 + state.cyber_strikes_count * 4)
	var wmd_pressure := float(state.cbrn_strikes_count * 16 + state.hemp_emp_strikes_count * 20 + state.orbital_rod_strikes_count * 22 + state.nuclear_detonations_count * 45)
	var target_esc := clampf(22.0 + combat_casualties + combat_losses + space_cyber_pressure + wmd_pressure, 0.0, 100.0)
	if target_esc > state.global_escalation_score:
		var esc_alpha := 0.45 if (wmd_pressure > 0.0 or space_cyber_pressure > 0.0) else clampf(0.08 * dt_sec, 0.01, 0.15)
		state.global_escalation_score = lerpf(state.global_escalation_score, target_esc, esc_alpha)

	_evaluate_defcon_transition(state)

	# 5. Step Physical Command Bunker Base (Proximity Threat, Kinetic Damage, Ground Capture & Game Over)
	_step_bunker_base(state, dt_sec)

	# 6. Periodic Simulated World News & OPFOR Autonomous R&D / Escalation (every 25 ticks)
	if state.tick_id > 0 and (state.tick_id % 25 == 0):
		_step_opfor_rd_and_escalation(state, sim_db)
		_generate_periodic_world_news(state)


static func _evaluate_defcon_transition(state: WorldState) -> void:
	var new_defcon := 5
	if state.global_escalation_score >= 88.0 or state.nuclear_detonations_count > 0:
		new_defcon = 1
	elif state.global_escalation_score >= 68.0 or state.cbrn_strikes_count > 0 or state.hemp_emp_strikes_count > 0:
		new_defcon = 2
	elif state.global_escalation_score >= 44.0 or state.asat_intercepts_count > 0:
		new_defcon = 3
	elif state.global_escalation_score >= 18.0:
		new_defcon = 4

	if new_defcon < state.defcon_level:
		state.defcon_level = new_defcon
		var th_name := _get_theater_display_short(state.active_theater_slug)
		var grant_musd := 0.0
		match new_defcon:
			4:
				grant_musd = 600.0
				state.latest_presidential_declaration = (
					"OVAL OFFICE ADDRESS // DEFCON 4: 'Conventional forces are fully engaged in %s. Congress has approved a $600M Emergency War Appropriation.'" % th_name
				)
				state.latest_world_news_headline = (
					"URGENT [AP / BBC]: Emergency war powers enacted as intense air-sea-land battles rage across %s." % th_name
				)
			3:
				grant_musd = 900.0
				state.blue_income_musd_per_min += 20.0
				state.red_income_musd_per_min += 20.0
				state.latest_presidential_declaration = (
					"PRESIDENTIAL EMERGENCY FLASH // DEFCON 3 ('ROUND HOUSE'): 'The conflict in %s is escalating rapidly. I have authorized Orbital ASAT, Offensive Cyber CNO, Hypersonic Salvos, and $900M in Strategic R&D funding.'" % th_name
				)
				state.latest_world_news_headline = (
					"FLASH [AL JAZEERA / REUTERS]: DEFCON 3 declared! Anti-satellite weapons and Mach-12 hypersonic missiles streaks across %s as global markets plunge." % th_name
				)
			2:
				grant_musd = 1200.0
				state.blue_income_musd_per_min += 35.0
				state.red_income_musd_per_min += 35.0
				state.latest_presidential_declaration = (
					"NATIONAL COMMAND AUTHORITY // DEFCON 2 ('FAST PACE'): 'The enemy is crossing the WMD threshold! I have signed PEAD-44 authorizing Tactical CBRN Aerosol Release, High-Altitude EMP Super-Bursts, Orbital Tungsten Rods, and $1.2B in emergency funds.'"
				)
				state.latest_world_news_headline = (
					"DOOMSDAY CLOCK AT 30 SECONDS [GNN / KYODO]: DEFCON 2! Chemical/biological hazard plumes and High-Altitude EMP bursts reported in %s; strategic nuclear forces placed on hair-trigger alert!" % th_name
				)
			1:
				grant_musd = 2000.0
				state.blue_income_musd_per_min += 60.0
				state.red_income_musd_per_min += 60.0
				state.latest_presidential_declaration = (
					"EMERGENCY ACTION MESSAGE // DEFCON 1 ('COCKED PISTOL' — NUCLEAR WAR): 'God help us all. Strategic & Tactical Thermonuclear Weapons Release (PEAD-99) is AUTHORIZED across all theaters. Launch on warning!'"
				)
				state.latest_world_news_headline = (
					"APOCALYPSE ALERT [EMERGENCY BROADCAST SYSTEM]: DEFCON 1! Thermonuclear warheads and orbital kinetic rods detonating in %s; global civilization enters uncharted escalation!" % th_name
				)

		state.blue_budget_available_musd += grant_musd
		state.red_budget_available_musd += grant_musd
		_push_news_item(state, "PRESIDENTIAL EAM", state.latest_presidential_declaration, new_defcon)
		_push_news_item(state, "WORLD WIRE", state.latest_world_news_headline, new_defcon)
		state.sim_events_queue.append({
			"type": "DEFCON_CHANGED",
			"defcon": new_defcon,
			"escalation": state.global_escalation_score,
			"declaration": state.latest_presidential_declaration,
			"headline": state.latest_world_news_headline,
		})


## Unlocks one of the 15 R&D Technology Tree nodes for `faction` if prerequisites and budget are met.
static func unlock_tech_node(state: WorldState, sim_db: Node, faction: int, tech_slug: String) -> Dictionary:
	if sim_db == null or not sim_db.tech_tree_by_slug.has(tech_slug):
		return {"ok": false, "reason": "UNKNOWN_TECH"}

	var tn: Dictionary = sim_db.tech_tree_by_slug[tech_slug]
	var unlocked_map: Dictionary = state.blue_unlocked_techs if faction == WorldState.FACTION_BLUE else state.red_unlocked_techs
	if unlocked_map.has(tech_slug):
		return {"ok": false, "reason": "ALREADY_UNLOCKED"}

	var prereq: String = String(tn.get("prereq_slug", ""))
	if not prereq.is_empty() and not unlocked_map.has(prereq):
		return {"ok": false, "reason": "MISSING_PREREQ", "prereq": prereq}

	var cost: float = float(tn.get("cost_musd", 300.0))
	var avail: float = state.blue_budget_available_musd if faction == WorldState.FACTION_BLUE else state.red_budget_available_musd
	if avail < cost:
		return {"ok": false, "reason": "INSUFFICIENT_BUDGET", "cost": cost, "available": avail}

	if faction == WorldState.FACTION_BLUE:
		state.blue_budget_available_musd -= cost
		state.blue_spent_rd_musd += cost
		state.blue_unlocked_techs[tech_slug] = true
	else:
		state.red_budget_available_musd -= cost
		state.red_spent_rd_musd += cost
		state.red_unlocked_techs[tech_slug] = true

	_recompute_faction_tech_modifiers(state, sim_db, faction)

	# Apply immediate one-shot grants from the unlocked technology
	var mods: Dictionary = tn.get("modifiers", {})
	var ammo_grant: int = int(mods.get("instant_ammo_grant", 0))
	if ammo_grant > 0:
		if faction == WorldState.FACTION_BLUE:
			state.blue_ammo_remaining += ammo_grant
			state.blue_ammo_initial_total = maxi(state.blue_ammo_initial_total, state.blue_ammo_remaining)
		else:
			state.red_ammo_remaining += ammo_grant
			state.red_ammo_initial_total = maxi(state.red_ammo_initial_total, state.red_ammo_remaining)
		_replenish_faction_unit_ammo(state, sim_db, faction, 6)

	var bonus_bays: int = int(mods.get("bonus_unmanned_bays", 0))
	if bonus_bays > 0:
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				if state.unit_unmanned_bays[uid] > 0:
					state.unit_unmanned_bays[uid] += bonus_bays

	var heal_ratio: float = float(mods.get("instant_heal_ratio", 0.0))
	if heal_ratio > 0.0:
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction:
				state.unit_hp[uid] = minf(state.unit_max_hp[uid], state.unit_hp[uid] + state.unit_max_hp[uid] * heal_ratio)

	var spawn_slug: String = String(mods.get("spawn_reinforcement_slug", ""))
	if not spawn_slug.is_empty():
		_spawn_tech_unit(state, sim_db, faction, spawn_slug, 4)

	var esc_delta: float = float(mods.get("escalation_delta", 0.0))
	if esc_delta > 0.0:
		state.global_escalation_score = clampf(state.global_escalation_score + esc_delta, 0.0, 100.0)
		_evaluate_defcon_transition(state)

	var t_name: String = String(tn.get("display_name", tech_slug))
	if faction == WorldState.FACTION_BLUE:
		var news_str := "DEFENSE R&D BREAKTHROUGH [PENTAGON / DARPA]: Coalition deploys '%s' ($%.0fM R&D) into active combat operations." % [t_name, cost]
		state.latest_world_news_headline = news_str
		_push_news_item(state, "DARPA / JOC", news_str, state.defcon_level)

	state.sim_events_queue.append({
		"type": "TECH_UNLOCKED",
		"faction": faction,
		"tech_slug": tech_slug,
		"display_name": t_name,
		"remaining_budget_musd": state.blue_budget_available_musd if faction == WorldState.FACTION_BLUE else state.red_budget_available_musd,
	})
	return {"ok": true, "tech_slug": tech_slug, "display_name": t_name, "cost_musd": cost}


static func _recompute_faction_tech_modifiers(state: WorldState, sim_db: Node, faction: int) -> void:
	var unlocked_map: Dictionary = state.blue_unlocked_techs if faction == WorldState.FACTION_BLUE else state.red_unlocked_techs
	var rcs_m := 1.0
	var rad_m := 1.0
	var mspd_m := 1.0
	var pk_b := 0.0
	var sam_b := 0.0
	var las_m := 1.0
	var dog_m := 1.0
	var dmg_m := 1.0
	var inc_rate := 48.0
	var auto_ammo := 0
	var cbrn_imm := 0
	var ew_imm := 0

	if sim_db != null:
		for t_slug in unlocked_map.keys():
			if sim_db.tech_tree_by_slug.has(t_slug):
				var mods: Dictionary = sim_db.tech_tree_by_slug[t_slug].get("modifiers", {})
				if mods.has("rcs_mult"):
					rcs_m *= float(mods["rcs_mult"])
				if mods.has("unmanned_rcs_mult"):
					rcs_m *= float(mods["unmanned_rcs_mult"])
				if mods.has("radar_range_mult"):
					rad_m *= float(mods["radar_range_mult"])
				if mods.has("missile_speed_mult"):
					mspd_m *= float(mods["missile_speed_mult"])
				if mods.has("swarm_pk_bonus"):
					pk_b += float(mods["swarm_pk_bonus"]) * 0.5
				if mods.has("air_pk_bonus"):
					pk_b += float(mods["air_pk_bonus"])
				if mods.has("missile_penetration_bonus"):
					pk_b += float(mods["missile_penetration_bonus"]) * 0.5
				if mods.has("sam_intercept_bonus"):
					sam_b += float(mods["sam_intercept_bonus"])
				if mods.has("laser_recharge_mult"):
					las_m *= float(mods["laser_recharge_mult"])
				if mods.has("dog_speed_mult"):
					dog_m *= float(mods["dog_speed_mult"])
				if mods.has("warhead_damage_mult"):
					dmg_m *= float(mods["warhead_damage_mult"])
				if mods.has("income_musd_per_min"):
					inc_rate += float(mods["income_musd_per_min"])
				if mods.has("auto_ammo_per_min"):
					auto_ammo += int(mods["auto_ammo_per_min"])
				if int(mods.get("cbrn_immunity", 0)) == 1:
					cbrn_imm = 1
				if int(mods.get("ew_jam_immunity", 0)) == 1:
					ew_imm = 1

	if faction == WorldState.FACTION_BLUE:
		state.blue_rcs_mult = rcs_m
		state.blue_radar_range_mult = rad_m
		state.blue_missile_speed_mult = mspd_m
		state.blue_pk_bonus = pk_b
		state.blue_sam_intercept_bonus = sam_b
		state.blue_laser_recharge_mult = las_m
		state.blue_dog_speed_mult = dog_m
		state.blue_warhead_damage_mult = dmg_m
		state.blue_income_musd_per_min = inc_rate
		state.blue_auto_ammo_per_min = auto_ammo
		state.blue_cbrn_immunity = cbrn_imm
		state.blue_ew_jam_immunity = ew_imm
	else:
		state.red_rcs_mult = rcs_m
		state.red_radar_range_mult = rad_m
		state.red_missile_speed_mult = mspd_m
		state.red_pk_bonus = pk_b
		state.red_sam_intercept_bonus = sam_b
		state.red_laser_recharge_mult = las_m
		state.red_dog_speed_mult = dog_m
		state.red_warhead_damage_mult = dmg_m
		state.red_income_musd_per_min = inc_rate
		state.red_auto_ammo_per_min = auto_ammo
		state.red_cbrn_immunity = cbrn_imm
		state.red_ew_jam_immunity = ew_imm


## Spends `$250M` from `faction` Defense Budget to immediately airlift `+15,000` munitions and refill unit magazines.
static func procure_emergency_ammo_airlift(state: WorldState, sim_db: Node, faction: int, cost_musd: float = 250.0, rounds_added: int = 15000) -> bool:
	var avail := state.blue_budget_available_musd if faction == WorldState.FACTION_BLUE else state.red_budget_available_musd
	if avail < cost_musd:
		return false
	if faction == WorldState.FACTION_BLUE:
		state.blue_budget_available_musd -= cost_musd
		state.blue_spent_procurement_musd += cost_musd
		state.blue_ammo_remaining += rounds_added
		state.blue_ammo_initial_total = maxi(state.blue_ammo_initial_total, state.blue_ammo_remaining)
	else:
		state.red_budget_available_musd -= cost_musd
		state.red_spent_procurement_musd += cost_musd
		state.red_ammo_remaining += rounds_added
		state.red_ammo_initial_total = maxi(state.red_ammo_initial_total, state.red_ammo_remaining)

	_replenish_faction_unit_ammo(state, sim_db, faction, 8)
	state.resupply_events_count += 1
	if faction == WorldState.FACTION_BLUE:
		var msg := "STRATEGIC AIRLIFT [USTRANSCOM]: C-17 & KC-46 airbridge delivers +%d precision munitions across theater ($%.0fM)." % [rounds_added, cost_musd]
		state.latest_world_news_headline = msg
		_push_news_item(state, "USTRANSCOM", msg, state.defcon_level)
	return true


## Spends Defense Budget to procure & deploy a new Task Force formation onto the War Table.
static func procure_reinforcement_package(state: WorldState, sim_db: Node, faction: int, package_code: String) -> int:
	if sim_db == null:
		return 0
	var cost := 350.0
	var slugs: Array = []
	var label := "Task Force"
	match package_code:
		"STEALTH_AIR_WING", "TF_STEALTH_AIR":
			cost = 450.0
			slugs = ["f_35a_lightning", "xq_58a_valkyrie", "b_21_raider", "kc_46_pegasus"]
			label = "5th-Gen Stealth & Loyal Wingman Air Wing"
		"ROBOT_DOG_ARMOR_TF", "TF_ROBOT_ARMOR":
			cost = 280.0
			slugs = ["m1a2_sepv3_platoon", "m2a4_mech_company", "vision_60_q_ugv", "fpv_fiber_swarm"]
			label = "Armored & Quadruped Robot Dog Vanguard"
		"DIRECTED_ENERGY_IADS", "TF_LASER_IADS":
			cost = 380.0
			slugs = ["mim_104f_patriot", "iron_beam_helws", "epirus_leonidas_hpm", "skynex_ahead_battery"]
			label = "Laser/HPM/Patriot Integrated Air Defense Task Force"
		"HYPERSONIC_NAVAL_TF", "TF_NAVAL_STRIKE":
			cost = 650.0
			slugs = ["dark_eagle_battery", "ddg_51_arleigh_burke", "magura_v5_usv", "orca_xluuv"]
			label = "Hypersonic & Naval Strike Task Group"
		_:
			return 0

	var avail := state.blue_budget_available_musd if faction == WorldState.FACTION_BLUE else state.red_budget_available_musd
	if avail < cost:
		return 0

	if faction == WorldState.FACTION_BLUE:
		state.blue_budget_available_musd -= cost
		state.blue_spent_procurement_musd += cost
	else:
		state.red_budget_available_musd -= cost
		state.red_spent_procurement_musd += cost

	var spawned := 0
	for s in slugs:
		spawned += _spawn_tech_unit(state, sim_db, faction, String(s), 3)

	if faction == WorldState.FACTION_BLUE and spawned > 0:
		var msg := "FORCE PROCUREMENT [PENTAGON]: %s (%d combat units, $%.0fM) deployed to active theater." % [label, spawned, cost]
		state.latest_world_news_headline = msg
		_push_news_item(state, "DEFENSE DEPT", msg, state.defcon_level)
	return spawned


## Executes one of the 4 Escalated / Apocalyptic Warfare Strikes:
## - `STRIKE_TACTICAL_CBRN` (Chemical/Biological Aerosol Plume Strike — $180M or unlocked via `tech_cbrn_aerosol_mopp5`)
## - `STRIKE_HEMP_EMP` (High-Altitude Electromagnetic Pulse Super-Burst — $320M or unlocked via `tech_hemp_orbital_emp`)
## - `STRIKE_ORBITAL_RODS` (Mach 24 Orbital Kinetic Tungsten Rods "Rods from God" — $400M or unlocked via `tech_hemp_orbital_emp`)
## - `STRIKE_THERMONUCLEAR` (PEAD-99 Tactical/Strategic Thermonuclear Warhead — $600M or unlocked via `tech_strategic_nuclear_triad`)
static func execute_escalated_warfare_strike(state: WorldState, sim_db: Node, faction: int, strike_type: String, target_pos_km: Vector3) -> Dictionary:
	var unlocked_map: Dictionary = state.blue_unlocked_techs if faction == WorldState.FACTION_BLUE else state.red_unlocked_techs
	var avail: float = state.blue_budget_available_musd if faction == WorldState.FACTION_BLUE else state.red_budget_available_musd
	var enemy_fac := WorldState.FACTION_RED if faction == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
	var th_name := _get_theater_display_short(state.active_theater_slug)

	# If target_pos_km is ZERO, pick the highest-value enemy cluster center
	var tpos := target_pos_km
	if tpos.length_squared() < 1.0:
		tpos = _find_dense_enemy_target_pos(state, enemy_fac)

	match strike_type:
		"STRIKE_TACTICAL_CBRN":
			var cost := 120.0 if unlocked_map.has("tech_cbrn_aerosol_mopp5") else 220.0
			if avail < cost:
				return {"ok": false, "reason": "INSUFFICIENT_BUDGET"}
			_deduct_budget(state, faction, cost)
			state.cbrn_strikes_count += 1
			state.global_escalation_score = clampf(state.global_escalation_score + 18.0, 0.0, 100.0)
			# Activate MOPP-4 on friendly forces and seed dense chemical/bio plume on target
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction:
					state.unit_cbrn_mopp[uid] = 1
			_inject_hazard_plume_circle(state, tpos.x, tpos.z, 68.0, 0.98)
			var casualties_inflicted := _apply_wmd_area_damage(state, sim_db, enemy_fac, tpos, 62.0, 0.42, true)
			state.active_nuclear_fireballs.append({
				"pos_km": tpos, "radius_km": 12.0, "max_radius_km": 62.0, "timer_sec": 18.0, "type": "CHEM", "faction": faction
			})
			_evaluate_defcon_transition(state)
			var headline := "CBRN FLASH [UN OPCW / REUTERS]: Tactical Chemical/Bio Aerosol warheads detonate in %s (%d casualties); toxic wind plume spreading!" % [th_name, casualties_inflicted]
			state.latest_world_news_headline = headline
			state.latest_presidential_declaration = "WHITE HOUSE SITUATION ROOM [CBRN THRESHOLD CROSSED]: 'Chemical/biological aerosols are active on the battlefield. All friendly forces ordered into MOPP-5 sealed posture!'"
			_push_news_item(state, "OPCW / GNN", headline, state.defcon_level)
			state.sim_events_queue.append({"type": "WMD_DETONATED", "wmd_type": "CBRN", "faction": faction, "pos_km": tpos, "yield_kt": 5.0})
			return {"ok": true, "type": "STRIKE_TACTICAL_CBRN", "casualties": casualties_inflicted, "pos_km": tpos}

		"STRIKE_HEMP_EMP":
			var cost := 200.0 if unlocked_map.has("tech_hemp_orbital_emp") else 350.0
			if avail < cost:
				return {"ok": false, "reason": "INSUFFICIENT_BUDGET"}
			_deduct_budget(state, faction, cost)
			state.hemp_emp_strikes_count += 1
			state.cyber_strikes_count += 1
			state.global_escalation_score = clampf(state.global_escalation_score + 22.0, 0.0, 100.0)
			var paralyzed := 0
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == enemy_fac:
					var d_km := Vector2(state.unit_pos[uid].x - tpos.x, state.unit_pos[uid].z - tpos.z).length()
					if d_km <= 350.0:
						state.unit_radar_active[uid] = 0
						state.unit_jammed[uid] = 1
						state.unit_cyber_timer[uid] = 65.0
						paralyzed += 1
			state.active_nuclear_fireballs.append({
				"pos_km": tpos + Vector3(0.0, 8000.0, 0.0), "radius_km": 35.0, "max_radius_km": 180.0, "timer_sec": 14.0, "type": "HEMP", "faction": faction
			})
			_evaluate_defcon_transition(state)
			var headline := "EMP BLACKOUT [BBC / AP]: Exoatmospheric High-Altitude EMP (HEMP) burst over %s blinds %d radar & drone networks across 350 km!" % [th_name, paralyzed]
			state.latest_world_news_headline = headline
			state.latest_presidential_declaration = "STRATCOM FLASH // HEMP DETONATION: 'High-Altitude Electromagnetic Pulse has crippled enemy IADS and C2 grids across 350 km. Launch immediate exploitation strikes!'"
			_push_news_item(state, "USSTRATCOM", headline, state.defcon_level)
			state.sim_events_queue.append({"type": "WMD_DETONATED", "wmd_type": "HEMP", "faction": faction, "pos_km": tpos, "yield_kt": 50.0})
			return {"ok": true, "type": "STRIKE_HEMP_EMP", "paralyzed_units": paralyzed, "pos_km": tpos}

		"STRIKE_ORBITAL_RODS":
			var cost := 250.0 if unlocked_map.has("tech_hemp_orbital_emp") else 420.0
			if avail < cost:
				return {"ok": false, "reason": "INSUFFICIENT_BUDGET"}
			_deduct_budget(state, faction, cost)
			state.orbital_rod_strikes_count += 1
			state.global_escalation_score = clampf(state.global_escalation_score + 24.0, 0.0, 100.0)
			# Spawn live Mach-24 (8.232 km/s) Orbital Kinetic Tungsten Rod munition descending from 550 km LEO orbit!
			var rod_wid: int = int(sim_db.weapon_id_by_slug.get("orbital_tungsten_rod", 0)) if sim_db != null else 0
			var rod_mid := -1
			if rod_wid > 0:
				rod_mid = state.spawn_munition(
					faction,
					rod_wid,
					-1,
					-1,
					Vector3(tpos.x - 45.0, 550000.0, tpos.z - 25.0),
					tpos,
					"ORBITAL_KINETIC_ROD"
				)
			state.inject_war_destruction(tpos.x, tpos.z, 48.0, 0.92)
			var cas_rod := _apply_wmd_area_damage(state, sim_db, enemy_fac, tpos, 52.0, 0.78, false)
			state.active_nuclear_fireballs.append({
				"pos_km": tpos, "radius_km": 10.0, "max_radius_km": 52.0, "timer_sec": 12.0, "type": "ORBITAL", "faction": faction
			})
			state.active_beams.append({
				"shooter_pos": Vector3(tpos.x - 45.0, 550000.0, tpos.z - 25.0),
				"target_pos": tpos,
				"is_hpm_cone": false,
				"faction": faction,
				"ttl": 4.5,
			})
			_evaluate_defcon_transition(state)
			var headline := "ORBITAL STRIKE [SPACE FORCE / KYODO]: Mach-24 (8.23 km/s) Kinetic Tungsten Rods de-orbit from 550 km LEO over %s, obliterating fortifications (%d casualties)!" % [th_name, cas_rod]
			state.latest_world_news_headline = headline
			_push_news_item(state, "SPACECOM", headline, state.defcon_level)
			state.sim_events_queue.append({"type": "WMD_DETONATED", "wmd_type": "ORBITAL_RODS", "faction": faction, "pos_km": tpos, "yield_kt": 15.0})
			return {"ok": true, "type": "STRIKE_ORBITAL_RODS", "casualties": cas_rod, "pos_km": tpos, "rod_munition_id": rod_mid, "rod_speed_km_s": 8.232, "rod_release_alt_km": 550.0}

		"STRIKE_THERMONUCLEAR":
			var cost := 350.0 if unlocked_map.has("tech_strategic_nuclear_triad") else 600.0
			if avail < cost:
				return {"ok": false, "reason": "INSUFFICIENT_BUDGET"}
			_deduct_budget(state, faction, cost)
			state.nuclear_detonations_count += 1
			state.global_escalation_score = 100.0
			state.bunker_shock_tremor = 1.0
			state.inject_war_destruction(tpos.x, tpos.z, 85.0, 1.0)
			_inject_hazard_plume_circle(state, tpos.x, tpos.z, 95.0, 1.0)
			var cas_nuke := _apply_wmd_area_damage(state, sim_db, enemy_fac, tpos, 82.0, 0.96, false)
			var nuke_entry := {
				"pos_km": tpos,
				"radius_km": 18.0,
				"max_radius_km": 92.0,
				"timer_sec": 32.0,
				"max_ttl_sec": 32.0,
				"type": "NUKE",
				"faction": faction,
				"yield_kt": 350.0,
				"flash_duration": 1.2,
				"fireball_max_r_km": 16.0,
				"shockwave_max_r_km": 72.0,
				"mushroom_stem_h_km": 30.0,
				"emp_wave_max_r_km": 150.0,
			}
			state.active_nuclear_fireballs.append(nuke_entry)
			state.active_nuke_effects.append(nuke_entry)
			state.recent_impacts.append({
				"pos_km": tpos, "radius_km": 85.0, "cost_musd": 500.0, "is_intercept": false, "ttl": 8.0
			})
			_evaluate_defcon_transition(state)
			var fac_label := "COALITION STRATCOM" if faction == WorldState.FACTION_BLUE else "OPFOR STRATEGIC ROCKET FORCES"
			var headline := "THERMONUCLEAR DETONATION [DEFCON 1 // GLOBAL FLASH]: %s detonates 350-kt Thermonuclear Warhead in %s! Massive fireball, %d military casualties & radioactive fallout plume!" % [
				fac_label, th_name, cas_nuke
			]
			state.latest_world_news_headline = headline
			state.latest_presidential_declaration = (
				"PRESIDENTIAL EMERGENCY BROADCAST // DEFCON 1: 'A thermonuclear weapon has detonated in %s. Strategic nuclear retaliation and full triad operations are underway. Seek fallout shelter immediately.'" % th_name
			)
			_push_news_item(state, "DEFCON 1 FLASH", headline, 1)
			state.sim_events_queue.append({"type": "WMD_DETONATED", "wmd_type": "THERMONUCLEAR", "faction": faction, "pos_km": tpos, "yield_kt": 350.0})
			return {"ok": true, "type": "STRIKE_THERMONUCLEAR", "casualties": cas_nuke, "pos_km": tpos, "defcon": 1}

	return {"ok": false, "reason": "UNKNOWN_STRIKE_TYPE"}


static func _deduct_budget(state: WorldState, faction: int, cost: float) -> void:
	if faction == WorldState.FACTION_BLUE:
		state.blue_budget_available_musd -= cost
		state.blue_spent_procurement_musd += cost
	else:
		state.red_budget_available_musd -= cost
		state.red_spent_procurement_musd += cost


static func _apply_wmd_area_damage(state: WorldState, sim_db: Node, target_faction: int, center_km: Vector3, radius_km: float, damage_ratio: float, check_cbrn_shield: bool) -> int:
	var total_casualties := 0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_faction[uid] != target_faction:
			continue
		var d_km := Vector2(state.unit_pos[uid].x - center_km.x, state.unit_pos[uid].z - center_km.z).length()
		if d_km > radius_km:
			continue
		if check_cbrn_shield and state.unit_cbrn_mopp[uid] == 1:
			continue
		var falloff := clampf(1.0 - (d_km / maxf(1.0, radius_km)) * 0.55, 0.25, 1.0)
		var dmg := state.unit_max_hp[uid] * damage_ratio * falloff
		state.unit_hp[uid] -= dmg
		state.unit_morale[uid] = maxf(0.10, state.unit_morale[uid] - 0.45)
		var pid: int = state.unit_platform_id[uid]
		var crew: int = sim_db.plat_crew_complement[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_crew_complement.size()) else 12
		if state.unit_hp[uid] <= 0.0:
			state.unit_active[uid] = 0
			var cost_u: float = sim_db.plat_cost_musd[pid] if (sim_db != null and pid > 0 and pid < sim_db.plat_cost_musd.size()) else 25.0
			if target_faction == WorldState.FACTION_BLUE:
				state.blue_units_destroyed += 1
				state.blue_lost_musd += cost_u
				state.blue_personnel_kia += crew
			else:
				state.red_units_destroyed += 1
				state.red_lost_musd += cost_u
				state.red_personnel_kia += crew
			total_casualties += crew
		else:
			var kia := int(round(float(crew) * 0.25 * falloff))
			var wia := int(round(float(crew) * 0.45 * falloff))
			if target_faction == WorldState.FACTION_BLUE:
				state.blue_personnel_kia += kia
				state.blue_personnel_wia += wia
			else:
				state.red_personnel_kia += kia
				state.red_personnel_wia += wia
			total_casualties += kia + wia
	return total_casualties


static func _inject_hazard_plume_circle(state: WorldState, cx_km: float, cz_km: float, radius_km: float, peak_val: float) -> void:
	var grid_w := WorldState.CIV_GRID_SIZE
	if state.hazard_density.size() < grid_w * grid_w:
		return
	var half_km := 250.0
	var cell_km := 500.0 / float(grid_w)
	var active_cnt := 0
	for gz in range(grid_w):
		var wz := -half_km + (float(gz) + 0.5) * cell_km
		for gx in range(grid_w):
			var wx := -half_km + (float(gx) + 0.5) * cell_km
			var idx := gz * grid_w + gx
			var d := Vector2(wx - cx_km, wz - cz_km).length()
			if d <= radius_km:
				var add_h := peak_val * exp(-(d * d) / maxf(1.0, radius_km * radius_km * 0.42))
				state.hazard_density[idx] = clampf(state.hazard_density[idx] + add_h, 0.0, 1.0)
			if state.hazard_density[idx] > 0.02:
				active_cnt += 1
	state.active_hazard_cells_count = active_cnt


static func _find_dense_enemy_target_pos(state: WorldState, enemy_fac: int) -> Vector3:
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == enemy_fac and state.unit_echelon[uid] == WorldState.ECHELON_BRIGADE:
			return Vector3(state.unit_pos[uid].x, 0.0, state.unit_pos[uid].z)
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == enemy_fac:
			return Vector3(state.unit_pos[uid].x, 0.0, state.unit_pos[uid].z)
	return Vector3(-65.0, 0.0, 0.0) if enemy_fac == WorldState.FACTION_RED else Vector3(65.0, 0.0, 0.0)


static func _replenish_faction_unit_ammo(state: WorldState, sim_db: Node, faction: int, add_qty: int) -> void:
	var total_rem := 0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == faction and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var pid: int = state.unit_platform_id[uid]
			var cap1 := 240
			var cap2 := 240
			if sim_db != null and pid > 0 and pid < sim_db.plat_w1_qty.size():
				cap1 = maxi(sim_db.plat_w1_qty[pid] * 8, 120)
				cap2 = maxi(sim_db.plat_w2_qty[pid] * 8, 120)
			state.unit_ammo_1[uid] = mini(cap1, state.unit_ammo_1[uid] + add_qty)
			state.unit_ammo_2[uid] = mini(cap2, state.unit_ammo_2[uid] + add_qty)
			total_rem += state.unit_ammo_1[uid] + state.unit_ammo_2[uid]
	if faction == WorldState.FACTION_BLUE:
		state.blue_ammo_remaining = maxi(state.blue_ammo_remaining, total_rem)
		if total_rem > 0:
			state.blue_ammo_remaining = total_rem
		state.blue_ammo_initial_total = maxi(state.blue_ammo_initial_total, state.blue_ammo_remaining)
	else:
		state.red_ammo_remaining = maxi(state.red_ammo_remaining, total_rem)
		if total_rem > 0:
			state.red_ammo_remaining = total_rem
		state.red_ammo_initial_total = maxi(state.red_ammo_initial_total, state.red_ammo_remaining)


static func _spawn_tech_unit(state: WorldState, sim_db: Node, faction: int, slug: String, count: int) -> int:
	if sim_db == null:
		return 0
	var pid: int = sim_db.get_platform_id(slug)
	if pid <= 0:
		return 0
	var p_def: Dictionary = sim_db.get_platform(pid)
	var base_x := 95.0 if faction == WorldState.FACTION_BLUE else -95.0
	var spawned := 0
	for i in range(count):
		var sx := base_x + float((i % 2) * 8 - 4)
		var sz := -25.0 + float(i * 14)
		var uid := state.spawn_unit(faction, pid, Vector3(sx, 0.0, sz), WorldState.ECHELON_COMPANY, -1, p_def)
		if uid >= 0:
			spawned += 1
	return spawned


static func _step_opfor_rd_and_escalation(state: WorldState, sim_db: Node) -> void:
	if sim_db == null:
		return
	for tn in sim_db.tech_tree_nodes:
		var slug := String(tn.get("slug", ""))
		if not state.red_unlocked_techs.has(slug):
			var prereq := String(tn.get("prereq_slug", ""))
			if prereq.is_empty() or state.red_unlocked_techs.has(prereq):
				var cost := float(tn.get("cost_musd", 300.0))
				if state.red_budget_available_musd >= cost + 400.0:
					unlock_tech_node(state, sim_db, WorldState.FACTION_RED, slug)
					break


static func _generate_periodic_world_news(state: WorldState) -> void:
	var th_name := _get_theater_display_short(state.active_theater_slug)
	var templates := [
		["REUTERS", "GLOBAL SITREP: Casualties in %s reach %d KIA / %d WIA as over %d precision munitions are expended across the front." % [
			th_name, state.blue_personnel_kia + state.red_personnel_kia, state.blue_personnel_wia + state.red_personnel_wia, state.blue_munitions_expended + state.red_munitions_expended
		]],
		["UN OCHA", "HUMANITARIAN FLASH: %.2f Million civilians evacuating along road corridors in %s as urban infrastructure suffers %d strike impacts." % [
			float(state.total_displaced_civilians) / 1000000.0, th_name, state.active_destroyed_cells_count
		]],
		["JANE'S DEFENCE", "ECONOMIC WAR LEDGER: Equipment losses top $%.0fM Blue vs $%.0fM Red in %s; Defense Ministries rush R&D technology deployments." % [
			state.blue_lost_musd, state.red_lost_musd, th_name
		]],
		["BBC WORLD", "ESCALATION WATCH [DEFCON %d]: Global tension index at %.0f%% across 7 theaters (1,000,000 active units); diplomatic hotlines strained." % [
			state.defcon_level, state.global_escalation_score
		]],
	]
	var pick_idx := int(state.tick_id / 25) % templates.size()
	var item: Array = templates[pick_idx]
	state.latest_world_news_headline = "[%s] %s" % [String(item[0]), String(item[1])]
	_push_news_item(state, String(item[0]), String(item[1]), state.defcon_level)


static func _push_news_item(state: WorldState, agency: String, headline: String, defcon: int) -> void:
	state.world_news_feed.push_front({
		"agency": agency,
		"headline": headline,
		"defcon": defcon,
		"sim_time_sec": state.sim_time_sec,
	})
	if state.world_news_feed.size() > 16:
		state.world_news_feed.resize(16)


static func _get_theater_display_short(t_slug: String) -> String:
	if t_slug.find("ukraine") != -1:
		return "UKRAINE & BLACK SEA"
	elif t_slug.find("baltic") != -1:
		return "NATO BALTIC / SUWALKI GAP"
	elif t_slug.find("himalaya") != -1:
		return "INDIA-CHINA HIMALAYA LAC"
	elif t_slug.find("korea") != -1:
		return "KOREAN PENINSULA DMZ"
	elif t_slug.find("mexico") != -1:
		return "US-MEXICO RIO GRANDE"
	elif t_slug.find("hormuz") != -1:
		return "STRAIT OF HORMUZ"
	return "TAIWAN STRAIT & WEST PACIFIC"


static func _initialize_bunker_base_for_theater(state: WorldState) -> void:
	var sites: Array = THEATER_BUNKER_SITES.get(state.active_theater_slug, THEATER_BUNKER_SITES["strait_theater"])
	var s0: Dictionary = sites[0]
	state.bunker_alternate_index = 0
	state.bunker_relocations_count = 0
	state.bunker_base_name = String(s0.get("name", "Hengshan Underground Command Center"))
	var p: Vector3 = s0.get("pos", Vector3(136.0, 0.0, -45.0))
	p.y = maxf(0.0, state.get_terrain_elevation_m(p.x, p.z))
	state.bunker_pos_km = p
	state.bunker_max_hp = 1000.0
	state.bunker_hp = 1000.0
	state.bunker_capture_progress = 0.0
	state.bunker_nearest_enemy_dist_km = 999.0
	state.bunker_is_lost = false
	state.bunker_was_captured = false
	state.bunker_loss_reason = ""
	state.bunker_status_code = "SECURE"
	state.bunker_shock_tremor = 0.0


## Relocates the Command Bunker to either a custom theater coordinate OR cycles to the next hardened alternate command site.
static func relocate_command_bunker(state: WorldState, custom_pos_km: Vector3 = Vector3.INF, custom_name: String = "") -> Dictionary:
	if state.bunker_is_lost:
		return {"ok": false, "reason": "BUNKER_ALREADY_LOST"}

	var reloc_cost := 200.0
	if state.blue_budget_available_musd >= reloc_cost:
		state.blue_budget_available_musd -= reloc_cost
		state.blue_spent_procurement_musd += reloc_cost

	var sites: Array = THEATER_BUNKER_SITES.get(state.active_theater_slug, THEATER_BUNKER_SITES["strait_theater"])
	state.bunker_alternate_index = (state.bunker_alternate_index + 1) % sites.size()
	var next_site: Dictionary = sites[state.bunker_alternate_index]
	var new_name := custom_name if not custom_name.is_empty() else String(next_site.get("name", "Alternate Mobile Command Post"))
	var new_pos: Vector3 = custom_pos_km if custom_pos_km != Vector3.INF else next_site.get("pos", Vector3(150.0, 0.0, 0.0))
	new_pos.y = maxf(0.0, state.get_terrain_elevation_m(new_pos.x, new_pos.z))

	state.bunker_base_name = new_name
	state.bunker_pos_km = new_pos
	state.bunker_relocations_count += 1
	state.bunker_capture_progress = 0.0
	state.bunker_hp = minf(state.bunker_max_hp, state.bunker_hp + 200.0)
	state.bunker_status_code = "SECURE"

	var news_msg := "COMMAND BUNKER RELOCATED [JOC C4ISR]: Theater Command Authority transferred to '%s' (%.0f, %.0f km) via E-4B Nightwatch air-ground relay." % [
		new_name, new_pos.x, new_pos.z
	]
	state.latest_world_news_headline = news_msg
	_push_news_item(state, "JOC C4ISR", news_msg, state.defcon_level)
	state.sim_events_queue.append({
		"type": "BUNKER_RELOCATED",
		"bunker_name": new_name,
		"pos_km": new_pos,
		"relocations_count": state.bunker_relocations_count,
	})
	return {"ok": true, "bunker_name": new_name, "pos_km": new_pos, "relocations_count": state.bunker_relocations_count}


## Inflicts kinetic/WMD damage or ground-assault capture progress on the Command Bunker; triggers GAME OVER if destroyed or captured.
static func damage_or_capture_command_bunker(state: WorldState, damage_hp: float, capture_delta: float, cause_desc: String = "OPFOR Strike on Command Bunker") -> bool:
	if state.bunker_is_lost:
		return true

	if damage_hp > 0.0:
		state.bunker_hp = maxf(0.0, state.bunker_hp - damage_hp)
		state.bunker_shock_tremor = clampf(state.bunker_shock_tremor + clampf(damage_hp / 180.0, 0.25, 1.0), 0.0, 1.0)
	if capture_delta > 0.0:
		state.bunker_capture_progress = clampf(state.bunker_capture_progress + capture_delta, 0.0, 100.0)

	if state.bunker_hp <= 0.0 or state.bunker_capture_progress >= 100.0:
		state.bunker_is_lost = true
		state.bunker_was_captured = (state.bunker_capture_progress >= 100.0 and state.bunker_hp > 0.0)
		state.bunker_status_code = "LOST"
		var mode_str := "COMMAND BUNKER CAPTURED BY OPFOR ASSAULT FORCES" if state.bunker_was_captured else "COMMAND BUNKER DESTROYED BY DIRECT STRIKE"
		state.bunker_loss_reason = "%s (%s — %s)" % [mode_str, state.bunker_base_name, cause_desc]
		state.latest_presidential_declaration = "EMERGENCY FLASH // COMMAND BUNKER LOST: '%s! Theater C4ISR severed—GAME OVER!'" % state.bunker_loss_reason
		state.latest_world_news_headline = "BREAKING [GLOBAL FLASH]: %s! Allied Theater Command Post overrun!" % state.bunker_loss_reason
		_push_news_item(state, "EMERGENCY FLASH", state.latest_world_news_headline, 1)
		state.sim_events_queue.append({
			"type": "BUNKER_GAME_OVER",
			"reason": state.bunker_loss_reason,
			"was_captured": state.bunker_was_captured,
		})
		return true

	if state.bunker_capture_progress >= 25.0:
		state.bunker_status_code = "BREACH_IN_PROGRESS"
	elif state.bunker_hp < 650.0:
		state.bunker_status_code = "UNDER_ATTACK"
	return false


static func _step_bunker_base(state: WorldState, dt_sec: float) -> void:
	state.bunker_shock_tremor = maxf(0.0, state.bunker_shock_tremor - dt_sec * 1.1)
	if state.bunker_is_lost:
		return

	var bpos := state.bunker_pos_km
	var min_enemy_d_sq := 999999.0
	var enemy_in_breach := 0
	var friendly_defenders := 0

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var up := state.unit_pos[uid]
		var dx := up.x - bpos.x
		var dz := up.z - bpos.z
		var d_sq := dx * dx + dz * dz
		if state.unit_faction[uid] == WorldState.FACTION_RED:
			if d_sq < min_enemy_d_sq:
				min_enemy_d_sq = d_sq
			if d_sq <= 18.0 * 18.0 and up.y < 600.0:
				enemy_in_breach += 1
		else:
			if d_sq <= 22.0 * 22.0:
				friendly_defenders += 1

	state.bunker_nearest_enemy_dist_km = sqrt(min_enemy_d_sq)

	# Check recent missile/bomb impacts near the Command Bunker (within 14 km)
	for imp in state.recent_impacts:
		var ip: Vector3 = imp.get("pos_km", Vector3.ZERO)
		if not bool(imp.get("is_intercept", false)) and not bool(imp.get("bunker_counted", false)):
			var d_imp := Vector2(ip.x - bpos.x, ip.z - bpos.z).length()
			if d_imp <= 14.0:
				imp["bunker_counted"] = true
				damage_or_capture_command_bunker(state, 65.0, 0.0, "Direct Missile Salvo on Command Bunker")
				if state.bunker_is_lost:
					return

	if enemy_in_breach > friendly_defenders:
		var cap_rate := float(enemy_in_breach - friendly_defenders) * 2.5 * dt_sec
		var dmg_rate := float(enemy_in_breach) * 4.0 * dt_sec
		damage_or_capture_command_bunker(state, dmg_rate, cap_rate, "OPFOR Ground Assault Breaching Blast Doors")
	else:
		state.bunker_capture_progress = maxf(0.0, state.bunker_capture_progress - dt_sec * 2.5)
		if state.bunker_nearest_enemy_dist_km <= 45.0:
			state.bunker_status_code = "PERIMETER_ALERT"
		elif state.bunker_hp < 750.0:
			state.bunker_status_code = "UNDER_ATTACK"
		else:
			state.bunker_status_code = "SECURE"

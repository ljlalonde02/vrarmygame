class_name DiplomacySystem
extends RefCounted
## Phase 19: AI Geopolitical Diplomacy, Sovereign Airspace/Territory Access & Coalition Finance Engine.
## - Manages 18 seeded Sovereign Nations across all 5 global theaters PLUS procedurally synthesized
##   AI-Generated Sovereign States, Breakaway Republics & Defense Syndicates (`generate_ai_country()`).
## - Allows both Enemy AI (`FACTION_RED`) and Player (`FACTION_BLUE`) to conduct diplomatic summits,
##   sign Sovereign Territory & Airspace Overflight Treaties (`DIPLO_AIRSPACE_ACCESS`), receive
##   Allied Warchest Financial Grants & Lend-Lease Subsidies (`DIPLO_REQUEST_ALLY_AID`), and forge
##   Mutual Defense Alliances (`DIPLO_MILITARY_ALLIANCE`) that deploy Allied Expeditionary Task Forces.
## - Enforces Sovereign Airspace Corridors (`airspace_rect_km`) and generates live AI World News & Officer Briefings.


static func initialize_theater_diplomacy(state: WorldState, sim_db: Node, theater_slug: String) -> void:
	state.active_nations.clear()
	state.blue_allied_nations_count = 0
	state.red_allied_nations_count = 0
	state.blue_airspace_treaties_count = 0
	state.red_airspace_treaties_count = 0
	state.blue_allied_aid_received_musd = 0.0
	state.red_allied_aid_received_musd = 0.0
	state.blue_allied_income_musd_per_min = 0.0
	state.red_allied_income_musd_per_min = 0.0
	state.diplomatic_events_count = 0
	state.ai_generated_countries_count = 0
	state.airspace_violations_count = 0

	var seeded_list: Array[Dictionary] = []
	if sim_db != null and sim_db.has_method("get_sovereign_nations_for_theater"):
		seeded_list = sim_db.get_sovereign_nations_for_theater(theater_slug)

	for sn in seeded_list:
		var align := float(sn.get("initial_alignment", 0.0))
		var rx := float(sn.get("airspace_x_min_km", -200.0))
		var rz := float(sn.get("airspace_z_min_km", -200.0))
		var rw := float(sn.get("airspace_width_km", 140.0))
		var rd := float(sn.get("airspace_depth_km", 110.0))
		var n_entry := {
			"slug": String(sn.get("slug", "nation")),
			"country_name": String(sn.get("country_name", "Sovereign Nation")),
			"iso_code": String(sn.get("iso_code", "UN")),
			"capital_name": String(sn.get("capital_name", "Capital")),
			"theater_slug": theater_slug,
			"alignment": align,
			"status": _alignment_to_status(align, align >= 52.0, align <= -52.0),
			"blue_airspace_open": (align >= 45.0),
			"red_airspace_open": (align <= -45.0),
			"airspace_rect_km": Rect2(rx, rz, rw, rd),
			"aid_musd_per_min": float(sn.get("aid_musd_per_min", 20.0)),
			"grant_package_musd": float(sn.get("grant_package_musd", 400.0)),
			"expeditionary_platform_slug": String(sn.get("expeditionary_platform_slug", "f_35a_lightning")),
			"diplomatic_profile": String(sn.get("diplomatic_profile", "Regional sovereign power.")),
			"is_ai_generated": false,
			"expeditionary_deployed": false,
		}
		state.active_nations.append(n_entry)

	# Synthesize 2 initial AI-generated Geopolitical States / Regional Autonomous Blocs for dynamic replayability
	generate_ai_country(state, sim_db, false)
	generate_ai_country(state, sim_db, false)
	_recompute_diplomatic_totals(state)


static func _alignment_to_status(align: float, blue_air: bool, red_air: bool) -> String:
	if align >= 68.0:
		return "BLUE_COALITION_ALLY"
	elif align <= -68.0:
		return "RED_PACT_ALLY"
	elif blue_air and align >= 25.0:
		return "AIRSPACE_OPEN_BLUE"
	elif red_air and align <= -25.0:
		return "AIRSPACE_OPEN_RED"
	elif align >= 20.0:
		return "LEAN_BLUE"
	elif align <= -20.0:
		return "LEAN_RED"
	return "NEUTRAL"


static func _recompute_diplomatic_totals(state: WorldState) -> void:
	var b_allies := 0
	var r_allies := 0
	var b_air := 0
	var r_air := 0
	var b_inc := 0.0
	var r_inc := 0.0

	for n in state.active_nations:
		var align := float(n.get("alignment", 0.0))
		var b_open := bool(n.get("blue_airspace_open", false))
		var r_open := bool(n.get("red_airspace_open", false))
		var aid_rate := float(n.get("aid_musd_per_min", 18.0))
		n["status"] = _alignment_to_status(align, b_open, r_open)
		if b_open:
			b_air += 1
		if r_open:
			r_air += 1
		if align >= 50.0:
			b_allies += 1
			b_inc += aid_rate
		elif align <= -50.0:
			r_allies += 1
			r_inc += aid_rate

	state.blue_allied_nations_count = b_allies
	state.red_allied_nations_count = r_allies
	state.blue_airspace_treaties_count = b_air
	state.red_airspace_treaties_count = r_air
	state.blue_allied_income_musd_per_min = b_inc
	state.red_allied_income_musd_per_min = r_inc


## Procedurally synthesizes an AI-Generated Sovereign Nation, Breakaway Autonomous Zone, or Geopolitical Defense Bloc.
static func generate_ai_country(state: WorldState, sim_db: Node, broadcast_news: bool = true) -> Dictionary:
	var idx := state.ai_generated_countries_count + 1
	var t_slug := state.active_theater_slug
	var templates := [
		{
			"prefix": "Sakhalin-Kuril Maritime Directorate",
			"iso": "SKD", "cap": "Yuzhno-Kurilsk", "align": -32.0,
			"rect": Rect2(-235.0, -180.0, 125.0, 95.0), "aid": 22.0, "grant": 410.0,
			"plat": "su_57_felon", "prof": "AI-generated northern maritime enclave controlling sea-skimming missile corridors."
		},
		{
			"prefix": "Bashi-Luzon Autonomous Defense Compact",
			"iso": "BLC", "cap": "Basco Citadel", "align": 28.0,
			"rect": Rect2(45.0, 125.0, 145.0, 105.0), "aid": 20.0, "grant": 380.0,
			"plat": "f_16cj_block70", "prof": "AI-generated archipelagic air-defense authority controlling southern strait airspace."
		},
		{
			"prefix": "Kaliningrad-Baltic Free Security Zone",
			"iso": "KBZ", "cap": "Baltiysk Hub", "align": -38.0,
			"rect": Rect2(-120.0, -195.0, 130.0, 95.0), "aid": 24.0, "grant": 440.0,
			"plat": "s_400_triumf", "prof": "AI-generated fortified A2/AD coastal territory with deep SAM and EW reserves."
		},
		{
			"prefix": "Nordic-Baltic Sovereign Wealth & Drone Union",
			"iso": "NBU", "cap": "Visby-Gotland", "align": 34.0,
			"rect": Rect2(-230.0, -140.0, 125.0, 110.0), "aid": 30.0, "grant": 520.0,
			"plat": "xq_58a_valkyrie", "prof": "AI-generated high-tech sovereign fund financing autonomous CCA drone wings."
		},
		{
			"prefix": "Trans-Caspian Energy & Airbridge Republic",
			"iso": "TCR", "cap": "Aktau Port", "align": -24.0,
			"rect": Rect2(85.0, -225.0, 140.0, 105.0), "aid": 26.0, "grant": 470.0,
			"plat": "tu_22m3_backfire", "prof": "AI-generated hydrocarbon state offering strategic bomber overflight & petrodollar grants."
		},
		{
			"prefix": "Indo-Pacific Maritime Security Syndicate",
			"iso": "IMS", "cap": "Port Blair", "align": 30.0,
			"rect": Rect2(95.0, -15.0, 135.0, 115.0), "aid": 25.0, "grant": 460.0,
			"plat": "ddg_51_arleigh_burke", "prof": "AI-generated naval coalition controlling vital choke-point sea lanes & refueling depots."
		},
	]
	var pick: Dictionary = templates[(idx - 1 + int(t_slug.hash() & 0x7FFFFFFF)) % templates.size()]
	var slug := "ai_nation_%d_%s" % [idx, String(pick["iso"]).to_lower()]
	var align_val := float(pick["align"])
	var n_dict := {
		"slug": slug,
		"country_name": "%s [AI-STATE #%d]" % [String(pick["prefix"]), idx],
		"iso_code": String(pick["iso"]),
		"capital_name": String(pick["cap"]),
		"theater_slug": t_slug,
		"alignment": align_val,
		"status": _alignment_to_status(align_val, false, false),
		"blue_airspace_open": (align_val >= 48.0),
		"red_airspace_open": (align_val <= -48.0),
		"airspace_rect_km": pick["rect"],
		"aid_musd_per_min": float(pick["aid"]),
		"grant_package_musd": float(pick["grant"]),
		"expeditionary_platform_slug": String(pick["plat"]),
		"diplomatic_profile": String(pick["prof"]),
		"is_ai_generated": true,
		"expeditionary_deployed": false,
	}
	state.active_nations.append(n_dict)
	state.ai_generated_countries_count += 1
	_recompute_diplomatic_totals(state)

	if broadcast_news:
		var headline := "GEOPOLITICAL FLASH [AI DIPLOMACY ENGINE // REUTERS]: Emergent sovereign bloc '%s' (%s) declares controlled airspace corridor & $%.0fM defense fund!" % [
			String(n_dict["country_name"]), String(n_dict["iso_code"]), float(n_dict["grant_package_musd"])
		]
		state.latest_diplomatic_cable = headline
		state.latest_world_news_headline = headline
		_push_diplomatic_news(state, "UN DIPLOMATIC WIRE", headline)
	return n_dict


## Executes a Diplomatic Treaty / Action for `faction` (`FACTION_BLUE = 1` or `FACTION_RED = 2`):
## - `DIPLO_ENVOY_SUMMIT`: Shifts nation alignment by +30 toward `faction` ($120M diplomatic package)
## - `DIPLO_AIRSPACE_ACCESS`: Gains permission to access the country's sovereign territory & airspace (`blue_airspace_open` / `red_airspace_open`) + forward staging base!
## - `DIPLO_REQUEST_ALLY_AID`: Secures immediate Allied Warchest Financial Grant (`+$310M..+$620M USD`) + continuous `+$M/min` Lend-Lease income!
## - `DIPLO_MILITARY_ALLIANCE`: Forges a Mutual Defense Pact, opens airspace, grants warchest aid, and deploys an Allied Expeditionary Task Force from that country's territory!
static func execute_diplomatic_action(
	state: WorldState,
	sim_db: Node,
	faction: int,
	nation_slug: String = "",
	action_code: String = "DIPLO_MILITARY_ALLIANCE"
) -> Dictionary:
	if state.active_nations.is_empty():
		initialize_theater_diplomacy(state, sim_db, state.active_theater_slug)

	var target_idx := _resolve_target_nation_index(state, faction, nation_slug, action_code)
	if target_idx < 0 or target_idx >= state.active_nations.size():
		return {"ok": false, "reason": "NO_VALID_NATION"}

	var nation: Dictionary = state.active_nations[target_idx]
	var c_name := String(nation.get("country_name", "Sovereign Nation"))
	var iso := String(nation.get("iso_code", "UN"))
	var sign_dir := 1.0 if faction == WorldState.FACTION_BLUE else -1.0
	var fac_label := "BLUE COALITION" if faction == WorldState.FACTION_BLUE else "OPFOR RED PACT"
	var rect: Rect2 = nation.get("airspace_rect_km", Rect2(-180.0, -180.0, 120.0, 100.0))
	var center_km := Vector3(
		clampf(rect.position.x + rect.size.x * 0.5, -230.0, 230.0),
		0.0,
		clampf(rect.position.y + rect.size.y * 0.5, -230.0, 230.0)
	)

	match action_code:
		"DIPLO_ENVOY_SUMMIT":
			var cost := 120.0
			if not _try_spend_diplomatic_funds(state, faction, cost):
				# Allow emergency envoy mission even on tight budget with slightly smaller shift
				pass
			nation["alignment"] = clampf(float(nation.get("alignment", 0.0)) + sign_dir * 32.0, -100.0, 100.0)
			if faction == WorldState.FACTION_BLUE and float(nation["alignment"]) >= 35.0:
				nation["blue_airspace_open"] = true
			elif faction == WorldState.FACTION_RED and float(nation["alignment"]) <= -35.0:
				nation["red_airspace_open"] = true
			state.diplomatic_events_count += 1
			_recompute_diplomatic_totals(state)
			var msg := "DIPLOMATIC SUMMIT [%s // %s]: %s envoys sign Strategic Security & Trade Protocol in %s (Alignment: %+.0f, Status: %s)." % [
				iso, String(nation.get("capital_name", "Capital")), fac_label, c_name, float(nation["alignment"]), String(nation["status"])
			]
			_broadcast_diplomatic_event(state, faction, iso, msg, action_code)
			return {"ok": true, "action": action_code, "nation_slug": nation["slug"], "country_name": c_name, "alignment": nation["alignment"], "status": nation["status"]}

		"DIPLO_AIRSPACE_ACCESS":
			var cost := 150.0
			_try_spend_diplomatic_funds(state, faction, cost)
			nation["alignment"] = clampf(float(nation.get("alignment", 0.0)) + sign_dir * 26.0, -100.0, 100.0)
			if faction == WorldState.FACTION_BLUE:
				nation["blue_airspace_open"] = true
				nation["red_airspace_open"] = false
			else:
				nation["red_airspace_open"] = true
				nation["blue_airspace_open"] = false

			# Establish an Allied Forward Operating Airbase & Overflight Corridor inside the country's sovereign territory
			state.active_sites.append({
				"site_id": 900 + state.diplomatic_events_count,
				"theater_id": 1,
				"site_name": "%s Allied Forward Airbase (%s)" % [iso, String(nation.get("capital_name", "Base"))],
				"site_type": "AIRBASE",
				"faction_owner": "BLUE" if faction == WorldState.FACTION_BLUE else "RED",
				"x_km": center_km.x,
				"z_km": center_km.z,
				"strategic_value": 150,
				"crater_timer_sec": 0.0,
				"hp": 600.0,
			})
			# Spawn 2 forward-staged flights inside the newly opened sovereign airspace corridor
			var exp_slug := String(nation.get("expeditionary_platform_slug", "f_35a_lightning"))
			var spawned_air := _spawn_allied_expeditionary_units(state, sim_db, faction, exp_slug, center_km, 2)
			state.diplomatic_events_count += 1
			_recompute_diplomatic_totals(state)
			var msg := "SOVEREIGN AIRSPACE OPENED [%s // REUTERS]: %s grants %s full military overflight, territory transit & forward airbase rights (%d flights staged)!" % [
				iso, c_name, fac_label, spawned_air
			]
			_broadcast_diplomatic_event(state, faction, iso, msg, action_code)
			return {
				"ok": true, "action": action_code, "nation_slug": nation["slug"], "country_name": c_name,
				"blue_airspace_open": nation["blue_airspace_open"], "red_airspace_open": nation["red_airspace_open"],
				"spawned_units": spawned_air
			}

		"DIPLO_REQUEST_ALLY_AID":
			var grant_musd := float(nation.get("grant_package_musd", 420.0))
			var rate_musd := float(nation.get("aid_musd_per_min", 24.0))
			nation["alignment"] = clampf(float(nation.get("alignment", 0.0)) + sign_dir * 22.0, -100.0, 100.0)
			if faction == WorldState.FACTION_BLUE:
				nation["blue_airspace_open"] = true
				state.blue_budget_available_musd += grant_musd
				state.blue_allied_aid_received_musd += grant_musd
				state.blue_income_musd_per_min += rate_musd * 0.5
			else:
				nation["red_airspace_open"] = true
				state.red_budget_available_musd += grant_musd
				state.red_allied_aid_received_musd += grant_musd
				state.red_income_musd_per_min += rate_musd * 0.5
			state.diplomatic_events_count += 1
			_recompute_diplomatic_totals(state)
			var msg := "ALLIED WARCHEST TRANSFER [%s TREASURY // BLOOMBERG]: %s approves $%.0fM Emergency Defense Grant & +$%.0fM/min Lend-Lease credit for %s!" % [
				iso, c_name, grant_musd, rate_musd, fac_label
			]
			_broadcast_diplomatic_event(state, faction, iso, msg, action_code)
			return {
				"ok": true, "action": action_code, "nation_slug": nation["slug"], "country_name": c_name,
				"grant_musd": grant_musd, "aid_musd_per_min": rate_musd
			}

		"DIPLO_MILITARY_ALLIANCE", _:
			var grant_musd := float(nation.get("grant_package_musd", 420.0)) * 0.65
			nation["alignment"] = 85.0 if faction == WorldState.FACTION_BLUE else -85.0
			if faction == WorldState.FACTION_BLUE:
				nation["blue_airspace_open"] = true
				nation["red_airspace_open"] = false
				state.blue_budget_available_musd += grant_musd
				state.blue_allied_aid_received_musd += grant_musd
			else:
				nation["red_airspace_open"] = true
				nation["blue_airspace_open"] = false
				state.red_budget_available_musd += grant_musd
				state.red_allied_aid_received_musd += grant_musd

			var exp_slug := String(nation.get("expeditionary_platform_slug", "f_35a_lightning"))
			var spawned_tf := _spawn_allied_expeditionary_units(state, sim_db, faction, exp_slug, center_km, 6)
			nation["expeditionary_deployed"] = true
			state.diplomatic_events_count += 1
			state.global_escalation_score = clampf(state.global_escalation_score + 8.0, 0.0, 100.0)
			_recompute_diplomatic_totals(state)
			var msg := "MUTUAL DEFENSE PACT [%s // AP FLASH]: %s enters war as %s Ally! Sovereign airspace opened, +$%.0fM warchest wired & %d Expeditionary Units deployed!" % [
				iso, c_name, fac_label, grant_musd, spawned_tf
			]
			_broadcast_diplomatic_event(state, faction, iso, msg, "DIPLO_MILITARY_ALLIANCE")
			return {
				"ok": true, "action": "DIPLO_MILITARY_ALLIANCE", "nation_slug": nation["slug"], "country_name": c_name,
				"grant_musd": grant_musd, "spawned_units": spawned_tf,
				"blue_airspace_open": nation["blue_airspace_open"], "red_airspace_open": nation["red_airspace_open"]
			}


static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	if dt <= 0.0 or state.bunker_is_lost:
		return
	if state.active_nations.is_empty():
		initialize_theater_diplomacy(state, sim_db, state.active_theater_slug)

	# 1. Accrue continuous Allied Coalition / Pact Financial Subsidies (+$M/min)
	var dt_min := dt / 60.0
	if state.blue_allied_income_musd_per_min > 0.0:
		var b_add := state.blue_allied_income_musd_per_min * dt_min
		state.blue_budget_available_musd += b_add
		state.blue_allied_aid_received_musd += b_add
	if state.red_allied_income_musd_per_min > 0.0:
		var r_add := state.red_allied_income_musd_per_min * dt_min
		state.red_budget_available_musd += r_add
		state.red_allied_aid_received_musd += r_add

	# 2. Enforce Sovereign Country Airspace & Border Access every 20 ticks (2.0s)
	if (state.tick_id % 20) == 0:
		_enforce_sovereign_airspace_corridors(state)

	# 3. Autonomous Enemy (OPFOR RED) Diplomacy & AI Country Generation Loop every 90 ticks (9.0s)
	if (state.tick_id % 90) == 45:
		_step_enemy_ai_diplomacy(state, sim_db)

	# 4. Emergent AI Geopolitical State / Crisis Summit synthesis every 220 ticks (22.0s)
	if (state.tick_id % 220) == 110 and state.active_nations.size() < 9:
		generate_ai_country(state, sim_db, true)


static func _step_enemy_ai_diplomacy(state: WorldState, sim_db: Node) -> void:
	# Enemy (RED) AI strategically courts neighboring & AI-generated countries to gain airspace, money, or military alliances!
	var action_cycle := int(state.tick_id / 90) % 3
	if action_cycle == 0:
		execute_diplomatic_action(state, sim_db, WorldState.FACTION_RED, "", "DIPLO_AIRSPACE_ACCESS")
	elif action_cycle == 1:
		execute_diplomatic_action(state, sim_db, WorldState.FACTION_RED, "", "DIPLO_REQUEST_ALLY_AID")
	else:
		execute_diplomatic_action(state, sim_db, WorldState.FACTION_RED, "", "DIPLO_MILITARY_ALLIANCE")


static func _enforce_sovereign_airspace_corridors(state: WorldState) -> void:
	for n in state.active_nations:
		var rect: Rect2 = n.get("airspace_rect_km", Rect2())
		if rect.size.x <= 1.0:
			continue
		var b_open := bool(n.get("blue_airspace_open", false))
		var r_open := bool(n.get("red_airspace_open", false))
		if b_open and r_open:
			continue

		for uid in range(state.unit_count):
			if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
				continue
			var up := state.unit_pos[uid]
			if up.y < 150.0:
				continue # Check airborne flights transiting sovereign airspace
			var fac := state.unit_faction[uid]
			if fac == WorldState.FACTION_BLUE and b_open:
				continue
			if fac == WorldState.FACTION_RED and r_open:
				continue
			if rect.has_point(Vector2(up.x, up.z)):
				# Unauthorized overflight of neutral/restricted sovereign airspace!
				state.airspace_violations_count += 1
				var align_shift := -2.5 if fac == WorldState.FACTION_BLUE else 2.5
				n["alignment"] = clampf(float(n.get("alignment", 0.0)) + align_shift, -100.0, 100.0)
				# Vector violating aircraft out of restricted airspace toward theater center
				state.unit_target_pos[uid] = Vector3(up.x * 0.65, up.y, up.z * 0.65)
				state.unit_has_waypoint[uid] = 1
				break


static func _resolve_target_nation_index(state: WorldState, faction: int, nation_slug: String, action_code: String) -> int:
	if not nation_slug.is_empty() and nation_slug != "AUTO":
		for i in range(state.active_nations.size()):
			if String(state.active_nations[i].get("slug", "")) == nation_slug:
				return i

	var best_idx := 0
	var best_score := -1e9
	for i in range(state.active_nations.size()):
		var n: Dictionary = state.active_nations[i]
		var align := float(n.get("alignment", 0.0))
		var b_open := bool(n.get("blue_airspace_open", false))
		var r_open := bool(n.get("red_airspace_open", false))
		var score := 0.0
		if faction == WorldState.FACTION_BLUE:
			score = align
			if action_code == "DIPLO_AIRSPACE_ACCESS" and not b_open:
				score += 45.0
			elif action_code == "DIPLO_MILITARY_ALLIANCE" and not bool(n.get("expeditionary_deployed", false)):
				score += 35.0
		else:
			score = -align
			if action_code == "DIPLO_AIRSPACE_ACCESS" and not r_open:
				score += 45.0
			elif action_code == "DIPLO_MILITARY_ALLIANCE" and not bool(n.get("expeditionary_deployed", false)):
				score += 35.0
		if score > best_score:
			best_score = score
			best_idx = i
	return best_idx


static func _try_spend_diplomatic_funds(state: WorldState, faction: int, cost_musd: float) -> bool:
	if faction == WorldState.FACTION_BLUE:
		if state.blue_budget_available_musd >= cost_musd:
			state.blue_budget_available_musd -= cost_musd
			state.blue_spent_procurement_musd += cost_musd
			return true
	else:
		if state.red_budget_available_musd >= cost_musd:
			state.red_budget_available_musd -= cost_musd
			state.red_spent_procurement_musd += cost_musd
			return true
	return false


static func _spawn_allied_expeditionary_units(state: WorldState, sim_db: Node, faction: int, slug: String, center_km: Vector3, count: int) -> int:
	if sim_db == null:
		return 0
	var pid: int = sim_db.get_platform_id(slug)
	if pid <= 0:
		pid = sim_db.get_platform_id("f_35a_lightning" if faction == WorldState.FACTION_BLUE else "su_57_felon")
	if pid <= 0:
		return 0
	var p_def: Dictionary = sim_db.get_platform(pid)
	var bde_uid := state.spawn_unit(faction, pid, center_km, WorldState.ECHELON_BRIGADE, -1, p_def)
	var bn_uid := state.spawn_unit(faction, pid, center_km + Vector3(2.0, 0.0, 2.0), WorldState.ECHELON_BATTALION, bde_uid, p_def)
	var spawned := 0
	if bde_uid >= 0:
		spawned += 1
	if bn_uid >= 0:
		spawned += 1
	for i in range(count):
		var off := Vector3(float((i % 3) - 1) * 4.5, 0.0, float(i / 3) * 4.5)
		var co_uid := state.spawn_unit(faction, pid, center_km + off, WorldState.ECHELON_COMPANY, bn_uid, p_def)
		if co_uid >= 0:
			spawned += 1
			var enemy_x := -45.0 if faction == WorldState.FACTION_BLUE else 45.0
			state.unit_target_pos[co_uid] = Vector3(enemy_x, state.unit_pos[co_uid].y, center_km.z * 0.5)
			state.unit_has_waypoint[co_uid] = 1
	return spawned


static func _broadcast_diplomatic_event(state: WorldState, faction: int, iso: String, headline: String, action_code: String) -> void:
	state.latest_diplomatic_cable = headline
	state.latest_world_news_headline = headline
	_push_diplomatic_news(state, "DIPLOMACY // " + iso, headline)
	if faction == WorldState.FACTION_RED:
		state.latest_officer_callsign = "CAPT. ELENA ROSTOVA (AWACS MAGIC 1-1 // FEMALE)"
		state.latest_officer_gender = "FEMALE"
		state.latest_officer_transcript = headline
	else:
		state.latest_officer_callsign = "GEN. VICTORIA STERLING (STRATCOM J5 // FEMALE)"
		state.latest_officer_gender = "FEMALE"
		state.latest_officer_transcript = headline
	state.sim_events_queue.append({
		"type": "DIPLOMATIC_EVENT",
		"faction": faction,
		"iso": iso,
		"action": action_code,
		"headline": headline,
	})


static func _push_diplomatic_news(state: WorldState, agency: String, headline: String) -> void:
	state.world_news_feed.push_front({
		"agency": agency,
		"headline": headline,
		"defcon": state.defcon_level,
		"sim_time_sec": state.sim_time_sec,
	})
	if state.world_news_feed.size() > 16:
		state.world_news_feed.resize(16)

class_name CampaignPersistenceSystem
extends RefCounted
## Phase 23: Persistent Save / Load Campaign State & Custom Scenario / Force Editor.
## Serializes and restores the entire live WorldState (units, positions, HP, ammo, R&D Techs,
## Budgets, DEFCON, Weather/Solar, Diplomacy, Bunker state, and Video News history)
## to JSON slots in `res://data/saves/`, and exports custom user-created scenarios.

const SAVE_DIR_RES: String = "res://data/saves"


func ensure_save_dir() -> String:
	var abs_dir: String = ProjectSettings.globalize_path(SAVE_DIR_RES)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)
	return abs_dir


func save_campaign_slot(state: WorldState, sim_db: Node, slot_id: String = "slot_1", scenario_slug: String = "op_pacific_shield_2028") -> Dictionary:
	if state == null or sim_db == null:
		return {"ok": false, "reason": "Null state or sim_db"}

	var abs_dir: String = ensure_save_dir()
	var clean_slot: String = slot_id.strip_edges().replace(" ", "_").to_lower()
	if clean_slot.is_empty():
		clean_slot = "slot_1"
	var file_path: String = "%s/campaign_%s.json" % [abs_dir, clean_slot]

	var units_list: Array = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0:
			continue
		var pid: int = state.unit_platform_id[uid]
		var p_def: Dictionary = sim_db.get_platform(pid) if sim_db.has_method("get_platform") else {}
		var p_slug: String = String(p_def.get("slug", ""))
		var pos: Vector3 = state.unit_pos[uid]
		var vel: Vector3 = state.unit_vel[uid]
		var wp: Vector3 = state.unit_target_pos[uid]
		units_list.append({
			"uid": uid,
			"platform_id": pid,
			"platform_slug": p_slug,
			"faction": int(state.unit_faction[uid]),
			"echelon": int(state.unit_echelon[uid]),
			"parent_id": int(state.unit_parent_id[uid]),
			"pos": [pos.x, pos.y, pos.z],
			"vel": [vel.x, vel.y, vel.z],
			"heading_rad": float(state.unit_heading_rad[uid]),
			"desired_alt_m": float(state.unit_desired_alt_m[uid]),
			"hp": float(state.unit_hp[uid]),
			"max_hp": float(state.unit_max_hp[uid]),
			"morale": float(state.unit_morale[uid]),
			"fuel_km": float(state.unit_fuel_km[uid]),
			"max_fuel_km": float(state.unit_max_fuel_km[uid]),
			"energy_cap": float(state.unit_energy_cap[uid]),
			"ammo_1": int(state.unit_ammo_1[uid]),
			"ammo_2": int(state.unit_ammo_2[uid]),
			"roe": int(state.unit_roe[uid]),
			"radar_active": int(state.unit_radar_active[uid]),
			"afterburner": int(state.unit_afterburner[uid]),
			"has_waypoint": int(state.unit_has_waypoint[uid]),
			"target_pos": [wp.x, wp.y, wp.z],
			"sim_lod": int(state.unit_sim_lod[uid]) if uid < state.unit_sim_lod.size() else 0,
		})

	var save_dict: Dictionary = {
		"version": "1.0.0-phase23",
		"slot_id": clean_slot,
		"saved_unix_sec": Time.get_unix_time_from_system(),
		"scenario_slug": scenario_slug,
		"active_theater_slug": state.active_theater_slug,
		"sim_time_sec": state.sim_time_sec,
		"tick_id": state.tick_id,
		"defcon_level": state.defcon_level,
		"global_escalation_score": state.global_escalation_score,
		"nuclear_detonations_count": state.nuclear_detonations_count,
		"cbrn_strikes_count": state.cbrn_strikes_count,
		"hemp_emp_strikes_count": state.hemp_emp_strikes_count,
		"orbital_rod_strikes_count": state.orbital_rod_strikes_count,
		"asat_intercepts_count": state.asat_intercepts_count,
		"blue_budget_available_musd": state.blue_budget_available_musd,
		"red_budget_available_musd": state.red_budget_available_musd,
		"blue_income_musd_per_min": state.blue_income_musd_per_min,
		"red_income_musd_per_min": state.red_income_musd_per_min,
		"blue_spent_rd_musd": state.blue_spent_rd_musd,
		"blue_spent_procurement_musd": state.blue_spent_procurement_musd,
		"blue_unlocked_techs": state.blue_unlocked_techs.duplicate(true),
		"red_unlocked_techs": state.red_unlocked_techs.duplicate(true),
		"tech_multipliers": {
			"blue_rcs_mult": state.blue_rcs_mult,
			"red_rcs_mult": state.red_rcs_mult,
			"blue_radar_range_mult": state.blue_radar_range_mult,
			"red_radar_range_mult": state.red_radar_range_mult,
			"blue_missile_speed_mult": state.blue_missile_speed_mult,
			"red_missile_speed_mult": state.red_missile_speed_mult,
			"blue_pk_bonus": state.blue_pk_bonus,
			"red_pk_bonus": state.red_pk_bonus,
			"blue_laser_recharge_mult": state.blue_laser_recharge_mult,
			"red_laser_recharge_mult": state.red_laser_recharge_mult,
			"blue_ew_jam_immunity": state.blue_ew_jam_immunity,
			"red_ew_jam_immunity": state.red_ew_jam_immunity,
			"blue_dog_speed_mult": state.blue_dog_speed_mult,
			"red_dog_speed_mult": state.red_dog_speed_mult,
		},
		"bunker": {
			"base_name": state.bunker_base_name,
			"pos_km": [state.bunker_pos_km.x, state.bunker_pos_km.y, state.bunker_pos_km.z],
			"hp": state.bunker_hp,
			"max_hp": state.bunker_max_hp,
			"capture_progress": state.bunker_capture_progress,
			"alternate_index": state.bunker_alternate_index,
			"relocations_count": state.bunker_relocations_count,
			"is_lost": state.bunker_is_lost,
			"was_captured": state.bunker_was_captured,
			"loss_reason": state.bunker_loss_reason,
			"status_code": state.bunker_status_code,
		},
		"weather_solar": {
			"weather_condition_code": state.weather_condition_code,
			"weather_cloud_cover": state.weather_cloud_cover,
			"weather_precip_intensity": state.weather_precip_intensity,
			"sea_state_beaufort": state.sea_state_beaufort,
			"solar_hour_utc": state.solar_hour_utc,
			"is_night_cycle": state.is_night_cycle,
			"weather_ir_eo_mult": state.weather_ir_eo_mult,
			"weather_laser_mult": state.weather_laser_mult,
			"weather_usv_speed_mult": state.weather_usv_speed_mult,
			"weather_air_sortie_mult": state.weather_air_sortie_mult,
		},
		"diplomacy": {
			"active_nations": state.active_nations.duplicate(true),
			"blue_allied_nations_count": state.blue_allied_nations_count,
			"red_allied_nations_count": state.red_allied_nations_count,
			"blue_airspace_treaties_count": state.blue_airspace_treaties_count,
			"red_airspace_treaties_count": state.red_airspace_treaties_count,
			"diplomatic_events_count": state.diplomatic_events_count,
			"airspace_violations_count": state.airspace_violations_count,
		},
		"hotline": {
			"is_ringing": state.hotline_is_ringing,
			"leader_name": state.hotline_leader_name,
			"leader_title": state.hotline_leader_title,
			"demand_headline": state.hotline_demand_headline,
			"demand_body": state.hotline_demand_body,
			"ceasefire_timer_sec": state.hotline_ceasefire_timer_sec,
			"calls_received_count": state.hotline_calls_received_count,
			"negotiations_resolved_count": state.hotline_negotiations_resolved_count,
		},
		"units": units_list,
	}

	var json_text: String = JSON.stringify(save_dict, "\t")
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "reason": "Failed to open save file: " + file_path}
	f.store_string(json_text)
	f.close()

	state.saves_performed_count += 1
	state.last_saved_slot_path = file_path

	state.sim_events_queue.append({
		"type": "campaign_state_saved",
		"slot_id": clean_slot,
		"file_path": file_path,
		"units_saved": units_list.size(),
	})
	return {
		"ok": true,
		"slot_id": clean_slot,
		"file_path": file_path,
		"units_saved": units_list.size(),
	}


func load_campaign_slot(state: WorldState, sim_db: Node, slot_id: String = "slot_1") -> Dictionary:
	if state == null or sim_db == null:
		return {"ok": false, "reason": "Null state or sim_db"}

	var abs_dir: String = ensure_save_dir()
	var clean_slot: String = slot_id.strip_edges().replace(" ", "_").to_lower()
	if clean_slot.is_empty():
		clean_slot = "slot_1"
	var file_path: String = "%s/campaign_%s.json" % [abs_dir, clean_slot]

	if not FileAccess.file_exists(file_path):
		return {"ok": false, "reason": "Save file does not exist: " + file_path}

	var raw_text: String = FileAccess.get_file_as_string(file_path)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {"ok": false, "reason": "Invalid JSON in save file: " + file_path}
	var d: Dictionary = parsed

	var prev_saves: int = state.saves_performed_count
	var prev_loads: int = state.loads_performed_count
	var prev_exports: int = state.custom_scenarios_exported_count

	# Preserve heightmap while resetting dynamic arrays
	var saved_hmap: PackedFloat32Array = state.heightmap_elev_m.duplicate()
	var saved_hmap_size: int = state.heightmap_size
	var saved_hmap_path: String = state.active_heightmap_path

	state.reset()
	state.heightmap_elev_m = saved_hmap
	state.heightmap_size = saved_hmap_size
	state.active_heightmap_path = saved_hmap_path

	state.active_theater_slug = str(d.get("active_theater_slug", state.active_theater_slug))
	state.sim_time_sec = float(d.get("sim_time_sec", 0.0))
	state.tick_id = int(d.get("tick_id", 0))
	state.defcon_level = int(d.get("defcon_level", 5))
	state.global_escalation_score = float(d.get("global_escalation_score", 8.0))
	state.nuclear_detonations_count = int(d.get("nuclear_detonations_count", 0))
	state.cbrn_strikes_count = int(d.get("cbrn_strikes_count", 0))
	state.hemp_emp_strikes_count = int(d.get("hemp_emp_strikes_count", 0))
	state.orbital_rod_strikes_count = int(d.get("orbital_rod_strikes_count", 0))
	state.asat_intercepts_count = int(d.get("asat_intercepts_count", 0))

	state.blue_budget_available_musd = float(d.get("blue_budget_available_musd", 4500.0))
	state.red_budget_available_musd = float(d.get("red_budget_available_musd", 4500.0))
	state.blue_income_musd_per_min = float(d.get("blue_income_musd_per_min", 45.0))
	state.red_income_musd_per_min = float(d.get("red_income_musd_per_min", 45.0))
	state.blue_spent_rd_musd = float(d.get("blue_spent_rd_musd", 0.0))
	state.blue_spent_procurement_musd = float(d.get("blue_spent_procurement_musd", 0.0))

	var bt: Variant = d.get("blue_unlocked_techs", {})
	if bt is Dictionary:
		state.blue_unlocked_techs = bt.duplicate(true)
	var rt: Variant = d.get("red_unlocked_techs", {})
	if rt is Dictionary:
		state.red_unlocked_techs = rt.duplicate(true)

	var tm: Dictionary = d.get("tech_multipliers", {})
	state.blue_rcs_mult = float(tm.get("blue_rcs_mult", 1.0))
	state.red_rcs_mult = float(tm.get("red_rcs_mult", 1.0))
	state.blue_radar_range_mult = float(tm.get("blue_radar_range_mult", 1.0))
	state.red_radar_range_mult = float(tm.get("red_radar_range_mult", 1.0))
	state.blue_missile_speed_mult = float(tm.get("blue_missile_speed_mult", 1.0))
	state.red_missile_speed_mult = float(tm.get("red_missile_speed_mult", 1.0))
	state.blue_pk_bonus = float(tm.get("blue_pk_bonus", 0.0))
	state.red_pk_bonus = float(tm.get("red_pk_bonus", 0.0))
	state.blue_laser_recharge_mult = float(tm.get("blue_laser_recharge_mult", 1.0))
	state.red_laser_recharge_mult = float(tm.get("red_laser_recharge_mult", 1.0))
	state.blue_ew_jam_immunity = int(tm.get("blue_ew_jam_immunity", 0))
	state.red_ew_jam_immunity = int(tm.get("red_ew_jam_immunity", 0))
	state.blue_dog_speed_mult = float(tm.get("blue_dog_speed_mult", 1.0))
	state.red_dog_speed_mult = float(tm.get("red_dog_speed_mult", 1.0))

	var bk: Dictionary = d.get("bunker", {})
	state.bunker_base_name = str(bk.get("base_name", "Hengshan Underground Command Center (Taipei)"))
	var b_pos_arr: Array = bk.get("pos_km", [136.0, 0.0, -45.0])
	if b_pos_arr.size() >= 3:
		state.bunker_pos_km = Vector3(float(b_pos_arr[0]), float(b_pos_arr[1]), float(b_pos_arr[2]))
	state.bunker_hp = float(bk.get("hp", 1000.0))
	state.bunker_max_hp = float(bk.get("max_hp", 1000.0))
	state.bunker_capture_progress = float(bk.get("capture_progress", 0.0))
	state.bunker_alternate_index = int(bk.get("alternate_index", 0))
	state.bunker_relocations_count = int(bk.get("relocations_count", 0))
	state.bunker_is_lost = bool(bk.get("is_lost", false))
	state.bunker_was_captured = bool(bk.get("was_captured", false))
	state.bunker_loss_reason = str(bk.get("loss_reason", ""))
	state.bunker_status_code = str(bk.get("status_code", "SECURE"))

	var ws: Dictionary = d.get("weather_solar", {})
	state.weather_condition_code = str(ws.get("weather_condition_code", "CLEAR"))
	state.weather_cloud_cover = float(ws.get("weather_cloud_cover", 0.15))
	state.weather_precip_intensity = float(ws.get("weather_precip_intensity", 0.0))
	state.sea_state_beaufort = int(ws.get("sea_state_beaufort", 2))
	state.solar_hour_utc = float(ws.get("solar_hour_utc", 14.0))
	state.is_night_cycle = bool(ws.get("is_night_cycle", false))
	state.weather_ir_eo_mult = float(ws.get("weather_ir_eo_mult", 1.0))
	state.weather_laser_mult = float(ws.get("weather_laser_mult", 1.0))
	state.weather_usv_speed_mult = float(ws.get("weather_usv_speed_mult", 1.0))
	state.weather_air_sortie_mult = float(ws.get("weather_air_sortie_mult", 1.0))

	var dip: Dictionary = d.get("diplomacy", {})
	state.active_nations.clear()
	for n_entry in dip.get("active_nations", []):
		if n_entry is Dictionary:
			var n_copy: Dictionary = n_entry.duplicate(true)
			if not (n_copy.get("airspace_rect_km") is Rect2):
				n_copy["airspace_rect_km"] = Rect2(
					float(n_copy.get("rect_x_km", -80.0)),
					float(n_copy.get("rect_z_km", -80.0)),
					float(n_copy.get("rect_w_km", 90.0)),
					float(n_copy.get("rect_h_km", 90.0))
				)
			state.active_nations.append(n_copy)
	state.blue_allied_nations_count = int(dip.get("blue_allied_nations_count", 0))
	state.red_allied_nations_count = int(dip.get("red_allied_nations_count", 0))
	state.blue_airspace_treaties_count = int(dip.get("blue_airspace_treaties_count", 0))
	state.red_airspace_treaties_count = int(dip.get("red_airspace_treaties_count", 0))
	state.diplomatic_events_count = int(dip.get("diplomatic_events_count", 0))
	state.airspace_violations_count = int(dip.get("airspace_violations_count", 0))

	var hl: Dictionary = d.get("hotline", {})
	state.hotline_is_ringing = bool(hl.get("is_ringing", false))
	state.hotline_leader_name = str(hl.get("leader_name", ""))
	state.hotline_leader_title = str(hl.get("leader_title", ""))
	state.hotline_demand_headline = str(hl.get("demand_headline", ""))
	state.hotline_demand_body = str(hl.get("demand_body", ""))
	state.hotline_ceasefire_timer_sec = float(hl.get("ceasefire_timer_sec", 0.0))
	state.hotline_calls_received_count = int(hl.get("calls_received_count", 0))
	state.hotline_negotiations_resolved_count = int(hl.get("negotiations_resolved_count", 0))

	var units_arr: Array = d.get("units", [])
	var restored_units: int = 0
	for u_entry in units_arr:
		if not (u_entry is Dictionary):
			continue
		var ud: Dictionary = u_entry
		var p_slug: String = str(ud.get("platform_slug", ""))
		var pid: int = sim_db.get_platform_id(p_slug) if (not p_slug.is_empty() and sim_db.has_method("get_platform_id")) else int(ud.get("platform_id", 1))
		if pid <= 0:
			pid = int(ud.get("platform_id", 1))
		var p_def: Dictionary = sim_db.get_platform(pid) if sim_db.has_method("get_platform") else {}
		var pos_a: Array = ud.get("pos", [0.0, 0.0, 0.0])
		var pos_v := Vector3(float(pos_a[0]), float(pos_a[1]), float(pos_a[2])) if pos_a.size() >= 3 else Vector3.ZERO
		var uid: int = state.spawn_unit(
			int(ud.get("faction", WorldState.FACTION_BLUE)),
			pid,
			pos_v,
			int(ud.get("echelon", WorldState.ECHELON_COMPANY)),
			int(ud.get("parent_id", -1)),
			p_def
		)
		if uid >= 0:
			state.unit_pos[uid] = pos_v
			state.unit_hp[uid] = float(ud.get("hp", state.unit_max_hp[uid]))
			state.unit_max_hp[uid] = float(ud.get("max_hp", state.unit_max_hp[uid]))
			state.unit_morale[uid] = float(ud.get("morale", 1.0))
			state.unit_fuel_km[uid] = float(ud.get("fuel_km", state.unit_fuel_km[uid]))
			state.unit_max_fuel_km[uid] = float(ud.get("max_fuel_km", state.unit_max_fuel_km[uid]))
			state.unit_energy_cap[uid] = float(ud.get("energy_cap", 100.0))
			state.unit_ammo_1[uid] = int(ud.get("ammo_1", state.unit_ammo_1[uid]))
			state.unit_ammo_2[uid] = int(ud.get("ammo_2", state.unit_ammo_2[uid]))
			state.unit_roe[uid] = int(ud.get("roe", 2))
			state.unit_heading_rad[uid] = float(ud.get("heading_rad", 0.0))
			state.unit_desired_alt_m[uid] = float(ud.get("desired_alt_m", pos_v.y))
			state.unit_radar_active[uid] = int(ud.get("radar_active", 1))
			state.unit_afterburner[uid] = int(ud.get("afterburner", 0))
			state.unit_has_waypoint[uid] = int(ud.get("has_waypoint", 0))
			var wp_a: Array = ud.get("target_pos", [0.0, 0.0, 0.0])
			if wp_a.size() >= 3:
				state.unit_target_pos[uid] = Vector3(float(wp_a[0]), float(wp_a[1]), float(wp_a[2]))
			var vel_a: Array = ud.get("vel", [0.0, 0.0, 0.0])
			if vel_a.size() >= 3:
				state.unit_vel[uid] = Vector3(float(vel_a[0]), float(vel_a[1]), float(vel_a[2]))
			state.unit_sim_lod[uid] = int(ud.get("sim_lod", 0))
			restored_units += 1

	state.saves_performed_count = prev_saves
	state.loads_performed_count = prev_loads + 1
	state.custom_scenarios_exported_count = prev_exports
	state.last_saved_slot_path = file_path

	state.sim_events_queue.append({
		"type": "campaign_state_loaded",
		"slot_id": clean_slot,
		"file_path": file_path,
		"units_loaded": restored_units,
	})
	return {
		"ok": true,
		"slot_id": clean_slot,
		"file_path": file_path,
		"units_loaded": restored_units,
		"scenario_slug": str(d.get("scenario_slug", "op_pacific_shield_2028")),
	}


func spawn_custom_editor_unit(
	state: WorldState,
	sim_db: Node,
	platform_slug: String,
	faction: int,
	pos_km: Vector3
) -> int:
	if state == null or sim_db == null:
		return -1
	var pid: int = sim_db.get_platform_id(platform_slug) if sim_db.has_method("get_platform_id") else -1
	if pid <= 0:
		return -1
	var p_def: Dictionary = sim_db.get_platform(pid) if sim_db.has_method("get_platform") else {}
	var uid: int = state.spawn_unit(
		faction,
		pid,
		pos_km,
		WorldState.ECHELON_COMPANY,
		-1,
		p_def
	)
	return uid


func export_custom_scenario_json(
	state: WorldState,
	sim_db: Node,
	custom_slug: String = "op_custom_user_theater",
	custom_title: String = "Custom Commander Scenario"
) -> Dictionary:
	if state == null or sim_db == null:
		return {"ok": false, "reason": "Null state or sim_db"}

	var abs_dir: String = ensure_save_dir()
	var clean_slug: String = custom_slug.strip_edges().replace(" ", "_").to_lower()
	if clean_slug.is_empty():
		clean_slug = "op_custom_user_theater"
	var file_path: String = "%s/custom_scenario_%s.json" % [abs_dir, clean_slug]

	var orbat_units: Array = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0:
			continue
		var pid: int = state.unit_platform_id[uid]
		var p_def: Dictionary = sim_db.get_platform(pid) if sim_db.has_method("get_platform") else {}
		var p_slug: String = String(p_def.get("slug", ""))
		var pos: Vector3 = state.unit_pos[uid]
		orbat_units.append({
			"uid": uid,
			"platform_slug": p_slug,
			"faction": "BLUE" if state.unit_faction[uid] == WorldState.FACTION_BLUE else "RED",
			"echelon": int(state.unit_echelon[uid]),
			"x_km": pos.x,
			"z_km": pos.z,
			"alt_m": pos.y,
			"ammo_1": int(state.unit_ammo_1[uid]),
			"ammo_2": int(state.unit_ammo_2[uid]),
			"roe": int(state.unit_roe[uid]),
		})

	var scenario_payload: Dictionary = {
		"slug": clean_slug,
		"title": custom_title,
		"base_theater_slug": state.active_theater_slug,
		"weather_condition_code": state.weather_condition_code,
		"defcon_level": state.defcon_level,
		"exported_unix_sec": Time.get_unix_time_from_system(),
		"orbat_count": orbat_units.size(),
		"orbat_units": orbat_units,
	}

	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "reason": "Failed to write custom scenario: " + file_path}
	f.store_string(JSON.stringify(scenario_payload, "\t"))
	f.close()

	state.custom_scenarios_exported_count += 1
	return {
		"ok": true,
		"slug": clean_slug,
		"file_path": file_path,
		"orbat_count": orbat_units.size(),
	}

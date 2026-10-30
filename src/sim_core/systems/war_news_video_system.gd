class_name WarNewsVideoSystem
extends RefCounted
## Phase 20 — Live AI War News & Google Veo 3.1 Video Broadcast Engine (`WarNewsVideoSystem`).
## - Connects real-time Command Bunker simulation events (Alpha Strikes, SAM/Laser/HPM Intercepts,
##   Stealth Airstrike Runway Craters, Naval Anti-Ship Salvos, Urban Robot Dog & Armor Offensives,
##   ASAT Orbital Kills, HEMP/Cyber Grid Blackouts, CBRN Plumes, Mach-24 Orbital Tungsten Rods,
##   DEFCON 1 Thermonuclear Detonations, Diplomatic Summits, and Command Bunker Breach Alerts)
##   to 12 Google Veo 3.1 Fast (`veo-3.1-fast-generate-001`) + FFmpeg TV News Video Broadcasts.
## - Integrates with `tools/news_video_pipeline/live_news_worker.py` (Google Gemini 2.5 Flash + Veo 3.1 Fast)
##   for live AI-authored breaking news anchor scripts, chyrons, and custom video generation.

const LIVE_AI_JSON_RES_PATH := "res://data/live_ai_news_latest.json"
const VILLERA_PYTHON_EXE := "C:/Users/ljlal/Documents/GitHub/villeraengine/server/.venv/Scripts/python.exe"

const SCENARIO_OPENING_CLIP := {
	"op_pacific_shield_2028": "missile_alpha_strike",
	"op_iron_hound_ridge": "urban_armor_robot_dogs",
	"op_red_strait_swarm": "naval_carrier_strike",
	"op_korean_thunder_dmz": "sam_air_defense_intercept",
	"op_baltic_shield_suwalki": "stealth_airstrike_sortie",
	"op_himalayan_sentinel_lac": "stealth_airstrike_sortie",
	"op_ukraine_donbas_2028": "urban_armor_robot_dogs",
	"op_mexico_rio_grande_2028": "urban_armor_robot_dogs",
	"op_global_escalation_chronicle_2028": "sam_air_defense_intercept",
}


static func initialize_scenario_news_video(state: WorldState, sim_db: Node, scenario_slug: String = "") -> void:
	var open_slug: String = SCENARIO_OPENING_CLIP.get(scenario_slug, "missile_alpha_strike")
	state.news_video_history.clear()
	state.news_video_broadcasts_count = 0
	trigger_broadcast(
		state,
		sim_db,
		open_slug,
		"Theater %s active — 1,000,000 global combat troops mobilized across 7 flashpoints." % state.active_theater_slug.to_upper(),
		false,
		false
	)


static func capture_metrics_snapshot(state: WorldState) -> Dictionary:
	return {
		"nukes": state.nuclear_detonations_count,
		"rods": state.orbital_rod_strikes_count,
		"hemp": state.hemp_emp_strikes_count,
		"cbrn": state.cbrn_strikes_count,
		"asat": state.asat_intercepts_count,
		"reloc": state.bunker_relocations_count,
		"bunker_status": state.bunker_status_code,
		"diplo": state.diplomatic_events_count,
		"craters": state.craters_inflicted_count,
		"ships": state.blue_ships_lost + state.red_ships_lost,
		"intercepts": state.blue_munitions_intercepted + state.red_munitions_intercepted,
		"urban": state.blue_armor_lost + state.red_armor_lost + state.trains_derailed_count,
		"salvos": state.blue_munitions_expended + state.red_munitions_expended,
	}


static func evaluate_and_broadcast_events(
	state: WorldState,
	sim_db: Node,
	prev: Dictionary,
	last_broadcast_sim_sec: float
) -> float:
	if prev.is_empty():
		return last_broadcast_sim_sec

	# High-priority strategic & WMD events always interrupt immediately
	if state.nuclear_detonations_count > int(prev.get("nukes", 0)):
		trigger_broadcast(
			state, sim_db, "thermonuclear_detonation",
			"DEFCON 1 THERMONUCLEAR DETONATION IN %s | Total Nukes: %d | Blue KIA: %d | Red KIA: %d" % [
				state.active_theater_slug.to_upper(), state.nuclear_detonations_count, state.blue_personnel_kia, state.red_personnel_kia
			]
		)
		return state.sim_time_sec

	if state.orbital_rod_strikes_count > int(prev.get("rods", 0)):
		trigger_broadcast(
			state, sim_db, "orbital_kinetic_rods",
			"MACH-24 ORBITAL TUNGSTEN ROD DE-ORBITED FROM 550 KM LEO (8.23 km/s) IN %s" % state.active_theater_slug.to_upper()
		)
		return state.sim_time_sec

	if state.hemp_emp_strikes_count > int(prev.get("hemp", 0)):
		trigger_broadcast(
			state, sim_db, "cyber_hemp_blackout",
			"300 KM EXOATMOSPHERIC HEMP & CYBER STRIKE BLACKS OUT %s RADAR GRID" % state.active_theater_slug.to_upper()
		)
		return state.sim_time_sec

	if state.cbrn_strikes_count > int(prev.get("cbrn", 0)):
		trigger_broadcast(
			state, sim_db, "cbrn_hazard_plume",
			"TACTICAL CBRN AEROSOL PLUME RELEASED IN %s — FORCES DON MOPP-4" % state.active_theater_slug.to_upper()
		)
		return state.sim_time_sec

	if state.asat_intercepts_count > int(prev.get("asat", 0)):
		trigger_broadcast(
			state, sim_db, "asat_orbital_warfare",
			"DIRECT-ASCENT ASAT KINETIC KILL SHATTERS LEO SATELLITE AT 550 KM ALTITUDE"
		)
		return state.sim_time_sec

	if state.bunker_relocations_count > int(prev.get("reloc", 0)) or (
		state.bunker_status_code in ["UNDER_ATTACK", "BREACH_IN_PROGRESS", "LOST"]
		and String(prev.get("bunker_status", "SECURE")) != state.bunker_status_code
	):
		trigger_broadcast(
			state, sim_db, "bunker_under_attack",
			"HQ BUNKER '%s' STATUS: %s (HULL %.0f%% | CAPTURE %.0f%%)" % [
				state.bunker_base_name, state.bunker_status_code,
				(state.bunker_hp / maxf(1.0, state.bunker_max_hp)) * 100.0,
				state.bunker_capture_progress
			]
		)
		return state.sim_time_sec

	if state.diplomatic_events_count > int(prev.get("diplo", 0)):
		trigger_broadcast(
			state, sim_db, "diplomatic_alliance_summit",
			state.latest_diplomatic_cable
		)
		return state.sim_time_sec

	# Tactical combat events respect a minimum 8-second broadcast hold so videos play through cleanly
	if (state.sim_time_sec - last_broadcast_sim_sec) < 8.0:
		return last_broadcast_sim_sec

	if state.craters_inflicted_count > int(prev.get("craters", 0)):
		trigger_broadcast(
			state, sim_db, "stealth_airstrike_sortie",
			"5TH-GEN STEALTH SORTIE CRATERS STRATEGIC RUNWAY IN %s (%d Craters Inflicted)" % [
				state.active_theater_slug.to_upper(), state.craters_inflicted_count
			]
		)
		return state.sim_time_sec

	if (state.blue_ships_lost + state.red_ships_lost) > int(prev.get("ships", 0)):
		trigger_broadcast(
			state, sim_db, "naval_carrier_strike",
			"NAVAL ANTI-SHIP SALVO ENGAGEMENT IN %s | Warships Hit: Blue %d / Red %d" % [
				state.active_theater_slug.to_upper(), state.blue_ships_lost, state.red_ships_lost
			]
		)
		return state.sim_time_sec

	if (state.blue_munitions_intercepted + state.red_munitions_intercepted) >= int(prev.get("intercepts", 0)) + 6:
		trigger_broadcast(
			state, sim_db, "sam_air_defense_intercept",
			"PATRIOT PAC-3, S-400 & DIRECTED-ENERGY LASERS INTERCEPT %d MISSILES/DRONES IN %s" % [
				state.blue_munitions_intercepted + state.red_munitions_intercepted,
				state.active_theater_slug.to_upper()
			]
		)
		return state.sim_time_sec

	if (state.blue_armor_lost + state.red_armor_lost + state.trains_derailed_count) >= int(prev.get("urban", 0)) + 2:
		trigger_broadcast(
			state, sim_db, "urban_armor_robot_dogs",
			"COMBINED-ARMS ARMOR & ARMED ROBOT DOGS CLASH IN %s | Armor Lost: %d | Trains Derailed: %d" % [
				state.active_theater_slug.to_upper(),
				state.blue_armor_lost + state.red_armor_lost,
				state.trains_derailed_count
			]
		)
		return state.sim_time_sec

	if (state.blue_munitions_expended + state.red_munitions_expended) >= int(prev.get("salvos", 0)) + 14:
		trigger_broadcast(
			state, sim_db, "missile_alpha_strike",
			"MASSIVE PRECISION SALVO IN %s | Missiles Fired: Blue %d / Red %d | In-Flight: %d" % [
				state.active_theater_slug.to_upper(),
				state.blue_munitions_expended, state.red_munitions_expended,
				state.blue_munitions_in_flight + state.red_munitions_in_flight
			]
		)
		return state.sim_time_sec

	return last_broadcast_sim_sec


static func trigger_broadcast(
	state: WorldState,
	sim_db: Node,
	slug_or_trigger: String,
	custom_context: String = "",
	spawn_async_gemini_worker: bool = false,
	generate_custom_veo: bool = false
) -> Dictionary:
	var clip: Dictionary = {}
	if sim_db != null and sim_db.has_method("get_news_video_clip"):
		clip = sim_db.get_news_video_clip(slug_or_trigger)

	var slug := String(clip.get("slug", slug_or_trigger if not slug_or_trigger.is_empty() else "missile_alpha_strike"))
	var network := String(clip.get("network", "GNN GLOBAL WAR DESK"))
	var headline := String(clip.get("headline", "BREAKING WAR REPORT: MASSIVE MISSILE & AIR DEFENSE ENGAGEMENT"))
	var sub_chyron := String(clip.get("sub_chyron", "Live satellite and frontline camera feeds confirm high-intensity kinetic strikes across the theater."))
	var correspondent := String(clip.get("correspondent", "Elena Rostova — GNN War Desk"))

	if not custom_context.is_empty():
		sub_chyron = "%s — %s" % [custom_context, sub_chyron]
		sub_chyron = sub_chyron.substr(0, 175)

	var anchor_script := "[%s] %s. %s" % [network, headline, sub_chyron]

	state.active_news_video_slug = slug
	state.active_news_video_network = network
	state.active_news_video_headline = headline
	state.active_news_video_sub_chyron = sub_chyron
	state.active_news_video_correspondent = correspondent
	state.active_news_video_anchor_script = anchor_script
	state.news_video_broadcasts_count += 1

	var entry := {
		"slug": slug,
		"network": network,
		"headline": headline,
		"sub_chyron": sub_chyron,
		"correspondent": correspondent,
		"defcon": state.defcon_level,
		"sim_time_sec": state.sim_time_sec,
	}
	state.news_video_history.push_front(entry)
	if state.news_video_history.size() > 24:
		state.news_video_history.resize(24)

	state.latest_world_news_headline = "LIVE TV [%s]: %s" % [network, headline]
	state.world_news_feed.push_front({
		"agency": network,
		"headline": "%s — %s" % [headline, sub_chyron],
		"defcon": state.defcon_level,
		"time_sec": state.sim_time_sec,
		"video_slug": slug,
	})
	if state.world_news_feed.size() > 28:
		state.world_news_feed.resize(28)

	state.sim_events_queue.append({
		"type": "WAR_NEWS_VIDEO_BROADCASTED",
		"clip_slug": slug,
		"network": network,
		"headline": headline,
		"sub_chyron": sub_chyron,
		"correspondent": correspondent,
		"defcon": state.defcon_level,
	})

	if spawn_async_gemini_worker:
		launch_live_gemini_news_worker(state, slug, custom_context, generate_custom_veo, false)

	return entry


static func launch_live_gemini_news_worker(
	state: WorldState,
	slug: String = "missile_alpha_strike",
	custom_context: String = "",
	generate_custom_veo: bool = false,
	blocking: bool = false
) -> bool:
	var py_exe := VILLERA_PYTHON_EXE
	if not FileAccess.file_exists(py_exe):
		py_exe = "python"
	var worker_script := ProjectSettings.globalize_path("res://tools/news_video_pipeline/live_news_worker.py")
	if not FileAccess.file_exists(worker_script):
		return false

	var out_global := ProjectSettings.globalize_path(LIVE_AI_JSON_RES_PATH)
	var ctx := custom_context
	if ctx.is_empty():
		ctx = "Theater %s at DEFCON %d | Blue KIA %d, Red KIA %d | Missiles Fired %d, Intercepted %d | HQ Bunker %s (%s)" % [
			state.active_theater_slug, state.defcon_level,
			state.blue_personnel_kia, state.red_personnel_kia,
			state.blue_munitions_expended + state.red_munitions_expended,
			state.blue_munitions_intercepted + state.red_munitions_intercepted,
			state.bunker_base_name, state.bunker_status_code
		]

	var args: PackedStringArray = PackedStringArray([
		worker_script,
		"--theater", state.active_theater_slug,
		"--event", slug.to_upper(),
		"--defcon", str(state.defcon_level),
		"--context", ctx,
		"--slug", slug,
		"--out", out_global,
	])
	if generate_custom_veo:
		args.append("--generate-veo")

	if blocking:
		var output: Array = []
		var exit_code := OS.execute(py_exe, args, output, true)
		if exit_code == 0:
			poll_live_gemini_json(state, null, true)
			return true
		return false
	else:
		var pid := OS.create_process(py_exe, args)
		return pid > 0


static func poll_live_gemini_json(state: WorldState, sim_db: Node = null, force_apply: bool = false) -> bool:
	var global_json := ProjectSettings.globalize_path(LIVE_AI_JSON_RES_PATH)
	if not FileAccess.file_exists(global_json):
		return false
	var raw := FileAccess.get_file_as_string(global_json)
	if raw.is_empty():
		return false
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var ts := float(parsed.get("timestamp", 0.0))
	var last_ts := float(state.get_meta("last_live_ai_news_ts", 0.0)) if state.has_meta("last_live_ai_news_ts") else 0.0
	if not force_apply and ts <= last_ts:
		return false
	state.set_meta("last_live_ai_news_ts", ts)

	var slug := String(parsed.get("video_slug", state.active_news_video_slug))
	var network := String(parsed.get("network", "GNN GLOBAL WAR DESK // AI LIVE"))
	var headline := String(parsed.get("headline", state.active_news_video_headline))
	var sub_chyron := String(parsed.get("sub_chyron", state.active_news_video_sub_chyron))
	var correspondent := String(parsed.get("correspondent", state.active_news_video_correspondent))
	var anchor_script := String(parsed.get("anchor_voice_script", "%s. %s" % [headline, sub_chyron]))

	if parsed.has("custom_clip_meta") and sim_db != null and typeof(parsed["custom_clip_meta"]) == TYPE_DICTIONARY:
		var cmeta: Dictionary = parsed["custom_clip_meta"]
		sim_db.news_video_by_slug[slug] = cmeta
		sim_db.news_video_clips.push_front(cmeta)

	state.active_news_video_slug = slug
	state.active_news_video_network = network
	state.active_news_video_headline = headline
	state.active_news_video_sub_chyron = sub_chyron
	state.active_news_video_correspondent = correspondent
	state.active_news_video_anchor_script = anchor_script
	state.live_ai_gemini_bulletins_count += 1
	state.news_video_broadcasts_count += 1

	state.latest_world_news_headline = "LIVE AI TV [%s]: %s" % [network, headline]
	state.world_news_feed.push_front({
		"agency": network,
		"headline": "%s — %s" % [headline, sub_chyron],
		"defcon": state.defcon_level,
		"time_sec": state.sim_time_sec,
		"video_slug": slug,
	})
	state.sim_events_queue.append({
		"type": "WAR_NEWS_VIDEO_BROADCASTED",
		"clip_slug": slug,
		"network": network,
		"headline": headline,
		"sub_chyron": sub_chyron,
		"correspondent": correspondent,
		"defcon": state.defcon_level,
	})
	return true

class_name StoryProgressionDirector
extends CanvasLayer
## Phase 21 — 8-Mission Historical Story & Capabilities Progression Director (`StoryProgressionDirector`).
## Introduces the game, its 2028 geopolitical history, and all Command Bunker capabilities across
## 8 chronological story missions (`DEFCON 5 -> DEFCON 1`), each paired with a live Google Veo 3.1 Fast
## (`veo-3.1-fast-generate-001`) TV News Video Broadcast, Presidential Directive, Officer Radio Voice
## Callout, and interactive capability objective.

signal story_mission_changed(mission_index: int, mission_slug: String, title: String)
signal story_campaign_completed()

const STORY_MISSIONS: Array[Dictionary] = [
	{
		"mission_number": 1,
		"slug": "m01_first_radar_flash",
		"date_stamp": "OCTOBER 14, 2028 // 04:15Z",
		"defcon": 5,
		"escalation": 12.0,
		"scenario_slug": "op_pacific_shield_2028",
		"theater_slug": "strait_theater",
		"initial_zoom": 1.25,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "sam_air_defense_intercept",
		"network": "REUTERS / SKY DEFENCE",
		"news_headline": "TAIWAN STRAIT CRISIS ERUPTS: PATRIOT & LASER BATTERIES INTERCEPT OPENING DRONE SALVO",
		"news_chyron": "1,000,000 troops mobilize across 7 global flashpoints as Taipei Hengshan Command Bunker activates multi-spectral IADS radar.",
		"presidential_directive": "WHITE HOUSE SITUATION ROOM [DEFCON 5 // PEAD-01]: 'All Theater Commanders: illuminate active IADS radar grids, group your Brigades, and intercept reconnaissance salvos.'",
		"officer_id": "MAGIC_FEMALE",
		"officer_transcript": "Commander, welcome to Hengshan Underground Bunker. Flip the Master IADS Lever and press V to group an entire 36-unit Brigade.",
		"title": "MISSION 1: FIRST RADAR FLASH — C4ISR & IADS AWAKENING (TAIWAN STRAIT)",
		"capability_badge": "CAPABILITY 1/8: 6-SPECTRUM IADS RADAR, 3-TIER BRIGADE GROUPING ([B]/[V]) & REAL-TIME SPEED CONTROL",
		"history_lore": "At 04:15Z on October 14, 2028, coordinated low-RCS Shahed-136 loitering munitions and DF-17 hypersonic gliders cross the Taiwan Strait Median Line while 1,000,000 troops mobilize across 7 world flashpoints. Inside the hardened Command Bunker, you take command of the 3D Holographic War Table.",
		"objective_text": "OBJECTIVE: Flip [MASTER IADS] to illuminate 6-Spectrum Radars, press [B] or [V] to group a Battalion/Brigade, or click [EXECUTE MISSION CAPABILITY NOW].",
		"completion_events": ["CMD_SET_MASTER_IADS", "BRIGADE_OR_BATTALION_SELECTED"],
		"reward_budget_musd": 400.0,
	},
	{
		"mission_number": 2,
		"slug": "m02_iron_hound_pack",
		"date_stamp": "OCTOBER 16, 2028 // 11:40Z",
		"defcon": 4,
		"escalation": 26.0,
		"scenario_slug": "op_iron_hound_ridge",
		"theater_slug": "strait_theater",
		"initial_zoom": 7.5,
		"initial_pan_km": Vector2(128.0, 22.0),
		"video_slug": "urban_armor_robot_dogs",
		"network": "FRONTLINE LIVE",
		"news_headline": "AUTONOMOUS ROBOT DOG PACKS & FIBER-OPTIC FPV SWARMS CLASH ON 3,800M YUSHAN RIDGE",
		"news_chyron": "Krasukha-4 broadband EW jammers blind RF drones; US & ROC forces deploy LiDAR-guided Ghost Robotics Vision 60 quadrupeds.",
		"presidential_directive": "PENTAGON SPECIAL OPERATIONS DESK [DEFCON 4 // PEAD-12]: 'Enemy Krasukha-4 EW jammers are active. Authorize autonomous Quadruped Robot Dog packs and jam-proof Fiber-Optic FPV Swarms.'",
		"officer_id": "J3_MALE",
		"officer_transcript": "Heavy tanks bog down on 30-degree mountain cliffs. Press U to unpack Vision 60 Robot Dogs and Fiber-Optic FPV Swarms!",
		"title": "MISSION 2: IRON HOUND PACK — ROBOT DOGS & JAM-PROOF FPV SWARMS (YUSHAN RIDGE)",
		"capability_badge": "CAPABILITY 2/8: QUADRUPED ROBOT DOGS (3D LIDAR), FIBER-OPTIC FPV SWARMS & EW JAMMING IMMUNITY",
		"history_lore": "Forty-eight hours into the crisis, OPFOR activates 1RL257 Krasukha-4 broadband electronic warfare stations along the central mountain spine, severing RF drone links. To hold the 3,800m Yushan pass where heavy armor cannot climb >30° cliffs, you must unpack autonomous AI Quadruped Robot Dogs and 25km spool-fed Fiber-Optic FPV Swarms.",
		"objective_text": "OBJECTIVE: Press [U] (or click [DEPLOY DOGS/FPV]) to unpack Quadruped Robot Dog Packs & Fiber-Optic FPV Swarms on the mountain ridge.",
		"completion_events": ["CMD_DEPLOY_UNMANNED_SUBUNIT"],
		"reward_budget_musd": 450.0,
	},
	{
		"mission_number": 3,
		"slug": "m03_wolfpack_chokepoint",
		"date_stamp": "OCTOBER 19, 2028 // 19:05Z",
		"defcon": 4,
		"escalation": 38.0,
		"scenario_slug": "op_red_strait_swarm",
		"theater_slug": "hormuz_theater",
		"initial_zoom": 3.2,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "naval_carrier_strike",
		"network": "INDO-PACIFIC TV",
		"news_headline": "CARRIER STRIKE GROUP LAUNCHES MASSIVE VLS SALVO IN STRAIT OF HORMUZ CHOKEPOINT",
		"news_chyron": "MAGURA V5 kamikaze drone boats, Orca autonomous XLUUV submarines, and Arleigh Burke destroyers engage hostile surface flotillas.",
		"presidential_directive": "FIFTH FLEET / CENTCOM FLASH [DEFCON 4 // PEAD-19]: 'Global energy shipping is under siege in the Strait of Hormuz. Commit a coordinated Naval & Stealth Air Alpha Strike immediately.'",
		"officer_id": "J3_MALE",
		"officer_transcript": "Fifth Fleet VLS cells and MAGURA V5 naval drone wolfpacks are locked on target. Press SPACE to execute a full Alpha Strike!",
		"title": "MISSION 3: WOLFPACK CHOKEPOINT — NAVAL USV SWARMS & CARRIER ALPHA STRIKE (HORMUZ)",
		"capability_badge": "CAPABILITY 3/8: NAVAL KAMIKAZE USVs, ORCA XLUUV SUBMARINES & COORDINATED ALPHA STRIKE [SPACE]",
		"history_lore": "Seeking to split coalition naval power and choke 30% of global oil transit, OPFOR closes the Strait of Hormuz with coastal anti-ship batteries and fast attack craft. Your Carrier Strike Group, Boeing Orca autonomous submarines, and MAGURA V5 surface drone wolfpacks must execute a synchronized Time-on-Target Alpha Strike.",
		"objective_text": "OBJECTIVE: Press [SPACE] (or slam the 3D [EXECUTE ALPHA STRIKE] button on the console) to launch a theater-wide precision missile salvo.",
		"completion_events": ["CMD_COMMIT_ALPHA_STRIKE"],
		"reward_budget_musd": 550.0,
	},
	{
		"mission_number": 4,
		"slug": "m04_coalition_of_steel",
		"date_stamp": "OCTOBER 22, 2028 // 08:30Z",
		"defcon": 3,
		"escalation": 52.0,
		"scenario_slug": "op_baltic_shield_suwalki",
		"theater_slug": "baltic_suwalki_theater",
		"initial_zoom": 2.2,
		"initial_pan_km": Vector2(20.0, 10.0),
		"video_slug": "diplomatic_alliance_summit",
		"network": "WORLD DIPLOMATIC TV",
		"news_headline": "EMERGENCY NATO & U.N. SUMMIT FORGES SOVEREIGN AIRSPACE TREATIES & WARCHEST GRANTS",
		"news_chyron": "As armor clashes in the Suwalki Corridor, rival blocs race to sign Mutual Defense Pacts, open border corridors, and secure +$450M allied aid.",
		"presidential_directive": "NATIONAL SECURITY COUNCIL [DEFCON 3 // PEAD-31]: 'The war is now global. Authorize State Department envoys to lock in Sovereign Airspace Access, Allied Warchest Grants, and Mutual Defense Pacts.'",
		"officer_id": "STRATCOM_FEMALE",
		"officer_transcript": "DEFCON 3 declared. Enemy diplomats are courting neutral neighbors for airspace access. Press G to sign a Coalition Defense Pact first!",
		"title": "MISSION 4: COALITION OF STEEL — AI DIPLOMACY, SOVEREIGN AIRSPACE & ALLIED AID (SUWALKI GAP)",
		"capability_badge": "CAPABILITY 4/8: AI GEOPOLITICAL DIPLOMACY ([G]), SOVEREIGN AIRSPACE CORRIDORS & +$M ALLIED WARCHEST GRANTS",
		"history_lore": "As Russian 11th Army Corps armor pushes toward the Suwalki Corridor between Poland and Lithuania, neighboring nations become decisive kingmakers. Both sides compete in real time to sign Sovereign Airspace Treaties (opening overflight corridors & forward airbases), request +$450M Allied Warchest Grants, and deploy 6-unit Allied Expeditionary Task Forces.",
		"objective_text": "OBJECTIVE: Press [G] (or use Tab 6 Diplomacy buttons) to sign a Mutual Defense Pact / Airspace Treaty & receive Allied Warchest funds.",
		"completion_events": ["DIPLOMATIC_ACTION_EXECUTED"],
		"reward_budget_musd": 600.0,
	},
	{
		"mission_number": 5,
		"slug": "m05_arsenal_of_2030",
		"date_stamp": "OCTOBER 25, 2028 // 14:20Z",
		"defcon": 3,
		"escalation": 64.0,
		"scenario_slug": "op_ukraine_donbas_2028",
		"theater_slug": "ukraine_donbas_theater",
		"initial_zoom": 1.8,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "stealth_airstrike_sortie",
		"network": "EUROVISION WAR DESK",
		"news_headline": "DARPA & COALITION R&D LABS RUSH 300KW LASERS, NEURAL WINGMEN & SMART AMMO TO DONBAS FRONT",
		"news_chyron": "240,000 troops clash across Donbas and Azov as automated 3D-printed drone factories and stealth sorties crater strategic runways.",
		"presidential_directive": "DEFENSE PRODUCTION ACT SURGE [DEFCON 3 // PEAD-44]: 'Ammunition expenditure exceeds 10,000 rounds per day. Invest Defense Budget into the 5-Branch R&D Technology Tree and Strategic Task Forces.'",
		"officer_id": "MAGIC_FEMALE",
		"officer_transcript": "Across the 240,000-unit Ukraine front, attrition is fierce. Press K to unlock R&D Technologies and procure an Emergency Ammo Airlift!",
		"title": "MISSION 5: ARSENAL OF 2030 — DEFENSE BUDGET, 15-NODE R&D TECH TREE & LOGISTICS (UKRAINE DONBAS)",
		"capability_badge": "CAPABILITY 5/8: DEFENSE BUDGET ($M), 5-BRANCH R&D TECH TREE ([K]), AMMO AIRLIFTS & RUNWAY CRATERING",
		"history_lore": "Across the 240,000-unit Donbas and Sea of Azov front, conventional ammunition stocks are burning at historic rates. Congress invokes the Defense Production Act, streaming +$M/min into your Defense Budget so you can unlock 15 R&D Technologies (Robotics, Directed Energy, Hypersonic Stealth, C4ISR Smart Factories, NBC) and airlift emergency munitions.",
		"objective_text": "OBJECTIVE: Press [K] to open the R&D Tech Tree & Budget Deck, then unlock any R&D Technology or procure an Emergency Ammo Airlift.",
		"completion_events": ["TECH_OR_PROCUREMENT_EXECUTED"],
		"reward_budget_musd": 750.0,
	},
	{
		"mission_number": 6,
		"slug": "m06_blind_the_heavens",
		"date_stamp": "OCTOBER 28, 2028 // 22:50Z",
		"defcon": 2,
		"escalation": 78.0,
		"scenario_slug": "op_korean_thunder_dmz",
		"theater_slug": "korean_dmz_theater",
		"initial_zoom": 0.22,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "asat_orbital_warfare",
		"network": "SPACECOM TV",
		"news_headline": "WAR REACHES LOW EARTH ORBIT: ASAT INTERCEPTORS & 300KM HEMP BLACKOUTS SHATTER SATELLITE GRIDS",
		"news_chyron": "550 km LEO Starshield & SAR satellites travelling at 7.59 km/s come under direct-ascent ASAT attack as HEMP pulses blind DMZ radars.",
		"presidential_directive": "US SPACE COMMAND FLASH [DEFCON 2 // PEAD-67]: 'Hostile reconnaissance satellites at 550 km LEO are guiding KN-25 and hypersonic salvos. Authorize Direct-Ascent ASAT [7], Cyber CNO [8], and HEMP EMP strikes.'",
		"officer_id": "STRATCOM_FEMALE",
		"officer_transcript": "We are at DEFCON 2! Zoom out to the 3D Planetary Orbital Globe, track LEO satellites at 7.59 km per second, and fire an ASAT or HEMP strike!",
		"title": "MISSION 6: BLIND THE HEAVENS — ORBITAL SATELLITE WARFARE, ASAT [7], CYBER [8] & HEMP EMP (KOREAN DMZ)",
		"capability_badge": "CAPABILITY 6/8: 3D PLANETARY ORBITAL GLOBE ([O]), KEPLERIAN LEO/MEO SATELLITES, ASAT [7], CYBER [8] & HEMP EMP",
		"history_lore": "Conflict escalates to DEFCON 2 above the Korean Peninsula. Twenty-four reconnaissance, Starshield SatCom, and GPS satellites orbit the 3D Planetary Globe at realistic Keplerian speeds (525–550 km LEO at 7.59 km/s; 20,200 km MEO at 3.87 km/s). To stop enemy hypersonic targeting, you must take the war into space and the electromagnetic spectrum.",
		"objective_text": "OBJECTIVE: Press [7] for a Direct-Ascent ASAT Satellite Kill, [8] for Cyber CNO Paralysis, or click [HEMP] for an Exoatmospheric EMP Blackout.",
		"completion_events": ["SPACE_CYBER_HEMP_EXECUTED"],
		"reward_budget_musd": 850.0,
	},
	{
		"mission_number": 7,
		"slug": "m07_citadel_under_siege",
		"date_stamp": "OCTOBER 30, 2028 // 03:10Z",
		"defcon": 2,
		"escalation": 88.0,
		"scenario_slug": "op_himalayan_sentinel_lac",
		"theater_slug": "himalaya_lac_theater",
		"initial_zoom": 2.4,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "bunker_under_attack",
		"network": "PENTAGON / STRATCOM TV",
		"news_headline": "ALERT: UNDERGROUND COMMAND BUNKER TARGETED BY HYPERSONIC BUNKER-BUSTERS & CBRN PLUMES",
		"news_chyron": "Seismic shockwaves rock forward HQ citadel as E-4B Nightwatch Airborne Command Post scrambles to relocate Theater Command Authority.",
		"presidential_directive": "NATIONAL MILITARY COMMAND CENTER [DEFCON 2 // PEAD-82]: 'OPFOR has triangulated your Command Bunker coordinates! If HQ Hull drops to 0% or Capture reaches 100%, Command is lost (GAME OVER). Relocate HQ [R] now!'",
		"officer_id": "SECURITY_MALE",
		"officer_transcript": "Warning! Bunker-buster salvos and enemy breach teams are closing on our citadel! Press R immediately to relocate HQ to our alternate underground bunker!",
		"title": "MISSION 7: CITADEL UNDER SIEGE — BUNKER BREACH DEFENSE, CBRN MOPP-4 & HQ RELOCATION [R] (HIMALAYAN LAC)",
		"capability_badge": "CAPABILITY 7/8: PHYSICAL HQ BUNKER INTEGRITY, CBRN PLUME DEFENSE ([0]) & E-4B NIGHTWATCH HQ RELOCATION ([R])",
		"history_lore": "High in the 5,600m Himalayan Karakoram sector, enemy SIGINT has triangulated your physical Command Bunker on the map, launching bunker-buster missiles, tactical CBRN aerosol plumes, and Spetsnaz/Robot Dog breach teams. If your HQ Bunker is destroyed or captured, the war is lost—you must don MOPP-4 gear and relocate Command Authority to a hardened alternate citadel.",
		"objective_text": "OBJECTIVE: Press [R] (or click [[R] RELOCATE HQ]) to transfer Command Authority to a hardened alternate underground bunker and restore shields.",
		"completion_events": ["BUNKER_RELOCATED_OR_CBRN"],
		"reward_budget_musd": 950.0,
	},
	{
		"mission_number": 8,
		"slug": "m08_twilight_of_the_triad",
		"date_stamp": "NOVEMBER 01, 2028 // 00:01Z",
		"defcon": 1,
		"escalation": 100.0,
		"scenario_slug": "op_pacific_shield_2028",
		"theater_slug": "strait_theater",
		"initial_zoom": 1.35,
		"initial_pan_km": Vector2(0.0, 0.0),
		"video_slug": "thermonuclear_detonation",
		"network": "EBS EMERGENCY BROADCAST",
		"news_headline": "DEFCON 1 COCKED PISTOL: MACH-24 ORBITAL TUNGSTEN RODS & STRATEGIC THERMONUCLEAR TRIAD RELEASED",
		"news_chyron": "Emergency Broadcast System activated worldwide as Project Thor kinetic rods streak from 550 km orbit and thermonuclear fireballs rise.",
		"presidential_directive": "EMERGENCY ACTION MESSAGE [DEFCON 1 // PEAD-99]: 'The nuclear threshold has been crossed. You have full Presidential release authority for Project Thor Mach-24 Orbital Kinetic Rods [RODS] and the Thermonuclear Triad [N].'",
		"officer_id": "STRATCOM_FEMALE",
		"officer_transcript": "DEFCON 1! All bunker strobes at red lockdown! You are authorized to drop Mach 24 Orbital Tungsten Rods from 550 km space or press N for Thermonuclear release!",
		"title": "MISSION 8: TWILIGHT OF THE TRIAD — MACH-24 ORBITAL KINETIC RODS & DEFCON 1 THERMONUCLEAR DETONATION",
		"capability_badge": "CAPABILITY 8/8: PROJECT THOR MACH-24 ORBITAL TUNGSTEN RODS (8.23 km/s), DEFCON 1 NUCLEAR TRIAD ([N]) & LIVE AI GEMINI TV ([J])",
		"history_lore": "Midnight, November 1, 2028. The conflict has escalated out of control to DEFCON 1 (Cocked Pistol). The Command Bunker's bulkheads strobe crimson as the President transmits PEAD-99 Emergency Action codes. Unleash Project Thor Mach-24 Orbital Kinetic Tungsten Rods from 550 km LEO (8.232 km/s) or detonate a 350-kt Thermonuclear Warhead [N], then press [J] for a live AI Gemini 2.5 Flash broadcast of the aftermath.",
		"objective_text": "OBJECTIVE: Click [RODS] (Mach-24 Orbital Tungsten Rods) or press [N] (Thermonuclear Detonation) or [J] (Live AI Gemini TV Report) to complete the Campaign!",
		"completion_events": ["ORBITAL_RODS_OR_NUKE_OR_GEMINI"],
		"reward_budget_musd": 1500.0,
	},
]

var sim_db: Node = null
var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null
var war_table: Node3D = null
var tactile_console: Node3D = null
var radio_synth: Node = null
var desktop_rig: Node3D = null

var is_active: bool = false
var is_completed: bool = false
var current_mission_index: int = 0
var missions_completed_count: int = 0
var _anim_time: float = 0.0

var card_panel: PanelContainer = null
var video_preview_rect: TextureRect = null
var chapter_badge_label: Label = null
var network_badge_label: Label = null
var title_label: Label = null
var capability_label: Label = null
var lore_rich_label: RichTextLabel = null
var objective_label: Label = null
var progress_bar: ProgressBar = null
var execute_demo_btn: Button = null
var ai_news_btn: Button = null
var prev_mission_btn: Button = null
var next_mission_btn: Button = null
var close_btn: Button = null


func _ready() -> void:
	if card_panel != null:
		return
	layer = 19
	_build_ui()


func setup(
	p_sim_db: Node,
	p_sim_server: Node,
	p_cmd_bus: Node,
	p_sig_bus: Node,
	p_war_table: Node3D,
	p_console: Node3D = null,
	p_synth: Node = null,
	p_desktop_rig: Node3D = null
) -> void:
	sim_db = p_sim_db
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	war_table = p_war_table
	tactile_console = p_console
	radio_synth = p_synth
	desktop_rig = p_desktop_rig

	if signal_bus != null:
		if not signal_bus.master_iads_toggled.is_connected(_on_master_iads_toggled):
			signal_bus.master_iads_toggled.connect(_on_master_iads_toggled)
		if not signal_bus.unmanned_deployed.is_connected(_on_unmanned_deployed):
			signal_bus.unmanned_deployed.connect(_on_unmanned_deployed)
		if not signal_bus.alpha_strike_committed.is_connected(_on_alpha_strike_committed):
			signal_bus.alpha_strike_committed.connect(_on_alpha_strike_committed)
		if not signal_bus.diplomatic_treaty_signed.is_connected(_on_diplomatic_treaty_signed):
			signal_bus.diplomatic_treaty_signed.connect(_on_diplomatic_treaty_signed)
		if not signal_bus.tech_unlocked.is_connected(_on_tech_unlocked):
			signal_bus.tech_unlocked.connect(_on_tech_unlocked)
		if not signal_bus.strategic_wmd_detonated.is_connected(_on_strategic_wmd_detonated):
			signal_bus.strategic_wmd_detonated.connect(_on_strategic_wmd_detonated)
		if not signal_bus.bunker_relocated.is_connected(_on_bunker_relocated):
			signal_bus.bunker_relocated.connect(_on_bunker_relocated)


func start_story_campaign(mission_idx: int = 0) -> Dictionary:
	# Enforce mutual exclusivity with Bootcamp Tutorial & Main Menu modal
	var p := get_parent()
	if p != null:
		var tc: Variant = p.get("tutorial_controller")
		if tc != null and tc.has_method("stop_bootcamp"):
			tc.stop_bootcamp()
		var mm: Variant = p.get("main_menu")
		if mm != null and mm.has_method("set_menu_visible") and bool(mm.get("is_menu_open")):
			mm.set_menu_visible(false)
	is_active = true
	is_completed = false
	visible = true
	return launch_story_mission(mission_idx)


func stop_story_campaign() -> void:
	is_active = false
	visible = false


func toggle_story_campaign() -> void:
	if is_active and visible:
		stop_story_campaign()
	else:
		start_story_campaign(current_mission_index)


func get_mission_count() -> int:
	return STORY_MISSIONS.size()


func get_current_mission() -> Dictionary:
	if STORY_MISSIONS.is_empty():
		return {}
	return STORY_MISSIONS[clampi(current_mission_index, 0, STORY_MISSIONS.size() - 1)]


func launch_story_mission(mission_idx: int) -> Dictionary:
	current_mission_index = clampi(mission_idx, 0, STORY_MISSIONS.size() - 1)
	is_active = true
	is_completed = false
	visible = true

	var m: Dictionary = STORY_MISSIONS[current_mission_index]
	var scen_slug := String(m.get("scenario_slug", "op_pacific_shield_2028"))
	var zoom := float(m.get("initial_zoom", 1.25))
	var pan: Vector2 = m.get("initial_pan_km", Vector2.ZERO)

	if sim_server != null:
		if sim_server.current_scenario_slug != scen_slug or sim_server.world_state.unit_count == 0:
			sim_server.load_scenario(scen_slug)
		var ws: WorldState = sim_server.world_state
		ws.defcon_level = int(m.get("defcon", 5))
		ws.global_escalation_score = float(m.get("escalation", 12.0))
		ws.latest_presidential_declaration = String(m.get("presidential_directive", ws.latest_presidential_declaration))
		ws.blue_budget_musd += float(m.get("reward_budget_musd", 400.0))

		# Cut the Bunker 2D PiP & 3D Bulkhead TV Monitors to this mission's Google Veo 3.1 video broadcast!
		var v_slug := String(m.get("video_slug", "missile_alpha_strike"))
		var custom_ctx := "[%s] %s — %s" % [
			String(m.get("date_stamp", "2028")),
			String(m.get("news_headline", "")),
			String(m.get("news_chyron", ""))
		]
		sim_server.trigger_news_video_broadcast(v_slug, custom_ctx, false, false)
		ws.active_news_video_network = String(m.get("network", ws.active_news_video_network))
		ws.active_news_video_headline = String(m.get("news_headline", ws.active_news_video_headline))
		ws.active_news_video_sub_chyron = String(m.get("news_chyron", ws.active_news_video_sub_chyron))

	if war_table != null:
		if sim_server != null:
			war_table.bind_sim_server(sim_server)
		war_table.set_zoom_and_pan(zoom, pan, true)

	if radio_synth != null and radio_synth.has_method("speak_officer_message"):
		radio_synth.call(
			"speak_officer_message",
			String(m.get("officer_id", "MAGIC_FEMALE")),
			String(m.get("officer_transcript", "")),
			true
		)

	_refresh_ui()
	story_mission_changed.emit(current_mission_index, String(m.get("slug", "")), String(m.get("title", "")))
	return m


func notify_capability_event(event_code: String) -> void:
	if not is_active or is_completed or current_mission_index >= STORY_MISSIONS.size():
		return
	var m: Dictionary = STORY_MISSIONS[current_mission_index]
	var allowed: Array = m.get("completion_events", [])
	if allowed.has(event_code):
		advance_to_next_mission()


func advance_to_next_mission() -> void:
	missions_completed_count += 1
	if current_mission_index + 1 < STORY_MISSIONS.size():
		launch_story_mission(current_mission_index + 1)
	else:
		is_completed = true
		_refresh_ui()
		story_campaign_completed.emit()


func prev_mission() -> void:
	if current_mission_index > 0:
		launch_story_mission(current_mission_index - 1)


func execute_current_mission_capability_demo() -> void:
	if is_completed:
		stop_story_campaign()
		return
	if sim_server == null:
		return
	var m: Dictionary = get_current_mission()
	var m_num := int(m.get("mission_number", 1))
	match m_num:
		1:
			if tactile_console != null:
				tactile_console.toggle_master_iads()
			if desktop_rig != null and desktop_rig.has_method("select_brigade_of_current"):
				desktop_rig.call("select_brigade_of_current")
			notify_capability_event("CMD_SET_MASTER_IADS")
		2:
			if tactile_console != null:
				tactile_console.press_deploy_unmanned(-1)
			notify_capability_event("CMD_DEPLOY_UNMANNED_SUBUNIT")
		3:
			if tactile_console != null:
				tactile_console.press_execute_alpha_strike()
			notify_capability_event("CMD_COMMIT_ALPHA_STRIKE")
		4:
			sim_server.execute_diplomacy("DIPLO_MILITARY_ALLIANCE", "", WorldState.FACTION_BLUE)
			notify_capability_event("DIPLOMATIC_ACTION_EXECUTED")
		5:
			sim_server.unlock_tech("tech_quadruped_lidar_v2", WorldState.FACTION_BLUE)
			sim_server.procure_ammo_airlift(WorldState.FACTION_BLUE)
			notify_capability_event("TECH_OR_PROCUREMENT_EXECUTED")
		6:
			sim_server.execute_mdd_action("ORDER_ASAT_STRIKE", WorldState.FACTION_BLUE)
			sim_server.execute_escalated_strike("STRIKE_HEMP_EMP", Vector3.ZERO, WorldState.FACTION_BLUE)
			notify_capability_event("SPACE_CYBER_HEMP_EXECUTED")
		7:
			sim_server.execute_mdd_action("ORDER_CBRN_MOPP", WorldState.FACTION_BLUE)
			sim_server.relocate_bunker()
			notify_capability_event("BUNKER_RELOCATED_OR_CBRN")
		8:
			sim_server.execute_escalated_strike("STRIKE_ORBITAL_RODS", Vector3(-40.0, 0.0, 10.0), WorldState.FACTION_BLUE)
			sim_server.execute_escalated_strike("STRIKE_THERMONUCLEAR", Vector3(-65.0, 0.0, -15.0), WorldState.FACTION_BLUE)
			notify_capability_event("ORBITAL_RODS_OR_NUKE_OR_GEMINI")


func _on_master_iads_toggled(_fac: int, _en: bool) -> void:
	notify_capability_event("CMD_SET_MASTER_IADS")


func _on_unmanned_deployed(_p: int, _c: int, _sub: int, _pos: Vector3) -> void:
	notify_capability_event("CMD_DEPLOY_UNMANNED_SUBUNIT")


func _on_alpha_strike_committed(_fac: int, _cnt: int) -> void:
	notify_capability_event("CMD_COMMIT_ALPHA_STRIKE")


func _on_diplomatic_treaty_signed(_fac: int, _iso: String, _act: String, _hl: String) -> void:
	notify_capability_event("DIPLOMATIC_ACTION_EXECUTED")


func _on_tech_unlocked(_fac: int, _slug: String, _name: String, _rem: float) -> void:
	notify_capability_event("TECH_OR_PROCUREMENT_EXECUTED")


func _on_strategic_wmd_detonated(wmd_type: String, _fac: int, _pos: Vector3, _yld: float) -> void:
	if wmd_type in ["HEMP_EMP", "ASAT"]:
		notify_capability_event("SPACE_CYBER_HEMP_EXECUTED")
	elif wmd_type in ["ORBITAL_RODS", "THERMONUCLEAR", "NUKE"]:
		notify_capability_event("ORBITAL_RODS_OR_NUKE_OR_GEMINI")


func _on_bunker_relocated(_name: String, _pos: Vector3, _cnt: int) -> void:
	notify_capability_event("BUNKER_RELOCATED_OR_CBRN")


func _process(delta: float) -> void:
	if not is_active or not visible:
		return
	_anim_time += delta
	if video_preview_rect != null and sim_db != null and sim_db.has_method("get_news_video_frame_textures"):
		var m := get_current_mission()
		var v_slug := String(m.get("video_slug", "missile_alpha_strike"))
		if sim_server != null and not sim_server.world_state.active_news_video_slug.is_empty():
			v_slug = sim_server.world_state.active_news_video_slug
		var frames: Array = sim_db.get_news_video_frame_textures(v_slug)
		if not frames.is_empty():
			var idx := int(_anim_time * 6.0) % frames.size()
			video_preview_rect.texture = frames[idx]


func _refresh_ui() -> void:
	if card_panel == null:
		return
	if is_completed:
		chapter_badge_label.text = "2028 GLOBAL CHRONICLE COMPLETE (8 / 8 MISSIONS)"
		network_badge_label.text = "● ALL 8 BUNKER CAPABILITIES MASTERED // DEFCON 1"
		title_label.text = "OPERATION DOOMSDAY CLOCK 2028 — FULL COMMAND QUALIFICATION ACHIEVED"
		capability_label.text = "YOU HAVE COMMANDED ALL 8 HISTORICAL CHAPTERS & MULTI-DOMAIN WARFARE SYSTEMS"
		lore_rich_label.text = (
			"[b][color=#00FF9D]CONGRATULATIONS, SUPREME THEATER COMMANDER![/color][/b]\n"
			+ "You have experienced the entire 2028 Global Flashpoint Chronicle from opening radar contact at DEFCON 5 to orbital & thermonuclear deterrence at DEFCON 1:\n"
			+ "• [b]Missions 1–3:[/b] 6-Spectrum IADS Radar, Brigade Grouping (`[B]`/`[V]`), Quadruped Robot Dogs & Jam-Proof Fiber-Optic FPV Swarms (`[U]`), and Naval USV Carrier Alpha Strikes (`[SPACE]`).\n"
			+ "• [b]Missions 4–6:[/b] AI Geopolitical Diplomacy & Sovereign Airspace Treaties (`[G]`), 15-Node R&D Tech Tree (`[K]`), and 3D Planetary Globe Orbital ASAT/Cyber/HEMP Warfare (`[7]`/`[8]`).\n"
			+ "• [b]Missions 7–8:[/b] Physical HQ Bunker Defense & Relocation (`[R]`), Mach-24 Orbital Tungsten Rods (`8.23 km/s`), DEFCON 1 Thermonuclear Triad (`[N]`), and Live AI Gemini 2.5 Flash + Veo 3.1 TV Broadcasts (`[J]`)."
		)
		objective_label.text = "Continue commanding the live theater war or press [ESC] to launch any of the 9 Global Scenarios."
		progress_bar.value = 100.0
		execute_demo_btn.text = "CLOSE CHRONICLE OVERLAY"
		return

	var m: Dictionary = get_current_mission()
	var m_num := int(m.get("mission_number", current_mission_index + 1))
	var total := STORY_MISSIONS.size()
	var dc := int(m.get("defcon", 5))
	chapter_badge_label.text = "STORY CAMPAIGN // MISSION %d OF %d — %s [DEFCON %d]" % [
		m_num, total, String(m.get("date_stamp", "")), dc
	]
	network_badge_label.text = "● LIVE VEO 3.1 TV BROADCAST: %s // %s" % [
		String(m.get("network", "GNN")), String(m.get("video_slug", "")).to_upper()
	]
	title_label.text = String(m.get("title", "Mission"))
	capability_label.text = String(m.get("capability_badge", ""))
	lore_rich_label.text = (
		"[b][color=#FF2A54]BREAKING TV NEWS:[/color][/b] [b]%s[/b] — [i]%s[/i]\n" % [
			String(m.get("news_headline", "")), String(m.get("news_chyron", ""))
		]
		+ "[color=#E0ECFF]%s[/color]\n" % String(m.get("history_lore", ""))
		+ "[color=#FFD940]%s[/color]" % String(m.get("presidential_directive", ""))
	)
	objective_label.text = String(m.get("objective_text", ""))
	progress_bar.value = (float(m_num) / float(max(1, total))) * 100.0
	execute_demo_btn.text = "▶ DEMO & ADVANCE CAPABILITY (%d/%d)" % [m_num, total]

	if video_preview_rect != null and sim_db != null and sim_db.has_method("get_news_video_frame_textures"):
		var frames: Array = sim_db.get_news_video_frame_textures(String(m.get("video_slug", "missile_alpha_strike")))
		if not frames.is_empty():
			video_preview_rect.texture = frames[0]


func _build_ui() -> void:
	visible = false
	var theme := TacticalTheme.create_theme()

	card_panel = PanelContainer.new()
	card_panel.name = "StoryProgressionDirectorPanel"
	card_panel.theme = theme
	card_panel.clip_contents = true
	card_panel.anchor_left = 0.19
	card_panel.anchor_right = 0.76
	card_panel.anchor_top = 0.055
	card_panel.anchor_bottom = 0.295
	add_child(card_panel)

	var main_hb := HBoxContainer.new()
	main_hb.add_theme_constant_override("separation", 10)
	card_panel.add_child(main_hb)

	# Left: Live Google Veo 3.1 TV Broadcast Video Monitor for the current Mission
	var tv_box := VBoxContainer.new()
	tv_box.add_theme_constant_override("separation", 4)
	main_hb.add_child(tv_box)

	var tv_frame := PanelContainer.new()
	tv_frame.custom_minimum_size = Vector2(236.0, 134.0)
	tv_box.add_child(tv_frame)

	video_preview_rect = TextureRect.new()
	video_preview_rect.name = "StoryMissionVeoVideoRect"
	video_preview_rect.custom_minimum_size = Vector2(230.0, 128.0)
	video_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	video_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tv_frame.add_child(video_preview_rect)

	network_badge_label = Label.new()
	network_badge_label.text = "● LIVE VEO 3.1 TV BROADCAST"
	network_badge_label.clip_text = true
	network_badge_label.add_theme_font_size_override("font_size", 10)
	network_badge_label.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	tv_box.add_child(network_badge_label)

	# Right: Historical Briefing, Capability Introduction & Mission Controls
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 3)
	main_hb.add_child(right_vb)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 8)
	right_vb.add_child(top_hb)

	chapter_badge_label = Label.new()
	chapter_badge_label.text = "STORY CAMPAIGN // MISSION 1 OF 8"
	chapter_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_badge_label.clip_text = true
	chapter_badge_label.add_theme_font_size_override("font_size", 11)
	chapter_badge_label.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	top_hb.add_child(chapter_badge_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(130.0, 14.0)
	progress_bar.max_value = 100.0
	progress_bar.value = 12.5
	top_hb.add_child(progress_bar)

	title_label = Label.new()
	title_label.text = "MISSION 1: FIRST RADAR FLASH"
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	right_vb.add_child(title_label)

	capability_label = Label.new()
	capability_label.text = "CAPABILITY 1/8: 6-SPECTRUM IADS RADAR & BRIGADE GROUPING"
	capability_label.clip_text = true
	capability_label.add_theme_font_size_override("font_size", 10)
	capability_label.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	right_vb.add_child(capability_label)

	lore_rich_label = RichTextLabel.new()
	lore_rich_label.bbcode_enabled = true
	lore_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lore_rich_label.custom_minimum_size = Vector2(0.0, 62.0)
	lore_rich_label.add_theme_font_size_override("normal_font_size", 11)
	right_vb.add_child(lore_rich_label)

	objective_label = Label.new()
	objective_label.clip_text = true
	objective_label.add_theme_font_size_override("font_size", 10)
	objective_label.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	right_vb.add_child(objective_label)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	right_vb.add_child(btn_hb)

	prev_mission_btn = Button.new()
	prev_mission_btn.text = "<< PREV MISSION"
	prev_mission_btn.pressed.connect(prev_mission)
	btn_hb.add_child(prev_mission_btn)

	execute_demo_btn = Button.new()
	execute_demo_btn.text = "▶ DEMO & ADVANCE CAPABILITY"
	execute_demo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	execute_demo_btn.add_theme_color_override("font_color", TacticalTheme.COL_FLIR_GREEN)
	execute_demo_btn.pressed.connect(execute_current_mission_capability_demo)
	btn_hb.add_child(execute_demo_btn)

	ai_news_btn = Button.new()
	ai_news_btn.text = "[J] LIVE AI GEMINI TV"
	ai_news_btn.add_theme_color_override("font_color", TacticalTheme.COL_UNMANNED_GOLD)
	ai_news_btn.pressed.connect(func():
		if desktop_rig != null and desktop_rig.has_method("trigger_live_ai_tv_report"):
			desktop_rig.call("trigger_live_ai_tv_report")
		notify_capability_event("ORBITAL_RODS_OR_NUKE_OR_GEMINI")
	)
	btn_hb.add_child(ai_news_btn)

	next_mission_btn = Button.new()
	next_mission_btn.text = "NEXT MISSION >>"
	next_mission_btn.add_theme_color_override("font_color", TacticalTheme.COL_NATO_BLUE)
	next_mission_btn.pressed.connect(advance_to_next_mission)
	btn_hb.add_child(next_mission_btn)

	close_btn = Button.new()
	close_btn.text = "HIDE [P]"
	close_btn.add_theme_color_override("font_color", TacticalTheme.COL_OPFOR_RED)
	close_btn.pressed.connect(stop_story_campaign)
	btn_hb.add_child(close_btn)

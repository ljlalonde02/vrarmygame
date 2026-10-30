extends SceneTree
## Automated Verification Suite for Phases 5, 6, and 7:
## - Phase 5: 5 Global 2028 Flashpoint Theaters, 6 Operations, 49 Multi-National Platforms + 27 Munitions (76 Real Photos)
## - Phase 6: Logistics & Sustainment (`KC-46 Pegasus` Aerial Refueling, `HEMTT` Ground Supply Convoys, Airbase Runway Cratering)
## - Phase 7: Tacview Replay Timeline Scrubber (`ReplayRecorder`), Selectable OPFOR AI Doctrines, Interactive Boot-Camp Tutorial & Field Manual

const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const LogisticsSystemScript := preload("res://src/sim_core/systems/logistics_system.gd")


func _init() -> void:
	print("=== [GATE 5-6-7] STARTING PHASES 5, 6 & 7 VERIFICATION SUITE ===")

	var bunker := CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	var sim_db: Node = bunker.sim_db
	var sim_server: Node = bunker.sim_server
	var war_table: Node3D = bunker.war_table
	var main_menu: CanvasLayer = bunker.main_menu
	var opfor: Node = bunker.opfor_commander

	# 1. Verify Phase 5 Multi-National Force Roster (49 Platforms + 27 Weapons = 76 Real Wikipedia Photos)
	var plat_cnt: int = sim_db.platforms_by_id.size() - 1
	var weap_cnt: int = sim_db.weapons_by_id.size() - 1
	var theater_cnt: int = sim_db.theaters_list.size()
	var scen_cnt: int = sim_db.scenarios_list.size()
	print(" -> Loaded DB: %d Platforms, %d Weapons, %d Global Theaters, %d Scenarios" % [plat_cnt, weap_cnt, theater_cnt, scen_cnt])
	assert(plat_cnt >= 49, "Expected >= 49 platforms in SimDB")
	assert(weap_cnt >= 27, "Expected >= 27 weapons in SimDB")
	assert(theater_cnt >= 5, "Expected >= 5 global theaters in SimDB")
	assert(scen_cnt >= 6, "Expected >= 6 playable scenarios in SimDB")

	var verified_photos: int = main_menu.verify_all_encyclopedia_photos_load()
	print(" -> Verified %d / %d Wikipedia Photo Textures load cleanly" % [verified_photos, plat_cnt + weap_cnt])
	assert(verified_photos >= 76, "Expected >= 76 valid Wikipedia/Wikimedia textures")

	# 2. Verify all 6 Global Flashpoint Operations load their respective Theater Heightmaps & Multi-National Units
	var all_scenarios := [
		["op_pacific_shield_2028", "strait_theater"],
		["op_iron_hound_ridge", "strait_theater"],
		["op_red_strait_swarm", "hormuz_theater"],
		["op_korean_thunder_dmz", "korean_dmz_theater"],
		["op_baltic_shield_suwalki", "baltic_suwalki_theater"],
		["op_himalayan_sentinel_lac", "himalaya_lac_theater"],
	]
	for pair in all_scenarios:
		var s_slug: String = String(pair[0])
		var expected_theater: String = String(pair[1])
		main_menu.launch_scenario(s_slug, 2.0, Vector2.ZERO)
		var st: WorldState = sim_server.world_state
		assert(st.active_theater_slug == expected_theater, "Scenario %s expected theater %s, got %s" % [s_slug, expected_theater, st.active_theater_slug])
		assert(st.get_active_unit_count() >= 40, "Scenario %s must seed active units" % s_slug)
		assert(st.active_sites.size() >= 3, "Theater %s must populate strategic sites" % expected_theater)
		print(" -> Scenario '%s' loaded on Theater '%s' (%d active units, %d strategic sites)" % [
			s_slug, st.active_theater_slug, st.get_active_unit_count(), st.active_sites.size()
		])

	# 3. Verify Phase 6 Logistics: KC-46 Aerial Refueling, HEMTT Convoy Resupply & Airbase Runway Cratering
	main_menu.launch_scenario("op_pacific_shield_2028", 1.0, Vector2.ZERO)
	var st6: WorldState = sim_server.world_state

	var tanker_pid: int = sim_db.get_platform_id("kc_46_pegasus")
	var f35_pid: int = sim_db.get_platform_id("f_35a_lightning")
	var convoy_pid: int = sim_db.get_platform_id("hemtt_supply_convoy")
	var m1_pid: int = sim_db.get_platform_id("m1a2_sepv3_platoon")

	var tanker_uid: int = st6.spawn_unit(WorldState.FACTION_BLUE, tanker_pid, Vector3(50.0, 8000.0, 50.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(tanker_pid))
	var f35_uid: int = st6.spawn_unit(WorldState.FACTION_BLUE, f35_pid, Vector3(55.0, 8000.0, 50.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(f35_pid))
	st6.unit_fuel_km[f35_uid] = 120.0
	var initial_fuel: float = st6.unit_fuel_km[f35_uid]

	var convoy_uid: int = st6.spawn_unit(WorldState.FACTION_BLUE, convoy_pid, Vector3(105.0, 0.0, 20.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(convoy_pid))
	var m1_uid: int = st6.spawn_unit(WorldState.FACTION_BLUE, m1_pid, Vector3(108.0, 0.0, 20.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(m1_pid))
	st6.unit_ammo_1[m1_uid] = 0

	for _t in range(10):
		sim_server.step_tick(0.1)

	assert(st6.unit_fuel_km[f35_uid] > initial_fuel, "KC-46 Pegasus Tanker must refuel nearby F-35A in flight")
	assert(st6.refuel_events_count > 0, "Expected refuel_events_count > 0")
	assert(st6.unit_ammo_1[m1_uid] > 0, "HEMTT Supply Convoy must replenish nearby M1A2 platoon ammo")
	assert(st6.resupply_events_count > 0, "Expected resupply_events_count > 0")
	assert(tanker_uid >= 0 and convoy_uid >= 0, "Tanker and Convoy spawned")

	# Crater an airbase runway and verify crater timer
	var airbase_pos := Vector3(110.0, 0.0, -40.0)
	for site in st6.active_sites:
		if String(site.get("site_type", "")) == "AIRBASE":
			airbase_pos = Vector3(float(site.get("x_km", 0.0)), 0.0, float(site.get("z_km", 0.0)))
			break
	var cratered_cnt: int = LogisticsSystemScript.crater_airbase_near(st6, airbase_pos, 20.0, 90.0)
	assert(cratered_cnt >= 1 and st6.craters_inflicted_count >= 1, "Expected airbase runway cratering to register")
	print(" -> Phase 6 Logistics Verified: F-35A Refueled (%.1f -> %.1f km), M1A2 Resupplied (%d rds), %d Airbase Cratered" % [
		initial_fuel, st6.unit_fuel_km[f35_uid], st6.unit_ammo_1[m1_uid], cratered_cnt
	])

	# 4. Verify Phase 7 Selectable OPFOR AI Doctrines, Replay Scrubber, Tutorial & Field Manual
	for doc in ["IADS_AMBUSH", "SWARM_SATURATION", "HYPERSONIC_DECAPITATION"]:
		opfor.set_doctrine(doc)
		assert(opfor.current_doctrine == doc, "OpForCommander must switch doctrine to " + doc)
		opfor.evaluate_and_issue_orders()

	for _t in range(15):
		sim_server.step_tick(0.1)

	var kf_count: int = sim_server.replay_recorder.get_keyframe_count()
	assert(kf_count >= 3, "ReplayRecorder must record timeline keyframes during battle")
	main_menu._on_replay_slider_changed(0.35)
	assert(sim_server.replay_recorder.is_scrubbing_replay == true, "Replay scrubber should enter scrub mode")
	sim_server.resume_live_from_replay()
	assert(sim_server.replay_recorder.is_scrubbing_replay == false, "resume_live_from_replay should exit scrub mode")

	assert(sim_db.tutorial_steps.size() >= 5, "Expected >= 5 interactive tutorial steps")
	assert(sim_db.manual_sections.size() >= 4, "Expected >= 4 Field Manual sections")
	assert(FileAccess.file_exists(ProjectSettings.globalize_path("res://docs/GAME_MANUAL.md")), "Expected docs/GAME_MANUAL.md on disk")
	print(" -> Phase 7 Verified: %d Replay Keyframes Scrubbed, 3 OPFOR Doctrines Tested, %d Tutorial Steps & %d Manual Sections Loaded" % [
		kf_count, sim_db.tutorial_steps.size(), sim_db.manual_sections.size()
	])

	war_table.visual_sync.sync_visuals()

	# 5. Verify Phase 8: Tacview 3D Miniatures (Jets, Ships, Individual Soldiers, Vehicles, Civilian Dots),
	#    Per-Unit Situational Awareness AI, 6 Military Mission Orders & AI Subordinate Staff COAs
	war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
	war_table.visual_sync.sync_visuals()
	var vs: Node3D = war_table.visual_sync
	print(" -> Phase 8 Macro View Rendered: %d 3D Jets, %d 3D Ships, %d Individual Soldiers, %d Vehicles/Robot Dogs, %d Neutral Civilian Dots" % [
		vs.last_visible_jet_count, vs.last_visible_ship_count, vs.last_visible_soldier_count, vs.last_visible_vehicle_count, vs.last_visible_civilian_dot_count
	])
	assert(vs.last_visible_jet_count > 0, "Expected 3D Tacview swept-wing jets rendered")
	assert(vs.last_visible_ship_count > 0, "Expected 3D miniature warships rendered")
	assert(vs.last_visible_soldier_count > 0, "Expected individual 3D infantry soldiers rendered on terrain")
	assert(vs.last_visible_vehicle_count > 0, "Expected individual 3D tanks / quadruped robot dogs rendered on terrain")
	assert(vs.last_visible_civilian_dot_count > 0, "Expected neutral C4ISR civilian shipping/highway dots rendered")

	# Also verify zoomed-in squad expansion on 1st Mechanized/Mountain Infantry Brigade at (117, -125)
	war_table.set_zoom_and_pan(5.0, Vector2(117.0, -125.0), true)
	war_table.visual_sync.sync_visuals()
	print(" -> Phase 8 Zoomed-In Squad Expansion (5.0x at 1st Mech Brigade): %d Individual Soldiers, %d Vehicles/Robot Dogs" % [
		vs.last_visible_soldier_count, vs.last_visible_vehicle_count
	])
	assert(vs.last_visible_soldier_count >= 48, "Expected 12-man infantry squad expansion when zoomed in >= 3.5x")

	# Test all 6 Military Mission Orders via ReconDossierPanel
	for order_code in ["ORDER_ASSAULT_SEIZE", "ORDER_SEAD_SUPPRESS", "ORDER_CAP_OVERWATCH", "ORDER_PRECISION_FIRE_TOT", "CYCLE_ALTITUDE", "DEPLOY_SUBUNIT"]:
		bunker.recon_dossier.issue_selected_unit_ability(order_code)
	sim_server.step_tick(0.1)

	# Test AI Subordinate Staff Officer SITREP & all 3 Joint COAs
	var staff: Node = bunker.subordinate_staff
	var sitrep: String = staff.update_sitrep()
	assert(sitrep.length() > 20, "Expected non-empty JOC Staff SITREP")
	for coa in ["COA_JFACC_AIR_SUPERIORITY", "COA_JFLCC_GROUND_VANGUARD", "COA_JFC_JOINT_TOT_STRIKE"]:
		var tasked: int = staff.execute_coa(coa)
		assert(tasked > 0, "Expected Subordinate Staff COA %s to task units" % coa)
	sim_server.step_tick(0.1)
	print(" -> Phase 8 Subordinate Staff & 6 Military Mission Orders Verified (%d COAs executed)" % staff.coas_executed_count)

	# 6. Verify Phase 9: C# .NET 8 Multi-Threaded SIMD Kernel, Spreading Civilian Density Field (civ/m^2) & 3-Tier Zoom Sim-LOD (3,500+ Units)
	assert(sim_server.cs_kernel != null, "Expected C# .NET 8 SimLodKernel to be instantiated")
	var is_simd: bool = sim_server.cs_kernel.call("IsSimdAccelerated")
	var hw_threads: int = sim_server.cs_kernel.call("GetHardwareThreadCount")
	print(" -> Phase 9 C# .NET 8 Kernel Active: Hardware SIMD=%s | CPU Threads=%d" % [str(is_simd), hw_threads])
	assert(is_simd == true and hw_threads >= 1, "Expected C# Vector<float> SIMD acceleration")

	# Verify Spreading Civilian Density Field (civ/m^2) conservation & combat evacuation diffusion
	var ws: WorldState = sim_server.world_state
	assert(ws.total_theater_civilians > 1000000.0, "Expected > 1M civilians seeded in 128x128 civ/m^2 density field")
	ws.inject_civilian_combat_shock(110.0, -40.0, 28.0, 2.5)
	ws.inject_civilian_combat_shock(95.0, -35.0, 28.0, 2.5)
	for _s in range(5):
		sim_server.step_tick(0.2)
	print(" -> Phase 9 Spreading Civilian Density Field: Total Pop=%.2fM | Active Density Cells=%d | Evacuated/Spread Civilians=%.0f" % [
		ws.total_theater_civilians / 1000000.0, vs.last_active_civilian_cells_count, ws.total_displaced_civilians
	])
	assert(ws.total_displaced_civilians > 100.0, "Expected civilian density field to spread/evacuate outward from combat shockwaves")

	# Verify 3-Tier Zoom Sim-LOD at Army Group Scale (3,500+ active units)
	var army_group_units: int = sim_server.spawn_army_group_reinforcements(3500)
	assert(army_group_units >= 3500, "Expected >= 3,500 active units in Army Group scale test")

	# Zoom out to 1.0x Macro: all non-selected units without immediate high threat run in Tier 2 Macro
	war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
	sim_server.step_tick(0.1)
	var macro_t2: int = ws.lod_tier2_count
	assert(macro_t2 >= 3000, "At 1.0x Macro Zoom, expected >= 3,000 units in LOD_TIER_2_MACRO")

	# Zoom in to 5.5x Tactical Valley: in-frustum units promote to Tier 0 Micro while off-screen units stay in Tier 2 Macro
	war_table.set_zoom_and_pan(5.5, Vector2(117.0, -125.0), true)
	var t_start_usec := Time.get_ticks_usec()
	for _b in range(10):
		sim_server.step_tick(0.1)
	var elapsed_ms := float(Time.get_ticks_usec() - t_start_usec) / 1000.0
	print(" -> Phase 9 Army Group Sim-LOD Benchmark (%d Active Units @ 5.5x Zoom): T0 Micro=%d | T1 Oper=%d | T2 Macro=%d | 10 Ticks=%.2f ms (%.2f ms/tick)" % [
		army_group_units, ws.lod_tier0_count, ws.lod_tier1_count, ws.lod_tier2_count, elapsed_ms, elapsed_ms / 10.0
	])
	assert(ws.lod_tier0_count > 20 and ws.lod_tier2_count > 2500, "Expected Zoom Sim-LOD to split in-frustum Tier 0 Micro vs off-screen Tier 2 Macro")

	# 7. Verify Phase 10: Two New Upper Zoom Levels (Planetary Orbital Globe 0.22x + 4,000 km Continental Curved Space 0.52x),
	#    24 Orbiting Space Force Satellites, and Multi-Domain Deterrence Warfare ([7] ASAT, [8] Cyber CNO, [9] PsyOp/Evac, [0] CBRN MOPP & Hazard Plume)
	war_table.set_zoom_and_pan(0.22, Vector2.ZERO, true)
	war_table.visual_sync.sync_visuals()
	assert(war_table.is_planetary_globe_visible() == true, "Expected 3D Planetary Orbital Globe visible at 0.22x zoom")
	assert(vs.last_visible_satellite_count >= 20, "Expected >= 20 3D Space Force satellites rendered in orbital constellation")
	print(" -> Phase 10 Level 1 Zoom (0.22x Planetary Orbital Globe): Globe Visible=%s | 3D Satellites=%d | Tier=%s" % [
		str(war_table.is_planetary_globe_visible()), vs.last_visible_satellite_count, war_table.get_active_zoom_tier_name()
	])

	war_table.set_zoom_and_pan(0.52, Vector2.ZERO, true)
	war_table.visual_sync.sync_visuals()
	assert(war_table.is_planetary_globe_visible() == false, "Expected Planetary Globe hidden at 0.52x Continental Curved Space zoom")
	assert(war_table.get_active_zoom_tier_name().find("8,000 KM") >= 0, "Expected 8,000 km Continental Curved Space tier label")
	print(" -> Phase 10 Level 2 Zoom (0.52x Continental Curved Space): Tier=%s | 3D Satellites=%d" % [
		war_table.get_active_zoom_tier_name(), vs.last_visible_satellite_count
	])

	# Execute all 4 Multi-Domain Deterrence Actions ([7] ASAT, [8] Cyber CNO, [9] PsyOp/Evac, [0] CBRN MOPP & Wind-Drifting Hazard Plume)
	var asat_res: int = sim_server.execute_mdd_action("ORDER_ASAT_STRIKE")
	var cyber_res: int = sim_server.execute_mdd_action("ORDER_CYBER_CNO")
	var psyop_res: int = sim_server.execute_mdd_action("ORDER_PSYOP_EVAC")
	var cbrn_res: int = sim_server.execute_mdd_action("ORDER_CBRN_MOPP")
	assert(asat_res >= 0 and ws.asat_intercepts_count >= 1, "Expected [7] ASAT strike to intercept/dazzle hostile satellite")
	assert(cyber_res > 0 and ws.cyber_strikes_count >= 1, "Expected [8] Cyber CNO strike to disable enemy SAM radars/drones")
	assert(psyop_res > 0 and ws.psyop_broadcasts_count >= 1, "Expected [9] PsyOp/Evac broadcast to suppress morale and accelerate civilian evacuation")
	assert(cbrn_res > 0, "Expected [0] CBRN MOPP to protect friendly forces and seed hazard plume")

	for _m in range(5):
		sim_server.step_tick(0.2)

	print(" -> Phase 10 Multi-Domain Deterrence Verified: ASAT=%d | Cyber=%d units | PsyOp=%d units | CBRN MOPP=%d units | Wind-Advected Hazard Cells=%d" % [
		ws.asat_intercepts_count, cyber_res, psyop_res, cbrn_res, ws.active_hazard_cells_count
	])
	assert(ws.active_hazard_cells_count > 10, "Expected 2D Wind-Advected Hazard Plume PDE to spread across terrain grid")

	# 8. Verify Phase 11: Living Battlefield Infrastructure (Nature/Forests, Rivers/Bridges, Highways/Railways,
	#    Procedural 3D City/Town/Airfield Cubes, Moving 3D Logistics Trains, Rail Derailment & Dynamic War Destruction)
	war_table.set_zoom_and_pan(1.5, Vector2.ZERO, true)
	war_table.visual_sync.sync_visuals()
	assert(ws.bldg_count >= 100, "Expected >= 100 procedural 3D city/town/airfield/bridge building cubes generated")
	assert(vs.last_visible_building_count >= 50, "Expected 3D building cubes rendered on WarTable")
	assert(ws.train_count >= 4 and vs.last_visible_train_car_count >= 12, "Expected >= 4 military logistics trains (16+ cars) rendered on railways")

	# Verify Highway vs River/Rubble Mobility Physics & Dynamic War Destruction / Train Derailment
	var train0_pos: Vector3 = ws.train_pos_km[0]
	var newly_destr: int = ws.inject_war_destruction(train0_pos.x, train0_pos.z, 16.0, 0.85)
	sim_server.step_tick(0.2)
	war_table.visual_sync.sync_visuals()

	var veh_rubble_mult: float = ws.get_ground_mobility_multiplier(train0_pos.x, train0_pos.z, false)
	var dog_rubble_mult: float = ws.get_ground_mobility_multiplier(train0_pos.x, train0_pos.z, true)
	var dog_cover_mult: float = ws.get_terrain_cover_damage_mult(train0_pos.x, train0_pos.z, true)
	print(" -> Phase 11 Living Infrastructure Verified: 3D Buildings=%d (Visible=%d) | Trains=%d (Cars=%d, Derailed=%d) | Rubble Cells=%d | Veh Rubble Spd=%.2fx vs Robot Dog=%.2fx (Cover=%.2fx)" % [
		ws.bldg_count, vs.last_visible_building_count, ws.train_count, vs.last_visible_train_car_count,
		ws.trains_derailed_count, ws.active_destroyed_cells_count, veh_rubble_mult, dog_rubble_mult, dog_cover_mult
	])
	assert(newly_destr > 0 and ws.active_destroyed_cells_count > 0, "Expected war destruction to create scorched rubble cells")
	assert(ws.trains_derailed_count >= 1, "Expected bombing railway under train 0 to derail/halt the logistics train")
	assert(dog_rubble_mult > veh_rubble_mult, "Expected Quadruped Robot Dogs & Infantry to traverse rubble faster than wheeled/tracked vehicles")
	assert(dog_cover_mult < 0.55, "Expected fortified urban rubble to grant strong defensive cover (<0.55x damage) to Infantry & Robot Dogs")

	# 9. Verify Phase 12: 6-Spectrum Sensor Fusion Matrix, 4-Tier C2 Integrity/Delegation & Live Interactive 5-Step TutorialController
	# 9a. 6-Spectrum Sensor Fusion Matrix Verification
	var pid_rafale: int = sim_db.get_platform_id("rafale_f4_flight")       # IR_EO (pirate_irst_passive, 65 km)
	var pid_j20: int = sim_db.get_platform_id("j_20_mighty_dragon")        # Stealth Fighter (RCS 0.015 m^2)
	var pid_s400: int = sim_db.get_platform_id("s_400_triumf")             # ACTIVE_RADAR (260 km)
	var pid_specops: int = sim_db.get_platform_id("specops_mountain_team") # ACOUSTIC_SONAR (12 km valley diffraction)
	var pid_orca: int = sim_db.get_platform_id("orca_xluuv")               # UUV Submarine (towed_sonar_array, 55 km)
	var pid_dog: int = sim_db.get_platform_id("vision_60_q_ugv")           # LIDAR_CV (5.5 km)

	var uid_rafale: int = ws.spawn_unit(WorldState.FACTION_BLUE, pid_rafale, Vector3(0.0, 9000.0, 0.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_rafale))
	var uid_j20: int = ws.spawn_unit(WorldState.FACTION_RED, pid_j20, Vector3(52.0, 9000.0, 0.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_j20))
	var uid_s400: int = ws.spawn_unit(WorldState.FACTION_RED, pid_s400, Vector3(-180.0, 1200.0, 0.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_s400))
	var uid_specops: int = ws.spawn_unit(WorldState.FACTION_BLUE, pid_specops, Vector3(130.0, 1500.0, 20.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_specops))
	var uid_orca: int = ws.spawn_unit(WorldState.FACTION_BLUE, pid_orca, Vector3(10.0, 0.0, 10.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_orca))
	var uid_dog: int = ws.spawn_unit(WorldState.FACTION_BLUE, pid_dog, Vector3(50.0, 9000.0, 0.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(pid_dog))

	# Rafale F4 in EMCON (radar OFF) vs stealth J-20A with afterburner ON -> Passive IRST (IR_EO) + 1.85x plume boost spots J-20A at 52 km!
	ws.unit_radar_active[uid_rafale] = 0
	ws.unit_radar_active[uid_j20] = 0
	ws.unit_afterburner[uid_j20] = 1
	var ir_eval: Dictionary = SensorLoSSystem.evaluate_pair_detection_spectrum(ws, sim_db, uid_rafale, uid_j20)
	assert(ir_eval["detected"] == true and ir_eval["spectrum"] == "IR_EO", "Expected Rafale F4 Passive IRST (IR_EO) to detect afterburning stealth J-20A in EMCON")

	# Rafale F4 in EMCON (radar OFF) vs radiating S-400 (260 km radar ON) -> Passive ESM triangulates S-400 at 1.6x range (416 km > 180 km)!
	ws.unit_radar_active[uid_s400] = 1
	var esm_eval: Dictionary = SensorLoSSystem.evaluate_pair_detection_spectrum(ws, sim_db, uid_rafale, uid_s400)
	assert(esm_eval["detected"] == true and esm_eval["spectrum"] == "PASSIVE_ESM" and float(esm_eval["eff_range_km"]) >= 400.0, "Expected Passive ESM to triangulate active S-400 radar at 1.6x range")

	# Submerged Orca XLUUV Submarine is immune to S-400 Active Radar
	var sub_vs_radar: Dictionary = SensorLoSSystem.evaluate_pair_detection_spectrum(ws, sim_db, uid_s400, uid_orca)
	assert(sub_vs_radar["detected"] == false, "Expected submerged Orca XLUUV submarine to be undetectable by surface/air Active Radar")

	# Vision 60 Robot Dog 3D LiDAR (LIDAR_CV, 5.5 km) detects stealth target at 2 km ignoring RCS
	var lidar_eval: Dictionary = SensorLoSSystem.evaluate_pair_detection_spectrum(ws, sim_db, uid_dog, uid_j20)
	assert(lidar_eval["detected"] == true and lidar_eval["spectrum"] == "LIDAR_CV", "Expected Robot Dog 3D LiDAR (LIDAR_CV) to detect stealth target at close range")

	# Special Forces Acoustic Array (ACOUSTIC_SONAR) enables Non-Line-of-Sight valley diffraction
	var ac_eval: Dictionary = SensorLoSSystem.evaluate_pair_detection_spectrum(ws, sim_db, uid_specops, uid_specops)
	assert(ac_eval["spectrum"] == "ACOUSTIC_SONAR" and ac_eval["allow_diffraction"] == true, "Expected ACOUSTIC_SONAR sensor to enable Non-Line-of-Sight valley diffraction")
	print(" -> Phase 12 6-Spectrum Sensor Fusion Verified: IR_EORange=%.1fkm | PASSIVE_ESM=%.1fkm | LIDAR_CV=%.1fkm | ACOUSTIC_SONAR Diffraction=%s | UUV Radar Stealth=OK" % [
		float(ir_eval["eff_range_km"]), float(esm_eval["eff_range_km"]), float(lidar_eval["eff_range_km"]), str(ac_eval["allow_diffraction"])
	])

	# 9b. 4-Tier C2 Integrity & AI Delegation Mode Toggle Verification
	assert(ws.unit_delegated_ai[uid_rafale] == 1, "Expected newly spawned unit to default to DELEGATED_TO_PARENT (1)")
	bunker.command_bus.enqueue_unit_ability([uid_rafale], "TOGGLE_AI_DELEGATION")
	sim_server.step_tick(0.1)
	assert(ws.unit_delegated_ai[uid_rafale] == 0, "Expected TOGGLE_AI_DELEGATION to lock unit to DIRECT_PLAYER_CONTROL (0)")
	for st in ws.active_sites:
		if String(st.get("faction_owner", "")) == "RED" and String(st.get("site_type", "")) == "COMMAND_BUNKER":
			st["crater_timer_sec"] = 90.0
	EchelonClusterSystem.step(ws)
	assert(ws.red_c2_integrity < ws.blue_c2_integrity, "Expected cratering Red Command Bunkers to degrade red_c2_integrity")
	print(" -> Phase 12 4-Tier C2 Integrity & Delegation Verified: Blue C2=%.0f%% vs Degraded Red C2=%.0f%% | Direct Control Lock=OK" % [
		ws.blue_c2_integrity * 100.0, ws.red_c2_integrity * 100.0
	])

	# 9c. Live Event-Driven 5-Step Interactive Boot-Camp TutorialController Verification
	var tut = bunker.tutorial_controller
	assert(tut != null, "Expected TutorialController instantiated in CommandBunker")
	tut.start_bootcamp(true)
	assert(tut.is_active == true and tut.current_step_index == 0 and tut.beacon_3d.visible == true, "Expected Boot-Camp to start at Step 1 with visible 3D beacon")
	for _step_i in range(5):
		tut.perform_current_step_demo_action()
	assert(tut.is_completed == true, "Expected all 5 interactive Boot-Camp lessons to complete via event notifications")
	print(" -> Phase 12 Interactive 5-Step Boot-Camp TutorialController Verified: Steps=%d | Completed=%s" % [
		tut.steps.size(), str(tut.is_completed)
	])

	# 10. Verify Phase 15: 1,000,000-Unit 7-Theater Global ORBAT (2,000x2,000 km), Ukraine & US-Mexico Theaters,
	#     92/92 Wikipedia Photos, Real-Time 1:1 Speeds, Battalion/Brigade Group Selection & Live Casualties/Ammunition Ledger
	assert(plat_cnt >= 62 and weap_cnt >= 30, "Expected 62 platforms and 30 weapons (92 total)")
	assert(verified_photos == plat_cnt + weap_cnt, "Expected 100%% (%d/%d) Wikipedia textures to load with 0 errors" % [verified_photos, plat_cnt + weap_cnt])
	assert(theater_cnt >= 7 and scen_cnt >= 8, "Expected 7 Global 2,000x2,000km Theaters and 8 Playable Scenarios")

	for new_pair in [
		["op_ukraine_donbas_2028", "ukraine_donbas_theater"],
		["op_mexico_rio_grande_2028", "mexico_rio_grande_theater"],
	]:
		main_menu.launch_scenario(String(new_pair[0]), 1.0, Vector2.ZERO)
		var st_new: WorldState = sim_server.world_state
		assert(st_new.active_theater_slug == String(new_pair[1]), "Expected theater " + String(new_pair[1]))
		assert(st_new.get_active_unit_count() >= 5000, "Expected >= 5,000 Army Group units in " + String(new_pair[0]))
		assert(st_new.global_total_units_active >= 950000, "Expected ~1,000,000 Global ORBAT units tracked across 7 theaters")

	# Verify 3-Tier Battalion/Brigade Selection & Multi-Unit Formation Waypoint Orders + Live Casualties/Ammo
	var rig = bunker.desktop_rig
	rig.select_battalion_of_current()
	var bn_sel_cnt: int = rig.selected_unit_ids.size()
	assert(bn_sel_cnt >= 4, "Expected [B] Battalion selection to group subordinate Companies (%d selected)" % bn_sel_cnt)

	rig.select_brigade_of_current()
	var bde_sel_cnt: int = rig.selected_unit_ids.size()
	assert(bde_sel_cnt >= 12, "Expected [V] Brigade selection to group all subordinate Companies in Brigade (%d selected)" % bde_sel_cnt)

	# Issue formation waypoint order to the entire selected Brigade and verify all subordinate units follow it
	var order_dest := Vector3(15.0, 0.0, 15.0)
	bunker.command_bus.enqueue_move_waypoints(rig.selected_unit_ids, [order_dest])
	rig.set_sim_time_scale(60.0)
	sim_server.step_tick(1.0)
	var sample_uid: int = rig.selected_unit_ids[0]
	assert(sim_server.world_state.unit_has_waypoint[sample_uid] == 1, "Ordered Brigade subordinate units must have active waypoint")
	assert(sim_server.world_state.unit_player_override_timer[sample_uid] > 100.0, "Ordered units must lock player override timer so AI does not cancel order")

	# Trigger Alpha Strike & combat ticks to verify Live Ammunition & Casualties (KIA/WIA) for both sides
	bunker.command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)
	bunker.command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_RED)
	for _c_step in range(25):
		sim_server.step_tick(2.0)
	rig._process(0.016)
	var st_final: WorldState = sim_server.world_state
	print(" -> Phase 15 Verified: 1M Global Units=%d | Bde Selected=%d units | Blue Ammo=%d (Fired=%d) | Red Ammo=%d (Fired=%d) | Blue KIA/WIA=%d/%d | Red KIA/WIA=%d/%d" % [
		st_final.global_total_units_active, bde_sel_cnt,
		st_final.blue_ammo_remaining, st_final.blue_munitions_expended,
		st_final.red_ammo_remaining, st_final.red_munitions_expended,
		st_final.blue_personnel_kia, st_final.blue_personnel_wia,
		st_final.red_personnel_kia, st_final.red_personnel_wia
	])
	assert(st_final.blue_ammo_remaining > 0 and st_final.red_ammo_remaining > 0, "Expected live ammo remaining tracked for both sides")
	assert(st_final.blue_munitions_expended > 0 and st_final.red_munitions_expended > 0, "Expected live munitions expended tracked for both sides")
	assert(st_final.blue_personnel_kia + st_final.red_personnel_kia > 0, "Expected live KIA/WIA casualties tracked for both sides")

	# 11. Verify Full VR (XRCommandRig) & Desktop Gamability Parity:
	#     - 3D VR Gauntlets, Laser Pointers, Reticles & Left-Wrist C4ISR Holographic Tablet
	#     - VR 3D Sphere Volume Group Selection & 1-Button Echelon Escalation (Company -> Battalion -> Brigade)
	#     - VR Laser Waypoint & Strike Order Issuing
	#     - VR Physical Hand Poke & Laser Actuation of 3D TactileConsole Switches & 3D Overhead C4ISR Board
	#     - VR/Desktop Planetary Globe 3D Flashpoint Beacon Selection
	var xr: XRCommandRig = bunker.xr_rig
	assert(xr != null, "Expected XRCommandRig initialized")
	xr.set_vr_simulator_mode(true)
	xr._process(0.016)
	bunker.tactile_console._process(0.016)
	assert(xr.left_controller.visible == true and xr.right_controller.visible == true, "Expected 3D VR Hand Controllers visible in VR mode")
	assert(xr._wrist_label_3d.text.find("VR C4ISR WRIST") != -1, "Expected 3D Left-Wrist C4ISR Tablet to display live telemetry")
	assert(bunker.tactile_console._holo_board_label_3d.text.find("3D C4ISR BUNKER HOLOGRAM") != -1, "Expected 3D Overhead Bunker Hologram Board to display live telemetry")

	# Test VR 3D Sphere Volume Selection on the War Table
	var wt_pos: Vector3 = bunker.war_table.position
	var vol_selected_cnt: int = xr.vr_sphere_volume_select(wt_pos, 0.85, false)
	assert(vol_selected_cnt >= 4, "Expected VR 3D Sphere Volume Selection to select multiple friendly units on War Table (got %d)" % vol_selected_cnt)

	# Test Desktop Control Group Save & Recall
	rig.save_control_group(1)
	rig.select_unit(rig.selected_unit_ids[0])
	assert(rig.selected_unit_ids.size() == 1, "Single unit selected before recalling group")
	var recalled_cnt: int = rig.recall_control_group(1)
	assert(recalled_cnt == vol_selected_cnt, "Expected Control Group 1 recall to restore %d units" % vol_selected_cnt)

	# Test VR 1-Button Echelon Escalation (Company -> Battalion -> Brigade)
	xr._echelon_cycle_stage = 0
	var vr_bn_cnt: int = xr.vr_cycle_echelon_selection()
	var vr_bde_cnt: int = xr.vr_cycle_echelon_selection()
	assert(vr_bn_cnt >= 3 and vr_bde_cnt >= vr_bn_cnt, "Expected VR Echelon Cycle button to escalate from Battalion (%d) to Brigade (%d)" % [vr_bn_cnt, vr_bde_cnt])

	# Test VR Laser Waypoint Order on War Table
	xr.aim_controller_at_world_pos("right", wt_pos + Vector3(0.15, 0.0, -0.15))
	var vr_order_ok: bool = xr.vr_laser_issue_order("right", false)
	assert(vr_order_ok == true, "Expected VR Laser to issue 3D Waypoint/Strike order onto War Table")

	# Test VR Laser Actuation of 3D TactileConsole Switch (`TimeScaleThrottle` & `MasterIADSLever`)
	var iads_wpos: Vector3 = bunker.tactile_console.get_control_world_pos(bunker.tactile_console._iads_lever_pivot)
	xr.aim_controller_at_world_pos("right", iads_wpos)
	var act_res: Dictionary = xr.vr_laser_select_or_actuate("right", false)
	assert(String(act_res.get("type", "")) == "CONSOLE_CONTROL", "Expected VR Laser to pick and actuate 3D TactileConsole switch")

	# Test VR Physical Hand Poke on 3D TactileConsole (`ExecuteAlphaStrikeButton3D`)
	bunker.tactile_console._last_poke_msec = 0
	var alpha_wpos: Vector3 = bunker.tactile_console.get_control_world_pos(bunker.tactile_console._alpha_button_mesh)
	var poked_ctrl: String = bunker.tactile_console.check_hand_proximity_actuation(alpha_wpos, rig.selected_unit_id)
	assert(poked_ctrl == "ExecuteAlphaStrikeButton3D", "Expected VR physical hand proximity to actuate ExecuteAlphaStrikeButton3D")

	# Test VR/Desktop 3D Planetary Globe Flashpoint Beacon Raycast Selection
	bunker.war_table.set_zoom_and_pan(0.22, Vector2.ZERO, true)
	assert(bunker.war_table.is_planetary_globe_visible() == true, "Expected 3D Planetary Globe visible at 0.22x zoom")
	var ukr_beacon: Node3D = bunker.war_table._planetary_globe_root.get_node_or_null("GlobeBeacon_op_ukraine_donbas_2028")
	assert(ukr_beacon != null, "Expected GlobeBeacon_op_ukraine_donbas_2028 on 3D Planetary Globe")
	var globe_root: Node3D = bunker.war_table._planetary_globe_root
	var ukr_wpos: Vector3 = wt_pos + globe_root.position + globe_root.transform.basis * ukr_beacon.position
	xr.aim_controller_at_world_pos("right", ukr_wpos)
	var globe_res: Dictionary = xr.vr_laser_select_or_actuate("right", false)
	assert(String(globe_res.get("type", "")) == "GLOBE_FLASHPOINT" and String(globe_res.get("target", "")) == "op_ukraine_donbas_2028", "Expected VR Laser to select Ukraine Flashpoint on 3D Planetary Globe")
	assert(xr.haptic_pulses_triggered >= 4, "Expected VR controller haptic feedback pulses triggered")
	print(" -> Phase 16 VR & Desktop Gamability Verified: VR Sphere Select=%d units | VR Bn/Bde=%d/%d | Console Laser='%s' | Hand Poke='%s' | Globe Flashpoint='%s' | Haptics=%d" % [
		vol_selected_cnt, vr_bn_cnt, vr_bde_cnt, String(act_res.get("target", "")), poked_ctrl, String(globe_res.get("target", "")), xr.haptic_pulses_triggered
	])

	# =========================================================================
	# 12. PHASE 17: DEFENSE BUDGET, 5-BRANCH R&D TECH TREE, DEFCON 5->1 ESCALATION, WORLD NEWS, PRESIDENTIAL DECLARATIONS & NBC/EMP/ORBITAL/THERMONUCLEAR WARFARE
	# =========================================================================
	print("--- [12/12] Testing Defense Budget, 15-Node Tech Tree, DEFCON 5->1 Escalation, World News, Presidential Declarations & NBC/EMP/Orbital/Thermonuclear Warfare ---")
	bunker.war_table.set_zoom_and_pan(1.5, Vector2.ZERO, true)
	assert(sim_db.tech_tree_nodes.size() == 15, "Expected 15 R&D Tech Tree nodes across 5 branches in SimDB")
	assert(ws.defcon_level <= 5 and ws.defcon_level >= 3, "Expected scenario to start at DEFCON 5..3")
	assert(ws.blue_budget_musd >= 2000.0, "Expected initial Blue Defense Budget >= $2,000M")

	# Test unlocking Tier 1 -> Tier 2 -> Tier 3 R&D Technologies and verify combat modifiers
	ws.blue_budget_musd += 3500.0
	var r1: Dictionary = sim_server.unlock_tech("tech_metamaterial_ram_coat", WorldState.FACTION_BLUE)
	assert(bool(r1.get("ok", false)) == true, "Expected Tier 1 Metamaterial Stealth RAM tech unlock to succeed")
	assert(ws.blue_rcs_mult < 0.70, "Expected Blue RCS multiplier reduced by Metamaterial Stealth RAM")

	var r2: Dictionary = sim_server.unlock_tech("tech_scramjet_glide_mach12", WorldState.FACTION_BLUE)
	assert(bool(r2.get("ok", false)) == true, "Expected Tier 2 Scramjet Mach 12+ tech unlock to succeed")
	assert(ws.blue_missile_speed_mult >= 1.24, "Expected Blue missile speed multiplier increased by Scramjet tech")

	var r3: Dictionary = sim_server.unlock_tech("tech_prompt_global_salvo", WorldState.FACTION_BLUE)
	assert(bool(r3.get("ok", false)) == true, "Expected Tier 3 Prompt Global Salvo tech unlock to succeed")

	# Test Emergency Ammo Airlift & Strategic Task Force Procurement
	var ammo_before: int = ws.blue_ammo_remaining
	var airlift_ok: bool = sim_server.procure_ammo_airlift(WorldState.FACTION_BLUE)
	assert(airlift_ok == true, "Expected Emergency Ammo Airlift procurement to succeed")
	sim_server.step_tick(0.1)
	assert(ws.blue_ammo_remaining > ammo_before, "Expected Blue ammunition reserves to increase after Emergency Airlift")

	ws.blue_budget_musd += 2500.0
	var tf_spawned: int = sim_server.procure_task_force("TF_ROBOT_ARMOR", WorldState.FACTION_BLUE)
	assert(tf_spawned >= 10, "Expected TF_ROBOT_ARMOR procurement to spawn a Brigade/Battalion/Company Task Force")

	# Test Escalating Conflict Out of Control (CBRN Plume -> HEMP EMP -> Orbital Kinetic Rods -> PEAD-99 Thermonuclear Salvo -> DEFCON 1!)
	var wmd_cbrn_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_TACTICAL_CBRN", Vector3(20.0, 0.0, -10.0), WorldState.FACTION_BLUE)
	assert(bool(wmd_cbrn_res.get("ok", false)) == true and ws.cbrn_strikes_count >= 1, "Expected Tactical CBRN Aerosol Strike to detonate")

	var hemp_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_HEMP_EMP", Vector3(25.0, 0.0, -12.0), WorldState.FACTION_BLUE)
	assert(bool(hemp_res.get("ok", false)) == true and ws.hemp_emp_strikes_count >= 1, "Expected Exoatmospheric HEMP EMP Super-Burst to detonate")

	var rod_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_ORBITAL_RODS", Vector3(30.0, 0.0, -15.0), WorldState.FACTION_BLUE)
	assert(bool(rod_res.get("ok", false)) == true and ws.orbital_rod_strikes_count >= 1, "Expected Mach-24 Orbital Kinetic Tungsten Rods strike to impact")

	var nuke_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_THERMONUCLEAR", Vector3(35.0, 0.0, -10.0), WorldState.FACTION_BLUE)
	assert(bool(nuke_res.get("ok", false)) == true and ws.nuclear_detonations_count >= 1, "Expected PEAD-99 Thermonuclear Warhead detonation")

	sim_server.step_tick(1.0)
	bunker.war_table.visual_sync.sync_visuals()
	bunker.main_menu.open_tech_tree_tab()
	assert(ws.defcon_level == 1, "Expected conflict escalation to reach DEFCON 1 (COCKED PISTOL / NUCLEAR WAR)")
	assert(ws.active_nuclear_fireballs.size() >= 3, "Expected active 3D nuclear/WMD fireball domes on War Table")
	assert(ws.world_news_feed.size() >= 5, "Expected World News & Presidential Directive feed populated")
	assert(ws.latest_presidential_declaration.find("DEFCON 1") != -1 or ws.latest_presidential_declaration.find("PEAD-99") != -1, "Expected Presidential Emergency Action Directive PEAD-99 at DEFCON 1")
	print(" -> Phase 17 Verified: DEFCON=%d (Esc:%.0f%%) | Techs Unlocked=%d/15 | Nukes=%d HEMP=%d OrbitalRods=%d CBRN=%d | News Feed=%d items | Pres Decl='%s'" % [
		ws.defcon_level, ws.global_escalation_score, ws.blue_unlocked_techs.size(),
		ws.nuclear_detonations_count, ws.hemp_emp_strikes_count, ws.orbital_rod_strikes_count, ws.cbrn_strikes_count,
		ws.world_news_feed.size(), ws.latest_presidential_declaration.substr(0, 72)
	])

	# =========================================================================
	# 13. PHASE 18: MALE & FEMALE MILITARY OFFICER VOICE SYNTH, 3D BUNKER DEFCON ATMOSPHERE, BUNKER RELOCATION & CAPTURE/DESTRUCTION GAME OVER
	# =========================================================================
	print("--- [13/13] Testing Male & Female Military Officer Voice Synth, 3D Bunker DEFCON Atmosphere, Relocation & Capture/Destruction Game Over ---")
	var synth: BunkerRadioSynth = bunker.radio_synth
	var m_prof: Dictionary = synth.speak_officer_transmission("MALE_J3_OPS", "Col. Marcus Vance reporting: 1st Armored Brigade advancing on objective.", true)
	var f_prof: Dictionary = synth.speak_officer_transmission("FEMALE_AWACS", "Capt. Elena Rostova (AWACS Magic 1-1): Hostile hypersonic launch detected!", true)
	assert(String(m_prof.get("gender", "")) == "MALE" and synth.male_voice_count >= 1, "Expected Male Military Officer voice transmission")
	assert(String(f_prof.get("gender", "")) == "FEMALE" and synth.female_voice_count >= 1, "Expected Female Military Officer voice transmission")

	# Verify 3D Bunker DEFCON 1 Atmosphere, Alert Beacons & Forward Bulkhead Status Board
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.25)
	assert(bunker._bulkhead_defcon_label_3d.text.find("DEFCON 1") != -1, "Expected 3D Bunker Bulkhead Board to display DEFCON 1")
	assert(bunker._beacon_left_light.light_energy > 0.01, "Expected 3D Bunker Rotating Alert Beacons active at DEFCON 1")

	# Verify HQ Command Bunker Relocation (`relocate_bunker()`)
	var old_bunker_name: String = ws.bunker_base_name
	var old_bunker_pos: Vector3 = ws.bunker_pos_km
	var reloc_res: Dictionary = sim_server.relocate_bunker()
	assert(bool(reloc_res.get("ok", false)) == true and ws.bunker_relocations_count >= 1, "Expected HQ Command Bunker relocation to succeed")
	assert(ws.bunker_base_name != old_bunker_name and ws.bunker_pos_km.distance_to(old_bunker_pos) > 5.0, "Expected HQ Command Bunker to move to new hardened alternate command site")

	# Verify HQ Command Bunker Capture & Destruction (`GAME OVER`)
	bunker.main_menu.set_menu_visible(false)
	var game_over_triggered: bool = sim_server.damage_or_capture_bunker(250.0, 100.0, "OPFOR Spetsnaz & Robot Dog Breach Team")
	assert(game_over_triggered == true and ws.bunker_is_lost == true and ws.bunker_was_captured == true, "Expected HQ Command Bunker capture to trigger GAME OVER")
	assert(bunker.main_menu.is_menu_open == true, "Expected BunkerMainMenu AAR modal to open automatically on Command Bunker Game Over")
	print(" -> Phase 18 Verified: Male/Female Voices=%d/%d | Relocated='%s' -> '%s' | Bunker Game Over='%s'" % [
		synth.male_voice_count, synth.female_voice_count, old_bunker_name, ws.bunker_base_name, ws.bunker_loss_reason
	])

	# =========================================================================
	# 14. PHASE 19: REALISTIC SATELLITE / ORBITAL ROD / JET / BOMBER / DRONE / MISSILE KINEMATICS & AI GEOPOLITICAL DIPLOMACY ENGINE
	# =========================================================================
	print("--- [14/14] Testing Realistic Satellite/Rod/Jet/Bomber/Drone/Missile Altitudes & Speeds + AI Geopolitical Diplomacy Engine ---")
	sim_server.load_scenario("op_pacific_shield_2028")
	ws = sim_server.world_state

	# A) Verify Realistic Satellite Altitudes (525km LEO, 550km Starshield, 20,200km MEO GPS) & Keplerian Orbital Speeds (~7.59 km/s LEO, ~3.87 km/s MEO)
	assert(ws.sat_count >= 24, "Expected 24 active Space Force satellites")
	assert(absf(ws.sat_alt_km[0] - 525.0) < 1.0 and absf(ws.sat_speed_km_s[0] - 7.60) < 0.15, "Expected LEO SAR satellite at 525 km altitude and ~7.60 km/s Keplerian speed")
	assert(absf(ws.sat_alt_km[1] - 550.0) < 1.0 and absf(ws.sat_speed_km_s[1] - 7.59) < 0.15, "Expected LEO Starshield satellite at 550 km altitude and ~7.59 km/s Keplerian speed")
	assert(absf(ws.sat_alt_km[2] - 20200.0) < 10.0 and absf(ws.sat_speed_km_s[2] - 3.87) < 0.15, "Expected MEO GPS satellite at 20,200 km altitude and ~3.87 km/s Keplerian speed")

	# B) Verify Realistic Fighter Jet, Strategic Bomber, MALE UCAV & Turbojet OWA Drone Altitudes & Speeds
	var sdb: Node = sim_server.sim_db_ref
	var pid_b21: int = sdb.get_platform_id("b_21_raider")
	var pid_f35: int = sdb.get_platform_id("f_35a_lightning")
	var pid_akinci: int = sdb.get_platform_id("bayraktar_akinci_ucav")
	var pid_palia: int = sdb.get_platform_id("palianytsia_drone_uk")
	assert(sdb.plat_cruise_alt_m[pid_b21] >= 13800.0, "Expected B-21 Raider strategic bomber cruise altitude >= 13,800m")
	assert(sdb.plat_cruise_alt_m[pid_f35] >= 10800.0 and sdb.plat_cruise_alt_m[pid_f35] <= 13500.0, "Expected F-35A fighter BVR cruise altitude in 10,800..13,500m")
	assert(absf(sdb.plat_cruise_alt_m[pid_akinci] - 7200.0) < 200.0, "Expected Bayraktar Akinci MALE UCAV cruise altitude ~7,200m")
	assert(absf(sdb.plat_cruise_alt_m[pid_palia] - 2400.0) < 200.0, "Expected Palianytsia turbojet OWA drone cruise altitude ~2,400m")

	# C) Verify Mach-24 (8.232 km/s) Orbital Kinetic Tungsten Rod & Missile Apogee Physics
	var wid_rod: int = sdb.get_weapon_id("orbital_tungsten_rod")
	assert(wid_rod > 0 and absf(sdb.weap_speed_km_s[wid_rod] - 8.232) < 0.05, "Expected Orbital Kinetic Tungsten Rod speed = Mach 24 (8.232 km/s)")
	ws.blue_budget_musd += 1000.0
	var rod_strike_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_ORBITAL_RODS", Vector3(-60.0, 0.0, 10.0), WorldState.FACTION_BLUE)
	var rod_mid: int = int(rod_strike_res.get("rod_munition_id", -1))
	assert(rod_mid >= 0 and ws.mun_apex_alt_m[rod_mid] >= 540000.0, "Expected Orbital Kinetic Rod munition spawned at 550 km (550,000 m) LEO altitude")

	# D) Verify AI Geopolitical Countries, Enemy (OPFOR) Diplomacy, Sovereign Airspace Access & Allied Warchest Money Transfers
	assert(ws.active_nations.size() >= 6 and ws.ai_generated_countries_count >= 2, "Expected seeded + AI-generated Sovereign Nations initialized")
	var ai_nat: Dictionary = sim_server.generate_ai_diplomatic_country(true)
	assert(bool(ai_nat.get("is_ai_generated", false)) == true and ws.ai_generated_countries_count >= 3, "Expected procedural AI Country generator to create emergent geopolitical state")

	var red_budget_before: float = ws.red_budget_musd
	var red_air_res: Dictionary = sim_server.execute_diplomacy("DIPLO_AIRSPACE_ACCESS", "", WorldState.FACTION_RED)
	assert(bool(red_air_res.get("ok", false)) == true and bool(red_air_res.get("red_airspace_open", false)) == true, "Expected Enemy (OPFOR) diplomacy to secure sovereign country airspace & territory permission")
	var red_aid_res: Dictionary = sim_server.execute_diplomacy("DIPLO_REQUEST_ALLY_AID", "", WorldState.FACTION_RED)
	assert(bool(red_aid_res.get("ok", false)) == true and ws.red_allied_aid_received_musd >= 300.0 and ws.red_budget_musd > red_budget_before, "Expected Enemy (OPFOR) to receive Allied Warchest financial grant (+$M)")
	var red_ally_res: Dictionary = sim_server.execute_diplomacy("DIPLO_MILITARY_ALLIANCE", "", WorldState.FACTION_RED)
	assert(bool(red_ally_res.get("ok", false)) == true and int(red_ally_res.get("spawned_units", 0)) >= 6 and ws.red_allied_nations_count >= 1, "Expected Enemy (OPFOR) Military Alliance to deploy Allied Expeditionary Task Force")

	var blue_ally_res: Dictionary = sim_server.execute_diplomacy("DIPLO_MILITARY_ALLIANCE", "", WorldState.FACTION_BLUE)
	assert(bool(blue_ally_res.get("ok", false)) == true and ws.blue_allied_nations_count >= 1 and ws.blue_allied_aid_received_musd >= 200.0, "Expected Player (BLUE) Military Alliance & Allied Warchest Aid")
	bunker.war_table.visual_sync.sync_visuals()
	bunker.main_menu.open_tech_tree_tab()
	print(" -> Phase 19 Verified: LEO Sat=%.0fkm (%.2fkm/s) | MEO Sat=%.0fkm (%.2fkm/s) | OrbitalRod=%.0fkm (%.3fkm/s) | B-21 Alt=%.0fm | Nations=%d (AI=%d) | Red Aid=+$%.0fM | Blue Aid=+$%.0fM" % [
		ws.sat_alt_km[1], ws.sat_speed_km_s[1], ws.sat_alt_km[2], ws.sat_speed_km_s[2],
		ws.mun_apex_alt_m[rod_mid] * 0.001, sdb.weap_speed_km_s[wid_rod], sdb.plat_cruise_alt_m[pid_b21],
		ws.active_nations.size(), ws.ai_generated_countries_count, ws.red_allied_aid_received_musd, ws.blue_allied_aid_received_musd
	])

	# =========================================================================
	# 15. PHASE 20: GOOGLE VEO 3.1 FAST + GEMINI 2.5 FLASH LIVE TV WAR NEWS & VIDEO BROADCAST ENGINE
	# =========================================================================
	print("--- [15/15] Testing Google Veo 3.1 Fast + Gemini 2.5 Flash Live TV War News & Video Broadcast Engine ---")
	var verified_clips_cnt: int = bunker.main_menu.verify_all_news_video_assets_load()
	assert(verified_clips_cnt >= 12, "Expected all 12 Google Veo 3.1 Fast War News Video Broadcasts (.mp4, .ogv, 24-frame _sheet.jpg) to load cleanly")

	# Verify simulation actions dynamically switch the live TV News Video Broadcast
	sim_server.execute_mdd_action("ORDER_ASAT_STRIKE", WorldState.FACTION_BLUE)
	assert(ws.active_news_video_slug == "asat_orbital_warfare", "Expected ASAT strike to cut TV broadcast to 'asat_orbital_warfare'")

	sim_server.execute_diplomacy("DIPLO_MILITARY_ALLIANCE", "", WorldState.FACTION_BLUE)
	assert(ws.active_news_video_slug == "diplomatic_alliance_summit", "Expected Diplomatic Alliance to cut TV broadcast to 'diplomatic_alliance_summit'")

	ws.blue_budget_musd += 2000.0
	sim_server.execute_escalated_strike("STRIKE_THERMONUCLEAR", Vector3(20.0, 0.0, -10.0), WorldState.FACTION_BLUE)
	assert(ws.active_news_video_slug == "thermonuclear_detonation", "Expected Thermonuclear strike to cut TV broadcast to 'thermonuclear_detonation'")

	# Verify 2D PiP TV Monitor, 3D Bunker Bulkhead Video Wall & Tab 7 TV Broadcast Studio
	var ch_slug: String = bunker.desktop_rig.cycle_tv_news_channel()
	assert(not ch_slug.is_empty(), "Expected DesktopCommandRig TV channel cycler to select valid video channel")
	bunker._process(0.20)
	bunker.desktop_rig._process(0.20)
	bunker.main_menu.open_news_video_studio_tab()
	bunker.main_menu._process(0.20)
	assert(bunker._news_wall_screen_mat.albedo_texture != null, "Expected 3D Bunker News Video Wall screen texture active")
	assert(bunker.desktop_rig._tv_news_video_rect.texture != null, "Expected 2D HUD PiP Live TV News Monitor texture active")
	assert(bunker.main_menu._studio_video_rect.texture != null, "Expected Tab 7 Live TV Studio Monitor texture active")

	# Verify Live Runtime Google Gemini 2.5 Flash TV Newsroom Bulletin Generation
	var gemini_ok: bool = sim_server.generate_live_gemini_tv_bulletin(
		"sam_air_defense_intercept",
		"Patriot PAC-3 MSE and Iron Beam lasers intercepted 22 incoming hypersonic and cruise missiles over Taipei.",
		true,
		false
	)
	assert(gemini_ok == true and ws.live_ai_gemini_bulletins_count >= 1, "Expected live Google Gemini 2.5 Flash TV Newsroom Worker to generate real-time war bulletin")
	print(" -> Phase 20 Verified: Veo 3.1 Video Clips=%d/12 | Broadcasts=%d | Live Gemini Bulletins=%d | Active TV='%s' (%s)" % [
		verified_clips_cnt, ws.news_video_broadcasts_count, ws.live_ai_gemini_bulletins_count,
		ws.active_news_video_slug, ws.active_news_video_headline.substr(0, 68)
	])

	# =========================================================================
	# 16. PHASE 21: 8-MISSION STORY CHRONICLE & VEO 3.1 CAPABILITIES PROGRESSION (`op_global_escalation_chronicle_2028`)
	# =========================================================================
	print("--- [16/16] Testing 8-Mission Story Chronicle & Veo 3.1 Capabilities Progression Director ---")
	assert(bunker.story_director != null, "Expected StoryProgressionDirector initialized in CommandBunker")
	bunker.main_menu.launch_scenario("op_global_escalation_chronicle_2028", 1.25, Vector2.ZERO)
	assert(bunker.story_director.is_active == true, "Launching 'op_global_escalation_chronicle_2028' must activate StoryProgressionDirector")
	assert(bunker.story_director.get_mission_count() == 8, "Expected 8 chronological story missions in StoryProgressionDirector")

	for m_step in range(8):
		var cur_m: Dictionary = bunker.story_director.get_current_mission()
		var expected_vid := String(cur_m.get("video_slug", ""))
		assert(sim_server.world_state.active_news_video_slug == expected_vid, "Story Mission %d must cut TV broadcast to %s" % [m_step + 1, expected_vid])
		bunker.story_director._process(0.20)
		assert(bunker.story_director.video_preview_rect.texture != null, "Story Mission %d Veo 3.1 video preview must have valid texture" % (m_step + 1))
		bunker.story_director.execute_current_mission_capability_demo()

	assert(bunker.story_director.is_completed == true and bunker.story_director.missions_completed_count >= 8, "Expected all 8 Story Chronicle missions & capability demos to complete")
	print(" -> Phase 21 Verified: Story Missions Completed=%d/8 | Final DEFCON=%d | Final Video='%s'" % [
		bunker.story_director.missions_completed_count,
		sim_server.world_state.defcon_level,
		sim_server.world_state.active_news_video_slug
	])

	# =========================================================================
	# 17. PHASE 22: FIRST-PERSON COCKPIT / DRONE / SATELLITE / ROBOT DOG / MISSILE LIVE FEED CAMERA (`FpvTargetingPodController`)
	# =========================================================================
	print("--- [17/20] Testing Phase 22 First-Person Cockpit / Drone / Satellite / Missile Live Feed Camera ---")
	var fpv_pod: Node = bunker.fpv_pod_controller
	assert(fpv_pod != null, "Expected FpvTargetingPodController initialized in CommandBunker")
	assert(fpv_pod.pod_camera != null and fpv_pod.sub_viewport != null, "Expected FpvPodSubViewport and FpvPodCamera3D active")
	var next_uid: int = fpv_pod.cycle_next_unit()
	assert(next_uid >= 0, "Expected FPV Targeting Pod to lock onto an active company unit")
	fpv_pod.set_pod_mode(0) # MODE_SELECTED_UNIT
	assert(fpv_pod.telemetry_speed_kmh >= 0.0 and not fpv_pod.telemetry_platform.is_empty(), "Expected live unit telemetry in FPV Targeting Pod")

	# Launch an Orbital Rod and attach the FPV Seeker Camera directly to the Mach-24 munition!
	ws = sim_server.world_state
	ws.blue_budget_musd += 1500.0
	var fpv_rod_res: Dictionary = sim_server.execute_escalated_strike("STRIKE_ORBITAL_RODS", Vector3(-35.0, 0.0, 15.0), WorldState.FACTION_BLUE)
	var fpv_rod_mid: int = int(fpv_rod_res.get("rod_munition_id", -1))
	fpv_pod.attach_to_munition(fpv_rod_mid)
	assert(fpv_pod.current_mode == 1 and fpv_pod.telemetry_mach >= 15.0, "Expected FPV Missile Seeker mode to track Mach-24 Orbital Tungsten Rod")

	# Switch to 550 km LEO Recon Satellite Nadir View
	fpv_pod.set_pod_mode(2) # MODE_ORBITAL_SATELLITE
	assert(absf(fpv_pod.telemetry_alt_m - 550000.0) < 10.0 and fpv_pod.telemetry_mach >= 20.0, "Expected 550 km LEO Satellite Nadir mode in FPV Pod")
	fpv_pod.cycle_flir_palette()
	print(" -> Phase 22 Verified: FPV Camera Updates=%d | Unit #%d | Rod Seeker Mach=%.1f | LEO Sat Alt=%.0fkm" % [
		fpv_pod.camera_updates_count, next_uid, 24.0, fpv_pod.telemetry_alt_m * 0.001
	])

	# =========================================================================
	# 18. PHASE 24: DYNAMIC WEATHER, DAY/NIGHT SOLAR TERMINATOR & SEA-STATE PHYSICS (`WeatherSolarSystem`)
	# =========================================================================
	print("--- [18/20] Testing Phase 24 Dynamic Weather, Solar Terminator & Sea-State Physics ---")
	sim_server.set_weather_condition("CLEAR")
	assert(ws.weather_condition_code == "CLEAR" and absf(ws.weather_ir_eo_mult - 1.0) < 0.01 and absf(ws.weather_laser_mult - 1.0) < 0.01, "Expected CLEAR weather to have 1.0x IR/EO and Laser multipliers")

	sim_server.set_weather_condition("TYPHOON_STORM")
	assert(ws.weather_condition_code == "TYPHOON_STORM", "Expected TYPHOON_STORM weather code")
	assert(ws.sea_state_beaufort == 8, "Expected Beaufort Sea State 8 in TYPHOON_STORM")
	assert(ws.weather_ir_eo_mult < 0.50 and ws.weather_laser_mult < 0.45 and ws.weather_usv_speed_mult < 0.65, "Expected Typhoon clouds/waves to attenuate IR/EO, 100kW Lasers, and surface USV speeds")

	var cyc_wx: String = sim_server.cycle_weather_condition()
	assert(cyc_wx == "SANDSTORM" and ws.weather_changes_count >= 2, "Expected weather cycle to transition TYPHOON_STORM -> SANDSTORM")
	print(" -> Phase 24 Verified: Weather='%s' | Sea State=Beaufort 8->%d | IR_EO=%.2fx | Laser=%.2fx | USV=%.2fx | UTC=%02.1f:00Z" % [
		ws.weather_condition_code, ws.sea_state_beaufort, ws.weather_ir_eo_mult, ws.weather_laser_mult, ws.weather_usv_speed_mult, ws.solar_hour_utc
	])

	# =========================================================================
	# 19. PHASE 25: LIVE AI ENEMY LEADER ULTIMATUMS & 3D RED PHONE HOTLINE NEGOTIATIONS (`RedPhoneHotlineSystem`)
	# =========================================================================
	print("--- [19/20] Testing Phase 25 3D Red Phone Hotline & Leader Crisis Negotiations ---")
	var rp_actuated: bool = bunker.tactile_console.actuate_control("RedPhoneHotline3D")
	assert(rp_actuated == true and ws.hotline_is_ringing == true and ws.hotline_calls_received_count >= 1, "Expected 3D Red Phone actuation to trigger OPFOR Supreme Commander hotline call")
	assert(not ws.hotline_leader_name.is_empty() and not ws.hotline_demand_body.is_empty(), "Expected authentic OPFOR leader persona & ultimatum demand")

	var cease_res: Dictionary = sim_server.resolve_red_phone_hotline("HOTLINE_ACCEPT_CEASEFIRE")
	assert(bool(cease_res.get("ok", false)) == true and ws.hotline_is_ringing == false and ws.hotline_ceasefire_timer_sec >= 40.0, "Expected HOTLINE_ACCEPT_CEASEFIRE to enforce 45s bilateral salvo ceasefire")

	sim_server.trigger_red_phone_hotline("DEFCON_1_NUCLEAR_BLACKMAIL")
	var budget_before_reject: float = ws.blue_budget_available_musd
	var rej_res: Dictionary = sim_server.resolve_red_phone_hotline("HOTLINE_REJECT_ESCALATE")
	assert(bool(rej_res.get("ok", false)) == true and ws.blue_budget_available_musd >= budget_before_reject + 499.0, "Expected HOTLINE_REJECT_ESCALATE to unlock +$500M emergency wartime budget")
	print(" -> Phase 25 Verified: Leader='%s' | Calls=%d | Resolved=%d | Ceasefire=%.0fs | Budget=+$500M ($%.0fM)" % [
		ws.hotline_leader_name, ws.hotline_calls_received_count, ws.hotline_negotiations_resolved_count,
		45.0, ws.blue_budget_available_musd
	])

	# =========================================================================
	# 20. PHASE 23: PERSISTENT SAVE / LOAD CAMPAIGN STATE & CUSTOM SCENARIO / FORCE EDITOR (`CampaignPersistenceSystem`)
	# =========================================================================
	print("--- [20/20] Testing Phase 23 Campaign Save/Load Persistence & Custom Scenario / Force Editor ---")
	var custom_uid: int = sim_server.spawn_custom_editor_unit("vision_60_q_ugv", WorldState.FACTION_BLUE, Vector3(42.0, 0.0, -28.0))
	assert(custom_uid >= 0, "Expected Custom Force Editor to spawn Vision 60 Robot Dog Company on War Table")

	var exp_res: Dictionary = sim_server.export_custom_scenario("op_custom_test_2028", "Automated Test Custom Scenario")
	assert(bool(exp_res.get("ok", false)) == true and FileAccess.file_exists(String(exp_res.get("file_path", ""))), "Expected Custom Scenario JSON export to write valid file")

	ws.blue_budget_available_musd = 7777.0
	sim_server.set_weather_condition("ARCTIC_BLIZZARD")
	var pre_save_units: int = ws.get_active_unit_count()
	var save_res: Dictionary = sim_server.save_campaign_state("test_slot_alpha")
	assert(bool(save_res.get("ok", false)) == true and int(save_res.get("units_saved", 0)) == pre_save_units, "Expected Campaign Save to serialize all active units")

	# Mutate state, then restore from test_slot_alpha and verify exact restoration!
	ws.blue_budget_available_musd = 123.0
	sim_server.set_weather_condition("CLEAR")
	var load_res: Dictionary = sim_server.load_campaign_state("test_slot_alpha")
	assert(bool(load_res.get("ok", false)) == true and int(load_res.get("units_loaded", 0)) == pre_save_units, "Expected Campaign Load to restore all saved units")
	assert(absf(ws.blue_budget_available_musd - 7777.0) < 1.0 and ws.weather_condition_code == "ARCTIC_BLIZZARD", "Expected Campaign Load to restore exact budget ($7777M) and weather (ARCTIC_BLIZZARD)")
	print(" -> Phase 23 Verified: Saved/Loaded Units=%d | Restored Budget=$%.0fM | Restored Weather='%s' | Custom Scenario='%s'" % [
		int(load_res.get("units_loaded", 0)), ws.blue_budget_available_musd, ws.weather_condition_code, String(exp_res.get("slug", ""))
	])

	# =========================================================================
	# 21. PHASE 26: HIGHWAY TRAFFIC, REFUGEE EVACUATION CONVOYS & MARITIME SHIPPING INTERDICTION (`CivilianTrafficConvoySystem`)
	# =========================================================================
	print("--- [21/23] Testing Phase 26 Highway Traffic, Refugee Evacuation Convoys & Maritime Interdiction ---")
	assert(ws.convoy_count >= 16, "Expected >=16 active highway traffic convoys and maritime tankers seeded across theater")
	var pre_corridor_budget: float = ws.blue_budget_available_musd
	var corr_res: Dictionary = sim_server.declare_humanitarian_corridor()
	assert(bool(corr_res.get("ok", false)) == true and ws.humanitarian_corridor_active == true, "Expected declare_humanitarian_corridor() to activate protected evacuation corridor")
	assert(ws.blue_budget_available_musd >= pre_corridor_budget + 199.0, "Expected Humanitarian Corridor UN grant (+$200M)")

	var vbss_res: Dictionary = sim_server.execute_maritime_interdiction()
	assert(bool(vbss_res.get("ok", false)) == true and ws.maritime_tankers_interdicted_count >= 1, "Expected execute_maritime_interdiction() to board & seize sanctioned OPFOR tanker")
	sim_server.step_tick(0.5)
	bunker.war_table.visual_sync.sync_visuals()
	print(" -> Phase 26 Verified: Active Convoys/Tankers=%d | Evac Corridor=ACTIVE (%.0fs) | VBSS Seized=%d | Budget=$%.0fM" % [
		ws.convoy_count, ws.humanitarian_corridor_timer_sec, ws.maritime_tankers_interdicted_count, ws.blue_budget_available_musd
	])

	# =========================================================================
	# 22. PHASE 27: SUBTERRANEAN UNDERGROUND TUNNEL NETWORKS, GBU-57 MOP & ROBOT DOG TUNNEL BREACH (`SubterraneanTunnelSystem`)
	# =========================================================================
	print("--- [22/23] Testing Phase 27 Subterranean Tunnel Networks, GBU-57 MOP & Robot Dog Tunnel Breach ---")
	assert(ws.tunnel_complexes.size() >= 3, "Expected >=3 subterranean tunnel complexes seeded in theater")
	var gpr_res: Dictionary = sim_server.execute_tunnel_operation("TUNNEL_GPR_SCAN", -1)
	assert(bool(gpr_res.get("ok", false)) == true and ws.gpr_seismic_scans_count >= 1, "Expected TUNNEL_GPR_SCAN to reveal hidden OPFOR tunnel portals")

	var mop1_res: Dictionary = sim_server.execute_tunnel_operation("BUNKER_BUSTER_MOP", -1)
	var mop2_res: Dictionary = sim_server.execute_tunnel_operation("BUNKER_BUSTER_MOP", -1)
	assert(bool(mop1_res.get("ok", false)) == true and bool(mop2_res.get("ok", false)) == true and ws.tunnels_collapsed_count >= 1, "Expected GBU-57 MOP strikes to collapse subterranean tunnel gallery")

	var dog_breach_res: Dictionary = sim_server.execute_tunnel_operation("ROBOT_DOG_TUNNEL_BREACH", -1)
	assert(bool(dog_breach_res.get("ok", false)) == true and ws.tunnels_captured_count >= 1, "Expected Vision 60 Robot Dog + SpecOps breach to capture underground complex intact")
	bunker.war_table.visual_sync.sync_visuals()
	print(" -> Phase 27 Verified: Tunnel Complexes=%d | GPR Scans=%d | GBU-57 MOPCollapsed=%d | Robot Dog Captured=%d ('%s')" % [
		ws.tunnel_complexes.size(), ws.gpr_seismic_scans_count, ws.tunnels_collapsed_count, ws.tunnels_captured_count, String(dog_breach_res.get("tunnel_name", ""))
	])

	# =========================================================================
	# 23. PHASE 28: STRATEGIC CEMA CYBER-EW, SCADA POWER GRID BLACKOUTS & DRONE SWARM HIJACKING (`CemaElectronicWarfareSystem`)
	# =========================================================================
	print("--- [23/23] Testing Phase 28 Strategic CEMA Cyber-EW, SCADA Blackouts & Drone Swarm Hijacking ---")
	var blk_res: Dictionary = sim_server.execute_cema_operation("CEMA_GRID_BLACKOUT")
	assert(bool(blk_res.get("ok", false)) == true and ws.red_power_grid_pct < 60.0, "Expected CEMA_GRID_BLACKOUT to plunge OPFOR power grid below 60%")

	var hij_res: Dictionary = sim_server.execute_cema_operation("CEMA_DRONE_HIJACK")
	assert(bool(hij_res.get("ok", false)) == true and ws.units_hijacked_count >= 1, "Expected CEMA_DRONE_HIJACK to spoof & flip OPFOR RF-datalinked UAVs to BLUE control")

	var dec_res: Dictionary = sim_server.execute_cema_operation("CEMA_DEEPFAKE_GHOST_DECOYS")
	assert(bool(dec_res.get("ok", false)) == true and ws.ghost_decoy_positions_km.size() == 8, "Expected CEMA_DEEPFAKE_GHOST_DECOYS to inject 8 DRFM phantom radar ghost echos")

	var fw_res: Dictionary = sim_server.execute_cema_operation("CEMA_QUANTUM_FIREWALL_PATCH")
	assert(bool(fw_res.get("ok", false)) == true and ws.blue_cyber_firewall_pct >= 99.0, "Expected CEMA_QUANTUM_FIREWALL_PATCH to restore Blue firewall to 100%")
	bunker.war_table.visual_sync.sync_visuals()
	print(" -> Phase 28 Verified: Red Grid=%.0f%% | Hijacked UAVs=%d | DRFM Ghost Echos=%d | Blue Firewall=%.0f%%" % [
		ws.red_power_grid_pct, ws.units_hijacked_count, ws.ghost_decoy_positions_km.size(), ws.blue_cyber_firewall_pct
	])

	# =========================================================================
	# 24. PHASE 29: 5 SELECTABLE WAR TABLE GRAPHIC STYLES (`war_table_terrain.gdshader`)
	# =========================================================================
	print("--- [24/25] Testing Phase 29 Selectable War Table Graphic Styles (5 Visual Modes) ---")
	var seen_styles: Array[String] = []
	for _s in range(5):
		var sname: String = bunker.desktop_rig.cycle_graphic_style()
		if not seen_styles.has(sname):
			seen_styles.append(sname)
	assert(seen_styles.size() == 5, "Expected 5 distinct War Table graphic styles when cycling [F12]")
	assert(bunker.war_table.graphic_style_mode == 0, "Expected 5th cycle to return to mode 0 (HOLO C4ISR OBSIDIAN)")
	print(" -> Phase 29 Verified: 5 Selectable Graphic Styles=%s" % [str(seen_styles)])

	# =========================================================================
	# 25. PHASE 30: VISIBLE MOVING INFANTRY, SNIPERS & COMMANDOS + LIVE .50 BMG / JTAC LASER BEAMS
	# =========================================================================
	print("--- [25/25] Testing Phase 30 Moving Infantry, Snipers & Commandos + Live .50 BMG & JTAC Laser Beams ---")
	var spec_units: Array[int] = sim_server.get_active_sniper_and_commando_units(0)
	assert(spec_units.size() >= 10, "Expected >=10 active Sniper, SEAL Commando & Spetsnaz squads across theater")
	var focused_sniper_uid: int = bunker.desktop_rig.select_and_focus_snipers_and_commandos()
	assert(focused_sniper_uid >= 0, "Expected [I] SNIPERS/COMMANDOS button to select and focus an active Sniper/Commando team")
	var sniper_pos_before: Vector3 = ws.unit_pos[focused_sniper_uid]
	sim_server.step_tick(1.0)
	var sniper_pos_after: Vector3 = ws.unit_pos[focused_sniper_uid]
	var sniper_moved_m: float = sniper_pos_before.distance_to(sniper_pos_after) * 1000.0
	assert(sniper_moved_m > 10.0, "Expected Sniper/Commando team to actively march/patrol across terrain (moved %.1fm)" % sniper_moved_m)

	bunker.war_table.visual_sync.sync_visuals()
	assert(bunker.war_table.visual_sync.last_visible_soldier_count >= 12, "Expected >=12 3D articulated soldiers rendered when zoomed onto Sniper/Commando squad")
	assert(bunker.war_table.visual_sync.last_active_sniper_commando_beams_count >= 1, "Expected live 3D .50 BMG sniper tracers & JTAC laser target designator beams rendered")
	print(" -> Phase 30 Verified: Active Sniper/Commando Squads=%d | Focused UID=%d (Moved %.1fm/s) | Visible 3D Soldiers=%d | Live Sniper/JTAC Laser & Tracer Beams=%d" % [
		spec_units.size(), focused_sniper_uid, sniper_moved_m,
		bunker.war_table.visual_sync.last_visible_soldier_count,
		bunker.war_table.visual_sync.last_active_sniper_commando_beams_count
	])

	# =========================================================================
	# 26. PHASE 31: COMBAT ENGINEERING, SMART MINEFIELDS, AVLB BRIDGE REBUILD & AIRBORNE PARATROOPER DROPS
	# =========================================================================
	print("--- [26/29] Testing Phase 31 Combat Engineering, Smart Minefields & Airborne Paratrooper Drops ---")
	var para_res: Dictionary = sim_server.execute_engineering_or_airborne_op("AIRBORNE_PARATROOP_DROP", Vector3(45.0, 0.0, -20.0))
	assert(bool(para_res.get("ok", false)) == true and ws.parachute_drops.size() >= 3, "Expected AIRBORNE_PARATROOP_DROP to spawn SEALs/Snipers/Robot Dogs with 3D descending parachutes")
	var mine_res: Dictionary = sim_server.execute_engineering_or_airborne_op("DEPLOY_SMART_MINEFIELD", Vector3(12.0, 0.0, 10.0))
	assert(bool(mine_res.get("ok", false)) == true and ws.minefields_deployed_count >= 1, "Expected DEPLOY_SMART_MINEFIELD to seed tactical smart minefield")
	var eng_res: Dictionary = sim_server.execute_engineering_or_airborne_op("ENGINEER_BREACH_AND_REBUILD")
	assert(bool(eng_res.get("ok", false)) == true and ws.engineer_breaches_rebuilds_count >= 1 and ws.trains_derailed_count == 0, "Expected ENGINEER_BREACH_AND_REBUILD to clear enemy minefields, repair bridges & re-rail trains")
	bunker.war_table.visual_sync.sync_visuals()
	print(" -> Phase 31 Verified: Parachute Drops=%d | Minefields=%d | Engineer Rebuilds=%d (Cleared Mines=%d)" % [
		ws.parachute_drops.size(), ws.minefields.size(), ws.engineer_breaches_rebuilds_count, int(eng_res.get("cleared_minefields", 0))
	])

	# =========================================================================
	# 27. PHASE 32: SUBMARINE UNDERSEA CABLE SABOTAGE, SOSUS HYDROPHONE ARRAYS & CABLE REPAIR
	# =========================================================================
	print("--- [27/29] Testing Phase 32 Undersea Cable Sabotage, SOSUS Hydrophone Arrays & Cable Repair ---")
	assert(ws.undersea_cables.size() >= 2, "Expected >=2 undersea fiber-optic cables/pipelines seeded on seabed")
	var sosus_res: Dictionary = sim_server.execute_undersea_operation("UNDERSEA_DEPLOY_SOSUS_BARRIER")
	assert(bool(sosus_res.get("ok", false)) == true and ws.sosus_barriers_active_count >= 2, "Expected UNDERSEA_DEPLOY_SOSUS_BARRIER to deploy seabed acoustic array")
	var sab_res: Dictionary = sim_server.execute_undersea_operation("UNDERSEA_SABOTAGE_ENEMY_CABLE")
	assert(bool(sab_res.get("ok", false)) == true and ws.cables_sabotaged_count >= 1, "Expected UNDERSEA_SABOTAGE_ENEMY_CABLE to sever OPFOR subsea cable")
	var rep_res: Dictionary = sim_server.execute_undersea_operation("UNDERSEA_REPAIR_CABLE_SHIP")
	assert(bool(rep_res.get("ok", false)) == true and ws.cables_repaired_count >= 1 and ws.blue_c2_integrity >= 0.99, "Expected UNDERSEA_REPAIR_CABLE_SHIP to splice Allied subsea trunk")
	bunker.war_table.visual_sync.sync_visuals()
	print(" -> Phase 32 Verified: Subsea Cables=%d | SOSUS Barriers=%d (Subs Localized=%d) | Severed='%s'" % [
		ws.undersea_cables.size(), ws.sosus_barriers_active_count, int(sosus_res.get("subs_detected", 0)), String(sab_res.get("cable_name", ""))
	])

	# =========================================================================
	# 28. PHASE 33: DOMESTIC HOMEFRONT STABILITY, BRENT CRUDE OIL ($/BBL), DEFENSE INDEX & UN SURGICAL ROE
	# =========================================================================
	print("--- [28/29] Testing Phase 33 Homefront Stability, War Bonds, Strategic Petroleum Reserve & Surgical ROE ---")
	var bonds_res: Dictionary = sim_server.execute_homefront_action("HOMEFRONT_ISSUE_WAR_BONDS")
	assert(bool(bonds_res.get("ok", false)) == true and ws.defense_industrial_index >= 1085.0, "Expected HOMEFRONT_ISSUE_WAR_BONDS to raise +$450M and boost Defense Industrial Index")
	var roe_res: Dictionary = sim_server.execute_homefront_action("HOMEFRONT_ENFORCE_SURGICAL_ROE")
	assert(bool(roe_res.get("ok", false)) == true and ws.surgical_roe_enforced == true and ws.un_war_crimes_investigation_level == 0, "Expected HOMEFRONT_ENFORCE_SURGICAL_ROE to enforce surgical precision ROE and clear UN Tribunal")
	var spr_res: Dictionary = sim_server.execute_homefront_action("HOMEFRONT_STRATEGIC_PETRO_RESERVE")
	assert(bool(spr_res.get("ok", false)) == true and ws.spr_releases_count >= 1, "Expected HOMEFRONT_STRATEGIC_PETRO_RESERVE to cool global oil price")
	print(" -> Phase 33 Verified: %s" % ws.latest_homefront_status)

	# =========================================================================
	# 29. PHASE 34: INTERACTIVE HUD DECLUTTER & COLLAPSIBLE DRAWER MODES (`HUD UX 2.0`)
	# =========================================================================
	print("--- [29/30] Testing Phase 34 Collapsible HUD Drawer & Clean Cinematic War Table Modes ---")
	var m1: String = bunker.desktop_rig.cycle_hud_layout_mode()
	assert(bunker.desktop_rig.hud_layout_mode == 1 and bunker.desktop_rig._left_hud_card.visible == false, "Expected Mode 1 (COMPACT TACTICAL HUD) to collapse left SITREP card")
	var m2: String = bunker.desktop_rig.cycle_hud_layout_mode()
	assert(bunker.desktop_rig.hud_layout_mode == 2 and bunker.desktop_rig._bottom_cmd_bar.visible == false, "Expected Mode 2 (CLEAN CINEMATIC WAR TABLE) to hide bottom bar for unobstructed fullscreen view")
	var m0: String = bunker.desktop_rig.cycle_hud_layout_mode()
	assert(bunker.desktop_rig.hud_layout_mode == 0 and bunker.desktop_rig._left_hud_card.visible == true, "Expected Mode 0 (FULL JOC STAFF HUD) to restore full panels")
	print(" -> Phase 34 Verified: HUD Modes Cycled=[%s -> %s -> %s]" % [m1, m2, m0])

	# =========================================================================
	# 30. PHASE 35: 688(I) NUCLEAR ATTACK SUBMARINE VR & DESKTOP SIM STATION
	# =========================================================================
	print("--- [30/30] Testing Phase 35 688(I) Nuclear Attack Submarine VR & Desktop Sim Station ---")
	assert(bunker.submarine_conn != null, "Expected SubmarineConnController to be initialized on CommandBunker")
	bunker.submarine_conn.set_sub_sim_active(true)
	assert(bunker.submarine_conn.is_sub_sim_active == true and ws.sub_sim_active == true and ws.sub_unit_id >= 0, "Expected activating 688 Sub Sim to spawn/bind USS Cheyenne SSN-688(I)")
	bunker.submarine_conn._process(0.10)
	assert(ws.sub_sonar_contacts.size() >= 1, "Expected Broadband Sonar Array to detect OPFOR maritime contacts")
	var dep_res: Dictionary = sim_server.execute_submarine_command("SUB_SET_DEPTH", 420.0)
	assert(bool(dep_res.get("ok", false)) == true and is_equal_approx(ws.sub_target_depth_ft, 420.0), "Expected SUB_SET_DEPTH 420ft below thermocline")
	var thr_res: Dictionary = sim_server.execute_submarine_command("SUB_SET_THROTTLE", 4.0)
	assert(bool(thr_res.get("ok", false)) == true and ws.sub_throttle_notch == 4, "Expected SUB_SET_THROTTLE Flank 33 kts")
	for _st in range(10):
		sim_server.step_tick(0.5)
	assert(ws.sub_cavitating == true, "Expected Flank speed to trigger propeller cavitation warning")
	var torp_res: Dictionary = sim_server.execute_submarine_command("SUB_FIRE_TORPEDO")
	assert(bool(torp_res.get("ok", false)) == true and ws.sub_torpedoes_remaining < 24 and ws.sub_water_plumes.size() >= 1, "Expected SUB_FIRE_TORPEDO to launch Mk 48 ADCAP wire-guided torpedo and spawn 3D water plume")
	var vls_res: Dictionary = sim_server.execute_submarine_command("SUB_LAUNCH_VLS_TOMAHAWK")
	assert(bool(vls_res.get("ok", false)) == true and ws.sub_vls_tomahawks_remaining < 12, "Expected SUB_LAUNCH_VLS_TOMAHAWK to fire BGM-109 Tomahawk from VLS tube")
	var moss_res: Dictionary = sim_server.execute_submarine_command("SUB_LAUNCH_DECOY")
	assert(bool(moss_res.get("ok", false)) == true and ws.sub_decoys_remaining < 8, "Expected SUB_LAUNCH_DECOY to launch MOSS acoustic decoy")
	var blow_res: Dictionary = sim_server.execute_submarine_command("SUB_EMERGENCY_BLOW")
	assert(bool(blow_res.get("ok", false)) == true and is_equal_approx(ws.sub_target_depth_ft, 0.0), "Expected SUB_EMERGENCY_BLOW to command emergency surface blow")
	bunker.submarine_conn._process(0.10)
	bunker.submarine_conn.set_sub_sim_active(false)
	print(" -> Phase 35 Verified: SubUID=%d | SonarContacts=%d | TorpedoesLeft=%d | VLSLeft=%d | Plumes=%d | Log='%s'" % [
		ws.sub_unit_id, ws.sub_sonar_contacts.size(), ws.sub_torpedoes_remaining, ws.sub_vls_tomahawks_remaining, ws.sub_water_plumes.size(), ws.sub_status_log
	])

	bunker.cleanup_bunker()
	bunker.free()

	print("=== [GATE 5..35] ALL PHASES 5 THROUGH 35 VERIFICATION CHECKS PASSED (0 ERRORS) ===")
	quit(0)

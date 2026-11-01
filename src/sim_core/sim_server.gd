class_name SimServer
extends Node
## Drives the 10 Hz data-oriented simulation tick (supports both `WorkerThreadPool` background tasks
## and deterministic synchronous `step_tick()` for headless testing & replays).
## Seeds all 6 Global Flashpoint Scenarios across 5 Theaters with hierarchical units, Logistics, and Replay Recording.

const LogisticsSystemScript := preload("res://src/sim_core/systems/logistics_system.gd")
const UnitTacticalAISystemScript := preload("res://src/sim_core/systems/unit_tactical_ai_system.gd")
const CivilianDensitySystemScript := preload("res://src/sim_core/systems/civilian_density_system.gd")
const SimLodSystemScript := preload("res://src/sim_core/systems/sim_lod_system.gd")
const StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")
const TerrainInfrastructureSystemScript := preload("res://src/sim_core/systems/terrain_infrastructure_system.gd")
const GlobalOrbatSystemScript := preload("res://src/sim_core/systems/global_orbat_system.gd")
const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")
const DiplomacySystemScript := preload("res://src/sim_core/systems/diplomacy_system.gd")
const WarNewsVideoSystemScript := preload("res://src/sim_core/systems/war_news_video_system.gd")
const WeatherSolarSystemScript := preload("res://src/sim_core/systems/weather_solar_system.gd")
const RedPhoneHotlineSystemScript := preload("res://src/sim_core/systems/red_phone_hotline_system.gd")
const CampaignPersistenceSystemScript := preload("res://src/sim_core/systems/campaign_persistence_system.gd")
const CivilianTrafficConvoySystemScript := preload("res://src/sim_core/systems/civilian_traffic_convoy_system.gd")
const SubterraneanTunnelSystemScript := preload("res://src/sim_core/systems/subterranean_tunnel_system.gd")
const CemaElectronicWarfareSystemScript := preload("res://src/sim_core/systems/cema_electronic_warfare_system.gd")
const CombatEngineeringAirborneSystemScript := preload("res://src/sim_core/systems/combat_engineering_airborne_system.gd")
const UnderseaWarfareSystemScript := preload("res://src/sim_core/systems/undersea_warfare_system.gd")
const HomefrontEconomySystemScript := preload("res://src/sim_core/systems/homefront_economy_system.gd")
const NuclearSubmarineSystemScript := preload("res://src/sim_core/systems/nuclear_submarine_system.gd")
const SwarmIntelligenceSystemScript := preload("res://src/sim_core/systems/swarm_intelligence_system.gd")
const UnitTacticalTrialsSystemScript := preload("res://src/sim_core/systems/unit_tactical_trials_system.gd")
const ReplayRecorderScript := preload("res://src/sim_core/replay_recorder.gd")
const DefconEscalationSystemScript := preload("res://src/sim_core/systems/defcon_escalation_system.gd")
const CoordinatedStrikeSystemScript := preload("res://src/sim_core/systems/coordinated_strike_system.gd")
const TacticalDoctrineFormationSystemScript := preload("res://src/sim_core/systems/tactical_doctrine_formation_system.gd")

const BASE_TICK_DT := 0.10 # 10 Hz simulation tick (100 ms)

var world_state: WorldState = WorldState.new()
var spatial_grid: SpatialHashGrid = SpatialHashGrid.new()
var snapshot_buffer: RenderSnapshot = RenderSnapshot.new()
var replay_recorder: RefCounted = ReplayRecorderScript.new()
var weather_solar_system: RefCounted = WeatherSolarSystemScript.new()
var red_phone_hotline_system: RefCounted = RedPhoneHotlineSystemScript.new()
var campaign_persistence_system: RefCounted = CampaignPersistenceSystemScript.new()
var defcon_escalation_system: RefCounted = DefconEscalationSystemScript.new()
var cs_kernel: Object = null

var current_scenario_slug: String = "op_pacific_shield_2028"
var default_army_group_unit_target: int = 160 if OS.has_feature("android") else 5000
var use_worker_thread: bool = false
var _tick_accumulator: float = 0.0
var _worker_task_id: int = -1
var _fow_texture: ImageTexture = null
var _infra_texture: ImageTexture = null
var _fow_update_counter: int = 0
var _last_cached_destroyed_count: int = -1
var _last_news_video_sim_sec: float = -999.0


var sim_db_ref: Node = null
var command_bus_ref: Node = null
var signal_bus_ref: Node = null


func _ready() -> void:
	_resolve_autoloads()


func _resolve_autoloads() -> void:
	if cs_kernel == null:
		cs_kernel = SimLodSystemScript.create_cs_kernel()
	if sim_db_ref == null and is_inside_tree():
		sim_db_ref = get_node_or_null("/root/SimDB")
	if command_bus_ref == null and is_inside_tree():
		command_bus_ref = get_node_or_null("/root/CommandBus")
	if signal_bus_ref == null and is_inside_tree():
		signal_bus_ref = get_node_or_null("/root/SignalBus")


func set_sim_focus(center_km: Vector2, zoom: float, sel_uid: int = -1) -> void:
	world_state.sim_focus_center_km = center_km
	world_state.sim_focus_zoom = maxf(zoom, 1.0)
	if sel_uid >= -1:
		world_state.selected_unit_id = sel_uid


func setup_references(p_sim_db: Node, p_cmd_bus: Node, p_sig_bus: Node = null) -> void:
	sim_db_ref = p_sim_db
	command_bus_ref = p_cmd_bus
	signal_bus_ref = p_sig_bus


func load_scenario(scenario_slug: String = "op_pacific_shield_2028") -> void:
	_resolve_autoloads()
	assert(sim_db_ref != null, "SimServer requires SimDB reference")
	sim_db_ref.load_database()

	current_scenario_slug = scenario_slug
	world_state.reset()
	replay_recorder.clear()
	if command_bus_ref != null:
		command_bus_ref.clear_all()

	# Resolve theater heightmap & strategic sites for the selected scenario
	var sc_info: Dictionary = sim_db_ref.scenarios_by_slug.get(scenario_slug, {})
	var theater_slug := String(sc_info.get("theater_slug", "strait_theater"))
	if theater_slug.is_empty():
		theater_slug = "strait_theater"
	world_state.active_theater_slug = theater_slug

	var th_info: Dictionary = sim_db_ref.get_theater(theater_slug)
	var hmap_path := String(th_info.get("heightmap_res_path", "res://data/theaters/strait_theater_heightmap.png"))
	world_state.load_heightmap(hmap_path)

	var raw_sites: Array = sim_db_ref.get_sites_for_theater(theater_slug)
	for st in raw_sites:
		var site_copy: Dictionary = st.duplicate(true)
		site_copy["crater_timer_sec"] = 0.0
		site_copy["hp"] = 500.0
		world_state.active_sites.append(site_copy)

	# FEAT-09: Initialize Dynamic DEFCON Escalation System
	if defcon_escalation_system == null:
		defcon_escalation_system = DefconEscalationSystemScript.new()
	var defcon_init: int = int(sc_info.get("defcon_initial", 5))
	var tens_init: float = float(sc_info.get("tension_initial", 10.0))
	defcon_escalation_system.current_defcon = defcon_init
	defcon_escalation_system.tension_score = tens_init
	world_state.defcon_level = defcon_init
	world_state.global_escalation_score = tens_init

	match scenario_slug:
		"op_iron_hound_ridge":
			_seed_scenario_iron_hound_ridge()
		"op_red_strait_swarm":
			_seed_scenario_sea_wolfpack()
		"op_korean_thunder_dmz":
			_seed_scenario_korean_dmz()
		"op_baltic_shield_suwalki":
			_seed_scenario_baltic_suwalki()
		"op_himalayan_sentinel_lac":
			_seed_scenario_himalaya_lac()
		"op_ukraine_donbas_2028":
			_seed_scenario_ukraine_donbas()
		"op_mexico_rio_grande_2028":
			_seed_scenario_mexico_rio_grande()
		"taiwan_strait_blockade_2028":
			_seed_scenario_taiwan_strait_blockade()
		"suwalki_corridor_breach_2028":
			_seed_scenario_suwalki_corridor_breach()
		"second_thomas_shoal_clash_2028":
			_seed_scenario_second_thomas_shoal()
		"giuk_arctic_bastion_2028":
			_seed_scenario_giuk_arctic_bastion()
		_:
			_seed_scenario_pacific_shield_600()

	# Scale all scenarios up to 5,000+ active Army Group units by default!
	if default_army_group_unit_target > world_state.unit_count:
		_populate_army_group_waves(default_army_group_unit_target)

	# Initial pass to populate 1,000,000-Unit Global ORBAT, Defense Budget & Tech Tree, Civilian Density Field, Living Infrastructure, Orbital Constellation, Sim-LOD tiers, spatial hash, sensors, echelon centers, FoW texture, and snapshot
	GlobalOrbatSystemScript.step_global_orbat(world_state, 0.0)
	BudgetTechSystemScript.initialize_scenario_economy(world_state, sim_db_ref, scenario_slug)
	DiplomacySystemScript.initialize_theater_diplomacy(world_state, sim_db_ref, theater_slug)
	WarNewsVideoSystemScript.initialize_scenario_news_video(world_state, sim_db_ref, scenario_slug)
	_last_news_video_sim_sec = 0.0
	CivilianDensitySystemScript.seed_theater_civilian_density(world_state)
	TerrainInfrastructureSystemScript.seed_theater_infrastructure(world_state)
	CivilianTrafficConvoySystemScript.seed_theater_traffic_and_shipping(world_state)
	SubterraneanTunnelSystemScript.seed_theater_tunnel_complexes(world_state)
	CombatEngineeringAirborneSystemScript.seed_theater_minefields(world_state)
	UnderseaWarfareSystemScript.seed_theater_undersea_cables(world_state)
	StrategicMddSystemScript.seed_orbital_constellation(world_state)
	SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
	spatial_grid.rebuild(world_state)
	ElectronicWarfareSystem.step(world_state, sim_db_ref, spatial_grid)
	SensorLoSSystem.step(world_state, sim_db_ref, spatial_grid, cs_kernel)
	LogisticsSystemScript.step(world_state, sim_db_ref, spatial_grid, 0.0)
	EchelonClusterSystem.step(world_state)
	_update_fow_global_texture()
	snapshot_buffer.publish_snapshot(world_state)
	snapshot_buffer.publish_snapshot(world_state)
	replay_recorder.record_keyframe(world_state, true)

	if signal_bus_ref != null:
		signal_bus_ref.scenario_loaded.emit(scenario_slug, String(sc_info.get("display_name", scenario_slug)))


## Sets up and boots an isolated Tactical Proving Trial for any of the 67 military platforms.
func load_unit_trial(platform_slug: String) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = UnitTacticalTrialsSystemScript.setup_trial_scenario(self, platform_slug)
	_update_fow_global_texture()
	snapshot_buffer.publish_snapshot(world_state)
	snapshot_buffer.publish_snapshot(world_state)
	if signal_bus_ref != null:
		signal_bus_ref.scenario_loaded.emit("trial_" + platform_slug, String(res.get("trial_title", platform_slug)))
	return res


## Seeds 688+ active units organized into Brigades (2) -> Battalions (1) -> Companies/Flights/Swarms/Robot Dogs (0)
func _seed_scenario_pacific_shield_600() -> void:
	var blue_templates := [
		["f_35a_lightning", "xq_58a_valkyrie", "f_16cj_block70", "mq_28_ghost_bat", "b_21_raider", "kc_46_pegasus"],
		["m1a2_sepv3_platoon", "m2a4_mech_company", "tier1_sniper_recon_team", "navy_seal_commando_squad", "specops_mountain_team", "vision_60_q_ugv"],
		["mim_104f_patriot", "iron_beam_helws", "epirus_leonidas_hpm", "skynex_ahead_battery", "dark_eagle_battery", "hemtt_supply_convoy"],
		["ddg_51_arleigh_burke", "ssn_688i_los_angeles", "magura_v5_usv", "orca_xluuv", "navy_seal_commando_squad", "e_3_sentry_awacs"],
	]
	var red_templates := [
		["j_20_mighty_dragon", "su_57_felon", "s_70_okhotnik", "tu_22m3_backfire", "j_20_mighty_dragon", "s_70_okhotnik"],
		["t_90m_platoon", "spetsnaz_sniper_commando", "uran_9_ugv", "unitree_b2w_armed", "lancet_3_team", "spetsnaz_sniper_commando"],
		["s_400_triumf", "krasukha_4_ew", "shahed_136_launcher", "lancet_3_team", "s_400_triumf", "krasukha_4_ew"],
		["type_055_renhai", "type_093b_shang_ssn", "sea_baby_usv", "shahed_136_launcher", "tu_22m3_backfire", "type_055_renhai"],
	]

	var is_mobile_vr := OS.has_feature("android")
	var num_bdes := 4 if is_mobile_vr else 8
	var num_bns := 3 if is_mobile_vr else 6
	var num_cos := 4 if is_mobile_vr else 6

	for bde_idx in range(num_bdes):
		var bde_z := -175.0 + float(bde_idx) * 50.0
		var bde_x := 85.0 + float(bde_idx % 3) * 32.0
		var grp: Array = blue_templates[bde_idx % blue_templates.size()]
		var lead_pid: int = sim_db_ref.get_platform_id(String(grp[0]))
		var lead_def: Dictionary = sim_db_ref.get_platform(lead_pid)

		if bde_idx % 4 == 3:
			bde_x = 68.0
		var bde_uid := world_state.spawn_unit(
			WorldState.FACTION_BLUE,
			lead_pid,
			Vector3(bde_x, 0.0, bde_z),
			WorldState.ECHELON_BRIGADE,
			-1,
			lead_def
		)

		for bn_idx in range(num_bns):
			var bn_x := bde_x + float((bn_idx % 3) - 1) * 14.0
			var bn_z := bde_z + float((bn_idx / 3) - 0.5) * 16.0
			var bn_slug: String = String(grp[bn_idx % grp.size()])
			var bn_pid: int = sim_db_ref.get_platform_id(bn_slug)
			var bn_def: Dictionary = sim_db_ref.get_platform(bn_pid)
			var bn_uid := world_state.spawn_unit(
				WorldState.FACTION_BLUE,
				bn_pid,
				Vector3(bn_x, 0.0, bn_z),
				WorldState.ECHELON_BATTALION,
				bde_uid,
				bn_def
			)

			for co_idx in range(num_cos):
				var co_slug: String = String(grp[(bn_idx + co_idx) % grp.size()])
				if bde_idx == 3 and bn_idx == 0 and co_idx == 0:
					co_slug = "cvn_78_gerald_r_ford"
				var co_pid: int = sim_db_ref.get_platform_id(co_slug)
				var co_def: Dictionary = sim_db_ref.get_platform(co_pid)
				var co_x := bn_x + float((co_idx % 3) - 1) * 3.8
				var co_z := bn_z + float((co_idx / 3) - 0.5) * 4.2
				if String(co_def.get("domain", "")) == "SEA":
					co_x = clampf(co_x, 42.0, 165.0)
					if co_slug == "cvn_78_gerald_r_ford":
						co_x = 168.0
				var co_uid := world_state.spawn_unit(
					WorldState.FACTION_BLUE,
					co_pid,
					Vector3(co_x, 0.0, co_z),
					WorldState.ECHELON_COMPANY,
					bn_uid,
					co_def
				)
				if co_uid >= 0:
					var dom_str := String(co_def.get("domain", ""))
					if dom_str in ["AIR", "SEA"]:
						world_state.unit_target_pos[co_uid] = Vector3(co_x - 35.0, world_state.unit_pos[co_uid].y, co_z)
						world_state.unit_has_waypoint[co_uid] = 1
					else:
						# Active ground maneuver & sniper/commando/infantry patrol waypoints
						var adv_dx := -18.0 if co_x > 45.0 else 16.0
						var adv_dz := 14.0 if (co_idx % 2 == 0) else -14.0
						world_state.unit_target_pos[co_uid] = Vector3(clampf(co_x + adv_dx, 38.0, 210.0), world_state.unit_pos[co_uid].y, clampf(co_z + adv_dz, -220.0, 220.0))
						world_state.unit_has_waypoint[co_uid] = 1

	for bde_idx in range(num_bdes):
		var bde_z := -175.0 + float(bde_idx) * 50.0
		var bde_x := -95.0 - float(bde_idx % 3) * 32.0
		var grp: Array = red_templates[bde_idx % red_templates.size()]
		var lead_pid: int = sim_db_ref.get_platform_id(String(grp[0]))
		var lead_def: Dictionary = sim_db_ref.get_platform(lead_pid)

		if bde_idx % 4 == 3:
			bde_x = -68.0
		var bde_uid := world_state.spawn_unit(
			WorldState.FACTION_RED,
			lead_pid,
			Vector3(bde_x, 0.0, bde_z),
			WorldState.ECHELON_BRIGADE,
			-1,
			lead_def
		)

		for bn_idx in range(num_bns):
			var bn_x := bde_x + float((bn_idx % 3) - 1) * 14.0
			var bn_z := bde_z + float((bn_idx / 3) - 0.5) * 16.0
			var bn_slug: String = String(grp[bn_idx % grp.size()])
			var bn_pid: int = sim_db_ref.get_platform_id(bn_slug)
			var bn_def: Dictionary = sim_db_ref.get_platform(bn_pid)
			var bn_uid := world_state.spawn_unit(
				WorldState.FACTION_RED,
				bn_pid,
				Vector3(bn_x, 0.0, bn_z),
				WorldState.ECHELON_BATTALION,
				bde_uid,
				bn_def
			)

			for co_idx in range(num_cos):
				var co_slug: String = String(grp[(bn_idx + co_idx) % grp.size()])
				if bde_idx == 3 and bn_idx == 0 and co_idx == 0:
					co_slug = "cns_fujian_cv18"
				var co_pid: int = sim_db_ref.get_platform_id(co_slug)
				var co_def: Dictionary = sim_db_ref.get_platform(co_pid)
				var co_x := bn_x + float((co_idx % 3) - 1) * 3.8
				var co_z := bn_z + float((co_idx / 3) - 0.5) * 4.2
				if String(co_def.get("domain", "")) == "SEA":
					co_x = clampf(co_x, -165.0, -42.0)
					if co_slug == "cns_fujian_cv18":
						co_x = -148.0
				var co_uid := world_state.spawn_unit(
					WorldState.FACTION_RED,
					co_pid,
					Vector3(co_x, 0.0, co_z),
					WorldState.ECHELON_COMPANY,
					bn_uid,
					co_def
				)
				if co_uid >= 0:
					var dom_str := String(co_def.get("domain", ""))
					if dom_str in ["AIR", "SEA"]:
						world_state.unit_target_pos[co_uid] = Vector3(co_x + 35.0, world_state.unit_pos[co_uid].y, co_z)
						world_state.unit_has_waypoint[co_uid] = 1
					else:
						var adv_dx := 18.0 if co_x < -45.0 else -16.0
						var adv_dz := -14.0 if (co_idx % 2 == 0) else 14.0
						world_state.unit_target_pos[co_uid] = Vector3(clampf(co_x + adv_dx, -210.0, -38.0), world_state.unit_pos[co_uid].y, clampf(co_z + adv_dz, -220.0, 220.0))
						world_state.unit_has_waypoint[co_uid] = 1


func _seed_scenario_iron_hound_ridge() -> void:
	var blue_slugs := ["m2a4_mech_company", "tier1_sniper_recon_team", "navy_seal_commando_squad", "specops_mountain_team", "vision_60_q_ugv", "fpv_fiber_swarm", "epirus_leonidas_hpm", "m1a2_sepv3_platoon"]
	var red_slugs := ["t_90m_platoon", "spetsnaz_sniper_commando", "uran_9_ugv", "unitree_b2w_armed", "lancet_3_team", "krasukha_4_ew", "shahed_136_launcher"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(134.0, 18.0), Vector2(118.0, 18.0), Vector2(-6.0, 0.0), 2, 3, 6)


func _seed_scenario_sea_wolfpack() -> void:
	var blue_slugs := ["ddg_51_arleigh_burke", "ssn_688i_los_angeles", "navy_seal_commando_squad", "magura_v5_usv", "orca_xluuv", "f_35a_lightning", "xq_58a_valkyrie", "kc_46_pegasus"]
	var red_slugs := ["type_055_renhai", "type_093b_shang_ssn", "spetsnaz_sniper_commando", "sea_baby_usv", "tu_22m3_backfire", "j_20_mighty_dragon", "s_70_okhotnik", "shahed_136_launcher"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(22.0, -35.0), Vector2(-24.0, 35.0), Vector2(-20.0, 20.0), 3, 3, 6)


func _seed_scenario_korean_dmz() -> void:
	# ROK / US Combined Forces (South of DMZ z > +35) vs DPRK Strategic Rocket & Artillery Forces (North of DMZ z < -15)
	var blue_slugs := ["kf_21_boramae", "k2_black_panther", "tier1_sniper_recon_team", "navy_seal_commando_squad", "hyunmoo_5_tel", "mim_104f_patriot", "f_35a_lightning", "vision_60_q_ugv"]
	var red_slugs := ["kn_25_mlrs_battery", "t_90m_platoon", "spetsnaz_sniper_commando", "uran_9_ugv", "unitree_b2w_armed", "shahed_136_launcher", "lancet_3_team", "s_400_triumf"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-10.0, 58.0), Vector2(-15.0, -35.0), Vector2(0.0, -30.0), 3, 3, 6)


func _seed_scenario_baltic_suwalki() -> void:
	# NATO Multinational Corps Northeast vs Kaliningrad / Belarus IADS Bastion
	var blue_slugs := ["rafale_f4_flight", "leopard_2a8_platoon", "tier1_sniper_recon_team", "navy_seal_commando_squad", "milrem_themis_ugv", "skynex_ahead_battery", "f_35a_lightning", "mim_104f_patriot"]
	var red_slugs := ["su_57_felon", "tu_22m3_backfire", "spetsnaz_sniper_commando", "s_400_triumf", "krasukha_4_ew", "t_90m_platoon", "uran_9_ugv", "lancet_3_team"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-18.0, 42.0), Vector2(65.0, -20.0), Vector2(25.0, -15.0), 3, 3, 6)


func _seed_scenario_himalaya_lac() -> void:
	# High-Altitude 5,600m Himalayan Ridge: Indian Mountain Strike Corps vs PLA & PAF Western Command
	var blue_slugs := ["hal_tejas_mk2", "zorawar_mountain_tank", "tier1_sniper_recon_team", "specops_mountain_team", "brahmos_coastal_battery", "rafale_f4_flight", "vision_60_q_ugv", "fpv_fiber_swarm"]
	var red_slugs := ["j_20_mighty_dragon", "jf_17_block3_flight", "spetsnaz_sniper_commando", "bayraktar_akinci_ucav", "unitree_b2w_armed", "t_90m_platoon", "s_400_triumf", "lancet_3_team"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-45.0, 20.0), Vector2(45.0, -18.0), Vector2(22.0, -10.0), 3, 3, 6)


func _seed_scenario_ukraine_donbas() -> void:
	# Ukraine (ZSU 47th Magura, 3rd Assault, 93rd Kholodnyi Yar, 414th Madyar's Birds, 19th Neptune Bde) vs Russian Southern/Western MD
	var blue_slugs := ["btr_4_bucephalus_co", "tier1_sniper_recon_team", "navy_seal_commando_squad", "fpv_fiber_swarm", "bohdana_2s22_artillery", "t_84_oplot_platoon", "m2a4_mech_company", "neptune_rk360mc_battery", "palianytsia_drone_uk", "f_16cj_block70"]
	var red_slugs := ["t_90m_platoon", "spetsnaz_sniper_commando", "lancet_3_team", "shahed_136_launcher", "uran_9_ugv", "s_400_triumf", "krasukha_4_ew", "su_57_felon", "tu_22m3_backfire", "unitree_b2w_armed"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-55.0, -25.0), Vector2(48.0, -10.0), Vector2(28.0, 5.0), 4, 3, 6)


func _seed_scenario_mexico_rio_grande() -> void:
	# US NORTHCOM III Armored Corps (1st Cavalry Div, 388th Wing, 4th Fleet) vs Mexican SEDENA (1/a Brigada Blindada, FAM Escuadron 401, SEMAR POLA-101)
	var blue_slugs := ["m1a2_sepv3_platoon", "m2a4_mech_company", "tier1_sniper_recon_team", "navy_seal_commando_squad", "epirus_leonidas_hpm", "f_35a_lightning", "vision_60_q_ugv", "specops_mountain_team"]
	var red_slugs := ["dn_xi_mexican_armor", "f_5f_tiger_mex_flight", "spetsnaz_sniper_commando", "fpv_fiber_swarm", "specops_mountain_team", "pola_benito_juarez_frigate", "switchblade_600_team", "dn_xi_mexican_armor"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-42.0, -68.0), Vector2(-58.0, 55.0), Vector2(-5.0, 32.0), 3, 3, 6)


func _seed_scenario_taiwan_strait_blockade() -> void:
	# FEAT-11: Taiwan Strait Blockade & Carrier Strike Group Clash
	var blue_slugs := ["cvn_78_gerald_r_ford", "f_35a_lightning", "xq_58a_valkyrie", "ddg_51_arleigh_burke", "mim_104f_patriot", "brahmos_coastal_battery", "ssn_688i_los_angeles", "magura_v5_usv"]
	var red_slugs := ["type_055_renhai", "type_093b_shang_ssn", "j_20_mighty_dragon", "s_70_okhotnik", "s_400_triumf", "tu_22m3_backfire", "krasukha_4_ew", "shahed_136_launcher"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(55.0, -25.0), Vector2(-45.0, 30.0), Vector2(-25.0, 15.0), 4, 3, 6)


func _seed_scenario_suwalki_corridor_breach() -> void:
	# FEAT-11: Suwalki Corridor Heavy Armor & EW Jamming Clash
	var blue_slugs := ["leopard_2a8_platoon", "m2a4_mech_company", "milrem_themis_ugv", "skynex_ahead_battery", "rafale_f4_flight", "f_35a_lightning", "tier1_sniper_recon_team", "hemtt_supply_convoy"]
	var red_slugs := ["t_90m_platoon", "uran_9_ugv", "lancet_3_team", "s_400_triumf", "krasukha_4_ew", "su_57_felon", "tu_22m3_backfire", "spetsnaz_sniper_commando"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-30.0, 35.0), Vector2(50.0, -25.0), Vector2(25.0, -10.0), 4, 3, 6)


func _seed_scenario_second_thomas_shoal() -> void:
	# FEAT-11: Second Thomas Shoal Littoral USV Swarm & BVR Air Cover
	var blue_slugs := ["magura_v5_usv", "ddg_51_arleigh_burke", "f_35a_lightning", "mq_28_ghost_bat", "navy_seal_commando_squad", "orca_xluuv", "fpv_fiber_swarm", "kc_46_pegasus"]
	var red_slugs := ["type_055_renhai", "sea_baby_usv", "type_093b_shang_ssn", "j_20_mighty_dragon", "shahed_136_launcher", "spetsnaz_sniper_commando", "tu_22m3_backfire", "krasukha_4_ew"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(30.0, -45.0), Vector2(-35.0, 40.0), Vector2(-15.0, 20.0), 3, 3, 6)


func _seed_scenario_giuk_arctic_bastion() -> void:
	# FEAT-11: GIUK Arctic Bastion Under-Ice SSBN & SOSUS Barrier Duel
	var blue_slugs := ["ssn_688i_los_angeles", "orca_xluuv", "ddg_51_arleigh_burke", "f_35a_lightning", "navy_seal_commando_squad", "tier1_sniper_recon_team", "magura_v5_usv", "kc_46_pegasus"]
	var red_slugs := ["type_093b_shang_ssn", "sea_baby_usv", "tu_22m3_backfire", "su_57_felon", "s_400_triumf", "spetsnaz_sniper_commando", "uran_9_ugv", "t_90m_platoon"]
	_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(-20.0, 45.0), Vector2(40.0, -35.0), Vector2(15.0, -15.0), 3, 3, 6)


func _spawn_symmetric_theater_forces(
	blue_slugs: Array,
	red_slugs: Array,
	blue_origin_xz: Vector2,
	red_origin_xz: Vector2,
	blue_advance_xz: Vector2,
	num_bdes: int,
	bns_per_bde: int,
	cos_per_bn: int
) -> void:
	for bde_idx in range(num_bdes):
		var lead_b_pid: int = sim_db_ref.get_platform_id(String(blue_slugs[0]))
		var lead_b_def: Dictionary = sim_db_ref.get_platform(lead_b_pid)
		var bde_pos := Vector3(blue_origin_xz.x + float(bde_idx) * 18.0, 0.0, blue_origin_xz.y + float(bde_idx) * 14.0)
		var bde_uid := world_state.spawn_unit(WorldState.FACTION_BLUE, lead_b_pid, bde_pos, WorldState.ECHELON_BRIGADE, -1, lead_b_def)

		for bn_idx in range(bns_per_bde):
			var bn_slug := String(blue_slugs[bn_idx % blue_slugs.size()])
			var bn_pid: int = sim_db_ref.get_platform_id(bn_slug)
			var bn_def: Dictionary = sim_db_ref.get_platform(bn_pid)
			var bn_hdg := atan2(blue_advance_xz.x, blue_advance_xz.y)
			var bn_off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
				TacticalDoctrineFormationSystemScript.FormationType.WEDGE,
				bn_idx,
				bns_per_bde,
				bn_hdg,
				2.2
			)
			var bn_pos := bde_pos + bn_off
			var bn_uid := world_state.spawn_unit(WorldState.FACTION_BLUE, bn_pid, bn_pos, WorldState.ECHELON_BATTALION, bde_uid, bn_def)

			var bn_dom := int(bn_def.get("domain_id", 0))
			var is_cvn := bn_slug.contains("cvn") or bn_slug.contains("carrier")
			var elev_m := world_state.get_terrain_elevation_m(bn_pos.x, bn_pos.z)
			var form_type := TacticalDoctrineFormationSystemScript.select_formation_for_group(bn_dom, WorldState.TACTICAL_POSTURE_AGGRESSIVE_PURSUIT, is_cvn, elev_m, 0.0)

			for co_idx in range(cos_per_bn):
				var co_slug := String(blue_slugs[(bn_idx + co_idx) % blue_slugs.size()])
				var co_pid: int = sim_db_ref.get_platform_id(co_slug)
				var co_def: Dictionary = sim_db_ref.get_platform(co_pid)
				var co_off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
					form_type,
					co_idx,
					cos_per_bn,
					bn_hdg,
					1.0
				)
				var co_pos := bn_pos + co_off
				var uid := world_state.spawn_unit(WorldState.FACTION_BLUE, co_pid, co_pos, WorldState.ECHELON_COMPANY, bn_uid, co_def)
				world_state.unit_heading_rad[uid] = bn_hdg
				world_state.unit_target_pos[uid] = Vector3(co_pos.x + blue_advance_xz.x, world_state.unit_pos[uid].y, co_pos.z + blue_advance_xz.y)
				world_state.unit_has_waypoint[uid] = 1

	for bde_idx in range(num_bdes):
		var lead_r_pid: int = sim_db_ref.get_platform_id(String(red_slugs[0]))
		var lead_r_def: Dictionary = sim_db_ref.get_platform(lead_r_pid)
		var bde_pos := Vector3(red_origin_xz.x + float(bde_idx) * 18.0, 0.0, red_origin_xz.y + float(bde_idx) * 14.0)
		var bde_uid := world_state.spawn_unit(WorldState.FACTION_RED, lead_r_pid, bde_pos, WorldState.ECHELON_BRIGADE, -1, lead_r_def)

		for bn_idx in range(bns_per_bde):
			var bn_slug := String(red_slugs[bn_idx % red_slugs.size()])
			var bn_pid: int = sim_db_ref.get_platform_id(bn_slug)
			var bn_def: Dictionary = sim_db_ref.get_platform(bn_pid)
			var red_adv := -blue_advance_xz
			var bn_hdg := atan2(red_adv.x, red_adv.y)
			var bn_off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
				TacticalDoctrineFormationSystemScript.FormationType.WEDGE,
				bn_idx,
				bns_per_bde,
				bn_hdg,
				2.2
			)
			var bn_pos := bde_pos + bn_off
			var bn_uid := world_state.spawn_unit(WorldState.FACTION_RED, bn_pid, bn_pos, WorldState.ECHELON_BATTALION, bde_uid, bn_def)

			var bn_dom := int(bn_def.get("domain_id", 0))
			var is_cvn := bn_slug.contains("cvn") or bn_slug.contains("fujian")
			var elev_m := world_state.get_terrain_elevation_m(bn_pos.x, bn_pos.z)
			var form_type := TacticalDoctrineFormationSystemScript.select_formation_for_group(bn_dom, WorldState.TACTICAL_POSTURE_AGGRESSIVE_PURSUIT, is_cvn, elev_m, 0.0)

			for co_idx in range(cos_per_bn):
				var co_slug := String(red_slugs[(bn_idx + co_idx) % red_slugs.size()])
				var co_pid: int = sim_db_ref.get_platform_id(co_slug)
				var co_def: Dictionary = sim_db_ref.get_platform(co_pid)
				var co_off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
					form_type,
					co_idx,
					cos_per_bn,
					bn_hdg,
					1.0
				)
				var co_pos := bn_pos + co_off
				var uid := world_state.spawn_unit(WorldState.FACTION_RED, co_pid, co_pos, WorldState.ECHELON_COMPANY, bn_uid, co_def)
				world_state.unit_heading_rad[uid] = bn_hdg
				world_state.unit_target_pos[uid] = Vector3(co_pos.x + red_adv.x, world_state.unit_pos[uid].y, co_pos.z + red_adv.y)
				world_state.unit_has_waypoint[uid] = 1


func _process(delta: float) -> void:
	if replay_recorder.is_scrubbing_replay or world_state.time_scale <= 0.0:
		_flush_sim_events_to_signals()
		return

	_tick_accumulator += delta * world_state.time_scale
	var is_mobile_vr := OS.has_feature("android")
	var max_steps_per_frame := 1 if is_mobile_vr else 2
	var step_dt := BASE_TICK_DT
	if world_state.time_scale > 15.0:
		step_dt = clampf(BASE_TICK_DT * (world_state.time_scale / 12.0), BASE_TICK_DT, 15.0)
	if _tick_accumulator > step_dt * 1.5:
		_tick_accumulator = step_dt * 1.5
	var steps := 0
	while _tick_accumulator >= step_dt and steps < max_steps_per_frame:
		_tick_accumulator -= step_dt
		steps += 1
		if use_worker_thread:
			if _worker_task_id == -1 or WorkerThreadPool.is_task_completed(_worker_task_id):
				if _worker_task_id != -1:
					WorkerThreadPool.wait_for_task_completion(_worker_task_id)
				_worker_task_id = WorkerThreadPool.add_task(_worker_step_callable)
		else:
			step_tick(step_dt)

	_flush_sim_events_to_signals()


func _worker_step_callable() -> void:
	step_tick(BASE_TICK_DT)


## Executes one deterministic 10 Hz simulation tick across all systems.
func step_tick(dt: float = BASE_TICK_DT) -> void:
	_resolve_autoloads()
	world_state.tick_id += 1
	world_state.sim_time_sec += dt
	var is_mobile_vr := OS.has_feature("android")

	# 1. Drain and apply deterministic commands from CommandBus
	var prev_news_metrics: Dictionary = WarNewsVideoSystemScript.capture_metrics_snapshot(world_state)
	if command_bus_ref != null:
		var cmds: Array[Dictionary] = command_bus_ref.drain_commands(world_state.tick_id)
		for cmd in cmds:
			_apply_command(cmd)

	# 2. Run 3-Tier Zoom Sim-LOD + C# Multi-Threaded SIMD systems in pipeline order
	WeatherSolarSystemScript.step(world_state, dt)
	SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
	KinematicsSystem.step(world_state, sim_db_ref, dt)
	spatial_grid.rebuild(world_state)
	ElectronicWarfareSystem.step(world_state, sim_db_ref, spatial_grid)
	SensorLoSSystem.step(world_state, sim_db_ref, spatial_grid, cs_kernel)
	UnitTacticalAISystemScript.step(world_state, sim_db_ref, spatial_grid, dt)
	SwarmIntelligenceSystemScript.step_swarm_intelligence(world_state, sim_db_ref, spatial_grid, dt)

	# Stagger secondary non-realtime subsystems across ticks to maintain rock-solid 60+ FPS
	var t_mod10 := world_state.tick_id % 10
	if t_mod10 == 1 or t_mod10 == 6:
		LogisticsSystemScript.step(world_state, sim_db_ref, spatial_grid, dt * 5.0)
	if t_mod10 == 3:
		TerrainInfrastructureSystemScript.step(world_state, sim_db_ref, dt * 10.0)
	SalvoCombatSystem.step(world_state, sim_db_ref, spatial_grid, dt)
	SimLodSystemScript.step_macro_echelons(world_state, cs_kernel, dt)
	StrategicMddSystemScript.step(world_state, sim_db_ref, cs_kernel, dt)
	if (world_state.tick_id % 5) == 2:
		CivilianTrafficConvoySystemScript.step(world_state, sim_db_ref, dt * 5.0)
	if (world_state.tick_id % 5) == 4:
		SubterraneanTunnelSystemScript.step(world_state, sim_db_ref, dt * 5.0)
	CemaElectronicWarfareSystemScript.step(world_state, dt)
	if (world_state.tick_id % 3) == 0:
		CombatEngineeringAirborneSystemScript.step(world_state, dt * 3.0)
	if t_mod10 == 5:
		HomefrontEconomySystemScript.step(world_state, dt * 10.0)
	if (world_state.tick_id % 3) == 1:
		NuclearSubmarineSystemScript.step(world_state, sim_db_ref, dt * 3.0)
	if t_mod10 == 2:
		CivilianDensitySystemScript.step(world_state, cs_kernel, dt * 10.0)
	if t_mod10 == 8:
		GlobalOrbatSystemScript.step_global_orbat(world_state, dt * 10.0)
	if t_mod10 == 7:
		BudgetTechSystemScript.step(world_state, sim_db_ref, dt * 10.0)
	if defcon_escalation_system != null:
		defcon_escalation_system.step(world_state, dt)
	CoordinatedStrikeSystemScript.step_combined_arms_synergy(world_state, sim_db_ref, spatial_grid, dt)
	if t_mod10 == 9:
		DiplomacySystemScript.step(world_state, sim_db_ref, dt * 10.0)
		red_phone_hotline_system.step(world_state, sim_db_ref, dt * 10.0)
	_last_news_video_sim_sec = WarNewsVideoSystemScript.evaluate_and_broadcast_events(world_state, sim_db_ref, prev_news_metrics, _last_news_video_sim_sec)
	if not is_mobile_vr and (world_state.tick_id % 25) == 0:
		WarNewsVideoSystemScript.poll_live_gemini_json(world_state, sim_db_ref)
	EchelonClusterSystem.step(world_state)

	# 3. Publish lock-free interpolation snapshot & record Tacview keyframe
	snapshot_buffer.publish_snapshot(world_state)
	if not is_mobile_vr or (world_state.tick_id % 10) == 0:
		replay_recorder.record_keyframe(world_state)

	# 4. Periodically update global FoW/Threat texture (every 20 ticks on PC, every 30 ticks on standalone VR)
	_fow_update_counter += 1
	var fow_interval := 30 if is_mobile_vr else 20
	if _fow_update_counter >= fow_interval and not use_worker_thread:
		_fow_update_counter = 0
		_update_fow_global_texture()



func scrub_replay_ratio(ratio: float) -> void:
	replay_recorder.scrub_to_ratio(ratio, snapshot_buffer, world_state)


func dispatch_commander_command(cmd_type: String, unit_ids: Array, target_pos: Vector3 = Vector3.ZERO, extra: Dictionary = {}) -> void:
	var cmd: Dictionary = extra.duplicate()
	cmd["type"] = cmd_type
	cmd["unit_ids"] = unit_ids
	cmd["faction"] = WorldState.FACTION_BLUE
	if cmd_type == "CMD_MOVE_WAYPOINTS":
		cmd["waypoints_km"] = [target_pos]
	elif cmd_type == "CMD_DEPLOY_UNMANNED_SUBUNIT":
		cmd["target_pos"] = target_pos
	_apply_command(cmd)


func _apply_command(cmd: Dictionary) -> void:
	var ctype := String(cmd.get("type", ""))
	match ctype:
		"CMD_MOVE_WAYPOINTS":
			var uids: Array = cmd.get("unit_ids", [])
			var wps: Array = cmd.get("waypoints_km", [])
			var cmd_fac: int = int(cmd.get("faction", WorldState.FACTION_BLUE))
			if wps.size() > 0 and uids.size() > 0:
				var first_wp: Vector3 = wps[0]
				var centroid := Vector3.ZERO
				var valid_cnt := 0
				for u in uids:
					var uid := int(u)
					if uid >= 0 and uid < world_state.unit_count and world_state.unit_active[uid] == 1 and world_state.unit_faction[uid] == cmd_fac:
						centroid += world_state.unit_pos[uid]
						valid_cnt += 1
				if valid_cnt > 0:
					centroid /= float(valid_cnt)
				for u in uids:
					var uid := int(u)
					if uid < 0 or uid >= world_state.unit_count or world_state.unit_active[uid] == 0:
						continue
					# Faction filter: ONLY process movement orders for units matching the commanding faction!
					if world_state.unit_faction[uid] != cmd_fac:
						continue
					var dest := first_wp
					if valid_cnt > 1:
						var off := world_state.unit_pos[uid] - centroid
						off.x = clampf(off.x, -28.0, 28.0)
						off.z = clampf(off.z, -28.0, 28.0)
						dest = Vector3(first_wp.x + off.x, first_wp.y, first_wp.z + off.z)
					EchelonClusterSystem.propagate_move_order(world_state, uid, dest)
					if wps.size() > 1:
						world_state.unit_waypoint_queues[uid] = wps.slice(1)

		"CMD_SET_DOCTRINE":
			var uids: Array = cmd.get("unit_ids", [])
			var rad_act: int = int(cmd.get("radar_active", -1))
			var roe_val: int = int(cmd.get("roe", -1))
			for u in uids:
				var uid := int(u)
				if uid >= 0 and uid < world_state.unit_count:
					if rad_act >= 0:
						world_state.unit_radar_active[uid] = rad_act
					if roe_val >= 0:
						world_state.unit_roe[uid] = roe_val

		"CMD_SET_TACTICAL_POSTURE":
			var uids: Array = cmd.get("unit_ids", [])
			var posture: int = int(cmd.get("posture", 0))
			for u in uids:
				var uid := int(u)
				if uid >= 0 and uid < world_state.unit_count and world_state.unit_active[uid] == 1:
					if uid < world_state.unit_tactical_posture.size():
						world_state.unit_tactical_posture[uid] = posture
					# Propagate to child echelons if battalion/brigade selected
					if world_state.unit_echelon[uid] > WorldState.ECHELON_COMPANY:
						for sub_id in range(world_state.unit_count):
							if world_state.unit_active[sub_id] == 1:
								var p1 := world_state.unit_parent_id[sub_id]
								var p2 := world_state.unit_parent_id[p1] if (p1 >= 0 and p1 < world_state.unit_parent_id.size()) else -1
								if p1 == uid or p2 == uid:
									if sub_id < world_state.unit_tactical_posture.size():
										world_state.unit_tactical_posture[sub_id] = posture

		"CMD_QUEUE_STRIKE":
			var raw_attackers: Array = cmd.get("attacker_ids", [])
			var expanded_attackers: Array[int] = []
			for a in raw_attackers:
				var a_uid := int(a)
				if a_uid >= 0 and a_uid < world_state.unit_count and world_state.unit_active[a_uid] == 1:
					if world_state.unit_echelon[a_uid] == WorldState.ECHELON_COMPANY:
						expanded_attackers.append(a_uid)
					else:
						for sub_id in range(world_state.unit_count):
							if world_state.unit_active[sub_id] == 1 and world_state.unit_echelon[sub_id] == WorldState.ECHELON_COMPANY:
								var p1 := world_state.unit_parent_id[sub_id]
								var p2 := world_state.unit_parent_id[p1] if p1 >= 0 else -1
								if p1 == a_uid or p2 == a_uid:
									expanded_attackers.append(sub_id)
			if expanded_attackers.size() > 0:
				var first_fac := world_state.unit_faction[expanded_attackers[0]]
				var t_uid := int(cmd.get("target_unit_id", -1))
				var t_pos: Vector3 = cmd.get("target_pos_km", Vector3.ZERO)
				var w_slot := int(cmd.get("weapon_slot", 1))
				var salvo_per := int(cmd.get("salvo_per_unit", 2))
				# Immediately launch an initial engagement salvo AND advance/orient attackers toward the target
				for l_uid in expanded_attackers:
					world_state.unit_player_override_timer[l_uid] = 180.0
					if l_uid < world_state.unit_delegated_ai.size():
						world_state.unit_delegated_ai[l_uid] = 0
					var dest_y := t_pos.y
					if world_state.unit_pos[l_uid].y > 180.0 and dest_y < 150.0:
						dest_y = world_state.unit_pos[l_uid].y
					world_state.unit_target_pos[l_uid] = Vector3(t_pos.x, dest_y, t_pos.z)
					world_state.unit_has_waypoint[l_uid] = 1
					SalvoCombatSystem.launch_strike_salvo(world_state, sim_db_ref, l_uid, t_uid, t_pos, w_slot, 1)
				world_state.queued_strikes.append({
					"package_id": int(cmd.get("package_id", 1)),
					"faction": first_fac,
					"attacker_ids": expanded_attackers,
					"target_unit_id": t_uid,
					"target_pos_km": t_pos,
					"weapon_slot": w_slot,
					"salvo_per_unit": salvo_per,
				})
				world_state.sim_events_queue.append({
					"type": "strike_queued",
					"package_id": int(cmd.get("package_id", 1)),
					"attacker_count": expanded_attackers.size(),
					"target_unit_id": t_uid,
				})

		"CMD_COMMIT_ALPHA_STRIKE":
			var fac := int(cmd.get("faction", WorldState.FACTION_BLUE))
			if world_state.queued_strikes.is_empty():
				_auto_queue_alpha_strike_package(fac)
			SalvoCombatSystem.commit_queued_strikes(world_state, sim_db_ref, fac)
			WarNewsVideoSystemScript.trigger_broadcast(
				world_state, sim_db_ref, "missile_alpha_strike",
				"COMMITTED ALPHA STRIKE IN %s | In-Flight Missiles: %d" % [
					world_state.active_theater_slug.to_upper(),
					world_state.blue_munitions_in_flight + world_state.red_munitions_in_flight
				]
			)

		"CMD_DEPLOY_UNMANNED_SUBUNIT":
			var parent_ids: Array = cmd.get("parent_unit_ids", [])
			var offset: Vector3 = cmd.get("deploy_offset_km", Vector3(1.5, 0.0, -1.5))
			for p in parent_ids:
				EchelonClusterSystem.deploy_unmanned_subunit(world_state, sim_db_ref, int(p), offset)

		"CMD_SET_MASTER_IADS":
			var fac := int(cmd.get("faction", WorldState.FACTION_BLUE))
			var enabled := 1 if bool(cmd.get("radar_enabled", true)) else 0
			for uid in range(world_state.unit_count):
				if world_state.unit_active[uid] == 1 and world_state.unit_faction[uid] == fac:
					world_state.unit_radar_active[uid] = enabled
			world_state.sim_events_queue.append({
				"type": "master_iads_toggled",
				"faction": fac,
				"radar_enabled": enabled == 1,
			})

		"CMD_SET_TIME_SCALE":
			world_state.time_scale = clampf(float(cmd.get("time_scale", 1.0)), 0.0, 1800.0)
			world_state.sim_events_queue.append({
				"type": "time_scale_changed",
				"new_scale": world_state.time_scale,
			})

		"CMD_SPAWN_SANDBOX_UNIT":
			var fac := int(cmd.get("faction", WorldState.FACTION_BLUE))
			var slug := String(cmd.get("platform_slug", "f_35a_lightning"))
			var pos: Vector3 = cmd.get("pos_km", Vector3.ZERO)
			var pid: int = sim_db_ref.get_platform_id(slug)
			if pid > 0:
				world_state.spawn_unit(fac, pid, pos, WorldState.ECHELON_COMPANY, -1, sim_db_ref.get_platform(pid))

		"CMD_UNIT_ABILITY":
			_execute_unit_ability_command(cmd)

		"CMD_SET_TACTICAL_POSTURE":
			var raw_uids: Array = cmd.get("unit_ids", [])
			var posture: int = int(cmd.get("posture", 0))
			for u in raw_uids:
				var uid := int(u)
				if uid < 0 or uid >= world_state.unit_count or world_state.unit_active[uid] == 0:
					continue
				if world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					world_state.unit_tactical_posture[uid] = posture
				else:
					var subordinates: Array[int] = EchelonClusterSystem.get_subordinate_leaf_units(world_state, uid)
					for s in subordinates:
						world_state.unit_tactical_posture[s] = posture
			world_state.sim_events_queue.append({
				"type": "tactical_posture_changed",
				"unit_count": raw_uids.size(),
				"posture": posture
			})


func _execute_unit_ability_command(cmd: Dictionary) -> void:
	var raw_uids: Array = cmd.get("unit_ids", [])
	var ability_code := String(cmd.get("ability_code", ""))
	var target_uid: int = int(cmd.get("target_unit_id", -1))
	var target_pos: Vector3 = cmd.get("target_pos_km", Vector3.ZERO)

	if ability_code in ["ORDER_ASAT_STRIKE", "ORDER_CYBER_CNO", "ORDER_PSYOP_EVAC", "ORDER_CBRN_MOPP"]:
		execute_mdd_action(ability_code, WorldState.FACTION_BLUE)
		return
	if ability_code in ["STRIKE_TACTICAL_CBRN", "STRIKE_HEMP_EMP", "STRIKE_ORBITAL_RODS", "STRIKE_THERMONUCLEAR"]:
		execute_escalated_strike(ability_code, target_pos, WorldState.FACTION_BLUE)
		return

	# Expand any Brigade/Battalion IDs to their subordinate Company/Flight leaf units
	var leaf_uids: Array[int] = []
	for u in raw_uids:
		var uid := int(u)
		if uid < 0 or uid >= world_state.unit_count or world_state.unit_active[uid] == 0:
			continue
		if world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			leaf_uids.append(uid)
		else:
			for sub_id in range(world_state.unit_count):
				if world_state.unit_active[sub_id] == 1 and world_state.unit_echelon[sub_id] == WorldState.ECHELON_COMPANY:
					var p1 := world_state.unit_parent_id[sub_id]
					var p2 := world_state.unit_parent_id[p1] if p1 >= 0 else -1
					if p1 == uid or p2 == uid:
						leaf_uids.append(sub_id)

	if leaf_uids.is_empty():
		return

	for l_uid in leaf_uids:
		world_state.unit_player_override_timer[l_uid] = 20.0

	match ability_code:
		"PRIMARY_SALVO", "SECONDARY_SALVO", "ORDER_PRECISION_FIRE_TOT":
			var slot := 2 if ability_code == "SECONDARY_SALVO" else 1
			for l_uid in leaf_uids:
				var u_fac := world_state.unit_faction[l_uid]
				var enemy_fac := WorldState.FACTION_RED if u_fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
				var u_pos := world_state.unit_pos[l_uid]
				var chosen_tid := target_uid
				var chosen_pos := target_pos
				if chosen_tid < 0 or chosen_tid >= world_state.unit_count or world_state.unit_active[chosen_tid] == 0:
					chosen_tid = spatial_grid.find_nearest_enemy_unit(world_state, enemy_fac, u_pos.x, u_pos.z, 240.0, 0)
					if chosen_tid >= 0:
						chosen_pos = world_state.unit_pos[chosen_tid]
				SalvoCombatSystem.launch_strike_salvo(world_state, sim_db_ref, l_uid, chosen_tid, chosen_pos, slot, 2)

		"ORDER_ASSAULT_SEIZE":
			for l_uid in leaf_uids:
				var u_fac := world_state.unit_faction[l_uid]
				var enemy_fac := WorldState.FACTION_RED if u_fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
				var u_pos := world_state.unit_pos[l_uid]
				world_state.unit_afterburner[l_uid] = 1
				world_state.unit_roe[l_uid] = 2
				world_state.unit_ai_state[l_uid] = WorldState.AI_BVR_INTERCEPT
				if world_state.unit_unmanned_bays[l_uid] > 0:
					EchelonClusterSystem.deploy_unmanned_subunit(world_state, sim_db_ref, l_uid, Vector3(1.8, 0.0, -1.5))
				var chosen_tid := spatial_grid.find_nearest_enemy_unit(world_state, enemy_fac, u_pos.x, u_pos.z, 240.0, 0)
				if chosen_tid >= 0:
					world_state.unit_target_pos[l_uid] = world_state.unit_pos[chosen_tid]
					world_state.unit_has_waypoint[l_uid] = 1
					SalvoCombatSystem.launch_strike_salvo(world_state, sim_db_ref, l_uid, chosen_tid, world_state.unit_pos[chosen_tid], 1, 1)

		"ORDER_SEAD_SUPPRESS":
			for l_uid in leaf_uids:
				var u_fac := world_state.unit_faction[l_uid]
				var enemy_fac := WorldState.FACTION_RED if u_fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
				var u_pos := world_state.unit_pos[l_uid]
				world_state.unit_desired_alt_m[l_uid] = 350.0 # NOE low-altitude terrain-masking
				world_state.unit_afterburner[l_uid] = 1
				world_state.unit_ai_state[l_uid] = WorldState.AI_SEAD_TERRAIN_MASK
				var chosen_tid := spatial_grid.find_nearest_enemy_unit(world_state, enemy_fac, u_pos.x, u_pos.z, 240.0, 0)
				if chosen_tid >= 0:
					SalvoCombatSystem.launch_strike_salvo(world_state, sim_db_ref, l_uid, chosen_tid, world_state.unit_pos[chosen_tid], 2, 2)

		"ORDER_CAP_OVERWATCH":
			for l_uid in leaf_uids:
				world_state.unit_desired_alt_m[l_uid] = 9200.0
				world_state.unit_radar_active[l_uid] = 1
				world_state.unit_roe[l_uid] = 2
				world_state.unit_has_waypoint[l_uid] = 0
				world_state.unit_ai_state[l_uid] = WorldState.AI_PATROL_CAP

		"TOGGLE_AFTERBURNER":
			for l_uid in leaf_uids:
				world_state.unit_afterburner[l_uid] = 0 if world_state.unit_afterburner[l_uid] == 1 else 1

		"CYCLE_ALTITUDE":
			for l_uid in leaf_uids:
				var cur_alt := world_state.unit_desired_alt_m[l_uid]
				var next_alt := 350.0
				if cur_alt < 1200.0:
					next_alt = 5500.0
				elif cur_alt < 8500.0:
					next_alt = 11500.0
				else:
					next_alt = 350.0
				world_state.unit_desired_alt_m[l_uid] = next_alt
				var tpos := world_state.unit_target_pos[l_uid]
				world_state.unit_target_pos[l_uid] = Vector3(tpos.x, next_alt, tpos.z)

		"TOGGLE_RADAR_EMCON", "ORDER_EMCON_SILENT":
			for l_uid in leaf_uids:
				world_state.unit_radar_active[l_uid] = 0 if world_state.unit_radar_active[l_uid] == 1 else 1

		"DEPLOY_SUBUNIT":
			for l_uid in leaf_uids:
				EchelonClusterSystem.deploy_unmanned_subunit(world_state, sim_db_ref, l_uid, Vector3(1.8, 0.0, -1.5))

		"TOGGLE_AI_DELEGATION":
			for l_uid in leaf_uids:
				if l_uid < world_state.unit_delegated_ai.size():
					if world_state.unit_delegated_ai[l_uid] == 1:
						world_state.unit_delegated_ai[l_uid] = 0
						world_state.unit_player_override_timer[l_uid] = 9999.0
					else:
						world_state.unit_delegated_ai[l_uid] = 1
						world_state.unit_player_override_timer[l_uid] = 0.0

		"ORDER_RTB_RESUPPLY":
			for l_uid in leaf_uids:
				world_state.unit_ai_state[l_uid] = WorldState.AI_RTB_RESUPPLY
				world_state.unit_afterburner[l_uid] = 1
				for st in world_state.active_sites:
					var fac_str := "BLUE" if world_state.unit_faction[l_uid] == WorldState.FACTION_BLUE else "RED"
					if String(st.get("faction_owner", "")) == fac_str:
						world_state.unit_target_pos[l_uid] = Vector3(float(st.get("x_km", 0.0)), world_state.unit_pos[l_uid].y, float(st.get("z_km", 0.0)))
						world_state.unit_has_waypoint[l_uid] = 1
						break


## Executes Theater/Planetary Multi-Domain Deterrence Operations ([7] ASAT, [8] Cyber CNO, [9] PsyOp/Evac, [0] CBRN/Hazard Plume)
func execute_mdd_action(action_code: String, faction: int = WorldState.FACTION_BLUE) -> int:
	_resolve_autoloads()
	var focus_xz := world_state.sim_focus_center_km
	if world_state.selected_unit_id >= 0 and world_state.selected_unit_id < world_state.unit_count:
		var sp := world_state.unit_pos[world_state.selected_unit_id]
		focus_xz = Vector2(sp.x, sp.z)

	var res := 0
	match action_code:
		"ORDER_ASAT_STRIKE":
			res = StrategicMddSystemScript.execute_asat_strike(world_state, faction, focus_xz)
			WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "asat_orbital_warfare", "DIRECT-ASCENT ASAT STRIKE AT 550 KM LEO")
		"ORDER_CYBER_CNO":
			res = StrategicMddSystemScript.execute_cyber_cno_strike(world_state, sim_db_ref, faction, focus_xz, 135.0)
			WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "cyber_hemp_blackout", "OFFENSIVE CYBER CNO TAKEDOWN OF SECTOR C2 & POWER GRID")
		"ORDER_PSYOP_EVAC":
			res = StrategicMddSystemScript.execute_psyop_evac_broadcast(world_state, sim_db_ref, faction, focus_xz, 120.0)
		"ORDER_CBRN_MOPP":
			res = StrategicMddSystemScript.execute_cbrn_mopp_and_hazard(world_state, faction, focus_xz, true)
			WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "cbrn_hazard_plume", "CBRN HAZARD PLUME & MOPP-4 PROTECTIVE POSTURE ACTIVATED")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## FEAT-12: Executes a 4-phase coordinated strike package (CEMA, SEAD, Decoys, Hypersonic)
func execute_coordinated_strike_package(target_coord: Vector3, package_config: Dictionary = {}) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = CoordinatedStrikeSystemScript.execute_strike_package(world_state, sim_db_ref, target_coord, package_config)
	if defcon_escalation_system != null:
		defcon_escalation_system.trigger_event("BALLISTIC_LAUNCH", 8.0, "Coordinated Strike Package Launched")
	WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "missile_alpha_strike", "COORDINATED MULTI-DOMAIN 4-PHASE STRIKE WAVE EXECUTED")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## FEAT-09: Verifies dual-key Permissive Action Link (PAL) authorization
func verify_pal_code(key_alpha: String, key_bravo: String) -> bool:
	if defcon_escalation_system != null:
		return defcon_escalation_system.verify_pal_code(key_alpha, key_bravo)
	return false


## FEAT-09: Triggers explicit DEFCON escalation event
func trigger_defcon_event(event_type: String, weight: float = 5.0, reason: String = "") -> void:
	if defcon_escalation_system != null:
		defcon_escalation_system.trigger_event(event_type, weight, reason)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()


## Unlocks a 5-Branch R&D Technology Tree node (`tech_slug`) for `faction` (1=BLUE, 2=RED).
func unlock_tech(tech_slug: String, faction: int = WorldState.FACTION_BLUE) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = BudgetTechSystemScript.unlock_tech_node(world_state, sim_db_ref, faction, tech_slug)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Procures an Emergency Strategic Airlift Resupply (+4 Primary/+4 Secondary ammo across theater units) for $250M.
func procure_ammo_airlift(faction: int = WorldState.FACTION_BLUE) -> bool:
	_resolve_autoloads()
	var ok: bool = BudgetTechSystemScript.procure_emergency_ammo_airlift(world_state, sim_db_ref, faction)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return ok


## Procures a Reinforcement Task Force package (`TF_STEALTH_AIR`, `TF_ROBOT_ARMOR`, `TF_LASER_IADS`, `TF_NAVAL_STRIKE`).
func procure_task_force(package_code: String, faction: int = WorldState.FACTION_BLUE) -> int:
	_resolve_autoloads()
	var spawned: int = BudgetTechSystemScript.procure_reinforcement_package(world_state, sim_db_ref, faction, package_code)
	if spawned > 0:
		SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
		spatial_grid.rebuild(world_state)
		EchelonClusterSystem.step(world_state)
		snapshot_buffer.publish_snapshot(world_state)
		_flush_sim_events_to_signals()
	return spawned


## Executes an Escalated NBC / HEMP / Orbital Rod / Thermonuclear Warfare Strike (`STRIKE_TACTICAL_CBRN`, `STRIKE_HEMP_EMP`, `STRIKE_ORBITAL_RODS`, `STRIKE_THERMONUCLEAR`).
func execute_escalated_strike(strike_type: String, target_pos_km: Vector3 = Vector3.ZERO, faction: int = WorldState.FACTION_BLUE) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = BudgetTechSystemScript.execute_escalated_warfare_strike(world_state, sim_db_ref, faction, strike_type, target_pos_km)
	if bool(res.get("ok", false)):
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, strike_type, String(res.get("headline", "")))
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Relocates the player's Command Bunker to either a custom theater coordinate OR cycles to the next hardened alternate command site.
func relocate_bunker(custom_pos_km: Vector3 = Vector3.INF, custom_name: String = "") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = BudgetTechSystemScript.relocate_command_bunker(world_state, custom_pos_km, custom_name)
	if bool(res.get("ok", false)):
		WarNewsVideoSystemScript.trigger_broadcast(
			world_state, sim_db_ref, "bunker_under_attack",
			"HQ COMMAND BUNKER RELOCATED TO %s" % world_state.bunker_base_name
		)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Applies direct kinetic/WMD damage or ground-capture progress to the Command Bunker; triggers GAME OVER if destroyed or captured.
func damage_or_capture_bunker(damage_hp: float, capture_delta: float, cause_desc: String = "OPFOR Assault on Command Bunker") -> bool:
	_resolve_autoloads()
	var lost: bool = BudgetTechSystemScript.damage_or_capture_command_bunker(world_state, damage_hp, capture_delta, cause_desc)
	WarNewsVideoSystemScript.trigger_broadcast(
		world_state, sim_db_ref, "bunker_under_attack",
		"HQ BUNKER '%s' UNDER ASSAULT (%s) | Hull %.0f%% | Capture %.0f%%" % [
			world_state.bunker_base_name, cause_desc,
			(world_state.bunker_hp / maxf(1.0, world_state.bunker_max_hp)) * 100.0,
			world_state.bunker_capture_progress
		]
	)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return lost


## Executes a Diplomatic Treaty / Action (`DIPLO_ENVOY_SUMMIT`, `DIPLO_AIRSPACE_ACCESS`, `DIPLO_REQUEST_ALLY_AID`, `DIPLO_MILITARY_ALLIANCE`) for `faction` (1=BLUE, 2=RED).
func execute_diplomacy(action_code: String = "DIPLO_MILITARY_ALLIANCE", nation_slug: String = "", faction: int = WorldState.FACTION_BLUE) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = DiplomacySystemScript.execute_diplomatic_action(world_state, sim_db_ref, faction, nation_slug, action_code)
	if bool(res.get("ok", false)):
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "diplomatic_alliance_summit", String(res.get("headline", "")))
	SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
	spatial_grid.rebuild(world_state)
	EchelonClusterSystem.step(world_state)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Triggers a Live TV War News Video Broadcast (with optional live Google Gemini 2.5 Flash anchor bulletin and Veo 3.1 Fast custom video generation).
func trigger_news_video_broadcast(
	slug_or_trigger: String = "missile_alpha_strike",
	custom_context: String = "",
	spawn_async_gemini: bool = false,
	generate_custom_veo: bool = false
) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = WarNewsVideoSystemScript.trigger_broadcast(
		world_state, sim_db_ref, slug_or_trigger, custom_context, spawn_async_gemini, generate_custom_veo
	)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Invokes `tools/news_video_pipeline/live_news_worker.py` (Google Gemini 2.5 Flash + optional Veo 3.1 Fast) for a live AI television bulletin.
func generate_live_gemini_tv_bulletin(
	slug: String = "missile_alpha_strike",
	custom_context: String = "",
	blocking: bool = false,
	generate_custom_veo: bool = false
) -> bool:
	_resolve_autoloads()
	var ok: bool = WarNewsVideoSystemScript.launch_live_gemini_news_worker(
		world_state, slug, custom_context, generate_custom_veo, blocking
	)
	if blocking and ok:
		snapshot_buffer.publish_snapshot(world_state)
		_flush_sim_events_to_signals()
	return ok


## Procedurally synthesizes a new AI-Generated Sovereign Nation / Geopolitical Defense Bloc in the active theater.
func generate_ai_diplomatic_country(broadcast_news: bool = true) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = DiplomacySystemScript.generate_ai_country(world_state, sim_db_ref, broadcast_news)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 24: Sets the active theater weather condition (`CLEAR`, `OVERCAST`, `TYPHOON_STORM`, `SANDSTORM`, `ARCTIC_BLIZZARD`).
func set_weather_condition(condition_code: String) -> void:
	_resolve_autoloads()
	weather_solar_system.set_weather_condition(world_state, condition_code, true)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()


## Phase 24: Cycles to the next theater weather condition and returns the new code.
func cycle_weather_condition() -> String:
	_resolve_autoloads()
	var next_code: String = weather_solar_system.cycle_weather_condition(world_state)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return next_code


## Phase 25: Rings the encrypted Red Phone Hotline on the Command Bunker console with an OPFOR Supreme Commander ultimatum.
func trigger_red_phone_hotline(reason: String = "STRATEGIC_ULTIMATUM") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = red_phone_hotline_system.trigger_hotline_call(world_state, sim_db_ref, reason)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 25: Resolves an active Red Phone Hotline negotiation (`HOTLINE_ACCEPT_CEASEFIRE`, `HOTLINE_BRIBE_DEESCALATE`, `HOTLINE_BLUFF_DETERRENCE`, `HOTLINE_REJECT_ESCALATE`).
func resolve_red_phone_hotline(choice_code: String = "HOTLINE_ACCEPT_CEASEFIRE") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = red_phone_hotline_system.resolve_hotline_call(world_state, sim_db_ref, choice_code)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 23: Saves the complete live campaign state to `res://data/saves/campaign_<slot_id>.json`.
func save_campaign_state(slot_id: String = "slot_1") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = campaign_persistence_system.save_campaign_slot(world_state, sim_db_ref, slot_id, current_scenario_slug)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 23: Loads a saved campaign state from `res://data/saves/campaign_<slot_id>.json`.
func load_campaign_state(slot_id: String = "slot_1") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = campaign_persistence_system.load_campaign_slot(world_state, sim_db_ref, slot_id)
	if bool(res.get("ok", false)):
		current_scenario_slug = str(res.get("scenario_slug", current_scenario_slug))
		CivilianDensitySystemScript.seed_theater_civilian_density(world_state)
		TerrainInfrastructureSystemScript.seed_theater_infrastructure(world_state)
		CivilianTrafficConvoySystemScript.seed_theater_traffic_and_shipping(world_state)
		SubterraneanTunnelSystemScript.seed_theater_tunnel_complexes(world_state)
		CombatEngineeringAirborneSystemScript.seed_theater_minefields(world_state)
		UnderseaWarfareSystemScript.seed_theater_undersea_cables(world_state)
		StrategicMddSystemScript.seed_orbital_constellation(world_state)
		SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
		spatial_grid.rebuild(world_state)
		ElectronicWarfareSystem.step(world_state, sim_db_ref, spatial_grid)
		SensorLoSSystem.step(world_state, sim_db_ref, spatial_grid, cs_kernel)
		EchelonClusterSystem.step(world_state)
		_update_fow_global_texture()
		snapshot_buffer.publish_snapshot(world_state)
		snapshot_buffer.publish_snapshot(world_state)
		_flush_sim_events_to_signals()
	return res


## Phase 23: Spawns a custom unit in the Scenario / Force Editor and rebuilds spatial indices.
func spawn_custom_editor_unit(platform_slug: String, faction: int, pos_km: Vector3) -> int:
	_resolve_autoloads()
	var uid: int = campaign_persistence_system.spawn_custom_editor_unit(world_state, sim_db_ref, platform_slug, faction, pos_km)
	if uid >= 0:
		SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
		spatial_grid.rebuild(world_state)
		EchelonClusterSystem.step(world_state)
		snapshot_buffer.publish_snapshot(world_state)
	return uid


## Phase 23: Exports the current War Table ORBAT to a standalone shareable scenario JSON file in `res://data/saves/custom_scenario_<slug>.json`.
func export_custom_scenario(custom_slug: String = "op_custom_user_theater", custom_title: String = "Custom Commander Scenario") -> Dictionary:
	_resolve_autoloads()
	return campaign_persistence_system.export_custom_scenario_json(world_state, sim_db_ref, custom_slug, custom_title)


## Phase 26: Declares an Official Humanitarian Evacuation Corridor (`[F7]`), accelerating civilian highway evacuation (+65%), awarding +$200M UN Aid & -10% Escalation.
func declare_humanitarian_corridor() -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = CivilianTrafficConvoySystemScript.declare_humanitarian_corridor(world_state, sim_db_ref)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 26: Executes a Naval Maritime Blockade / VBSS Boarding Interdiction against sanctioned OPFOR tankers (+$180M seized warchest).
func execute_maritime_interdiction() -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = CivilianTrafficConvoySystemScript.execute_maritime_interdiction(world_state, sim_db_ref)
	WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "naval_carrier_strike", "MARITIME VBSS INTERDICTION OF SANCTIONED OPFOR TANKER")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 27: Executes a Subterranean Counter-Tunnel Operation (`TUNNEL_GPR_SCAN`, `BUNKER_BUSTER_MOP`, `ROBOT_DOG_TUNNEL_BREACH`).
func execute_tunnel_operation(op_code: String = "ROBOT_DOG_TUNNEL_BREACH", target_tunnel_id: int = -1) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = SubterraneanTunnelSystemScript.execute_tunnel_operation(world_state, sim_db_ref, op_code, target_tunnel_id)
	if op_code == "BUNKER_BUSTER_MOP":
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "stealth_airstrike_sortie", "GBU-57 MOP BUNKER-BUSTER STRIKE COLLAPSES SUBTERRANEAN GALLERY")
	elif op_code == "ROBOT_DOG_TUNNEL_BREACH":
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "urban_armor_robot_dogs", "ROBOT DOG & SPECOPS BREACH CAPTURES UNDERGROUND TUNNEL COMPLEX")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 28: Executes a Strategic CEMA Cyber-EW Operation (`CEMA_GRID_BLACKOUT`, `CEMA_DRONE_HIJACK`, `CEMA_DEEPFAKE_GHOST_DECOYS`, `CEMA_QUANTUM_FIREWALL_PATCH`).
func execute_cema_operation(op_code: String = "CEMA_DRONE_HIJACK") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = CemaElectronicWarfareSystemScript.execute_cema_operation(world_state, sim_db_ref, op_code)
	WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "cyber_hemp_blackout", world_state.latest_cema_status)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 31: Executes a Combat Engineering or Airborne Paratrooper Insertion (`AIRBORNE_PARATROOP_DROP`, `DEPLOY_SMART_MINEFIELD`, `ENGINEER_BREACH_AND_REBUILD`).
func execute_engineering_or_airborne_op(op_code: String = "AIRBORNE_PARATROOP_DROP", target_pos_km: Vector3 = Vector3.INF) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = CombatEngineeringAirborneSystemScript.execute_engineering_or_airborne_op(world_state, sim_db_ref, op_code, target_pos_km)
	if op_code == "AIRBORNE_PARATROOP_DROP":
		SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
		spatial_grid.rebuild(world_state)
		EchelonClusterSystem.step(world_state)
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "urban_armor_robot_dogs", "AIRBORNE PARATROOPER, SNIPER & ROBOT DOG INSERTION")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 32: Executes an Undersea Warfare / Subsea Cable Operation (`UNDERSEA_DEPLOY_SOSUS_BARRIER`, `UNDERSEA_SABOTAGE_ENEMY_CABLE`, `UNDERSEA_REPAIR_CABLE_SHIP`).
func execute_undersea_operation(op_code: String = "UNDERSEA_SABOTAGE_ENEMY_CABLE") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = UnderseaWarfareSystemScript.execute_undersea_operation(world_state, sim_db_ref, op_code)
	WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "naval_carrier_strike", "SUBSEA FIBER-OPTIC CABLE & SOSUS UNDERSEA WARFARE OPERATION")
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 33: Executes a Homefront War Economy or UN ROE Action (`HOMEFRONT_ISSUE_WAR_BONDS`, `HOMEFRONT_ENFORCE_SURGICAL_ROE`, `HOMEFRONT_STRATEGIC_PETRO_RESERVE`).
func execute_homefront_action(action_code: String = "HOMEFRONT_ISSUE_WAR_BONDS") -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = HomefrontEconomySystemScript.execute_homefront_action(world_state, sim_db_ref, action_code)
	WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "diplomatic_alliance_summit", world_state.latest_homefront_status)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


## Phase 35: Ensures USS Cheyenne SSN-688(I) nuclear submarine exists in theater and returns its `unit_id`.
func ensure_player_submarine() -> int:
	_resolve_autoloads()
	var uid: int = NuclearSubmarineSystemScript.ensure_player_submarine_unit(world_state, sim_db_ref)
	NuclearSubmarineSystemScript.step(world_state, sim_db_ref, 0.05)
	snapshot_buffer.publish_snapshot(world_state)
	return uid


## Phase 35: Executes a 688(I) Nuclear Attack Submarine Conn command (`SUB_SET_DEPTH`, `SUB_SET_THROTTLE`, `SUB_TURN_HEADING`, `SUB_TOGGLE_PERISCOPE`, `SUB_CYCLE_TARGET`, `SUB_FIRE_TORPEDO`, `SUB_LAUNCH_VLS_TOMAHAWK`, `SUB_LAUNCH_DECOY`, `SUB_EMERGENCY_BLOW`).
func execute_submarine_command(cmd_code: String, param: float = 0.0) -> Dictionary:
	_resolve_autoloads()
	var res: Dictionary = NuclearSubmarineSystemScript.execute_sub_command(world_state, sim_db_ref, cmd_code, param)
	if cmd_code in ["SUB_FIRE_TORPEDO", "SUB_LAUNCH_VLS_TOMAHAWK"]:
		WarNewsVideoSystemScript.trigger_broadcast(world_state, sim_db_ref, "naval_carrier_strike", world_state.sub_status_log)
	snapshot_buffer.publish_snapshot(world_state)
	_flush_sim_events_to_signals()
	return res


func _auto_queue_alpha_strike_package(faction: int) -> void:
	var target_uid := -1
	var target_pos := Vector3(-110.0, 50.0, -10.0) if faction == WorldState.FACTION_BLUE else Vector3(110.0, 50.0, -40.0)
	for uid in range(world_state.unit_count):
		if world_state.unit_active[uid] == 1 and world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY and world_state.unit_faction[uid] != faction:
			target_uid = uid
			target_pos = world_state.unit_pos[uid]
			break

	var attackers: Array[int] = []
	for uid in range(world_state.unit_count):
		if world_state.unit_active[uid] == 1 and world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY and world_state.unit_faction[uid] == faction:
			if world_state.unit_ammo_1[uid] > 0:
				attackers.append(uid)
				if attackers.size() >= 16:
					break
	if attackers.size() > 0:
		world_state.queued_strikes.append({
			"package_id": 999,
			"faction": faction,
			"attacker_ids": attackers,
			"target_unit_id": target_uid,
			"target_pos_km": target_pos,
			"weapon_slot": 1,
			"salvo_per_unit": 2,
		})


func _exit_tree() -> void:
	cleanup()


func cleanup() -> void:
	if _worker_task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_worker_task_id)
		_worker_task_id = -1
	RenderingServer.global_shader_parameter_set("fow_threat_map", null)
	RenderingServer.global_shader_parameter_set("terrain_infra_map", null)
	_fow_texture = null
	_infra_texture = null


func _update_fow_global_texture() -> void:
	if sim_db_ref == null:
		return
	var fow_res := 64
	var img := SensorLoSSystem.build_fow_threat_image(world_state, sim_db_ref, fow_res)
	if _fow_texture == null:
		_fow_texture = ImageTexture.create_from_image(img)
	else:
		_fow_texture.update(img)
	RenderingServer.global_shader_parameter_set("fow_threat_map", _fow_texture)

	var cur_destr: int = world_state.active_destroyed_cells_count
	if _infra_texture == null or cur_destr != _last_cached_destroyed_count:
		_last_cached_destroyed_count = cur_destr
		var infra_img := TerrainInfrastructureSystemScript.build_infra_image(world_state)
		if _infra_texture == null:
			_infra_texture = ImageTexture.create_from_image(infra_img)
		else:
			_infra_texture.update(infra_img)
		RenderingServer.global_shader_parameter_set("terrain_infra_map", _infra_texture)



## Spawns Army Group scale reinforcements across the 2,000x2,000km theater up to `target_unit_count` (e.g., 5,000–12,000+ units)
## using authentic theater-specific national army compositions (Infantry/Mech, Drone Swarms, Artillery, Armor, Air, IADS).
func _populate_army_group_waves(target_unit_count: int = 5000) -> void:
	var t_slug := world_state.active_theater_slug
	var blue_slugs := ["m2a4_mech_company", "m2a4_mech_company", "fpv_fiber_swarm", "vision_60_q_ugv", "m1a2_sepv3_platoon", "f_35a_lightning", "mim_104f_patriot", "hemtt_supply_convoy"]
	var red_slugs := ["t_90m_platoon", "unitree_b2w_armed", "lancet_3_team", "shahed_136_launcher", "uran_9_ugv", "j_20_mighty_dragon", "s_400_triumf", "krasukha_4_ew"]
	var blue_west_side := false
	var north_south_split := false

	if t_slug.find("ukraine") != -1 or t_slug.find("donbas") != -1:
		blue_slugs = ["btr_4_bucephalus_co", "btr_4_bucephalus_co", "fpv_fiber_swarm", "fpv_fiber_swarm", "bohdana_2s22_artillery", "t_84_oplot_platoon", "m2a4_mech_company", "neptune_rk360mc_battery", "palianytsia_drone_uk", "f_16cj_block70"]
		red_slugs = ["t_90m_platoon", "uran_9_ugv", "lancet_3_team", "lancet_3_team", "shahed_136_launcher", "s_400_triumf", "krasukha_4_ew", "su_57_felon", "tu_22m3_backfire", "unitree_b2w_armed"]
		blue_west_side = true
	elif t_slug.find("mexico") != -1 or t_slug.find("rio_grande") != -1:
		blue_slugs = ["m2a4_mech_company", "m1a2_sepv3_platoon", "epirus_leonidas_hpm", "vision_60_q_ugv", "specops_mountain_team", "f_35a_lightning", "mim_104f_patriot", "hemtt_supply_convoy"]
		red_slugs = ["dn_xi_mexican_armor", "dn_xi_mexican_armor", "specops_mountain_team", "fpv_fiber_swarm", "switchblade_600_team", "f_5f_tiger_mex_flight", "dn_xi_mexican_armor", "f_5f_tiger_mex_flight"]
		north_south_split = true
	elif t_slug.find("baltic") != -1 or t_slug.find("suwalki") != -1:
		blue_slugs = ["leopard_2a8_platoon", "m2a4_mech_company", "milrem_themis_ugv", "skynex_ahead_battery", "rafale_f4_flight", "f_35a_lightning", "mim_104f_patriot", "hemtt_supply_convoy"]
		red_slugs = ["t_90m_platoon", "uran_9_ugv", "lancet_3_team", "shahed_136_launcher", "s_400_triumf", "krasukha_4_ew", "su_57_felon", "tu_22m3_backfire"]
		blue_west_side = true
	elif t_slug.find("himalaya") != -1 or t_slug.find("lac") != -1:
		blue_slugs = ["specops_mountain_team", "zorawar_mountain_tank", "vision_60_q_ugv", "fpv_fiber_swarm", "brahmos_coastal_battery", "hal_tejas_mk2", "rafale_f4_flight", "hemtt_supply_convoy"]
		red_slugs = ["unitree_b2w_armed", "t_90m_platoon", "lancet_3_team", "bayraktar_akinci_ucav", "jf_17_block3_flight", "j_20_mighty_dragon", "s_400_triumf", "krasukha_4_ew"]
		blue_west_side = true
	elif t_slug.find("korea") != -1:
		blue_slugs = ["k2_black_panther", "m2a4_mech_company", "vision_60_q_ugv", "hyunmoo_5_tel", "kf_21_boramae", "f_35a_lightning", "mim_104f_patriot", "iron_beam_helws"]
		red_slugs = ["kn_25_mlrs_battery", "t_90m_platoon", "unitree_b2w_armed", "lancet_3_team", "shahed_136_launcher", "s_400_triumf", "krasukha_4_ew", "uran_9_ugv"]

	var wave := 0
	while world_state.unit_count < mini(target_unit_count, WorldState.MAX_UNITS - 64):
		var z_off := -210.0 + float((wave * 37) % 420)
		var x_blue := 68.0 + float((wave * 29) % 165)
		var x_red := -68.0 - float((wave * 31) % 165)
		var adv := Vector2(-28.0, 0.0)
		if blue_west_side:
			x_blue = -68.0 - float((wave * 29) % 165)
			x_red = 68.0 + float((wave * 31) % 165)
			adv = Vector2(28.0, 0.0)
		elif north_south_split:
			x_blue = -180.0 + float((wave * 37) % 320)
			x_red = -180.0 + float((wave * 41) % 320)
			var z_b := -58.0 - float((wave * 23) % 160)
			var z_r := 58.0 + float((wave * 29) % 160)
			_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(x_blue, z_b), Vector2(x_red, z_r), Vector2(0.0, 28.0), 1, 3, 6)
			wave += 1
			continue
		_spawn_symmetric_theater_forces(blue_slugs, red_slugs, Vector2(x_blue, z_off), Vector2(x_red, z_off), adv, 1, 3, 6)
		wave += 1


func spawn_army_group_reinforcements(target_unit_count: int = 5000) -> int:
	_resolve_autoloads()
	_populate_army_group_waves(target_unit_count)
	SimLodSystemScript.update_sim_lod_tiers(world_state, cs_kernel)
	spatial_grid.rebuild(world_state)
	EchelonClusterSystem.step(world_state)
	snapshot_buffer.publish_snapshot(world_state)
	return world_state.get_active_unit_count()


## Returns all active Sniper, Commando, and SpecOps Infantry leaf units (`tier1_sniper_recon_team`, `navy_seal_commando_squad`, `specops_mountain_team`, `spetsnaz_sniper_commando`, `m2a4_mech_company`).
func get_active_sniper_and_commando_units(faction: int = 0) -> Array[int]:
	_resolve_autoloads()
	var out: Array[int] = []
	for uid in range(world_state.unit_count):
		if world_state.unit_active[uid] == 0 or world_state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		if faction != 0 and world_state.unit_faction[uid] != faction:
			continue
		var pdef: Dictionary = sim_db_ref.get_platform(world_state.unit_platform_id[uid])
		var slug := String(pdef.get("slug", ""))
		if slug in ["tier1_sniper_recon_team", "navy_seal_commando_squad", "specops_mountain_team", "spetsnaz_sniper_commando"]:
			out.append(uid)
	return out


func get_fow_texture() -> Texture2D:
	if _fow_texture == null:
		_update_fow_global_texture()
	return _fow_texture


func _flush_sim_events_to_signals() -> void:
	if signal_bus_ref == null or world_state.sim_events_queue.is_empty():
		return
	var evs := world_state.sim_events_queue.duplicate(true)
	world_state.sim_events_queue.clear()
	for ev in evs:
		var etype := String(ev.get("type", ""))
		match etype:
			"salvo_launched":
				signal_bus_ref.salvo_launched.emit(int(ev["attacker_id"]), int(ev["target_id"]), int(ev["weapon_id"]), ev["pos_km"])
			"alpha_strike_committed":
				signal_bus_ref.alpha_strike_committed.emit(int(ev["faction"]), int(ev["total_missiles_launched"]))
			"directed_energy_fired":
				signal_bus_ref.directed_energy_fired.emit(int(ev["shooter_id"]), ev["target_pos_km"], bool(ev["is_hpm_cone"]), float(ev["de_kw"]))
			"unit_damaged":
				signal_bus_ref.unit_damaged.emit(int(ev["unit_id"]), float(ev["damage"]), ev["pos_km"], float(ev["cost_musd"]))
				signal_bus_ref.dollar_loss_updated.emit(world_state.blue_lost_musd, world_state.red_lost_musd)
			"unit_destroyed":
				signal_bus_ref.unit_destroyed.emit(int(ev["unit_id"]), int(ev["platform_id"]), int(ev["faction"]), ev["pos_km"], float(ev["unit_cost_musd"]))
				signal_bus_ref.dollar_loss_updated.emit(world_state.blue_lost_musd, world_state.red_lost_musd)
			"unmanned_deployed":
				signal_bus_ref.unmanned_deployed.emit(int(ev["parent_unit_id"]), int(ev["child_unit_id"]), int(ev["sub_platform_id"]), ev["pos_km"])
			"strike_queued":
				signal_bus_ref.strike_queued.emit(int(ev["package_id"]), int(ev["attacker_count"]), int(ev["target_unit_id"]))
			"master_iads_toggled":
				signal_bus_ref.master_iads_toggled.emit(int(ev["faction"]), bool(ev["radar_enabled"]))
			"time_scale_changed":
				signal_bus_ref.time_scale_changed.emit(float(ev["new_scale"]))
			"DEFCON_CHANGED":
				signal_bus_ref.defcon_changed.emit(int(ev.get("defcon", world_state.defcon_level)), float(ev.get("escalation", world_state.global_escalation_score)), String(ev.get("declaration", "")))
			"TECH_UNLOCKED":
				signal_bus_ref.tech_unlocked.emit(int(ev.get("faction", 1)), String(ev.get("tech_slug", "")), String(ev.get("display_name", "")), float(ev.get("remaining_budget_musd", world_state.blue_budget_available_musd)))
			"WMD_DETONATED":
				signal_bus_ref.strategic_wmd_detonated.emit(String(ev.get("wmd_type", "NUKE")), int(ev.get("faction", 1)), ev.get("pos_km", Vector3.ZERO), float(ev.get("yield_kt", 100.0)))
				signal_bus_ref.world_news_flashed.emit("USSTRATCOM FLASH", world_state.latest_world_news_headline, world_state.defcon_level)
			"BUNKER_RELOCATED":
				signal_bus_ref.bunker_relocated.emit(String(ev.get("bunker_name", world_state.bunker_base_name)), ev.get("pos_km", world_state.bunker_pos_km), int(ev.get("relocations_count", world_state.bunker_relocations_count)))
			"BUNKER_GAME_OVER":
				var reason_str := String(ev.get("reason", world_state.bunker_loss_reason))
				var cap_flag := bool(ev.get("was_captured", world_state.bunker_was_captured))
				signal_bus_ref.bunker_game_over.emit(reason_str, cap_flag)
				signal_bus_ref.battle_concluded.emit(false, "GAME OVER // " + reason_str, world_state.blue_lost_musd, world_state.red_lost_musd)
			"DIPLOMATIC_EVENT":
				var d_fac := int(ev.get("faction", 1))
				var d_iso := String(ev.get("iso", "UN"))
				var d_act := String(ev.get("action", "DIPLO_MILITARY_ALLIANCE"))
				var d_head := String(ev.get("headline", world_state.latest_diplomatic_cable))
				signal_bus_ref.diplomatic_treaty_signed.emit(d_fac, d_iso, d_act, d_head)
				signal_bus_ref.world_news_flashed.emit("DIPLOMACY // " + d_iso, d_head, world_state.defcon_level)
			"WAR_NEWS_VIDEO_BROADCASTED":
				signal_bus_ref.war_news_video_broadcasted.emit(
					String(ev.get("clip_slug", world_state.active_news_video_slug)),
					String(ev.get("network", world_state.active_news_video_network)),
					String(ev.get("headline", world_state.active_news_video_headline)),
					String(ev.get("sub_chyron", world_state.active_news_video_sub_chyron)),
					String(ev.get("correspondent", world_state.active_news_video_correspondent)),
					int(ev.get("defcon", world_state.defcon_level))
				)
			"WEATHER_CHANGED", "weather_condition_changed":
				signal_bus_ref.weather_condition_changed.emit(
					String(ev.get("weather_code", world_state.weather_condition_code)),
					int(ev.get("sea_state", world_state.sea_state_beaufort)),
					float(ev.get("solar_hour", world_state.solar_hour_utc)),
					float(ev.get("ir_mult", world_state.weather_ir_eo_mult)),
					float(ev.get("laser_mult", world_state.weather_laser_mult))
				)
			"red_phone_hotline_ringing":
				signal_bus_ref.red_phone_hotline_ringing.emit(
					String(ev.get("leader_name", world_state.hotline_leader_name)),
					String(ev.get("leader_title", world_state.hotline_leader_title)),
					String(ev.get("headline", world_state.hotline_demand_headline)),
					String(ev.get("body", world_state.hotline_demand_body)),
					int(ev.get("defcon", world_state.defcon_level))
				)
			"red_phone_hotline_resolved":
				signal_bus_ref.red_phone_hotline_resolved.emit(
					String(ev.get("choice_code", "")),
					String(ev.get("outcome_summary", ""))
				)
			"campaign_state_saved":
				signal_bus_ref.campaign_state_saved.emit(
					1,
					String(ev.get("file_path", world_state.last_saved_slot_path)),
					"Saved %d units (%s)" % [int(ev.get("units_saved", 0)), String(ev.get("slot_id", "slot_1"))]
				)
			"campaign_state_loaded":
				signal_bus_ref.campaign_state_loaded.emit(
					1,
					String(ev.get("file_path", world_state.last_saved_slot_path)),
					"Loaded %d units (%s)" % [int(ev.get("units_loaded", 0)), String(ev.get("slot_id", "slot_1"))]
				)

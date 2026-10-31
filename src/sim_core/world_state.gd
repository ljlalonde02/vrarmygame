class_name WorldState
extends RefCounted
## Pure Data-Oriented Structure-of-Arrays (SoA) simulation state.
## Zero Node3D/CharacterBody3D dependencies so 4,000+ units and 8,000+ munitions update in <5ms on WorkerThreadPool.

const MAX_UNITS := 16384
const MAX_MUNITIONS := 8192

const FACTION_BLUE := 1
const FACTION_RED := 2

const ECHELON_COMPANY := 0   # Tactical leaf unit (Flight, Platoon, Robot Dog Pack, FPV Swarm, Ship)
const ECHELON_BATTALION := 1 # Operational group (Squadron, Battalion)
const ECHELON_BRIGADE := 2   # Strategic cluster (Wing, Brigade, Task Force)

const LOD_TIER_0_MICRO := 0       # Full 10 Hz Agent Physics, 3D Ribbons, Ray-LoS & Squad Disaggregation
const LOD_TIER_1_OPERATIONAL := 1 # 5 Hz Operational Salvo & Fast Horizon LoS
const LOD_TIER_2_MACRO := 2       # 1 Hz Statistical Lanchester Echelon Aggregation

const CIV_GRID_SIZE := 128        # 128x128 (16,384 cells) Spreading Civilian Density Grid (civilians/m^2)
const CIV_CELL_AREA_M2 := 15258789.0 # (500,000m / 128)^2 m^2 per cell (~15.26 km^2)

const AI_PATROL_CAP := 0
const AI_BVR_INTERCEPT := 1
const AI_SEAD_TERRAIN_MASK := 2
const AI_EVASIVE_DEFENSIVE := 3
const AI_UNMANNED_ASSAULT := 4
const AI_SHOOT_AND_SCOOT := 5
const AI_RTB_RESUPPLY := 6

const TACTICAL_POSTURE_AUTO := 0
const TACTICAL_POSTURE_BVR_STANDOFF := 1
const TACTICAL_POSTURE_AGGRESSIVE_PURSUIT := 2
const TACTICAL_POSTURE_DEFENSIVE_BREAK := 3
const TACTICAL_POSTURE_HOLD_AMBUSH := 4
const TACTICAL_POSTURE_RETREAT := 5

# --- Unit SoA Pools (Coordinate convention: x = East/West km [-250..250], y = Altitude meters, z = North/South km [-250..250]) ---
var unit_count: int = 0
var unit_active: PackedByteArray = PackedByteArray()
var unit_tactical_posture: PackedByteArray = PackedByteArray()
var unit_posture: PackedByteArray:
	get: return unit_tactical_posture
	set(val): unit_tactical_posture = val
var unit_pos: PackedVector3Array = PackedVector3Array()
var unit_vel: PackedVector3Array = PackedVector3Array()
var unit_target_pos: PackedVector3Array = PackedVector3Array()
var unit_has_waypoint: PackedByteArray = PackedByteArray()
var unit_faction: PackedByteArray = PackedByteArray()
var unit_platform_id: PackedInt32Array = PackedInt32Array()
var unit_echelon: PackedByteArray = PackedByteArray()
var unit_parent_id: PackedInt32Array = PackedInt32Array()
var unit_radar_active: PackedByteArray = PackedByteArray()
var unit_roe: PackedByteArray = PackedByteArray()
var unit_hp: PackedFloat32Array = PackedFloat32Array()
var unit_max_hp: PackedFloat32Array = PackedFloat32Array()
var unit_ammo_1: PackedInt32Array = PackedInt32Array()
var unit_ammo_2: PackedInt32Array = PackedInt32Array()
var unit_energy_cap: PackedFloat32Array = PackedFloat32Array()
var unit_unmanned_bays: PackedInt32Array = PackedInt32Array()
var unit_detected_mask: PackedByteArray = PackedByteArray()
var unit_jammed: PackedByteArray = PackedByteArray()
var unit_cooldown: PackedFloat32Array = PackedFloat32Array()
var unit_fuel_km: PackedFloat32Array = PackedFloat32Array()
var unit_max_fuel_km: PackedFloat32Array = PackedFloat32Array()
var unit_afterburner: PackedByteArray = PackedByteArray()
var unit_desired_alt_m: PackedFloat32Array = PackedFloat32Array()
var unit_ai_state: PackedByteArray = PackedByteArray()
var unit_threat_level: PackedFloat32Array = PackedFloat32Array()
var unit_player_override_timer: PackedFloat32Array = PackedFloat32Array()
var unit_heading_rad: PackedFloat32Array = PackedFloat32Array()
var unit_pitch_rad: PackedFloat32Array = PackedFloat32Array()
var unit_roll_rad: PackedFloat32Array = PackedFloat32Array()
var unit_turret_hdg_rad: PackedFloat32Array = PackedFloat32Array()
var unit_suppression_level: PackedFloat32Array = PackedFloat32Array()
var unit_sim_lod: PackedByteArray = PackedByteArray()
var unit_morale: PackedFloat32Array = PackedFloat32Array()
var unit_cyber_timer: PackedFloat32Array = PackedFloat32Array()
var unit_cbrn_mopp: PackedByteArray = PackedByteArray()
var unit_delegated_ai: PackedByteArray = PackedByteArray() # 1 = DELEGATED_TO_PARENT (Subordinate AI), 0 = DIRECT_PLAYER_CONTROL

# --- Sprint 7: Tactical Match Loop & Sonar Pings ---
var active_sonar_pings: Array[Dictionary] = []
var tactical_match_active: bool = false
var match_outcome: String = "IN_PROGRESS" # "IN_PROGRESS", "VICTORY", "DEFEAT"
var match_objectives: Array[Dictionary] = []
var match_stats: Dictionary = {
	"blue_lost": 0,
	"red_lost": 0,
	"objectives_done": 0,
	"elapsed_sec": 0.0
}

# --- 4-Tier Hierarchical AI C2 Integrity (Command Bunkers + AWACS + SATCOM) ---
var blue_c2_integrity: float = 1.0
var red_c2_integrity: float = 1.0

# --- 3-Tier Zoom Sim-LOD Focus State ---
var sim_focus_center_km: Vector2 = Vector2.ZERO
var sim_focus_zoom: float = 1.0
var sim_focus_radius_km: float = 120.0
var selected_unit_id: int = -1
var lod_tier0_count: int = 0
var lod_tier1_count: int = 0
var lod_tier2_count: int = 0

# --- Spreading Civilian Density Field (civilians/m^2 across 128x128 theater grid) ---
var civ_density_m2: PackedFloat32Array = PackedFloat32Array()
var civ_initial_m2: PackedFloat32Array = PackedFloat32Array()
var civ_passability: PackedFloat32Array = PackedFloat32Array()
var civ_threat_field: PackedFloat32Array = PackedFloat32Array()
var civ_flux_activity: PackedFloat32Array = PackedFloat32Array()
var total_theater_civilians: float = 0.0
var total_displaced_civilians: float = 0.0
var estimated_civilian_casualties: float = 0.0

# --- Phase 10: 2D Wind-Advected Environmental Hazard Plume Field & Global Space Force Satellites ---
const MAX_SATELLITES := 24
const SAT_ROLE_RECON_SAR := 0
const SAT_ROLE_SATCOM_LEO := 1
const SAT_ROLE_PNT_GPS := 2
const SAT_ROLE_EARLY_WARN := 3

var hazard_density: PackedFloat32Array = PackedFloat32Array()
var wind_vec_km_s: Vector2 = Vector2(0.42, 0.18)
var active_hazard_cells_count: int = 0

var sat_count: int = 0
var sat_active: PackedByteArray = PackedByteArray()
var sat_faction: PackedByteArray = PackedByteArray()
var sat_role: PackedByteArray = PackedByteArray()
var sat_inclination_rad: PackedFloat32Array = PackedFloat32Array()
var sat_raan_rad: PackedFloat32Array = PackedFloat32Array()
var sat_phase_rad: PackedFloat32Array = PackedFloat32Array()
var sat_angular_vel: PackedFloat32Array = PackedFloat32Array()
var sat_alt_km: PackedFloat32Array = PackedFloat32Array()
var sat_speed_km_s: PackedFloat32Array = PackedFloat32Array()
var sat_pos_km: PackedVector3Array = PackedVector3Array()
var sat_dazzled_timer: PackedFloat32Array = PackedFloat32Array()

var blue_satcom_factor: float = 1.0
var red_satcom_factor: float = 1.0
var blue_pnt_factor: float = 1.0
var red_pnt_factor: float = 1.0
var asat_intercepts_count: int = 0
var cyber_strikes_count: int = 0
var psyop_broadcasts_count: int = 0

# --- Phase 11: Living Battlefield Infrastructure (Nature/Forests, Rivers/Bridges, Highways/Railways, Procedural 3D Cities/Airfields, Logistics Trains & War Destruction) ---
const BIOME_OCEAN := 0
const BIOME_PLAINS := 1
const BIOME_FOREST := 2
const BIOME_VILLAGE := 3
const BIOME_URBAN_CITY := 4
const BIOME_ALPINE := 5

const BLDG_VILLAGE_HOUSE := 0
const BLDG_URBAN_TOWER := 1
const BLDG_AIRPORT_RUNWAY := 2
const BLDG_AIRPORT_HANGAR := 3
const BLDG_BRIDGE_SPAN := 4
const BLDG_ROAD_AVENUE := 5

const MAX_TRAINS := 16

var infra_biome: PackedByteArray = PackedByteArray()           # 128x128 biome ID (Ocean, Plains, Forest, Village, City, Alpine)
var infra_forest_density: PackedFloat32Array = PackedFloat32Array() # 128x128 [0..1] Nature/Forest canopy cover
var infra_river_mask: PackedFloat32Array = PackedFloat32Array()     # 128x128 [0..1] Hydrological rivers carved from peaks to sea
var infra_road_mask: PackedFloat32Array = PackedFloat32Array()      # 128x128 [0..1] Highway / MSR road network
var infra_rail_mask: PackedFloat32Array = PackedFloat32Array()      # 128x128 [0..1] Heavy military railway corridors
var infra_bridge_mask: PackedFloat32Array = PackedFloat32Array()    # 128x128 [0..1] Road/Rail river bridge crossings
var infra_urban_density: PackedFloat32Array = PackedFloat32Array()  # 128x128 [0..1] Village / Town / City density
var destruction_level: PackedFloat32Array = PackedFloat32Array()    # 128x128 [0..1] Dynamic War Destruction / Rubble / Craters
var road_segments_km: Array[Vector4] = []                           # Inter-city highway segments (ax_km, az_km, bx_km, bz_km)
var city_hubs_km: Array[Vector3] = []                               # Urban street grid & ring-road hubs (cx_km, cz_km, radius_km)

var bldg_count: int = 0
var bldg_pos_km: PackedVector3Array = PackedVector3Array()     # (x_km, y_elev_m, z_km)
var bldg_scale_m: PackedVector3Array = PackedVector3Array()    # 3D table-local box dimensions (width, height, depth)
var bldg_yaw_rad: PackedFloat32Array = PackedFloat32Array()    # Rotation yaw (for aligned airport runways & bridges)
var bldg_type: PackedByteArray = PackedByteArray()             # BLDG_VILLAGE_HOUSE..BLDG_BRIDGE_SPAN
var bldg_cell_idx: PackedInt32Array = PackedInt32Array()       # Index into 128x128 destruction_level array

var train_count: int = 0
var train_active: PackedByteArray = PackedByteArray()
var train_faction: PackedByteArray = PackedByteArray()
var train_pos_km: PackedVector3Array = PackedVector3Array()
var train_start_km: PackedVector3Array = PackedVector3Array()
var train_end_km: PackedVector3Array = PackedVector3Array()
var train_heading_rad: PackedFloat32Array = PackedFloat32Array()
var train_progress: PackedFloat32Array = PackedFloat32Array()
var train_dir_sign: PackedFloat32Array = PackedFloat32Array()
var train_derailed: PackedByteArray = PackedByteArray()

var active_destroyed_cells_count: int = 0
var bridges_destroyed_count: int = 0
var trains_derailed_count: int = 0
var airfields_captured_count: int = 0

# Waypoint queues for multi-segment paths (unit_id -> Array[Vector3])
var unit_waypoint_queues: Dictionary = {}

# --- Munition SoA Pools ---
var mun_count: int = 0
var mun_active: PackedByteArray = PackedByteArray()
var mun_pos: PackedVector3Array = PackedVector3Array()
var mun_start_pos: PackedVector3Array = PackedVector3Array()
var mun_target_pos: PackedVector3Array = PackedVector3Array()
var mun_vel: PackedVector3Array = PackedVector3Array()
var mun_faction: PackedByteArray = PackedByteArray()
var mun_weapon_id: PackedInt32Array = PackedInt32Array()
var mun_shooter_id: PackedInt32Array = PackedInt32Array()
var mun_target_unit_id: PackedInt32Array = PackedInt32Array()
var mun_flight_progress: PackedFloat32Array = PackedFloat32Array()
var mun_total_dist_km: PackedFloat32Array = PackedFloat32Array()
var mun_apex_alt_m: PackedFloat32Array = PackedFloat32Array()
var mun_jammed: PackedByteArray = PackedByteArray()

# --- Queued Alpha Strike Packages & Transient Directed Energy / Shockwave Events ---
var queued_strikes: Array[Dictionary] = []
var active_beams: Array[Dictionary] = []       # {shooter_pos, target_pos, is_hpm_cone, faction, ttl}
var recent_impacts: Array[Dictionary] = []     # {pos_km, radius_km, cost_musd, is_intercept, ttl}
var sim_events_queue: Array[Dictionary] = []   # Drained on main thread to emit SignalBus signals safely
var active_countermeasures: Array[Dictionary] = [] # Sprint 6: {unit_id, pos_km, vel_km_s, ttl_sec, max_ttl_sec, faction}
var active_radar_tracks: Array[Dictionary] = []    # Sprint 6: {radar_uid, target_uid, radar_pos, target_pos, cone_deg, ttl_sec, faction}
var active_nuke_effects: Array[Dictionary] = []    # Sprint 6: Multi-stage physical nuclear explosion simulation

# --- Theater Heightmap RAM Grid (512x512 floats in meters) & Active Strategic Sites ---
var active_theater_slug: String = "strait_theater"
var active_heightmap_path: String = "res://data/theaters/strait_theater_heightmap.png"
var active_sites: Array[Dictionary] = []       # Copy of theater sites with runtime `crater_timer_sec` & `hp`
var heightmap_size: int = 512
var heightmap_elev_m: PackedFloat32Array = PackedFloat32Array()
var theater_size_km: float = 2000.0

# --- Phase 15: 1,000,000-Unit Global Multi-Theater Order of Battle (7 Theaters of War) ---
var global_theaters: Dictionary = {}
var global_blue_units_active: int = 485000
var global_red_units_active: int = 515000
var global_total_units_active: int = 1000000

# --- Economic War Ledger, Live Casualties, Ammunition & Telemetry (Both Sides: Blue & Red) ---
var tick_id: int = 0
var sim_time_sec: float = 0.0
var time_scale: float = 1.0
var blue_lost_musd: float = 0.0
var red_lost_musd: float = 0.0
var blue_units_destroyed: int = 0
var red_units_destroyed: int = 0
var blue_munitions_intercepted: int = 0
var red_munitions_intercepted: int = 0
var blue_munitions_expended: int = 0
var red_munitions_expended: int = 0
var blue_ammo_initial_total: int = 0
var red_ammo_initial_total: int = 0
var blue_ammo_remaining: int = 0
var red_ammo_remaining: int = 0
var blue_munitions_in_flight: int = 0
var red_munitions_in_flight: int = 0
var blue_personnel_kia: int = 0
var blue_personnel_wia: int = 0
var red_personnel_kia: int = 0
var red_personnel_wia: int = 0
var blue_aircraft_lost: int = 0
var red_aircraft_lost: int = 0
var blue_armor_lost: int = 0
var red_armor_lost: int = 0
var blue_ships_lost: int = 0
var red_ships_lost: int = 0
var blue_unmanned_lost: int = 0
var red_unmanned_lost: int = 0
var global_blue_kia: int = 0
var global_blue_wia: int = 0
var global_red_kia: int = 0
var global_red_wia: int = 0
var global_blue_ammo_expended: int = 0
var global_red_ammo_expended: int = 0
var refuel_events_count: int = 0
var resupply_events_count: int = 0
var craters_inflicted_count: int = 0
var collateral_incidents_count: int = 0

# --- Phase 17: Defense Budget, 5-Branch R&D Technology Tree, DEFCON 5->1 Escalation, Presidential Declarations, World News & NBC/Nuclear Warfare ---
var blue_budget_available_musd: float = 4500.0
var red_budget_available_musd: float = 4500.0
var blue_budget_musd: float:
	get:
		return blue_budget_available_musd
	set(val):
		blue_budget_available_musd = val
var red_budget_musd: float:
	get:
		return red_budget_available_musd
	set(val):
		red_budget_available_musd = val
var blue_budget_spent_musd: float:
	get:
		return blue_spent_rd_musd + blue_spent_procurement_musd
var blue_income_musd_per_min: float = 45.0
var red_income_musd_per_min: float = 45.0
var blue_spent_rd_musd: float = 0.0
var blue_spent_procurement_musd: float = 0.0
var red_spent_rd_musd: float = 0.0
var red_spent_procurement_musd: float = 0.0

var blue_unlocked_techs: Dictionary = {}
var red_unlocked_techs: Dictionary = {}

# Active R&D Combat Modifiers (applied in SensorLoS, SalvoCombat, Kinematics & Logistics)
var blue_rcs_mult: float = 1.0
var red_rcs_mult: float = 1.0
var blue_radar_range_mult: float = 1.0
var red_radar_range_mult: float = 1.0
var blue_missile_speed_mult: float = 1.0
var red_missile_speed_mult: float = 1.0
var blue_pk_bonus: float = 0.0
var red_pk_bonus: float = 0.0
var blue_sam_intercept_bonus: float = 0.0
var red_sam_intercept_bonus: float = 0.0
var blue_laser_recharge_mult: float = 1.0
var red_laser_recharge_mult: float = 1.0
var blue_dog_speed_mult: float = 1.0
var red_dog_speed_mult: float = 1.0
var blue_warhead_damage_mult: float = 1.0
var red_warhead_damage_mult: float = 1.0
var blue_auto_ammo_per_min: int = 0
var red_auto_ammo_per_min: int = 0
var blue_cbrn_immunity: int = 0
var red_cbrn_immunity: int = 0
var blue_ew_jam_immunity: int = 0
var red_ew_jam_immunity: int = 0

# DEFCON 5 -> 1 Escalation Loop, Presidential Declarations, World News & NBC/EMP/Orbital/Nuclear State
var defcon_level: int = 5
var global_escalation_score: float = 8.0
var nuclear_detonations_count: int = 0
var cbrn_strikes_count: int = 0
var hemp_emp_strikes_count: int = 0
var orbital_rod_strikes_count: int = 0
var active_nuclear_fireballs: Array[Dictionary] = []
var latest_world_news_headline: String = "BREAKING [REUTERS / GNN]: UN Security Council convenes emergency session as 1,000,000 troops mass across 7 global flashpoints."
var latest_presidential_declaration: String = "WHITE HOUSE SITUATION ROOM [DEFCON 5]: 'Maintain strict EMCON discipline, shadow OPFOR formations, and fund priority R&D defense programs.'"
var world_news_feed: Array[Dictionary] = []

# --- Phase 18: Physical Command Bunker Base (Relocation, Damage, Capture, Destruction / Game Over) & Officer Voice Comms ---
var bunker_base_name: String = "Hengshan Underground Command Center (Taipei)"
var bunker_pos_km: Vector3 = Vector3(136.0, 0.0, -45.0)
var bunker_hp: float = 1000.0
var bunker_max_hp: float = 1000.0
var bunker_capture_progress: float = 0.0        # 0.0 .. 100.0% (100% = Captured by OPFOR -> Game Over)
var bunker_nearest_enemy_dist_km: float = 999.0
var bunker_relocations_count: int = 0
var bunker_alternate_index: int = 0
var bunker_is_lost: bool = false
var bunker_was_captured: bool = false
var bunker_loss_reason: String = ""
var bunker_status_code: String = "SECURE"       # SECURE, PERIMETER_ALERT, UNDER_ATTACK, BREACH_IN_PROGRESS, RELOCATING, LOST
var bunker_shock_tremor: float = 0.0            # 0.0 .. 1.0 seismic camera & bunker shake from nearby detonations
var latest_officer_callsign: String = "CAPT. ELENA ROSTOVA (AWACS MAGIC 1-1 // FEMALE)"
var latest_officer_gender: String = "FEMALE"
var latest_officer_transcript: String = "Command Bunker C4ISR links online. All 7 global flashpoint sensors nominal."

# --- Phase 19: AI Geopolitical Diplomacy, Sovereign Airspace Access & Coalition Finance Engine ---
var active_nations: Array[Dictionary] = []
var blue_allied_nations_count: int = 0
var red_allied_nations_count: int = 0
var blue_airspace_treaties_count: int = 0
var red_airspace_treaties_count: int = 0
var blue_allied_aid_received_musd: float = 0.0
var red_allied_aid_received_musd: float = 0.0
var blue_allied_income_musd_per_min: float = 0.0
var red_allied_income_musd_per_min: float = 0.0
var diplomatic_events_count: int = 0
var ai_generated_countries_count: int = 0
var airspace_violations_count: int = 0
var latest_diplomatic_cable: String = "STATE DEPT / J5 COALITION DESK: 18 Sovereign Nations & Regional Airspace Corridors monitored."

# --- Phase 20: Live AI War News & Google Veo 3.1 Video Broadcast Engine ---
var active_news_video_slug: String = "missile_alpha_strike"
var active_news_video_network: String = "GNN GLOBAL WAR DESK"
var active_news_video_headline: String = "BREAKING: MASSIVE CRUISE & HYPERSONIC MISSILE SALVO LAUNCHED ACROSS THEATER"
var active_news_video_sub_chyron: String = "Long-range precision strike packages and hypersonic boost-glide vehicles detected inbound toward strategic command nodes."
var active_news_video_correspondent: String = "Marcus Vance — GNN Senior Defense Correspondent"
var active_news_video_anchor_script: String = "Live breaking footage from the theater as precision missile salvos and air defense interceptors light up the night sky."
var news_video_broadcasts_count: int = 0
var live_ai_gemini_bulletins_count: int = 0
var news_video_history: Array[Dictionary] = []

# --- Phase 24: Dynamic Weather, Day/Night Solar Terminator & Sea-State Physics ---
var weather_condition_code: String = "CLEAR"     # CLEAR, OVERCAST, TYPHOON_STORM, SANDSTORM, ARCTIC_BLIZZARD
var weather_cloud_cover: float = 0.15            # 0.0 .. 1.0
var weather_precip_intensity: float = 0.0        # 0.0 .. 1.0
var sea_state_beaufort: int = 2                  # 1 .. 9 Beaufort scale
var solar_hour_utc: float = 14.0                 # 0.0 .. 24.0 UTC solar cycle
var is_night_cycle: bool = false
var weather_ir_eo_mult: float = 1.0              # Attenuates IR_EO sensor range in clouds/typhoon/sandstorm
var weather_laser_mult: float = 1.0              # Attenuates 100kW Iron Beam laser recharge & range in rain/sand/clouds
var weather_usv_speed_mult: float = 1.0          # Slows littoral USV drone boats in high Beaufort sea state
var weather_air_sortie_mult: float = 1.0         # Slight non-all-weather drone/aircraft speed penalty in severe storms
var weather_changes_count: int = 0

# --- Phase 25: Red Phone Hotline Ultimatums & Leader Crisis Negotiations ---
var hotline_is_ringing: bool = false
var hotline_leader_name: String = "PREMIER CHEN WEI-GUO"
var hotline_leader_title: String = "CENTRAL MILITARY COMMISSION // BEIJING RED LINE"
var hotline_demand_headline: String = "RED PHONE HOTLINE STANDBY"
var hotline_demand_body: String = "Direct encrypted Moscow-Beijing-Washington-Brussels nuclear & diplomatic crisis line."
var hotline_ceasefire_timer_sec: float = 0.0
var hotline_calls_received_count: int = 0
var hotline_negotiations_resolved_count: int = 0
var hotline_history: Array[Dictionary] = []

# --- Phase 23: Campaign Save / Load & Custom Scenario Editor Metadata ---
var saves_performed_count: int = 0
var loads_performed_count: int = 0
var custom_scenarios_exported_count: int = 0
var last_saved_slot_path: String = ""

# --- Phase 26: Civilian Highway Traffic, Refugee Evacuation Convoys & Maritime Shipping Lanes ---
const MAX_TRAFFIC_CONVOYS := 48
const CONVOY_CIVILIAN_COMMUTER := 0
const CONVOY_REFUGEE_EVAC := 1
const CONVOY_MILITARY_SUPPLY := 2
const CONVOY_MARITIME_TANKER := 3

var convoy_count: int = 0
var convoy_active: PackedByteArray = PackedByteArray()
var convoy_type: PackedByteArray = PackedByteArray()
var convoy_faction: PackedByteArray = PackedByteArray()
var convoy_pos_km: PackedVector3Array = PackedVector3Array()
var convoy_start_km: PackedVector3Array = PackedVector3Array()
var convoy_end_km: PackedVector3Array = PackedVector3Array()
var convoy_heading_rad: PackedFloat32Array = PackedFloat32Array()
var convoy_progress: PackedFloat32Array = PackedFloat32Array()
var convoy_dir_sign: PackedFloat32Array = PackedFloat32Array()
var convoy_speed_km_s: PackedFloat32Array = PackedFloat32Array()
var humanitarian_corridor_active: bool = false
var humanitarian_corridor_timer_sec: float = 0.0
var humanitarian_corridors_declared_count: int = 0
var evacuated_convoys_completed_count: int = 0
var maritime_tankers_interdicted_count: int = 0
var collateral_convoy_hits_count: int = 0

# --- Phase 27: Subterranean Underground Tunnel Networks, Deep Hardened Bunkers & Tunnel Breach Assault ---
const MAX_TUNNEL_COMPLEXES := 8
var tunnel_complexes: Array[Dictionary] = []         # {id, name, faction_owner, portal_a_km, portal_b_km, integrity_pct, discovered_by_blue, units_sheltered, collapsed}
var gpr_seismic_scans_count: int = 0
var bunker_buster_strikes_count: int = 0
var tunnel_breach_assaults_count: int = 0
var tunnels_collapsed_count: int = 0
var tunnels_captured_count: int = 0

# --- Phase 28: Strategic CEMA (Cyber-Electro-Magnetic Activities), Power Grid Blackouts & Drone Swarm Hijacking ---
var blue_power_grid_pct: float = 100.0
var red_power_grid_pct: float = 100.0
var blue_cyber_firewall_pct: float = 100.0
var red_cyber_firewall_pct: float = 100.0
var cema_grid_blackout_timer_sec: float = 0.0
var cema_operations_executed_count: int = 0
var units_hijacked_count: int = 0
var ghost_decoys_spawned_count: int = 0
var ghost_decoy_positions_km: PackedVector3Array = PackedVector3Array()
var latest_cema_status: String = "USCYBERCOM / J6 CEMA MATRIX: Blue Grid 100% | Red Grid 100% | Quantum Encryption Nominal."

# --- Phase 31: Combat Engineering, Tactical Minefields, Bridge Rebuild & Airborne Paratrooper Drops ---
var parachute_drops: Array[Dictionary] = []          # {unit_id, pos_km, alt_m, faction}
var minefields: Array[Dictionary] = []               # {pos_km, radius_km, faction, domain, active}
var airborne_drops_executed_count: int = 0
var minefields_deployed_count: int = 0
var engineer_breaches_rebuilds_count: int = 0

# --- Phase 32: Submarine Undersea Cable Sabotage, SOSUS Hydrophone Arrays & ASW ---
var undersea_cables: Array[Dictionary] = []          # {id, name, faction_owner, start_km, end_km, severed}
var sosus_barriers_active_count: int = 0
var cables_sabotaged_count: int = 0
var cables_repaired_count: int = 0

# --- Phase 33: Domestic Homefront Stability, Brent Crude Oil ($/bbl), Defense Index & UN/ICC War Crimes ROE ---
var blue_public_support_pct: float = 78.0
var global_oil_price_bbl: float = 84.0
var defense_industrial_index: float = 1000.0
var un_war_crimes_investigation_level: int = 0
var surgical_roe_enforced: bool = false
var war_bonds_issued_count: int = 0
var spr_releases_count: int = 0
var latest_homefront_status: String = "HOMEFRONT & MARKETS: Public Support 78% | Brent Crude $84/bbl | Defense Index 1000 | ROE: STANDARD"

# --- Phase 35: 688(I) / Virginia-Class Nuclear Attack Submarine VR & Desktop Sim Station ---
var sub_sim_active: bool = false
var sub_unit_id: int = -1
var sub_hull_name: String = "USS CHEYENNE (SSN-773 // 688I HUNTER-KILLER)"
var sub_depth_ft: float = 58.0
var sub_target_depth_ft: float = 58.0
var sub_thermocline_depth_ft: float = 280.0
var sub_dive_plane_deg: float = 0.0
var sub_ballast_blow_active: bool = false
var sub_throttle_notch: int = 1                  # 0=STOP, 1=AHEAD 1/3 (5kt), 2=STD (15kt), 3=FULL (24kt), 4=FLANK (33kt)
var sub_speed_kts: float = 5.0
var sub_heading_deg: float = 270.0
var sub_target_heading_deg: float = 270.0
var sub_cavitating: bool = false
var sub_own_noise_db: float = 88.0
var sub_silent_running: bool = false
var sub_periscope_raised: bool = true
var sub_periscope_bearing_deg: float = 0.0
var sub_periscope_zoom_x: float = 1.0
var sub_periscope_flir_mode: int = 0             # 0=DAY EO, 1=NVG GREEN, 2=WHITE-HOT FLIR
var sub_locked_target_uid: int = -1
var sub_locked_target_name: String = "NO TARGET LOCKED"
var sub_locked_target_range_km: float = 0.0
var sub_locked_target_bearing_deg: float = 0.0
var sub_sonar_contacts: Array[Dictionary] = []   # {uid, name, bearing_deg, range_km, speed_kts, noise_db, is_sub, pos_km}
var sub_torpedo_tubes: Array[String] = ["READY", "READY", "READY", "READY"]
var sub_torpedoes_remaining: int = 16
var sub_vls_tomahawks_remaining: int = 12
var sub_decoys_remaining: int = 8
var sub_torpedoes_fired_count: int = 0
var sub_vls_salvos_fired_count: int = 0
var sub_decoys_launched_count: int = 0
var sub_ships_sunk_count: int = 0
var sub_water_plumes: Array[Dictionary] = []     # {pos_km, height_m, ttl_sec}
var sub_status_log: String = "CONN, SONAR: Rigged for Periscope Depth (58 ft). Towed array streaming nominal."


func _init() -> void:
	reset()


func reset() -> void:
	unit_count = 0
	unit_active.resize(MAX_UNITS)
	unit_active.fill(0)
	unit_tactical_posture.resize(MAX_UNITS)
	unit_tactical_posture.fill(TACTICAL_POSTURE_AUTO)
	unit_pos.resize(MAX_UNITS)
	unit_vel.resize(MAX_UNITS)
	unit_target_pos.resize(MAX_UNITS)
	unit_has_waypoint.resize(MAX_UNITS)
	unit_has_waypoint.fill(0)
	unit_faction.resize(MAX_UNITS)
	unit_platform_id.resize(MAX_UNITS)
	unit_echelon.resize(MAX_UNITS)
	unit_parent_id.resize(MAX_UNITS)
	unit_parent_id.fill(-1)
	unit_radar_active.resize(MAX_UNITS)
	unit_radar_active.fill(1)
	unit_roe.resize(MAX_UNITS)
	unit_roe.fill(2)
	unit_hp.resize(MAX_UNITS)
	unit_max_hp.resize(MAX_UNITS)
	unit_ammo_1.resize(MAX_UNITS)
	unit_ammo_2.resize(MAX_UNITS)
	unit_energy_cap.resize(MAX_UNITS)
	unit_unmanned_bays.resize(MAX_UNITS)
	unit_detected_mask.resize(MAX_UNITS)
	unit_detected_mask.fill(0)
	unit_jammed.resize(MAX_UNITS)
	unit_jammed.fill(0)
	unit_cooldown.resize(MAX_UNITS)
	unit_cooldown.fill(0.0)
	unit_fuel_km.resize(MAX_UNITS)
	unit_fuel_km.fill(1000.0)
	unit_max_fuel_km.resize(MAX_UNITS)
	unit_max_fuel_km.fill(1000.0)
	unit_afterburner.resize(MAX_UNITS)
	unit_afterburner.fill(0)
	unit_desired_alt_m.resize(MAX_UNITS)
	unit_desired_alt_m.fill(0.0)
	unit_ai_state.resize(MAX_UNITS)
	unit_ai_state.fill(AI_PATROL_CAP)
	unit_threat_level.resize(MAX_UNITS)
	unit_threat_level.fill(0.0)
	unit_player_override_timer.resize(MAX_UNITS)
	unit_player_override_timer.fill(0.0)
	unit_heading_rad.resize(MAX_UNITS)
	unit_heading_rad.fill(0.0)
	unit_pitch_rad.resize(MAX_UNITS)
	unit_pitch_rad.fill(0.0)
	unit_roll_rad.resize(MAX_UNITS)
	unit_roll_rad.fill(0.0)
	unit_turret_hdg_rad.resize(MAX_UNITS)
	unit_turret_hdg_rad.fill(0.0)
	unit_suppression_level.resize(MAX_UNITS)
	unit_suppression_level.fill(0.0)
	unit_sim_lod.resize(MAX_UNITS)
	unit_sim_lod.fill(LOD_TIER_0_MICRO)
	unit_morale.resize(MAX_UNITS)
	unit_morale.fill(1.0)
	unit_cyber_timer.resize(MAX_UNITS)
	unit_cyber_timer.fill(0.0)
	unit_cbrn_mopp.resize(MAX_UNITS)
	unit_cbrn_mopp.fill(0)
	unit_delegated_ai.resize(MAX_UNITS)
	unit_delegated_ai.fill(1)
	blue_c2_integrity = 1.0
	red_c2_integrity = 1.0
	unit_waypoint_queues.clear()

	var civ_cells := CIV_GRID_SIZE * CIV_GRID_SIZE
	civ_density_m2.resize(civ_cells)
	civ_density_m2.fill(0.0)
	civ_initial_m2.resize(civ_cells)
	civ_initial_m2.fill(0.0)
	civ_passability.resize(civ_cells)
	civ_passability.fill(1.0)
	civ_threat_field.resize(civ_cells)
	civ_threat_field.fill(0.0)
	civ_flux_activity.resize(civ_cells)
	civ_flux_activity.fill(0.0)
	hazard_density.resize(civ_cells)
	hazard_density.fill(0.0)
	active_hazard_cells_count = 0
	total_theater_civilians = 0.0
	total_displaced_civilians = 0.0
	estimated_civilian_casualties = 0.0
	lod_tier0_count = 0
	lod_tier1_count = 0
	lod_tier2_count = 0

	sat_count = 0
	sat_active.resize(MAX_SATELLITES)
	sat_active.fill(0)
	sat_faction.resize(MAX_SATELLITES)
	sat_role.resize(MAX_SATELLITES)
	sat_inclination_rad.resize(MAX_SATELLITES)
	sat_raan_rad.resize(MAX_SATELLITES)
	sat_phase_rad.resize(MAX_SATELLITES)
	sat_angular_vel.resize(MAX_SATELLITES)
	sat_alt_km.resize(MAX_SATELLITES)
	sat_speed_km_s.resize(MAX_SATELLITES)
	sat_speed_km_s.fill(7.59)
	sat_pos_km.resize(MAX_SATELLITES)
	sat_dazzled_timer.resize(MAX_SATELLITES)
	sat_dazzled_timer.fill(0.0)
	blue_satcom_factor = 1.0
	red_satcom_factor = 1.0
	blue_pnt_factor = 1.0
	red_pnt_factor = 1.0
	asat_intercepts_count = 0
	cyber_strikes_count = 0
	psyop_broadcasts_count = 0

	infra_biome.resize(civ_cells)
	infra_biome.fill(BIOME_OCEAN)
	infra_forest_density.resize(civ_cells)
	infra_forest_density.fill(0.0)
	infra_river_mask.resize(civ_cells)
	infra_river_mask.fill(0.0)
	infra_road_mask.resize(civ_cells)
	infra_road_mask.fill(0.0)
	infra_rail_mask.resize(civ_cells)
	infra_rail_mask.fill(0.0)
	infra_bridge_mask.resize(civ_cells)
	infra_bridge_mask.fill(0.0)
	infra_urban_density.resize(civ_cells)
	infra_urban_density.fill(0.0)
	destruction_level.resize(civ_cells)
	destruction_level.fill(0.0)

	bldg_count = 0
	bldg_pos_km.clear()
	bldg_scale_m.clear()
	bldg_yaw_rad.clear()
	bldg_type.clear()
	bldg_cell_idx.clear()

	train_count = 0
	train_active.resize(MAX_TRAINS)
	train_active.fill(0)
	train_faction.resize(MAX_TRAINS)
	train_pos_km.resize(MAX_TRAINS)
	train_start_km.resize(MAX_TRAINS)
	train_end_km.resize(MAX_TRAINS)
	train_heading_rad.resize(MAX_TRAINS)
	train_progress.resize(MAX_TRAINS)
	train_dir_sign.resize(MAX_TRAINS)
	train_derailed.resize(MAX_TRAINS)
	train_derailed.fill(0)

	active_destroyed_cells_count = 0
	bridges_destroyed_count = 0
	trains_derailed_count = 0
	airfields_captured_count = 0

	mun_count = 0
	mun_active.resize(MAX_MUNITIONS)
	mun_active.fill(0)
	mun_pos.resize(MAX_MUNITIONS)
	mun_start_pos.resize(MAX_MUNITIONS)
	mun_target_pos.resize(MAX_MUNITIONS)
	mun_vel.resize(MAX_MUNITIONS)
	mun_faction.resize(MAX_MUNITIONS)
	mun_weapon_id.resize(MAX_MUNITIONS)
	mun_shooter_id.resize(MAX_MUNITIONS)
	mun_target_unit_id.resize(MAX_MUNITIONS)
	mun_flight_progress.resize(MAX_MUNITIONS)
	mun_total_dist_km.resize(MAX_MUNITIONS)
	mun_apex_alt_m.resize(MAX_MUNITIONS)
	mun_jammed.resize(MAX_MUNITIONS)
	mun_jammed.fill(0)

	queued_strikes.clear()
	active_beams.clear()
	recent_impacts.clear()
	sim_events_queue.clear()
	active_sites.clear()
	active_countermeasures.clear()
	active_radar_tracks.clear()
	active_nuke_effects.clear()
	active_sonar_pings.clear()
	tactical_match_active = false
	match_outcome = "IN_PROGRESS"
	match_objectives.clear()

	tick_id = 0
	sim_time_sec = 0.0
	blue_lost_musd = 0.0
	red_lost_musd = 0.0
	blue_units_destroyed = 0
	red_units_destroyed = 0
	blue_munitions_intercepted = 0
	red_munitions_intercepted = 0
	blue_munitions_expended = 0
	red_munitions_expended = 0
	blue_ammo_initial_total = 0
	red_ammo_initial_total = 0
	blue_ammo_remaining = 0
	red_ammo_remaining = 0
	blue_munitions_in_flight = 0
	red_munitions_in_flight = 0
	blue_personnel_kia = 0
	blue_personnel_wia = 0
	red_personnel_kia = 0
	red_personnel_wia = 0
	blue_aircraft_lost = 0
	red_aircraft_lost = 0
	blue_armor_lost = 0
	red_armor_lost = 0
	blue_ships_lost = 0
	red_ships_lost = 0
	blue_unmanned_lost = 0
	red_unmanned_lost = 0
	global_blue_kia = 0
	global_blue_wia = 0
	global_red_kia = 0
	global_red_wia = 0
	global_blue_ammo_expended = 0
	global_red_ammo_expended = 0
	refuel_events_count = 0
	resupply_events_count = 0
	craters_inflicted_count = 0
	collateral_incidents_count = 0

	blue_budget_available_musd = 4500.0
	red_budget_available_musd = 4500.0
	blue_income_musd_per_min = 45.0
	red_income_musd_per_min = 45.0
	blue_spent_rd_musd = 0.0
	blue_spent_procurement_musd = 0.0
	red_spent_rd_musd = 0.0
	red_spent_procurement_musd = 0.0
	blue_unlocked_techs.clear()
	red_unlocked_techs.clear()
	blue_rcs_mult = 1.0
	red_rcs_mult = 1.0
	blue_radar_range_mult = 1.0
	red_radar_range_mult = 1.0
	blue_missile_speed_mult = 1.0
	red_missile_speed_mult = 1.0
	blue_pk_bonus = 0.0
	red_pk_bonus = 0.0
	blue_sam_intercept_bonus = 0.0
	red_sam_intercept_bonus = 0.0
	blue_laser_recharge_mult = 1.0
	red_laser_recharge_mult = 1.0
	blue_dog_speed_mult = 1.0
	red_dog_speed_mult = 1.0
	blue_warhead_damage_mult = 1.0
	red_warhead_damage_mult = 1.0
	blue_auto_ammo_per_min = 0
	red_auto_ammo_per_min = 0
	blue_cbrn_immunity = 0
	red_cbrn_immunity = 0
	blue_ew_jam_immunity = 0
	red_ew_jam_immunity = 0

	bunker_base_name = "Hengshan Underground Command Center (Taipei)"
	bunker_pos_km = Vector3(136.0, 0.0, -45.0)
	bunker_hp = 1000.0
	bunker_max_hp = 1000.0
	bunker_capture_progress = 0.0
	bunker_nearest_enemy_dist_km = 999.0
	bunker_relocations_count = 0
	bunker_alternate_index = 0
	bunker_is_lost = false
	bunker_was_captured = false
	bunker_loss_reason = ""
	bunker_status_code = "SECURE"
	bunker_shock_tremor = 0.0
	latest_officer_callsign = "CAPT. ELENA ROSTOVA (AWACS MAGIC 1-1 // FEMALE)"
	latest_officer_gender = "FEMALE"
	latest_officer_transcript = "Command Bunker C4ISR links online. All 7 global flashpoint sensors nominal."

	active_nations.clear()
	blue_allied_nations_count = 0
	red_allied_nations_count = 0
	blue_airspace_treaties_count = 0
	red_airspace_treaties_count = 0
	blue_allied_aid_received_musd = 0.0
	red_allied_aid_received_musd = 0.0
	blue_allied_income_musd_per_min = 0.0
	red_allied_income_musd_per_min = 0.0
	diplomatic_events_count = 0
	ai_generated_countries_count = 0
	airspace_violations_count = 0
	latest_diplomatic_cable = "STATE DEPT / J5 COALITION DESK: 18 Sovereign Nations & Regional Airspace Corridors monitored."

	active_news_video_slug = "missile_alpha_strike"
	active_news_video_network = "GNN GLOBAL WAR DESK"
	active_news_video_headline = "BREAKING: MASSIVE CRUISE & HYPERSONIC MISSILE SALVO LAUNCHED ACROSS THEATER"
	active_news_video_sub_chyron = "Long-range precision strike packages and hypersonic boost-glide vehicles detected inbound toward strategic command nodes."
	active_news_video_correspondent = "Marcus Vance — GNN Senior Defense Correspondent"
	active_news_video_anchor_script = "Live breaking footage from the theater as precision missile salvos and air defense interceptors light up the night sky."
	news_video_broadcasts_count = 0
	live_ai_gemini_bulletins_count = 0
	news_video_history.clear()

	weather_condition_code = "CLEAR"
	weather_cloud_cover = 0.15
	weather_precip_intensity = 0.0
	sea_state_beaufort = 2
	solar_hour_utc = 14.0
	is_night_cycle = false
	weather_ir_eo_mult = 1.0
	weather_laser_mult = 1.0
	weather_usv_speed_mult = 1.0
	weather_air_sortie_mult = 1.0
	weather_changes_count = 0

	hotline_is_ringing = false
	hotline_leader_name = "PREMIER CHEN WEI-GUO"
	hotline_leader_title = "CENTRAL MILITARY COMMISSION // BEIJING RED LINE"
	hotline_demand_headline = "RED PHONE HOTLINE STANDBY"
	hotline_demand_body = "Direct encrypted Moscow-Beijing-Washington-Brussels nuclear & diplomatic crisis line."
	hotline_ceasefire_timer_sec = 0.0
	hotline_calls_received_count = 0
	hotline_negotiations_resolved_count = 0
	hotline_history.clear()

	convoy_count = 0
	convoy_active.resize(MAX_TRAFFIC_CONVOYS)
	convoy_active.fill(0)
	convoy_type.resize(MAX_TRAFFIC_CONVOYS)
	convoy_type.fill(0)
	convoy_faction.resize(MAX_TRAFFIC_CONVOYS)
	convoy_faction.fill(0)
	convoy_pos_km.resize(MAX_TRAFFIC_CONVOYS)
	convoy_start_km.resize(MAX_TRAFFIC_CONVOYS)
	convoy_end_km.resize(MAX_TRAFFIC_CONVOYS)
	convoy_heading_rad.resize(MAX_TRAFFIC_CONVOYS)
	convoy_progress.resize(MAX_TRAFFIC_CONVOYS)
	convoy_dir_sign.resize(MAX_TRAFFIC_CONVOYS)
	convoy_speed_km_s.resize(MAX_TRAFFIC_CONVOYS)
	humanitarian_corridor_active = false
	humanitarian_corridor_timer_sec = 0.0
	humanitarian_corridors_declared_count = 0
	evacuated_convoys_completed_count = 0
	maritime_tankers_interdicted_count = 0
	collateral_convoy_hits_count = 0

	tunnel_complexes.clear()
	gpr_seismic_scans_count = 0
	bunker_buster_strikes_count = 0
	tunnel_breach_assaults_count = 0
	tunnels_collapsed_count = 0
	tunnels_captured_count = 0

	blue_power_grid_pct = 100.0
	red_power_grid_pct = 100.0
	blue_cyber_firewall_pct = 100.0
	red_cyber_firewall_pct = 100.0
	cema_grid_blackout_timer_sec = 0.0
	cema_operations_executed_count = 0
	units_hijacked_count = 0
	ghost_decoys_spawned_count = 0
	ghost_decoy_positions_km.clear()
	latest_cema_status = "USCYBERCOM / J6 CEMA MATRIX: Blue Grid 100% | Red Grid 100% | Quantum Encryption Nominal."

	parachute_drops.clear()
	minefields.clear()
	airborne_drops_executed_count = 0
	minefields_deployed_count = 0
	engineer_breaches_rebuilds_count = 0

	undersea_cables.clear()
	sosus_barriers_active_count = 0
	cables_sabotaged_count = 0
	cables_repaired_count = 0

	blue_public_support_pct = 78.0
	global_oil_price_bbl = 84.0
	defense_industrial_index = 1000.0
	un_war_crimes_investigation_level = 0
	surgical_roe_enforced = false
	war_bonds_issued_count = 0
	spr_releases_count = 0
	latest_homefront_status = "HOMEFRONT & MARKETS: Public Support 78% | Brent Crude $84/bbl | Defense Index 1000 | ROE: STANDARD"

	sub_sim_active = false
	sub_unit_id = -1
	sub_hull_name = "USS CHEYENNE (SSN-773 // 688I HUNTER-KILLER)"
	sub_depth_ft = 58.0
	sub_target_depth_ft = 58.0
	sub_thermocline_depth_ft = 280.0
	sub_dive_plane_deg = 0.0
	sub_ballast_blow_active = false
	sub_throttle_notch = 1
	sub_speed_kts = 5.0
	sub_heading_deg = 270.0
	sub_target_heading_deg = 270.0
	sub_cavitating = false
	sub_own_noise_db = 88.0
	sub_silent_running = false
	sub_periscope_raised = true
	sub_periscope_bearing_deg = 0.0
	sub_periscope_zoom_x = 1.0
	sub_periscope_flir_mode = 0
	sub_locked_target_uid = -1
	sub_locked_target_name = "NO TARGET LOCKED"
	sub_locked_target_range_km = 0.0
	sub_locked_target_bearing_deg = 0.0
	sub_sonar_contacts.clear()
	sub_torpedo_tubes = ["READY", "READY", "READY", "READY"]
	sub_torpedoes_remaining = 16
	sub_vls_tomahawks_remaining = 12
	sub_decoys_remaining = 8
	sub_torpedoes_fired_count = 0
	sub_vls_salvos_fired_count = 0
	sub_decoys_launched_count = 0
	sub_ships_sunk_count = 0
	sub_water_plumes.clear()
	sub_status_log = "CONN, SONAR: Rigged for Periscope Depth (58 ft). Towed array streaming nominal."

	defcon_level = 5
	global_escalation_score = 8.0
	nuclear_detonations_count = 0
	cbrn_strikes_count = 0
	hemp_emp_strikes_count = 0
	orbital_rod_strikes_count = 0
	active_nuclear_fireballs.clear()
	latest_world_news_headline = "BREAKING [REUTERS / GNN]: UN Security Council convenes emergency session as 1,000,000 troops mass across 7 global flashpoints."
	latest_presidential_declaration = "WHITE HOUSE SITUATION ROOM [DEFCON 5]: 'Maintain strict EMCON discipline, shadow OPFOR formations, and fund priority R&D defense programs.'"
	world_news_feed.clear()
	refuel_events_count = 0
	resupply_events_count = 0
	craters_inflicted_count = 0
	collateral_incidents_count = 0

	active_countermeasures.clear()
	active_radar_tracks.clear()
	active_nuke_effects.clear()

	if heightmap_elev_m.is_empty():
		load_heightmap(active_heightmap_path)


## Spawns dynamic thermal countermeasure flares popping behind an aircraft.
func spawn_countermeasure_flares(unit_id: int, pos: Vector3, heading_rad: float, faction: int, count: int = 4) -> void:
	for i in range(count):
		var ang := heading_rad + PI + randf_range(-0.55, 0.55)
		var spd := randf_range(0.06, 0.16)
		var vel := Vector3(cos(ang) * spd, randf_range(-0.04, -0.01), sin(ang) * spd)
		active_countermeasures.append({
			"unit_id": unit_id,
			"pos_km": pos + Vector3(randf_range(-0.15, 0.15), randf_range(-0.03, 0.03), randf_range(-0.15, 0.15)),
			"vel_km_s": vel,
			"ttl_sec": randf_range(2.6, 4.2),
			"max_ttl_sec": 4.2,
			"faction": faction,
		})


## Triggers a realistic multi-stage thermonuclear detonation at ground zero.
func trigger_thermonuclear_detonation(pos_km: Vector3, faction: int = 1, yield_kt: float = 350.0) -> Dictionary:
	nuclear_detonations_count += 1
	defcon_level = 1
	global_escalation_score = 100.0
	bunker_shock_tremor = 1.0 # Immediate maximum seismic bunker shake

	var nuke_entry := {
		"pos_km": pos_km,
		"radius_km": 18.0,
		"max_radius_km": 92.0,
		"timer_sec": 30.0,
		"max_ttl_sec": 30.0,
		"type": "NUKE",
		"faction": faction,
		"yield_kt": yield_kt,
		"flash_duration": 1.2,
		"fireball_max_r_km": 14.0,
		"shockwave_max_r_km": 68.0,
		"mushroom_stem_h_km": 28.0,
		"emp_wave_max_r_km": 140.0,
	}
	active_nuclear_fireballs.append(nuke_entry)
	active_nuke_effects.append(nuke_entry)

	sim_events_queue.append({
		"type": "WMD_DETONATED",
		"wmd_type": "THERMONUCLEAR",
		"faction": faction,
		"pos_km": pos_km,
		"yield_kt": yield_kt
	})
	return nuke_entry


## Spawns an underwater acoustic active sonar pulse expanding from a submarine or ASW platform
func spawn_sonar_ping(unit_id: int, pos_km: Vector3, faction: int, max_radius_km: float = 28.0) -> void:
	active_sonar_pings.append({
		"unit_id": unit_id,
		"pos_km": pos_km,
		"radius_km": 1.0,
		"current_radius_km": 1.0,
		"max_radius_km": max_radius_km,
		"timer_sec": 4.5,
		"ttl_sec": 4.5,
		"duration_sec": 4.5,
		"max_ttl_sec": 4.5,
		"faction": faction
	})


## Initializes a playable tactical match with objectives and outcome tracking
func init_tactical_match(scenario_name: String, primary_enemy_uids: Array = []) -> void:
	tactical_match_active = true
	match_outcome = "IN_PROGRESS"
	match_stats = {
		"blue_lost": 0,
		"red_lost": 0,
		"objectives_done": 0,
		"elapsed_sec": 0.0
	}
	match_objectives.clear()
	match_objectives.append({
		"id": "OBJ_DEFEND_BEACHHEAD",
		"title": "DEFEND TAOYUAN BEACHHEAD",
		"desc": "Repel hostile amphibious invasion armor columns and robot dogs",
		"completed": false,
		"required_uids": primary_enemy_uids.duplicate()
	})
	match_objectives.append({
		"id": "OBJ_PROTECT_BUNKER",
		"title": "SECURE HQ COMMAND CITADEL",
		"desc": "Keep HQ Command Bunker operational above 20% hull integrity",
		"completed": false
	})


## Evaluates real-time tactical match victory / defeat conditions
func evaluate_match_conditions() -> String:
	if not tactical_match_active:
		return match_outcome
	
	if bunker_is_lost or bunker_hp <= 0.0 or bunker_status_code == "LOST":
		match_outcome = "DEFEAT"
		tactical_match_active = false
		sim_events_queue.append({
			"type": "match_ended",
			"outcome": "DEFEAT",
			"scenario": active_theater_slug
		})
		return match_outcome

	var obj_all_done := true
	for obj in match_objectives:
		if String(obj.get("id", "")) == "OBJ_DEFEND_BEACHHEAD":
			var req_uids: Array = obj.get("required_uids", [])
			var any_alive := false
			for r in req_uids:
				var r_uid := int(r)
				if r_uid >= 0 and r_uid < unit_count and unit_active[r_uid] == 1:
					any_alive = true
					break
			if not any_alive and not req_uids.is_empty():
				obj["completed"] = true
			elif not bool(obj.get("completed", false)):
				obj_all_done = false
		elif String(obj.get("id", "")) == "OBJ_PROTECT_BUNKER":
			if bunker_hp > 50.0:
				obj["completed"] = true
			else:
				obj_all_done = false

	if obj_all_done:
		match_outcome = "VICTORY"
		tactical_match_active = false
		sim_events_queue.append({
			"type": "match_ended",
			"outcome": "VICTORY",
			"scenario": active_theater_slug
		})
	return match_outcome


func load_heightmap(res_path: String) -> void:
	active_heightmap_path = res_path
	var img: Image = null
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			img = (res as Texture2D).get_image()
		elif res is Image:
			img = res
	if img == null and not OS.has_feature("android"):
		var global_path := ProjectSettings.globalize_path(res_path)
		var file_img := Image.new()
		if FileAccess.file_exists(global_path) and file_img.load(global_path) == OK:
			img = file_img
	if img != null and not img.is_empty():
		heightmap_size = img.get_width()
		heightmap_elev_m.resize(heightmap_size * heightmap_size)
		for y in range(heightmap_size):
			for x in range(heightmap_size):
				var h_norm: float = img.get_pixel(x, y).r
				# 0.22 is sea level (0m); below 0.22 down to -500m; above 0.22 up to 3800m
				var elev: float = 0.0
				if h_norm < 0.22:
					elev = -500.0 * ((0.22 - h_norm) / 0.22)
				else:
					elev = 3800.0 * ((h_norm - 0.22) / 0.78)
				heightmap_elev_m[y * heightmap_size + x] = elev
	else:
		heightmap_size = 128
		heightmap_elev_m.resize(128 * 128)
		heightmap_elev_m.fill(0.0)


func get_terrain_elevation_m(x_km: float, z_km: float) -> float:
	if heightmap_elev_m.is_empty():
		return 0.0
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var ix: int = clampi(int(u * float(heightmap_size - 1)), 0, heightmap_size - 1)
	var iy: int = clampi(int(v * float(heightmap_size - 1)), 0, heightmap_size - 1)
	return heightmap_elev_m[iy * heightmap_size + ix]


func get_terrain_slope_deg(x_km: float, z_km: float) -> float:
	var step_km := 1.0
	var h_c := maxf(0.0, get_terrain_elevation_m(x_km, z_km))
	var h_x := maxf(0.0, get_terrain_elevation_m(x_km + step_km, z_km))
	var h_z := maxf(0.0, get_terrain_elevation_m(x_km, z_km + step_km))
	var dx_m := h_x - h_c
	var dz_m := h_z - h_c
	var grad := sqrt(dx_m * dx_m + dz_m * dz_m) / (step_km * 1000.0)
	return rad_to_deg(atan(grad))


func spawn_unit(faction: int, platform_id: int, pos_km: Vector3, echelon: int = ECHELON_COMPANY, parent_id: int = -1, p_def: Dictionary = {}) -> int:
	var uid := -1
	for i in range(unit_count):
		if unit_active[i] == 0 and unit_echelon[i] == ECHELON_COMPANY and echelon == ECHELON_COMPANY:
			uid = i
			break
	if uid == -1:
		if unit_count >= MAX_UNITS:
			return -1
		uid = unit_count
		unit_count += 1

	var max_hp_val: float = float(p_def.get("max_hp", 100.0))
	var domain: String = String(p_def.get("domain", "LAND"))
	var spawn_alt_m: float = pos_km.y
	if echelon == ECHELON_COMPANY:
		if domain == "AIR" and spawn_alt_m < 100.0:
			var op_alt: float = float(p_def.get("operational_altitude_m", 0.0))
			if op_alt > 200.0:
				spawn_alt_m = op_alt
			else:
				var u_cls := String(p_def.get("unit_class", ""))
				var ceil_m := float(p_def.get("max_altitude_m", 11000.0))
				if u_cls == "STRIKE":
					spawn_alt_m = clampf(ceil_m * 0.96, 13800.0, 15200.0)
				elif u_cls in ["FIGHTER", "SEAD"]:
					spawn_alt_m = clampf(ceil_m * 0.76, 10800.0, 13500.0)
				elif u_cls in ["AWACS", "TANKER"]:
					spawn_alt_m = clampf(ceil_m * 0.82, 9600.0, 10800.0)
				else:
					spawn_alt_m = clampf(ceil_m * 0.72, 2400.0, 10500.0)
		elif domain == "LAND":
			spawn_alt_m = maxf(0.0, get_terrain_elevation_m(pos_km.x, pos_km.z)) + 5.0
		elif domain == "SEA":
			spawn_alt_m = 0.0

	var max_fuel: float = maxf(80.0, float(p_def.get("combat_radius_km", 250.0)) * 2.0)
	var final_pos := Vector3(pos_km.x, spawn_alt_m, pos_km.z)
	unit_active[uid] = 1
	unit_tactical_posture[uid] = TACTICAL_POSTURE_AUTO
	unit_pos[uid] = final_pos
	unit_vel[uid] = Vector3.ZERO
	unit_target_pos[uid] = final_pos
	unit_has_waypoint[uid] = 0
	unit_faction[uid] = faction
	unit_platform_id[uid] = platform_id
	unit_echelon[uid] = echelon
	unit_parent_id[uid] = parent_id
	unit_radar_active[uid] = 1
	unit_roe[uid] = 2
	unit_hp[uid] = max_hp_val
	unit_max_hp[uid] = max_hp_val
	unit_ammo_1[uid] = int(p_def.get("weapon_1_qty", 8))
	unit_ammo_2[uid] = int(p_def.get("weapon_2_qty", 4))
	unit_energy_cap[uid] = 100.0
	unit_unmanned_bays[uid] = int(p_def.get("carrier_sub_count", 0))
	unit_detected_mask[uid] = (1 if faction == FACTION_BLUE else 2)
	unit_jammed[uid] = 0
	unit_cooldown[uid] = 0.0
	unit_fuel_km[uid] = max_fuel
	unit_max_fuel_km[uid] = max_fuel
	unit_afterburner[uid] = 0
	unit_desired_alt_m[uid] = spawn_alt_m
	unit_ai_state[uid] = AI_PATROL_CAP
	unit_threat_level[uid] = 0.0
	unit_player_override_timer[uid] = 0.0
	unit_heading_rad[uid] = PI if faction == FACTION_BLUE else 0.0
	unit_pitch_rad[uid] = 0.0
	unit_roll_rad[uid] = 0.0
	unit_turret_hdg_rad[uid] = unit_heading_rad[uid]
	unit_suppression_level[uid] = 0.0
	unit_sim_lod[uid] = LOD_TIER_0_MICRO
	unit_morale[uid] = 1.0
	unit_cyber_timer[uid] = 0.0
	unit_cbrn_mopp[uid] = 0
	unit_delegated_ai[uid] = 1
	return uid


## Samples the 2D Wind-Advected Environmental Hazard Plume intensity (0.0..1.0) at (x_km, z_km)
func sample_hazard_density(x_km: float, z_km: float) -> float:
	if hazard_density.is_empty():
		return 0.0
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var ix: int = clampi(int(u * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	var iy: int = clampi(int(v * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	return hazard_density[iy * CIV_GRID_SIZE + ix]


func get_infra_cell_index(x_km: float, z_km: float) -> int:
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var ix: int = clampi(int(round(u * float(CIV_GRID_SIZE - 1))), 0, CIV_GRID_SIZE - 1)
	var iy: int = clampi(int(round(v * float(CIV_GRID_SIZE - 1))), 0, CIV_GRID_SIZE - 1)
	return iy * CIV_GRID_SIZE + ix


func sample_destruction_level(x_km: float, z_km: float) -> float:
	if destruction_level.is_empty():
		return 0.0
	return destruction_level[get_infra_cell_index(x_km, z_km)]


## Computes terrain/infrastructure mobility speed multiplier for LAND units:
## - Highways/Roads (`infra_road_mask > 0.35`, intact): 1.45x speed (Wheeled/Tracked rapid transit)
## - Rivers (`infra_river_mask > 0.45`): 1.25x if on intact Bridge (`infra_bridge_mask > 0.35`), else 0.18x amphibious river ford!
## - Destroyed Rubble (`destruction_level > 0.35`): 0.25x for wheeled/tracked (bogged in craters/rubble), 0.95x for Quadruped Robot Dogs & Infantry!
## - Dense Forest / Nature (`infra_forest_density > 0.45`): 0.62x for vehicles, 0.95x for Infantry/Robot Dogs
func get_ground_mobility_multiplier(x_km: float, z_km: float, is_foot_or_dog: bool) -> float:
	if infra_biome.is_empty():
		return 1.0
	var idx: int = get_infra_cell_index(x_km, z_km)
	var destr: float = destruction_level[idx]
	var river: float = infra_river_mask[idx]
	var bridge: float = infra_bridge_mask[idx]
	var road: float = infra_road_mask[idx]
	var forest: float = infra_forest_density[idx]

	# 1. River Crossing & Strategic Bridge Check
	if river > 0.45:
		if bridge > 0.35 and destr < 0.50:
			return 1.25 # Intact highway/rail bridge over river
		return 0.42 if is_foot_or_dog else 0.16 # Unbridged river or blown bridge chokepoint!

	# 2. War-Torn Cratered / Rubble Area Check
	if destr > 0.35:
		if is_foot_or_dog:
			return 0.92 # Quadruped Robot Dogs & Infantry clamber over urban rubble
		return clampf(1.0 - destr * 0.78, 0.22, 0.65)

	# 3. Intact Highway / Main Supply Route (MSR) Road Bonus
	if road > 0.35:
		return 1.20 if is_foot_or_dog else 1.45

	# 4. Nature / Dense Forest Canopy Off-Road Friction
	if forest > 0.45:
		return 0.95 if is_foot_or_dog else 0.62

	return 1.0


## Computes defensive cover damage multiplier (< 1.0 means reduced incoming damage):
## - Intact Village / Town / Urban City: 0.55x damage (45% urban cover)
## - Destroyed Rubble (`destruction_level > 0.45`): 0.38x damage for Infantry/Robot Dogs (62% fortified rubble cover!)
## - Dense Forest / Nature (`infra_forest_density > 0.45`): 0.68x damage (32% concealment & tree cover)
func get_terrain_cover_damage_mult(x_km: float, z_km: float, is_foot_or_dog: bool) -> float:
	if infra_biome.is_empty():
		return 1.0
	var idx: int = get_infra_cell_index(x_km, z_km)
	var destr: float = destruction_level[idx]
	var urban: float = infra_urban_density[idx]
	var forest: float = infra_forest_density[idx]

	if destr > 0.45 and (urban > 0.20 or is_foot_or_dog):
		return 0.38 if is_foot_or_dog else 0.68
	if urban > 0.30:
		return 0.52 if is_foot_or_dog else 0.72
	if forest > 0.45:
		return 0.65 if is_foot_or_dog else 0.80
	return 1.0


## Inflicts physical war destruction (craters, collapsed buildings, blown bridges, severed rails & charred forests)
func inject_war_destruction(x_km: float, z_km: float, radius_km: float = 12.0, intensity: float = 0.55) -> int:
	if destruction_level.is_empty():
		return 0
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var cx: int = clampi(int(round(u * float(CIV_GRID_SIZE - 1))), 0, CIV_GRID_SIZE - 1)
	var cy: int = clampi(int(round(v * float(CIV_GRID_SIZE - 1))), 0, CIV_GRID_SIZE - 1)
	var cell_rad: int = maxi(1, int(ceil(radius_km / (500.0 / float(CIV_GRID_SIZE)))))
	var newly_destroyed := 0

	for dy in range(-cell_rad, cell_rad + 1):
		var ny: int = cy + dy
		if ny < 0 or ny >= CIV_GRID_SIZE:
			continue
		for dx in range(-cell_rad, cell_rad + 1):
			var nx: int = cx + dx
			if nx < 0 or nx >= CIV_GRID_SIZE:
				continue
			var d_norm: float = sqrt(float(dx * dx + dy * dy)) / float(max(1, cell_rad))
			if d_norm <= 1.0:
				var idx: int = ny * CIV_GRID_SIZE + nx
				var prev_d: float = destruction_level[idx]
				var next_d: float = clampf(prev_d + intensity * (1.0 - d_norm * 0.65), 0.0, 1.0)
				destruction_level[idx] = next_d
				if prev_d < 0.25 and next_d >= 0.25:
					active_destroyed_cells_count += 1
					newly_destroyed += 1
				if infra_bridge_mask[idx] > 0.35 and prev_d < 0.50 and next_d >= 0.50:
					bridges_destroyed_count += 1
				# Rubble & craters degrade civilian road passability and burn forest cover
				civ_passability[idx] = maxf(0.15, civ_passability[idx] * (1.0 - next_d * 0.45))
				infra_forest_density[idx] = maxf(0.0, infra_forest_density[idx] * (1.0 - next_d * 0.60))
	return newly_destroyed


## Injects an Environmental Contamination / Fallout Plume at (x_km, z_km) that drifts with theater wind
func inject_hazard_plume(x_km: float, z_km: float, radius_km: float = 24.0, intensity: float = 0.88) -> void:
	if hazard_density.is_empty():
		return
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var cx: int = clampi(int(u * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	var cy: int = clampi(int(v * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	var cell_rad: int = maxi(2, int(ceil(radius_km / (500.0 / float(CIV_GRID_SIZE)))))

	for dy in range(-cell_rad, cell_rad + 1):
		var ny: int = cy + dy
		if ny < 1 or ny >= CIV_GRID_SIZE - 1:
			continue
		for dx in range(-cell_rad, cell_rad + 1):
			var nx: int = cx + dx
			if nx < 1 or nx >= CIV_GRID_SIZE - 1:
				continue
			var d_norm: float = sqrt(float(dx * dx + dy * dy)) / float(cell_rad)
			if d_norm <= 1.0:
				var idx: int = ny * CIV_GRID_SIZE + nx
				hazard_density[idx] = clampf(hazard_density[idx] + intensity * (1.0 - d_norm * 0.75), 0.0, 1.0)
				civ_threat_field[idx] = minf(3.5, civ_threat_field[idx] + 2.8 * (1.0 - d_norm))
				civ_flux_activity[idx] = minf(1.0, civ_flux_activity[idx] + 0.85 * (1.0 - d_norm))


## Bilinearly samples the continuous Spreading Civilian Density Field (in civilians/m^2) at (x_km, z_km)
func sample_civilian_density_m2(x_km: float, z_km: float) -> float:
	if civ_density_m2.is_empty():
		return 0.0
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var fx: float = u * float(CIV_GRID_SIZE - 1)
	var fy: float = v * float(CIV_GRID_SIZE - 1)
	var x0: int = clampi(int(fx), 0, CIV_GRID_SIZE - 1)
	var y0: int = clampi(int(fy), 0, CIV_GRID_SIZE - 1)
	var x1: int = mini(x0 + 1, CIV_GRID_SIZE - 1)
	var y1: int = mini(y0 + 1, CIV_GRID_SIZE - 1)
	var tx: float = fx - float(x0)
	var ty: float = fy - float(y0)

	var c00: float = civ_density_m2[y0 * CIV_GRID_SIZE + x0]
	var c10: float = civ_density_m2[y0 * CIV_GRID_SIZE + x1]
	var c01: float = civ_density_m2[y1 * CIV_GRID_SIZE + x0]
	var c11: float = civ_density_m2[y1 * CIV_GRID_SIZE + x1]
	return lerpf(lerpf(c00, c10, tx), lerpf(c01, c11, tx), ty)


## Injects a repulsive combat shockwave into the Civilian Density Field so nearby populations spread & evacuate
func inject_civilian_combat_shock(x_km: float, z_km: float, radius_km: float = 20.0, intensity: float = 1.0) -> void:
	if civ_threat_field.is_empty():
		return
	var u: float = clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v: float = clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var cx: int = clampi(int(u * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	var cy: int = clampi(int(v * float(CIV_GRID_SIZE - 1)), 0, CIV_GRID_SIZE - 1)
	var cell_rad: int = maxi(2, int(ceil(radius_km / (500.0 / float(CIV_GRID_SIZE)))))

	for dy in range(-cell_rad, cell_rad + 1):
		var ny: int = cy + dy
		if ny < 1 or ny >= CIV_GRID_SIZE - 1:
			continue
		for dx in range(-cell_rad, cell_rad + 1):
			var nx: int = cx + dx
			if nx < 1 or nx >= CIV_GRID_SIZE - 1:
				continue
			var d_norm: float = sqrt(float(dx * dx + dy * dy)) / float(cell_rad)
			if d_norm <= 1.0:
				var idx: int = ny * CIV_GRID_SIZE + nx
				civ_threat_field[idx] = minf(3.5, civ_threat_field[idx] + intensity * (1.0 - d_norm))
				civ_flux_activity[idx] = minf(1.0, civ_flux_activity[idx] + 0.65 * (1.0 - d_norm))


func spawn_munition(faction: int, weapon_id: int, shooter_id: int, target_unit_id: int, start_pos: Vector3, target_pos: Vector3, flight_profile: String) -> int:
	var mid := -1
	for i in range(mun_count):
		if mun_active[i] == 0:
			mid = i
			break
	if mid == -1:
		if mun_count >= MAX_MUNITIONS:
			return -1
		mid = mun_count
		mun_count += 1

	var dist_km := Vector2(start_pos.x, start_pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
	dist_km = maxf(dist_km, 0.25)

	var actual_start := start_pos
	var apex_m := maxf(start_pos.y, target_pos.y) + 250.0
	if flight_profile == "ORBITAL_KINETIC_ROD":
		actual_start = Vector3(target_pos.x - 45.0, 550000.0, target_pos.z - 25.0) # Released from 550 km LEO orbital strike platform!
		apex_m = 550000.0
		dist_km = sqrt(45.0 * 45.0 + 25.0 * 25.0 + 550.0 * 550.0) # True 3D orbital re-entry path (~552.4 km at Mach 24 = 8.232 km/s)
	elif flight_profile == "LOFTED_BALLISTIC":
		if dist_km > 180.0:
			apex_m = maxf(start_pos.y, target_pos.y) + clampf(dist_km * 195.0, 28000.0, 85000.0) # Stratospheric/Mesospheric Quasi-Ballistic & Hypersonic Glide
		elif dist_km > 15.0:
			apex_m = maxf(start_pos.y, target_pos.y) + clampf(dist_km * 165.0, 14500.0, 32000.0) # Lofted BVR AAM / SAM arc
		else:
			apex_m = maxf(start_pos.y, target_pos.y) + 160.0 # Top-attack Javelin ATGM
	elif flight_profile == "SEA_SKIM_TERCOM":
		var terr_y := maxf(0.0, get_terrain_elevation_m((start_pos.x + target_pos.x) * 0.5, (start_pos.z + target_pos.z) * 0.5))
		apex_m = maxf(terr_y + 35.0, maxf(start_pos.y, target_pos.y) * 0.25 + 35.0)
	elif flight_profile == "DIRECT":
		if dist_km <= 15.0 and start_pos.y < 500.0:
			apex_m = maxf(start_pos.y, target_pos.y) + 120.0 # Low-altitude FPV kamikaze drone (120m AGL)
		else:
			apex_m = maxf(start_pos.y, target_pos.y) + 950.0 # Loitering munition (Switchblade 600 / Lancet-3 / Harop at ~950m)

	mun_active[mid] = 1
	mun_pos[mid] = actual_start
	mun_start_pos[mid] = actual_start
	mun_target_pos[mid] = target_pos
	mun_vel[mid] = Vector3.ZERO
	mun_faction[mid] = faction
	mun_weapon_id[mid] = weapon_id
	mun_shooter_id[mid] = shooter_id
	mun_target_unit_id[mid] = target_unit_id
	mun_flight_progress[mid] = 0.0
	mun_total_dist_km[mid] = dist_km
	mun_apex_alt_m[mid] = apex_m
	mun_jammed[mid] = 0
	return mid


func get_active_unit_count() -> int:
	var c := 0
	for i in range(unit_count):
		if unit_active[i] == 1:
			c += 1
	return c


func get_active_leaf_unit_count() -> int:
	var c := 0
	for i in range(unit_count):
		if unit_active[i] == 1 and unit_echelon[i] == ECHELON_COMPANY:
			c += 1
	return c


func get_active_munition_count() -> int:
	var c := 0
	for i in range(mun_count):
		if mun_active[i] == 1:
			c += 1
	return c

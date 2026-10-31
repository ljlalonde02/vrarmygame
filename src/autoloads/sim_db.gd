extends Node
## SimDB Autoload: Connects to `res://data/wargame.db` (or `res://data/wargame_cache.json`)
## and populates both Dictionary metadata AND Pre-Compiled Structure-of-Arrays (SoA) Fast Lookup Tables
## (`plat_domain_id`, `plat_class_flags`, `plat_rcs_factor`, `weap_speed_km_s`, etc.) so inner simulation
## loops execute with zero Dictionary/String hashing overhead.

const DB_PATH := "res://data/wargame.db"
const CACHE_JSON_PATH := "res://data/wargame_cache.json"

# Target Domain Bitmask Constants (matches SQLite schema)
const DOMAIN_MASK_AIR := 1
const DOMAIN_MASK_LAND := 2
const DOMAIN_MASK_SEA := 4
const DOMAIN_MASK_RADAR := 8
const DOMAIN_MASK_MISSILE_DRONE := 16

# Fast Integer Domain IDs for O(1) array branching
const DOM_LAND := 0
const DOM_AIR := 1
const DOM_SEA := 2

# 6-Spectrum Sensor Fusion Matrix IDs (Section 11 of ARCHITECTURE.md)
const SENSOR_ACTIVE_RADAR := 0
const SENSOR_PASSIVE_ESM := 1
const SENSOR_IR_EO := 2
const SENSOR_LIDAR_CV := 3
const SENSOR_ACOUSTIC_SONAR := 4
const SENSOR_SAT_SAR_EO := 5

# Pre-compiled Platform Class Bitflags for zero-string inner-loop checks
const FLAG_SAM := 1 << 0
const FLAG_FIGHTER := 1 << 1
const FLAG_SEAD := 1 << 2
const FLAG_AWACS := 1 << 3
const FLAG_TANKER := 1 << 4
const FLAG_LOGISTICS := 1 << 5
const FLAG_EW_JAMMER := 1 << 6
const FLAG_ARTILLERY := 1 << 7
const FLAG_INFANTRY := 1 << 8
const FLAG_ROBOT_DOG := 1 << 9
const FLAG_ARMOR := 1 << 10
const FLAG_SWARM := 1 << 11
const FLAG_SHIP := 1 << 12
const FLAG_CLIMB_SLOPES := 1 << 13
const FLAG_RF_DATALINK := 1 << 14
const FLAG_UNMANNED := 1 << 15
const FLAG_CUAS_GUN := 1 << 16
const FLAG_UUV_SUB := 1 << 17

const KNOTS_TO_KM_PER_SEC := 0.000514444
const TACTICAL_PACE_MULT := 1.0 # 1.0 = True 1:1 Real-Time Physical Speeds (1 kt = 1.852 km/h = 0.0005144 km/s)
const MACH_TO_KM_PER_SEC := 0.343
const MUNITION_PACE_MULT := 1.0 # 1.0 = True 1:1 Real-Time Missile Physics (Mach 1 = 343 m/s = 0.343 km/s)

# O(1) Integer-Indexed Dictionary Arrays (Index 0 is dummy/null record)
var platforms_by_id: Array[Dictionary] = []
var weapons_by_id: Array[Dictionary] = []
var sensors_by_id: Array[Dictionary] = []

# Pre-Compiled O(1) Platform SoA LUTs (indexed by platform_id)
var plat_domain_id: PackedByteArray = PackedByteArray()
var plat_class_flags: PackedInt32Array = PackedInt32Array()
var plat_cruise_km_s: PackedFloat32Array = PackedFloat32Array()
var plat_max_km_s: PackedFloat32Array = PackedFloat32Array()
var plat_max_alt_m: PackedFloat32Array = PackedFloat32Array()
var plat_cruise_alt_m: PackedFloat32Array = PackedFloat32Array()
var plat_rcs_factor: PackedFloat32Array = PackedFloat32Array()
var plat_ir_factor: PackedFloat32Array = PackedFloat32Array()
var plat_acoustic_factor: PackedFloat32Array = PackedFloat32Array()
var plat_sensor_range_km: PackedFloat32Array = PackedFloat32Array()
var plat_sensor_is_radar: PackedByteArray = PackedByteArray()
var plat_sensor_type_id: PackedByteArray = PackedByteArray()
var plat_has_passive_esm: PackedByteArray = PackedByteArray()
var plat_de_kw: PackedFloat32Array = PackedFloat32Array()
var plat_de_cone_deg: PackedFloat32Array = PackedFloat32Array()
var plat_de_cone_cos: PackedFloat32Array = PackedFloat32Array()
var plat_w1_id: PackedInt32Array = PackedInt32Array()
var plat_w1_qty: PackedInt32Array = PackedInt32Array()
var plat_w2_id: PackedInt32Array = PackedInt32Array()
var plat_w2_qty: PackedInt32Array = PackedInt32Array()
var plat_cost_musd: PackedFloat32Array = PackedFloat32Array()
var plat_armor_mitigation: PackedFloat32Array = PackedFloat32Array()
var plat_sub_pid: PackedInt32Array = PackedInt32Array()
var plat_sub_count: PackedInt32Array = PackedInt32Array()
var plat_crew_complement: PackedInt32Array = PackedInt32Array()

# Pre-Compiled O(1) Weapon SoA LUTs (indexed by weapon_id)
var weap_speed_km_s: PackedFloat32Array = PackedFloat32Array()
var weap_nez_km: PackedFloat32Array = PackedFloat32Array()
var weap_max_range_km: PackedFloat32Array = PackedFloat32Array()
var weap_damage: PackedFloat32Array = PackedFloat32Array()
var weap_base_pk: PackedFloat32Array = PackedFloat32Array()
var weap_cost_musd: PackedFloat32Array = PackedFloat32Array()
var weap_is_interceptable: PackedByteArray = PackedByteArray()

# Fast Slug & Relational Maps
var platform_id_by_slug: Dictionary = {}
var weapon_id_by_slug: Dictionary = {}
var sensor_id_by_slug: Dictionary = {}
var platform_sensor_ids: Dictionary = {}
var platform_loadouts: Dictionary = {}
var formations_by_slug: Dictionary = {}
var theaters_by_slug: Dictionary = {}
var theaters_by_id: Dictionary = {}
var theaters_list: Array[Dictionary] = []
var theater_sites: Array[Dictionary] = []
var scenarios_by_slug: Dictionary = {}
var scenarios_list: Array[Dictionary] = []
var tutorial_steps: Array[Dictionary] = []
var manual_sections: Array[Dictionary] = []
var tech_tree_nodes: Array[Dictionary] = []
var tech_tree_by_slug: Dictionary = {}
var sovereign_nations: Array[Dictionary] = []
var sovereign_nations_by_slug: Dictionary = {}
var campaign_nations: Array[Dictionary] = []
var campaign_nations_by_slug: Dictionary = {}
var campaign_story_nodes: Array[Dictionary] = []
var campaign_story_nodes_by_slug: Dictionary = {}
var campaign_story_edges: Array[Dictionary] = []
var campaign_story_edges_by_from_node: Dictionary = {}
var news_video_clips: Array[Dictionary] = []
var news_video_by_slug: Dictionary = {}
var news_video_by_trigger: Dictionary = {}

# Preloaded / Cached Real Wikipedia Photographs (image_res_path -> Texture2D) & News Video Filmstrips
var _photo_cache: Dictionary = {}
var _news_frames_cache: Dictionary = {}
var is_loaded: bool = false


func _ready() -> void:
	load_database()


func load_database() -> void:
	if is_loaded and platforms_by_id.size() > 1:
		return

	platforms_by_id.clear()
	weapons_by_id.clear()
	sensors_by_id.clear()
	platform_id_by_slug.clear()
	weapon_id_by_slug.clear()
	sensor_id_by_slug.clear()
	platform_sensor_ids.clear()
	platform_loadouts.clear()
	formations_by_slug.clear()
	theaters_by_slug.clear()
	theaters_by_id.clear()
	theaters_list.clear()
	theater_sites.clear()
	scenarios_by_slug.clear()
	scenarios_list.clear()
	tutorial_steps.clear()
	manual_sections.clear()
	tech_tree_nodes.clear()
	tech_tree_by_slug.clear()
	sovereign_nations.clear()
	sovereign_nations_by_slug.clear()
	campaign_nations.clear()
	campaign_nations_by_slug.clear()
	campaign_story_nodes.clear()
	campaign_story_nodes_by_slug.clear()
	campaign_story_edges.clear()
	campaign_story_edges_by_from_node.clear()

	platforms_by_id.append({"platform_id": 0, "slug": "none", "display_name": "None"})
	weapons_by_id.append({"weapon_id": 0, "slug": "none", "display_name": "None"})
	sensors_by_id.append({"sensor_id": 0, "slug": "none", "display_name": "None"})

	var payload: Dictionary = {}

	if ClassDB.class_exists("SQLite"):
		var db: Object = ClassDB.instantiate("SQLite")
		if db != null:
			db.set("path", DB_PATH)
			if db.call("open_db"):
				for tbl in ["platforms", "sensors", "weapons", "platform_sensors", "platform_loadouts", "formation_templates", "theaters", "theater_sites", "scenarios", "tutorial_steps", "manual_sections", "tech_tree_nodes", "sovereign_nations", "campaign_nations", "campaign_story_nodes", "campaign_story_edges"]:
					if db.call("query", "SELECT * FROM " + tbl):
						payload[tbl] = db.get("query_result")
				db.call("close_db")

	if payload.is_empty() and ResourceLoader.exists(CACHE_JSON_PATH):
		var json_res = load(CACHE_JSON_PATH)
		if json_res != null and "data" in json_res and typeof(json_res.data) == TYPE_DICTIONARY:
			payload = json_res.data

	if payload.is_empty() and FileAccess.file_exists(CACHE_JSON_PATH):
		var json_text := FileAccess.get_file_as_string(CACHE_JSON_PATH)
		var parsed = JSON.parse_string(json_text)
		if typeof(parsed) == TYPE_DICTIONARY:
			payload = parsed

	assert(not payload.is_empty(), "SimDB failed to load data/wargame.db or data/wargame_cache.json")

	for s in payload.get("sensors", []):
		var sid: int = int(s["sensor_id"])
		while sensors_by_id.size() <= sid:
			sensors_by_id.append({})
		sensors_by_id[sid] = s
		sensor_id_by_slug[String(s["slug"])] = sid

	for w in payload.get("weapons", []):
		var wid: int = int(w["weapon_id"])
		while weapons_by_id.size() <= wid:
			weapons_by_id.append({})
		weapons_by_id[wid] = w
		weapon_id_by_slug[String(w["slug"])] = wid

	for p in payload.get("platforms", []):
		var pid: int = int(p["platform_id"])
		while platforms_by_id.size() <= pid:
			platforms_by_id.append({})
		platforms_by_id[pid] = p
		platform_id_by_slug[String(p["slug"])] = pid
		platform_sensor_ids[pid] = []
		platform_loadouts[pid] = {"weapon_1_id": 0, "weapon_1_qty": 0, "weapon_2_id": 0, "weapon_2_qty": 0}

	for ps in payload.get("platform_sensors", []):
		var pid: int = int(ps["platform_id"])
		var sid: int = int(ps["sensor_id"])
		if not platform_sensor_ids.has(pid):
			platform_sensor_ids[pid] = []
		platform_sensor_ids[pid].append(sid)

	for pl in payload.get("platform_loadouts", []):
		var pid: int = int(pl["platform_id"])
		platform_loadouts[pid] = {
			"role_code": String(pl.get("role_code", "STANDARD")),
			"display_name": String(pl.get("display_name", "Standard")),
			"weapon_1_id": int(pl.get("weapon_1_id", 0)),
			"weapon_1_qty": int(pl.get("weapon_1_qty", 0)),
			"weapon_2_id": int(pl.get("weapon_2_id", 0)),
			"weapon_2_qty": int(pl.get("weapon_2_qty", 0)),
		}

	# Build Pre-Compiled O(1) Platform SoA LUTs
	var num_p := platforms_by_id.size()
	plat_domain_id.resize(num_p)
	plat_class_flags.resize(num_p)
	plat_cruise_km_s.resize(num_p)
	plat_max_km_s.resize(num_p)
	plat_max_alt_m.resize(num_p)
	plat_cruise_alt_m.resize(num_p)
	plat_rcs_factor.resize(num_p)
	plat_ir_factor.resize(num_p)
	plat_acoustic_factor.resize(num_p)
	plat_sensor_range_km.resize(num_p)
	plat_sensor_is_radar.resize(num_p)
	plat_sensor_type_id.resize(num_p)
	plat_has_passive_esm.resize(num_p)
	plat_de_kw.resize(num_p)
	plat_de_cone_deg.resize(num_p)
	plat_de_cone_cos.resize(num_p)
	plat_w1_id.resize(num_p)
	plat_w1_qty.resize(num_p)
	plat_w2_id.resize(num_p)
	plat_w2_qty.resize(num_p)
	plat_cost_musd.resize(num_p)
	plat_armor_mitigation.resize(num_p)
	plat_sub_pid.resize(num_p)
	plat_sub_count.resize(num_p)
	plat_crew_complement.resize(num_p)

	for pid in range(1, num_p):
		var p: Dictionary = platforms_by_id[pid]
		if p.is_empty():
			continue
		var sids: Array = platform_sensor_ids.get(pid, [])
		var primary_sid: int = int(sids[0]) if sids.size() > 0 else 0
		p["primary_sensor_id"] = primary_sid
		if primary_sid > 0 and primary_sid < sensors_by_id.size():
			p["sensor_range_km"] = float(sensors_by_id[primary_sid].get("max_range_km", 20.0))
			p["sensor_type"] = String(sensors_by_id[primary_sid].get("sensor_type", "ACTIVE_RADAR"))
		else:
			p["sensor_range_km"] = 15.0
			p["sensor_type"] = "IR_EO"

		var ld: Dictionary = platform_loadouts.get(pid, {})
		p["weapon_1_id"] = int(ld.get("weapon_1_id", 0))
		p["weapon_1_qty"] = int(ld.get("weapon_1_qty", 0))
		p["weapon_2_id"] = int(ld.get("weapon_2_id", 0))
		p["weapon_2_qty"] = int(ld.get("weapon_2_qty", 0))

		var sub_slug := String(p.get("carrier_sub_platform_slug", ""))
		var sub_id: int = int(platform_id_by_slug.get(sub_slug, 0)) if sub_slug != "" else 0
		p["carrier_sub_platform_id"] = sub_id

		var dom_str := String(p.get("domain", "LAND"))
		plat_domain_id[pid] = DOM_AIR if dom_str == "AIR" else (DOM_SEA if dom_str == "SEA" else DOM_LAND)

		var u_class := String(p.get("unit_class", ""))
		var autonomy := String(p.get("autonomy_level", "MANNED"))
		var flags := 0
		if u_class == "SAM":
			flags |= FLAG_SAM
		if u_class in ["FIGHTER", "STEALTH_FIGHTER", "CCA_DRONE", "UCAV", "HELICOPTER"]:
			flags |= FLAG_FIGHTER
		if u_class == "SEAD":
			flags |= FLAG_SEAD
		if u_class == "AWACS":
			flags |= FLAG_AWACS
		if u_class == "TANKER":
			flags |= FLAG_TANKER
		if u_class == "LOGISTICS":
			flags |= FLAG_LOGISTICS
		if u_class == "EW_JAMMER":
			flags |= FLAG_EW_JAMMER
		if u_class in ["ARTILLERY", "MLRS", "HYPERSONIC_TEL"]:
			flags |= FLAG_ARTILLERY
		if u_class == "INFANTRY":
			flags |= FLAG_INFANTRY
		if u_class == "ROBOT_DOG":
			flags |= FLAG_ROBOT_DOG
		if u_class in ["ARMOR", "MECH", "UGV"]:
			flags |= FLAG_ARMOR
		if u_class in ["SWARM_TEAM", "CCA_DRONE", "USV_DRONE"]:
			flags |= FLAG_SWARM
		if u_class == "SHIP":
			flags |= FLAG_SHIP
		if u_class in ["UUV_DRONE", "SSBN", "SSN"]:
			flags |= FLAG_UUV_SUB
		if u_class == "CUAS_GUN":
			flags |= FLAG_CUAS_GUN
		if int(p.get("can_climb_steep_slopes", 0)) == 1:
			flags |= FLAG_CLIMB_SLOPES
		if autonomy == "RF_DATALINK":
			flags |= FLAG_RF_DATALINK
		if autonomy != "MANNED":
			flags |= FLAG_UNMANNED
		plat_class_flags[pid] = flags

		var c_kts := float(p.get("cruise_speed_knots", 35.0))
		var m_kts := maxf(c_kts * 1.5, float(p.get("max_speed_knots", c_kts * 1.5)))
		plat_cruise_km_s[pid] = c_kts * KNOTS_TO_KM_PER_SEC * TACTICAL_PACE_MULT
		plat_max_km_s[pid] = m_kts * KNOTS_TO_KM_PER_SEC * TACTICAL_PACE_MULT
		var ceil_m := float(p.get("max_altitude_m", 8000.0))
		plat_max_alt_m[pid] = ceil_m
		var p_slug := String(p.get("slug", ""))
		var p_nato := String(p.get("nato_symbol_code", ""))
		var op_alt_m := 0.0
		if dom_str == "AIR":
			if u_class == "STRIKE" or p_nato in ["AIR_BOMBER_STEALTH", "AIR_BOMBER"]:
				op_alt_m = clampf(ceil_m * 0.96, 13800.0, 15200.0) # High-altitude strategic bomber (45,000-50,000 ft)
			elif u_class in ["FIGHTER", "SEAD"]:
				op_alt_m = clampf(ceil_m * 0.76, 10800.0, 13500.0) # 4.5th/5th-Gen BVR CAP supercruise (35,500-44,000 ft)
			elif u_class in ["AWACS", "TANKER"]:
				op_alt_m = clampf(ceil_m * 0.82, 9600.0, 10800.0)  # AWACS / Tanker high racetrack orbit (31,500-35,500 ft)
			elif p_slug == "palianytsia_drone_uk":
				op_alt_m = 2400.0                                  # Low-altitude turbojet deep-strike OWA drone
			elif p_slug == "bayraktar_akinci_ucav":
				op_alt_m = 7200.0                                  # MALE turboprop strike UCAV (23,600 ft)
			elif u_class == "HELICOPTER" or p_nato.begins_with("AIR_HELICOPTER") or p.has("operational_altitude_m"):
				op_alt_m = float(p.get("operational_altitude_m", 120.0)) # NOE attack helicopter flight (120m)
			else:
				op_alt_m = clampf(ceil_m * 0.72, 8500.0, 10500.0)  # Stealth Loyal Wingman CCA (28,000-34,500 ft)
		elif dom_str == "SEA" and (u_class in ["SSBN", "UUV_DRONE", "SSN"] or p_nato.begins_with("SEA_SUB")):
			op_alt_m = float(p.get("operational_altitude_m", ceil_m if ceil_m < 0.0 else -180.0))
		plat_cruise_alt_m[pid] = op_alt_m
		p["operational_altitude_m"] = op_alt_m

		var rcs := maxf(float(p.get("rcs_m2", 1.0)), 0.00005)
		plat_rcs_factor[pid] = pow(rcs / 5.0, 0.25)
		plat_ir_factor[pid] = clampf(float(p.get("ir_signature", 0.5)), 0.25, 1.6)
		# Acoustic / Sonar signature factor (propeller drones, low-flying jets, armor, ships & submarines)
		var ac_factor := 0.85
		if u_class in ["SWARM_TEAM", "CCA_DRONE", "USV_DRONE"]:
			ac_factor = 1.25
		elif u_class in ["UUV_DRONE", "SSBN", "SSN"]:
			ac_factor = 0.25 if u_class == "SSBN" else 0.70
		elif u_class == "ROBOT_DOG":
			ac_factor = 0.35
		plat_acoustic_factor[pid] = ac_factor
		plat_sensor_range_km[pid] = float(p.get("sensor_range_km", 20.0))
		var stype_str := String(p.get("sensor_type", "ACTIVE_RADAR"))
		plat_sensor_is_radar[pid] = 1 if stype_str == "ACTIVE_RADAR" else 0
		var stype_id := SENSOR_ACTIVE_RADAR
		if stype_str == "PASSIVE_ESM":
			stype_id = SENSOR_PASSIVE_ESM
		elif stype_str == "IR_EO":
			stype_id = SENSOR_IR_EO
		elif stype_str == "LIDAR_CV":
			stype_id = SENSOR_LIDAR_CV
		elif stype_str == "ACOUSTIC_SONAR":
			stype_id = SENSOR_ACOUSTIC_SONAR
		elif stype_str == "SAT_SAR_EO":
			stype_id = SENSOR_SAT_SAR_EO
		plat_sensor_type_id[pid] = stype_id
		# Modern aircraft, AWACS, SEAD, SAMs, EW jammers, and warships also carry Passive ESM/RWR suites
		var has_esm := 1 if (stype_id == SENSOR_PASSIVE_ESM or dom_str == "AIR" or (flags & (FLAG_SAM | FLAG_SEAD | FLAG_AWACS | FLAG_EW_JAMMER | FLAG_SHIP)) != 0) else 0
		plat_has_passive_esm[pid] = has_esm

		var de_kw := float(p.get("directed_energy_kw", 0.0))
		var de_cone := float(p.get("de_aoe_cone_deg", 0.0))
		plat_de_kw[pid] = de_kw
		plat_de_cone_deg[pid] = de_cone
		plat_de_cone_cos[pid] = cos(deg_to_rad(de_cone * 0.5)) if de_cone > 0.0 else 1.0

		plat_w1_id[pid] = int(p["weapon_1_id"])
		plat_w1_qty[pid] = int(p["weapon_1_qty"])
		plat_w2_id[pid] = int(p["weapon_2_id"])
		plat_w2_qty[pid] = int(p["weapon_2_qty"])
		plat_cost_musd[pid] = float(p.get("unit_cost_musd", 10.0))
		var armor := float(p.get("armor_rating", 5.0))
		plat_armor_mitigation[pid] = clampf(1.0 - armor * 0.004, 0.35, 1.0)
		plat_sub_pid[pid] = sub_id
		plat_sub_count[pid] = int(p.get("carrier_sub_count", 0))

		# Realistic personnel complement per unit token for KIA/WIA casualty tracking
		var nato_code := String(p.get("nato_symbol_code", ""))
		var crew := 16
		if autonomy != "MANNED":
			crew = 0
		elif nato_code == "SEA_CARRIER":
			crew = 2800
		elif dom_str == "SEA":
			crew = 260
		elif dom_str == "AIR":
			crew = 12 if (u_class in ["AWACS", "TANKER", "BOMBER"]) else 4
		elif u_class in ["INFANTRY", "MECH_INF", "MECH"]:
			crew = 36
		plat_crew_complement[pid] = crew

	# Build Pre-Compiled O(1) Weapon SoA LUTs
	var num_w := weapons_by_id.size()
	weap_speed_km_s.resize(num_w)
	weap_nez_km.resize(num_w)
	weap_max_range_km.resize(num_w)
	weap_damage.resize(num_w)
	weap_base_pk.resize(num_w)
	weap_cost_musd.resize(num_w)
	weap_is_interceptable.resize(num_w)

	for wid in range(1, num_w):
		var w: Dictionary = weapons_by_id[wid]
		if w.is_empty():
			continue
		var mach := float(w.get("speed_mach", 2.5))
		weap_speed_km_s[wid] = maxf(0.025, mach * MACH_TO_KM_PER_SEC * MUNITION_PACE_MULT)
		weap_nez_km[wid] = float(w.get("no_escape_range_km", 15.0))
		weap_max_range_km[wid] = float(w.get("max_range_km", 25.0))
		weap_damage[wid] = float(w.get("warhead_damage", 80.0))
		weap_base_pk[wid] = float(w.get("base_pk", 0.8))
		weap_cost_musd[wid] = float(w.get("round_cost_musd", 0.1))
		weap_is_interceptable[wid] = int(w.get("is_interceptable", 1))

	for f in payload.get("formation_templates", []):
		var f_copy: Dictionary = f.duplicate()
		var parsed_children = JSON.parse_string(String(f.get("child_entries_json", "[]")))
		f_copy["children"] = parsed_children if typeof(parsed_children) == TYPE_ARRAY else []
		formations_by_slug[String(f["slug"])] = f_copy

	for t in payload.get("theaters", []):
		theaters_by_slug[String(t["slug"])] = t
		theaters_by_id[int(t["theater_id"])] = t
		theaters_list.append(t)
	for st in payload.get("theater_sites", []):
		theater_sites.append(st)

	for sc in payload.get("scenarios", []):
		var sc_copy: Dictionary = sc.duplicate()
		var parsed_orbat = JSON.parse_string(String(sc.get("orbat_json", "{}")))
		sc_copy["orbat"] = parsed_orbat if typeof(parsed_orbat) == TYPE_DICTIONARY else {}
		if not sc_copy.has("theater_slug") or String(sc_copy.get("theater_slug", "")).is_empty():
			var tid: int = int(sc_copy.get("theater_id", 1))
			var th_dict: Dictionary = theaters_by_id.get(tid, {})
			sc_copy["theater_slug"] = String(th_dict.get("slug", "strait_theater"))
		scenarios_by_slug[String(sc["slug"])] = sc_copy
		scenarios_list.append(sc_copy)

	# FEAT-11: Load external crisis scenario JSON files from res://data/scenarios/
	var sc_dir := DirAccess.open("res://data/scenarios")
	if sc_dir != null:
		sc_dir.list_dir_begin()
		var sc_fname := sc_dir.get_next()
		while not sc_fname.is_empty():
			if not sc_dir.current_is_dir() and sc_fname.ends_with(".json"):
				var fpath := "res://data/scenarios/" + sc_fname
				var sc_file := FileAccess.open(fpath, FileAccess.READ)
				if sc_file != null:
					var sc_json = JSON.parse_string(sc_file.get_as_text())
					sc_file.close()
					if typeof(sc_json) == TYPE_DICTIONARY:
						var sc_dict: Dictionary = sc_json
						var s_slug := String(sc_dict.get("slug", sc_fname.get_basename()))
						if not sc_dict.has("theater_slug"):
							sc_dict["theater_slug"] = "strait_theater"
						var parsed_orb = JSON.parse_string(String(sc_dict.get("orbat_json", "{}")))
						sc_dict["orbat"] = parsed_orb if typeof(parsed_orb) == TYPE_DICTIONARY else {}
						scenarios_by_slug[s_slug] = sc_dict
						var exists := false
						for existing in scenarios_list:
							if String(existing.get("slug", "")) == s_slug:
								exists = true
								break
						if not exists:
							scenarios_list.append(sc_dict)
			sc_fname = sc_dir.get_next()
		sc_dir.list_dir_end()

	for ts in payload.get("tutorial_steps", []):
		tutorial_steps.append(ts)
	for ms in payload.get("manual_sections", []):
		manual_sections.append(ms)
	for tn in payload.get("tech_tree_nodes", []):
		var tn_copy: Dictionary = tn.duplicate()
		var parsed_mods = JSON.parse_string(String(tn.get("modifiers_json", "{}")))
		tn_copy["modifiers"] = parsed_mods if typeof(parsed_mods) == TYPE_DICTIONARY else {}
		tech_tree_nodes.append(tn_copy)
		tech_tree_by_slug[String(tn["slug"])] = tn_copy

	for sn in payload.get("sovereign_nations", []):
		var sn_copy: Dictionary = sn.duplicate()
		sovereign_nations.append(sn_copy)
		sovereign_nations_by_slug[String(sn["slug"])] = sn_copy

	for cn in payload.get("campaign_nations", []):
		var cn_copy: Dictionary = cn.duplicate()
		var p_caps = JSON.parse_string(String(cn.get("special_capabilities_json", "{}")))
		cn_copy["special_capabilities"] = p_caps if typeof(p_caps) == TYPE_DICTIONARY else {}
		campaign_nations.append(cn_copy)
		campaign_nations_by_slug[String(cn["slug"])] = cn_copy

	for csn in payload.get("campaign_story_nodes", []):
		var csn_copy: Dictionary = csn.duplicate()
		campaign_story_nodes.append(csn_copy)
		campaign_story_nodes_by_slug[String(csn["slug"])] = csn_copy

	for cse in payload.get("campaign_story_edges", []):
		var cse_copy: Dictionary = cse.duplicate()
		campaign_story_edges.append(cse_copy)
		var from_s := String(cse.get("from_node_slug", ""))
		if not campaign_story_edges_by_from_node.has(from_s):
			campaign_story_edges_by_from_node[from_s] = []
		campaign_story_edges_by_from_node[from_s].append(cse_copy)

	reload_news_videos_manifest()
	is_loaded = true


func reload_news_videos_manifest() -> void:
	news_video_clips.clear()
	news_video_by_slug.clear()
	news_video_by_trigger.clear()
	const NEWS_MANIFEST_PATH := "res://data/news_videos_manifest.json"
	var parsed = null
	if ResourceLoader.exists(NEWS_MANIFEST_PATH):
		var json_res = load(NEWS_MANIFEST_PATH)
		if json_res != null and "data" in json_res and typeof(json_res.data) == TYPE_DICTIONARY:
			parsed = json_res.data
	if parsed == null and FileAccess.file_exists(NEWS_MANIFEST_PATH):
		var raw_json := FileAccess.get_file_as_string(NEWS_MANIFEST_PATH)
		if not raw_json.is_empty():
			parsed = JSON.parse_string(raw_json)
	if typeof(parsed) == TYPE_DICTIONARY:
		for c in parsed.get("clips", []):
			if typeof(c) == TYPE_DICTIONARY:
				var c_copy: Dictionary = c.duplicate(true)
				var slug := String(c_copy.get("slug", ""))
				var trig := String(c_copy.get("event_trigger", ""))
				news_video_clips.append(c_copy)
				if not slug.is_empty():
					news_video_by_slug[slug] = c_copy
				if not trig.is_empty():
					news_video_by_trigger[trig] = c_copy


func get_news_video_clip(slug_or_trigger: String) -> Dictionary:
	if news_video_clips.is_empty():
		reload_news_videos_manifest()
	if news_video_by_slug.has(slug_or_trigger):
		return news_video_by_slug[slug_or_trigger]
	if news_video_by_trigger.has(slug_or_trigger):
		return news_video_by_trigger[slug_or_trigger]
	if not news_video_clips.is_empty():
		return news_video_clips[0]
	return {}


func get_news_video_frame_textures(slug: String) -> Array[Texture2D]:
	if _news_frames_cache.has(slug):
		return _news_frames_cache[slug]
	var clip: Dictionary = get_news_video_clip(slug)
	var frames: Array[Texture2D] = []
	if clip.is_empty():
		return frames
	var sheet_path := String(clip.get("sheet_res_path", "res://assets/videos/news/%s_sheet.jpg" % slug))
	var sheet_tex: Texture2D = get_wiki_photo_texture(sheet_path)
	if sheet_tex == null:
		return frames
	var cols: int = maxi(1, int(clip.get("sheet_cols", 6)))
	var rows: int = maxi(1, int(clip.get("sheet_rows", 4)))
	var total_f: int = maxi(1, int(clip.get("sheet_frames", cols * rows)))
	var fw: float = float(sheet_tex.get_width()) / float(cols)
	var fh: float = float(sheet_tex.get_height()) / float(rows)
	for idx in range(total_f):
		var col := idx % cols
		var row := idx / cols
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_tex
		atlas.region = Rect2(col * fw, row * fh, fw, fh)
		frames.append(atlas)
	_news_frames_cache[slug] = frames
	return frames


func get_sovereign_nations_for_theater(theater_slug: String) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for sn in sovereign_nations:
		if String(sn.get("theater_slug", "")) == theater_slug:
			res.append(sn.duplicate(true))
	return res


func get_theater(theater_slug: String) -> Dictionary:
	return theaters_by_slug.get(theater_slug, {})


func get_sites_for_theater(theater_slug: String) -> Array[Dictionary]:
	var t_info: Dictionary = theaters_by_slug.get(theater_slug, {})
	var target_tid: int = int(t_info.get("theater_id", 1))
	var res: Array[Dictionary] = []
	for st in theater_sites:
		if int(st.get("theater_id", 1)) == target_tid:
			res.append(st.duplicate(true))
	return res


func get_platform(platform_id: int) -> Dictionary:
	if platform_id > 0 and platform_id < platforms_by_id.size():
		return platforms_by_id[platform_id]
	return platforms_by_id[0]


func get_platform_by_slug(slug: String) -> Dictionary:
	var pid: int = int(platform_id_by_slug.get(slug, 0))
	return get_platform(pid)


func get_platform_id(slug: String) -> int:
	return int(platform_id_by_slug.get(slug, 0))


func get_weapon(weapon_id: int) -> Dictionary:
	if weapon_id > 0 and weapon_id < weapons_by_id.size():
		return weapons_by_id[weapon_id]
	return weapons_by_id[0]


func get_weapon_by_slug(slug: String) -> Dictionary:
	var wid: int = int(weapon_id_by_slug.get(slug, 0))
	return get_weapon(wid)


func get_weapon_id(slug: String) -> int:
	return int(weapon_id_by_slug.get(slug, 0))


func get_sensor(sensor_id: int) -> Dictionary:
	if sensor_id > 0 and sensor_id < sensors_by_id.size():
		return sensors_by_id[sensor_id]
	return sensors_by_id[0]


func get_wiki_photo_texture(image_res_path: String) -> Texture2D:
	if image_res_path == "":
		return null
	if _photo_cache.has(image_res_path):
		return _photo_cache[image_res_path]

	var tex: Texture2D = null
	if ResourceLoader.exists(image_res_path):
		var res = load(image_res_path)
		if res is Texture2D:
			tex = res
		elif res is Image:
			tex = ImageTexture.create_from_image(res)
	if tex == null and not OS.has_feature("android"):
		var global_path := ProjectSettings.globalize_path(image_res_path)
		var img := Image.new()
		if FileAccess.file_exists(global_path) and img.load(global_path) == OK and not img.is_empty():
			tex = ImageTexture.create_from_image(img)

	if tex != null:
		_photo_cache[image_res_path] = tex
	return tex


func get_campaign_nations() -> Array[Dictionary]:
	return campaign_nations.duplicate(true)


func get_campaign_nation(nation_slug: String) -> Dictionary:
	return campaign_nations_by_slug.get(nation_slug, {})


func get_campaign_story_node(node_slug: String) -> Dictionary:
	return campaign_story_nodes_by_slug.get(node_slug, {})


func get_campaign_story_nodes_for_nation(nation_slug: String) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for n in campaign_story_nodes:
		if String(n.get("nation_slug", "")) == nation_slug:
			res.append(n.duplicate(true))
	return res


func get_campaign_story_edges_from(from_node_slug: String) -> Array[Dictionary]:
	var arr: Array = campaign_story_edges_by_from_node.get(from_node_slug, [])
	var res: Array[Dictionary] = []
	for item in arr:
		if typeof(item) == TYPE_DICTIONARY:
			res.append(item.duplicate(true))
	return res


func get_campaign_edge(from_node_slug: String, outcome: String) -> Dictionary:
	var edges: Array = campaign_story_edges_by_from_node.get(from_node_slug, [])
	for e in edges:
		if typeof(e) == TYPE_DICTIONARY and String(e.get("condition_outcome", "")) == outcome:
			return e.duplicate(true)
	if not edges.is_empty() and typeof(edges[0]) == TYPE_DICTIONARY:
		return edges[0].duplicate(true)
	return {}


class_name NuclearSubmarineSystem
extends RefCounted
## Phase 35: 688(I) Los Angeles / Virginia-Class Nuclear Attack Submarine VR & Desktop Simulation Engine:
## - Links directly to an active `ssn_688i_los_angeles` (or `orca_xluuv`) unit in `WorldState`.
## - Simulates Diving Physics (`0 ft` Surface -> `58 ft` Periscope Depth -> `280 ft` Thermocline -> `950 ft` Deep -> `1,450 ft` Crush Depth),
##   Emergency Main Ballast Tank (`EMBT`) Blow, Telegraph Throttle (`0..33 kts`), Cavitation & Acoustic Stealth (`dB`),
##   Broadband/Narrowband Sonar Waterfall contacts (`sub_sonar_contacts`), Periscope Optics (`360°` bearing, `EO/NVG/FLIR`),
##   4x `Mk 48 ADCAP` Heavyweight Torpedo Tubes, 12x VLS `Tomahawk` Cruise Missile Tubes, and `MOSS` Acoustic Decoys.

const SalvoCombatSystemScript := preload("res://src/sim_core/systems/salvo_combat_system.gd")
const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const THROTTLE_SPEEDS_KTS: Array[float] = [0.0, 5.0, 15.0, 24.0, 33.0]
const THROTTLE_NAMES: Array[String] = [
	"ALL STOP (0 KT)",
	"AHEAD 1/3 (5 KT - SILENT)",
	"AHEAD STANDARD (15 KT)",
	"AHEAD FULL (24 KT)",
	"AHEAD FLANK (33 KT - CAVITATION!)",
]


static func ensure_player_submarine_unit(state: WorldState, sim_db: Node) -> int:
	if state.sub_unit_id >= 0 and state.sub_unit_id < state.unit_count and state.unit_active[state.sub_unit_id] == 1:
		return state.sub_unit_id

	var ssn_pid: int = sim_db.get_platform_id("ssn_688i_los_angeles")
	var orca_pid: int = sim_db.get_platform_id("orca_xluuv")

	# 1. Search for an existing active Blue SSN-688(I) or Orca submarine
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var pid: int = state.unit_platform_id[uid]
			if pid == ssn_pid or pid == orca_pid:
				state.sub_unit_id = uid
				break

	# 2. If none found, spawn USS Cheyenne (SSN-688I) in the central maritime channel facing enemy fleet
	if state.sub_unit_id < 0 or state.sub_unit_id >= state.unit_count or state.unit_active[state.sub_unit_id] == 0:
		var use_pid: int = ssn_pid if ssn_pid > 0 else orca_pid
		if use_pid > 0:
			var pdef: Dictionary = sim_db.get_platform(use_pid)
			var spawn_pos := Vector3(12.0, 0.0, -8.0)
			state.sub_unit_id = state.spawn_unit(WorldState.FACTION_BLUE, use_pid, spawn_pos, WorldState.ECHELON_COMPANY, -1, pdef)

	# 3. Ensure at least one enemy surface warship & one enemy Type 093B submarine are within periscope/sonar range (8–22 km)
	if state.sub_unit_id >= 0:
		var sub_pos: Vector3 = state.unit_pos[state.sub_unit_id]
		var has_near_enemy_ship := false
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				var pid: int = state.unit_platform_id[uid]
				if pid > 0 and pid < sim_db.plat_domain_id.size() and sim_db.plat_domain_id[pid] == 2:
					if sub_pos.distance_to(state.unit_pos[uid]) < 35.0:
						has_near_enemy_ship = true
						break
		if not has_near_enemy_ship:
			var d_pid: int = sim_db.get_platform_id("type_055_renhai")
			var c_pid: int = sim_db.get_platform_id("cns_fujian_cv18")
			var r_sub_pid: int = sim_db.get_platform_id("type_093b_shang_ssn")
			if d_pid > 0:
				state.spawn_unit(WorldState.FACTION_RED, d_pid, sub_pos + Vector3(-11.5, 0.0, -3.5), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(d_pid))
			if c_pid > 0:
				state.spawn_unit(WorldState.FACTION_RED, c_pid, sub_pos + Vector3(-16.0, 0.0, 4.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(c_pid))
			if r_sub_pid > 0:
				state.spawn_unit(WorldState.FACTION_RED, r_sub_pid, sub_pos + Vector3(-14.0, 0.0, -9.0), WorldState.ECHELON_COMPANY, -1, sim_db.get_platform(r_sub_pid))

		update_sonar_contacts(state, sim_db)
		if state.sub_locked_target_uid < 0 and not state.sub_sonar_contacts.is_empty():
			var first_c: Dictionary = state.sub_sonar_contacts[0]
			state.sub_locked_target_uid = int(first_c["uid"])
			state.sub_locked_target_name = String(first_c["name"])
			state.sub_locked_target_range_km = float(first_c["range_km"])
			state.sub_locked_target_bearing_deg = float(first_c["bearing_deg"])
			state.sub_periscope_bearing_deg = state.sub_locked_target_bearing_deg

	return state.sub_unit_id


static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	# Decay 3D torpedo water plumes
	for i in range(state.sub_water_plumes.size() - 1, -1, -1):
		var pl: Dictionary = state.sub_water_plumes[i]
		var ttl: float = float(pl.get("ttl_sec", 0.0)) - dt
		if ttl <= 0.0:
			state.sub_water_plumes.remove_at(i)
		else:
			pl["ttl_sec"] = ttl
			state.sub_water_plumes[i] = pl

	if not state.sub_sim_active and state.sub_unit_id < 0:
		return

	var sub_uid := ensure_player_submarine_unit(state, sim_db)
	if sub_uid < 0 or sub_uid >= state.unit_count or state.unit_active[sub_uid] == 0:
		return

	# 1. Step Depth & Emergency Ballast Blow Physics
	if state.sub_ballast_blow_active:
		state.sub_target_depth_ft = 0.0
		state.sub_depth_ft = maxf(0.0, state.sub_depth_ft - 42.0 * dt)
		state.sub_dive_plane_deg = 22.0
		if state.sub_depth_ft <= 2.0:
			state.sub_ballast_blow_active = false
			state.sub_dive_plane_deg = 0.0
	else:
		var depth_err := state.sub_target_depth_ft - state.sub_depth_ft
		state.sub_dive_plane_deg = clampf(-depth_err * 0.25, -20.0, 20.0)
		var climb_rate := clampf(depth_err * 0.85, -24.0, 24.0)
		state.sub_depth_ft = clampf(state.sub_depth_ft + climb_rate * dt, 0.0, 1450.0)

	# Automatically lower periscope if diving below 75 ft
	if state.sub_depth_ft > 75.0 and state.sub_periscope_raised:
		state.sub_periscope_raised = false

	# 2. Step Speed, Heading, Cavitation & Acoustic Noise Signature (dB)
	var target_kts: float = THROTTLE_SPEEDS_KTS[clampi(state.sub_throttle_notch, 0, THROTTLE_SPEEDS_KTS.size() - 1)]
	state.sub_speed_kts = lerpf(state.sub_speed_kts, target_kts, clampf(dt * 1.5, 0.0, 1.0))

	var hdg_diff := wrapf(state.sub_target_heading_deg - state.sub_heading_deg, -180.0, 180.0)
	var max_turn_deg := 14.0 * dt
	state.sub_heading_deg = fposmod(state.sub_heading_deg + clampf(hdg_diff, -max_turn_deg, max_turn_deg), 360.0)

	state.sub_cavitating = (state.sub_speed_kts > 18.0 and state.sub_depth_ft < 160.0) or state.sub_speed_kts > 27.0
	var base_noise := 84.0 + state.sub_speed_kts * 1.45
	if state.sub_silent_running:
		base_noise -= 14.0
	if state.sub_cavitating:
		base_noise += 38.0
	state.sub_own_noise_db = clampf(base_noise, 72.0, 165.0)

	# 3. Advance the Submarine unit in `WorldState` along its compass heading
	var hdg_rad := deg_to_rad(state.sub_heading_deg - 90.0)
	state.unit_heading_rad[sub_uid] = hdg_rad
	var spd_km_s := maxf(state.sub_speed_kts * 0.000514444, 0.045 if state.sub_throttle_notch > 0 else 0.0)
	var cur_pos: Vector3 = state.unit_pos[sub_uid]
	var next_x := clampf(cur_pos.x + cos(hdg_rad) * spd_km_s * dt, -235.0, 235.0)
	var next_z := clampf(cur_pos.z + sin(hdg_rad) * spd_km_s * dt, -235.0, 235.0)
	state.unit_pos[sub_uid] = Vector3(next_x, 0.0, next_z)
	state.unit_has_waypoint[sub_uid] = 0

	# Below thermocline (280 ft) & not cavitating -> conceal from enemy surface radar/sonar
	if state.sub_depth_ft >= state.sub_thermocline_depth_ft and not state.sub_cavitating:
		state.unit_detected_mask[sub_uid] &= ~2

	update_sonar_contacts(state, sim_db)


static func update_sonar_contacts(state: WorldState, sim_db: Node) -> void:
	state.sub_sonar_contacts.clear()
	if state.sub_unit_id < 0 or state.sub_unit_id >= state.unit_count or state.unit_active[state.sub_unit_id] == 0:
		return
	var sub_pos: Vector3 = state.unit_pos[state.sub_unit_id]
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var flag_sub := int(sim_db.FLAG_UUV_SUB)

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_faction[uid] != WorldState.FACTION_RED or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid: int = state.unit_platform_id[uid]
		if pid <= 0 or pid >= p_dom.size() or p_dom[pid] != 2:
			continue
		var upos: Vector3 = state.unit_pos[uid]
		var dx := upos.x - sub_pos.x
		var dz := upos.z - sub_pos.z
		var dist_km := sqrt(dx * dx + dz * dz)
		if dist_km > 120.0:
			continue
		var brg_deg := fposmod(rad_to_deg(atan2( dz, dx )) + 90.0, 360.0)
		var pdef: Dictionary = sim_db.get_platform(pid)
		var is_sub: bool = (p_flags[pid] & flag_sub) != 0
		var spd_kts := float(pdef.get("cruise_speed_kts", 20.0))
		var noise_db := (96.0 if is_sub else 128.0) - dist_km * 0.45
		state.sub_sonar_contacts.append({
			"uid": uid,
			"name": String(pdef.get("display_name", "OPFOR Vessel")),
			"slug": String(pdef.get("slug", "")),
			"bearing_deg": brg_deg,
			"range_km": dist_km,
			"speed_kts": spd_kts,
			"noise_db": noise_db,
			"is_sub": is_sub,
			"pos_km": upos,
			"hp_ratio": clampf(state.unit_hp[uid] / maxf(1.0, state.unit_max_hp[uid]), 0.0, 1.0),
		})

	state.sub_sonar_contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["range_km"]) < float(b["range_km"])
	)
	if state.sub_sonar_contacts.size() > 12:
		state.sub_sonar_contacts.resize(12)

	# Refresh locked target telemetry if valid
	if state.sub_locked_target_uid >= 0:
		var found := false
		for c in state.sub_sonar_contacts:
			if int(c["uid"]) == state.sub_locked_target_uid:
				state.sub_locked_target_name = String(c["name"])
				state.sub_locked_target_range_km = float(c["range_km"])
				state.sub_locked_target_bearing_deg = float(c["bearing_deg"])
				found = true
				break
		if not found and not state.sub_sonar_contacts.is_empty():
			var c0: Dictionary = state.sub_sonar_contacts[0]
			state.sub_locked_target_uid = int(c0["uid"])
			state.sub_locked_target_name = String(c0["name"])
			state.sub_locked_target_range_km = float(c0["range_km"])
			state.sub_locked_target_bearing_deg = float(c0["bearing_deg"])


static func execute_sub_command(state: WorldState, sim_db: Node, cmd_code: String, param: float = 0.0) -> Dictionary:
	var sub_uid := ensure_player_submarine_unit(state, sim_db)
	if sub_uid < 0:
		return {"ok": false, "reason": "No submarine unit available"}

	match cmd_code:
		"SUB_SET_DEPTH":
			state.sub_ballast_blow_active = false
			state.sub_target_depth_ft = clampf(param, 0.0, 1450.0)
			state.sub_depth_ft = state.sub_target_depth_ft
			if state.sub_depth_ft > 75.0:
				state.sub_periscope_raised = false
			state.sub_status_log = "CONN, DIVING OFFICER: Steady at %.0f ft." % state.sub_depth_ft
			return {"ok": true, "depth_ft": state.sub_depth_ft}

		"SUB_SET_THROTTLE":
			state.sub_throttle_notch = clampi(int(round(param)), 0, THROTTLE_SPEEDS_KTS.size() - 1)
			state.sub_speed_kts = THROTTLE_SPEEDS_KTS[state.sub_throttle_notch]
			state.sub_cavitating = (state.sub_speed_kts > 18.0 and state.sub_depth_ft < 160.0) or state.sub_speed_kts > 27.0
			state.sub_status_log = "CONN, MANEUVERING: Engine Telegraph set to %s." % THROTTLE_NAMES[state.sub_throttle_notch]
			return {"ok": true, "notch": state.sub_throttle_notch, "speed_kts": state.sub_speed_kts}

		"SUB_SET_DEPTH_PERISCOPE":
			state.sub_ballast_blow_active = false
			state.sub_target_depth_ft = 58.0
			state.sub_depth_ft = 58.0
			state.sub_periscope_raised = true
			state.sub_status_log = "CONN, HELM: Steady at Periscope Depth (58 ft). Up Scope!"
			return {"ok": true, "depth_ft": state.sub_depth_ft, "periscope": state.sub_periscope_raised}

		"SUB_SET_DEPTH_THERMOCLINE":
			state.sub_ballast_blow_active = false
			state.sub_target_depth_ft = 420.0
			state.sub_depth_ft = 420.0
			state.sub_periscope_raised = false
			state.sub_status_log = "CONN, DIVING OFFICER: Passing 280 ft Thermal Layer; steady at 420 ft. Masked from surface active sonar!"
			return {"ok": true, "depth_ft": state.sub_depth_ft, "below_thermocline": true}

		"SUB_SET_DEPTH_DEEP":
			state.sub_ballast_blow_active = false
			state.sub_target_depth_ft = 950.0
			state.sub_depth_ft = 950.0
			state.sub_periscope_raised = false
			state.sub_status_log = "CONN, DIVING OFFICER: Deep silent running at 950 ft (Test Depth 1,450 ft). Hull pressure nominal."
			return {"ok": true, "depth_ft": state.sub_depth_ft}

		"SUB_EMERGENCY_BLOW":
			state.sub_ballast_blow_active = true
			state.sub_target_depth_ft = 0.0
			state.sub_depth_ft = 0.0
			state.sub_periscope_raised = true
			state.sub_status_log = "CHIEF OF THE WATCH: EMERGENCY MAIN BALLAST TANK BLOW! Surfacing at maximum angle!"
			return {"ok": true, "depth_ft": state.sub_depth_ft, "surfaced": true}

		"SUB_CYCLE_THROTTLE":
			state.sub_throttle_notch = (state.sub_throttle_notch + 1) % THROTTLE_SPEEDS_KTS.size()
			state.sub_speed_kts = THROTTLE_SPEEDS_KTS[state.sub_throttle_notch]
			state.sub_cavitating = (state.sub_speed_kts > 18.0 and state.sub_depth_ft < 160.0) or state.sub_speed_kts > 27.0
			state.sub_status_log = "CONN, MANEUVERING: Engine Telegraph set to %s." % THROTTLE_NAMES[state.sub_throttle_notch]
			return {"ok": true, "notch": state.sub_throttle_notch, "speed_kts": state.sub_speed_kts}

		"SUB_STEER_HEADING":
			state.sub_target_heading_deg = fposmod(state.sub_target_heading_deg + param, 360.0)
			state.sub_heading_deg = state.sub_target_heading_deg
			state.sub_status_log = "CONN, HELM: Coming to new course %03d°." % int(state.sub_heading_deg)
			return {"ok": true, "heading_deg": state.sub_heading_deg}

		"SUB_TOGGLE_SILENT_RUNNING":
			state.sub_silent_running = not state.sub_silent_running
			if state.sub_silent_running and state.sub_throttle_notch > 1:
				state.sub_throttle_notch = 1
				state.sub_speed_kts = 5.0
			state.sub_status_log = "CONN: Rigged for Silent Running (-14 dB acoustic signature)." if state.sub_silent_running else "CONN: Normal reactor coolant flow restored."
			return {"ok": true, "silent_running": state.sub_silent_running}

		"SUB_TOGGLE_PERISCOPE":
			if state.sub_depth_ft > 75.0:
				state.sub_target_depth_ft = 58.0
				state.sub_depth_ft = 58.0
				state.sub_periscope_raised = true
				state.sub_status_log = "CONN: Ascended to Periscope Depth (58 ft) — Attack Periscope Raised!"
			else:
				state.sub_periscope_raised = not state.sub_periscope_raised
				state.sub_status_log = "CONN: Up Scope!" if state.sub_periscope_raised else "CONN: Down Scope!"
			return {"ok": true, "periscope_raised": state.sub_periscope_raised}

		"SUB_PAN_PERISCOPE":
			state.sub_periscope_bearing_deg = fposmod(state.sub_periscope_bearing_deg + param, 360.0)
			return {"ok": true, "bearing_deg": state.sub_periscope_bearing_deg}

		"SUB_CYCLE_OPTICS":
			state.sub_periscope_flir_mode = (state.sub_periscope_flir_mode + 1) % 3
			state.sub_periscope_zoom_x = 1.0 if state.sub_periscope_zoom_x >= 8.0 else (4.0 if state.sub_periscope_zoom_x < 2.0 else 8.0)
			var mode_names := ["DAYLIGHT EO", "NIGHT-VISION GREEN", "WHITE-HOT FLIR"]
			state.sub_status_log = "PERISCOPE OPTICS: %s // %.0fx Magnification." % [mode_names[state.sub_periscope_flir_mode], state.sub_periscope_zoom_x]
			return {"ok": true, "flir_mode": state.sub_periscope_flir_mode, "zoom_x": state.sub_periscope_zoom_x}

		"SUB_CYCLE_TARGET":
			update_sonar_contacts(state, sim_db)
			if state.sub_sonar_contacts.is_empty():
				return {"ok": false, "reason": "No sonar contacts"}
			var cur_idx := 0
			for i in range(state.sub_sonar_contacts.size()):
				if int(state.sub_sonar_contacts[i]["uid"]) == state.sub_locked_target_uid:
					cur_idx = (i + 1) % state.sub_sonar_contacts.size()
					break
			var tc: Dictionary = state.sub_sonar_contacts[cur_idx]
			state.sub_locked_target_uid = int(tc["uid"])
			state.sub_locked_target_name = String(tc["name"])
			state.sub_locked_target_range_km = float(tc["range_km"])
			state.sub_locked_target_bearing_deg = float(tc["bearing_deg"])
			state.sub_periscope_bearing_deg = state.sub_locked_target_bearing_deg
			state.sub_status_log = "TMA SOLUTION LOCKED: %s — Bearing %03d°, Range %.1f km." % [
				state.sub_locked_target_name, int(state.sub_locked_target_bearing_deg), state.sub_locked_target_range_km
			]
			return {"ok": true, "target_uid": state.sub_locked_target_uid, "target_name": state.sub_locked_target_name}

		"SUB_FIRE_TORPEDO":
			update_sonar_contacts(state, sim_db)
			if state.sub_torpedoes_remaining <= 0:
				return {"ok": false, "reason": "No Mk 48 ADCAP torpedoes remaining"}
			if state.sub_locked_target_uid < 0 and not state.sub_sonar_contacts.is_empty():
				state.sub_locked_target_uid = int(state.sub_sonar_contacts[0]["uid"])
				state.sub_locked_target_name = String(state.sub_sonar_contacts[0]["name"])
			var tid := state.sub_locked_target_uid
			var tpos := state.unit_pos[sub_uid] + Vector3(-12.0, 0.0, 0.0)
			if tid >= 0 and tid < state.unit_count and state.unit_active[tid] == 1:
				tpos = state.unit_pos[tid]
				# Inflict immediate heavy keel-breaking torpedo damage + spawn 120m water geyser plume + launch live munition!
				state.unit_hp[tid] = maxf(0.0, state.unit_hp[tid] - 185.0)
				if state.unit_hp[tid] <= 0.0:
					state.unit_active[tid] = 0
					state.red_units_destroyed += 1
					state.red_ships_lost += 1
					state.sub_ships_sunk_count += 1
			state.sub_torpedoes_remaining -= 1
			state.sub_torpedoes_fired_count += 1
			var tube_idx := (state.sub_torpedoes_fired_count - 1) % 4
			state.sub_torpedo_tubes[tube_idx] = "RELOADING"
			SalvoCombatSystemScript.launch_strike_salvo(state, sim_db, sub_uid, tid, tpos, 1, 1)
			state.sub_water_plumes.append({"pos_km": tpos, "height_m": 125.0, "ttl_sec": 12.0})
			state.sub_status_log = "TORPEDO ROOM: Tube %d FIRED! Mk 48 Mod 7 ADCAP running hot, normal, and straight toward %s!" % [
				tube_idx + 1, state.sub_locked_target_name
			]
			BudgetTechSystemScript.add_escalation(state, sim_db, 4.5,
				"688(I) NUCLEAR SUBMARINE TORPEDO STRIKE: USS Cheyenne fired Mk 48 ADCAP heavyweight torpedo at %s!" % state.sub_locked_target_name,
				"COMSUBPAC PEARL HARBOR: 'Mk 48 ADCAP wire-guided torpedo detonated beneath hostile warship keel!'")
			update_sonar_contacts(state, sim_db)
			return {
				"ok": true,
				"torpedoes_fired": state.sub_torpedoes_fired_count,
				"torpedoes_remaining": state.sub_torpedoes_remaining,
				"ships_sunk": state.sub_ships_sunk_count,
			}

		"SUB_LAUNCH_VLS_TOMAHAWK":
			if state.sub_vls_tomahawks_remaining <= 0:
				return {"ok": false, "reason": "No VLS Tomahawk missiles remaining"}
			var tpos := Vector3(-115.0, 20.0, -25.0)
			if state.sub_locked_target_uid >= 0 and state.sub_locked_target_uid < state.unit_count:
				tpos = state.unit_pos[state.sub_locked_target_uid]
			var launched := SalvoCombatSystemScript.launch_strike_salvo(state, sim_db, sub_uid, state.sub_locked_target_uid, tpos, 2, 2)
			state.sub_vls_tomahawks_remaining = maxi(0, state.sub_vls_tomahawks_remaining - maxi(1, launched))
			state.sub_vls_salvos_fired_count += 1
			state.sub_status_log = "WEAPONS CONTROL: VLS Doors 1–4 Open — UGM-109 Tomahawk / JASSM Cruise Missile Salvo broached ocean surface!"
			BudgetTechSystemScript.add_escalation(state, sim_db, 5.0,
				"SUBMARINE VLS CRUISE MISSILE SALVO: Submerged SSN-688(I) launched VLS Tomahawk land-attack strike package!",
				"USS CHEYENNE CONN: 'VLS capsules broached surface; booster ignition confirmed!'")
			return {
				"ok": true,
				"vls_salvos_fired": state.sub_vls_salvos_fired_count,
				"vls_remaining": state.sub_vls_tomahawks_remaining,
			}

		"SUB_LAUNCH_DECOY":
			if state.sub_decoys_remaining <= 0:
				return {"ok": false, "reason": "No MOSS acoustic decoys remaining"}
			state.sub_decoys_remaining -= 1
			state.sub_decoys_launched_count += 1
			state.unit_detected_mask[sub_uid] &= ~2
			state.sub_status_log = "COUNTERMEASURES: MOSS Acoustic Decoy & Evasive Knuckle deployed! Hostile sonar homing spoofed!"
			return {
				"ok": true,
				"decoys_launched": state.sub_decoys_launched_count,
				"decoys_remaining": state.sub_decoys_remaining,
			}

	return {"ok": false, "reason": "Unknown submarine command: " + cmd_code}

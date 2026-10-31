class_name SubterraneanTunnelSystem
extends RefCounted
## Phase 27: Subterranean Underground Tunnel Networks, Deep Hardened Mountain Bunkers,
## Seismic Ground-Penetrating Radar (GPR), Bunker-Buster (`GBU-57 MOP`) Strikes & Robot Dog Tunnel Breach Assaults.

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const OP_TUNNEL_GPR_SCAN := "TUNNEL_GPR_SCAN"
const OP_BUNKER_BUSTER_MOP := "BUNKER_BUSTER_MOP"
const OP_ROBOT_DOG_TUNNEL_BREACH := "ROBOT_DOG_TUNNEL_BREACH"


static func seed_theater_tunnel_complexes(state: WorldState) -> void:
	state.tunnel_complexes.clear()
	state.gpr_seismic_scans_count = 0
	state.bunker_buster_strikes_count = 0
	state.tunnel_breach_assaults_count = 0
	state.tunnels_collapsed_count = 0
	state.tunnels_captured_count = 0

	var defs := _get_theater_tunnel_defs(state.active_theater_slug)
	for i in range(defs.size()):
		var d: Dictionary = defs[i]
		var pa: Vector2 = d["portal_a"]
		var pb: Vector2 = d["portal_b"]
		var ya := maxf(2.0, state.get_terrain_elevation_m(pa.x, pa.y))
		var yb := maxf(2.0, state.get_terrain_elevation_m(pb.x, pb.y))
		var fac := int(d["faction"])
		state.tunnel_complexes.append({
			"id": i,
			"name": String(d["name"]),
			"faction_owner": fac,
			"portal_a_km": Vector3(pa.x, ya, pa.y),
			"portal_b_km": Vector3(pb.x, yb, pb.y),
			"depth_m": float(d.get("depth_m", 280.0)),
			"integrity_pct": 100.0,
			"discovered_by_blue": (fac == WorldState.FACTION_BLUE or i == 0),
			"collapsed": false,
			"units_sheltered": 0,
		})


static func _get_theater_tunnel_defs(t_slug: String) -> Array[Dictionary]:
	if t_slug.find("korea") != -1:
		return [
			{"name": "KPA 3rd Infiltration Tunnel (Kaesong-Panmunjom DMZ)", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-45.0, -35.0), "portal_b": Vector2(-15.0, 22.0), "depth_m": 145.0},
			{"name": "KPA 4th Eastern Sector Tunnel (Punchbowl Ridge)", "faction": WorldState.FACTION_RED, "portal_a": Vector2(65.0, -42.0), "portal_b": Vector2(58.0, 18.0), "depth_m": 180.0},
			{"name": "Pyongyang Moranbong Deep Underground Metro Citadel", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-95.0, -145.0), "portal_b": Vector2(-65.0, -115.0), "depth_m": 320.0},
			{"name": "ROK Capital Defense B-1 Subterranean Bunker (Seoul)", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-18.0, 68.0), "portal_b": Vector2(15.0, 92.0), "depth_m": 260.0},
		]
	elif t_slug.find("hormuz") != -1:
		return [
			{"name": "IRGC Hajjiabad Underground Ballistic Missile City", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-25.0, -135.0), "portal_b": Vector2(15.0, -85.0), "depth_m": 350.0},
			{"name": "IRGC Qeshm Island Subterranean Fast-Attack Naval Caverns", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-38.0, -45.0), "portal_b": Vector2(8.0, -28.0), "depth_m": 160.0},
			{"name": "Bandar Abbas Kuh-e Geno Hardened Mountain Silo Complex", "faction": WorldState.FACTION_RED, "portal_a": Vector2(35.0, -95.0), "portal_b": Vector2(75.0, -60.0), "depth_m": 390.0},
			{"name": "Khasab Musandam Coalition Underground Radar Vault", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-12.0, 48.0), "portal_b": Vector2(18.0, 75.0), "depth_m": 210.0},
		]
	elif t_slug.find("ukraine") != -1 or t_slug.find("donbas") != -1:
		return [
			{"name": "Soledar-Bakhmut Subterranean Salt Mine Gallery (280m Deep)", "faction": WorldState.FACTION_RED, "portal_a": Vector2(38.0, -28.0), "portal_b": Vector2(8.0, -15.0), "depth_m": 280.0},
			{"name": "Azovstal Deep Underground Metallurgical Bunker Network", "faction": WorldState.FACTION_RED, "portal_a": Vector2(42.0, 88.0), "portal_b": Vector2(72.0, 98.0), "depth_m": 195.0},
			{"name": "Sevastopol Object-825GTS Underground Submarine Base (Balaklava)", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-35.0, 175.0), "portal_b": Vector2(5.0, 185.0), "depth_m": 240.0},
			{"name": "ZSU Dnipro-Carpathian Underground C4ISR & Drone Assembly Vault", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-95.0, -25.0), "portal_b": Vector2(-55.0, 5.0), "depth_m": 220.0},
		]
	elif t_slug.find("baltic") != -1 or t_slug.find("suwalki") != -1:
		return [
			{"name": "Kaliningrad Kolosovka Subterranean Nuclear & Iskander Vault", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-145.0, -95.0), "portal_b": Vector2(-95.0, -65.0), "depth_m": 250.0},
			{"name": "Grodno-Suwalki Cross-Border Forest Infiltration Tunnel", "faction": WorldState.FACTION_RED, "portal_a": Vector2(45.0, 35.0), "portal_b": Vector2(-12.0, 18.0), "depth_m": 120.0},
			{"name": "NATO Suwalki Hardened Subterranean Command & Ammo Depot", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-45.0, 55.0), "portal_b": Vector2(-15.0, 85.0), "depth_m": 210.0},
		]
	elif t_slug.find("himalaya") != -1 or t_slug.find("lac") != -1:
		return [
			{"name": "PLA Aksai Chin Pangong Subterranean Mountain Garrison", "faction": WorldState.FACTION_RED, "portal_a": Vector2(75.0, -55.0), "portal_b": Vector2(28.0, -18.0), "depth_m": 420.0},
			{"name": "PLA Hotan-Rutog Deep Underground TEL Tunnel Gallery", "faction": WorldState.FACTION_RED, "portal_a": Vector2(135.0, -115.0), "portal_b": Vector2(95.0, -75.0), "depth_m": 460.0},
			{"name": "India Atal-Zoji La All-Weather Strategic Himalayan Tunnel", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-115.0, 85.0), "portal_b": Vector2(-55.0, 35.0), "depth_m": 380.0},
		]
	elif t_slug.find("mexico") != -1 or t_slug.find("rio_grande") != -1:
		return [
			{"name": "Reynosa-McAllen Cross-Border Reinforced Smuggling & Tactical Tunnel", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-25.0, 32.0), "portal_b": Vector2(-18.0, -18.0), "depth_m": 95.0},
			{"name": "Sierra Madre Oriental Hardened Mountain Redoubt (Monterrey)", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-75.0, 125.0), "portal_b": Vector2(-35.0, 85.0), "depth_m": 310.0},
			{"name": "NORTHCOM Fort Cavazos Underground C4ISR Vault", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(-45.0, -135.0), "portal_b": Vector2(-10.0, -95.0), "depth_m": 220.0},
		]
	# Default: Taiwan Strait (`strait_theater`)
	return [
		{"name": "ROC Air Force Chiashan Underground Mountain Airbase (Hualien)", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(162.0, -18.0), "portal_b": Vector2(142.0, 12.0), "depth_m": 380.0},
		{"name": "ROC Chihhang Underground Fighter Cavern (Taitung)", "faction": WorldState.FACTION_BLUE, "portal_a": Vector2(148.0, 68.0), "portal_b": Vector2(125.0, 92.0), "depth_m": 340.0},
		{"name": "PLA Fujian Longtian Subterranean DF-17 Missile & UCAV Gallery", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-135.0, -45.0), "portal_b": Vector2(-92.0, -18.0), "depth_m": 310.0},
		{"name": "PLA Xiamen-Quanzhou Underground Amphibious Staging Complex", "faction": WorldState.FACTION_RED, "portal_a": Vector2(-155.0, 35.0), "portal_b": Vector2(-108.0, 62.0), "depth_m": 260.0},
	]


static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	if dt <= 0.0:
		return
	if state.tunnel_complexes.is_empty():
		seed_theater_tunnel_complexes(state)

	# Periodically count sheltered units near intact tunnel portals & allow subterranean ammo/HP regeneration
	if (state.tick_id % 10) != 0:
		return

	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var max_pid: int = p_dom.size()
	for tc in state.tunnel_complexes:
		if bool(tc.get("collapsed", false)):
			tc["units_sheltered"] = 0
			continue
		var fac_owner := int(tc.get("faction_owner", WorldState.FACTION_RED))
		var pa: Vector3 = tc["portal_a_km"]
		var pb: Vector3 = tc["portal_b_km"]
		var sheltered := 0
		var r_sq := 22.0 * 22.0
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == fac_owner and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				var pid := state.unit_platform_id[uid]
				if pid > 0 and pid < max_pid and p_dom[pid] != 2:
					var up := state.unit_pos[uid]
					var da_sq := (up.x - pa.x) * (up.x - pa.x) + (up.z - pa.z) * (up.z - pa.z)
					var db_sq := (up.x - pb.x) * (up.x - pb.x) + (up.z - pb.z) * (up.z - pb.z)
					if da_sq <= r_sq or db_sq <= r_sq:
						sheltered += 1
						# Units sheltered inside hardened underground mountain galleries slowly repair HP
						state.unit_hp[uid] = minf(state.unit_max_hp[uid], state.unit_hp[uid] + 1.5)
		tc["units_sheltered"] = sheltered


## Executes a Phase 27 Subterranean Counter-Tunnel Operation (`[F8]` hotkey / Tab 8):
## - `TUNNEL_GPR_SCAN`: Ground-Penetrating Radar & Acoustic Seismic Scan (reveals all hidden OPFOR underground complexes).
## - `BUNKER_BUSTER_MOP`: B-21 Raider / F-15E `GBU-57A/B Massive Ordnance Penetrator` earth-penetrating strike (collapses an OPFOR tunnel complex).
## - `ROBOT_DOG_TUNNEL_BREACH`: Autonomous Quadruped Robot Dog (`Vision 60 Q-UGV`) + Special Forces subterranean breach assault (captures an OPFOR tunnel complex intact!).
static func execute_tunnel_operation(state: WorldState, sim_db: Node, op_code: String, target_tunnel_id: int = -1) -> Dictionary:
	if state.tunnel_complexes.is_empty():
		seed_theater_tunnel_complexes(state)

	if op_code == OP_TUNNEL_GPR_SCAN:
		state.gpr_seismic_scans_count += 1
		var newly_discovered := 0
		for tc in state.tunnel_complexes:
			if not bool(tc.get("discovered_by_blue", false)):
				tc["discovered_by_blue"] = true
				newly_discovered += 1
			# Also reveal any OPFOR units hiding near the tunnel portals
			var pa: Vector3 = tc["portal_a_km"]
			var pb: Vector3 = tc["portal_b_km"]
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED:
					var up := state.unit_pos[uid]
					if Vector2(up.x, up.z).distance_to(Vector2(pa.x, pa.z)) <= 35.0 or Vector2(up.x, up.z).distance_to(Vector2(pb.x, pb.z)) <= 35.0:
						state.unit_detected_mask[uid] |= 1
		BudgetTechSystemScript.add_escalation(state, sim_db, 2.0,
			"SEISMIC GPR & ACOUSTIC TUNNEL SCAN COMPLETE: Mapped %d subterranean mountain galleries & DMZ infiltration tunnels." % state.tunnel_complexes.size(),
			"NGA / GEOINT SUBTERRANEAN DESK: 'Synthetic aperture radar and seismic acoustic arrays have pinpointed OPFOR underground portals.'")
		return {
			"ok": true,
			"op_code": op_code,
			"newly_discovered": newly_discovered,
			"total_tunnels": state.tunnel_complexes.size(),
		}

	# Select target OPFOR tunnel complex
	var target_tc: Dictionary = {}
	for tc in state.tunnel_complexes:
		if int(tc.get("id", -1)) == target_tunnel_id:
			target_tc = tc
			break
	if target_tc.is_empty():
		for tc in state.tunnel_complexes:
			if int(tc.get("faction_owner", WorldState.FACTION_RED)) == WorldState.FACTION_RED and not bool(tc.get("collapsed", false)):
				target_tc = tc
				break
	if target_tc.is_empty() and not state.tunnel_complexes.is_empty():
		target_tc = state.tunnel_complexes[0]

	var t_name := String(target_tc.get("name", "Subterranean Complex"))
	var pa: Vector3 = target_tc.get("portal_a_km", Vector3.ZERO)
	var pb: Vector3 = target_tc.get("portal_b_km", Vector3.ZERO)
	var mid_p := (pa + pb) * 0.5
	target_tc["discovered_by_blue"] = true

	if op_code == OP_BUNKER_BUSTER_MOP:
		state.bunker_buster_strikes_count += 1
		var prev_int := float(target_tc.get("integrity_pct", 100.0))
		var new_int := maxf(0.0, prev_int - 65.0)
		target_tc["integrity_pct"] = new_int
		# Spawn a visible 3D earth-penetrating hypersonic/MOP munition toward the tunnel portal
		state.spawn_munition(WorldState.FACTION_BLUE, 1, 0, -1, Vector3(pa.x + 45.0, 14200.0, pa.z + 25.0), pa, "LOFTED_BALLISTIC")
		state.inject_war_destruction(pa.x, pa.z, 14.0, 0.75)
		state.inject_war_destruction(pb.x, pb.z, 14.0, 0.65)
		state.recent_impacts.append({"pos_km": pa, "ttl": 2.2, "is_intercept": false})
		# Damage OPFOR units sheltered inside the collapsing underground cavern
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED:
				var up := state.unit_pos[uid]
				if Vector2(up.x, up.z).distance_to(Vector2(pa.x, pa.z)) <= 24.0 or Vector2(up.x, up.z).distance_to(Vector2(pb.x, pb.z)) <= 24.0:
					state.unit_hp[uid] = maxf(10.0, state.unit_hp[uid] * 0.42)
		if new_int <= 35.0 and not bool(target_tc.get("collapsed", false)):
			target_tc["collapsed"] = true
			target_tc["integrity_pct"] = 0.0
			state.tunnels_collapsed_count += 1
		BudgetTechSystemScript.add_escalation(state, sim_db, 9.0,
			"GBU-57 MOP BUNKER-BUSTER STRIKE: 30,000-lb earth-penetrating ordnance struck '%s' (Integrity: %d%%, Collapsed: %s)!" % [
				t_name, int(target_tc["integrity_pct"]), str(target_tc["collapsed"])
			],
			"USSTRATCOM B-21 RAIDER STRIKE DESK: 'Seismic sensors confirm deep subterranean cavern collapse at target portal.'")
		return {
			"ok": true,
			"op_code": op_code,
			"tunnel_name": t_name,
			"integrity_pct": float(target_tc["integrity_pct"]),
			"collapsed": bool(target_tc["collapsed"]),
		}

	# Default / OP_ROBOT_DOG_TUNNEL_BREACH: Autonomous Lidar Robot Dog (`Vision 60 Q-UGV`) + SpecOps Subterranean Breach
	state.tunnel_breach_assaults_count += 1
	target_tc["faction_owner"] = WorldState.FACTION_BLUE
	target_tc["collapsed"] = false
	target_tc["integrity_pct"] = maxf(65.0, float(target_tc.get("integrity_pct", 100.0)))
	state.tunnels_captured_count += 1
	state.blue_budget_available_musd += 250.0 # Captured underground missile/munitions stockpile!
	state.recent_impacts.append({"pos_km": mid_p, "ttl": 2.0, "is_intercept": true})
	BudgetTechSystemScript.add_escalation(state, sim_db, 6.0,
		"ROBOT DOG & SPECOPS TUNNEL BREACH: Vision 60 Q-UGV packs cleared & captured '%s' intact (+$250M Captured Underground Arsenal)!" % t_name,
		"JSOC / AUTONOMOUS BREACH TEAM: '3D Lidar quadruped packs neutralized subterranean defenders inside GPS-denied tunnel galleries.'")
	return {
		"ok": true,
		"op_code": op_code,
		"tunnel_name": t_name,
		"captured": true,
		"tunnels_captured_count": state.tunnels_captured_count,
	}


## US-10.2: Evaluates hardened subterranean damage mitigation (85% kinetic mitigation vs 100% MOP penetration)
static func apply_subterranean_bunker_strike(
	state: WorldState,
	target_complex_id: int,
	is_bunker_buster: bool,
	raw_damage: float
) -> Dictionary:
	if target_complex_id < 0 or target_complex_id >= state.tunnel_complexes.size():
		return {"error": "Invalid complex ID"}

	var tc: Dictionary = state.tunnel_complexes[target_complex_id]
	var effective_damage := raw_damage
	var mitigation_pct := 0.0

	if not is_bunker_buster:
		mitigation_pct = 85.0
		effective_damage = raw_damage * 0.15 # 85% kinetic shielding mitigation
	else:
		state.bunker_shock_tremor = maxf(state.bunker_shock_tremor, 0.65)

	var cur_integrity: float = float(tc.get("integrity_pct", 100.0))
	var new_integrity: float = maxf(0.0, cur_integrity - effective_damage)
	tc["integrity_pct"] = new_integrity

	var collapsed := false
	if new_integrity <= 0.0 and not bool(tc.get("collapsed", false)):
		tc["collapsed"] = true
		collapsed = true
		state.tunnels_collapsed_count += 1

	state.sim_events_queue.append({
		"type": "SUBTERRANEAN_STRIKE_RESOLVED",
		"complex_id": target_complex_id,
		"is_bunker_buster": is_bunker_buster,
		"effective_damage": effective_damage,
		"integrity_pct": new_integrity,
		"collapsed": collapsed
	})

	return {
		"complex_id": target_complex_id,
		"is_bunker_buster": is_bunker_buster,
		"effective_damage": effective_damage,
		"mitigation_pct": mitigation_pct,
		"integrity_pct": new_integrity,
		"collapsed": collapsed
	}

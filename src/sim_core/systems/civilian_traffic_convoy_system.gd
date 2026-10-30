class_name CivilianTrafficConvoySystem
extends RefCounted
## Phase 26: Civilian Highway Traffic, Refugee Evacuation Convoy Columns, Overland MSR Supply Trucks & Maritime Shipping Lanes.
## Spawns and steps up to 48 live 3D highway convoys & maritime cargo tankers along `road_segments_km` and strategic sea lanes.
## Supports declaring Official Humanitarian Evacuation Corridors (`declare_humanitarian_corridor`) and Naval Maritime Interdiction (`execute_maritime_interdiction`).

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")


static func seed_theater_traffic_and_shipping(state: WorldState) -> void:
	state.convoy_count = 0
	state.humanitarian_corridor_active = false
	state.humanitarian_corridor_timer_sec = 0.0
	state.evacuated_convoys_completed_count = 0
	state.maritime_tankers_interdicted_count = 0
	state.collateral_convoy_hits_count = 0

	# 1. Spawn Highway Commuter Traffic, Refugee Evacuation Buses/Cars & Military MSR Supply Trucks along `road_segments_km`
	var seg_cnt := state.road_segments_km.size()
	for i in range(seg_cnt):
		if state.convoy_count >= WorldState.MAX_TRAFFIC_CONVOYS - 10:
			break
		var seg: Vector4 = state.road_segments_km[i]
		var a_km := Vector2(seg.x, seg.y)
		var b_km := Vector2(seg.z, seg.w)
		if a_km.distance_to(b_km) < 8.0:
			continue

		# Spawn 2 convoys per highway corridor (1 Civilian/Evac + 1 Military MSR Supply or Commuter)
		for k in range(2):
			if state.convoy_count >= WorldState.MAX_TRAFFIC_CONVOYS - 8:
				break
			var c_type := WorldState.CONVOY_CIVILIAN_COMMUTER
			if (i + k) % 3 == 1:
				c_type = WorldState.CONVOY_REFUGEE_EVAC
			elif (i + k) % 3 == 2:
				c_type = WorldState.CONVOY_MILITARY_SUPPLY
			var fac := WorldState.FACTION_BLUE if a_km.x >= 0.0 else WorldState.FACTION_RED
			var init_prog := fmod(float(i * 19 + k * 47) * 0.07, 0.92)
			_spawn_convoy(state, c_type, fac, a_km, b_km, init_prog, 1.0 if k == 0 else -1.0)

	# 2. Spawn Commercial LNG / Oil Tankers & Container Ships along Theater Maritime Shipping Lanes
	var sea_lanes := _get_theater_shipping_lanes(state.active_theater_slug)
	for s_i in range(sea_lanes.size()):
		if state.convoy_count >= WorldState.MAX_TRAFFIC_CONVOYS:
			break
		var lane: Array = sea_lanes[s_i]
		var sa: Vector2 = lane[0]
		var sb: Vector2 = lane[1]
		var s_fac: int = WorldState.FACTION_RED if (s_i % 2 == 1) else WorldState.FACTION_BLUE
		_spawn_convoy(state, WorldState.CONVOY_MARITIME_TANKER, s_fac, sa, sb, fmod(float(s_i) * 0.23 + 0.15, 0.85), 1.0)


static func _get_theater_shipping_lanes(t_slug: String) -> Array:
	if t_slug.find("hormuz") != -1:
		return [
			[Vector2(-180.0, 20.0), Vector2(180.0, -15.0)],
			[Vector2(175.0, 35.0), Vector2(-170.0, -10.0)],
			[Vector2(-120.0, 45.0), Vector2(160.0, 10.0)],
			[Vector2(140.0, -35.0), Vector2(-140.0, 15.0)],
		]
	elif t_slug.find("ukraine") != -1 or t_slug.find("donbas") != -1:
		return [
			[Vector2(-180.0, 185.0), Vector2(45.0, 195.0)],
			[Vector2(95.0, 180.0), Vector2(-140.0, 190.0)],
			[Vector2(-60.0, 165.0), Vector2(130.0, 175.0)],
		]
	elif t_slug.find("baltic") != -1 or t_slug.find("suwalki") != -1:
		return [
			[Vector2(-190.0, -140.0), Vector2(-65.0, -185.0)],
			[Vector2(-85.0, -175.0), Vector2(-195.0, -95.0)],
		]
	elif t_slug.find("korea") != -1:
		return [
			[Vector2(-185.0, -120.0), Vector2(-165.0, 160.0)],
			[Vector2(175.0, 155.0), Vector2(165.0, -135.0)],
		]
	elif t_slug.find("mexico") != -1:
		return [
			[Vector2(145.0, -165.0), Vector2(185.0, 165.0)],
			[Vector2(190.0, 145.0), Vector2(135.0, -145.0)],
		]
	# Default: Taiwan Strait / Indo-Pacific
	return [
		[Vector2(-35.0, -195.0), Vector2(25.0, 195.0)],
		[Vector2(35.0, 190.0), Vector2(-25.0, -190.0)],
		[Vector2(-55.0, -170.0), Vector2(5.0, 180.0)],
		[Vector2(15.0, 175.0), Vector2(-45.0, -175.0)],
		[Vector2(165.0, -180.0), Vector2(185.0, 175.0)],
		[Vector2(-15.0, 150.0), Vector2(40.0, -160.0)],
	]


static func _spawn_convoy(state: WorldState, c_type: int, fac: int, a_km: Vector2, b_km: Vector2, prog: float, dir_s: float) -> void:
	var cid := state.convoy_count
	if cid >= WorldState.MAX_TRAFFIC_CONVOYS:
		return
	state.convoy_count += 1
	var sy := 0.5 if c_type == WorldState.CONVOY_MARITIME_TANKER else maxf(2.0, state.get_terrain_elevation_m(a_km.x, a_km.y))
	var ey := 0.5 if c_type == WorldState.CONVOY_MARITIME_TANKER else maxf(2.0, state.get_terrain_elevation_m(b_km.x, b_km.y))
	state.convoy_active[cid] = 1
	state.convoy_type[cid] = c_type
	state.convoy_faction[cid] = fac
	state.convoy_start_km[cid] = Vector3(a_km.x, sy, a_km.y)
	state.convoy_end_km[cid] = Vector3(b_km.x, ey, b_km.y)
	state.convoy_progress[cid] = clampf(prog, 0.05, 0.95)
	state.convoy_dir_sign[cid] = dir_s
	# Scaled visual-tactical speeds so highway traffic and sea tankers visibly flow across the War Table
	var spd := 0.16
	if c_type == WorldState.CONVOY_REFUGEE_EVAC:
		spd = 0.22
	elif c_type == WorldState.CONVOY_MILITARY_SUPPLY:
		spd = 0.20
	elif c_type == WorldState.CONVOY_MARITIME_TANKER:
		spd = 0.12
	state.convoy_speed_km_s[cid] = spd
	var p3 := state.convoy_start_km[cid].lerp(state.convoy_end_km[cid], state.convoy_progress[cid])
	if c_type != WorldState.CONVOY_MARITIME_TANKER:
		p3.y = maxf(2.0, state.get_terrain_elevation_m(p3.x, p3.z))
	state.convoy_pos_km[cid] = p3
	state.convoy_heading_rad[cid] = atan2((b_km.y - a_km.y) * dir_s, (b_km.x - a_km.x) * dir_s)


static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	if dt <= 0.0:
		return
	if state.convoy_count == 0 and state.road_segments_km.size() > 0:
		seed_theater_traffic_and_shipping(state)

	if state.humanitarian_corridor_timer_sec > 0.0:
		state.humanitarian_corridor_timer_sec = maxf(0.0, state.humanitarian_corridor_timer_sec - dt)
		state.humanitarian_corridor_active = (state.humanitarian_corridor_timer_sec > 0.0)

	var corridor_mult := 1.65 if state.humanitarian_corridor_active else 1.0
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var max_pid: int = p_dom.size()

	for cid in range(state.convoy_count):
		if state.convoy_active[cid] == 0:
			continue
		var c_type := state.convoy_type[cid]
		var cur_p := state.convoy_pos_km[cid]

		# Check if highway bridge or road cell under overland convoy is heavily bombed (`destruction_level >= 0.55`)
		if c_type != WorldState.CONVOY_MARITIME_TANKER:
			var destr := state.sample_destruction_level(cur_p.x, cur_p.z)
			if destr >= 0.55:
				# Reverse direction at blown bridge/cratered highway!
				state.convoy_dir_sign[cid] = -state.convoy_dir_sign[cid]

		var s_km := state.convoy_start_km[cid]
		var e_km := state.convoy_end_km[cid]
		var dist_len := maxf(2.0, Vector2(s_km.x, s_km.z).distance_to(Vector2(e_km.x, e_km.z)))
		var spd := state.convoy_speed_km_s[cid]
		if c_type == WorldState.CONVOY_REFUGEE_EVAC or c_type == WorldState.CONVOY_CIVILIAN_COMMUTER:
			spd *= corridor_mult

		var next_prog := state.convoy_progress[cid] + state.convoy_dir_sign[cid] * (spd * dt) / dist_len
		if next_prog >= 1.0:
			next_prog = 1.0
			state.convoy_dir_sign[cid] = -1.0
			if c_type == WorldState.CONVOY_REFUGEE_EVAC:
				state.evacuated_convoys_completed_count += 1
				state.total_displaced_civilians += 12500.0
		elif next_prog <= 0.0:
			next_prog = 0.0
			state.convoy_dir_sign[cid] = 1.0
			if c_type == WorldState.CONVOY_REFUGEE_EVAC:
				state.evacuated_convoys_completed_count += 1
				state.total_displaced_civilians += 12500.0

		state.convoy_progress[cid] = next_prog
		var nx := lerpf(s_km.x, e_km.x, next_prog)
		var nz := lerpf(s_km.z, e_km.z, next_prog)
		var ny := 0.5 if c_type == WorldState.CONVOY_MARITIME_TANKER else maxf(2.0, state.get_terrain_elevation_m(nx, nz))
		state.convoy_pos_km[cid] = Vector3(nx, ny, nz)
		state.convoy_heading_rad[cid] = atan2((e_km.z - s_km.z) * state.convoy_dir_sign[cid], (e_km.x - s_km.x) * state.convoy_dir_sign[cid])

		# Military Supply Truck Convoys resupply nearby friendly ground units within 16 km
		if c_type == WorldState.CONVOY_MILITARY_SUPPLY and (state.tick_id & 15) == 0:
			var c_fac := state.convoy_faction[cid]
			var r_sq := 16.0 * 16.0
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == c_fac and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid > 0 and pid < max_pid and p_dom[pid] == 0:
						var up := state.unit_pos[uid]
						if (up.x - nx) * (up.x - nx) + (up.z - nz) * (up.z - nz) <= r_sq:
							var p_def: Dictionary = sim_db.platforms_by_id[pid]
							var max_a1: int = int(p_def.get("weapon_1_qty", 4))
							if state.unit_ammo_1[uid] < max_a1:
								state.unit_ammo_1[uid] = max_a1
								state.resupply_events_count += 1


## Declares an Official UN/Coalition Humanitarian Evacuation Corridor (`[F7]` hotkey / Tab 8):
## Boosts civilian/refugee highway evacuation speed by +65% for 90s, awards +$200M UN humanitarian grant, and lowers escalation by -10%.
static func declare_humanitarian_corridor(state: WorldState, sim_db: Node) -> Dictionary:
	state.humanitarian_corridor_active = true
	state.humanitarian_corridor_timer_sec = 90.0
	state.humanitarian_corridors_declared_count += 1
	state.blue_budget_available_musd += 200.0
	state.total_displaced_civilians += 85000.0
	BudgetTechSystemScript.add_escalation(state, sim_db, -10.0,
		"UN OCHA / HUMANITARIAN CORRIDOR OPENED: Safe civilian highway evacuation lanes established across all cities (+$200M UN Aid, -10% Escalation).",
		"WHITE HOUSE / J9 CIVIL AFFAIRS: 'Protected green-zone highway corridors are active. All coalition strike packages must avoid civilian evacuation routes.'")
	return {
		"ok": true,
		"corridors_declared": state.humanitarian_corridors_declared_count,
		"timer_sec": state.humanitarian_corridor_timer_sec,
		"budget_musd": state.blue_budget_available_musd,
	}


## Executes a Naval Maritime Blockade / Visit-Board-Search-Seizure (VBSS) Interdiction against OPFOR commercial tankers:
## Seizes sanctioned oil/arms cargo (`+$180M` warchest) and reduces OPFOR budget/supply.
static func execute_maritime_interdiction(state: WorldState, sim_db: Node) -> Dictionary:
	var target_cid := -1
	for cid in range(state.convoy_count):
		if state.convoy_active[cid] == 1 and state.convoy_type[cid] == WorldState.CONVOY_MARITIME_TANKER:
			target_cid = cid
			if state.convoy_faction[cid] == WorldState.FACTION_RED:
				break
	if target_cid >= 0:
		state.convoy_faction[target_cid] = WorldState.FACTION_BLUE
	state.maritime_tankers_interdicted_count += 1
	state.blue_budget_available_musd += 180.0
	state.red_budget_available_musd = maxf(0.0, state.red_budget_available_musd - 180.0)
	BudgetTechSystemScript.add_escalation(state, sim_db, 4.0,
		"MARITIME VBSS INTERDICTION: Coalition naval boarding teams seized sanctioned OPFOR tanker cargo in sea lane (+$180M Seized Contraband).",
		"US INDOPACOM / 5TH FLEET MARITIME OPS: 'Sanctioned shadow-fleet tanker boarded and diverted to allied port.'")
	return {
		"ok": true,
		"interdicted_count": state.maritime_tankers_interdicted_count,
		"convoy_id": target_cid,
	}

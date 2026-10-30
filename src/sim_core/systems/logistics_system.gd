class_name LogisticsSystem
extends RefCounted
## Phase 6 Operational Depth:
## - Airborne Fuel Burn (`unit_fuel_km`), KC-46 Pegasus Aerial Refueling Orbits, and Auto-RTB to Friendly Airbases
## - Strategic Airbase Runway Cratering (`crater_timer_sec` prevents refuel/rearm on bombed airbases)
## - Ground Supply Convoys (`hemtt_supply_convoy`) & Forward Operating Base (FOB) Ammo/Drone Resupply

const TANKER_REFUEL_RADIUS_KM := 35.0
const AIRBASE_REFUEL_RADIUS_KM := 18.0
const CONVOY_RESUPPLY_RADIUS_KM := 20.0
const LOW_FUEL_BINGO_RATIO := 0.22


static func step(state: WorldState, sim_db: Node, grid: SpatialHashGrid, dt: float) -> void:
	var platforms: Array = sim_db.platforms_by_id
	var max_pid: int = platforms.size()

	# 1. Tick down runway repair timers on cratered airbases
	for i in range(state.active_sites.size()):
		var st: Dictionary = state.active_sites[i]
		var timer: float = float(st.get("crater_timer_sec", 0.0))
		if timer > 0.0:
			st["crater_timer_sec"] = maxf(0.0, timer - dt)

	# 2. Collect active Tankers (`TANKER`) and Ground Logistics Convoys (`LOGISTICS`)
	var tankers: Array[int] = []
	var convoys: Array[int] = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid: int = state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var p_def: Dictionary = platforms[pid]
		var u_class := String(p_def.get("unit_class", ""))
		if u_class == "TANKER":
			tankers.append(uid)
		elif u_class == "LOGISTICS":
			convoys.append(uid)

	# 3. Process airborne fuel consumption, KC-46 aerial refueling, and Airbase RTB/rearm
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid: int = state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var p_def: Dictionary = platforms[pid]
		var domain := String(p_def.get("domain", "LAND"))
		var u_class := String(p_def.get("unit_class", ""))
		var u_pos: Vector3 = state.unit_pos[uid]
		var u_fac: int = state.unit_faction[uid]

		if domain == "AIR" and u_class != "TANKER":
			# Burn fuel proportional to horizontal distance covered + loiter burn
			var vel_2d := Vector2(state.unit_vel[uid].x, state.unit_vel[uid].z).length()
			var burn_km := maxf(0.15, vel_2d) * dt
			state.unit_fuel_km[uid] = maxf(0.0, state.unit_fuel_km[uid] - burn_km)

			# Check aerial refueling from friendly KC-46 Pegasus Tanker within 35 km
			var refueled_in_air := false
			for t_uid in tankers:
				if state.unit_faction[t_uid] != u_fac:
					continue
				var t_pos: Vector3 = state.unit_pos[t_uid]
				var dist_km := Vector2(u_pos.x, u_pos.z).distance_to(Vector2(t_pos.x, t_pos.z))
				if dist_km <= TANKER_REFUEL_RADIUS_KM and state.unit_fuel_km[uid] < state.unit_max_fuel_km[uid] * 0.92:
					state.unit_fuel_km[uid] = minf(state.unit_max_fuel_km[uid], state.unit_fuel_km[uid] + 140.0 * dt)
					state.refuel_events_count += 1
					refueled_in_air = true
					state.active_beams.append({
						"shooter_pos": t_pos,
						"target_pos": u_pos,
						"is_hpm_cone": false,
						"cone_deg": 0.0,
						"faction": u_fac,
						"ttl": 0.25,
					})
					break

			# Check operational friendly Airbase within 18 km for full refuel + rearm
			if not refueled_in_air:
				var fac_str := "BLUE" if u_fac == WorldState.FACTION_BLUE else "RED"
				for st in state.active_sites:
					if String(st.get("site_type", "")) == "AIRBASE" and String(st.get("faction_owner", "")) == fac_str:
						if float(st.get("crater_timer_sec", 0.0)) <= 0.0:
							var sx := float(st.get("x_km", 0.0))
							var sz := float(st.get("z_km", 0.0))
							if Vector2(u_pos.x, u_pos.z).distance_to(Vector2(sx, sz)) <= AIRBASE_REFUEL_RADIUS_KM:
								if state.unit_fuel_km[uid] < state.unit_max_fuel_km[uid] * 0.95 or state.unit_ammo_1[uid] < int(p_def.get("weapon_1_qty", 4)):
									state.unit_fuel_km[uid] = state.unit_max_fuel_km[uid]
									state.unit_ammo_1[uid] = int(p_def.get("weapon_1_qty", 4))
									state.unit_ammo_2[uid] = int(p_def.get("weapon_2_qty", 2))
									state.refuel_events_count += 1
								break

			# Bingo Fuel (< 22%): auto-route to nearest uncratered friendly Airbase or Tanker
			if state.unit_fuel_km[uid] < state.unit_max_fuel_km[uid] * LOW_FUEL_BINGO_RATIO:
				var rtb_pos := _find_nearest_refuel_point(state, tankers, u_fac, u_pos)
				if rtb_pos != Vector3.ZERO:
					state.unit_target_pos[uid] = Vector3(rtb_pos.x, u_pos.y, rtb_pos.z)
					state.unit_has_waypoint[uid] = 1

		# 4. Ground / SAM / Mech / Robot Dog resupply from friendly HEMTT Supply Convoys
		elif domain == "LAND" and u_class != "LOGISTICS":
			var max_a1: int = int(p_def.get("weapon_1_qty", 4))
			var max_a2: int = int(p_def.get("weapon_2_qty", 2))
			if state.unit_ammo_1[uid] < max_a1 or state.unit_ammo_2[uid] < max_a2:
				for c_uid in convoys:
					if state.unit_faction[c_uid] != u_fac or state.unit_cooldown[c_uid] > 0.0:
						continue
					var c_pos: Vector3 = state.unit_pos[c_uid]
					if Vector2(u_pos.x, u_pos.z).distance_to(Vector2(c_pos.x, c_pos.z)) <= CONVOY_RESUPPLY_RADIUS_KM:
						state.unit_ammo_1[uid] = max_a1
						state.unit_ammo_2[uid] = max_a2
						state.unit_cooldown[c_uid] = 2.0
						state.resupply_events_count += 1
						state.sim_events_queue.append({
							"type": "unit_resupplied",
							"convoy_id": c_uid,
							"unit_id": uid,
							"pos_km": u_pos,
						})
						break


static func _find_nearest_refuel_point(state: WorldState, tankers: Array[int], faction: int, from_pos: Vector3) -> Vector3:
	var best_pos := Vector3.ZERO
	var best_d := 999999.0
	for t_uid in tankers:
		if state.unit_faction[t_uid] == faction and state.unit_active[t_uid] == 1:
			var t_pos: Vector3 = state.unit_pos[t_uid]
			var d := Vector2(from_pos.x, from_pos.z).distance_to(Vector2(t_pos.x, t_pos.z))
			if d < best_d:
				best_d = d
				best_pos = t_pos

	var fac_str := "BLUE" if faction == WorldState.FACTION_BLUE else "RED"
	for st in state.active_sites:
		if String(st.get("site_type", "")) == "AIRBASE" and String(st.get("faction_owner", "")) == fac_str:
			if float(st.get("crater_timer_sec", 0.0)) <= 0.0:
				var sx := float(st.get("x_km", 0.0))
				var sz := float(st.get("z_km", 0.0))
				var d := Vector2(from_pos.x, from_pos.z).distance_to(Vector2(sx, sz))
				if d < best_d:
					best_d = d
					best_pos = Vector3(sx, from_pos.y, sz)
	return best_pos


## Craters any strategic airbase runway within `radius_km` of a heavy missile impact for `duration_sec`.
static func crater_airbase_near(state: WorldState, impact_pos_km: Vector3, radius_km: float = 16.0, duration_sec: float = 90.0) -> int:
	var cratered := 0
	for i in range(state.active_sites.size()):
		var st: Dictionary = state.active_sites[i]
		if String(st.get("site_type", "")) != "AIRBASE":
			continue
		var sx := float(st.get("x_km", 0.0))
		var sz := float(st.get("z_km", 0.0))
		if Vector2(impact_pos_km.x, impact_pos_km.z).distance_to(Vector2(sx, sz)) <= radius_km:
			st["crater_timer_sec"] = maxf(float(st.get("crater_timer_sec", 0.0)), duration_sec)
			st["hp"] = maxf(0.0, float(st.get("hp", 500.0)) - 125.0)
			state.craters_inflicted_count += 1
			cratered += 1
			state.sim_events_queue.append({
				"type": "airbase_cratered",
				"site_name": String(st.get("site_name", "Airbase")),
				"pos_km": Vector3(sx, 0.0, sz),
				"duration_sec": duration_sec,
			})
	return cratered

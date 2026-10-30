class_name CombatEngineeringAirborneSystem
extends RefCounted
## Phase 31: Combat Engineering, Tactical Minefields, AVLB Bridge Rebuilding & Airborne Paratrooper Drops:
## - `AIRBORNE_PARATROOP_DROP`: C-17 / Chinook airborne insertion of Navy SEALs, Tier-1 Snipers & Vision 60 Robot Dogs with 3D descending parachute canopies (`parachute_drops`).
## - `DEPLOY_SMART_MINEFIELD`: FASCAM / Quickstrike scatterable land & naval sea minefields (`minefields`) that slow (`0.35x`) and attrit opposing armor & ships.
## - `ENGINEER_BREACH_AND_REBUILD`: Combat Engineer M1150 Assault Breacher & AVLB Bridge Layer operation that clears enemy minefields, repairs blown river bridges, clears rubble, and re-rails logistics trains.

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const AIRBORNE_PARATROOP_DROP := "AIRBORNE_PARATROOP_DROP"
const DEPLOY_SMART_MINEFIELD := "DEPLOY_SMART_MINEFIELD"
const ENGINEER_BREACH_AND_REBUILD := "ENGINEER_BREACH_AND_REBUILD"


static func seed_theater_minefields(state: WorldState) -> void:
	state.parachute_drops.clear()
	state.minefields.clear()
	# Seed 2 initial OPFOR defensive mine belts along the border/strait chokepoint
	state.minefields.append({
		"pos_km": Vector3(-35.0, 0.0, -20.0),
		"radius_km": 18.0,
		"faction": WorldState.FACTION_RED,
		"domain": "LAND",
		"active": true,
	})
	state.minefields.append({
		"pos_km": Vector3(-12.0, 0.0, 28.0),
		"radius_km": 20.0,
		"faction": WorldState.FACTION_RED,
		"domain": "SEA",
		"active": true,
	})


static func step(state: WorldState, dt: float) -> void:
	# 1. Step descending 3D Paratrooper & Robot Dog parachute drops (1,800m -> terrain surface)
	for i in range(state.parachute_drops.size() - 1, -1, -1):
		var drop: Dictionary = state.parachute_drops[i]
		var uid: int = int(drop.get("unit_id", -1))
		var cur_alt: float = float(drop.get("alt_m", 0.0)) - 220.0 * dt
		if uid >= 0 and uid < state.unit_count and state.unit_active[uid] == 1:
			drop["pos_km"] = state.unit_pos[uid]
		if cur_alt <= 0.0:
			state.parachute_drops.remove_at(i)
		else:
			drop["alt_m"] = cur_alt
			state.parachute_drops[i] = drop

	# 2. Apply active Minefield attrition & slowdown to opposing units entering the minefield radius
	if state.minefields.is_empty():
		return
	for mf in state.minefields:
		if not bool(mf.get("active", false)):
			continue
		var mf_pos: Vector3 = mf["pos_km"]
		var mf_rad_sq: float = float(mf.get("radius_km", 18.0)) ** 2
		var mf_fac: int = int(mf.get("faction", WorldState.FACTION_BLUE))
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY or state.unit_faction[uid] == mf_fac:
				continue
			var upos: Vector3 = state.unit_pos[uid]
			if upos.y > 180.0:
				continue # High-altitude aircraft fly safely above land/sea minefields
			var d_sq := Vector2(upos.x - mf_pos.x, upos.z - mf_pos.z).length_squared()
			if d_sq <= mf_rad_sq:
				state.unit_hp[uid] = maxf(10.0, state.unit_hp[uid] - 1.5 * dt)


static func execute_engineering_or_airborne_op(state: WorldState, sim_db: Node, op_code: String, target_pos_km: Vector3 = Vector3.INF) -> Dictionary:
	var focus_pos := target_pos_km
	if focus_pos == Vector3.INF:
		focus_pos = Vector3(state.sim_focus_center_km.x, 0.0, state.sim_focus_center_km.y)
		if focus_pos.length_squared() < 1.0:
			focus_pos = Vector3(25.0, 0.0, -15.0)

	if op_code == AIRBORNE_PARATROOP_DROP:
		var drop_slugs := ["navy_seal_commando_squad", "tier1_sniper_recon_team", "vision_60_q_ugv"]
		var spawned_uids: Array[int] = []
		for i in range(drop_slugs.size()):
			var slug: String = String(drop_slugs[i])
			var pid: int = sim_db.get_platform_id(slug)
			if pid <= 0:
				continue
			var pdef: Dictionary = sim_db.get_platform(pid)
			var off := Vector3(float(i - 1) * 4.5, 0.0, float(i % 2) * 3.8)
			var drop_pos := focus_pos + off
			drop_pos.y = maxf(0.0, state.get_terrain_elevation_m(drop_pos.x, drop_pos.z)) + 5.0
			var uid := state.spawn_unit(WorldState.FACTION_BLUE, pid, drop_pos, WorldState.ECHELON_COMPANY, -1, pdef)
			if uid >= 0:
				state.unit_target_pos[uid] = drop_pos + Vector3(-16.0, 0.0, 12.0)
				state.unit_has_waypoint[uid] = 1
				spawned_uids.append(uid)
				state.parachute_drops.append({
					"unit_id": uid,
					"pos_km": drop_pos,
					"alt_m": 1650.0 - float(i) * 180.0,
					"faction": WorldState.FACTION_BLUE,
				})
		state.airborne_drops_executed_count += 1
		BudgetTechSystemScript.add_escalation(state, sim_db, 4.0,
			"AIRBORNE PARATROOP & ROBOT DOG INSERTION: C-17 Globemaster III dropped SEAL Commandos, Tier-1 Snipers & Vision 60 Robot Dogs into forward sector!",
			"XVIII AIRBORNE CORPS / JSOC: 'Canopies open! Paratroopers, Sniper teams, and Quadruped Robot Dogs on the drop zone advancing on objective.'")
		return {
			"ok": spawned_uids.size() > 0,
			"op_code": op_code,
			"spawned_units": spawned_uids.size(),
			"active_parachutes": state.parachute_drops.size(),
		}

	elif op_code == DEPLOY_SMART_MINEFIELD:
		var elev := state.get_terrain_elevation_m(focus_pos.x, focus_pos.z)
		var dom := "SEA" if elev <= 0.0 else "LAND"
		state.minefields.append({
			"pos_km": Vector3(focus_pos.x, maxf(0.0, elev), focus_pos.z),
			"radius_km": 22.0,
			"faction": WorldState.FACTION_BLUE,
			"domain": dom,
			"active": true,
		})
		state.minefields_deployed_count += 1
		BudgetTechSystemScript.add_escalation(state, sim_db, 3.0,
			"SMART MINEFIELD BARRIER DEPLOYED: %s FASCAM/Quickstrike smart minefield seeded across (%.0f, %.0f) km!" % [dom, focus_pos.x, focus_pos.z],
			"JOINT ENGINEER COMMAND: 'Scatterable acoustic/magnetic smart mines active; enemy armor and naval corridors interdicted.'")
		return {
			"ok": true,
			"op_code": op_code,
			"domain": dom,
			"total_minefields": state.minefields.size(),
		}

	elif op_code == ENGINEER_BREACH_AND_REBUILD:
		var cleared_mines := 0
		for i in range(state.minefields.size()):
			var mf: Dictionary = state.minefields[i]
			if int(mf.get("faction", 0)) == WorldState.FACTION_RED and bool(mf.get("active", false)):
				mf["active"] = false
				state.minefields[i] = mf
				cleared_mines += 1
		# Repair destroyed terrain cells, bridges & re-rail logistics trains
		var repaired_cells := 0
		for c_idx in range(state.destruction_level.size()):
			if state.destruction_level[c_idx] > 0.15:
				state.destruction_level[c_idx] = maxf(0.0, state.destruction_level[c_idx] - 0.65)
				repaired_cells += 1
		state.active_destroyed_cells_count = maxi(0, state.active_destroyed_cells_count - repaired_cells)
		state.bridges_destroyed_count = 0
		for t_i in range(state.train_count):
			if state.train_derailed[t_i] == 1:
				state.train_derailed[t_i] = 0
		state.trains_derailed_count = 0
		state.engineer_breaches_rebuilds_count += 1
		BudgetTechSystemScript.add_escalation(state, sim_db, -3.0,
			"COMBAT ENGINEERS & AVLB BRIDGES: Cleared %d OPFOR minefields, rebuilt blown river bridges & restored MSR rail logistics!" % cleared_mines,
			"US ARMY CORPS OF ENGINEERS: 'M1150 Assault Breachers cleared enemy mine belts; AVLB scissor bridges and rail lines restored.'")
		return {
			"ok": true,
			"op_code": op_code,
			"cleared_minefields": cleared_mines,
			"repaired_cells": repaired_cells,
		}

	return {"ok": false, "reason": "Unknown engineering/airborne op_code"}

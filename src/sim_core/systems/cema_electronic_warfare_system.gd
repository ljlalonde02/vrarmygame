class_name CemaElectronicWarfareSystem
extends RefCounted
## Phase 28: Strategic CEMA (Cyber-Electro-Magnetic Activities), SCADA Power Grid Blackouts,
## RF/GNSS Drone Swarm Hijacking (`FLAG_RF_DATALINK` vs `FLAG_FIBER_OPTIC`), and DRFM Phantom Radar Ghost Decoys.

const BudgetTechSystemScript := preload("res://src/sim_core/systems/budget_tech_system.gd")

const CEMA_GRID_BLACKOUT := "CEMA_GRID_BLACKOUT"
const CEMA_DRONE_HIJACK := "CEMA_DRONE_HIJACK"
const CEMA_DEEPFAKE_GHOST_DECOYS := "CEMA_DEEPFAKE_GHOST_DECOYS"
const CEMA_QUANTUM_FIREWALL_PATCH := "CEMA_QUANTUM_FIREWALL_PATCH"


static func step(state: WorldState, dt: float) -> void:
	if dt <= 0.0:
		return

	if state.cema_grid_blackout_timer_sec > 0.0:
		state.cema_grid_blackout_timer_sec = maxf(0.0, state.cema_grid_blackout_timer_sec - dt)

	# Gradual natural recovery of national power grids and cyber firewalls
	state.blue_power_grid_pct = minf(100.0, state.blue_power_grid_pct + dt * 0.18)
	state.red_power_grid_pct = minf(100.0, state.red_power_grid_pct + dt * 0.14)
	state.blue_cyber_firewall_pct = minf(100.0, state.blue_cyber_firewall_pct + dt * 0.15)
	state.red_cyber_firewall_pct = minf(100.0, state.red_cyber_firewall_pct + dt * 0.12)

	# Slowly drift holographic DRFM Phantom Radar Ghost Decoys across the contested airspace
	var g_cnt := state.ghost_decoy_positions_km.size()
	for gi in range(g_cnt):
		var gp := state.ghost_decoy_positions_km[gi]
		var dir_x := -1.0 if (gi % 2 == 0) else -0.65
		var dir_z := sin(state.sim_time_sec * 0.4 + float(gi)) * 0.5
		gp.x = clampf(gp.x + dir_x * 0.28 * dt * 10.0, -210.0, 210.0)
		gp.z = clampf(gp.z + dir_z * 0.22 * dt * 10.0, -210.0, 210.0)
		state.ghost_decoy_positions_km[gi] = gp


## Executes a Phase 28 Strategic CEMA Cyber-EW Operation (`[F10]` hotkey / Tab 8):
## - `CEMA_GRID_BLACKOUT`: SCADA Logic Bomb plunges OPFOR power grid into blackout (-45% Red Grid, degrades Red SAM radar & C2).
## - `CEMA_DRONE_HIJACK`: RF/GNSS Protocol Spoofing hijacks up to 8 enemy RF-datalinked UAVs/loitering drones (`FLAG_RF_DATALINK` without `FLAG_FIBER_OPTIC`), flipping them to `FACTION_BLUE`!
## - `CEMA_DEEPFAKE_GHOST_DECOYS`: Spawns 8 DRFM Holographic Radar Ghost Echos (`ghost_decoy_positions_km`) that bait enemy SAMs and confuse OPFOR C2.
## - `CEMA_QUANTUM_FIREWALL_PATCH`: Restores Blue Power Grid (+45%) and purges all cyber/EW jamming from Blue units.
static func execute_cema_operation(state: WorldState, sim_db: Node, op_code: String) -> Dictionary:
	state.cema_operations_executed_count += 1
	state.cyber_strikes_count += 1

	if op_code == CEMA_GRID_BLACKOUT:
		state.red_power_grid_pct = maxf(12.0, state.red_power_grid_pct - 48.0)
		state.red_cyber_firewall_pct = maxf(15.0, state.red_cyber_firewall_pct - 35.0)
		state.cema_grid_blackout_timer_sec = 60.0
		state.red_c2_integrity = maxf(0.35, state.red_c2_integrity - 0.28)
		state.red_radar_range_mult = maxf(0.58, state.red_radar_range_mult * 0.78)
		# Disable radar on 35% of OPFOR stationary/land SAMs due to grid power loss
		var sam_disabled := 0
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED:
				if (uid % 3) == 0:
					state.unit_cyber_timer[uid] = maxf(state.unit_cyber_timer[uid], 30.0)
					sam_disabled += 1
		state.latest_cema_status = "USCYBERCOM CEMA STRIKE: OPFOR SCADA Power Grid Blackout (Red Grid %d%% | %d Nodes Offline)." % [
			int(state.red_power_grid_pct), sam_disabled
		]
		BudgetTechSystemScript.add_escalation(state, sim_db, 7.0,
			"CYBER SCADA BLACKOUT: Zero-day logic bomb crippled OPFOR regional electrical grid (%d%% capacity) & darkened IADS radar sectors!" % int(state.red_power_grid_pct),
			"USCYBERCOM / FORT MEADE JOC: 'Substation transformers tripped across enemy theater; OPFOR airbases forced onto backup diesel generators.'")
		return {
			"ok": true,
			"op_code": op_code,
			"red_power_grid_pct": state.red_power_grid_pct,
			"nodes_affected": sam_disabled,
		}

	elif op_code == CEMA_DRONE_HIJACK:
		var p_flags: PackedInt32Array = sim_db.plat_class_flags
		var max_pid: int = p_flags.size()
		var flag_rf := int(sim_db.FLAG_RF_DATALINK)
		var flag_unmanned := int(sim_db.FLAG_UNMANNED | sim_db.FLAG_SWARM)
		var hijacked_now := 0

		# First look for RF-datalinked unmanned units (not protected by fiber-optic spool!)
		for uid in range(state.unit_count):
			if hijacked_now >= 8:
				break
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
				var pid := state.unit_platform_id[uid]
				if pid > 0 and pid < max_pid:
					var flg := p_flags[pid]
					var aut_lvl := String(sim_db.get_platform(pid).get("autonomy_level", ""))
					if (flg & (flag_rf | flag_unmanned)) != 0 and aut_lvl != "FIBER_OPTIC":
						state.unit_faction[uid] = WorldState.FACTION_BLUE
						state.unit_detected_mask[uid] |= 1
						state.unit_jammed[uid] = 0
						hijacked_now += 1
						state.units_hijacked_count += 1

		# Fallback if all remaining Red units are manned/other: hijack up to 4 Red leaf units with exposed C2 links
		if hijacked_now == 0:
			for uid in range(state.unit_count):
				if hijacked_now >= 4:
					break
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					state.unit_faction[uid] = WorldState.FACTION_BLUE
					state.unit_detected_mask[uid] |= 1
					hijacked_now += 1
					state.units_hijacked_count += 1

		# Also hijack up to 4 in-flight OPFOR RF-guided loitering munitions in mid-air!
		for mid in range(state.mun_count):
			if state.mun_active[mid] == 1 and state.mun_faction[mid] == WorldState.FACTION_RED:
				state.mun_faction[mid] = WorldState.FACTION_BLUE
				state.mun_target_pos[mid] = state.mun_start_pos[mid]

		state.latest_cema_status = "CEMA PROTOCOL HIJACK: %d OPFOR RF-Datalinked UAVs/Swarms Spoofed & Flipped to BLUE Control!" % state.units_hijacked_count
		BudgetTechSystemScript.add_escalation(state, sim_db, 6.0,
			"CEMA DRONE SWARM HIJACK: Coalition EW/Cyber teams cracked OPFOR unencrypted RF datalinks, flipping %d enemy drone units to Allied control!" % hijacked_now,
			"EA-37B COMPASS CALL / J6 EW DESK: 'Enemy RF-linked UAVs captured in flight; Fiber-Optic spool drones remain physically immune.'")
		return {
			"ok": true,
			"op_code": op_code,
			"hijacked_now": hijacked_now,
			"total_hijacked": state.units_hijacked_count,
		}

	elif op_code == CEMA_DEEPFAKE_GHOST_DECOYS:
		state.ghost_decoy_positions_km.clear()
		for i in range(8):
			var gx := -45.0 + float(i % 4) * 32.0
			var gz := -90.0 + float(i / 4) * 65.0 + float(i * 11)
			var gy := 8500.0 + float(i % 3) * 1800.0
			state.ghost_decoy_positions_km.append(Vector3(gx, gy, gz))
		state.ghost_decoys_spawned_count += 8
		state.blue_sam_intercept_bonus = minf(0.35, state.blue_sam_intercept_bonus + 0.08)
		# Cause OPFOR SAM batteries to expend interceptor ammo against the false DRFM radar ghosts!
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_ammo_1[uid] > 2:
				if (uid % 5) == 0:
					state.unit_ammo_1[uid] = maxi(1, state.unit_ammo_1[uid] - 1)
					state.red_munitions_expended += 1
		state.latest_cema_status = "CEMA DRFM DECOY SWARM: 8 Phantom Stealth Wing Ghost Echos Injected into OPFOR IADS!"
		BudgetTechSystemScript.add_escalation(state, sim_db, 4.0,
			"DRFM GHOST DECOYS & AI DEEPFAKE C2: 8 false radar formations injected into OPFOR IADS, baiting enemy SAMs into firing at empty sky!",
			"MALD-J / COMPASS CALL SPECTRUM DESK: 'OPFOR fire-control radars are tracking our synthetic ghost signatures.'")
		return {
			"ok": true,
			"op_code": op_code,
			"active_ghosts": state.ghost_decoy_positions_km.size(),
			"total_ghosts_spawned": state.ghost_decoys_spawned_count,
		}

	# Default / CEMA_QUANTUM_FIREWALL_PATCH: Restore Blue Power Grid & Purge Jamming
	state.blue_power_grid_pct = minf(100.0, state.blue_power_grid_pct + 45.0)
	state.blue_cyber_firewall_pct = 100.0
	state.blue_c2_integrity = 1.0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE:
			state.unit_jammed[uid] = 0
			state.unit_cyber_timer[uid] = 0.0
	state.latest_cema_status = "QUANTUM ZERO-TRUST PATCH: Blue Power Grid (%d%%) & C2 Encryption (100%%) Restored!" % int(state.blue_power_grid_pct)
	BudgetTechSystemScript.add_escalation(state, sim_db, -4.0,
		"QUANTUM C2 FIREWALL PATCHED: All OPFOR cyber intrusions purged; Coalition power grid & Link-16 datalinks restored to 100%.",
		"NSA / USCYBERCOM DEFENSIVE DESK: 'Post-quantum cryptographic keys rotated across all theater brigades and satellites.'")
	return {
		"ok": true,
		"op_code": op_code,
		"blue_power_grid_pct": state.blue_power_grid_pct,
		"blue_cyber_firewall_pct": state.blue_cyber_firewall_pct,
	}

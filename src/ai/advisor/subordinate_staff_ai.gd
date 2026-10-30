class_name SubordinateStaffAI
extends Node
## AI Subordinate Staff Officers (J2 Intel, JFACC Air Component, JFLCC Land/Unmanned Component, JFC Joint Fires).
## Provides real-time battlefield SITREPs, tactical decision recommendations, and 1-click execution of
## authentic military Courses of Action (COAs) via Auftragstaktik (Mission-Type Orders).

const COA_JFACC_AIR_SUPERIORITY := "COA_JFACC_AIR_SUPERIORITY"
const COA_JFLCC_GROUND_VANGUARD := "COA_JFLCC_GROUND_VANGUARD"
const COA_JFC_JOINT_TOT_STRIKE := "COA_JFC_JOINT_TOT_STRIKE"

var sim_server: Node = null
var command_bus: Node = null
var signal_bus: Node = null

var auto_delegate_subordinates: bool = true
var last_sitrep_text: String = "JOC STAFF INITIALIZING SITUATIONAL AWARENESS..."
var coas_executed_count: int = 0
var _sitrep_timer: float = 0.0


func setup(p_sim_server: Node, p_cmd_bus: Node, p_sig_bus: Node = null) -> void:
	sim_server = p_sim_server
	command_bus = p_cmd_bus
	signal_bus = p_sig_bus
	update_sitrep()


func _process(delta: float) -> void:
	if sim_server == null:
		return
	_sitrep_timer += delta
	if _sitrep_timer >= 1.5:
		_sitrep_timer = 0.0
		update_sitrep()


func update_sitrep() -> String:
	if sim_server == null or sim_server.sim_db_ref == null:
		return last_sitrep_text
	var state: WorldState = sim_server.world_state
	var sim_db: Node = sim_server.sim_db_ref
	var grid: SpatialHashGrid = sim_server.spatial_grid

	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var max_pid: int = p_dom.size()

	var blue_air := 0
	var blue_gnd := 0
	var blue_sams := 0
	var red_air_detected := 0
	var red_gnd_detected := 0
	var red_sams_active := 0
	var blue_unmanned_bays := 0

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid := state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		if state.unit_faction[uid] == WorldState.FACTION_BLUE:
			if p_dom[pid] == 1:
				blue_air += 1
			else:
				blue_gnd += 1
			if (p_flags[pid] & int(sim_db.FLAG_SAM)) != 0 and state.unit_radar_active[uid] == 1:
				blue_sams += 1
			blue_unmanned_bays += state.unit_unmanned_bays[uid]
		else:
			if (state.unit_detected_mask[uid] & 1) != 0:
				if p_dom[pid] == 1:
					red_air_detected += 1
				else:
					red_gnd_detected += 1
				if (p_flags[pid] & int(sim_db.FLAG_SAM)) != 0 and state.unit_radar_active[uid] == 1:
					red_sams_active += 1

	var f1_win := 82.0
	var f1_loss := 4.5
	var f2_win := 74.0
	var f2_loss := 11.2
	var f3_win := 88.0
	var f3_loss := 5.8
	var cs_kernel: Object = sim_server.get("cs_kernel")
	if cs_kernel != null and cs_kernel.has_method("ForecastCoaLanchesterFast"):
		var r1: PackedFloat32Array = cs_kernel.call("ForecastCoaLanchesterFast", float(blue_air * 10), float(blue_gnd * 8), float(blue_sams * 12), float(max(red_air_detected, 8) * 10), float(max(red_gnd_detected, 12) * 8), float(max(red_sams_active, 4) * 14), 1)
		var r2: PackedFloat32Array = cs_kernel.call("ForecastCoaLanchesterFast", float(blue_air * 10), float(blue_gnd * 8), float(blue_sams * 12), float(max(red_air_detected, 8) * 10), float(max(red_gnd_detected, 12) * 8), float(max(red_sams_active, 4) * 14), 2)
		var r3: PackedFloat32Array = cs_kernel.call("ForecastCoaLanchesterFast", float(blue_air * 10), float(blue_gnd * 8), float(blue_sams * 12), float(max(red_air_detected, 8) * 10), float(max(red_gnd_detected, 12) * 8), float(max(red_sams_active, 4) * 14), 3)
		if r1.size() >= 2 and r2.size() >= 2 and r3.size() >= 2:
			f1_win = r1[0]; f1_loss = r1[1]
			f2_win = r2[0]; f2_loss = r2[1]
			f3_win = r3[0]; f3_loss = r3[1]

	var inc_muns := grid.active_red_muns
	var recommendation := "T+15m Forecast: [F1] Win %.0f%% (Loss %.1f%%) | [F2] Win %.0f%% (Loss %.1f%%) | [F3] Win %.0f%% (Loss %.1f%%)" % [
		f1_win, f1_loss, f2_win, f2_loss, f3_win, f3_loss
	]
	if inc_muns >= 4:
		recommendation = "ALERT: %d Inbound Missiles! %s" % [inc_muns, recommendation]

	last_sitrep_text = (
		"JOC STAFF // SIM-LOD [.NET8 SIMD]: T0=%d Micro | T1=%d Oper | T2=%d Macro | CIV POP: %.2fM (EVAC: %dk | COLLAT: %.0f)\n" % [
			state.lod_tier0_count, state.lod_tier1_count, state.lod_tier2_count,
			state.total_theater_civilians / 1000000.0, int(state.total_displaced_civilians / 1000.0), state.estimated_civilian_casualties
		]
		+ "SPACE & INFRA: SATCOM %.0f%% | GPS %.0f%% | 3D BLDGS=%d | TRAINS=%d (DERAILED=%d) | RUBBLE CELLS=%d\n" % [
			state.blue_satcom_factor * 100.0, state.blue_pnt_factor * 100.0,
			state.bldg_count, state.train_count, state.trains_derailed_count, state.active_destroyed_cells_count
		]
		+ "STAFF COA LOOKAHEAD: %s" % recommendation
	)
	return last_sitrep_text


## Executes a full Doctrinal Course of Action (COA) across subordinate units on the battlefield.
func execute_coa(coa_code: String) -> int:
	if sim_server == null or command_bus == null or sim_server.sim_db_ref == null:
		return 0
	var state: WorldState = sim_server.world_state
	var sim_db: Node = sim_server.sim_db_ref
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var p_flags: PackedInt32Array = sim_db.plat_class_flags
	var max_pid: int = p_dom.size()

	var orders_issued := 0
	coas_executed_count += 1

	match coa_code:
		COA_JFACC_AIR_SUPERIORITY:
			# Vector friendly fighters/stealth jets to BVR intercept & SEAD jets to low-altitude SAM suppression
			var best_red_sam := -1
			var best_red_air := -1
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid > 0 and pid < max_pid:
						if best_red_sam == -1 and (p_flags[pid] & int(sim_db.FLAG_SAM)) != 0:
							best_red_sam = uid
						if best_red_air == -1 and p_dom[pid] == 1:
							best_red_air = uid

			var air_strikers: Array[int] = []
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid > 0 and pid < max_pid and p_dom[pid] == 1 and (p_flags[pid] & int(sim_db.FLAG_TANKER | sim_db.FLAG_AWACS)) == 0:
						state.unit_afterburner[uid] = 1
						if (p_flags[pid] & int(sim_db.FLAG_SEAD)) != 0 and best_red_sam >= 0:
							state.unit_desired_alt_m[uid] = 350.0 # NOE terrain-masking
							state.unit_ai_state[uid] = WorldState.AI_SEAD_TERRAIN_MASK
						else:
							state.unit_desired_alt_m[uid] = 9200.0
							state.unit_ai_state[uid] = WorldState.AI_BVR_INTERCEPT
						if state.unit_ammo_1[uid] > 0 and air_strikers.size() < 12:
							air_strikers.append(uid)
						orders_issued += 1

			var target_id := best_red_air if best_red_air >= 0 else best_red_sam
			var target_pos := state.unit_pos[target_id] if target_id >= 0 else Vector3(-85.0, 4000.0, 0.0)
			if air_strikers.size() > 0:
				command_bus.enqueue_strike(air_strikers, target_id, target_pos, 1, 2)
				command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)

		COA_JFLCC_GROUND_VANGUARD:
			# Unpack Quadruped Robot Dogs & FPV Swarms + Advance Mech/Infantry/Armor + Fire Artillery
			var carriers: Array[int] = []
			var arty_units: Array[int] = []
			var best_red_ground := -1
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid <= 0 or pid >= max_pid:
						continue
					if state.unit_faction[uid] == WorldState.FACTION_RED and p_dom[pid] == 0 and best_red_ground == -1:
						best_red_ground = uid
					elif state.unit_faction[uid] == WorldState.FACTION_BLUE and p_dom[pid] == 0:
						if state.unit_unmanned_bays[uid] > 0 and carriers.size() < 8:
							carriers.append(uid)
						if (p_flags[pid] & int(sim_db.FLAG_ARTILLERY)) != 0 and state.unit_ammo_1[uid] > 0 and arty_units.size() < 8:
							arty_units.append(uid)
						orders_issued += 1

			if carriers.size() > 0:
				command_bus.enqueue_deploy_unmanned(carriers, Vector3(-2.5, 0.0, 1.5))
			var tpos: Vector3 = state.unit_pos[best_red_ground] if best_red_ground >= 0 else Vector3(-90.0, 50.0, 10.0)
			if arty_units.size() > 0:
				command_bus.enqueue_strike(arty_units, best_red_ground, tpos, 1, 2)
				command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)

		COA_JFC_JOINT_TOT_STRIKE:
			# Synchronized Joint Time-on-Target Salvo against highest-cost RED unit
			var hvt_uid := -1
			var best_cost := -1.0
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid: int = state.unit_platform_id[uid]
					var c: float = float(sim_db.plat_cost_musd[pid]) if (pid > 0 and pid < sim_db.plat_cost_musd.size()) else 10.0
					if c > best_cost:
						best_cost = c
						hvt_uid = uid
			var joint_strikers: Array[int] = []
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					if state.unit_ammo_1[uid] > 0:
						joint_strikers.append(uid)
						orders_issued += 1
						if joint_strikers.size() >= 16:
							break
			var hvt_pos: Vector3 = state.unit_pos[hvt_uid] if hvt_uid >= 0 else Vector3(-100.0, 20.0, 0.0)
			if joint_strikers.size() > 0:
				command_bus.enqueue_strike(joint_strikers, hvt_uid, hvt_pos, 1, 2)
				command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_BLUE)

	if signal_bus != null:
		signal_bus.frago_received.emit("JOC SUBORDINATE COA AUTHORIZED: " + coa_code, "Subordinate commanders executing coordinated mission orders (%d units tasked)." % orders_issued)
	return orders_issued

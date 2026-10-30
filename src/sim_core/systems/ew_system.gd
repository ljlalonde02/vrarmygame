class_name ElectronicWarfareSystem
extends RefCounted
## Processes Electronic Warfare (EW) Jammer Cones & C2 Datalink Disruption.
## - `RF_DATALINK` units/drones entering a hostile jammer envelope have `unit_jammed = 1` (link severed).
## - `FIBER_OPTIC` (wired 10km FPVs), `AUTONOMOUS_AI` (Vision 60 Robot Dogs, XQ-58 Valkyrie, Lancet-3),
##   and `MANNED` platforms are 100% immune to C2 datalink jamming (`unit_jammed = 0`).

const DEFAULT_EW_JAM_RANGE_KM := 115.0


static func step(state: WorldState, sim_db: Node, _grid: SpatialHashGrid) -> void:
	var platforms: Array = sim_db.platforms_by_id
	var max_pid: int = platforms.size()

	# Clear previous tick's jam flags
	for uid in range(state.unit_count):
		state.unit_jammed[uid] = 0
	for mid in range(state.mun_count):
		state.mun_jammed[mid] = 0

	# Gather active EW jammers (e.g., `krasukha_4_ew` or AWACS/SEAD with active radar/jammer)
	var jammers: Array[Dictionary] = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		if state.unit_radar_active[uid] == 0:
			continue
		var pid := state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var p_def: Dictionary = platforms[pid]
		var u_class := String(p_def.get("unit_class", ""))
		if u_class == "EW_JAMMER" or u_class == "SEAD" or u_class == "AWACS":
			var jam_range := DEFAULT_EW_JAM_RANGE_KM if u_class == "EW_JAMMER" else 55.0
			jammers.append({
				"uid": uid,
				"faction": state.unit_faction[uid],
				"pos": state.unit_pos[uid],
				"range_sq": jam_range * jam_range,
			})

	if jammers.is_empty():
		return

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pid := state.unit_platform_id[uid]
		if pid <= 0 or pid >= max_pid:
			continue
		var p_def: Dictionary = platforms[pid]
		var autonomy := String(p_def.get("autonomy_level", "MANNED"))

		# FIBER_OPTIC, AUTONOMOUS_AI, and MANNED units cannot have their C2 link severed by RF jamming
		if autonomy != "RF_DATALINK":
			state.unit_jammed[uid] = 0
			continue

		var u_pos := state.unit_pos[uid]
		var u_fac := state.unit_faction[uid]
		for j in jammers:
			if int(j["faction"]) != u_fac:
				var j_pos: Vector3 = j["pos"]
				var d_sq := Vector2(u_pos.x, u_pos.z).distance_squared_to(Vector2(j_pos.x, j_pos.z))
				if d_sq <= float(j["range_sq"]):
					state.unit_jammed[uid] = 1
					break

class_name InfluenceMap
extends RefCounted
## 20x20 Tactical Influence & Threat Grid over the 500km x 500km theater.
## Evaluates BLUE vs RED force concentration and SAM threat density so `OpForCommander`
## can identify high-value strike targets and low-threat ingress corridors.

const GRID_SIZE := 20
const CELL_KM := 25.0

var blue_power_grid: PackedFloat32Array = PackedFloat32Array()
var red_power_grid: PackedFloat32Array = PackedFloat32Array()


func _init() -> void:
	blue_power_grid.resize(GRID_SIZE * GRID_SIZE)
	red_power_grid.resize(GRID_SIZE * GRID_SIZE)


func rebuild(state: WorldState, sim_db: Node) -> void:
	blue_power_grid.fill(0.0)
	red_power_grid.fill(0.0)
	var platforms: Array = sim_db.platforms_by_id
	var max_pid: int = platforms.size()

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var pos := state.unit_pos[uid]
		var cx := clampi(int((pos.x + 250.0) / CELL_KM), 0, GRID_SIZE - 1)
		var cz := clampi(int((pos.z + 250.0) / CELL_KM), 0, GRID_SIZE - 1)
		var pid := state.unit_platform_id[uid]
		var p_def: Dictionary = platforms[pid] if (pid > 0 and pid < max_pid) else {}
		var weight := float(p_def.get("unit_cost_musd", 20.0)) + 10.0
		var idx := cz * GRID_SIZE + cx
		if state.unit_faction[uid] == WorldState.FACTION_BLUE:
			blue_power_grid[idx] += weight
		else:
			red_power_grid[idx] += weight


func find_highest_value_blue_sector_km() -> Vector3:
	var best_idx := 0
	var best_val := -1.0
	for i in range(blue_power_grid.size()):
		if blue_power_grid[i] > best_val:
			best_val = blue_power_grid[i]
			best_idx = i
	var cx := best_idx % GRID_SIZE
	var cz := best_idx / GRID_SIZE
	var x_km := (float(cx) + 0.5) * CELL_KM - 250.0
	var z_km := (float(cz) + 0.5) * CELL_KM - 250.0
	return Vector3(x_km, 50.0, z_km)

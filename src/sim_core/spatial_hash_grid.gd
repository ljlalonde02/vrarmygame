class_name SpatialHashGrid
extends RefCounted
## Zero-Allocation Intrusive Linked-List 50x50 Spatial Hash Grid (10 km cells over 500x500 km theater).
## Partitioned by faction (`_blue_unit_head`, `_red_unit_head`, `_blue_mun_head`, `_red_mun_head`)
## with flat `_unit_next` / `_mun_next` index chains:
##   - O(N) rebuild with ZERO dynamic memory allocations (`.fill(-1)` + 2 integer array writes per entity)
##   - O(1) early-out when `active_red_muns == 0` or `active_blue_muns == 0`
##   - Zero-allocation scratch buffer queries (`scratch_uids`, `scratch_mids`) for inner combat/AI loops.

const GRID_DIM := 50
const TOTAL_CELLS := 2500
const CELL_SIZE_KM := 10.0
const INV_CELL_SIZE_KM := 0.1
const HALF_THEATER_KM := 250.0

var _blue_unit_head: PackedInt32Array = PackedInt32Array()
var _red_unit_head: PackedInt32Array = PackedInt32Array()
var _unit_next: PackedInt32Array = PackedInt32Array()

var _blue_mun_head: PackedInt32Array = PackedInt32Array()
var _red_mun_head: PackedInt32Array = PackedInt32Array()
var _mun_next: PackedInt32Array = PackedInt32Array()

var active_blue_units: int = 0
var active_red_units: int = 0
var active_blue_muns: int = 0
var active_red_muns: int = 0

# Pre-allocated scratch buffers for zero-heap-allocation inner-loop queries
var scratch_uids: PackedInt32Array = PackedInt32Array()
var scratch_mids: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	_blue_unit_head.resize(TOTAL_CELLS)
	_red_unit_head.resize(TOTAL_CELLS)
	_unit_next.resize(WorldState.MAX_UNITS)

	_blue_mun_head.resize(TOTAL_CELLS)
	_red_mun_head.resize(TOTAL_CELLS)
	_mun_next.resize(WorldState.MAX_MUNITIONS)

	scratch_uids.resize(WorldState.MAX_UNITS)
	scratch_mids.resize(WorldState.MAX_MUNITIONS)


func rebuild(state: WorldState) -> void:
	_blue_unit_head.fill(-1)
	_red_unit_head.fill(-1)
	_blue_mun_head.fill(-1)
	_red_mun_head.fill(-1)

	active_blue_units = 0
	active_red_units = 0
	active_blue_muns = 0
	active_red_muns = 0

	var u_active := state.unit_active
	var u_ech := state.unit_echelon
	var u_pos := state.unit_pos
	var u_fac := state.unit_faction
	var n_units := state.unit_count

	for uid in range(n_units):
		if u_active[uid] == 0 or u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue
		var p := u_pos[uid]
		var cx := clampi(int((p.x + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
		var cz := clampi(int((p.z + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
		var c_idx := cz * GRID_DIM + cx
		if u_fac[uid] == WorldState.FACTION_BLUE:
			_unit_next[uid] = _blue_unit_head[c_idx]
			_blue_unit_head[c_idx] = uid
			active_blue_units += 1
		else:
			_unit_next[uid] = _red_unit_head[c_idx]
			_red_unit_head[c_idx] = uid
			active_red_units += 1

	var m_active := state.mun_active
	var m_pos := state.mun_pos
	var m_fac := state.mun_faction
	var n_muns := state.mun_count

	for mid in range(n_muns):
		if m_active[mid] == 0:
			continue
		var mp := m_pos[mid]
		var mcx := clampi(int((mp.x + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
		var mcz := clampi(int((mp.z + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
		var mc_idx := mcz * GRID_DIM + mcx
		if m_fac[mid] == WorldState.FACTION_BLUE:
			_mun_next[mid] = _blue_mun_head[mc_idx]
			_blue_mun_head[mc_idx] = mid
			active_blue_muns += 1
		else:
			_mun_next[mid] = _red_mun_head[mc_idx]
			_red_mun_head[mc_idx] = mid
			active_red_muns += 1


## Zero-allocation query writing hostile unit IDs in candidate cells into `scratch_uids` and returning count.
func query_enemy_units_into_scratch(enemy_faction: int, x_km: float, z_km: float, radius_km: float) -> int:
	if enemy_faction == WorldState.FACTION_BLUE and active_blue_units == 0:
		return 0
	if enemy_faction == WorldState.FACTION_RED and active_red_units == 0:
		return 0

	var cell_rad := int(ceil(radius_km * INV_CELL_SIZE_KM)) + 1
	var cx_c := clampi(int((x_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var cz_c := clampi(int((z_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var min_x := maxi(0, cx_c - cell_rad)
	var max_x := mini(GRID_DIM - 1, cx_c + cell_rad)
	var min_z := maxi(0, cz_c - cell_rad)
	var max_z := mini(GRID_DIM - 1, cz_c + cell_rad)

	var heads := _blue_unit_head if enemy_faction == WorldState.FACTION_BLUE else _red_unit_head
	var out_cnt := 0
	for cz in range(min_z, max_z + 1):
		var row_offset := cz * GRID_DIM
		for cx in range(min_x, max_x + 1):
			var uid := heads[row_offset + cx]
			while uid != -1:
				scratch_uids[out_cnt] = uid
				out_cnt += 1
				uid = _unit_next[uid]
	return out_cnt


## Zero-allocation query writing hostile munition IDs in candidate cells into `scratch_mids` and returning count.
func query_enemy_munitions_into_scratch(enemy_faction: int, x_km: float, z_km: float, radius_km: float) -> int:
	if enemy_faction == WorldState.FACTION_BLUE and active_blue_muns == 0:
		return 0
	if enemy_faction == WorldState.FACTION_RED and active_red_muns == 0:
		return 0

	var cell_rad := int(ceil(radius_km * INV_CELL_SIZE_KM)) + 1
	var cx_c := clampi(int((x_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var cz_c := clampi(int((z_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var min_x := maxi(0, cx_c - cell_rad)
	var max_x := mini(GRID_DIM - 1, cx_c + cell_rad)
	var min_z := maxi(0, cz_c - cell_rad)
	var max_z := mini(GRID_DIM - 1, cz_c + cell_rad)

	var heads := _blue_mun_head if enemy_faction == WorldState.FACTION_BLUE else _red_mun_head
	var out_cnt := 0
	for cz in range(min_z, max_z + 1):
		var row_offset := cz * GRID_DIM
		for cx in range(min_x, max_x + 1):
			var mid := heads[row_offset + cx]
			while mid != -1:
				scratch_mids[out_cnt] = mid
				out_cnt += 1
				mid = _mun_next[mid]
	return out_cnt


## Fast zero-allocation nearest hostile unit finder within `radius_km`.
func find_nearest_enemy_unit(state: WorldState, enemy_faction: int, x_km: float, z_km: float, radius_km: float, req_detected_mask: int = 0) -> int:
	var cnt := query_enemy_units_into_scratch(enemy_faction, x_km, z_km, radius_km)
	if cnt == 0:
		return -1
	var best_uid := -1
	var best_d_sq := radius_km * radius_km
	var u_pos := state.unit_pos
	var u_active := state.unit_active
	var u_det := state.unit_detected_mask
	for i in range(cnt):
		var uid := scratch_uids[i]
		if u_active[uid] == 0:
			continue
		if req_detected_mask != 0 and (u_det[uid] & req_detected_mask) == 0:
			continue
		var p := u_pos[uid]
		var dx := p.x - x_km
		var dz := p.z - z_km
		var d_sq := dx * dx + dz * dz
		if d_sq <= best_d_sq:
			best_d_sq = d_sq
			best_uid = uid
	return best_uid


## Fast zero-allocation nearest interceptable hostile munition finder within `radius_km`.
func find_nearest_enemy_munition(state: WorldState, enemy_faction: int, x_km: float, z_km: float, radius_km: float, interceptable_lut: PackedByteArray) -> int:
	var cnt := query_enemy_munitions_into_scratch(enemy_faction, x_km, z_km, radius_km)
	if cnt == 0:
		return -1
	var best_mid := -1
	var best_d_sq := radius_km * radius_km
	var m_pos := state.mun_pos
	var m_active := state.mun_active
	var m_wid := state.mun_weapon_id
	for i in range(cnt):
		var mid := scratch_mids[i]
		if m_active[mid] == 0:
			continue
		if interceptable_lut[m_wid[mid]] == 0:
			continue
		var p := m_pos[mid]
		var dx := p.x - x_km
		var dz := p.z - z_km
		var d_sq := dx * dx + dz * dz
		if d_sq <= best_d_sq:
			best_d_sq = d_sq
			best_mid = mid
	return best_mid


func query_units_in_radius(x_km: float, z_km: float, radius_km: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	var cell_rad := int(ceil(radius_km * INV_CELL_SIZE_KM)) + 1
	var cx_c := clampi(int((x_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var cz_c := clampi(int((z_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var min_x := maxi(0, cx_c - cell_rad)
	var max_x := mini(GRID_DIM - 1, cx_c + cell_rad)
	var min_z := maxi(0, cz_c - cell_rad)
	var max_z := mini(GRID_DIM - 1, cz_c + cell_rad)

	for cz in range(min_z, max_z + 1):
		var row_offset := cz * GRID_DIM
		for cx in range(min_x, max_x + 1):
			var idx := row_offset + cx
			var u1 := _blue_unit_head[idx]
			while u1 != -1:
				result.append(u1)
				u1 = _unit_next[u1]
			var u2 := _red_unit_head[idx]
			while u2 != -1:
				result.append(u2)
				u2 = _unit_next[u2]
	return result


func query_munitions_in_radius(x_km: float, z_km: float, radius_km: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	var cell_rad := int(ceil(radius_km * INV_CELL_SIZE_KM)) + 1
	var cx_c := clampi(int((x_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var cz_c := clampi(int((z_km + HALF_THEATER_KM) * INV_CELL_SIZE_KM), 0, GRID_DIM - 1)
	var min_x := maxi(0, cx_c - cell_rad)
	var max_x := mini(GRID_DIM - 1, cx_c + cell_rad)
	var min_z := maxi(0, cz_c - cell_rad)
	var max_z := mini(GRID_DIM - 1, cz_c + cell_rad)

	for cz in range(min_z, max_z + 1):
		var row_offset := cz * GRID_DIM
		for cx in range(min_x, max_x + 1):
			var idx := row_offset + cx
			var m1 := _blue_mun_head[idx]
			while m1 != -1:
				result.append(m1)
				m1 = _mun_next[m1]
			var m2 := _red_mun_head[idx]
			while m2 != -1:
				result.append(m2)
				m2 = _mun_next[m2]
	return result

class_name TerrainInfrastructureSystem
extends RefCounted

const CivilianDensitySystemScript := preload("res://src/sim_core/systems/civilian_density_system.gd")
## Phase 11 Living Battlefield Infrastructure System:
## 1. Nature / Dense Forest Canopies (`infra_forest_density`) & Biome Classification (`infra_biome`)
## 2. Hydrological Downhill Rivers (`infra_river_mask`) & Strategic Road/Rail Bridges (`infra_bridge_mask`)
## 3. Highway / MSR Road Network (`infra_road_mask`) & Heavy Military Railway Network (`infra_rail_mask`)
## 4. Procedural 3D Cities, Towns, Villages & Airport/Airfield Complexes (`bldg_pos_km`, `bldg_scale_m`, `bldg_type`)
## 5. Moving 3D Military Echelon Logistics Trains (`train_pos_km`) with Rail-Cut Derailment & High-Capacity Resupply
## 6. Forward Airfield Ground Capture (`airfields_captured_count`) & Dynamic War Destruction (`destruction_level`)


static func seed_theater_infrastructure(state: WorldState) -> void:
	var g := WorldState.CIV_GRID_SIZE
	var total_cells := g * g
	state.infra_biome.resize(total_cells)
	state.infra_biome.fill(WorldState.BIOME_OCEAN)
	state.infra_forest_density.resize(total_cells)
	state.infra_forest_density.fill(0.0)
	state.infra_river_mask.resize(total_cells)
	state.infra_river_mask.fill(0.0)
	state.infra_road_mask.resize(total_cells)
	state.infra_road_mask.fill(0.0)
	state.infra_rail_mask.resize(total_cells)
	state.infra_rail_mask.fill(0.0)
	state.infra_bridge_mask.resize(total_cells)
	state.infra_bridge_mask.fill(0.0)
	state.infra_urban_density.resize(total_cells)
	state.infra_urban_density.fill(0.0)
	state.destruction_level.resize(total_cells)
	state.destruction_level.fill(0.0)

	state.bldg_count = 0
	state.bldg_pos_km.clear()
	state.bldg_scale_m.clear()
	state.bldg_yaw_rad.clear()
	state.bldg_type.clear()
	state.bldg_cell_idx.clear()
	state.road_segments_km.clear()
	state.city_hubs_km.clear()

	state.active_destroyed_cells_count = 0
	state.bridges_destroyed_count = 0
	state.trains_derailed_count = 0
	state.airfields_captured_count = 0

	# 1. Classify Base Biomes, Nature/Forest Canopy, and Village/Urban Density across 128x128 grid
	for y in range(g):
		var z_km := -250.0 + (float(y) / float(g - 1)) * 500.0
		for x in range(g):
			var x_km := -250.0 + (float(x) / float(g - 1)) * 500.0
			var idx := y * g + x
			var elev_m := state.get_terrain_elevation_m(x_km, z_km)
			if elev_m <= 2.0:
				state.infra_biome[idx] = WorldState.BIOME_OCEAN
				continue

			var civ_rho: float = state.civ_initial_m2[idx] if idx < state.civ_initial_m2.size() else 0.0
			if civ_rho > 0.012:
				state.infra_biome[idx] = WorldState.BIOME_URBAN_CITY
				state.infra_urban_density[idx] = clampf(civ_rho / 0.032, 0.55, 1.0)
				state.infra_road_mask[idx] = 1.0
			elif civ_rho > 0.0025:
				state.infra_biome[idx] = WorldState.BIOME_VILLAGE
				state.infra_urban_density[idx] = clampf(civ_rho / 0.012, 0.25, 0.65)
				if (x % 2 == 0) or (y % 2 == 0):
					state.infra_road_mask[idx] = maxf(state.infra_road_mask[idx], 0.85)
			elif elev_m > 1650.0:
				state.infra_biome[idx] = WorldState.BIOME_ALPINE
			else:
				# Deterministic organic forest/nature belts on mid-elevation foothills & valleys
				var f_wave := sin(x_km * 0.055 + 1.3) * cos(z_km * 0.048 - 0.7) + 0.5 * sin((x_km + z_km) * 0.085)
				var elev_band := 1.0 - absf(elev_m - 480.0) / 750.0
				var f_val := clampf((f_wave * 0.45 + 0.38) * clampf(elev_band, 0.2, 1.0), 0.0, 1.0)
				if f_val > 0.42:
					state.infra_biome[idx] = WorldState.BIOME_FOREST
					state.infra_forest_density[idx] = f_val
				else:
					state.infra_biome[idx] = WorldState.BIOME_PLAINS
					state.infra_forest_density[idx] = f_val * 0.5

	# 2. Carve Hydrological Downhill Rivers from High Foothills/Mountains to the Sea (or across Valleys)
	_carve_hydrological_rivers(state, g)

	# 3. Build Highway Road Network (`infra_road_mask`), Railway Network (`infra_rail_mask`), and River Bridges (`infra_bridge_mask`)
	_build_roads_rails_and_bridges(state, g)

	# 4. Generate Procedural 3D City Skyscrapers, Town/Village Cubes, Airport Runways/Hangars & Bridge Spans
	_generate_procedural_3d_buildings(state, g)


static func _carve_hydrological_rivers(state: WorldState, g: int) -> void:
	# Find 6 high-elevation watershed sources spaced across the theater and trace them downhill
	var sources: Array[Vector2i] = []
	for sy_band in range(6):
		var best_cell := Vector2i(g / 2, g / 2)
		var best_elev := -100.0
		var y_start := clampi(10 + sy_band * 18, 8, g - 20)
		for y in range(y_start, mini(g - 8, y_start + 18), 2):
			for x in range(10, g - 10, 2):
				var x_km := -250.0 + (float(x) / float(g - 1)) * 500.0
				var z_km := -250.0 + (float(y) / float(g - 1)) * 500.0
				var el := state.get_terrain_elevation_m(x_km, z_km)
				if el > best_elev:
					best_elev = el
					best_cell = Vector2i(x, y)
		if best_elev > 45.0:
			sources.append(best_cell)

	# Fallback river across central valley if terrain is very flat
	if sources.size() < 3:
		sources.append(Vector2i(g / 2, 12))
		sources.append(Vector2i(14, g / 2))

	for src in sources:
		var cx := src.x
		var cy := src.y
		var flow_dir := Vector2(-1.0 if cx > g / 2 else 1.0, 0.35 if (cy & 1) == 0 else -0.35).normalized()
		for step_i in range(140):
			if cx <= 2 or cx >= g - 3 or cy <= 2 or cy >= g - 3:
				break
			var idx := cy * g + cx
			state.infra_river_mask[idx] = 1.0
			# Widen river channel slightly downstream
			if step_i > 12:
				var side_idx := cy * g + clampi(cx + 1, 0, g - 1)
				state.infra_river_mask[side_idx] = maxf(state.infra_river_mask[side_idx], 0.72)

			var x_km := -250.0 + (float(cx) / float(g - 1)) * 500.0
			var z_km := -250.0 + (float(cy) / float(g - 1)) * 500.0
			if state.get_terrain_elevation_m(x_km, z_km) <= 1.5 and step_i > 8:
				break # Reached ocean!

			# Pick steepest downhill neighbor biased along watershed flow + natural meander
			var best_nx := cx
			var best_ny := cy
			var best_score := 999999.0
			var meander := sin(float(step_i) * 0.28 + float(src.y)) * 0.45
			var pref_dir := Vector2(flow_dir.x, flow_dir.y + meander).normalized()

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := cx + dx
					var ny := cy + dy
					var n_idx := ny * g + nx
					if state.infra_river_mask[n_idx] > 0.8:
						continue
					var nx_km := -250.0 + (float(nx) / float(g - 1)) * 500.0
					var nz_km := -250.0 + (float(ny) / float(g - 1)) * 500.0
					var n_el := state.get_terrain_elevation_m(nx_km, nz_km)
					var step_v := Vector2(float(dx), float(dy)).normalized()
					var score := n_el - step_v.dot(pref_dir) * 85.0
					if score < best_score:
						best_score = score
						best_nx = nx
						best_ny = ny

			if best_nx == cx and best_ny == cy:
				cx = clampi(cx + int(round(pref_dir.x)), 2, g - 3)
				cy = clampi(cy + int(round(pref_dir.y)), 2, g - 3)
			else:
				cx = best_nx
				cy = best_ny


static func _build_roads_rails_and_bridges(state: WorldState, g: int) -> void:
	var nodes_km: Array[Vector2] = []
	for st in state.active_sites:
		var sv := Vector2(float(st.get("x_km", 0.0)), float(st.get("z_km", 0.0)))
		nodes_km.append(sv)
		state.city_hubs_km.append(Vector3(sv.x, sv.y, 10.5))
		_stamp_village_cluster(state, g, sv.x, sv.y, 4)

	# Add Real-World GIS Metropolitan Cities & Regional Town Hubs so every theater has authentic highway, street grid & rail corridors
	var real_cities: Array[Dictionary] = CivilianDensitySystemScript.get_theater_real_cities(state.active_theater_slug)
	for rc in real_cities:
		var rc_v := Vector2(float(rc.get("x_km", 0.0)), float(rc.get("z_km", 0.0)))
		var already_near := false
		for ex_n in nodes_km:
			if ex_n.distance_to(rc_v) < 10.0:
				already_near = true
				break
		if not already_near:
			nodes_km.append(rc_v)
		state.city_hubs_km.append(Vector3(rc_v.x, rc_v.y, 14.0))
		_stamp_village_cluster(state, g, rc_v.x, rc_v.y, 5)

	# Connect same-landmass nodes with Highways (`infra_road_mask`) and major trunks with Railways (`infra_rail_mask`)
	state.train_count = 0
	var connected_pairs: Dictionary = {}
	for i in range(nodes_km.size()):
		var a: Vector2 = nodes_km[i]
		# Connect each city/site node to its 3 nearest overland/coastal neighbors
		var best_j1 := -1
		var best_d1 := 999999.0
		var best_j2 := -1
		var best_d2 := 999999.0
		var best_j3 := -1
		var best_d3 := 999999.0
		for j in range(nodes_km.size()):
			if i == j:
				continue
			var b: Vector2 = nodes_km[j]
			var d := a.distance_to(b)
			# Skip across wide open-ocean straits (> 95 km with deep-water midpoint), but allow coastal bay causeways
			var mid := (a + b) * 0.5
			var q1 := a.lerp(b, 0.25)
			var q3 := a.lerp(b, 0.75)
			var water_pts := 0
			if state.get_terrain_elevation_m(mid.x, mid.y) <= 0.5:
				water_pts += 1
			if state.get_terrain_elevation_m(q1.x, q1.y) <= 0.5:
				water_pts += 1
			if state.get_terrain_elevation_m(q3.x, q3.y) <= 0.5:
				water_pts += 1
			if water_pts >= 2 and d > 85.0:
				continue
			if d < best_d1:
				best_d3 = best_d2
				best_j3 = best_j2
				best_d2 = best_d1
				best_j2 = best_j1
				best_d1 = d
				best_j1 = j
			elif d < best_d2:
				best_d3 = best_d2
				best_j3 = best_j2
				best_d2 = d
				best_j2 = j
			elif d < best_d3:
				best_d3 = d
				best_j3 = j

		var neighbors: Array[int] = [best_j1, best_j2, best_j3]
		var dists: Array[float] = [best_d1, best_d2, best_d3]
		for n_k in range(neighbors.size()):
			var nj: int = neighbors[n_k]
			var nd: float = dists[n_k]
			if nj < 0 or (n_k >= 1 and nd > 195.0) or (n_k == 2 and nd > 145.0):
				continue
			var p_min := mini(i, nj)
			var p_max := maxi(i, nj)
			var pair_key := "%d_%d" % [p_min, p_max]
			var is_rail_trunk := (n_k == 0 and i < 8)
			_rasterize_corridor(state, g, a, nodes_km[nj], true, is_rail_trunk)
			if not connected_pairs.has(pair_key):
				connected_pairs[pair_key] = true
				state.road_segments_km.append(Vector4(a.x, a.y, nodes_km[nj].x, nodes_km[nj].y))
			if n_k == 0 and i < WorldState.MAX_TRAINS and nd >= 22.0 and state.train_count < 8:
				_spawn_logistics_train(state, a, nodes_km[nj])

	# Guarantee at least 4 active military logistics trains even on island/archipelago maps
	if state.train_count < 4:
		var fallback_rails := [
			[Vector2(95.0, -90.0), Vector2(120.0, 65.0)],
			[Vector2(-105.0, -85.0), Vector2(-95.0, 75.0)],
			[Vector2(85.0, -20.0), Vector2(130.0, 45.0)],
			[Vector2(-130.0, -40.0), Vector2(-85.0, 40.0)],
		]
		for pair in fallback_rails:
			if state.train_count >= 6:
				break
			var pa: Vector2 = pair[0]
			var pb: Vector2 = pair[1]
			_rasterize_corridor(state, g, pa, pb, true, true)
			_spawn_logistics_train(state, pa, pb)


static func _stamp_village_cluster(state: WorldState, g: int, x_km: float, z_km: float, rad_cells: int) -> void:
	var u := clampf((x_km + 250.0) / 500.0, 0.0, 1.0)
	var v := clampf((z_km + 250.0) / 500.0, 0.0, 1.0)
	var cx := clampi(int(round(u * float(g - 1))), 0, g - 1)
	var cy := clampi(int(round(v * float(g - 1))), 0, g - 1)
	for dy in range(-rad_cells, rad_cells + 1):
		for dx in range(-rad_cells, rad_cells + 1):
			var nx := clampi(cx + dx, 0, g - 1)
			var ny := clampi(cy + dy, 0, g - 1)
			var d_norm := sqrt(float(dx * dx + dy * dy)) / float(max(1, rad_cells))
			if d_norm <= 1.0:
				var idx := ny * g + nx
				var is_cardinal_avenue := (dx == 0 or dy == 0)
				var is_ring_road := absf(d_norm - 0.65) <= 0.22
				var is_street_grid := ((absi(dx) % 2 == 0) or (absi(dy) % 2 == 0)) and d_norm <= 0.85
				if state.infra_biome[idx] != WorldState.BIOME_OCEAN or d_norm <= 0.45:
					if state.infra_biome[idx] == WorldState.BIOME_OCEAN:
						state.infra_biome[idx] = WorldState.BIOME_URBAN_CITY if d_norm <= 0.35 else WorldState.BIOME_VILLAGE
					elif d_norm <= 0.45:
						state.infra_biome[idx] = WorldState.BIOME_URBAN_CITY
					else:
						state.infra_biome[idx] = WorldState.BIOME_VILLAGE
					state.infra_urban_density[idx] = maxf(state.infra_urban_density[idx], 0.72 * (1.0 - d_norm * 0.55))
					if is_cardinal_avenue or is_ring_road:
						state.infra_road_mask[idx] = 1.0
					elif is_street_grid:
						state.infra_road_mask[idx] = maxf(state.infra_road_mask[idx], 0.88)


static func _rasterize_corridor(state: WorldState, g: int, a_km: Vector2, b_km: Vector2, is_road: bool, is_rail: bool) -> void:
	var dist_km := a_km.distance_to(b_km)
	var steps := maxi(24, int(dist_km / 1.8))
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var p := a_km.lerp(b_km, t)
		var elev := state.get_terrain_elevation_m(p.x, p.y)
		# Allow coastal causeways/bridges across narrow bays/harbors (< 90 km corridor), skip open ocean
		if elev <= 0.5 and dist_km > 90.0:
			continue
		var idx := state.get_infra_cell_index(p.x, p.y)
		if is_road:
			state.infra_road_mask[idx] = 1.0
		if is_rail:
			state.infra_rail_mask[idx] = 1.0
		# Where a road or railway crosses a river or coastal bay inlet, construct a Strategic Bridge / Causeway!
		if state.infra_river_mask[idx] > 0.35 or (elev <= 0.5 and (s % 3 == 0)):
			state.infra_bridge_mask[idx] = 1.0


static func _spawn_logistics_train(state: WorldState, start_km: Vector2, end_km: Vector2) -> void:
	var tid := state.train_count
	if tid >= WorldState.MAX_TRAINS:
		return
	state.train_count += 1
	var fac := WorldState.FACTION_BLUE if start_km.x >= 0.0 else WorldState.FACTION_RED
	var sy := maxf(2.0, state.get_terrain_elevation_m(start_km.x, start_km.y))
	var ey := maxf(2.0, state.get_terrain_elevation_m(end_km.x, end_km.y))
	state.train_active[tid] = 1
	state.train_faction[tid] = fac
	state.train_start_km[tid] = Vector3(start_km.x, sy, start_km.y)
	state.train_end_km[tid] = Vector3(end_km.x, ey, end_km.y)
	state.train_progress[tid] = fmod(float(tid) * 0.27, 0.9)
	state.train_dir_sign[tid] = 1.0
	state.train_derailed[tid] = 0
	var p3 := state.train_start_km[tid].lerp(state.train_end_km[tid], state.train_progress[tid])
	p3.y = maxf(2.0, state.get_terrain_elevation_m(p3.x, p3.z))
	state.train_pos_km[tid] = p3
	state.train_heading_rad[tid] = atan2(end_km.y - start_km.y, end_km.x - start_km.x)


static func _generate_procedural_3d_buildings(state: WorldState, g: int) -> void:
	# 1. Generate 3D Airport / Airfield Runways, Control Towers & Hardened Aircraft Hangars at every AIRBASE site
	for st in state.active_sites:
		var sx := float(st.get("x_km", 0.0))
		var sz := float(st.get("z_km", 0.0))
		var stype := String(st.get("site_type", ""))
		var elev := maxf(2.0, state.get_terrain_elevation_m(sx, sz))
		var c_idx := state.get_infra_cell_index(sx, sz)

		if stype == "AIRBASE":
			# Main 3D Runway Strip + Parallel Taxiway
			_add_bldg(state, Vector3(sx, elev + 2.0, sz), Vector3(0.0045, 0.0009, 0.028), 0.35, WorldState.BLDG_AIRPORT_RUNWAY, c_idx)
			_add_bldg(state, Vector3(sx + 1.4, elev + 2.0, sz), Vector3(0.0025, 0.0008, 0.024), 0.35, WorldState.BLDG_AIRPORT_RUNWAY, c_idx)
			# Airfield Control Tower
			_add_bldg(state, Vector3(sx - 1.8, elev, sz - 1.2), Vector3(0.0028, 0.0145, 0.0028), 0.0, WorldState.BLDG_URBAN_TOWER, c_idx)
			# 6 Hardened Aircraft Shelter Hangars along the tarmac
			for h_i in range(6):
				var hz := sz - 3.5 + float(h_i) * 1.4
				_add_bldg(state, Vector3(sx + 2.6, elev, hz), Vector3(0.0038, 0.0036, 0.0048), 0.35, WorldState.BLDG_AIRPORT_HANGAR, c_idx)

	# 1b. Generate Recognizable Real-World Metropolitan Landmarks & Container Port Quays
	var real_cities: Array[Dictionary] = CivilianDensitySystemScript.get_theater_real_cities(state.active_theater_slug)
	for rc in real_cities:
		var rcx := float(rc.get("x_km", 0.0))
		var rcz := float(rc.get("z_km", 0.0))
		var r_name := String(rc.get("name", ""))
		var r_elev := maxf(2.0, state.get_terrain_elevation_m(rcx, rcz))
		var rc_idx := state.get_infra_cell_index(rcx, rcz)

		# Distinct Landmark Skyscraper for major capitals/metropolises
		if r_name.find("TAIPEI") != -1:
			_add_bldg(state, Vector3(rcx, r_elev, rcz), Vector3(0.0035, 0.0360, 0.0035), 0.0, WorldState.BLDG_LANDMARK_SKYSCRAPER, rc_idx)
		elif r_name.find("KAOHSIUNG") != -1:
			_add_bldg(state, Vector3(rcx, r_elev, rcz), Vector3(0.0032, 0.0260, 0.0032), 0.0, WorldState.BLDG_LANDMARK_SKYSCRAPER, rc_idx)
		elif r_name.find("XIAMEN") != -1 or r_name.find("SEOUL") != -1 or r_name.find("DUBAI") != -1:
			_add_bldg(state, Vector3(rcx, r_elev, rcz), Vector3(0.0030, 0.0280, 0.0030), 0.0, WorldState.BLDG_LANDMARK_SKYSCRAPER, rc_idx)
		else:
			_add_bldg(state, Vector3(rcx, r_elev, rcz), Vector3(0.0028, 0.0210, 0.0028), 0.0, WorldState.BLDG_URBAN_TOWER, rc_idx)

		# Container Port Cranes & Harbor Pier Quays for coastal port cities
		if r_name.find("PORT") != -1 or r_name.find("KAOHSIUNG") != -1 or r_name.find("XIAMEN") != -1 or r_name.find("INCHEON") != -1 or r_name.find("FUZHOU") != -1:
			for crane_i in range(3):
				var c_off_x := rcx + (float(crane_i) - 1.0) * 1.8
				var c_off_z := rcz - 2.2
				var c_elev := maxf(1.0, state.get_terrain_elevation_m(c_off_x, c_off_z))
				_add_bldg(state, Vector3(c_off_x, c_elev, c_off_z), Vector3(0.0018, 0.0085, 0.0024), 0.78, WorldState.BLDG_PORT_CONTAINER_CRANE, rc_idx)

	# 2. Generate 3D Bridge Spans wherever a Highway/Rail Bridge crosses a River
	for y in range(2, g - 2):
		for x in range(2, g - 2):
			var idx := y * g + x
			if state.infra_bridge_mask[idx] > 0.5:
				var bx_km := -250.0 + (float(x) / float(g - 1)) * 500.0
				var bz_km := -250.0 + (float(y) / float(g - 1)) * 500.0
				var b_elev := maxf(2.0, state.get_terrain_elevation_m(bx_km, bz_km))
				_add_bldg(state, Vector3(bx_km, b_elev + 4.0, bz_km), Vector3(0.0042, 0.0026, 0.0115), 0.0, WorldState.BLDG_BRIDGE_SPAN, idx)

	# 3. Generate Procedural 3D City Skyscrapers, Structured City Blocks & 3D Urban Boulevard Strips across populated cells
	var block_quadrants := [
		Vector2(-0.88, -0.88),
		Vector2(0.88, -0.88),
		Vector2(-0.88, 0.88),
		Vector2(0.88, 0.88),
	]
	var is_mobile_vr := OS.has_feature("android")
	var max_bldg_cap := 450 if is_mobile_vr else 5800
	for y in range(2, g - 2):
		var z_km := -250.0 + (float(y) / float(g - 1)) * 500.0
		for x in range(2, g - 2):
			var idx := y * g + x
			var urb := state.infra_urban_density[idx]
			if urb < 0.22:
				continue
			var x_km := -250.0 + (float(x) / float(g - 1)) * 500.0
			var base_elev := maxf(2.0, state.get_terrain_elevation_m(x_km, z_km))

			var is_city := (state.infra_biome[idx] == WorldState.BIOME_URBAN_CITY or urb >= 0.48)
			# Add 3D Intersecting Urban Boulevards (N-S and E-W avenues separating the 4 city blocks)
			if is_city and state.bldg_count < max_bldg_cap and not is_mobile_vr:
				_add_bldg(state, Vector3(x_km, base_elev + 0.5, z_km), Vector3(0.0035, 0.0005, 0.0160), 0.0, WorldState.BLDG_ROAD_AVENUE, idx)
				_add_bldg(state, Vector3(x_km, base_elev + 0.5, z_km), Vector3(0.0160, 0.0005, 0.0035), 0.0, WorldState.BLDG_ROAD_AVENUE, idx)

			var cubes_in_cell := (2 if is_city else 1) if is_mobile_vr else (4 if is_city else 2)
			for c_i in range(cubes_in_cell):
				if state.bldg_count >= max_bldg_cap:
					break
				var h_seed := float((idx * 37 + c_i * 73) % 100) * 0.01
				var quad: Vector2 = block_quadrants[c_i % 4]
				var jitter_x := (fmod(float(idx * 17 + c_i * 31), 11.0) / 5.5 - 1.0) * 0.24
				var jitter_z := (fmod(float(idx * 23 + c_i * 43), 11.0) / 5.5 - 1.0) * 0.24
				var ox := quad.x + jitter_x
				var oz := quad.y + jitter_z
				var bx := x_km + ox
				var bz := z_km + oz
				var b_elev := maxf(2.0, state.get_terrain_elevation_m(bx, bz))
				# Realistic spatial scale: Village houses (6.5-10mm wide, 5.5-10mm tall), Skyscrapers (9-15mm wide, 16-55mm tall)
				# Compared to tanks (~5.6mm wide, ~11mm long) and soldiers (~1.6mm wide, ~3.6mm tall)
				var w_m := (0.0090 + h_seed * 0.0060) if is_city else (0.0065 + h_seed * 0.0035)
				var d_m := (0.0090 + fmod(h_seed * 1.7, 1.0) * 0.0060) if is_city else (0.0065 + fmod(h_seed * 1.7, 1.0) * 0.0035)
				var h_m := (0.0160 + h_seed * 0.0380 * urb) if is_city else (0.0055 + h_seed * 0.0045)
				var b_type := WorldState.BLDG_URBAN_TOWER if (is_city and h_seed > 0.32) else WorldState.BLDG_VILLAGE_HOUSE
				# Align city buildings to the orthogonal urban street grid!
				var yaw := 0.0 if is_city else fmod(h_seed * 1.57, 0.78)
				_add_bldg(state, Vector3(bx, b_elev, bz), Vector3(w_m, h_m, d_m), yaw, b_type, idx)

	state.bldg_count = state.bldg_pos_km.size()


static func _add_bldg(state: WorldState, pos_km: Vector3, scale_m: Vector3, yaw_rad: float, b_type: int, cell_idx: int) -> void:
	state.bldg_pos_km.append(pos_km)
	state.bldg_scale_m.append(scale_m)
	state.bldg_yaw_rad.append(yaw_rad)
	state.bldg_type.append(b_type)
	state.bldg_cell_idx.append(cell_idx)
	state.bldg_count += 1


## Advances 3D Military Logistics Trains along railway corridors, checks for severed tracks/bridges,
## and processes Forward Airfield Ground Capture by Infantry / Armor / Quadruped Robot Dogs.
static func step(state: WorldState, sim_db: Node, dt: float) -> void:
	if dt <= 0.0:
		return

	# 1. Step Military Logistics Trains along Railway Corridors (`train_pos_km`)
	var p_dom: PackedByteArray = sim_db.plat_domain_id
	var max_pid: int = p_dom.size()
	var train_speed_km_s := 0.24 # Scaled tactical rail speed (~85 knots with simulation pacing)

	for tid in range(state.train_count):
		if state.train_active[tid] == 0:
			continue
		var cur_p := state.train_pos_km[tid]
		# Check if track or bridge under the train has been bombed (`destruction_level >= 0.45`)
		var destr := state.sample_destruction_level(cur_p.x, cur_p.z)
		if destr >= 0.45:
			if state.train_derailed[tid] == 0:
				state.train_derailed[tid] = 1
				state.trains_derailed_count += 1
			continue
		else:
			state.train_derailed[tid] = 0

		var s_km := state.train_start_km[tid]
		var e_km := state.train_end_km[tid]
		var track_len := maxf(1.0, Vector2(s_km.x, s_km.z).distance_to(Vector2(e_km.x, e_km.z)))
		var dir_s := state.train_dir_sign[tid]
		var next_prog := state.train_progress[tid] + dir_s * (train_speed_km_s * dt) / track_len
		if next_prog >= 1.0:
			next_prog = 1.0
			state.train_dir_sign[tid] = -1.0
		elif next_prog <= 0.0:
			next_prog = 0.0
			state.train_dir_sign[tid] = 1.0
		state.train_progress[tid] = next_prog

		var nx := lerpf(s_km.x, e_km.x, next_prog)
		var nz := lerpf(s_km.z, e_km.z, next_prog)
		var ny := maxf(2.0, state.get_terrain_elevation_m(nx, nz))
		state.train_pos_km[tid] = Vector3(nx, ny, nz)
		var hdg := atan2((e_km.z - s_km.z) * state.train_dir_sign[tid], (e_km.x - s_km.x) * state.train_dir_sign[tid])
		state.train_heading_rad[tid] = hdg

		# High-capacity train resupply to nearby friendly ground/SAM units within 24 km
		if (state.tick_id & 7) == 0:
			var t_fac := state.train_faction[tid]
			var r_sq := 24.0 * 24.0
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == t_fac and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid > 0 and pid < max_pid and p_dom[pid] == 0:
						var up := state.unit_pos[uid]
						var d_sq := (up.x - nx) * (up.x - nx) + (up.z - nz) * (up.z - nz)
						if d_sq <= r_sq:
							var p_def: Dictionary = sim_db.platforms_by_id[pid]
							var max_a1: int = int(p_def.get("weapon_1_qty", 4))
							if state.unit_ammo_1[uid] < max_a1:
								state.unit_ammo_1[uid] = max_a1
								state.resupply_events_count += 1

	# 2. Check Forward Airfield / Airport Ground Capture by Land Units (Every 10 ticks)
	if (state.tick_id % 10) == 0:
		for s_i in range(state.active_sites.size()):
			var st: Dictionary = state.active_sites[s_i]
			if String(st.get("site_type", "")) != "AIRBASE":
				continue
			var sx := float(st.get("x_km", 0.0))
			var sz := float(st.get("z_km", 0.0))
			var owner_str := String(st.get("faction_owner", "BLUE"))
			var blue_near := 0
			var red_near := 0
			var cap_r_sq := 10.0 * 10.0

			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
					var pid := state.unit_platform_id[uid]
					if pid > 0 and pid < max_pid and p_dom[pid] == 0:
						var up := state.unit_pos[uid]
						var d_sq := (up.x - sx) * (up.x - sx) + (up.z - sz) * (up.z - sz)
						if d_sq <= cap_r_sq:
							if state.unit_faction[uid] == WorldState.FACTION_BLUE:
								blue_near += 1
							else:
								red_near += 1

			if blue_near >= 1 and red_near == 0 and owner_str != "BLUE":
				st["faction_owner"] = "BLUE"
				st["crater_timer_sec"] = 0.0
				state.airfields_captured_count += 1
			elif red_near >= 1 and blue_near == 0 and owner_str != "RED":
				st["faction_owner"] = "RED"
				st["crater_timer_sec"] = 0.0
				state.airfields_captured_count += 1


## Builds a 128x128 RGBA8 texture (`terrain_infra_map`) for `war_table_terrain.gdshader`:
## - R = Nature / Forest Canopy Density [0..1]
## - G = Hydrological River & Bridge Network [0..1]
## - B = Highway Road & Railway Infrastructure [0..1]
## - A = Dynamic War Destruction / Scorched Rubble & Craters [0..1]
static func build_infra_image(state: WorldState) -> Image:
	var g := WorldState.CIV_GRID_SIZE
	var bytes := PackedByteArray()
	bytes.resize(g * g * 4)
	var total := g * g

	if state.infra_forest_density.size() == total:
		for i in range(total):
			var r_forest := clampi(int(state.infra_forest_density[i] * 255.0), 0, 255)
			var g_river := clampi(int(state.infra_river_mask[i] * 255.0), 0, 255)
			var road_rail := maxf(state.infra_road_mask[i] * 0.72, state.infra_rail_mask[i])
			if state.infra_bridge_mask[i] > 0.35:
				road_rail = 1.0
			var b_infra := clampi(int(road_rail * 255.0), 0, 255)
			var a_destr := clampi(int(state.destruction_level[i] * 255.0), 0, 255)

			var b_idx := i * 4
			bytes[b_idx] = r_forest
			bytes[b_idx + 1] = g_river
			bytes[b_idx + 2] = b_infra
			bytes[b_idx + 3] = a_destr

	return Image.create_from_data(g, g, false, Image.FORMAT_RGBA8, bytes)

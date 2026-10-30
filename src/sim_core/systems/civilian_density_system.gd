class_name CivilianDensitySystem
extends RefCounted
## Manages the 128x128 Spreading Civilian Density Field (measured in civilians/m^2) across the 500km x 500km theater.
## Solves the 2D Conservative Advection-Diffusion Evacuation PDE:
##   d(rho)/dt = D * Laplacian(rho) - div(rho * v_evac)
## using the C# .NET 8 Multi-Threaded SIMD `SimLodKernel` (with deterministic GDScript fallback).

const BASE_DIFFUSION_RATE := 0.14
const EVAC_ADVECTION_RATE := 0.85


## Seeds realistic metropolitan centers, suburban rings, and valley corridors in civilians/m^2 on passable land.
static func seed_theater_civilian_density(state: WorldState) -> void:
	var g := WorldState.CIV_GRID_SIZE
	var total_cells := g * g
	state.civ_density_m2.resize(total_cells)
	state.civ_density_m2.fill(0.0)
	state.civ_initial_m2.resize(total_cells)
	state.civ_initial_m2.fill(0.0)
	state.civ_passability.resize(total_cells)
	state.civ_passability.fill(0.0)
	state.civ_threat_field.resize(total_cells)
	state.civ_threat_field.fill(0.0)
	state.civ_flux_activity.resize(total_cells)
	state.civ_flux_activity.fill(0.0)

	var step_km := 500.0 / float(g - 1)

	# 1. Compute terrain passability per cell (0.0 in ocean, 1.0 on flat coastal/valley land, lower on steep peaks)
	for y in range(g):
		var z_km := float(y) * step_km - 250.0
		for x in range(g):
			var x_km := float(x) * step_km - 250.0
			var elev := state.get_terrain_elevation_m(x_km, z_km)
			var idx := y * g + x
			if elev <= 0.5:
				state.civ_passability[idx] = 0.0 # Water/Ocean cannot hold land civilian density
			elif elev < 650.0:
				state.civ_passability[idx] = 1.0 # Flat plains / river valleys / urban basins
			elif elev < 2200.0:
				state.civ_passability[idx] = clampf(1.0 - (elev - 650.0) / 2200.0, 0.25, 0.90)
			else:
				state.civ_passability[idx] = 0.10

	# 2. Gather urban population epicenters from theater strategic sites + Real-World GIS Metropolitan Hubs
	var hubs: Array[Dictionary] = []
	for st in state.active_sites:
		var sx := float(st.get("x_km", 0.0))
		var sz := float(st.get("z_km", 0.0))
		var stype := String(st.get("site_type", "URBAN"))
		var peak_rho := 0.038 if stype in ["PORT", "URBAN", "HQ"] else 0.024
		hubs.append({"x": sx, "z": sz, "peak_rho": peak_rho, "radius_km": 26.0})

	var real_cities := get_theater_real_cities(state.active_theater_slug)
	for rc in real_cities:
		var rcx := float(rc.get("x_km", 0.0))
		var rcz := float(rc.get("z_km", 0.0))
		if state.get_terrain_elevation_m(rcx, rcz) > 1.0:
			hubs.append({
				"x": rcx,
				"z": rcz,
				"peak_rho": float(rc.get("peak_rho", 0.034)),
				"radius_km": float(rc.get("radius_km", 28.0)),
			})

	# 3. Deposit Gaussian metropolitan cores & suburban corridors onto passable land cells
	var total_pop := 0.0
	for y in range(1, g - 1):
		var z_km := float(y) * step_km - 250.0
		for x in range(1, g - 1):
			var idx := y * g + x
			var pass_val := state.civ_passability[idx]
			if pass_val <= 0.01:
				continue
			var x_km := float(x) * step_km - 250.0
			var rho := 0.00025 * pass_val # Baseline rural density (250 people / km^2)

			for h in hubs:
				var hx: float = float(h["x"])
				var hz: float = float(h["z"])
				var rad: float = float(h["radius_km"])
				var pk: float = float(h["peak_rho"])
				var d_sq := (x_km - hx) * (x_km - hx) + (z_km - hz) * (z_km - hz)
				if d_sq < rad * rad * 2.5:
					var gauss := exp(-d_sq / (2.0 * (rad * 0.48) * (rad * 0.48)))
					rho += pk * gauss * pass_val

			rho = clampf(rho, 0.0, 0.050)
			state.civ_density_m2[idx] = rho
			state.civ_initial_m2[idx] = rho
			total_pop += rho * WorldState.CIV_CELL_AREA_M2

	state.total_theater_civilians = total_pop
	state.total_displaced_civilians = 0.0


## Returns authentic real-world metropolitan cities, population densities & coordinates for each 500x500 km theater.
static func get_theater_real_cities(theater_slug: String) -> Array[Dictionary]:
	if theater_slug.find("hormuz") != -1:
		return [
			{"name": "DUBAI METRO (UAE)", "x_km": 48.0, "z_km": 118.0, "peak_rho": 0.042, "radius_km": 30.0},
			{"name": "SHARJAH / AJMAN (UAE)", "x_km": 62.0, "z_km": 102.0, "peak_rho": 0.034, "radius_km": 24.0},
			{"name": "FUJAIRAH PORT CITY (UAE)", "x_km": 88.0, "z_km": 112.0, "peak_rho": 0.028, "radius_km": 22.0},
			{"name": "KHASAB MUSANDAM (OMAN)", "x_km": 18.0, "z_km": 48.0, "peak_rho": 0.024, "radius_km": 18.0},
			{"name": "BANDAR ABBAS (IRAN)", "x_km": -15.0, "z_km": -95.0, "peak_rho": 0.038, "radius_km": 28.0},
			{"name": "QESHM ISLAND CITY (IRAN)", "x_km": -24.0, "z_km": -35.0, "peak_rho": 0.028, "radius_km": 20.0},
			{"name": "MINAB / JASK LITTORAL (IRAN)", "x_km": 95.0, "z_km": -75.0, "peak_rho": 0.026, "radius_km": 22.0},
		]
	elif theater_slug.find("korea") != -1:
		return [
			{"name": "SEOUL CAPITAL MEGACITY (ROK)", "x_km": -32.0, "z_km": 48.0, "peak_rho": 0.048, "radius_km": 34.0},
			{"name": "INCHEON PORT METRO (ROK)", "x_km": -72.0, "z_km": 56.0, "peak_rho": 0.038, "radius_km": 26.0},
			{"name": "SUWON / PYEONGTAEK (ROK)", "x_km": -24.0, "z_km": 98.0, "peak_rho": 0.036, "radius_km": 26.0},
			{"name": "CHUNCHEON / GANGNEUNG (ROK)", "x_km": 42.0, "z_km": 52.0, "peak_rho": 0.026, "radius_km": 22.0},
			{"name": "PYONGYANG CAPITAL (DPRK)", "x_km": -55.0, "z_km": -68.0, "peak_rho": 0.040, "radius_km": 30.0},
			{"name": "KAESONG BORDER CITY (DPRK)", "x_km": -35.0, "z_km": -8.0, "peak_rho": 0.028, "radius_km": 20.0},
			{"name": "WONSAN EAST SEA PORT (DPRK)", "x_km": 58.0, "z_km": -76.0, "peak_rho": 0.030, "radius_km": 22.0},
		]
	elif theater_slug.find("baltic") != -1 or theater_slug.find("suwalki") != -1:
		return [
			{"name": "VILNIUS CAPITAL (LITHUANIA)", "x_km": 122.0, "z_km": -18.0, "peak_rho": 0.038, "radius_km": 28.0},
			{"name": "KAUNAS (LITHUANIA)", "x_km": 68.0, "z_km": -42.0, "peak_rho": 0.032, "radius_km": 24.0},
			{"name": "SUWALKI / AUGUSTOW (POLAND)", "x_km": 45.0, "z_km": 55.0, "peak_rho": 0.028, "radius_km": 22.0},
			{"name": "BIALYSTOK (POLAND)", "x_km": 32.0, "z_km": 125.0, "peak_rho": 0.034, "radius_km": 26.0},
			{"name": "KLAIPEDA PORT (LITHUANIA)", "x_km": -42.0, "z_km": -95.0, "peak_rho": 0.030, "radius_km": 22.0},
			{"name": "KALININGRAD CITY (RUSSIA)", "x_km": -52.0, "z_km": 32.0, "peak_rho": 0.036, "radius_km": 26.0},
			{"name": "GRODNO (BELARUS)", "x_km": 118.0, "z_km": 78.0, "peak_rho": 0.032, "radius_km": 24.0},
		]
	elif theater_slug.find("himalaya") != -1 or theater_slug.find("lac") != -1:
		return [
			{"name": "LEH LADAKH TOWN (INDIA)", "x_km": -75.0, "z_km": 65.0, "peak_rho": 0.028, "radius_km": 24.0},
			{"name": "KARGIL / DRASS VALLEY (INDIA)", "x_km": -142.0, "z_km": 92.0, "peak_rho": 0.026, "radius_km": 22.0},
			{"name": "DISKIT / NUBRA VALLEY (INDIA)", "x_km": -58.0, "z_km": -18.0, "peak_rho": 0.022, "radius_km": 20.0},
			{"name": "SKARDU BASIN (PAKISTAN)", "x_km": -125.0, "z_km": -85.0, "peak_rho": 0.028, "radius_km": 24.0},
			{"name": "RUTOG / GAR NGARI (CHINA)", "x_km": 92.0, "z_km": 48.0, "peak_rho": 0.024, "radius_km": 22.0},
			{"name": "HOTAN SOUTHERN OASIS (CHINA)", "x_km": 115.0, "z_km": -52.0, "peak_rho": 0.030, "radius_km": 26.0},
		]
	elif theater_slug.find("ukraine") != -1 or theater_slug.find("donbas") != -1:
		return [
			{"name": "DNIPRO / MYRHOROD HUB (UKRAINE)", "x_km": -122.0, "z_km": -78.0, "peak_rho": 0.044, "radius_km": 32.0},
			{"name": "ZAPORIZHZHIA DNIPRO CITY (UKRAINE)", "x_km": -92.0, "z_km": 18.0, "peak_rho": 0.040, "radius_km": 28.0},
			{"name": "KRAMATORSK / POKROVSK (UKRAINE)", "x_km": -24.0, "z_km": -42.0, "peak_rho": 0.034, "radius_km": 26.0},
			{"name": "ODESA / MYKOLAIV LITTORAL (UKRAINE)", "x_km": -178.0, "z_km": 98.0, "peak_rho": 0.042, "radius_km": 30.0},
			{"name": "DONETSK METROPOLIS (DONBAS)", "x_km": 52.0, "z_km": -12.0, "peak_rho": 0.042, "radius_km": 30.0},
			{"name": "MARIUPOL / BERDIANSK (AZOV)", "x_km": 44.0, "z_km": 78.0, "peak_rho": 0.034, "radius_km": 24.0},
			{"name": "ROSTOV-ON-DON METRO (RUSSIA)", "x_km": 158.0, "z_km": -32.0, "peak_rho": 0.042, "radius_km": 30.0},
		]
	elif theater_slug.find("mexico") != -1 or theater_slug.find("rio_grande") != -1:
		return [
			{"name": "SAN ANTONIO METRO (TEXAS USA)", "x_km": -38.0, "z_km": -152.0, "peak_rho": 0.044, "radius_km": 32.0},
			{"name": "CORPUS CHRISTI PORT (TEXAS USA)", "x_km": 82.0, "z_km": -95.0, "peak_rho": 0.034, "radius_km": 24.0},
			{"name": "LAREDO / NUEVO LAREDO CROSSING", "x_km": -45.0, "z_km": -48.0, "peak_rho": 0.036, "radius_km": 26.0},
			{"name": "MCALLEN / REYNOSA RIO GRANDE", "x_km": 25.0, "z_km": -12.0, "peak_rho": 0.038, "radius_km": 28.0},
			{"name": "MONTERREY MEGACITY (NUEVO LEON MEX)", "x_km": -88.0, "z_km": 88.0, "peak_rho": 0.048, "radius_km": 34.0},
			{"name": "SALTILLO SIERRA MADRE (COAHUILA MEX)", "x_km": -135.0, "z_km": 115.0, "peak_rho": 0.036, "radius_km": 26.0},
			{"name": "MATAMOROS / TAMPICO GULF (MEX)", "x_km": 92.0, "z_km": 68.0, "peak_rho": 0.034, "radius_km": 24.0},
		]
	# Default: Taiwan Strait (`strait_theater`)
	return [
		{"name": "TAIPEI METROPOLIS (ROC)", "x_km": 135.0, "z_km": -115.0, "peak_rho": 0.046, "radius_km": 32.0},
		{"name": "HSINCHU SILICON HUB (ROC)", "x_km": 110.0, "z_km": -42.0, "peak_rho": 0.038, "radius_km": 26.0},
		{"name": "TAICHUNG BASIN (ROC)", "x_km": 98.0, "z_km": 15.0, "peak_rho": 0.040, "radius_km": 28.0},
		{"name": "KAOHSIUNG / TAINAN METRO (ROC)", "x_km": 88.0, "z_km": 115.0, "peak_rho": 0.042, "radius_km": 30.0},
		{"name": "FUZHOU CAPITAL (FUJIAN PRC)", "x_km": -142.0, "z_km": -68.0, "peak_rho": 0.042, "radius_km": 30.0},
		{"name": "PUTIAN / QUANZHOU BAY (PRC)", "x_km": -115.0, "z_km": 5.0, "peak_rho": 0.038, "radius_km": 28.0},
		{"name": "XIAMEN / ZHANGZHOU METRO (PRC)", "x_km": -128.0, "z_km": 78.0, "peak_rho": 0.044, "radius_km": 30.0},
	]


## Advances the 2D Conservative Advection-Diffusion PDE by `dt` seconds.
static func step(state: WorldState, cs_kernel: Object, dt: float) -> void:
	if dt <= 0.0 or state.civ_density_m2.is_empty():
		return

	var g := WorldState.CIV_GRID_SIZE
	var total_cells := g * g

	# 1. Inject localized combat repulsion from active frontline units under fire
	var inv_500 := float(g - 1) / 500.0
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			var thr := state.unit_threat_level[uid]
			if thr > 0.20:
				var p := state.unit_pos[uid]
				var gx := clampi(int((p.x + 250.0) * inv_500), 1, g - 2)
				var gy := clampi(int((p.z + 250.0) * inv_500), 1, g - 2)
				var c_idx := gy * g + gx
				state.civ_threat_field[c_idx] = minf(3.0, state.civ_threat_field[c_idx] + thr * dt * 1.8)

	# 2. Solve 2D Conservative Advection-Diffusion PDE via C# Multi-Threaded SIMD Kernel (or GDScript fallback)
	if cs_kernel != null and cs_kernel.has_method("StepCivilianDensityFieldParallel"):
		var next_arr: PackedFloat32Array = cs_kernel.call(
			"StepCivilianDensityFieldParallel",
			state.civ_density_m2,
			state.civ_passability,
			state.civ_threat_field,
			state.civ_flux_activity,
			g,
			dt,
			BASE_DIFFUSION_RATE,
			EVAC_ADVECTION_RATE
		)
		if next_arr.size() == total_cells:
			state.civ_density_m2 = next_arr
	else:
		_step_gdscript_fallback(state, g, dt)

	# 3. Decay threat field & compute total displaced population (L1 Earth-Mover distance from initial census)
	var decay := clampf(1.0 - dt * 0.25, 0.80, 0.99)
	var flux_decay := clampf(1.0 - dt * 0.40, 0.75, 0.98)
	var l1_diff_sum := 0.0
	for i in range(total_cells):
		state.civ_threat_field[i] *= decay
		state.civ_flux_activity[i] *= flux_decay
		l1_diff_sum += absf(state.civ_density_m2[i] - state.civ_initial_m2[i])

	state.total_displaced_civilians = 0.5 * l1_diff_sum * WorldState.CIV_CELL_AREA_M2


static func _step_gdscript_fallback(state: WorldState, g: int, dt: float) -> void:
	var rho_in := state.civ_density_m2
	var pass_in := state.civ_passability
	var threat_in := state.civ_threat_field
	var next_rho := rho_in.duplicate()

	for y in range(1, g - 1):
		var row := y * g
		for x in range(1, g - 1):
			var idx := row + x
			var r_c := rho_in[idx]
			if r_c <= 1e-6 or pass_in[idx] <= 0.01:
				continue
			var t_c := threat_in[idx]
			var eff_d := BASE_DIFFUSION_RATE * (1.0 + t_c * 18.0)
			var n_indices := [idx - g, idx + g, idx - 1, idx + 1]
			for n_idx in n_indices:
				var p_n: float = pass_in[n_idx]
				if p_n <= 0.01:
					continue
				var r_n: float = rho_in[n_idx]
				var t_n: float = threat_in[n_idx]
				var d_flux := maxf(0.0, r_c - r_n) * eff_d * p_n * dt * 0.20
				var e_flux := r_c * maxf(0.0, t_c - t_n) * EVAC_ADVECTION_RATE * p_n * dt * 0.22
				var out_f := minf(r_c * 0.15, d_flux + e_flux)
				if out_f > 1e-7:
					next_rho[idx] -= out_f
					next_rho[n_idx] += out_f
					state.civ_flux_activity[idx] = minf(1.0, state.civ_flux_activity[idx] + 0.25)

	state.civ_density_m2 = next_rho

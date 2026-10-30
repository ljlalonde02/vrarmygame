class_name SimLodSystem
extends RefCounted
## Manages the 3-Tier Zoom Sim-LOD Engine + C# .NET 8 Multi-Threaded SIMD Accelerator (`SimLodKernel.cs`).
## Dynamically shifts units between:
## - Tier 0 (Micro Agent Physics, 10 Hz): Units inside zoomed-in camera frustum or selected / terminal combat
## - Tier 1 (Operational Salvo, 5 Hz): Units in medium-zoom frustum
## - Tier 2 (Macro Lanchester Aggregation, 1 Hz): Off-screen or macro-zoomed echelons


static func create_cs_kernel() -> Object:
	var cs_path := "res://src/sim_core/cs/SimLodKernel.cs"
	if ResourceLoader.exists(cs_path):
		var script_res = load(cs_path)
		if script_res != null and script_res.can_instantiate():
			return script_res.new()
	if ClassDB.class_exists("SimLodKernel"):
		return ClassDB.instantiate("SimLodKernel")
	return null


static func update_sim_lod_tiers(state: WorldState, cs_kernel: Object) -> void:
	if state.unit_count <= 0:
		state.lod_tier0_count = 0
		state.lod_tier1_count = 0
		state.lod_tier2_count = 0
		return

	var zoom := maxf(state.sim_focus_zoom, 1.0)
	state.sim_focus_radius_km = clampf(215.0 / zoom, 22.0, 230.0)

	if cs_kernel != null and cs_kernel.has_method("ComputeUnitSimLodTiersParallel"):
		var lod_arr: PackedByteArray = cs_kernel.call(
			"ComputeUnitSimLodTiersParallel",
			state.unit_pos,
			state.unit_active,
			state.unit_echelon,
			state.unit_threat_level,
			state.unit_count,
			state.sim_focus_center_km.x,
			state.sim_focus_center_km.y,
			state.sim_focus_radius_km,
			zoom,
			state.selected_unit_id,
			state.tick_id & 1
		)
		if lod_arr.size() >= state.unit_count:
			for u in range(state.unit_count):
				state.unit_sim_lod[u] = lod_arr[u]
	else:
		var fx := state.sim_focus_center_km.x
		var fz := state.sim_focus_center_km.y
		var r_micro_sq := state.sim_focus_radius_km * state.sim_focus_radius_km
		var r_oper_sq := (state.sim_focus_radius_km * 1.85) * (state.sim_focus_radius_km * 1.85)
		var is_macro := zoom < 1.8
		var is_micro := zoom >= 3.2
		for u in range(state.unit_count):
			if state.unit_active[u] == 0:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_2_MACRO
				continue
			if u == state.selected_unit_id:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_0_MICRO
				continue
			var p := state.unit_pos[u]
			var d_sq := (p.x - fx) * (p.x - fx) + (p.z - fz) * (p.z - fz)
			if is_micro and d_sq <= r_micro_sq:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_0_MICRO
			elif not is_macro and d_sq <= r_oper_sq:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_1_OPERATIONAL
			elif d_sq <= r_micro_sq and state.unit_threat_level[u] > 0.35:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_0_MICRO
			else:
				state.unit_sim_lod[u] = WorldState.LOD_TIER_2_MACRO

	var c0 := 0
	var c1 := 0
	var c2 := 0
	for u in range(state.unit_count):
		if state.unit_active[u] == 0:
			continue
		var tier := state.unit_sim_lod[u]
		if tier == WorldState.LOD_TIER_0_MICRO:
			c0 += 1
		elif tier == WorldState.LOD_TIER_1_OPERATIONAL:
			c1 += 1
		else:
			c2 += 1
	state.lod_tier0_count = c0
	state.lod_tier1_count = c1
	state.lod_tier2_count = c2


static func step_macro_echelons(state: WorldState, cs_kernel: Object, dt: float) -> void:
	if state.lod_tier2_count <= 0 or cs_kernel == null:
		return
	if cs_kernel.has_method("StepMacroLanchesterEchelonsParallel"):
		var next_hp: PackedFloat32Array = cs_kernel.call(
			"StepMacroLanchesterEchelonsParallel",
			state.unit_pos,
			state.unit_active,
			state.unit_faction,
			state.unit_echelon,
			state.unit_sim_lod,
			state.unit_hp,
			state.unit_max_hp,
			state.unit_parent_id,
			state.unit_count,
			dt
		)
		if next_hp.size() >= state.unit_count:
			for u in range(state.unit_count):
				if state.unit_active[u] == 1 and state.unit_sim_lod[u] == WorldState.LOD_TIER_2_MACRO:
					var prev_hp := state.unit_hp[u]
					var nhp := next_hp[u]
					state.unit_hp[u] = nhp
					if nhp < prev_hp - 0.05:
						var loss_frac := (prev_hp - nhp) / maxf(1.0, state.unit_max_hp[u])
						if state.unit_faction[u] == WorldState.FACTION_BLUE:
							state.blue_lost_musd += loss_frac * 0.15
							if ((state.tick_id + u) & 3) == 0:
								state.blue_personnel_wia += 1
								state.red_munitions_expended += 1
						else:
							state.red_lost_musd += loss_frac * 0.15
							if ((state.tick_id + u) & 3) == 0:
								state.red_personnel_wia += 1
								state.blue_munitions_expended += 1
					if nhp <= 0.5:
						state.unit_hp[u] = 0.0
						state.unit_active[u] = 0
						if state.unit_faction[u] == WorldState.FACTION_BLUE:
							state.blue_units_destroyed += 1
							state.blue_personnel_kia += 4
							state.blue_armor_lost += 1
						else:
							state.red_units_destroyed += 1
							state.red_personnel_kia += 4
							state.red_armor_lost += 1

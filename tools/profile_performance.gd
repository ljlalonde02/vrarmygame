extends SceneTree

func _init() -> void:
	print("==================================================================")
	print("[PROFILER] Starting Deep Performance & Bottleneck Analysis...")
	print("==================================================================")
	
	var bunker_scene: PackedScene = load("res://src/presentation/bunker/command_bunker.tscn")
	var t0 := Time.get_ticks_usec()
	var bunker := bunker_scene.instantiate()
	var t_inst := Time.get_ticks_usec() - t0
	print("  [1] Bunker instantiate() took: %.2f ms" % (float(t_inst) / 1000.0))
	
	root.add_child(bunker)
	bunker.initialize_bunker()
	var t_ready := Time.get_ticks_usec() - t0 - t_inst
	print("  [2] Bunker initialize_bunker() took: %.2f ms" % (float(t_ready) / 1000.0))
	
	var sim_server: SimServer = bunker.sim_server
	var world_state: WorldState = sim_server.world_state
	print("  [3] Active units in scenario: %d" % world_state.unit_count)
	
	# Profile 1 simulation step_tick
	var systems_to_profile := [
		["WeatherSolar", func(): sim_server.weather_solar_system.step(world_state, 0.1)],
		["SimLodTiers", func(): sim_server.SimLodSystemScript.update_sim_lod_tiers(world_state, sim_server.cs_kernel)],
		["Kinematics", func(): KinematicsSystem.step(world_state, sim_server.sim_db_ref, 0.1)],
		["SpatialGridRebuild", func(): sim_server.spatial_grid.rebuild(world_state)],
		["ElectronicWarfare", func(): ElectronicWarfareSystem.step(world_state, sim_server.sim_db_ref, sim_server.spatial_grid)],
		["SensorLoS", func(): SensorLoSSystem.step(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, sim_server.cs_kernel)],
		["UnitTacticalAI", func(): sim_server.UnitTacticalAISystemScript.step(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, 0.1)],
		["SwarmIntelligence", func(): sim_server.SwarmIntelligenceSystemScript.step_swarm_intelligence(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, 0.1)],
		["Logistics", func(): sim_server.LogisticsSystemScript.step(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, 0.1)],
		["TerrainInfrastructure", func(): sim_server.TerrainInfrastructureSystemScript.step(world_state, sim_server.sim_db_ref, 0.1)],
		["SalvoCombat", func(): SalvoCombatSystem.step(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, 0.1)],
		["MacroEchelons", func(): sim_server.SimLodSystemScript.step_macro_echelons(world_state, sim_server.cs_kernel, 0.1)],
		["StrategicMdd", func(): sim_server.StrategicMddSystemScript.step(world_state, sim_server.sim_db_ref, sim_server.cs_kernel, 0.1)],
		["CivilianTraffic", func(): sim_server.CivilianTrafficConvoySystemScript.step(world_state, sim_server.sim_db_ref, 0.1)],
		["CivilianDensity", func(): sim_server.CivilianDensitySystemScript.step(world_state, sim_server.cs_kernel, 0.1)],
		["GlobalOrbat", func(): sim_server.GlobalOrbatSystemScript.step_global_orbat(world_state, 0.1)],
		["BudgetTech", func(): sim_server.BudgetTechSystemScript.step(world_state, sim_server.sim_db_ref, 0.1)],
		["CoordinatedStrike", func(): sim_server.CoordinatedStrikeSystemScript.step_combined_arms_synergy(world_state, sim_server.sim_db_ref, sim_server.spatial_grid, 0.1)],
		["EchelonCluster", func(): EchelonClusterSystem.step(world_state)],
		["UpdateFoWTexture", func(): sim_server._update_fow_global_texture()],
	]
	
	print("\n--- [4] Detailed System Tick Breakdown (Single 0.1s Tick) ---")
	var total_tick_ms := 0.0
	for entry in systems_to_profile:
		var s_name: String = entry[0]
		var s_fn: Callable = entry[1]
		var t_start := Time.get_ticks_usec()
		s_fn.call()
		var dur_ms := float(Time.get_ticks_usec() - t_start) / 1000.0
		total_tick_ms += dur_ms
		var alert := " *** BOTTLENECK ***" if dur_ms > 15.0 else ""
		print("    %-25s: %8.2f ms%s" % [s_name, dur_ms, alert])
	print("    -----------------------------------------")
	print("    TOTAL SIM TICK TIME      : %8.2f ms" % total_tick_ms)
	
	# Profile Presentation _process frames
	print("\n--- [5] Presentation & Render Frame Breakdown ---")
	var vs = bunker.war_table.get_node_or_null("VisualSyncController")
	if vs != null:
		var t_vs0 := Time.get_ticks_usec()
		vs._process(0.016)
		var t_vs := float(Time.get_ticks_usec() - t_vs0) / 1000.0
		print("    VisualSyncController._process: %.2f ms" % t_vs)
	
	var rig = bunker.desktop_rig
	if rig != null:
		var t_rig0 := Time.get_ticks_usec()
		rig._process(0.016)
		var t_rig := float(Time.get_ticks_usec() - t_rig0) / 1000.0
		print("    DesktopCommandRig._process   : %.2f ms" % t_rig)
	
	# Profile 5 frames of full step_tick
	print("\n--- [6] 5 Full Frames (sim + presentation) ---")
	for f in range(5):
		var tf0 := Time.get_ticks_usec()
		sim_server.step_tick(0.1)
		if vs != null:
			vs._process(0.016)
		var frame_ms := float(Time.get_ticks_usec() - tf0) / 1000.0
		print("    Frame %2d: %6.2f ms (%.1f FPS)" % [f, frame_ms, 1000.0 / maxf(frame_ms, 0.001)])
		
	print("\n==================================================================")
	print("[PROFILER] Analysis Finished cleanly.")
	print("==================================================================")
	quit()

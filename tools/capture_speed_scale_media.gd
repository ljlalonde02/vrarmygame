extends SceneTree

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames"

var bunker: CommandBunker = null
var cam: Camera3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_capture_sequence, CONNECT_ONE_SHOT)


func _run_capture_sequence() -> void:
	print("==================================================================")
	print("[SPEED & SCALE MEDIA CAPTURE] Capturing Visual Proofs on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var st: WorldState = bunker.sim_server.world_state
	var sdb: Node = bunker.sim_db
	var wt: Node3D = bunker.war_table

	# Wait 6 frames for shaders, meshes and textures to compile
	for f in range(6):
		await process_frame

	# ------------------------------------------------------------------
	# SCENE 1: Infantry vs Tanks vs Road vs Village Houses (Speed & Scale)
	# ------------------------------------------------------------------
	print(">> Capturing Scene 1: Combined Arms Speed & Miniature Dimensional Proportions...")
	wt.zoom_scale = 4.8 # High micro-tactical zoom
	wt.pan_offset_km = Vector2(20.0, -15.0)
	cam.global_position = Vector3(0.0, 1.35, 0.75)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	# Setup an infantry company and a tank platoon marching along an avenue
	var pid_inf: int = int(sdb.get_platform_id("specops_mountain_team"))
	var pid_arm: int = int(sdb.get_platform_id("m1a2_sepv3_platoon"))
	var pid_dog: int = int(sdb.get_platform_id("vision_60_q_ugv"))

	var u_inf := 0
	var u_arm := 1
	var u_dog := 2

	st.unit_active[u_inf] = 1
	st.unit_faction[u_inf] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_inf] = pid_inf
	st.unit_pos[u_inf] = Vector3(18.0, 25.0, -15.0)
	st.unit_target_pos[u_inf] = Vector3(35.0, 25.0, -15.0)
	st.unit_has_waypoint[u_inf] = 1
	st.unit_sim_lod[u_inf] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_arm] = 1
	st.unit_faction[u_arm] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_arm] = pid_arm
	st.unit_pos[u_arm] = Vector3(17.5, 25.0, -14.2)
	st.unit_target_pos[u_arm] = Vector3(35.0, 25.0, -14.2)
	st.unit_has_waypoint[u_arm] = 1
	st.unit_sim_lod[u_arm] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_dog] = 1
	st.unit_faction[u_dog] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_dog] = pid_dog
	st.unit_pos[u_dog] = Vector3(18.5, 25.0, -15.8)
	st.unit_target_pos[u_dog] = Vector3(35.0, 25.0, -15.8)
	st.unit_has_waypoint[u_dog] = 1
	st.unit_sim_lod[u_dog] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.select_unit(u_arm)

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/scale_01_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "speed_scale_01_combined_arms_realism.png")

	# ------------------------------------------------------------------
	# SCENE 2: Attack Helicopter NOE (120m) vs Jet High BVR (11,500m)
	# ------------------------------------------------------------------
	print(">> Capturing Scene 2: Attack Helicopter NOE vs Jet Altitude & Speed...")
	wt.zoom_scale = 2.2
	wt.pan_offset_km = Vector2(45.0, 10.0)
	cam.global_position = Vector3(0.15, 1.45, 0.95)
	cam.look_at(Vector3(0.0, 0.95, -0.05), Vector3.UP)

	var pid_heli: int = int(sdb.get_platform_id("ah_64e_apache_guardian"))
	var pid_jet: int = int(sdb.get_platform_id("f_35a_lightning"))

	var u_heli := 3
	var u_jet := 4

	st.unit_active[u_heli] = 1
	st.unit_faction[u_heli] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_heli] = pid_heli
	st.unit_pos[u_heli] = Vector3(40.0, 120.0, 10.0)
	st.unit_target_pos[u_heli] = Vector3(65.0, 120.0, 10.0)
	st.unit_has_waypoint[u_heli] = 1
	st.unit_desired_alt_m[u_heli] = 120.0
	st.unit_sim_lod[u_heli] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_jet] = 1
	st.unit_faction[u_jet] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_jet] = pid_jet
	st.unit_pos[u_jet] = Vector3(35.0, 11500.0, 15.0)
	st.unit_target_pos[u_jet] = Vector3(95.0, 11500.0, 15.0)
	st.unit_has_waypoint[u_jet] = 1
	st.unit_desired_alt_m[u_jet] = 11500.0
	st.unit_sim_lod[u_jet] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.select_unit(u_heli)

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/scale_02_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "speed_scale_02_helicopter_noe_vs_jet_altitude.png")

	# ------------------------------------------------------------------
	# SCENE 3: Columbia SSBN Negative Immersion (-180m) vs Surface Fleet
	# ------------------------------------------------------------------
	print(">> Capturing Scene 3: Submarine Undersea Immersion vs Surface Fleet...")
	wt.zoom_scale = 3.0
	wt.pan_offset_km = Vector2(90.0, 40.0)
	cam.global_position = Vector3(-0.10, 1.28, 0.82)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	var pid_ssbn: int = int(sdb.get_platform_id("columbia_class_ssbn"))
	var pid_ship: int = int(sdb.get_platform_id("arleigh_burke_flt_iii"))

	var u_sub := 5
	var u_ship := 6

	st.unit_active[u_sub] = 1
	st.unit_faction[u_sub] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_sub] = pid_ssbn
	st.unit_pos[u_sub] = Vector3(88.0, -180.0, 40.0)
	st.unit_target_pos[u_sub] = Vector3(105.0, -180.0, 40.0)
	st.unit_has_waypoint[u_sub] = 1
	st.unit_desired_alt_m[u_sub] = -180.0
	st.unit_sim_lod[u_sub] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_ship] = 1
	st.unit_faction[u_ship] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_ship] = pid_ship
	st.unit_pos[u_ship] = Vector3(88.0, 0.0, 43.5)
	st.unit_target_pos[u_ship] = Vector3(105.0, 0.0, 43.5)
	st.unit_has_waypoint[u_ship] = 1
	st.unit_sim_lod[u_ship] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.select_unit(u_sub)

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/scale_03_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "speed_scale_03_submerged_submarine_immersion.png")

	# ------------------------------------------------------------------
	# SCENE 4: Hypersonic Mach 10 Salvo & Lofted Ballistic Profile
	# ------------------------------------------------------------------
	print(">> Capturing Scene 4: Hypersonic Mach 10 Salvo & Lofted Ballistic Trajectory...")
	wt.zoom_scale = 1.4
	wt.pan_offset_km = Vector2(0.0, 0.0)
	cam.global_position = Vector3(0.0, 1.55, 1.15)
	cam.look_at(Vector3(0.0, 0.90, 0.0), Vector3.UP)

	# Launch Hypersonic DF-17 / Zircon salvo
	var wid_hyp: int = int(sdb.get_weapon_id("df_17_glide_vehicle"))
	if wid_hyp <= 0:
		wid_hyp = 1
	st.spawn_munition(WorldState.FACTION_BLUE, wid_hyp, u_ship, u_sub, Vector3(-80.0, 10.0, -40.0), Vector3(60.0, 10.0, 50.0), "LOFTED_BALLISTIC")
	st.spawn_munition(WorldState.FACTION_BLUE, wid_hyp, u_ship, u_sub, Vector3(-85.0, 10.0, -35.0), Vector3(60.0, 10.0, 50.0), "LOFTED_BALLISTIC")

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.25)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/scale_04_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "speed_scale_04_hypersonic_missile_salvo.png")

	print("==================================================================")
	print("[SPEED & SCALE MEDIA CAPTURE] All 4 Stills and Frame Sequences Generated!")
	print("==================================================================")
	quit(0)


func _save_both(img: Image, filename: String) -> void:
	var path_art := "%s/%s" % [ARTIFACT_DIR, filename]
	var path_med := "%s/%s" % [MEDIA_DIR, filename]
	img.save_png(path_art)
	img.save_png(path_med)
	print("  Saved: ", filename)

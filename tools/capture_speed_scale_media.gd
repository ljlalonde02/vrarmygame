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

	# Hide ALL 2D HUD overlays so the 3D Holographic War Table and units are in 100% full unobstructed view!
	_dismiss_all_2d_overlays()

	# Wait 6 frames for shaders, meshes and textures to compile
	for f in range(6):
		await process_frame

	# ------------------------------------------------------------------
	# SCENE 1: Infantry vs Tanks vs Road vs Village Houses (Speed & Scale)
	# ------------------------------------------------------------------
	print(">> Capturing Scene 1: Combined Arms Tactical Zoom Rapproché (Speed & Scale)...")
	var v_pan := Vector2(20.0, -15.0)
	wt.set_zoom_and_pan(8.0, v_pan, true)
	cam.global_position = Vector3(0.0, 1.08, 0.28)
	cam.look_at(Vector3(0.0, 0.89, 0.0), Vector3.UP)

	# Stamp village houses along the road around the tactical encounter
	for bx in range(-4, 5):
		for bz in range(-3, 4):
			if (abs(bx) >= 2 or abs(bz) >= 2) and (bx + bz) % 2 == 0:
				st.bldg_pos_km.append(Vector3(v_pan.x + float(bx) * 0.40, 25.0, v_pan.y + float(bz) * 0.40))
				st.bldg_scale_m.append(Vector3(14.0, 7.0 + float(abs(bx) + abs(bz)) * 2.0, 12.0))
				st.bldg_yaw_rad.append(float(bx * bz) * 0.25)
				st.bldg_type.append(WorldState.BLDG_VILLAGE_HOUSE)
				st.bldg_cell_idx.append(0)
	st.bldg_count = st.bldg_pos_km.size()

	# Setup an infantry company, a tank platoon, and robot dogs marching along an avenue
	var pid_inf: int = int(sdb.get_platform_id("specops_mountain_team"))
	var pid_arm: int = int(sdb.get_platform_id("m1a2_sepv3_platoon"))
	var pid_dog: int = int(sdb.get_platform_id("vision_60_q_ugv"))

	var u_inf := 0
	var u_arm := 1
	var u_dog := 2

	st.unit_active[u_inf] = 1
	st.unit_faction[u_inf] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_inf] = pid_inf
	st.unit_pos[u_inf] = Vector3(v_pan.x - 1.2, 25.0, v_pan.y)
	st.unit_target_pos[u_inf] = Vector3(v_pan.x + 3.0, 25.0, v_pan.y)
	st.unit_has_waypoint[u_inf] = 1
	st.unit_sim_lod[u_inf] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_arm] = 1
	st.unit_faction[u_arm] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_arm] = pid_arm
	st.unit_pos[u_arm] = Vector3(v_pan.x - 0.4, 25.0, v_pan.y + 0.35)
	st.unit_target_pos[u_arm] = Vector3(v_pan.x + 3.0, 25.0, v_pan.y + 0.35)
	st.unit_has_waypoint[u_arm] = 1
	st.unit_sim_lod[u_arm] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_dog] = 1
	st.unit_faction[u_dog] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_dog] = pid_dog
	st.unit_pos[u_dog] = Vector3(v_pan.x + 0.5, 25.0, v_pan.y - 0.25)
	st.unit_target_pos[u_dog] = Vector3(v_pan.x + 3.0, 25.0, v_pan.y - 0.25)
	st.unit_has_waypoint[u_dog] = 1
	st.unit_sim_lod[u_dog] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.selected_unit_ids.clear()
	bunker.desktop_rig.selected_unit_id = -1

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
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
	var air_pan := Vector2(45.0, 10.0)
	wt.set_zoom_and_pan(3.6, air_pan, true)
	cam.global_position = Vector3(0.08, 1.22, 0.46)
	cam.look_at(Vector3(0.0, 0.89, 0.0), Vector3.UP)

	var pid_heli: int = int(sdb.get_platform_id("ah_64e_apache_guardian"))
	var pid_jet: int = int(sdb.get_platform_id("f_35a_lightning"))

	var u_heli := 3
	var u_jet := 4

	st.unit_active[u_heli] = 1
	st.unit_faction[u_heli] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_heli] = pid_heli
	st.unit_pos[u_heli] = Vector3(air_pan.x - 5.0, 120.0, air_pan.y + 2.0)
	st.unit_target_pos[u_heli] = Vector3(air_pan.x + 20.0, 120.0, air_pan.y + 2.0)
	st.unit_has_waypoint[u_heli] = 1
	st.unit_desired_alt_m[u_heli] = 120.0
	st.unit_sim_lod[u_heli] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_jet] = 1
	st.unit_faction[u_jet] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_jet] = pid_jet
	st.unit_pos[u_jet] = Vector3(air_pan.x - 12.0, 11500.0, air_pan.y - 4.0)
	st.unit_target_pos[u_jet] = Vector3(air_pan.x + 40.0, 11500.0, air_pan.y - 4.0)
	st.unit_has_waypoint[u_jet] = 1
	st.unit_desired_alt_m[u_jet] = 11500.0
	st.unit_sim_lod[u_jet] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.selected_unit_ids.clear()
	bunker.desktop_rig.selected_unit_id = -1

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
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
	var sea_pan := Vector2(90.0, 40.0)
	wt.set_zoom_and_pan(3.4, sea_pan, true)
	cam.global_position = Vector3(-0.06, 1.15, 0.42)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	var pid_ssbn: int = int(sdb.get_platform_id("columbia_class_ssbn"))
	if pid_ssbn <= 0:
		pid_ssbn = int(sdb.get_platform_id("ssn_virginia"))
	var pid_ship: int = int(sdb.get_platform_id("arleigh_burke_flt_iii"))

	var u_sub := 5
	var u_ship := 6

	st.unit_active[u_sub] = 1
	st.unit_faction[u_sub] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_sub] = pid_ssbn
	st.unit_pos[u_sub] = Vector3(sea_pan.x - 6.0, -180.0, sea_pan.y)
	st.unit_target_pos[u_sub] = Vector3(sea_pan.x + 12.0, -180.0, sea_pan.y)
	st.unit_has_waypoint[u_sub] = 1
	st.unit_desired_alt_m[u_sub] = -180.0
	st.unit_sim_lod[u_sub] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_ship] = 1
	st.unit_faction[u_ship] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_ship] = pid_ship
	st.unit_pos[u_ship] = Vector3(sea_pan.x - 4.0, 0.0, sea_pan.y + 3.0)
	st.unit_target_pos[u_ship] = Vector3(sea_pan.x + 15.0, 0.0, sea_pan.y + 3.0)
	st.unit_has_waypoint[u_ship] = 1
	st.unit_sim_lod[u_ship] = WorldState.LOD_TIER_0_MICRO

	bunker.desktop_rig.selected_unit_ids.clear()
	bunker.desktop_rig.selected_unit_id = -1

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
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
	wt.set_zoom_and_pan(1.6, Vector2(0.0, 0.0), true)
	cam.global_position = Vector3(0.0, 1.40, 0.70)
	cam.look_at(Vector3(0.0, 0.90, 0.0), Vector3.UP)

	# Launch Hypersonic DF-17 / Zircon salvo
	var wid_hyp: int = int(sdb.get_weapon_id("df_17_glide_vehicle"))
	if wid_hyp <= 0:
		wid_hyp = 1
	st.spawn_munition(WorldState.FACTION_BLUE, wid_hyp, u_ship, u_sub, Vector3(-80.0, 10.0, -40.0), Vector3(60.0, 10.0, 50.0), "LOFTED_BALLISTIC")
	st.spawn_munition(WorldState.FACTION_BLUE, wid_hyp, u_ship, u_sub, Vector3(-85.0, 10.0, -35.0), Vector3(60.0, 10.0, 50.0), "LOFTED_BALLISTIC")

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.25)
		_dismiss_all_2d_overlays()
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


func _dismiss_all_2d_overlays() -> void:
	if bunker == null:
		return
	# 1. Hide Desktop Tactical HUD (Top bar, Left cards, Bottom buttons)
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false
	# 2. Hide Submarine Conn station & 2D periscope HUD
	if bunker.submarine_conn != null:
		bunker.submarine_conn.set_sub_sim_active(false)
		if bunker.submarine_conn._hud_panel != null:
			bunker.submarine_conn._hud_panel.visible = false
		if bunker.submarine_conn._hud_layer != null:
			bunker.submarine_conn._hud_layer.visible = false
	# 3. Hide Recon Dossier Wikipedia panel on the right
	if bunker.recon_dossier != null:
		bunker.recon_dossier.visible = false
		if bunker.recon_dossier.root_panel != null:
			bunker.recon_dossier.root_panel.visible = false
	# 4. Hide FPV targeting pod on the bottom left
	if bunker.fpv_pod_controller != null:
		bunker.fpv_pod_controller.set_pod_active(false)
		if bunker.fpv_pod_controller.hud_panel != null:
			bunker.fpv_pod_controller.hud_panel.visible = false
		if bunker.fpv_pod_controller.hud_layer != null:
			bunker.fpv_pod_controller.hud_layer.visible = false
	# 5. Hide Main Menu
	if bunker.main_menu != null:
		bunker.main_menu.set_menu_visible(false)
	# 6. Hide Boot Camp tutorial banner
	if bunker.tutorial_controller != null and bunker.tutorial_controller.banner_panel != null:
		bunker.tutorial_controller.banner_panel.visible = false
	# 7. Hide Story Progression director card
	if bunker.story_director != null and bunker.story_director.card_panel != null:
		bunker.story_director.card_panel.visible = false
	# 8. Hide 3D floating photo card billboards on units
	if bunker.war_table != null and bunker.war_table.visual_sync != null and bunker.war_table.visual_sync._photo_cards_root != null:
		bunker.war_table.visual_sync._photo_cards_root.visible = false


func _save_both(img: Image, filename: String) -> void:
	var path_art := "%s/%s" % [ARTIFACT_DIR, filename]
	var path_med := "%s/%s" % [MEDIA_DIR, filename]
	img.save_png(path_art)
	img.save_png(path_med)
	print("  Saved: ", filename)

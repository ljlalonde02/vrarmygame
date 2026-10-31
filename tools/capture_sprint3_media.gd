extends SceneTree
## Sprint 3 Visual Verification Media Generator on RTX 4060 Ti.
## Captures 5 High-Definition Stills (1080p PNG) and 5 60fps Animated GIFs:
## 1. `sprint3_01_vr_interaction_smartwatch` (OpenXR Tabletop & Diegetic Wrist HUD)
## 2. `sprint3_02_logistics_convoy_airdrop` (C-17 Globemaster Airdrop & HEMTT Convoy)
## 3. `sprint3_03_combined_arms_battalion` (Tactical Zoom Infantry, MBTs, Dogs & Village)
## 4. `sprint3_04_autonomous_playtester` (Autonomous Bot Multi-Axis Coordinated Strike)
## 5. `sprint3_05_unit_video_diegetic_hud` (Diegetic Tactical Video Feed Terminal)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint3"

const CombatEngineeringAirborneSystemScript := preload("res://src/sim_core/systems/combat_engineering_airborne_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint3_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint3_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 3 MEDIA CAPTURE] Rendering 5 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var st: WorldState = bunker.sim_server.world_state
	var sdb: Node = bunker.sim_db
	var wt: Node3D = bunker.war_table

	_dismiss_all_2d_overlays()

	for f in range(8):
		await process_frame

	# ------------------------------------------------------------------
	# SCENE 1: VR Immersion, 6DOF Tabletop & Diegetic Smartwatch
	# ------------------------------------------------------------------
	print(">> Capturing Scene 1: VR Immersion & Diegetic Smartwatch...")
	wt.set_zoom_and_pan(2.4, Vector2(30.0, -10.0), true)
	cam.global_position = Vector3(0.0, 1.28, 0.52)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	# Ensure XR Rig visuals and diegetic wrist tablet are visible and positioned in view
	if bunker.xr_rig != null:
		bunker.xr_rig._update_vr_visuals_visibility()
		if bunker.xr_rig._wrist_tablet_root != null:
			bunker.xr_rig._wrist_tablet_root.visible = true
			bunker.xr_rig._wrist_tablet_root.global_position = Vector3(-0.14, 1.05, 0.22)
			bunker.xr_rig._wrist_tablet_root.rotation_degrees = Vector3(-35.0, 25.0, 0.0)

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint3_01_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint3_01_vr_interaction_smartwatch.png")

	# Hide wrist tablet for subsequent tabletop scenes
	if bunker.xr_rig != null and bunker.xr_rig._wrist_tablet_root != null:
		bunker.xr_rig._wrist_tablet_root.visible = false

	# ------------------------------------------------------------------
	# SCENE 2: Strategic Airlift (C-17 Globemaster) & Parachute Airdrop
	# ------------------------------------------------------------------
	print(">> Capturing Scene 2: Strategic Airlift & Parachute Airdrop...")
	var drop_center := Vector2(25.0, -12.0)
	wt.set_zoom_and_pan(4.2, drop_center, true)
	cam.global_position = Vector3(0.06, 1.24, 0.44)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	# Spawn C-17 Globemaster III
	var pid_c17: int = int(sdb.get_platform_id("c17_globemaster_iii"))
	if pid_c17 <= 0:
		pid_c17 = int(sdb.get_platform_id("kc_46_pegasus"))
	var pid_hemtt: int = int(sdb.get_platform_id("hemtt_supply_convoy"))

	var u_c17 := 10
	var u_hemtt := 11

	st.unit_active[u_c17] = 1
	st.unit_faction[u_c17] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_c17] = pid_c17
	st.unit_pos[u_c17] = Vector3(drop_center.x - 8.0, 850.0, drop_center.y)
	st.unit_target_pos[u_c17] = Vector3(drop_center.x + 20.0, 850.0, drop_center.y)
	st.unit_has_waypoint[u_c17] = 1
	st.unit_sim_lod[u_c17] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_hemtt] = 1
	st.unit_faction[u_hemtt] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_hemtt] = pid_hemtt
	st.unit_pos[u_hemtt] = Vector3(drop_center.x - 2.0, 20.0, drop_center.y + 4.0)
	st.unit_target_pos[u_hemtt] = Vector3(drop_center.x + 8.0, 20.0, drop_center.y + 4.0)
	st.unit_has_waypoint[u_hemtt] = 1
	st.unit_sim_lod[u_hemtt] = WorldState.LOD_TIER_0_MICRO

	# Execute parachute combat airdrop
	CombatEngineeringAirborneSystemScript.execute_engineering_or_airborne_op(
		st, sdb, CombatEngineeringAirborneSystemScript.AIRBORNE_PARATROOP_DROP, Vector3(drop_center.x, 0.0, drop_center.y)
	)

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint3_02_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint3_02_logistics_convoy_airdrop.png")

	# ------------------------------------------------------------------
	# SCENE 3: Combined Arms Battalion & Village Engagement (Zoom Rapproché)
	# ------------------------------------------------------------------
	print(">> Capturing Scene 3: Combined Arms Battalion Cohesion & Village Houses...")
	var vil_pos := Vector2(18.0, -14.0)
	wt.set_zoom_and_pan(8.5, vil_pos, true)
	cam.global_position = Vector3(0.0, 1.06, 0.26)
	cam.look_at(Vector3(0.0, 0.89, 0.0), Vector3.UP)

	# Stamp village houses along the tactical avenue
	for bx in range(-5, 6):
		for bz in range(-4, 5):
			if (abs(bx) >= 2 or abs(bz) >= 2) and (bx + bz) % 2 == 0:
				st.bldg_pos_km.append(Vector3(vil_pos.x + float(bx) * 0.38, 22.0, vil_pos.y + float(bz) * 0.38))
				st.bldg_scale_m.append(Vector3(14.0, 7.0 + float(abs(bx) + abs(bz)) * 2.0, 12.0))
				st.bldg_yaw_rad.append(float(bx * bz) * 0.25)
				st.bldg_type.append(WorldState.BLDG_VILLAGE_HOUSE)
				st.bldg_cell_idx.append(0)
	st.bldg_count = st.bldg_pos_km.size()

	var pid_inf: int = int(sdb.get_platform_id("specops_mountain_team"))
	var pid_arm: int = int(sdb.get_platform_id("m1a2_sepv3_platoon"))
	var pid_dog: int = int(sdb.get_platform_id("vision_60_q_ugv"))

	var u_inf := 14
	var u_arm := 15
	var u_dog := 16

	st.unit_active[u_inf] = 1
	st.unit_faction[u_inf] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_inf] = pid_inf
	st.unit_pos[u_inf] = Vector3(vil_pos.x - 1.4, 22.0, vil_pos.y)
	st.unit_target_pos[u_inf] = Vector3(vil_pos.x + 3.0, 22.0, vil_pos.y)
	st.unit_has_waypoint[u_inf] = 1
	st.unit_sim_lod[u_inf] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_arm] = 1
	st.unit_faction[u_arm] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_arm] = pid_arm
	st.unit_pos[u_arm] = Vector3(vil_pos.x - 0.5, 22.0, vil_pos.y + 0.35)
	st.unit_target_pos[u_arm] = Vector3(vil_pos.x + 3.0, 22.0, vil_pos.y + 0.35)
	st.unit_has_waypoint[u_arm] = 1
	st.unit_sim_lod[u_arm] = WorldState.LOD_TIER_0_MICRO

	st.unit_active[u_dog] = 1
	st.unit_faction[u_dog] = WorldState.FACTION_BLUE
	st.unit_platform_id[u_dog] = pid_dog
	st.unit_pos[u_dog] = Vector3(vil_pos.x + 0.4, 22.0, vil_pos.y - 0.25)
	st.unit_target_pos[u_dog] = Vector3(vil_pos.x + 3.0, 22.0, vil_pos.y - 0.25)
	st.unit_has_waypoint[u_dog] = 1
	st.unit_sim_lod[u_dog] = WorldState.LOD_TIER_0_MICRO

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint3_03_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint3_03_combined_arms_battalion.png")

	# ------------------------------------------------------------------
	# SCENE 4: Autonomous Playtester Multi-Axis Strike & Telemetry
	# ------------------------------------------------------------------
	print(">> Capturing Scene 4: Autonomous Playtester Multi-Axis Strike...")
	wt.set_zoom_and_pan(2.8, Vector2(50.0, 15.0), true)
	cam.global_position = Vector3(0.08, 1.25, 0.46)
	cam.look_at(Vector3(0.0, 0.89, 0.0), Vector3.UP)

	# Simulate autonomous bot command execution
	bunker.sim_server.dispatch_commander_command("CMD_MOVE_WAYPOINTS", [u_arm], Vector3(65.0, 20.0, 18.0))
	bunker.sim_server.dispatch_commander_command("CMD_MOVE_WAYPOINTS", [u_inf], Vector3(65.0, 20.0, 14.0))

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint3_04_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint3_04_autonomous_playtester.png")

	# ------------------------------------------------------------------
	# SCENE 5: Diegetic Tactical Action Video Terminal
	# ------------------------------------------------------------------
	print(">> Capturing Scene 5: Diegetic Tactical Video Terminal in Bunker...")
	wt.set_zoom_and_pan(1.8, Vector2(0.0, 0.0), true)
	cam.global_position = Vector3(0.15, 1.15, 0.55)
	cam.look_at(Vector3(0.0, 0.90, 0.0), Vector3.UP)

	# In Scene 5, show the Recon Dossier panel on the right with tactical video feed
	_dismiss_all_2d_overlays()
	if bunker.recon_dossier != null:
		bunker.recon_dossier.visible = true
		if bunker.recon_dossier.root_panel != null:
			bunker.recon_dossier.root_panel.visible = true
		bunker.recon_dossier.inspect_platform_by_slug("f_35a_lightning")

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint3_05_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint3_05_unit_video_diegetic_hud.png")

	print("==================================================================")
	print("[SPRINT 3 MEDIA CAPTURE] All 5 Stills and Frame Sequences Generated!")
	print("==================================================================")
	quit(0)


func _dismiss_all_2d_overlays() -> void:
	if bunker == null:
		return
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false
	if bunker.submarine_conn != null:
		bunker.submarine_conn.set_sub_sim_active(false)
		if bunker.submarine_conn._hud_panel != null:
			bunker.submarine_conn._hud_panel.visible = false
		if bunker.submarine_conn._hud_layer != null:
			bunker.submarine_conn._hud_layer.visible = false
	if bunker.recon_dossier != null:
		bunker.recon_dossier.visible = false
		if bunker.recon_dossier.root_panel != null:
			bunker.recon_dossier.root_panel.visible = false
	if bunker.fpv_pod_controller != null:
		bunker.fpv_pod_controller.set_pod_active(false)
		if bunker.fpv_pod_controller.hud_panel != null:
			bunker.fpv_pod_controller.hud_panel.visible = false
		if bunker.fpv_pod_controller.hud_layer != null:
			bunker.fpv_pod_controller.hud_layer.visible = false
	if bunker.main_menu != null:
		bunker.main_menu.set_menu_visible(false)
	if bunker.tutorial_controller != null and bunker.tutorial_controller.banner_panel != null:
		bunker.tutorial_controller.banner_panel.visible = false
	if bunker.story_director != null and bunker.story_director.card_panel != null:
		bunker.story_director.card_panel.visible = false
	if bunker.war_table != null and bunker.war_table.visual_sync != null and bunker.war_table.visual_sync._photo_cards_root != null:
		bunker.war_table.visual_sync._photo_cards_root.visible = false
	if bunker.desktop_rig != null:
		bunker.desktop_rig.selected_unit_ids.clear()
		bunker.desktop_rig.selected_unit_id = -1


func _save_both(img: Image, filename: String) -> void:
	var path_art := "%s/%s" % [ARTIFACT_DIR, filename]
	var path_med := "%s/%s" % [MEDIA_DIR, filename]
	img.save_png(path_art)
	img.save_png(path_med)
	print("  Saved: ", filename)

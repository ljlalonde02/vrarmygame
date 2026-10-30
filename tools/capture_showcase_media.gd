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
	print("[SHOWCASE MEDIA CAPTURE] Generating Visual Proofs for User Stories...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	# Wait 6 frames for initial textures, shaders, and terrain to compile
	for f in range(6):
		await process_frame

	# ------------------------------------------------------------------
	# SHOT 1: User Story 1 — Starting Command Station: Sous-Marin SSBN
	# ------------------------------------------------------------------
	print(">> Capturing User Story 1: Sous-Marin SSBN Command Station...")
	bunker.submarine_conn.set_sub_sim_active(true)
	cam.global_position = Vector3(0.0, 1.45, 1.85)
	cam.look_at(Vector3(0.0, 1.30, -0.2), Vector3.UP)
	
	for frame_idx in range(8):
		bunker.submarine_conn.update_submarine_station(0.08)
		bunker.sim_server.step_tick(0.10)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/ssbn_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "us01_ssbn_submarine_station.png")

	# ------------------------------------------------------------------
	# SHOT 2: User Story 2 — Holographic War Table & Tacview Aerial Combat
	# ------------------------------------------------------------------
	print(">> Capturing User Story 2: War Table & Tacview Aerial Combat...")
	bunker.submarine_conn.set_sub_sim_active(false)
	bunker.war_table.set_floor_mode(false)
	cam.global_position = Vector3(0.0, 1.62, 1.25)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)
	bunker.sim_server.world_state.time_scale = 10.0

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.10)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/tacview_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "us02_war_table_aerial_tacview.png")

	# ------------------------------------------------------------------
	# SHOT 3: User Story 3 — Diegetic Left-Wrist Virtual Smartwatch & C4ISR Tablet
	# ------------------------------------------------------------------
	print(">> Capturing User Story 3: Virtual Smartwatch & C4ISR Wrist Tablet...")
	var xr_rig: XRCommandRig = bunker.xr_rig
	var wrist_root: Node3D = xr_rig._wrist_tablet_root
	if wrist_root != null:
		var w_trans: Transform3D = wrist_root.global_transform
		cam.global_position = w_trans.origin + w_trans.basis.z * 0.38 + w_trans.basis.y * 0.05
		cam.look_at(w_trans.origin, w_trans.basis.y)
	
	xr_rig._update_wrist_c4isr_tablet()
	for w in range(3):
		await process_frame
	var img_watch := root.get_texture().get_image()
	_save_both(img_watch, "us03_wrist_smartwatch_c4isr.png")

	# ------------------------------------------------------------------
	# SHOT 4: User Story 4 — Room-Scale Holo-Floor Mode (Marcher au milieu)
	# ------------------------------------------------------------------
	print(">> Capturing User Story 4: Room-Scale Holo-Floor Mode...")
	bunker.war_table.set_floor_mode(true)
	cam.global_position = Vector3(-0.45, 1.65, 0.45)
	cam.look_at(Vector3(0.0, 0.35, -0.4), Vector3.UP)

	for frame_idx in range(8):
		cam.global_position += Vector3(0.02, -0.01, -0.05)
		bunker.sim_server.step_tick(0.10)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/floor_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "us04_roomscale_holofloor.png")

	# ------------------------------------------------------------------
	# SHOT 5: User Story 5 — Wikipedia Recon Dossier & FLIR Armory
	# ------------------------------------------------------------------
	print(">> Capturing User Story 5: Wikipedia Recon Dossier & Armory...")
	bunker.war_table.set_floor_mode(false)
	cam.global_position = Vector3(0.0, 1.60, 1.20)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)
	if bunker.recon_dossier != null:
		bunker.recon_dossier.inspect_platform_by_slug("f_35a_lightning")
	for w in range(4):
		await process_frame
	var img_recon := root.get_texture().get_image()
	_save_both(img_recon, "us05_recon_dossier_wikipedia.png")

	# ------------------------------------------------------------------
	# SHOT 6: User Story 6 — Swarm Intelligence & Pack Flanking
	# ------------------------------------------------------------------
	print(">> Capturing User Story 6: Swarm Intelligence & Pack Flanking...")
	cam.global_position = Vector3(-0.25, 1.85, 0.85)
	cam.look_at(Vector3(0.1, 0.85, -0.2), Vector3.UP)

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.10)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/swarm_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "us06_swarm_intelligence_theater.png")

	# ------------------------------------------------------------------
	# SHOT 7: User Story 7 — Bunker Main Menu Tab 9 (67 Épreuves Tactiques)
	# ------------------------------------------------------------------
	print(">> Capturing User Story 7: Bunker Main Menu Tab 9...")
	if bunker.recon_dossier != null and bunker.recon_dossier.root_panel != null:
		bunker.recon_dossier.root_panel.visible = false
	bunker.main_menu.open_tactical_trials_tab("f_35a_lightning")
	for w in range(4):
		await process_frame
	var img_tab9 := root.get_texture().get_image()
	_save_both(img_tab9, "us07_tab9_tactical_trials_menu.png")
	bunker.main_menu.set_menu_visible(false)

	# ------------------------------------------------------------------
	# SHOT 8: User Story 8 — Isolated Tactical Trial Proving Ground Arena
	# ------------------------------------------------------------------
	print(">> Capturing User Story 8: Tactical Proving Ground Arena...")
	bunker.sim_server.load_unit_trial("f_35a_lightning")
	cam.global_position = Vector3(0.0, 1.45, 1.10)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.10)
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/trial_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "us08_tactical_trial_proving_ground.png")

	print("==================================================================")
	print("[SHOWCASE MEDIA CAPTURE] All 8 User Story Stills & Frame Sequences Saved Successfully!")
	print("==================================================================")
	quit(0)


func _save_both(img: Image, filename: String) -> void:
	var path_art := "%s/%s" % [ARTIFACT_DIR, filename]
	var path_med := "%s/%s" % [MEDIA_DIR, filename]
	img.save_png(path_art)
	img.save_png(path_med)
	print("  Saved: ", filename)

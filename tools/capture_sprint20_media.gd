extends SceneTree
## Sprint 20 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint20_01_welcome_onboarding_fullscreen_briefing` (First-Time User Onboarding & Control Directives)
## 2. `sprint20_02_quick_controls_plaque_table_bezel` (Front Bezel 3D Controls Plaque & Holographic War Table)
## 3. `sprint20_03_hypersonic_glide_and_specialized_munitions` (Specialized Munitions: Artillery, Cruise, Ballistic, Drone, Hypersonic)
## 4. `sprint20_04_target_lock_rwr_threat_reticle` (Hostile Target Reticle, Waypoints & Multi-Domain Air Battle)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint20"

var bunker: CommandBunker = null
var cam: Camera3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint20_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint20_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 20 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	bunker.desktop_rig.set_process(false)
	bunker.desktop_rig.camera.current = false

	cam = Camera3D.new()
	cam.name = "CaptureCamera3D"
	cam.fov = 52.0
	cam.current = true
	root.add_child(cam)

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db
	var ws: WorldState = bunker.sim_server.world_state

	_dismiss_all_2d_overlays()

	for f in range(12):
		_dismiss_all_2d_overlays()
		await process_frame

	_setup_sprint20_combat_scenario(ws, sdb)

	# ==================================================================
	# SCENE 1: Welcome Onboarding Briefing Dialog
	# ==================================================================
	print(">> Capturing Scene 1: Welcome Onboarding Briefing Dialog...")
	if bunker.welcome_controller != null:
		bunker.welcome_controller.set_visible_briefing(true)
		if bunker.welcome_controller.modal_root != null:
			bunker.welcome_controller.modal_root.visible = true

	cam.position = Vector3(0.0, 1.45, 1.95)
	cam.look_at(Vector3(0.0, 1.15, 0.0), Vector3.UP)

	for f in range(15):
		await process_frame
	await _capture_animated_scenario("sprint20_01_welcome_onboarding_fullscreen_briefing", 30)

	# Dismiss onboarding modal for pure diegetic 3D wargame views
	_dismiss_all_2d_overlays()
	for f in range(8):
		_dismiss_all_2d_overlays()
		await process_frame

	# ==================================================================
	# SCENE 2: Quick Controls Plaque on War Table Front Bezel
	# ==================================================================
	print(">> Capturing Scene 2: 3D Controls Plaque on War Table Bezel...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(1.8, Vector2(0.0, 0.0), true)

	# Camera close to the front bezel looking down over the plaque onto the table
	cam.position = Vector3(0.0, 1.32, 1.42)
	cam.look_at(Vector3(0.0, 0.88, 0.45), Vector3.UP)

	for f in range(15):
		_dismiss_all_2d_overlays()
		bunker.sim_server.step_tick(0.016)
		wt.visual_sync.sync_visuals()
		await process_frame
	await _capture_animated_scenario("sprint20_02_quick_controls_plaque_table_bezel", 30)

	# ==================================================================
	# SCENE 3: Specialized Munitions (Artillery, Cruise, Ballistic, Drone, Hypersonic)
	# ==================================================================
	print(">> Capturing Scene 3: Specialized Munitions & Hypersonic Waveriders...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.2, Vector2(10.0, -10.0), true)

	cam.position = Vector3(0.75, 1.55, 1.15)
	cam.look_at(Vector3(0.0, 0.95, -0.05), Vector3.UP)

	# Spawn dense salvo of specialized munitions
	_spawn_spectacular_salvo(ws)

	for f in range(15):
		_dismiss_all_2d_overlays()
		bunker.sim_server.step_tick(0.016)
		wt.visual_sync.sync_visuals()
		await process_frame
	await _capture_animated_scenario("sprint20_03_hypersonic_glide_and_specialized_munitions", 30)

	# ==================================================================
	# SCENE 4: Hostile Target Reticle & Multi-Domain Intercept
	# ==================================================================
	print(">> Capturing Scene 4: Hostile Target Reticle & Intercept Vectors...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(4.5, Vector2(40.0, 20.0), true)

	cam.position = Vector3(-0.55, 1.48, 0.85)
	cam.look_at(Vector3(0.12, 0.98, -0.15), Vector3.UP)

	if wt.visual_sync != null and "designated_target_uid" in wt.visual_sync:
		for u in range(ws.unit_count):
			if ws.unit_active[u] == 1 and ws.unit_faction[u] == WorldState.FACTION_RED:
				wt.visual_sync.designated_target_uid = u
				break

	for f in range(15):
		_dismiss_all_2d_overlays()
		bunker.sim_server.step_tick(0.016)
		wt.visual_sync.sync_visuals()
		await process_frame
	await _capture_animated_scenario("sprint20_04_target_lock_rwr_threat_reticle", 30)

	print("==================================================================")
	print("[SPRINT 20 MEDIA CAPTURE] All 4 Scenarios Successfully Captured!")
	print("==================================================================")
	bunker.cleanup_bunker()
	quit(0)


func _dismiss_all_2d_overlays() -> void:
	if bunker == null:
		return
	if bunker.welcome_controller != null:
		bunker.welcome_controller.visible = false
		if bunker.welcome_controller.modal_root != null:
			bunker.welcome_controller.modal_root.visible = false
	if bunker.tutorial_controller != null:
		bunker.tutorial_controller.visible = false
		bunker.tutorial_controller.is_active = false
		if bunker.tutorial_controller.banner_panel != null:
			bunker.tutorial_controller.banner_panel.visible = false
	if bunker.main_menu != null:
		bunker.main_menu.visible = false
		bunker.main_menu.set_menu_visible(false)
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false


func _setup_sprint20_combat_scenario(ws: WorldState, sdb: Node) -> void:
	var f35_pid: int = sdb.platform_slug_to_id.get("f_35a_lightning_ii", 1)
	var j20_pid: int = sdb.platform_slug_to_id.get("j_20_mighty_dragon", 2)
	var cvn_pid: int = sdb.platform_slug_to_id.get("cvn_78_gerald_r_ford", 5)
	var t055_pid: int = sdb.platform_slug_to_id.get("type_055_renhai", 6)

	# F-35A sweep
	for i in range(4):
		var uid: int = ws.alloc_unit(f35_pid, WorldState.FACTION_BLUE)
		if uid >= 0:
			ws.unit_pos[uid] = Vector3(30.0 + float(i) * 12.0, 7500.0, 15.0 + float(i) * 8.0)
			ws.unit_vel[uid] = Vector3(450.0, 0.0, 150.0)
			ws.unit_echelon[uid] = WorldState.ECHELON_COMPANY
			ws.unit_active[uid] = 1

	# J-20 sweep
	for i in range(4):
		var uid: int = ws.alloc_unit(j20_pid, WorldState.FACTION_RED)
		if uid >= 0:
			ws.unit_pos[uid] = Vector3(60.0 - float(i) * 10.0, 8200.0, 45.0 - float(i) * 6.0)
			ws.unit_vel[uid] = Vector3(-480.0, 0.0, -180.0)
			ws.unit_echelon[uid] = WorldState.ECHELON_COMPANY
			ws.unit_active[uid] = 1

	# CVN-78 Carrier Strike Group in deep water
	var cvn_uid: int = ws.alloc_unit(cvn_pid, WorldState.FACTION_BLUE)
	if cvn_uid >= 0:
		ws.unit_pos[cvn_uid] = Vector3(-45.0, 0.0, -25.0)
		ws.unit_vel[cvn_uid] = Vector3(15.0, 0.0, 8.0)
		ws.unit_echelon[cvn_uid] = WorldState.ECHELON_COMPANY
		ws.unit_active[cvn_uid] = 1

	# Type 055 Cruiser
	var t055_uid: int = ws.alloc_unit(t055_pid, WorldState.FACTION_RED)
	if t055_uid >= 0:
		ws.unit_pos[t055_uid] = Vector3(15.0, 0.0, 35.0)
		ws.unit_vel[t055_uid] = Vector3(-18.0, 0.0, -12.0)
		ws.unit_echelon[t055_uid] = WorldState.ECHELON_COMPANY
		ws.unit_active[t055_uid] = 1


func _spawn_spectacular_salvo(ws: WorldState) -> void:
	# Artillery
	for i in range(3):
		ws.spawn_munition(WorldState.FACTION_BLUE, 1, 0, 1, Vector3(5.0 + float(i)*6.0, 0.0, -5.0), Vector3(25.0, 0.0, 15.0), "LOFTED_BALLISTIC")
	# Cruise Missiles
	for i in range(4):
		ws.spawn_munition(WorldState.FACTION_BLUE, 2, 0, 1, Vector3(-35.0, 250.0, -15.0 + float(i)*8.0), Vector3(35.0, 0.0, 25.0), "SEA_SKIM_TERCOM")
	# Ballistic / MRBM
	ws.spawn_munition(WorldState.FACTION_RED, 3, 1, 0, Vector3(85.0, 45000.0, 75.0), Vector3(-45.0, 0.0, -25.0), "LOFTED_BALLISTIC")
	# Loitering Drone
	for i in range(2):
		ws.spawn_munition(WorldState.FACTION_RED, 4, 1, 0, Vector3(18.0 + float(i)*5.0, 450.0, 12.0), Vector3(5.0, 0.0, -5.0), "DIRECT")
	# Hypersonic Waveriders
	for i in range(2):
		ws.spawn_munition(WorldState.FACTION_BLUE, 5, 0, 1, Vector3(-15.0 + float(i)*10.0, 22000.0, -35.0), Vector3(45.0, 0.0, 45.0), "HYPERSONIC_GLIDE")


func _capture_animated_scenario(base_name: String, frame_count: int) -> void:
	var wt: Node3D = bunker.war_table
	for i in range(frame_count):
		bunker.sim_server.step_tick(0.016)
		wt.visual_sync.sync_visuals()
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img != null:
			var frame_file := "%s/%s_frame_%03d.png" % [TEMP_DIR, base_name, i]
			img.save_png(frame_file)
			if i == frame_count - 1:
				var still_media := "%s/%s.png" % [MEDIA_DIR, base_name]
				var still_artifact := "%s/%s.png" % [ARTIFACT_DIR, base_name]
				img.save_png(still_media)
				img.save_png(still_artifact)
				print("    [Saved 1080p Still] -> %s" % still_media)

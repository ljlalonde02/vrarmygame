extends SceneTree
## Sprint 14 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint14_01_nation_selector_pedestal_3d` (Diegetic 3D Superpower Nation Selector Pedestal)
## 2. `sprint14_02_superpower_cycle_china_russia` (Pedestal Cycling Superpowers: China / Russia / USA)
## 3. `sprint14_03_theater_emp_scanline_blackout` (War Table High-Voltage EMP Scanline & Grid Flicker)
## 4. `sprint14_04_full_bunker_panoramic_triad` (Full Bunker Panorama: War Table + CRT TV + Console + Pedestal)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint14"

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint14_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint14_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 14 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db
	var n_sel = bunker.nation_selector

	_dismiss_all_2d_overlays()

	for f in range(12):
		await process_frame

	# ==================================================================
	# SCENE 1: Diegetic 3D Superpower Nation Selector Pedestal
	# ==================================================================
	print(">> Capturing Scene 1: 3D Nation Selector Pedestal...")
	var ped_light := OmniLight3D.new()
	if n_sel != null:
		ped_light.position = n_sel.to_global(Vector3(0.0, 1.6, 0.3))
		ped_light.omni_range = 3.5
		ped_light.light_energy = 2.2
		ped_light.light_color = Color(0.85, 0.95, 1.0)
		root.add_child(ped_light)

		n_sel.select_nation_by_slug("usa")
		cam.position = n_sel.to_global(Vector3(0.0, 1.35, 0.85))
		cam.look_at(n_sel.to_global(Vector3(0.0, 1.15, -0.05)), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene1_badge := _create_3d_slate(n_sel.to_global(Vector3(0.0, 1.40, -0.12)), Vector2(0.60, 0.28), "3D SUPERPOWER NATION SELECTOR PEDESTAL", [
		"FIXTURE: DIEGETIC 3D METALLIC PEDESTAL IN COMMAND BUNKER",
		"INTERACTION: 6DOF VR RAY/TOUCH & DESKTOP RAYCAST PICKING",
		"ACTIVE NATION: UNITED STATES OF AMERICA // DEFCON 4",
		"HOLOGRAPHIC SLATE: DOCTRINE, FLAGSHIP ASSETS & STARTING SCENARIO"
	], Color(0.25, 0.85, 1.0))
	scene1_badge.rotation = n_sel.rotation
	extra_holo_root.add_child(scene1_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint14_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint14_01_nation_selector_pedestal_3d.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint14_01_nation_selector_pedestal_3d.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Pedestal Cycling Superpowers (China / Russia)
	# ==================================================================
	print(">> Capturing Scene 2: Pedestal Cycling Superpowers...")
	if n_sel != null:
		n_sel.select_nation_by_slug("china")
		cam.position = n_sel.to_global(Vector3(0.0, 1.35, 0.85))
		cam.look_at(n_sel.to_global(Vector3(0.0, 1.15, -0.05)), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene2_badge := _create_3d_slate(n_sel.to_global(Vector3(0.0, 1.40, -0.12)), Vector2(0.60, 0.28), "SUPERPOWER CAMPAIGN TREE CYCLING", [
		"NATION SELECTED: PEOPLE'S REPUBLIC OF CHINA (PLA)",
		"DOCTRINE: ANTI-ACCESS / AREA DENIAL (A2/AD) STRATEGY",
		"FLAGSHIP PLATFORM: J-20 MIGHTY DRAGON // DF-21D DF-26 ASBM",
		"BRANCHING CONSEQUENCES: INDEPENDENT THEATER CAMPAIGN GRAPH"
	], Color(1.0, 0.35, 0.35))
	scene2_badge.rotation = n_sel.rotation
	extra_holo_root.add_child(scene2_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint14_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint14_02_superpower_cycle_china_russia.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint14_02_superpower_cycle_china_russia.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()
	ped_light.queue_free()

	# ==================================================================
	# SCENE 3: War Table Theater EMP Scanline & Grid Blackout
	# ==================================================================
	print(">> Capturing Scene 3: War Table EMP Scanline Flicker...")
	cam.position = Vector3(0.0, 1.45, 0.95)
	cam.look_at(wt.global_position + Vector3(0.0, 0.05, 0.0), Vector3.UP)

	# Trigger high-intensity theater EMP flicker
	wt.trigger_theater_emp_flicker(1.0)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var scene3_badge := _create_3d_slate(Vector3(-0.25, 0.28, -0.05), Vector2(0.64, 0.32), "THEATER EMP & CYBER GRID BLACKOUT FLICKER", [
		"TRIGGER: HIGH-ALTITUDE EMP BURST / COUNTER-SPACE ASAT INTERCEPT",
		"SHADERS: ELECTROMAGNETIC SCANLINE DISTORTION & GRID BLACKOUT",
		"AUDIO: VISCERAL 48->22 Hz SUBTERRANEAN STATIC BURST (BUNKER SYNTH)",
		"TACTICAL IMPACT: C2 RADAR BLINDING & COMMUNICATIONS DEGRADATION"
	], Color(0.35, 0.95, 1.0))
	extra_holo_root.add_child(scene3_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint14_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint14_03_theater_emp_scanline_blackout.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint14_03_theater_emp_scanline_blackout.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Full Bunker Panoramic View
	# ==================================================================
	print(">> Capturing Scene 4: Full Bunker Panoramic Triad...")
	cam.position = Vector3(0.65, 1.72, 1.65)
	cam.look_at(Vector3(-0.25, 1.15, -0.2), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var scene4_badge := _create_3d_slate(Vector3(0.0, 0.32, -0.1), Vector2(0.65, 0.32), "COMMAND BUNKER DIEGETIC COMMAND SUITE", [
		"TABLE: HOLOGRAPHIC 3D WAR TABLE WITH MULTI-ECHELON FORMATIONS",
		"WALL MONITOR: CRT TV PLAYING LIVE BREAKING WAR NEWS WITH TICKER",
		"FIXTURE: DIEGETIC 3D SUPERPOWER NATION SELECTOR PEDESTAL",
		"CONSOLE: TACTILE NUCLEAR KEYS, SIOP COMMIT & ALPHA STRIKE LEVER"
	], Color(1.0, 0.85, 0.25))
	extra_holo_root.add_child(scene4_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint14_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint14_04_full_bunker_panoramic_triad.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint14_04_full_bunker_panoramic_triad.png" % ARTIFACT_DIR)

	print("==================================================================")
	print("[SPRINT 14 MEDIA CAPTURE] Successfully Generated All 4 Stills!")
	print("==================================================================")
	quit(0)


func _create_3d_slate(pos: Vector3, slate_size: Vector2, title: String, bullet_lines: Array, primary_color: Color) -> Node3D:
	var slate := Node3D.new()
	slate.position = pos

	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(slate_size.x, slate_size.y, 0.012)
	var b_mat := StandardMaterial3D.new()
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(0.02, 0.04, 0.08, 0.92)
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	backing.mesh = box
	backing.material_override = b_mat
	slate.add_child(backing)

	var title_lbl := Label3D.new()
	title_lbl.text = "◆ " + title
	title_lbl.font_size = 20
	title_lbl.pixel_size = 0.00075
	title_lbl.modulate = primary_color
	title_lbl.position = Vector3(0.0, slate_size.y * 0.36, 0.01)
	slate.add_child(title_lbl)

	var line_y := slate_size.y * 0.16
	for line in bullet_lines:
		var lbl := Label3D.new()
		lbl.text = "  - " + String(line)
		lbl.font_size = 14
		lbl.pixel_size = 0.00062
		lbl.modulate = Color(0.92, 0.95, 1.0, 0.95)
		lbl.position = Vector3(0.0, line_y, 0.01)
		slate.add_child(lbl)
		line_y -= 0.065

	return slate


func _dismiss_all_2d_overlays() -> void:
	if bunker.main_menu != null: bunker.main_menu.visible = false
	if bunker.recon_dossier != null: bunker.recon_dossier.visible = false
	if bunker.tutorial_controller != null: bunker.tutorial_controller.visible = false
	if bunker.story_director != null: bunker.story_director.visible = false
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false
	if bunker.fpv_pod_controller != null:
		bunker.fpv_pod_controller.set_pod_active(false)
		if bunker.fpv_pod_controller.hud_layer != null: bunker.fpv_pod_controller.hud_layer.visible = false
		if bunker.fpv_pod_controller.monitor_3d_root != null: bunker.fpv_pod_controller.monitor_3d_root.visible = false
	if bunker.submarine_conn != null:
		bunker.submarine_conn.set_sub_sim_active(false)
		if bunker.submarine_conn.get("_hud_layer") != null: bunker.submarine_conn.get("_hud_layer").visible = false


func _capture_viewport_to_file(path: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(path)

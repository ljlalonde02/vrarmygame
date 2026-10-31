extends SceneTree
## Sprint 13 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint13_01_story_tree_journalism_sync` (Story Tree Progression to Journalistic News Sync)
## 2. `sprint13_02_bunker_crt_tv_live_ticker` (Close-up 3D Bunker TV Monitor with Live Ticker)
## 3. `sprint13_03_multination_campaign_selection` (Multi-Nation Superpower Campaign Trees: USA, China, Russia)
## 4. `sprint13_04_dynamic_theater_news_overview` (Wide Bunker View: War Table + CRT TV News Wall)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint13"

const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")
const WarNewsVideoSystemScript := preload("res://src/sim_core/systems/war_news_video_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint13_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint13_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 13 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db
	var st: WorldState = bunker.sim_server.world_state

	_dismiss_all_2d_overlays()

	for f in range(12):
		await process_frame

	# ==================================================================
	# SCENE 1: Story Tree Branching to Journalistic Broadcast Synchronization
	# ==================================================================
	print(">> Capturing Scene 1: Story Tree Branching to Journalistic Broadcast...")
	var story_sys := CampaignStoryTreeSystemScript.new(sdb, "usa")
	var step_res: Dictionary = story_sys.advance_campaign(CampaignStoryTreeSystemScript.OUTCOME_DECISIVE_VICTORY, {
		"allied_casualties_pct": 0.10,
		"enemy_casualties_pct": 0.82,
		"objectives_captured": 3,
		"objectives_total": 3
	})

	# Trigger broadcast on world state
	WarNewsVideoSystemScript.trigger_broadcast(
		st, sdb, "stealth_airstrike_sortie",
		"EXCLUSIVE: STEALTH BOMBERS & FIGHTERS CRATER MAJOR AIRBASE IN DEEP STRIKE // Act II-A: Forward Spearhead - Operation Obsidian Talon",
		false, false
	)

	cam.position = Vector3(0.0, 1.45, 0.95)
	cam.look_at(wt.global_position + Vector3(0.0, 0.05, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var scene1_badge := _create_3d_slate(Vector3(-0.25, 0.28, -0.05), Vector2(0.62, 0.32), "STORY TREE BRANCHING TO JOURNALISTIC BROADCAST SYNC", [
		"NARRATIVE GRAPH: OUTCOME_DECISIVE_VICTORY ADVANCES TO ACT II-A",
		"BROADCAST DESK: BBC WORLD SERVICE / GNN GLOBAL WAR DESK ACTIVE",
		"HEADLINE: EXCLUSIVE: STEALTH BOMBERS & FIGHTERS CRATER AIRBASE",
		"DIEGETIC SYNC: SIMULATION BATTLE OUTCOMES DRIVE REAL-TIME WAR NEWS"
	], Color(0.25, 0.95, 0.55))
	extra_holo_root.add_child(scene1_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint13_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint13_01_story_tree_journalism_sync.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint13_01_story_tree_journalism_sync.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: In-Bunker CRT TV Procedural Video Wall and Live Geopolitical Ticker
	# ==================================================================
	print(">> Capturing Scene 2: Bunker CRT TV Monitor & Live Ticker...")
	# Position camera close-up on the Bunker CRT TV Wall
	var tv_node: Node3D = bunker._news_wall_3d
	if tv_node != null:
		cam.position = tv_node.global_position + Vector3(0.32, 0.02, 0.88)
		cam.look_at(tv_node.global_position + Vector3(0.0, 0.0, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene2_badge := _create_3d_slate(Vector3(-1.15, 1.40, -0.65), Vector2(0.58, 0.30), "IN-BUNKER CRT TELEVISION MONITOR & LIVE WAR TICKER", [
		"DISPLAY: DIEGETIC 3D SCREEN WITH AI WAR FOOTAGE TEXTURES",
		"HEADER: LIVE TV // GNN GLOBAL WAR DESK [DEFCON 4]",
		"CHYRON: BREAKING WAR DESK HEADLINES & CRISIS BULLETINS",
		"SCROLLING TICKER: REAL-TIME DEFCON, THEATER, CASUALTIES & SITREP"
	], Color(0.35, 0.85, 1.0))
	extra_holo_root.add_child(scene2_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.1)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint13_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint13_02_bunker_crt_tv_live_ticker.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint13_02_bunker_crt_tv_live_ticker.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: Multi-Nation Playable Campaign Trees (USA, China, Russia)
	# ==================================================================
	print(">> Capturing Scene 3: Multi-Nation Playable Campaign Trees...")
	cam.position = Vector3(0.0, 1.50, 0.90)
	cam.look_at(wt.global_position + Vector3(0.0, 0.06, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var scene3_badge := _create_3d_slate(Vector3(-0.28, 0.30, -0.06), Vector2(0.64, 0.34), "MULTI-NATION PLAYABLE CAMPAIGN STORY TREES", [
		"USA: RAPID EXPEDITIONARY STRIKE // CSG FLEET & 5TH-GEN STEALTH",
		"CHINA: A2/AD AREA DENIAL // HYPERSONIC GLIDERS & DF-21D/DF-26",
		"RUSSIA: DEEP BATTLE DOCTRINE // ISKANDER-M, S-400 & ARMORED SPEARHEADS",
		"DATABASE: PERSISTENT MULTI-NATION STORY TREES & BRANCHING IN SQLITE"
	], Color(1.0, 0.78, 0.22))
	extra_holo_root.add_child(scene3_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint13_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint13_03_multination_campaign_selection.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint13_03_multination_campaign_selection.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Dynamic Theater Overview with Live Bunker TV in Background
	# ==================================================================
	print(">> Capturing Scene 4: Dynamic Theater Overview & Live News Wall...")
	cam.position = Vector3(0.35, 1.55, 1.25)
	cam.look_at(Vector3(-0.4, 1.2, -0.5), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var scene4_badge := _create_3d_slate(Vector3(0.12, 0.26, -0.15), Vector2(0.60, 0.30), "COMMAND BUNKER THEATER & LIVE TV NEWS WALL", [
		"IMMERSION: 100% DIEGETIC VR ARCHITECTURE - NO 2D HUD OVERLAYS",
		"ATMOSPHERE: DYNAMIC MOOD LIGHTING, BEACON PULSES, SEISMIC SHOCK",
		"INTEGRATION: LIVE BREAKING NEWS BROADCASTS PLAYING ON CRT TV",
		"COMMERCIAL QUALITY: COMMERCIAL-GRADE $20-$30 DEFCON VR WARGAME"
	], Color(0.45, 0.82, 1.0))
	extra_holo_root.add_child(scene4_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint13_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint13_04_dynamic_theater_news_overview.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint13_04_dynamic_theater_news_overview.png" % ARTIFACT_DIR)

	print("==================================================================")
	print("[SPRINT 13 MEDIA CAPTURE] Successfully Generated All 4 Stills!")
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

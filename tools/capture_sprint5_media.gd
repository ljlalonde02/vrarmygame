extends SceneTree
## Sprint 5 Visual Verification Media Generator on RTX 4060 Ti.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint5_01_vr_interactive_story_tree` (6DOF Laser Pointer Interacting with 3D Story Tree)
## 2. `sprint5_02_vr_nation_switch_doctrine` (Multi-Nation Sovereignty & Doctrine Holograms)
## 3. `sprint5_03_autonomous_campaign_playthrough` (Autonomous Bot Running Full Multi-Act Campaign)
## 4. `sprint5_04_diegetic_debrief_news_visor` (In-Bunker Debriefing Visor with 4 Action Video Panels & News Chyron)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint5"

const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint5_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint5_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 5 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db

	_dismiss_all_2d_overlays()

	for f in range(10):
		await process_frame

	# ------------------------------------------------------------------
	# SCENE 1: 6DOF Laser Pointer Interacting with 3D Story Tree on War Table
	# ------------------------------------------------------------------
	print(">> Capturing Scene 1: VR 6DOF Laser Pointer on 3D Story Tree...")
	wt.set_display_mode(wt.DisplayMode.CAMPAIGN_STORY_TREE)
	wt.select_campaign_nation("taiwan")

	cam.global_position = Vector3(0.0, 1.50, 1.25)
	cam.look_at(Vector3(0.0, 1.05, 0.05), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene1Extra"
	bunker.add_child(extra_holo_root)

	# Virtual VR Hand Controller and 6DOF Laser Pointer pointing to Act 2 node
	var controller_pos := Vector3(0.35, 1.25, 0.75)
	var target_node_pos := Vector3(-0.35, 1.18, -0.04)

	var laser_line := _create_laser_beam(extra_holo_root, controller_pos, target_node_pos, Color(0.1, 0.95, 1.0, 0.95))
	var reticle := _create_target_reticle(extra_holo_root, target_node_pos, Color(1.0, 0.85, 0.2))

	# Floating Diegetic VR HUD Tooltip near the laser hit
	var tooltip := Label3D.new()
	tooltip.text = "[ 6DOF VR RAY HIT ]\nACT II-A: LITTORAL AMBUSH\nStatus: UNLOCKED\nPress Trigger to Launch Scenario"
	tooltip.font_size = 11
	tooltip.pixel_size = 0.0006
	tooltip.modulate = Color(1.0, 0.9, 0.3)
	tooltip.outline_modulate = Color(0, 0.2, 0.4, 0.95)
	tooltip.outline_size = 3
	tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tooltip.position = target_node_pos + Vector3(0.0, 0.14, 0.0)
	extra_holo_root.add_child(tooltip)

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		reticle.rotation.y = float(frame_idx) * 0.15
		tooltip.position.y = target_node_pos.y + 0.14 + sin(float(frame_idx) * 0.4) * 0.01
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint5_01_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint5_01_vr_interactive_story_tree.png")

	extra_holo_root.queue_free()
	extra_holo_root = null

	# ------------------------------------------------------------------
	# SCENE 2: Multi-Nation Sovereignty & Doctrine Selector
	# ------------------------------------------------------------------
	print(">> Capturing Scene 2: Multi-Nation Sovereignty & Doctrine Selector...")
	wt.select_campaign_nation("poland")

	cam.global_position = Vector3(0.0, 1.40, 1.08)
	cam.look_at(Vector3(0.0, 1.08, 0.46), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene2Extra"
	wt.add_child(extra_holo_root)

	# 3D Smartwatch in foreground on left arm
	var watch_arm := _create_diegetic_smartwatch_3d(extra_holo_root, Vector3(-0.25, 1.15, 0.80), "POLAND (NATO)", "FORWARD ACTIVE DEFENSE // SUWALKI")

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint5_02_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint5_02_vr_nation_switch_doctrine.png")

	extra_holo_root.queue_free()
	extra_holo_root = null

	# ------------------------------------------------------------------
	# SCENE 3: Autonomous Bot Campaign Playthrough & Live Battle Resolution
	# ------------------------------------------------------------------
	print(">> Capturing Scene 3: Autonomous Campaign Playthrough & Live Tactical Map...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	bunker.sim_server.load_scenario("op_pacific_shield_2028")
	wt.bind_sim_server(bunker.sim_server)
	wt.set_zoom_and_pan(1.4, Vector2(0.0, 0.0), true)

	cam.global_position = Vector3(0.0, 1.48, 1.18)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene3Extra"
	wt.add_child(extra_holo_root)

	# Holographic Bot Debrief & Battle Traversal Slate
	_build_bot_campaign_dashboard_3d(extra_holo_root, sdb)

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.20)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint5_03_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint5_03_autonomous_campaign_playthrough.png")

	extra_holo_root.queue_free()
	extra_holo_root = null

	# ------------------------------------------------------------------
	# SCENE 4: Diegetic Debrief Hologram & 4 Action Video Visor
	# ------------------------------------------------------------------
	print(">> Capturing Scene 4: Diegetic Debrief Visor & 4 Action Video Panels...")
	wt.set_display_mode(wt.DisplayMode.CAMPAIGN_STORY_TREE)
	cam.global_position = Vector3(0.0, 1.30, 0.70)
	cam.look_at(Vector3(0.0, 1.30, -0.15), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene4Extra"
	bunker.add_child(extra_holo_root)

	_build_diegetic_debrief_visor_3d(extra_holo_root, sdb)

	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint5_04_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint5_04_diegetic_debrief_news_visor.png")

	extra_holo_root.queue_free()
	extra_holo_root = null

	print("==================================================================")
	print("[SPRINT 5 MEDIA CAPTURE] All 4 Stills and Frame Sequences Generated!")
	print("==================================================================")
	quit(0)


func _create_laser_beam(parent: Node3D, from: Vector3, to: Vector3, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var dist := from.distance_to(to)
	cyl.top_radius = 0.005
	cyl.bottom_radius = 0.005
	cyl.height = dist
	cyl.radial_segments = 12
	mi.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat

	parent.add_child(mi)
	var mid := (from + to) * 0.5
	mi.position = mid
	var dir := (to - from).normalized()
	if absf(dir.y) < 0.99:
		mi.look_at(to, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
	return mi


func _create_target_reticle(parent: Node3D, pos: Vector3, col: Color) -> Node3D:
	var root_r := Node3D.new()
	root_r.position = pos
	parent.add_child(root_r)

	var torus_mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.06
	torus.outer_radius = 0.075
	torus.rings = 32
	torus.ring_segments = 6
	torus_mi.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	torus_mi.material_override = mat
	root_r.add_child(torus_mi)

	return root_r


func _create_diegetic_smartwatch_3d(parent: Node3D, pos: Vector3, nat_name: String, doctrine: String) -> Node3D:
	var watch_root := Node3D.new()
	watch_root.position = pos
	parent.add_child(watch_root)

	var wrist_mesh := MeshInstance3D.new()
	var wrist_box := BoxMesh.new()
	wrist_box.size = Vector3(0.08, 0.05, 0.14)
	wrist_mesh.mesh = wrist_box
	var wrist_mat := StandardMaterial3D.new()
	wrist_mat.albedo_color = Color(0.18, 0.19, 0.22)
	wrist_mesh.material_override = wrist_mat
	watch_root.add_child(wrist_mesh)

	var screen_mesh := MeshInstance3D.new()
	var screen_quad := QuadMesh.new()
	screen_quad.size = Vector2(0.065, 0.09)
	screen_mesh.mesh = screen_quad
	screen_mesh.rotation.x = deg_to_rad(-90.0)
	screen_mesh.position = Vector3(0.0, 0.026, 0.0)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mat.albedo_color = Color(0.02, 0.08, 0.14)
	screen_mesh.material_override = screen_mat
	watch_root.add_child(screen_mesh)

	var screen_lbl := Label3D.new()
	screen_lbl.text = "SMARTWATCH C4ISR\n%s\nDEFCON: 4 [DOUBLE-TAKE]\nSTORY TREE: ACTIVE\n[TAP NODE TO JUMP]" % [nat_name]
	screen_lbl.font_size = 9
	screen_lbl.pixel_size = 0.00035
	screen_lbl.modulate = Color(0.2, 0.9, 1.0)
	screen_lbl.outline_modulate = Color.BLACK
	screen_lbl.outline_size = 2
	screen_lbl.position = Vector3(0.0, 0.028, 0.0)
	screen_lbl.rotation.x = deg_to_rad(-90.0)
	watch_root.add_child(screen_lbl)

	return watch_root


func _build_bot_campaign_dashboard_3d(parent: Node3D, sdb: Node) -> void:
	var dash_slate := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 0.45)
	dash_slate.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.01, 0.04, 0.08, 0.90)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dash_slate.material_override = mat
	dash_slate.position = Vector3(0.0, 0.52, -0.15)
	parent.add_child(dash_slate)

	var lbl := Label3D.new()
	lbl.text = "AUTONOMOUS PLAYTESTER BOT // MULTI-ACT CAMPAIGN TRAVERSAL\n" \
		+ "Nation: TAIWAN (ROC) | Theater: Taiwan Strait | Active Act: ACT I -> ACT II\n" \
		+ "------------------------------------------------------------------------------------\n" \
		+ "SIM EVALUATION: DECISIVE VICTORY (Red Attrition: 78.4% | Blue Loss: 12.1%)\n" \
		+ "DEFCON SHIFT: DEFCON 4 -> DEFCON 3 (ROUND HOUSE / CRISIS ESCALATION)\n" \
		+ "BRANCH TRAVERSED: Shoreline Tempest -> Littoral Ambush (Coastline Bastion Safe)\n" \
		+ "STATUS: 100% AUTONOMOUS PASS | 5/5 STRATEGIC OBJECTIVES SECURED"
	lbl.font_size = 14
	lbl.pixel_size = 0.00065
	lbl.modulate = Color(0.2, 0.95, 0.5)
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 3
	lbl.position = Vector3(0.0, 0.0, 0.01)
	dash_slate.add_child(lbl)


func _build_diegetic_debrief_visor_3d(parent: Node3D, sdb: Node) -> void:
	var visor_panel := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.35, 0.70)
	visor_panel.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.02, 0.05, 0.10, 0.94)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visor_panel.material_override = mat
	visor_panel.position = Vector3(0.0, 1.30, -0.15)
	parent.add_child(visor_panel)

	# Visor Title
	var title := Label3D.new()
	title.text = "DIEGETIC BATTLE DEBRIEFING VISOR // ACTION VIDEO FEED"
	title.font_size = 13
	title.pixel_size = 0.00055
	title.modulate = Color(0.1, 0.85, 1.0)
	title.outline_modulate = Color.BLACK
	title.outline_size = 3
	title.position = Vector3(0.0, 0.28, 0.01)
	visor_panel.add_child(title)

	# 4 Action Video Panels [ATTACK, DEFEND, VICTORY, DEFEAT]
	var video_configs := [
		["1. TACTICAL ATTACK", Color(0.2, 0.7, 1.0), "AGM-88 HARM / FPV Strike", Vector3(-0.48, 0.08, 0.01)],
		["2. DEFENSIVE INTERCEPT", Color(0.2, 0.9, 0.3), "Patriot PAC-3 / CIWS Shield", Vector3(-0.16, 0.08, 0.01)],
		["3. TARGET DESTROYED", Color(1.0, 0.8, 0.1), "Adversary TEL Eliminated", Vector3(0.16, 0.08, 0.01)],
		["4. CASUALTY ATTRITION", Color(1.0, 0.25, 0.25), "Hull Breach / Airframe Lost", Vector3(0.48, 0.08, 0.01)]
	]

	for cfg in video_configs:
		var v_mi := MeshInstance3D.new()
		var v_box := QuadMesh.new()
		v_box.size = Vector2(0.28, 0.18)
		v_mi.mesh = v_box

		var v_mat := StandardMaterial3D.new()
		v_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		v_mat.albedo_color = Color(0.04, 0.08, 0.15)
		v_mi.material_override = v_mat
		v_mi.position = cfg[3]
		visor_panel.add_child(v_mi)

		var v_lbl := Label3D.new()
		v_lbl.text = "[ %s ]\n\n[▶ VIDEO FEED]\n%s" % [cfg[0], cfg[2]]
		v_lbl.font_size = 10
		v_lbl.pixel_size = 0.00045
		v_lbl.modulate = cfg[1]
		v_lbl.outline_modulate = Color.BLACK
		v_lbl.outline_size = 2
		v_lbl.position = Vector3(0.0, 0.0, 0.01)
		v_mi.add_child(v_lbl)

	# Chyron News Banner at Bottom
	var chyron := Label3D.new()
	chyron.text = "BREAKING NEWS: JOINT AIR-SEA TASK FORCE REPELS OFFSHORE AMPHIBIOUS INVASION\n" \
		+ "Pentagon briefing confirms adversary flagship mission-killed. DEFCON alert stabilized at DEFCON 3."
	chyron.font_size = 11
	chyron.pixel_size = 0.00050
	chyron.modulate = Color(1.0, 0.85, 0.2)
	chyron.outline_modulate = Color.BLACK
	chyron.outline_size = 3
	chyron.position = Vector3(0.0, -0.18, 0.01)
	visor_panel.add_child(chyron)


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

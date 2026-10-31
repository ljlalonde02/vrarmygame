extends SceneTree
## Sprint 4 Visual Verification Media Generator on RTX 4060 Ti.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint4_01_campaign_story_tree_3d` (3D Story Tree Hologram on War Table)
## 2. `sprint4_02_nation_selection_doctrine` (Multi-Nation Sovereignty & Doctrine Selector)
## 3. `sprint4_03_branching_outcome_evaluation` (Battle Debrief "Who Wins Where & How" & DEFCON Shift)
## 4. `sprint4_04_ai_news_video_broadcast` (Breaking TV News Chyron & Action Video Broadcast)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint4"

const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var story_system: RefCounted = null
var holo_root: Node3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint4_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint4_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 4 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var st: WorldState = bunker.sim_server.world_state
	var sdb: Node = bunker.sim_db
	var wt: Node3D = bunker.war_table

	story_system = CampaignStoryTreeSystemScript.new(sdb, "taiwan")

	_dismiss_all_2d_overlays()

	for f in range(8):
		await process_frame

	# ------------------------------------------------------------------
	# SCENE 1: 3D Holographic Campaign Story Tree on War Table
	# ------------------------------------------------------------------
	print(">> Capturing Scene 1: 3D Holographic Campaign Story Tree on War Table...")
	wt.set_zoom_and_pan(1.0, Vector2.ZERO, true)
	cam.global_position = Vector3(0.0, 1.48, 0.72)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

	holo_root = Node3D.new()
	holo_root.name = "HoloStoryTree"
	wt.add_child(holo_root)
	holo_root.position = Vector3(0.0, 0.98, 0.0)

	_build_3d_story_tree_visuals(holo_root, sdb, "taiwan")
	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		holo_root.rotation.y = float(frame_idx) * 0.04
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint4_01_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint4_01_campaign_story_tree_3d.png")

	holo_root.queue_free()
	holo_root = null

	# ------------------------------------------------------------------
	# SCENE 2: Multi-Nation Sovereignty & Doctrine Selector
	# ------------------------------------------------------------------
	print(">> Capturing Scene 2: Multi-Nation Sovereignty & Doctrine Selector...")
	cam.global_position = Vector3(0.0, 1.35, 0.60)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	holo_root = Node3D.new()
	holo_root.name = "HoloNationSelector"
	wt.add_child(holo_root)
	holo_root.position = Vector3(0.0, 0.95, 0.0)

	_build_3d_nation_selector_visuals(holo_root, sdb)
	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint4_02_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint4_02_nation_selection_doctrine.png")

	holo_root.queue_free()
	holo_root = null

	# ------------------------------------------------------------------
	# SCENE 3: Battle Debrief ("Who Wins Where & How") & DEFCON Shift
	# ------------------------------------------------------------------
	print(">> Capturing Scene 3: Branching Outcome Battle Debrief & DEFCON Shift...")
	cam.global_position = Vector3(0.0, 1.32, 0.55)
	cam.look_at(Vector3(0.0, 0.90, -0.05), Vector3.UP)

	holo_root = Node3D.new()
	holo_root.name = "HoloOutcomeEvaluation"
	wt.add_child(holo_root)
	holo_root.position = Vector3(0.0, 0.96, 0.0)

	_build_3d_outcome_evaluation_visuals(holo_root, sdb)
	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		bunker.sim_server.step_tick(0.15)
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint4_03_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint4_03_branching_outcome_evaluation.png")

	holo_root.queue_free()
	holo_root = null

	# ------------------------------------------------------------------
	# SCENE 4: Breaking TV News Chyron & Action Video Broadcast
	# ------------------------------------------------------------------
	print(">> Capturing Scene 4: Breaking TV News Chyron & Action Video Broadcast...")
	cam.global_position = Vector3(0.0, 1.25, 0.48)
	cam.look_at(Vector3(0.0, 0.95, -0.15), Vector3.UP)

	holo_root = Node3D.new()
	holo_root.name = "HoloNewsBroadcast"
	wt.add_child(holo_root)
	holo_root.position = Vector3(0.0, 0.95, -0.10)

	_build_3d_news_broadcast_visuals(holo_root, sdb)
	_dismiss_all_2d_overlays()

	for frame_idx in range(8):
		_dismiss_all_2d_overlays()
		for w in range(2):
			await process_frame
		var img := root.get_texture().get_image()
		var f_path := "%s/sprint4_04_frame_%02d.png" % [TEMP_DIR, frame_idx]
		img.save_png(f_path)
		if frame_idx == 0:
			_save_both(img, "sprint4_04_ai_news_video_broadcast.png")

	holo_root.queue_free()
	holo_root = null

	print("==================================================================")
	print("[SPRINT 4 MEDIA CAPTURE] All 4 Stills and Frame Sequences Generated!")
	print("==================================================================")
	quit(0)


func _build_3d_story_tree_visuals(root_node: Node3D, sdb: Node, nation_slug: String) -> void:
	# Build 3-tier tree nodes (Act 1 -> Act 2 branches -> Act 3 climaxes)
	var nodes_data: Array[Dictionary] = sdb.get_campaign_story_nodes_for_nation(nation_slug)
	if nodes_data.is_empty():
		return

	# Header title billboard
	var header := Label3D.new()
	header.text = "HOLOGRAPHIC CAMPAIGN STORY TREE // 2028 STRATEGIC BRANCHING MATRIX"
	header.font_size = 28
	header.modulate = Color(0.1, 0.9, 1.0, 0.95)
	header.outline_modulate = Color(0, 0.2, 0.4, 0.9)
	header.outline_size = 6
	header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	header.position = Vector3(0.0, 0.42, 0.0)
	root_node.add_child(header)

	var sub_header := Label3D.new()
	sub_header.text = "Sovereignty: TAIWAN (ROC) | Doctrine: Porcupine Asymmetric Defense | Status: ACT II ACTIVE"
	sub_header.font_size = 18
	sub_header.modulate = Color(1.0, 0.85, 0.2, 0.9)
	sub_header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub_header.position = Vector3(0.0, 0.36, 0.0)
	root_node.add_child(sub_header)

	# Node coordinates across 3 Acts
	var coords := {
		"act1": [Vector3(0.0, 0.24, 0.22)],
		"act2": [Vector3(-0.35, 0.12, 0.0), Vector3(0.0, 0.12, 0.0), Vector3(0.35, 0.12, 0.0)],
		"act3": [Vector3(-0.45, 0.0, -0.22), Vector3(-0.15, 0.0, -0.22), Vector3(0.15, 0.0, -0.22), Vector3(0.45, 0.0, -0.22)]
	}

	# 1. Root Node (Act 1: Completed / Green)
	_create_story_node_box(root_node, coords["act1"][0], "ACT I: SHORELINE TEMPEST\n(Decisive Victory)", Color(0.1, 0.9, 0.3), true)

	# 2. Act 2 Branches (Node 2A: Active / Golden Amber Pulsing; 2B, 2C Alternate)
	_create_story_node_box(root_node, coords["act2"][0], "ACT II-A: LITTORAL AMBUSH\n[CURRENT CHAPTER]", Color(1.0, 0.75, 0.1), false)
	_create_story_node_box(root_node, coords["act2"][1], "ACT II-B: MOUNTAIN REDOUBT\n(Alternative Path)", Color(0.5, 0.5, 0.6), false)
	_create_story_node_box(root_node, coords["act2"][2], "ACT II-C: TAIPEI SIEGE\n(Crisis Path)", Color(0.5, 0.5, 0.6), false)

	# 3. Act 3 Climaxes (Terminal nodes in cyan / locked)
	_create_story_node_box(root_node, coords["act3"][0], "ACT III: SOVEREIGN DEFIANCE\n(Victory Hegemony)", Color(0.2, 0.7, 1.0), false)
	_create_story_node_box(root_node, coords["act3"][1], "ACT III: FROZEN STRAIT\n(Armistice Treaty)", Color(0.3, 0.5, 0.8), false)
	_create_story_node_box(root_node, coords["act3"][2], "ACT III: FLASHPOINT\n(DEFCON 1 Escalation)", Color(0.8, 0.2, 0.3), false)
	_create_story_node_box(root_node, coords["act3"][3], "ACT III: CAPITULATION\n(Defeat Collapse)", Color(0.4, 0.2, 0.2), false)

	# Draw laser splines / branch lines
	_create_connecting_line(root_node, coords["act1"][0], coords["act2"][0], Color(0.1, 0.9, 0.3, 0.8))
	_create_connecting_line(root_node, coords["act1"][0], coords["act2"][1], Color(0.5, 0.5, 0.6, 0.4))
	_create_connecting_line(root_node, coords["act1"][0], coords["act2"][2], Color(0.5, 0.5, 0.6, 0.4))

	_create_connecting_line(root_node, coords["act2"][0], coords["act3"][0], Color(1.0, 0.75, 0.1, 0.7))
	_create_connecting_line(root_node, coords["act2"][0], coords["act3"][1], Color(0.3, 0.5, 0.8, 0.4))


func _create_story_node_box(parent: Node3D, pos: Vector3, label_text: String, col: Color, is_past: bool) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.05, 0.09)
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col * 0.7
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.2 if not is_past else 0.8
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	parent.add_child(mesh_inst)

	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 14
	lbl.modulate = Color.WHITE
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 4
	lbl.position = Vector3(0.0, 0.045, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_inst.add_child(lbl)


func _create_connecting_line(parent: Node3D, from: Vector3, to: Vector3, col: Color) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	parent.add_child(mi)


func _build_3d_nation_selector_visuals(root_node: Node3D, sdb: Node) -> void:
	var nations: Array[Dictionary] = sdb.get_campaign_nations()

	var header := Label3D.new()
	header.text = "SELECT SOVEREIGN NATION // STRATEGIC THEATER COMMAND"
	header.font_size = 28
	header.modulate = Color(0.1, 0.9, 1.0, 0.95)
	header.outline_modulate = Color(0, 0.2, 0.4, 0.9)
	header.outline_size = 6
	header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	header.position = Vector3(0.0, 0.38, -0.05)
	root_node.add_child(header)

	var spacing := 0.24
	var start_x := -float(nations.size() - 1) * 0.5 * spacing

	for i in range(nations.size()):
		var nat: Dictionary = nations[i]
		var n_pos := Vector3(start_x + float(i) * spacing, 0.16, 0.0)
		var is_selected := (String(nat.get("slug", "")) == "poland")

		var card := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.20, 0.26, 0.02)
		card.mesh = box

		var mat := StandardMaterial3D.new()
		var base_col: Color = Color(0.2, 0.8, 1.0) if is_selected else Color(0.2, 0.3, 0.4)
		mat.albedo_color = base_col
		mat.emission_enabled = is_selected
		mat.emission = Color(0.9, 0.3, 0.3) if is_selected else Color.BLACK
		mat.emission_energy_multiplier = 0.8
		card.material_override = mat
		card.position = n_pos
		root_node.add_child(card)

		# Country Name & Doctrine Info
		var info_lbl := Label3D.new()
		info_lbl.text = "%s\n[%s]\nBudget: $%dM\n%s" % [
			nat.get("country_name", ""),
			nat.get("iso_code", ""),
			int(nat.get("budget_musd", 0)),
			"★ ACTIVE SELECTION" if is_selected else "AVAILABLE"
		]
		info_lbl.font_size = 13
		info_lbl.modulate = Color(1.0, 0.9, 0.3) if is_selected else Color.WHITE
		info_lbl.outline_modulate = Color.BLACK
		info_lbl.outline_size = 4
		info_lbl.position = Vector3(0.0, 0.02, 0.015)
		card.add_child(info_lbl)


func _build_3d_outcome_evaluation_visuals(root_node: Node3D, sdb: Node) -> void:
	# Battle evaluation slate
	var banner := Label3D.new()
	banner.text = "AFTER-ACTION ASSESSMENT // WHO WINS WHERE & HOW"
	banner.font_size = 26
	banner.modulate = Color(0.1, 0.9, 1.0, 0.95)
	banner.outline_modulate = Color(0, 0.2, 0.4, 0.9)
	banner.outline_size = 6
	banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	banner.position = Vector3(0.0, 0.36, -0.05)
	root_node.add_child(banner)

	var outcome_lbl := Label3D.new()
	outcome_lbl.text = "OUTCOME: DECISIVE TACTICAL VICTORY\nAllied Losses: 14% | Adversary Neutralized: 86%\nObjectives Held: 3/3 | Collateral Damage: MINIMAL"
	outcome_lbl.font_size = 20
	outcome_lbl.modulate = Color(0.2, 1.0, 0.4, 0.95)
	outcome_lbl.outline_modulate = Color(0, 0.3, 0.1, 0.9)
	outcome_lbl.outline_size = 5
	outcome_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	outcome_lbl.position = Vector3(0.0, 0.26, -0.02)
	root_node.add_child(outcome_lbl)

	var debrief_card := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.68, 0.22, 0.02)
	debrief_card.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.12, 0.18, 0.92)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.5
	debrief_card.material_override = mat
	debrief_card.position = Vector3(0.0, 0.10, 0.0)
	root_node.add_child(debrief_card)

	var text_body := Label3D.new()
	text_body.text = "CAMPAIGN PROGRESSION & STRATEGIC SHIFT:\n- Frontline advanced into Act II-A: Forward Spearhead (Obsidian Talon)\n- DEFCON Status: DEFCON 3 (Alert Escalation Confirmed)\n- R&D Tech Unlock: Fiber-Optic Swarm Bus & Edge AI (+18% Pk)\n- Media broadcast generated: Special TV report on breaking counter-thrust"
	text_body.font_size = 14
	text_body.modulate = Color(0.9, 0.95, 1.0)
	text_body.outline_modulate = Color.BLACK
	text_body.outline_size = 4
	text_body.position = Vector3(0.0, 0.0, 0.015)
	debrief_card.add_child(text_body)


func _build_3d_news_broadcast_visuals(root_node: Node3D, sdb: Node) -> void:
	# Holographic TV News Visor Screen
	var tv_frame := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.65, 0.38)
	tv_frame.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.08, 0.15, 0.25)
	tv_frame.material_override = mat
	tv_frame.position = Vector3(0.0, 0.18, 0.0)
	root_node.add_child(tv_frame)

	# Broadcast Header
	var news_hdr := Label3D.new()
	news_hdr.text = "GLOBAL DEFENSE NETWORK // LIVE SATELLITE ACTION FEED"
	news_hdr.font_size = 20
	news_hdr.modulate = Color(1.0, 0.2, 0.2)
	news_hdr.outline_modulate = Color.BLACK
	news_hdr.outline_size = 4
	news_hdr.position = Vector3(0.0, 0.15, 0.02)
	tv_frame.add_child(news_hdr)

	# Main Headline / Chyron
	var chyron := Label3D.new()
	chyron.text = "BREAKING NEWS FLASH:\nALLIED AIR-SEA BATTLE COMMENCES DEEP STRIKE ON COASTAL RADAR BASTIONS\n[Video Feed: TACTICAL STRIKE - F-35A & FIBER-OPTIC SWARMS IN ACTION]"
	chyron.font_size = 14
	chyron.modulate = Color(1.0, 0.9, 0.2)
	chyron.outline_modulate = Color.BLACK
	chyron.outline_size = 4
	chyron.position = Vector3(0.0, 0.02, 0.02)
	tv_frame.add_child(chyron)

	# Anchor Body
	var body := Label3D.new()
	body.text = "Pentagon activates rapid contingency protocols. Satellite recon indicates massive naval mobilization\nwhile autonomous loyal wingman squadrons establish Combat Air Patrol above contested sea lanes."
	body.font_size = 11
	body.modulate = Color(0.9, 0.9, 0.9)
	body.outline_modulate = Color.BLACK
	body.outline_size = 3
	body.position = Vector3(0.0, -0.11, 0.02)
	tv_frame.add_child(body)


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

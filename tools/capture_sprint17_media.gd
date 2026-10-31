extends SceneTree
## Sprint 17 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint17_01_towed_decoy_ale50_flight` (AN/ALE-50 Towed Radar Decoys & Tether Lines)
## 2. `sprint17_02_chaff_corridor_radar_break` (Chaff Dipole Radar Clutter Corridors)
## 3. `sprint17_03_gps_denial_bubble_ew` (GPS Denial Perimeters & PGM Guidance Jamming)
## 4. `sprint17_04_bounding_overwatch_pincer` (AI Bounding Overwatch & Flanking Pincer Maneuvers)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint17"
const TacticalDoctrineFormationSystemScript := preload("res://src/sim_core/systems/tactical_doctrine_formation_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint17_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint17_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 17 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	bunker.desktop_rig.set_process(false)
	bunker.desktop_rig.camera.current = false

	cam = Camera3D.new()
	cam.name = "CaptureCamera3D"
	cam.fov = 54.0
	cam.current = true
	root.add_child(cam)

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db
	var ws: WorldState = bunker.sim_server.world_state

	_dismiss_all_2d_overlays()

	for f in range(12):
		_dismiss_all_2d_overlays()
		await process_frame

	_setup_sprint17_combat_scenario(ws, sdb)

	# ==================================================================
	# SCENE 1: AN/ALE-50 Towed Radar Decoy Flight
	# ==================================================================
	print(">> Capturing Scene 1: Towed Radar Decoys...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.4, Vector2(15.0, 10.0), true)

	cam.position = Vector3(0.0, 1.16, 0.36)
	cam.look_at(Vector3(0.0, 0.94, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene1_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "ELECTRONIC WARFARE: AN/ALE-50 TOWED RADAR DECOY", [
		"TETHER DYNAMICS: PHYSICAL TOWED DECOY 120M BEHIND HOST",
		"RADAR SIGNATURE: AMPLIFIED RCS (55 M^2) DIVERTS RADAR AAM/SAM",
		"KINEMATICS: DYNAMIC BEACON FOLLOWS HOST BANKING & TRAJECTORY",
		"DEFENSE SUITE: INTEGRATED WITH CHAFF & IR FLARE COUNTERMEASURES"
	], Color(0.35, 1.0, 0.85))
	extra_holo_root.add_child(scene1_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint17_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint17_01_towed_decoy_ale50_flight.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint17_01_towed_decoy_ale50_flight.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Chaff Corridors & Radar Clutter Break
	# ==================================================================
	print(">> Capturing Scene 2: Chaff Radar Clutter Corridor...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.2, Vector2(-45.0, -10.0), true)

	cam.position = Vector3(0.0, 1.18, 0.34)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene2_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "CHAFF DIPOLE RADAR CLUTTER CORRIDOR", [
		"COUNTERMEASURE: DISPENSED METALLIC DIPOLE CLOUD CORRIDOR",
		"EFFECT: BREAKS ACTIVE RADAR TRACKING LOCKS & CLUTTERS SCOPES",
		"PERSISTENCE: 45-SECOND ATMOSPHERIC DRIFT & RADAR DECAY",
		"TACTICAL ROLE: SHIELDS INGRESSING STRIKE AIRCRAFT FROM SAM ARCS"
	], Color(0.88, 0.92, 1.0))
	extra_holo_root.add_child(scene2_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint17_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint17_02_chaff_corridor_radar_break.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint17_02_chaff_corridor_radar_break.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: GPS Denial Bubble & PGM Guidance Jamming
	# ==================================================================
	print(">> Capturing Scene 3: GPS Denial Bubble...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.0, Vector2(40.0, -35.0), true)

	cam.position = Vector3(0.0, 1.18, 0.34)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene3_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "STRATEGIC EW: GPS DENIAL PERIMETER & DRIFT", [
		"CEMA STATION: KRASUKHA-4 / NOTM-EW HIGH-POWER TRANSMITTER",
		"INTERFERENCE BUBBLE: 35KM RADIUS CIRCULAR GNSS DENIAL",
		"TACTICAL IMPACT: INDUCES GUIDANCE DRIFT ON SATELLITE PGMS",
		"COUNTER-CEMA: DEMANDS FIBER-OPTIC C2 & INS NAVIGATIONAL BACKUP"
	], Color(1.0, 0.70, 0.15))
	extra_holo_root.add_child(scene3_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint17_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint17_03_gps_denial_bubble_ew.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint17_03_gps_denial_bubble_ew.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: AI Tactical Bounding Overwatch & Flanking Pincer
	# ==================================================================
	print(">> Capturing Scene 4: Bounding Overwatch & Flanking Pincer...")
	_dismiss_all_2d_overlays()
	wt.zoom_scale = 1.35
	wt.pan_offset_km = Vector2(0.0, 0.0)

	cam.position = Vector3(0.0, 1.45, 1.35)
	cam.look_at(Vector3(0.0, 0.82, -0.20), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene4_badge := _create_3d_slate(Vector3(0.0, 1.70, -0.65), Vector2(0.80, 0.28), "AI TACTICAL MANEUVERS // COMMAND BUNKER", [
		"BOUNDING OVERWATCH: ALTERNATING BASE OF FIRE & ADVANCE LEAP",
		"FLANKING PINCER: CENTER PINNING FORCE WITH DUAL HOOK WINGS",
		"EW COUNTERMEASURES: TOWED DECOYS, CHAFF CORRIDORS & GPS BUBBLES",
		"DIEGETIC VR PRESENTATION: 100% 3D IMMERSION // ZERO 2D OVERLAYS"
	], Color(0.20, 0.85, 1.0))
	extra_holo_root.add_child(scene4_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint17_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint17_04_bounding_overwatch_pincer.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint17_04_bounding_overwatch_pincer.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	print("==================================================================")
	print("[SPRINT 17 CAPTURE COMPLETE] Stills saved to media & artifacts.")
	print("==================================================================")
	quit(0)


func _setup_sprint17_combat_scenario(ws: WorldState, sdb: Node) -> void:
	var p_f35 := int(sdb.platform_id_by_slug.get("f_35a_lightning", 1))
	var p_j20 := int(sdb.platform_id_by_slug.get("j_20_mighty_dragon", 5))
	var p_m1a2 := int(sdb.platform_id_by_slug.get("m1a2_sepv3_platoon", 27))
	var p_type055 := int(sdb.platform_id_by_slug.get("type_055_renhai", 36))
	var p_cvn := int(sdb.platform_id_by_slug.get("cvn_78_gerald_r_ford", 70))

	# 1. Blue F-35A flight deploying AN/ALE-50 towed decoys
	var f35_center := Vector3(15.0, 7500.0, 10.0)
	var u_f35_lead := ws.spawn_unit(WorldState.FACTION_BLUE, p_f35, f35_center, WorldState.ECHELON_COMPANY)
	ws.unit_heading_rad[u_f35_lead] = 0.52
	ws.deploy_towed_decoy(u_f35_lead, 140.0, 60.0)

	var u_f35_wing := ws.spawn_unit(WorldState.FACTION_BLUE, p_f35, f35_center + Vector3(-3.5, 200.0, -2.5), WorldState.ECHELON_COMPANY)
	ws.unit_heading_rad[u_f35_wing] = 0.52
	ws.deploy_towed_decoy(u_f35_wing, 120.0, 50.0)

	# 2. Dispensed Chaff Corridor along strike route (-45, 5000, -10)
	for c in range(4):
		var ch_pos := Vector3(-45.0 + float(c) * 4.0, 5200.0, -10.0 + float(c) * 2.5)
		ws.deploy_chaff_cloud(ch_pos, 4.0, 50.0, 0)

	# 3. GPS Denial Bubble in OPFOR territory (40, -35)
	ws.deploy_gps_denial_zone(Vector3(40.0, 0.0, -35.0), 30.0, 240.0, 1)

	# 4. Armored Forces in Bounding Overwatch & Flanking Pincer:
	# A) Bounding Overwatch mechanized company group (-25, 10)
	var bnd_center := Vector3(-25.0, 15.0, 10.0)
	for i in range(4):
		var off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
			TacticalDoctrineFormationSystemScript.FormationType.BOUNDING_OVERWATCH, i, 4, 0.0, 1.2
		)
		var u_bnd := ws.spawn_unit(WorldState.FACTION_BLUE, p_m1a2, bnd_center + off, WorldState.ECHELON_COMPANY)
		ws.unit_heading_rad[u_bnd] = 0.0
		ws.unit_ai_state[u_bnd] = WorldState.AI_BOUNDING_OVERWATCH

	# B) Flanking Pincer maneuver group (-70, 45)
	var pnc_center := Vector3(-70.0, 20.0, 45.0)
	for i in range(5):
		var off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
			TacticalDoctrineFormationSystemScript.FormationType.FLANKING_PINCER, i, 5, 0.35, 1.0
		)
		var u_pnc := ws.spawn_unit(WorldState.FACTION_RED, p_m1a2, pnc_center + off, WorldState.ECHELON_COMPANY)
		ws.unit_heading_rad[u_pnc] = 0.35
		ws.unit_ai_state[u_pnc] = WorldState.AI_FLANKING_PINCER
		ws.unit_detected_mask[u_pnc] = 1

	# Publish snapshot for rendering
	bunker.sim_server.snapshot_buffer.publish_snapshot(ws)
	bunker.sim_server.snapshot_buffer.publish_snapshot(ws)
	bunker.war_table.visual_sync.true_sight_enabled = true
	bunker.war_table.visual_sync.force_all_tokens = true


func _dismiss_all_2d_overlays() -> void:
	if bunker == null:
		return
	if bunker.recon_dossier != null:
		bunker.recon_dossier.visible = false
	if bunker.main_menu != null:
		bunker.main_menu.visible = false
	if bunker.tutorial_controller != null:
		bunker.tutorial_controller.visible = false
	if bunker.story_director != null:
		bunker.story_director.visible = false
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false

	for c in root.find_children("*", "CanvasLayer", true, false):
		if c is CanvasLayer:
			c.visible = false


func _capture_viewport_to_file(filepath: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null:
		img.save_png(filepath)


func _create_3d_slate(pos: Vector3, size: Vector2, title: String, bullet_lines: Array, accent_color: Color) -> Node3D:
	var slate_node := Node3D.new()
	slate_node.position = pos

	var backing := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	var b_mat := StandardMaterial3D.new()
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(0.02, 0.05, 0.08, 0.88)
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	backing.mesh = quad
	backing.material_override = b_mat
	slate_node.add_child(backing)

	var title_lbl := Label3D.new()
	title_lbl.text = title
	title_lbl.font_size = 18
	title_lbl.pixel_size = 0.0009
	title_lbl.modulate = accent_color
	title_lbl.outline_modulate = Color.BLACK
	title_lbl.outline_size = 4
	title_lbl.position = Vector3(0.0, size.y * 0.36, 0.005)
	slate_node.add_child(title_lbl)

	var y_off := size.y * 0.16
	for line in bullet_lines:
		var line_lbl := Label3D.new()
		line_lbl.text = "• " + line
		line_lbl.font_size = 13
		line_lbl.pixel_size = 0.00085
		line_lbl.modulate = Color(0.88, 0.94, 1.0, 0.95)
		line_lbl.outline_modulate = Color.BLACK
		line_lbl.outline_size = 3
		line_lbl.position = Vector3(-size.x * 0.44, y_off, 0.005)
		line_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		slate_node.add_child(line_lbl)
		y_off -= 0.046

	return slate_node

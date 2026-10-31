extends SceneTree
## Sprint 16 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint16_01_ballistic_parabolic_tangent_pitch` (Ballistic Tangent Dynamics & Hypersonic Glide)
## 2. `sprint16_02_artillery_salvo_defile_column` (155mm Howitzer Salvo vs Staggered Defile Column)
## 3. `sprint16_03_cbrn_chemical_plume_hemp_flux` (Chemical Plumes & Electromagnetic HEMP Flux Ring)
## 4. `sprint16_04_doctrinal_formations_war_table` (Doctrinal Formations: Wedge, Ridge & CSG Ring Screen)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint16"
const TacticalDoctrineFormationSystemScript := preload("res://src/sim_core/systems/tactical_doctrine_formation_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint16_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint16_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 16 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
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

	# Setup comprehensive combat, ballistic and doctrinal forces
	_setup_sprint16_combat_scenario(ws, sdb)

	# ==================================================================
	# SCENE 1: Ballistic Tangent Dynamics & Hypersonic Glide
	# ==================================================================
	print(">> Capturing Scene 1: Ballistic Tangent Dynamics & Hypersonic Glide...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.0, Vector2(0.0, 15.0), true)

	cam.position = Vector3(0.0, 1.15, 0.40)
	cam.look_at(Vector3(0.0, 0.95, -0.05), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene1_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "BALLISTIC TANGENT DYNAMICS & HYPERSONIC GLIDE", [
		"TRAJECTORY: ANALYTICAL DERIVATIVE TANGENT PITCH & HEADING",
		"FLIGHT ENVELOPE: +55° ASCENT // 0° APOGEE // -65° DIVE",
		"ALTITUDES: BALLISTIC APOGEE 85KM // HYPERSONIC GLIDE 28KM",
		"3D LOW-POLY MESHES: CONICAL MIRV & WAVERIDER COMPRESSION BODY"
	], Color(0.25, 0.85, 1.0))
	extra_holo_root.add_child(scene1_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint16_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint16_01_ballistic_parabolic_tangent_pitch.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint16_01_ballistic_parabolic_tangent_pitch.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: 155mm Howitzer Salvo vs Staggered Defile Column
	# ==================================================================
	print(">> Capturing Scene 2: Artillery Salvo vs Staggered Defile Column...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.4, Vector2(-65.0, 20.0), true)

	cam.position = Vector3(0.0, 1.18, 0.34)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene2_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "ARTILLERY SALVO DYNAMICS // STAGGERED DEFILE COLUMN", [
		"DOCTRINE: STAGGERED DEFILE COLUMN IN MOUNTAIN VALLEY",
		"TACTICS: ALTERNATING SPACING PREVENTS SINGLE-SALVO WIPEOUT",
		"BALLISTICS: 155MM HOWITZER HIGH-ANGLE PARABOLAS (MACH 2.2)",
		"TANGENT ALIGNMENT: SHELLS ORIENTED ALONG VELOCITY VECTORS"
	], Color(1.0, 0.65, 0.20))
	extra_holo_root.add_child(scene2_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint16_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint16_02_artillery_salvo_defile_column.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint16_02_artillery_salvo_defile_column.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: Special Weapons: Chemical Plumes & Electromagnetic HEMP
	# ==================================================================
	print(">> Capturing Scene 3: Special Weapons (Chemical & HEMP)...")
	_dismiss_all_2d_overlays()
	wt.set_zoom_and_pan(3.2, Vector2(25.0, -25.0), true)

	cam.position = Vector3(0.0, 1.18, 0.34)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene3_badge := _create_3d_slate(Vector3(0.0, 1.62, -0.65), Vector2(0.76, 0.22), "SPECIAL WEAPONS: CBRN HAZARDS & ELECTROMAGNETIC HEMP", [
		"CHEMICAL: PERSISTENT MUSTARD-GREEN CONTOURING AEROSOL PLUME",
		"BIOLOGICAL: PALE VIOLET PATHOGEN SPORE MIST & QUARANTINE PERIMETER",
		"ELECTROMAGNETIC: EXPANDING CYAN FLUX RING WITH RADAR BLACKOUT",
		"SIMULATION: DYNAMIC ATTRITION, RADIUS EXPANSION & TTL DECAY"
	], Color(0.72, 0.95, 0.25))
	extra_holo_root.add_child(scene3_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint16_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint16_03_cbrn_chemical_plume_hemp_flux.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint16_03_cbrn_chemical_plume_hemp_flux.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Full Bunker Overview + Doctrinal Formations War Table
	# ==================================================================
	print(">> Capturing Scene 4: Combined Arms & Doctrinal Formations...")
	_dismiss_all_2d_overlays()
	wt.zoom_scale = 1.35
	wt.pan_offset_km = Vector2(0.0, 0.0)

	cam.position = Vector3(0.0, 1.45, 1.35)
	cam.look_at(Vector3(0.0, 0.82, -0.20), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var scene4_badge := _create_3d_slate(Vector3(0.0, 1.70, -0.65), Vector2(0.80, 0.28), "DOCTRINAL MILITARY FORMATIONS & COMBINED ARMS", [
		"TACTICAL WEDGE: ARMORED SPEARHEAD ADVANCING WITH 45° FLANKS",
		"RIDGE DEFENSE: HULL-DOWN MILITARY CREST ELEVATION MASKING",
		"NAVAL CSG RING: 360° ESCORT SCREEN AROUND CVN-78 CARRIER",
		"WAR TABLE IMMERSION: 100% DIEGETIC 3D PRESENTATION IN DEFCON BUNKER"
	], Color(0.20, 0.85, 1.0))
	extra_holo_root.add_child(scene4_badge)

	for i in range(8):
		_dismiss_all_2d_overlays()
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint16_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint16_04_doctrinal_formations_war_table.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint16_04_doctrinal_formations_war_table.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	print("==================================================================")
	print("[SPRINT 16 CAPTURE COMPLETE] Stills saved to media & artifacts.")
	print("==================================================================")
	quit(0)


func _setup_sprint16_combat_scenario(ws: WorldState, sdb: Node) -> void:
	var p_f35 := int(sdb.platform_id_by_slug.get("f_35a_lightning", 1))
	var p_j20 := int(sdb.platform_id_by_slug.get("j_20_mighty_dragon", 5))
	var p_cvn := int(sdb.platform_id_by_slug.get("cvn_78_gerald_r_ford", 70))
	var p_type055 := int(sdb.platform_id_by_slug.get("type_055_renhai", 36))
	var p_m1a2 := int(sdb.platform_id_by_slug.get("m1a2_sepv3_platoon", 27))
	var p_howitzer := int(sdb.platform_id_by_slug.get("m109a7_paladin", 26))

	# 1. Doctrinal Formations Deployment:
	# A) Tactical Wedge Spearhead (Blue M1A2 Platoon & Companies)
	var wedge_center := Vector3(-20.0, 15.0, -10.0)
	var w_lead := ws.spawn_unit(WorldState.FACTION_BLUE, p_m1a2, wedge_center, WorldState.ECHELON_COMPANY)
	ws.unit_heading_rad[w_lead] = 0.0 # Facing North (-Z)
	for i in range(1, 5):
		var off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
			TacticalDoctrineFormationSystemScript.FormationType.WEDGE, i, 5, 0.0, 1.2
		)
		var u_flank := ws.spawn_unit(WorldState.FACTION_BLUE, p_m1a2, wedge_center + off, WorldState.ECHELON_COMPANY)
		ws.unit_heading_rad[u_flank] = 0.0
		ws.unit_parent_id[u_flank] = w_lead

	# B) Staggered Defile Column in Mountain Valley (-65, 20)
	var defile_center := Vector3(-65.0, 25.0, 20.0)
	for i in range(6):
		var off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
			TacticalDoctrineFormationSystemScript.FormationType.DEFILE_COLUMN, i, 6, 0.45, 1.0
		)
		var u_col := ws.spawn_unit(WorldState.FACTION_RED, p_m1a2, defile_center + off, WorldState.ECHELON_COMPANY)
		ws.unit_heading_rad[u_col] = 0.45
		ws.unit_detected_mask[u_col] = 1

	# C) Naval CSG Ring Screen around CVN-78 in deep ocean (90, 65)
	var csg_center := Vector3(90.0, 0.0, 65.0)
	var u_cvn := ws.spawn_unit(WorldState.FACTION_BLUE, p_cvn, csg_center, WorldState.ECHELON_COMPANY)
	ws.unit_heading_rad[u_cvn] = -0.8
	for i in range(1, 7):
		var off := TacticalDoctrineFormationSystemScript.compute_formation_offset(
			TacticalDoctrineFormationSystemScript.FormationType.CSG_RING, i, 7, -0.8, 1.0
		)
		var u_escort := ws.spawn_unit(WorldState.FACTION_BLUE, p_type055, csg_center + off, WorldState.ECHELON_COMPANY)
		ws.unit_heading_rad[u_escort] = -0.8
		ws.unit_parent_id[u_escort] = u_cvn

	# 2. Munitions with Tangent Dynamics:
	# Ballistic Missile in flight (Ascending phase: +55 deg pitch)
	var bal_asc := ws.spawn_munition(0, 1, 0, 1, Vector3(-80.0, 10.0, 80.0), Vector3(80.0, 10.0, -80.0), "LOFTED_BALLISTIC")
	ws.mun_flight_progress[bal_asc] = 0.15
	ws.mun_pos[bal_asc] = Vector3(-55.0, 28000.0, 55.0)
	ws.mun_pitch_rad[bal_asc] = deg_to_rad(52.0)
	ws.mun_heading_rad[bal_asc] = atan2(160.0, -160.0)

	# Ballistic Missile at Apogee (Flat: 0 deg pitch)
	var bal_apo := ws.spawn_munition(0, 1, 0, 1, Vector3(-90.0, 10.0, 70.0), Vector3(70.0, 10.0, -90.0), "LOFTED_BALLISTIC")
	ws.mun_flight_progress[bal_apo] = 0.50
	ws.mun_pos[bal_apo] = Vector3(-10.0, 65000.0, -10.0)
	ws.mun_pitch_rad[bal_apo] = deg_to_rad(0.0)
	ws.mun_heading_rad[bal_apo] = atan2(160.0, -160.0)

	# Ballistic Missile Reentry Cone (Terminal plunge: -65 deg pitch)
	var bal_plg := ws.spawn_munition(0, 1, 0, 1, Vector3(-100.0, 10.0, 60.0), Vector3(60.0, 10.0, -100.0), "LOFTED_BALLISTIC")
	ws.mun_flight_progress[bal_plg] = 0.92
	ws.mun_pos[bal_plg] = Vector3(45.0, 14000.0, -85.0)
	ws.mun_pitch_rad[bal_plg] = deg_to_rad(-65.0)
	ws.mun_heading_rad[bal_plg] = atan2(160.0, -160.0)

	# Hypersonic Waverider Glider (Cruise at 28km)
	var hgv_mid := ws.spawn_munition(0, 1, 0, 1, Vector3(-70.0, 10.0, -50.0), Vector3(70.0, 10.0, 50.0), "ORBITAL_KINETIC_ROD")
	ws.mun_class_id[hgv_mid] = 5 # Hypersonic
	ws.mun_flight_progress[hgv_mid] = 0.45
	ws.mun_pos[hgv_mid] = Vector3(-5.0, 28000.0, -5.0)
	ws.mun_pitch_rad[hgv_mid] = deg_to_rad(-3.0)
	ws.mun_heading_rad[hgv_mid] = atan2(140.0, 100.0)

	# 155mm Artillery Salvo (Parabolic tangent dive over defile column)
	for s in range(5):
		var art_mid := ws.spawn_munition(0, 1, 0, 1, Vector3(-95.0, 20.0, 0.0), Vector3(-65.0, 25.0, 20.0), "LOFTED_BALLISTIC")
		ws.mun_class_id[art_mid] = 1 # Shell
		var prog := 0.65 + float(s) * 0.06
		ws.mun_flight_progress[art_mid] = prog
		var arc_y := 4200.0 * (1.0 - (prog - 0.5) * (prog - 0.5) * 4.0)
		ws.mun_pos[art_mid] = Vector3(lerpf(-95.0, -65.0, prog), arc_y, lerpf(0.0, 20.0, prog) + float(s - 2) * 1.5)
		ws.mun_pitch_rad[art_mid] = deg_to_rad(-38.0 - float(s) * 4.0)
		ws.mun_heading_rad[art_mid] = atan2(30.0, 20.0)

	# 3. Special Weapons Hazards (CBRN & Electromagnetic)
	ws.spawn_chemical_hazard(Vector3(25.0, 0.0, -25.0), 16.0, 180.0, 0)
	ws.spawn_biological_hazard(Vector3(-15.0, 0.0, 45.0), 14.0, 240.0, 0)
	ws.spawn_electromagnetic_hazard(Vector3(30.0, 35.0, -20.0), 28.0, 60.0, 0)

	# Publish snapshot to ensure visual controller has all newly spawned units and munitions
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

	# Recursively search and hide ALL CanvasLayers in the tree
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

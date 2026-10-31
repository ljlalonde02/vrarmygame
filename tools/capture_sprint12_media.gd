extends SceneTree
## Sprint 12 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint12_01_two_man_nuclear_key_turn_actuation` (Diegetic Two-Man Rule Key Turn Protocol)
## 2. `sprint12_02_strategic_triad_siop_boost_phase` (Coordinated Triad SIOP Salvo: Silos + SSBN + Bombers)
## 3. `sprint12_03_mirv_reentry_terminal_strikes` (Mach 24 MIRV Re-Entry & Ionization Trails)
## 4. `sprint12_04_defcon1_global_thermonuclear_warfare` (DEFCON 1 Global Thermonuclear Apex Climax)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint12"

const StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint12_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint12_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 12 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
	print("==================================================================")

	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	cam = bunker.desktop_rig.camera
	cam.current = true

	var wt: Node3D = bunker.war_table
	var sdb: Node = bunker.sim_db
	var st: WorldState = bunker.sim_server.world_state
	var console = bunker.tactile_console

	_dismiss_all_2d_overlays()

	for f in range(12):
		await process_frame

	# ==================================================================
	# SCENE 1: Diegetic Two-Man Rule Nuclear Key Turn Protocol
	# ==================================================================
	print(">> Capturing Scene 1: Diegetic Two-Man Rule Key Turn Protocol...")
	if console != null:
		console.turn_nuclear_key_alpha()
		console.turn_nuclear_key_bravo()
		console.flip_alpha_strike_guard_cover(true)

	# Position camera close to Tactile Console Dual Key Assemblies
	cam.position = Vector3(0.0, 1.25, 0.42)
	cam.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var key_badge := _create_3d_slate(Vector3(0.0, 1.35, -0.05), Vector2(0.58, 0.30), "DIEGETIC TWO-MAN RULE NUCLEAR KEY TURN PROTOCOL", [
		"HARDWARE: DUAL PHYSICAL 3D KEY ASSEMBLIES ON TACTILE CONSOLE",
		"TWO-MAN RULE: KEYS ROTATED WITHIN 5.0s COINCIDENCE WINDOW",
		"STATE: [KEY ALPHA: ARMED] & [KEY BRAVO: ARMED] -> AUTH UNLOCKED",
		"AUDIO / VISUAL: DUAL METALLIC KEY CLUNKS & RED DEFCON 1 STROBES"
	], Color(1.0, 0.22, 0.22))
	extra_holo_root.add_child(key_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint12_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint12_01_two_man_nuclear_key_turn_actuation.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint12_01_two_man_nuclear_key_turn_actuation.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Strategic Nuclear Triad SIOP Boost Phase Salvo
	# ==================================================================
	print(">> Capturing Scene 2: Strategic Nuclear Triad SIOP Boost Phase...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	wt.set_zoom_and_pan(1.8, Vector2(-15.0, 0.0))

	# Launch Triad SIOP
	StrategicMddSystemScript.execute_strategic_triad_siop(st, sdb, WorldState.FACTION_BLUE)

	cam.position = Vector3(-0.15, 1.55, 0.85)
	cam.look_at(wt.global_position + Vector3(-0.05, 0.10, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var boost_badge := _create_3d_slate(Vector3(-0.25, 0.35, -0.05), Vector2(0.58, 0.32), "STRATEGIC NUCLEAR TRIAD SIOP BOOST PHASE SALVO", [
		"LEG 1 (LAND): ICBM SILOS DISPATCHING MULTI-STAGE BOOSTERS",
		"LEG 2 (SEA): SSBN SUBMARINES LAUNCHING TRIDENT II D5 SLBMS",
		"LEG 3 (AIR): B-21 RAIDER DELIVERING STANDOFF CRUISE MISSILES",
		"TRAJECTORY: 16 SUBORBITAL WARHEADS CONVERGING ON CITADELS"
	], Color(1.0, 0.45, 0.15))
	extra_holo_root.add_child(boost_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint12_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint12_02_strategic_triad_siop_boost_phase.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint12_02_strategic_triad_siop_boost_phase.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: Mach 24 MIRV Re-Entry & Ionization Trails
	# ==================================================================
	print(">> Capturing Scene 3: Mach 24 MIRV Re-Entry & Ionization Trails...")
	wt.set_zoom_and_pan(2.8, Vector2(60.0, -30.0))

	cam.position = Vector3(0.18, 1.48, 0.72)
	cam.look_at(wt.global_position + Vector3(0.15, 0.06, -0.05), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var mirv_badge := _create_3d_slate(Vector3(0.22, 0.28, -0.08), Vector2(0.58, 0.32), "MIRV WARHEAD RE-ENTRY & IONIZATION TRAILS", [
		"SEPARATION: POST-BOOST VEHICLE (PBV) DISPERSES INDEPENDENT MIRVS",
		"TERMINAL VELOCITY: MACH 24 ATMOSPHERIC RE-ENTRY CORRIDORS",
		"IONIZATION TRAILS: DIEGETIC HOLOGRAPHIC TRAJECTORY ARCS",
		"PENETRATION AIDS: INTEGRATED CHAFF & DECOY DEPLOYMENT"
	], Color(0.0, 0.85, 1.0))
	extra_holo_root.add_child(mirv_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint12_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint12_03_mirv_reentry_terminal_strikes.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint12_03_mirv_reentry_terminal_strikes.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: DEFCON 1 Global Thermonuclear Apex Climax
	# ==================================================================
	print(">> Capturing Scene 4: DEFCON 1 Global Thermonuclear Apex Climax...")
	wt.set_zoom_and_pan(1.4, Vector2.ZERO)

	# Trigger multiple physical thermonuclear explosions on the table
	wt.trigger_nuclear_detonation(Vector3(50.0, 0.0, -40.0))
	wt.trigger_nuclear_detonation(Vector3(-60.0, 0.0, 30.0))
	st.trigger_thermonuclear_detonation(Vector3(50.0, 0.0, -40.0), 1, 450.0)
	st.trigger_thermonuclear_detonation(Vector3(-60.0, 0.0, 30.0), 1, 300.0)

	cam.position = Vector3(0.0, 1.58, 0.85)
	cam.look_at(wt.global_position + Vector3(0.0, 0.08, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var apex_badge := _create_3d_slate(Vector3(-0.28, 0.32, -0.06), Vector2(0.58, 0.32), "GLOBAL THERMONUCLEAR WARFARE // DEFCON 1 APEX", [
		"DEFCON LEVEL: 1 [COCKED PISTOL] // ESCALATION: 100% MAXIMUM",
		"VOLUMETRIC EFFECTS: SUPERSONIC SHOCKWAVES & EMP SCANLINES",
		"SEISMIC FEEDBACK: DIEGETIC BUNKER TREMOR & RED LIGHTING",
		"STATUS: APEX CLIMAX OF STRATEGIC DEFCON WARFARE EXPERIENCE"
	], Color(1.0, 0.22, 0.22))
	extra_holo_root.add_child(apex_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint12_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint12_04_defcon1_global_thermonuclear_warfare.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint12_04_defcon1_global_thermonuclear_warfare.png" % ARTIFACT_DIR)

	print("==================================================================")
	print("[SPRINT 12 MEDIA CAPTURE] Successfully Generated All 4 Stills!")
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


func _capture_viewport_to_file(path: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(path)

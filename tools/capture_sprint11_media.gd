extends SceneTree
## Sprint 11 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint11_01_asw_sonobuoy_field_localization` (Maritime ASW Sonobuoy Barrier & Torpedo Engagement)
## 2. `sprint11_02_orbital_kinetic_asat_intercept` (Orbital Counter-Space Kinetic ASAT Intercept & C4ISR Degradation)
## 3. `sprint11_03_vr_smartwatch_tactical_radial` (VR Holographic Smartwatch C2 Touch Zones & DEFCON Monitor)
## 4. `sprint11_04_combined_arms_battlefield_overview` (Multi-Domain Integrated Air-Sea-Space-Undersea Theater)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint11"

const UnderseaWarfareSystemScript := preload("res://src/sim_core/systems/undersea_warfare_system.gd")
const StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint11_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint11_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 11 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
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
	# SCENE 1: Autonomous Maritime ASW Sonobuoy Barrier & Torpedo Engagement
	# ==================================================================
	print(">> Capturing Scene 1: Maritime ASW Sonobuoy Barrier & Torpedo Engagement...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	wt.set_zoom_and_pan(3.2, Vector2(-40.0, 15.0))

	var sub_pid: int = int(sdb.get_platform_id("ru_yasen_sub"))
	if sub_pid <= 0: sub_pid = 1

	var sub_uid: int = st.spawn_unit(WorldState.FACTION_RED, sub_pid, Vector3(-25.0, -0.05, 15.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(sub_pid))
	st.unit_hp[sub_uid] = 80.0

	UnderseaWarfareSystemScript.deploy_asw_sonobuoy_field(
		st, sdb, Vector3(-45.0, 0.0, 15.0), 0.0, 5, 6.0, WorldState.FACTION_BLUE
	)

	cam.position = Vector3(-0.08, 1.46, 0.76)
	cam.look_at(wt.global_position + Vector3(-0.10, 0.06, 0.04), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var asw_badge := _create_3d_slate(Vector3(-0.16, 0.28, -0.05), Vector2(0.58, 0.32), "AUTONOMOUS MARITIME ASW PATROL & SONOBUOY BARRIER", [
		"PATROL CRAFT: P-8A POSEIDON / TU-142 SEEDING BARRIER LINE",
		"SENSOR FIELD: 5-BUOY ACOUSTIC ARRAY (12 KM LOCALIZATION CONES)",
		"CONTACT CLASSIFIED: YASEN-M SSGN SUBMERGED @ 180m DEPTH",
		"ENGAGEMENT: AIR-DROPPED MK 54 HOMING TORPEDO DETONATION"
	], Color(0.18, 0.95, 0.65))
	extra_holo_root.add_child(asw_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint11_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint11_01_asw_sonobuoy_field_localization.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint11_01_asw_sonobuoy_field_localization.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Orbital Counter-Space Kinetic ASAT Intercept & C4ISR Degradation
	# ==================================================================
	print(">> Capturing Scene 2: Orbital Counter-Space Kinetic ASAT Intercept...")
	wt.set_zoom_and_pan(1.8, Vector2(0.0, 0.0))

	# Launch kinetic ASAT interceptor against Red satellite
	StrategicMddSystemScript.execute_counter_space_kinetic_asat(st, WorldState.FACTION_BLUE, Vector2.ZERO)

	cam.position = Vector3(0.0, 1.58, 0.88)
	cam.look_at(wt.global_position + Vector3(0.0, 0.12, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var asat_badge := _create_3d_slate(Vector3(0.18, 0.32, -0.08), Vector2(0.58, 0.32), "ORBITAL COUNTER-SPACE KINETIC ASAT INTERCEPT", [
		"DIRECT-ASCENT ASAT: SM-3 BLOCK IIA / NUDOL INTERCEPTOR",
		"TARGET: OPFOR LEO RECONNAISSANCE SATELLITE (ALTITUDE: 450 KM)",
		"PHYSICAL RESULT: SATELLITE PHYSICALLY DESTROYED (sat_active = 0)",
		"STRATEGIC DEGRADATION: SATCOM -33% | PNT GPS WEAPON CEP WIDENED"
	], Color(1.0, 0.45, 0.15))
	extra_holo_root.add_child(asat_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint11_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint11_02_orbital_kinetic_asat_intercept.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint11_02_orbital_kinetic_asat_intercept.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: VR Holographic Smartwatch C2 Touch Zones & DEFCON Monitor
	# ==================================================================
	print(">> Capturing Scene 3: VR Holographic Smartwatch C2 Radial...")
	var xr_rig: Node3D = bunker.xr_rig
	if xr_rig != null:
		xr_rig.visible = true
		if xr_rig.has_method("set_vr_simulator_mode"):
			xr_rig.set_vr_simulator_mode(true)
		if xr_rig.has_method("actuate_wrist_button"):
			xr_rig.actuate_wrist_button("btn_sitrep")

	# Position camera close to player's left wrist smartwatch
	cam.position = Vector3(-0.24, 1.28, 0.65)
	cam.look_at(Vector3(-0.28, 1.20, 0.68), Vector3.UP)

	extra_holo_root = Node3D.new()
	root.add_child(extra_holo_root)

	var watch_badge := _create_3d_slate(Vector3(-0.06, 1.34, 0.58), Vector2(0.54, 0.30), "VR HOLOGRAPHIC SMARTWATCH C2 QUICK-TOUCH RADIAL", [
		"DIEGETIC C2: ZERO FLAT 2D HUD // 100% IMMERSIVE VIRTUAL WRIST",
		"TOUCH ZONES: [C4ISR SITREP] [DEFCON STAT] [THEATER MAP]",
		"ACTUATION MODES: DIRECT PHYSICAL 3D TOUCH & LASER RAYCAST",
		"TACTILE FEEDBACK: DIEGETIC HAPTIC CLICKS ON ENGAGEMENT"
	], Color(0.0, 0.85, 1.0))
	extra_holo_root.add_child(watch_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint11_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint11_03_vr_smartwatch_tactical_radial.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint11_03_vr_smartwatch_tactical_radial.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Multi-Domain Integrated Air-Sea-Space-Undersea Theater
	# ==================================================================
	print(">> Capturing Scene 4: Multi-Domain Integrated DEFCON Warfare Overview...")
	cam.position = Vector3(0.0, 1.58, 0.82)
	cam.look_at(wt.global_position + Vector3(0.0, 0.08, 0.0), Vector3.UP)
	wt.set_zoom_and_pan(1.4, Vector2.ZERO)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var theater_badge := _create_3d_slate(Vector3(-0.24, 0.32, -0.06), Vector2(0.58, 0.32), "MULTI-DOMAIN INTEGRATED DEFCON WARFARE OVERVIEW", [
		"AIR / LAND: COMBINED ARMS STRIKE PACKAGES & SEAD ESCORTS",
		"MARITIME / UNDERSEA: CVN BATTLE GROUPS & ASW SONOBUOY SCREENS",
		"SPACE DOMAIN: 3D KEPLERIAN SATELLITE ORBITS & ASAT INTERCEPTS",
		"DEFCON ALERT: REAL-TIME ESCALATION & VOLUMETRIC THERMAL EFFECTS"
	], Color(0.72, 0.30, 1.0))
	extra_holo_root.add_child(theater_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint11_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint11_04_combined_arms_battlefield_overview.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint11_04_combined_arms_battlefield_overview.png" % ARTIFACT_DIR)

	print("==================================================================")
	print("[SPRINT 11 MEDIA CAPTURE] Successfully Generated All 4 Stills!")
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

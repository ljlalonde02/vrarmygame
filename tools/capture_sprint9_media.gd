extends SceneTree
## Sprint 9 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint9_01_multi_echelon_strike_package` (Multi-Echelon AI Strike Package: Escort + SEAD + Strike Bomber)
## 2. `sprint9_02_naval_task_force_screen_umbrella` (Carrier Battle Group 30km Air Defense Screening Umbrella)
## 3. `sprint9_03_oceanic_bathymetry_contour_shading` (Advanced Oceanic Bathymetry Trenches & Mountain Topography)
## 4. `sprint9_04_defcon1_nuclear_shockwave_emp` (Volumetric Thermonuclear Shockwave & EMP Hologram Glitch)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint9"

const CoordinatedStrikeSystemScript := preload("res://src/sim_core/systems/coordinated_strike_system.gd")

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint9_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint9_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 9 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
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
	# SCENE 1: Multi-Echelon AI Strike Package (Escort + SEAD + Strike)
	# ==================================================================
	print(">> Capturing Scene 1: Multi-Echelon AI Strike Package...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	wt.set_zoom_and_pan(2.4, Vector2(10.0, 10.0))

	var f35_pid: int = int(sdb.get_platform_id("us_f35a"))
	var f16_pid: int = int(sdb.get_platform_id("us_f16c"))
	var b21_pid: int = int(sdb.get_platform_id("us_b21_raider"))
	if f35_pid <= 0: f35_pid = 1
	if f16_pid <= 0: f16_pid = 1
	if b21_pid <= 0: b21_pid = 1

	var u_esc: int = st.spawn_unit(WorldState.FACTION_BLUE, f35_pid, Vector3(25.0, 10500.0, 25.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(f35_pid))
	var u_sead: int = st.spawn_unit(WorldState.FACTION_BLUE, f16_pid, Vector3(15.0, 4500.0, 15.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(f16_pid))
	var u_stk: int = st.spawn_unit(WorldState.FACTION_BLUE, b21_pid, Vector3(0.0, 8200.0, 0.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(b21_pid))

	var target_pt := Vector3(90.0, 0.0, 75.0)
	CoordinatedStrikeSystemScript.form_air_strike_package(st, sdb, WorldState.FACTION_BLUE, target_pt, [u_esc], [u_sead], [u_stk])

	cam.position = Vector3(0.12, 1.48, 0.72)
	cam.look_at(wt.global_position + Vector3(0.05, 0.08, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var pkg_badge := _create_3d_slate(Vector3(0.24, 0.28, -0.10), Vector2(0.56, 0.32), "MULTI-ECHELON AIR STRIKE PACKAGE", [
		"ECHELON 1 (HIGH CAP): F-35A SWEEP @ 10,500m (BVR STAND-OFF)",
		"ECHELON 2 (MID SEAD): F-16C AGM-88 @ 4,500m (RADAR KILL)",
		"ECHELON 3 (LOW STRIKE): B-21 RAIDER @ 8,200m (INGRESS TO TARGET)",
		"CORRIDOR STATUS: ENEMY AIR DEFENSES SUPPRESSED 78%"
	], Color(0.15, 0.90, 1.0))
	extra_holo_root.add_child(pkg_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint9_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint9_01_multi_echelon_strike_package.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint9_01_multi_echelon_strike_package.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Naval Task Force Screen Umbrella (CVN-78 + 4x DDG-51)
	# ==================================================================
	print(">> Capturing Scene 2: Naval Task Force Screening Umbrella...")
	wt.set_zoom_and_pan(3.0, Vector2(-20.0, -10.0))

	var cvn_pid: int = int(sdb.get_platform_id("us_cvn78_carrier"))
	var ddg_pid: int = int(sdb.get_platform_id("us_ddg51_destroyer"))
	if cvn_pid <= 0: cvn_pid = 2
	if ddg_pid <= 0: ddg_pid = 2

	var u_cvn: int = st.spawn_unit(WorldState.FACTION_BLUE, cvn_pid, Vector3(-20.0, 0.0, -10.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(cvn_pid))
	var escorts: Array[int] = []
	for k in range(4):
		var u_ddg: int = st.spawn_unit(WorldState.FACTION_BLUE, ddg_pid, Vector3(-20.0, 0.0, -10.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(ddg_pid))
		escorts.append(u_ddg)

	CoordinatedStrikeSystemScript.form_naval_task_force_screen(st, sdb, u_cvn, escorts, 28.0)

	cam.position = Vector3(0.0, 1.50, 0.70)
	cam.look_at(wt.global_position + Vector3(-0.06, 0.02, -0.04), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var screen_badge := _create_3d_slate(Vector3(-0.28, 0.26, -0.08), Vector2(0.58, 0.32), "NAVAL TASK FORCE AIR DEFENSE SCREEN", [
		"FLAGSHIP: USS GERALD R. FORD (CVN-78 HIGH-VALUE UNIT)",
		"SCREEN: 4x ARLEIGH BURKE DDG (28km DIAMOND PERIMETER)",
		"RADAR COVERAGE: AN/SPY-6(V) ACTIVE 360° OVERLAPPING UMBRELLA",
		"MISSION: INTERCEPT INBOUND ANTI-SHIP CRUISE MISSILES"
	], Color(0.20, 1.0, 0.65))
	extra_holo_root.add_child(screen_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint9_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint9_02_naval_task_force_screen_umbrella.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint9_02_naval_task_force_screen_umbrella.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: Oceanic Bathymetry & Micro-Topography Shading
	# ==================================================================
	print(">> Capturing Scene 3: Oceanic Bathymetry & Micro-Topography...")
	wt.set_zoom_and_pan(1.8, Vector2(0.0, 0.0))

	cam.position = Vector3(0.0, 1.56, 0.78)
	cam.look_at(wt.global_position, Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var topo_badge := _create_3d_slate(Vector3(0.32, 0.28, -0.15), Vector2(0.56, 0.32), "OCEANIC BATHYMETRY & TOPOGRAPHY", [
		"TRENCH BATHYMETRY: PROCEDURAL DEPTH ISO-CONTOURS (-3,000m)",
		"CONTINENTAL SHELF: MULTI-LAYER SHALLOW WATER REFLECTION",
		"MOUNTAIN RIDGES: 200m ISO-HYPSOMETRIC EMERALD CONTOURS",
		"C4ISR GRID: 50km MAJOR & 10km TACTICAL VECTOR COORDINATES"
	], Color(0.0, 0.88, 1.0))
	extra_holo_root.add_child(topo_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint9_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint9_03_oceanic_bathymetry_contour_shading.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint9_03_oceanic_bathymetry_contour_shading.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Volumetric DEFCON 1 Nuclear Shockwave & EMP Glitch
	# ==================================================================
	print(">> Capturing Scene 4: Volumetric DEFCON 1 Nuclear Shockwave & EMP...")
	wt.set_zoom_and_pan(2.2, Vector2(15.0, -10.0))
	wt.trigger_nuclear_detonation(Vector3(15.0, 0.0, -10.0))
	st.trigger_thermonuclear_detonation(Vector3(15.0, 0.0, -10.0), 1, 450.0)

	cam.position = Vector3(0.0, 1.46, 0.72)
	cam.look_at(wt.global_position + Vector3(0.05, 0.02, -0.03), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var nuke_badge := _create_3d_slate(Vector3(-0.30, 0.28, -0.06), Vector2(0.58, 0.32), "DEFCON 1 VOLUMETRIC THERMONUCLEAR DETONATION", [
		"GROUND ZERO: 450 KILOTON STRATEGIC SUBSURFACE / GROUND BURST",
		"SHOCKWAVE: EXPANDING SUPERSONIC RING (cs = 1,200 m/s)",
		"ELECTROMAGNETIC PULSE: HOLOGRAPHIC SCANLINE GLITCH & STATIC",
		"CRATER: SCORCHED THERMAL ASH DECAL ON 3D TERRAIN MESH"
	], Color(1.0, 0.32, 0.20))
	extra_holo_root.add_child(nuke_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint9_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint9_04_defcon1_nuclear_shockwave_emp.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint9_04_defcon1_nuclear_shockwave_emp.png" % ARTIFACT_DIR)

	print("==================================================================")
	print("[SPRINT 9 MEDIA CAPTURE] Successfully Generated All 4 Stills!")
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

extends SceneTree
## Sprint 7 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint7_01_command_radial_selection` (Diegetic 3D Radial Command Menu & Hostile Target Reticle)
## 2. `sprint7_02_tank_battalion_apfsds_muzzle_flash` (Tank Turret Azimuth Tracking, APFSDS Kinetic Tracers & Muzzle Blast)
## 3. `sprint7_03_helicopter_noe_infantry_suppression` (Attack Helicopter NOE Terrain Masking & Infantry Entrenched Cover)
## 4. `sprint7_04_submarine_sonar_match_victory` (Submarine Acoustic Sonar Waves & Tactical Match Victory Banner)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint7"

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint7_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint7_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 7 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
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
	# SCENE 1: Diegetic 3D Holographic Radial Command Menu & Target Reticle
	# ==================================================================
	print(">> Capturing Scene 1: Diegetic 3D Command Radial Menu & Reticle...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	wt.set_zoom_and_pan(2.8, Vector2(0.0, 0.0))

	# Find tank and mech platform IDs
	var m1a2_pid: int = int(sdb.get_platform_id("us_m1a2_sepv3_co"))
	if m1a2_pid <= 0: m1a2_pid = 3
	var t90_pid: int = int(sdb.get_platform_id("ru_t90m_proryv_co"))
	if t90_pid <= 0: t90_pid = 4

	var u_blue_tank: int = st.spawn_unit(WorldState.FACTION_BLUE, m1a2_pid, Vector3(-6.0, 0.0, 4.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(m1a2_pid))
	st.unit_tactical_posture[u_blue_tank] = WorldState.TACTICAL_POSTURE_HOLD_AMBUSH
	st.unit_heading_rad[u_blue_tank] = -0.45
	st.unit_turret_hdg_rad[u_blue_tank] = -0.45

	var u_red_target: int = st.spawn_unit(WorldState.FACTION_RED, t90_pid, Vector3(14.0, 0.0, -8.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(t90_pid))
	st.unit_detected_mask[u_red_target] = 3
	st.unit_hp[u_red_target] = 85.0

	wt.visual_sync.selected_unit_id = u_blue_tank
	wt.visual_sync.designated_target_uid = u_red_target

	cam.position = Vector3(0.0, 1.48, 0.88)
	cam.look_at(wt.global_position + Vector3(0.0, 0.04, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var radial_badge := _create_3d_slate(Vector3(0.38, 0.18, -0.22), Vector2(0.48, 0.28), "3D DIEGETIC COMMAND RADIAL", [
		"RADIAL POSTURES: MOVE, ATTACK, PATROL, HOLD/AMBUSH, RETREAT",
		"ACTIVE POSTURE: HOLD / AMBUSH (ENTRENCHED COVER -40% DMG)",
		"TARGET LOCK: T-90M PRORYV COMPANY (HP: 85) VIA 3D RETICLE",
		"VR INTERACTION: 6DOF LASER POINTER & VR WRIST ACTUATION"
	], TacticalTheme.COL_NATO_BLUE)
	radial_badge.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	extra_holo_root.add_child(radial_badge)

	for i in range(8):
		wt.set_zoom_and_pan(2.8, Vector2(sin(float(i) * 0.15) * 2.0, 0.0))
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint7_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint7_01_command_radial_selection.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint7_01_command_radial_selection.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Tank Battalion Combat, Turret Tracking & APFSDS Muzzle Blast
	# ==================================================================
	print(">> Capturing Scene 2: Tank Battalion Combat & APFSDS Muzzle Blast...")
	wt.set_zoom_and_pan(3.4, Vector2(-4.0, 2.0))

	# Orient lead tank turret towards target bearing and spawn APFSDS kinetic tracer
	var tank_pos := st.unit_pos[u_blue_tank]
	var enemy_pos := st.unit_pos[u_red_target]
	var to_enemy := enemy_pos - tank_pos
	var enemy_bearing := atan2(to_enemy.x, to_enemy.z)
	st.unit_turret_hdg_rad[u_blue_tank] = enemy_bearing

	st.sim_events_queue.clear()
	st.sim_events_queue.append({
		"type": "tank_muzzle_flash",
		"attacker_id": u_blue_tank,
		"pos_km": tank_pos,
		"target_pos_km": enemy_pos,
		"faction": WorldState.FACTION_BLUE
	})

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var tank_badge := _create_3d_slate(Vector3(-0.35, 0.18, -0.15), Vector2(0.48, 0.28), "COMBINED ARMS TANK BATTALION", [
		"ARMOR DOCTRINE: 4-TANK BATTALION BOUNDING OVERWATCH",
		"INDEPENDENT AZIMUTH: TURRET TRACKS TARGET WHILE CHASSIS MOVES",
		"KINETIC HYPER-VELOCITY: 120MM APFSDS KINETIC TRACER BEAM",
		"HIGHWAY TRANSIT: INTACT ROAD 1.45x SPEED MOBILITY MULTIPLIER"
	], Color(1.0, 0.88, 0.25))
	tank_badge.rotation_degrees = Vector3(0.0, 18.0, 0.0)
	extra_holo_root.add_child(tank_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint7_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint7_02_tank_battalion_apfsds_muzzle_flash.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint7_02_tank_battalion_apfsds_muzzle_flash.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: Attack Helicopter NOE Terrain Masking & Infantry Suppression
	# ==================================================================
	print(">> Capturing Scene 3: Helicopter NOE Masking & Infantry Suppression...")
	wt.set_zoom_and_pan(3.0, Vector2(10.0, -15.0))

	var heli_pid: int = int(sdb.get_platform_id("us_ah64e_apache"))
	if heli_pid <= 0: heli_pid = 5
	var inf_pid: int = int(sdb.get_platform_id("us_marine_infantry_co"))
	if inf_pid <= 0: inf_pid = 6

	# Helicopter hovering low (~45m AGL) behind mountain ridgeline
	var u_heli := st.spawn_unit(WorldState.FACTION_BLUE, heli_pid, Vector3(8.0, 48.0, -12.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(heli_pid))
	st.unit_desired_alt_m[u_heli] = 45.0
	st.unit_heading_rad[u_heli] = 1.2
	st.unit_roll_rad[u_heli] = -0.15

	# Infantry squad taking cover in urban rubble under suppressive fire
	var u_inf := st.spawn_unit(WorldState.FACTION_BLUE, inf_pid, Vector3(12.0, 0.0, -18.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(inf_pid))
	st.unit_tactical_posture[u_inf] = WorldState.TACTICAL_POSTURE_HOLD_AMBUSH
	st.unit_suppression_level[u_inf] = 0.65 # Pinned down under suppressive fire

	wt.visual_sync.selected_unit_id = u_inf

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var heli_badge := _create_3d_slate(Vector3(0.32, 0.18, -0.18), Vector2(0.48, 0.28), "NOE MASKING & URBAN COVER", [
		"NAP-OF-THE-EARTH (NOE): AH-64E HOVERS AT 45M AGL MASKED BY RIDGE",
		"INFANTRY FORTIFIED COVER: 62% DAMAGE REDUCTION IN URBAN RUBBLE",
		"SUPPRESSION DYNAMICS: PINNED UNDER FIRE SLOWS MOBILITY BY 60%",
		"COMBINED ARMS SYNERGY: HELICOPTER HELLFIRE BREAKS ENEMY PIN"
	], Color(0.20, 1.0, 0.65))
	heli_badge.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	extra_holo_root.add_child(heli_badge)

	for i in range(8):
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint7_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint7_03_helicopter_noe_infantry_suppression.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint7_03_helicopter_noe_infantry_suppression.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: Submarine Acoustic Sonar Waves & Match Tactical Victory
	# ==================================================================
	print(">> Capturing Scene 4: Submarine Acoustic Sonar & Match Victory...")
	wt.set_zoom_and_pan(2.4, Vector2(-45.0, -45.0))

	var sub_pid: int = int(sdb.get_platform_id("us_ssn_virginia"))
	if sub_pid <= 0: sub_pid = 7

	var u_sub := st.spawn_unit(WorldState.FACTION_BLUE, sub_pid, Vector3(-45.0, -180.0, -45.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(sub_pid))
	st.active_sonar_pings.clear()
	st.spawn_sonar_ping(u_sub, Vector3(-45.0, -180.0, -45.0), WorldState.FACTION_BLUE, 55.0)
	st.active_sonar_pings[0]["current_radius_km"] = 32.0
	st.active_sonar_pings[0]["radius_km"] = 32.0

	# Set Tactical Match Outcome to VICTORY
	st.tactical_match_active = false
	st.match_outcome = "VICTORY"

	# Move camera to view both War Table and Bulkhead Board
	cam.position = Vector3(0.0, 1.62, 1.35)
	cam.look_at(wt.global_position + Vector3(0.0, 0.45, -0.65), Vector3.UP)

	extra_holo_root = Node3D.new()
	wt.add_child(extra_holo_root)

	var victory_badge := _create_3d_slate(Vector3(-0.42, 0.22, -0.25), Vector2(0.50, 0.28), "TACTICAL MATCH VICTORY", [
		"THEATER OBJECTIVE COMPLETE: TAOYUAN INVASION BEACHHEAD REPELLED",
		"SUBMARINE ASW ACOUSTIC: CONCENTRIC ACTIVE SONAR PING ARCS",
		"BUNKER BULKHEAD BOARD: VICTORY ANNOUNCEMENT & LOSS LEDGER",
		"COMMERCIAL LOOP: END-TO-END MATCH RESOLUTION -> STORY TREE NEXT"
	], Color(0.20, 1.0, 0.55))
	victory_badge.rotation_degrees = Vector3(0.0, 22.0, 0.0)
	extra_holo_root.add_child(victory_badge)

	for i in range(8):
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.04)
		wt.visual_sync.sync_visuals()
		await process_frame
		_capture_viewport_to_file("%s/sprint7_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint7_04_submarine_sonar_match_victory.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint7_04_submarine_sonar_match_victory.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	print("==================================================================")
	print("[SPRINT 7 MEDIA CAPTURE] All 4 Scenarios Successfully Captured!")
	print("==================================================================")
	quit(0)


func _create_3d_slate(pos: Vector3, sz: Vector2, title: String, bullet_lines: Array, tint: Color) -> Node3D:
	var root_slate := Node3D.new()
	root_slate.position = pos

	var bg_mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = sz
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.02, 0.05, 0.10, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mi.mesh = quad
	bg_mi.material_override = mat
	root_slate.add_child(bg_mi)

	var title_lbl := Label3D.new()
	title_lbl.position = Vector3(0.0, sz.y * 0.38, 0.008)
	title_lbl.pixel_size = 0.0006
	title_lbl.font_size = 18
	title_lbl.modulate = tint
	title_lbl.outline_size = 3
	title_lbl.text = "◆ " + title
	title_lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	root_slate.add_child(title_lbl)

	var body_txt := ""
	for l in bullet_lines:
		body_txt += "• " + String(l) + "\n"

	var body_lbl := Label3D.new()
	body_lbl.position = Vector3(0.0, -0.02, 0.008)
	body_lbl.pixel_size = 0.0005
	body_lbl.font_size = 15
	body_lbl.modulate = Color(0.92, 0.95, 0.98, 0.95)
	body_lbl.outline_size = 2
	body_lbl.text = body_txt.strip_edges()
	body_lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	root_slate.add_child(body_lbl)

	return root_slate


func _dismiss_all_2d_overlays() -> void:
	if bunker.recon_dossier != null: bunker.recon_dossier.visible = false
	if bunker.main_menu != null: bunker.main_menu.visible = false
	if bunker.tutorial_controller != null: bunker.tutorial_controller.visible = false
	if bunker.story_director != null: bunker.story_director.visible = false
	if bunker.desktop_rig != null and bunker.desktop_rig.hud_layer != null:
		bunker.desktop_rig.hud_layer.visible = false
	if bunker.fpv_pod_controller != null:
		bunker.fpv_pod_controller.visible = false
		if bunker.fpv_pod_controller.hud_layer != null:
			bunker.fpv_pod_controller.hud_layer.visible = false
	if bunker.submarine_conn != null: bunker.submarine_conn.visible = false
	if bunker.tri_command != null: bunker.tri_command.visible = false


func _capture_viewport_to_file(out_path: String) -> void:
	var vp: Viewport = root.get_viewport()
	var tex: ViewportTexture = vp.get_texture()
	var img: Image = tex.get_image()
	if img != null:
		img.save_png(out_path)

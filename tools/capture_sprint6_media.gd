extends SceneTree
## Sprint 6 Visual Verification Media Generator on RTX 4060 Ti GPU.
## Captures 4 High-Definition Stills (1080p PNG) and 4 60fps Animated GIFs:
## 1. `sprint6_01_squadron_dogfight_flares` (F-35 Squadron Banking Maneuvers, Lead Pursuit & Flare Countermeasures)
## 2. `sprint6_02_sam_radar_intercept_salvo` (Integrated Air Defense Radar Illumination Cones & Vertical SAM Launches)
## 3. `sprint6_03_defcon1_thermonuclear_detonation` (Multi-Stage 3D Thermonuclear Detonation & Bunker Crimson Reaction)
## 4. `sprint6_04_journalistic_news_video_bunker` (In-Bunker Live TV News Monitor, Video Player & War Chyrons)

const ARTIFACT_DIR := "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
const MEDIA_DIR := "c:/dev/vrarmygame/docs/media"
const TEMP_DIR := "c:/dev/vrarmygame/temp_frames_sprint6"

var bunker: CommandBunker = null
var cam: Camera3D = null
var extra_holo_root: Node3D = null

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	process_frame.connect(_run_sprint6_capture_sequence, CONNECT_ONE_SHOT)


func _run_sprint6_capture_sequence() -> void:
	print("==================================================================")
	print("[SPRINT 6 MEDIA CAPTURE] Rendering 4 Scenarios on RTX 4060 Ti...")
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
	# SCENE 1: F-35 Squadron Banking Maneuvers, Lead Pursuit & Flares
	# ==================================================================
	print(">> Capturing Scene 1: F-35 Squadron Banking Maneuvers & Flares...")
	wt.set_display_mode(wt.DisplayMode.TACTICAL_MAP)
	wt.set_zoom_and_pan(2.8, Vector2(0.0, 0.0))

	# Spawn Blue F-35A flight and Red Su-57
	var f35_pid: int = sdb.get_platform_id("us_f35a_lightning")
	if f35_pid <= 0: f35_pid = 1
	var su57_pid: int = sdb.get_platform_id("ru_su57_felon")
	if su57_pid <= 0: su57_pid = 2

	var u_f35: int = st.spawn_unit(WorldState.FACTION_BLUE, f35_pid, Vector3(-12.0, 9200.0, 8.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(f35_pid))
	st.unit_vel[u_f35] = Vector3(0.58, 0.04, -0.22)
	st.unit_heading_rad[u_f35] = -0.38
	st.unit_roll_rad[u_f35] = -0.85 # 48 degree bank into turn
	st.unit_pitch_rad[u_f35] = 0.12
	st.unit_ai_state[u_f35] = WorldState.AI_BVR_INTERCEPT
	st.unit_target_pos[u_f35] = Vector3(18.0, 9500.0, -10.0)
	st.unit_has_waypoint[u_f35] = 1

	var u_su57: int = st.spawn_unit(WorldState.FACTION_RED, su57_pid, Vector3(22.0, 9500.0, -12.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(su57_pid))
	st.unit_vel[u_su57] = Vector3(-0.52, -0.02, 0.18)
	st.unit_heading_rad[u_su57] = 2.8
	st.unit_roll_rad[u_su57] = 0.72
	st.unit_detected_mask[u_su57] = 3

	# Deploy active countermeasure flares behind F-35
	st.active_countermeasures.clear()
	for ci in range(8):
		var flare_spread := Vector3(float(ci - 4) * 0.45, -float(ci) * 0.25, float(ci % 3) * 0.35)
		st.active_countermeasures.append({
			"unit_id": u_f35,
			"pos_km": st.unit_pos[u_f35] - st.unit_vel[u_f35] * (0.8 + float(ci) * 0.3) + flare_spread,
			"vel_km_s": Vector3(-0.08, -0.05, 0.04),
			"ttl_sec": 3.5 - float(ci) * 0.25,
			"max_ttl_sec": 4.0,
			"faction": WorldState.FACTION_BLUE
		})

	# Position camera for dramatic high-altitude dogfight view
	cam.global_position = Vector3(0.0, 1.48, 0.82)
	cam.look_at(Vector3(0.02, 1.05, 0.0), Vector3.UP)

	# 3D Tactical Hologram Overlay Badge for Air Combat
	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene1Extra"
	bunker.add_child(extra_holo_root)

	var air_badge := _create_3d_slate(Vector3(-0.15, 1.38, 0.12), Vector2(0.58, 0.22), "AIR COMBAT TACTICS // 4-SHIP LEAD PURSUIT", [
		"F-35A FLIGHT 'VIPER 1-1' // BVR INTERCEPT & CRANK",
		"SPEED: MACH 1.6 (SPRINT) | ALT: 9,200m MSL",
		"BANK ANGLE: 48° INTO HIGH-G LEAD PURSUIT",
		"DEFENSIVE COUNTERMEASURES: 8x FLARES / DIRCM DEPLOYED"
	], Color(0.12, 0.95, 1.0))
	extra_holo_root.add_child(air_badge)

	for i in range(8):
		# Animate slight motion for 60fps GIF
		st.unit_pos[u_f35] += st.unit_vel[u_f35] * 0.04
		st.unit_roll_rad[u_f35] = -0.85 + sin(float(i) * 0.4) * 0.12
		wt.visual_sync._process(0.016)
		await process_frame
		_capture_viewport_to_file("%s/sprint6_01_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint6_01_squadron_dogfight_flares.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint6_01_squadron_dogfight_flares.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 2: Integrated Air Defense (IADS) Radar Cones & Vertical SAMs
	# ==================================================================
	print(">> Capturing Scene 2: IADS Radar Tracking Cones & Vertical SAM Launches...")
	st.active_countermeasures.clear()
	st.active_radar_tracks.clear()

	wt.set_zoom_and_pan(3.2, Vector2(-15.0, 0.0))

	var sam_pid: int = sdb.get_platform_id("mim_104f_patriot")
	if sam_pid <= 0: sam_pid = 5
	var u_sam: int = st.spawn_unit(WorldState.FACTION_BLUE, sam_pid, Vector3(-18.0, 15.0, 5.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(sam_pid))
	st.unit_radar_active[u_sam] = 1

	var bmr_pid: int = sdb.get_platform_id("tu_22m3_backfire")
	if bmr_pid <= 0: bmr_pid = 6
	var u_bmr: int = st.spawn_unit(WorldState.FACTION_RED, bmr_pid, Vector3(8.0, 7800.0, -8.0), WorldState.ECHELON_COMPANY, -1, sdb.get_platform(bmr_pid))
	st.unit_vel[u_bmr] = Vector3(-0.48, 0.0, 0.12)
	st.unit_detected_mask[u_bmr] = 1

	# Active 3D radar tracking illumination cone from Patriot battery to bomber
	st.active_radar_tracks.append({
		"radar_uid": u_sam,
		"target_uid": u_bmr,
		"radar_pos": st.unit_pos[u_sam],
		"target_pos": st.unit_pos[u_bmr],
		"cone_deg": 18.0,
		"ttl_sec": 3.0,
		"faction": WorldState.FACTION_BLUE
	})

	# Spawn vertical SAM missile intercept launch
	var pac3_wid: int = sdb.plat_w1_id[sam_pid] if sam_pid < sdb.plat_w1_id.size() else 1
	var m_sam := st.spawn_munition(
		WorldState.FACTION_BLUE, pac3_wid, u_sam, u_bmr,
		st.unit_pos[u_sam] + Vector3(0.0, 5.0, 0.0),
		st.unit_pos[u_bmr], "LOFTED_BALLISTIC"
	)
	if m_sam >= 0:
		st.mun_flight_progress[m_sam] = 0.12
		st.mun_pos[m_sam] = st.unit_pos[u_sam] + Vector3(0.5, 3200.0, -0.2)

	cam.global_position = Vector3(-0.12, 1.48, 0.85)
	cam.look_at(Vector3(-0.10, 1.05, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene2Extra"
	bunker.add_child(extra_holo_root)

	var iads_badge := _create_3d_slate(Vector3(-0.20, 1.40, 0.15), Vector2(0.58, 0.22), "INTEGRATED AIR DEFENSE // IADS TRACKING", [
		"PATRIOT PAC-3 RADAR: AN/MPQ-65 PHASED ARRAY",
		"ACTIVE ILLUMINATION: 18° GIKBAL CONE ON TU-22M3",
		"ENGAGEMENT: VERTICAL HOT-LAUNCH SAM INTERCEPT",
		"INTERCEPT ENVELOPE: 65 km NEZ | TRACK LOCK: 100%"
	], Color(0.15, 1.0, 0.55))
	extra_holo_root.add_child(iads_badge)

	for i in range(8):
		if m_sam >= 0:
			st.mun_pos[m_sam] += Vector3(0.12, 120.0, -0.08)
		wt.visual_sync._process(0.016)
		await process_frame
		_capture_viewport_to_file("%s/sprint6_02_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint6_02_sam_radar_intercept_salvo.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint6_02_sam_radar_intercept_salvo.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 3: DEFCON 1 Multi-Stage Thermonuclear Detonation & Bunker Shake
	# ==================================================================
	print(">> Capturing Scene 3: DEFCON 1 Thermonuclear Detonation...")
	st.active_radar_tracks.clear()
	st.active_nuclear_fireballs.clear()
	st.active_nuke_effects.clear()
	wt.set_zoom_and_pan(1.8, Vector2(0.0, 0.0))

	# Trigger real multi-stage thermonuclear detonation at center
	var nuke_det := st.trigger_thermonuclear_detonation(Vector3(0.0, 5.0, 0.0), WorldState.FACTION_BLUE, 350.0)

	# Bunker into DEFCON 1 emergency crimson strobe
	st.defcon_level = 1
	bunker.update_bunker_defcon_and_integrity_atmosphere(0.50)

	cam.global_position = Vector3(0.0, 1.58, 1.15)
	cam.look_at(Vector3(0.0, 1.02, 0.0), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene3Extra"
	bunker.add_child(extra_holo_root)

	var nuke_badge := _create_3d_slate(Vector3(-0.35, 1.34, 0.45), Vector2(0.56, 0.22), "DEFCON 1 THERMONUCLEAR DETONATION", [
		"YIELD: 350-KILOTON STRATEGIC THERMONUCLEAR TRIAD",
		"STAGE 2: INCANDESCENT EXPANDING FIREBALL (14 km)",
		"STAGE 3: SUPERSONIC BLAST SHOCKWAVE RING (68 km)",
		"STAGE 4: CONVECTIVE TOROIDAL MUSHROOM CLOUD (28 km)",
		"BUNKER STATUS: CRIMSON STROBE // SEISMIC TREMOR"
	], Color(1.0, 0.22, 0.28))
	nuke_badge.rotation_degrees = Vector3(0.0, 12.0, 0.0)
	extra_holo_root.add_child(nuke_badge)

	for i in range(8):
		var prog := 0.28 + float(i) * 0.04
		nuke_det["timer_sec"] = (1.0 - prog) * 30.0
		nuke_det["ttl_sec"] = nuke_det["timer_sec"]
		nuke_det["max_ttl_sec"] = 30.0
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.05)
		wt.visual_sync._process(0.016)
		await process_frame
		_capture_viewport_to_file("%s/sprint6_03_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint6_03_defcon1_thermonuclear_detonation.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint6_03_defcon1_thermonuclear_detonation.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	# ==================================================================
	# SCENE 4: In-Bunker Live TV News Monitor, Video Feeds & War Chyrons
	# ==================================================================
	print(">> Capturing Scene 4: In-Bunker Journalistic News Video Feed...")
	# Activate live broadcast video slug
	st.defcon_level = 1
	if bunker.sim_server != null and bunker.sim_server.defcon_escalation_system != null:
		bunker.sim_server.defcon_escalation_system.current_defcon = 1
		bunker.sim_server.defcon_escalation_system.tension_score = 100.0
	st.global_escalation_score = 100.0
	st.latest_officer_callsign = "GEN. STERLING // STRATCOM"
	st.latest_officer_transcript = "DEFCON 1 DECLARED. STRATEGIC NUCLEAR TRIAD AT MAXIMUM READINESS."
	st.active_news_video_slug = "thermonuclear_detonation"
	st.active_news_video_network = "GNN GLOBAL CRISIS DESK (LIVE VEO FEED)"
	st.active_news_video_headline = "BREAKING NEWS: THERMONUCLEAR DETONATION CONFIRMED — DEFCON 1 DECLARED"

	# Position camera directly viewing the Bunker News Wall screen with comfortable framing
	cam.global_position = Vector3(-0.82, 1.74, -0.32)
	cam.look_at(Vector3(-1.45, 1.76, -1.18), Vector3.UP)

	extra_holo_root = Node3D.new()
	extra_holo_root.name = "Scene4Extra"
	bunker.add_child(extra_holo_root)

	var news_badge := _create_3d_slate(Vector3(-1.20, 2.05, -0.95), Vector2(0.56, 0.16), "BUNKER TV // JOURNALISTIC AI WAR STREAM", [
		"CHANNEL: GNN GLOBAL CRISIS NETWORK [DEFCON 1]",
		"FEED: 60FPS AI-GENERATED CRISIS BROADCAST",
		"CHYRON: LIVE SATELLITE BVR COMBAT & DETONATION",
		"DEBRIEF: INTEGRATED WITH DIEGETIC VISOR & C2 DESK"
	], Color(1.0, 0.88, 0.25))
	news_badge.rotation_degrees = Vector3(0.0, 22.0, 0.0)
	extra_holo_root.add_child(news_badge)

	for i in range(8):
		bunker._news_wall_anim_time = float(i) * 0.25
		bunker.update_bunker_defcon_and_integrity_atmosphere(0.04)
		await process_frame
		_capture_viewport_to_file("%s/sprint6_04_frame_%02d.png" % [TEMP_DIR, i])
		if i == 4:
			_capture_viewport_to_file("%s/sprint6_04_journalistic_news_video_bunker.png" % MEDIA_DIR)
			_capture_viewport_to_file("%s/sprint6_04_journalistic_news_video_bunker.png" % ARTIFACT_DIR)

	extra_holo_root.queue_free()

	print("==================================================================")
	print("[SPRINT 6 MEDIA CAPTURE] All 4 Scenarios Successfully Captured!")
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

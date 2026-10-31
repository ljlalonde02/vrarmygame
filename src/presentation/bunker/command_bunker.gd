class_name CommandBunker
extends Node3D
## Master Scene Root (`res://src/presentation/bunker/command_bunker.tscn`).
## Assembles:
## - Dark Brutalist Underground Command Bunker Architecture & Volumetric Lighting (`#05080E`)
## - `SimServer` (10 Hz Data-Oriented Simulation Engine with 600+ hierarchical units)
## - `WarTable` (1.8m x 1.8m Holographic Sand Table + Shaders + MultiMesh Sync)
## - `TactileConsole` (Interactive 3D Bunker Hardware Switches & Alpha Strike Commit Button)
## - `ReconDossierPanel` (Real Wikipedia Photographs for Platforms & Munitions + FLIR Toggle)
## - `BunkerMainMenu` (Dynamic 3-Operation Campaign, 3 Scenarios, Sandbox Builder, Wikipedia Photo Armory & AAR)
## - `OpForCommander` & `TheaterDirector` (Utility AI + OPORD/FRAGO Storyteller)
## - `BunkerRadioSynth` (Procedural RWR & Military Radio Synthesizer)
## - Automatic Dual-Rig Switching (`XRCommandRig` for Meta Quest 3 / PCVR, `DesktopCommandRig` for Flatscreen PC)

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CommandBusScript := preload("res://src/autoloads/command_bus.gd")
const SignalBusScript := preload("res://src/autoloads/signal_bus.gd")
const SimServerScript := preload("res://src/sim_core/sim_server.gd")
const WarTableScene := preload("res://src/presentation/war_table/war_table.tscn")
const TactileConsoleScript := preload("res://src/presentation/bunker/hardware/tactile_console.gd")
const ReconDossierScript := preload("res://src/presentation/bunker/recon_dossier_panel.gd")
const BunkerMainMenuScript := preload("res://src/presentation/bunker/bunker_main_menu.gd")
const TutorialControllerScript := preload("res://src/presentation/bunker/tutorial_controller.gd")
const OpForCommanderScript := preload("res://src/ai/tactical/opfor_commander.gd")
const TheaterDirectorScript := preload("res://src/ai/storyteller/theater_director.gd")
const StoryProgressionDirectorScript := preload("res://src/ai/storyteller/story_progression_director.gd")
const FpvTargetingPodControllerScript := preload("res://src/presentation/bunker/fpv_targeting_pod_controller.gd")
const SubmarineConnControllerScript := preload("res://src/presentation/bunker/submarine_conn_controller.gd")
const TriCommandSystemScript := preload("res://src/presentation/bunker/tri_command_system.gd")
const SubordinateStaffAIScript := preload("res://src/ai/advisor/subordinate_staff_ai.gd")
const BunkerRadioSynthScript := preload("res://src/presentation/audio/bunker_radio_synth.gd")
const DesktopCommandRigScript := preload("res://src/presentation/rigs/desktop_command_rig.gd")
const XRCommandRigScript := preload("res://src/presentation/rigs/xr_command_rig.gd")

var sim_db: Node = null
var command_bus: Node = null
var signal_bus: Node = null

var sim_server: Node = null
var war_table: Node3D = null
var tactile_console: Node3D = null
var recon_dossier: CanvasLayer = null
var main_menu: CanvasLayer = null
var tutorial_controller: CanvasLayer = null
var opfor_commander: Node = null
var theater_director: Node = null
var story_director: CanvasLayer = null
var fpv_pod_controller: Node3D = null
var submarine_conn: Node3D = null
var tri_command: Node3D = null
var subordinate_staff: Node = null
var radio_synth: Node = null
var desktop_rig: Node3D = null
var xr_rig: XROrigin3D = null

var _env_ref: Environment = null
var _key_light: OmniLight3D = null
var _beacon_left_piv: Node3D = null
var _beacon_right_piv: Node3D = null
var _beacon_left_light: OmniLight3D = null
var _beacon_right_light: OmniLight3D = null
var _bulkhead_board_3d: Node3D = null
var _bulkhead_defcon_label_3d: Label3D = null
var _bulkhead_bunker_label_3d: Label3D = null
var _bulkhead_officer_label_3d: Label3D = null
var _news_wall_3d: Node3D = null
var _news_wall_screen_mat: StandardMaterial3D = null
var _news_wall_header_3d: Label3D = null
var _news_wall_chyron_3d: Label3D = null
var _news_wall_anim_time: float = 0.0
var _beacon_spin_angle: float = 0.0

var _initialized: bool = false


func _ready() -> void:
	initialize_bunker()


func initialize_bunker(p_sim_db: Node = null, p_cmd_bus: Node = null, p_sig_bus: Node = null) -> void:
	if _initialized:
		return
	_initialized = true

	# 1. Resolve Autoloads (or instantiate standalone instances when booted from a SceneTree test script)
	sim_db = p_sim_db if p_sim_db != null else (get_node_or_null("/root/SimDB") if is_inside_tree() else null)
	if sim_db == null:
		sim_db = SimDBScript.new()
		sim_db.name = "SimDBLocal"
		add_child(sim_db)
	sim_db.load_database()

	command_bus = p_cmd_bus if p_cmd_bus != null else (get_node_or_null("/root/CommandBus") if is_inside_tree() else null)
	if command_bus == null:
		command_bus = CommandBusScript.new()
		command_bus.name = "CommandBusLocal"
		add_child(command_bus)

	signal_bus = p_sig_bus if p_sig_bus != null else (get_node_or_null("/root/SignalBus") if is_inside_tree() else null)
	if signal_bus == null:
		signal_bus = SignalBusScript.new()
		signal_bus.name = "SignalBusLocal"
		add_child(signal_bus)

	# 2. Build Dark Obsidian Underground Bunker Room Environment & Lighting
	_build_bunker_architecture()

	# 3. Instantiate SimServer
	sim_server = SimServerScript.new()
	sim_server.name = "SimServer"
	sim_server.setup_references(sim_db, command_bus, signal_bus)
	add_child(sim_server)

	# 4. Instantiate Holographic War Table at table height (y = 0.85m)
	war_table = WarTableScene.instantiate()
	war_table.name = "WarTable"
	war_table.position = Vector3(0.0, 0.85, 0.0)
	add_child(war_table)
	if war_table.visual_sync == null:
		war_table._ready()
	if war_table.visual_sync.unit_tokens_mmi == null:
		war_table.visual_sync._ready()
	if war_table.strike_preview._immediate == null:
		war_table.strike_preview._ready()

	# 5. Instantiate Procedural Military Radio & Male/Female Officer Voice Synthesizer
	radio_synth = BunkerRadioSynthScript.new()
	radio_synth.name = "BunkerRadioSynth"
	add_child(radio_synth)
	if radio_synth._player == null:
		radio_synth._ready()
	radio_synth.bind_signal_bus(signal_bus)
	signal_bus.officer_radio_spoke.connect(func(_id: String, callsign: String, gender: String, transcript: String):
		if sim_server != null:
			sim_server.world_state.latest_officer_callsign = callsign
			sim_server.world_state.latest_officer_gender = gender
			sim_server.world_state.latest_officer_transcript = transcript
	)

	# 6. Instantiate Diegetic 3D Tactile Console along the front bezel of the War Table
	tactile_console = TactileConsoleScript.new()
	tactile_console.name = "TactileConsole"
	tactile_console.position = Vector3(0.0, 0.82, 0.98)
	add_child(tactile_console)
	if tactile_console._iads_lever_pivot == null:
		tactile_console._ready()
	tactile_console.setup(sim_server, command_bus, signal_bus, radio_synth)

	# 7. Instantiate AI Commanders (OpForCommander + TheaterDirector Storyteller)
	opfor_commander = OpForCommanderScript.new()
	opfor_commander.name = "OpForCommander"
	opfor_commander.setup(sim_server, command_bus)
	add_child(opfor_commander)

	theater_director = TheaterDirectorScript.new()
	theater_director.name = "TheaterDirector"
	theater_director.setup(sim_server, signal_bus)
	add_child(theater_director)

	subordinate_staff = SubordinateStaffAIScript.new()
	subordinate_staff.name = "SubordinateStaffAI"
	subordinate_staff.setup(sim_server, command_bus, signal_bus)
	add_child(subordinate_staff)

	# 8. Instantiate Wikipedia Real-Photo Recon Dossier Panel
	recon_dossier = ReconDossierScript.new()
	recon_dossier.name = "ReconDossierPanel"
	add_child(recon_dossier)
	if recon_dossier.root_panel == null:
		recon_dossier._ready()
	recon_dossier.setup(sim_db, sim_server, signal_bus, command_bus)

	# 9. Instantiate Interactive 5-Step Boot-Camp TutorialController & Bunker Main Menu
	tutorial_controller = TutorialControllerScript.new()
	tutorial_controller.name = "TutorialController"
	add_child(tutorial_controller)
	if tutorial_controller.banner_panel == null:
		tutorial_controller._ready()
	tutorial_controller.setup(sim_db, signal_bus, command_bus, war_table)

	main_menu = BunkerMainMenuScript.new()
	main_menu.name = "BunkerMainMenu"
	add_child(main_menu)
	if main_menu._modal_root == null:
		main_menu._ready()
	main_menu.setup(sim_db, sim_server, command_bus, signal_bus, war_table, recon_dossier, opfor_commander, tutorial_controller)

	# 9b. Instantiate 8-Mission Historical Story & Capabilities Progression Director (`StoryProgressionDirector`)
	story_director = StoryProgressionDirectorScript.new()
	story_director.name = "StoryProgressionDirector"
	add_child(story_director)
	if story_director.card_panel == null:
		story_director._ready()

	# 9c. Instantiate Phase 22 First-Person Cockpit / Drone / Satellite / Missile Live Feed Camera (`FpvTargetingPodController`)
	fpv_pod_controller = FpvTargetingPodControllerScript.new()
	fpv_pod_controller.name = "FpvTargetingPodController"
	add_child(fpv_pod_controller)
	if fpv_pod_controller.pod_camera == null:
		fpv_pod_controller._ready()
	fpv_pod_controller.setup_references(sim_server, war_table, signal_bus)

	# 9d. Instantiate Phase 35 688(I) Nuclear Attack Submarine VR & Desktop Conn Station (`SubmarineConnController`)
	submarine_conn = SubmarineConnControllerScript.new()
	submarine_conn.name = "SubmarineConnController"
	add_child(submarine_conn)
	if submarine_conn._ocean_viewport == null:
		submarine_conn._ready()
	submarine_conn.setup(sim_server, war_table, radio_synth)

	# FEAT-10: Instantiate TriCommandSystem (Deep Granite Bunker / Submarine Conn / E-4B Doomsday Plane)
	tri_command = TriCommandSystemScript.new()
	tri_command.name = "TriCommandSystem"
	add_child(tri_command)
	tri_command.setup(sim_server, war_table, submarine_conn, self)

	# 10. Instantiate Dual Rigs (XRCommandRig + DesktopCommandRig) with automatic OpenXR detection
	xr_rig = XRCommandRigScript.new()
	xr_rig.name = "XRCommandRig"
	add_child(xr_rig)
	if xr_rig.xr_camera == null:
		xr_rig._ready()

	desktop_rig = DesktopCommandRigScript.new()
	desktop_rig.name = "DesktopCommandRig"
	add_child(desktop_rig)
	if desktop_rig.camera == null:
		desktop_rig._ready()
	desktop_rig.setup(war_table, sim_server, command_bus, signal_bus, tactile_console, main_menu, theater_director, subordinate_staff, tutorial_controller)
	desktop_rig.xr_rig_ref = xr_rig
	desktop_rig.radio_synth_ref = radio_synth
	desktop_rig.story_director_ref = story_director
	desktop_rig.fpv_pod_ref = fpv_pod_controller
	desktop_rig.submarine_conn_ref = submarine_conn
	desktop_rig.tri_command_ref = tri_command
	story_director.setup(sim_db, sim_server, command_bus, signal_bus, war_table, tactile_console, radio_synth, desktop_rig)
	main_menu.story_director = story_director
	main_menu.fpv_pod_controller = fpv_pod_controller
	xr_rig.setup(war_table, sim_server, command_bus, signal_bus, tactile_console, desktop_rig, main_menu)
	xr_rig.tri_command_ref = tri_command
	tactile_console.war_table_ref = war_table
	tactile_console.desktop_rig_ref = desktop_rig
	tactile_console.main_menu_ref = main_menu
	# Zéro bouton physique dans la pièce: tout se commande via la montre/tablette virtuelle et les lasers
	tactile_console.visible = false

	if xr_rig.try_initialize_openxr():
		desktop_rig.camera.current = false
		if OS.has_feature("android"):
			desktop_rig.set_process(false)
			if desktop_rig.hud_layer != null:
				desktop_rig.hud_layer.visible = false
			if fpv_pod_controller != null:
				fpv_pod_controller.set_pod_active(false)
	else:
		desktop_rig.camera.current = true

	# 11. Boot initial flagship scenario ("Operation Pacific Shield 2028" — 688 active units)
	sim_server.load_scenario("op_pacific_shield_2028")
	war_table.bind_sim_server(sim_server)

	# Commencer dans le poste de commandement Sous-Marin SSBN (User requirement: "Sous-Marin SSBN")
	if submarine_conn != null:
		submarine_conn.set_sub_sim_active(true)

	# Select a friendly F-35A or Bradley unit by default so the Wikipedia Recon Dossier is live immediately
	for uid in range(sim_server.world_state.unit_count):
		if sim_server.world_state.unit_active[uid] == 1 and sim_server.world_state.unit_faction[uid] == WorldState.FACTION_BLUE and sim_server.world_state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			desktop_rig.select_unit(uid)
			break


func _build_bunker_architecture() -> void:
	# WorldEnvironment with Dark Obsidian Void (#05080E)
	var env_node := WorldEnvironment.new()
	env_node.name = "BunkerWorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = TacticalTheme.COL_BUNKER_VOID
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.06, 0.10, 0.16, 1.0)
	env.ambient_light_energy = 0.85
	env_node.environment = env
	_env_ref = env
	add_child(env_node)

	# Brutalist Underground Bunker Floor
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "BunkerFloor"
	var f_plane := PlaneMesh.new()
	f_plane.size = Vector2(9.0, 9.0)
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.02, 0.03, 0.05, 1.0)
	f_mat.roughness = 0.45
	f_mat.metallic = 0.4
	f_plane.material = f_mat
	floor_mi.mesh = f_plane
	add_child(floor_mi)

	# Overhead Tactical Spotlight above the War Table (reacts dynamically to DEFCON 5..1 & Bunker Integrity)
	var key_light := OmniLight3D.new()
	key_light.name = "WarTableOverheadLight"
	key_light.position = Vector3(0.0, 2.8, 0.0)
	key_light.light_color = Color(0.55, 0.88, 1.0)
	key_light.light_energy = 1.6
	key_light.omni_range = 6.0
	_key_light = key_light
	add_child(key_light)

	# Left & Right Rotating 3D Bunker DEFCON Alert Beacons
	_beacon_left_piv = Node3D.new()
	_beacon_left_piv.name = "BunkerAlertBeaconLeft3D"
	_beacon_left_piv.position = Vector3(-1.65, 2.35, -1.20)
	add_child(_beacon_left_piv)
	_beacon_left_light = OmniLight3D.new()
	_beacon_left_light.light_color = Color(1.0, 0.25, 0.18)
	_beacon_left_light.light_energy = 0.0
	_beacon_left_light.omni_range = 4.2
	_beacon_left_piv.add_child(_beacon_left_light)

	_beacon_right_piv = Node3D.new()
	_beacon_right_piv.name = "BunkerAlertBeaconRight3D"
	_beacon_right_piv.position = Vector3(1.65, 2.35, -1.20)
	add_child(_beacon_right_piv)
	_beacon_right_light = OmniLight3D.new()
	_beacon_right_light.light_color = Color(1.0, 0.25, 0.18)
	_beacon_right_light.light_energy = 0.0
	_beacon_right_light.omni_range = 4.2
	_beacon_right_piv.add_child(_beacon_right_light)

	# Forward Bulkhead 3D DEFCON, Bunker Base Integrity & Officer Comms Wall Board
	_bulkhead_board_3d = Node3D.new()
	_bulkhead_board_3d.name = "BunkerBulkheadStatusBoard3D"
	_bulkhead_board_3d.position = Vector3(0.0, 1.96, -1.35)
	add_child(_bulkhead_board_3d)

	var wall_panel := MeshInstance3D.new()
	var wp_box := BoxMesh.new()
	wp_box.size = Vector3(2.30, 0.50, 0.03)
	var wp_mat := StandardMaterial3D.new()
	wp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wp_mat.albedo_color = Color(0.02, 0.05, 0.09, 0.90)
	wp_box.material = wp_mat
	wall_panel.mesh = wp_box
	_bulkhead_board_3d.add_child(wall_panel)

	_bulkhead_defcon_label_3d = Label3D.new()
	_bulkhead_defcon_label_3d.name = "BulkheadDefconLabel3D"
	_bulkhead_defcon_label_3d.position = Vector3(0.0, 0.14, 0.02)
	_bulkhead_defcon_label_3d.pixel_size = 0.0011
	_bulkhead_defcon_label_3d.font_size = 32
	_bulkhead_defcon_label_3d.modulate = Color(0.0, 0.95, 1.0)
	_bulkhead_defcon_label_3d.text = "■ DEFCON 4 // STRATEGIC WATCH // BUDGET: $4500M"
	_bulkhead_board_3d.add_child(_bulkhead_defcon_label_3d)

	_bulkhead_bunker_label_3d = Label3D.new()
	_bulkhead_bunker_label_3d.name = "BulkheadBunkerLabel3D"
	_bulkhead_bunker_label_3d.position = Vector3(0.0, 0.0, 0.02)
	_bulkhead_bunker_label_3d.pixel_size = 0.00095
	_bulkhead_bunker_label_3d.font_size = 24
	_bulkhead_bunker_label_3d.modulate = Color(0.25, 1.0, 0.65)
	_bulkhead_bunker_label_3d.text = "HQ BUNKER: Hengshan Underground Command Center | INTEGRITY: 100% | STATUS: SECURE"
	_bulkhead_board_3d.add_child(_bulkhead_bunker_label_3d)

	_bulkhead_officer_label_3d = Label3D.new()
	_bulkhead_officer_label_3d.name = "BulkheadOfficerLabel3D"
	_bulkhead_officer_label_3d.position = Vector3(0.0, -0.14, 0.02)
	_bulkhead_officer_label_3d.pixel_size = 0.00085
	_bulkhead_officer_label_3d.font_size = 22
	_bulkhead_officer_label_3d.modulate = Color(1.0, 0.84, 0.28)
	_bulkhead_officer_label_3d.text = "[OFFICER COMMS] CAPT. ELENA ROSTOVA: All 7 global flashpoint sensors nominal."
	_bulkhead_board_3d.add_child(_bulkhead_officer_label_3d)

	# 3D Command Bunker Live TV Breaking News Video Wall Monitor (displays Google Veo 3.1 Fast War Videos in 3D space)
	_news_wall_3d = Node3D.new()
	_news_wall_3d.name = "BunkerNewsVideoWall3D"
	_news_wall_3d.position = Vector3(-1.45, 1.72, -1.18)
	_news_wall_3d.rotation_degrees = Vector3(0.0, 22.0, 0.0)
	add_child(_news_wall_3d)

	var bezel_mi := MeshInstance3D.new()
	var bezel_box := BoxMesh.new()
	bezel_box.size = Vector3(0.92, 0.56, 0.03)
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bezel_mat.albedo_color = Color(0.04, 0.07, 0.12, 0.96)
	bezel_box.material = bezel_mat
	bezel_mi.mesh = bezel_box
	_news_wall_3d.add_child(bezel_mi)

	var screen_mi := MeshInstance3D.new()
	screen_mi.name = "NewsWallScreenMesh3D"
	screen_mi.position = Vector3(0.0, 0.02, 0.018)
	var screen_quad := QuadMesh.new()
	screen_quad.size = Vector2(0.86, 0.46)
	_news_wall_screen_mat = StandardMaterial3D.new()
	_news_wall_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_news_wall_screen_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	screen_quad.material = _news_wall_screen_mat
	screen_mi.mesh = screen_quad
	_news_wall_3d.add_child(screen_mi)

	_news_wall_header_3d = Label3D.new()
	_news_wall_header_3d.name = "NewsWallHeaderLabel3D"
	_news_wall_header_3d.position = Vector3(0.0, 0.25, 0.022)
	_news_wall_header_3d.pixel_size = 0.00075
	_news_wall_header_3d.font_size = 22
	_news_wall_header_3d.modulate = Color(1.0, 0.22, 0.32)
	_news_wall_header_3d.text = "● LIVE TV // GNN GLOBAL WAR DESK (VEO 3.1 AI FEED)"
	_news_wall_3d.add_child(_news_wall_header_3d)

	_news_wall_chyron_3d = Label3D.new()
	_news_wall_chyron_3d.name = "NewsWallChyronLabel3D"
	_news_wall_chyron_3d.position = Vector3(0.0, -0.24, 0.022)
	_news_wall_chyron_3d.pixel_size = 0.00068
	_news_wall_chyron_3d.font_size = 20
	_news_wall_chyron_3d.modulate = Color(1.0, 0.92, 0.45)
	_news_wall_chyron_3d.text = "BREAKING: MASSIVE CRUISE & HYPERSONIC MISSILE SALVO LAUNCHED"
	_news_wall_3d.add_child(_news_wall_chyron_3d)


func _process(delta: float) -> void:
	update_bunker_defcon_and_integrity_atmosphere(delta)


func update_bunker_defcon_and_integrity_atmosphere(delta: float) -> void:
	if sim_server == null:
		return
	var st: WorldState = sim_server.world_state
	var dc: int = st.defcon_level
	_beacon_spin_angle = wrapf(_beacon_spin_angle + delta * (6.5 if dc <= 2 else 2.8), 0.0, TAU)
	var pulse := 0.5 + 0.5 * sin(_beacon_spin_angle)

	var target_key_col := Color(0.55, 0.88, 1.0)
	var target_amb_col := Color(0.06, 0.10, 0.16)
	var beacon_energy := 0.0

	if st.bunker_is_lost or dc == 1:
		target_key_col = Color(1.0, 0.16, 0.18)
		target_amb_col = Color(0.18, 0.02, 0.03)
		beacon_energy = 1.8 * pulse
	elif dc == 2 or st.bunker_status_code in ["BREACH_IN_PROGRESS", "UNDER_ATTACK"]:
		target_key_col = Color(1.0, 0.42, 0.14)
		target_amb_col = Color(0.14, 0.05, 0.02)
		beacon_energy = 1.2 * pulse
	elif dc == 3 or st.bunker_status_code == "PERIMETER_ALERT":
		target_key_col = Color(1.0, 0.78, 0.25)
		target_amb_col = Color(0.10, 0.08, 0.03)
		beacon_energy = 0.55 * pulse
	elif dc == 4:
		target_key_col = Color(0.38, 0.82, 1.0)
		target_amb_col = Color(0.05, 0.10, 0.16)
		beacon_energy = 0.0

	if _key_light != null:
		_key_light.light_color = _key_light.light_color.lerp(target_key_col, clampf(delta * 4.0, 0.0, 1.0))
		var tremor_jitter := (randf() - 0.5) * st.bunker_shock_tremor * 0.65
		_key_light.light_energy = clampf(1.55 + tremor_jitter, 0.4, 2.5)
	if _env_ref != null:
		_env_ref.ambient_light_color = _env_ref.ambient_light_color.lerp(target_amb_col, clampf(delta * 4.0, 0.0, 1.0))
	if _beacon_left_light != null and _beacon_right_light != null:
		_beacon_left_light.light_energy = beacon_energy
		_beacon_right_light.light_energy = beacon_energy
		_beacon_left_light.visible = beacon_energy > 0.01
		_beacon_right_light.visible = beacon_energy > 0.01
		_beacon_left_piv.rotation.y = _beacon_spin_angle
		_beacon_right_piv.rotation.y = -_beacon_spin_angle

	if _bulkhead_defcon_label_3d != null:
		var hl_tag: String = " [RED PHONE RINGING!]" if st.hotline_is_ringing else ""
		var d_txt := "■ DEFCON %d (ESC: %.0f%%) // WX: %s (SEA B%d | %02.0f:00Z) // BUDGET: $%.0fM // TECHS: %d/15%s" % [
			dc, st.global_escalation_score, st.weather_condition_code, st.sea_state_beaufort, st.solar_hour_utc,
			st.blue_budget_available_musd, st.blue_unlocked_techs.size(), hl_tag
		]
		if _bulkhead_defcon_label_3d.text != d_txt:
			_bulkhead_defcon_label_3d.text = d_txt
		_bulkhead_defcon_label_3d.modulate = target_key_col

	if _bulkhead_bunker_label_3d != null:
		var hp_pct := clampf((st.bunker_hp / maxf(1.0, st.bunker_max_hp)) * 100.0, 0.0, 100.0)
		var b_txt := "HQ BUNKER: %s (%.0f, %.0f km) | HULL: %.0f%% | CAPTURE: %.0f%% | STATUS: %s (RELOC: %d)" % [
			st.bunker_base_name, st.bunker_pos_km.x, st.bunker_pos_km.z,
			hp_pct, st.bunker_capture_progress, st.bunker_status_code, st.bunker_relocations_count
		]
		if _bulkhead_bunker_label_3d.text != b_txt:
			_bulkhead_bunker_label_3d.text = b_txt
		_bulkhead_bunker_label_3d.modulate = Color(1.0, 0.25, 0.25) if (st.bunker_is_lost or hp_pct < 50.0 or st.bunker_capture_progress > 20.0) else Color(0.25, 1.0, 0.65)

	if _bulkhead_officer_label_3d != null:
		var o_txt := "[%s] \"%s\"" % [
			st.latest_officer_callsign, st.latest_officer_transcript.substr(0, 96)
		]
		if _bulkhead_officer_label_3d.text != o_txt:
			_bulkhead_officer_label_3d.text = o_txt

	if _news_wall_screen_mat != null and sim_db != null and sim_db.has_method("get_news_video_frame_textures"):
		_news_wall_anim_time += delta
		var frames: Array = sim_db.get_news_video_frame_textures(st.active_news_video_slug)
		if not frames.is_empty():
			var f_idx := int(_news_wall_anim_time * 6.0) % frames.size()
			_news_wall_screen_mat.albedo_texture = frames[f_idx]
		if _news_wall_header_3d != null:
			var h_txt := "● LIVE // %s [DEFCON %d]" % [st.active_news_video_network, dc]
			if _news_wall_header_3d.text != h_txt:
				_news_wall_header_3d.text = h_txt
		if _news_wall_chyron_3d != null:
			var c_txt := st.active_news_video_headline.substr(0, 68)
			if _news_wall_chyron_3d.text != c_txt:
				_news_wall_chyron_3d.text = c_txt


func cleanup_bunker() -> void:
	if sim_server != null:
		sim_server.cleanup()

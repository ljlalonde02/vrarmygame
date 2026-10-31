class_name TriCommandSystem
extends Node3D
## FEAT-10: Tri-Command Headquarters (Sprint 2 / PI 02)
## Orchestrates 3 strategic National Command Authority (NCA) operational headquarters:
## - STATION_BUNKER (0): Deep Granite Underground Bunker (Raven Rock / Cheyenne Mountain) with Holotable.
## - STATION_SSBN (1): Submarine Conn (USS Columbia / Ohio-Class SSBN) with Periscope & Sonar Waterfall.
## - STATION_E4B (2): E-4B Nightwatch "Doomsday Plane" NAOC (National Airborne Operations Center) at 38,000 ft
##   with aerodynamic turbulence/cabin banking, and 8.0 km trailing wire VLF antenna status.
##
## Includes screen transition fade, active station switching, and smartwatch button binding.

signal station_changed(old_station: int, new_station: int, station_name: String)

enum Station {
	STATION_BUNKER = 0,
	STATION_SSBN = 1,
	STATION_E4B = 2,
}

const STATION_NAMES := {
	Station.STATION_BUNKER: "DEEP GRANITE BUNKER (RAVEN ROCK / CHEYENNE MTN)",
	Station.STATION_SSBN: "USS COLUMBIA SSBN SUBMARINE CONN",
	Station.STATION_E4B: "E-4B NIGHTWATCH DOOMSDAY PLANE (NAOC)",
}

const STATION_SHORT_NAMES := {
	Station.STATION_BUNKER: "BKR",
	Station.STATION_SSBN: "SSBN",
	Station.STATION_E4B: "E4B",
}

# External references
var sim_server: Node = null
var war_table: Node3D = null
var submarine_conn_ref: Node3D = null
var bunker_root: Node3D = null

# Active station state
var current_station: int = Station.STATION_BUNKER
var is_transitioning: bool = false
var transition_progress: float = 0.0

# E-4B NAOC Airborne Station parameters
var e4b_altitude_ft: float = 38000.0
var e4b_speed_mach: float = 0.84
var e4b_trailing_vlf_antenna_km: float = 8.0 # 8 km dual trailing wire antenna
var e4b_antenna_deployed: bool = true
var e4b_cabin_shake_intensity: float = 0.12
var e4b_bank_angle_rad: float = 0.0

# 3D visuals for E-4B Doomsday Plane Cabin
var _e4b_cabin_root: Node3D = null
var _e4b_status_label_3d: Label3D = null
var _e4b_telemetry_label_3d: Label3D = null
var _e4b_screen_mesh: MeshInstance3D = null

# 2D Screen Fade Overlay
var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_alpha: float = 0.0
var _pending_target_station: int = -1


func _ready() -> void:
	_build_e4b_airborne_cabin()
	_build_fade_overlay()
	_apply_station_visibility(current_station)


func setup(p_sim_server: Node, p_war_table: Node3D, p_submarine_conn: Node3D, p_bunker_root: Node3D = null) -> void:
	sim_server = p_sim_server
	war_table = p_war_table
	submarine_conn_ref = p_submarine_conn
	bunker_root = p_bunker_root
	if _e4b_cabin_root == null:
		_build_e4b_airborne_cabin()
	if _fade_layer == null:
		_build_fade_overlay()
	_apply_station_visibility(current_station)


func get_active_station() -> int:
	return current_station


func get_station_name(station: int = -1) -> String:
	var st := current_station if station == -1 else station
	return STATION_NAMES.get(st, "UNKNOWN HQ")


func get_station_short_name(station: int = -1) -> String:
	var st := current_station if station == -1 else station
	return STATION_SHORT_NAMES.get(st, "HQ")


## Cycles to the next headquarters station in sequence (Bunker -> SSBN -> E-4B -> Bunker)
func cycle_next_station() -> int:
	var next_st := (current_station + 1) % 3
	switch_station(next_st)
	return next_st


## Switches to the specified headquarters station with a smooth transition fade
func switch_station(target_station: int) -> void:
	if target_station == current_station or is_transitioning:
		return
	if target_station < 0 or target_station > 2:
		return

	_pending_target_station = target_station
	is_transitioning = true
	transition_progress = 0.0


func _process(delta: float) -> void:
	if is_transitioning:
		transition_progress += delta * 3.5
		if transition_progress < 1.0:
			_fade_alpha = transition_progress
		elif transition_progress < 2.0:
			if _pending_target_station >= 0:
				var old := current_station
				current_station = _pending_target_station
				_pending_target_station = -1
				_apply_station_visibility(current_station)
				station_changed.emit(old, current_station, get_station_name(current_station))
			_fade_alpha = 2.0 - transition_progress
		else:
			_fade_alpha = 0.0
			is_transitioning = false

		if _fade_rect != null:
			_fade_rect.color = Color(0.0, 0.0, 0.0, clampf(_fade_alpha, 0.0, 1.0))
			_fade_rect.visible = _fade_alpha > 0.01

	# If E-4B is active, update cabin banking & turbulence
	if current_station == Station.STATION_E4B:
		_step_e4b_airborne_dynamics(delta)


func _step_e4b_airborne_dynamics(delta: float) -> void:
	var t := float(Time.get_ticks_msec()) * 0.001
	e4b_bank_angle_rad = sin(t * 0.28) * 0.045
	var shake := sin(t * 8.5) * 0.003 * e4b_cabin_shake_intensity

	if _e4b_cabin_root != null:
		_e4b_cabin_root.rotation.z = e4b_bank_angle_rad
		_e4b_cabin_root.position.y = 1.65 + shake

	if _e4b_status_label_3d != null:
		var vlf_status := "VLF/ELF 8.0 KM TRAILING ANTENNA: DEPLOYED & NOMINAL" if e4b_antenna_deployed else "VLF ANTENNA: RETRACTED"
		_e4b_status_label_3d.text = (
			"■ E-4B NIGHTWATCH // NAOC AIRBORNE COMMAND POST // 1ST ACCS\n"
			+ "ALT: %d FT | MACH %.2f | HEADING: 285° | CABIN PRESS: 8,000 FT\n" % [int(e4b_altitude_ft), e4b_speed_mach]
			+ "%s\n" % vlf_status
			+ "SECURE MILSTAR / AEHF / VLF STRATCOM DATA-LINK ACTIVE"
		)


func _apply_station_visibility(st: int) -> void:
	# Bunker Holotable is primary room; always present or toggled
	if submarine_conn_ref != null and submarine_conn_ref.has_method("set_sub_sim_active"):
		submarine_conn_ref.call("set_sub_sim_active", st == Station.STATION_SSBN)

	if _e4b_cabin_root != null:
		_e4b_cabin_root.visible = (st == Station.STATION_E4B)


func _build_e4b_airborne_cabin() -> void:
	if _e4b_cabin_root != null:
		return
	_e4b_cabin_root = Node3D.new()
	_e4b_cabin_root.name = "E4BCabinRoot3D"
	_e4b_cabin_root.position = Vector3(0.0, 1.65, 0.0)
	add_child(_e4b_cabin_root)

	# E-4B Conference / Battle Staff Display Screen
	_e4b_screen_mesh = MeshInstance3D.new()
	_e4b_screen_mesh.name = "E4BBattleStaffScreen"
	var qm := QuadMesh.new()
	qm.size = Vector2(2.4, 1.1)
	_e4b_screen_mesh.mesh = qm
	_e4b_screen_mesh.position = Vector3(0.0, 0.45, -1.8)

	var scr_mat := StandardMaterial3D.new()
	scr_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scr_mat.albedo_color = Color(0.04, 0.08, 0.15, 0.95)
	_e4b_screen_mesh.material_override = scr_mat
	_e4b_cabin_root.add_child(_e4b_screen_mesh)

	# 3D Telemetry and Antenna Status Label
	_e4b_status_label_3d = Label3D.new()
	_e4b_status_label_3d.name = "E4BStatusLabel3D"
	_e4b_status_label_3d.position = Vector3(0.0, 0.45, -1.78)
	_e4b_status_label_3d.pixel_size = 0.0012
	_e4b_status_label_3d.font_size = 26
	_e4b_status_label_3d.modulate = Color(0.0, 0.9, 1.0)
	_e4b_status_label_3d.outline_modulate = Color(0.0, 0.2, 0.4)
	_e4b_cabin_root.add_child(_e4b_status_label_3d)

	_e4b_cabin_root.visible = false


func _build_fade_overlay() -> void:
	if _fade_layer != null:
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "HQTransitionFadeLayer"
	_fade_layer.layer = 99
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "HQTransitionFadeRect"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.visible = false
	_fade_layer.add_child(_fade_rect)

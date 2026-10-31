class_name RenderSnapshot
extends RefCounted
## Triple-Buffered Snapshot Holder (`prev_snap`, `curr_snap`, `write_snap`).
## Allows the 90 Hz VR/Desktop render thread to smoothly interpolate unit and missile transforms
## without locking the 10 Hz background simulation thread.

class SnapshotData extends RefCounted:
	var tick_id: int = 0
	var timestamp_sec: float = 0.0
	var unit_count: int = 0
	var unit_active: PackedByteArray = PackedByteArray()
	var unit_pos: PackedVector3Array = PackedVector3Array()
	var unit_vel: PackedVector3Array = PackedVector3Array()
	var unit_target_pos: PackedVector3Array = PackedVector3Array()
	var unit_has_waypoint: PackedByteArray = PackedByteArray()
	var unit_faction: PackedByteArray = PackedByteArray()
	var unit_platform_id: PackedInt32Array = PackedInt32Array()
	var unit_echelon: PackedByteArray = PackedByteArray()
	var unit_parent_id: PackedInt32Array = PackedInt32Array()
	var unit_radar_active: PackedByteArray = PackedByteArray()
	var unit_hp: PackedFloat32Array = PackedFloat32Array()
	var unit_max_hp: PackedFloat32Array = PackedFloat32Array()
	var unit_ammo_1: PackedInt32Array = PackedInt32Array()
	var unit_ammo_2: PackedInt32Array = PackedInt32Array()
	var unit_energy_cap: PackedFloat32Array = PackedFloat32Array()
	var unit_unmanned_bays: PackedInt32Array = PackedInt32Array()
	var unit_detected_mask: PackedByteArray = PackedByteArray()
	var unit_jammed: PackedByteArray = PackedByteArray()
	var unit_ai_state: PackedByteArray = PackedByteArray()
	var unit_threat_level: PackedFloat32Array = PackedFloat32Array()
	var unit_afterburner: PackedByteArray = PackedByteArray()
	var unit_desired_alt_m: PackedFloat32Array = PackedFloat32Array()
	var unit_fuel_km: PackedFloat32Array = PackedFloat32Array()
	var unit_heading_rad: PackedFloat32Array = PackedFloat32Array()
	var unit_pitch_rad: PackedFloat32Array = PackedFloat32Array()
	var unit_roll_rad: PackedFloat32Array = PackedFloat32Array()
	var unit_sim_lod: PackedByteArray = PackedByteArray()
	var unit_morale: PackedFloat32Array = PackedFloat32Array()
	var unit_cyber_timer: PackedFloat32Array = PackedFloat32Array()
	var unit_cbrn_mopp: PackedByteArray = PackedByteArray()
	var unit_delegated_ai: PackedByteArray = PackedByteArray()
	var unit_posture: PackedByteArray = PackedByteArray()
	var unit_turret_hdg_rad: PackedFloat32Array = PackedFloat32Array()
	var unit_suppression_level: PackedFloat32Array = PackedFloat32Array()
	var blue_c2_integrity: float = 1.0
	var red_c2_integrity: float = 1.0

	var sat_count: int = 0
	var sat_active: PackedByteArray = PackedByteArray()
	var sat_faction: PackedByteArray = PackedByteArray()
	var sat_role: PackedByteArray = PackedByteArray()
	var sat_pos_km: PackedVector3Array = PackedVector3Array()
	var sat_dazzled_timer: PackedFloat32Array = PackedFloat32Array()

	var train_count: int = 0
	var train_active: PackedByteArray = PackedByteArray()
	var train_faction: PackedByteArray = PackedByteArray()
	var train_pos_km: PackedVector3Array = PackedVector3Array()
	var train_heading_rad: PackedFloat32Array = PackedFloat32Array()
	var train_derailed: PackedByteArray = PackedByteArray()

	var destruction_level: PackedFloat32Array = PackedFloat32Array()
	var active_destroyed_cells_count: int = 0
	var bridges_destroyed_count: int = 0
	var trains_derailed_count: int = 0
	var airfields_captured_count: int = 0

	var mun_count: int = 0
	var mun_active: PackedByteArray = PackedByteArray()
	var mun_pos: PackedVector3Array = PackedVector3Array()
	var mun_start_pos: PackedVector3Array = PackedVector3Array()
	var mun_target_pos: PackedVector3Array = PackedVector3Array()
	var mun_faction: PackedByteArray = PackedByteArray()
	var mun_weapon_id: PackedInt32Array = PackedInt32Array()
	var mun_flight_progress: PackedFloat32Array = PackedFloat32Array()
	var mun_apex_alt_m: PackedFloat32Array = PackedFloat32Array()
	var mun_heading_rad: PackedFloat32Array = PackedFloat32Array()
	var mun_pitch_rad: PackedFloat32Array = PackedFloat32Array()
	var mun_class_id: PackedByteArray = PackedByteArray()

	var active_beams: Array[Dictionary] = []
	var recent_impacts: Array[Dictionary] = []
	var queued_strikes: Array[Dictionary] = []
	var active_cbrn_hazards: Array[Dictionary] = []
	var active_towed_decoys: Array[Dictionary] = []
	var active_chaff_clouds: Array[Dictionary] = []
	var active_gps_denial_zones: Array[Dictionary] = []
	var blue_lost_musd: float = 0.0
	var red_lost_musd: float = 0.0
	var lod_tier0_count: int = 0
	var lod_tier1_count: int = 0
	var lod_tier2_count: int = 0
	var total_theater_civilians: float = 0.0
	var total_displaced_civilians: float = 0.0
	var estimated_civilian_casualties: float = 0.0
	var active_hazard_cells_count: int = 0
	var blue_satcom_factor: float = 1.0
	var red_satcom_factor: float = 1.0
	var blue_pnt_factor: float = 1.0
	var red_pnt_factor: float = 1.0
	var asat_intercepts_count: int = 0
	var cyber_strikes_count: int = 0
	var psyop_broadcasts_count: int = 0

	func copy_from_world(state: WorldState) -> void:
		tick_id = state.tick_id
		timestamp_sec = state.sim_time_sec
		unit_count = state.unit_count
		unit_active = state.unit_active.duplicate()
		unit_pos = state.unit_pos.duplicate()
		unit_vel = state.unit_vel.duplicate()
		unit_target_pos = state.unit_target_pos.duplicate()
		unit_has_waypoint = state.unit_has_waypoint.duplicate()
		unit_faction = state.unit_faction.duplicate()
		unit_platform_id = state.unit_platform_id.duplicate()
		unit_echelon = state.unit_echelon.duplicate()
		unit_parent_id = state.unit_parent_id.duplicate()
		unit_radar_active = state.unit_radar_active.duplicate()
		unit_hp = state.unit_hp.duplicate()
		unit_max_hp = state.unit_max_hp.duplicate()
		unit_ammo_1 = state.unit_ammo_1.duplicate()
		unit_ammo_2 = state.unit_ammo_2.duplicate()
		unit_energy_cap = state.unit_energy_cap.duplicate()
		unit_unmanned_bays = state.unit_unmanned_bays.duplicate()
		unit_detected_mask = state.unit_detected_mask.duplicate()
		unit_jammed = state.unit_jammed.duplicate()
		unit_ai_state = state.unit_ai_state.duplicate()
		unit_threat_level = state.unit_threat_level.duplicate()
		unit_afterburner = state.unit_afterburner.duplicate()
		unit_desired_alt_m = state.unit_desired_alt_m.duplicate()
		unit_fuel_km = state.unit_fuel_km.duplicate()
		unit_heading_rad = state.unit_heading_rad.duplicate()
		unit_pitch_rad = state.unit_pitch_rad.duplicate()
		unit_roll_rad = state.unit_roll_rad.duplicate()
		unit_sim_lod = state.unit_sim_lod.duplicate()
		unit_morale = state.unit_morale.duplicate()
		unit_cyber_timer = state.unit_cyber_timer.duplicate()
		unit_cbrn_mopp = state.unit_cbrn_mopp.duplicate()
		unit_delegated_ai = state.unit_delegated_ai.duplicate()
		unit_posture = state.unit_posture.duplicate()
		unit_turret_hdg_rad = state.unit_turret_hdg_rad.duplicate()
		unit_suppression_level = state.unit_suppression_level.duplicate()
		blue_c2_integrity = state.blue_c2_integrity
		red_c2_integrity = state.red_c2_integrity

		sat_count = state.sat_count
		sat_active = state.sat_active.duplicate()
		sat_faction = state.sat_faction.duplicate()
		sat_role = state.sat_role.duplicate()
		sat_pos_km = state.sat_pos_km.duplicate()
		sat_dazzled_timer = state.sat_dazzled_timer.duplicate()

		train_count = state.train_count
		train_active = state.train_active.duplicate()
		train_faction = state.train_faction.duplicate()
		train_pos_km = state.train_pos_km.duplicate()
		train_heading_rad = state.train_heading_rad.duplicate()
		train_derailed = state.train_derailed.duplicate()

		destruction_level = state.destruction_level.duplicate()
		active_destroyed_cells_count = state.active_destroyed_cells_count
		bridges_destroyed_count = state.bridges_destroyed_count
		trains_derailed_count = state.trains_derailed_count
		airfields_captured_count = state.airfields_captured_count

		mun_count = state.mun_count
		mun_active = state.mun_active.duplicate()
		mun_pos = state.mun_pos.duplicate()
		mun_start_pos = state.mun_start_pos.duplicate()
		mun_target_pos = state.mun_target_pos.duplicate()
		mun_faction = state.mun_faction.duplicate()
		mun_weapon_id = state.mun_weapon_id.duplicate()
		mun_flight_progress = state.mun_flight_progress.duplicate()
		mun_apex_alt_m = state.mun_apex_alt_m.duplicate()
		mun_heading_rad = state.mun_heading_rad.duplicate()
		mun_pitch_rad = state.mun_pitch_rad.duplicate()
		mun_class_id = state.mun_class_id.duplicate()

		active_beams = state.active_beams.duplicate(true)
		recent_impacts = state.recent_impacts.duplicate(true)
		queued_strikes = state.queued_strikes.duplicate(true)
		active_cbrn_hazards = state.active_cbrn_hazards.duplicate(true)
		active_towed_decoys = state.active_towed_decoys.duplicate(true)
		active_chaff_clouds = state.active_chaff_clouds.duplicate(true)
		active_gps_denial_zones = state.active_gps_denial_zones.duplicate(true)
		blue_lost_musd = state.blue_lost_musd
		red_lost_musd = state.red_lost_musd
		lod_tier0_count = state.lod_tier0_count
		lod_tier1_count = state.lod_tier1_count
		lod_tier2_count = state.lod_tier2_count
		total_theater_civilians = state.total_theater_civilians
		total_displaced_civilians = state.total_displaced_civilians
		estimated_civilian_casualties = state.estimated_civilian_casualties
		active_hazard_cells_count = state.active_hazard_cells_count
		blue_satcom_factor = state.blue_satcom_factor
		red_satcom_factor = state.red_satcom_factor
		blue_pnt_factor = state.blue_pnt_factor
		red_pnt_factor = state.red_pnt_factor
		asat_intercepts_count = state.asat_intercepts_count
		cyber_strikes_count = state.cyber_strikes_count
		psyop_broadcasts_count = state.psyop_broadcasts_count


var _mutex: Mutex = Mutex.new()
var prev_snap: SnapshotData = SnapshotData.new()
var curr_snap: SnapshotData = SnapshotData.new()
var write_snap: SnapshotData = SnapshotData.new()
var last_commit_usec: int = 0


func publish_snapshot(state: WorldState) -> void:
	write_snap.copy_from_world(state)
	_mutex.lock()
	var old_prev := prev_snap
	prev_snap = curr_snap
	curr_snap = write_snap
	write_snap = old_prev
	last_commit_usec = Time.get_ticks_usec()
	_mutex.unlock()


func get_read_pair() -> Array[SnapshotData]:
	_mutex.lock()
	var pair: Array[SnapshotData] = [prev_snap, curr_snap]
	_mutex.unlock()
	return pair

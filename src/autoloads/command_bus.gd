extends Node
## CommandBus Autoload: Thread-safe deterministic command queue (`Mutex` protected)
## decoupling VR hands, Desktop mouse/keyboard, and Tactical AI from `WorldState`.
## Also records every applied command with `tick_id` for Tacview-style After-Action Replay.

const CMD_MOVE_WAYPOINTS := "CMD_MOVE_WAYPOINTS"
const CMD_SET_DOCTRINE := "CMD_SET_DOCTRINE"
const CMD_QUEUE_STRIKE := "CMD_QUEUE_STRIKE"
const CMD_COMMIT_ALPHA_STRIKE := "CMD_COMMIT_ALPHA_STRIKE"
const CMD_DEPLOY_UNMANNED_SUBUNIT := "CMD_DEPLOY_UNMANNED_SUBUNIT"
const CMD_SET_MASTER_IADS := "CMD_SET_MASTER_IADS"
const CMD_SET_TIME_SCALE := "CMD_SET_TIME_SCALE"
const CMD_SPAWN_SANDBOX_UNIT := "CMD_SPAWN_SANDBOX_UNIT"
const CMD_UNIT_ABILITY := "CMD_UNIT_ABILITY"
const CMD_SET_TACTICAL_POSTURE := "CMD_SET_TACTICAL_POSTURE"

var _mutex: Mutex = Mutex.new()
var _pending_commands: Array[Dictionary] = []
var _replay_log: Array[Dictionary] = []
var _next_package_id: int = 1


func push_command(cmd_type: String, payload: Dictionary) -> void:
	var cmd := payload.duplicate(true)
	cmd["type"] = cmd_type
	cmd["queued_msec"] = Time.get_ticks_msec()
	_mutex.lock()
	_pending_commands.append(cmd)
	_mutex.unlock()


func enqueue_move_waypoints(unit_ids: Array, waypoints_km: Array, speed_mode: String = "CRUISE") -> void:
	push_command(CMD_MOVE_WAYPOINTS, {
		"unit_ids": unit_ids,
		"waypoints_km": waypoints_km,
		"speed_mode": speed_mode,
	})


func enqueue_set_doctrine(unit_ids: Array, radar_active: int = -1, roe: int = -1) -> void:
	push_command(CMD_SET_DOCTRINE, {
		"unit_ids": unit_ids,
		"radar_active": radar_active,
		"roe": roe,
	})


func enqueue_strike(attacker_ids: Array, target_unit_id: int, target_pos_km: Vector3, weapon_slot: int = 1, salvo_per_unit: int = 2) -> int:
	_mutex.lock()
	var pkg_id := _next_package_id
	_next_package_id += 1
	_mutex.unlock()
	push_command(CMD_QUEUE_STRIKE, {
		"package_id": pkg_id,
		"attacker_ids": attacker_ids,
		"target_unit_id": target_unit_id,
		"target_pos_km": target_pos_km,
		"weapon_slot": weapon_slot,
		"salvo_per_unit": salvo_per_unit,
	})
	return pkg_id


func enqueue_commit_alpha_strike(faction: int = 1) -> void:
	push_command(CMD_COMMIT_ALPHA_STRIKE, {"faction": faction})


func enqueue_deploy_unmanned(parent_unit_ids: Array, deploy_offset_km: Vector3 = Vector3(1.5, 0.0, -1.5)) -> void:
	push_command(CMD_DEPLOY_UNMANNED_SUBUNIT, {
		"parent_unit_ids": parent_unit_ids,
		"deploy_offset_km": deploy_offset_km,
	})


func enqueue_set_master_iads(faction: int, radar_enabled: bool) -> void:
	push_command(CMD_SET_MASTER_IADS, {
		"faction": faction,
		"radar_enabled": radar_enabled,
	})


func enqueue_set_time_scale(time_scale: float) -> void:
	push_command(CMD_SET_TIME_SCALE, {"time_scale": time_scale})


func enqueue_spawn_sandbox_unit(faction: int, platform_slug: String, pos_km: Vector3) -> void:
	push_command(CMD_SPAWN_SANDBOX_UNIT, {
		"faction": faction,
		"platform_slug": platform_slug,
		"pos_km": pos_km,
	})


func enqueue_unit_ability(unit_ids: Array, ability_code: String, target_unit_id: int = -1, target_pos_km: Vector3 = Vector3.ZERO) -> void:
	push_command(CMD_UNIT_ABILITY, {
		"unit_ids": unit_ids,
		"ability_code": ability_code,
		"target_unit_id": target_unit_id,
		"target_pos_km": target_pos_km,
	})


func enqueue_set_tactical_posture(unit_ids: Array, posture: int) -> void:
	push_command(CMD_SET_TACTICAL_POSTURE, {
		"unit_ids": unit_ids,
		"posture": posture,
	})


## Called exclusively by `SimServer` at the start of each 10 Hz simulation tick.
func drain_commands(current_tick_id: int) -> Array[Dictionary]:
	_mutex.lock()
	var drained: Array[Dictionary] = []
	if _pending_commands.is_empty():
		_mutex.unlock()
		return drained
	drained.append_array(_pending_commands)
	_pending_commands.clear()
	for cmd in drained:
		var log_entry := cmd.duplicate(true)
		log_entry["tick_id"] = current_tick_id
		_replay_log.append(log_entry)
	_mutex.unlock()
	return drained


func get_replay_log() -> Array[Dictionary]:
	_mutex.lock()
	var copy: Array[Dictionary] = []
	copy.append_array(_replay_log)
	_mutex.unlock()
	return copy


func clear_all() -> void:
	_mutex.lock()
	_pending_commands.clear()
	_replay_log.clear()
	_next_package_id = 1
	_mutex.unlock()

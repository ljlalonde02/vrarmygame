class_name ReplayRecorder
extends RefCounted
## Phase 7 Tacview-Style Timeline Scrubber & Keyframe Ring Buffer.
## Captures `RenderSnapshot.SnapshotData` keyframes during live battle and allows
## scrubbing forward/backward along the timeline on the Holographic War Table.

const MAX_KEYFRAMES := 300

var keyframes: Array[RenderSnapshot.SnapshotData] = []
var record_interval_ticks: int = 5
var is_scrubbing_replay: bool = false
var active_keyframe_index: int = -1


func clear() -> void:
	keyframes.clear()
	is_scrubbing_replay = false
	active_keyframe_index = -1


func record_keyframe(state: WorldState, force: bool = false) -> void:
	if is_scrubbing_replay:
		return
	if not force and (state.tick_id % record_interval_ticks) != 0:
		return
	var snap := RenderSnapshot.SnapshotData.new()
	snap.copy_from_world(state)
	keyframes.append(snap)
	if keyframes.size() > MAX_KEYFRAMES:
		keyframes.remove_at(0)
	active_keyframe_index = keyframes.size() - 1


func get_keyframe_count() -> int:
	return keyframes.size()


func scrub_to_keyframe(index: int, snapshot_buffer: RenderSnapshot, state: WorldState = null) -> RenderSnapshot.SnapshotData:
	if keyframes.is_empty():
		return null
	var idx: int = clampi(index, 0, keyframes.size() - 1)
	active_keyframe_index = idx
	is_scrubbing_replay = true
	var kf: RenderSnapshot.SnapshotData = keyframes[idx]
	snapshot_buffer._mutex.lock()
	snapshot_buffer.prev_snap = kf
	snapshot_buffer.curr_snap = kf
	snapshot_buffer.last_commit_usec = Time.get_ticks_usec()
	snapshot_buffer._mutex.unlock()

	if state != null:
		state.unit_pos = kf.unit_pos.duplicate()
		state.unit_active = kf.unit_active.duplicate()
		state.mun_pos = kf.mun_pos.duplicate()
		state.mun_active = kf.mun_active.duplicate()
		state.blue_lost_musd = kf.blue_lost_musd
		state.red_lost_musd = kf.red_lost_musd
	return kf


func scrub_to_ratio(ratio: float, snapshot_buffer: RenderSnapshot, state: WorldState = null) -> RenderSnapshot.SnapshotData:
	if keyframes.is_empty():
		return null
	var idx: int = clampi(int(round(clampf(ratio, 0.0, 1.0) * float(keyframes.size() - 1))), 0, keyframes.size() - 1)
	return scrub_to_keyframe(idx, snapshot_buffer, state)


func exit_scrub_mode() -> void:
	is_scrubbing_replay = false

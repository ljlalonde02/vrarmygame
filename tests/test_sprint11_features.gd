extends SceneTree

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const UnderseaWarfareSystemScript := preload("res://src/sim_core/systems/undersea_warfare_system.gd")
const StrategicMddSystemScript := preload("res://src/sim_core/systems/strategic_mdd_system.gd")
const XRCommandRigScript := preload("res://src/presentation/rigs/xr_command_rig.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("==================================================")
	print("=== SPRINT 11 VERIFICATION TEST SUITE ===")
	print("==================================================")

	test_asw_sonobuoy_field_and_torpedo_drop()
	test_counter_space_kinetic_asat_intercept()
	test_smartwatch_wrist_c2_touch_actuation()

	print("==================================================")
	print("SPRINT 11 VERIFICATION RESULTS: %d/%d TESTS PASSED!" % [_pass_count, _pass_count + _fail_count])
	if _fail_count == 0:
		print("ALL SYSTEMS OPERATIONAL")
	else:
		print("WARNING: SOME TESTS FAILED")
	print("==================================================")
	quit(_fail_count)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("[PASS] %s" % test_name)
		_pass_count += 1
	else:
		print("[FAIL] %s" % test_name)
		_fail_count += 1


func test_asw_sonobuoy_field_and_torpedo_drop() -> void:
	var sdb := SimDBScript.new()
	sdb.load_database()

	var state := WorldStateScript.new()
	state.reset()

	# Find or use submarine platform
	var sub_pid := -1
	for pid in range(sdb.plat_domain_id.size()):
		if sdb.plat_domain_id[pid] == 2 or (sdb.plat_class_flags[pid] & sdb.FLAG_UUV_SUB) != 0:
			sub_pid = pid
			break
	if sub_pid <= 0:
		sub_pid = 1

	# Spawn hostile submarine along the patrol axis (at x=12.0, z=0.0)
	var sub_uid := state.spawn_unit(WorldStateScript.FACTION_RED, sub_pid, Vector3(12.0, -0.05, 0.0), WorldStateScript.ECHELON_COMPANY)
	state.unit_hp[sub_uid] = 100.0

	# Deploy 4-buoy ASW field along heading 0 rad (East) from origin
	var res: Dictionary = UnderseaWarfareSystemScript.deploy_asw_sonobuoy_field(
		state, sdb, Vector3.ZERO, 0.0, 4, 6.0, WorldStateScript.FACTION_BLUE
	)

	var ok: bool = (
		res.get("status") == "SONOBUOY_BARRIER_ACTIVE" and
		res.get("subs_localized", 0) >= 1 and
		res.get("torpedoes_dropped", 0) >= 1 and
		(state.unit_detected_mask[sub_uid] & 1) != 0 and
		state.unit_hp[sub_uid] < 100.0
	)
	_assert(ok, "TEST 1: Autonomous Maritime ASW Sonobuoy Barrier & Torpedo Engagement")


func test_counter_space_kinetic_asat_intercept() -> void:
	var state := WorldStateScript.new()
	state.reset()

	# Seed 3 RED SATCOM satellites and 3 RED PNT satellites
	state.sat_count = 6
	state.sat_active.resize(6)
	state.sat_faction.resize(6)
	state.sat_role.resize(6)
	state.sat_pos_km.resize(6)
	state.sat_dazzled_timer.resize(6)
	state.sat_phase_rad.resize(6)
	state.sat_angular_vel.resize(6)
	state.sat_inclination_rad.resize(6)
	state.sat_raan_rad.resize(6)
	state.sat_alt_km.resize(6)

	for i in range(6):
		state.sat_active[i] = 1
		state.sat_faction[i] = WorldStateScript.FACTION_RED
		state.sat_role[i] = WorldStateScript.SAT_ROLE_SATCOM_LEO if i < 3 else WorldStateScript.SAT_ROLE_PNT_GPS
		state.sat_pos_km[i] = Vector3(float(i * 20), 450.0, float(i * 10))
		state.sat_dazzled_timer[i] = 0.0
		state.sat_phase_rad[i] = 0.0
		state.sat_angular_vel[i] = 0.01
		state.sat_inclination_rad[i] = 0.8
		state.sat_raan_rad[i] = 0.5
		state.sat_alt_km[i] = 450.0

	# Initial factors should be 1.0 (3/3 operational)
	StrategicMddSystemScript._update_satellite_positions_and_factors(state, 0.0)
	var pre_satcom := state.red_satcom_factor

	# Launch direct-ascent kinetic ASAT interceptor from Blue
	var asat_res: Dictionary = StrategicMddSystemScript.execute_counter_space_kinetic_asat(
		state, WorldStateScript.FACTION_BLUE, Vector2.ZERO
	)

	var destroyed_id: int = asat_res.get("destroyed_sat_id", -1)
	var ok: bool = (
		asat_res.get("success", false) == true and
		destroyed_id >= 0 and
		state.sat_active[destroyed_id] == 0 and
		state.asat_intercepts_count >= 1 and
		(state.red_satcom_factor < pre_satcom or state.red_pnt_factor < 1.0)
	)
	_assert(ok, "TEST 2: Orbital Counter-Space Kinetic ASAT Intercept & PNT/SATCOM Degradation")


func test_smartwatch_wrist_c2_touch_actuation() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var rig := XRCommandRigScript.new()
	root.add_child(rig)
	rig._ready()

	# Verify buttons are present
	var has_sitrep: bool = rig._wrist_buttons.has("btn_sitrep")
	var has_defcon: bool = rig._wrist_buttons.has("btn_defcon")
	var has_theater: bool = rig._wrist_buttons.has("btn_theater")

	# Test direct actuation
	var res_sitrep: String = rig.actuate_wrist_button("btn_sitrep")
	var res_defcon: String = rig.actuate_wrist_button("btn_defcon")
	var res_theater: String = rig.actuate_wrist_button("btn_theater")

	# Test pick by touch proximity
	var defcon_btn: Dictionary = rig._wrist_buttons.get("btn_defcon", {})
	var tablet_trans: Transform3D = rig.get_wrist_tablet_transform()
	var btn_local := Vector3(float(defcon_btn.get("center_x", 0.02)), float(defcon_btn.get("center_y", -0.076)), 0.006)
	var finger_world := tablet_trans * btn_local
	var picked_by_touch: String = rig.pick_wrist_button_by_touch(finger_world, 0.02)

	var ok: bool = (
		has_sitrep and has_defcon and has_theater and
		res_sitrep == "C4ISR_SITREP_OK" and
		res_defcon == "DEFCON_STATUS_OK" and
		res_theater.begins_with("THEATER") and
		picked_by_touch == "btn_defcon"
	)
	_assert(ok, "TEST 3: VR Holographic Smartwatch C2 Radial & Proximity Touch Actuation")
	root.queue_free()

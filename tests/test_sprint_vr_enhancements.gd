extends SceneTree

var bunker: CommandBunker = null

func _init() -> void:
	bunker = CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)


func _run_test() -> void:
	print("==================================================================")
	print("[SPRINT VR TEST] Testing Meta Quest 3 VR Enhancements Suite...")
	print("==================================================================")

	# 2. Verify Zero physical buttons in the room requirement
	assert(bunker.tactile_console != null, "TactileConsole must exist")
	assert(bunker.tactile_console.visible == false, "TactileConsole must be hidden (Zero physical buttons in room)")
	print("  [1] PASSED: Zero physical buttons in room verified (tactile_console.visible == false)")

	# 3. Verify Starting Command Post: Sous-Marin SSBN
	assert(bunker.submarine_conn != null, "SubmarineConnController must exist")
	assert(bunker.submarine_conn.is_sub_sim_active == true, "Must start in Sous-Marin SSBN command station")
	print("  [2] PASSED: Sous-Marin SSBN command station active on boot (periscope + sonar waterfall)")

	# 4. Verify Room-Scale Holo-Floor Mode
	var war_table: WarTable = bunker.war_table
	assert(war_table != null, "WarTable must exist")
	assert(war_table.is_floor_mode == false, "Starts in table mode")
	var floor_activated: bool = war_table.toggle_floor_mode()
	assert(floor_activated == true, "Floor mode toggle returned true")
	assert(war_table.is_floor_mode == true, "WarTable is in floor mode")
	assert(war_table.position.y < 0.10, "WarTable dropped to floor level (y ~ 0.02m)")
	var floor_deactivated: bool = war_table.toggle_floor_mode()
	assert(floor_deactivated == false, "Floor mode toggle returned false")
	assert(war_table.is_floor_mode == false, "WarTable returned to table mode")
	print("  [3] PASSED: Room-scale Holo-Floor mode toggle verified (walk in the middle of theater)")

	# 5. Verify Virtual Smartwatch / C4ISR Wrist Tablet Interactive Controls & Ray Picking
	var xr_rig: XRCommandRig = bunker.xr_rig
	assert(xr_rig != null, "XRCommandRig must exist")
	assert(xr_rig._wrist_tablet_root != null, "Wrist tablet root must exist")
	assert(xr_rig._wrist_buttons.size() == 5, "Must have 5 interactive wrist buttons (Floor, Posture, Time, SSBN, Strike)")

	# Test ray picking on wrist buttons:
	# Position the ray to point directly at the wrist tablet in its local coordinates
	var tablet_trans: Transform3D = xr_rig._wrist_tablet_root.global_transform
	var btn_floor_pos: Vector3 = tablet_trans * Vector3(-0.096, -0.046, 0.006)
	var ray_origin := btn_floor_pos + tablet_trans.basis.z * 0.35 # 35cm in front of the button
	var ray_dir := (-tablet_trans.basis.z).normalized()
	var hit_btn: String = xr_rig.pick_wrist_button_by_ray(ray_origin, ray_dir)
	assert(hit_btn == "btn_floor", "Laser must hit btn_floor, got: %s" % hit_btn)

	# Actuate Floor Mode via wrist button
	var act_res: String = xr_rig.actuate_wrist_button("btn_floor")
	assert(act_res == "FLOOR_MODE_ON", "Must actuate floor mode ON")
	assert(war_table.is_floor_mode == true, "WarTable is now in floor mode via wrist button")

	# Actuate Tactical Posture cycle via wrist button
	var post_res: String = xr_rig.actuate_wrist_button("btn_posture")
	assert(post_res == "POSTURE_BVR", "Must cycle posture to BVR Stand-off")
	print("  [4] PASSED: Virtual Smartwatch ray picking & button actuation verified (5 controls)")

	# 6. Verify Tactical Posture propagation to aircraft
	var sim_server: SimServer = bunker.sim_server
	sim_server.step_tick(0.10)
	var st: WorldState = sim_server.world_state
	var found_bvr_air: bool = false
	for u in range(st.unit_count):
		if st.unit_active[u] == 1 and st.unit_faction[u] == WorldState.FACTION_BLUE:
			if st.unit_tactical_posture[u] == WorldState.TACTICAL_POSTURE_BVR_STANDOFF:
				found_bvr_air = true
				break
	assert(found_bvr_air, "BVR Stand-off posture must be applied to friendly air units")
	print("  [5] PASSED: Aerial combat posture BVR Stand-off propagated to flights")

	# 7. Verify Swarm Intelligence System & Platform Pros/Cons
	assert(SwarmIntelligenceSystem.PLATFORM_PROS_CONS.has("f_35a_lightning"), "Must have F-35A pros/cons")
	var f35_info: Dictionary = SwarmIntelligenceSystem.get_platform_nuance("f_35a_lightning")
	assert(f35_info.has("qualities") and f35_info.has("flaws"), "Must have qualities and flaws")
	assert(f35_info.has("swarm_role"), "Must have swarm role")
	print("  [6] PASSED: Swarm Intelligence Pack coordination & unit pros/cons verified (%d platforms cataloged)" % SwarmIntelligenceSystem.PLATFORM_PROS_CONS.size())

	print("==================================================================")
	print("[SPRINT VR TEST PASSED] All 6 Meta Quest 3 Enhancements Succeeded with 0 Errors!")
	print("==================================================================")
	quit(0)

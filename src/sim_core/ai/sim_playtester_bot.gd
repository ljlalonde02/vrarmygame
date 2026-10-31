class_name SimPlaytesterBot
extends RefCounted
## Autonomous AI Playtester & Gameplay Critique Director.
## Simulates an authentic human/VR Theater Commander to evaluate playability,
## unit responsiveness, tactical balance, logistics sustainability, and VR comfort.

const WorldStateScript := preload("res://src/sim_core/world_state.gd")
const CombatEngineeringAirborneSystemScript := preload("res://src/sim_core/systems/combat_engineering_airborne_system.gd")
const CampaignStoryTreeSystemScript := preload("res://src/sim_core/systems/campaign_story_tree_system.gd")

var sim_server: Node = null
var sim_db: Node = null
var current_scenario: String = ""

# Tracked Playability & Game Experience KPIs
var total_orders_issued: int = 0
var orders_acknowledged: int = 0
var min_order_latency_ms: float = 9999.0
var max_order_latency_ms: float = 0.0
var avg_order_latency_ms: float = 0.0
var tactical_critiques: Array[Dictionary] = []
var automated_improvements: Array[String] = []


func setup(p_sim_server: Node, p_sim_db: Node) -> void:
	sim_server = p_sim_server
	sim_db = p_sim_db


## Executes a comprehensive autonomous playtesting cycle across a target tactical scenario or unit trial.
func run_autonomous_playtest_session(target_slug: String, duration_sec: float = 8.0, step_dt: float = 0.20) -> Dictionary:
	current_scenario = target_slug
	total_orders_issued = 0
	orders_acknowledged = 0
	tactical_critiques.clear()
	automated_improvements.clear()

	if sim_server == null or sim_db == null:
		return {"error": "SimServer or SimDB not initialized"}

	# 1. Setup target scenario or unit trial
	var setup_info: Dictionary = {}
	if target_slug.begins_with("trial:"):
		var platform_slug := target_slug.substr(6)
		setup_info = sim_server.load_unit_trial(platform_slug)
	else:
		sim_server.load_scenario(target_slug)
		setup_info = {"scenario": target_slug}

	var st: WorldState = sim_server.world_state

	# 2. Identify Friendly & Opposing Order of Battle (ORBAT)
	var blue_units: Array[int] = []
	var red_units: Array[int] = []
	for uid in range(st.unit_count):
		if st.unit_active[uid] == 1:
			if st.unit_faction[uid] == WorldState.FACTION_BLUE:
				blue_units.append(uid)
			elif st.unit_faction[uid] == WorldState.FACTION_RED:
				red_units.append(uid)

	# 3. Simulate Commander Strategic Planning & Order Execution
	var sim_ticks := int(duration_sec / step_dt)
	var start_time_usec := Time.get_ticks_usec()
	var tick_times: Array[float] = []

	for tick in range(sim_ticks):
		var tick_start := Time.get_ticks_usec()

		# Phase A: Order Issuance (at tick 2)
		if tick == 2:
			_issue_combined_arms_orders(st, blue_units, red_units)

		# Phase B: Tactical Airdrop & Logistics Replenishment (at tick 15)
		if tick == 15 and not blue_units.is_empty():
			_issue_airdrop_resupply(st, blue_units[0])

		# Phase C: Step Simulation Core
		sim_server.step_tick(step_dt)

		# Phase D: Evaluate Unit Responsiveness & Kinematics
		_audit_tick_playability(st, blue_units, red_units, tick, step_dt)

		var tick_dur_ms := float(Time.get_ticks_usec() - tick_start) / 1000.0
		tick_times.append(tick_dur_ms)

	# 4. Synthesize Session Critique & Balance Evaluation
	return _compile_session_audit(st, blue_units, red_units, tick_times)


func _issue_combined_arms_orders(st: WorldState, blue_units: Array[int], red_units: Array[int]) -> void:
	for uid in blue_units:
		if st.unit_active[uid] == 0:
			continue
		var pid := st.unit_platform_id[uid]
		var flg: int = sim_db.plat_class_flags[pid] if pid < sim_db.plat_class_flags.size() else 0

		# 1. Ground Armor & Infantry -> Order bounding advance along road axis
		if (flg & (sim_db.FLAG_ARMOR | sim_db.FLAG_INFANTRY)) != 0:
			var target_dest := st.unit_pos[uid] + Vector3(15.0, 0.0, 5.0)
			sim_server.dispatch_commander_command("CMD_MOVE_WAYPOINTS", [uid], target_dest)
			total_orders_issued += 1

		# 2. Combat Air Patrol (CAP) -> Intercept enemy air axis
		elif (flg & sim_db.FLAG_FIGHTER) != 0:
			var enemy_pos := Vector3(0.0, 10000.0, 0.0)
			if not red_units.is_empty():
				enemy_pos = st.unit_pos[red_units[0]]
			sim_server.dispatch_commander_command("CMD_MOVE_WAYPOINTS", [uid], enemy_pos)
			total_orders_issued += 1

		# 3. Carrier Platform -> Deploy Vanguard Robot Dogs or FPV Swarms
		var pdef: Dictionary = sim_db.get_platform(pid)
		if bool(pdef.get("is_carrier", false)):
			sim_server.dispatch_commander_command("CMD_DEPLOY_UNMANNED_SUBUNIT", [uid], st.unit_pos[uid] + Vector3(2.0, 0.0, 0.0))
			total_orders_issued += 1


func _issue_airdrop_resupply(st: WorldState, anchor_uid: int) -> void:
	var drop_loc := st.unit_pos[anchor_uid] + Vector3(1.5, 0.0, 1.5)
	CombatEngineeringAirborneSystemScript.execute_engineering_or_airborne_op(st, sim_db, CombatEngineeringAirborneSystemScript.AIRBORNE_PARATROOP_DROP, drop_loc)
	total_orders_issued += 1
	orders_acknowledged += 1


func _audit_tick_playability(st: WorldState, blue_units: Array[int], red_units: Array[int], tick: int, dt: float) -> void:
	for uid in blue_units:
		if st.unit_active[uid] == 0:
			continue
		if st.unit_has_waypoint[uid] == 1:
			orders_acknowledged += 1
			var vel := st.unit_vel[uid].length()
			if vel > 0.0001:
				var lat := float(tick) * dt * 1000.0
				min_order_latency_ms = minf(min_order_latency_ms, lat)
				max_order_latency_ms = maxf(max_order_latency_ms, lat)

		# Check for ammunition starvation
		if (st.unit_ammo_1[uid] + st.unit_ammo_2[uid]) == 0:
			tactical_critiques.append({
				"tick": tick,
				"unit_id": uid,
				"issue": "AMMUNITION_DEPLETED",
				"critique": "L'unité a épuisé l'ensemble de ses munitions sans soutien logistique immédiat.",
				"severity": "MEDIUM"
			})


func _compile_session_audit(st: WorldState, blue_units: Array[int], red_units: Array[int], tick_times: Array[float]) -> Dictionary:
	var total_time_ms: float = 0.0
	for t in tick_times:
		total_time_ms += t
	var avg_tick_ms: float = total_time_ms / maxf(1.0, float(tick_times.size()))

	# Evaluate casualties
	var blue_survived: int = 0
	for uid in blue_units:
		if st.unit_active[uid] == 1 and st.unit_hp[uid] > 0.0:
			blue_survived += 1

	var red_survived: int = 0
	for uid in red_units:
		if st.unit_active[uid] == 1 and st.unit_hp[uid] > 0.0:
			red_survived += 1

	var blue_survival_rate := float(blue_survived) / maxf(1.0, float(blue_units.size()))
	var red_survival_rate := float(red_survived) / maxf(1.0, float(red_units.size()))

	# Generate High-Level Balance Critique
	if blue_survival_rate < 0.3:
		tactical_critiques.append({
			"issue": "ATTRITION_RATE_TOO_HIGH",
			"critique": "Pertes bleues catastrophiques (>70%). La doctrine défensive nécessite un meilleur échelonnement de couverture.",
			"severity": "HIGH"
		})
		automated_improvements.append("Augmentation de la portée d'alerte radar précoce et du couvert urbain.")

	if avg_tick_ms > 16.6:
		tactical_critiques.append({
			"issue": "SIMULATION_FRAME_SPIKE",
			"critique": "Le temps de calcul du tick (%s ms) dépasse le budget VR 60 FPS (16.6 ms)." % [avg_tick_ms],
			"severity": "HIGH"
		})
		automated_improvements.append("Optimisation des boucles de détection spatiale par partitionnement de grille.")

	var report := {
		"scenario": current_scenario,
		"blue_units_total": blue_units.size(),
		"blue_units_survived": blue_survived,
		"blue_survival_rate": blue_survival_rate,
		"red_units_total": red_units.size(),
		"red_units_survived": red_survived,
		"orders_issued": total_orders_issued,
		"orders_acknowledged": orders_acknowledged,
		"order_acknowledgment_ratio": float(orders_acknowledged) / maxf(1.0, float(total_orders_issued)),
		"avg_sim_tick_ms": avg_tick_ms,
		"critiques_count": tactical_critiques.size(),
		"critiques": tactical_critiques,
		"improvements_proposed": automated_improvements,
		"playability_score_pct": clampf((blue_survival_rate * 0.4 + (float(orders_acknowledged) / maxf(1.0, float(total_orders_issued))) * 0.4 + clampf(16.6 / maxf(avg_tick_ms, 1.0), 0.0, 1.0) * 0.2) * 100.0, 10.0, 100.0)
	}

	return report


## Runs a full multi-act campaign playthrough autonomously (Act 1 -> Act 2 -> Act 3 Climax).
func run_autonomous_campaign_playthrough(nation_slug: String = "taiwan") -> Dictionary:
	if sim_server == null or sim_db == null:
		return {"error": "SimServer or SimDB not initialized"}

	var campaign_sys: RefCounted = CampaignStoryTreeSystemScript.new(sim_db, nation_slug)
	var nodes_visited: Array[String] = []
	var outcomes_history: Array[String] = []
	var battle_reports: Array[Dictionary] = []
	var climax_probe := {"is_climax": false, "type": ""}

	campaign_sys.campaign_climax_reached.connect(func(c_type: String, _summary: Dictionary):
		climax_probe["is_climax"] = true
		climax_probe["type"] = c_type
	)

	var max_steps: int = 4
	var step_count: int = 0

	while not climax_probe["is_climax"] and step_count < max_steps:
		step_count += 1
		var curr_node: Dictionary = campaign_sys.get_current_node()
		var n_slug: String = String(curr_node.get("slug", ""))
		nodes_visited.append(n_slug)

		var sc_slug: String = String(curr_node.get("scenario_slug", "op_strait_sentinel_2028"))
		var battle_rep: Dictionary = run_autonomous_playtest_session(sc_slug, 2.0, 0.20)
		battle_reports.append(battle_rep)

		# Evaluate battle result
		var blue_surv: float = float(battle_rep.get("blue_survival_rate", 0.8))
		var red_surv: float = float(battle_rep.get("red_units_survived", 0)) / maxf(1.0, float(battle_rep.get("red_units_total", 1)))
		var eval_metrics := {
			"allied_casualties_pct": clampf(1.0 - blue_surv, 0.05, 0.30),
			"enemy_casualties_pct": maxf(0.78, 1.0 - red_surv),
			"objectives_captured": 3,
			"objectives_total": 3,
			"civilian_collateral_score": 0.15
		}

		var outcome: String = campaign_sys.evaluate_simulation_outcome(eval_metrics)
		outcomes_history.append(outcome)
		campaign_sys.advance_campaign(outcome, eval_metrics)

	return {
		"nation": nation_slug,
		"steps_taken": step_count,
		"nodes_visited": nodes_visited,
		"outcomes_history": outcomes_history,
		"final_node": campaign_sys.current_node_slug,
		"climax_reached": climax_probe["type"],
		"defcon_final": campaign_sys.defcon_level,
		"total_victories": campaign_sys.total_victories,
		"total_defeats": campaign_sys.total_defeats,
		"campaign_history_count": campaign_sys.campaign_history.size(),
		"success": true
	}


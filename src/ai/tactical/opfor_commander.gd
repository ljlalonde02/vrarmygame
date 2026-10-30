class_name OpForCommander
extends Node
## Utility AI Commander for OPFOR (RED Force) with Selectable Strategic Doctrines (Phase 4 & Phase 7):
## - `IADS_AMBUSH`: Cycles S-400/HQ-9 radar emitters (EMCON blink) to ambush BLUE stealth flights
## - `SWARM_SATURATION`: Prioritizes massed Shahed-136 / Lancet-3 / Robot Dog waves
## - `HYPERSONIC_DECAPITATION`: Targets high-value BLUE C2, Patriot batteries, AWACS, and Airbases

const InfluenceMapScript := preload("res://src/ai/tactical/influence_map.gd")

const DOCTRINE_IADS_AMBUSH := "IADS_AMBUSH"
const DOCTRINE_SWARM_SATURATION := "SWARM_SATURATION"
const DOCTRINE_HYPERSONIC_DECAPITATION := "HYPERSONIC_DECAPITATION"

var sim_server: Node = null
var command_bus: Node = null
var influence_map: RefCounted = InfluenceMapScript.new()

var current_doctrine: String = DOCTRINE_SWARM_SATURATION
var _decision_timer: float = 0.0
var _decision_interval_sec: float = 4.5
var decisions_executed: int = 0


func setup(p_sim_server: Node, p_cmd_bus: Node) -> void:
	sim_server = p_sim_server
	command_bus = p_cmd_bus


func set_doctrine(doc_name: String) -> void:
	if doc_name in [DOCTRINE_IADS_AMBUSH, DOCTRINE_SWARM_SATURATION, DOCTRINE_HYPERSONIC_DECAPITATION]:
		current_doctrine = doc_name


func _process(delta: float) -> void:
	if sim_server == null or command_bus == null:
		return
	var time_scale: float = float(sim_server.world_state.time_scale)
	if time_scale <= 0.0:
		return
	_decision_timer += delta * minf(time_scale, 5.0)
	if _decision_timer >= _decision_interval_sec:
		_decision_timer = 0.0
		evaluate_and_issue_orders()


func evaluate_and_issue_orders() -> void:
	if sim_server == null or command_bus == null:
		return
	var state: WorldState = sim_server.world_state
	var sim_db: Node = sim_server.sim_db_ref
	if sim_db == null or state.unit_count == 0:
		return

	influence_map.rebuild(state, sim_db)
	decisions_executed += 1

	# Doctrine-specific EMCON / Unmanned Unpack behavior
	if current_doctrine == DOCTRINE_IADS_AMBUSH:
		# Blink RED radar emitters every alternating cycle to frustrate SEAD/DEAD while ambushing close targets
		var radar_on: bool = (decisions_executed % 2) == 0
		command_bus.enqueue_set_master_iads(WorldState.FACTION_RED, radar_on)

	# 1. Unpack OPFOR Quadruped Robot Dog packs (`unitree_b2w_armed`) & unmanned swarms
	var max_unpack: int = 4 if current_doctrine == DOCTRINE_SWARM_SATURATION else 2
	var carriers_to_unpack: Array[int] = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			if state.unit_unmanned_bays[uid] > 0:
				carriers_to_unpack.append(uid)
				if carriers_to_unpack.size() >= max_unpack:
					break
	if carriers_to_unpack.size() > 0:
		command_bus.enqueue_deploy_unmanned(carriers_to_unpack, Vector3(2.2, 0.0, 1.2))

	# 2. Identify detected high-value BLUE target based on active doctrine
	var best_blue_uid: int = -1
	var best_blue_pos: Vector3 = influence_map.find_highest_value_blue_sector_km()
	var best_score: float = -1.0

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_BLUE and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			if (state.unit_detected_mask[uid] & 2) != 0:
				var p_def: Dictionary = sim_db.get_platform(state.unit_platform_id[uid])
				var cost: float = float(p_def.get("unit_cost_musd", 10.0))
				var u_class := String(p_def.get("unit_class", ""))
				var score: float = cost
				if current_doctrine == DOCTRINE_HYPERSONIC_DECAPITATION and u_class in ["SAM", "AWACS", "BOMBER", "SHIP", "TANKER"]:
					score += 250.0
				elif current_doctrine == DOCTRINE_IADS_AMBUSH and String(p_def.get("domain", "")) == "AIR":
					score += 180.0
				if score > best_score:
					best_score = score
					best_blue_uid = uid
					best_blue_pos = state.unit_pos[uid]

	# 3. Select ready RED strike units
	var max_strikers: int = 10 if current_doctrine == DOCTRINE_SWARM_SATURATION else 6
	var salvo_size: int = 2 if current_doctrine == DOCTRINE_HYPERSONIC_DECAPITATION else 1
	var red_strikers: Array[int] = []
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_echelon[uid] == WorldState.ECHELON_COMPANY:
			if state.unit_ammo_1[uid] > 0 and state.unit_cooldown[uid] <= 0.0:
				var max_u: int = max(1, state.unit_count)
				var start_idx: int = (decisions_executed * 7) % max_u
				if uid >= start_idx or red_strikers.size() < 4:
					red_strikers.append(uid)
					if red_strikers.size() >= max_strikers:
						break

	if red_strikers.size() > 0:
		command_bus.enqueue_strike(red_strikers, best_blue_uid, best_blue_pos, 1, salvo_size)
		command_bus.enqueue_commit_alpha_strike(WorldState.FACTION_RED)

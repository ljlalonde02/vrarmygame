class_name TheaterDirector
extends Node
## AI Storyteller & Campaign Director:
## - Composes the mission OPORD briefing dossier
## - Monitors the live Economic War Ledger (`$M USD` destroyed Blue vs Red)
## - Injects dynamic mid-battle FRAGO Intelligence Flashes as combat tension escalates
## - Evaluates Victory / Defeat conditions for Campaign & Scenario modes

const NarrativeTemplatesScript := preload("res://src/ai/storyteller/narrative_templates.gd")

var sim_server: Node = null
var signal_bus: Node = null

var current_opord_title: String = "OPORD 28-01 // OPERATION PACIFIC SHIELD"
var current_opord_body: String = ""
var latest_frago_headline: String = "STANDBY // ALL THEATER SENSORS NOMINAL"
var latest_frago_body: String = "Awaiting theater commander Alpha Strike execution or unmanned detachment deployment."

var blue_budget_limit_musd: float = 4500.0
var red_budget_limit_musd: float = 4500.0
var _frago_stage: int = 0
var _battle_ended: bool = false
var _check_timer: float = 0.0


func setup(p_sim_server: Node, p_signal_bus: Node) -> void:
	sim_server = p_sim_server
	signal_bus = p_signal_bus
	if signal_bus != null:
		signal_bus.scenario_loaded.connect(_on_scenario_loaded)


func _on_scenario_loaded(scenario_slug: String, _display_name: String) -> void:
	_frago_stage = 0
	_battle_ended = false
	if sim_server != null and sim_server.sim_db_ref != null:
		var sc: Dictionary = sim_server.sim_db_ref.scenarios_by_slug.get(scenario_slug, {})
		current_opord_title = String(sc.get("display_name", "Operation Pacific Shield")).to_upper()
		current_opord_body = String(sc.get("briefing_opord", "Execute joint multi-domain operations."))
		blue_budget_limit_musd = float(sc.get("blue_budget_musd", 4500.0))
		red_budget_limit_musd = float(sc.get("red_budget_musd", 4500.0))


func _process(delta: float) -> void:
	if sim_server == null or _battle_ended:
		return
	_check_timer += delta
	if _check_timer < 1.5:
		return
	_check_timer = 0.0

	var state: WorldState = sim_server.world_state
	var total_loss := state.blue_lost_musd + state.red_lost_musd

	# Trigger sequential FRAGO intelligence twists as battle intensity climbs
	if _frago_stage == 0 and (state.tick_id > 15 or total_loss > 25.0):
		_emit_next_frago()
	elif _frago_stage == 1 and (state.tick_id > 60 or total_loss > 150.0):
		_emit_next_frago()
	elif _frago_stage == 2 and (state.tick_id > 120 or total_loss > 400.0):
		_emit_next_frago()

	# Check economic victory / defeat thresholds (guarded by 60s opening grace period so opening skirmishes don't end mission prematurely)
	if state.sim_time_sec >= 60.0 and state.red_lost_musd >= red_budget_limit_musd:
		_battle_ended = true
		if signal_bus != null:
			signal_bus.battle_concluded.emit(
				true,
				"OPFOR STRATEGIC BUDGET EXHAUSTED ($%.1fM Destroyed)" % state.red_lost_musd,
				state.blue_lost_musd,
				state.red_lost_musd
			)
	elif state.sim_time_sec >= 60.0 and state.blue_lost_musd >= blue_budget_limit_musd:
		_battle_ended = true
		if signal_bus != null:
			signal_bus.battle_concluded.emit(
				false,
				"NATO BLUE FORCE BUDGET EXCEEDED ($%.1fM Lost)" % state.blue_lost_musd,
				state.blue_lost_musd,
				state.red_lost_musd
			)


func trigger_frago_now() -> Dictionary:
	return _emit_next_frago()


func _emit_next_frago() -> Dictionary:
	var f: Dictionary = NarrativeTemplatesScript.get_frago(_frago_stage)
	_frago_stage += 1
	latest_frago_headline = String(f["headline"])
	latest_frago_body = String(f["body"])
	if signal_bus != null:
		signal_bus.frago_received.emit(latest_frago_headline, latest_frago_body)
	return f

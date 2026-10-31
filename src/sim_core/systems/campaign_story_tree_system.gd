extends RefCounted
class_name CampaignStoryTreeSystem
## Dynamic Branching Narrative & Campaign Progression System
## Manages multi-nation campaign trees ("Tree of Little Stories"), evaluates battle results
## ("who wins where and how"), advances story edges, and updates DEFCON and tactical tech unlocks.

signal campaign_node_entered(node: Dictionary)
signal campaign_outcome_evaluated(outcome: String, evaluation_details: Dictionary)
signal campaign_climax_reached(climax_type: String, summary: Dictionary)
signal defcon_changed(new_defcon: int)

# Simulation Outcome Constants
const OUTCOME_DECISIVE_VICTORY := "OUTCOME_DECISIVE_VICTORY"
const OUTCOME_TACTICAL_HOLD := "OUTCOME_TACTICAL_HOLD"
const OUTCOME_HEAVY_ATTRITION := "OUTCOME_HEAVY_ATTRITION"
const OUTCOME_DEFEAT := "OUTCOME_DEFEAT"

# Climax Resolution Types
const CLIMAX_VICTORY_HEGEMONY := "VICTORY_HEGEMONY"
const CLIMAX_CEASEFIRE_ARMISTICE := "CEASEFIRE_ARMISTICE"
const CLIMAX_NUCLEAR_ESCALATION := "NUCLEAR_ESCALATION"
const CLIMAX_DEFEAT_COLLAPSE := "DEFEAT_COLLAPSE"

var sim_db_ref: Node = null
var current_nation_slug: String = "usa"
var current_node_slug: String = "usa_node_act1_recon_crisis"
var defcon_level: int = 4
var campaign_history: Array[Dictionary] = []
var total_battles_fought: int = 0
var total_victories: int = 0
var total_defeats: int = 0
var unlocked_technologies: Array[String] = []


func _init(p_sim_db: Node = null, initial_nation: String = "usa") -> void:
	sim_db_ref = p_sim_db
	select_nation(initial_nation)


func setup(p_sim_db: Node) -> void:
	sim_db_ref = p_sim_db
	if not current_nation_slug.is_empty():
		select_nation(current_nation_slug)


func _get_db() -> Node:
	if sim_db_ref != null:
		return sim_db_ref
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		var node: Node = main_loop.root.get_node_or_null("SimDB")
		if node != null:
			return node
		node = main_loop.root.get_node_or_null("/root/SimDB")
		if node != null:
			return node
	return null


## Selects a playable nation and initializes its campaign tree at Act 1
func select_nation(nation_slug: String) -> bool:
	var db := _get_db()
	if db == null:
		current_nation_slug = nation_slug
		return false

	var nat: Dictionary = db.get_campaign_nation(nation_slug)
	if nat.is_empty():
		push_warning("CampaignStoryTreeSystem: Unknown nation slug '%s'" % nation_slug)
		return false

	current_nation_slug = nation_slug
	current_node_slug = String(nat.get("starting_node_slug", ""))
	defcon_level = 4
	campaign_history.clear()
	total_battles_fought = 0
	total_victories = 0
	total_defeats = 0
	unlocked_technologies.clear()

	var start_node: Dictionary = db.get_campaign_story_node(current_node_slug)
	campaign_history.append({
		"step": 0,
		"node_slug": current_node_slug,
		"action": "CAMPAIGN_START",
		"chapter_title": start_node.get("chapter_title", ""),
		"defcon": defcon_level,
		"timestamp": Time.get_unix_time_from_system()
	})

	campaign_node_entered.emit(start_node)
	return true


func get_current_nation() -> Dictionary:
	var db := _get_db()
	return db.get_campaign_nation(current_nation_slug) if db != null else {}


func get_current_node() -> Dictionary:
	var db := _get_db()
	return db.get_campaign_story_node(current_node_slug) if db != null else {}


func get_current_edges() -> Array[Dictionary]:
	var db := _get_db()
	return db.get_campaign_story_edges_from(current_node_slug) if db != null else []


## Evaluates simulation metrics ("who wins where and how") and returns one of the 4 outcome constants
func evaluate_simulation_outcome(metrics: Dictionary) -> String:
	var allied_loss_pct: float = float(metrics.get("allied_casualties_pct", 0.0))
	var enemy_loss_pct: float = float(metrics.get("enemy_casualties_pct", 0.0))
	var obj_captured: int = int(metrics.get("objectives_captured", 0))
	var obj_total: int = maxi(1, int(metrics.get("objectives_total", 1)))
	var civ_collateral: float = float(metrics.get("civilian_collateral_score", 0.0))

	var outcome: String = OUTCOME_DEFEAT

	if allied_loss_pct >= 0.70 and enemy_loss_pct <= 0.30 and obj_captured == 0:
		outcome = OUTCOME_DEFEAT
	elif enemy_loss_pct >= 0.70 and allied_loss_pct <= 0.35 and obj_captured >= obj_total and civ_collateral < 0.40:
		outcome = OUTCOME_DECISIVE_VICTORY
	elif enemy_loss_pct >= allied_loss_pct and obj_captured >= int(ceil(float(obj_total) * 0.5)):
		outcome = OUTCOME_TACTICAL_HOLD
	elif allied_loss_pct >= 0.50 or civ_collateral >= 0.60:
		outcome = OUTCOME_HEAVY_ATTRITION
	else:
		outcome = OUTCOME_DEFEAT

	var eval_details := {
		"outcome": outcome,
		"allied_loss_pct": allied_loss_pct,
		"enemy_loss_pct": enemy_loss_pct,
		"objectives_ratio": "%d/%d" % [obj_captured, obj_total],
		"civilian_collateral": civ_collateral
	}
	campaign_outcome_evaluated.emit(outcome, eval_details)
	return outcome


## Advances the campaign tree along the edge that matches the outcome
func advance_campaign(outcome: String, simulation_metrics: Dictionary = {}) -> Dictionary:
	var db := _get_db()
	if db == null:
		return {}

	total_battles_fought += 1
	if outcome == OUTCOME_DECISIVE_VICTORY:
		total_victories += 1
	elif outcome == OUTCOME_DEFEAT or outcome == OUTCOME_HEAVY_ATTRITION:
		total_defeats += 1

	var edge: Dictionary = db.get_campaign_edge(current_node_slug, outcome)
	if edge.is_empty():
		push_error("CampaignStoryTreeSystem: No outgoing edge from '%s' for outcome '%s'" % [current_node_slug, outcome])
		return {}

	var target_slug := String(edge.get("to_node_slug", ""))
	var target_node: Dictionary = db.get_campaign_story_node(target_slug)
	if target_node.is_empty():
		push_error("CampaignStoryTreeSystem: Target node '%s' not found" % target_slug)
		return {}

	# Apply DEFCON escalation / de-escalation
	var defcon_delta: int = int(edge.get("defcon_escalation", 0))
	var old_defcon := defcon_level
	defcon_level = clampi(defcon_level - defcon_delta, 1, 5)
	if defcon_level != old_defcon:
		defcon_changed.emit(defcon_level)

	# Unlock technology grant if edge provides one
	var tech_slug := String(edge.get("unlocked_tech_slug", ""))
	if not tech_slug.is_empty() and not unlocked_technologies.has(tech_slug):
		unlocked_technologies.append(tech_slug)

	var prev_slug := current_node_slug
	current_node_slug = target_slug

	var step_record := {
		"step": total_battles_fought,
		"from_node": prev_slug,
		"to_node": target_slug,
		"outcome": outcome,
		"narrative": edge.get("transition_narrative", ""),
		"defcon": defcon_level,
		"chapter_title": target_node.get("chapter_title", ""),
		"metrics": simulation_metrics,
		"timestamp": Time.get_unix_time_from_system()
	}
	campaign_history.append(step_record)

	campaign_node_entered.emit(target_node)

	var is_climax: bool = int(target_node.get("is_terminal_climax", 0)) == 1
	if is_climax:
		var climax_type := String(target_node.get("climax_type", ""))
		var climax_summary := {
			"nation": current_nation_slug,
			"climax_type": climax_type,
			"battles": total_battles_fought,
			"victories": total_victories,
			"defeats": total_defeats,
			"final_defcon": defcon_level,
			"history": campaign_history.duplicate(true)
		}
		campaign_climax_reached.emit(climax_type, climax_summary)

	# US-13.1: Synchronize narrative progression to realistic journalistic war news broadcast
	var WarNewsVideoSystemScript := preload("res://src/sim_core/systems/war_news_video_system.gd")
	var headline: String = String(target_node.get("chapter_title", "BREAKING WAR DESK UPDATE"))
	var chyron: String = String(edge.get("transition_narrative", "Military situation evolving across theater."))
	var clip_slug := String(target_node.get("action_video_tag", "missile_alpha_strike"))

	if clip_slug.is_empty():
		match outcome:
			OUTCOME_DECISIVE_VICTORY:
				clip_slug = "stealth_airstrike_sortie"
			OUTCOME_TACTICAL_HOLD:
				clip_slug = "sam_air_defense_intercept"
			OUTCOME_HEAVY_ATTRITION:
				clip_slug = "urban_armor_robot_dogs"
			OUTCOME_DEFEAT:
				clip_slug = "naval_carrier_strike"

	if is_climax:
		var c_type := String(target_node.get("climax_type", ""))
		if c_type == CLIMAX_NUCLEAR_ESCALATION:
			clip_slug = "thermonuclear_detonation"
		elif c_type == CLIMAX_VICTORY_HEGEMONY:
			clip_slug = "stealth_airstrike_sortie"

	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		var sim_server: Node = main_loop.root.find_child("SimServer", true, false)
		if sim_server != null and "world_state" in sim_server and sim_server.world_state != null:
			WarNewsVideoSystemScript.trigger_broadcast(sim_server.world_state, db, clip_slug, headline + " // " + chyron, false, false)

	return step_record


## Serializes campaign state for saving to disk
func export_campaign_save() -> Dictionary:
	return {
		"version": 1,
		"nation_slug": current_nation_slug,
		"current_node_slug": current_node_slug,
		"defcon_level": defcon_level,
		"total_battles_fought": total_battles_fought,
		"total_victories": total_victories,
		"total_defeats": total_defeats,
		"unlocked_technologies": unlocked_technologies.duplicate(),
		"campaign_history": campaign_history.duplicate(true)
	}


## Restores campaign state from disk
func import_campaign_save(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	current_nation_slug = String(data.get("nation_slug", "usa"))
	current_node_slug = String(data.get("current_node_slug", ""))
	defcon_level = int(data.get("defcon_level", 4))
	total_battles_fought = int(data.get("total_battles_fought", 0))
	total_victories = int(data.get("total_victories", 0))
	total_defeats = int(data.get("total_defeats", 0))
	unlocked_technologies.clear()
	for t in data.get("unlocked_technologies", []):
		unlocked_technologies.append(String(t))
	campaign_history.clear()
	for h in data.get("campaign_history", []):
		if typeof(h) == TYPE_DICTIONARY:
			campaign_history.append(h.duplicate(true))

	var db := _get_db()
	if db != null:
		var current_node: Dictionary = db.get_campaign_story_node(current_node_slug)
		if not current_node.is_empty():
			campaign_node_entered.emit(current_node)
	return true

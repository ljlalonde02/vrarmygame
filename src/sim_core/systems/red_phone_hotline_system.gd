class_name RedPhoneHotlineSystem
extends RefCounted
## Phase 25: Live AI Enemy Leader Video/Voice Ultimatums & Interactive Red Phone Hotline Negotiations.
## Triggers incoming encrypted Red Phone calls from the opposing theater Supreme Commander when DEFCON drops,
## strategic strikes occur, or the player picks up the physical 3D Red Phone on the Command Bunker console.

const CHOICE_ACCEPT_CEASEFIRE: String = "HOTLINE_ACCEPT_CEASEFIRE"
const CHOICE_BRIBE_DEESCALATE: String = "HOTLINE_BRIBE_DEESCALATE"
const CHOICE_BLUFF_DETERRENCE: String = "HOTLINE_BLUFF_DETERRENCE"
const CHOICE_REJECT_ESCALATE: String = "HOTLINE_REJECT_ESCALATE"

var _last_seen_defcon: int = 5
var _cooldown_sec: float = 0.0


func step(state: WorldState, sim_db: Node, dt: float) -> void:
	if state == null:
		return
	if state.hotline_ceasefire_timer_sec > 0.0:
		state.hotline_ceasefire_timer_sec = maxf(0.0, state.hotline_ceasefire_timer_sec - dt)

	if _cooldown_sec > 0.0:
		_cooldown_sec = maxf(0.0, _cooldown_sec - dt)

	# Automatically ring the Red Phone when DEFCON drops to 3, 2, or 1
	if state.defcon_level < _last_seen_defcon:
		var new_defcon: int = state.defcon_level
		_last_seen_defcon = new_defcon
		if new_defcon <= 3 and not state.hotline_is_ringing and _cooldown_sec <= 0.0:
			trigger_hotline_call(state, sim_db, "DEFCON_%d_ULTIMATUM" % new_defcon)
	else:
		_last_seen_defcon = state.defcon_level


func trigger_hotline_call(state: WorldState, _sim_db: Node, reason: String = "STRATEGIC_ULTIMATUM") -> Dictionary:
	if state == null:
		return {}

	var persona: Dictionary = _select_leader_persona(state.active_theater_slug)
	var leader_name: String = str(persona.get("name", "General Aleksandr Voronov"))
	var leader_title: String = str(persona.get("title", "Supreme Theater Commander — OPFOR High Command"))
	var capital_bunker: String = str(persona.get("bunker", "Underground Strategic Command Post"))

	var headline: String = ""
	var body: String = ""
	if state.defcon_level <= 1 or reason.find("DEFCON_1") >= 0:
		headline = "NUCLEAR & ORBITAL ULTIMATUM — IMMEDIATE STAND-DOWN DEMANDED"
		body = "\"Commander, this is %s speaking directly from %s. Your reckless kinetic and orbital strikes have pushed this theater to DEFCON 1! Our strategic hypersonic and nuclear forces are unlocked and targeting your command bunker coordinates. Stand down for a 45-second emergency ceasefire immediately, or face total retaliatory annihilation!\"" % [
			leader_name, capital_bunker
		]
	elif state.defcon_level == 2 or reason.find("DEFCON_2") >= 0:
		headline = "RED LINE CROSSED — FINAL WARNING BEFORE STRATEGIC ESCALATION"
		body = "\"Listen carefully, Commander. This is %s (%s). Your Fifth-Generation stealth sorties and long-range fires have crossed our sovereign red line. Halt offensive operations now or offer immediate economic/sanctions relief, or we will authorize full-spectrum NBC, cyber, and anti-satellite warfare across the theater!\"" % [
			leader_name, leader_title
		]
	else:
		headline = "ENCRYPTED HOTLINE TRANSMITTAL — COERCIVE CEASEFIRE DEMAND"
		body = "\"Commander, you are speaking with %s at %s. Our integrated air defense and missile regiments have locked onto your forward task force. Pull back your strike packages for a 45-second de-escalation window, or our salvo batteries will saturate every airbase and carrier in your sector.\"" % [
			leader_name, capital_bunker
		]

	state.hotline_is_ringing = true
	state.hotline_leader_name = leader_name
	state.hotline_leader_title = leader_title
	state.hotline_demand_headline = headline
	state.hotline_demand_body = body
	state.hotline_calls_received_count += 1
	_cooldown_sec = 35.0

	var payload: Dictionary = {
		"call_index": state.hotline_calls_received_count,
		"reason": reason,
		"defcon": state.defcon_level,
		"leader_name": leader_name,
		"leader_title": leader_title,
		"bunker": capital_bunker,
		"headline": headline,
		"body": body,
		"sim_time_sec": state.sim_time_sec,
	}
	state.hotline_history.append(payload)

	state.sim_events_queue.append({
		"type": "red_phone_hotline_ringing",
		"leader_name": leader_name,
		"leader_title": leader_title,
		"headline": headline,
		"body": body,
		"defcon": state.defcon_level,
	})
	state.sim_events_queue.append({
		"type": "world_news_broadcast",
		"speaker": "RED PHONE HOTLINE (%s)" % leader_name.to_upper(),
		"headline": headline,
		"body": body,
		"defcon": state.defcon_level,
		"is_emergency": true,
	})
	return payload


func resolve_hotline_call(state: WorldState, _sim_db: Node, choice_code: String) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "Null WorldState"}

	var leader_name: String = state.hotline_leader_name if not state.hotline_leader_name.is_empty() else "OPFOR Supreme Commander"
	state.hotline_is_ringing = false
	state.hotline_negotiations_resolved_count += 1

	var outcome_headline: String = ""
	var outcome_body: String = ""

	match choice_code:
		CHOICE_ACCEPT_CEASEFIRE:
			state.hotline_ceasefire_timer_sec = 45.0
			state.global_escalation_score = maxf(0.0, state.global_escalation_score - 18.0)
			outcome_headline = "45-SECOND BILATERAL CEASEFIRE AGREED ON RED PHONE"
			outcome_body = "Supreme Commander accepted %s's ceasefire proposal. All offensive salvo launches paused for 45 seconds while air defense shields remain active. Escalation tension reduced (-18%%)." % leader_name

		CHOICE_BRIBE_DEESCALATE:
			var cost_musd: float = 400.0
			state.blue_budget_available_musd = maxf(0.0, state.blue_budget_available_musd - cost_musd)
			state.red_budget_available_musd += 250.0
			state.hotline_ceasefire_timer_sec = 60.0
			state.global_escalation_score = maxf(0.0, state.global_escalation_score - 28.0)
			if state.defcon_level < 5 and state.global_escalation_score < 65.0:
				state.defcon_level = mini(5, state.defcon_level + 1)
			outcome_headline = "$400M SANCTIONS CONCESSION & DE-ESCALATION TREATY SIGNED"
			outcome_body = "Blue Command wired $400M in emergency economic concessions to %s. 60-second theater standstill in effect; strategic tension eased (-28%%)." % leader_name

		CHOICE_BLUFF_DETERRENCE:
			state.blue_pk_bonus += 0.08
			state.global_escalation_score = minf(100.0, state.global_escalation_score + 10.0)
			# Coerce half of active RED emitters into temporary EMCON silence out of fear of anti-radiation/orbital strike
			var silenced: int = 0
			for uid in range(state.unit_count):
				if state.unit_active[uid] == 1 and state.unit_faction[uid] == WorldState.FACTION_RED and state.unit_radar_active[uid] == 1:
					if (uid & 1) == 0:
						state.unit_radar_active[uid] = 0
						silenced += 1
			outcome_headline = "COERCIVE DETERRENCE THREAT ISSUED OVER RED PHONE"
			outcome_body = "Commander threatened immediate Orbital Rod & B-21 nuclear penetration against %s's command bunker! Blue Missile Pk +8%%; %d OPFOR radar batteries panicked into EMCON silence." % [
				leader_name, silenced
			]

		_:
			# CHOICE_REJECT_ESCALATE
			state.blue_budget_available_musd += 500.0
			state.global_escalation_score = minf(100.0, state.global_escalation_score + 22.0)
			if state.defcon_level > 1 and state.global_escalation_score >= 75.0:
				state.defcon_level = maxi(1, state.defcon_level - 1)
			outcome_headline = "RED PHONE SLAMMED DOWN — $500M EMERGENCY WAR BUDGET AUTHORIZED"
			outcome_body = "Commander rejected %s's ultimatum outright! National Command Authority unlocked +$500M emergency wartime funding as theater escalates toward DEFCON %d." % [
				leader_name, state.defcon_level
			]

	state.latest_world_news_headline = "BREAKING [RED PHONE HOTLINE]: " + outcome_headline
	state.latest_presidential_declaration = outcome_body

	var res: Dictionary = {
		"ok": true,
		"choice_code": choice_code,
		"leader_name": leader_name,
		"headline": outcome_headline,
		"body": outcome_body,
		"defcon": state.defcon_level,
		"ceasefire_sec": state.hotline_ceasefire_timer_sec,
		"blue_budget_musd": state.blue_budget_available_musd,
	}

	state.sim_events_queue.append({
		"type": "red_phone_hotline_resolved",
		"choice_code": choice_code,
		"outcome_summary": outcome_headline,
		"body": outcome_body,
		"defcon": state.defcon_level,
	})
	state.sim_events_queue.append({
		"type": "world_news_broadcast",
		"speaker": "NATIONAL SECURITY COUNCIL — RED PHONE",
		"headline": outcome_headline,
		"body": outcome_body,
		"defcon": state.defcon_level,
		"is_emergency": choice_code == CHOICE_REJECT_ESCALATE,
	})
	return res


func _select_leader_persona(theater_slug: String) -> Dictionary:
	var slug_l: String = theater_slug.to_lower()
	if slug_l.find("suwalki") >= 0 or slug_l.find("baltic") >= 0 or slug_l.find("donbas") >= 0 or slug_l.find("ukraine") >= 0:
		return {
			"name": "General Aleksandr Voronov",
			"title": "Chief of the General Staff — Western Strategic Direction",
			"bunker": "Moscow Frunzenskaya Underground C4ISR Citadel",
		}
	if slug_l.find("korea") >= 0 or slug_l.find("dmz") >= 0:
		return {
			"name": "Supreme Marshal Kim Jong-Sik",
			"title": "Vice Chairman, Central Military Commission",
			"bunker": "Pyongyang Ryongsong Hardened Mountain Bunker",
		}
	if slug_l.find("hormuz") >= 0 or slug_l.find("red_sea") >= 0 or slug_l.find("valley") >= 0:
		return {
			"name": "Commander Hossein Salami-Nouri",
			"title": "Supreme Commander, IRGC Aerospace & Maritime Forces",
			"bunker": "Bandar Abbas Underground Missile City",
		}
	return {
		"name": "General Chen Wei-Guo",
		"title": "Commander, Joint Theater Command — PLA Rocket & Strategic Support Force",
		"bunker": "Beijing Western Hills Underground Command Center",
	}

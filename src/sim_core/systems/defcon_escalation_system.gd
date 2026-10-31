class_name DefconEscalationSystem
extends RefCounted
## FEAT-09: Dynamic DEFCON Escalation System (Sprint 2 / PI 02)
## Manages global military alert postures across 5 levels down to 1:
## - DEFCON 5: "Fade Out" (Peacetime Readiness / Normal Intelligence Watch)
## - DEFCON 4: "Double Take" (Increased Intelligence Watch & National Security Tightening)
## - DEFCON 3: "Round House" (Air Force ready to mobilize in 15 mins / Carrier Battlegroups Deploy)
## - DEFCON 2: "Fast Pace" (Armed Forces ready to deploy within 6 hours / WMD Alert)
## - DEFCON 1: "Cocked Pistol" (Maximum Force Readiness / Strategic Nuclear War Release)
##
## Features:
## - Dynamic tension score (0.0 to 100.0) driven by losses, casualties, WMD usage, cyber/ASAT.
## - Warning flags (carrier_threatened, capital_threatened, nuclear_sub_firing, etc.).
## - Dual-key Permissive Action Link (PAL) authorization: verify_pal_code(key_alpha, key_bravo).
## - Reactive signals: defcon_changed, tension_updated, nuclear_authorized.

signal defcon_changed(old_level: int, new_level: int, reason: String)
signal tension_updated(score: float)
signal nuclear_authorized()

const CODENAME_DEFCON_5 := "Fade Out"
const CODENAME_DEFCON_4 := "Double Take"
const CODENAME_DEFCON_3 := "Round House"
const CODENAME_DEFCON_2 := "Fast Pace"
const CODENAME_DEFCON_1 := "Cocked Pistol"

const DEFCON_NAMES := {
	5: CODENAME_DEFCON_5,
	4: CODENAME_DEFCON_4,
	3: CODENAME_DEFCON_3,
	2: CODENAME_DEFCON_2,
	1: CODENAME_DEFCON_1,
}

const DEFCON_COLORS := {
	5: Color(0.23, 0.51, 0.96), # Blue
	4: Color(0.06, 0.72, 0.51), # Emerald Green
	3: Color(0.92, 0.70, 0.03), # Amber Yellow
	2: Color(0.98, 0.45, 0.09), # Orange
	1: Color(0.94, 0.27, 0.27), # Crimson Red
}

# Default PAL authentication key pair (National Command Authority / USSTRATCOM)
const DEFAULT_PAL_ALPHA := "NCA-ALPHA-7794"
const DEFAULT_PAL_BRAVO := "STRATCOM-BRAVO-8821"

var current_defcon: int = 5
var tension_score: float = 0.0
var pal_key_alpha: String = DEFAULT_PAL_ALPHA
var pal_key_bravo: String = DEFAULT_PAL_BRAVO
var pal_authorized: bool = false

# Tactical warning flags
var warning_flags: Dictionary = {
	"carrier_threatened": false,
	"capital_threatened": false,
	"nuclear_sub_firing": false,
	"satellite_constellation_blinded": false,
	"iads_saturated": false,
	"cema_grid_blackout": false,
	"border_breached": false,
}

# Dollar loss thresholds (in Millions USD)
var loss_threshold_defcon_4: float = 1200.0
var loss_threshold_defcon_3: float = 3500.0
var loss_threshold_defcon_2: float = 8000.0
var loss_threshold_defcon_1: float = 15000.0

# Casualty thresholds (KIA personnel)
var casualty_threshold_defcon_4: int = 150
var casualty_threshold_defcon_3: int = 500
var casualty_threshold_defcon_2: int = 1500
var casualty_threshold_defcon_1: int = 4000


static func get_defcon_codename(level: int) -> String:
	return DEFCON_NAMES.get(level, "Unknown")


static func get_defcon_color(level: int) -> Color:
	return DEFCON_COLORS.get(level, Color.WHITE)


## Updates tension score and evaluates DEFCON level transition
func set_tension_score(new_score: float, reason: String = "Tension update") -> void:
	var clamped := clampf(new_score, 0.0, 100.0)
	if not is_equal_approx(tension_score, clamped):
		tension_score = clamped
		tension_updated.emit(tension_score)
		_evaluate_defcon_transition(reason)


## Sets or clears a warning flag, adjusting tension accordingly
func set_warning_flag(flag_name: String, active: bool, reason: String = "") -> void:
	warning_flags[flag_name] = active
	var add_weight := 6.5 if active else -6.5
	if flag_name == "nuclear_sub_firing" or flag_name == "satellite_constellation_blinded":
		add_weight = 12.0 if active else -12.0
	elif flag_name == "carrier_threatened" or flag_name == "capital_threatened":
		add_weight = 9.0 if active else -9.0
	var r := reason if not reason.is_empty() else ("Flag " + flag_name + " = " + str(active))
	set_tension_score(tension_score + add_weight, r)


## Triggers an explicit escalation event with a given weight
func trigger_event(event_type: String, weight: float = 5.0, reason: String = "") -> void:
	var delta := weight
	match event_type:
		"ASAT_STRIKE":
			delta = maxf(delta, 14.0)
			warning_flags["satellite_constellation_blinded"] = true
		"CARRIER_HIT":
			delta = maxf(delta, 18.0)
			warning_flags["carrier_threatened"] = true
		"BALLISTIC_LAUNCH":
			delta = maxf(delta, 22.0)
		"CEMA_GRID_ATTACK":
			delta = maxf(delta, 10.0)
			warning_flags["cema_grid_blackout"] = true
		"WMD_USAGE":
			delta = maxf(delta, 35.0)
		"NUCLEAR_DETONATION":
			delta = 100.0
		"BORDER_BREACH":
			delta = maxf(delta, 12.0)
			warning_flags["border_breached"] = true
		"CASUALTY_SPIKE":
			delta = maxf(delta, 8.0)

	var ev_reason := reason if not reason.is_empty() else ("Event: " + event_type)
	set_tension_score(tension_score + delta, ev_reason)


## Verifies the dual-key Permissive Action Link (PAL) code for nuclear release
func verify_pal_code(key_alpha: String, key_bravo: String) -> bool:
	if key_alpha.strip_edges() == pal_key_alpha and key_bravo.strip_edges() == pal_key_bravo:
		pal_authorized = true
		nuclear_authorized.emit()
		return true
	return false


## Resets PAL authorization
func revoke_pal_authorization() -> void:
	pal_authorized = false


## Evaluates DEFCON transitions based on tension score, losses, and strategic events
func _evaluate_defcon_transition(reason: String) -> void:
	var target_defcon := 5
	if tension_score >= 88.0:
		target_defcon = 1
	elif tension_score >= 68.0:
		target_defcon = 2
	elif tension_score >= 44.0:
		target_defcon = 3
	elif tension_score >= 18.0:
		target_defcon = 4

	if target_defcon != current_defcon:
		var old := current_defcon
		current_defcon = target_defcon
		defcon_changed.emit(old, current_defcon, reason)


## Regular step function called by SimServer to evaluate world state dynamics
func step(state: WorldState, dt: float) -> void:
	if state == null:
		return

	# Compute aggregate metrics from WorldState
	var total_losses := state.blue_lost_musd + state.red_lost_musd
	var total_kia := state.blue_personnel_kia + state.red_personnel_kia

	var computed_tension := 10.0
	computed_tension += total_losses * 0.003
	computed_tension += float(total_kia) * 0.012

	if total_losses >= loss_threshold_defcon_1 or total_kia >= casualty_threshold_defcon_1:
		computed_tension = maxf(computed_tension, 90.0)
	elif total_losses >= loss_threshold_defcon_2 or total_kia >= casualty_threshold_defcon_2:
		computed_tension = maxf(computed_tension, 70.0)
	elif total_losses >= loss_threshold_defcon_3 or total_kia >= casualty_threshold_defcon_3:
		computed_tension = maxf(computed_tension, 48.0)
	elif total_losses >= loss_threshold_defcon_4 or total_kia >= casualty_threshold_defcon_4:
		computed_tension = maxf(computed_tension, 24.0)

	if state.nuclear_detonations_count > 0:
		computed_tension = 100.0
	elif state.cbrn_strikes_count > 0 or state.hemp_emp_strikes_count > 0:
		computed_tension = maxf(computed_tension, 75.0)
	elif state.asat_intercepts_count > 0:
		computed_tension = maxf(computed_tension, 52.0)

	# Factor in warning flags
	for f in warning_flags:
		if warning_flags[f]:
			computed_tension += 3.5

	# Smoothly blend tension score
	var alpha := clampf(dt * 0.5, 0.02, 1.0)
	var new_score := lerpf(tension_score, computed_tension, alpha)
	set_tension_score(new_score, "World state step update")

	# Keep world_state in sync
	state.defcon_level = current_defcon
	state.global_escalation_score = tension_score

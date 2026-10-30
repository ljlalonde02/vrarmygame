class_name WeatherSolarSystem
extends RefCounted
## Phase 24 — Dynamic Weather, Day/Night Solar Terminator & Sea-State Physics (`WeatherSolarSystem`).
## Simulates theater-specific meteorology (`CLEAR`, `OVERCAST`, `TYPHOON_STORM`, `SANDSTORM`, `ARCTIC_BLIZZARD`),
## Beaufort Sea State (`1..9`), and the 24-hour UTC Solar Terminator cycle.
## Physically modifies:
## - `weather_ir_eo_mult`: Clouds, rain, sandstorms, and blizzards attenuate `IR_EO` / FLIR sensors while `ACTIVE_RADAR` & `SAT_SAR_EO` penetrate clouds.
## - `weather_laser_mult`: Rain, dust, and cloud water vapor scatter 100kW Iron Beam high-energy lasers (`de_kw`), while 30° HPM microwave cones (`Leonidas`) are unaffected by rain/clouds.
## - `weather_usv_speed_mult`: High Beaufort sea states (`Beaufort 6–9`) slow small surface kamikaze USVs (`MAGURA V5`, `Sea Baby`), while submerged `Orca XLUUV` submarines are immune.
## - `wind_vec_km_s`: Storms accelerate wind-advected CBRN / Nuclear fallout plumes across the theater.

const WEATHER_PRESETS := {
	"CLEAR": {
		"display": "CLEAR SKIES // BEAUFORT 2",
		"cloud": 0.12,
		"precip": 0.0,
		"beaufort": 2,
		"ir_mult": 1.00,
		"laser_mult": 1.00,
		"usv_mult": 1.00,
		"air_mult": 1.00,
		"wind_km_s": Vector2(0.38, 0.16),
	},
	"OVERCAST": {
		"display": "HEAVY MONSOON CLOUD DECK // BEAUFORT 4",
		"cloud": 0.68,
		"precip": 0.35,
		"beaufort": 4,
		"ir_mult": 0.68,
		"laser_mult": 0.62,
		"usv_mult": 0.88,
		"air_mult": 0.94,
		"wind_km_s": Vector2(0.62, 0.28),
	},
	"TYPHOON_STORM": {
		"display": "CATEGORY-4 SUPER TYPHOON // BEAUFORT 8",
		"cloud": 0.96,
		"precip": 0.92,
		"beaufort": 8,
		"ir_mult": 0.38,
		"laser_mult": 0.28,
		"usv_mult": 0.52,
		"air_mult": 0.78,
		"wind_km_s": Vector2(1.15, 0.65),
	},
	"SANDSTORM": {
		"display": "HABOOB SILICA SANDSTORM // BEAUFORT 6",
		"cloud": 0.85,
		"precip": 0.75,
		"beaufort": 6,
		"ir_mult": 0.32,
		"laser_mult": 0.25,
		"usv_mult": 0.78,
		"air_mult": 0.82,
		"wind_km_s": Vector2(0.95, -0.42),
	},
	"ARCTIC_BLIZZARD": {
		"display": "HIGH-ALTITUDE WHITE-OUT BLIZZARD // BEAUFORT 7",
		"cloud": 0.90,
		"precip": 0.84,
		"beaufort": 7,
		"ir_mult": 0.42,
		"laser_mult": 0.34,
		"usv_mult": 0.65,
		"air_mult": 0.80,
		"wind_km_s": Vector2(0.88, 0.54),
	},
}

const WEATHER_CYCLE_ORDER := [
	"CLEAR",
	"OVERCAST",
	"TYPHOON_STORM",
	"SANDSTORM",
	"ARCTIC_BLIZZARD",
]


static func initialize_theater_weather(state: WorldState, theater_slug: String = "") -> void:
	var default_code := "CLEAR"
	if theater_slug.find("hormuz") != -1:
		default_code = "CLEAR"
	elif theater_slug.find("himalaya") != -1:
		default_code = "OVERCAST"
	set_weather_condition(state, default_code, false)


static func set_weather_condition(state: WorldState, weather_code: String, emit_event: bool = true) -> Dictionary:
	var code := weather_code if WEATHER_PRESETS.has(weather_code) else "CLEAR"
	var p: Dictionary = WEATHER_PRESETS[code]
	state.weather_condition_code = code
	state.weather_cloud_cover = float(p.get("cloud", 0.15))
	state.weather_precip_intensity = float(p.get("precip", 0.0))
	state.sea_state_beaufort = int(p.get("beaufort", 2))
	state.weather_ir_eo_mult = float(p.get("ir_mult", 1.0))
	state.weather_laser_mult = float(p.get("laser_mult", 1.0))
	state.weather_usv_speed_mult = float(p.get("usv_mult", 1.0))
	state.weather_air_sortie_mult = float(p.get("air_mult", 1.0))
	state.wind_vec_km_s = p.get("wind_km_s", Vector2(0.42, 0.18))
	if emit_event:
		state.weather_changes_count += 1
		state.sim_events_queue.append({
			"type": "WEATHER_CHANGED",
			"weather_code": code,
			"sea_state": state.sea_state_beaufort,
			"solar_hour": state.solar_hour_utc,
			"ir_mult": state.weather_ir_eo_mult,
			"laser_mult": state.weather_laser_mult,
		})
	return p


static func cycle_weather_condition(state: WorldState) -> String:
	var cur_idx := WEATHER_CYCLE_ORDER.find(state.weather_condition_code)
	var next_idx := (cur_idx + 1) % WEATHER_CYCLE_ORDER.size()
	var next_code: String = WEATHER_CYCLE_ORDER[next_idx]
	set_weather_condition(state, next_code, true)
	return next_code


static func step(state: WorldState, dt: float) -> void:
	# Advance 24-hour UTC Solar Terminator (1 sim hour per 120 sim seconds so day/night transitions are visible)
	state.solar_hour_utc = fposmod(state.solar_hour_utc + (dt / 120.0), 24.0)
	state.is_night_cycle = (state.solar_hour_utc < 6.0 or state.solar_hour_utc >= 19.5)

	# Dynamic weather evolution every ~180 sim seconds if left on automatic progression
	var prev_bucket := int((state.sim_time_sec - dt) / 180.0)
	var cur_bucket := int(state.sim_time_sec / 180.0)
	if cur_bucket > prev_bucket and state.sim_time_sec > 10.0:
		var t_slug := state.active_theater_slug
		if state.weather_condition_code == "CLEAR":
			if t_slug.find("hormuz") != -1 or t_slug.find("mexico") != -1:
				set_weather_condition(state, "SANDSTORM", true)
			elif t_slug.find("himalaya") != -1 or t_slug.find("baltic") != -1:
				set_weather_condition(state, "ARCTIC_BLIZZARD", true)
			else:
				set_weather_condition(state, "TYPHOON_STORM", true)
		else:
			set_weather_condition(state, "CLEAR", true)


static func get_weather_hud_summary(state: WorldState) -> String:
	var hr := int(state.solar_hour_utc)
	var mn := int(fposmod(state.solar_hour_utc * 60.0, 60.0))
	var dn_tag := "NIGHT" if state.is_night_cycle else "DAY"
	return "WX: %s | SEA: BFT-%d | %02d:%02dZ (%s) | IR:%.0f%% LSR:%.0f%% USV:%.0f%%" % [
		state.weather_condition_code,
		state.sea_state_beaufort,
		hr, mn, dn_tag,
		state.weather_ir_eo_mult * 100.0,
		state.weather_laser_mult * 100.0,
		state.weather_usv_speed_mult * 100.0,
	]

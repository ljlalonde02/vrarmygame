class_name BunkerRadioSynth
extends Node
## Pleasant, Rate-Limited Military Bunker Audio & Male/Female Officer Formant Voice Synthesizer (`AudioStreamGenerator`).
## - Eliminates harsh high-frequency sine beeps and unthrottled combat audio spam:
##   - Uses warm low-pass filtered frequencies (< 480 Hz for tactile clicks & distant muffled ordnance)
##   - Enforces strict cooldowns (3.2s between background combat thumps, 3.5s between voice transmissions)
##   - Supports instant Mute/Unmute (`toggle_audio_mute()` / `[M]` hotkey)
## - Synthesizes distinct **Male (`100–115 Hz` Baritone) & Female (`188–215 Hz` Alto/Mezzo) Military Officer Voices**
##   using multi-syllable vowel formant modulation (F0 + F1 + F2 harmonics with soft cosine envelopes & PTT mic click).

const MIX_RATE := 22050.0

const OFFICER_ROSTER := {
	"FEMALE_AWACS": {
		"id": "FEMALE_AWACS",
		"callsign": "CAPT. ELENA ROSTOVA (AWACS MAGIC 1-1 // FEMALE)",
		"gender": "FEMALE",
		"f0_hz": 212.0,
		"f1_hz": 680.0,
		"f2_hz": 1560.0,
	},
	"MALE_J3_OPS": {
		"id": "MALE_J3_OPS",
		"callsign": "COL. MARCUS VANCE (J3 OPERATIONS // MALE)",
		"gender": "MALE",
		"f0_hz": 114.0,
		"f1_hz": 490.0,
		"f2_hz": 1120.0,
	},
	"FEMALE_STRATCOM": {
		"id": "FEMALE_STRATCOM",
		"callsign": "GEN. VICTORIA STERLING (STRATCOM // FEMALE)",
		"gender": "FEMALE",
		"f0_hz": 188.0,
		"f1_hz": 610.0,
		"f2_hz": 1420.0,
	},
	"MALE_BUNKER_SEC": {
		"id": "MALE_BUNKER_SEC",
		"callsign": "LT. COL. VIKTOR KOVALENKO (BUNKER SECURITY // MALE)",
		"gender": "MALE",
		"f0_hz": 98.0,
		"f1_hz": 440.0,
		"f2_hz": 980.0,
	},
}

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _active_tones: Array[Dictionary] = []
var _phase_f0: float = 0.0
var _phase_f1: float = 0.0
var _phase_f2: float = 0.0
var _lp_prev: float = 0.0

var audio_muted: bool = false
var use_os_tts_when_available: bool = false
var synth_triggers_count: int = 0
var voice_transmissions_count: int = 0
var male_voice_count: int = 0
var female_voice_count: int = 0
var last_officer_id: String = "FEMALE_AWACS"
var last_officer_callsign: String = "CAPT. ELENA ROSTOVA (AWACS MAGIC 1-1 // FEMALE)"
var last_officer_gender: String = "FEMALE"
var last_officer_transcript: String = "Command Bunker C4ISR links online. All 7 global flashpoint sensors nominal."

var _last_combat_sfx_msec: int = -10000
var _last_ui_sfx_msec: int = -10000
var _last_voice_msec: int = -10000
var _voice_turn_index: int = 0


func _ready() -> void:
	if _player != null:
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.18

	_player = AudioStreamPlayer.new()
	_player.name = "ProceduralRadioPlayer"
	_player.stream = gen
	_player.volume_db = -15.0 # Warm, comfortable background level
	add_child(_player)

	if AudioServer.get_driver_name() != "Dummy":
		_player.play()
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

	var sig_bus: Node = get_node_or_null("/root/SignalBus") if is_inside_tree() else null
	_connect_signals(sig_bus)


func bind_signal_bus(sig_bus: Node) -> void:
	_connect_signals(sig_bus)


func _connect_signals(sig_bus: Node) -> void:
	if sig_bus == null:
		return
	if not sig_bus.unit_selected.is_connected(_on_unit_selected):
		sig_bus.unit_selected.connect(_on_unit_selected)
	if not sig_bus.alpha_strike_committed.is_connected(_on_alpha_strike_committed):
		sig_bus.alpha_strike_committed.connect(_on_alpha_strike_committed)
	if not sig_bus.salvo_launched.is_connected(_on_salvo_launched):
		sig_bus.salvo_launched.connect(_on_salvo_launched)
	if not sig_bus.directed_energy_fired.is_connected(_on_de_fired):
		sig_bus.directed_energy_fired.connect(_on_de_fired)
	if not sig_bus.unmanned_deployed.is_connected(_on_unmanned_deployed):
		sig_bus.unmanned_deployed.connect(_on_unmanned_deployed)
	if not sig_bus.frago_received.is_connected(_on_frago_received):
		sig_bus.frago_received.connect(_on_frago_received)
	if not sig_bus.defcon_changed.is_connected(_on_defcon_changed):
		sig_bus.defcon_changed.connect(_on_defcon_changed)
	if not sig_bus.tech_unlocked.is_connected(_on_tech_unlocked):
		sig_bus.tech_unlocked.connect(_on_tech_unlocked)
	if not sig_bus.strategic_wmd_detonated.is_connected(_on_wmd_detonated):
		sig_bus.strategic_wmd_detonated.connect(_on_wmd_detonated)
	if not sig_bus.bunker_relocated.is_connected(_on_bunker_relocated):
		sig_bus.bunker_relocated.connect(_on_bunker_relocated)
	if not sig_bus.bunker_game_over.is_connected(_on_bunker_game_over):
		sig_bus.bunker_game_over.connect(_on_bunker_game_over)
	if not sig_bus.war_news_video_broadcasted.is_connected(_on_war_news_video_broadcasted):
		sig_bus.war_news_video_broadcasted.connect(_on_war_news_video_broadcasted)


func _on_unit_selected(_u: int, _p: int, _f: int) -> void:
	play_ui_chirp()


func _on_alpha_strike_committed(_f: int, total_launched: int) -> void:
	play_alpha_strike_klaxon()
	speak_officer_transmission(
		"MALE_J3_OPS",
		"Alpha Strike package committed! %d standoff munitions airborne on coordinated Time-On-Target vectors." % maxi(1, total_launched),
		true
	)


func _on_salvo_launched(_a: int, _t: int, _w: int, _p: Vector3) -> void:
	play_missile_launch_thump()


func _on_de_fired(_s: int, _p: Vector3, is_hpm: bool, _kw: float) -> void:
	play_directed_energy_pulse(is_hpm)


func _on_unmanned_deployed(_pu: int, _cu: int, _sp: int, _p: Vector3) -> void:
	play_servo_deploy_chirp()
	speak_officer_transmission(
		"FEMALE_AWACS",
		"Autonomous Quadruped Robot Dog pack and fiber-optic FPV swarm deployed to forward sector.",
		false
	)


func _on_frago_received(headline: String, _body: String) -> void:
	var off_id := "FEMALE_AWACS" if (_voice_turn_index % 2 == 0) else "MALE_J3_OPS"
	_voice_turn_index += 1
	speak_officer_transmission(off_id, headline, false)


func _on_defcon_changed(new_defcon: int, _esc: float, _decl: String) -> void:
	play_alpha_strike_klaxon()
	var off_id := "FEMALE_STRATCOM" if (new_defcon % 2 == 1) else "MALE_J3_OPS"
	speak_officer_transmission(
		off_id,
		"Attention in the Command Bunker! National Command Authority has transitioned theater readiness to DEFCON %d!" % new_defcon,
		true
	)


func _on_tech_unlocked(fac: int, _slug: String, dname: String, _rem: float) -> void:
	if fac == 1:
		speak_officer_transmission(
			"FEMALE_AWACS",
			"DARPA R&D breakthrough confirmed: %s is now operational across all theater forces." % dname,
			false
		)


func _on_wmd_detonated(wmd_type: String, _fac: int, _pos: Vector3, yield_kt: float) -> void:
	play_alpha_strike_klaxon()
	speak_officer_transmission(
		"FEMALE_STRATCOM",
		"FLASH OVERRIDE! Strategic %s detonation detected—yield %.0f kilotons! Brace for electromagnetic and seismic shockwave!" % [wmd_type, yield_kt],
		true
	)


func _on_bunker_relocated(new_name: String, _pos: Vector3, _cnt: int) -> void:
	speak_officer_transmission(
		"MALE_BUNKER_SEC",
		"Command Bunker C4ISR handoff complete. Operations transferred to %s." % new_name,
		true
	)


func _on_bunker_game_over(reason: String, _captured: bool) -> void:
	play_alpha_strike_klaxon()
	speak_officer_transmission(
		"MALE_BUNKER_SEC",
		"MAYDAY! MAYDAY! %s! Zeroizing cryptographic keys—Command Bunker lost!" % reason,
		true
	)


func _on_war_news_video_broadcasted(_clip_slug: String, network: String, headline: String, _sub: String, _corr: String, defcon_lvl: int) -> void:
	var off_id := "FEMALE_AWACS" if (_voice_turn_index % 2 == 0) else "MALE_J3_OPS"
	_voice_turn_index += 1
	speak_officer_transmission(
		off_id,
		"[%s // DEFCON %d] %s" % [network, defcon_lvl, headline],
		defcon_lvl <= 2
	)


func toggle_audio_mute() -> bool:
	audio_muted = not audio_muted
	if _player != null:
		_player.stream_paused = audio_muted
	return audio_muted


## Synthesizes a realistic Male or Female Military Officer radio transmission using multi-syllable vowel formants.
func speak_officer_transmission(officer_id: String, transcript: String, force_priority: bool = false) -> Dictionary:
	var profile: Dictionary = OFFICER_ROSTER.get(officer_id, OFFICER_ROSTER["FEMALE_AWACS"])
	last_officer_id = String(profile["id"])
	last_officer_callsign = String(profile["callsign"])
	last_officer_gender = String(profile["gender"])
	last_officer_transcript = transcript
	voice_transmissions_count += 1
	synth_triggers_count += 1
	if last_officer_gender == "MALE":
		male_voice_count += 1
	else:
		female_voice_count += 1

	var sig_bus: Node = get_node_or_null("/root/SignalBus") if is_inside_tree() else null
	if sig_bus != null:
		sig_bus.officer_radio_spoke.emit(last_officer_id, last_officer_callsign, last_officer_gender, transcript)

	var now_ms := Time.get_ticks_msec()
	if not force_priority and (now_ms - _last_voice_msec < 3500):
		return profile
	_last_voice_msec = now_ms

	if audio_muted:
		return profile

	if force_priority and _active_tones.size() > 2:
		_active_tones.clear()

	var f0 := float(profile["f0_hz"])
	var f1 := float(profile["f1_hz"])
	var f2 := float(profile["f2_hz"])

	# Subtle 12ms Push-To-Talk (PTT) radio mic key click (warm 380 Hz)
	_queue_formant_syllable(380.0, 420.0, 900.0, 900.0, 0.015, 0.08, true)

	# Generate 6 pleasant formant syllables modulated by transcript character hashes
	var words := transcript.split(" ", false)
	var num_syllables := clampi(words.size(), 4, 7)
	for i in range(num_syllables):
		var w_hash: int = words[i % words.size()].hash()
		var pitch_infl := 1.0 + float((w_hash % 17) - 8) * 0.012
		if i == num_syllables - 1:
			pitch_infl *= 0.90 # Natural downward sentence cadence at end of transmission
		var vow_f1 := f1 * (0.85 + float(abs(w_hash) % 5) * 0.07)
		var vow_f2 := f2 * (0.88 + float((abs(w_hash) >> 3) % 5) * 0.06)
		var syl_dur := 0.065 + float(abs(w_hash) % 3) * 0.018
		_queue_formant_syllable(f0 * pitch_infl, f0 * pitch_infl * 0.97, vow_f1, vow_f2, syl_dur, 0.14, false)

	# Subtle 10ms PTT mic release click
	_queue_formant_syllable(310.0, 260.0, 750.0, 750.0, 0.012, 0.06, true)
	return profile


func play_switch_clunk() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	_queue_tone(125.0, 68.0, 0.045, 0.16, false)


func play_ui_chirp() -> void:
	synth_triggers_count += 1
	var now_ms := Time.get_ticks_msec()
	if audio_muted or (now_ms - _last_ui_sfx_msec < 260):
		return
	_last_ui_sfx_msec = now_ms
	# Soft, warm low-mid tactile confirmation pulse (320 -> 390 Hz) instead of piercing 1680 Hz beep
	_queue_tone(320.0, 390.0, 0.035, 0.09, false)


func play_missile_launch_thump() -> void:
	synth_triggers_count += 1
	var now_ms := Time.get_ticks_msec()
	if audio_muted or (now_ms - _last_combat_sfx_msec < 3200):
		return
	_last_combat_sfx_msec = now_ms
	# Deep muffled distant launch thump (85 -> 38 Hz)
	_queue_tone(85.0, 38.0, 0.11, 0.18, true)


func play_directed_energy_pulse(is_hpm: bool) -> void:
	synth_triggers_count += 1
	var now_ms := Time.get_ticks_msec()
	if audio_muted or (now_ms - _last_combat_sfx_msec < 3200):
		return
	_last_combat_sfx_msec = now_ms
	if is_hpm:
		_queue_tone(180.0, 72.0, 0.10, 0.14, false)
	else:
		_queue_tone(290.0, 210.0, 0.07, 0.10, false)


func play_servo_deploy_chirp() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	_queue_tone(240.0, 340.0, 0.07, 0.12, false)


func play_alpha_strike_klaxon() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	# Warm low-brass submarine/bunker klaxon chord (220 -> 165 Hz) instead of shrill 880 Hz siren
	_queue_tone(220.0, 165.0, 0.22, 0.20, false)


func play_radio_squelch() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	_queue_tone(340.0, 280.0, 0.05, 0.08, true)


## Sprint 8: Resonant underwater acoustic sonar ping
func play_submarine_sonar_ping() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	# Pure resonant acoustic ocean chime: 580 Hz with long clean sine decay
	_queue_tone(580.0, 560.0, 0.45, 0.18, false)


## Sprint 8: Muffled 120mm APFSDS tank cannon report with low-frequency bunker resonance
func play_tank_cannon_apfsds() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	# Heavy kinetic thump (95 -> 38 Hz) with explosive transient
	_queue_tone(95.0, 38.0, 0.14, 0.24, true)


## Sprint 8: Low-frequency pulsing DEFCON emergency siren
func play_defcon_alarm_pulse() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	_queue_tone(175.0, 135.0, 0.35, 0.16, false)


## Sprint 8: Tactical posture actuation C2 relay chirp
func play_tactical_posture_actuate() -> void:
	synth_triggers_count += 1
	if audio_muted:
		return
	_queue_tone(360.0, 460.0, 0.045, 0.12, false)


func _queue_tone(freq_start: float, freq_end: float, duration_sec: float, amp: float, add_noise: bool) -> void:
	if _active_tones.size() < 10:
		_active_tones.append({
			"f0": freq_start,
			"f1": freq_end,
			"formant_1": 0.0,
			"formant_2": 0.0,
			"dur": duration_sec,
			"elapsed": 0.0,
			"amp": amp,
			"noise": add_noise,
		})


func _queue_formant_syllable(f0_start: float, f0_end: float, form1_hz: float, form2_hz: float, duration_sec: float, amp: float, add_noise: bool) -> void:
	if _active_tones.size() < 16:
		_active_tones.append({
			"f0": f0_start,
			"f1": f0_end,
			"formant_1": form1_hz,
			"formant_2": form2_hz,
			"dur": duration_sec,
			"elapsed": 0.0,
			"amp": amp,
			"noise": add_noise,
		})


func _process(_delta: float) -> void:
	if _playback == null or audio_muted:
		_active_tones.clear()
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return

	var inv_rate := 1.0 / MIX_RATE
	for _i in range(frames):
		var raw_sample := 0.0
		if not _active_tones.is_empty():
			var t_entry: Dictionary = _active_tones[0]
			var el: float = float(t_entry["elapsed"])
			var dur: float = maxf(0.01, float(t_entry["dur"]))
			var prog := clampf(el / dur, 0.0, 1.0)
			# Smooth raised-cosine window envelope (zero click at start & end)
			var env := sin(prog * PI)
			var freq := lerpf(float(t_entry["f0"]), float(t_entry["f1"]), prog)
			_phase_f0 = fmod(_phase_f0 + freq * inv_rate, 1.0)

			var fm1: float = float(t_entry.get("formant_1", 0.0))
			var fm2: float = float(t_entry.get("formant_2", 0.0))
			if fm1 > 50.0:
				_phase_f1 = fmod(_phase_f1 + fm1 * inv_rate, 1.0)
				_phase_f2 = fmod(_phase_f2 + fm2 * inv_rate, 1.0)
				# Glottal pulse + vowel formants (F1 & F2) for human vocal tract timbre
				var glottal := sin(_phase_f0 * TAU) + 0.45 * sin(_phase_f0 * TAU * 2.0)
				var tract := 0.55 * sin(_phase_f1 * TAU) + 0.28 * sin(_phase_f2 * TAU)
				raw_sample = (glottal * 0.55 + tract * 0.45) * float(t_entry["amp"]) * env
			else:
				raw_sample = sin(_phase_f0 * TAU) * float(t_entry["amp"]) * env

			if bool(t_entry["noise"]):
				raw_sample += (randf() * 2.0 - 1.0) * 0.04 * env

			t_entry["elapsed"] = el + inv_rate
			if el + inv_rate >= dur:
				_active_tones.pop_front()

		# Warm 1-pole low-pass smoothing filter to remove any harsh high-frequency edge
		_lp_prev = _lp_prev + 0.28 * (raw_sample - _lp_prev)
		_playback.push_frame(Vector2(_lp_prev, _lp_prev))

# SAFe PI-20 Sprint 20 Specification
## Commander First-Hour Ready-to-Play Polish, Keyboard Flow, Tactical Audio Synthesis & Multi-Domain Visual Cues

**Sprint**: Sprint 20 (Program Increment 20)  
**Methodology**: Scaled Agile Framework (SAFe) + Stanford Design Studio  
**Target Architecture**: Godot 4.7.2 Forward Mobile // NVIDIA GeForce RTX 4060 Ti  
**Platform Scope**: Pure Diegetic VR Holographic War Table (DEFCON Modern VR Wargame)

---

## 1. Executive Summary & Problem Statement
With deep simulation mechanics, naval bathymetric routing, real-world named cities, and low-poly 3D platform silhouettes in place, this sprint is laser-focused on the user's explicit directive: ensuring the wargame is in a 100% playable, intuitive, and enjoyable state for immediate hands-on playtesting by a new user. 

Key challenges addressed in Sprint 20:
1. **Modal Ergonomics & Keyboard Accessibility (`WelcomeOnboardingController`)**:
   - First-time players on Desktop need immediate keyboard navigation from the briefing modal without being forced to click UI buttons.
   - Added instant shortcut handlers: `[ESC]` / `[ENTER]` / `[SPACE]` to dismiss briefing and enter the war room, `[H]` to launch the 5-step bootcamp tutorial, and `[P]` to open the global campaign selector.
   - Enforced viewport safety guards to ensure robust operation in both headless test runners and live graphics window viewports.
2. **Tactile Audio Synthesis & Combat Feedback (`BunkerRadioSynth`)**:
   - Synthesized real-time Radar Warning Receiver (RWR) threat lock alert tones (pulsed 850 Hz - 920 Hz audio chirps) when designating hostile contacts.
   - Synthesized low-frequency hypersonic waverider Mach booms (180 Hz -> 42 Hz explosive shockwave crack) when Mach 5+ missiles cross the sound barrier.
   - Synthesized tactile posture actuation clicks for unit selections, waypoint moves, and strike assignments.
3. **Multi-Domain Munition Differentiation (`VisualSyncController`)**:
   - Fully partitioned munition rendering into 5 dedicated high-performance MultiMesh layers: 155mm Artillery Shells (`artillery_mmi`), Cruise Missiles (`cruise_mmi`), Ballistic Missiles / MRBMs (`ballistic_mmi`), Loitering Drones (`drone_mmi`), and Hypersonic Waveriders (`hypersonic_mmi`).
   - Mapped explicit `HYPERSONIC_GLIDE` flight profile in `WorldState`.
4. **End-to-End Quality Gates & Visual Verification**:
   - `tests/test_sprint20_features.gd` (13/13 PASS, 100%).
   - Regression suites: `tests/test_sprint19_features.gd` (30/30 PASS, 100%), `tests/test_sprint18_features.gd` (46/46 PASS, 100%), and Gate 4 Full Game Boot (`test_full_game_boot.gd`) (PASS with 0 errors).
   - Rendered 4 HD stills and 4 60fps animated GIFs on the RTX 4060 Ti GPU, visually inspected via `view_file`.

---

## 2. User Stories & Acceptance Criteria

### US-20.1: Welcome Onboarding Modal Keyboard Navigation
- **Description**: Enable intuitive keyboard control of the first-time welcome briefing modal.
- **Acceptance Criteria**:
  * Pressing `[ESC]`, `[ENTER]`, or `[SPACE]` dismisses the briefing and emits `welcome_dismissed`.
  * Pressing `[H]` launches the 5-step bootcamp tutorial and emits `start_tutorial_requested`.
  * Pressing `[P]` opens the campaign theater picker and emits `open_campaign_requested`.
  * Event consumption calls `get_viewport().set_input_as_handled()` with null-safety checks.

### US-20.2: Tactical Audio Synthesis (RWR Threat Lock & Hypersonic Mach Boom)
- **Description**: Synthesize warm, rate-limited audio cues for radar lock-on and hypersonic transitions.
- **Acceptance Criteria**:
  * `BunkerRadioSynth.play_rwr_threat_lock_tone()` generates rapid pulsed 850-920 Hz threat alert tones.
  * `BunkerRadioSynth.play_hypersonic_mach_boom()` produces low-frequency subterranean rumble and Mach crack.
  * Audio triggers increment `synth_triggers_count` and respect `audio_muted`.

### US-20.3: Desktop Rig Tactile Audio Feedback on Selection & Orders
- **Description**: Every player action must produce immediate audio-tactical confirmation.
- **Acceptance Criteria**:
  * Selecting a friendly unit plays `play_tactical_posture_actuate()`.
  * Selecting/designating a hostile enemy unit plays `play_rwr_threat_lock_tone()`.
  * Issuing move waypoints or attack vectors plays `play_tactical_posture_actuate()`.

### US-20.4: Specialized Munitions MultiMesh Partitioning
- **Description**: Five distinct classes of munitions render with unique geometries and flight dynamics.
- **Acceptance Criteria**:
  * Class 1: 155mm Artillery Shells.
  * Class 2: Low-altitude Sea-skimming Cruise Missiles.
  * Class 3: Stratospheric/Mesospheric Ballistic Missiles / MRBMs.
  * Class 4: Low-altitude Loitering Kamikaze Drones.
  * Class 5: Extreme-speed Hypersonic Waveriders.
  * All 5 classes sync to dedicated MultiMesh instances without draw call overhead.

### US-20.5: End-to-End Ready-to-Play Verification
- **Description**: The wargame must boot cleanly into a fully functional, welcoming state.
- **Acceptance Criteria**:
  * Physical 3D gold `QuickControlsPlaque3D` visible on the front table bezel.
  * Dual-rig support verified (flatscreen desktop + OpenXR VR).
  * 100% test pass rate across all suites with zero regressions.

---

## 3. Verification Summary Matrix

| Test Suite | Tests | Result | Status |
| :--- | :--- | :--- | :--- |
| `tests/test_sprint20_features.gd` | 13 / 13 | 100% | PASS |
| `tests/test_sprint19_features.gd` | 30 / 30 | 100% | PASS |
| `tests/test_sprint18_features.gd` | 46 / 46 | 100% | PASS |
| `tests/test_full_game_boot.gd` (Gate 4) | 6 / 6 phases | 100% | PASS |

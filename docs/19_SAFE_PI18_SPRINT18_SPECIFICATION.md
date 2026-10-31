# SAFe PI-18 Sprint 18 Specification
## Commander First-Time Onboarding UX, Interactive Bootcamp Flow & 3D Table Controls Plaque

**Sprint**: Sprint 18 (Program Increment 18)  
**Methodology**: Scaled Agile Framework (SAFe) + Stanford Design Studio  
**Target Architecture**: Godot 4.7.2 Forward Mobile // NVIDIA GeForce RTX 4060 Ti  
**Platform Scope**: Pure Diegetic VR Holographic War Table (DEFCON Modern VR Wargame)

---

## 1. Executive Summary & Problem Statement
With deep multi-domain combat systems, realistic parabolic ballistics, electronic warfare countermeasures, and doctrinal military maneuvers complete, user testing reveals that first-time commanders booting the wargame for the first time face an overwhelming initial cognitive load. Booting directly into a chaotic theater with 600+ moving military tokens without immediate onboarding context or visible control directives creates friction and confusion.

Sprint 18 resolves this by delivering an intuitive, welcoming, polished onboarding experience:
1. **Welcome Onboarding Briefing Dialog (`WelcomeOnboardingController`)**:
   - Presents an immediate, high-contrast, tactical briefing modal on startup for flatscreen PC and OpenXR VR.
   - Explains the multi-domain scale (2,000 km theater, 500km strategic to 15km mountain passes).
   - Details full dual-rig controls (Desktop mouse/keyboard directives and OpenXR VR natural hand gestures).
   - Provides 1-click action buttons: `[★ START BOOTCAMP TUTORIAL]`, `[🚀 ENTER WAR ROOM]`, `[🌐 CAMPAIGN & THEATERS]`, and `[📖 FIELD MANUAL]`.
2. **Modal Mutual-Exclusivity Suppression**:
   - Seamless arbitration between `WelcomeOnboardingController`, `BunkerMainMenu`, and `TutorialController`.
   - Opening one automatically closes and suspends the others, preventing visual collision or competing audio.
3. **Interactive 5-Step Bootcamp Progression (`TutorialController`)**:
   - Connects directly to the Welcome modal.
   - Highlights targets with a 3D pulsing holographic target beacon projected onto the War Table.
   - Validates live player actions (e.g. zooming in >= 4.0x, deploying robot dogs, committing strikes) and automatically advances.
4. **Desktop Command Rig [? BRIEFING] Button & 3D War Table Bezel Plaque**:
   - Added persistent `[? BRIEFING & CONTROLS]` button to the top command bar in `DesktopCommandRig`.
   - Cast a physical 3D gold `Label3D` quick-reference controls plaque onto the front bezel of the holographic war table (`COMMAND CONTROLS: [H] BOOTCAMP TUTORIAL • [ESC] MAIN MENU • [SPACE] ALPHA STRIKE • [SCROLL] ZOOM • [DRAG] PAN`), readable from any seated VR or desktop viewpoint.
5. **Adversarial Test Suite & RTX 4060 Ti GPU Verification**:
   - `tests/test_sprint18_features.gd` (46/46 PASS, 100%).
   - Zero regressions across Sprint 17 (25/25 PASS), Sprint 16 (43/43 PASS), and Gate 4 Full Game Boot (PASS).
   - 4 high-definition stills and 4 60fps animated GIFs generated and inspected.

---

## 2. User Stories & Acceptance Criteria

### US-18.1: First-Time Commander Welcome Briefing Modal & Mutual Exclusivity
- **Description**: Add an instant-access tactical onboarding briefing modal that opens on startup and can be recalled anytime.
- **Acceptance Criteria**:
  * `WelcomeOnboardingController` instantiated in `CommandBunker` and presented on initial boot.
  * 2-column layout detailing Theater Doctrine & Mechanics on the left, and Desktop/VR Controls on the right.
  * 4 action buttons emit appropriate signals (`start_tutorial_requested`, `welcome_dismissed`, `open_campaign_requested`, `open_manual_requested`).
  * Mutual-exclusivity logic ensures Welcome Briefing, Main Menu, and Bootcamp Tutorial never collide.

### US-18.2: 5-Step Bootcamp Tutorial Flow & 3D Holo-Beacon
- **Description**: Guided onboarding tutorial with 3D spatial guidance on the war table.
- **Acceptance Criteria**:
  * Step 1: Tactical Zoom & Echelon Scaling with live zoom-level detection.
  * Step 2: 6-Spectrum Sensor Overlays & Integrated Air Defense System.
  * Step 3: Quadruped Robot Dogs & FPV Swarm Carrier Unpacking.
  * Step 4: Wikipedia Real-Photo Recon Intelligence Dossier Inspection.
  * Step 5: Strategic DEFCON Alpha Strike Salvo Execution.
  * Pulsing 3D emerald target cylinder beacon rotates and scales dynamically over focal points.

### US-18.3: Top Command Bar [? BRIEFING] Button & 3D Bezel Controls Plaque
- **Description**: Diegetic and UI control references for immediate user clarity.
- **Acceptance Criteria**:
  * Top command bar in `DesktopCommandRig` includes `[? BRIEFING & CONTROLS]`, toggling the briefing modal.
  * Permanent 3D gold quick-reference controls plaque placed on the front table bezel casing, readable from any viewpoint.

### US-18.4: Automated Test Suite & Visual Proofs on RTX 4060 Ti
- **Description**: Complete adversarial test coverage and visual proof generation.
- **Acceptance Criteria**:
  * `tests/test_sprint18_features.gd` achieves 100% pass rate.
  * Zero regressions across legacy suites and Gate 4.
  * 4 HD PNG stills + 4 60fps animated GIFs validated with `view_file`.

---

## 3. Architecture & File Manifest
- `src/presentation/bunker/welcome_onboarding_controller.gd`: Welcome Onboarding Briefing Dialog component.
- `src/presentation/bunker/command_bunker.gd`: Bunker orchestration, 3D bezel plaque, and modal event routing.
- `src/presentation/rigs/desktop_command_rig.gd`: Top command bar `[? BRIEFING]` button and toggle logic.
- `src/presentation/bunker/bunker_main_menu.gd`: Modal mutual-exclusivity suppression.
- `src/presentation/bunker/tutorial_controller.gd`: Tutorial controller with mutual suppression and 3D beacon.
- `tests/test_sprint18_features.gd`: 46-test automated verification suite.
- `tools/capture_sprint18_media.gd`: GPU-accelerated 4-scenario media capture script.
- `tools/build_sprint18_gifs.py`: 60 FPS animated GIF compilation script.
- `docs/media/sprint18_01_welcome_onboarding_briefing.png` + `_anim.gif`
- `docs/media/sprint18_02_bootcamp_tutorial_interactive_beacon.png` + `_anim.gif`
- `docs/media/sprint18_03_desktop_hud_briefing_top_bar.png` + `_anim.gif`
- `docs/media/sprint18_04_3d_controls_plaque_bunker_view.png` + `_anim.gif`

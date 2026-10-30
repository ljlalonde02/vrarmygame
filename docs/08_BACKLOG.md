# SAFe Program Increment (PI) Backlog & Feature Register
## 2028 Global Theater Wargame Simulator (VR & PC)

> **Governance Model**: All new user requirements are processed through **Design Thinking** (User Empathy, Problem Definition, Ideation, User Story, Acceptance Criteria) and registered into this SAFe Backlog. Implementation, test writing, and continuous integration loops are executed by the **Autonomous AI Engineering Studio Swarm** (DeepSeek 4.1 Flash multi-agent swarm).

---

## 1. Feature Prioritization Matrix (WSJF - Weighted Shortest Job First)

| Feature ID | Title | Business Value | Time Criticality | RRoE (Risk Red.) | Job Size | **WSJF Score** | Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **FEAT-01** | SSBN Submarine Station & Periscope VR Stance | 9 | 8 | 8 | 5 | **5.00** | `VERIFIED_PASS` |
| **FEAT-02** | Room-Scale Holo-Floor Walkable Battle Table ($y = 0.02\text{ m}$) | 9 | 9 | 7 | 4 | **6.25** | `VERIFIED_PASS` |
| **FEAT-03** | Virtual Smartwatch & C4ISR Wrist Control (Zero Physical Buttons) | 10 | 9 | 9 | 5 | **5.60** | `VERIFIED_PASS` |
| **FEAT-04** | Wikipedia Real-Photo Armory & Recon Dossier | 8 | 7 | 6 | 4 | **5.25** | `VERIFIED_PASS` |
| **FEAT-05** | Swarm Intelligence Flanking & Collaborative Tactics | 10 | 9 | 9 | 5 | **5.60** | `VERIFIED_PASS` |
| **FEAT-06** | **Authoritative Tactical Trials for All 67 Military Platforms** | 10 | 10 | 9 | 6 | **4.83** | `APPROVED_FOR_BUILD` |
| **FEAT-07** | VR Smartwatch Instant Trial Launcher & Arena HUD | 8 | 7 | 6 | 3 | **7.00** | `APPROVED_FOR_BUILD` |
| **FEAT-08** | Bunker Main Menu Tab 9 (67 Tactical Trials Proving Ground) | 9 | 8 | 7 | 4 | **6.00** | `APPROVED_FOR_BUILD` |
| **FEAT-09** | **Sprint 2: DEFCON Escalation System (DEFCON 4 to 1)** | 10 | 9 | 9 | 5 | **5.60** | `DRAFTING` |
| **FEAT-10** | **Sprint 2: Tri-Command Headquarters (Bunker / SSBN / Doomsday Plane)** | 9 | 8 | 8 | 5 | **5.00** | `DRAFTING` |
| **FEAT-11** | **Sprint 2: 2028 Dynamic Geopolitical Backstory & Flashpoint Campaign** | 8 | 8 | 7 | 4 | **5.75** | `DRAFTING` |
| **FEAT-12** | **Sprint 2: Multi-Domain Theater AI & Coordinated Strike Waves** | 10 | 9 | 9 | 6 | **4.67** | `DRAFTING` |

---

## 2. Feature Details & Acceptance Criteria

### FEAT-06: Authoritative Tactical Trials for All 67 Military Platforms
- **Subsystem**: `sim_core/tactics`
- **Target File**: `src/sim_core/systems/unit_tactical_trials_system.gd`
- **User Story**: 
  *As a Theater Commander, I want each of the 67 military units in the game to possess a dedicated tactical mini-mission in an isolated proving ground, so that I can observe its realistic speed, flight/drive envelope, weapons engagement, defensive countermeasures, its signature "special trick" against its nemesis, and its collaborative integration with friendly units.*
- **Acceptance Criteria**:
  1. All 67 discrete platforms in `data/wargame_cache.json` (Air, Land, Sea, C-UAS, Robot Dogs, Carriers, Submarines) have a fully detailed tactical trial entry.
  2. Each trial entry specifies:
     - `title`: French military tactical title.
     - `domain`: `AIR`, `LAND`, `SEA`.
     - `opposing_threat`: Nemesis platform slug.
     - `friendly_partner`: Wingman / cooperative platform slug.
     - `move_act`: Realistic movement profile, supersonic Mach/knots, terrain hugging, or silent running.
     - `fight`: Engagement envelope, BVR lofting, lead pursuit, wire guidance, or top attack.
     - `defend`: Active countermeasures (APS Trophy, chaff/flares, DIRCM, reactive armor, thermal layer diving).
     - `special_trick`: The distinct technical innovation against the enemy category.
     - `friendly_integration`: Swarm datalink (MADL/CEC, buddy lasing, deconfliction).
  3. `setup_trial_scenario(sim_server, platform_slug)` cleanly resets world state, isolates a $50\text{ km} \times 50\text{ km}$ proving arena, and spawns the subject, partner, and threat with realistic vectors and postures.

---

### FEAT-07: VR Smartwatch Instant Trial Launcher
- **Subsystem**: `presentation/vr`
- **Target File**: `src/presentation/rigs/xr_command_rig.gd`
- **User Story**:
  *As a VR Commander inspecting a unit via my virtual wrist smartwatch, I want a dedicated holographic button to immediately load and experience that unit's tactical trial on the War Table.*
- **Acceptance Criteria**:
  1. Smartwatch HUD displays a "LANCER ÉPREUVE TACTIQUE" action when a unit or dossier is inspected.
  2. Triggering the button calls `sim_server.load_unit_trial(platform_slug)`.
  3. Maintains zero physical furniture buttons in the room (interaction via wrist smartwatch or laser pointer).

---

### FEAT-08: Bunker Main Menu Tab 9 (67 Unit Tactical Trials Proving Ground)
- **Subsystem**: `presentation/bunker`
- **Target File**: `src/presentation/bunker/bunker_main_menu.gd`
- **User Story**:
  *As a Commander in the bunker, I want Tab 9 in the main menu to display a browsable, domain-filtered (AIR / LAND / SEA / SWARM) catalog of all 67 tactical trials with one-click deployment.*
- **Acceptance Criteria**:
  1. Tab 9 labeled `9. ÉPREUVES TACTIQUES (67 MISSIONS)` in `BunkerMainMenuModal`.
  2. Domain filter buttons for `ALL`, `AIR`, `LAND`, `SEA`.
  3. Detail panel displays the trial's movements, offensive tactics, defenses, special trick, and friendly integration.
  4. Launch button triggers the trial and closes the modal.

---

### FEAT-09: DEFCON Escalation System (DEFCON 4 to DEFCON 1)
- **Subsystem**: `sim_core/escalation`
- **Target File**: `src/sim_core/systems/escalation_system.gd`
- **User Story**:
  *As a Supreme Commander, I want the wargame to dynamically transition through DEFCON 4 (Hybrid/Cyber), DEFCON 3 (Mobilization/BVR Standoff), DEFCON 2 (Kinetic Strike Packages), and DEFCON 1 (Nuclear Deterrence/PAL Codes), complete with adaptive bunker lighting and audio cues.*
- **Acceptance Criteria**:
  1. Escalation level calculated from casualty thresholds, loss of high-value assets (AWACS, carriers), and missile strikes.
  2. Bunker ambiance shifts color palette: DEFCON 4 (Blue/C4ISR), DEFCON 3 (Intense White), DEFCON 2 (Pulsing Amber), DEFCON 1 (Emergency Red Strobe).
  3. Dynamic Rules of Engagement (ROE) enforced for AI: passive escort in DEFCON 4, self-defense BVR in DEFCON 3, unrestricted deep strike in DEFCON 2.

---

### FEAT-10: Tri-Command Headquarters (Bunker / SSBN / Doomsday Plane)
- **Subsystem**: `presentation/bunker`
- **Target File**: `src/presentation/bunker/bunker_environment.gd`
- **User Story**:
  *As a VR Commander, I want the freedom to lead the war from three distinct realistic headquarters: the Deep Granite Command Bunker, the SSBN Submarine Conn (red alert with periscope), or the E-4B Doomsday Plane (high-altitude pressurized cabin with VLF trailing wire).*
- **Acceptance Criteria**:
  1. Headquarters selector available at campaign start and during emergency relocation (`RELOCATE_HQ`).
  2. Distinct visual atmosphere, ambient soundscape, and viewports for all three command stations.
  3. Seamless transition with zero physical furniture buttons in the room.

---

### FEAT-11: 2028 Dynamic Geopolitical Backstory & Flashpoint Campaign
- **Subsystem**: `sim_core/campaign`
- **Target File**: `src/sim_core/systems/campaign_director.gd`
- **User Story**:
  *As a player, I want an immersive 2028 geopolitical crisis timeline with branching narrative events and breaking news broadcasts that respond to my strategic choices on the War Table.*
- **Acceptance Criteria**:
  1. Narrative chronology covering Pacific Shield (Taiwan Strait / Thomas Shoal) and Suwalki Breach scenarios.
  2. Breaking TV news broadcasts with simulated AI anchor reports triggered upon major escalations.
  3. AAR (After-Action Report) summarizes geopolitical outcomes and diplomatic stability.

---

### FEAT-12: Multi-Domain Theater AI & Coordinated Strike Waves
- **Subsystem**: `sim_core/ai`
- **Target File**: `src/sim_core/systems/theater_ai_system.gd`
- **User Story**:
  *As a General, I want the adversary AI to conduct realistic combined-arms strike packages (cyber disruption -> SEAD -> decoy swarms -> hypersonic cruise missiles) that challenge my defense network.*
- **Acceptance Criteria**:
  1. OPFOR AI organizes attacks in coordinated sequential waves rather than trickle attacks.
  2. Friendly IADS and fighter escorts coordinate automated sensor fusion and deconfliction.
  3. Realistic energy retention, BVR lofting trajectories, and missile evasion behaviors verified.

---

## 3. Definition of Done (DoD) & Mandatory Visual Verification Pipeline

> **Rule Enforced**: No sprint or feature can be closed or marked `VERIFIED_PASS` without visual proof extracted directly from Godot in action. The user must be able to visually verify every User Story and gameplay mechanic from the chat/docs without putting on the VR headset.

### Required Visual Artifacts Per Sprint:
1. **High-Resolution Stills (1080p PNG)**:
   - Captured directly from the Forward Mobile Vulkan renderer (RTX 4060 Ti).
   - Clear visual depiction of each user story (cockpits, tactical table, menus, shaders).
2. **Animated Gameplay Videos/GIFs (60 FPS)**:
   - Dynamic real-time action demonstrating:
     - Real-time physics, trajectories, flight paths, and tactical turns.
     - Missile flyouts, BVR engagement envelopes, and defensive counter-measures.
     - Interactive UI controls (virtual smartwatch, C4ISR holographic panels, periscope).
     - Swarm maneuvers (collaborative flanking, pincer tactics, deconfliction).
3. **Showcase Markdown Document**:
   - Comprehensive sprint report linking every visual still and animated GIF to its corresponding User Story and acceptance criteria.
4. **Git Versioning**:
   - All visual assets committed to `docs/media/` and tracked on the active branch (`feature/aa-defcon-vr-wargame`).

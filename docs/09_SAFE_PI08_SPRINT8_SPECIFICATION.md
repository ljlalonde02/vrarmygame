# SAFe PI 08 — Sprint 8 Specification: 6DOF VR Haptics, Diegetic Spatial Audio, Campaign Progression & CAS Sorties

> **Program Increment**: PI 08  
> **Sprint**: Sprint 8 (Autonomous Engineering Loop)  
> **Target Platform**: Godot 4.7.2 Forward Mobile (OpenXR VR + Desktop 4K)  
> **Target Release Value**: $20 - $30 Commercial AA Strategy / Simulation  
> **Baseline Commit**: `26db75e` (Sprint 7 Verified)

---

## 1. Feature Breakdown & User Stories

### US-8.1: 6DOF VR Controller Raycast & Haptic Actuation for 3D Command Radial
- **Objective**: Allow players in VR (and desktop) to point at the floating 3D Command Radial Menu wedges with their 6DOF laser pointer and actuate posture changes with real-time visual feedback and OpenXR controller haptic vibration.
- **Components**: `src/presentation/war_table/visual_sync_controller.gd`, `src/presentation/vr_rig/vr_rig.gd`, `src/autoloads/command_bus.gd`.
- **Acceptance Criteria**:
  1. Raycast hitting wedge bounds highlights the wedge in bright neon gold.
  2. Trigger press triggers `CommandBus.issue_tactical_posture(uids, posture_id)`.
  3. Triggers haptic pulse on the active hand (`XRServer.get_tracker()` haptic feedback).

### US-8.2: Diegetic Spatial Audio Architecture & Sound Effects
- **Objective**: Deliver authentic 3D positional and environmental sound inside the command bunker and on the war table.
- **Components**: `src/presentation/audio/tactical_audio_controller.gd`.
- **Acceptance Criteria**:
  1. Procedural submarine acoustic sonar ping chime with distance attenuation.
  2. Muffled 120mm APFSDS tank cannon reports with low-frequency bunker room resonance.
  3. Tactical radio squelch comms chatter ("Target locked", "Beachhead fortified").
  4. DEFCON alarm strobes accompanied by pulsing klaxon tone when DEFCON <= 2.

### US-8.3: Dynamic Multi-Act Campaign Progression Loop
- **Objective**: Connect real-time tactical match resolution directly to the 3D Story Tree.
- **Components**: `src/sim_core/world_state.gd`, `src/presentation/war_table/war_table.gd`, `src/presentation/bunker/story_director.gd`.
- **Acceptance Criteria**:
  1. When `match_outcome == "VICTORY"`, current story node is marked completed and downstream nodes are unlocked.
  2. 3D holographic "PROCEED TO CAMPAIGN MAP" button transitions War Table seamlessly into `CAMPAIGN_STORY_TREE` mode.

### US-8.4: Combined Arms Air-Ground Coordination (CAS & SEAD Sorties)
- **Objective**: Coordinated air strikes designed to break ground suppression and neutralize air defenses.
- **Components**: `src/sim_core/systems/salvo_combat_system.gd`, `src/sim_core/systems/unit_tactical_ai_system.gd`.
- **Acceptance Criteria**:
  1. Close Air Support (CAS) strikes reduce friendly unit suppression by 80% and damage suppressing enemies.
  2. SEAD strikes home in on units with `unit_radar_active == 1` and neutralizing radar guidance.

### US-8.5: Adversarial Automated Test Suite & GPU Visual Media
- **Objective**: 100% test coverage with 0 regressions, 4x 1080p stills and 4x 60fps animated GIFs on RTX 4060 Ti GPU.

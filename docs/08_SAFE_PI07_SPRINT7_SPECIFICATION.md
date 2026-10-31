# SAFe PI-07 / Sprint 7 Specification
## Playable Unit Interactions, Vehicle Tactics, 6DOF VR Command Radial, Speed Calibration & End-to-End Match Loop

**Program Increment:** PI-07  
**Sprint:** Sprint 7  
**System Architecture:** Godot 4.7.2 Forward Mobile (.NET / GDScript ECS & SoA)  
**Target Hardware:** NVIDIA GeForce RTX 4060 Ti / Meta Quest 3 VR  

---

### 1. Vision & Executive Mandate

In direct response to gameplay playability reviews and user feedback:
1. **Interactive Multi-Unit Selection & 3D Radial Command Menu (US-701)**:
   - Selecting a friendly unit/group displays a diegetic 3D holographic command radial floating above the unit on the War Table with 5 tactical options: MOVE, ATTACK, PATROL, HOLD/AMBUSH, RETREAT.
   - Selecting an enemy unit designates it as target with an animated 3D red locking reticle and target vectors from friendly units.
   - Zero flat 2D screen obstructions; fully responsive in 6DOF VR motion controllers and desktop mouse/keyboard.

2. **Domain & Vehicle Specific Tactical Behaviors (US-702)**:
   - **Tanks / Armor (M1A2, T-90M)**: Independent turret rotation tracking target azimuth, kinetic APFSDS rounds (~1.7 km/s) with muzzle blast flash, road movement speed bonus vs steep slope penalty.
   - **Attack Helicopters (AH-64, Ka-52)**: Low-altitude Nap-of-the-Earth (50-120m AGL) terrain masking behind hills (blocks line of sight from enemy SAM radars), hovering in combat, direct ATGM salvos.
   - **Infantry Squads**: Dispersed tactical wedge, urban ruins & trench cover (+40% to +50% armor mitigation), assault rifle / machine gun tracer bursts with suppressive fire pinning mechanics.
   - **Submarines (Virginia, Yasen)**: Diving below thermoclines (-120m to -350m), sonar ping pulse rings, heavyweight wire-guided torpedo salvos with cavitation trails, and VLS Tomahawk cruise missile launches breaking the water surface.

3. **Relative Speeds Calibration (US-703)**:
   - Strict physical calibration across platform domains:
     - Infantry: 8–12 km/h (~0.0028 km/s)
     - Armor: 45–65 km/h (~0.0139 km/s)
     - Helicopters: 240–310 km/h (~0.0778 km/s)
     - Jets: 900–2,400 km/h (0.25–0.67 km/s)
     - Submarines: 25–42 km/h (0.007–0.012 km/s)
     - Missiles: Mach 2–6+ (> 0.68 km/s)

4. **Playable Tactical Match Loop & Objectives (US-704)**:
   - Objective-based victory and defeat tracking.
   - Real-time evaluation of objectives (e.g., neutralize invading amphibious armor group, protect HQ Command Bunker).
   - End-of-match victory/defeat atmosphere, bulkhead debriefing slate, and progression into the Campaign Story Tree.

---

### 2. User Stories & Acceptance Criteria

#### US-701: 6DOF VR & Desktop Multi-Unit Selection and Radial Order Menu
- **Given** friendly units are selected by raycast or box-drag on the 3D War Table,
- **When** the selection is active,
- **Then** a floating 3D holographic command radial is rendered at the selection centroid with MOVE, ATTACK, PATROL, HOLD/AMBUSH, and RETREAT wedges.
- **And** selecting an enemy unit marks it with a rotating 3D Red Locking Target Reticle.

#### US-702: Domain & Vehicle Specific Tactics & Feedback
- **Given** Armor, Helicopter, Infantry, and Submarine units engaged in combat,
- **Then** Tanks rotate their turrets toward hostile azimuth and fire kinetic APFSDS rounds with muzzle flashes.
- **And** Helicopters fly low-altitude NOE and hover in combat.
- **And** Infantry in urban areas receive +40-50% cover mitigation and pin targets under suppressive fire.
- **And** Submarines operate submerged, emit acoustic sonar pulses, and fire torpedoes.

#### US-703: Calibrated Realistic Relative Speeds & Scales
- **Given** simulated platforms across all domains,
- **Then** kinematic speeds strictly adhere to relative ratios within ±15% tolerance.

#### US-704: End-to-End Playable Tactical Match Loop
- **Given** an active tactical engagement,
- **When** all hostile primary objectives are eliminated,
- **Then** `match_outcome` evaluates to `"VICTORY"`, displaying debrief statistics and advancing the story tree.
- **When** the friendly bunker is destroyed or captured,
- **Then** `match_outcome` evaluates to `"DEFEAT"`.

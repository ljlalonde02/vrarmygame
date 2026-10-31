# SAFe PI-16 Sprint 16 Specification
## Realistic Ballistic Munition Dynamics, Special CBRN/Electromagnetic Effects & Doctrinal Military Formations

**Sprint**: Sprint 16 (Program Increment 16)  
**Methodology**: Scaled Agile Framework (SAFe) + Stanford Design Studio  
**Target Architecture**: Godot 4.7.2 Forward Mobile // NVIDIA GeForce RTX 4060 Ti  
**Platform Scope**: Pure Diegetic VR Holographic War Table (DEFCON Modern VR Wargame)

---

## 1. Executive Summary & Problem Statement
Prior sprints established the 3D flagship unit armory, naval bathymetry draft constraints, real named cities, and tactical combat flares. However, munition flight paths previously utilized simplified straight target lookups with generic box meshes, and unit formations defaulted to regular geometric lines rather than authentic military doctrine adapted to terrain.

Sprint 16 implements:
1. **Realistic Ballistic Trajectories & Orientations**:
   - Every munition (artillery shell, cruise missile, loitering drone, hypersonic glide vehicle, ballistic missile) travels along a physics-grounded flight path.
   - Munition attitude (pitch and heading) dynamically aligns with the instantaneous tangent velocity vector: climbing with positive nose pitch during ascent, leveling at apogee, and pitching down steeply into terminal dive.
   - Authentic relative altitudes and speeds:
     * 155mm Artillery Shells: Apogee 3–8 km, Mach 1.8–2.5 (~0.65 km/s).
     * Cruise Missiles (Tomahawk/Kalibr): Low-altitude terrain-following (50–150m AGL), Mach 0.8 (~0.28 km/s).
     * Loitering Drones (Shahed-136/Switchblade): Low altitude 300–600m, slow cruise (~0.045 km/s), steep spiraling terminal dive.
     * Ballistic Missiles (DF-21D/ATACMS/Iskander): High mesospheric parabola (Apogee 45–120 km), Mach 6–10 (~2.2–3.5 km/s).
     * Hypersonic Glide Vehicles (DF-17): Initial rocket boost to 40 km, waverider skip-glide cruise at 28 km, terminal dive at Mach 10+.
2. **Distinct Munition 3D Low-Poly Meshes**:
   - Conical boat-tail artillery shell.
   - Cruciform-fin winged cruise missile.
   - Delta-wing pusher-prop loitering drone.
   - High-fineness rocket booster + reentry cone ballistic missile.
   - Sharp triangular waverider hypersonic glider.
3. **Special Weapons (CBRN & Electromagnetic Effects)**:
   - **Chemical Weapons (Armes Chimiques)**: Persistent mustard-green/yellow toxic aerosol cloud that contours to terrain depressions and valleys, causing ground unit combat degradation.
   - **Biological Weapons (Armes Biologiques)**: Pale violet/bioluminescent pathogen spore mist with expanding quarantine perimeter rings.
   - **Magnetic / Electromagnetic Weapons (Armes Magnétiques / HEMP / HPM)**: Expanding spherical magnetic flux rings with electric cyan ionization, disabling radars and scrambling electronics.
4. **Doctrinal Military Formations**:
   - **Tactical Wedge (Vee)**: Armored spearheads advance with recon/point element leading and flanks stepped back at 45°–60°.
   - **Staggered Defile Column**: In mountain passes, valleys, or along roads, units advance in serpentine staggered columns alternating sides to prevent single-salvo wipeout.
   - **Hull-Down Ridgeline Defense**: Units on elevated crests disperse along the military crest using elevation masking for defense.
   - **Naval CSG / SAG Protective Ring**: Supercarrier in the center sanctum with guided missile destroyers in a 360° defensive screen.
   - **Air Combat Finger-Four / Spread**: 4-ship flight with staggered altitudes and lateral offsets for mutual radar coverage.

---

## 2. User Stories & Acceptance Criteria

### US-16.1: Ballistic Munition Flight Dynamics & Tangent Parabolic Orientations
- **Description**: All active munitions must track realistic 3D parabolic or terrain-following curves, with pitch and heading strictly aligned to instantaneous tangent velocity.
- **Acceptance Criteria**:
  * Munition velocity tangent $\vec{v}(t) = \frac{d\vec{P}(t)}{dt}$ calculated each physics tick.
  * Heading calculated as $\text{atan2}(v_x, v_z)$; pitch calculated as $\text{atan2}(v_y, \sqrt{v_x^2 + v_z^2})$.
  * Ballistic missiles climb with pitch $+35^\circ$ to $+75^\circ$, level at apogee ($0^\circ$), and dive with pitch $-45^\circ$ to $-80^\circ$.
  * Visual MultiMesh transform applies full 3D rotation basis corresponding to tangent velocity.

### US-16.2: Distinct Munition 3D Meshes & Speed-Altitude Physics
- **Description**: Distinguish between artillery shells, cruise missiles, loitering drones, ballistic missiles, and hypersonic gliders in both visual mesh representation and flight envelope.
- **Acceptance Criteria**:
  * Dedicated low-poly procedural meshes generated in `PlatformMeshArmory` or `VisualSyncController` for each of the 5 munition classes.
  * Flight progress, apogee altitude, and speed scaling verified per munition profile.

### US-16.3: Special CBRN & Electromagnetic Weapons
- **Description**: Unique visual and tactical representation for chemical, biological, and electromagnetic weapons.
- **Acceptance Criteria**:
  * Chemical aerosol plumes render as terrain-following persistent toxic clouds (`Color(0.72, 0.88, 0.15, 0.55)`).
  * Biological mist renders as expanding pathogen cloud (`Color(0.75, 0.40, 0.95, 0.40)`) with quarantine rings.
  * Electromagnetic HEMP renders as expanding spherical magnetic flux rings (`Color(0.20, 0.85, 1.0, 0.90)`) with radar blackout capability.

### US-16.4: Doctrinal Military Formations
- **Description**: Battalions and company groups position in doctrinally sound formations adapted to terrain.
- **Acceptance Criteria**:
  * Formations generated based on posture and terrain: Tactical Wedge, Staggered Valley Column, Hull-Down Crest Defense, Naval CSG Ring Screen, and Air Finger-Four.
  * Units no longer spawn in plain straight geometric lines.

---

## 3. Verification & Test Plan
1. `tests/test_sprint16_features.gd`:
   - Unit tests for tangent velocity & pitch orientation math.
   - Test distinctive munition mesh generation and vertex counts.
   - Test CBRN and electromagnetic weapon state tracking.
   - Test doctrinal formation layouts (Wedge, Defile Column, Ridgeline Defense, CSG Ring).
2. GPU Media Capture on RTX 4060 Ti (`tools/capture_sprint16_media.gd`):
   - Scene 1: Ballistic Missile Parabolic Arc & Hypersonic Glide tangent orientation.
   - Scene 2: Artillery Shell Salvo vs Staggered Valley Defile Column.
   - Scene 3: Chemical Toxic Cloud & Electromagnetic HEMP Magnetic Flux Ring.
   - Scene 4: Combined Arms War Table with Doctrinal Formations (Wedge, Ridge Defense & CSG Ring).

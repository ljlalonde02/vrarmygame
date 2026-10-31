# SAFe PI-19 Sprint 19 Specification
## Naval Draft Dynamics, Bathymetric Contour Routing, Real-World Named Cities & Featured 3D Platform Meshes

**Sprint**: Sprint 19 (Program Increment 19)  
**Methodology**: Scaled Agile Framework (SAFe) + Stanford Design Studio  
**Target Architecture**: Godot 4.7.2 Forward Mobile // NVIDIA GeForce RTX 4060 Ti  
**Platform Scope**: Pure Diegetic VR Holographic War Table (DEFCON Modern VR Wargame)

---

## 1. Executive Summary & Problem Statement
In authentic modern multi-domain littoral warfare (such as the Taiwan Strait, South China Sea, and Baltic chokepoints), naval vessels cannot traverse arbitrary shallow coastal waters or beaches, but are governed strictly by draft displacement, bathymetric channels, and undersea topography. Furthermore, wargamers and defense analysts demand recognizable geographic grounding—prominent named metropolitan centers (Taipei, Kaohsiung, Taichung, Xiamen, Fuzhou) with authentic landmarks (Taipei 101, Kaohsiung 85 Sky Tower, Xiamen International Center) and industrial maritime infrastructure (port container cranes)—rather than abstract uniform generic boxes. Finally, featured multi-domain combat platforms (F-35A Lightning II, Chengdu J-20 Mighty Dragon, Sukhoi Su-57 Felon, B-21 Raider, Type 055 Renhai Guided-Missile Cruiser, CVN-78 Gerald R. Ford Supercarrier) require lightweight (< 50 vertices), instantly identifiable 3D low-poly procedural silhouettes optimized for massive swarm engagements at 90+ FPS in VR.

Sprint 19 achieves this through three core engineering pillars:
1. **Naval Bathymetric Draft Dynamics & Contour Deflection (`KinematicsSystem`)**:
   - Vessel draft requirements defined per classification: Supercarrier (CVN-78: 12.0m), Guided-Missile Destroyer/Cruiser (Type 055: 7.5m), Frigate (4.8m), Corvette (3.5m), USV (1.2m), Attack Submarine (15.0m).
   - Bathymetric depth query calculates oceanic floor depth across littoral shelves and deep maritime trenches.
   - Smooth tangent deflection along bathymetric contour gradients ($\vec{t} = (-\frac{\partial D}{\partial z}, \frac{\partial D}{\partial x})$) when approaching shoals, ensuring capital ships naturally navigate deep channels without grounding or stuttering.
2. **OpenStreetMap-Aligned Named Cities & Iconic Metropolitan Landmarks (`TerrainInfrastructureSystem`)**:
   - Integration with theater real-world population nodes (Taipei, Kaohsiung, Taichung, Tainan, Keelung, Xiamen, Quanzhou, Fuzhou).
   - Procedural generation of landmark skyscrapers: Taipei 101 Pagoda Spire ($h=0.036\text{m}$, radiant emerald/gold), Kaohsiung 85 Sky Tower ($h=0.026\text{m}$, dual-tower pylon), and Xiamen International Center ($h=0.028\text{m}$, crystalline tower).
   - Placement of maritime container port cranes along quays and deepwater container terminals.
   - Visual synchronization with high-contrast diegetic 3D labels and distinct color palettes.
3. **Optimized 3D Low-Poly Procedural Platform Meshes (`VisualSyncController`)**:
   - Ultra-low polygon count (< 50 vertices per platform) enabling hundreds of units on screen simultaneously without draw-call bottlenecks.
   - Realistic planform geometry: F-35A trapezoidal wings and twin canted tails; J-20 forward canards and delta wing; Su-57 blended wing body; B-21 flying wing stealth diamond; Type 055 flared tumblehome bow and integrated stealth mast; CVN-78 angled flight deck and aft island superstructure.
   - Dynamic banking, pitching, wake turbulence, and sonic vapor cone effects.
4. **Adversarial Test Suite & RTX 4060 Ti GPU Verification**:
   - `tests/test_sprint19_features.gd` (30/30 PASS, 100%).
   - Zero regressions across Sprint 18 (46/46 PASS) and Gate 4 Full Game Boot (`test_full_game_boot.gd`) (PASS).
   - 4 high-definition stills and 4 60fps animated GIFs rendered on GPU and visually verified.

---

## 2. User Stories & Acceptance Criteria

### US-19.1: Naval Draft Requirements & Bathymetric Depth Queries
- **Description**: Warships must respect realistic ocean draft limits and cannot navigate into shallow shoals or coastal waters exceeding their draught.
- **Acceptance Criteria**:
  * `WorldState.get_ship_required_draft_m(pid, flags, p_slug)` returns calibrated draft requirements (CVN-78 = 12.0m, Type 055 = 7.5m, Frigate = 4.8m, USV = 1.2m, Submarine = 15.0m).
  * `WorldState.get_water_depth_m(x, z)` calculates true water depth from coastal shelf to oceanic abyss.
  * Vessels with drafts exceeding available depth are prohibited from navigating into shallow waters.

### US-19.2: Bathymetric Contour Sliding & Smooth Channel Traversal
- **Description**: When approaching shoals, vessels smoothly divert along deep bathymetric contours rather than stopping dead or penetrating coastlines.
- **Acceptance Criteria**:
  * `KinematicsSystem` computes the 2D bathymetric gradient vector $\nabla D = (\frac{\partial D}{\partial x}, \frac{\partial D}{\partial z})$.
  * The velocity vector is projected onto the bathymetric contour tangent $\vec{t} = (-\frac{\partial D}{\partial z}, \frac{\partial D}{\partial x})$, sliding the warship along deep oceanic channels.
  * Verified in test scenarios with simulated headland obstacles.

### US-19.3: Recognized Named Cities, Landmark Spires & Maritime Port Cranes
- **Description**: Real named cities are populated with recognizable architectural landmarks and maritime port infrastructure.
- **Acceptance Criteria**:
  * `TerrainInfrastructureSystem` spawns `BLDG_LANDMARK_SKYSCRAPER` (6) at primary metropolitan centers (Taipei 101, Kaohsiung 85, Xiamen International Center).
  * Spawns `BLDG_PORT_CONTAINER_CRANE` (7) at harbor terminals along Taiwan Strait coastlines.
  * `VisualSyncController` assigns distinct, vibrant emissive colors (emerald/gold for skyscrapers, maritime orange for container cranes).
  * OpenStreetMap city labels render above metropolitan clusters.

### US-19.4: Featured 3D Platform Meshes (< 50 Vertices)
- **Description**: Distinctive 3D low-poly procedural platform meshes for high-performance multi-domain rendering.
- **Acceptance Criteria**:
  * Meshes built for F-35A, J-20, Su-57, B-21, Type 055, and CVN-78.
  * All platform meshes maintain under 50 vertices to guarantee 90+ FPS in VR with massive battle formations.
  * Realistic aerodynamic attitudes (banking on turns, climb/descent pitching).

---

## 3. Architecture & Verification Summary

```
                      +-----------------------------------+
                      |       WORLD STATE BATHYMETRY      |
                      | get_ship_required_draft_m(p_slug) |
                      |      get_water_depth_m(x, z)      |
                      +-----------------+-----------------+
                                        |
                                        v
                      +-----------------------------------+
                      |         KINEMATICS SYSTEM         |
                      |   Bathymetric Gradient Deflection |
                      |    v_tangent = (t . v_desired) * t|
                      +-----------------+-----------------+
                                        |
                   +--------------------+--------------------+
                   |                                         |
                   v                                         v
+------------------------------------+    +------------------------------------+
|   TERRAIN INFRASTRUCTURE SYSTEM    |    |       VISUAL SYNC CONTROLLER       |
| Real-World OpenStreetMap Cities    |    | Low-Poly 3D Featured Meshes        |
| Taipei 101, Kaohsiung 85, Xiamen   |    | F-35A, J-20, Su-57, B-21           |
| Port Gantry Container Cranes       |    | Type 055 Cruiser, CVN-78 Carrier   |
+------------------------------------+    +------------------------------------+
```

### Verification Matrix
| Test Suite | Test Count | Pass Rate | Status |
| :--- | :--- | :--- | :--- |
| `tests/test_sprint19_features.gd` | 30 / 30 | 100% | PASS |
| `tests/test_sprint18_features.gd` | 46 / 46 | 100% | PASS |
| `tests/test_full_game_boot.gd` | 6 / 6 phases | 100% | PASS |

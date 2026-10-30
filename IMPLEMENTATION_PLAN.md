# Step-by-Step Implementation Plan — VR & PC Holographic Wargame Simulator

> [!IMPORTANT]
> **Instructions for the Executing Agent (Gemini 3.8 Flash):**
> - **Architecture Reference:** Always follow [ARCHITECTURE.md](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/ARCHITECTURE.md) in the workspace root.
> - **Godot 4.7.2 Console Executable:** `C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe`
> - **Local Godot 4.7 Docs (if needed):** `C:\Godot\godot-docs-html-master\classes\`
> - **Golden Rule (Test-Driven Gates):** After completing **each phase**, you **MUST** run that phase's Automated Verification Test Script using `C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe` and fix all errors until every assertion passes (`0 errors`).

---

## 0. Visual Elegance, "Sense of Power" Juice & Zero-Programmer-Art Contract

> [!CAUTION]
> **NO DEFAULT GODOT GREY UI OR UGLY PLACEHOLDER COLORS:**
> Every 2D HUD panel, 3D diegetic dossier, and holographic shader **MUST** adhere strictly to this visual design system so the game looks like a polished \$25 tactical masterpiece (*HighFleet* + *DEFCON* + *VTOL VR*):

### 0.1 Master Color Palette (Linear / Hex Contract)
| Element | Hex Code | Godot `Color(...)` | Visual Usage |
| :--- | :--- | :--- | :--- |
| **Bunker Void & Obsidian Sea** | `#05080E` | `Color(0.02, 0.03, 0.055, 1.0)` | Bunker room background, deep ocean floor, vignette base |
| **Tactical Glass Panel BG** | `#0A111CEB` | `Color(0.04, 0.067, 0.11, 0.92)` | All UI cards, Main Menu, Recon Photo Dossier, OPORD Clipboard |
| **NATO Blue Force (Friendly)** | `#00D8FF` | `Color(0.0, 0.85, 1.0, 1.0)` | Friendly tokens, radar LoS illumination, friendly missile trails |
| **OPFOR Red Force (Hostile)** | `#FF2A54` | `Color(1.0, 0.165, 0.33, 1.0)` | Hostile tokens, SAM Fresnel threat domes, hostile missile salvos |
| **Unmanned / Robot Dog / AI Gold** | `#FFB800` | `Color(1.0, 0.72, 0.0, 1.0)` | Robot Dog packs, FPV swarms, Loyal Wingmen, `[DEPLOY UNMANNED]` rings |
| **Directed Energy (Laser / HPM)** | `#B84DFF` | `Color(0.72, 0.30, 1.0, 1.0)` | *Iron Beam* 100kW laser beams & *Epirus Leonidas* 30° HPM microwave cones |
| **Topographic Contour Emerald** | `#148578` | `Color(0.08, 0.52, 0.47, 1.0)` | 200m elevation iso-contour lines & ridge rim-lighting on mountains |

### 0.2 UI & Typography Elegance Rules (`src/presentation/ui/tactical_theme.gd`)
1. **Programmatic `Theme` Builder (`TacticalTheme.create_theme()`):**
   - Never use unstyled `Panel` or `Button` nodes. All UI roots apply `TacticalTheme.create_theme()`, which configures `StyleBoxFlat` with:
     - Background: `Color(0.04, 0.067, 0.11, 0.92)`
     - Border: `1px` or `2px` glowing cyan (`#00D8FF66`) on normal, brightening to `#00D8FF` on hover/focus
     - Corner radius / bevel: `3px` sharp military chamfers
     - Shadow: `8px` soft black drop-shadow (`Color(0, 0, 0, 0.6)`)
2. **Framed Real Wikipedia Recon Photographs:**
   - Every Wikipedia photograph (`res://assets/wiki_images/...`) rendered in the **Recon Dossier Panel**, **Armory Encyclopedia**, or **Floating Token Photo Card** is framed inside a sleek dark bezel with corner reticle brackets (`[ ]`), an optional **FLIR Green/Cyan Recon Tint toggle**, and a crisp military specification badge (`RCS | SPEED | RANGE | $M COST`).
3. **Combat "Juice" & Micro-Interactions:**
   - **Parabolic Ballistic Arcs:** Missiles never fly in flat straight lines—they climb into a 3D parabolic arc above the mountain ridges with a glowing multi-segment ribbon trail and a vertical altitude stem to the ground.
   - **Expanding Shockwave Rings:** Every missile intercept or ground impact spawns an expanding, fading holographic ring on the table + a floating `-$45.0M` damage telemetry popup.
   - **Smooth Exponential Damping:** Camera zoom, table pan, switch flips, and echelon splitting (`Brigade -> Battalion -> Company`) use smooth exponential interpolation (`lerp(a, b, 1.0 - exp(-12.0 * delta))`) so nothing ever snaps jarringly.

---

## Phase 1: SQLite Database (`data/wargame.db`), Wikipedia Seed Pipeline & 500km Theater Generator ✅ (COMPLETED & VERIFIED)

### Status
- **Already executed and verified on disk!**
- [seed_wargame_db.py](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/tools/wiki_pipeline/seed_wargame_db.py) created `data/wargame.db` and `data/wargame_cache.json`, and downloaded **23/23 real Wikipedia weapon photos** (`assets/wiki_images/weapons/*.jpg`) and **36/36 real Wikipedia platform/robot-dog/drone photos** (`assets/wiki_images/platforms/*.jpg`), plus 3 playable scenarios (`scenarios` table).
- [generate_theater.py](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/tools/terrain_pipeline/generate_theater.py) generated the `512×512` 500 km × 500 km heightmap at `data/theaters/strait_theater_heightmap.png`.

### Files Created
1. `tools/wiki_pipeline/seed_wargame_db.py`
   - Creates `data/wargame.db` executing the exact DDL from Section 3 of `ARCHITECTURE.md` (`platforms`, `sensors`, `weapons`, `platform_sensors`, `platform_loadouts`, `formation_templates`, `theaters`, `theater_sites`, `scenarios`), including `wiki_page_title TEXT`, `image_res_path TEXT`, and `wiki_summary TEXT` columns on both `platforms` and `weapons`.
   - **Real Wikipedia Photograph Downloader (`res://assets/wiki_images/`):**
     - Queries the official **Wikipedia REST API** (`https://en.wikipedia.org/api/rest_v1/page/summary/{wiki_page_title}`) and **MediaWiki PageImages API** to fetch real **Wikimedia Commons photographs** and encyclopedia summaries.
     - Saves real photographs locally to `assets/wiki_images/platforms/{slug}.jpg` and `assets/wiki_images/weapons/{slug}.jpg`.
   - Seeds **36 real-world platforms** with authentic Wikipedia specifications (`rcs_m2`, `max_speed_knots`, `combat_radius_km`, `unit_cost_musd`, `autonomy_level`, `can_climb_steep_slopes`, `carrier_sub_platform_slug`, `directed_energy_kw`, `de_aoe_cone_deg`):
     - **Manned Air:** `f_35a_lightning`, `f_16cj_block50`, `b_21_raider`, `e_3_sentry_awacs`, `su_57_felon`, `j_20_mighty_dragon`, `tu_22m3_backfire`
     - **Loyal Wingman / CCA AI Jets:** `xq_58a_valkyrie`, `mq_28_ghost_bat`, `s_70_okhotnik`, `bayraktar_kizilelma`
     - **Quadruped Robot Dogs & UGVs:** `vision_60_q_ugv` (`can_climb_steep_slopes=1`, `rcs_m2=0.0005`, `autonomy_level='AUTONOMOUS_AI'`), `unitree_b2w_armed` (`can_climb_steep_slopes=1`), `milrem_themis_ugv`, `uran_9_ugv`
     - **Loitering Munitions & FPV Swarms:** `fpv_fiber_swarm` (`autonomy_level='FIBER_OPTIC'`), `switchblade_600_team`, `lancet_3_team`, `shahed_136_launcher`, `iai_harop_launcher`
     - **Naval & Kamikaze USVs/UUVs:** `ddg_51_arleigh_burke`, `type_055_renhai`, `magura_v5_usv`, `sea_baby_usv`, `orca_xluuv`
     - **SAMs, Directed Energy Lasers & HPM Microwaves:** `mim_104f_patriot`, `s_400_triumf`, `iron_beam_helws` (`directed_energy_kw=100.0`), `de_m_shorad_stryker` (`directed_energy_kw=50.0`), `epirus_leonidas_hpm` (`directed_energy_kw=75.0`, `de_aoe_cone_deg=30.0`), `krasukha_4_ew`
     - **Ground Battalions / Carriers (with Robot Dog & FPV Bays):** `m1a2_sepv3_platoon`, `m2a4_mech_company` (`carrier_sub_platform_slug='vision_60_q_ugv'`, `carrier_sub_count=2`), `specops_mountain_team` (`carrier_sub_platform_slug='fpv_fiber_swarm'`, `carrier_sub_count=3`), `t_90m_platoon`
   - Seeds **25+ authentic munitions** (`aim_120d`, `agm_88g_aargm_er`, `agm_158_jassm`, `lrhw_dark_eagle`, `3m22_zircon`, `kh_47m2_kinzhal`, `pac_3_mse`, `48n6e3`, `adm_160_mald`, `switchblade_600_round`, `shahed_136_round`, `lancet_3_round`, `fgm_148_javelin`, `helws_laser_pulse`, `leonidas_hpm_pulse`).
   - Seeds **Brigade $\rightarrow$ Battalion $\rightarrow$ Company/Flight** `formation_templates` for both `BLUE` and `RED` factions.
   - **Important Dual-Export Bridge:** In addition to writing `data/wargame.db` (SQLite), the script also exports `data/wargame_cache.json` (a mirror of all SQLite tables) so `SimDB` in Godot 4.7 can either query `godot-sqlite` natively OR load `wargame_cache.json` / query SQLite via CLI seamlessly without requiring external C++ DLL compilation.
2. `tools/terrain_pipeline/generate_theater.py`
   - Generates a `1024×1024` heightmap PNG (`data/theaters/strait_theater_heightmap.png`) featuring an authentic strait, coastal plains, rugged central mountain range (up to 3,800m elevation with steep valleys for radar masking), and islands.

### Phase 1 Verification Command
```powershell
python tools/wiki_pipeline/seed_wargame_db.py
python tools/terrain_pipeline/generate_theater.py
```

---

## Phase 2: Godot 4.7 Project Setup, Autoloads & Data-Oriented `SimCore` (5,000+ Token Engine)

### Goal
Create `project.godot`, the 3 core Autoloads (`SimDB`, `CommandBus`, `SignalBus`), and the multi-threaded `SimServer` + `WorldState` Structure-of-Arrays engine capable of simulating thousands of tokens, hierarchical echelons (`Brigade -> Battalion -> Company`), radar horizon + RCS equations, EW jamming, Directed Energy thermal capacitors, and Robot Dog unpacking.

### Files to Create
1. `project.godot`
   - Configured for Godot 4.7 (`config_version=5`), renderer set to `mobile` (Vulkan Mobile for Quest 3 compatibility + PC speed), window size `1920x1080`, global shader uniform `fow_threat_map` (`sampler2D`), and Autoloads:
     - `SimDB="*res://src/autoloads/sim_db.gd"`
     - `CommandBus="*res://src/autoloads/command_bus.gd"`
     - `SignalBus="*res://src/autoloads/signal_bus.gd"`
2. `src/autoloads/sim_db.gd`
   - Connects to `res://data/wargame.db` (via `SQLite` class if GDExtension present, with automatic zero-error fallback to `res://data/wargame_cache.json` and SQLite CLI sync) and populates $O(1)$ integer-indexed arrays (`platforms_by_id`, `weapons_by_id`, `sensors_by_id`, `formations_by_slug`, `theaters_by_slug`).
3. `src/autoloads/command_bus.gd`
   - Thread-safe command queue (`Mutex` protected) supporting:
     - `CMD_MOVE_WAYPOINTS`, `CMD_SET_DOCTRINE`, `CMD_QUEUE_STRIKE`, `CMD_COMMIT_ALPHA_STRIKE`, `CMD_DEPLOY_UNMANNED_SUBUNIT`, `CMD_SET_MASTER_IADS`, `CMD_SET_TIME_SCALE`.
   - Logs all commands with `tick_id` for Tacview-style After-Action Replay.
4. `src/autoloads/signal_bus.gd`
   - Signals for UI, Audio, and Bunker Hardware (`unit_selected`, `salvo_launched`, `unit_destroyed`, `dollar_loss_updated`, `frago_received`, `time_scale_changed`, `master_iads_toggled`, `alpha_strike_committed`).
5. `src/sim_core/world_state.gd`
   - Pre-allocated `PackedVector3Array`, `PackedFloat32Array`, `PackedInt32Array`, and `PackedByteArray` pools for up to `MAX_UNITS = 4096` and `MAX_MUNITIONS = 8192`.
   - Tracks `unit_pos`, `unit_vel`, `unit_faction`, `unit_platform_id`, `unit_echelon` (`0=Co/Flight, 1=Bn/Sqn, 2=Bde/Wing`), `unit_parent_id`, `unit_radar_active`, `unit_roe`, `unit_hp`, `unit_ammo_1`, `unit_ammo_2`, `unit_energy_cap`, `unit_unmanned_bays`, `unit_detected_mask`.
   - Tracks heightmap elevation sampling helper `get_terrain_elevation_m(x_km: float, z_km: float) -> float`.
6. `src/sim_core/spatial_hash_grid.gd`
   - `50 × 50` grid of 10 km cells over the 500 km × 500 km theater for $O(1)$ neighborhood queries.
7. `src/sim_core/render_snapshot.gd`
   - Triple-buffered snapshot holder (`prev_snap`, `curr_snap`, `write_snap`) so the 90 Hz render thread interpolates smoothly without locking the 10 Hz simulation thread.
8. `src/sim_core/systems/`
   - `kinematics_system.gd`: Moves units along 3D waypoints; applies steep slope penalty (`>25°`) to standard ground units while allowing `can_climb_steep_slopes == 1` (**Robot Dogs** & Mountain Infantry) full mobility on sheer cliffs.
   - `sensor_los_system.gd`: Implements the Radar Horizon equation ($4.12(\sqrt{h_1}+\sqrt{h_2})$), 8-step terrain heightmap raymarch, and Fourth-Root RCS equation ($\text{Range} \times (\text{RCS}/5.0)^{0.25}$). Generates the `256×256` `fow_threat_map` `ImageTexture`.
   - `ew_system.gd`: Processes jammer cones; severs `RF_DATALINK` drones while `FIBER_OPTIC` and `AUTONOMOUS_AI` units operate unimpeded.
   - `salvo_combat_system.gd`: Launches missiles, loitering munitions, and hypersonics; resolves Patriot/S-400 missile intercepts; fires **Directed Energy Lasers (`Iron Beam`)** and **30° HPM Microwave Cones (`Epirus Leonidas`)** against drone swarms using thermal capacitor pools; tracks `$ Millions USD` destroyed per side.
   - `echelon_cluster_system.gd`: Computes center-of-mass and aggregate strength for parent Battalions and Brigades; handles unpacking **Robot Dog Packs** and **FPV Swarms** from parent carrier units.
9. `src/sim_core/sim_server.gd`
   - Node/Service driving the 10 Hz tick via `WorkerThreadPool` (with deterministic single-thread test mode) and seeding a massive **500 km × 500 km "Operation Pacific Shield 2028" scenario** with **600+ active units** organized into Brigades $\rightarrow$ Battalions $\rightarrow$ Companies/Flights/Swarms/Robot Dog Packs.

### Phase 2 Verification Command
Create `tests/test_sim_core.gd` (extending `SceneTree`) that boots `SimDB` and `SimServer`, spawns 600+ units across the 500 km theater, runs 50 simulation ticks, tests Robot Dog deployment, Radar RCS detection, and Alpha Strike salvo launch, and asserts 0 errors:
```powershell
& "C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe" --headless --path "c:\Users\ljlal\Documents\GitHub\vrarmygame" -s res://tests/test_sim_core.gd
```

---

## Phase 3: The Holographic War Table, Shaders & `MultiMesh` Renderer

### Goal
Build the stunning **"Dark Obsidian Bunker + High-Contrast Volumetric Hologram"** War Table (`1.8m × 1.8m` physical surface representing `500 km × 500 km`), custom Godot 4.7 shaders, single-draw-call `MultiMeshInstance3D` token/stem/missile rendering, Semantic Zoom Echelon transitions, and live parabolic Strike Preview arcs.

### Files to Create
1. `src/presentation/war_table/shaders/war_table_terrain.gdshader`
   - Vertex displacement from `strait_theater_heightmap.png`.
   - Fragment shader: glossy dark obsidian ocean with bathymetry grid, 200m glowing cyan/emerald topographic iso-contour lines, slope rim lighting, and real-time sampling of `fow_threat_map` (brightening friendly radar Line-of-Sight corridors and tinting enemy SAM domes crimson/amber).
2. `src/presentation/war_table/shaders/hologram_token.gdshader`
   - Unshaded additive/alpha billboard/plaque shader using `INSTANCE_CUSTOM` color/data to render NATO symbology, echelon bars (`I`, `II`, `III`, `X`), HP/Ammo bars, and autonomous/robot-dog badge highlights.
3. `src/presentation/war_table/shaders/fresnel_dome.gdshader`
   - Translucent Fresnel rim-glow shader for Radar, SAM, and HPM Microwave domes that stays crystal clear in the center and glows on edges.
4. `src/presentation/war_table/visual_sync_controller.gd`
   - Interpolates between `prev_snap` and `curr_snap` at 90 Hz.
   - Updates 4 `MultiMeshInstance3D` nodes in bulk:
     1. `UnitTokensMultiMesh` (NATO squadron squares / 3D holo icons filtered by current Semantic Zoom level: Brigade vs. Battalion vs. Company/Robot Dog Pack)
     2. `AltitudeStemsMultiMesh` (Vertical laser drop-lines from air units & missiles to the terrain below)
     3. `ActiveMunitionsMultiMesh` (Glowing missiles, hypersonics, and FPV swarms arcing in 3D)
     4. `LaserHpmBeamsMesh` (`ImmediateMesh` drawing cyan High-Energy Laser beams, pulsing violet HPM Microwave cones, and waypoint paths)
5. `src/presentation/war_table/strike_preview_renderer.gd`
   - Draws live dashed parabolic trajectories, Time-on-Target (TOT) counters, and SAM exposure warnings when the player drags an attack vector from a unit or Brigade.
6. `src/presentation/war_table/war_table.tscn` & `war_table.gd`
   - Assembles the table bezel, terrain mesh, `MultiMesh` layers, zoom/pan transform (`zoom_scale` from `1.0x` 500 km theater view up to `25.0x` `<15 km` tactical valley view where Robot Dogs and FPV swarms unpack!).

### Phase 3 Verification Command
```powershell
& "C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe" --headless --path "c:\Users\ljlal\Documents\GitHub\vrarmygame" --quit
```

---

## Phase 4: Main Menu, Campaign/Scenario Selector, Diegetic Bunker Hardware, Dual Rig (`DesktopRig` + `XRRig`), AI & Audio

### Goal
Assemble a **100% playable game from start to finish** inside the **Command Bunker** (`src/presentation/bunker/command_bunker.tscn`) featuring a **Bunker Main Menu & Campaign/Scenario Selector**, a **Wikipedia Real-Photo Armory & Encyclopedia Browser**, tactile *HighFleet*/*VTOL VR*-style switches, seamless Desktop Mouse/Keyboard + OpenXR Quest 3/PCVR controls, the Tactical AI + AI Storyteller OPORD Clipboard, Victory/Defeat After-Action Reports, and the Procedural Military Radio Synthesizer.

### Files to Create
1. `src/presentation/bunker/bunker_main_menu.gd`
   - **Diegetic Command Bunker Main Menu & Mission Hub** (accessible at game boot and via `ESC` / Bunker Menu button):
     - **[1] DYNAMIC CAMPAIGN MODE ("2028 Pacific Flashpoint — 3-Operation Campaign"):** Sequential progression through all 3 operations (*Op Pacific Shield* $\rightarrow$ *Op Iron Hound (Robot Dog Ridge)* $\rightarrow$ *Op Sea Wolfpack*), carrying over cumulative `$M USD` budget, surviving squadrons, and AI Storyteller OPORD briefings.
     - **[2] SCENARIO SELECTOR (3 Scenarios from `wargame.db` + Custom Sandbox):**
       - *Operation Pacific Shield (Full 500km Theater War — 600+ Units)*
       - *Operation Iron Hound (15km Mountain Ridge Robot Dog & FPV Clash)*
       - *Operation Sea Wolfpack (Naval Kamikaze USVs & Orca UUVs vs Carrier Group)*
       - *Custom Sandbox War Builder (Pick force budgets, unit density, and spawn custom platoons/flights on the table)*
     - **[3] WIKIPEDIA ARMORY, REAL PHOTO ENCYCLOPEDIA & FIELD MANUAL:** Full interactive browser of all **47 platforms across 9 nations**, **27 weapons**, **14 multi-spectral sensors**, and the **Commander's Field Manual (`manual_sections` from SQLite)** displaying their **real downloaded Wikipedia photographs**, Wikipedia summaries, RCS, speed, range, and cost.
     - **[4] INTERACTIVE 5-STEP BUNKER BOOT-CAMP TUTORIAL (`tutorial_controller.gd`):** Launches a guided training session on the War Table with live 3D holographic target highlights (`ZOOM_TACTICAL_REACHED` $\rightarrow$ `CMD_SET_MASTER_IADS` $\rightarrow$ `CMD_DEPLOY_UNMANNED_SUBUNIT` $\rightarrow$ `RECON_PHOTO_TOGGLED` $\rightarrow$ `CMD_COMMIT_ALPHA_STRIKE`).
     - **[5] VICTORY / DEFEAT & AFTER-ACTION REPORT (AAR) SCREEN:** Triggers when strategic objectives are met or budget is exhausted; shows `$M USD` equipment destroyed ledger, killed units list, and `[NEXT CAMPAIGN MISSION]` / `[WATCH TACVIEW REPLAY]` / `[RETURN TO MAIN MENU]`.
2. `src/presentation/bunker/hardware/tactile_console.gd`
   - Interactive 3D switches on the War Table's angled front bezel (clickable with Mouse OR grabbable with VR hands):
     - **Master IADS Lever** (`RADAR DARK / EMCON` $\leftrightarrow$ `ACTIVE IADS`)
     - **Notched Time-Compression Throttle** (`PAUSE`, `1x`, `5x`, `15x`, `30x`)
     - **Guarded Red Safety Cover + `EXECUTE ALPHA STRIKE` Button** (releases all queued strike packages simultaneously)
     - **`DEPLOY UNMANNED (DOGS / FPV)` Tactical Button** (unpacks Robot Dog packs and FPV swarms from selected battalions)
     - **`RECON PHOTO MODE` Toggle Switch (`NATO SYMBOLOGY` $\leftrightarrow$ `REAL WIKIPEDIA PHOTOS`)**: Toggles floating miniature real-world photographs above tokens on the War Table and expands the **Wikipedia Recon Dossier Card**!
     - **Semantic Echelon Override Switch** (`AUTO ZOOM STACK` / `FORCE ALL 600+ TOKENS`)
     - **True-Sight / AAR Replay Toggle** (inspect all enemy units & replay salvos)
3. `src/presentation/bunker/recon_dossier_panel.gd`
   - Diegetic **3D Holographic / Clipboard Recognition Dossier** (plus crisp HUD inspector on Desktop) that appears whenever you select a unit or weapon:
     - Displays the **real Wikipedia photograph** of the platform (e.g., *F-35A*, *Vision 60 Robot Dog*, *S-400*, *Lancet-3*) and **real Wikipedia photographs of its equipped weapons/missiles** (`image_res_path` loaded from `res://assets/wiki_images/`).
     - Shows the Wikipedia encyclopedia extract (`wiki_summary`), live ammo count, Radar Cross Section (`rcs_m2`), range rings, and unit replacement cost in `$M USD`.
     - Includes a toggle to apply a **"Classified Satellite / FLIR Green-Phosphor Filter"** or view the **Full-Color Real Wikipedia Photograph**.
4. `src/presentation/rigs/desktop_command_rig.gd` & `src/presentation/rigs/xr_command_rig.gd`
   - **Automatic XR Detection:** On startup, checks `XRServer.find_interface("OpenXR")`; if a VR headset (Quest 3 / PCVR) is connected, activates `XRCommandRig` with two-hand table pinch-zoom/pan and laser/hand grab; otherwise activates `DesktopCommandRig` with smooth `WASD` + Right-Click Orbit, Scroll-Wheel Semantic Zoom, Left-Click Magnetic Token Selection, Right-Click Drag 3D Strike Vector, and crisp Tactical HUD overlay.
5. `src/ai/tactical/opfor_commander.gd` & `src/ai/storyteller/theater_director.gd`
   - **OpForCommander:** Runs IADS ambush doctrine (keeps S-400 radars dark until player jets approach, fires interceptors at incoming strikes, launches Shahed/Lancet swarm waves and Zircon salvos).
   - **TheaterDirector:** Generates the dynamic **Operation Briefing (OPORD)**, tracks the live **Economic War Ledger (`$M Destroyed` Blue vs. Red)**, and injects mid-battle **FRAGO Intelligence Flashes** when tension thresholds are crossed.
6. `src/presentation/audio/bunker_radio_synth.gd`
   - Procedural synthesizer (`AudioStreamGenerator`) generating authentic RWR radar-lock chirps, missile launch sub-bass thumps, mechanical switch clunks, and radio squelch bursts—zero external `.wav` files required!
7. `src/presentation/bunker/command_bunker.tscn`
   - Set as `run/main_scene` in `project.godot`.

### Phase 4 Final Verification Command
Create `tests/test_full_game_boot.gd` that instantiates `command_bunker.tscn`, verifies the Main Menu, Campaign/Scenario selector, and Wikipedia Photo Encyclopedia load all 59 real photos, runs 30 frames of `VisualSyncController`, triggers an Alpha Strike + Robot Dog deployment + Time Compression via `TactileConsole`, and verifies zero script/shader errors:
```powershell
& "C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe" --headless --path "c:\Users\ljlal\Documents\GitHub\vrarmygame" -s res://tests/test_full_game_boot.gd
```

---

## 5. Phases 5–12: Global Theaters, 6-Spectrum Sensors, 4-Tier AI C2, C# SIMD 5,000+ Unit Scale & Living Infrastructure

### Phase 5: 5 Global Flashpoint Theaters & 9-Nation Doctrinal Asymmetry
- **Files:** `tools/wiki_pipeline/seed_wargame_db.py`, `tools/wiki_pipeline/generate_heightmap.py`, `src/sim_core/sim_server.gd`
- **Features:**
  - 5 Global 500×500 km Theaters (`strait_theater`, `hormuz_theater`, `korean_dmz_theater`, `baltic_suwalki_theater`, `himalaya_lac_theater`) with 16-bit elevation heightmaps and 32 strategic sites (`AIRBASE`, `COMMAND_BUNKER`, `NAVAL_PORT`, `CHOKEPOINT`).
  - 49 Platforms and 27 Munitions across 9 Nations (`USA`, `EUR_NATO`, `CHN`, `RUS`, `KOR`, `PRK`, `IND`, `PAK`, `TUR`) with 74/76 real Wikipedia photographs + 2 procedural tactical fallback cards (`76/76` verified `Texture2D` assets).

### Phase 6: Deep Airbase Logistics, Tanker Refueling & Runway Cratering
- **Files:** `src/sim_core/systems/logistics_system.gd`, `src/sim_core/systems/salvo_combat_system.gd`
- **Features:**
  - Aerial refueling orbits (`KC-46A Pegasus` transferring `+350 km` fuel to airborne flights), ground supply convoys (`Oshkosh M977 HEMTT` replenishing SAMs, tanks, and Robot Dog / FPV bays), and anti-runway bunker-buster cratering (`crater_timer_sec = 90s`).

### Phase 7: Deterministic Tacview Timeline Replay Recorder & 4-Doctrine OPFOR AI
- **Files:** `src/sim_core/replay_recorder.gd`, `src/ai/tactical/opfor_commander.gd`
- **Features:**
  - Ring-buffer keyframe recorder (`record_keyframe()`, `scrub_to_ratio()`) wired to the interactive Tacview Timeline Scrubber Slider in Tab 4 (`AFTER-ACTION & REPLAY`).
  - 4 Selectable OPFOR AI Doctrines (`IADS_AMBUSH`, `SWARM_SATURATION`, `HYPERSONIC_DECAPITATION`, `COMBINED_ARMS_BLITZ`).

### Phase 8: 4-Tier Hierarchical AI Mission Command, C2 Integrity & 6-Spectrum Sensor Fusion
- **Files:** `src/sim_core/systems/sensor_los_system.gd`, `src/sim_core/cs/SimLodKernel.cs`, `src/sim_core/systems/echelon_cluster_system.gd`, `src/sim_core/systems/unit_tactical_ai_system.gd`, `src/ai/advisor/subordinate_staff_ai.gd`
- **Features:**
  - **6-Spectrum Sensor Fusion Matrix (`Section 11` of `ARCHITECTURE.md`):**
    1. `ACTIVE_RADAR`: Fourth-root RCS scaling ($\text{RCS}^{0.25}$), blocked by Earth curvature horizon and terrain raymarching.
    2. `PASSIVE_ESM`: Silent $1.6\times$ range triangulation of active radar emitters and `RF_DATALINK` drones even while in EMCON (`unit_radar_active == 0`).
    3. `IR_EO`: Passive IRST/FLIR thermal detection (boosted $1.85\times$ against afterburning jets), countering radar stealth (*F-35A, J-20A*) within thermal range.
    4. `LIDAR_CV`: 3D LiDAR & Computer Vision on Quadruped Robot Dogs & Autonomous UGVs (`5.5 km`), immune to stealth and EW jamming.
    5. `ACOUSTIC_SONAR`: Non-Line-of-Sight mountain valley acoustic diffraction (+450m ridge tolerance) against low-flying propeller drones + Towed Naval Sonar hunting submerged submarines (*Orca XLUUV*).
    6. `SAT_SAR_EO`: Orbital LEO Recon/SAR passes.
  - **4-Tier Hierarchical AI C2 & Decapitation (`Section 10` of `ARCHITECTURE.md`):**
    - `DELEGATED_TO_PARENT` (`unit_delegated_ai == 1`) vs `DIRECT_PLAYER_CONTROL` (`unit_delegated_ai == 0`, toggled via `[L]` or Dossier).
    - Live `blue_c2_integrity` and `red_c2_integrity` computed from surviving `COMMAND_BUNKER` sites, `AWACS`, and `satcom_factor`, inflicting C2 decapitation delay when degraded.
    - JOC Subordinate Staff AI (`[F1]`–`[F3]`) with C# `.NET 8.0` T+15m Lanchester Monte-Carlo COA forecasts.

### Phase 9: 3-Tier Zoom Sim-LOD (`5,000+` Units) & Spreading Civilian Density PDE
- **Files:** `src/sim_core/cs/SimLodKernel.cs`, `src/sim_core/systems/sim_lod_system.gd`, `src/sim_core/systems/civilian_density_system.gd`
- **Features:**
  - C# `.NET 8.0` Multi-Threaded SIMD kernel (`System.Numerics.Vector<float>` + `Parallel.For`) driving 5,000–6,500+ units at `<2 ms/tick` via `LOD_TIER_0_MICRO (10 Hz)`, `LOD_TIER_1_OPERATIONAL (5 Hz)`, and `LOD_TIER_2_MACRO (1 Hz Lanchester Square-Law)`.
  - $128 \times 128$ Conservative Advection-Diffusion Civilian Density Field (`civilians/m²`, ~49 Million theater population) with ROE collateral warnings.

### Phase 10: 5-Tier Planetary-to-Tactical Zoom & Multi-Domain Deterrence (`[7]`–`[0]`)
- **Files:** `src/sim_core/systems/strategic_mdd_system.gd`, `src/presentation/war_table/war_table.gd`, `src/presentation/war_table/visual_sync_controller.gd`
- **Features:**
  - 5-Tier Zoom (`0.15x` 3D Planetary Globe & 24 LEO Satellites $\rightarrow$ `0.45x` Continental $\rightarrow$ `1.0x` Operational $\rightarrow$ `4.5x` Tactical $\rightarrow$ `12.0x–25.0x` Micro-Tactical Valley).
  - `[7] ASAT` anti-satellite intercept, `[8] CYBER` CNO paralysis, `[9] PSYOP` evacuation broadcast, `[0] CBRN` MOPP gear & wind-advected hazard plume.

### Phase 11: Living Battlefield Infrastructure, 3D Cities, Bridges, Railways & Dynamic War Destruction
- **Files:** `src/sim_core/systems/terrain_infrastructure_system.gd`, `src/presentation/war_table/shaders/war_table_terrain.gdshader`
- **Features:**
  - Hydrological rivers, strategic bridges, highways (`1.45x` speed), railways with 8 moving 3D logistics trains, and 3,800+ procedural 3D buildings (`unit_buildings_mmi`).
  - Dynamic war destruction (`inject_war_destruction`): collapses 3D urban towers into smoking rubble, blows river bridges, craters airfields, and derails supply trains.

### Phase 12: Live Event-Driven 5-Step Interactive Boot-Camp `TutorialController` & Living Documentation Sync
- **Files:** `src/presentation/bunker/tutorial_controller.gd`, `src/presentation/bunker/bunker_main_menu.gd`, `docs/GAME_MANUAL.md`
- **Features:**
  - Live interactive HUD Coach (`[H]` key or Main Menu Tab 5 `[LAUNCH LIVE INTERACTIVE 5-STEP BOOT-CAMP]`) + pulsing 3D holographic target ring (`TutorialTargetBeacon3D`) on the War Table / Console that listens to `SignalBus` and `WarTable` zoom to auto-advance Steps 1–5.
  - Auto-synced `docs/GAME_MANUAL.md` generated directly from `data/wargame.db` via `seed_wargame_db.py`.

### Phase 13: Real-World GIS World Map (`Natural Earth GeoJSON` + `AWS Terrarium / Mapbox DEM`) & Sovereign Borders
- **Files:** `tools/wiki_pipeline/generate_world_map.py`, `data/theaters/world_political_map.png`, `src/presentation/war_table/shaders/planetary_globe.gdshader`, `src/presentation/war_table/shaders/war_table_terrain.gdshader`, `src/presentation/war_table/war_table.gd`
- **Features:**
  - **Real-World GIS Data Pipeline (`generate_world_map.py`):** Fetches and caches **Natural Earth Admin-0 Sovereign Countries GeoJSON** (`177` countries in `data/theaters/ne_110m_admin_0_countries.geojson`) and **1024×1024 Global SRTM/ETOPO DEM Tiles** via **AWS Open Data Mapzen Terrarium** (`s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png`) or **Mapbox Terrain-RGB** (`MAPBOX_ACCESS_TOKEN`), rasterizing a `1440×720` equirectangular RGBA texture (`world_political_map.png` encoding `R = SRTM/ETOPO Elevation & Bathymetry`, `G = Anti-Aliased International Country Borders & Coastlines`, `B = Sovereign Geopolitical Bloc Alignment`, `A = 34 World Capital Lights`).
  - **Holographic C4ISR Shaders & 3D Sovereign Labels (`planetary_globe.gdshader`, `war_table_terrain.gdshader`, `war_table.gd`):** Preserves the signature Dark Obsidian + Volumetric Hologram aesthetic while rendering authentic continents, razor-sharp international borders, faction territory tinting, 24 3D Sovereign Country/Capital labels on the Planetary Globe, real surrounding countries in the 4,000 km Continental View, and 3D Sovereign Country Banners + dashed International Demarcation Lines (`Taiwan Strait Median Line`, `Strait of Hormuz Maritime Demarcation`, `38th Parallel Korean DMZ`, `Suwalki Gap NATO Frontier`, `Himalayan Line of Actual Control`) on the 500 km War Table.

### Phase 14: High-Resolution (`z=6`) Real-World SRTM/ETOPO DEM Tiles for All 5 Tactical Theaters + Real Metropolitan Cities & Corridors
- **Files:** `tools/terrain_pipeline/generate_theater.py`, `src/sim_core/systems/civilian_density_system.gd`, `src/sim_core/systems/terrain_infrastructure_system.gd`, `src/presentation/war_table/war_table.gd`
- **Features:**
  - **`z=6` SRTM/ETOPO DEM Tile Pipeline (`RealDemTileSampler` in `generate_theater.py`):** Downloads, caches (`data/theaters/dem_cache/`), and bilinearly samples `z=6` real-world elevation & bathymetry tiles from **AWS Open Data Mapzen Terrarium** or **Mapbox Terrain-RGB** across the exact Lat/Lon bounding boxes of all 5 500×500 km theaters (`strait_theater`, `hormuz_theater`, `korean_dmz_theater`, `baltic_suwalki_theater`, `himalaya_lac_theater`).
  - **Authentic Metropolitan Cities & Highway/Rail Corridors (`get_theater_real_cities()`):** Seeds 34 real-world metropolitan cities across the 5 theaters (*Taipei, Hsinchu, Taichung, Kaohsiung, Fuzhou, Putian/Quanzhou, Xiamen; Dubai, Sharjah, Fujairah, Khasab, Bandar Abbas, Qeshm, Jask; Seoul, Incheon, Suwon, Chuncheon, Pyongyang, Kaesong, Wonsan; Vilnius, Kaunas, Suwalki, Bialystok, Klaipeda, Kaliningrad, Grodno; Leh, Kargil, Nubra Valley, Skardu, Rutog, Hotan*) into the $128 \times 128$ Civilian Density PDE (`~255M` total population), connects them via overland Highway & Military Railway corridors with 3D urban building clusters, and pins 3D Golden C4ISR Metropolitan City Labels (`RealCityLabel_*`) on the War Table.

---

## 6. Mandatory 5-Gate Automated Testing Protocol

Every phase is verified via headless Godot 4.7.2 .NET Mono CLI (`C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe`):
1. **Gate 1 (`python tools/wiki_pipeline/seed_wargame_db.py`):** Verifies `data/wargame.db`, `data/wargame_cache.json`, `docs/GAME_MANUAL.md`, 49 platforms, 27 weapons, 14 sensors, 5 theaters, 6 scenarios, 5 tutorial steps, and 7 manual sections.
2. **Gate 2 (`res://tests/test_sim_core.gd`):** Headless unit & integration suite testing `SimDB` $O(1)$ lookup, 600+ unit `WorldState` SoA allocation, Radar Horizon & $\text{RCS}^{0.25}$ math, Robot Dog cliff-climbing & detachment unpacking, EW jamming vs. Fiber-Optic/AI autonomy, and Directed Energy (`Iron Beam` laser / `Epirus Leonidas` HPM microwave).
3. **Gate 3 (`res://tests/test_war_table_visuals.gd`):** Instantiates `war_table.tscn`, verifies all shaders compile with 0 errors, tests Semantic Zoom echelon transitions, and verifies `MultiMesh` buffer population.
4. **Gate 4 (`res://tests/test_full_game_boot.gd`):** End-to-end integration test of `command_bunker.tscn`, `BunkerMainMenu`, `ReconDossierPanel`, `TactileConsole`, `OpForCommander`, and `TutorialController`.
5. **Gate 5 (`res://tests/test_phases_5_6_7.gd`):** Comprehensive verification of Phases 5–12 (5 Global Theaters, Logistics & Cratering, Tacview Replay, 6-Spectrum Sensor Fusion Matrix, 4-Tier C2 Integrity & Delegation, C# `.NET 8.0` SIMD 5,000+ Unit Army Group Scale, Civilian Density PDE, Multi-Domain Deterrence `[7]`–`[0]`, Living Infrastructure & Bridge/Train Destruction, and Live 5-Step Interactive `TutorialController`).



### Phase 15: 1,000,000-Unit 7-Theater Global ORBAT, 2,000×2,000 km Theater Scale, Real-Time 1:1 Speeds, 3-Tier Battalion/Brigade Selection & Live Casualties/Ammunition Ledger
- **Files:** `tools/wiki_pipeline/seed_wargame_db.py`, `tools/terrain_pipeline/generate_theater.py`, `src/sim_core/systems/global_orbat_system.gd`, `src/autoloads/sim_db.gd`, `src/sim_core/world_state.gd`, `src/sim_core/systems/kinematics_system.gd`, `src/sim_core/systems/salvo_combat_system.gd`, `src/sim_core/systems/echelon_cluster_system.gd`, `src/presentation/war_table/visual_sync_controller.gd`, `src/presentation/rigs/desktop_command_rig.gd`, `src/presentation/bunker/recon_dossier_panel.gd`
- **Features:**
  - **1,000,000 Combat Units Across 7 Global `2,000×2,000 km` Theaters:** Expanded theater scale to `2,000 km × 2,000 km` across 7 global flashpoints (`Taiwan Strait`, `Ukraine & Black Sea`, `Baltic/Suwalki Gap`, `Himalayan LAC`, `Korean DMZ`, `US-Mexico Rio Grande`, `Strait of Hormuz`) with 62 platforms, 30 weapons (`92/92` Wikipedia photos verified), and internet-researched unit/carrier/base names.
  - **True 1:1 Real-Time Physical Speeds + `0x..900x` Time Acceleration:** Default `1x REAL-TIME` uses exact physical speeds (`1 kt = 0.0005144 km/s`, `Mach 1 = 0.343 km/s`), paired with HUD & Console time-compression controls (`0x PAUSE`, `1x REAL`, `10x`, `60x`, `300x`, `900x`).
  - **3-Tier Echelon Organization (`Company -> Battalion -> Brigade`), Marquee Box-Drag Selection & Reliable Order Execution:** Added Left-Mouse Box-Drag marquee selection, `[B] SELECT BATTALION`, `[V] SELECT BRIGADE`, Domain selection buttons (`ALL AIR`, `ALL LAND`, `ALL SEA`), 3D golden selection rings, C2 hierarchy tethers, and green/red waypoint vectors. Fixed `propagate_move_order()` so player orders override autonomous AI (`unit_player_override_timer = 180s`) and preserve formation offsets.
  - **Live Casualties & Ammunition Telemetry (`BLUE` & `RED`):** Real-time HUD and Dossier ledger tracking **Personnel KIA & WIA**, **Platform Losses (`Air`, `Armor/SAM`, `Naval`, `Unmanned/Robot Dogs`, `$M`)**, and **Ammunition Stocks (`Remaining`, `% Stock`, `Expended/Fired`, `In-Flight`, `Intercepted`)** for all sides.

### Phase 16: Full VR (`XRCommandRig`) & Desktop (`DesktopCommandRig`) Gamability Parity
- **Files:** `src/presentation/rigs/xr_command_rig.gd`, `src/presentation/rigs/desktop_command_rig.gd`, `src/presentation/bunker/hardware/tactile_console.gd`, `src/presentation/war_table/war_table.gd`, `src/presentation/bunker/command_bunker.gd`, `tests/test_phases_5_6_7.gd`
- **Features:**
  - **3D VR Gauntlets, Dynamic Laser Pointers, Target Reticles & Desktop VR Simulator (`[F11]`):** Full 3D hand visuals, color-coded laser pointers, and surface reticles operable via OpenXR hardware controllers or Desktop VR Simulator mode (`VR HANDS [F11]`).
  - **Diegetic 3D Left-Wrist C4ISR Tablet & 3D Overhead Bunker Hologram Board:** Stereo 3D holographic displays showing live Casualties (`KIA`/`WIA`), Ammunition Stocks (`Remaining %`/`Fired`/`In-Air`/`Intercepts`), 1,000,000-unit Global ORBAT, and `Company -> Battalion -> Brigade` organization inside the 3D bunker.
  - **VR 3D Sphere Volume Group Selection, 1-Button Battalion/Brigade Escalation & Laser Orders:** Drag a 3D selection sphere in VR to group units, press `A` to escalate Company $\rightarrow$ Battalion $\rightarrow$ Brigade, and press `Left Trigger` / `B` to issue 3D Move Waypoints or Strike Salvos with haptic feedback.
  - **Direct 3D Console Switch Actuation (Hand Poke + Laser + Mouse) & 3D Planetary Globe Flashpoint Clicking:** All 10 physical 3D switches/buttons on `TactileConsole` and all 7 Global Flashpoint Beacons on the 3D Planetary Globe can be clicked or poked directly in 3D space.
- **Phase 17 (`BudgetTechSystem`, 5-Branch R&D Technology Tree, DEFCON 5->1 Escalation Loop, Simulated World News, Presidential Emergency Directives & NBC/EMP/Orbital/Thermonuclear Warfare) — COMPLETED:**
  - **Defense Budget & Strategic Task Force Procurement (`src/sim_core/systems/budget_tech_system.gd`):** Added live Defense Budget (`$M USD`), continuous wartime appropriations (`+$M/min`), Emergency Strategic Airlift Resupply (`$250M`), and 4 procurable Reinforcement Task Forces (`TF_STEALTH_AIR`, `TF_ROBOT_ARMOR`, `TF_LASER_IADS`, `TF_NAVAL_STRIKE`).
  - **15-Node 5-Branch R&D Technology Tree (`tech_tree_nodes` in `wargame.db` & `SimDB`):** Seeded 15 technologies across `ROBOTICS_AI`, `DIRECTED_ENERGY`, `HYPERSONIC_STEALTH`, `C4ISR_LOGISTICS`, and `NBC_APOCALYPSE`, dynamically modifying RCS, radar range, missile speed, $P_k$, laser recharge, Robot Dog mobility, automated missile printing, and EW/CBRN immunity.
  - **Escalating Game Loop (`DEFCON 5 -> DEFCON 1`), World News Wire & Presidential Declarations:** Added live `defcon_level` (`5..1`), `global_escalation_score` (`0..100%`), Presidential Emergency Action Directives (`PEAD`), and simulated international news agency headlines (`REUTERS`, `BBC WORLD`, `UN OCHA`, `SPACECOM`, `USSTRATCOM`) across Desktop HUD, `BunkerMainMenu` Tab 6 (`[K]`), 3D VR Left-Wrist C4ISR Tablet, and 3D Overhead Bunker Hologram Board.
  - **NBC, HEMP EMP, Orbital Kinetic Rods & Thermonuclear Warfare:** Implemented `STRIKE_TACTICAL_CBRN`, `STRIKE_HEMP_EMP`, `STRIKE_ORBITAL_RODS`, and `STRIKE_THERMONUCLEAR` (`[N]`) with 3D expanding Nuclear Mushroom Cloud domes, HEMP shockwave hemispheres, and Orbital Kinetic Rod beams in `VisualSyncController`.
- **Phase 18 (Audio UX Overhaul, Male & Female Military Officer Formant Voice Synthesizer, 3D Bunker DEFCON Atmosphere & Physical Command Bunker Relocation / Capture / Destruction Game Over) — COMPLETED:**
  - **Warm Rate-Limited Audio & Male/Female Officer Formant Voice Engine (`src/presentation/audio/bunker_radio_synth.gd`):** Eliminated high-pitched sine beeps and combat spam with warm low-pass filtered tactile clicks/thumps (`3.2s` cooldown), `[M]` Mute toggle, and 4 Male & Female Military Officer Personas (`CAPT. ELENA ROSTOVA`, `COL. MARCUS VANCE`, `GEN. VICTORIA STERLING`, `LT. COL. VIKTOR KOVALENKO`) using multi-syllable vowel formant synthesis ($F_0 + F_1 + F_2$).
  - **3D Bunker DEFCON Atmosphere & Forward Bulkhead Wall Display (`src/presentation/bunker/command_bunker.gd`):** Added dynamic DEFCON 5->1 lighting shifts, rotating 3D red/amber alert beacons, seismic bunker tremor, and a 3D Forward Bulkhead Status Board (`BunkerBulkheadStatusBoard3D`).
  - **Physical Command Bunker Base Relocation, Siege, Capture & Destruction (`GAME OVER`):** Seeded 3 hardened Command Bunker sites per theater (`THEATER_BUNKER_SITES`), rendered a 3D Citadel Pyramid on the War Table, added `[R] RELOCATE HQ` (`relocate_bunker()`), and implemented kinetic damage & ground-breach capture (`damage_or_capture_bunker()`) triggering automatic **GAME OVER** when `bunker_hp <= 0` or `bunker_capture_progress >= 100%`.
- **Phase 19 (Realistic Satellite / Orbital Rod / Jet / Bomber / Drone / Missile Kinematics & AI Geopolitical Diplomacy, Sovereign Airspace Access & Coalition Finance Engine) — COMPLETED:**
  - **Realistic Keplerian Satellite Orbits & Mach-24 Orbital Kinetic Tungsten Rods (`StrategicMddSystem`, `SimDB`, `WorldState`):** Set true orbital altitudes (`525 km` LEO SAR, `550 km` Starshield LEO, `1,200 km` SDA Tracking Layer, `20,200 km` MEO GPS/Galileo/BeiDou) and Keplerian orbital speeds ($v = \sqrt{\mu_\oplus / (R_\oplus + h)} = 7.60\text{ km/s}$, $7.59\text{ km/s}$, $7.26\text{ km/s}$, $3.87\text{ km/s}$), plus live Mach-24 (`8.232 km/s`) `orbital_tungsten_rod` munitions descending from `550 km` LEO orbit.
  - **Realistic Operational Altitudes & Speeds for Bombers, Fighters, AWACS/Tankers, UCAVs, Drones & Missiles:** Added `plat_cruise_alt_m` in `SimDB` (`13,800–15,200 m` for strategic bombers like `B-21 Raider`, `10,800–13,500 m` for 4.5th/5th-gen fighters, `9,600–10,800 m` for AWACS/Tankers, `8,500–10,500 m` for Loyal Wingman CCAs, `7,200 m` for MALE UCAVs, `2,400 m` for turbojet OWA drones) and realistic missile apogees (`35 m` sea-skimming cruise, `120 m` FPV kamikaze, `14.5–32 km` lofted BVR/SAM, `28–85 km` mesospheric hypersonic glide).
  - **AI Geopolitical Countries, Autonomous Enemy & Player Diplomacy, Sovereign Airspace Access & Allied Warchest Grants (`src/sim_core/systems/diplomacy_system.gd`):** Seeded 18 Sovereign Nations in `wargame.db` (`sovereign_nations` table) plus procedural AI-generated sovereign states (`generate_ai_country()`), rendered 3D Sovereign Airspace Corridors on the War Table, and implemented `DIPLO_ENVOY_SUMMIT`, `DIPLO_AIRSPACE_ACCESS`, `DIPLO_REQUEST_ALLY_AID` (`+$310M–$620M` allied warchest transfers + continuous `+$M/min`), and `DIPLO_MILITARY_ALLIANCE` (`[G]` hotkey) for both Enemy AI (`FACTION_RED`) and Player (`FACTION_BLUE`).

- **Phase 20 (Live AI War News & Google Veo 3.1 Video Broadcast Engine — `WarNewsVideoSystem`, `generate_war_news_videos.py`, `live_news_worker.py`) — COMPLETED:**
  - **12 Real Google Veo 3.1 Fast (`veo-3.1-fast-generate-001`) + Gemini 2.5 Flash + FFmpeg War News Broadcast Videos (`tools/news_video_pipeline/generate_war_news_videos.py`, `data/news_videos_manifest.json`):** Inspired by `villeraengine`, generated 12 authentic 8-second HD breaking-news videos (`is_veo_generated: true` across all 12 clips: `missile_alpha_strike`, `sam_air_defense_intercept`, `stealth_airstrike_sortie`, `naval_carrier_strike`, `urban_armor_robot_dogs`, `asat_orbital_warfare`, `cyber_hemp_blackout`, `cbrn_hazard_plume`, `orbital_kinetic_rods`, `thermonuclear_detonation`, `diplomatic_alliance_summit`, `bunker_under_attack`) with TV network chyrons, stereo explosion/missile/news ticker audio, `.mp4`, Godot `.ogv`, `.jpg` thumbnails, and `24-frame (6×4)` contact sheet textures.
  - **Runtime Gemini 2.5 Flash Live News & On-Demand Veo 3.1 Video Worker (`tools/news_video_pipeline/live_news_worker.py`):** Generates live AI breaking news bulletins (`data/live_ai_news_latest.json`) and custom Veo 3.1 videos directly from active simulation telemetry (`[J]` hotkey or `AI GEMINI LIVE REPORT [J]`).
  - **Event-Driven Simulation Hookup (`src/sim_core/systems/war_news_video_system.gd`, `SimServer`, `SimDB`, `WorldState`, `SignalBus`):** Automatically switches the live TV broadcast whenever Alpha Strikes, SAM/Laser Intercepts, Runway Craters, Naval Salvos, Robot Dog/Armor Battles, ASAT Kills, HEMP/Cyber Blackouts, CBRN Plumes, Mach-24 Orbital Rods, Thermonuclear Detonations, Diplomatic Summits, or Bunker Breaches/Relocations occur.
  - **3-Surface Live Video Broadcast Display (`DesktopCommandRig`, `CommandBunker`, `BunkerMainMenu`, `BunkerRadioSynth`):** Added the 2D HUD Picture-in-Picture Live TV Monitor (`LiveNewsMonitorPanel`), the 3D Command Bunker Bulkhead Video Wall (`BunkerNewsVideoWall3D`), and `BunkerMainMenu` Tab 7 (`7. LIVE TV NEWS & VEO STUDIO`) with a 12-channel video switcher grid, plus TV newsroom chime and anchor voice callouts.

- **Phase 21 (8-Mission Story Chronicle & Google Veo 3.1 Capabilities Tour — `StoryProgressionDirector` & `op_global_escalation_chronicle_2028`) — COMPLETED:**
  - **Playable Story Progression Scenario (`op_global_escalation_chronicle_2028`) & Director (`src/ai/storyteller/story_progression_director.gd`):** Added a 9th playable scenario (`Operation Doomsday Clock 2028`) and an interactive 8-Mission Historical Story & Capabilities Director (`[P]` hotkey / `[STORY CAMPAIGN (P)]` Top Bar button / Main Menu Tab 1 `M1..M8` selector).
  - **8 Chronological Missions with Live Veo 3.1 TV Broadcasts & Hands-On Capability Objectives:** Steps from `October 14, 2028 (DEFCON 5)` to `November 1, 2028 (DEFCON 1)` across `Taiwan Strait`, `Yushan Ridge`, `Strait of Hormuz`, `Baltic Suwalki Gap`, `Ukraine Donbas`, `Korean DMZ Orbital Space`, and `Himalayan LAC`, pairing each chapter with its Google Veo 3.1 Fast breaking news video, Presidential Directive, Officer Radio Voice callout, and live capability objective (or 1-click `▶ DEMO & ADVANCE CAPABILITY`).

- **Phase 22 (First-Person Cockpit / Drone / Satellite / Robot Dog / Missile Live Feed Camera — `FpvTargetingPodController`) — COMPLETED:**
  - **Live 3D SubViewport + Camera3D FLIR Targeting Pod (`src/presentation/bunker/fpv_targeting_pod_controller.gd`):** Renders a live 3D First-Person camera feed on both a floating 3D Bunker Monitor (`FpvPodMonitor3D`) and a 2D Picture-in-Picture / Fullscreen-Expandable HUD (`[Z]` hotkey / `FPV POD [Z]` button).
  - **3 Camera Attachment Modes & 3 FLIR Palettes:** Supports `MODE_SELECTED_UNIT` (rides in the cockpit/head of `F-35A`, `B-21 Raider`, `Vision 60 Robot Dog`, or `FPV Kamikaze Drone`), `MODE_IN_FLIGHT_MUNITION` (rides on the nosecone of an in-flight `Mach-24 Orbital Tungsten Rod` or hypersonic missile all the way to impact), and `MODE_ORBITAL_SATELLITE` (`550 km` LEO Recon Satellite nadir view at `7.59 km/s`), with `GREEN NVG`, `WHITE-HOT FLIR`, and `EO COLOR` palettes.

- **Phase 23 (Persistent Save / Load Campaign State & Custom Scenario / Force Editor — `CampaignPersistenceSystem`) — COMPLETED:**
  - **Full Campaign Serialization (`src/sim_core/systems/campaign_persistence_system.gd`):** Saves and loads the entire live `WorldState` (all active units, positions, HP, ammo, waypoints, Defense Budgets, unlocked R&D Techs & multipliers, DEFCON level, Weather/Solar/Sea-State, Diplomacy nations/treaties, Bunker integrity/location, and Red Phone state) to `res://data/saves/campaign_<slot_id>.json` (`[F5]` Save / `[F9]` Load / Tab 8).
  - **Custom Force Spawner & Scenario JSON Exporter:** Allows spawning custom units (`spawn_custom_editor_unit()`) and exporting the live War Table ORBAT to `res://data/saves/custom_scenario_<slug>.json` (`export_custom_scenario()`).

- **Phase 24 (Dynamic Weather, Day/Night Solar Terminator & Sea-State Physics — `WeatherSolarSystem`) — COMPLETED:**
  - **5 Theater Weather Regimes & Beaufort Sea States (`src/sim_core/systems/weather_solar_system.gd`):** Simulates `CLEAR`, `OVERCAST`, `TYPHOON_STORM`, `SANDSTORM`, and `ARCTIC_BLIZZARD` (`[F6]` hotkey / `WX [F6]` button / Tab 8), Beaufort Sea States (`2..8`), and the 24-hour UTC Solar Terminator cycle (`solar_hour_utc`, `is_night_cycle`).
  - **Physical Sensor, Laser & USV Attenuation (`SensorLoSSystem`, `SalvoCombatSystem`, `KinematicsSystem`):** Typhoon clouds/rain/sandstorms attenuate `IR_EO` thermal range (`weather_ir_eo_mult`) and `100kW Iron Beam` optical laser range/dwell (`weather_laser_mult`) while leaving `ACTIVE_RADAR`, `SAT_SAR_EO`, and `30° HPM` microwave cones all-weather capable; high Beaufort sea states slow surface kamikaze USVs (`weather_usv_speed_mult`) while submerged `Orca XLUUV` submarines remain unaffected.

- **Phase 25 (Live AI Enemy Leader Video/Voice Ultimatums & 3D Red Phone Hotline Negotiations — `RedPhoneHotlineSystem`) — COMPLETED:**
  - **Physical 3D Red Hotline Phone (`RedPhoneHotline3D` on `TactileConsole`) & Crisis Engine (`src/sim_core/systems/red_phone_hotline_system.gd`):** Added a physical 3D Red Phone on the Command Bunker console (`[Y]` hotkey / `RedPhoneHotline3D`) that pulses crimson when ringing with ultimatums from theater OPFOR Supreme Commanders (*Gen. Chen Wei-Guo*, *Gen. Aleksandr Voronov*, *Supreme Marshal Kim Jong-Sik*, *Cmdr. Hossein Salami-Nouri*).
  - **4 Strategic Negotiation Choices (`Tab 8` / `resolve_red_phone_hotline()`):** Supports `HOTLINE_ACCEPT_CEASEFIRE` (`45s` bilateral salvo pause, `-18%` escalation), `HOTLINE_BRIBE_DEESCALATE` (`$400M` sanctions/trade concession for `60s` ceasefire, `-28%` escalation), `HOTLINE_BLUFF_DETERRENCE` (`+8%` Blue missile $P_k$, panics 50% of OPFOR radars into EMCON silence), and `HOTLINE_REJECT_ESCALATE` (slams down the phone, unlocking `+$500M` emergency wartime budget and escalating toward `DEFCON 1`).

- **Phase 26 (Civilian Highway Traffic, Refugee Evacuation Convoys, Maritime Shipping Lanes & VBSS Interdiction — `CivilianTrafficConvoySystem`) — COMPLETED:**
  - **Live 3D Highway Traffic & Commercial Shipping Lanes (`src/sim_core/systems/civilian_traffic_convoy_system.gd`):** Spawns and steps up to `48` live 3D commuter convoys, refugee evacuation columns, overland MSR military supply trucks, and commercial LNG/Oil tankers along `road_segments_km` and theater sea lanes, rendered in 3D via `VisualSyncController`.
  - **Official Humanitarian Evacuation Corridors & Maritime VBSS Interdiction (`[F7]` / Tab 8):** Supports `declare_humanitarian_corridor()` (`+65%` civilian highway evacuation speed for `90s`, `+$200M` UN humanitarian grant, `-10%` escalation) and `execute_maritime_interdiction()` (boards and seizes sanctioned OPFOR tankers for `+$180M`).

- **Phase 27 (Subterranean Underground Tunnel Networks, Deep Hardened Mountain Bunkers, `GBU-57 MOP` Strikes & Robot Dog Tunnel Breach — `SubterraneanTunnelSystem`) — COMPLETED:**
  - **Authentic Subterranean Complexes Across All 7 Theaters (`src/sim_core/systems/subterranean_tunnel_system.gd`):** Seeds underground mountain airbases, DMZ infiltration tunnels, salt-mine galleries, and subterranean missile cities (*Chiashan*, *Chihhang*, *Fujian Longtian*, *KPA 3rd/4th DMZ Tunnels*, *Hajjiabad Missile City*, *Soledar Salt Mines*, *Azovstal*, *Kaliningrad*, *Aksai Chin*), rendered as 3D subterranean corridors and octagonal tunnel portals on the War Table.
  - **3 Counter-Tunnel Operations (`[F8]` / Tab 8):** Supports `TUNNEL_GPR_SCAN` (Seismic Ground-Penetrating Radar & Acoustic Array mapping), `BUNKER_BUSTER_MOP` (30,000-lb `GBU-57A/B` earth-penetrating ordnance that collapses subterranean roofs), and `ROBOT_DOG_TUNNEL_BREACH` (`Vision 60 Q-UGV` Lidar Robot Dog + SpecOps subterranean assault that captures underground arsenals intact for `+$250M`).

- **Phase 28 (Strategic CEMA Cyber-EW Matrix, SCADA Power Grid Blackouts, DRFM Ghost Decoys & RF Drone Swarm Hijacking — `CemaElectronicWarfareSystem`) — COMPLETED:**
  - **Full-Spectrum Offensive & Defensive CEMA Matrix (`src/sim_core/systems/cema_electronic_warfare_system.gd`):** Tracks national electrical grid integrity (`blue_power_grid_pct`, `red_power_grid_pct`), cyber firewalls, hijacked UAVs, and 3D DRFM holographic phantom radar ghost decoys (`ghost_decoy_positions_km`).
  - **4 Executable CEMA Operations (`[F10]` / Tab 8):** Supports `CEMA_GRID_BLACKOUT` (SCADA logic bomb plunging OPFOR power grid by `-48%` and disabling stationary SAM radars), `CEMA_DRONE_HIJACK` (RF/GNSS protocol takeover flipping enemy `FLAG_RF_DATALINK` UAVs to `FACTION_BLUE` while `FLAG_FIBER_OPTIC` spool drones remain physically immune), `CEMA_DEEPFAKE_GHOST_DECOYS` (injects `8` 3D holographic phantom stealth formations into OPFOR IADS), and `CEMA_QUANTUM_FIREWALL_PATCH` (restores Blue Power Grid & purges jamming).

- **Phase 29 (5 Selectable War Table Graphic Styles & Visual/UX Polish — `war_table_terrain.gdshader`, `WarTable`, `DesktopCommandRig`, `BunkerMainMenu`) — COMPLETED:**
  - **5 Real-Time Shader Visual Modes (`graphic_style_mode = 0..4`):**
    1. `0: HOLO C4ISR OBSIDIAN` (Signature dark obsidian + glowing cyan/emerald topographic contours)
    2. `1: SATELLITE TRUE-EARTH DAYLIGHT (GEOINT EO)` (True-color satellite ocean blue, lush green forests/lowlands, arid foothills, grey granite & alpine snow peaks `>2100m`)
    3. `2: NIGHT-VISION FLIR GREEN (AN/AAQ-33)` (Military thermal phosphor green NVG with scanlines & hot white-green target highlights)
    4. `3: RETRO NORAD WOPR AMBER (1983 CRT)` (Glowing vector amber-orange CRT on pitch black)
    5. `4: NATO TOPOGRAPHIC SITUATION MAP` (Bright parchment/ivory topographic relief map with crisp dark contour lines & deep navy sea)
  - **Instant UI & Hotkey Switching (`[F12]`):** Added `[STYLE: HOLO C4ISR (F12)]` button in the Top Bar (`DesktopCommandRig`) and a 5-Button **WAR TABLE GRAPHIC STYLE** selector bar at the top of `BunkerMainMenu` (`[ESC]`).

- **Phase 30 (Visible Moving Infantry, Snipers & Commandos + Live `.50 BMG` & JTAC Laser Target Designator Beams) — COMPLETED:**
  - **3 New Elite Sniper & Commando Platforms in `wargame.db` (`65` Platforms, `31` Weapons):** Added `tier1_sniper_recon_team` (*Tier-1 Sniper & JTAC Recon Team (`M82A1 .50 BMG`)*), `navy_seal_commando_squad` (*Naval Special Warfare SEAL Commando Platoon*), and `spetsnaz_sniper_commando` (*Spetsnaz SSO Sniper & Sabotage Commando Group*) with real Wikipedia photos (`Barrett M82`, `United States Navy SEALs`, `Spetsnaz`) and seeded them across all 8 theater scenarios.
  - **Continuous Tactical Patrols & Visual Ground Maneuver (`KinematicsSystem`, `SimServer`):** Assigned active forward tactical patrol/infiltration waypoints (`unit_has_waypoint = 1`) and continuous patrol generation + visual ground stride pace so Infantry, Snipers, Commandos, Robot Dogs, and Armor visibly march and maneuver across the 3D War Table at `1x` speed.
  - **3D Articulated Soldier Mesh & Live `.50 BMG` / JTAC Laser Firefights (`VisualSyncController`, `DesktopCommandRig`):** Upgraded `soldiers_mmi` to `_create_tactical_soldier_mesh()` (3D helmet, torso, striding legs, and forward rifle/sniper barrel), colored Snipers & Commandos in high-contrast SpecOps Emerald-Lime / Amber, added live 3D `.50 BMG` sniper tracers, JTAC laser target designator beams, and small-arms tracer bursts, and added **`[I] SNIPERS/COMMANDOS`** button (`[I]` hotkey) to immediately select and zoom (`6.8x`) onto active Sniper & Commando squads.

- **Phase 31 (Combat Engineering, Smart Minefields, AVLB Bridge Rebuild & Airborne Paratrooper / Robot Dog Drops — `CombatEngineeringAirborneSystem`) — COMPLETED:**
  - **3D Airborne Paratrooper & Robot Dog Insertion (`AIRBORNE_PARATROOP_DROP` / `[X]` Key):** Drops SEAL Commandos, Tier-1 Snipers, and Vision 60 Robot Dogs from `1,650m` with 3D descending parachute canopies and suspension lines (`parachute_drops`).
  - **Smart Scatterable Minefields & Combat Engineer AVLB Rebuilds (`DEPLOY_SMART_MINEFIELD`, `ENGINEER_BREACH_AND_REBUILD`):** Deploys land/sea smart minefields (`minefields`) rendered as 3D hazard hexagons, and dispatches M1150 Assault Breachers + AVLB bridge layers to clear OPFOR mine belts, repair blown river bridges, clear rubble, and re-rail derailed logistics trains.

- **Phase 32 (Submarine Undersea Cable Sabotage, SOSUS Seabed Hydrophone Arrays & Cable Repair — `UnderseaWarfareSystem`) — COMPLETED:**
  - **Seabed Fiber-Optic Internet Trunk Cables & Offshore Gas Pipelines (`undersea_cables`):** Seeds and renders real-world undersea fiber-optic cables and gas pipelines across the seabed (`TPE/APG`, `Taiwan-Penghu-Kinmen`, `Balticconnector`, `FALCON Hormuz`).
  - **3 Undersea Operations:** Supports `UNDERSEA_DEPLOY_SOSUS_BARRIER` (localizing submerged `FLAG_UUV_SUB` submarines and surface vessels), `UNDERSEA_SABOTAGE_ENEMY_CABLE` (`Orca XLUUV` / SEAL SDV severance of OPFOR subsea trunks, `-22%` Red C2), and `UNDERSEA_REPAIR_CABLE_SHIP` (splicing Allied subsea trunks).

- **Phase 33 (Domestic Homefront Stability, Brent Crude Oil `$/bbl`, Defense Industrial Stock Index & UN War Crimes Surgical ROE — `HomefrontEconomySystem`) — COMPLETED:**
  - **Macro-Economic & UN Tribunal Telemetry:** Tracks `blue_public_support_pct`, `global_oil_price_bbl`, `defense_industrial_index`, and `un_war_crimes_investigation_level`.
  - **3 Executable Homefront & ROE Directives:** Supports `HOMEFRONT_ISSUE_WAR_BONDS` (`+$450M` warchest, `+85` Defense Index), `HOMEFRONT_ENFORCE_SURGICAL_ROE` (clears UN War Crimes scrutiny, `+14%` public support, `+$220M` Coalition legitimacy grant), and `HOMEFRONT_STRATEGIC_PETRO_RESERVE` (`-$32/bbl` Brent Crude, `+$25M/min` budget rate).

- **Phase 34 (Interactive HUD Declutter & Collapsible Drawer Modes — `HUD UX 2.0`) — COMPLETED:**
  - **3 Instant HUD Layout Modes (`[BACKSPACE]` / `[HUD: ... (BKSP)]` Top-Bar Button):** Cycles cleanly between `0: FULL JOC STAFF HUD`, `1: COMPACT TACTICAL HUD` (collapses left SITREP drawer), and `2: CLEAN CINEMATIC WAR TABLE` (hides side and bottom panels for an unobstructed fullscreen view of the 3D War Table).

- **Phase 35 (688(I) Nuclear Attack Submarine VR & Desktop Sim Station — `NuclearSubmarineSystem`, `SubmarineConnController`, `periscope_ocean.gdshader`) — COMPLETED:**
  - **2 New Nuclear Attack Submarine Platforms in `wargame.db` (`67` Platforms, `31` Weapons):** Seeded `ssn_688i_los_angeles` (*USS Cheyenne SSN-688(I) / Virginia Nuclear Attack Submarine*) and `type_093b_shang_ssn` (*PLA Navy Type 093B Shang-III / Akula Nuclear Attack Submarine*) with real Wikipedia photography and `Mk 48 ADCAP` heavyweight torpedoes + `VLS Tomahawk` loadouts.
  - **3D VR Submarine Control Room ("Conn") & Physical Attack Periscope (`SubmarineConnController`):** Built an interactive 3D Submarine Control Room inside the bunker with a physical vertical **Attack Periscope Column**, fold-down grab handles, red combat conn lighting, Broadband Sonar Waterfall console, Helm/Diving/Emergency Ballast Blow levers, and 4-Tube Torpedo / 12-Tube VLS Fire Control board (`[;]` hotkey or **`[⚓ 688 SUB SIM (;)]`** Top/Bottom Bar buttons).
  - **3D Rolling Ocean Waves Shader (`periscope_ocean.gdshader`) & Live 3D Periscope `SubViewport`:** Renders animated Gerstner ocean waves, whitecap foam crests, dynamic Beaufort sea states, 3D enemy Destroyers/Carriers/Submarines positioned at real relative bearings/ranges on the horizon, and **120-meter 3D Torpedo Water Plume geysers** when `Mk 48 ADCAP` torpedoes detonate beneath enemy keels.
  - **Authentic 688(I) Submarine Physics & Acoustic Warfare (`NuclearSubmarineSystem`):** Simulates Depth & Thermal Layer physics (`58 ft` Periscope Depth $\rightarrow$ `280 ft` Thermocline acoustic shadow $\rightarrow$ `420 ft` Below Layer $\rightarrow$ `950 ft` Deep Silent Running $\rightarrow$ `1,450 ft` Crush Depth), Emergency Main Ballast Tank (`EMBT`) Blow, Engine Telegraph (`0..33 kts` Flank with propeller cavitation warnings), Broadband/Narrowband Sonar Waterfall bearing-time tracks, `Mk 48 Mod 7 ADCAP` wire-guided torpedo salvos, `BGM-109 Tomahawk` VLS cruise missile launches, and `MOSS` acoustic decoys.

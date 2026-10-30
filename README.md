# VR & Desktop Holographic Command Bunker (`vrarmygame`)

A next-generation **2025–2030 Multi-Domain Strategic & Tactical Wargame** built in **Godot 4.7 (.NET 8.0 Mono + GDScript)** for **Desktop (Mouse & Keyboard)** and **OpenXR Virtual Reality (Meta Quest 3 / PCVR)**.

Command **1,000,000 combat units** across **7 real-world `2,000 km × 2,000 km` Flashpoint Theaters** from inside a dark brutalist underground command bunker, zooming seamlessly from a **40,000 km 3D Planetary Orbital Globe** down to individual **Quadruped Robot Dog Packs, 12-man Infantry Squads, 4-Ship Stealth Fighter Wings, Aircraft Carrier Strike Groups, and 3,800+ 3D urban buildings**.

---

## Key Features & Capabilities

### 1. 1,000,000 Combat Units Across 7 Global `2,000 × 2,000 km` Theaters
- **Real-World GIS & SRTM/ETOPO DEM Terrain (`tools/terrain_pipeline/generate_theater.py` & `tools/wiki_pipeline/generate_world_map.py`):**
  - Uses **Natural Earth Admin-0 Sovereign Borders** (`177` countries) and **AWS Open Data Mapzen Terrarium / Mapbox Terrain-RGB (`z=6`)** elevation & bathymetry tiles.
- **7 Active Global Flashpoints (`GlobalOrbatSystem`):**
  1. **China / Taiwan Strait (`strait_theater` — 220,000 Units):** *USS Gerald R. Ford (CVN-78)* & *ROCAF 4th TFW* vs *PLA 71st/72nd/73rd Group Armies* & *CNS Fujian (CV-18)*.
  2. **Ukraine Donbas & Black Sea (`ukraine_donbas_theater` — 240,000 Units):** *3rd Assault Bde "Azov"*, *47th Mech Bde "Magura"*, *414th UAV Bde "Madyar's Birds"*, *BTR-4E*, *2S22 Bohdana*, *RK-360MC Neptune* vs *Russian 1st Guards Tank Army*, *58th CAA*, *Admiral Gorshkov*.
  3. **NATO Baltic / Suwalki Gap (`baltic_suwalki_theater` — 160,000 Units):** *Polish 18th "Iron" Div*, *German 45th Panzer Bde*, *FS Charles de Gaulle (R91)*, *HMS Queen Elizabeth (R08)* vs *Russian 11th Army Corps (Kaliningrad)* & *Belarusian Western Operational Command*.
  4. **India / Himalaya LAC (`himalaya_lac_theater` — 150,000 Units):** *Indian XIV "Fire and Fury" Corps*, *INS Vikrant (R11)*, *HAL Tejas Mk2*, *Zorawar Light Tank*, *BrahMos* vs *PLA 76th/77th Group Armies* & *PAF No. 15 "Cobras"*.
  5. **Korean DMZ (`korean_dmz_theater` — 110,000 Units):** *ROK VII "Vanguard" Corps*, *ROKS Jeongjo the Great*, *KF-21 Boramae*, *K2 Black Panther*, *Hyunmoo-5* vs *KPA II Corps* & *105th Ryu Kyong-su Tank Div*.
  6. **US-Mexico Rio Grande & Sierra Madre (`mexico_rio_grande_theater` — 70,000 Units):** *US III Armored Corps (1st Cavalry Div, Fort Cavazos)* vs *SEDENA 1/a Brigada Blindada*, *FAM Escuadrón Aéreo 401*, *ARM Reformador (POLA-101)*.
  7. **Strait of Hormuz (`hormuz_theater` — 50,000 Units):** *USS Abraham Lincoln (CVN-72) CSG-3* vs *IRGCN 1st Naval Region (Bandar Abbas)*.
- **92/92 Authentic Wikipedia/Wikimedia Platform & Weapon Photographs:**
  - `62` platforms across `11` armed forces (`USA`, `EUR_NATO`, `UKR`, `MEX`, `CHN`, `RUS`, `KOR`, `PRK`, `IND`, `PAK`, `TUR`) and `30` weapons/munitions with real Wikipedia photography, radar cross-sections (RCS), Mach speeds, and unit dollar costs (`$M USD`).

### 2. True 1:1 Real-Time Physical Speeds + High Time Acceleration (`0x` to `900x`)
- **True 1:1 Real-Time Simulation at `1x REAL`:**
  - Units and missiles move at exact physical speeds (`1 kt = 1.852 km/h = 0.0005144 km/s`, `Mach 1 = 343 m/s = 0.343 km/s`).
- **One-Click Time Acceleration:**
  - Instant HUD and 3D Console controls for **`0x PAUSE`**, **`1x REAL`**, **`10x`**, **`60x`**, **`300x`**, and **`900x`** (up to `1800x`).

### 3. 3-Tier Force Organization (`Company -> Battalion -> Brigade`), Easy Group Selection & Reliable Orders
- **3-Tier Hierarchy (`EchelonClusterSystem`):**
  - **Company / Flight / Battery (`[0]`)** $\rightarrow$ **Battalion / Squadron (`[1]` — 6 Companies)** $\rightarrow$ **Brigade / Air Wing / Carrier Strike Group (`[2]` — 36 Companies)**.
- **Effortless Selection & Grouping (Desktop & VR):**
  - **Desktop Box-Drag (Marquee Selection)** or **VR Right-Trigger 3D Sphere Volume Selection** selects all friendly units inside the region.
  - **`[B]` (`[B] BATTALION`)** & **`[V]` (`[V] BRIGADE`)** buttons immediately expand selection to the entire parent Battalion or Brigade, highlighted with golden 3D selection rings and C2 hierarchy tether lines.
  - **Domain Selection (`ALL AIR`, `ALL LAND`, `ALL SEA`)** and **Control Groups (`Ctrl + 1/2/3` to save, `Alt + 1/2/3` to recall)**.
- **Reliable Order Execution:**
  - Right-click (or VR Left Trigger / `B`) on terrain to order formation movement (`Shift + Right-Click` chains multi-waypoint dogleg routes), or Right-click an enemy unit to fire an immediate Strike Salvo and intercept vector. Player orders lock `DIRECT_PLAYER_CONTROL` (`180s` override) so autonomous AI never overwrites your waypoints.

### 4. Live Casualties (`KIA`/`WIA`) & Ammunition Telemetry for All Sides (`BLUE` & `RED`)
- **Real-Time Casualties Ledger:** Tracks **Personnel KIA & WIA** using authentic platform crew complements (`0` for unmanned Robot Dogs/FPVs/USVs, `4–12` for aircraft flights, `16` for armor/SAMs, `36` for infantry companies, `260` for warships, `2,800` for aircraft carriers), plus platform category losses (`Air`, `Land`, `Sea`, `Drone`, and `$M USD`).
- **Real-Time Ammunition Ledger:** Tracks **Remaining Stock (`%`)**, **Fired/Expended Munitions**, **In-Flight Salvos**, and **Intercepts** across both sides on the Top Bar, Left SITREP Card, 3D Overhead Bunker Hologram Board, and 3D VR Left-Wrist C4ISR Tablet.

### 5. Desktop (`DesktopCommandRig`) & OpenXR VR (`XRCommandRig`) Parity
| Action | Desktop (`DesktopCommandRig`) | OpenXR VR (`XRCommandRig` + `[F11]` VR Simulator) |
| :--- | :--- | :--- |
| **Pan & Zoom (5 Tiers)** | `WASD` Pan, `Scroll Wheel` / `Q` & `E` Zoom, `[O]` Cycle Orbital Globe | Two-Hand Grip Pinch-Zoom & Pan, Single-Hand Grip Grab-Pan, Thumbsticks |
| **Select Unit / Group** | `Left-Click` 3D Ray Pick, `Left-Mouse Drag` Marquee Box | `Right Trigger` Tap Laser Pick, `Right Trigger Hold-Drag` 3D Sphere Volume |
| **Select Battalion / Brigade** | `[B]` Battalion (6 Cos), `[V]` Brigade (36 Cos), `ALL AIR/LAND/SEA` | `Right A/X Button` Cycles `Company -> Battalion -> Brigade`, or 3D Console Buttons |
| **Move / Strike Order** | `Right-Click` Terrain (Move) or Enemy (Strike), `Shift+RMB` Chain Waypoints | `Left Trigger` or `Right B/Y Button` Laser Move / Strike Salvo |
| **Time Acceleration** | HUD Buttons (`0x`, `1x`, `10x`, `60x`, `300x`, `900x`), `[T]`, `-` / `=` | `Left X/A Button` or Poke/Laser `TimeScaleThrottle` on 3D Console |
| **Deploy Robot Dogs / FPV** | `[U]` or `[6]` Key / HUD Button | `Left Y/B Button` or Poke `DeployUnmannedButton3D` on 3D Console |
| **Alpha Strike & IADS** | `Space` Alpha Strike, HUD / 3D Console Switches | Physical Hand Poke or Laser Click on 3D `TactileConsole` Switches |
| **R&D Tech Tree & Budget** | `[K]` Key or `[R&D TECH TREE & BUDGET (K)]` Top/Left HUD Buttons | 3D Left-Wrist C4ISR Tablet + Bunker Menu Tab 6 |
| **NBC / HEMP / Rods / Nuke** | Left HUD Quick-Bar (`CBRN`, `HEMP`, `RODS`, `[N] NUKE`) or `[N]` Key | Bunker Menu Tab 6 / Escalation Deck |
| **Relocate HQ Bunker** | `[R]` Key or `[R] RELOCATE HQ` Left HUD / Tab 6 Button | Bunker Menu Tab 6 (`[RELOCATE HQ BUNKER $200M (R)]`) |
| **AI Diplomacy & Airspace** | `[G]` Key or Tab 6 (`AIRSPACE TREATY`, `ALLIED AID +$M`, `DEFENSE PACT`) | Bunker Menu Tab 6 Diplomacy Deck |
| **Live TV News & Veo Studio** | `[J]` Live AI Gemini Report, Bottom-Right PiP TV Monitor, Tab 7 (`TV STUDIO`) | **3D Bulkhead Live TV Video Wall** + Bunker Menu Tab 7 (`12 Veo 3.1 Channels`) |
| **8-Mission Story Chronicle** | `[P]` Key or `[STORY CAMPAIGN (P)]` Top Bar / Tab 1 `M1..M8` / Tab 2 `OP 9` | Bunker Menu Tab 1 / Tab 2 (`Operation Doomsday Clock 2028`) |
| **Audio & Officer Voices** | `[M]` Key or `[AUDIO/VOICE: ON (M)]` Top Bar Button | 3D Forward Bulkhead Officer Comms Board |
| **Live C4ISR Telemetry** | Top Bar, Left SITREP Panel, Right Recon Dossier (`[TAB]`) | **3D Left-Wrist C4ISR Tablet** + **3D Overhead Bunker Hologram Board** |

### 6. Defense Budget, 5-Branch R&D Technology Tree, DEFCON 5 $\rightarrow$ 1 Escalation, World News & NBC / Thermonuclear Warfare
- **Live Defense Budget (`$M USD`) & Strategic Procurement (`[K]`):**
  - Receive continuous wartime budget appropriations (`+$48M–$320M/min`) and Congressional emergency grants at each DEFCON transition.
  - Procure **Emergency Ammo Airlifts (`$250M`)** and **4 Reinforcement Task Forces** (*Stealth Air Wing*, *Robot Dog Armor TF*, *Laser/Patriot IADS*, *Hypersonic Naval TF*).
- **15-Node R&D Technology Tree Across 5 Branches (`wargame.db`):**
  1. **Robotics & AI Swarms:** *Quadruped Pack Autonomy* $\rightarrow$ *Fiber-Optic FPV Swarm Saturation* $\rightarrow$ *Neural CCA Loyal Wingmen*.
  2. **Directed Energy & IADS:** *300 kW Solid-State Laser* $\rightarrow$ *Wide-Cone HPM EMP* $\rightarrow$ *Aegis GPI Hypersonic Interceptor*.
  3. **Hypersonic & Stealth:** *Plasma Metamaterial Stealth RAM* $\rightarrow$ *Dual-Pulse Scramjet* $\rightarrow$ *Project Thor Mach-24 Orbital Tungsten Rods*.
  4. **C4ISR & Logistics:** *Quantum LEO SAR & Photonic Mesh* $\rightarrow$ *3D-Printed Smart Ammo Factories* $\rightarrow$ *Defense Production Act Surge*.
  5. **NBC & Apocalypse Warfare:** *MOPP-5 & Tactical CBRN Plume* $\rightarrow$ *Exoatmospheric HEMP EMP Super-Burst* $\rightarrow$ *PEAD-99 Strategic Thermonuclear Triad*.
- **Escalating Doomsday Loop (`DEFCON 5 -> DEFCON 1`), World News & Presidential Directives:**
  - Watch the conflict spiral out of control through live **World News Wire Flashes** (`REUTERS`, `BBC WORLD`, `UN OCHA`, `SPACECOM`, `USSTRATCOM`) and **Presidential Emergency Action Directives (`PEAD`)**, culminating in **Tactical CBRN Plumes**, **350 km HEMP EMP Blackouts**, **Mach-24 Orbital Kinetic Rods**, and **350-kt Thermonuclear Mushroom Clouds (`[N]`)** on the 3D War Table.

### 7. Live AI War News & Google Veo 3.1 Video Broadcast Engine (`WarNewsVideoSystem`)
- **12 Real Google Veo 3.1 Fast (`veo-3.1-fast-generate-001`) + Gemini 2.5 Flash HD War News Videos (`tools/news_video_pipeline/`):**
  - Every major battlefield event—Alpha Strikes, Patriot/S-400/Laser Air Defense Intercepts, Stealth Runway Cratering, Carrier Anti-Ship Salvos, Urban Robot Dog & Armor Offensives, ASAT Orbital Kills, HEMP/Cyber Grid Blackouts, CBRN Plumes, Mach-24 Orbital Tungsten Rods, DEFCON 1 Thermonuclear Detonations, Diplomatic Summits, and Command Bunker Breach Alerts—automatically cuts the bunker's television monitors to a real Veo 3.1 breaking news video broadcast with live theater casualties and missile counts embedded in the lower-third chyron.
- **3-Surface Live Video Broadcast Display & Runtime Gemini 2.5 Flash Live News Worker (`[J]`):**
  - Watch live broadcasts on the **2D HUD Picture-in-Picture TV Monitor** (`DesktopCommandRig`), the **3D Forward Bulkhead Live TV Video Wall** (`BunkerNewsVideoWall3D` in `CommandBunker`), or **Main Menu Tab 7 (`7. LIVE TV NEWS & VEO STUDIO`)**, and press **`[J]`** at any time to invoke `tools/news_video_pipeline/live_news_worker.py` (`gemini-2.5-flash-lite` + `veo-3.1-fast-generate-001`) for a live AI-authored breaking news bulletin.

### 8. 8-Mission Historical Story Chronicle & Capabilities Tour (`Operation Doomsday Clock 2028` — `[P]`)
- **Chronological 8-Chapter Campaign (`src/ai/storyteller/story_progression_director.gd` & `op_global_escalation_chronicle_2028`):**
  - Press **`[P]`** (`[STORY CAMPAIGN (P)]` on the Top Bar) or launch **`★ OP 9: DOOMSDAY CLOCK 2028`** from Main Menu Tab 1 / Tab 2 to experience the complete historical progression of the 2028 Global Conflict from **`DEFCON 5 (Oct 14, 2028)`** to **`DEFCON 1 (Nov 1, 2028)`**.
  - Each of the 8 missions loads its theater, plays its **Google Veo 3.1 Fast TV News Video Broadcast**, delivers a **Presidential Emergency Directive** and **Male/Female Officer Voice Briefing**, and introduces one of the game's core capabilities with a hands-on objective (or 1-click **`▶ DEMO & ADVANCE CAPABILITY`** button):
    1. **Mission 1 (`DEFCON 5` — Taiwan Strait):** 6-Spectrum IADS Radar, 3-Tier Battalion/Brigade Grouping (`[B]`/`[V]`), and Real-Time Physical Speeds.
    2. **Mission 2 (`DEFCON 4` — Yushan Ridge):** Quadruped Robot Dogs (3D LiDAR climbing `>30°` cliffs) & Jam-Proof Fiber-Optic FPV Swarms (`[U]`).
    3. **Mission 3 (`DEFCON 4` — Strait of Hormuz):** Naval Kamikaze USV Wolfpacks, Orca XLUUV Submarines & Coordinated Alpha Strikes (`[SPACE]`).
    4. **Mission 4 (`DEFCON 3` — Baltic Suwalki Gap):** AI Geopolitical Diplomacy (`[G]`), Sovereign Airspace Access Treaties & `+$M` Allied Warchest Grants.
    5. **Mission 5 (`DEFCON 3` — Ukraine Donbas & Azov):** Defense Budget (`$M`), 15-Node 5-Branch R&D Tech Tree (`[K]`) & Emergency Ammo Airlifts.
    6. **Mission 6 (`DEFCON 2` — Korean DMZ & 3D Orbital Globe):** 3D Planetary Globe (`0.22x`), Keplerian Satellites (`550 km` at `7.59 km/s`), ASAT (`[7]`), Cyber (`[8]`) & HEMP EMP.
    7. **Mission 7 (`DEFCON 2` — 5,600m Himalayan LAC):** Physical HQ Bunker Siege Defense, MOPP-4 CBRN Protection (`[0]`) & E-4B Nightwatch HQ Relocation (`[R]`).
    8. **Mission 8 (`DEFCON 1` — Strategic Climax):** Project Thor Mach-24 Orbital Kinetic Tungsten Rods (`8.23 km/s`), Thermonuclear Triad (`[N]`) & Live AI Gemini TV (`[J]`).
- **First-Person Cockpit / Drone / Satellite / Robot Dog / Missile Live Feed Camera (`FpvTargetingPodController`, Phase 22):**
  - Press **`[Z]`** (or click **`FPV POD [Z]`**) to open/toggle the live 3D FLIR Targeting Pod Camera (`SubViewport` + `Camera3D` + 3D Bunker Monitor `FpvPodMonitor3D`), riding inside any selected `F-35A`, `Vision 60 Robot Dog`, or `FPV Kamikaze Drone`, riding on the nosecone of an in-flight `Mach-24 Orbital Tungsten Rod`, or looking down from a `550 km` LEO Recon Satellite (`7.59 km/s`).
- **Dynamic Weather, Day/Night Solar Terminator & Beaufort Sea-State Physics (`WeatherSolarSystem`, Phase 24):**
  - Press **`[F6]`** (or click **`WX [F6]`** / Main Menu Tab 8) to cycle between `CLEAR`, `OVERCAST`, `TYPHOON_STORM`, `SANDSTORM`, and `ARCTIC_BLIZZARD` (`Beaufort 2–8`), physically attenuating `IR_EO` sensors, `100kW Iron Beam` lasers, and surface `USV` speeds while `ACTIVE_RADAR`, `30° HPM` microwave cones, and submerged `Orca XLUUV` submarines remain all-weather capable.
- **3D Red Phone Hotline Ultimatums & Crisis Negotiations (`RedPhoneHotlineSystem`, Phase 25):**
  - Click the physical **3D Red Hotline Phone (`RedPhoneHotline3D`)** on the Command Bunker console or press **`[Y]`** to answer encrypted ultimatums from opposing theater Supreme Commanders (*Gen. Chen Wei-Guo*, *Gen. Aleksandr Voronov*, *Supreme Marshal Kim Jong-Sik*, *Cmdr. Hossein Salami-Nouri*) and choose between a `45s Ceasefire`, `$400M Concession Treaty`, `Coercive Orbital Deterrence Bluff`, or `Reject & Unlock +$500M Wartime Budget`.
- **Persistent Campaign Save / Load & Custom Scenario Exporter (`CampaignPersistenceSystem`, Phase 23):**
  - Press **`[F5]`** to save and **`[F9]`** to load the complete live war state (`res://data/saves/campaign_slot_1.json`), or export custom scenarios from Main Menu Tab 8 (`res://data/saves/custom_scenario_*.json`).
- **Civilian Highway Traffic, Refugee Evacuation Convoys & Maritime Shipping Interdiction (`CivilianTrafficConvoySystem`, Phase 26):**
  - Live 3D commuter traffic, refugee evacuation columns, military MSR supply trucks, and commercial LNG/Oil tankers flow along the city street grids, inter-city highways, and sea lanes. Press **`[F7]`** (or click **`EVAC/VBSS [F7]`** / Tab 8) to declare an Official UN Humanitarian Evacuation Corridor (`+$200M` UN grant, `+65%` evacuation speed, `-10%` escalation) and execute Naval VBSS Tanker Interdictions (`+$180M` seized contraband).
- **Subterranean Underground Tunnel Networks, `GBU-57 MOP` Bunker-Busters & Robot Dog Tunnel Breach (`SubterraneanTunnelSystem`, Phase 27):**
  - Every theater features authentic subterranean mountain airbases, DMZ infiltration tunnels, and underground missile galleries (*Chiashan*, *Fujian Longtian*, *KPA 3rd/4th DMZ Tunnels*, *Hajjiabad Missile City*, *Soledar Salt Mines*, *Kaliningrad*, *Aksai Chin*). Press **`[F8]`** (or click **`TUNNEL OPS [F8]`** / Tab 8) to run Seismic GPR Scans, launch `GBU-57 MOP` earth-penetrating bunker-buster strikes, or send `Vision 60` Quadruped Robot Dog packs underground to capture tunnel complexes intact (`+$250M`).
- **Strategic CEMA Cyber-EW Matrix, SCADA Power Grid Blackouts & RF Drone Swarm Hijacking (`CemaElectronicWarfareSystem`, Phase 28):**
  - Press **`[F10]`** (or click **`CEMA CYBER [F10]`** / Tab 8) to execute SCADA Power Grid Blackouts (`-48%` OPFOR electrical grid), hijack enemy RF-datalinked UAV swarms mid-flight (`CEMA_DRONE_HIJACK`, flipping them to `FACTION_BLUE` while Fiber-Optic spool drones remain immune), inject `8` 3D DRFM Phantom Radar Ghost Decoys (`CEMA_DEEPFAKE_GHOST_DECOYS`), or apply a Quantum Zero-Trust Firewall Patch.
- **5 Selectable War Table Graphic Styles (`war_table_terrain.gdshader`, Phase 29):**
  - Press **`[F12]`** (or click **`[STYLE: ... (F12)]`** in the Top Bar / the 5-button **WAR TABLE GRAPHIC STYLE** bar in the `[ESC]` Main Menu) to switch between **`1: HOLO C4ISR OBSIDIAN`**, **`2: SATELLITE TRUE-EARTH DAYLIGHT`**, **`3: NIGHT-VISION FLIR GREEN`**, **`4: RETRO NORAD WOPR AMBER`**, and **`5: NATO TOPOGRAPHIC MAP`**.
- **Visible Moving Infantry, Snipers & Commandos + Live `.50 BMG` & JTAC Laser Beams (Phase 30):**
  - Press **`[I]`** (or click **`[I] SNIPERS/COMMANDOS`** in the Force Org bar) to select and focus the camera (`6.8x` Tactical Valley View) directly onto active **Tier-1 Sniper & JTAC Recon Teams (`M82A1 .50 BMG`)**, **Navy SEAL Commando Platoons**, **Mountain SpecOps**, and **Spetsnaz Commandos** as their 12-man 3D articulated squads visibly march across the terrain and fire live `.50 BMG` sniper tracers, JTAC laser target designator beams, and small-arms bursts.
- **Airborne Paratrooper Drops, Smart Minefields, Subsea Cables, Homefront Economy & Clean HUD Modes (Phases 31–34):**
  - Press **`[X]`** (or click **`PARA/MINES [X]`**) to drop Airborne SEALs, Snipers & Vision 60 Robot Dogs under 3D descending parachutes, deploy scatterable land/sea smart minefields, and dispatch Combat Engineers (`AVLB` bridge rebuilds & mine breaching).
  - Click **`SUBSEA/ROE`** (or Tab 8) to deploy **SOSUS Seabed Hydrophone Arrays**, sever OPFOR **Subsea Fiber-Optic Cables** (`-22%` Red C2), issue **Defense War Bonds (`+$450M`)**, release the **Strategic Petroleum Reserve (`-$32/bbl`)**, and enforce **Surgical Precision ROE** (`+$220M` Coalition grant).
  - Press **`[BACKSPACE]`** (or click **`[HUD: ... (BKSP)]`** in the Top Bar) to cycle between **`FULL JOC STAFF HUD`**, **`COMPACT TACTICAL HUD`**, and **`CLEAN CINEMATIC WAR TABLE`** (unobstructed fullscreen 3D War Table view).
- **688(I) Nuclear Attack Submarine VR & Desktop Sim Station (`NuclearSubmarineSystem` & `SubmarineConnController`, Phase 35):**
  - Press **`[;]`** (or click **`[⚓ 688 SUB SIM (;)]`** on the Top/Bottom Bar) to step inside the **USS Cheyenne (`SSN-688I`) 3D Submarine Control Room ("Conn") & Attack Periscope Station**.
  - Features a live **3D Rolling Ocean Waves & Warship Horizon Periscope View (`periscope_ocean.gdshader`)**, **360° Periscope Rotation & Stadimeter Rangefinder (`EO Daylight` / `NVG Green` / `White-Hot FLIR`)**, **Broadband/Narrowband Sonar Waterfall Display**, **Thermocline Layer Diving (`58 ft` Periscope $\rightarrow$ `280 ft` Thermal Layer $\rightarrow$ `420 ft` Below Layer $\rightarrow$ `950 ft` Deep)**, **Cavitation & Silent Running Physics (`0–33 kts`)**, **4× `Mk 48 ADCAP` Heavyweight Torpedo Tubes** (producing 120m 3D water plumes on impact), **12× VLS `Tomahawk` Cruise Missile Tubes**, **`MOSS` Acoustic Decoys**, and **Emergency Main Ballast Tank (`EMBT`) Blow**.

---

## Documentation Index

- **[`ARCHITECTURE.md`](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/ARCHITECTURE.md):** Complete system architecture, SQLite schema, 10 Hz `SimServer` + C# `.NET 8.0` SIMD `SimLodKernel`, 6-Spectrum Sensor Fusion math, Unmanned/Directed-Energy warfare, and Phases 1–16 specifications.
- **[`IMPLEMENTATION_PLAN.md`](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/IMPLEMENTATION_PLAN.md):** Phase-by-phase engineering log and 5-Gate automated verification protocol.
- **[`docs/GAME_MANUAL.md`](file:///c:/Users/ljlal/Documents/GitHub/vrarmygame/docs/GAME_MANUAL.md):** Auto-generated Commander's Tactical Field Manual & Encyclopedia synced directly from `data/wargame.db` (`62` platforms, `30` weapons, `7` theaters, `8` operations, `5` tutorial lessons).

---

## Running & Verifying the Project

### 1. Rebuild the SQLite Database & Auto-Sync `docs/GAME_MANUAL.md`
```powershell
python tools/wiki_pipeline/seed_wargame_db.py
```

### 2. Run All 4 Headless Automated Test Gates (`0 Errors`)
```powershell
C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe --headless --path . --script res://tests/test_sim_core.gd
C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe --headless --path . --script res://tests/test_war_table_visuals.gd
C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe --headless --path . --script res://tests/test_full_game_boot.gd
C:\Godot\Godot_v4.7.2-stable_mono_win64_console.exe --headless --path . --script res://tests/test_phases_5_6_7.gd
```

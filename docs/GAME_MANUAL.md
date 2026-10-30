# Commander's Tactical Field Manual & Encyclopedia (Auto-Synced from `wargame.db`)

> **Living Documentation Guarantee:** This manual and the in-game **Field Manual & 5-Step Boot-Camp Tutorial** are generated directly from `data/wargame.db` via `tools/wiki_pipeline/seed_wargame_db.py` so documentation, tutorials, and unit stats never drift out of sync.

---

## Part I: Core Doctrine & Controls

### 1. Desktop & OpenXR VR Controls + 5-Tier Planetary-to-Tactical Zoom
- **Desktop Camera & Table View:** `WASD` Pan | Right-Click Drag Orbit/Pitch | Scroll-Wheel / `Q` & `E` Zoom | `[C]` Tacview 3D Follow Camera | `[F11]` Toggle 3D VR Hands Simulator.
- **OpenXR VR (`XRCommandRig` — Meta Quest 3 / PCVR):** Two-Hand Grip Pinch-Zoom & Pan | Single-Hand Grip Grab-Pan | Right Trigger Tap to Select Unit / Poke 3D Console Switch / Click 3D Globe Flashpoint | Right Trigger Hold-Drag to Expand **3D Holographic Sphere Volume Selector** | Left Trigger or Right `B` Button to Issue 3D Move Waypoint or Strike Vector | Right `A` Button to Escalate `Company -> Battalion -> Brigade` | Left `X` to Cycle Time Scale | Left `Y` to Deploy Robot Dogs / FPVs | Look at **Left Wrist** for live 3D C4ISR Telemetry.
- **5-Tier Zoom Hierarchy (`[O]` / `[G]`):** `0.15x` Planetary 3D Orbital Globe (24 LEO Satellites + 7 Clickable Global Flashpoints) -> `0.45x` Continental Curved Space (`8,000x8,000 km`) -> `1.0x` Theater Macro (`2,000x2,000 km`) -> `2.2x–6.5x` Operational Sector (`Battalions + 3D Cities/Airports/Trains`) -> `6.5x–25.0x` Tactical Valley (`Individual Soldiers, Robot Dogs & 4-Ship Wings`).
- **Interactive Boot-Camp (`[H]`):** Press `H` at any time to toggle the live 5-Step Interactive Boot-Camp Coach with 3D holographic target beacons.

### 2. 3-Tier Force Organization (`Company -> Battalion -> Brigade`), Easy Group Selection & Orders
- **3-Tier Military Hierarchy:** Every force is organized into **Brigades / Air Wings / Carrier Strike Groups (`[2]` — 36 Companies)** -> **Battalions / Squadrons (`[1]` — 6 Companies)** -> **Companies / Flights / Packs (`[0]`)**.
- **Easy Group Selection:**
  - **Left-Mouse Box-Drag (Marquee)** on Desktop or **Right-Trigger Sphere Drag** in VR selects all friendly units inside the region (`Shift` adds to selection).
  - Press **`[B]` (`[B] BATTALION`)** to select the entire parent Battalion (6 Companies) or **`[V]` (`[V] BRIGADE`)** to select the entire parent Brigade (36 Companies), highlighted with golden 3D selection rings and C2 tether lines.
  - Use **`ALL AIR` / `ALL LAND` / `ALL SEA`** buttons or save/recall custom Control Groups with `Ctrl + 1/2/3` and `Alt + 1/2/3`.
- **Reliable Order Execution:** Right-Click (or VR Left Trigger / `B`) on terrain to order formation movement (`Shift + Right-Click` chains multi-waypoint dogleg routes), or Right-Click an enemy unit to fire an immediate Strike Salvo and intercept vector. Player orders lock `DIRECT_PLAYER_CONTROL` (`180s` override) so autonomous AI never overwrites your waypoints.
- **JOC Staff AI Courses of Action (`[F1]`–`[F3]`):** Execute 1-click Theater COAs (`[F1] JFACC Air Sweep`, `[F2] JFLCC Dog/Mech Vanguard`, `[F3] Joint TOT Salvo`) backed by a C# `.NET 8.0` T+15m Lanchester Monte-Carlo forecast.

### 3. True 1:1 Real-Time Physical Speeds, Time Acceleration & Live Casualties/Ammo Telemetry
- **True 1:1 Real-Time Speeds (`1x REAL` Default):** All units and munitions move at exact physical speeds (`1 kt = 1.852 km/h = 0.0005144 km/s`, `Mach 1 = 343 m/s = 0.343 km/s`). Use one-click HUD or 3D Console buttons for **`0x PAUSE`**, **`1x REAL`**, **`10x`**, **`60x`**, **`300x`**, and **`900x`** time acceleration (`[T]`, `-`, `=`).
- **Live Casualties Ledger (`BLUE` & `RED`):** Tracks real-time **Personnel KIA & WIA** based on authentic platform crew complements (`0` for unmanned Robot Dogs/FPVs/USVs, `4–12` for aircraft flights, `16` for armor/SAMs, `36` for infantry companies, `260` for warships, `2,800` for aircraft carriers), plus platform category losses (`Air`, `Land`, `Sea`, `Drone`, and `$M USD`).
- **Live Ammunition Ledger (`BLUE` & `RED`):** Tracks **Remaining Munition Stock (`%`)**, **Expended/Fired Munitions**, **In-Flight Salvos**, and **Successful Intercepts** across both the active theater and all 7 global theaters.

### 4. The 6-Spectrum Sensor Fusion Matrix
1. **Active Radar (`ACTIVE_RADAR`):** Long range (20–420 km), blocked by terrain horizon, scales by $\text{RCS}^{0.25}$. **Warning:** Enemy Passive ESM detects active radars at $1.6\times$ range!
2. **Passive ESM / ELINT (`PASSIVE_ESM`):** Silent receiver that triangulates enemy radar emitters ($1.6\times$ range) and `RF_DATALINK` drones even while your own radar is DARK (EMCON).
3. **Infrared / IRST (`IR_EO`):** Passive thermal detection (14–65 km, boosted $1.85\times$ against afterburning jets). Counters radar stealth (*F-35 / J-20*) without triggering RWR!
4. **3D LiDAR & Computer Vision (`LIDAR_CV`):** Short-range (5.5 km) obstacle & target recognition used by **Quadruped Robot Dogs** and UGVs in cliffs/cities; immune to stealth and jamming.
5. **Acoustic & Sonar (`ACOUSTIC_SONAR`):** Non-Line-of-Sight valley diffraction hears low-flying propeller drones (*Shahed / FPV*) around mountain corners (+450m ridge diffraction); Towed Sonar hunts submerged submarines (*Orca XLUUV*) at sea.
6. **Orbital Satellite (`SAT_SAR_EO`):** 24 LEO Recon/SATCOM/PNT/Early-Warning satellites orbiting overhead.

### 5. Unmanned Warfare: Robot Dogs, FPV Swarms, EW & Directed Energy
- **Quadruped Robot Dogs (*Vision 60 / Unitree B2-W*):** Unpacked in `<15km` tactical zoom (`[U]` or `[6]`). Ignore `>25°` cliff slope penalties, have near-zero RCS (`0.0005 m²`), clamber over urban rubble at `0.92x` speed, suffer `0` human KIA when lost, and carry Javelins/FPVs/Laser designators.
- **EW Jamming vs. Autonomy:** `RF_DATALINK` drones suffer 85% $P_k$ loss inside *Krasukha-4* EW jammer cones; `FIBER_OPTIC` wired FPVs (12 km) and `AUTONOMOUS_AI` Loyal Wingmen/Robot Dogs are 100% immune to jamming!
- **Directed Energy Economy:** Never waste $4.0M *Patriot PAC-3* missiles on $25k *Shahed* drones! Use *Iron Beam 100kW Lasers* ($2/shot) and *Epirus Leonidas HPM Microwaves* (30° EMP cone frying whole swarms).

### 6. 11-Nation Armed Forces, 1,000,000-Unit Global ORBAT & 7 `2,000x2,000 km` Theaters
- **11-Nation Roster (62 Platforms, 30 Munitions — 92/92 Real Wikipedia Photos):** Authentic systems across `USA`, `EUR_NATO`, `UKR`, `MEX`, `CHN`, `RUS`, `KOR`, `PRK`, `IND`, `PAK`, and `TUR`.
- **1,000,000-Unit Multi-Theater Global Order of Battle (`GlobalOrbatSystem`):** Simulates **1,000,000 tactical combat units** (`10,000` Battalion clusters) across all **7 `2,000x2,000 km` Global Theaters of War** simultaneously with authentic historical formation callsigns, aircraft carriers, and bases:
  1. `ukraine_donbas_theater` (**240,000 Units** — `UKR + NATO` vs `RUS`): *3rd Assault Bde 'Azov'*, *47th Mech Bde 'Magura'*, *414th Strike UAV Bde 'Madyar's Birds'*, *BTR-4E*, *2S22 Bohdana*, *Neptune* vs *1st Guards Tank Army*, *58th CAA*, *Admiral Gorshkov*.
  2. `strait_theater` (**220,000 Units** — `CHN PLA` vs `USA + TWN`): *USS Gerald R. Ford (CVN-78)*, *ROCAF 4th TFW* vs *PLA 71st/72nd/73rd Group Armies* & *CNS Fujian (CV-18)*.
  3. `baltic_suwalki_theater` (**160,000 Units** — `EUR_NATO + USA` vs `RUS + BLR`): *Polish 18th 'Iron' Div*, *German 45th Panzer Bde*, *FS Charles de Gaulle (R91)*, *HMS Queen Elizabeth (R08)* vs *11th Army Corps Kaliningrad*.
  4. `himalaya_lac_theater` (**150,000 Units** — `IND` vs `CHN + PAK`): *Indian XIV 'Fire and Fury' Corps*, *INS Vikrant (R11)*, *Tejas Mk2*, *Zorawar Light Tank*, *BrahMos* vs *PLA 76th/77th Group Armies* & *PAF No. 15 'Cobras'*.
  5. `korean_dmz_theater` (**110,000 Units** — `KOR + USA` vs `PRK`): *ROK VII 'Vanguard' Corps*, *ROKS Jeongjo the Great*, *KF-21 Boramae*, *K2 Black Panther*, *Hyunmoo-5* vs *KPA II Corps* & *105th Ryu Kyong-su Tank Div*.
  6. `mexico_rio_grande_theater` (**70,000 Units** — `USA NORTHCOM` vs `MEX SEDENA`): *US III Armored Corps (1st Cavalry Div, Fort Cavazos)* vs *SEDENA 1/a Brigada Blindada*, *FAM Escuadrón Aéreo 401*, *ARM Reformador (POLA-101)*.
  7. `hormuz_theater` (**50,000 Units** — `USA 5th Fleet + Coalition` vs `IRN IRGC`): *USS Abraham Lincoln (CVN-72) CSG-3* vs *IRGCN 1st Naval Region (Bandar Abbas)*.

### 7. Living Battlefield Infrastructure, Logistics, Civilian PDE & Space/Cyber/CBRN (`[7]`–`[0]`)
- **Living Infrastructure (`128x128` Grid + 3,800+ 3D Buildings):** Hydrological rivers with strategic bridges, highway MSRs (`1.45x` speed), railways with 8 moving 3D military supply trains, 48 real-world metropolitan cities, airfields, and forests (`0.65x` damage cover).
- **Dynamic War Destruction:** Heavy strikes crater runways, collapse 3D urban towers into smoking rubble (`+62%` fortification cover for Infantry & Robot Dogs), blow river bridges (`0.16x` ford penalty), and derail supply trains.
- **Spreading Civilian Density Field & Multi-Domain Deterrence (`[7]`–`[0]`):** C# `.NET 8.0` parallel Advection-Diffusion PDE models ~397M civilians fleeing combat along road networks; `[7] ASAT`, `[8] CYBER`, `[9] PSYOP`, `[0] CBRN`.

---

## Part II: Interactive 5-Step Bunker Boot-Camp Tutorial

| Step | Lesson Title | Instructor | Action / Target | Tactical Takeaway |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Lesson 1: Holographic Table & Semantic Echelon Zoom** | `MAGIC 1-1 (AWACS INSTRUCTOR)` | `WAR_TABLE_ZOOM` | At any zoom level, you can order an entire Brigade at once—and its Subordinate AI will handle formation bounding—or zoom in to take Direct Manual Control of a single flight! |
| **2** | **Lesson 2: The 6-Spectrum Sensor War (Radar vs. Passive ESM, IRST & Acoustic)** | `MAGIC 1-1 (AWACS INSTRUCTOR)` | `CONSOLE_MASTER_IADS` | Remember: Active Radar sees far but broadcasts your position to enemy Passive ESM at 1.6x range! Stealth jets (F-35/J-20) beat Radar, but Passive IRST and Acoustic Arrays can still spot them at closer range. |
| **3** | **Lesson 3: Deploying Quadruped Robot Dogs & Jam-Proof FPV Swarms** | `HOUND ACTUAL (SPEC-OPS)` | `CONSOLE_DEPLOY_UNMANNED` | Quadruped Robot Dogs use 3D LiDAR + Autonomous AI (immune to EW jamming), have a tiny 0.0005 m² radar signature, and climb sheer cliffs to laser-designate enemy SAMs! |
| **4** | **Lesson 4: Wikipedia Intelligence Dossier & Real Recon Photographs** | `INTEL DIRECTOR` | `CONSOLE_RECON_PHOTO` | Every weapon shot has a real dollar cost: never waste a $4.0M Patriot PAC-3 interceptor on a $25,000 Shahed drone! |
| **5** | **Lesson 5: Orchestrating an Alpha Strike & Laser/HPM Swarm Defense** | `STRIKE MARSHAL` | `CONSOLE_ALPHA_STRIKE` | Tutorial Complete! Watch your Iron Beam 100kW Lasers ($2/shot) and Epirus Leonidas 30° HPM Microwave cones zap incoming enemy drone swarms while your hypersonics and stealth flights strike home. |

---

## Part III: 11-Nation Platforms, Aircraft Carriers, Robot Dogs & Unmanned Roster (67 Systems)

| Faction | Platform | Domain / Class | Speed (kts) | Radius (km) | RCS ($m^2$) | Autonomy | Cost ($M) | Photo Asset |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `USA` | **F-35A Lightning II Flight** | `AIR/FIGHTER` | 1060 | 1090 | `0.0015` | `MANNED` | **$320.00M** | `res://assets/wiki_images/platforms/f_35a_lightning.jpg` |
| `USA` | **F-16V/CJ Wild Weasel Flight** | `AIR/SEAD` | 1150 | 620 | `1.2` | `MANNED` | **$140.00M** | `res://assets/wiki_images/platforms/f_16cj_block70.jpg` |
| `USA` | **B-21 Raider Stealth Bomber Cell** | `AIR/STRIKE` | 560 | 4000 | `0.0005` | `MANNED` | **$1400.00M** | `res://assets/wiki_images/platforms/b_21_raider.jpg` |
| `USA` | **E-3G Sentry AWACS Orbit** | `AIR/AWACS` | 460 | 2500 | `65.0` | `MANNED` | **$380.00M** | `res://assets/wiki_images/platforms/e_3_sentry_awacs.jpg` |
| `CHN` | **Chengdu J-20A Mighty Dragon Flight** | `AIR/FIGHTER` | 1120 | 1100 | `0.015` | `MANNED` | **$360.00M** | `res://assets/wiki_images/platforms/j_20_mighty_dragon.jpg` |
| `RUS` | **Sukhoi Su-57 Felon Strike Flight** | `AIR/FIGHTER` | 1150 | 1050 | `0.1` | `MANNED` | **$240.00M** | `res://assets/wiki_images/platforms/su_57_felon.jpg` |
| `RUS` | **Tu-22M3M Backfire Missile Bomber Flight** | `AIR/STRIKE` | 1050 | 2200 | `25.0` | `MANNED` | **$180.00M** | `res://assets/wiki_images/platforms/tu_22m3_backfire.jpg` |
| `USA` | **XQ-58A Valkyrie Loyal Wingman Swarm** | `AIR/CCA_DRONE` | 565 | 1800 | `0.005` | `AUTONOMOUS_AI` | **$16.00M** | `res://assets/wiki_images/platforms/xq_58a_valkyrie.jpg` |
| `USA` | **MQ-28 Ghost Bat AI Wingman Cell** | `AIR/CCA_DRONE` | 620 | 1900 | `0.008` | `AUTONOMOUS_AI` | **$44.00M** | `res://assets/wiki_images/platforms/mq_28_ghost_bat.jpg` |
| `RUS` | **Sukhoi S-70 Okhotnik-B Stealth UCAV** | `AIR/CCA_DRONE` | 540 | 2000 | `0.01` | `AUTONOMOUS_AI` | **$36.00M** | `res://assets/wiki_images/platforms/s_70_okhotnik.jpg` |
| `TUR` | **Bayraktar Kizilelma Unmanned Fighter** | `AIR/CCA_DRONE` | 590 | 930 | `0.02` | `AUTONOMOUS_AI` | **$40.00M** | `res://assets/wiki_images/platforms/bayraktar_kizilelma.jpg` |
| `USA` | **Ghost Robotics Vision 60 Robot Dog Pack** | `LAND/ROBOT_DOG` | 12 | 16 | `0.0005` | `AUTONOMOUS_AI` | **$1.20M** | `res://assets/wiki_images/platforms/vision_60_q_ugv.jpg` |
| `CHN` | **Armed Quadruped Robot Dog Assault Pack** | `LAND/ROBOT_DOG` | 14 | 18 | `0.0006` | `AUTONOMOUS_AI` | **$0.60M** | `res://assets/wiki_images/platforms/unitree_b2w_armed.png` |
| `NATO` | **Milrem THeMIS Combat UGV Section** | `LAND/UGV` | 25 | 45 | `0.15` | `AUTONOMOUS_AI` | **$2.40M** | `res://assets/wiki_images/platforms/milrem_themis_ugv.jpg` |
| `RUS` | **Uran-9 Heavy Robotic Tank Section** | `LAND/UGV` | 22 | 40 | `0.4` | `RF_DATALINK` | **$4.50M** | `res://assets/wiki_images/platforms/uran_9_ugv.jpg` |
| `NATO` | **Fiber-Optic FPV Hunter-Killer Swarm** | `LAND/SWARM_TEAM` | 20 | 20 | `0.01` | `FIBER_OPTIC` | **$0.15M** | `res://assets/wiki_images/platforms/fpv_fiber_swarm.jpg` |
| `USA` | **Switchblade 600 Loitering Swarm Battery** | `LAND/SWARM_TEAM` | 42 | 120 | `0.2` | `RF_DATALINK` | **$1.80M** | `res://assets/wiki_images/platforms/switchblade_600_team.jpg` |
| `RUS` | **ZALA Lancet-3 AI Swarm Section** | `LAND/SWARM_TEAM` | 40 | 110 | `0.2` | `AUTONOMOUS_AI` | **$1.10M** | `res://assets/wiki_images/platforms/lancet_3_team.jpg` |
| `RUS` | **Shahed-136 / Geran-2 Saturation Truck** | `LAND/SWARM_TEAM` | 38 | 200 | `1.5` | `GPS_INS` | **$0.90M** | `res://assets/wiki_images/platforms/shahed_136_launcher.jpg` |
| `USA` | **IAI Harop Anti-Radar Drone Battery** | `LAND/SWARM_TEAM` | 40 | 180 | `1.2` | `AUTONOMOUS_AI` | **$2.50M** | `res://assets/wiki_images/platforms/iai_harop_launcher.jpg` |
| `USA` | **Iron Beam 100kW High-Energy Laser Battery** | `LAND/CUAS_LASER` | 35 | 150 | `2.0` | `MANNED` | **$28.00M** | `res://assets/wiki_images/platforms/iron_beam_helws.jpg` |
| `USA` | **Epirus Leonidas HPM Microwave C-UAS Stryker** | `LAND/CUAS_HPM` | 52 | 220 | `1.8` | `MANNED` | **$18.00M** | `res://assets/wiki_images/platforms/epirus_leonidas_hpm.jpg` |
| `NATO` | **Rheinmetall Skynex 35mm C-UAS Battery** | `LAND/CUAS_GUN` | 45 | 180 | `2.2` | `MANNED` | **$22.00M** | `res://assets/wiki_images/platforms/skynex_ahead_battery.jpg` |
| `USA` | **MIM-104F Patriot PAC-3 SAM Battery** | `LAND/SAM` | 30 | 150 | `6.0` | `MANNED` | **$420.00M** | `res://assets/wiki_images/platforms/mim_104f_patriot.jpg` |
| `RUS` | **S-400 Triumf Strategic SAM Battalion** | `LAND/SAM` | 30 | 150 | `7.5` | `MANNED` | **$310.00M** | `res://assets/wiki_images/platforms/s_400_triumf.jpg` |
| `RUS` | **1RL257 Krasukha-4 Electronic Warfare Station** | `LAND/EW_JAMMER` | 35 | 180 | `4.0` | `MANNED` | **$25.00M** | `res://assets/wiki_images/platforms/krasukha_4_ew.jpg` |
| `USA` | **M1A2 SEPv3 Abrams Tank Platoon** | `LAND/ARMOR` | 38 | 200 | `3.5` | `MANNED` | **$44.00M** | `res://assets/wiki_images/platforms/m1a2_sepv3_platoon.jpg` |
| `USA` | **M2A4 Bradley Mechanized Infantry (with Robot Dogs)** | `LAND/MECH_INF` | 36 | 210 | `2.8` | `MANNED` | **$24.00M** | `res://assets/wiki_images/platforms/m2a4_mech_company.jpg` |
| `USA` | **Special Forces Mountain Recon (Robot Dogs + FPVs)** | `LAND/INFANTRY` | 15 | 80 | `0.02` | `MANNED` | **$4.00M** | `res://assets/wiki_images/platforms/specops_mountain_team.png` |
| `USA` | **Tier-1 Sniper & JTAC Laser Recon Team (.50 BMG M107)** | `LAND/INFANTRY` | 18 | 95 | `0.002` | `MANNED` | **$3.20M** | `res://assets/wiki_images/platforms/tier1_sniper_recon_team.jpg` |
| `USA` | **Tier-1 SEAL / SAS Commando Sabotage Squad** | `LAND/INFANTRY` | 20 | 110 | `0.004` | `MANNED` | **$4.80M** | `res://assets/wiki_images/platforms/navy_seal_commando_squad.png` |
| `RUS` | **OPFOR Spetsnaz Sniper & Commando Sabotage Team** | `LAND/INFANTRY` | 19 | 100 | `0.005` | `MANNED` | **$3.50M** | `res://assets/wiki_images/platforms/spetsnaz_sniper_commando.png` |
| `RUS` | **T-90M Proryv-3 Tank Platoon (with Robot Dogs)** | `LAND/ARMOR` | 35 | 190 | `3.2` | `MANNED` | **$18.00M** | `res://assets/wiki_images/platforms/t_90m_platoon.jpg` |
| `USA` | **LRHW Dark Eagle Hypersonic Battery** | `LAND/HYPERSONIC_TEL` | 40 | 300 | `4.5` | `MANNED` | **$160.00M** | `res://assets/wiki_images/platforms/dark_eagle_battery.jpg` |
| `USA` | **USS Arleigh Burke Flight III Destroyer** | `SEA/SHIP` | 31 | 4500 | `80.0` | `MANNED` | **$2200.00M** | `res://assets/wiki_images/platforms/ddg_51_arleigh_burke.jpg` |
| `CHN` | **Type 055 Renhai Guided-Missile Cruiser** | `SEA/SHIP` | 30 | 5000 | `95.0` | `MANNED` | **$1800.00M** | `res://assets/wiki_images/platforms/type_055_renhai.jpg` |
| `NATO` | **MAGURA V5 Kamikaze Naval Drone Wolfpack** | `SEA/USV_DRONE` | 42 | 450 | `0.008` | `AUTONOMOUS_AI` | **$1.50M** | `res://assets/wiki_images/platforms/magura_v5_usv.webp` |
| `RUS` | **Sea Baby Multi-Role Naval USV Pack** | `SEA/USV_DRONE` | 45 | 500 | `0.01` | `AUTONOMOUS_AI` | **$1.60M** | `res://assets/wiki_images/platforms/sea_baby_usv.jpg` |
| `USA` | **Boeing Orca Autonomous XLUUV Submarine** | `SEA/UUV_DRONE` | 12 | 6000 | `0.0001` | `AUTONOMOUS_AI` | **$45.00M** | `res://assets/wiki_images/platforms/orca_xluuv.jpg` |
| `USA` | **USS Cheyenne SSN-688(I) / Virginia Nuclear Attack Submarine** | `SEA/UUV_DRONE` | 33 | 12000 | `0.0001` | `MANNED` | **$2850.00M** | `res://assets/wiki_images/platforms/ssn_688i_los_angeles.jpg` |
| `CHN` | **PLA Navy Type 093B Shang-III / Akula Nuclear Attack Submarine** | `SEA/UUV_DRONE` | 30 | 10000 | `0.0002` | `MANNED` | **$1650.00M** | `res://assets/wiki_images/platforms/type_093b_shang_ssn.png` |
| `EUR_NATO` | **Dassault Rafale F4 Omnirole Flight (Meteor)** | `AIR/FIGHTER` | 1050 | 1050 | `0.1` | `MANNED` | **$340.00M** | `res://assets/wiki_images/platforms/rafale_f4_flight.jpg` |
| `EUR_NATO` | **Leopard 2A8 Tank Platoon (with Trophy APS)** | `LAND/ARMOR` | 37 | 210 | `3.2` | `MANNED` | **$48.00M** | `res://assets/wiki_images/platforms/leopard_2a8_platoon.jpg` |
| `KOR` | **KAI KF-21 Boramae 4.5-Gen Fighter Flight** | `AIR/FIGHTER` | 1020 | 1000 | `0.05` | `MANNED` | **$280.00M** | `res://assets/wiki_images/platforms/kf_21_boramae.jpg` |
| `KOR` | **K2 Black Panther Mountain Tank Platoon** | `LAND/ARMOR` | 40 | 220 | `3.0` | `MANNED` | **$36.00M** | `res://assets/wiki_images/platforms/k2_black_panther.jpg` |
| `KOR` | **Hyunmoo-5 Monster Bunker-Buster Battery** | `LAND/HYPERSONIC_TEL` | 35 | 250 | `4.5` | `MANNED` | **$110.00M** | `res://assets/wiki_images/platforms/hyunmoo_5_tel.jpg` |
| `PRK` | **KN-25 600mm Super-Large MLRS Battery** | `LAND/HYPERSONIC_TEL` | 32 | 200 | `5.0` | `MANNED` | **$45.00M** | `res://assets/wiki_images/platforms/kn_25_mlrs_battery.png` |
| `IND` | **HAL Tejas Mk2 Medium Weight Fighter Flight** | `AIR/FIGHTER` | 1040 | 950 | `0.25` | `MANNED` | **$210.00M** | `res://assets/wiki_images/platforms/hal_tejas_mk2.jpg` |
| `IND` | **BrahMos PJ-10 Supersonic Cruise Battery** | `LAND/HYPERSONIC_TEL` | 35 | 260 | `4.0` | `MANNED` | **$95.00M** | `res://assets/wiki_images/platforms/brahmos_coastal_battery.jpg` |
| `IND` | **Zorawar High-Altitude Light Tank Platoon** | `LAND/ARMOR` | 42 | 240 | `2.2` | `MANNED` | **$18.00M** | `res://assets/wiki_images/platforms/zorawar_mountain_tank.jpg` |
| `PAK` | **JF-17 Thunder Block III AESA Flight (PL-15)** | `AIR/FIGHTER` | 1030 | 900 | `0.5` | `MANNED` | **$140.00M** | `res://assets/wiki_images/platforms/jf_17_block3_flight.jpg` |
| `PAK` | **Bayraktar Akinci Heavy Strike UCAV Wing** | `AIR/CCA_DRONE` | 210 | 2500 | `0.4` | `AUTONOMOUS_AI` | **$32.00M** | `res://assets/wiki_images/platforms/bayraktar_akinci_ucav.jpg` |
| `USA` | **KC-46A Pegasus Aerial Refueling Tanker Orbit** | `AIR/TANKER` | 490 | 4500 | `55.0` | `MANNED` | **$210.00M** | `res://assets/wiki_images/platforms/kc_46_pegasus.jpg` |
| `USA` | **Oshkosh M977 HEMTT Ammo & Drone Resupply Convoy** | `LAND/LOGISTICS` | 42 | 450 | `4.0` | `MANNED` | **$6.50M** | `res://assets/wiki_images/platforms/hemtt_supply_convoy.jpg` |
| `UKR` | **T-84 Oplot-M Ukrainian Tank Platoon (Duplet ERA)** | `LAND/ARMOR` | 38 | 210 | `3.1` | `MANNED` | **$22.00M** | `res://assets/wiki_images/platforms/t_84_oplot_platoon.jpg` |
| `UKR` | **BTR-4E Bucephalus Mechanized Infantry (with FPVs)** | `LAND/MECH_INF` | 44 | 260 | `2.5` | `MANNED` | **$12.00M** | `res://assets/wiki_images/platforms/btr_4_bucephalus_co.jpg` |
| `UKR` | **RK-360MC Neptune Cruise & Vilkha-M Strike Battery** | `LAND/HYPERSONIC_TEL` | 36 | 280 | `4.0` | `MANNED` | **$65.00M** | `res://assets/wiki_images/platforms/neptune_rk360mc_battery.jpg` |
| `UKR` | **2S22 Bohdana 155mm Self-Propelled Artillery Battery** | `LAND/HYPERSONIC_TEL` | 40 | 250 | `3.6` | `MANNED` | **$18.00M** | `res://assets/wiki_images/platforms/bohdana_2s22_artillery.jpg` |
| `UKR` | **Palianytsia Rocket-Drone & Liutyi Deep-Strike Wing** | `AIR/CCA_DRONE` | 410 | 1200 | `0.08` | `AUTONOMOUS_AI` | **$8.50M** | `res://assets/wiki_images/platforms/palianytsia_drone_uk.png` |
| `MEX` | **SEDENA DN-XI & ERC-90 Lynx Armored Cavalry Squadron** | `LAND/MECH_INF` | 46 | 280 | `2.4` | `MANNED` | **$14.00M** | `res://assets/wiki_images/platforms/dn_xi_mexican_armor.png` |
| `MEX` | **FAM F-5E/F Tiger II & Texan II Tactical Strike Flight** | `AIR/FIGHTER` | 920 | 780 | `1.4` | `MANNED` | **$95.00M** | `res://assets/wiki_images/platforms/f_5f_tiger_mex_flight.png` |
| `MEX` | **ARM Benito Juarez / Reformador (POLA-101) Frigate** | `SEA/SHIP` | 28 | 4200 | `45.0` | `MANNED` | **$680.00M** | `res://assets/wiki_images/platforms/pola_benito_juarez_frigate.jpg` |
| `USA` | **USS Gerald R. Ford (CVN-78) Supercarrier CSG** | `SEA/SHIP` | 31 | 9500 | `160.0` | `MANNED` | **$13000.00M** | `res://assets/wiki_images/platforms/cvn_78_gerald_r_ford.jpg` |
| `CHN` | **CNS Fujian (CV-18) EMALS Supercarrier CSG** | `SEA/SHIP` | 30 | 7500 | `150.0` | `MANNED` | **$8500.00M** | `res://assets/wiki_images/platforms/cns_fujian_cv18.jpg` |
| `EUR_NATO` | **FS Charles de Gaulle (R91) Nuclear Carrier CSG** | `SEA/SHIP` | 27 | 8000 | `120.0` | `MANNED` | **$4800.00M** | `res://assets/wiki_images/platforms/fs_charles_de_gaulle_r91.jpg` |
| `IND` | **INS Vikrant (R11) Carrier Battle Group** | `SEA/SHIP` | 28 | 7000 | `125.0` | `MANNED` | **$3600.00M** | `res://assets/wiki_images/platforms/ins_vikrant_r11.jpg` |
| `RUS` | **Admiral Gorshkov (Project 22350) Zircon Frigate** | `SEA/SHIP` | 29 | 4800 | `55.0` | `MANNED` | **$950.00M** | `res://assets/wiki_images/platforms/admiral_gorshkov_frigate.jpg` |

---

## Part IV: Authentic Wikipedia Weapons & Directed-Energy Munitions (31 Munitions)

| Weapon / Munition | Guidance | Max Range (km) | Speed (Mach) | Base $P_k$ | Cost per Shot ($M) | Photo Asset |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **AIM-120D AMRAAM** | `ACTIVE_RADAR` | 160.0 km | Mach 4.00 | 80% | **$1.090000M** | `res://assets/wiki_images/weapons/aim_120d.jpg` |
| **MBDA Meteor Ramjet BVR AAM** | `ACTIVE_RADAR` | 200.0 km | Mach 4.50 | 88% | **$2.100000M** | `res://assets/wiki_images/weapons/mbda_meteor.jpg` |
| **PL-15 Dual-Pulse BVR AAM** | `ACTIVE_RADAR` | 180.0 km | Mach 4.50 | 78% | **$1.200000M** | `res://assets/wiki_images/weapons/pl_15_aam.jpg` |
| **AGM-88G AARGM-ER Anti-Radiation** | `ANTI_RADIATION` | 130.0 km | Mach 3.20 | 82% | **$1.800000M** | `res://assets/wiki_images/weapons/agm_88g_aargm_er.jpg` |
| **AGM-158B JASSM-ER Stealth Cruise** | `GPS_INS` | 280.0 km | Mach 0.85 | 85% | **$1.500000M** | `res://assets/wiki_images/weapons/agm_158_jassm.jpg` |
| **BrahMos PJ-10 Mach 3 Supersonic Cruise** | `ACTIVE_RADAR` | 350.0 km | Mach 3.00 | 89% | **$2.750000M** | `res://assets/wiki_images/weapons/brahmos_supersonic.jpg` |
| **Hyunmoo-5 8-Ton Monster Bunker Buster** | `GPS_INS` | 300.0 km | Mach 6.50 | 94% | **$8.500000M** | `res://assets/wiki_images/weapons/hyunmoo_5_bunker.jpg` |
| **KN-25 600mm Super-Large Guided MLRS** | `GPS_INS` | 340.0 km | Mach 4.20 | 74% | **$0.850000M** | `res://assets/wiki_images/weapons/kn_25_600mm_mlrs.png` |
| **LRHW Dark Eagle Hypersonic Glide** | `GPS_INS` | 480.0 km | Mach 17.00 | 92% | **$41.000000M** | `res://assets/wiki_images/weapons/lrhw_dark_eagle.jpg` |
| **3M22 Zircon Scramjet Hypersonic** | `ACTIVE_RADAR` | 420.0 km | Mach 8.50 | 90% | **$12.000000M** | `res://assets/wiki_images/weapons/3m22_zircon.jpg` |
| **Kh-47M2 Kinzhal Air-Launched Ballistic** | `GPS_INS` | 380.0 km | Mach 10.00 | 86% | **$10.000000M** | `res://assets/wiki_images/weapons/kh_47m2_kinzhal.jpg` |
| **MIM-104F Patriot PAC-3 MSE** | `ACTIVE_RADAR` | 120.0 km | Mach 4.10 | 84% | **$4.000000M** | `res://assets/wiki_images/weapons/pac_3_mse.jpg` |
| **RIM-174 Standard ERAM (SM-6)** | `ACTIVE_RADAR` | 240.0 km | Mach 3.50 | 85% | **$4.300000M** | `res://assets/wiki_images/weapons/sm_6_eram.jpg` |
| **48N6E3 S-400 Long-Range SAM** | `SEMI_ACTIVE` | 200.0 km | Mach 6.00 | 78% | **$1.500000M** | `res://assets/wiki_images/weapons/48n6e3_s400.jpg` |
| **ADM-160C MALD-J Radar Decoy** | `DECOY` | 220.0 km | Mach 0.80 | 0% | **$0.320000M** | `res://assets/wiki_images/weapons/adm_160_mald.jpg` |
| **AeroVironment Switchblade 600 Loitering** | `IR` | 40.0 km | Mach 0.16 | 82% | **$0.080000M** | `res://assets/wiki_images/weapons/switchblade_600_round.jpg` |
| **ZALA Lancet-3 AI Loitering Munition** | `IR` | 45.0 km | Mach 0.25 | 80% | **$0.035000M** | `res://assets/wiki_images/weapons/lancet_3_round.jpg` |
| **HESA Shahed 136 OWA-UAV** | `GPS_INS` | 320.0 km | Mach 0.17 | 72% | **$0.025000M** | `res://assets/wiki_images/weapons/shahed_136_round.jpg` |
| **IAI Harop Anti-Radiation Drone** | `ANTI_RADIATION` | 250.0 km | Mach 0.32 | 85% | **$0.070000M** | `res://assets/wiki_images/weapons/iai_harop_round.jpg` |
| **Fiber-Optic Jam-Proof FPV Drone** | `IR` | 12.0 km | Mach 0.13 | 84% | **$0.001000M** | `res://assets/wiki_images/weapons/fpv_fiber_kamikaze.jpg` |
| **FGM-148 Javelin Top-Attack ATGM** | `IR` | 4.8 km | Mach 0.60 | 90% | **$0.175000M** | `res://assets/wiki_images/weapons/fgm_148_javelin.jpg` |
| **120mm M829A4 APFSDS Depleted Uranium** | `DIRECT` | 4.0 km | Mach 4.90 | 85% | **$0.010000M** | `res://assets/wiki_images/weapons/m829a4_apfsds.jpg` |
| **Iron Beam 100kW High-Energy Laser Pulse** | `DIRECT` | 10.0 km | Mach 999.00 | 92% | **$0.000002M** | `res://assets/wiki_images/weapons/helws_100kw_laser.jpg` |
| **Epirus Leonidas High-Power Microwave Cone** | `DIRECT` | 3.5 km | Mach 999.00 | 95% | **$0.000001M** | `res://assets/wiki_images/weapons/leonidas_hpm_burst.jpg` |
| **Skynex 35mm AHEAD Programmable Burst** | `DIRECT` | 4.5 km | Mach 3.10 | 88% | **$0.004000M** | `res://assets/wiki_images/weapons/ahead_35mm_burst.jpg` |
| **Naval Kamikaze USV 500kg Hull Charge** | `IR` | 180.0 km | Mach 0.07 | 85% | **$0.250000M** | `res://assets/wiki_images/weapons/usv_500kg_warhead.webp` |
| **Mark 48 ADCAP Heavyweight Torpedo** | `ACTIVE_RADAR` | 38.0 km | Mach 0.09 | 90% | **$3.800000M** | `res://assets/wiki_images/weapons/mk48_adcap_torpedo.jpg` |
| **R-360 Neptune Anti-Ship & Land Cruise** | `ACTIVE_RADAR` | 300.0 km | Mach 0.85 | 87% | **$1.450000M** | `res://assets/wiki_images/weapons/r_360_neptune.jpg` |
| **Vilkha-M 300mm Precision Guided MLRS** | `GPS_INS` | 130.0 km | Mach 3.40 | 84% | **$0.350000M** | `res://assets/wiki_images/weapons/vilkha_m_300mm.jpg` |
| **Stugna-P (Skif) Laser-Guided Heavy ATGM** | `IR` | 5.5 km | Mach 0.65 | 88% | **$0.045000M** | `res://assets/wiki_images/weapons/stugna_p_atgm.jpg` |
| **Project Thor Mach-24 Orbital Kinetic Tungsten Rod** | `GPS_INS` | 2000.0 km | Mach 24.00 | 98% | **$45.000000M** | `res://assets/wiki_images/weapons/orbital_tungsten_rod.png` |

---

## Part V: 7 Global `2,000 × 2,000 km` Theaters & 9 Operations (1,000,000 Total Units)

| Operation Slug | Operation Name | Theater (`2,000x2,000 km`) | Era / Doctrine | Blue / Red Budget ($M) |
| :--- | :--- | :--- | :--- | :--- |
| `op_pacific_shield_2028` | **Operation Pacific Shield (Full 500km Theater War)** | `strait_theater` | 2028 Drone, Robot Dog & Hypersonic Era | **$4500M / $4500M** |
| `op_iron_hound_ridge` | **Operation Iron Hound (Mountain Ridge Robot Dog & FPV Clash)** | `strait_theater` | 2028 Tactical Unmanned Warfare | **$850M / $950M** |
| `op_red_strait_swarm` | **Operation Sea Wolfpack (Strait of Hormuz USVs vs Carrier Group)** | `hormuz_theater` | 2028 Littoral Drone Swarm War | **$2800M / $2800M** |
| `op_korean_thunder_dmz` | **Operation Iron Peninsula (Korean DMZ: KF-21, K2 & Hyunmoo-5 vs KN-25)** | `korean_dmz_theater` | 2028 Korean Peninsula High-Intensity War | **$3200M / $3200M** |
| `op_baltic_shield_suwalki` | **Operation Baltic Shield (Suwalki Gap: Rafale F4 & Leopard 2A8 vs S-400)** | `baltic_suwalki_theater` | 2028 NATO Eastern Flank Coalition War | **$3400M / $3400M** |
| `op_himalayan_sentinel_lac` | **Operation High Sentinel (5,600m Himalayan LAC: Tejas Mk2 & Zorawar vs J-20)** | `himalaya_lac_theater` | 2028 Extreme-Altitude Mountain & Robot Dog Warfare | **$2900M / $2900M** |
| `op_ukraine_donbas_2028` | **Operation Steppe Shield (Ukraine Donbas & Azov: 240,000 Units Drone-Artillery War)** | `ukraine_donbas_theater` | 2028 High-Density FPV Swarm, Artillery & Mechanized Front | **$3800M / $4200M** |
| `op_mexico_rio_grande_2028` | **Operation Rio Bravo (US-Mexico Sierra Madre & Gulf: 70,000 Units Cavalry & Mountain War)** | `mexico_rio_grande_theater` | 2028 North American Rio Grande & Sierra Madre Campaign | **$2600M / $2400M** |
| `op_global_escalation_chronicle_2028` | **Operation Doomsday Clock 2028 (8-Chapter Story Campaign with Live Veo 3.1 News & Capabilities)** | `strait_theater` | 2028 Complete Historical Progression & Capabilities Showcase (DEFCON 5 -> DEFCON 1) | **$4800M / $4800M** |

---

## Part VI: 4-Branch Defense R&D Technology Tree (15 Technologies)

| Branch | Tier | Technology Name | Prerequisite | R&D Cost ($M) | Strategic & Tactical Modifiers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ROBOTICS_AI` | **Tier 1** | **Quadruped 4D LiDAR & Cliff-Agile Actuators** (`tech_quadruped_lidar_v2`) | *None (Tier 1)* | **$250M** | +35% Robot Dog & UGV speed, +25% 3D LiDAR detection range, and +2 Unmanned Bays on friendly Mech/Infantry companies. |
| `ROBOTICS_AI` | **Tier 2** | **25km Fiber-Optic & Edge-AI Swarm Seeker Bus** (`tech_fiber_optic_swarm_bus`) | `tech_quadruped_lidar_v2` | **$450M** | +18% FPV & Loitering Swarm Pk, 100% immunity to Krasukha-4 RF jamming, and +3,500 loitering drone munitions delivered. |
| `ROBOTICS_AI` | **Tier 3** | **Autonomous CCA Loyal Wingman Neural Mesh** (`tech_cca_loyal_wingman_net`) | `tech_fiber_optic_swarm_bus` | **$850M** | -35% unmanned aircraft RCS, +15% BVR air-to-air Pk, and spawns an autonomous XQ-58A Valkyrie / MQ-28 Ghost Bat flight. |
| `DIRECTED_ENERGY` | **Tier 1** | **200kW Solid-State Fiber Laser Capacitors** (`tech_solid_state_hel_200kw`) | *None (Tier 1)* | **$300M** | 2.0x thermal capacitor recharge rate and +30% intercept range for Iron Beam 100kW Lasers & C-UAS batteries. |
| `DIRECTED_ENERGY` | **Tier 2** | **Gallium Nitride (GaN) Ultra-Wideband AESA Radar** (`tech_gan_aesa_iads`) | `tech_solid_state_hel_200kw` | **$550M** | +25% Active Radar & Passive ESM detection range across the theater, and +15% SAM interceptor hit probability (Pk). |
| `DIRECTED_ENERGY` | **Tier 3** | **Wideband HPM Microwave Swarm Neutralizer** (`tech_wideband_hpm_emp`) | `tech_gan_aesa_iads` | **$900M** | +50% Epirus Leonidas HPM EMP cone radius and -25% enemy missile/drone hit probability against all friendly forces. |
| `HYPERSONIC_STEALTH` | **Tier 1** | **Metamaterial Radar Absorbent Coating (RAM)** (`tech_metamaterial_ram_coat`) | *None (Tier 1)* | **$350M** | -40% Radar Cross Section (RCS) on all friendly aircraft & warships, shrinking enemy SAM detection rings. |
| `HYPERSONIC_STEALTH` | **Tier 2** | **Scramjet Thermal Shield & Mach 12+ Glide Vehicles** (`tech_scramjet_glide_mach12`) | `tech_metamaterial_ram_coat` | **$650M** | +25% speed for all friendly missiles/hypersonics and +20% penetration against enemy SAM interceptors. |
| `HYPERSONIC_STEALTH` | **Tier 3** | **Integrated Prompt Global Hypersonic Salvo** (`tech_prompt_global_salvo`) | `tech_scramjet_glide_mach12` | **$1100M** | +20% warhead damage, +8,000 long-range precision munitions delivered, and spawns an LRHW Dark Eagle Hypersonic battery. |
| `C4ISR_LOGISTICS` | **Tier 1** | **Proliferated LEO SAR & Starshield Mesh** (`tech_leo_proliferated_satcom`) | *None (Tier 1)* | **$280M** | Locks friendly C2 Integrity & GPS/PNT >= 95% (ASAT-resilient) and generates +$40M/min Wartime Defense Appropriation. |
| `C4ISR_LOGISTICS` | **Tier 2** | **Automated 3D-Printed Drone & Artillery Smart Factories** (`tech_automated_ammo_factories`) | `tech_leo_proliferated_satcom` | **$500M** | Continuously manufactures +2,400 munitions/min into theater stocks, delivers +10,000 rounds now, and adds +$60M/min budget. |
| `C4ISR_LOGISTICS` | **Tier 3** | **Quantum Cryptographic C4ISR & Autonomous Cyber CNO** (`tech_quantum_cyber_dominance`) | `tech_automated_ammo_factories` | **$950M** | Doubles Cyber CNO enemy IADS blackout duration, adds +$90M/min Defense Budget income, and repairs all friendly units +25% HP. |
| `NBC_APOCALYPSE` | **Tier 1** | **MOPP-5 Nano-Shield & Tactical CBRN Aerosol Warheads** (`tech_cbrn_aerosol_mopp5`) | *None (Tier 1)* | **$400M** | 100% friendly CBRN hazard immunity, unlocks Tactical Chemical/Bio Aerosol Strikes, and 2x hazard plume lethality vs enemy. |
| `NBC_APOCALYPSE` | **Tier 2** | **High-Altitude EMP (HEMP) & Orbital Kinetic Tungsten Rods** (`tech_hemp_orbital_emp`) | `tech_cbrn_aerosol_mopp5` | **$750M** | Unlocks Theater HEMP Electromagnetic Super-Burst (blinds radars/drones across 350km) and Mach 24 'Rods from God' Orbital Strikes. |
| `NBC_APOCALYPSE` | **Tier 3** | **PEAD-99 Thermonuclear Triad Release (B61-12 / Trident D5 / Sarmat)** (`tech_strategic_nuclear_triad`) | `tech_hemp_orbital_emp` | **$1400M** | Escalates to DEFCON 1: Authorizes Tactical & Strategic Thermonuclear Salvos ([N]) with 3D nuclear fireballs, shockwaves & fallout. |

---

## Part VII: Sovereign Nations, Airspace Corridors & AI Diplomacy Matrix (18 Seeded Nations + Procedural AI States)

| ISO | Sovereign Nation | Theater | Initial Alignment | Aid ($M/min) | Grant ($M) | Expeditionary Force | Geopolitical Profile |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `JPN` | **Japan (JSDF Ryukyu & Yonaguni Command)** (`jpn_self_defense`) | `strait_theater` | `LEAN_BLUE` (+45) | **+$28M/min** | **+$480M** | `f_35a_lightning` | Mutual Security Treaty Partner; controls Ryukyu airspace corridor & Kadena staging. |
| `PHL` | **Republic of the Philippines (EDCA Luzon)** (`phl_armed_forces`) | `strait_theater` | `NEUTRAL` (+18) | **+$14M/min** | **+$320M** | `brahmos_coastal_battery` | Controls Bashi Channel southern naval/airspace approach & Luzon EDCA airbases. |
| `AUS` | **Commonwealth of Australia (ADF RAAF/RAN)** (`aus_adf_indopac`) | `strait_theater` | `LEAN_BLUE` (+55) | **+$24M/min** | **+$450M** | `mq_28_ghost_bat` | AUKUS partner; provides Ghost Bat CCA wings, submarine patrols & coalition defence funds. |
| `RUS` | **Russian Federation (Pacific Fleet & VKS East)** (`rus_pacific_fleet`) | `strait_theater` | `LEAN_RED` (-48) | **+$26M/min** | **+$460M** | `tu_22m3_backfire` | Strategic Eurasian partner; grants northern bomber overflight corridor & Zircon naval support. |
| `CHN` | **People's Republic of China (Northern Theater PLA)** (`chn_northern_pla`) | `korea_dmz_theater` | `LEAN_RED` (-44) | **+$38M/min** | **+$620M** | `j_20_mighty_dragon` | Yalu River sovereign airspace buffer; major economic & stealth air-superiority backstop. |
| `JPN` | **Japan Maritime & Air SDF (Tsushima Strait)** (`jpn_korea_liaison`) | `korea_dmz_theater` | `LEAN_BLUE` (+42) | **+$26M/min** | **+$450M** | `ddg_51_arleigh_burke` | Controls Korea Strait rear logistics lane, Aegis BMD umbrella & allied warchest credit. |
| `RUS` | **Russian Federation (Primorsky Krai Corridor)** (`rus_primorsky_pact`) | `korea_dmz_theater` | `LEAN_RED` (-40) | **+$22M/min** | **+$410M** | `s_400_triumf` | Tumen River rail/airspace corridor supplying artillery, S-400 SAMs & petroleum aid. |
| `POL` | **Republic of Poland (Eastern Shield & Rzeszow Hub)** (`pol_armed_forces`) | `baltic_suwalki_theater` | `LEAN_BLUE` (+54) | **+$25M/min** | **+$440M** | `leopard_2a8_platoon` | Primary NATO logistics airbridge, armored staging corridor & sovereign SAM umbrella. |
| `BLR` | **Republic of Belarus (Union State Northern Axis)** (`blr_union_state`) | `baltic_suwalki_theater` | `LEAN_RED` (-50) | **+$18M/min** | **+$350M** | `s_400_triumf` | Northern strategic airspace & highway staging axis for deep strike and missile salvos. |
| `FIN` | **Nordic Defense Pact (Finland & Sweden Joint Air)** (`fin_swe_nordic`) | `baltic_suwalki_theater` | `NEUTRAL` (+26) | **+$22M/min** | **+$420M** | `rafale_f4_flight` | Controls Baltic Sea northern airspace, Gotland radar coverage & high-tech warchest grants. |
| `IRN` | **Islamic Republic of Iran (Caspian Drone Corridor)** (`irn_drone_syndicate`) | `baltic_suwalki_theater` | `LEAN_RED` (-45) | **+$20M/min** | **+$390M** | `shahed_136_launcher` | Supplies OWA drone swarms, ballistic munitions & Caspian airspace transit corridor. |
| `PAK` | **Islamic Republic of Pakistan (Northern Air Command)** (`pak_strategic_command`) | `himalaya_lac_theater` | `LEAN_RED` (-46) | **+$19M/min** | **+$360M** | `jf_17_block3_flight` | Western Karakoram two-front airspace corridor, JF-17 Block III flights & Akinci UCAVs. |
| `KAZ` | **Republic of Kazakhstan & Central Asian Union** (`kaz_central_asia`) | `himalaya_lac_theater` | `NEUTRAL` (-8) | **+$16M/min** | **+$340M** | `t_90m_platoon` | Resource-rich neutral buffer controlling northern continental overflight & energy revenues. |
| `FRA` | **French Republic & Quad Liaison (Indo-Pacific)** (`fra_indopac_taskforce`) | `himalaya_lac_theater` | `LEAN_BLUE` (+35) | **+$24M/min** | **+$430M** | `rafale_f4_flight` | Provides Rafale F4 Meteor air wings, satellite intelligence & European coalition funding. |
| `MMR` | **Union of Myanmar (Irrawaddy Corridor)** (`mmr_southern_corridor`) | `himalaya_lac_theater` | `NEUTRAL` (-18) | **+$13M/min** | **+$290M** | `unitree_b2w_armed` | Southeastern mountain & Bay of Bengal access corridor for flanking operations. |
| `CAN` | **Canada (NORAD Continental Defense Command)** (`can_norad_command`) | `mexico_rio_grande_theater` | `LEAN_BLUE` (+58) | **+$28M/min** | **+$490M** | `f_35a_lightning` | Integrated NORAD aerospace defense shield, Arctic overflight & allied treasury support. |
| `VEN` | **Bolivarian Republic of Venezuela & Caribbean Pact** (`ven_caribbean_pact`) | `mexico_rio_grande_theater` | `LEAN_RED` (-45) | **+$20M/min** | **+$380M** | `su_57_felon` | Southern Gulf & Caribbean maritime/airspace staging corridor with oil-backed warchest aid. |
| `COL` | **Republic of Colombia (Andean Security Coalition)** (`col_andean_shield`) | `mexico_rio_grande_theater` | `NEUTRAL` (+22) | **+$15M/min** | **+$310M** | `specops_mountain_team` | Southern air interdiction partner controlling Pacific-Caribbean transit lanes. |

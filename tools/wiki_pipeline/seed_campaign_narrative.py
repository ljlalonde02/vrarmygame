#!/usr/bin/env python3
"""
Branching Campaign Narrative Seeder for VR/PC Holographic Wargame Simulator.
Populates:
- `campaign_nations`: 5 Playable Sovereignties (USA, ROC/Taiwan, Poland, Ukraine, South Korea).
- `campaign_story_nodes`: 40 Interconnected Dynamic Story Chapters across 3 Acts with TV Chyrons, AI OPORDs & Action Video feeds.
- `campaign_story_edges`: 80 Outcome-Driven Branching Transitions ("who wins where and how").
"""

import json
import sqlite3
from pathlib import Path


def seed_campaign_narrative(cur: sqlite3.Cursor) -> None:
    # -------------------------------------------------------------
    # 1. Seed Campaign Playable Nations (5 Nations)
    # -------------------------------------------------------------
    nations = [
        (
            "usa",
            "United States of America",
            "USA",
            "Washington, D.C.",
            "res://assets/ui/flags/usa.png",
            "strait_theater",
            "Multi-Domain Prompt Global Strike & Coalition Command",
            "Deploys Carrier Strike Groups (CVN-78), autonomous Loyal Wingman CCAs (XQ-58A), Dark Eagle Hypersonics, and space-based kinetic deterrence across contested maritime littorals.",
            5000.0,
            1,
            1,
            "usa_node_act1_recon_crisis",
            "cvn_78_gerald_r_ford",
            json.dumps({"prompt_global_strike": 1, "carrier_csg": 1, "space_asat": 1, "autonomous_wingman": 1}),
        ),
        (
            "taiwan",
            "Republic of China (Taiwan)",
            "ROC",
            "Taipei",
            "res://assets/ui/flags/taiwan.png",
            "strait_theater",
            "Porcupine Asymmetric Defense & Littoral Swarm",
            "Relies on dense coastal missile batteries, fiber-optic FPV swarms, Sea Baby naval drone wolfpacks, and fortified mountain bunker redoubts to repel amphibious assault.",
            2800.0,
            1,
            1,
            "taiwan_node_act1_strait_crossing",
            "fpv_fiber_swarm",
            json.dumps({"littoral_swarm": 1, "mountain_redoubt": 1, "jam_resistant_fpv": 1, "coastal_harpoon_shield": 1}),
        ),
        (
            "poland",
            "Republic of Poland",
            "POL",
            "Warsaw",
            "res://assets/ui/flags/poland.png",
            "baltic_suwalki_theater",
            "Eastern Shield Armored Vanguard & Suwalki Iron Corridor",
            "Anchors NATO's eastern frontier with heavy Leopard 2A8 armor, Milrem THeMIS armed UGVs, Rheinmetall Skynex 35mm C-UAS batteries, and high-tempo mechanized counter-thrusts.",
            3400.0,
            1,
            1,
            "poland_node_act1_suwalki_incursion",
            "leopard_2a8_platoon",
            json.dumps({"eastern_shield": 1, "skynex_cuas": 1, "themis_ugv_recon": 1, "rapid_nato_airbridge": 1}),
        ),
        (
            "ukraine",
            "Ukraine",
            "UKR",
            "Kyiv",
            "res://assets/ui/flags/ukraine.png",
            "ukraine_donbas_theater",
            "Autonomous Drone-Artillery Recon-Strike Complex",
            "Pioneers massive 240k-unit high-density frontline warfare with Palianytsia rocket-drones, Bohdana 155mm wheeled artillery, Neptune maritime cruise missiles, and fiber-optic FPV kamikaze networks.",
            3200.0,
            1,
            1,
            "ukraine_node_act1_donbas_breakthrough",
            "t_84_oplot_platoon",
            json.dumps({"deep_strike_rockets": 1, "fiber_optic_fpv_mesh": 1, "wheeled_artillery_burst": 1, "naval_usv_sea_baby": 1}),
        ),
        (
            "south_korea",
            "Republic of Korea",
            "KOR",
            "Seoul",
            "res://assets/ui/flags/south_korea.png",
            "korean_dmz_theater",
            "Three-Axis Deterrence & Decapitation Kill Chain",
            "Fields K2 Black Panther mountain tanks, KF-21 Boramae 4.5+ gen stealth fighters, 8-ton Hyunmoo-5 bunker-busters, and autonomous robot dog scouts along the rugged DMZ.",
            3600.0,
            1,
            1,
            "korea_node_act1_dmz_artillery_duel",
            "k2_black_panther",
            json.dumps({"kill_chain": 1, "hyunmoo_bunker_strike": 1, "k2_hydraulic_stance": 1, "vision60_mountain_dogs": 1}),
        ),
    ]

    for nat in nations:
        cur.execute(
            """INSERT INTO campaign_nations (
                   slug, country_name, iso_code, capital_name, flag_res_path,
                   theater_slug, doctrine_label, doctrine_summary, budget_musd,
                   is_playable, unlocked_by_default, starting_node_slug,
                   flagship_platform_slug, special_capabilities_json
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            nat,
        )

    # -------------------------------------------------------------
    # 2. Seed Campaign Story Nodes (40 Nodes: 8 per Nation)
    # -------------------------------------------------------------
    # Schema: (slug, nation_slug, act, title, scenario, briefing, chyron, news_body, video_tag, is_terminal, climax_type)
    story_nodes = [
        # =========================================================
        # USA STORY TREE (Indo-Pacific & Global Deterrence)
        # =========================================================
        (
            "usa_node_act1_recon_crisis",
            "usa",
            1,
            "Act I: Sovereign Straits - Operation Sentinel Tide",
            "op_global_escalation_chronicle_2028",
            "OPORD 28-USA-01: Chinese carrier group Shandong and nuclear attack subs have crossed the median line. Command CVN-78 Ford CSG and scramjet hypersonics to secure maritime air corridors and protect commercial sea lanes.",
            "BREAKING: US 7TH FLEET SCRAMBLES CARRIER TASKFORCE INTO CONTESTED LITTORALS",
            "Pentagon activates INDOPACOM rapid contingency protocols. Satellite recon indicates massive naval mobilization while autonomous loyal wingman squadrons establish Combat Air Patrol.",
            "video_atk",
            0,
            "",
        ),
        (
            "usa_node_act2_deep_strike",
            "usa",
            2,
            "Act II-A: Forward Spearhead - Operation Obsidian Talon",
            "op_red_strait_swarm",
            "OPORD 28-USA-02A: Tactical victory in the outer strait allows forward strike operations. Deploy F-35A flights and Dark Eagle hypersonics to neutralize coastal A2/AD missile citadels and naval staging basins.",
            "FLASH: ALLIED AIR-SEA BATTLE COMMENCES DEEP STRIKE ON COASTAL RADAR BASTIONS",
            "Joint Chiefs report successful breakthrough of outer radar picket. Stealth strike packages and robotic loyal wingmen penetrate contested air defense envelope.",
            "video_atk",
            0,
            "",
        ),
        (
            "usa_node_act2_attrition_standoff",
            "usa",
            2,
            "Act II-B: Contested Bastion - Operation Iron Attrition",
            "op_red_strait_swarm",
            "OPORD 28-USA-02B: Battle has devolved into an intense electronic warfare and hypersonic duel. Reinforce logistics lanes with C-17 airbridges, deploy Orca XLUUV autonomous wolfpacks, and hold defensive perimeter.",
            "SPECIAL REPORT: ELECTRONIC WARFARE DUEL ENGULFS THE THEATER; FLEET ON HIGH ALERT",
            "Allied and adversary fleets exchange anti-ship missile salvos in dense littoral choke points. High-energy lasers and Skynex intercept swarms maintain air defense umbrella.",
            "video_def",
            0,
            "",
        ),
        (
            "usa_node_act2_carrier_loss_retaliation",
            "usa",
            2,
            "Act II-C: Emergency Scramble - Operation Retribution Shield",
            "op_red_strait_swarm",
            "OPORD 28-USA-02C: Heavy carrier damage and hypersonic saturation strikes have compromised the forward line. Fall back to Guam-Okinawa axis, activate prompt global kinetic strikes, and launch coordinated submarine wolfpacks.",
            "URGENT: CARRIER BATTLE GROUP SUSTAINS MAJOR HITS; DEFCON 2 DECLARED ACROSS PACIFIC",
            "White House convenes emergency National Security Council. Strategic bombers deploy standoff stealth cruise missiles to prevent collapse of allied perimeter.",
            "video_loss",
            0,
            "",
        ),
        (
            "usa_node_act3_hegemony_restored",
            "usa",
            3,
            "Act III: Decisive Triumph - Pacific Pax Hegemony",
            "op_global_escalation_chronicle_2028",
            "STRATEGIC AFTER-ACTION: Enemy maritime forces completely neutralized. Allied air-sea superiority guarantees sovereign integrity and re-opens global commercial sea lanes.",
            "VICTORY CONFIRMED: ADVERSARY ADMITS NAVAL ROUT; COMPREHENSIVE SURRENDER NEGOTIATED",
            "International maritime freedom re-established. Coalition forces establish permanent multi-domain monitoring mesh across the Western Pacific.",
            "video_win",
            1,
            "VICTORY_HEGEMONY",
        ),
        (
            "usa_node_act3_armistice",
            "usa",
            3,
            "Act III: Frozen Conflict - Geneva Littoral Accord",
            "op_global_escalation_chronicle_2028",
            "STRATEGIC AFTER-ACTION: Mutual attrition exhausts anti-ship missile stockpiles. UN Security Council brokers an immediate ceasefire and demilitarized buffer zone.",
            "DIPLOMATIC FLASH: CEASEFIRE ACCORD RATIFIED IN GENEVA; BUFFER ZONE PATROLLED BY NEUTRALS",
            "Both superpowers freeze combat operations along negotiated demarcation lines. War economy transitions to long-term vigilance and border stabilization.",
            "video_def",
            1,
            "CEASEFIRE_ARMISTICE",
        ),
        (
            "usa_node_act3_nuclear_alert",
            "usa",
            3,
            "Act III: Doomsday Threshold - Global DEFCON 1 Escalation",
            "op_global_escalation_chronicle_2028",
            "STRATEGIC AFTER-ACTION: Catastrophic strike on strategic deterrence facilities triggers nationwide DEFCON 1 alert. Submarine-launched ballistic forces stand by for final retaliation.",
            "RED FLASH: STRATCOM ORDERS DEFCON 1; COLUMBIA-CLASS BOOMERS RECEIVE EXECUTION ORDERS",
            "Global sirens echo as the world balances on the brink of thermonuclear exchange. Kinetic orbital strikes and ASAT lasers disable early warning satellite constellations.",
            "video_loss",
            1,
            "NUCLEAR_ESCALATION",
        ),
        (
            "usa_node_act3_pacific_retreat",
            "usa",
            3,
            "Act III: Strategic Retrenchment - Second Island Chain Fallback",
            "op_global_escalation_chronicle_2028",
            "STRATEGIC AFTER-ACTION: Overwhelming hypersonic salvos breach theater defenses. US Pacific Command executes retrograde maneuver to Hawaii and continental bastions.",
            "WAR BULLETIN: ALLIED FORCES RETREAT TO MID-PACIFIC; ADVERSARY OCCUPIES MARITIME BASINS",
            "Major geopolitical realignment underway as Western Pacific presence is dismantled. Emergency mobilization enacted along North American Pacific coastlines.",
            "video_loss",
            1,
            "DEFEAT_COLLAPSE",
        ),

        # =========================================================
        # TAIWAN STORY TREE (Porcupine Defense & Swarm Warfare)
        # =========================================================
        (
            "taiwan_node_act1_strait_crossing",
            "taiwan",
            1,
            "Act I: Shoreline Tempest - Operation Porcupine Shield",
            "op_strait_sentinel_2028",
            "OPORD 28-ROC-01: An armada of 120 amphibious landing ships and drone swarms approaches Penghu Islands and Taoyuan coast. Unleash coastal Harpoon batteries, fiber-optic FPV swarms, and Sea Baby naval drones.",
            "BREAKING NEWS: MASS AMPHIBIOUS INVASION FLEET DETECTED CROSSING TAIWAN STRAIT",
            "Civil defense sirens sound across Taipei and Kaohsiung. Taiwanese armed forces scramble mobile missile TELs into fortified mountain shelters and activate highway runway dispersal.",
            "video_atk",
            0,
            "",
        ),
        (
            "taiwan_node_act2_littoral_ambush",
            "taiwan",
            2,
            "Act II-A: Littoral Ambush - Operation Coral Wolfpack",
            "op_yushan_ridge_defense",
            "OPORD 28-ROC-02A: Landing craft routed in the surf zone. Deploy Tuo Chiang stealth catamarans, armed robot dog units, and precision artillery to crush surviving beachhead pockets.",
            "EXCLUSIVE: BEACHHEAD LANDINGS CRUSHED BY ROBOTIC MINELAYERS AND FPV DRONE WAVES",
            "Ministry of National Defense releases reconnaissance footage of destroyed amphibious transports. Coastal defense batteries continue interdiction of enemy follow-on echelons.",
            "video_win",
            0,
            "",
        ),
        (
            "taiwan_node_act2_mountain_redoubt",
            "taiwan",
            2,
            "Act II-B: Central Redoubt - Operation Jade Mountain",
            "op_yushan_ridge_defense",
            "OPORD 28-ROC-02B: Enemy mechanized spearheads penetrate northern plains. Fall back to steep Yushan mountain ridges, unleash cliff-climbing Vision 60 robot dogs and drone ambushes.",
            "SPECIAL DISPATCH: COMBAT SHIFTS TO JADE MOUNTAIN PASSES AS GUERRILLA CAMPAIGN ESCALATES",
            "High-altitude mountain passes become impregnable defensive redoubts. Adversary armor stalls on 30-degree slopes under devastating drone-guided artillery strikes.",
            "video_def",
            0,
            "",
        ),
        (
            "taiwan_node_act2_taipei_siege",
            "taiwan",
            2,
            "Act II-C: Urban Citadel - Operation Dragon Citadel",
            "op_yushan_ridge_defense",
            "OPORD 28-ROC-02C: Heavy coastal bombardment breaches outer seawalls. Form urban defense rings in New Taipei City, deploy man-portable Javelins from fortified high-rises, and hold until foreign coalition arrives.",
            "WAR DISPATCH: STREET FIGHTING ENGULFS SUBURBAN TAIPEI; ALLIED COALITION AIRLIFT PENDING",
            "Civilians evacuate into massive underground subway bunkers as urban defense militia engages advancing mechanized infantry. High-rise rubble converted into anti-tank strongpoints.",
            "video_loss",
            0,
            "",
        ),
        (
            "taiwan_node_act3_invasion_repelled",
            "taiwan",
            3,
            "Act III: Sovereign Defiance - The Strait Repelled",
            "op_strait_sentinel_2028",
            "STRATEGIC AFTER-ACTION: Amphibious invasion fleet completely shattered in the littoral. Enemy remnants surrender en masse; sovereign democracy secured for a generation.",
            "TRIUMPHANT COMMUNIQUE: TAIWAN STRAIT CLEARED; INVASION FORCES SUFFER HISTORIC DEFEAT",
            "National Day parade celebrates heroic porcupine defense. Allied naval taskforces arrive to escort commercial merchant convoys into Port of Kaohsiung.",
            "video_win",
            1,
            "VICTORY_HEGEMONY",
        ),
        (
            "taiwan_node_act3_frozen_strait",
            "taiwan",
            3,
            "Act III: Armistice Line - The 2028 Demarcation Treaty",
            "op_strait_sentinel_2028",
            "STRATEGIC AFTER-ACTION: Both militaries sustain unsustainable attrition. International coalition mediates a permanent maritime demilitarized zone under UN monitoring.",
            "DIPLOMATIC FLASH: CROSS-STRAIT ARMISTICE SIGNED; DEMILITARIZED BUFFER ZONE ESTABLISHED",
            "Heavy missile strikes cease across the island. Fortified garrisons remain on 24-hour alert along the hardened coastal perimeter.",
            "video_def",
            1,
            "CEASEFIRE_ARMISTICE",
        ),
        (
            "taiwan_node_act3_escalation_flashpoint",
            "taiwan",
            3,
            "Act III: Superpower Climax - Strategic Deterrence Broken",
            "op_strait_sentinel_2028",
            "STRATEGIC AFTER-ACTION: Direct clash between superpower naval fleets in the strait leads to tactical nuclear employment on maritime carrier taskforces.",
            "BREAKING FLASH: NUCLEAR DETONATION OVER TAIWAN STRAIT SHOCKS WORLD FINANCIAL MARKETS",
            "Emergency hotlines between Washington and Beijing activate as tactical warhead vaporizes offshore battle fleet. Global air travel grounded worldwide.",
            "video_loss",
            1,
            "NUCLEAR_ESCALATION",
        ),
        (
            "taiwan_node_act3_capitulation",
            "taiwan",
            3,
            "Act III: Island Darkness - Fall of the Redoubt",
            "op_strait_sentinel_2028",
            "STRATEGIC AFTER-ACTION: Munitions depots exhausted after 60 days of relentless siege. Government signs emergency surrender to avert total civilian catastrophe.",
            "SOBERING HEADLINE: TAIPEI CAPITULATES AS RESUPPLY CONVOYS BLOCKED; OCCUPATION COMMENCES",
            "Final radio transmission from the presidential bunker thanks coalition allies before going dark. Airborne occupation brigades land at Taoyuan International Airport.",
            "video_loss",
            1,
            "DEFEAT_COLLAPSE",
        ),

        # =========================================================
        # POLAND STORY TREE (NATO Eastern Shield & Suwalki Gap)
        # =========================================================
        (
            "poland_node_act1_suwalki_incursion",
            "poland",
            1,
            "Act I: Iron Frontier - Operation Suwalki Bastion",
            "op_baltic_shield_suwalki",
            "OPORD 28-POL-01: Belarusian armored columns and Kaliningrad missile regiments thrust into the Suwalki Corridor. Scramble 18th Mechanized Division (Leopard 2A8, THeMIS UGVs, Skynex C-UAS) to plug the gap.",
            "WAR FLASH: ADVERSARY MECH COLUMNS LAUNCH SURPRISE PUSH INTO SUWALKI CORRIDOR",
            "Polish General Staff invokes NATO Article 4 consultations. Armored cavalry divisions rush to reinforce border villages along the Lithuanian-Polish frontier.",
            "video_atk",
            0,
            "",
        ),
        (
            "poland_node_act2_kaliningrad_containment",
            "poland",
            2,
            "Act II-A: Northern Counter-Thrust - Operation Baltic Hammer",
            "op_baltic_shield_suwalki",
            "OPORD 28-POL-02A: Enemy breakthrough repulsed at Augustow Canal. Launch synchronized strike with Rafale F4 and HIMARS salvos to isolate and neutralize Kaliningrad S-400 SAM batteries.",
            "FRONT REPORT: POLISH ARMOR ENCIRCLES ENEMY SPEARHEAD; S-400 BATTERIES BLOWN BY HIMARS",
            "NATO Allied Land Command confirms destruction of enemy artillery regiments. Polish Leopard 2A8 platoons lead counter-offensive toward the Baltic coastline.",
            "video_win",
            0,
            "",
        ),
        (
            "poland_node_act2_vistula_barrier",
            "poland",
            2,
            "Act II-B: Sovereign Line - Operation Vistula Shield",
            "op_baltic_shield_suwalki",
            "OPORD 28-POL-02B: Fierce enemy Iskander-M salvos disrupt border bridges. Fall back to prepared anti-tank ditch lines along the Biebrza Marshes and establish Skynex drone killzones.",
            "DISPATCH: FIERCE TANK DUELS IN THE BIEBRZA MARSHES AS POLISH DEFENDERS DIG IN",
            "Adversary T-90M tanks become bogged down in wetland terrain under non-stop FPV drone strikes. Rheinmetall Skynex 35mm guns down 98% of incoming cruise missiles.",
            "video_def",
            0,
            "",
        ),
        (
            "poland_node_act2_nato_article5_call",
            "poland",
            2,
            "Act II-C: Emergency Redoubt - Operation Warsaw Rampart",
            "op_baltic_shield_suwalki",
            "OPORD 28-POL-02C: Heavy hypersonic strikes breach the eastern border line. NATO formally invokes Article 5 collective defense. Hold the Warsaw-Deblin bridgeheads until allied reinforcements arrive.",
            "HISTORIC ALLIANCE ACTION: NATO UNANIMOUSLY INVOKES ARTICLE 5 AFTER BORDER CITADEL OVERRUN",
            "American, British, and German rapid-reaction divisions deploy across Germany into western Poland. Massive air corridors opened above Warsaw to supply artillery munitions.",
            "video_loss",
            0,
            "",
        ),
        (
            "poland_node_act3_eastern_shield_intact",
            "poland",
            3,
            "Act III: Eastern Shield Unbroken - Sovereign Fortress",
            "op_baltic_shield_suwalki",
            "STRATEGIC AFTER-ACTION: The Suwalki corridor remains open and inviolable. Adversary offensive forces utterly decimated; Poland establishes permanent eastern security cordon.",
            "ALLIED TRIUMPH: SUWALKI CORRIDOR SECURED; NATO REAFFIRMS INTEGRITY OF EASTERN FLANK",
            "Warsaw military parade displays captured enemy equipment. Allied heads of state praise the unbreakable Eastern Shield defense.",
            "video_win",
            1,
            "VICTORY_HEGEMONY",
        ),
        (
            "poland_node_act3_suwalki_armistice",
            "poland",
            3,
            "Act III: Standoff Treaty - The Bialystok Protocol",
            "op_baltic_shield_suwalki",
            "STRATEGIC AFTER-ACTION: High casualties force both coalitions to negotiate. A 50km demilitarized exclusion zone is established along the Belarusian border.",
            "PEACE TREATY: BIALYSTOK ARMISTICE CONFIRMED; HEAVY WEAPONS WITHDRAWN FROM BORDER",
            "Artillery fire ceases along the eastern front. Drone reconnaissance patrols monitor compliance under international observer supervision.",
            "video_def",
            1,
            "CEASEFIRE_ARMISTICE",
        ),
        (
            "poland_node_act3_nato_nuclear_threshold",
            "poland",
            3,
            "Act III: Atomic Stand-Down - Tactical Weapons Deployed",
            "op_baltic_shield_suwalki",
            "STRATEGIC AFTER-ACTION: Enemy tactical nuclear artillery detonates in Polish marshlands, prompting immediate French-British-American retaliatory nuclear posture.",
            "SHOCKING COMMUNIQUE: TACTICAL ATOMIC WEAPON DETONATED IN POLISH BORDER SECTOR",
            "Emergency NATO nuclear consultation group convenes in Brussels. Worldwide broadcast urges immediate cessation of hostilities before strategic launch.",
            "video_loss",
            1,
            "NUCLEAR_ESCALATION",
        ),
        (
            "poland_node_act3_baltic_collapse",
            "poland",
            3,
            "Act III: Baltic Cutoff - Severance of the Corridor",
            "op_baltic_shield_suwalki",
            "STRATEGIC AFTER-ACTION: Enemy armored pincers link Kaliningrad with Belarus, isolating the Baltic States. Allied command scrambles to establish new defensive line on the Oder.",
            "TRAGIC DISPATCH: SUWALKI CORRIDOR SEVERED; BALTIC ALLIES CUT OFF FROM EUROPEAN LAND BRIDGE",
            "Emergency naval evacuation begins in Riga and Tallinn as eastern defenses buckle. Warsaw declares nationwide state of martial mobilization.",
            "video_loss",
            1,
            "DEFEAT_COLLAPSE",
        ),

        # =========================================================
        # UKRAINE STORY TREE (240k Frontline & Drone-Artillery War)
        # =========================================================
        (
            "ukraine_node_act1_donbas_breakthrough",
            "ukraine",
            1,
            "Act I: Steppe Crucible - Operation Donbas Bastion",
            "op_ukraine_donbas_2028",
            "OPORD 28-UKR-01: 240,000 enemy troops, 1,200 tanks, and FAB glide-bomb regiments launch multi-axis assault on Pokrovsk and Kramatorsk. Deploy T-84 Oplot armor, Bohdana 155mm howitzers, and fiber-optic FPV swarms to hold the ridge.",
            "FRONT COMMUNIQUE: HIGH-DENSITY MECHANIZED ASSAULT LAUNCHED ACROSS DONBAS RIDGELINE",
            "General Staff reports over 400 combat engagements along 600km front. Ukrainian drone command launches 5,000 fiber-optic FPVs in opening 4 hours.",
            "video_atk",
            0,
            "",
        ),
        (
            "ukraine_node_act2_azov_counteroffensive",
            "ukraine",
            2,
            "Act II-A: Southern Thrust - Operation Azov Breaker",
            "op_ukraine_donbas_2028",
            "OPORD 28-UKR-02A: Enemy mechanized thrust bled dry in Donbas killzones. Launch rapid counter-thrust toward Melitopol with Leopard 2A8 armor and Palianytsia rocket-drone deep strikes on rear supply hubs.",
            "EXCLUSIVE: UKRAINIAN ARMOR BREAKS THROUGH SOUTHERN DEFENSE LINE TOWARD AZOV COAST",
            "Reconnaissance feeds confirm liberation of key transport junctions. Deep-strike Palianytsia drones crater ammunition depots and bridge crossings.",
            "video_win",
            0,
            "",
        ),
        (
            "ukraine_node_act2_trench_attrition",
            "ukraine",
            2,
            "Act II-B: Fortress Line - Operation Iron Trench",
            "op_ukraine_donbas_2028",
            "OPORD 28-UKR-02B: Fierce glide-bomb barrages prevent offensive maneuver. Fortify concrete pillboxes, deploy autonomous robot dogs for subterranean clearing, and wage relentless drone attrition war.",
            "WAR DISPATCH: TRENCH WARFARE INTENSIFIES; AUTONOMOUS FPV INTERDICTION DRIES UP SUPPLY CONVOYS",
            "Frontlines stabilize into hardened multi-layered fortifications. Neither side can concentrate armor under non-stop drone surveillance and precision cluster munition strikes.",
            "video_def",
            0,
            "",
        ),
        (
            "ukraine_node_act2_dnipro_last_stand",
            "ukraine",
            2,
            "Act II-C: River Rampart - Operation Dnipro Fortress",
            "op_ukraine_donbas_2028",
            "OPORD 28-UKR-02C: Massive enemy numerical superiority forces orderly withdrawal. Blow eastern bridges and anchor defense along the wide Dnipro River with Neptune anti-ship missiles and coastal batteries.",
            "CRITICAL ALERT: BRIDGES BLOWN ACROSS DNIPRO AS DEFENDERS RETIRE TO WEST BANK REDOUBTS",
            "Engineers detonate crossings to halt advancing tank columns. Western bank artillery batteries unleash devastating barrages against amphibious assault boats.",
            "video_loss",
            0,
            "",
        ),
        (
            "ukraine_node_act3_sovereign_liberation",
            "ukraine",
            3,
            "Act III: Sovereign Restoration - The Azov Victory",
            "op_ukraine_donbas_2028",
            "STRATEGIC AFTER-ACTION: Decisive counter-thrust reaches the Sea of Azov, severing the southern land bridge. Adversary forces sign unconditional withdrawal protocol.",
            "HISTORIC COMMUNIQUE: TOTAL LIBERATION ACHIEVED; SOVEREIGN BORDERS RESTORED ACROSS ALL FRONTS",
            "Jubilant celebrations across Ukrainian cities as victory is broadcast worldwide. International reconstruction fund activated.",
            "video_win",
            1,
            "VICTORY_HEGEMONY",
        ),
        (
            "ukraine_node_act3_donbas_ceasefire",
            "ukraine",
            3,
            "Act III: Exhaustion Armistice - The Black Sea Pact",
            "op_ukraine_donbas_2028",
            "STRATEGIC AFTER-ACTION: Both armies reach the limit of logistic endurance. International mediation establishes a fortified demilitarized cordon with EU peacekeeping observers.",
            "DIPLOMATIC FLASH: ARMISTICE SIGNED IN RIYADH; WEAPONS SILENCED ALONG 1,000KM FRONT",
            "Guns fall silent across the scarred steppe. Massive de-mining and drone-sweeping operations begin under blue-helmet supervision.",
            "video_def",
            1,
            "CEASEFIRE_ARMISTICE",
        ),
        (
            "ukraine_node_act3_cbrn_threat",
            "ukraine",
            3,
            "Act III: Nuclear Blackmail - The Reactor Crisis",
            "op_ukraine_donbas_2028",
            "STRATEGIC AFTER-ACTION: Strike near Zaporizhzhia nuclear plant risks regional catastrophe, triggering international emergency summit and allied threat of direct intervention.",
            "GLOBAL CRISIS: RADIATION SENSORS DETECT LEAK NEAR ZAPORIZHZHIA; UN SECURITY COUNCIL CONVENES",
            "Emergency evacuation perimeter declared around the Dnieper basin. World leaders warn of catastrophic military response if reactor containment fails.",
            "video_loss",
            1,
            "NUCLEAR_ESCALATION",
        ),
        (
            "ukraine_node_act3_frontline_shattered",
            "ukraine",
            3,
            "Act III: Bitter Resistance - Fallback to the Carpathians",
            "op_ukraine_donbas_2028",
            "STRATEGIC AFTER-ACTION: Overwhelming artillery weight shatters central defensive nodes. Military commands pivot to long-term insurgency and western mountain redoubts.",
            "SOBERING BULLETIN: CENTRAL DEFENSIVE NODES SHATTERED; PARTISAN RESISTANCE DECLARED",
            "Government relocates administrative apparatus to Lviv as partisans continue sabotaging occupying rail networks with fiber-optic FPV swarms.",
            "video_loss",
            1,
            "DEFEAT_COLLAPSE",
        ),

        # =========================================================
        # SOUTH KOREA STORY TREE (Korean DMZ & Three-Axis Kill Chain)
        # =========================================================
        (
            "korea_node_act1_dmz_artillery_duel",
            "south_korea",
            1,
            "Act I: Peninsula Thunder - Operation Iron Aegis",
            "op_korean_thunder_dmz",
            "OPORD 28-ROK-01: Massive KN-25 600mm MLRS and heavy artillery bombard the DMZ sector. Scramble KF-21 Boramae flights, fire K9A2 Thunder batteries, and deploy K2 Black Panthers to repel armor incursions.",
            "EMERGENCY FLASH: MASSIVE ARTILLERY BARRAGE OPENS ALONG THE 38TH PARALLEL DMZ",
            "Seoul civil defense sirens sound as missile defense batteries engage inbound rocket salvos. 7th ROK Corps executes rapid forward deployment into western invasion corridors.",
            "video_atk",
            0,
            "",
        ),
        (
            "korea_node_act2_pyongyang_decapitation",
            "south_korea",
            2,
            "Act II-A: Three-Axis Strike - Operation Falcon Claw",
            "op_korean_thunder_dmz",
            "OPORD 28-ROK-02A: Enemy artillery citadels suppressed by counter-battery radar. Launch 8-ton Hyunmoo-5 bunker busters against underground command citadels and send K2 armor thrust north across the Imjin.",
            "FRONT COMMUNIQUE: HYUNMOO-5 BUNKER BUSTERS VAPORIZE UNDERGROUND ENEMY COMMAND CENTRES",
            "ROK Joint Chiefs announce total destruction of northern missile TEL silos. Allied mechanized armor crosses the DMZ spearheading counter-offensive toward Kaesong.",
            "video_win",
            0,
            "",
        ),
        (
            "korea_node_act2_dmz_stalemate",
            "south_korea",
            2,
            "Act II-B: Iron Valley - Operation Chosin Shield",
            "op_korean_thunder_dmz",
            "OPORD 28-ROK-02B: Fierce mountain warfare locks combatants in the rugged Taebaek peaks. Deploy Vision 60 robot dog packs with 4D LiDAR to spot camouflaged bunker entrances and hold the mountain crests.",
            "SPECIAL REPORT: HIGH-ALTITUDE MOUNTAIN COMBAT ENGULFS TAEBAEK RANGE",
            "Robot dog units navigate cliff faces in zero visibility, painting targets for standoff smart glide-bombs. Both armies construct fortified mountain artillery redoubts.",
            "video_def",
            0,
            "",
        ),
        (
            "korea_node_act2_seoul_under_fire",
            "south_korea",
            2,
            "Act II-C: Metropolitan Rampart - Operation Capital Shield",
            "op_korean_thunder_dmz",
            "OPORD 28-ROK-02C: Dense rocket barrages damage northern Seoul suburbs. Relocate strategic defense assets to Han River bridges, deploy Iron Beam laser batteries, and hold the capital perimeter.",
            "URGENT DISPATCH: CIVILIAN SHELTERS FULL AS SEOUL CAPITAL AREA DEFENDS AGAINST ASSAULT",
            "Emergency air defense grid intercepts 94% of incoming warheads. Capital Defense Command prepares urban anti-armor defenses along northern expressway approaches.",
            "video_loss",
            0,
            "",
        ),
        (
            "korea_node_act3_peninsula_unification",
            "south_korea",
            3,
            "Act III: Sovereign Unification - The Free Peninsula",
            "op_korean_thunder_dmz",
            "STRATEGIC AFTER-ACTION: Total collapse of opposing regime leadership following Hyunmoo-5 strikes. ROK forces enter Pyongyang peacefully to oversee national reunification.",
            "HISTORIC COMMUNIQUE: PENINSULA REUNIFIED; PYONGYANG WELCOMES UNIFICATION PEACE MISSION",
            "Millions celebrate across Seoul and Pyongyang as the 75-year division comes to an end. Massive humanitarian aid convoys cross the former DMZ.",
            "video_win",
            1,
            "VICTORY_HEGEMONY",
        ),
        (
            "korea_node_act3_panmunjom_accord",
            "south_korea",
            3,
            "Act III: Armistice Restored - The Panmunjom Accord",
            "op_korean_thunder_dmz",
            "STRATEGIC AFTER-ACTION: Heavy casualties on both sides lead to international ceasefire mediation. Both forces withdraw 10km behind a newly reinforced security cordon.",
            "DIPLOMATIC FLASH: CEASEFIRE RATIFIED AT PANMUNJOM; HEAVY ARTILLERY RETRACTED 20KM",
            "Armistice commission establishes automated sensor towers to monitor peace across the peninsula. Joint security patrols resume along demarcated lines.",
            "video_def",
            1,
            "CEASEFIRE_ARMISTICE",
        ),
        (
            "korea_node_act3_theater_nuclear_exchange",
            "south_korea",
            3,
            "Act III: Nuclear Retaliation - The Broken DMZ",
            "op_korean_thunder_dmz",
            "STRATEGIC AFTER-ACTION: Desperate adversary TEL launches tactical nuclear warhead toward military airfield, prompting allied strategic bomber decapitation strike.",
            "RED BULLETIN: THEATER NUCLEAR DETONATION CONFIRMED; ALLIED RETALIATORY STRIKE EXECUTED",
            "Radiation warning alarms sound across Northeast Asia. Global stock markets tumble as international coalition enforces complete naval-air quarantine.",
            "video_loss",
            1,
            "NUCLEAR_ESCALATION",
        ),
        (
            "korea_node_act3_seoul_fallen",
            "south_korea",
            3,
            "Act III: Southern Bastion - Fallback to Busan Perimeter",
            "op_korean_thunder_dmz",
            "STRATEGIC AFTER-ACTION: Overwhelming swarm saturation forces evacuation of Seoul. ROK military establishes impenetrable fallback redoubt around Busan port perimeter.",
            "WAR BULLETIN: GOVERNMENT RELOCATES TO BUSAN PERIMETER; REGROUPING FOR MAJOR RECOVERY",
            "Allied naval convoys land heavy armored divisions in Busan harbor to reinforce the southern defensive arc. Counter-offensive planning underway.",
            "video_loss",
            1,
            "DEFEAT_COLLAPSE",
        ),
    ]

    for node in story_nodes:
        cur.execute(
            """INSERT INTO campaign_story_nodes (
                   slug, nation_slug, act_number, chapter_title, scenario_slug,
                   situation_briefing, chyron_headline, news_flash_body,
                   action_video_tag, is_terminal_climax, climax_type
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            node,
        )

    # -------------------------------------------------------------
    # 3. Seed Campaign Story Edges (80 Branching Edges: 16 per Nation)
    # -------------------------------------------------------------
    # Helper to generate edges for a nation
    def generate_nation_edges(prefix: str):
        return [
            # Act 1 -> Act 2
            (f"{prefix}_node_act1_recon_crisis" if prefix == "usa" else
             f"{prefix}_node_act1_strait_crossing" if prefix == "taiwan" else
             f"{prefix}_node_act1_suwalki_incursion" if prefix == "poland" else
             f"{prefix}_node_act1_donbas_breakthrough" if prefix == "ukraine" else
             f"{prefix}_node_act1_dmz_artillery_duel",
             f"{prefix}_node_act2_deep_strike" if prefix == "usa" else
             f"{prefix}_node_act2_littoral_ambush" if prefix == "taiwan" else
             f"{prefix}_node_act2_kaliningrad_containment" if prefix == "poland" else
             f"{prefix}_node_act2_azov_counteroffensive" if prefix == "ukraine" else
             f"{prefix}_node_act2_pyongyang_decapitation",
             "OUTCOME_DECISIVE_VICTORY", "Decisive tactical victory opens path for strategic counter-offensive.", 0, "tech_fiber_optic_swarm_bus"),

            (f"{prefix}_node_act1_recon_crisis" if prefix == "usa" else
             f"{prefix}_node_act1_strait_crossing" if prefix == "taiwan" else
             f"{prefix}_node_act1_suwalki_incursion" if prefix == "poland" else
             f"{prefix}_node_act1_donbas_breakthrough" if prefix == "ukraine" else
             f"{prefix}_node_act1_dmz_artillery_duel",
             f"{prefix}_node_act2_attrition_standoff" if prefix == "usa" else
             f"{prefix}_node_act2_mountain_redoubt" if prefix == "taiwan" else
             f"{prefix}_node_act2_vistula_barrier" if prefix == "poland" else
             f"{prefix}_node_act2_trench_attrition" if prefix == "ukraine" else
             f"{prefix}_node_act2_dmz_stalemate",
             "OUTCOME_TACTICAL_HOLD", "Frontline stabilized at heavy cost; conflict enters grinding attrition phase.", 0, "tech_quadruped_lidar_v2"),

            (f"{prefix}_node_act1_recon_crisis" if prefix == "usa" else
             f"{prefix}_node_act1_strait_crossing" if prefix == "taiwan" else
             f"{prefix}_node_act1_suwalki_incursion" if prefix == "poland" else
             f"{prefix}_node_act1_donbas_breakthrough" if prefix == "ukraine" else
             f"{prefix}_node_act1_dmz_artillery_duel",
             f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             "OUTCOME_HEAVY_ATTRITION", "Severe casualties force immediate emergency mobilization and tactical withdrawal.", 1, ""),

            (f"{prefix}_node_act1_recon_crisis" if prefix == "usa" else
             f"{prefix}_node_act1_strait_crossing" if prefix == "taiwan" else
             f"{prefix}_node_act1_suwalki_incursion" if prefix == "poland" else
             f"{prefix}_node_act1_donbas_breakthrough" if prefix == "ukraine" else
             f"{prefix}_node_act1_dmz_artillery_duel",
             f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             "OUTCOME_DEFEAT", "Defensive lines breached; military command falls back to secondary redoubt.", 1, ""),

            # Act 2-A -> Act 3
            (f"{prefix}_node_act2_deep_strike" if prefix == "usa" else
             f"{prefix}_node_act2_littoral_ambush" if prefix == "taiwan" else
             f"{prefix}_node_act2_kaliningrad_containment" if prefix == "poland" else
             f"{prefix}_node_act2_azov_counteroffensive" if prefix == "ukraine" else
             f"{prefix}_node_act2_pyongyang_decapitation",
             f"{prefix}_node_act3_hegemony_restored" if prefix == "usa" else
             f"{prefix}_node_act3_invasion_repelled" if prefix == "taiwan" else
             f"{prefix}_node_act3_eastern_shield_intact" if prefix == "poland" else
             f"{prefix}_node_act3_sovereign_liberation" if prefix == "ukraine" else
             f"{prefix}_node_act3_peninsula_unification",
             "OUTCOME_DECISIVE_VICTORY", "Enemy command structure incapacitated; sovereign victory secured.", -1, "tech_prompt_global_salvo"),

            (f"{prefix}_node_act2_deep_strike" if prefix == "usa" else
             f"{prefix}_node_act2_littoral_ambush" if prefix == "taiwan" else
             f"{prefix}_node_act2_kaliningrad_containment" if prefix == "poland" else
             f"{prefix}_node_act2_azov_counteroffensive" if prefix == "ukraine" else
             f"{prefix}_node_act2_pyongyang_decapitation",
             f"{prefix}_node_act3_armistice" if prefix == "usa" else
             f"{prefix}_node_act3_frozen_strait" if prefix == "taiwan" else
             f"{prefix}_node_act3_suwalki_armistice" if prefix == "poland" else
             f"{prefix}_node_act3_donbas_ceasefire" if prefix == "ukraine" else
             f"{prefix}_node_act3_panmunjom_accord",
             "OUTCOME_TACTICAL_HOLD", "Counter-offensive stalls, brokering an internationally supervised ceasefire.", 0, ""),

            (f"{prefix}_node_act2_deep_strike" if prefix == "usa" else
             f"{prefix}_node_act2_littoral_ambush" if prefix == "taiwan" else
             f"{prefix}_node_act2_kaliningrad_containment" if prefix == "poland" else
             f"{prefix}_node_act2_azov_counteroffensive" if prefix == "ukraine" else
             f"{prefix}_node_act2_pyongyang_decapitation",
             f"{prefix}_node_act3_armistice" if prefix == "usa" else
             f"{prefix}_node_act3_frozen_strait" if prefix == "taiwan" else
             f"{prefix}_node_act3_suwalki_armistice" if prefix == "poland" else
             f"{prefix}_node_act3_donbas_ceasefire" if prefix == "ukraine" else
             f"{prefix}_node_act3_panmunjom_accord",
             "OUTCOME_HEAVY_ATTRITION", "Both coalitions exhaust munition reserves, accepting armistice terms.", 0, ""),

            (f"{prefix}_node_act2_deep_strike" if prefix == "usa" else
             f"{prefix}_node_act2_littoral_ambush" if prefix == "taiwan" else
             f"{prefix}_node_act2_kaliningrad_containment" if prefix == "poland" else
             f"{prefix}_node_act2_azov_counteroffensive" if prefix == "ukraine" else
             f"{prefix}_node_act2_pyongyang_decapitation",
             f"{prefix}_node_act3_nuclear_alert" if prefix == "usa" else
             f"{prefix}_node_act3_escalation_flashpoint" if prefix == "taiwan" else
             f"{prefix}_node_act3_nato_nuclear_threshold" if prefix == "poland" else
             f"{prefix}_node_act3_cbrn_threat" if prefix == "ukraine" else
             f"{prefix}_node_act3_theater_nuclear_exchange",
             "OUTCOME_DEFEAT", "Overextended spearhead ambushed, triggering emergency strategic deterrence alert.", 2, ""),

            # Act 2-B -> Act 3
            (f"{prefix}_node_act2_attrition_standoff" if prefix == "usa" else
             f"{prefix}_node_act2_mountain_redoubt" if prefix == "taiwan" else
             f"{prefix}_node_act2_vistula_barrier" if prefix == "poland" else
             f"{prefix}_node_act2_trench_attrition" if prefix == "ukraine" else
             f"{prefix}_node_act2_dmz_stalemate",
             f"{prefix}_node_act3_hegemony_restored" if prefix == "usa" else
             f"{prefix}_node_act3_invasion_repelled" if prefix == "taiwan" else
             f"{prefix}_node_act3_eastern_shield_intact" if prefix == "poland" else
             f"{prefix}_node_act3_sovereign_liberation" if prefix == "ukraine" else
             f"{prefix}_node_act3_peninsula_unification",
             "OUTCOME_DECISIVE_VICTORY", "Attrition warfare breaks enemy supply lines leading to total collapse.", -1, ""),

            (f"{prefix}_node_act2_attrition_standoff" if prefix == "usa" else
             f"{prefix}_node_act2_mountain_redoubt" if prefix == "taiwan" else
             f"{prefix}_node_act2_vistula_barrier" if prefix == "poland" else
             f"{prefix}_node_act2_trench_attrition" if prefix == "ukraine" else
             f"{prefix}_node_act2_dmz_stalemate",
             f"{prefix}_node_act3_armistice" if prefix == "usa" else
             f"{prefix}_node_act3_frozen_strait" if prefix == "taiwan" else
             f"{prefix}_node_act3_suwalki_armistice" if prefix == "poland" else
             f"{prefix}_node_act3_donbas_ceasefire" if prefix == "ukraine" else
             f"{prefix}_node_act3_panmunjom_accord",
             "OUTCOME_TACTICAL_HOLD", "Frontlines freeze into fortified demilitarized zone under treaty supervision.", 0, ""),

            (f"{prefix}_node_act2_attrition_standoff" if prefix == "usa" else
             f"{prefix}_node_act2_mountain_redoubt" if prefix == "taiwan" else
             f"{prefix}_node_act2_vistula_barrier" if prefix == "poland" else
             f"{prefix}_node_act2_trench_attrition" if prefix == "ukraine" else
             f"{prefix}_node_act2_dmz_stalemate",
             f"{prefix}_node_act3_nuclear_alert" if prefix == "usa" else
             f"{prefix}_node_act3_escalation_flashpoint" if prefix == "taiwan" else
             f"{prefix}_node_act3_nato_nuclear_threshold" if prefix == "poland" else
             f"{prefix}_node_act3_cbrn_threat" if prefix == "ukraine" else
             f"{prefix}_node_act3_theater_nuclear_exchange",
             "OUTCOME_HEAVY_ATTRITION", "Critical infrastructure strikes prompt retaliatory nuclear posturing.", 1, ""),

            (f"{prefix}_node_act2_attrition_standoff" if prefix == "usa" else
             f"{prefix}_node_act2_mountain_redoubt" if prefix == "taiwan" else
             f"{prefix}_node_act2_vistula_barrier" if prefix == "poland" else
             f"{prefix}_node_act2_trench_attrition" if prefix == "ukraine" else
             f"{prefix}_node_act2_dmz_stalemate",
             f"{prefix}_node_act3_pacific_retreat" if prefix == "usa" else
             f"{prefix}_node_act3_capitulation" if prefix == "taiwan" else
             f"{prefix}_node_act3_baltic_collapse" if prefix == "poland" else
             f"{prefix}_node_act3_frontline_shattered" if prefix == "ukraine" else
             f"{prefix}_node_act3_seoul_fallen",
             "OUTCOME_DEFEAT", "Defensive lines break under sustained bombardment; national command falls.", 1, ""),

            # Act 2-C -> Act 3
            (f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             f"{prefix}_node_act3_armistice" if prefix == "usa" else
             f"{prefix}_node_act3_frozen_strait" if prefix == "taiwan" else
             f"{prefix}_node_act3_suwalki_armistice" if prefix == "poland" else
             f"{prefix}_node_act3_donbas_ceasefire" if prefix == "ukraine" else
             f"{prefix}_node_act3_panmunjom_accord",
             "OUTCOME_DECISIVE_VICTORY", "Miraculous counter-attack saves capital and forces hasty ceasefire.", 0, ""),

            (f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             f"{prefix}_node_act3_armistice" if prefix == "usa" else
             f"{prefix}_node_act3_frozen_strait" if prefix == "taiwan" else
             f"{prefix}_node_act3_suwalki_armistice" if prefix == "poland" else
             f"{prefix}_node_act3_donbas_ceasefire" if prefix == "ukraine" else
             f"{prefix}_node_act3_panmunjom_accord",
             "OUTCOME_TACTICAL_HOLD", "Foreign intervention halts enemy vanguard; uneasy armistice declared.", 0, ""),

            (f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             f"{prefix}_node_act3_nuclear_alert" if prefix == "usa" else
             f"{prefix}_node_act3_escalation_flashpoint" if prefix == "taiwan" else
             f"{prefix}_node_act3_nato_nuclear_threshold" if prefix == "poland" else
             f"{prefix}_node_act3_cbrn_threat" if prefix == "ukraine" else
             f"{prefix}_node_act3_theater_nuclear_exchange",
             "OUTCOME_HEAVY_ATTRITION", "Desperate standoff escalates to tactical WMD threshold.", 2, ""),

            (f"{prefix}_node_act2_carrier_loss_retaliation" if prefix == "usa" else
             f"{prefix}_node_act2_taipei_siege" if prefix == "taiwan" else
             f"{prefix}_node_act2_nato_article5_call" if prefix == "poland" else
             f"{prefix}_node_act2_dnipro_last_stand" if prefix == "ukraine" else
             f"{prefix}_node_act2_seoul_under_fire",
             f"{prefix}_node_act3_pacific_retreat" if prefix == "usa" else
             f"{prefix}_node_act3_capitulation" if prefix == "taiwan" else
             f"{prefix}_node_act3_baltic_collapse" if prefix == "poland" else
             f"{prefix}_node_act3_frontline_shattered" if prefix == "ukraine" else
             f"{prefix}_node_act3_seoul_fallen",
             "OUTCOME_DEFEAT", "Allied defenses overrun; theater operations collapse.", 1, ""),
        ]

    for pfx in ("usa", "taiwan", "poland", "ukraine", "korea"):
        for edge in generate_nation_edges(pfx):
            cur.execute(
                """INSERT INTO campaign_story_edges (
                       from_node_slug, to_node_slug, condition_outcome,
                       transition_narrative, defcon_escalation, unlocked_tech_slug
                   ) VALUES (?, ?, ?, ?, ?, ?)""",
                edge,
            )

    print("=== Campaign Narrative Seeded Successfully: 5 Nations, 40 Story Nodes, 80 Branching Edges ===")


if __name__ == "__main__":
    db_path = Path(__file__).resolve().parents[2] / "data" / "wargame.db"
    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()
    seed_campaign_narrative(cur)
    conn.commit()
    conn.close()

#!/usr/bin/env python3
"""
Seeds China and Russia playable campaign nations, story nodes, and branching edges
into `data/wargame.db` and mirrors them into `data/wargame_cache.json`.
"""

import json
import sqlite3
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "data"
DB_PATH = DATA_DIR / "wargame.db"
CACHE_JSON_PATH = DATA_DIR / "wargame_cache.json"

NATIONS = [
    {
        "slug": "china",
        "country_name": "People's Republic of China",
        "iso_code": "CHN",
        "capital_name": "Beijing",
        "flag_res_path": "res://assets/ui/flags/china.png",
        "theater_slug": "strait_theater",
        "doctrine_label": "A2/AD Hypersonic Saturation & Maritime Siege",
        "doctrine_summary": "Eastern & Southern Theater Command doctrine emphasizing anti-ship ballistic missiles (DF-21D/DF-26D), Type 055 guided missile cruisers, and orbital ASAT laser dazzling.",
        "budget_musd": 4500.0,
        "is_playable": 1,
        "unlocked_by_default": 1,
        "starting_node_slug": "china_node_act1_strait_blockade",
        "flagship_platform_slug": "cn_type055_destroyer",
        "special_capabilities_json": json.dumps({
            "hypersonic_anti_ship": 1,
            "asat_laser_dazzling": 1,
            "drone_swarm_interdiction": 1
        })
    },
    {
        "slug": "russia",
        "country_name": "Russian Federation",
        "iso_code": "RUS",
        "capital_name": "Moscow",
        "flag_res_path": "res://assets/ui/flags/russia.png",
        "theater_slug": "baltic_theater",
        "doctrine_label": "Broadband CEMA Jamming & Strategic Retaliation",
        "doctrine_summary": "Strategic Rocket Forces and Northern Fleet doctrine emphasizing Krasukha-4 broadband electronic warfare, Kaliningrad bastion anti-ship missiles, and fail-deadly nuclear triad defense.",
        "budget_musd": 3200.0,
        "is_playable": 1,
        "unlocked_by_default": 1,
        "starting_node_slug": "russia_node_act1_suwalki_thrust",
        "flagship_platform_slug": "ru_yasen_sub",
        "special_capabilities_json": json.dumps({
            "cema_broadband_jamming": 1,
            "subsea_cable_interdiction": 1,
            "dead_hand_nuclear_triad": 1
        })
    }
]

STORY_NODES = [
    # China Campaign Tree
    {
        "slug": "china_node_act1_strait_blockade",
        "nation_slug": "china",
        "act_number": 1,
        "chapter_title": "Act 1: Joint Sword - Taiwan Strait Blockade",
        "scenario_slug": "op_red_strait_swarm",
        "situation_briefing": "PLA Eastern Theater Command initiates joint multi-domain blockade operations across the Taiwan Strait. Deploy DF-21D/DF-26D batteries, Type 055 destroyers, and J-20A fighter sweeps.",
        "chyron_headline": "BREAKING: PLA ANNOUNCES COMPREHENSIVE COMBINED-ARMS BLOCKADE AROUND TAIWAN",
        "news_flash_body": "CCTV / Global Times Report: Frontline maritime and rocket forces seal navigation corridors and project dense anti-access bubbles across littoral straits.",
        "action_video_tag": "naval_carrier_strike",
        "is_terminal_climax": 0,
        "climax_type": ""
    },
    {
        "slug": "china_node_act2_island_landing",
        "nation_slug": "china",
        "act_number": 2,
        "chapter_title": "Act 2: Dragon Leap - Amphibious Assault & Penghu Breakthrough",
        "scenario_slug": "op_red_strait_swarm",
        "situation_briefing": "Decisive victory in the naval air battle allows amphibious landing flotillas and Type 075 LHDs to initiate littoral beachhead operations.",
        "chyron_headline": "CRISIS UPDATE: AMPHIBIOUS TRANSPORTS MOVE TOWARD BEACHHEADS UNDER AIR SCREEN",
        "news_flash_body": "Xinhua Flash: Marine corps mechanized armor establishes lodgments on western shores as opposing coastal missile batteries are neutralized.",
        "action_video_tag": "urban_armor_robot_dogs",
        "is_terminal_climax": 0,
        "climax_type": ""
    },
    {
        "slug": "china_node_act2_prolonged_siege",
        "nation_slug": "china",
        "act_number": 2,
        "chapter_title": "Act 2: Iron Wall - Submarine & Attrition War of Attrition",
        "scenario_slug": "op_red_strait_swarm",
        "situation_briefing": "Heavy adversary Allied carrier strike group counter-offensive forces theater into protracted maritime attrition.",
        "chyron_headline": "WAR DESK: HIGH-INTENSITY NAVAL DUELS IN WESTERN PACIFIC CAUSE SEVERE WARSHIP LOSSES",
        "news_flash_body": "International News: Carrier battle groups trade massive anti-ship salvos while undersea attack submarines duel across deep oceanic trenches.",
        "action_video_tag": "sam_air_defense_intercept",
        "is_terminal_climax": 0,
        "climax_type": ""
    },
    {
        "slug": "china_node_act3_pacific_hegemony",
        "nation_slug": "china",
        "act_number": 3,
        "chapter_title": "Act 3 Climax: Red Sun Over the First Island Chain",
        "scenario_slug": "op_red_strait_swarm",
        "situation_briefing": "Allied naval power forced east of Guam. Complete strategic control established over First Island Chain.",
        "chyron_headline": "WORLD BULLETIN: PEACE ARMISTICE SIGNED IN SINGAPORE; FIRST ISLAND CHAIN RECOGNIZED",
        "news_flash_body": "Global War Desk: Hostilities conclude under negotiated armistice as regional naval supremacy shifts decisively.",
        "action_video_tag": "stealth_airstrike_sortie",
        "is_terminal_climax": 1,
        "climax_type": "VICTORY_HEGEMONY"
    },
    {
        "slug": "china_node_act3_nuclear_escalation",
        "nation_slug": "china",
        "act_number": 3,
        "chapter_title": "Act 3 Climax: Strategic Retaliation - DEFCON 1",
        "scenario_slug": "op_red_strait_swarm",
        "situation_briefing": "Escalation surpasses threshold following strikes on coastal command citadels. DF-41 road-mobile ICBMs spooled for strategic retaliation.",
        "chyron_headline": "FLASH ALERT: DEFCON 1 DECLARED; STRATEGIC ROCKET FORCES COMMITTED TO FULL SALVO",
        "news_flash_body": "Emergency Broadcast System: Thermonuclear detonations confirmed at multiple military redoubts as global crisis reaches absolute apex.",
        "action_video_tag": "thermonuclear_detonation",
        "is_terminal_climax": 1,
        "climax_type": "NUCLEAR_ESCALATION"
    },

    # Russia Campaign Tree
    {
        "slug": "russia_node_act1_suwalki_thrust",
        "nation_slug": "russia",
        "act_number": 1,
        "chapter_title": "Act 1: Zapad Storm - Suwalki Gap Offensive",
        "scenario_slug": "op_baltic_shield_suwalki",
        "situation_briefing": "Western Military District forces deploy armored spearheads and Krasukha-4 broadband electronic warfare arrays to link Kaliningrad with Belarus across the Suwalki Corridor.",
        "chyron_headline": "BREAKING: RUSSIAN ARMORED CORPS ADVANCE INTO SUWALKI CORRIDOR UNDER HEAVY EW UMBRELLA",
        "news_flash_body": "TASS / Interfax Alert: GPS and satellite communication signals blackout across the Baltic as mechanized echelons engage forward defense redoubts.",
        "action_video_tag": "urban_armor_robot_dogs",
        "is_terminal_climax": 0,
        "climax_type": ""
    },
    {
        "slug": "russia_node_act2_baltic_bastion",
        "nation_slug": "russia",
        "act_number": 2,
        "chapter_title": "Act 2: Baltic Bastion - Bastion Coastal Shield",
        "scenario_slug": "op_baltic_shield_suwalki",
        "situation_briefing": "Kaliningrad Bastion-P anti-ship batteries and S-400 battalions project total anti-access air defense bubble across the Baltic littoral.",
        "chyron_headline": "STRATEGIC REPORT: NATO FORCES ENGAGE RUSSIAN A2/AD BASTION IN HIGH-INTENSITY AIR BATTLES",
        "news_flash_body": "Baltic News Wire: Intense missile duels light the night sky over Gdansk and Klaipeda as air defense interceptors clash with strike sorties.",
        "action_video_tag": "sam_air_defense_intercept",
        "is_terminal_climax": 0,
        "climax_type": ""
    },
    {
        "slug": "russia_node_act3_dead_hand_defcon1",
        "nation_slug": "russia",
        "act_number": 3,
        "chapter_title": "Act 3 Climax: Perimeter Automated Retaliation - Dead Hand",
        "scenario_slug": "op_baltic_shield_suwalki",
        "situation_briefing": "Automated nuclear command apparatus triggers fail-deadly strategic response across all silo, submarine, and mobile missile wings.",
        "chyron_headline": "DEFCON 1 EMERGENCY: AUTOMATED 'DEAD HAND' STRATEGIC SALVO LAUNCHED WORLDWIDE",
        "news_flash_body": "All News Networks: Strategic nuclear triad launches detected across Arctic and Siberian launch fields as DEFCON 1 conditions engulf the planet.",
        "action_video_tag": "thermonuclear_detonation",
        "is_terminal_climax": 1,
        "climax_type": "NUCLEAR_ESCALATION"
    }
]

STORY_EDGES = [
    # China Edges
    {
        "from_node_slug": "china_node_act1_strait_blockade",
        "to_node_slug": "china_node_act2_island_landing",
        "condition_outcome": "OUTCOME_DECISIVE_VICTORY",
        "transition_narrative": "Strait blockade shatters Allied surface picket line; amphibious assault transport echelons ordered to embark.",
        "defcon_escalation": 1,
        "unlocked_tech_slug": "tech_df26_hypersonic"
    },
    {
        "from_node_slug": "china_node_act1_strait_blockade",
        "to_node_slug": "china_node_act2_prolonged_siege",
        "condition_outcome": "OUTCOME_TACTICAL_HOLD",
        "transition_narrative": "Heavy Allied carrier counter-strikes stall forward landing fleet; theater transitions into deep missile siege.",
        "defcon_escalation": 0,
        "unlocked_tech_slug": ""
    },
    {
        "from_node_slug": "china_node_act1_strait_blockade",
        "to_node_slug": "china_node_act3_nuclear_escalation",
        "condition_outcome": "OUTCOME_DEFEAT",
        "transition_narrative": "Carrier air wings breach mainland coastal air defenses; strategic command prepares nuclear triad retaliation.",
        "defcon_escalation": 2,
        "unlocked_tech_slug": ""
    },
    {
        "from_node_slug": "china_node_act2_island_landing",
        "to_node_slug": "china_node_act3_pacific_hegemony",
        "condition_outcome": "OUTCOME_DECISIVE_VICTORY",
        "transition_narrative": "Amphibious beachheads secured; opposing coalition forces accept terms under Singapore Armistice.",
        "defcon_escalation": -1,
        "unlocked_tech_slug": ""
    },
    {
        "from_node_slug": "china_node_act2_island_landing",
        "to_node_slug": "china_node_act3_nuclear_escalation",
        "condition_outcome": "OUTCOME_HEAVY_ATTRITION",
        "transition_narrative": "Catastrophic casualty rates in beachhead fighting trigger uncontrolled strategic nuclear escalation.",
        "defcon_escalation": 2,
        "unlocked_tech_slug": ""
    },

    # Russia Edges
    {
        "from_node_slug": "russia_node_act1_suwalki_thrust",
        "to_node_slug": "russia_node_act2_baltic_bastion",
        "condition_outcome": "OUTCOME_DECISIVE_VICTORY",
        "transition_narrative": "Suwalki Gap linked to Kaliningrad; Baltic coastal defense shield activated.",
        "defcon_escalation": 1,
        "unlocked_tech_slug": "tech_s400_hypersonic_missile"
    },
    {
        "from_node_slug": "russia_node_act1_suwalki_thrust",
        "to_node_slug": "russia_node_act3_dead_hand_defcon1",
        "condition_outcome": "OUTCOME_DEFEAT",
        "transition_narrative": "NATO counter-offensive breaches Kaliningrad perimeter, triggering automated Dead Hand strategic release.",
        "defcon_escalation": 2,
        "unlocked_tech_slug": ""
    },
    {
        "from_node_slug": "russia_node_act2_baltic_bastion",
        "to_node_slug": "russia_node_act3_dead_hand_defcon1",
        "condition_outcome": "OUTCOME_HEAVY_ATTRITION",
        "transition_narrative": "Standoff cruise strikes destroy command citadels; automated Dead Hand launch sequence initiated.",
        "defcon_escalation": 2,
        "unlocked_tech_slug": ""
    }
]

def seed_superpowers():
    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()

    for n in NATIONS:
        cur.execute(
            """INSERT OR REPLACE INTO campaign_nations (
                   slug, country_name, iso_code, capital_name,
                   flag_res_path, theater_slug, doctrine_label,
                   doctrine_summary, budget_musd, is_playable,
                   unlocked_by_default, starting_node_slug,
                   flagship_platform_slug, special_capabilities_json
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                n["slug"], n["country_name"], n["iso_code"], n["capital_name"],
                n["flag_res_path"], n["theater_slug"], n["doctrine_label"],
                n["doctrine_summary"], n["budget_musd"], n["is_playable"],
                n["unlocked_by_default"], n["starting_node_slug"],
                n["flagship_platform_slug"], n["special_capabilities_json"]
            )
        )

    for node in STORY_NODES:
        cur.execute(
            """INSERT OR REPLACE INTO campaign_story_nodes (
                   slug, nation_slug, act_number, chapter_title, scenario_slug,
                   situation_briefing, chyron_headline, news_flash_body,
                   action_video_tag, is_terminal_climax, climax_type
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                node["slug"], node["nation_slug"], node["act_number"],
                node["chapter_title"], node["scenario_slug"],
                node["situation_briefing"], node["chyron_headline"],
                node["news_flash_body"], node["action_video_tag"],
                node["is_terminal_climax"], node["climax_type"]
            )
        )

    for edge in STORY_EDGES:
        cur.execute(
            """INSERT OR REPLACE INTO campaign_story_edges (
                   from_node_slug, to_node_slug, condition_outcome,
                   transition_narrative, defcon_escalation, unlocked_tech_slug
               ) VALUES (?, ?, ?, ?, ?, ?)""",
            (
                edge["from_node_slug"], edge["to_node_slug"],
                edge["condition_outcome"], edge["transition_narrative"],
                edge["defcon_escalation"], edge["unlocked_tech_slug"]
            )
        )

    conn.commit()

    # Mirror into wargame_cache.json
    conn.row_factory = sqlite3.Row
    rcur = conn.cursor()
    cache_payload = {}
    if CACHE_JSON_PATH.exists():
        cache_payload = json.loads(CACHE_JSON_PATH.read_text(encoding="utf-8"))

    for tbl in ("campaign_nations", "campaign_story_nodes", "campaign_story_edges"):
        rcur.execute(f"SELECT * FROM {tbl}")
        cache_payload[tbl] = [dict(row) for row in rcur.fetchall()]

    CACHE_JSON_PATH.write_text(json.dumps(cache_payload, indent=2), encoding="utf-8")
    conn.close()
    print(f"[SUPERPOWERS SEED] Successfully seeded {len(NATIONS)} nations, {len(STORY_NODES)} nodes, and {len(STORY_EDGES)} edges into wargame.db & JSON cache!")

if __name__ == "__main__":
    seed_superpowers()

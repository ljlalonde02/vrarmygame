#!/usr/bin/env python3
"""
AI Campaign Story Tree Generator for VR/PC Holographic Wargame Simulator.
Generates dynamic mini-stories, OPORDs, TV news chyrons, and action video prompts,
and injects them directly into `data/wargame.db` and `data/wargame_cache.json`.
Supports online generation via Google Gemini API (GEMINI_API_KEY) and offline procedural military templates.
"""

import argparse
import json
import os
import sqlite3
import sys
import urllib.request
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "data"
DB_PATH = DATA_DIR / "wargame.db"
CACHE_JSON_PATH = DATA_DIR / "wargame_cache.json"

DOCTRINE_THEMES = {
    "usa": {
        "callsigns": ["Viper 1-1", "Ghost Rider", "Titan Actual", "Dark Eagle Battery Alpha"],
        "keywords": ["Carrier Strike Group", "Prompt Global Strike", "Hypersonic Salvo", "Autonomous CCA Wing", "A2/AD Penetration"],
        "anchors": ["Global Defense Network", "Strategic Pacific Wire", "Pentagon Press Pool"]
    },
    "taiwan": {
        "callsigns": ["Jade Shield", "Porcupine 6", "Taoyuan Guard", "Penghu Sentinel"],
        "keywords": ["Fiber-Optic FPV Swarms", "Sea Baby Wolfpacks", "Mountain Bunker Redoubts", "Coastal Harpoon Batteries", "Amphibious Interdiction"],
        "anchors": ["Taipei News 24", "Strait Defense Dispatch", "Formosa Watch"]
    },
    "poland": {
        "callsigns": ["White Eagle", "Winged Hussar Actual", "Suwalki Iron Lead", "Vistula Sentinel"],
        "keywords": ["Leopard 2A8 Armor", "Eastern Shield", "Skynex 35mm C-UAS", "Milrem THeMIS UGVs", "NATO Article 5 Forward Defense"],
        "anchors": ["Warsaw Security Wire", "Baltic Strategic Dispatch", "NATO Flank Monitor"]
    },
    "ukraine": {
        "callsigns": ["Steppe Falcon", "Dnipro Shield", "Bohdana Lead", "Azov Horizon"],
        "keywords": ["Palianytsia Rocket-Drones", "Fiber-Optic FPV Kamikazes", "Bohdana 155mm Artillery", "Neptune Coastal Shield", "240k Frontline Complex"],
        "anchors": ["Kyiv Operational Dispatch", "Dnieper Defense Bulletin", "Free Steppe News"]
    },
    "south_korea": {
        "callsigns": ["Tiger Actual", "Baekdu Sentinel", "Falcon Flight", "Hyunmoo Battery Bravo"],
        "keywords": ["Three-Axis Deterrence", "K2 Black Panther", "KF-21 Boramae Meteor", "Hyunmoo-5 Bunker-Busters", "Autonomous Robot Dogs"],
        "anchors": ["Seoul Defense Network", "Peninsula Crisis Wire", "Han River Broadcast"]
    }
}


def call_gemini_api(prompt: str, api_key: str) -> str:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1024}
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        res_data = json.loads(resp.read().decode("utf-8"))
        return res_data["candidates"][0]["content"]["parts"][0]["text"]


def generate_story_node_data(nation_slug: str, act: int, scenario_slug: str, branch_type: str = "OFFENSIVE") -> dict:
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    theme = DOCTRINE_THEMES.get(nation_slug, DOCTRINE_THEMES["usa"])

    if api_key:
        prompt = (
            f"Generate a military wargame campaign story node in JSON format for nation '{nation_slug}', Act {act}, "
            f"scenario '{scenario_slug}', branch type '{branch_type}'. "
            f"Must output strictly valid JSON with keys: 'chapter_title', 'situation_briefing', 'chyron_headline', 'news_flash_body', 'action_video_tag' (one of video_atk, video_def, video_win, video_loss)."
        )
        try:
            raw = call_gemini_api(prompt, api_key)
            cleaned = raw.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            parsed = json.loads(cleaned.strip())
            return parsed
        except Exception as exc:
            print(f"[WARN] Gemini online generation failed ({exc}), falling back to procedural engine.")

    # Offline high-fidelity procedural generation
    import random
    callsign = random.choice(theme["callsigns"])
    keyword1 = random.choice(theme["keywords"])
    keyword2 = random.choice(theme["keywords"])
    anchor = random.choice(theme["anchors"])

    if branch_type == "OFFENSIVE":
        title = f"Act {act}: Forward Thrust - Operation {keyword1.split()[0]} Dawn"
        briefing = f"OPORD 28-{nation_slug.upper()}-AI: {callsign} reports enemy spearhead faltering. Deploy {keyword1} and {keyword2} to breach remaining fortified defense sectors."
        chyron = f"BREAKING: {nation_slug.upper()} ALLIED FORCES INITIATE DECISIVE OFFENSIVE ALONG FRONT"
        news = f"Live report from {anchor}: Frontline reconnaissance confirms major tactical breakthrough as autonomous precision strikes shatter opposing defensive lines."
        video_tag = "video_atk"
    elif branch_type == "DEFENSIVE":
        title = f"Act {act}: Perimeter Defense - Operation {keyword1.split()[0]} Bastion"
        briefing = f"OPORD 28-{nation_slug.upper()}-AI: Heavy adversary saturation strikes detected. {callsign} must reinforce line with {keyword1} and hold bridgeheads at all costs."
        chyron = f"CRISIS REPORT: INTENSE COMBAT REPORTED; {nation_slug.upper()} FORCES HOLD FORTIFIED REDOUBTS"
        news = f"Dispatch via {anchor}: Massive artillery and drone duels rage across contested terrain as defenders repulse multiple mechanized assault waves."
        video_tag = "video_def"
    else:
        title = f"Act {act}: Emergency Scramble - Operation {keyword1.split()[0]} Retribution"
        briefing = f"OPORD 28-{nation_slug.upper()}-AI: Line breached in sector 4. {callsign} executing retrograde maneuver while {keyword2} launches emergency interdiction."
        chyron = f"ALERT: EMERGENCY WITHDRAWAL ORDERED TO SECONDARY FALLBACK POSITIONS"
        news = f"Flash bulletin from {anchor}: Coalition command orders urgent redeployment to mountain and river ramparts to stem unexpected enemy thrust."
        video_tag = "video_loss"

    return {
        "chapter_title": title,
        "situation_briefing": briefing,
        "chyron_headline": chyron,
        "news_flash_body": news,
        "action_video_tag": video_tag
    }


def inject_node_into_db(node_dict: dict, from_node_slug: str = "", outcome_condition: str = "OUTCOME_DECISIVE_VICTORY") -> None:
    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()

    cur.execute(
        """INSERT OR REPLACE INTO campaign_story_nodes (
               slug, nation_slug, act_number, chapter_title, scenario_slug,
               situation_briefing, chyron_headline, news_flash_body,
               action_video_tag, is_terminal_climax, climax_type
           ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            node_dict["slug"],
            node_dict["nation_slug"],
            node_dict.get("act_number", 2),
            node_dict["chapter_title"],
            node_dict["scenario_slug"],
            node_dict["situation_briefing"],
            node_dict["chyron_headline"],
            node_dict["news_flash_body"],
            node_dict["action_video_tag"],
            node_dict.get("is_terminal_climax", 0),
            node_dict.get("climax_type", ""),
        ),
    )

    if from_node_slug:
        cur.execute(
            """INSERT OR REPLACE INTO campaign_story_edges (
                   from_node_slug, to_node_slug, condition_outcome,
                   transition_narrative, defcon_escalation, unlocked_tech_slug
               ) VALUES (?, ?, ?, ?, ?, ?)""",
            (
                from_node_slug,
                node_dict["slug"],
                outcome_condition,
                node_dict.get("transition_narrative", "AI Generated dynamic tactical transition."),
                node_dict.get("defcon_escalation", 0),
                node_dict.get("unlocked_tech_slug", ""),
            ),
        )

    conn.commit()

    # Mirror to JSON cache
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
    print(f"[AI GENERATOR] Successfully injected node '{node_dict['slug']}' into wargame.db and JSON cache.")


def main():
    parser = argparse.ArgumentParser(description="Generate branching story nodes for VR wargame.")
    parser.add_argument("--nation", default="usa", choices=["usa", "taiwan", "poland", "ukraine", "south_korea"])
    parser.add_argument("--act", type=int, default=2)
    parser.add_argument("--scenario", default="op_global_escalation_chronicle_2028")
    parser.add_argument("--branch", default="OFFENSIVE", choices=["OFFENSIVE", "DEFENSIVE", "CRISIS"])
    parser.add_argument("--node-slug", default="")
    parser.add_argument("--from-node", default="")
    parser.add_argument("--outcome", default="OUTCOME_DECISIVE_VICTORY")
    parser.add_argument("--inject", action="store_true", help="Write directly to DB and JSON cache")

    args = parser.parse_args()

    slug = args.node_slug or f"{args.nation}_ai_gen_act{args.act}_{args.branch.lower()}"
    story_data = generate_story_node_data(args.nation, args.act, args.scenario, args.branch)
    story_data["slug"] = slug
    story_data["nation_slug"] = args.nation
    story_data["act_number"] = args.act
    story_data["scenario_slug"] = args.scenario

    print("\n=== AI GENERATED STORY NODE ===")
    print(json.dumps(story_data, indent=2))

    if args.inject:
        inject_node_into_db(story_data, args.from_node, args.outcome)


if __name__ == "__main__":
    main()

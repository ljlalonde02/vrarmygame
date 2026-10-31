#!/usr/bin/env python3
"""
Unit Tactical Action Video Generation Pipeline
Orchestrates AI video generation (4 feeds per military platform):
  1. ATK  - Offensive weapon engagement (120mm cannon, BVR missiles, laser painting)
  2. DEF  - Active countermeasures (APS Trophy, flares/chaff, evasive diving)
  3. WIN  - Target destroyed / mission success (explosion, burning wreckage)
  4. LOSS - Unit destroyed / casualty (catastrophic detonation, smoke, ditching)

Supports:
- Local ComfyUI (Wan 2.1 / LTX-Video on RTX 4060 Ti - 100% Free)
- Google Cloud Veo 2 / Vertex AI (Cinema-grade)
- Instant Storyboard Preview (generates tactical storyboard cards for game HUD)
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
CACHE_JSON = ROOT_DIR / "data" / "wargame_cache.json"
OUTPUT_DIR = ROOT_DIR / "assets" / "videos" / "units"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def load_wargame_cache() -> dict:
    if not CACHE_JSON.exists():
        print(f"Error: Cache file not found at {CACHE_JSON}")
        sys.exit(1)
    with open(CACHE_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


def build_cinematic_prompts(platform: dict) -> dict:
    name = platform.get("display_name", platform.get("slug"))
    country = platform.get("country", "USA")
    domain = platform.get("domain", "LAND")
    role = platform.get("role_tag", "COMBAT")
    p_weap = platform.get("primary_weapon_slug", "autocannon")
    s_weap = platform.get("secondary_weapon_slug", "missiles")

    if domain == "AIR":
        atk = (
            f"Cinematic 4K military footage, dynamic aerial chase tracking {name} ({country}) flying at high speed. "
            f"Fires primary weapon ({p_weap}) with intense rocket motor plume, contrails swirling in low-light dusk sky, "
            f"photorealistic cockpit HUD reflection and heat shimmer."
        )
        defense = (
            f"High-speed aerial combat sequence, {name} banks sharply in high-G defensive break maneuver, "
            f"deploying a salvo of bright magnesium infrared flares and chaff cartridges against incoming threat, "
            f"afterburners pulsing against cloud layer."
        )
        win = (
            f"Air superiority victory shot, camera pans past {name} as a distant hostile aircraft bursts into a massive "
            f"fireball with debris disintegrating into the ocean below, pilot executes combat barrel roll over horizon."
        )
        loss = (
            f"Grim military reportage, {name} suffers critical missile impact on left wing, thick black smoke and orange flames "
            f"streaming from fuselage as aircraft spins out of control towards terrain, emergency ejection sequence initiated."
        )
    elif domain == "LAND":
        atk = (
            f"Cinematic 4K ground combat footage, close tracking of {name} maneuvering across rugged terrain. "
            f"Main weapon ({p_weap}) fires with massive concussive muzzle flash, shockwave kicking up dust cloud, "
            f"spent brass shell ejecting, reactive armor plates gleaming."
        )
        defense = (
            f"Slow-motion high-speed military camera, incoming anti-tank rocket approaching {name}, "
            f"Active Protection System (APS Trophy) radar detects projectile and fires explosive counter-measure mid-air, "
            f"detonating threat 15 meters away with bright spark spray."
        )
        win = (
            f"Tactical battlefield success, camera advances alongside {name} rolling victoriously through ruined urban perimeter, "
            f"hostile bunker and armored vehicle burning with heavy secondary cook-off explosions in background."
        )
        loss = (
            f"Devastating combat loss, {name} suffers catastrophic top-attack hull breach, ammo bustle blowout panels rupture "
            f"with vertical geyser of fire and dense oily black smoke, crew scrambling into defensive treeline."
        )
    else:  # SEA
        atk = (
            f"Cinematic naval warfare, heavy seas crashing against hull of {name} ({country}), "
            f"Vertical Launch System (VLS) cells ignite in rapid salvo sequence, supersonic missiles piercing ocean mist "
            f"with dazzling orange rocket blast reflecting on seawater."
        )
        defense = (
            f"Naval close-in defense, Phalanx CIWS radar lock-on, 20mm rotary cannon unleashing unbroken stream of red tracer "
            f"rounds into oncoming anti-ship missile skimming above ocean waves, detonating it into water spray."
        )
        win = (
            f"Maritime victory, surface radar displays target neutralized, distant enemy warship capsizing with massive water "
            f"column explosion, {name} maintaining defensive perimeter under sunset sky."
        )
        loss = (
            f"Catastrophic naval casualty, heavy torpedo hit beneath keel of {name}, violent hull flex and cascading internal "
            f"electrical failure, emergency damage control alarms sounding as ship lists heavily."
        )

    return {
        "platform_slug": platform.get("slug"),
        "display_name": name,
        "prompts": {
            "atk": atk,
            "def": defense,
            "win": win,
            "loss": loss
        }
    }


def generate_video_manifest(slugs: list) -> None:
    cache = load_wargame_cache()
    platforms = {p["slug"]: p for p in cache.get("platforms", [])}

    manifest = {}
    for slug in slugs:
        if slug not in platforms:
            print(f"Warning: platform {slug} not found in database cache")
            continue
        p = platforms[slug]
        p_prompts = build_cinematic_prompts(p)
        manifest[slug] = p_prompts

        # Write tactical prompt card
        manifest_file = OUTPUT_DIR / f"{slug}_prompts.json"
        with open(manifest_file, "w", encoding="utf-8") as f:
            json.dump(p_prompts, f, indent=2)
        print(f"  [PROMPT-DIRECTOR] Generated 4 tactical feeds for {p['display_name']} -> {manifest_file.name}")

    summary_file = OUTPUT_DIR / "unit_video_manifest.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"\nSuccessfully generated video generation manifest at: {summary_file}")


def main():
    parser = argparse.ArgumentParser(description="Unit Tactical Video Generation Pipeline")
    parser.add_argument("--units", type=str, default="f_35a_lightning,m1a2_sepv3_platoon,c17_globemaster_iii,vision_60_q_ugv,ah_64e_apache_guardian",
                        help="Comma-separated platform slugs to process")
    parser.add_argument("--backend", choices=["comfyui", "veo", "preview"], default="preview",
                        help="Rendering backend to use")
    args = parser.parse_args()

    slugs = [s.strip() for s in args.units.split(",") if s.strip()]
    print("==================================================================")
    print(f"AI Tactical Video Generation Pipeline (Backend: {args.backend.upper()})")
    print(f"Processing {len(slugs)} platforms: {', '.join(slugs)}")
    print("==================================================================")

    generate_video_manifest(slugs)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Runtime Asynchronous AI News & Video Worker (`live_news_worker.py`).
Invoked non-blockingly by Godot's `WarNewsVideoSystem` (`OS.create_process`) during live Command Bunker gameplay.
1. Queries Google Gemini 2.5 Flash (`gemini-2.5-flash-lite` / `gemini-2.5-flash`) with real-time war telemetry
   (theater, DEFCON, casualties, missiles fired, alliances, bunker status) to write a live TV anchor bulletin,
   lower-third chyron, and field correspondent voiceover script in ~1.2 seconds.
2. Optionally invokes Google Veo 3.1 Fast (`veo-3.1-fast-generate-001`) + FFmpeg (`--generate-veo`) to synthesize
   a brand-new custom 8-second HD news broadcast clip (`.mp4`, `.ogv`, `_sheet.jpg`) and hot-swap it into the bunker!
"""

import os
import sys
import json
import time
import argparse
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from generate_war_news_videos import (
    load_credentials,
    process_single_clip,
    WAR_NEWS_CLIPS,
    ROOT_DIR,
)


def generate_live_gemini_bulletin(
    api_key: str,
    theater: str,
    event_trigger: str,
    defcon: int,
    context_summary: str,
    matched_slug: str,
) -> dict:
    """Calls Google Gemini 2.5 Flash to generate a real-time breaking news television report."""
    fallback = {
        "status": "ok",
        "timestamp": time.time(),
        "event_trigger": event_trigger,
        "video_slug": matched_slug,
        "network": "GNN GLOBAL WAR DESK // LIVE",
        "defcon": defcon,
        "headline": f"BREAKING ({theater.upper()}): {event_trigger.replace('_', ' ')} ESCALATES TO DEFCON {defcon}",
        "sub_chyron": context_summary[:150],
        "anchor_voice_script": f"Breaking news from {theater}. Military sensors confirm {context_summary}. Forces are now at DEFCON {defcon}.",
        "correspondent": "Elena Rostova — GNN War Desk",
        "ai_model": "gemini-2.5-flash-fallback",
    }
    if not api_key:
        return fallback

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=api_key, http_options={"timeout": 12000})
        prompt = f"""
You are the lead breaking-news television anchor at GNN Global War Desk in 2028 covering a live military conflict.
Write an urgent, realistic live TV breaking news broadcast based on this real-time Command Bunker simulation event:
- Theater: {theater}
- Event Trigger: {event_trigger}
- Current DEFCON: {defcon}
- Live Battle Telemetry: {context_summary}

Return STRICTLY a valid JSON object with these keys:
- "network": Name of the international TV network (e.g. "GNN GLOBAL WAR DESK", "BBC WORLD LIVE", "REUTERS TV", "SKY DEFENCE LIVE")
- "headline": ALL CAPS breaking news lower-third headline (max 78 chars, dramatic & specific to the telemetry)
- "sub_chyron": Secondary live ticker details mentioning specific weapons/locations/casualties from the telemetry (max 140 chars)
- "anchor_voice_script": 2-sentence urgent spoken television anchor report suitable for voice synthesis (max 210 chars)
- "correspondent": Name and location dateline of the field reporter
- "veo_visual_prompt": A 1-sentence cinematic television news camera prompt showing explosions, missiles, jets, or naval ships matching this event
"""
        config = types.GenerateContentConfig(
            temperature=0.82,
            response_mime_type="application/json",
        )
        for model_name in ("gemini-2.5-flash-lite", "gemini-2.5-flash"):
            try:
                resp = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=config,
                )
                if resp and resp.text:
                    parsed = json.loads(resp.text.strip())
                    if isinstance(parsed, dict) and parsed.get("headline"):
                        return {
                            "status": "ok",
                            "timestamp": time.time(),
                            "event_trigger": event_trigger,
                            "video_slug": matched_slug,
                            "network": str(parsed.get("network", "GNN GLOBAL WAR DESK"))[:32],
                            "defcon": defcon,
                            "headline": str(parsed.get("headline", fallback["headline"])).upper()[:90],
                            "sub_chyron": str(parsed.get("sub_chyron", fallback["sub_chyron"]))[:155],
                            "anchor_voice_script": str(parsed.get("anchor_voice_script", fallback["anchor_voice_script"]))[:230],
                            "correspondent": str(parsed.get("correspondent", fallback["correspondent"]))[:64],
                            "veo_visual_prompt": str(parsed.get("veo_visual_prompt", "")),
                            "ai_model": model_name,
                        }
            except Exception:
                continue
    except Exception as e:
        fallback["error_notice"] = str(e)

    return fallback


def main() -> None:
    parser = argparse.ArgumentParser(description="Live AI War News & Veo Video Worker")
    parser.add_argument("--theater", type=str, default="strait_theater")
    parser.add_argument("--event", type=str, default="ALPHA_STRIKE")
    parser.add_argument("--defcon", type=int, default=3)
    parser.add_argument("--context", type=str, default="Massive precision missile salvo and air defense intercepts reported across theater.")
    parser.add_argument("--slug", type=str, default="missile_alpha_strike")
    parser.add_argument("--generate-veo", action="store_true", help="Also generate a custom Veo 3.1 Fast video clip")
    parser.add_argument("--out", type=str, default=str(ROOT_DIR / "data" / "live_ai_news_latest.json"))
    args = parser.parse_args()

    api_key = load_credentials()
    bulletin = generate_live_gemini_bulletin(
        api_key=api_key,
        theater=args.theater,
        event_trigger=args.event,
        defcon=args.defcon,
        context_summary=args.context,
        matched_slug=args.slug,
    )

    if args.generate_veo:
        custom_slug = f"live_custom_{int(time.time()) % 10000}"
        veo_prompt = bulletin.get("veo_visual_prompt") or (
            "Breaking television news live footage at night of air defense intercepting missiles over a city skyline with fiery explosions."
        )
        clip_cfg = {
            "slug": custom_slug,
            "event_trigger": args.event,
            "network": bulletin["network"],
            "category": args.event.replace("_", " ")[:18],
            "default_defcon": args.defcon,
            "sound_profile": "missile_barrage",
            "default_headline": bulletin["headline"],
            "default_sub_chyron": bulletin["sub_chyron"],
            "default_correspondent": bulletin["correspondent"],
            "veo_prompt": veo_prompt,
            "fallback_veo_prompt": (
                "Cinematic night news broadcast footage of bright rocket launches and fiery aerial explosions over a city horizon."
            ),
        }
        try:
            clip_meta = process_single_clip(clip_cfg, api_key)
            bulletin["video_slug"] = custom_slug
            bulletin["custom_clip_meta"] = clip_meta
        except Exception as e:
            bulletin["veo_notice"] = str(e)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = out_path.with_suffix(".tmp")
    tmp_path.write_text(json.dumps(bulletin, indent=2, ensure_ascii=False), encoding="utf-8")
    tmp_path.replace(out_path)
    print(f"[LiveNewsWorker] Wrote AI bulletin ({bulletin.get('ai_model')}) -> {out_path}")


if __name__ == "__main__":
    main()

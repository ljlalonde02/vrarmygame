#!/usr/bin/env python3
"""
Wikipedia REST API Scraper & SQLite Database Seeder for VR/PC Holographic Wargame Simulator.
Fetches real Wikipedia summaries and Wikimedia Commons photographs for 2025-2030 platforms,
quadruped robot dogs, FPV/loitering drones, Loyal Wingman CCAs, Directed Energy lasers/HPM,
and modern munitions, and builds `data/wargame.db` + `data/wargame_cache.json`.
"""

import json
import os
import sqlite3
import struct
import time
import urllib.parse
import urllib.request
import zlib
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT_DIR / "data"
DB_PATH = DATA_DIR / "wargame.db"
CACHE_JSON_PATH = DATA_DIR / "wargame_cache.json"
IMG_PLATFORMS_DIR = ROOT_DIR / "assets" / "wiki_images" / "platforms"
IMG_WEAPONS_DIR = ROOT_DIR / "assets" / "wiki_images" / "weapons"

USER_AGENT = "VRArmyGameWikiPipeline/1.0 (https://github.com/vrarmygame; tactical-sim-educator)"


def create_fallback_png(filepath: Path, r: int, g: int, b: int, width: int = 256, height: int = 160) -> None:
    """Generates a valid high-contrast tactical recon card PNG if offline or Wikipedia has no thumbnail."""
    filepath.parent.mkdir(parents=True, exist_ok=True)
    raw_rows = bytearray()
    for y in range(height):
        raw_rows.append(0)  # Filter type 0
        border = y < 3 or y >= height - 3
        scanline = (y % 6 == 0)
        for x in range(width):
            edge = border or x < 3 or x >= width - 3
            crosshair = (abs(x - width // 2) < 20 and abs(y - height // 2) <= 1) or (
                abs(y - height // 2) < 20 and abs(x - width // 2) <= 1
            )
            if edge or crosshair:
                raw_rows.extend((min(255, r + 90), min(255, g + 90), min(255, b + 90), 255))
            elif scanline:
                raw_rows.extend((max(0, r // 3), max(0, g // 3), max(0, b // 3), 255))
            else:
                raw_rows.extend((max(0, r // 5), max(0, g // 5), max(0, b // 5), 255))

    def make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    compressed = zlib.compress(bytes(raw_rows), 6)
    png_bytes = (
        b"\x89PNG\r\n\x1a\n"
        + make_chunk(b"IHDR", ihdr)
        + make_chunk(b"IDAT", compressed)
        + make_chunk(b"IEND", b"")
    )
    filepath.write_bytes(png_bytes)


_EXISTING_CACHE = {}
if CACHE_JSON_PATH.exists():
    try:
        _old = json.loads(CACHE_JSON_PATH.read_text(encoding="utf-8"))
        for _tbl in ("platforms", "weapons"):
            for _row in _old.get(_tbl, []):
                _EXISTING_CACHE[_row["slug"]] = _row
    except Exception:
        pass


def _detect_ext_from_bytes(data: bytes) -> str:
    if data.startswith(b"\x89PNG"):
        return ".png"
    if data.startswith(b"RIFF") and b"WEBP" in data[:16]:
        return ".webp"
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    return ""


def fetch_wikipedia_metadata_and_photo(wiki_title: str, slug: str, target_dir: Path, fallback_rgb=(20, 140, 160)) -> dict:
    """Queries Wikipedia REST API v1 for summary text and downloads the real thumbnail image."""
    target_dir.mkdir(parents=True, exist_ok=True)
    cached = _EXISTING_CACHE.get(slug)
    if cached:
        for cand_ext in (".jpg", ".png", ".webp"):
            cand_path = target_dir / f"{slug}{cand_ext}"
            if cand_path.exists() and cand_path.stat().st_size > 1024:
                raw = cand_path.read_bytes()
                true_ext = _detect_ext_from_bytes(raw)
                if not true_ext:
                    cand_path.unlink()
                    imp_file = Path(str(cand_path) + ".import")
                    if imp_file.exists():
                        imp_file.unlink()
                    continue
                if true_ext != cand_ext:
                    fixed_path = target_dir / f"{slug}{true_ext}"
                    fixed_path.write_bytes(raw)
                    cand_path.unlink()
                    imp_file = Path(str(cand_path) + ".import")
                    if imp_file.exists():
                        imp_file.unlink()
                    cand_path = fixed_path
                if cached.get("wiki_summary"):
                    return {
                        "wiki_url": cached.get("wiki_url", ""),
                        "wiki_summary": cached.get("wiki_summary", ""),
                        "image_res_path": "res://" + cand_path.relative_to(ROOT_DIR).as_posix(),
                        "downloaded_real_photo": True,
                    }
    encoded_title = urllib.parse.quote(wiki_title.replace(" ", "_"))
    api_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{encoded_title}"

    summary_text = ""
    wiki_url = f"https://en.wikipedia.org/wiki/{encoded_title}"
    img_filename = f"{slug}.jpg"
    img_disk_path = target_dir / img_filename
    downloaded_ok = False

    try:
        req = urllib.request.Request(api_url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            summary_text = data.get("extract", "")
            content_urls = data.get("content_urls", {}).get("desktop", {})
            if content_urls.get("page"):
                wiki_url = content_urls["page"]

            thumb_url = data.get("thumbnail", {}).get("source")
            if thumb_url:
                img_req = urllib.request.Request(thumb_url, headers={"User-Agent": USER_AGENT})
                with urllib.request.urlopen(img_req, timeout=8) as img_resp:
                    img_bytes = img_resp.read()
                    true_ext = _detect_ext_from_bytes(img_bytes)
                    if len(img_bytes) > 512 and true_ext:
                        img_filename = f"{slug}{true_ext}"
                        img_disk_path = target_dir / img_filename
                        img_disk_path.write_bytes(img_bytes)
                        downloaded_ok = True
    except Exception as exc:
        print(f"  [WARN] Wikipedia fetch fallback for {wiki_title}: {exc}")

    if not downloaded_ok:
        # Fallback: MediaWiki Search + PageImages API to find closest page with a real photo
        try:
            search_q = urllib.parse.quote(wiki_title)
            mw_url = (
                f"https://en.wikipedia.org/w/api.php?action=query&generator=search"
                f"&gsrsearch={search_q}&gsrlimit=5&prop=pageimages|extracts&exintro=1&explaintext=1"
                f"&pithumbsize=512&format=json"
            )
            req2 = urllib.request.Request(mw_url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req2, timeout=8) as resp2:
                mw_data = json.loads(resp2.read().decode("utf-8"))
                pages = mw_data.get("query", {}).get("pages", {})
                for _, pinfo in pages.items():
                    if not summary_text and pinfo.get("extract"):
                        summary_text = pinfo["extract"]
                    t_src = pinfo.get("thumbnail", {}).get("source")
                    if t_src:
                        img_req = urllib.request.Request(t_src, headers={"User-Agent": USER_AGENT})
                        with urllib.request.urlopen(img_req, timeout=8) as img_resp:
                            img_bytes = img_resp.read()
                            true_ext = _detect_ext_from_bytes(img_bytes)
                            if len(img_bytes) > 512 and true_ext:
                                img_filename = f"{slug}{true_ext}"
                                img_disk_path = target_dir / img_filename
                                img_disk_path.write_bytes(img_bytes)
                                downloaded_ok = True
                                break
        except Exception as exc2:
            print(f"  [WARN] MediaWiki image search fallback for {wiki_title}: {exc2}")

    if not downloaded_ok and not img_disk_path.exists():
        img_filename = f"{slug}.png"
        img_disk_path = target_dir / img_filename
        create_fallback_png(img_disk_path, *fallback_rgb)

    rel_res_path = "res://" + img_disk_path.relative_to(ROOT_DIR).as_posix()
    return {
        "wiki_url": wiki_url,
        "wiki_summary": summary_text[:600] if summary_text else f"Modern tactical system ({wiki_title}).",
        "image_res_path": rel_res_path,
        "downloaded_real_photo": downloaded_ok,
    }


SENSORS_SEED = [
    ("an_apg_81_aesa", "AN/APG-81 AESA Radar", "ACTIVE_RADAR", 185.0, 0.0, 1, 1),
    ("an_apg_83_sabr", "AN/APG-83 SABR AESA", "ACTIVE_RADAR", 145.0, 0.0, 1, 1),
    ("an_apy_2_awacs", "AN/APY-2 Airborne Warning Radar", "ACTIVE_RADAR", 420.0, 0.0, 1, 1),
    ("an_mpq_65_patriot", "AN/MPQ-65 Patriot Phased Array", "ACTIVE_RADAR", 170.0, 30.0, 1, 1),
    ("91n6e_big_bird", "91N6E Big Bird S-400 Radar", "ACTIVE_RADAR", 260.0, 25.0, 1, 1),
    ("type_346a_dragon_eye", "Type 346A Dragon Eye AESA", "ACTIVE_RADAR", 300.0, 15.0, 1, 1),
    ("an_spy_6_amdr", "AN/SPY-6(V)1 AMDR Radar", "ACTIVE_RADAR", 320.0, 10.0, 1, 1),
    ("an_asq_239_esm", "AN/ASQ-239 Barracuda Passive ESM/ELINT", "PASSIVE_ESM", 310.0, 0.0, 1, 0),
    ("pirate_irst_passive", "Long-Wave Infrared Search & Track (IRST)", "IR_EO", 65.0, 0.0, 1, 1),
    ("electro_optical_flir_hd", "HD Thermal/EO Laser Designator Pod", "IR_EO", 14.0, 0.0, 1, 1),
    ("micro_eo_dog_turret", "3D LiDAR & Thermal CV Gimbal", "LIDAR_CV", 5.5, 0.0, 1, 1),
    ("acoustic_cuas_array", "3D Acoustic & Seismic C-UAS Array", "ACOUSTIC_SONAR", 12.0, 0.0, 1, 1),
    ("towed_sonar_array", "AN/SQR-20 Multi-Function Towed Sonar", "ACOUSTIC_SONAR", 55.0, -500.0, 1, 1),
    ("ku_band_cuas_radar", "Ku-Band Micro-Doppler C-UAS Radar", "ACTIVE_RADAR", 22.0, 0.0, 1, 1),
]

# (slug, display_name, wiki_title, target_mask, guidance, max_km, ne_km, min_km, mach, profile, pk, dmg, interceptable, cost_musd)
# target_mask bits: 1=AIR, 2=LAND, 4=SEA, 8=RADAR_EMITTER, 16=MISSILE/DRONE
WEAPONS_SEED = [
    ("aim_120d", "AIM-120D AMRAAM", "AIM-120 AMRAAM", 1 | 16, "ACTIVE_RADAR", 160.0, 65.0, 2.0, 4.0, "LOFTED_BALLISTIC", 0.80, 100.0, 0, 1.09),
    ("mbda_meteor", "MBDA Meteor Ramjet BVR AAM", "Meteor (missile)", 1 | 16, "ACTIVE_RADAR", 200.0, 100.0, 3.0, 4.5, "LOFTED_BALLISTIC", 0.88, 110.0, 0, 2.10),
    ("pl_15_aam", "PL-15 Dual-Pulse BVR AAM", "PL-15", 1 | 16, "ACTIVE_RADAR", 180.0, 70.0, 3.0, 4.5, "LOFTED_BALLISTIC", 0.78, 100.0, 0, 1.20),
    ("agm_88g_aargm_er", "AGM-88G AARGM-ER Anti-Radiation", "AGM-88 HARM", 2 | 8, "ANTI_RADIATION", 130.0, 80.0, 4.0, 3.2, "LOFTED_BALLISTIC", 0.82, 140.0, 1, 1.80),
    ("agm_158_jassm", "AGM-158B JASSM-ER Stealth Cruise", "AGM-158 JASSM", 2 | 4, "GPS_INS", 280.0, 250.0, 15.0, 0.85, "SEA_SKIM_TERCOM", 0.85, 220.0, 1, 1.50),
    ("brahmos_supersonic", "BrahMos PJ-10 Mach 3 Supersonic Cruise", "BrahMos", 2 | 4, "ACTIVE_RADAR", 350.0, 310.0, 10.0, 3.0, "SEA_SKIM_TERCOM", 0.89, 300.0, 1, 2.75),
    ("hyunmoo_5_bunker", "Hyunmoo-5 8-Ton Monster Bunker Buster", "Hyunmoo", 2, "GPS_INS", 300.0, 290.0, 20.0, 6.5, "LOFTED_BALLISTIC", 0.94, 550.0, 0, 8.50),
    ("kn_25_600mm_mlrs", "KN-25 600mm Super-Large Guided MLRS", "KN-25", 2, "GPS_INS", 340.0, 310.0, 15.0, 4.2, "LOFTED_BALLISTIC", 0.74, 240.0, 1, 0.85),
    ("lrhw_dark_eagle", "LRHW Dark Eagle Hypersonic Glide", "Long-Range Hypersonic Weapon", 2 | 4, "GPS_INS", 480.0, 450.0, 40.0, 17.0, "LOFTED_BALLISTIC", 0.92, 450.0, 0, 41.00),
    ("3m22_zircon", "3M22 Zircon Scramjet Hypersonic", "3M22 Zircon", 2 | 4, "ACTIVE_RADAR", 420.0, 380.0, 25.0, 8.5, "LOFTED_BALLISTIC", 0.90, 380.0, 0, 12.00),
    ("kh_47m2_kinzhal", "Kh-47M2 Kinzhal Air-Launched Ballistic", "Kh-47M2 Kinzhal", 2 | 4, "GPS_INS", 380.0, 350.0, 30.0, 10.0, "LOFTED_BALLISTIC", 0.86, 340.0, 0, 10.00),
    ("pac_3_mse", "MIM-104F Patriot PAC-3 MSE", "MIM-104 Patriot", 1 | 16, "ACTIVE_RADAR", 120.0, 65.0, 3.0, 4.1, "LOFTED_BALLISTIC", 0.84, 120.0, 0, 4.00),
    ("sm_6_eram", "RIM-174 Standard ERAM (SM-6)", "RIM-174 Standard ERAM", 1 | 4 | 16, "ACTIVE_RADAR", 240.0, 100.0, 5.0, 3.5, "LOFTED_BALLISTIC", 0.85, 130.0, 0, 4.30),
    ("48n6e3_s400", "48N6E3 S-400 Long-Range SAM", "S-400 missile system", 1 | 16, "SEMI_ACTIVE", 200.0, 90.0, 5.0, 6.0, "LOFTED_BALLISTIC", 0.78, 135.0, 0, 1.50),
    ("adm_160_mald", "ADM-160C MALD-J Radar Decoy", "ADM-160 MALD", 1 | 8, "DECOY", 220.0, 200.0, 5.0, 0.80, "DIRECT", 0.0, 0.0, 1, 0.32),
    ("switchblade_600_round", "AeroVironment Switchblade 600 Loitering", "AeroVironment Switchblade", 2 | 8, "IR", 40.0, 35.0, 0.5, 0.16, "DIRECT", 0.82, 110.0, 1, 0.08),
    ("lancet_3_round", "ZALA Lancet-3 AI Loitering Munition", "ZALA Lancet", 2 | 8, "IR", 45.0, 40.0, 0.5, 0.25, "DIRECT", 0.80, 105.0, 1, 0.035),
    ("shahed_136_round", "HESA Shahed 136 OWA-UAV", "HESA Shahed 136", 2 | 8, "GPS_INS", 320.0, 300.0, 5.0, 0.17, "SEA_SKIM_TERCOM", 0.72, 130.0, 1, 0.025),
    ("iai_harop_round", "IAI Harop Anti-Radiation Drone", "IAI Harop", 2 | 8, "ANTI_RADIATION", 250.0, 220.0, 3.0, 0.32, "DIRECT", 0.85, 140.0, 1, 0.07),
    ("fpv_fiber_kamikaze", "Fiber-Optic Jam-Proof FPV Drone", "First-person view (radio control)", 2, "IR", 12.0, 11.0, 0.1, 0.13, "DIRECT", 0.84, 75.0, 1, 0.001),
    ("fgm_148_javelin", "FGM-148 Javelin Top-Attack ATGM", "FGM-148 Javelin", 2, "IR", 4.75, 4.5, 0.1, 0.6, "LOFTED_BALLISTIC", 0.90, 95.0, 0, 0.175),
    ("m829a4_apfsds", "120mm M829A4 APFSDS Depleted Uranium", "M829", 2, "DIRECT", 4.0, 3.5, 0.05, 4.9, "DIRECT", 0.85, 80.0, 0, 0.01),
    ("helws_100kw_laser", "Iron Beam 100kW High-Energy Laser Pulse", "Iron Beam", 1 | 16, "DIRECT", 10.0, 10.0, 0.1, 999.0, "DIRECT", 0.92, 60.0, 0, 0.000002),
    ("leonidas_hpm_burst", "Epirus Leonidas High-Power Microwave Cone", "Directed-energy weapon", 1 | 16, "DIRECT", 3.5, 3.5, 0.05, 999.0, "DIRECT", 0.95, 85.0, 0, 0.000001),
    ("ahead_35mm_burst", "Skynex 35mm AHEAD Programmable Burst", "Skyranger 35", 1 | 16, "DIRECT", 4.5, 4.0, 0.1, 3.1, "DIRECT", 0.88, 70.0, 0, 0.004),
    ("usv_500kg_warhead", "Naval Kamikaze USV 500kg Hull Charge", "MAGURA V5", 4, "IR", 180.0, 160.0, 0.1, 0.07, "SEA_SKIM_TERCOM", 0.85, 320.0, 1, 0.25),
    ("mk48_adcap_torpedo", "Mark 48 ADCAP Heavyweight Torpedo", "Mark 48 torpedo", 4, "ACTIVE_RADAR", 38.0, 30.0, 1.0, 0.09, "SEA_SKIM_TERCOM", 0.90, 360.0, 0, 3.80),
    ("r_360_neptune", "R-360 Neptune Anti-Ship & Land Cruise", "R-360 Neptune", 2 | 4, "ACTIVE_RADAR", 300.0, 270.0, 8.0, 0.85, "SEA_SKIM_TERCOM", 0.87, 290.0, 1, 1.45),
    ("vilkha_m_300mm", "Vilkha-M 300mm Precision Guided MLRS", "Vilkha", 2, "GPS_INS", 130.0, 115.0, 10.0, 3.4, "LOFTED_BALLISTIC", 0.84, 195.0, 1, 0.35),
    ("stugna_p_atgm", "Stugna-P (Skif) Laser-Guided Heavy ATGM", "Skif (anti-tank guided missile)", 2, "IR", 5.5, 5.0, 0.1, 0.65, "DIRECT", 0.88, 92.0, 0, 0.045),
    ("orbital_tungsten_rod", "Project Thor Mach-24 Orbital Kinetic Tungsten Rod", "Kinetic bombardment", 2 | 4 | 8, "GPS_INS", 2000.0, 1950.0, 0.0, 24.0, "ORBITAL_KINETIC_ROD", 0.98, 850.0, 0, 45.00),
]

# Platforms:
# (slug, name, wiki_title, country, year, domain, unit_class, nato_code, max_kts, cruise_kts, radius_km, max_alt_m, rcs, ir, armor, hp, elements, cost_musd,
#  autonomy, climb_steep, sub_slug, sub_cnt, de_kw, de_cone, sensor_slug, w1_slug, w1_qty, w2_slug, w2_qty)
PLATFORMS_SEED = [
    # --- MANNED AIRCRAFT ---
    ("f_35a_lightning", "F-35A Lightning II Flight", "Lockheed Martin F-35 Lightning II", "USA", 2026, "AIR", "FIGHTER", "AIR_FIGHTER_STEALTH",
     1060, 560, 1090, 15240, 0.0015, 0.4, 10.0, 100.0, 4, 320.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_81_aesa", "aim_120d", 16, "agm_158_jassm", 8),
    ("f_16cj_block70", "F-16V/CJ Wild Weasel Flight", "General Dynamics F-16 Fighting Falcon", "USA", 2025, "AIR", "SEAD", "AIR_SEAD",
     1150, 520, 620, 15240, 1.2, 1.0, 8.0, 90.0, 4, 140.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "agm_88g_aargm_er", 8, "adm_160_mald", 8),
    ("b_21_raider", "B-21 Raider Stealth Bomber Cell", "Northrop Grumman B-21 Raider", "USA", 2027, "AIR", "STRIKE", "AIR_BOMBER_STEALTH",
     560, 510, 4000, 15000, 0.0005, 0.25, 15.0, 160.0, 2, 1400.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_81_aesa", "agm_158_jassm", 24, "adm_160_mald", 8),
    ("e_3_sentry_awacs", "E-3G Sentry AWACS Orbit", "Boeing E-3 Sentry", "USA", 2025, "AIR", "AWACS", "AIR_AWACS",
     460, 400, 2500, 12500, 65.0, 1.8, 12.0, 140.0, 1, 380.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apy_2_awacs", "adm_160_mald", 4, "", 0),
    ("j_20_mighty_dragon", "Chengdu J-20A Mighty Dragon Flight", "Chengdu J-20", "CHN", 2026, "AIR", "FIGHTER", "AIR_FIGHTER_STEALTH",
     1120, 580, 1100, 18000, 0.015, 0.55, 10.0, 105.0, 4, 360.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_81_aesa", "pl_15_aam", 16, "agm_88g_aargm_er", 4),
    ("su_57_felon", "Sukhoi Su-57 Felon Strike Flight", "Sukhoi Su-57", "RUS", 2026, "AIR", "FIGHTER", "AIR_FIGHTER_STEALTH",
     1150, 560, 1050, 17500, 0.1, 0.7, 11.0, 105.0, 4, 240.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_81_aesa", "pl_15_aam", 16, "kh_47m2_kinzhal", 4),
    ("tu_22m3_backfire", "Tu-22M3M Backfire Missile Bomber Flight", "Tupolev Tu-22M", "RUS", 2025, "AIR", "STRIKE", "AIR_BOMBER",
     1050, 490, 2200, 13300, 25.0, 1.7, 15.0, 150.0, 2, 180.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "kh_47m2_kinzhal", 6, "3m22_zircon", 4),

    # --- LOYAL WINGMAN / CCA AI COMBAT DRONES ---
    ("xq_58a_valkyrie", "XQ-58A Valkyrie Loyal Wingman Swarm", "Kratos XQ-58 Valkyrie", "USA", 2027, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     565, 480, 1800, 13700, 0.005, 0.25, 5.0, 60.0, 4, 16.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "aim_120d", 8, "adm_160_mald", 8),
    ("mq_28_ghost_bat", "MQ-28 Ghost Bat AI Wingman Cell", "Boeing MQ-28 Ghost Bat", "USA", 2027, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     620, 500, 1900, 12500, 0.008, 0.3, 6.0, 65.0, 4, 44.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "aim_120d", 8, "switchblade_600_round", 8),
    ("s_70_okhotnik", "Sukhoi S-70 Okhotnik-B Stealth UCAV", "Sukhoi S-70 Okhotnik-B", "RUS", 2027, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     540, 470, 2000, 12000, 0.01, 0.35, 8.0, 75.0, 2, 36.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "pl_15_aam", 4, "lancet_3_round", 8),
    ("bayraktar_kizilelma", "Bayraktar Kizilelma Unmanned Fighter", "Baykar Bayraktar Kızılelma", "TUR", 2026, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     590, 450, 930, 11000, 0.02, 0.4, 6.0, 65.0, 4, 40.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "aim_120d", 8, "agm_88g_aargm_er", 4),

    # --- QUADRUPED ROBOT DOGS & ARMED UGVS ---
    ("vision_60_q_ugv", "Ghost Robotics Vision 60 Robot Dog Pack", "Ghost Robotics", "USA", 2026, "LAND", "ROBOT_DOG", "LAND_ROBOT_DOG",
     12, 8, 16, 4000, 0.0005, 0.05, 2.0, 35.0, 8, 1.2, "AUTONOMOUS_AI", 1, "", 0, 0.0, 0.0,
     "micro_eo_dog_turret", "fgm_148_javelin", 4, "fpv_fiber_kamikaze", 8),
    ("unitree_b2w_armed", "Armed Quadruped Robot Dog Assault Pack", "Quadruped robot", "CHN", 2026, "LAND", "ROBOT_DOG", "LAND_ROBOT_DOG",
     14, 9, 18, 4000, 0.0006, 0.06, 2.5, 38.0, 8, 0.6, "AUTONOMOUS_AI", 1, "", 0, 0.0, 0.0,
     "micro_eo_dog_turret", "fpv_fiber_kamikaze", 12, "fgm_148_javelin", 2),
    ("milrem_themis_ugv", "Milrem THeMIS Combat UGV Section", "THeMIS", "NATO", 2026, "LAND", "UGV", "LAND_UGV",
     25, 18, 45, 3500, 0.15, 0.25, 18.0, 65.0, 4, 2.4, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "fgm_148_javelin", 8, "switchblade_600_round", 6),
    ("uran_9_ugv", "Uran-9 Heavy Robotic Tank Section", "Uran-9", "RUS", 2025, "LAND", "UGV", "LAND_UGV",
     22, 16, 40, 3000, 0.4, 0.4, 30.0, 80.0, 4, 4.5, "RF_DATALINK", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "lancet_3_round", 8, "fgm_148_javelin", 6),

    # --- LOITERING MUNITIONS & FPV SWARM LAUNCHERS ---
    ("fpv_fiber_swarm", "Fiber-Optic FPV Hunter-Killer Swarm", "Unmanned aerial vehicle", "NATO", 2026, "LAND", "SWARM_TEAM", "LAND_FPV_SWARM",
     20, 15, 20, 3800, 0.01, 0.08, 1.0, 28.0, 12, 0.15, "FIBER_OPTIC", 1, "", 0, 0.0, 0.0,
     "micro_eo_dog_turret", "fpv_fiber_kamikaze", 24, "", 0),
    ("switchblade_600_team", "Switchblade 600 Loitering Swarm Battery", "AeroVironment Switchblade", "USA", 2026, "LAND", "SWARM_TEAM", "LAND_LOITER_SWARM",
     42, 32, 120, 3000, 0.2, 0.2, 6.0, 45.0, 6, 1.8, "RF_DATALINK", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "switchblade_600_round", 18, "", 0),
    ("lancet_3_team", "ZALA Lancet-3 AI Swarm Section", "ZALA Lancet", "RUS", 2026, "LAND", "SWARM_TEAM", "LAND_LOITER_SWARM",
     40, 30, 110, 3000, 0.2, 0.2, 5.0, 45.0, 6, 1.1, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "lancet_3_round", 20, "", 0),
    ("shahed_136_launcher", "Shahed-136 / Geran-2 Saturation Truck", "HESA Shahed 136", "RUS", 2025, "LAND", "SWARM_TEAM", "LAND_STRIKE_DRONE",
     38, 28, 200, 2500, 1.5, 0.5, 8.0, 55.0, 4, 0.9, "GPS_INS", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "shahed_136_round", 24, "", 0),
    ("iai_harop_launcher", "IAI Harop Anti-Radar Drone Battery", "IAI Harop", "USA", 2025, "LAND", "SWARM_TEAM", "LAND_SEAD_DRONE",
     40, 30, 180, 2800, 1.2, 0.4, 8.0, 55.0, 4, 2.5, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "iai_harop_round", 16, "", 0),

    # --- DIRECTED ENERGY (LASERS & HPM MICROWAVES) & SAMS ---
    ("iron_beam_helws", "Iron Beam 100kW High-Energy Laser Battery", "Iron Beam", "USA", 2026, "LAND", "CUAS_LASER", "LAND_LASER_DEFENSE",
     35, 25, 150, 2500, 2.0, 0.6, 15.0, 85.0, 2, 28.0, "MANNED", 0, "", 0, 100.0, 0.0,
     "ku_band_cuas_radar", "helws_100kw_laser", 999, "ahead_35mm_burst", 60),
    ("epirus_leonidas_hpm", "Epirus Leonidas HPM Microwave C-UAS Stryker", "Stryker", "USA", 2026, "LAND", "CUAS_HPM", "LAND_HPM_DEFENSE",
     52, 38, 220, 2800, 1.8, 0.5, 22.0, 90.0, 4, 18.0, "MANNED", 0, "", 0, 75.0, 30.0,
     "ku_band_cuas_radar", "leonidas_hpm_burst", 999, "fgm_148_javelin", 4),
    ("skynex_ahead_battery", "Rheinmetall Skynex 35mm C-UAS Battery", "Skyranger 35", "NATO", 2026, "LAND", "CUAS_GUN", "LAND_SPAAG",
     45, 32, 180, 2500, 2.2, 0.5, 20.0, 85.0, 4, 22.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "ku_band_cuas_radar", "ahead_35mm_burst", 120, "", 0),
    ("mim_104f_patriot", "MIM-104F Patriot PAC-3 SAM Battery", "MIM-104 Patriot", "USA", 2025, "LAND", "SAM", "LAND_SAM_HEAVY",
     30, 20, 150, 2000, 6.0, 0.9, 12.0, 110.0, 4, 420.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_mpq_65_patriot", "pac_3_mse", 32, "", 0),
    ("s_400_triumf", "S-400 Triumf Strategic SAM Battalion", "S-400 missile system", "RUS", 2025, "LAND", "SAM", "LAND_SAM_HEAVY",
     30, 20, 150, 2000, 7.5, 1.0, 12.0, 120.0, 4, 310.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "91n6e_big_bird", "48n6e3_s400", 32, "", 0),
    ("krasukha_4_ew", "1RL257 Krasukha-4 Electronic Warfare Station", "Krasukha (electronic warfare system)", "RUS", 2025, "LAND", "EW_JAMMER", "LAND_EW",
     35, 25, 180, 2200, 4.0, 0.7, 10.0, 75.0, 2, 25.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_asq_239_esm", "", 0, "", 0),

    # --- GROUND ARMOR, HYPERSONIC BATTERIES & ROBOT-DOG CARRIERS ---
    ("m1a2_sepv3_platoon", "M1A2 SEPv3 Abrams Tank Platoon", "M1 Abrams", "USA", 2025, "LAND", "ARMOR", "LAND_ARMOR",
     38, 28, 200, 2500, 3.5, 1.2, 85.0, 160.0, 4, 44.0, "MANNED", 0, "vision_60_q_ugv", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 40, "fgm_148_javelin", 4),
    ("m2a4_mech_company", "M2A4 Bradley Mechanized Infantry (with Robot Dogs)", "M2 Bradley", "USA", 2026, "LAND", "MECH_INF", "LAND_MECH_INF",
     36, 26, 210, 2800, 2.8, 0.9, 55.0, 130.0, 4, 24.0, "MANNED", 0, "vision_60_q_ugv", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "fgm_148_javelin", 12, "fpv_fiber_kamikaze", 12),
    ("specops_mountain_team", "Special Forces Mountain Recon (Robot Dogs + FPVs)", "United States Army Special Forces", "USA", 2026, "LAND", "INFANTRY", "LAND_SPECOPS",
     15, 10, 80, 4000, 0.02, 0.1, 8.0, 60.0, 6, 4.0, "MANNED", 1, "fpv_fiber_swarm", 2, 0.0, 0.0,
     "acoustic_cuas_array", "fgm_148_javelin", 6, "switchblade_600_round", 6),
    ("tier1_sniper_recon_team", "Tier-1 Sniper & JTAC Laser Recon Team (.50 BMG M107)", "Barrett M82", "USA", 2026, "LAND", "INFANTRY", "LAND_SNIPER",
     18, 12, 95, 4500, 0.002, 0.04, 6.0, 55.0, 4, 3.2, "MANNED", 1, "fpv_fiber_swarm", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "fgm_148_javelin", 8, "switchblade_600_round", 6),
    ("navy_seal_commando_squad", "Tier-1 SEAL / SAS Commando Sabotage Squad", "United States Navy SEALs", "USA", 2026, "LAND", "INFANTRY", "LAND_COMMANDO",
     20, 14, 110, 4000, 0.004, 0.06, 10.0, 72.0, 8, 4.8, "MANNED", 1, "vision_60_q_ugv", 2, 0.0, 0.0,
     "acoustic_cuas_array", "fgm_148_javelin", 8, "fpv_fiber_kamikaze", 10),
    ("spetsnaz_sniper_commando", "OPFOR Spetsnaz Sniper & Commando Sabotage Team", "Spetsnaz", "RUS", 2026, "LAND", "INFANTRY", "LAND_COMMANDO",
     19, 13, 100, 4200, 0.005, 0.07, 9.0, 68.0, 6, 3.5, "MANNED", 1, "lancet_3_team", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "stugna_p_atgm", 8, "fpv_fiber_kamikaze", 8),
    ("t_90m_platoon", "T-90M Proryv-3 Tank Platoon (with Robot Dogs)", "T-90", "RUS", 2025, "LAND", "ARMOR", "LAND_ARMOR",
     35, 25, 190, 2500, 3.2, 1.1, 78.0, 145.0, 4, 18.0, "MANNED", 0, "unitree_b2w_armed", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 36, "lancet_3_round", 6),
    ("dark_eagle_battery", "LRHW Dark Eagle Hypersonic Battery", "Long-Range Hypersonic Weapon", "USA", 2027, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     40, 30, 300, 2000, 4.5, 0.8, 14.0, 90.0, 2, 160.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "lrhw_dark_eagle", 8, "", 0),

    # --- NAVAL WARSHIPS & KAMIKAZE USV / UUV DRONES ---
    ("ddg_51_arleigh_burke", "USS Arleigh Burke Flight III Destroyer", "Arleigh Burke-class destroyer", "USA", 2026, "SEA", "SHIP", "SEA_DESTROYER",
     31, 20, 4500, 0, 80.0, 2.0, 60.0, 320.0, 1, 2200.0, "MANNED", 0, "orca_xluuv", 1, 60.0, 0.0,
     "an_spy_6_amdr", "sm_6_eram", 48, "agm_158_jassm", 24),
    ("type_055_renhai", "Type 055 Renhai Guided-Missile Cruiser", "Type 055 destroyer", "CHN", 2026, "SEA", "SHIP", "SEA_CRUISER",
     30, 20, 5000, 0, 95.0, 2.2, 65.0, 350.0, 1, 1800.0, "MANNED", 0, "sea_baby_usv", 2, 0.0, 0.0,
     "type_346a_dragon_eye", "3m22_zircon", 24, "48n6e3_s400", 48),
    ("magura_v5_usv", "MAGURA V5 Kamikaze Naval Drone Wolfpack", "MAGURA V5", "NATO", 2026, "SEA", "USV_DRONE", "SEA_USV_SWARM",
     42, 25, 450, 0, 0.008, 0.12, 2.0, 35.0, 6, 1.5, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "micro_eo_dog_turret", "usv_500kg_warhead", 6, "", 0),
    ("sea_baby_usv", "Sea Baby Multi-Role Naval USV Pack", "Sea Baby", "RUS", 2026, "SEA", "USV_DRONE", "SEA_USV_SWARM",
     45, 26, 500, 0, 0.01, 0.14, 3.0, 40.0, 6, 1.6, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "micro_eo_dog_turret", "usv_500kg_warhead", 6, "", 0),
    ("orca_xluuv", "Boeing Orca Autonomous XLUUV Submarine", "Orca (UUV)", "USA", 2027, "SEA", "UUV_DRONE", "SEA_UUV",
     12, 8, 6000, 0, 0.0001, 0.01, 15.0, 80.0, 2, 45.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "towed_sonar_array", "mk48_adcap_torpedo", 8, "", 0),
    ("ssn_688i_los_angeles", "USS Cheyenne SSN-688(I) / Virginia Nuclear Attack Submarine", "Los Angeles-class submarine", "USA", 2026, "SEA", "UUV_DRONE", "SEA_SUBMARINE_SSN",
     33, 20, 12000, 0, 0.0001, 0.01, 45.0, 280.0, 1, 2850.0, "MANNED", 0, "orca_xluuv", 1, 0.0, 0.0,
     "towed_sonar_array", "mk48_adcap_torpedo", 16, "agm_158_jassm", 12),
    ("type_093b_shang_ssn", "PLA Navy Type 093B Shang-III / Akula Nuclear Attack Submarine", "Type 093 submarine", "CHN", 2026, "SEA", "UUV_DRONE", "SEA_SUBMARINE_SSN",
     30, 18, 10000, 0, 0.0002, 0.02, 42.0, 260.0, 1, 1650.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "towed_sonar_array", "mk48_adcap_torpedo", 16, "3m22_zircon", 8),

    # --- EUROPEAN NATO, SOUTH/NORTH KOREA, INDIA & PAKISTAN FORCES ---
    ("rafale_f4_flight", "Dassault Rafale F4 Omnirole Flight (Meteor)", "Dassault Rafale", "EUR_NATO", 2026, "AIR", "FIGHTER", "AIR_FIGHTER",
     1050, 540, 1050, 15240, 0.1, 0.65, 10.0, 100.0, 4, 340.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "pirate_irst_passive", "mbda_meteor", 16, "agm_158_jassm", 8),
    ("leopard_2a8_platoon", "Leopard 2A8 Tank Platoon (with Trophy APS)", "Leopard 2", "EUR_NATO", 2026, "LAND", "ARMOR", "LAND_ARMOR",
     37, 27, 210, 2500, 3.2, 1.0, 88.0, 165.0, 4, 48.0, "MANNED", 0, "milrem_themis_ugv", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 40, "fgm_148_javelin", 4),
    ("kf_21_boramae", "KAI KF-21 Boramae 4.5-Gen Fighter Flight", "KAI KF-21 Boramae", "KOR", 2026, "AIR", "FIGHTER", "AIR_FIGHTER_STEALTH",
     1020, 540, 1000, 15000, 0.05, 0.5, 9.0, 95.0, 4, 280.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "mbda_meteor", 16, "agm_88g_aargm_er", 4),
    ("k2_black_panther", "K2 Black Panther Mountain Tank Platoon", "K2 Black Panther", "KOR", 2026, "LAND", "ARMOR", "LAND_ARMOR",
     40, 28, 220, 3000, 3.0, 0.95, 84.0, 155.0, 4, 36.0, "MANNED", 1, "vision_60_q_ugv", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 40, "fgm_148_javelin", 6),
    ("hyunmoo_5_tel", "Hyunmoo-5 Monster Bunker-Buster Battery", "Hyunmoo", "KOR", 2026, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     35, 25, 250, 2000, 4.5, 0.8, 14.0, 90.0, 2, 110.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "hyunmoo_5_bunker", 4, "", 0),
    ("kn_25_mlrs_battery", "KN-25 600mm Super-Large MLRS Battery", "KN-25", "PRK", 2025, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     32, 22, 200, 2000, 5.0, 0.9, 12.0, 85.0, 4, 45.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "kn_25_600mm_mlrs", 16, "", 0),
    ("hal_tejas_mk2", "HAL Tejas Mk2 Medium Weight Fighter Flight", "HAL Tejas Mk2", "IND", 2027, "AIR", "FIGHTER", "AIR_FIGHTER",
     1040, 530, 950, 15200, 0.25, 0.6, 8.0, 90.0, 4, 210.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "pirate_irst_passive", "mbda_meteor", 12, "brahmos_supersonic", 4),
    ("brahmos_coastal_battery", "BrahMos PJ-10 Supersonic Cruise Battery", "BrahMos", "IND", 2026, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     35, 25, 260, 3500, 4.0, 0.75, 14.0, 90.0, 3, 95.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "brahmos_supersonic", 12, "", 0),
    ("zorawar_mountain_tank", "Zorawar High-Altitude Light Tank Platoon", "Zorawar LT", "IND", 2026, "LAND", "ARMOR", "LAND_ARMOR",
     42, 30, 240, 4500, 2.2, 0.7, 50.0, 115.0, 4, 18.0, "MANNED", 1, "fpv_fiber_swarm", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 36, "fgm_148_javelin", 8),
    ("jf_17_block3_flight", "JF-17 Thunder Block III AESA Flight (PL-15)", "CAC/PAC JF-17 Thunder", "PAK", 2026, "AIR", "FIGHTER", "AIR_FIGHTER",
     1030, 520, 900, 15200, 0.5, 0.7, 8.0, 88.0, 4, 140.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "pl_15_aam", 16, "agm_88g_aargm_er", 4),
    ("bayraktar_akinci_ucav", "Bayraktar Akinci Heavy Strike UCAV Wing", "Baykar Bayraktar Akıncı", "PAK", 2026, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     210, 160, 2500, 12200, 0.4, 0.3, 6.0, 70.0, 4, 32.0, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "agm_158_jassm", 8, "switchblade_600_round", 12),

    # --- PHASE 6: AERIAL REFUELING TANKERS & LOGISTICS SUPPLY CONVOYS ---
    ("kc_46_pegasus", "KC-46A Pegasus Aerial Refueling Tanker Orbit", "Boeing KC-46 Pegasus", "USA", 2026, "AIR", "TANKER", "AIR_TANKER",
     490, 450, 4500, 12200, 55.0, 1.6, 10.0, 130.0, 1, 210.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "adm_160_mald", 4, "", 0),
    ("hemtt_supply_convoy", "Oshkosh M977 HEMTT Ammo & Drone Resupply Convoy", "Heavy Expanded Mobility Tactical Truck", "USA", 2026, "LAND", "LOGISTICS", "LAND_SUPPLY",
     42, 30, 450, 3500, 4.0, 0.8, 12.0, 95.0, 6, 6.5, "MANNED", 0, "vision_60_q_ugv", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "switchblade_600_round", 8, "", 0),

    # --- PHASE 15: UKRAINIAN ARMED FORCES (ZSU) & MEXICAN ARMED FORCES (SEDENA / SEMAR) ---
    ("t_84_oplot_platoon", "T-84 Oplot-M Ukrainian Tank Platoon (Duplet ERA)", "T-84", "UKR", 2026, "LAND", "ARMOR", "LAND_ARMOR",
     38, 27, 210, 2800, 3.1, 1.05, 82.0, 152.0, 4, 22.0, "MANNED", 0, "fpv_fiber_swarm", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "m829a4_apfsds", 40, "stugna_p_atgm", 8),
    ("btr_4_bucephalus_co", "BTR-4E Bucephalus Mechanized Infantry (with FPVs)", "BTR-4", "UKR", 2026, "LAND", "MECH_INF", "LAND_MECH_INF",
     44, 32, 260, 2800, 2.5, 0.85, 48.0, 120.0, 4, 12.0, "MANNED", 0, "fpv_fiber_swarm", 3, 0.0, 0.0,
     "electro_optical_flir_hd", "stugna_p_atgm", 16, "fpv_fiber_kamikaze", 18),
    ("neptune_rk360mc_battery", "RK-360MC Neptune Cruise & Vilkha-M Strike Battery", "R-360 Neptune", "UKR", 2026, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     36, 26, 280, 2500, 4.0, 0.75, 14.0, 90.0, 3, 65.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "r_360_neptune", 12, "vilkha_m_300mm", 12),
    ("bohdana_2s22_artillery", "2S22 Bohdana 155mm Self-Propelled Artillery Battery", "2S22 Bohdana", "UKR", 2026, "LAND", "HYPERSONIC_TEL", "LAND_MISSILE",
     40, 28, 250, 2800, 3.6, 0.8, 16.0, 88.0, 4, 18.0, "MANNED", 0, "fpv_fiber_swarm", 1, 0.0, 0.0,
     "electro_optical_flir_hd", "vilkha_m_300mm", 18, "switchblade_600_round", 8),
    ("palianytsia_drone_uk", "Palianytsia Rocket-Drone & Liutyi Deep-Strike Wing", "Palianytsia (missile)", "UKR", 2026, "AIR", "CCA_DRONE", "AIR_UAV_CCA",
     410, 340, 1200, 9500, 0.08, 0.35, 5.0, 58.0, 6, 8.5, "AUTONOMOUS_AI", 0, "", 0, 0.0, 0.0,
     "electro_optical_flir_hd", "r_360_neptune", 6, "iai_harop_round", 12),
    ("dn_xi_mexican_armor", "SEDENA DN-XI & ERC-90 Lynx Armored Cavalry Squadron", "Panhard ERC 90 Sagaie", "MEX", 2026, "LAND", "MECH_INF", "LAND_MECH_INF",
     46, 34, 280, 3600, 2.4, 0.8, 42.0, 115.0, 6, 14.0, "MANNED", 1, "fpv_fiber_swarm", 2, 0.0, 0.0,
     "electro_optical_flir_hd", "fgm_148_javelin", 12, "switchblade_600_round", 12),
    ("f_5f_tiger_mex_flight", "FAM F-5E/F Tiger II & Texan II Tactical Strike Flight", "Mexican Air Force", "MEX", 2026, "AIR", "FIGHTER", "AIR_FIGHTER",
     920, 480, 780, 15000, 1.4, 0.9, 8.0, 85.0, 4, 95.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_apg_83_sabr", "aim_120d", 8, "agm_88g_aargm_er", 6),
    ("pola_benito_juarez_frigate", "ARM Benito Juarez / Reformador (POLA-101) Frigate", "Reformador-class frigate", "MEX", 2026, "SEA", "SHIP", "SEA_DESTROYER",
     28, 18, 4200, 0, 45.0, 1.5, 48.0, 240.0, 1, 680.0, "MANNED", 0, "", 0, 0.0, 0.0,
     "an_spy_6_amdr", "sm_6_eram", 16, "r_360_neptune", 8),

    # --- FLAGSHIP AIRCRAFT CARRIERS & HYPERSONIC STRIKE FRIGATES ---
    ("cvn_78_gerald_r_ford", "USS Gerald R. Ford (CVN-78) Supercarrier CSG", "USS Gerald R. Ford", "USA", 2026, "SEA", "SHIP", "SEA_CARRIER",
     31, 22, 9500, 0, 160.0, 2.8, 92.0, 650.0, 1, 13000.0, "MANNED", 0, "f_35a_lightning", 3, 100.0, 0.0,
     "an_spy_6_amdr", "sm_6_eram", 64, "agm_158_jassm", 32),
    ("cns_fujian_cv18", "CNS Fujian (CV-18) EMALS Supercarrier CSG", "Chinese aircraft carrier Fujian", "CHN", 2026, "SEA", "SHIP", "SEA_CARRIER",
     30, 21, 7500, 0, 150.0, 2.7, 88.0, 580.0, 1, 8500.0, "MANNED", 0, "j_20_mighty_dragon", 3, 0.0, 0.0,
     "type_346a_dragon_eye", "3m22_zircon", 32, "48n6e3_s400", 64),
    ("fs_charles_de_gaulle_r91", "FS Charles de Gaulle (R91) Nuclear Carrier CSG", "French aircraft carrier Charles de Gaulle", "EUR_NATO", 2026, "SEA", "SHIP", "SEA_CARRIER",
     27, 20, 8000, 0, 120.0, 2.3, 82.0, 490.0, 1, 4800.0, "MANNED", 0, "rafale_f4_flight", 2, 0.0, 0.0,
     "an_spy_6_amdr", "mbda_meteor", 32, "agm_158_jassm", 24),
    ("ins_vikrant_r11", "INS Vikrant (R11) Carrier Battle Group", "INS Vikrant (2013)", "IND", 2026, "SEA", "SHIP", "SEA_CARRIER",
     28, 20, 7000, 0, 125.0, 2.4, 80.0, 480.0, 1, 3600.0, "MANNED", 0, "hal_tejas_mk2", 2, 0.0, 0.0,
     "an_spy_6_amdr", "brahmos_supersonic", 24, "sm_6_eram", 32),
    ("admiral_gorshkov_frigate", "Admiral Gorshkov (Project 22350) Zircon Frigate", "Admiral Gorshkov-class frigate", "RUS", 2026, "SEA", "SHIP", "SEA_CRUISER",
     29, 20, 4800, 0, 55.0, 1.8, 56.0, 290.0, 1, 950.0, "MANNED", 0, "sea_baby_usv", 2, 0.0, 0.0,
     "91n6e_big_bird", "3m22_zircon", 24, "48n6e3_s400", 32),
]


def build_database() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        try:
            DB_PATH.unlink()
        except PermissionError:
            pass

    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()

    cur.executescript(
        """
        DROP TABLE IF EXISTS sovereign_nations;
        DROP TABLE IF EXISTS tech_tree_nodes;
        DROP TABLE IF EXISTS manual_sections;
        DROP TABLE IF EXISTS tutorial_steps;
        DROP TABLE IF EXISTS scenarios;
        DROP TABLE IF EXISTS theater_sites;
        DROP TABLE IF EXISTS theaters;
        DROP TABLE IF EXISTS formation_templates;
        DROP TABLE IF EXISTS platform_loadouts;
        DROP TABLE IF EXISTS platform_sensors;
        DROP TABLE IF EXISTS weapons;
        DROP TABLE IF EXISTS sensors;
        DROP TABLE IF EXISTS platforms;
        CREATE TABLE platforms (
            platform_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            wiki_page_title TEXT NOT NULL,
            wiki_url TEXT,
            wiki_summary TEXT,
            image_res_path TEXT,
            country_origin TEXT NOT NULL,
            service_year INTEGER NOT NULL,
            domain TEXT NOT NULL,
            unit_class TEXT NOT NULL,
            nato_symbol_code TEXT NOT NULL,
            max_speed_knots REAL NOT NULL,
            cruise_speed_knots REAL NOT NULL,
            combat_radius_km REAL NOT NULL,
            max_altitude_m REAL NOT NULL,
            rcs_m2 REAL NOT NULL,
            ir_signature REAL NOT NULL,
            armor_rating REAL DEFAULT 0.0,
            max_hp REAL NOT NULL,
            elements_per_token INTEGER DEFAULT 4,
            unit_cost_musd REAL NOT NULL,
            autonomy_level TEXT DEFAULT 'MANNED',
            can_climb_steep_slopes INTEGER DEFAULT 0,
            carrier_sub_platform_slug TEXT DEFAULT '',
            carrier_sub_count INTEGER DEFAULT 0,
            directed_energy_kw REAL DEFAULT 0.0,
            de_aoe_cone_deg REAL DEFAULT 0.0
        );

        CREATE TABLE sensors (
            sensor_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            sensor_type TEXT NOT NULL,
            max_range_km REAL NOT NULL,
            min_altitude_m REAL DEFAULT 0.0,
            look_down_shoot_down INTEGER DEFAULT 1,
            can_guide_weapons INTEGER DEFAULT 1
        );

        CREATE TABLE weapons (
            weapon_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            wiki_page_title TEXT NOT NULL,
            wiki_url TEXT,
            wiki_summary TEXT,
            image_res_path TEXT,
            target_domain_mask INTEGER NOT NULL,
            guidance_type TEXT NOT NULL,
            max_range_km REAL NOT NULL,
            no_escape_range_km REAL NOT NULL,
            min_range_km REAL NOT NULL,
            speed_mach REAL NOT NULL,
            flight_profile TEXT NOT NULL,
            base_pk REAL NOT NULL,
            warhead_damage REAL NOT NULL,
            is_interceptable INTEGER DEFAULT 1,
            round_cost_musd REAL NOT NULL
        );

        CREATE TABLE platform_sensors (
            platform_id INTEGER REFERENCES platforms(platform_id),
            sensor_id INTEGER REFERENCES sensors(sensor_id),
            PRIMARY KEY (platform_id, sensor_id)
        );

        CREATE TABLE platform_loadouts (
            loadout_id INTEGER PRIMARY KEY AUTOINCREMENT,
            platform_id INTEGER REFERENCES platforms(platform_id),
            role_code TEXT NOT NULL,
            display_name TEXT NOT NULL,
            weapon_1_id INTEGER REFERENCES weapons(weapon_id),
            weapon_1_qty INTEGER DEFAULT 0,
            weapon_2_id INTEGER REFERENCES weapons(weapon_id),
            weapon_2_qty INTEGER DEFAULT 0
        );

        CREATE TABLE formation_templates (
            template_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            faction TEXT NOT NULL,
            echelon_level INTEGER NOT NULL,
            child_entries_json TEXT NOT NULL
        );

        CREATE TABLE theaters (
            theater_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            size_km REAL DEFAULT 500.0,
            min_elevation_m REAL DEFAULT -500.0,
            max_elevation_m REAL DEFAULT 3800.0,
            heightmap_res_path TEXT NOT NULL
        );

        CREATE TABLE theater_sites (
            site_id INTEGER PRIMARY KEY AUTOINCREMENT,
            theater_id INTEGER REFERENCES theaters(theater_id),
            site_name TEXT NOT NULL,
            site_type TEXT NOT NULL,
            faction_owner TEXT NOT NULL,
            x_km REAL NOT NULL,
            z_km REAL NOT NULL,
            strategic_value INTEGER DEFAULT 100
        );

        CREATE TABLE scenarios (
            scenario_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            theater_slug TEXT NOT NULL,
            era_label TEXT NOT NULL,
            briefing_opord TEXT NOT NULL,
            blue_budget_musd REAL NOT NULL,
            red_budget_musd REAL NOT NULL,
            orbat_json TEXT NOT NULL
        );

        CREATE TABLE tutorial_steps (
            step_id INTEGER PRIMARY KEY AUTOINCREMENT,
            step_order INTEGER NOT NULL,
            slug TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            instructor_callsign TEXT NOT NULL,
            prompt_text TEXT NOT NULL,
            ui_highlight_target TEXT NOT NULL,
            completion_signal_or_cmd TEXT NOT NULL,
            reward_tip TEXT NOT NULL
        );

        CREATE TABLE manual_sections (
            section_id INTEGER PRIMARY KEY AUTOINCREMENT,
            section_order INTEGER NOT NULL,
            slug TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            markdown_body TEXT NOT NULL
        );

        CREATE TABLE tech_tree_nodes (
            tech_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            branch_code TEXT NOT NULL,
            tier INTEGER NOT NULL,
            prereq_slug TEXT DEFAULT '',
            cost_musd REAL NOT NULL,
            effect_summary TEXT NOT NULL,
            modifiers_json TEXT NOT NULL
        );

        CREATE TABLE sovereign_nations (
            nation_id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            country_name TEXT NOT NULL,
            iso_code TEXT NOT NULL,
            capital_name TEXT NOT NULL,
            theater_slug TEXT NOT NULL,
            initial_alignment REAL NOT NULL,
            initial_status TEXT NOT NULL,
            airspace_x_min_km REAL NOT NULL,
            airspace_z_min_km REAL NOT NULL,
            airspace_width_km REAL NOT NULL,
            airspace_depth_km REAL NOT NULL,
            aid_musd_per_min REAL NOT NULL,
            grant_package_musd REAL NOT NULL,
            expeditionary_platform_slug TEXT NOT NULL,
            diplomatic_profile TEXT NOT NULL
        );
        """
    )

    # 1. Insert Sensors
    sensor_id_by_slug = {}
    for s in SENSORS_SEED:
        cur.execute(
            """INSERT INTO sensors (slug, display_name, sensor_type, max_range_km, min_altitude_m, look_down_shoot_down, can_guide_weapons)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            s,
        )
        sensor_id_by_slug[s[0]] = cur.lastrowid

    # 2. Insert Weapons + Fetch Real Wikipedia Images & Summaries
    print("=== Fetching Weapon Data & Real Photos from Wikipedia REST API ===")
    weapon_id_by_slug = {}
    real_weapon_photos = 0
    for w in WEAPONS_SEED:
        slug, name, wiki_title, mask, guidance, max_km, ne_km, min_km, mach, profile, pk, dmg, interceptable, cost = w
        meta = fetch_wikipedia_metadata_and_photo(wiki_title, slug, IMG_WEAPONS_DIR, fallback_rgb=(200, 110, 30))
        if meta["downloaded_real_photo"]:
            real_weapon_photos += 1
        cur.execute(
            """INSERT INTO weapons (
                slug, display_name, wiki_page_title, wiki_url, wiki_summary, image_res_path,
                target_domain_mask, guidance_type, max_range_km, no_escape_range_km, min_range_km,
                speed_mach, flight_profile, base_pk, warhead_damage, is_interceptable, round_cost_musd
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                slug, name, wiki_title, meta["wiki_url"], meta["wiki_summary"], meta["image_res_path"],
                mask, guidance, max_km, ne_km, min_km, mach, profile, pk, dmg, interceptable, cost,
            ),
        )
        weapon_id_by_slug[slug] = cur.lastrowid
        print(f"  [WEAPON] {name:42s} -> {meta['image_res_path']} (RealWikiPhoto={meta['downloaded_real_photo']})")

    # 3. Insert Platforms + Fetch Real Wikipedia Images & Summaries
    print("\n=== Fetching Platform, Robot Dog & Drone Data & Real Photos from Wikipedia REST API ===")
    platform_id_by_slug = {}
    real_platform_photos = 0
    for p in PLATFORMS_SEED:
        (
            slug, name, wiki_title, country, year, domain, unit_class, nato_code,
            max_kts, cruise_kts, radius_km, max_alt_m, rcs, ir, armor, hp, elements, cost_musd,
            autonomy, climb_steep, sub_slug, sub_cnt, de_kw, de_cone,
            sensor_slug, w1_slug, w1_qty, w2_slug, w2_qty,
        ) = p
        rgb = (30, 160, 220) if country in ("USA", "NATO", "TUR") else (220, 60, 60)
        meta = fetch_wikipedia_metadata_and_photo(wiki_title, slug, IMG_PLATFORMS_DIR, fallback_rgb=rgb)
        if meta["downloaded_real_photo"]:
            real_platform_photos += 1

        cur.execute(
            """INSERT INTO platforms (
                slug, display_name, wiki_page_title, wiki_url, wiki_summary, image_res_path,
                country_origin, service_year, domain, unit_class, nato_symbol_code,
                max_speed_knots, cruise_speed_knots, combat_radius_km, max_altitude_m,
                rcs_m2, ir_signature, armor_rating, max_hp, elements_per_token, unit_cost_musd,
                autonomy_level, can_climb_steep_slopes, carrier_sub_platform_slug, carrier_sub_count,
                directed_energy_kw, de_aoe_cone_deg
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                slug, name, wiki_title, meta["wiki_url"], meta["wiki_summary"], meta["image_res_path"],
                country, year, domain, unit_class, nato_code,
                max_kts, cruise_kts, radius_km, max_alt_m,
                rcs, ir, armor, hp, elements, cost_musd,
                autonomy, climb_steep, sub_slug, sub_cnt, de_kw, de_cone,
            ),
        )
        pid = cur.lastrowid
        platform_id_by_slug[slug] = pid

        if sensor_slug and sensor_slug in sensor_id_by_slug:
            cur.execute("INSERT INTO platform_sensors VALUES (?, ?)", (pid, sensor_id_by_slug[sensor_slug]))

        w1_id = weapon_id_by_slug.get(w1_slug, 0) if w1_slug else 0
        w2_id = weapon_id_by_slug.get(w2_slug, 0) if w2_slug else 0
        cur.execute(
            """INSERT INTO platform_loadouts (platform_id, role_code, display_name, weapon_1_id, weapon_1_qty, weapon_2_id, weapon_2_qty)
               VALUES (?, 'STANDARD', 'Standard Combat Loadout', ?, ?, ?, ?)""",
            (pid, w1_id, w1_qty, w2_id, w2_qty),
        )
        print(f"  [PLATFORM] {name:46s} -> {meta['image_res_path']} (RealWikiPhoto={meta['downloaded_real_photo']})")

    # 4. Seed 7 Global Flashpoint Theaters (2,000 km x 2,000 km Operational Scale) & Authentic Strategic Bases
    theaters_seed = [
        ("strait_theater", "Taiwan Strait & East China Sea (2000x2000 km)", 2000.0, -500.0, 3800.0, "res://data/theaters/strait_theater_heightmap.png", [
            ("Kadena Air Base (USAF 18th & 388th Wing)", "AIRBASE", "BLUE", 160.0, -90.0, 250),
            ("Hsinchu & CCK Air Defense Command (ROC)", "COMMAND_BUNKER", "BLUE", 110.0, -40.0, 300),
            ("Kaohsiung & Zuoying Fleet Base (USS Ford CVN-78)", "NAVAL_PORT", "BLUE", 85.0, 120.0, 200),
            ("Yushan Central Mountain Pass (3,800m)", "CHOKEPOINT", "BLUE", 135.0, 25.0, 180),
            ("Fuzhou PLAAF Airbase (Eastern Theater Command)", "AIRBASE", "RED", -145.0, -65.0, 250),
            ("Xiamen 73rd Group Army & CNS Fujian (CV-18) Base", "NAVAL_PORT", "RED", -130.0, 80.0, 250),
            ("Longtian Airbase & PLA Rocket Force Base 61", "COMMAND_BUNKER", "RED", -110.0, -10.0, 300),
        ]),
        ("hormuz_theater", "Strait of Hormuz, Persian Gulf & Arabian Sea (2000x2000 km)", 2000.0, -500.0, 3400.0, "res://data/theaters/hormuz_theater_heightmap.png", [
            ("Al Dhafra & Al Udeid Air Base (380th AEW)", "AIRBASE", "BLUE", 65.0, 145.0, 300),
            ("Khasab Musandam Radar & Laser Bastion", "COMMAND_BUNKER", "BLUE", 20.0, 45.0, 250),
            ("Fujairah & 5th Fleet Port (USS Lincoln CVN-72)", "NAVAL_PORT", "BLUE", 85.0, 110.0, 220),
            ("Bandar Abbas & Shiraz IRIAF Tactical Airbase", "AIRBASE", "RED", -15.0, -95.0, 300),
            ("Qeshm Island IRGC Aerospace & Shahed Citadel", "COMMAND_BUNKER", "RED", -25.0, -35.0, 260),
            ("Jask & Chabahar Submarine & USV Pen", "NAVAL_PORT", "RED", 115.0, -65.0, 220),
        ]),
        ("korean_dmz_theater", "Korean Peninsula, Yellow Sea & Sea of Japan (2000x2000 km)", 2000.0, -500.0, 2800.0, "res://data/theaters/korean_dmz_heightmap.png", [
            ("Osan & Cheongju Air Base (7th AF & ROK 17th Wing)", "AIRBASE", "BLUE", -25.0, 95.0, 300),
            ("Seoul Capital HQ (ROK VII Corps 'Fierce Tiger')", "COMMAND_BUNKER", "BLUE", -35.0, 45.0, 350),
            ("Busan & Jinhae Naval Base (ROKS Jeongjo the Great)", "NAVAL_PORT", "BLUE", -75.0, 55.0, 220),
            ("Chorwon & Iron Triangle DMZ Pass", "CHOKEPOINT", "BLUE", 15.0, 12.0, 200),
            ("Sunchon KPA Underground Fighter Airbase", "AIRBASE", "RED", -40.0, -110.0, 280),
            ("Pyongyang Missile General Bureau & 105th Tank Div", "COMMAND_BUNKER", "RED", -55.0, -65.0, 350),
            ("Wonsan Kalma Naval & Drone Base (KPA IV Corps)", "NAVAL_PORT", "RED", 65.0, -75.0, 220),
        ]),
        ("baltic_suwalki_theater", "Baltic Sea, Suwalki Gap, Poland & Kaliningrad (2000x2000 km)", 2000.0, -300.0, 1800.0, "res://data/theaters/baltic_suwalki_heightmap.png", [
            ("Siauliai & Lask NATO Air Base (Rafale F4 & F-35A)", "AIRBASE", "BLUE", 65.0, -115.0, 280),
            ("Suwalki & Rukla HQ (German 45th Bde & Polish 18th Div)", "COMMAND_BUNKER", "BLUE", 45.0, 55.0, 320),
            ("Klaipeda & Gdynia Port (FS Charles de Gaulle R91)", "NAVAL_PORT", "BLUE", -45.0, -95.0, 210),
            ("Chkalovsk Kaliningrad VKS Airbase (Su-57 & Kinzhal)", "AIRBASE", "RED", -65.0, 25.0, 280),
            ("Kaliningrad 11th Army Corps & S-400 Bastion", "COMMAND_BUNKER", "RED", -45.0, 40.0, 320),
            ("Grodno Western MD Tank Assembly (1st Guards Tank Army)", "CHOKEPOINT", "RED", 125.0, 75.0, 250),
        ]),
        ("himalaya_lac_theater", "Himalaya LAC, Northern India, Pakistan & Tibet (2000x2000 km)", 2000.0, 0.0, 5600.0, "res://data/theaters/himalaya_lac_heightmap.png", [
            ("Leh & Ambala AFS (No. 17 'Golden Arrows' & Tejas Mk2)", "AIRBASE", "BLUE", -75.0, 65.0, 300),
            ("Leh XIV 'Fire and Fury' Corps & Daulat Beg Oldi HQ", "COMMAND_BUNKER", "BLUE", -35.0, -65.0, 280),
            ("Pangong Tso & Rezang La (XVII Brahmastra Strike Corps)", "CHOKEPOINT", "BLUE", 5.0, 15.0, 260),
            ("Hotan & Ngari Gunsa PLAAF Western Theater Airbase", "AIRBASE", "RED", 115.0, -45.0, 300),
            ("Aksai Chin PLA 76th & 77th Group Army Citadel", "COMMAND_BUNKER", "RED", 65.0, -10.0, 280),
            ("PAF Base Skardu & Minhas Kamra (No. 28 Sq JF-17)", "AIRBASE", "RED", -125.0, -85.0, 250),
        ]),
        ("ukraine_donbas_theater", "Ukraine, Black Sea, Donbas & Western Russia (2000x2000 km)", 2000.0, -200.0, 900.0, "res://data/theaters/ukraine_donbas_heightmap.png", [
            ("Myrhorod & Starokostiantyniv Airbase (40th Tactical Bde)", "AIRBASE", "BLUE", -125.0, -85.0, 320),
            ("Kramatorsk & Pokrovsk HQ (3rd Assault & 93rd Kholodnyi Yar)", "COMMAND_BUNKER", "BLUE", -25.0, -45.0, 350),
            ("Zaporizhzhia Steppe (47th Magura & 414th Madyar's Birds)", "CHOKEPOINT", "BLUE", -95.0, 20.0, 300),
            ("Odesa Naval Base (385th USV Bde & 19th Neptune Bde)", "NAVAL_PORT", "BLUE", -185.0, 115.0, 260),
            ("Engels-2 & Millerovo VKS Bomber Airbase", "AIRBASE", "RED", 165.0, -35.0, 320),
            ("Donetsk & Rostov Southern MD HQ (8th & 58th Armies)", "COMMAND_BUNKER", "RED", 55.0, -10.0, 350),
            ("Sevastopol & Novorossiysk Black Sea Fleet (Adm. Gorshkov)", "NAVAL_PORT", "RED", 45.0, 95.0, 260),
        ]),
        ("mexico_rio_grande_theater", "US-Mexico Rio Grande, Sierra Madre & Gulf (2000x2000 km)", 2000.0, -400.0, 3400.0, "res://data/theaters/mexico_rio_grande_heightmap.png", [
            ("Joint Base San Antonio & Kelly AFB (USAF ACC)", "AIRBASE", "BLUE", -35.0, -155.0, 320),
            ("Fort Cavazos & Laredo HQ (III Corps & 1st Cavalry Div)", "COMMAND_BUNKER", "BLUE", -45.0, -55.0, 340),
            ("NAS Corpus Christi & Gulf Carrier Group (USS Ford)", "NAVAL_PORT", "BLUE", 95.0, -95.0, 260),
            ("BAM-1 Santa Lucia & BAM-14 Monterrey (Escuadron 401)", "AIRBASE", "RED", -85.0, 125.0, 300),
            ("Monterrey IV Region Militar & 1/a Brigada Blindada HQ", "COMMAND_BUNKER", "RED", -95.0, 85.0, 340),
            ("Veracruz & Tampico SEMAR Base (ARM Benito Juarez POLA-101)", "NAVAL_PORT", "RED", 110.0, 75.0, 250),
        ]),
    ]
    for t_slug, t_name, t_size, t_min, t_max, t_path, t_sites in theaters_seed:
        cur.execute(
            """INSERT INTO theaters (slug, display_name, size_km, min_elevation_m, max_elevation_m, heightmap_res_path)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (t_slug, t_name, t_size, t_min, t_max, t_path),
        )
        tid = cur.lastrowid
        for s in t_sites:
            cur.execute(
                "INSERT INTO theater_sites (theater_id, site_name, site_type, faction_owner, x_km, z_km, strategic_value) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (tid, *s),
            )

    # 4.5 Seed Formation Templates (Brigade -> Battalion -> Company/Flight TO&E)
    formations = [
        (
            "us_388th_stealth_wing",
            "388th Composite Stealth & CCA Wing",
            "BLUE",
            2,
            json.dumps([
                {"slug": "f_35a_lightning", "dx": -6.0, "dz": -4.0},
                {"slug": "xq_58a_valkyrie", "dx": 6.0, "dz": -4.0},
                {"slug": "f_16cj_block70", "dx": -6.0, "dz": 5.0},
                {"slug": "mq_28_ghost_bat", "dx": 6.0, "dz": 5.0},
            ]),
        ),
        (
            "us_1st_abct_robot_dog_bde",
            "1st Armored & Quadruped Robot Dog Brigade",
            "BLUE",
            2,
            json.dumps([
                {"slug": "m1a2_sepv3_platoon", "dx": -5.0, "dz": -3.0},
                {"slug": "m2a4_mech_company", "dx": 5.0, "dz": -3.0},
                {"slug": "specops_mountain_team", "dx": 0.0, "dz": 4.0},
                {"slug": "iron_beam_helws", "dx": -4.0, "dz": 6.0},
                {"slug": "epirus_leonidas_hpm", "dx": 4.0, "dz": 6.0},
            ]),
        ),
        (
            "opfor_bastion_iads_regiment",
            "OPFOR Integrated Air Defense & EW Regiment",
            "RED",
            2,
            json.dumps([
                {"slug": "s_400_triumf", "dx": 0.0, "dz": 0.0},
                {"slug": "krasukha_4_ew", "dx": -5.0, "dz": 3.0},
                {"slug": "shahed_136_launcher", "dx": 5.0, "dz": -3.0},
                {"slug": "lancet_3_team", "dx": 5.0, "dz": 4.0},
            ]),
        ),
        (
            "opfor_4th_guards_robot_tank_bde",
            "4th Guards Tank & Robotic Assault Brigade",
            "RED",
            2,
            json.dumps([
                {"slug": "t_90m_platoon", "dx": -5.0, "dz": -3.0},
                {"slug": "uran_9_ugv", "dx": 5.0, "dz": -3.0},
                {"slug": "unitree_b2w_armed", "dx": 0.0, "dz": 4.0},
                {"slug": "lancet_3_team", "dx": -4.0, "dz": 5.0},
            ]),
        ),
    ]
    for f in formations:
        cur.execute(
            """INSERT INTO formation_templates (slug, display_name, faction, echelon_level, child_entries_json)
               VALUES (?, ?, ?, ?, ?)""",
            f,
        )

    # 5. Seed Playable Scenarios (Used by Main Menu & Campaign Selector)
    scenarios = [
        (
            "op_pacific_shield_2028",
            "Operation Pacific Shield (Full 500km Theater War)",
            "strait_theater",
            "2028 Drone, Robot Dog & Hypersonic Era",
            "OPORD 28-01: Enemy S-400 battalions, Type 055 cruisers, and Shahed/Lancet drone swarms are massing across the strait. Use F-35 stealth flights, XQ-58 Valkyrie AI Wingmen, Iron Beam lasers, and Epirus Leonidas microwave domes to shatter their IADS and hold the central mountain ridge.",
            4500.0,
            4500.0,
            json.dumps({"scale": "FULL_THEATER", "brigades_per_side": 5}),
        ),
        (
            "op_iron_hound_ridge",
            "Operation Iron Hound (Mountain Ridge Robot Dog & FPV Clash)",
            "strait_theater",
            "2028 Tactical Unmanned Warfare",
            "OPORD 28-02: Enemy T-90M armor and Uran-9 robotic tanks are pushing through Yushan Ridge Pass. Zoom into the 15km mountain sector, deploy Ghost Robotics Vision 60 Robot Dog packs up the sheer cliffside to laser-designate targets, and unleash jam-proof fiber-optic FPV swarms.",
            850.0,
            950.0,
            json.dumps({"scale": "TACTICAL_RIDGE", "brigades_per_side": 2}),
        ),
        (
            "op_red_strait_swarm",
            "Operation Sea Wolfpack (Strait of Hormuz USVs vs Carrier Group)",
            "hormuz_theater",
            "2028 Littoral Drone Swarm War",
            "OPORD 28-03: High-speed MAGURA V5 and Sea Baby kamikaze drone boats alongside Orca autonomous submarines are hunting surface warships in the narrow Strait of Hormuz while 3M22 Zircon hypersonics streak overhead.",
            2800.0,
            2800.0,
            json.dumps({"scale": "NAVAL_STRAIT", "brigades_per_side": 3}),
        ),
        (
            "op_korean_thunder_dmz",
            "Operation Iron Peninsula (Korean DMZ: KF-21, K2 & Hyunmoo-5 vs KN-25)",
            "korean_dmz_theater",
            "2028 Korean Peninsula High-Intensity War",
            "OPORD 28-04: North Korean KN-25 600mm super-large MLRS batteries and T-90M armor are shelling along the DMZ. Scramble ROKAF KF-21 Boramae flights (armed with MBDA Meteor), K2 Black Panther mountain tanks, Vision 60 Robot Dogs, and 8-ton Hyunmoo-5 bunker-buster missiles to crater enemy TEL citadels.",
            3200.0,
            3200.0,
            json.dumps({"scale": "KOREAN_DMZ", "brigades_per_side": 4}),
        ),
        (
            "op_baltic_shield_suwalki",
            "Operation Baltic Shield (Suwalki Gap: Rafale F4 & Leopard 2A8 vs S-400)",
            "baltic_suwalki_theater",
            "2028 NATO Eastern Flank Coalition War",
            "OPORD 28-05: Kaliningrad S-400 regiments, Su-57 Felons, and Uran-9 robotic tanks are attempting to sever the Suwalki Corridor. Deploy European NATO Dassault Rafale F4 flights, Leopard 2A8 platoons with Milrem THeMIS UGVs, and Rheinmetall Skynex 35mm AHEAD C-UAS batteries.",
            3400.0,
            3400.0,
            json.dumps({"scale": "BALTIC_SUWALKI", "brigades_per_side": 4}),
        ),
        (
            "op_himalayan_sentinel_lac",
            "Operation High Sentinel (5,600m Himalayan LAC: Tejas Mk2 & Zorawar vs J-20)",
            "himalaya_lac_theater",
            "2028 Extreme-Altitude Mountain & Robot Dog Warfare",
            "OPORD 28-06: Across 5,600m Karakoram peaks where heavy tanks bog down on >25° slopes, deploy Indian Zorawar high-altitude light tanks, HAL Tejas Mk2 fighters, BrahMos supersonic cruise batteries, and cliff-climbing Quadruped Robot Dog packs against J-20 stealth flights and JF-17 Block III squadrons.",
            2900.0,
            2900.0,
            json.dumps({"scale": "HIMALAYA_LAC", "brigades_per_side": 3}),
        ),
        (
            "op_ukraine_donbas_2028",
            "Operation Steppe Shield (Ukraine Donbas & Azov: 240,000 Units Drone-Artillery War)",
            "ukraine_donbas_theater",
            "2028 High-Density FPV Swarm, Artillery & Mechanized Front",
            "OPORD 28-07: Across the fortified Donbas Ridge, Zaporizhzhia Steppe, and Sea of Azov littoral (240,000 combat units), command Ukrainian T-84 Oplot-M & Leopard 2A8 armor, BTR-4E & M2A4 Bradley infantry, 2S22 Bohdana 155mm artillery, RK-360MC Neptune batteries, Palianytsia rocket-drones, Fiber-Optic FPV Swarms, and MAGURA V5 naval drones against Russian T-90M, S-400, Krasukha-4 EW, and Lancet/Shahed regiments.",
            3800.0,
            4200.0,
            json.dumps({"scale": "UKRAINE_DONBAS", "brigades_per_side": 6}),
        ),
        (
            "op_mexico_rio_grande_2028",
            "Operation Rio Bravo (US-Mexico Sierra Madre & Gulf: 70,000 Units Cavalry & Mountain War)",
            "mexico_rio_grande_theater",
            "2028 North American Rio Grande & Sierra Madre Campaign",
            "OPORD 28-08: Along the Rio Grande frontier, the 3,200m Sierra Madre Oriental mountain passes around Monterrey, and the Gulf Coast (70,000 combat units), US NORTHCOM III Armored Corps (M1A2 SEPv3, M2A4 Bradley, F-35A, Stryker Leonidas HPM, Vision 60 Robot Dogs) clashes with Mexican SEDENA DN-XI armored cavalry, FAM F-5F tactical flights, and SEMAR POLA-101 Reformador frigates.",
            2600.0,
            2400.0,
            json.dumps({"scale": "MEXICO_RIO_GRANDE", "brigades_per_side": 4}),
        ),
        (
            "op_global_escalation_chronicle_2028",
            "Operation Doomsday Clock 2028 (8-Chapter Story Campaign with Live Veo 3.1 News & Capabilities)",
            "strait_theater",
            "2028 Complete Historical Progression & Capabilities Showcase (DEFCON 5 -> DEFCON 1)",
            "OPORD 28-00 // STORY PROLOGUE & 8-MISSION PROGRESSION: Experience the complete historical escalation of the 2028 Global Conflict from DEFCON 5 to DEFCON 1 across 8 guided story missions—each introduced by a live Google Veo 3.1 TV News Video Broadcast, Presidential Directive, and Officer Voice Briefing while progressively unlocking Stealth SEAD, Robot Dogs & FPV Swarms, Naval USV Wolfpacks, Diplomacy & Airspace Treaties, R&D Tech Tree, Space ASAT & HEMP, Bunker Relocation, and Orbital Tungsten Rods / Thermonuclear Deterrence.",
            4800.0,
            4800.0,
            json.dumps({"scale": "STORY_PROGRESSION_CAMPAIGN", "missions": 8, "brigades_per_side": 5}),
        ),
    ]
    for sc in scenarios:
        cur.execute(
            """INSERT INTO scenarios (slug, display_name, theater_slug, era_label, briefing_opord, blue_budget_musd, red_budget_musd, orbat_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            sc,
        )

    # 6. Seed Interactive Tutorial Steps (Driven by TutorialController in-game)
    tutorial_steps = [
        (
            1,
            "tut_zoom_and_echelons",
            "Lesson 1: Holographic Table & Semantic Echelon Zoom",
            "MAGIC 1-1 (AWACS INSTRUCTOR)",
            "Welcome to the C4ISR Command Bunker, Commander. At 500km Macro View, units stack into Brigade & Air Wing counters. Scroll your mouse wheel (or pinch-spread with both VR hands) to zoom into a <15km mountain valley and watch Brigades split into Battalions and Companies.",
            "WAR_TABLE_ZOOM",
            "ZOOM_TACTICAL_REACHED",
            "At any zoom level, you can order an entire Brigade at once—and its Subordinate AI will handle formation bounding—or zoom in to take Direct Manual Control of a single flight!",
        ),
        (
            2,
            "tut_multispectral_sensors",
            "Lesson 2: The 6-Spectrum Sensor War (Radar vs. Passive ESM, IRST & Acoustic)",
            "MAGIC 1-1 (AWACS INSTRUCTOR)",
            "Right now your air-defense radars are DARK (EMCON) to hide from enemy anti-radiation missiles. Flip the physical [MASTER IADS LEVER] on the table console to illuminate the theater with Active Radar, while your Passive ESM, IRST, and Acoustic Arrays listen silently.",
            "CONSOLE_MASTER_IADS",
            "CMD_SET_MASTER_IADS",
            "Remember: Active Radar sees far but broadcasts your position to enemy Passive ESM at 1.6x range! Stealth jets (F-35/J-20) beat Radar, but Passive IRST and Acoustic Arrays can still spot them at closer range.",
        ),
        (
            3,
            "tut_deploy_robot_dogs",
            "Lesson 3: Deploying Quadruped Robot Dogs & Jam-Proof FPV Swarms",
            "HOUND ACTUAL (SPEC-OPS)",
            "Tanks cannot climb >30° mountain cliffs, and standard RF drones get jammed by Krasukha-4 EW stations. Select a friendly M2A4 Bradley Company or Special Forces team and press [DEPLOY UNMANNED (DOGS / FPV)] on the console to unpack Vision 60 Robot Dog Packs and Fiber-Optic FPV Swarms!",
            "CONSOLE_DEPLOY_UNMANNED",
            "CMD_DEPLOY_UNMANNED_SUBUNIT",
            "Quadruped Robot Dogs use 3D LiDAR + Autonomous AI (immune to EW jamming), have a tiny 0.0005 m² radar signature, and climb sheer cliffs to laser-designate enemy SAMs!",
        ),
        (
            4,
            "tut_recon_photo_dossier",
            "Lesson 4: Wikipedia Intelligence Dossier & Real Recon Photographs",
            "INTEL DIRECTOR",
            "Select any token on the table—or flip the [RECON PHOTO MODE] switch on the console—to inspect real Wikipedia photographs of the platform and its equipped missiles, radar cross-section (RCS), and unit replacement cost in $M USD.",
            "CONSOLE_RECON_PHOTO",
            "RECON_PHOTO_TOGGLED",
            "Every weapon shot has a real dollar cost: never waste a $4.0M Patriot PAC-3 interceptor on a $25,000 Shahed drone!",
        ),
        (
            5,
            "tut_alpha_strike_and_lasers",
            "Lesson 5: Orchestrating an Alpha Strike & Laser/HPM Swarm Defense",
            "STRIKE MARSHAL",
            "Select a friendly Fighter Flight or Brigade, right-click drag (or VR trigger-pull) a 3D Strike Vector onto a red target to preview parabolic missile arcs, then flip open the Red Safety Cover and slam [EXECUTE ALPHA STRIKE]!",
            "CONSOLE_ALPHA_STRIKE",
            "CMD_COMMIT_ALPHA_STRIKE",
            "Tutorial Complete! Watch your Iron Beam 100kW Lasers ($2/shot) and Epirus Leonidas 30° HPM Microwave cones zap incoming enemy drone swarms while your hypersonics and stealth flights strike home.",
        ),
    ]
    for ts in tutorial_steps:
        cur.execute(
            """INSERT INTO tutorial_steps (step_order, slug, title, instructor_callsign, prompt_text, ui_highlight_target, completion_signal_or_cmd, reward_tip)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            ts,
        )

    # 7. Seed In-Game Field Manual Sections (Phases 1-16 Complete Architecture)
    manual_sections = [
        (
            1,
            "man_controls_ux",
            "1. Desktop & OpenXR VR Controls + 5-Tier Planetary-to-Tactical Zoom",
            "CONTROLS",
            "- **Desktop Camera & Table View:** `WASD` Pan | Right-Click Drag Orbit/Pitch | Scroll-Wheel / `Q` & `E` Zoom | `[C]` Tacview 3D Follow Camera | `[F11]` Toggle 3D VR Hands Simulator.\n"
            "- **OpenXR VR (`XRCommandRig` — Meta Quest 3 / PCVR):** Two-Hand Grip Pinch-Zoom & Pan | Single-Hand Grip Grab-Pan | Right Trigger Tap to Select Unit / Poke 3D Console Switch / Click 3D Globe Flashpoint | Right Trigger Hold-Drag to Expand **3D Holographic Sphere Volume Selector** | Left Trigger or Right `B` Button to Issue 3D Move Waypoint or Strike Vector | Right `A` Button to Escalate `Company -> Battalion -> Brigade` | Left `X` to Cycle Time Scale | Left `Y` to Deploy Robot Dogs / FPVs | Look at **Left Wrist** for live 3D C4ISR Telemetry.\n"
            "- **5-Tier Zoom Hierarchy (`[O]` / `[G]`):** `0.15x` Planetary 3D Orbital Globe (24 LEO Satellites + 7 Clickable Global Flashpoints) -> `0.45x` Continental Curved Space (`8,000x8,000 km`) -> `1.0x` Theater Macro (`2,000x2,000 km`) -> `2.2x–6.5x` Operational Sector (`Battalions + 3D Cities/Airports/Trains`) -> `6.5x–25.0x` Tactical Valley (`Individual Soldiers, Robot Dogs & 4-Ship Wings`).\n"
            "- **Interactive Boot-Camp (`[H]`):** Press `H` at any time to toggle the live 5-Step Interactive Boot-Camp Coach with 3D holographic target beacons.",
        ),
        (
            2,
            "man_command_ai",
            "2. 3-Tier Force Organization (`Company -> Battalion -> Brigade`), Easy Group Selection & Orders",
            "DOCTRINE",
            "- **3-Tier Military Hierarchy:** Every force is organized into **Brigades / Air Wings / Carrier Strike Groups (`[2]` — 36 Companies)** -> **Battalions / Squadrons (`[1]` — 6 Companies)** -> **Companies / Flights / Packs (`[0]`)**.\n"
            "- **Easy Group Selection:**\n"
            "  - **Left-Mouse Box-Drag (Marquee)** on Desktop or **Right-Trigger Sphere Drag** in VR selects all friendly units inside the region (`Shift` adds to selection).\n"
            "  - Press **`[B]` (`[B] BATTALION`)** to select the entire parent Battalion (6 Companies) or **`[V]` (`[V] BRIGADE`)** to select the entire parent Brigade (36 Companies), highlighted with golden 3D selection rings and C2 tether lines.\n"
            "  - Use **`ALL AIR` / `ALL LAND` / `ALL SEA`** buttons or save/recall custom Control Groups with `Ctrl + 1/2/3` and `Alt + 1/2/3`.\n"
            "- **Reliable Order Execution:** Right-Click (or VR Left Trigger / `B`) on terrain to order formation movement (`Shift + Right-Click` chains multi-waypoint dogleg routes), or Right-Click an enemy unit to fire an immediate Strike Salvo and intercept vector. Player orders lock `DIRECT_PLAYER_CONTROL` (`180s` override) so autonomous AI never overwrites your waypoints.\n"
            "- **JOC Staff AI Courses of Action (`[F1]`–`[F3]`):** Execute 1-click Theater COAs (`[F1] JFACC Air Sweep`, `[F2] JFLCC Dog/Mech Vanguard`, `[F3] Joint TOT Salvo`) backed by a C# `.NET 8.0` T+15m Lanchester Monte-Carlo forecast.",
        ),
        (
            3,
            "man_realtime_casualties_ammo",
            "3. True 1:1 Real-Time Physical Speeds, Time Acceleration & Live Casualties/Ammo Telemetry",
            "TELEMETRY",
            "- **True 1:1 Real-Time Speeds (`1x REAL` Default):** All units and munitions move at exact physical speeds (`1 kt = 1.852 km/h = 0.0005144 km/s`, `Mach 1 = 343 m/s = 0.343 km/s`). Use one-click HUD or 3D Console buttons for **`0x PAUSE`**, **`1x REAL`**, **`10x`**, **`60x`**, **`300x`**, and **`900x`** time acceleration (`[T]`, `-`, `=`).\n"
            "- **Live Casualties Ledger (`BLUE` & `RED`):** Tracks real-time **Personnel KIA & WIA** based on authentic platform crew complements (`0` for unmanned Robot Dogs/FPVs/USVs, `4–12` for aircraft flights, `16` for armor/SAMs, `36` for infantry companies, `260` for warships, `2,800` for aircraft carriers), plus platform category losses (`Air`, `Land`, `Sea`, `Drone`, and `$M USD`).\n"
            "- **Live Ammunition Ledger (`BLUE` & `RED`):** Tracks **Remaining Munition Stock (`%`)**, **Expended/Fired Munitions**, **In-Flight Salvos**, and **Successful Intercepts** across both the active theater and all 7 global theaters.",
        ),
        (
            4,
            "man_sensors_6spectrum",
            "4. The 6-Spectrum Sensor Fusion Matrix",
            "SENSORS",
            "1. **Active Radar (`ACTIVE_RADAR`):** Long range (20–420 km), blocked by terrain horizon, scales by $\\text{RCS}^{0.25}$. **Warning:** Enemy Passive ESM detects active radars at $1.6\\times$ range!\n"
            "2. **Passive ESM / ELINT (`PASSIVE_ESM`):** Silent receiver that triangulates enemy radar emitters ($1.6\\times$ range) and `RF_DATALINK` drones even while your own radar is DARK (EMCON).\n"
            "3. **Infrared / IRST (`IR_EO`):** Passive thermal detection (14–65 km, boosted $1.85\\times$ against afterburning jets). Counters radar stealth (*F-35 / J-20*) without triggering RWR!\n"
            "4. **3D LiDAR & Computer Vision (`LIDAR_CV`):** Short-range (5.5 km) obstacle & target recognition used by **Quadruped Robot Dogs** and UGVs in cliffs/cities; immune to stealth and jamming.\n"
            "5. **Acoustic & Sonar (`ACOUSTIC_SONAR`):** Non-Line-of-Sight valley diffraction hears low-flying propeller drones (*Shahed / FPV*) around mountain corners (+450m ridge diffraction); Towed Sonar hunts submerged submarines (*Orca XLUUV*) at sea.\n"
            "6. **Orbital Satellite (`SAT_SAR_EO`):** 24 LEO Recon/SATCOM/PNT/Early-Warning satellites orbiting overhead.",
        ),
        (
            5,
            "man_unmanned_ew_lasers",
            "5. Unmanned Warfare: Robot Dogs, FPV Swarms, EW & Directed Energy",
            "UNMANNED",
            "- **Quadruped Robot Dogs (*Vision 60 / Unitree B2-W*):** Unpacked in `<15km` tactical zoom (`[U]` or `[6]`). Ignore `>25°` cliff slope penalties, have near-zero RCS (`0.0005 m²`), clamber over urban rubble at `0.92x` speed, suffer `0` human KIA when lost, and carry Javelins/FPVs/Laser designators.\n"
            "- **EW Jamming vs. Autonomy:** `RF_DATALINK` drones suffer 85% $P_k$ loss inside *Krasukha-4* EW jammer cones; `FIBER_OPTIC` wired FPVs (12 km) and `AUTONOMOUS_AI` Loyal Wingmen/Robot Dogs are 100% immune to jamming!\n"
            "- **Directed Energy Economy:** Never waste $4.0M *Patriot PAC-3* missiles on $25k *Shahed* drones! Use *Iron Beam 100kW Lasers* ($2/shot) and *Epirus Leonidas HPM Microwaves* (30° EMP cone frying whole swarms).",
        ),
        (
            6,
            "man_9nations_theaters",
            "6. 11-Nation Armed Forces, 1,000,000-Unit Global ORBAT & 7 `2,000x2,000 km` Theaters",
            "THEATERS",
            "- **11-Nation Roster (62 Platforms, 30 Munitions — 92/92 Real Wikipedia Photos):** Authentic systems across `USA`, `EUR_NATO`, `UKR`, `MEX`, `CHN`, `RUS`, `KOR`, `PRK`, `IND`, `PAK`, and `TUR`.\n"
            "- **1,000,000-Unit Multi-Theater Global Order of Battle (`GlobalOrbatSystem`):** Simulates **1,000,000 tactical combat units** (`10,000` Battalion clusters) across all **7 `2,000x2,000 km` Global Theaters of War** simultaneously with authentic historical formation callsigns, aircraft carriers, and bases:\n"
            "  1. `ukraine_donbas_theater` (**240,000 Units** — `UKR + NATO` vs `RUS`): *3rd Assault Bde 'Azov'*, *47th Mech Bde 'Magura'*, *414th Strike UAV Bde 'Madyar's Birds'*, *BTR-4E*, *2S22 Bohdana*, *Neptune* vs *1st Guards Tank Army*, *58th CAA*, *Admiral Gorshkov*.\n"
            "  2. `strait_theater` (**220,000 Units** — `CHN PLA` vs `USA + TWN`): *USS Gerald R. Ford (CVN-78)*, *ROCAF 4th TFW* vs *PLA 71st/72nd/73rd Group Armies* & *CNS Fujian (CV-18)*.\n"
            "  3. `baltic_suwalki_theater` (**160,000 Units** — `EUR_NATO + USA` vs `RUS + BLR`): *Polish 18th 'Iron' Div*, *German 45th Panzer Bde*, *FS Charles de Gaulle (R91)*, *HMS Queen Elizabeth (R08)* vs *11th Army Corps Kaliningrad*.\n"
            "  4. `himalaya_lac_theater` (**150,000 Units** — `IND` vs `CHN + PAK`): *Indian XIV 'Fire and Fury' Corps*, *INS Vikrant (R11)*, *Tejas Mk2*, *Zorawar Light Tank*, *BrahMos* vs *PLA 76th/77th Group Armies* & *PAF No. 15 'Cobras'*.\n"
            "  5. `korean_dmz_theater` (**110,000 Units** — `KOR + USA` vs `PRK`): *ROK VII 'Vanguard' Corps*, *ROKS Jeongjo the Great*, *KF-21 Boramae*, *K2 Black Panther*, *Hyunmoo-5* vs *KPA II Corps* & *105th Ryu Kyong-su Tank Div*.\n"
            "  6. `mexico_rio_grande_theater` (**70,000 Units** — `USA NORTHCOM` vs `MEX SEDENA`): *US III Armored Corps (1st Cavalry Div, Fort Cavazos)* vs *SEDENA 1/a Brigada Blindada*, *FAM Escuadrón Aéreo 401*, *ARM Reformador (POLA-101)*.\n"
            "  7. `hormuz_theater` (**50,000 Units** — `USA 5th Fleet + Coalition` vs `IRN IRGC`): *USS Abraham Lincoln (CVN-72) CSG-3* vs *IRGCN 1st Naval Region (Bandar Abbas)*.",
        ),
        (
            7,
            "man_logistics_infrastructure",
            "7. Living Battlefield Infrastructure, Logistics, Civilian PDE & Space/Cyber/CBRN (`[7]`–`[0]`)",
            "STRATEGIC",
            "- **Living Infrastructure (`128x128` Grid + 3,800+ 3D Buildings):** Hydrological rivers with strategic bridges, highway MSRs (`1.45x` speed), railways with 8 moving 3D military supply trains, 48 real-world metropolitan cities, airfields, and forests (`0.65x` damage cover).\n"
            "- **Dynamic War Destruction:** Heavy strikes crater runways, collapse 3D urban towers into smoking rubble (`+62%` fortification cover for Infantry & Robot Dogs), blow river bridges (`0.16x` ford penalty), and derail supply trains.\n"
            "- **Spreading Civilian Density Field & Multi-Domain Deterrence (`[7]`–`[0]`):** C# `.NET 8.0` parallel Advection-Diffusion PDE models ~397M civilians fleeing combat along road networks; `[7] ASAT`, `[8] CYBER`, `[9] PSYOP`, `[0] CBRN`.",
        ),
    ]
    for ms in manual_sections:
        cur.execute(
            """INSERT INTO manual_sections (section_order, slug, title, category, markdown_body)
               VALUES (?, ?, ?, ?, ?)""",
            ms,
        )

    # 8. Seed 4-Branch x 3-Tier Defense R&D Technology Tree (`tech_tree_nodes`)
    tech_tree_seed = [
        # Branch 1: ROBOTICS_AI (Autonomous AI, Quadruped Robot Dogs & Swarms)
        (
            "tech_quadruped_lidar_v2",
            "Quadruped 4D LiDAR & Cliff-Agile Actuators",
            "ROBOTICS_AI",
            1,
            "",
            250.0,
            "+35% Robot Dog & UGV speed, +25% 3D LiDAR detection range, and +2 Unmanned Bays on friendly Mech/Infantry companies.",
            json.dumps({"dog_speed_mult": 1.35, "lidar_range_mult": 1.25, "bonus_unmanned_bays": 2}),
        ),
        (
            "tech_fiber_optic_swarm_bus",
            "25km Fiber-Optic & Edge-AI Swarm Seeker Bus",
            "ROBOTICS_AI",
            2,
            "tech_quadruped_lidar_v2",
            450.0,
            "+18% FPV & Loitering Swarm Pk, 100% immunity to Krasukha-4 RF jamming, and +3,500 loitering drone munitions delivered.",
            json.dumps({"swarm_pk_bonus": 0.18, "ew_jam_immunity": 1, "instant_ammo_grant": 3500}),
        ),
        (
            "tech_cca_loyal_wingman_net",
            "Autonomous CCA Loyal Wingman Neural Mesh",
            "ROBOTICS_AI",
            3,
            "tech_fiber_optic_swarm_bus",
            850.0,
            "-35% unmanned aircraft RCS, +15% BVR air-to-air Pk, and spawns an autonomous XQ-58A Valkyrie / MQ-28 Ghost Bat flight.",
            json.dumps({"unmanned_rcs_mult": 0.65, "air_pk_bonus": 0.15, "spawn_reinforcement_slug": "xq_58a_valkyrie"}),
        ),
        # Branch 2: DIRECTED_ENERGY (High-Energy Lasers, GaN AESA Radars & HPM Microwaves)
        (
            "tech_solid_state_hel_200kw",
            "200kW Solid-State Fiber Laser Capacitors",
            "DIRECTED_ENERGY",
            1,
            "",
            300.0,
            "2.0x thermal capacitor recharge rate and +30% intercept range for Iron Beam 100kW Lasers & C-UAS batteries.",
            json.dumps({"laser_recharge_mult": 2.0, "laser_range_mult": 1.30}),
        ),
        (
            "tech_gan_aesa_iads",
            "Gallium Nitride (GaN) Ultra-Wideband AESA Radar",
            "DIRECTED_ENERGY",
            2,
            "tech_solid_state_hel_200kw",
            550.0,
            "+25% Active Radar & Passive ESM detection range across the theater, and +15% SAM interceptor hit probability (Pk).",
            json.dumps({"radar_range_mult": 1.25, "sam_intercept_bonus": 0.15}),
        ),
        (
            "tech_wideband_hpm_emp",
            "Wideband HPM Microwave Swarm Neutralizer",
            "DIRECTED_ENERGY",
            3,
            "tech_gan_aesa_iads",
            900.0,
            "+50% Epirus Leonidas HPM EMP cone radius and -25% enemy missile/drone hit probability against all friendly forces.",
            json.dumps({"hpm_radius_mult": 1.50, "enemy_pk_penalty": 0.25}),
        ),
        # Branch 3: HYPERSONIC_STEALTH (Metamaterial Stealth, Scramjets & Prompt Global Strike)
        (
            "tech_metamaterial_ram_coat",
            "Metamaterial Radar Absorbent Coating (RAM)",
            "HYPERSONIC_STEALTH",
            1,
            "",
            350.0,
            "-40% Radar Cross Section (RCS) on all friendly aircraft & warships, shrinking enemy SAM detection rings.",
            json.dumps({"rcs_mult": 0.60}),
        ),
        (
            "tech_scramjet_glide_mach12",
            "Scramjet Thermal Shield & Mach 12+ Glide Vehicles",
            "HYPERSONIC_STEALTH",
            2,
            "tech_metamaterial_ram_coat",
            650.0,
            "+25% speed for all friendly missiles/hypersonics and +20% penetration against enemy SAM interceptors.",
            json.dumps({"missile_speed_mult": 1.25, "missile_penetration_bonus": 0.20}),
        ),
        (
            "tech_prompt_global_salvo",
            "Integrated Prompt Global Hypersonic Salvo",
            "HYPERSONIC_STEALTH",
            3,
            "tech_scramjet_glide_mach12",
            1100.0,
            "+20% warhead damage, +8,000 long-range precision munitions delivered, and spawns an LRHW Dark Eagle Hypersonic battery.",
            json.dumps({"warhead_damage_mult": 1.20, "instant_ammo_grant": 8000, "spawn_reinforcement_slug": "dark_eagle_battery"}),
        ),
        # Branch 4: C4ISR_LOGISTICS (Orbital Starshield, Smart Ammo Factories & Quantum Cyber)
        (
            "tech_leo_proliferated_satcom",
            "Proliferated LEO SAR & Starshield Mesh",
            "C4ISR_LOGISTICS",
            1,
            "",
            280.0,
            "Locks friendly C2 Integrity & GPS/PNT >= 95% (ASAT-resilient) and generates +$40M/min Wartime Defense Appropriation.",
            json.dumps({"c2_floor": 0.95, "income_musd_per_min": 40.0}),
        ),
        (
            "tech_automated_ammo_factories",
            "Automated 3D-Printed Drone & Artillery Smart Factories",
            "C4ISR_LOGISTICS",
            2,
            "tech_leo_proliferated_satcom",
            500.0,
            "Continuously manufactures +2,400 munitions/min into theater stocks, delivers +10,000 rounds now, and adds +$60M/min budget.",
            json.dumps({"auto_ammo_per_min": 2400, "instant_ammo_grant": 10000, "income_musd_per_min": 60.0}),
        ),
        (
            "tech_quantum_cyber_dominance",
            "Quantum Cryptographic C4ISR & Autonomous Cyber CNO",
            "C4ISR_LOGISTICS",
            3,
            "tech_automated_ammo_factories",
            950.0,
            "Doubles Cyber CNO enemy IADS blackout duration, adds +$90M/min Defense Budget income, and repairs all friendly units +25% HP.",
            json.dumps({"cyber_duration_mult": 2.0, "income_musd_per_min": 90.0, "instant_heal_ratio": 0.25}),
        ),
        # Branch 5: NBC_APOCALYPSE (CBRN Warfare, High-Altitude EMP, Orbital Kinetic Rods & Thermonuclear Triad)
        (
            "tech_cbrn_aerosol_mopp5",
            "MOPP-5 Nano-Shield & Tactical CBRN Aerosol Warheads",
            "NBC_APOCALYPSE",
            1,
            "",
            400.0,
            "100% friendly CBRN hazard immunity, unlocks Tactical Chemical/Bio Aerosol Strikes, and 2x hazard plume lethality vs enemy.",
            json.dumps({"cbrn_immunity": 1, "unlock_chem_strike": 1, "hazard_lethality_mult": 2.0, "escalation_delta": 15.0}),
        ),
        (
            "tech_hemp_orbital_emp",
            "High-Altitude EMP (HEMP) & Orbital Kinetic Tungsten Rods",
            "NBC_APOCALYPSE",
            2,
            "tech_cbrn_aerosol_mopp5",
            750.0,
            "Unlocks Theater HEMP Electromagnetic Super-Burst (blinds radars/drones across 350km) and Mach 24 'Rods from God' Orbital Strikes.",
            json.dumps({"unlock_hemp_emp": 1, "unlock_orbital_rods": 1, "escalation_delta": 25.0}),
        ),
        (
            "tech_strategic_nuclear_triad",
            "PEAD-99 Thermonuclear Triad Release (B61-12 / Trident D5 / Sarmat)",
            "NBC_APOCALYPSE",
            3,
            "tech_hemp_orbital_emp",
            1400.0,
            "Escalates to DEFCON 1: Authorizes Tactical & Strategic Thermonuclear Salvos ([N]) with 3D nuclear fireballs, shockwaves & fallout.",
            json.dumps({"unlock_nuclear_triad": 1, "warhead_damage_mult": 1.50, "escalation_delta": 40.0}),
        ),
    ]
    for tn in tech_tree_seed:
        cur.execute(
            """INSERT INTO tech_tree_nodes (slug, display_name, branch_code, tier, prereq_slug, cost_musd, effect_summary, modifiers_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            tn,
        )

    sovereign_nations_seed = [
        # Western Pacific & Taiwan Strait (`strait_theater`)
        ("jpn_self_defense", "Japan (JSDF Ryukyu & Yonaguni Command)", "JPN", "Tokyo", "strait_theater", 45.0, "LEAN_BLUE", 65.0, -230.0, 175.0, 105.0, 28.0, 480.0, "f_35a_lightning", "Mutual Security Treaty Partner; controls Ryukyu airspace corridor & Kadena staging."),
        ("phl_armed_forces", "Republic of the Philippines (EDCA Luzon)", "PHL", "Manila", "strait_theater", 18.0, "NEUTRAL", -35.0, 115.0, 195.0, 115.0, 14.0, 320.0, "brahmos_coastal_battery", "Controls Bashi Channel southern naval/airspace approach & Luzon EDCA airbases."),
        ("aus_adf_indopac", "Commonwealth of Australia (ADF RAAF/RAN)", "AUS", "Canberra", "strait_theater", 55.0, "LEAN_BLUE", 105.0, 110.0, 130.0, 120.0, 24.0, 450.0, "mq_28_ghost_bat", "AUKUS partner; provides Ghost Bat CCA wings, submarine patrols & coalition defence funds."),
        ("rus_pacific_fleet", "Russian Federation (Pacific Fleet & VKS East)", "RUS", "Vladivostok", "strait_theater", -48.0, "LEAN_RED", -240.0, -235.0, 145.0, 115.0, 26.0, 460.0, "tu_22m3_backfire", "Strategic Eurasian partner; grants northern bomber overflight corridor & Zircon naval support."),
        # Korean Peninsula (`korea_dmz_theater`)
        ("chn_northern_pla", "People's Republic of China (Northern Theater PLA)", "CHN", "Beijing", "korea_dmz_theater", -44.0, "LEAN_RED", -240.0, -235.0, 165.0, 125.0, 38.0, 620.0, "j_20_mighty_dragon", "Yalu River sovereign airspace buffer; major economic & stealth air-superiority backstop."),
        ("jpn_korea_liaison", "Japan Maritime & Air SDF (Tsushima Strait)", "JPN", "Tokyo", "korea_dmz_theater", 42.0, "LEAN_BLUE", 90.0, 85.0, 145.0, 145.0, 26.0, 450.0, "ddg_51_arleigh_burke", "Controls Korea Strait rear logistics lane, Aegis BMD umbrella & allied warchest credit."),
        ("rus_primorsky_pact", "Russian Federation (Primorsky Krai Corridor)", "RUS", "Moscow", "korea_dmz_theater", -40.0, "LEAN_RED", 70.0, -235.0, 165.0, 115.0, 22.0, 410.0, "s_400_triumf", "Tumen River rail/airspace corridor supplying artillery, S-400 SAMs & petroleum aid."),
        # Eastern Europe, Suwalki & Ukraine-Donbas (`baltic_suwalki_theater`)
        ("pol_armed_forces", "Republic of Poland (Eastern Shield & Rzeszow Hub)", "POL", "Warsaw", "baltic_suwalki_theater", 54.0, "LEAN_BLUE", -240.0, 10.0, 145.0, 200.0, 25.0, 440.0, "leopard_2a8_platoon", "Primary NATO logistics airbridge, armored staging corridor & sovereign SAM umbrella."),
        ("blr_union_state", "Republic of Belarus (Union State Northern Axis)", "BLR", "Minsk", "baltic_suwalki_theater", -50.0, "LEAN_RED", 30.0, -100.0, 200.0, 140.0, 18.0, 350.0, "s_400_triumf", "Northern strategic airspace & highway staging axis for deep strike and missile salvos."),
        ("fin_swe_nordic", "Nordic Defense Pact (Finland & Sweden Joint Air)", "FIN", "Helsinki", "baltic_suwalki_theater", 26.0, "NEUTRAL", -195.0, -235.0, 215.0, 110.0, 22.0, 420.0, "rafale_f4_flight", "Controls Baltic Sea northern airspace, Gotland radar coverage & high-tech warchest grants."),
        ("irn_drone_syndicate", "Islamic Republic of Iran (Caspian Drone Corridor)", "IRN", "Tehran", "baltic_suwalki_theater", -45.0, "LEAN_RED", 90.0, 90.0, 145.0, 140.0, 20.0, 390.0, "shahed_136_launcher", "Supplies OWA drone swarms, ballistic munitions & Caspian airspace transit corridor."),
        # Himalayan LAC (`himalaya_lac_theater`)
        ("pak_strategic_command", "Islamic Republic of Pakistan (Northern Air Command)", "PAK", "Islamabad", "himalaya_lac_theater", -46.0, "LEAN_RED", -240.0, -190.0, 135.0, 195.0, 19.0, 360.0, "jf_17_block3_flight", "Western Karakoram two-front airspace corridor, JF-17 Block III flights & Akinci UCAVs."),
        ("kaz_central_asia", "Republic of Kazakhstan & Central Asian Union", "KAZ", "Astana", "himalaya_lac_theater", -8.0, "NEUTRAL", -95.0, -235.0, 210.0, 105.0, 16.0, 340.0, "t_90m_platoon", "Resource-rich neutral buffer controlling northern continental overflight & energy revenues."),
        ("fra_indopac_taskforce", "French Republic & Quad Liaison (Indo-Pacific)", "FRA", "Paris", "himalaya_lac_theater", 35.0, "LEAN_BLUE", -225.0, 85.0, 165.0, 140.0, 24.0, 430.0, "rafale_f4_flight", "Provides Rafale F4 Meteor air wings, satellite intelligence & European coalition funding."),
        ("mmr_southern_corridor", "Union of Myanmar (Irrawaddy Corridor)", "MMR", "Naypyidaw", "himalaya_lac_theater", -18.0, "NEUTRAL", 95.0, 80.0, 140.0, 150.0, 13.0, 290.0, "unitree_b2w_armed", "Southeastern mountain & Bay of Bengal access corridor for flanking operations."),
        # North American Rio Grande & Gulf (`mexico_rio_grande_theater`)
        ("can_norad_command", "Canada (NORAD Continental Defense Command)", "CAN", "Ottawa", "mexico_rio_grande_theater", 58.0, "LEAN_BLUE", -225.0, -235.0, 295.0, 95.0, 28.0, 490.0, "f_35a_lightning", "Integrated NORAD aerospace defense shield, Arctic overflight & allied treasury support."),
        ("ven_caribbean_pact", "Bolivarian Republic of Venezuela & Caribbean Pact", "VEN", "Caracas", "mexico_rio_grande_theater", -45.0, "LEAN_RED", 75.0, 95.0, 160.0, 140.0, 20.0, 380.0, "su_57_felon", "Southern Gulf & Caribbean maritime/airspace staging corridor with oil-backed warchest aid."),
        ("col_andean_shield", "Republic of Colombia (Andean Security Coalition)", "COL", "Bogota", "mexico_rio_grande_theater", 22.0, "NEUTRAL", -225.0, 115.0, 175.0, 120.0, 15.0, 310.0, "specops_mountain_team", "Southern air interdiction partner controlling Pacific-Caribbean transit lanes."),
    ]
    for sn in sovereign_nations_seed:
        cur.execute(
            """INSERT INTO sovereign_nations (
                   slug, country_name, iso_code, capital_name, theater_slug,
                   initial_alignment, initial_status, airspace_x_min_km, airspace_z_min_km,
                   airspace_width_km, airspace_depth_km, aid_musd_per_min, grant_package_musd,
                   expeditionary_platform_slug, diplomatic_profile
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            sn,
        )

    conn.commit()

    # Export JSON mirror for instant SimDB loading in Godot 4.7
    conn.row_factory = sqlite3.Row
    rcur = conn.cursor()
    cache_payload = {}
    for table in (
        "platforms",
        "sensors",
        "weapons",
        "platform_sensors",
        "platform_loadouts",
        "formation_templates",
        "theaters",
        "theater_sites",
        "scenarios",
        "tutorial_steps",
        "manual_sections",
        "tech_tree_nodes",
        "sovereign_nations",
    ):
        rcur.execute(f"SELECT * FROM {table}")
        cache_payload[table] = [dict(row) for row in rcur.fetchall()]

    CACHE_JSON_PATH.write_text(json.dumps(cache_payload, indent=2), encoding="utf-8")

    # Auto-Generate Living Player & Developer Documentation: docs/GAME_MANUAL.md
    docs_dir = ROOT_DIR / "docs"
    docs_dir.mkdir(parents=True, exist_ok=True)
    manual_md_path = docs_dir / "GAME_MANUAL.md"

    md_lines = [
        "# Commander's Tactical Field Manual & Encyclopedia (Auto-Synced from `wargame.db`)",
        "",
        "> **Living Documentation Guarantee:** This manual and the in-game **Field Manual & 5-Step Boot-Camp Tutorial** are generated directly from `data/wargame.db` via `tools/wiki_pipeline/seed_wargame_db.py` so documentation, tutorials, and unit stats never drift out of sync.",
        "",
        "---",
        "",
        "## Part I: Core Doctrine & Controls",
        "",
    ]
    for ms in cache_payload["manual_sections"]:
        md_lines.append(f"### {ms['title']}")
        md_lines.append(ms["markdown_body"])
        md_lines.append("")

    md_lines.extend([
        "---",
        "",
        "## Part II: Interactive 5-Step Bunker Boot-Camp Tutorial",
        "",
        "| Step | Lesson Title | Instructor | Action / Target | Tactical Takeaway |",
        "| :--- | :--- | :--- | :--- | :--- |",
    ])
    for ts in cache_payload["tutorial_steps"]:
        md_lines.append(
            f"| **{ts['step_order']}** | **{ts['title']}** | `{ts['instructor_callsign']}` | `{ts['ui_highlight_target']}` | {ts['reward_tip']} |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        f"## Part III: 11-Nation Platforms, Aircraft Carriers, Robot Dogs & Unmanned Roster ({len(cache_payload['platforms'])} Systems)",
        "",
        "| Faction | Platform | Domain / Class | Speed (kts) | Radius (km) | RCS ($m^2$) | Autonomy | Cost ($M) | Photo Asset |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
    ])
    for p in cache_payload["platforms"]:
        md_lines.append(
            f"| `{p['country_origin']}` | **{p['display_name']}** | `{p['domain']}/{p['unit_class']}` | {p['max_speed_knots']:.0f} | {p['combat_radius_km']:.0f} | `{p['rcs_m2']}` | `{p['autonomy_level']}` | **${p['unit_cost_musd']:.2f}M** | `{p['image_res_path']}` |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        f"## Part IV: Authentic Wikipedia Weapons & Directed-Energy Munitions ({len(cache_payload['weapons'])} Munitions)",
        "",
        "| Weapon / Munition | Guidance | Max Range (km) | Speed (Mach) | Base $P_k$ | Cost per Shot ($M) | Photo Asset |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
    ])
    for w in cache_payload["weapons"]:
        md_lines.append(
            f"| **{w['display_name']}** | `{w['guidance_type']}` | {w['max_range_km']:.1f} km | Mach {w['speed_mach']:.2f} | {w['base_pk']*100:.0f}% | **${w['round_cost_musd']:.6f}M** | `{w['image_res_path']}` |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        f"## Part V: 7 Global `2,000 × 2,000 km` Theaters & {len(cache_payload['scenarios'])} Operations (1,000,000 Total Units)",
        "",
        "| Operation Slug | Operation Name | Theater (`2,000x2,000 km`) | Era / Doctrine | Blue / Red Budget ($M) |",
        "| :--- | :--- | :--- | :--- | :--- |",
    ])
    for sc in cache_payload["scenarios"]:
        md_lines.append(
            f"| `{sc['slug']}` | **{sc['display_name']}** | `{sc['theater_slug']}` | {sc['era_label']} | **${sc['blue_budget_musd']:.0f}M / ${sc['red_budget_musd']:.0f}M** |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        f"## Part VI: 4-Branch Defense R&D Technology Tree ({len(cache_payload['tech_tree_nodes'])} Technologies)",
        "",
        "| Branch | Tier | Technology Name | Prerequisite | R&D Cost ($M) | Strategic & Tactical Modifiers |",
        "| :--- | :--- | :--- | :--- | :--- | :--- |",
    ])
    for tn in cache_payload["tech_tree_nodes"]:
        prereq_str = f"`{tn['prereq_slug']}`" if tn["prereq_slug"] else "*None (Tier 1)*"
        md_lines.append(
            f"| `{tn['branch_code']}` | **Tier {tn['tier']}** | **{tn['display_name']}** (`{tn['slug']}`) | {prereq_str} | **${tn['cost_musd']:.0f}M** | {tn['effect_summary']} |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        f"## Part VII: Sovereign Nations, Airspace Corridors & AI Diplomacy Matrix ({len(cache_payload['sovereign_nations'])} Seeded Nations + Procedural AI States)",
        "",
        "| ISO | Sovereign Nation | Theater | Initial Alignment | Aid ($M/min) | Grant ($M) | Expeditionary Force | Geopolitical Profile |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
    ])
    for sn in cache_payload["sovereign_nations"]:
        md_lines.append(
            f"| `{sn['iso_code']}` | **{sn['country_name']}** (`{sn['slug']}`) | `{sn['theater_slug']}` | `{sn['initial_status']}` ({sn['initial_alignment']:+.0f}) | **+${sn['aid_musd_per_min']:.0f}M/min** | **+${sn['grant_package_musd']:.0f}M** | `{sn['expeditionary_platform_slug']}` | {sn['diplomatic_profile']} |"
        )

    manual_md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
    conn.close()

    print("\n==================================================================")
    print(f"SQLite Database built at: {DB_PATH}")
    print(f"JSON Mirror Cache built at: {CACHE_JSON_PATH}")
    print(f"Living Game Manual generated at: {manual_md_path}")
    print(f"Real Wikipedia Weapon Photos downloaded:   {real_weapon_photos}/{len(WEAPONS_SEED)}")
    print(f"Real Wikipedia Platform Photos downloaded: {real_platform_photos}/{len(PLATFORMS_SEED)}")
    print("==================================================================")


if __name__ == "__main__":
    build_database()

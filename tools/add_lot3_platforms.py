#!/usr/bin/env python3
import json
import sqlite3
import struct
import zlib
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "data"
DB_PATH = DATA_DIR / "wargame.db"
CACHE_JSON_PATH = DATA_DIR / "wargame_cache.json"
IMG_PLATFORMS_DIR = ROOT_DIR / "assets" / "wiki_images" / "platforms"
IMG_WEAPONS_DIR = ROOT_DIR / "assets" / "wiki_images" / "weapons"


def create_fallback_png(filepath: Path, r: int, g: int, b: int, width: int = 256, height: int = 160) -> None:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    raw_rows = bytearray()
    for y in range(height):
        raw_rows.append(0)
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


def main():
    cache = json.loads(CACHE_JSON_PATH.read_text(encoding="utf-8"))
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    new_weapons = [
        {
            "weapon_id": 32,
            "slug": "agm_114_hellfire",
            "display_name": "AGM-114 Hellfire ATGM",
            "wiki_page_title": "AGM-114 Hellfire",
            "wiki_url": "https://en.wikipedia.org/wiki/AGM-114_Hellfire",
            "wiki_summary": "The AGM-114 Hellfire is an American air-to-surface missile first developed for anti-armor use and precision strikes.",
            "image_res_path": "res://assets/wiki_images/weapons/agm_114_hellfire.png",
            "target_domain_mask": 2,
            "guidance_type": "SEMI_ACTIVE_LASER",
            "max_range_km": 11.0,
            "no_escape_range_km": 7.0,
            "min_range_km": 0.5,
            "speed_mach": 1.3,
            "flight_profile": "DIRECT_FIRE",
            "base_pk": 0.88,
            "warhead_damage": 95.0,
            "is_interceptable": 1,
            "round_cost_musd": 0.15,
        },
        {
            "weapon_id": 33,
            "slug": "m230_30mm_chain_gun",
            "display_name": "M230 30mm Automatic Chain Gun",
            "wiki_page_title": "M230 chain gun",
            "wiki_url": "https://en.wikipedia.org/wiki/M230_chain_gun",
            "wiki_summary": "The M230 Chain Gun is a 30 mm automatic autocannon mounted on the AH-64 Apache attack helicopter.",
            "image_res_path": "res://assets/wiki_images/weapons/m230_30mm_chain_gun.png",
            "target_domain_mask": 2,
            "guidance_type": "UNGUIDED",
            "max_range_km": 3.5,
            "no_escape_range_km": 1.5,
            "min_range_km": 0.1,
            "speed_mach": 2.4,
            "flight_profile": "DIRECT_FIRE",
            "base_pk": 0.65,
            "warhead_damage": 35.0,
            "is_interceptable": 0,
            "round_cost_musd": 0.01,
        },
        {
            "weapon_id": 34,
            "slug": "9k121_vikhr_atgm",
            "display_name": "9K121 Vikhr Laser-Guided ATGM",
            "wiki_page_title": "9K121 Vikhr",
            "wiki_url": "https://en.wikipedia.org/wiki/9K121_Vikhr",
            "wiki_summary": "The 9K121 Vikhr is a Russian laser beam-riding anti-tank missile deployed from the Ka-52 Alligator attack helicopter.",
            "image_res_path": "res://assets/wiki_images/weapons/9k121_vikhr_atgm.png",
            "target_domain_mask": 2,
            "guidance_type": "LASER_BEAM_RIDER",
            "max_range_km": 12.0,
            "no_escape_range_km": 8.0,
            "min_range_km": 0.5,
            "speed_mach": 1.8,
            "flight_profile": "DIRECT_FIRE",
            "base_pk": 0.85,
            "warhead_damage": 95.0,
            "is_interceptable": 1,
            "round_cost_musd": 0.12,
        },
        {
            "weapon_id": 35,
            "slug": "cannon_2a42_30mm",
            "display_name": "2A42 30mm Dual-Feed Autocannon",
            "wiki_page_title": "2A42 autocannon",
            "wiki_url": "https://en.wikipedia.org/wiki/2A42",
            "wiki_summary": "The 2A42 is a 30 mm automatic autocannon developed in the Soviet Union and used on the Ka-52 Alligator.",
            "image_res_path": "res://assets/wiki_images/weapons/cannon_2a42_30mm.png",
            "target_domain_mask": 2,
            "guidance_type": "UNGUIDED",
            "max_range_km": 4.0,
            "no_escape_range_km": 2.0,
            "min_range_km": 0.1,
            "speed_mach": 2.8,
            "flight_profile": "DIRECT_FIRE",
            "base_pk": 0.65,
            "warhead_damage": 40.0,
            "is_interceptable": 0,
            "round_cost_musd": 0.01,
        },
        {
            "weapon_id": 36,
            "slug": "trident_ii_d5_slbm",
            "display_name": "UGM-133A Trident II D5 LE SLBM",
            "wiki_page_title": "UGM-133 Trident II",
            "wiki_url": "https://en.wikipedia.org/wiki/UGM-133_Trident_II",
            "wiki_summary": "The UGM-133A Trident II is an American submarine-launched ballistic missile (SLBM) with multiple independently targetable reentry vehicles.",
            "image_res_path": "res://assets/wiki_images/weapons/trident_ii_d5_slbm.png",
            "target_domain_mask": 2,
            "guidance_type": "ASTRO_INERTIAL",
            "max_range_km": 12000.0,
            "no_escape_range_km": 8000.0,
            "min_range_km": 100.0,
            "speed_mach": 24.0,
            "flight_profile": "LOFTED_BALLISTIC",
            "base_pk": 0.99,
            "warhead_damage": 1000.0,
            "is_interceptable": 1,
            "round_cost_musd": 31.0,
        },
        {
            "weapon_id": 37,
            "slug": "jl_3_slbm",
            "display_name": "JL-3 Intercontinental SLBM",
            "wiki_page_title": "JL-3",
            "wiki_url": "https://en.wikipedia.org/wiki/JL-3",
            "wiki_summary": "The Julang-3 is a third-generation Chinese intercontinental submarine-launched ballistic missile deployed aboard Type 094 SSBNs.",
            "image_res_path": "res://assets/wiki_images/weapons/jl_3_slbm.png",
            "target_domain_mask": 2,
            "guidance_type": "ASTRO_INERTIAL",
            "max_range_km": 10000.0,
            "no_escape_range_km": 6500.0,
            "min_range_km": 100.0,
            "speed_mach": 20.0,
            "flight_profile": "LOFTED_BALLISTIC",
            "base_pk": 0.98,
            "warhead_damage": 900.0,
            "is_interceptable": 1,
            "round_cost_musd": 25.0,
        },
        {
            "weapon_id": 38,
            "slug": "yu_6_torpedo",
            "display_name": "Yu-6 Heavyweight Torpedo",
            "wiki_page_title": "Yu-6 torpedo",
            "wiki_url": "https://en.wikipedia.org/wiki/Yu-6_torpedo",
            "wiki_summary": "The Yu-6 is a Chinese thermal-powered wire-guided heavyweight torpedo used by nuclear submarines.",
            "image_res_path": "res://assets/wiki_images/weapons/yu_6_torpedo.png",
            "target_domain_mask": 4,
            "guidance_type": "WIRE_ACOUSTIC",
            "max_range_km": 45.0,
            "no_escape_range_km": 25.0,
            "min_range_km": 0.5,
            "speed_mach": 0.15,
            "flight_profile": "DIRECT_FIRE",
            "base_pk": 0.85,
            "warhead_damage": 280.0,
            "is_interceptable": 1,
            "round_cost_musd": 1.8,
        },
    ]

    new_platforms = [
        {
            "platform_id": 68,
            "slug": "ah_64e_apache_guardian",
            "display_name": "AH-64E Apache Guardian Flight",
            "wiki_page_title": "Boeing AH-64 Apache",
            "wiki_url": "https://en.wikipedia.org/wiki/Boeing_AH-64_Apache",
            "wiki_summary": "The Boeing AH-64 Apache is an American twin-turboshaft attack helicopter with tandem cockpit, armed with AGM-114 Hellfire missiles and 30mm M230 chain gun.",
            "image_res_path": "res://assets/wiki_images/platforms/ah_64e_apache_guardian.png",
            "country_origin": "USA",
            "service_year": 2026,
            "domain": "AIR",
            "unit_class": "HELICOPTER",
            "nato_symbol_code": "AIR_HELICOPTER",
            "max_speed_knots": 165.0,
            "cruise_speed_knots": 140.0,
            "combat_radius_km": 480.0,
            "max_altitude_m": 6000.0,
            "operational_altitude_m": 120.0,
            "rcs_m2": 3.5,
            "ir_signature": 0.85,
            "armor_rating": 15.0,
            "max_hp": 120.0,
            "elements_per_token": 4,
            "unit_cost_musd": 38.0,
            "autonomy_level": "MANNED",
            "can_climb_steep_slopes": 0,
            "carrier_sub_platform_slug": "",
            "carrier_sub_count": 0,
            "directed_energy_kw": 0.0,
            "de_aoe_cone_deg": 0.0,
        },
        {
            "platform_id": 69,
            "slug": "ka_52_alligator",
            "display_name": "Ka-52 Alligator Attack Helicopter Flight",
            "wiki_page_title": "Kamov Ka-50",
            "wiki_url": "https://en.wikipedia.org/wiki/Kamov_Ka-50",
            "wiki_summary": "The Kamov Ka-52 'Alligator' is a Russian attack helicopter featuring coaxial contra-rotating rotors, armed with 9K121 Vikhr ATGMs, 30mm 2A42 cannon, and Vitebsk DIRCM defense.",
            "image_res_path": "res://assets/wiki_images/platforms/ka_52_alligator.png",
            "country_origin": "RUS",
            "service_year": 2026,
            "domain": "AIR",
            "unit_class": "HELICOPTER",
            "nato_symbol_code": "AIR_HELICOPTER",
            "max_speed_knots": 170.0,
            "cruise_speed_knots": 145.0,
            "combat_radius_km": 460.0,
            "max_altitude_m": 5500.0,
            "operational_altitude_m": 120.0,
            "rcs_m2": 4.0,
            "ir_signature": 0.90,
            "armor_rating": 18.0,
            "max_hp": 130.0,
            "elements_per_token": 4,
            "unit_cost_musd": 32.0,
            "autonomy_level": "MANNED",
            "can_climb_steep_slopes": 0,
            "carrier_sub_platform_slug": "",
            "carrier_sub_count": 0,
            "directed_energy_kw": 0.0,
            "de_aoe_cone_deg": 0.0,
        },
        {
            "platform_id": 70,
            "slug": "columbia_class_ssbn",
            "display_name": "Columbia-Class Ballistic Missile Submarine",
            "wiki_page_title": "Columbia-class submarine",
            "wiki_url": "https://en.wikipedia.org/wiki/Columbia-class_submarine",
            "wiki_summary": "The Columbia-class submarine is an American nuclear-powered ballistic missile submarine (SSBN) with electric drive, anechoic sound-dampening coatings, Trident II D5 LE SLBMs, and Mk 48 ADCAP torpedoes.",
            "image_res_path": "res://assets/wiki_images/platforms/columbia_class_ssbn.png",
            "country_origin": "USA",
            "service_year": 2028,
            "domain": "SEA",
            "unit_class": "SSBN",
            "nato_symbol_code": "SEA_SUB_BALLISTIC",
            "max_speed_knots": 22.0,
            "cruise_speed_knots": 20.0,
            "combat_radius_km": 18000.0,
            "max_altitude_m": -180.0,
            "operational_altitude_m": -180.0,
            "rcs_m2": 0.01,
            "ir_signature": 0.1,
            "armor_rating": 35.0,
            "max_hp": 600.0,
            "elements_per_token": 1,
            "unit_cost_musd": 3800.0,
            "autonomy_level": "MANNED",
            "can_climb_steep_slopes": 0,
            "carrier_sub_platform_slug": "",
            "carrier_sub_count": 0,
            "directed_energy_kw": 0.0,
            "de_aoe_cone_deg": 0.0,
        },
        {
            "platform_id": 71,
            "slug": "type_094_jin_ssbn",
            "display_name": "Type 094 Jin-Class Ballistic Submarine",
            "wiki_page_title": "Type 094 submarine",
            "wiki_url": "https://en.wikipedia.org/wiki/Type_094_submarine",
            "wiki_summary": "The Type 094 (Jin-class) is a Chinese nuclear-powered ballistic missile submarine equipped with 12 JL-3 submarine-launched ballistic missiles and Yu-6 heavyweight torpedoes.",
            "image_res_path": "res://assets/wiki_images/platforms/type_094_jin_ssbn.png",
            "country_origin": "CHN",
            "service_year": 2027,
            "domain": "SEA",
            "unit_class": "SSBN",
            "nato_symbol_code": "SEA_SUB_BALLISTIC",
            "max_speed_knots": 20.0,
            "cruise_speed_knots": 18.0,
            "combat_radius_km": 15000.0,
            "max_altitude_m": -150.0,
            "operational_altitude_m": -150.0,
            "rcs_m2": 0.02,
            "ir_signature": 0.1,
            "armor_rating": 30.0,
            "max_hp": 550.0,
            "elements_per_token": 1,
            "unit_cost_musd": 1800.0,
            "autonomy_level": "MANNED",
            "can_climb_steep_slopes": 0,
            "carrier_sub_platform_slug": "",
            "carrier_sub_count": 0,
            "directed_energy_kw": 0.0,
            "de_aoe_cone_deg": 0.0,
        },
    ]

    new_loadouts = [
        {"loadout_id": 68, "platform_id": 68, "role_code": "STANDARD", "display_name": "Hellfire + Chain Gun", "weapon_1_id": 32, "weapon_1_qty": 16, "weapon_2_id": 33, "weapon_2_qty": 1200},
        {"loadout_id": 69, "platform_id": 69, "role_code": "STANDARD", "display_name": "Vikhr + 30mm Cannon", "weapon_1_id": 34, "weapon_1_qty": 12, "weapon_2_id": 35, "weapon_2_qty": 460},
        {"loadout_id": 70, "platform_id": 70, "role_code": "STANDARD", "display_name": "Trident II D5 + Mk 48", "weapon_1_id": 36, "weapon_1_qty": 16, "weapon_2_id": 27, "weapon_2_qty": 16},
        {"loadout_id": 71, "platform_id": 71, "role_code": "STANDARD", "display_name": "JL-3 SLBM + Yu-6 Torpedo", "weapon_1_id": 37, "weapon_1_qty": 12, "weapon_2_id": 38, "weapon_2_qty": 16},
    ]

    new_sensors = [
        {"platform_id": 68, "sensor_id": 10}, # electro_optical_flir_hd
        {"platform_id": 69, "sensor_id": 10}, # electro_optical_flir_hd
        {"platform_id": 70, "sensor_id": 13}, # towed_sonar_array
        {"platform_id": 71, "sensor_id": 13}, # towed_sonar_array
    ]

    # Insert into SQLite
    for w in new_weapons:
        cur.execute(
            """INSERT OR REPLACE INTO weapons (
                weapon_id, slug, display_name, wiki_page_title, wiki_url, wiki_summary,
                image_res_path, target_domain_mask, guidance_type, max_range_km,
                no_escape_range_km, min_range_km, speed_mach, flight_profile, base_pk,
                warhead_damage, is_interceptable, round_cost_musd
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                w["weapon_id"], w["slug"], w["display_name"], w["wiki_page_title"], w["wiki_url"],
                w["wiki_summary"], w["image_res_path"], w["target_domain_mask"], w["guidance_type"],
                w["max_range_km"], w["no_escape_range_km"], w["min_range_km"], w["speed_mach"],
                w["flight_profile"], w["base_pk"], w["warhead_damage"], w["is_interceptable"],
                w["round_cost_musd"],
            ),
        )

    for p in new_platforms:
        cur.execute(
            """INSERT OR REPLACE INTO platforms (
                platform_id, slug, display_name, wiki_page_title, wiki_url, wiki_summary,
                image_res_path, country_origin, service_year, domain, unit_class, nato_symbol_code,
                max_speed_knots, cruise_speed_knots, combat_radius_km, max_altitude_m, rcs_m2,
                ir_signature, armor_rating, max_hp, elements_per_token, unit_cost_musd,
                autonomy_level, can_climb_steep_slopes, carrier_sub_platform_slug, carrier_sub_count,
                directed_energy_kw, de_aoe_cone_deg
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                p["platform_id"], p["slug"], p["display_name"], p["wiki_page_title"], p["wiki_url"],
                p["wiki_summary"], p["image_res_path"], p["country_origin"], p["service_year"],
                p["domain"], p["unit_class"], p["nato_symbol_code"], p["max_speed_knots"],
                p["cruise_speed_knots"], p["combat_radius_km"], p["max_altitude_m"], p["rcs_m2"],
                p["ir_signature"], p["armor_rating"], p["max_hp"], p["elements_per_token"],
                p["unit_cost_musd"], p["autonomy_level"], p["can_climb_steep_slopes"],
                p["carrier_sub_platform_slug"], p["carrier_sub_count"], p["directed_energy_kw"],
                p["de_aoe_cone_deg"],
            ),
        )

    for l in new_loadouts:
        cur.execute(
            """INSERT OR REPLACE INTO platform_loadouts (
                loadout_id, platform_id, role_code, display_name, weapon_1_id, weapon_1_qty, weapon_2_id, weapon_2_qty
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (l["loadout_id"], l["platform_id"], l["role_code"], l["display_name"], l["weapon_1_id"], l["weapon_1_qty"], l["weapon_2_id"], l["weapon_2_qty"])
        )

    for ps in new_sensors:
        cur.execute("DELETE FROM platform_sensors WHERE platform_id = ? AND sensor_id = ?", (ps["platform_id"], ps["sensor_id"]))
        cur.execute("INSERT INTO platform_sensors (platform_id, sensor_id) VALUES (?, ?)", (ps["platform_id"], ps["sensor_id"]))

    con.commit()
    con.close()
    print("SQLite wargame.db updated successfully.")

    # Update cache JSON
    # Update weapons
    existing_weap_ids = {w["weapon_id"]: i for i, w in enumerate(cache["weapons"])}
    for nw in new_weapons:
        if nw["weapon_id"] in existing_weap_ids:
            cache["weapons"][existing_weap_ids[nw["weapon_id"]]] = nw
        else:
            cache["weapons"].append(nw)

    # Update platforms
    existing_plat_ids = {p["platform_id"]: i for i, p in enumerate(cache["platforms"])}
    for np in new_platforms:
        if np["platform_id"] in existing_plat_ids:
            cache["platforms"][existing_plat_ids[np["platform_id"]]] = np
        else:
            cache["platforms"].append(np)

    # Update loadouts
    if "platform_loadouts" not in cache:
        cache["platform_loadouts"] = []
    existing_loadout_ids = {l["loadout_id"]: i for i, l in enumerate(cache["platform_loadouts"])}
    for nl in new_loadouts:
        if nl["loadout_id"] in existing_loadout_ids:
            cache["platform_loadouts"][existing_loadout_ids[nl["loadout_id"]]] = nl
        else:
            cache["platform_loadouts"].append(nl)

    # Update sensors
    if "platform_sensors" not in cache:
        cache["platform_sensors"] = []
    for ns in new_sensors:
        if not any(s["platform_id"] == ns["platform_id"] and s["sensor_id"] == ns["sensor_id"] for s in cache["platform_sensors"]):
            cache["platform_sensors"].append(ns)

    CACHE_JSON_PATH.write_text(json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8")
    print("wargame_cache.json updated successfully.")

    # Create fallback PNG cards for platforms & weapons
    for p in new_platforms:
        img_path = ROOT_DIR / p["image_res_path"].replace("res://", "")
        if not img_path.exists():
            create_fallback_png(img_path, 30, 160, 210)
            print(f"Created fallback image: {img_path}")

    for w in new_weapons:
        img_path = ROOT_DIR / w["image_res_path"].replace("res://", "")
        if not img_path.exists():
            create_fallback_png(img_path, 210, 80, 40)
            print(f"Created fallback image: {img_path}")


if __name__ == "__main__":
    main()

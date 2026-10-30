#!/usr/bin/env python3
"""
Real-World GIS Geopolitical & Topographic World Map Pipeline (`data/theaters/world_political_map.png`).

Data Sources Integrated (100% Real-World GIS Data, Zero Paid Key Required by Default):
  1. Natural Earth Admin-0 Sovereign Countries GeoJSON (`ne_110m_admin_0_countries.geojson`)
     Automatically fetched from the public Natural Earth repository and cached locally in
     `data/theaters/ne_110m_admin_0_countries.geojson`.
  2. Real-World Global SRTM / ETOPO Elevation & Bathymetry Tiles (`1024x1024` Web Mercator z=2):
     - If `MAPBOX_ACCESS_TOKEN` is set in environment: fetches Mapbox Terrain-RGB (`mapbox.terrain-rgb`)
       using `elevation_m = -10000 + (R * 65536 + G * 256 + B) * 0.1`.
     - By default (keyless): fetches AWS Open Data / Mapzen Terrarium DEM Tiles
       (`https://s3.amazonaws.com/elevation-tiles-prod/terrarium/2/{x}/{y}.png`)
       using `elevation_m = (R * 256 + G + B / 256) - 32768`, cached in `data/theaters/dem_cache/`.

RGBA Channel Encoding (`1440x720` Equirectangular Projection, 0.25 deg/pixel):
  R = Real SRTM/ETOPO Elevation & Bathymetry (0.00..0.35 Ocean Bathymetry, 0.36..1.00 Land Elevation)
  G = Anti-Aliased International Country Borders & Coastlines (0.00..1.00)
  B = Sovereign Geopolitical Alignment ID:
        0.00 = Ocean / High Seas
        0.25 = NATO / US / Allied Democracies (USA, Canada, EU/NATO, UK, SKorea, Japan, Taiwan, Aus/NZ, Philippines)
        0.40 = Neutral / Non-Aligned / Frontline Buffer (Ukraine, Switzerland, Austria, Mongolia, Ireland, etc.)
        0.55 = Regional / Multi-Polar Powers (India, Pakistan, GCC/Saudi/UAE/Oman, ASEAN, LatAm, African Union)
        0.85 = OPFOR / Red Bloc (Russia, China, North Korea, Iran, Belarus)
  A = Major World Capitals & C4ISR Strategic Megacity Nodes (0.00..1.00)
"""

import json
import math
import os
import struct
import urllib.request
import zlib
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
THEATERS_DIR = ROOT_DIR / "data" / "theaters"
DEM_CACHE_DIR = THEATERS_DIR / "dem_cache"
GEOJSON_CACHE_PATH = THEATERS_DIR / "ne_110m_admin_0_countries.geojson"
OUT_PATH = THEATERS_DIR / "world_political_map.png"

NATURAL_EARTH_URL = (
    "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/"
    "geojson/ne_110m_admin_0_countries.geojson"
)

# ISO-A3 & Country Name -> Geopolitical Alignment Code
NATO_AND_ALLIES = {
    "USA", "CAN", "GBR", "FRA", "DEU", "ITA", "ESP", "PRT", "NLD", "BEL", "LUX",
    "NOR", "DNK", "ISL", "POL", "CZE", "SVK", "HUN", "ROU", "BGR", "GRC", "ALB",
    "HRV", "SVN", "EST", "LVA", "LTU", "FIN", "SWE", "MNE", "MKD", "TUR",
    "JPN", "KOR", "TWN", "AUS", "NZL", "PHL", "ISR",
    "United States of America", "Canada", "United Kingdom", "France", "Germany",
    "Poland", "Lithuania", "Latvia", "Estonia", "Finland", "Sweden", "Norway", "Turkey",
    "South Korea", "Taiwan", "Japan", "Australia", "New Zealand", "Philippines",
}

OPFOR_BLOC = {
    "RUS", "CHN", "PRK", "IRN", "BLR", "SYR", "VEN", "CUB", "NIC", "MMR",
    "Russia", "China", "North Korea", "Iran", "Belarus", "Syria", "Venezuela",
}

NEUTRAL_BUFFER = {
    "UKR", "CHE", "AUT", "IRL", "MNG", "KAZ", "UZB", "TKM", "KGZ", "TJK", "AFG",
    "SRB", "BIH", "MDA", "GEO", "ARM", "AZE",
    "Ukraine", "Switzerland", "Austria", "Ireland", "Mongolia", "Kazakhstan",
}

FALLBACK_COUNTRIES = [
    ("USA", 0.25, [(-125, 48), (-124, 40), (-117, 32), (-97, 26), (-81, 25), (-67, 45), (-105, 49)]),
    ("CAN", 0.25, [(-140, 60), (-125, 49), (-67, 45), (-53, 47), (-64, 60), (-105, 72), (-135, 70)]),
    ("FRA", 0.25, [(-5, 48), (-2, 43), (3, 42), (7, 44), (8, 49), (2, 51)]),
    ("DEU", 0.25, [(6, 50), (7, 47), (13, 47), (15, 50), (14, 54), (7, 54)]),
    ("POL", 0.25, [(14, 54), (19, 54.5), (23.5, 54), (24, 49.5), (15, 50)]),
    ("LTU", 0.25, [(21, 55.3), (22, 56.4), (26.5, 56.0), (26.5, 54.0), (23.5, 53.9)]),
    ("BLR", 0.85, [(23.5, 53.9), (27.5, 55.8), (32, 54.5), (30.5, 51.5), (23.6, 51.5)]),
    ("UKR", 0.40, [(22, 48), (24, 51.5), (32, 52), (40, 49), (38, 46), (30, 45)]),
    ("RUS", 0.85, [(28, 60), (30, 70), (105, 74), (175, 66), (135, 45), (92, 50), (55, 51), (38, 48), (27.5, 56)]),
    ("TUR", 0.25, [(26, 41), (36, 42), (44, 40), (44, 37), (36, 36), (27, 36.5)]),
    ("IRN", 0.85, [(44, 39), (54, 37), (61, 36), (62, 25.2), (56, 27.1), (48, 30)]),
    ("SAU", 0.55, [(35, 31), (47, 31), (56.4, 26.2), (59.8, 22.5), (43, 13), (35, 28)]),
    ("PAK", 0.55, [(61.5, 25.2), (62, 29.5), (71, 36), (75.5, 36.5), (74.5, 31.5), (67, 24)]),
    ("IND", 0.55, [(68.5, 23.5), (74.5, 31.5), (79.5, 34.2), (88, 28), (96, 28), (88, 22), (77.5, 8.1), (72, 21)]),
    ("CHN", 0.85, [(75.5, 36.5), (88, 49), (118, 49), (134, 45), (122, 37), (121.8, 30), (116, 22.5), (108, 21.5), (97, 28), (79.5, 34.2)]),
    ("PRK", 0.85, [(124.2, 40.0), (128.0, 41.8), (130.6, 42.3), (128.3, 38.3), (125.0, 38.0)]),
    ("KOR", 0.25, [(126.0, 38.0), (128.3, 38.3), (129.5, 35.1), (126.2, 34.3)]),
    ("TWN", 0.25, [(120.1, 22.0), (120.3, 24.5), (121.9, 25.3), (121.5, 22.8)]),
    ("JPN", 0.25, [(130, 31), (136, 35), (141.5, 41), (145, 43.5), (141, 45), (139, 39), (130, 33)]),
    ("AUS", 0.25, [(114, -22), (131, -12), (142, -11), (153, -26), (149, -37.5), (115, -34)]),
]

MAJOR_CAPITALS = [
    (-77.04, 38.90, 1.00),  # Washington D.C. (USA)
    (-75.70, 45.42, 0.88),  # Ottawa (Canada)
    (-99.13, 19.43, 0.90),  # Mexico City (Mexico)
    (-47.88, -15.79, 0.88), # Brasilia (Brazil)
    (-58.38, -34.60, 0.88), # Buenos Aires (Argentina)
    (-0.13, 51.51, 1.00),   # London (UK)
    (2.35, 48.86, 1.00),    # Paris (France)
    (13.40, 52.52, 0.96),   # Berlin (Germany)
    (12.50, 41.90, 0.90),   # Rome (Italy)
    (-3.70, 40.42, 0.90),   # Madrid (Spain)
    (21.01, 52.23, 0.96),   # Warsaw (Poland)
    (25.28, 54.69, 0.95),   # Vilnius (Lithuania - Suwalki Gap)
    (20.51, 54.71, 0.95),   # Kaliningrad (Russia Baltic Fleet)
    (27.57, 53.90, 0.92),   # Minsk (Belarus)
    (30.52, 50.45, 0.96),   # Kyiv (Ukraine)
    (37.62, 55.75, 1.00),   # Moscow (Russia)
    (32.86, 39.93, 0.95),   # Ankara (Turkey)
    (31.24, 30.04, 0.92),   # Cairo (Egypt)
    (46.72, 24.69, 0.92),   # Riyadh (Saudi Arabia)
    (51.39, 35.69, 1.00),   # Tehran (Iran)
    (55.27, 25.20, 0.96),   # Dubai / Abu Dhabi (UAE - Strait of Hormuz)
    (58.41, 23.59, 0.90),   # Muscat (Oman)
    (73.05, 33.68, 0.96),   # Islamabad (Pakistan)
    (77.21, 28.61, 1.00),   # New Delhi (India)
    (77.58, 34.15, 0.92),   # Leh / Ladakh (Himalaya LAC)
    (116.41, 39.90, 1.00),  # Beijing (China)
    (121.47, 31.23, 0.96),  # Shanghai (China)
    (121.56, 25.03, 1.00),  # Taipei (Taiwan)
    (125.75, 39.03, 0.96),  # Pyongyang (North Korea)
    (126.98, 37.57, 1.00),  # Seoul (South Korea)
    (139.69, 35.69, 1.00),  # Tokyo (Japan)
    (120.98, 14.60, 0.92),  # Manila (Philippines)
    (103.82, 1.35, 0.94),   # Singapore
    (149.13, -35.28, 0.90), # Canberra / Sydney (Australia)
]


def decode_png_rgb_bytes(png_bytes: bytes) -> tuple:
    """
    Pure-Python 8-bit RGB/RGBA PNG decoder (supports all 5 PNG scanline filters: None, Sub, Up, Average, Paeth).
    Returns (width, height, channels, bytearray_pixels).
    """
    pos = 8
    w = h = color_type = 0
    idat = bytearray()
    while pos + 8 <= len(png_bytes):
        length, ctype = struct.unpack(">I4s", png_bytes[pos : pos + 8])
        chunk = png_bytes[pos + 8 : pos + 8 + length]
        if ctype == b"IHDR":
            w, h, _bit_depth, color_type, _, _, _ = struct.unpack(">IIBBBBB", chunk)
        elif ctype == b"IDAT":
            idat.extend(chunk)
        elif ctype == b"IEND":
            break
        pos += 12 + length

    bpp = 4 if color_type == 6 else 3
    stride = w * bpp
    raw = zlib.decompress(bytes(idat))
    out = bytearray(h * stride)

    for y in range(h):
        row_start = y * (stride + 1)
        f_type = raw[row_start]
        src_off = row_start + 1
        dst_off = y * stride
        prev_off = (y - 1) * stride

        if f_type == 0:  # None
            out[dst_off : dst_off + stride] = raw[src_off : src_off + stride]
        elif f_type == 1:  # Sub
            for i in range(stride):
                a = out[dst_off + i - bpp] if i >= bpp else 0
                out[dst_off + i] = (raw[src_off + i] + a) & 0xFF
        elif f_type == 2:  # Up
            for i in range(stride):
                b = out[prev_off + i] if y > 0 else 0
                out[dst_off + i] = (raw[src_off + i] + b) & 0xFF
        elif f_type == 3:  # Average
            for i in range(stride):
                a = out[dst_off + i - bpp] if i >= bpp else 0
                b = out[prev_off + i] if y > 0 else 0
                out[dst_off + i] = (raw[src_off + i] + ((a + b) >> 1)) & 0xFF
        elif f_type == 4:  # Paeth
            for i in range(stride):
                a = out[dst_off + i - bpp] if i >= bpp else 0
                b = out[prev_off + i] if y > 0 else 0
                c = out[prev_off + i - bpp] if (y > 0 and i >= bpp) else 0
                p = a + b - c
                pa = abs(p - a)
                pb = abs(p - b)
                pc = abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                out[dst_off + i] = (raw[src_off + i] + pr) & 0xFF

    return w, h, bpp, out


def load_or_fetch_global_dem_grid(zoom: int = 2) -> tuple:
    """
    Fetches & caches real-world z=2 (1024x1024) SRTM/ETOPO elevation & bathymetry tiles from:
      - Mapbox Terrain-RGB (`MAPBOX_ACCESS_TOKEN`), OR
      - AWS Open Data Mapzen Terrarium (`https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png`)
    Returns (grid_size, elev_meters_grid_2d) or (0, None) if offline.
    """
    DEM_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    mapbox_token = os.environ.get("MAPBOX_ACCESS_TOKEN", "").strip()
    provider = "mapbox" if mapbox_token else "terrarium"
    ntiles = 1 << zoom
    grid_size = ntiles * 256
    elev_grid = [[0.0] * grid_size for _ in range(grid_size)]

    fetched_count = 0
    for ty in range(ntiles):
        for tx in range(ntiles):
            cache_file = DEM_CACHE_DIR / f"{provider}_z{zoom}_{tx}_{ty}.png"
            png_bytes = None
            if cache_file.exists() and cache_file.stat().st_size > 500:
                png_bytes = cache_file.read_bytes()
            else:
                if provider == "mapbox":
                    url = (
                        f"https://api.mapbox.com/v4/mapbox.terrain-rgb/{zoom}/{tx}/{ty}.pngraw"
                        f"?access_token={mapbox_token}"
                    )
                else:
                    url = f"https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{zoom}/{tx}/{ty}.png"
                try:
                    req = urllib.request.Request(url, headers={"User-Agent": "VRArmyGame-GIS-DEM/1.0"})
                    with urllib.request.urlopen(req, timeout=10) as resp:
                        png_bytes = resp.read()
                        cache_file.write_bytes(png_bytes)
                except Exception as exc:
                    print(f"[GIS DEM] Warning fetching tile ({zoom}/{tx}/{ty}): {exc}")

            if png_bytes:
                try:
                    tw, th, bpp, pix = decode_png_rgb_bytes(png_bytes)
                    base_x = tx * 256
                    base_y = ty * 256
                    for py in range(min(256, th)):
                        row_dst = elev_grid[base_y + py]
                        row_off = py * tw * bpp
                        for px in range(min(256, tw)):
                            idx = row_off + px * bpp
                            r = pix[idx]
                            g = pix[idx + 1]
                            b = pix[idx + 2]
                            if provider == "mapbox":
                                elev_m = -10000.0 + (r * 65536.0 + g * 256.0 + b) * 0.1
                            else:
                                elev_m = (r * 256.0 + g + b / 256.0) - 32768.0
                            row_dst[base_x + px] = elev_m
                    fetched_count += 1
                except Exception as exc:
                    print(f"[GIS DEM] Decode warning on tile ({zoom}/{tx}/{ty}): {exc}")

    if fetched_count == ntiles * ntiles:
        src_label = "Mapbox Terrain-RGB" if provider == "mapbox" else "AWS Open Data Terrarium SRTM/ETOPO DEM"
        print(f"[GIS DEM] Loaded {grid_size}x{grid_size} real-world global elevation grid via {src_label}.")
        return grid_size, elev_grid
    return 0, None


def sample_real_dem_meters(lon: float, lat: float, grid_size: int, elev_grid: list) -> float:
    """Samples Web Mercator DEM grid at (lon_deg, lat_deg) in meters."""
    if grid_size <= 0 or elev_grid is None:
        return 0.0
    # Clamp latitude to Web Mercator domain [-85.05, +85.05]
    lat_clamped = max(-85.0, min(85.0, lat))
    lat_rad = math.radians(lat_clamped)
    u = (lon + 180.0) / 360.0
    v = (1.0 - math.log(math.tan(lat_rad) + (1.0 / math.cos(lat_rad))) / math.pi) * 0.5
    px = max(0, min(grid_size - 1, int(u * (grid_size - 1))))
    py = max(0, min(grid_size - 1, int(v * (grid_size - 1))))
    return elev_grid[py][px]


def _classify_country_alignment(props: dict) -> float:
    iso_a3 = str(props.get("ISO_A3", "") or props.get("ADM0_A3", "")).strip()
    name = str(props.get("NAME", "") or props.get("ADMIN", "")).strip()
    if name == "Antarctica" or iso_a3 == "ATA":
        return 0.40
    if iso_a3 in OPFOR_BLOC or name in OPFOR_BLOC:
        return 0.85
    if iso_a3 in NATO_AND_ALLIES or name in NATO_AND_ALLIES:
        return 0.25
    if iso_a3 in NEUTRAL_BUFFER or name in NEUTRAL_BUFFER:
        return 0.40
    return 0.55


def load_or_fetch_natural_earth_polygons() -> list:
    THEATERS_DIR.mkdir(parents=True, exist_ok=True)
    geojson_data = None

    if GEOJSON_CACHE_PATH.exists() and GEOJSON_CACHE_PATH.stat().st_size > 10000:
        try:
            geojson_data = json.loads(GEOJSON_CACHE_PATH.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"[GIS] Cached GeoJSON read warning: {exc}")

    if geojson_data is None:
        try:
            print(f"[GIS] Downloading Natural Earth Admin-0 Countries GeoJSON from {NATURAL_EARTH_URL} ...")
            req = urllib.request.Request(
                NATURAL_EARTH_URL,
                headers={"User-Agent": "VRArmyGame-GIS-Pipeline/1.0"}
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                raw_bytes = resp.read()
                GEOJSON_CACHE_PATH.write_bytes(raw_bytes)
                geojson_data = json.loads(raw_bytes.decode("utf-8"))
                print(f"[GIS] Cached {len(raw_bytes)} bytes to {GEOJSON_CACHE_PATH.name}")
        except Exception as exc:
            print(f"[GIS] Offline or download skipped ({exc}); using built-in sovereign polygons.")

    if geojson_data and "features" in geojson_data:
        parsed = []
        for feat in geojson_data["features"]:
            props = feat.get("properties", {}) or {}
            geom = feat.get("geometry", {}) or {}
            gtype = geom.get("type", "")
            coords = geom.get("coordinates", [])
            code = str(props.get("ADM0_A3") or props.get("ISO_A3") or props.get("NAME") or "UNK")
            align = _classify_country_alignment(props)
            rings = []
            if gtype == "Polygon":
                for ring in coords:
                    if len(ring) >= 3:
                        rings.append([(float(pt[0]), float(pt[1])) for pt in ring])
            elif gtype == "MultiPolygon":
                for poly in coords:
                    for ring in poly:
                        if len(ring) >= 3:
                            rings.append([(float(pt[0]), float(pt[1])) for pt in ring])
            if rings:
                parsed.append((code, align, rings))
        has_twn = any(c[0] in ("TWN", "Taiwan") for c in parsed)
        if not has_twn:
            parsed.append(("TWN", 0.25, [[(120.1, 22.0), (120.3, 24.5), (121.9, 25.3), (121.5, 22.8), (120.1, 22.0)]]))
        print(f"[GIS] Loaded {len(parsed)} real sovereign countries from Natural Earth GeoJSON.")
        return parsed

    return [(code, align, [poly]) for code, align, poly in FALLBACK_COUNTRIES]


def sample_orographic_relief(
    lon: float,
    lat: float,
    is_land: bool,
    dem_grid_size: int = 0,
    dem_grid: list = None,
) -> float:
    """
    Combines Real SRTM/ETOPO DEM elevation (from AWS Terrarium / Mapbox Terrain-RGB tiles)
    with analytical mountain range continuity so both 40,000km globe and 4,000km continental views
    display authentic topography & ocean bathymetry.
    """
    if dem_grid_size > 0 and dem_grid is not None:
        elev_m = sample_real_dem_meters(lon, lat, dem_grid_size, dem_grid)
        if not is_land:
            # Ocean bathymetry: -6000m .. 0m -> normalized [0.05 .. 0.33]
            depth_norm = max(0.0, min(1.0, (elev_m + 5500.0) / 5500.0))
            return 0.05 + depth_norm * 0.28
        else:
            # Land elevation: 0m .. 5500m -> normalized [0.42 .. 0.99]
            land_norm = max(0.0, min(1.0, max(0.0, elev_m) / 4800.0))
            return 0.42 + (land_norm ** 0.72) * 0.57

    wave = (
        0.025 * math.sin(lon * 0.18 + lat * 0.14)
        + 0.015 * math.cos(lon * 0.45 - lat * 0.38)
    )
    if not is_land:
        mid_atlantic = 0.06 * math.exp(-((lon + 30.0 - 8.0 * math.sin(lat * 0.05)) / 6.5) ** 2)
        return max(0.06, min(0.32, 0.13 + mid_atlantic + wave * 0.5))

    himalaya = 0.42 * math.exp(-((lon - 86.0) / 13.0) ** 2 - ((lat - 32.5) / 5.5) ** 2)
    karakoram = 0.34 * math.exp(-((lon - 75.0) / 7.5) ** 2 - ((lat - 38.0) / 4.5) ** 2)
    zagros = 0.24 * math.exp(-((lon - 50.0) / 8.5) ** 2 - ((lat - 33.5) / 4.8) ** 2)
    alps = 0.22 * math.exp(-((lon - 11.5) / 5.5) ** 2 - ((lat - 46.2) / 2.2) ** 2)
    urals = 0.16 * math.exp(-((lon - 59.5) / 2.8) ** 2 - ((lat - 59.0) / 7.0) ** 2)
    rockies = 0.26 * math.exp(-((lon + 114.0) / 8.0) ** 2 - ((lat - 46.0) / 14.0) ** 2)
    andes = 0.34 * math.exp(-((lon + 70.0) / 4.2) ** 2 - ((lat + 20.0) / 24.0) ** 2)
    ethiopia = 0.20 * math.exp(-((lon - 38.5) / 4.5) ** 2 - ((lat - 7.5) / 6.5) ** 2)
    taiwan_mtn = 0.26 * math.exp(-((lon - 121.1) / 0.9) ** 2 - ((lat - 23.8) / 1.4) ** 2)
    korea_mtn = 0.18 * math.exp(-((lon - 128.2) / 1.5) ** 2 - ((lat - 38.5) / 2.5) ** 2)

    mtn = max(himalaya, karakoram, zagros, alps, urals, rockies, andes, ethiopia, taiwan_mtn, korea_mtn)
    return max(0.40, min(0.99, 0.50 + mtn + wave))


def _splat_segment_border(
    border_grid: list,
    width: int,
    height: int,
    lon1: float,
    lat1: float,
    lon2: float,
    lat2: float,
    intensity: float = 1.0,
) -> None:
    if abs(lon2 - lon1) > 180.0:
        return
    x1 = (lon1 + 180.0) / 360.0 * (width - 1)
    y1 = (90.0 - lat1) / 180.0 * (height - 1)
    x2 = (lon2 + 180.0) / 360.0 * (width - 1)
    y2 = (90.0 - lat2) / 180.0 * (height - 1)

    dist = math.hypot(x2 - x1, y2 - y1)
    steps = max(1, int(dist * 2.0))
    for s in range(steps + 1):
        t = s / float(steps)
        px = x1 + (x2 - x1) * t
        py = y1 + (y2 - y1) * t
        ix = int(round(px))
        iy = int(round(py))
        for dy in range(-1, 2):
            ny = iy + dy
            if 0 <= ny < height:
                row = border_grid[ny]
                for dx in range(-1, 2):
                    nx = (ix + dx) % width
                    d = math.hypot(px - (ix + dx), py - ny)
                    w = max(0.0, 1.0 - d / 1.45) * intensity
                    if w > row[nx]:
                        row[nx] = w


def generate_world_political_map(width: int = 1440, height: int = 720) -> None:
    countries = load_or_fetch_natural_earth_polygons()
    dem_grid_size, dem_grid = load_or_fetch_global_dem_grid(zoom=2)

    align_grid = [[0.0] * width for _ in range(height)]
    country_idx_grid = [[-1] * width for _ in range(height)]
    border_grid = [[0.0] * width for _ in range(height)]

    # 1. Scanline Fill of all Sovereign Country Polygon Rings + Anti-Aliased Border Splatting
    for c_idx, (code, align, rings) in enumerate(countries):
        for ring in rings:
            n = len(ring)
            if n < 3:
                continue
            for i in range(n):
                lon1, lat1 = ring[i]
                lon2, lat2 = ring[(i + 1) % n]
                _splat_segment_border(border_grid, width, height, lon1, lat1, lon2, lat2, 1.0)

            lats = [pt[1] for pt in ring]
            min_lat = max(-90.0, min(lats))
            max_lat = min(90.0, max(lats))
            y_start = max(0, int((90.0 - max_lat) / 180.0 * (height - 1)))
            y_end = min(height - 1, int(math.ceil((90.0 - min_lat) / 180.0 * (height - 1))))

            for y in range(y_start, y_end + 1):
                lat = 90.0 - (y / float(height - 1)) * 180.0 + 1e-5
                intersections = []
                j = n - 1
                for i in range(n):
                    xi, yi = ring[i]
                    xj, yj = ring[j]
                    if (yi > lat) != (yj > lat) and abs(xj - xi) < 180.0:
                        lon_x = (xj - xi) * (lat - yi) / (yj - yi) + xi
                        intersections.append(lon_x)
                    j = i
                intersections.sort()
                for k in range(0, len(intersections) - 1, 2):
                    lon_a = intersections[k]
                    lon_b = intersections[k + 1]
                    xa = max(0, int(math.ceil((lon_a + 180.0) / 360.0 * (width - 1))))
                    xb = min(width - 1, int((lon_b + 180.0) / 360.0 * (width - 1)))
                    a_row = align_grid[y]
                    c_row = country_idx_grid[y]
                    for x in range(xa, xb + 1):
                        a_row[x] = align
                        c_row[x] = c_idx

    # 2. Enhance internal international borders where country_idx_grid changes between neighbors
    for y in range(1, height - 1):
        c_row = country_idx_grid[y]
        c_up = country_idx_grid[y - 1]
        c_dn = country_idx_grid[y + 1]
        b_row = border_grid[y]
        for x in range(width):
            cid = c_row[x]
            c_left = c_row[(x - 1) % width]
            c_right = c_row[(x + 1) % width]
            if cid != c_left or cid != c_right or cid != c_up[x] or cid != c_dn[x]:
                if b_row[x] < 0.95:
                    b_row[x] = 0.95

    # 3. Precompute Capital & Strategic Megacity Lights (`A` channel)
    city_grid = [[0.0] * width for _ in range(height)]
    for clon, clat, cint in MAJOR_CAPITALS:
        cx = int((clon + 180.0) / 360.0 * (width - 1))
        cy = int((90.0 - clat) / 180.0 * (height - 1))
        rad = 7
        for dy in range(-rad, rad + 1):
            ny = cy + dy
            if 0 <= ny < height:
                for dx in range(-rad, rad + 1):
                    nx = (cx + dx) % width
                    d2 = float(dx * dx + dy * dy)
                    glow = cint * math.exp(-d2 / 5.5)
                    if glow > city_grid[ny][nx]:
                        city_grid[ny][nx] = glow

    # 4. Pack RGBA rows
    raw_rows = bytearray()
    for y in range(height):
        raw_rows.append(0)
        lat = 90.0 - (y / float(height - 1)) * 180.0
        a_row = align_grid[y]
        b_row = border_grid[y]
        g_row = city_grid[y]
        for x in range(width):
            lon = -180.0 + (x / float(width - 1)) * 360.0
            align = a_row[x]
            is_land = align > 0.0
            elev = sample_orographic_relief(lon, lat, is_land, dem_grid_size, dem_grid)
            border = b_row[x]
            if not is_land and border > 0.0:
                elev = max(elev, 0.28 * border)
            r_byte = int(max(0.0, min(1.0, elev)) * 255.0)
            g_byte = int(max(0.0, min(1.0, border)) * 255.0)
            b_byte = int(max(0.0, min(1.0, align)) * 255.0)
            a_byte = int(max(0.0, min(1.0, g_row[x])) * 255.0)
            raw_rows.extend((r_byte, g_byte, b_byte, a_byte))

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
    OUT_PATH.write_bytes(png_bytes)
    print(
        f"[GIS] Generated {width}x{height} Real-World Geopolitical & SRTM/ETOPO DEM Map: "
        f"{OUT_PATH} ({OUT_PATH.stat().st_size} bytes)"
    )


if __name__ == "__main__":
    generate_world_political_map()

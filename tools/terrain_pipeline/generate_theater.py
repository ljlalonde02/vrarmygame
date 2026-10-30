#!/usr/bin/env python3
"""
Phase 14 Real-World SRTM/ETOPO DEM Tile (`z=6`) + Tactical Shoreline Calibrated Heightmap Generator
for all 5 Global 500 km x 500 km Flashpoint Theaters (`data/theaters/*.png`):
  1. `strait_theater_heightmap.png`   — Taiwan Strait & Central Mountain Range (22.0N..26.2N, 118.0E..122.8E)
  2. `hormuz_theater_heightmap.png`   — Strait of Hormuz, Qeshm Island & Zagros (24.2N..28.2N, 54.0E..58.6E)
  3. `korean_dmz_heightmap.png`       — Korean Peninsula DMZ, Taebaek & West Sea (36.0N..40.2N, 124.8E..129.8E)
  4. `baltic_suwalki_heightmap.png`   — Suwalki Gap, Kaliningrad & Baltic Littoral (52.4N..56.4N, 19.6E..26.2E)
  5. `himalaya_lac_heightmap.png`     — Ladakh / Aksai Chin 5,600m Himalayan Ridge (32.0N..36.0N, 76.0E..80.8E)

Data Sources:
  - AWS Open Data Mapzen Terrarium SRTM/ETOPO DEM (`https://s3.amazonaws.com/elevation-tiles-prod/terrarium/6/{x}/{y}.png`)
  - Optional Mapbox Terrain-RGB (`MAPBOX_ACCESS_TOKEN` env var)
  - Cached locally in `data/theaters/dem_cache/` for instant offline rebuilds.
"""

import math
import os
import struct
import urllib.request
import zlib
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
THEATERS_DIR = ROOT_DIR / "data" / "theaters"
DEM_CACHE_DIR = THEATERS_DIR / "dem_cache"


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def pseudo_noise(x: float, y: float) -> float:
    """Deterministic multi-frequency trigonometric terrain noise."""
    return (
        math.sin(x * 1.7 + y * 1.3) * 0.45
        + math.cos(x * 3.9 - y * 2.7) * 0.28
        + math.sin(x * 8.3 + y * 7.1) * 0.16
        + math.cos(x * 17.5 - y * 14.2) * 0.11
    )


def decode_png_rgb_bytes(png_bytes: bytes) -> tuple:
    """Pure-Python 8-bit RGB/RGBA PNG scanline decoder (None, Sub, Up, Average, Paeth)."""
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

        if f_type == 0:
            out[dst_off : dst_off + stride] = raw[src_off : src_off + stride]
        elif f_type == 1:
            for i in range(stride):
                a = out[dst_off + i - bpp] if i >= bpp else 0
                out[dst_off + i] = (raw[src_off + i] + a) & 0xFF
        elif f_type == 2:
            for i in range(stride):
                b = out[prev_off + i] if y > 0 else 0
                out[dst_off + i] = (raw[src_off + i] + b) & 0xFF
        elif f_type == 3:
            for i in range(stride):
                a = out[dst_off + i - bpp] if i >= bpp else 0
                b = out[prev_off + i] if y > 0 else 0
                out[dst_off + i] = (raw[src_off + i] + ((a + b) >> 1)) & 0xFF
        elif f_type == 4:
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


def _lonlat_to_tile_xy(lon_deg: float, lat_deg: float, zoom: int) -> tuple:
    n = float(1 << zoom)
    lat_rad = math.radians(clamp(lat_deg, -85.05, 85.05))
    xtile = (lon_deg + 180.0) / 360.0 * n
    ytile = (1.0 - math.log(math.tan(lat_rad) + (1.0 / math.cos(lat_rad))) / math.pi) * 0.5 * n
    return xtile, ytile


class RealDemTileSampler:
    """Fetches, caches, and bilinearly samples z=6 SRTM/ETOPO DEM tiles for a Lat/Lon box."""

    def __init__(self, min_lon: float, min_lat: float, max_lon: float, max_lat: float, zoom: int = 6):
        self.min_lon = min_lon
        self.min_lat = min_lat
        self.max_lon = max_lon
        self.max_lat = max_lat
        self.zoom = zoom
        self.tiles = {}
        self._load_bbox_tiles()

    def _load_bbox_tiles(self) -> None:
        DEM_CACHE_DIR.mkdir(parents=True, exist_ok=True)
        mapbox_token = os.environ.get("MAPBOX_ACCESS_TOKEN", "").strip()
        provider = "mapbox" if mapbox_token else "terrarium"

        x0_f, y0_f = _lonlat_to_tile_xy(self.min_lon, self.max_lat, self.zoom)
        x1_f, y1_f = _lonlat_to_tile_xy(self.max_lon, self.min_lat, self.zoom)
        tx_min = max(0, int(math.floor(min(x0_f, x1_f))))
        tx_max = min((1 << self.zoom) - 1, int(math.floor(max(x0_f, x1_f))))
        ty_min = max(0, int(math.floor(min(y0_f, y1_f))))
        ty_max = min((1 << self.zoom) - 1, int(math.floor(max(y0_f, y1_f))))

        for ty in range(ty_min, ty_max + 1):
            for tx in range(tx_min, tx_max + 1):
                cache_file = DEM_CACHE_DIR / f"{provider}_z{self.zoom}_{tx}_{ty}.png"
                png_bytes = None
                if cache_file.exists() and cache_file.stat().st_size > 400:
                    png_bytes = cache_file.read_bytes()
                else:
                    if provider == "mapbox":
                        url = (
                            f"https://api.mapbox.com/v4/mapbox.terrain-rgb/{self.zoom}/{tx}/{ty}.pngraw"
                            f"?access_token={mapbox_token}"
                        )
                    else:
                        url = f"https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{self.zoom}/{tx}/{ty}.png"
                    try:
                        req = urllib.request.Request(url, headers={"User-Agent": "VRArmyGame-Theater-DEM/1.0"})
                        with urllib.request.urlopen(req, timeout=10) as resp:
                            png_bytes = resp.read()
                            cache_file.write_bytes(png_bytes)
                    except Exception as exc:
                        print(f"[Theater DEM] Warning fetching tile z={self.zoom}/{tx}/{ty}: {exc}")

                if png_bytes:
                    try:
                        tw, th, bpp, pix = decode_png_rgb_bytes(png_bytes)
                        grid = [[0.0] * tw for _ in range(th)]
                        for py in range(th):
                            row_off = py * tw * bpp
                            row_dst = grid[py]
                            for px in range(tw):
                                idx = row_off + px * bpp
                                r = pix[idx]
                                g = pix[idx + 1]
                                b = pix[idx + 2]
                                if provider == "mapbox":
                                    elev_m = -10000.0 + (r * 65536.0 + g * 256.0 + b) * 0.1
                                else:
                                    elev_m = (r * 256.0 + g + b / 256.0) - 32768.0
                                row_dst[px] = elev_m
                        self.tiles[(tx, ty)] = grid
                    except Exception as exc:
                        print(f"[Theater DEM] Decode warning on tile z={self.zoom}/{tx}/{ty}: {exc}")

    def sample_elevation_m(self, nx: float, ny: float) -> tuple:
        """
        Samples elevation in meters at normalized theater coordinates nx, ny in [-1..+1].
        Returns (has_tile_data: bool, elev_m: float).
        """
        if not self.tiles:
            return False, 0.0
        u = (nx + 1.0) * 0.5
        v = (ny + 1.0) * 0.5
        lon = self.min_lon + u * (self.max_lon - self.min_lon)
        lat = self.max_lat - v * (self.max_lat - self.min_lat)
        xtile_f, ytile_f = _lonlat_to_tile_xy(lon, lat, self.zoom)
        tx = int(math.floor(xtile_f))
        ty = int(math.floor(ytile_f))
        grid = self.tiles.get((tx, ty))
        if grid is None:
            return False, 0.0

        fx = (xtile_f - tx) * 255.0
        fy = (ytile_f - ty) * 255.0
        ix0 = clamp(int(math.floor(fx)), 0, 255)
        iy0 = clamp(int(math.floor(fy)), 0, 255)
        ix1 = min(255, ix0 + 1)
        iy1 = min(255, iy0 + 1)
        wx = fx - ix0
        wy = fy - iy0

        v00 = grid[iy0][ix0]
        v10 = grid[iy0][ix1]
        v01 = grid[iy1][ix0]
        v11 = grid[iy1][ix1]
        val = (v00 * (1.0 - wx) + v10 * wx) * (1.0 - wy) + (v01 * (1.0 - wx) + v11 * wx) * wy
        return True, val


def _write_png_grayscale(out_path: Path, size: int, raw_rows: bytearray) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    def make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    compressed = zlib.compress(bytes(raw_rows), 6)
    png_bytes = (
        b"\x89PNG\r\n\x1a\n"
        + make_chunk(b"IHDR", ihdr)
        + make_chunk(b"IDAT", compressed)
        + make_chunk(b"IEND", b"")
    )
    out_path.write_bytes(png_bytes)
    print(f"Generated 500x500 km SRTM/DEM theater heightmap: {out_path.name:32s} ({len(png_bytes)} bytes)")


def sample_strait_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    west_land = 0.0
    if nx < -0.15:
        t = min(1.0, (-0.15 - nx) / 0.55)
        west_land = 0.24 + t * 0.38 + n1 * 0.12 + abs(n2) * 0.08

    east_island = 0.0
    island_center_x = 0.35 - ny * 0.12
    dx = (nx - island_center_x) / 0.32
    dy = ny / 0.78
    dist_sq = dx * dx + dy * dy
    if dist_sq < 1.15:
        island_mask = max(0.0, 1.0 - dist_sq)
        ridge = math.exp(-((nx - (island_center_x + 0.06)) / 0.11) ** 2) * island_mask
        valley_cut = math.sin(ny * 14.0 + n1 * 2.0) * 0.08 * ridge
        east_island = 0.23 + island_mask * 0.25 + ridge * 0.52 - valley_cut + n2 * 0.09

    archipelago = 0.0
    isl_d = math.hypot(nx - 0.02, ny - 0.15)
    if isl_d < 0.09:
        archipelago = 0.28 + (0.09 - isl_d) * 1.4 + n2 * 0.04

    bathymetry = 0.10 + 0.06 * math.cos(nx * 3.14) + n1 * 0.03
    return max(bathymetry, west_land, east_island, archipelago)


def sample_hormuz_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    bend = 0.28 * math.exp(-((nx - 0.05) / 0.42) ** 2)
    north_coast_y = -0.22 + bend
    north_land = 0.0
    if ny < north_coast_y:
        t = min(1.0, (north_coast_y - ny) / 0.55)
        zagros = math.sin(nx * 10.0 + ny * 6.0) * 0.12
        north_land = 0.25 + t * 0.58 + abs(n1) * 0.14 + zagros

    musandam_tip_y = 0.12 - 0.38 * math.exp(-((nx - 0.08) / 0.22) ** 2)
    south_land = 0.0
    if ny > musandam_tip_y:
        t = min(1.0, (ny - musandam_tip_y) / 0.65)
        south_land = 0.24 + t * 0.42 + n1 * 0.10 + abs(n2) * 0.09

    island_d = math.hypot((nx + 0.06) * 0.7, (ny - (north_coast_y + 0.09)) * 1.6)
    qeshm = (0.28 + (0.08 - island_d) * 1.8) if island_d < 0.08 else 0.0

    bathymetry = 0.11 + 0.04 * n1
    return max(bathymetry, north_land, south_land, qeshm)


def sample_korean_dmz_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    west_coast = -0.42 + 0.08 * math.sin(ny * 3.5) + n1 * 0.04
    east_coast = 0.44 - 0.06 * math.cos(ny * 2.8)
    if nx < west_coast or nx > east_coast:
        return 0.10 + 0.04 * n1

    east_bias = clamp((nx - west_coast) / max(0.1, east_coast - west_coast), 0.0, 1.0)
    taebaek_ridge = math.exp(-((east_bias - 0.78) / 0.18) ** 2) * 0.52
    dmz_valley = -0.07 * math.exp(-((ny - 0.02) / 0.08) ** 2)
    elev = 0.26 + east_bias * 0.18 + taebaek_ridge + dmz_valley + n1 * 0.11 + abs(n2) * 0.08
    return max(0.23, elev)


def sample_baltic_suwalki_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    coast_line = -0.18 - ny * 0.45 + n1 * 0.08
    if nx < coast_line:
        return 0.12 + 0.03 * n1

    ridges = 0.30 + 0.18 * clamp((nx - coast_line) / 0.9, 0.0, 1.0) + n1 * 0.09 + n2 * 0.07
    return max(0.23, ridges)


def sample_himalaya_lac_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    pangong_d = math.hypot((nx - 0.05) * 0.65, (ny - 0.02) * 2.4)
    if pangong_d < 0.11:
        return 0.18  # Deep alpine glacial lake

    karakoram_spine = math.exp(-((nx + ny * 0.65) / 0.35) ** 2) * 0.42
    gorge_cuts = abs(math.sin((nx * 6.5 - ny * 5.2) + n1 * 1.5)) * 0.22
    elev = 0.44 + karakoram_spine + gorge_cuts + n2 * 0.10
    return clamp(elev, 0.26, 0.99)


def sample_ukraine_donbas_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    # Sea of Azov & Black Sea Littoral in the South-Southeast
    azov_coast_y = 0.46 - 0.16 * math.sin(nx * 2.4) + n1 * 0.05
    crimea_mask = (nx < -0.08 and ny > 0.64 and math.hypot(nx + 0.35, ny - 0.78) < 0.32)
    if ny > azov_coast_y and not crimea_mask:
        return 0.11 + 0.04 * n1

    # Wide Dnipro River Reservoir bend on the West-Central axis
    dnipro_x = -0.32 + 0.18 * math.sin(ny * 3.1)
    if abs(nx - dnipro_x) < 0.038 and ny < azov_coast_y:
        return 0.17  # Navigable Dnipro reservoir channel

    # Donbas Ridge (Donetskyi Kriazh) in the East + Zaporizhzhia Steppe
    donbas_ridge = math.exp(-((nx - 0.28) / 0.34) ** 2) * math.exp(-((ny + 0.05) / 0.42) ** 2) * 0.34
    elev = 0.27 + donbas_ridge + n1 * 0.09 + abs(n2) * 0.07
    return clamp(elev, 0.235, 0.88)


def sample_mexico_rio_grande_theater(nx: float, ny: float, n1: float, n2: float) -> float:
    # Gulf of Mexico Coastline along the East (Corpus Christi -> Matamoros -> Tampico)
    gulf_coast_x = 0.56 - 0.12 * ny + 0.06 * math.sin(ny * 3.5) + n1 * 0.04
    if nx > gulf_coast_x:
        return 0.10 + 0.04 * n1

    # Sierra Madre Oriental 3,200m Mountain Spines in the South-Southwest (Monterrey / Saltillo)
    sierra_mask = clamp((0.18 - nx) / 0.75, 0.0, 1.0) * clamp((ny + 0.25) / 0.95, 0.0, 1.0)
    sierra_ridges = abs(math.sin((nx * 7.5 + ny * 5.5) + n1 * 1.4)) * 0.42 * sierra_mask
    # Rio Grande / Rio Bravo valley floor cutting NW -> SE
    rio_y = -0.08 + nx * 0.42 + 0.06 * math.sin(nx * 5.0)
    rio_valley = -0.06 * math.exp(-((ny - rio_y) / 0.09) ** 2)
    elev = 0.26 + sierra_mask * 0.30 + sierra_ridges + rio_valley + n1 * 0.09 + abs(n2) * 0.07
    return clamp(elev, 0.235, 0.96)


def fuse_real_dem_with_tactical_envelope(
    h_base: float,
    has_dem: bool,
    dem_elev_m: float,
    max_elev_m: float,
) -> float:
    """
    Blends real-world z=6 SRTM/ETOPO satellite DEM elevation (`dem_elev_m`) with the
    tactical domain envelope (`h_base`) so real mountain peaks, river valleys, and ocean
    trenches are sculpted onto the 512x512 heightmap while keeping 100% of land/sea
    unit spawn coordinates and strategic sites domain-safe (0.22 = sea level).
    """
    if not has_dem:
        return h_base

    if h_base >= 0.225:
        # Land domain: blend real SRTM elevation (0m..max_elev_m -> 0.235..0.98)
        dem_pos_m = max(12.0, dem_elev_m)
        dem_norm = 0.235 + clamp(dem_pos_m / max(500.0, max_elev_m), 0.0, 1.0) * 0.745
        fused = h_base * 0.52 + dem_norm * 0.48
        return clamp(fused, 0.235, 0.99)
    else:
        # Ocean / Lake domain: blend real ETOPO bathymetry (-1500m..0m -> 0.04..0.20)
        dem_neg_m = min(-5.0, dem_elev_m)
        dem_bath = 0.205 - clamp(abs(dem_neg_m) / 1200.0, 0.0, 1.0) * 0.155
        fused = h_base * 0.55 + dem_bath * 0.45
        return clamp(fused, 0.04, 0.205)


def generate_all_theaters(size: int = 512) -> None:
    theaters = [
        # (filename, base_sampler, (min_lon, min_lat, max_lon, max_lat), max_elev_m)
        ("strait_theater_heightmap.png", sample_strait_theater, (118.0, 22.0, 122.8, 26.2), 3800.0),
        ("hormuz_theater_heightmap.png", sample_hormuz_theater, (54.0, 24.2, 58.6, 28.2), 3200.0),
        ("korean_dmz_heightmap.png", sample_korean_dmz_theater, (124.8, 36.0, 129.8, 40.2), 2600.0),
        ("baltic_suwalki_heightmap.png", sample_baltic_suwalki_theater, (19.6, 52.4, 26.2, 56.4), 600.0),
        ("himalaya_lac_heightmap.png", sample_himalaya_lac_theater, (76.0, 32.0, 80.8, 36.0), 5600.0),
        ("ukraine_donbas_heightmap.png", sample_ukraine_donbas_theater, (32.5, 45.5, 39.2, 49.8), 900.0),
        ("mexico_rio_grande_heightmap.png", sample_mexico_rio_grande_theater, (-101.8, 24.5, -96.5, 29.0), 3400.0),
    ]
    for filename, sampler, bbox, max_elev_m in theaters:
        dem_sampler = RealDemTileSampler(bbox[0], bbox[1], bbox[2], bbox[3], zoom=6)
        raw_rows = bytearray()
        for py in range(size):
            raw_rows.append(0)
            ny = (py / (size - 1)) * 2.0 - 1.0
            for px in range(size):
                nx = (px / (size - 1)) * 2.0 - 1.0
                n1 = pseudo_noise(nx * 2.5, ny * 2.5)
                n2 = pseudo_noise(nx * 6.0 + 1.4, ny * 6.0 - 0.8)
                h_base = sampler(nx, ny, n1, n2)
                has_dem, dem_m = dem_sampler.sample_elevation_m(nx, ny)
                h = fuse_real_dem_with_tactical_envelope(h_base, has_dem, dem_m, max_elev_m)
                h_byte = max(0, min(255, int(h * 255.0)))
                raw_rows.extend((h_byte, h_byte, h_byte))
        _write_png_grayscale(THEATERS_DIR / filename, size, raw_rows)


if __name__ == "__main__":
    generate_all_theaters(512)

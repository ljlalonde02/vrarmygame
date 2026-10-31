#!/usr/bin/env python3
"""
Generates crisp 128x80 tactical flag PNG textures for playable campaign nations:
USA, Taiwan (ROC), Poland, Ukraine, South Korea.
"""

import struct
import zlib
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "ui" / "flags"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def save_rgba_png(filepath: Path, width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> None:
    raw_rows = bytearray()
    for y in range(height):
        raw_rows.append(0)  # filter type 0
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw_rows.extend((r, g, b, a))

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    compressed = zlib.compress(bytes(raw_rows), 6)
    png_bytes = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
    filepath.write_bytes(png_bytes)
    print(f"Generated: {filepath}")


def make_usa(w=128, h=80):
    px = []
    canton_w = int(w * 0.45)
    canton_h = int(h * 0.54)
    for y in range(h):
        stripe = int(y / (h / 13.0))
        is_red = (stripe % 2 == 0)
        base_c = (190, 30, 45, 255) if is_red else (240, 240, 245, 255)
        for x in range(w):
            if x < canton_w and y < canton_h:
                # Blue canton with star points
                star_x = (x % 12 == 6)
                star_y = (y % 9 == 4)
                if star_x and star_y:
                    px.append((255, 255, 255, 255))
                else:
                    px.append((10, 35, 95, 255))
            else:
                px.append(base_c)
    return px


def make_taiwan(w=128, h=80):
    px = []
    canton_w = int(w * 0.5)
    canton_h = int(h * 0.5)
    cx, cy = canton_w // 2, canton_h // 2
    sun_r = 10
    for y in range(h):
        for x in range(w):
            if x < canton_w and y < canton_h:
                # Blue canton with white sun
                dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if dist < sun_r:
                    px.append((255, 255, 255, 255))
                elif dist < sun_r + 4 and ((abs(x - cx) <= 2) or (abs(y - cy) <= 2) or (abs(abs(x - cx) - abs(y - cy)) <= 2)):
                    px.append((255, 255, 255, 255))
                else:
                    px.append((0, 45, 140, 255))
            else:
                px.append((220, 20, 35, 255))
    return px


def make_poland(w=128, h=80):
    px = []
    for y in range(h):
        c = (250, 250, 255, 255) if y < h // 2 else (210, 25, 50, 255)
        for x in range(w):
            px.append(c)
    return px


def make_ukraine(w=128, h=80):
    px = []
    for y in range(h):
        c = (0, 90, 190, 255) if y < h // 2 else (255, 215, 0, 255)
        for x in range(w):
            px.append(c)
    return px


def make_south_korea(w=128, h=80):
    px = []
    cx, cy = w // 2, h // 2
    r_taegeuk = 18
    for y in range(h):
        for x in range(w):
            dx = x - cx
            dy = y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            # Four corner trigrams (black bars)
            in_trigram = False
            for tx, ty in [(-42, -24), (42, -24), (-42, 24), (42, 24)]:
                if abs(dx - tx) < 8 and abs(dy - ty) < 14 and (abs(dy - ty) % 5 <= 2):
                    in_trigram = True
                    break

            if in_trigram:
                px.append((20, 20, 25, 255))
            elif dist < r_taegeuk:
                # S-curve Taegeuk: top red, bottom blue
                if dy < 0 or (abs(dy) < 5 and dx > 0):
                    px.append((205, 30, 45, 255))  # Red (Yang)
                else:
                    px.append((0, 70, 160, 255))   # Blue (Eum)
            else:
                px.append((248, 248, 250, 255))
    return px


def main():
    W, H = 128, 80
    save_rgba_png(OUT_DIR / "usa.png", W, H, make_usa(W, H))
    save_rgba_png(OUT_DIR / "taiwan.png", W, H, make_taiwan(W, H))
    save_rgba_png(OUT_DIR / "poland.png", W, H, make_poland(W, H))
    save_rgba_png(OUT_DIR / "ukraine.png", W, H, make_ukraine(W, H))
    save_rgba_png(OUT_DIR / "south_korea.png", W, H, make_south_korea(W, H))
    print("All 5 nation flags generated successfully.")


if __name__ == "__main__":
    main()

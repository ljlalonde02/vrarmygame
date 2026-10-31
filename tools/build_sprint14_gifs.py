import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint14"

SCENARIOS = [
    ("sprint14_01", "sprint14_01_nation_selector_pedestal_3d_anim.gif"),
    ("sprint14_02", "sprint14_02_superpower_cycle_china_russia_anim.gif"),
    ("sprint14_03", "sprint14_03_theater_emp_scanline_blackout_anim.gif"),
    ("sprint14_04", "sprint14_04_full_bunker_panoramic_triad_anim.gif")
]

def build_gifs():
    for prefix, out_name in SCENARIOS:
        frames = []
        for i in range(8):
            fpath = os.path.join(TEMP_DIR, f"{prefix}_frame_{i:02d}.png")
            if os.path.exists(fpath):
                img = Image.open(fpath).convert("RGB")
                img = img.resize((960, 540), Image.Resampling.LANCZOS)
                frames.append(img)
        if frames:
            dst_art = os.path.join(ARTIFACT_DIR, out_name)
            dst_med = os.path.join(MEDIA_DIR, out_name)
            frames[0].save(dst_art, save_all=True, append_images=frames[1:], duration=150, loop=0)
            frames[0].save(dst_med, save_all=True, append_images=frames[1:], duration=150, loop=0)
            print(f"Generated {out_name} ({len(frames)} frames) -> {dst_med} & {dst_art}")

if __name__ == "__main__":
    build_gifs()

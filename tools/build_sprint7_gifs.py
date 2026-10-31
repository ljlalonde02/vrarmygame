import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint7"

SCENARIOS = [
    ("sprint7_01", "sprint7_01_command_radial_selection_anim.gif"),
    ("sprint7_02", "sprint7_02_tank_battalion_apfsds_muzzle_flash_anim.gif"),
    ("sprint7_03", "sprint7_03_helicopter_noe_infantry_suppression_anim.gif"),
    ("sprint7_04", "sprint7_04_submarine_sonar_match_victory_anim.gif")
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

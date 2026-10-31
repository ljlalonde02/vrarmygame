import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint3"

SCENARIOS = [
    ("sprint3_01", "sprint3_01_vr_interaction_smartwatch_anim.gif"),
    ("sprint3_02", "sprint3_02_logistics_convoy_airdrop_anim.gif"),
    ("sprint3_03", "sprint3_03_combined_arms_battalion_anim.gif"),
    ("sprint3_04", "sprint3_04_autonomous_playtester_anim.gif"),
    ("sprint3_05", "sprint3_05_unit_video_diegetic_hud_anim.gif")
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

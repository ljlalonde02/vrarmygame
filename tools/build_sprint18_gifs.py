import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint18"

SCENARIOS = [
    ("sprint18_01", "sprint18_01_welcome_onboarding_briefing_anim.gif"),
    ("sprint18_02", "sprint18_02_bootcamp_tutorial_interactive_beacon_anim.gif"),
    ("sprint18_03", "sprint18_03_desktop_hud_briefing_top_bar_anim.gif"),
    ("sprint18_04", "sprint18_04_3d_controls_plaque_bunker_view_anim.gif")
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

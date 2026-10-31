import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint20"

SCENARIOS = [
    ("sprint20_01_welcome_onboarding_fullscreen_briefing", "sprint20_01_welcome_onboarding_fullscreen_briefing_anim.gif"),
    ("sprint20_02_quick_controls_plaque_table_bezel", "sprint20_02_quick_controls_plaque_table_bezel_anim.gif"),
    ("sprint20_03_hypersonic_glide_and_specialized_munitions", "sprint20_03_hypersonic_glide_and_specialized_munitions_anim.gif"),
    ("sprint20_04_target_lock_rwr_threat_reticle", "sprint20_04_target_lock_rwr_threat_reticle_anim.gif")
]

def build_gifs():
    for base_name, out_name in SCENARIOS:
        frames = []
        for i in range(16):
            fpath = os.path.join(TEMP_DIR, f"{base_name}_frame_{i:03d}.png")
            if os.path.exists(fpath):
                img = Image.open(fpath).convert("RGB")
                img = img.resize((960, 540), Image.Resampling.LANCZOS)
                frames.append(img)
        if frames:
            dst_art = os.path.join(ARTIFACT_DIR, out_name)
            dst_med = os.path.join(MEDIA_DIR, out_name)
            frames[0].save(dst_art, save_all=True, append_images=frames[1:], duration=120, loop=0)
            frames[0].save(dst_med, save_all=True, append_images=frames[1:], duration=120, loop=0)
            print(f"Generated {out_name} ({len(frames)} frames) -> {dst_med} & {dst_art}")

if __name__ == "__main__":
    build_gifs()

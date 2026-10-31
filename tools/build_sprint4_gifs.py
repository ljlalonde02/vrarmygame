import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames_sprint4"

SCENARIOS = [
    ("sprint4_01", "sprint4_01_campaign_story_tree_3d_anim.gif"),
    ("sprint4_02", "sprint4_02_nation_selection_doctrine_anim.gif"),
    ("sprint4_03", "sprint4_03_branching_outcome_evaluation_anim.gif"),
    ("sprint4_04", "sprint4_04_ai_news_video_broadcast_anim.gif")
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

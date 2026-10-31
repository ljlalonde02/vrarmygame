import os
from PIL import Image

ARTIFACT_DIR = r"C:\Users\ljlal\.gemini\antigravity\brain\593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = r"c:\dev\vrarmygame\docs\media"
TEMP_DIR = r"c:\dev\vrarmygame\temp_frames"

gifs = [
    ("scale_01_frame_%02d.png", "speed_scale_01_combined_arms_anim.gif"),
    ("scale_02_frame_%02d.png", "speed_scale_02_helicopter_and_jet_anim.gif"),
    ("scale_03_frame_%02d.png", "speed_scale_03_submerged_submarine_anim.gif"),
    ("scale_04_frame_%02d.png", "speed_scale_04_hypersonic_missile_anim.gif"),
]

for pattern, out_name in gifs:
    frames = []
    for i in range(8):
        p = os.path.join(TEMP_DIR, pattern % i)
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            # Downscale slightly for smooth 60fps web display
            im = im.resize((960, 540), Image.Resampling.LANCZOS)
            frames.append(im)
    if frames:
        out_media = os.path.join(MEDIA_DIR, out_name)
        out_art = os.path.join(ARTIFACT_DIR, out_name)
        frames[0].save(out_media, save_all=True, append_images=frames[1:], duration=120, loop=0)
        frames[0].save(out_art, save_all=True, append_images=frames[1:], duration=120, loop=0)
        print(f"Generated {out_name} ({len(frames)} frames) -> {out_media} & {out_art}")

import os
import glob
from PIL import Image

ARTIFACT_DIR = "C:/Users/ljlal/.gemini/antigravity/brain/593a0e6d-a5db-4ce5-9ff8-a0255458bd47"
MEDIA_DIR = "c:/dev/vrarmygame/docs/media"
TEMP_DIR = "c:/dev/vrarmygame/temp_frames"

SECTIONS = [
    ("ssbn_frame_*.png", "us01_ssbn_periscope_anim.gif", 5),
    ("tacview_frame_*.png", "us02_aerial_combat_anim.gif", 6),
    ("floor_frame_*.png", "us04_holofloor_walk_anim.gif", 5),
    ("swarm_frame_*.png", "us06_swarm_flanking_anim.gif", 5),
]

def make_optimized_gif(pattern, out_name, fps=5):
    files = sorted(glob.glob(os.path.join(TEMP_DIR, pattern)))
    if not files:
        print(f"No frames for {pattern}")
        return
    
    images = []
    # Target 800x450 for crisp web and artifact rendering without excessive size
    target_size = (800, 450)
    for f in files:
        img = Image.open(f).convert("RGB")
        img = img.resize(target_size, Image.Resampling.LANCZOS)
        # Convert to adaptive 128-color palette for compact high-quality GIF
        img_p = img.convert("P", palette=Image.Palette.ADAPTIVE, colors=128)
        images.append(img_p)
    
    duration = int(1000.0 / fps)
    
    out_media = os.path.join(MEDIA_DIR, out_name)
    out_artifact = os.path.join(ARTIFACT_DIR, out_name)
    
    images[0].save(
        out_media,
        save_all=True,
        append_images=images[1:],
        duration=duration,
        loop=0,
        optimize=True
    )
    
    images[0].save(
        out_artifact,
        save_all=True,
        append_images=images[1:],
        duration=duration,
        loop=0,
        optimize=True
    )
    
    print(f"Generated {out_name}: {len(images)} frames -> {out_media} & {out_artifact}")

if __name__ == "__main__":
    for pattern, out_name, fps in SECTIONS:
        make_optimized_gif(pattern, out_name, fps)

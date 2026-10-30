import sys
import os
import glob
from PIL import Image

def make_gif(frame_pattern, output_path, fps=8, loop=0, resize=None):
    files = sorted(glob.glob(frame_pattern))
    if not files:
        print(f"No frames found for pattern: {frame_pattern}")
        return False
    
    images = []
    for f in files:
        img = Image.open(f)
        if resize:
            img = img.resize(resize, Image.Resampling.LANCZOS)
        images.append(img.convert("RGB"))
        
    duration = int(1000.0 / fps)
    images[0].save(
        output_path,
        save_all=True,
        append_images=images[1:],
        duration=duration,
        loop=loop,
        optimize=True
    )
    print(f"Generated GIF: {output_path} ({len(images)} frames, {duration}ms/frame)")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python build_gif_anim.py <frame_pattern> <output_path> [fps]")
        sys.exit(1)
    pattern = sys.argv[1]
    out = sys.argv[2]
    fps = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    make_gif(pattern, out, fps)

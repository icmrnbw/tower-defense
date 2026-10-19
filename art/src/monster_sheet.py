"""Review sheet: assemble each built monster's rest pose from its atlas + json.

Usage: python3 monster_sheet.py OUT.png [id ...]
"""
import json
import os
import sys

from PIL import Image, ImageDraw

from monster_kit import OUT


def assemble(mid, cell=300):
    meta = json.load(open(os.path.join(OUT, mid + ".json")))
    atlas = Image.open(os.path.join(OUT, mid + ".png"))
    h = meta["height"]
    w_units, h_units = h * 1.6, h * 1.3
    if meta.get("style") == "worm":
        w_units, h_units = h * 5, h * 1.6
    k = cell / w_units
    canvas = Image.new("RGBA", (int(w_units * k), int(h_units * k)), (58, 74, 50, 255))
    ox, oy = w_units * (0.75 if meta.get("style") == "worm" else 0.5), h_units * 0.88
    for p in meta["parts"]:
        x, y, w, hh = p["rect"]
        img = atlas.crop((x, y, x + w, y + hh))
        size = (max(1, int(p["size"][0] * k)), max(1, int(p["size"][1] * k)))
        img = img.resize(size, Image.LANCZOS)
        pos = (int((p["origin"][0] + ox) * k), int((p["origin"][1] + oy) * k))
        if p["name"] == "seg":
            for i in range(meta.get("segments", 4), 0, -1):
                canvas.alpha_composite(img, (pos[0] - int(i * meta.get("spacing", 20) * k), pos[1]))
        elif p["name"] == "tail":
            canvas.alpha_composite(img, (pos[0] - int((meta.get("segments", 4) + 1) * meta.get("spacing", 20) * k), pos[1]))
        else:
            canvas.alpha_composite(img, pos)
    ImageDraw.Draw(canvas).text((6, 4), mid, fill=(255, 255, 255, 255))
    return canvas


if __name__ == "__main__":
    out = sys.argv[1]
    ids = sys.argv[2:] or sorted(f[:-5] for f in os.listdir(OUT) if f.endswith(".json"))
    imgs = [assemble(i) for i in ids]
    cols = min(4, len(imgs))
    cw = max(i.width for i in imgs)
    ch = max(i.height for i in imgs)
    sheet = Image.new("RGBA", (cw * cols, ch * ((len(imgs) + cols - 1) // cols)), (40, 50, 36, 255))
    for n, im in enumerate(imgs):
        sheet.paste(im, ((n % cols) * cw, (n // cols) * ch))
    sheet.save(out)

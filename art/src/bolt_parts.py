"""Bolt Turret split into parts for in-game animation.

The game draws the base sprite, then the turret sprite rotated toward its target. For the
crossbow states (L1-L3) the bow limbs and string are drawn in code so the string can be
pulled back and snap forward; the loaded bolt is its own sprite that rides on the string.

Usage: python3 bolt_parts.py  -> writes game/art/towers/bolt/parts/*
"""
import json
import os
import subprocess

import bolt as B
from common import MATERIALS, PIVOT, defs, pad

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "game", "art", "towers", "bolt", "parts")
TURRET_SIZE = 768  # turret canvas; the mount point sits at its centre

# Crossbow states: bow(y, span, sweep, mat, tip_mat, w) and bolts(xs, back, tip, head, shaft)
BOWS = {
    "l1": dict(y=-112, span=92, sweep=34, mat="wood", tip="brass", w=10,
               xs=[0], back=-40, tip_y=-178, head="iron", shaft="wood"),
    "l2": dict(y=-118, span=100, sweep=36, mat="steel", tip="brass", w=11,
               xs=[-15, 15], back=-40, tip_y=-186, head="steel", shaft="wood"),
    "l3": dict(y=-142, span=112, sweep=40, mat="steel", tip="gold", w=12,
               xs=[-16, 16], back=-44, tip_y=-214, head="gold", shaft="iron"),
}


def turret_body(state):
    """Turret without bow, string or bolts (crossbows) or the full turret (heavy branches)."""
    if state == "l1":
        return B.rail(0, -150, -30, 20, "wood") + B.housing_l1()
    if state == "l2":
        return B.rail(-15, -160, -30, 18, "iron") + B.rail(15, -160, -30, 18, "iron") + B.housing_l2()
    if state == "l3":
        return (B.rail(-16, -196, -30, 20, "steel") + B.rail(16, -196, -30, 20, "steel")
                + B.energy_line(-16, -190, -48) + B.energy_line(16, -190, -48)
                + B.housing_l3() + B.crest(-58))
    return B.TURRETS[state]()


def wrap(body, size, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
            f'viewBox="0 0 {size} {size}"><title>{title}</title>{defs()}{body}</svg>\n')


def main():
    os.makedirs(OUT, exist_ok=True)
    meta = {"turret_size": TURRET_SIZE, "states": {}}
    jobs = []
    c = TURRET_SIZE / 2
    for st in B.STATES if hasattr(B, "STATES") else ["l1", "l2", "l3", "l4a", "l5a", "l4b", "l5b"]:
        s = B.SCALE[st]
        b, (cx, top) = B.base(st, s)
        files = {"base": wrap(pad() + b, 512, f"bolt_{st}_base"),
                 "turret": wrap(f'<g transform="translate({c},{c}) scale({s:.3f})">{turret_body(st)}</g>',
                                TURRET_SIZE, f"bolt_{st}_turret")}
        info = {"mount": [cx, top], "scale": s}
        if st in BOWS:
            bw = BOWS[st]
            length = bw["back"] - bw["tip_y"]
            bolts = "".join(B.bolt(x, 0, -length, head=bw["head"], shaft=bw["shaft"]) for x in bw["xs"])
            files["bolt"] = wrap(f'<g transform="translate({c},{c}) scale({s:.3f})">{bolts}</g>',
                                 TURRET_SIZE, f"bolt_{st}_bolt")
            info["bow"] = {k: bw[k] for k in ("y", "span", "sweep", "w")}
            info["bow"]["colors"] = list(MATERIALS[bw["mat"]])
            info["bow"]["tip_colors"] = list(MATERIALS[bw["tip"]])
            info["bolt"] = {"back": bw["back"], "length": length, "drawn": -36}
        meta["states"][st] = info
        for part, text in files.items():
            svg_path = os.path.join(OUT, f"{st}_{part}.svg")
            with open(svg_path, "w") as f:
                f.write(text)
            jobs.append((part, os.path.join(OUT, f"{st}_{part}.png"), svg_path))
    for size in (512, TURRET_SIZE):
        args = []
        for part, png, svg_path in jobs:
            if (size == 512) == (part == "base"):
                args += [png, svg_path]
        subprocess.run(["node", os.path.join(HERE, "render.mjs"), str(size), *args], check=True, cwd=HERE)
    for _, _, svg_path in jobs:
        os.remove(svg_path)
    meta["pivot"] = list(PIVOT)
    with open(os.path.join(OUT, "parts.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("wrote", OUT)


if __name__ == "__main__":
    main()

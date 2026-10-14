"""Write SVGs, render 512px PNGs and a preview sheet for the given towers.

Usage: python3 build.py bolt [cannon ...]
"""
import importlib
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.dirname(HERE)
STATES = ["l1", "l2", "l3", "l4a", "l5a", "l4b", "l5b"]

for tower in sys.argv[1:]:
    mod = importlib.import_module(tower)
    out = os.path.join(ART, "towers", tower)
    os.makedirs(os.path.join(out, "svg"), exist_ok=True)
    os.makedirs(os.path.join(out, "png"), exist_ok=True)
    args = []
    for st in STATES:
        name = f"tower_{tower}_{st}"
        svg_path = os.path.join(out, "svg", name + ".svg")
        with open(svg_path, "w") as f:
            f.write(mod.build(st))
        args += [os.path.join(out, "png", name + ".png"), svg_path]
    subprocess.run(["node", os.path.join(HERE, "render.mjs"), "512", *args], check=True, cwd=HERE)
    # preview sheet: L1 L2 L3 / L4A L5A / L4B L5B on a dark backdrop
    pngs = [a for a in args[0::2]]
    sheet = os.path.join(ART, "previews", f"{tower}_sheet.png")
    os.makedirs(os.path.dirname(sheet), exist_ok=True)
    def tile(p, bg):
        return ["(", p, "-background", bg, "-flatten", ")"]
    rows = [(pngs[:3], "#26303d"), (pngs[3:5], "#3a2f4a"), (pngs[5:7], "#2c4038")]
    cmd = ["convert"]
    for row, bg in rows:
        cmd += ["("] + sum((tile(p, bg) for p in row), []) + ["+append", ")"]
    cmd += ["-background", "#1b2129", "-gravity", "center", "-append", "-resize", "50%", sheet]
    subprocess.run(cmd, check=True)
    print("wrote", sheet)

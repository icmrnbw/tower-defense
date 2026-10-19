"""Shape kit and build pipeline for rigged monster sprites.

Each monster is drawn in side view facing right, feet at (0, 0), up is -y, in "units".
A monster is a list of parts; each part is SVG drawn in assembled (rest pose) coordinates
plus a pivot (its joint), a parent and an animation spec the game plays procedurally.

build(monster) renders every part with headless Chromium, trims it, packs all parts and a
white silhouette copy of each (for hit flashes and status tints) into one atlas PNG, and
writes game/art/monsters/<id>.png + <id>.json.
"""
import json
import math
import os
import subprocess
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "game", "art", "monsters")
OL = "#1c1724"

# name: (light, mid, dark)
MATS = {
    "goblin":  ("#b9e070", "#6fae3a", "#2f5a1a"),
    "hob":     ("#ffb880", "#d8743a", "#7a3414"),
    "robe":    ("#8ae8c8", "#2f9a7a", "#0f4a3a"),
    "orc":     ("#a9bc84", "#6c8452", "#33422a"),
    "troll":   ("#8fe0cc", "#3fa890", "#17504a"),
    "ogre":    ("#f0c8a0", "#c08860", "#6a4430"),
    "imp":     ("#d8b0ff", "#9b6bd6", "#4a2a7a"),
    "leather": ("#c89060", "#8a5a30", "#4a2c16"),
    "dleather": ("#8a6a50", "#5a4030", "#2c1c12"),
    "wood":    ("#e0a466", "#a8682f", "#5b3312"),
    "red":     ("#ff8a70", "#c83a30", "#6a1418"),
    "blue":    ("#8ab8ff", "#3f6fd0", "#1a2e6a"),
    "teal":    ("#9ff0d8", "#3fbf98", "#1a5a48"),
    "purple":  ("#c8a0ff", "#7a4ad0", "#301a5a"),
    "bone":    ("#fff8e6", "#e2d0a8", "#8a7a58"),
    "iron":    ("#a0a8b8", "#5a6272", "#262a34"),
    "steel":   ("#f2f6fa", "#a9b6c5", "#4d5b6c"),
    "dsteel":  ("#9aa7b8", "#56616f", "#232a36"),
    "gold":    ("#fff3a8", "#f2c230", "#9a600a"),
    "brass":   ("#ffd98a", "#d49a35", "#7a4a10"),
    "fur":     ("#cbbfa8", "#8a7d68", "#40382c"),
    "furtan":  ("#f0d090", "#c0904a", "#6a4a1c"),
    "bat":     ("#8a78b0", "#4a3c6a", "#1c1630"),
    "batwing": ("#b090d0", "#6a4a9a", "#2a1a48"),
    "ghost":   ("#ffffff", "#c8baff", "#6a58c0"),
    "wyvern":  ("#b8cce0", "#6f87a0", "#2e3e52"),
    "worm":    ("#f0b080", "#b0703c", "#5a3418"),
    "flesh":   ("#ff9aa8", "#d04a60", "#6a1828"),
    "sand":    ("#ffe6a8", "#d9a650", "#7a5420"),
    "ice":     ("#ffffff", "#a8daf8", "#3c78b0"),
    "mummy":   ("#fff4d8", "#d8c89a", "#7a6a48"),
    "stone":   ("#d0c8bc", "#8a8278", "#423c36"),
    "moss":    ("#b8e070", "#6a9a3a", "#2a4a1a"),
    "shell":   ("#9ab0c8", "#4a5a70", "#161c28"),
    "thorn":   ("#b0c070", "#6b8a3a", "#2a3c18"),
    "void":    ("#a070d0", "#4a2a7a", "#140a24"),
    "voidskin": ("#7a6aa0", "#3a2a5a", "#120a20"),
    "magenta": ("#ffb0f8", "#e04ad8", "#701a6a"),
    "char":    ("#7a8494", "#3e4656", "#14181f"),
    "ember":   ("#fff0a0", "#ff9a2f", "#b8380a"),
    "black":   ("#4a4458", "#24202e", "#0c0a12"),
}


# ---------------------------------------------------------------- svg helpers

def grad_defs():
    out = []
    for name, (a, b, c) in MATS.items():
        out.append(f'<linearGradient id="l_{name}" x1="0.1" y1="0" x2="0.8" y2="1">'
                   f'<stop offset="0" stop-color="{a}"/><stop offset="0.5" stop-color="{b}"/>'
                   f'<stop offset="1" stop-color="{c}"/></linearGradient>')
        out.append(f'<radialGradient id="r_{name}" cx="0.36" cy="0.3" r="0.85">'
                   f'<stop offset="0" stop-color="{a}"/><stop offset="0.5" stop-color="{b}"/>'
                   f'<stop offset="1" stop-color="{c}"/></radialGradient>')
    return "".join(out)


def fill_of(mat, radial=True):
    if mat is None:
        return "none"
    if mat.startswith("#") or mat.startswith("url") or mat == "none":
        return mat
    return f"url(#{'r' if radial else 'l'}_{mat})"


def _shape(tag, mat, sw, radial, extra, **a):
    attrs = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in a.items())
    stroke = f'stroke="{OL}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"' if sw else ""
    return f'<{tag} {attrs} fill="{fill_of(mat, radial)}" {stroke} {extra}/>'


def ell(cx, cy, rx, ry, mat, sw=3, radial=True, rot=0, extra=""):
    t = f'transform="rotate({rot} {cx} {cy})" ' if rot else ""
    return _shape("ellipse", mat, sw, radial, t + extra, cx=f"{cx:.1f}", cy=f"{cy:.1f}", rx=f"{rx:.1f}", ry=f"{ry:.1f}")


def circ(cx, cy, r, mat, sw=3, radial=True, extra=""):
    return _shape("circle", mat, sw, radial, extra, cx=f"{cx:.1f}", cy=f"{cy:.1f}", r=f"{r:.1f}")


def path(d, mat, sw=3, radial=True, extra=""):
    return _shape("path", mat, sw, radial, extra, d=d)


def poly(pts, mat, sw=3, radial=False, extra=""):
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    return path(d, mat, sw, radial, extra)


def smooth_d(pts, closed=True, tension=0.5):
    """Catmull-Rom spline through pts as an SVG path."""
    n = len(pts)
    if n < 3:
        return "M" + " L".join(f"{x},{y}" for x, y in pts)
    d = f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed or i > 0 else pts[0]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed or i + 2 < n else pts[-1]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 3, p1[1] + (p2[1] - p0[1]) * tension / 3)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 3, p2[1] - (p3[1] - p1[1]) * tension / 3)
        d += f" C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}"
    return d + (" Z" if closed else "")


def blob(pts, mat, sw=3, radial=True, extra=""):
    return path(smooth_d(pts), mat, sw, radial, extra)


def limb(p1, p2, w1, w2, mat, sw=3, radial=False):
    """Tapered capsule from p1 (width w1) to p2 (width w2)."""
    (x1, y1), (x2, y2) = p1, p2
    a = math.atan2(y2 - y1, x2 - x1)
    nx, ny = -math.sin(a), math.cos(a)
    r1, r2 = w1 / 2, w2 / 2
    d = (f"M{x1 + nx*r1:.1f},{y1 + ny*r1:.1f} L{x2 + nx*r2:.1f},{y2 + ny*r2:.1f} "
         f"A{r2:.1f},{r2:.1f} 0 0 0 {x2 - nx*r2:.1f},{y2 - ny*r2:.1f} "
         f"L{x1 - nx*r1:.1f},{y1 - ny*r1:.1f} A{r1:.1f},{r1:.1f} 0 0 0 {x1 + nx*r1:.1f},{y1 + ny*r1:.1f} Z")
    return path(d, mat, sw, radial)


def stroke(d, color, w, opacity=1.0, cap="round"):
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="{cap}" '
            f'stroke-linejoin="round" opacity="{opacity}"/>')


def hl(d, opacity=0.35):
    """Soft white highlight shape."""
    return f'<path d="{d}" fill="#ffffff" opacity="{opacity}"/>'


def hl_ell(cx, cy, rx, ry, opacity=0.3, rot=0):
    t = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
    return f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="#ffffff" opacity="{opacity}"{t}/>'


def eye(cx, cy, r, color, pupil=True):
    """Glowing eye: drawn into the part's glow layer (no paint filter)."""
    out = (f'<circle cx="{cx}" cy="{cy}" r="{r*2.6:.1f}" fill="{color}" opacity="0.55" filter="url(#blur)"/>'
           f'<circle cx="{cx}" cy="{cy}" r="{r+1.2:.1f}" fill="{OL}"/>'
           f'<circle cx="{cx}" cy="{cy}" r="{r:.1f}" fill="{color}"/>'
           f'<circle cx="{cx+r*0.15:.1f}" cy="{cy-r*0.1:.1f}" r="{r*0.5:.1f}" fill="#ffffff"/>')
    if pupil:
        out += f'<ellipse cx="{cx+r*0.35:.1f}" cy="{cy:.1f}" rx="{r*0.22:.1f}" ry="{r*0.6:.1f}" fill="{OL}"/>'
    return out


def glowdot(cx, cy, r, color, core="#ffffff"):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r*2.4:.1f}" fill="{color}" opacity="0.6" filter="url(#blur)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r:.1f}" fill="{color}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*0.45:.1f}" fill="{core}"/>')


def glowpath(d, color, w, core="#ffffff"):
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w*2.6}" opacity="0.55" '
            f'stroke-linecap="round" filter="url(#blur)"/>'
            + stroke(d, color, w) + stroke(d, core, w * 0.35))


# ---------------------------------------------------------------- parts

def part(name, svg, pivot, z, parent=None, anim=None, glow="", shade=False):
    return {"name": name, "svg": svg, "pivot": list(pivot), "z": z, "parent": parent,
            "anim": anim or {}, "glow": glow, "shade": shade}


def swing(amp, phase=0.0, base=0.0, freq=1.0):
    return {"type": "swing", "amp": amp, "phase": phase, "base": base, "freq": freq}


def flap(amp, phase=0.0, base=0.0):
    return {"type": "flap", "amp": amp, "phase": phase, "base": base}


def bob(amp, phase=0.0, freq=2.0):
    return {"type": "bob", "amp": amp, "phase": phase, "freq": freq}


def filters(rim, seed):
    return (
        f'<filter id="paint" x="-0.1" y="-0.1" width="1.2" height="1.2" '
        f'color-interpolation-filters="sRGB">'
        # rim light: band just inside the outline along the top/back edge
        f'<feMorphology in="SourceAlpha" operator="erode" radius="2" result="e1"/>'
        f'<feOffset in="e1" dx="-2.5" dy="3.5" result="e2"/>'
        f'<feComposite in="e1" in2="e2" operator="out" result="edge"/>'
        f'<feGaussianBlur in="edge" stdDeviation="0.9" result="edgeb"/>'
        f'<feFlood flood-color="{rim}" flood-opacity="0.6"/>'
        f'<feComposite in2="edgeb" operator="in" result="rim"/>'
        f'<feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="rim"/></feMerge></filter>'
        '<filter id="shade" color-interpolation-filters="sRGB"><feComponentTransfer>'
        '<feFuncR type="linear" slope="0.68"/><feFuncG type="linear" slope="0.66"/>'
        '<feFuncB type="linear" slope="0.74"/></feComponentTransfer></filter>'
        '<filter id="blur" x="-2" y="-2" width="5" height="5"><feGaussianBlur stdDeviation="2.4"/></filter>'
        '<filter id="blurbig" x="-2" y="-2" width="5" height="5"><feGaussianBlur stdDeviation="6"/></filter>'
    )


def shadow_part(width, height=None):
    h = height or width * 0.32
    s = (f'<radialGradient id="sh"><stop offset="0" stop-color="#000" stop-opacity="0.5"/>'
         f'<stop offset="0.6" stop-color="#000" stop-opacity="0.28"/>'
         f'<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
         f'<ellipse cx="0" cy="0" rx="{width/2}" ry="{h/2}" fill="url(#sh)"/>')
    return {"name": "shadow", "svg": s, "pivot": [0, 0], "z": -100, "parent": None, "anim": {},
            "glow": "", "shade": False, "raw": True}


# ---------------------------------------------------------------- build

def paint_noise(im, seed, strength=0.26, cell=10):
    """Painterly mottling: multiply RGB by smooth multi-octave value noise (alpha untouched)."""
    import random
    rnd = random.Random(seed)
    w, h = im.size
    acc = None
    amp_total = 0.0
    for octave, amp in ((cell * 2.2, 0.55), (cell, 0.3), (cell * 0.45, 0.15)):
        gw, gh = max(2, int(w / octave) + 2), max(2, int(h / octave) + 2)
        small = Image.new("L", (gw, gh))
        small.putdata([rnd.randint(0, 255) for _ in range(gw * gh)])
        layer = small.resize((w, h), Image.BICUBIC)
        acc = layer if acc is None else Image.blend(acc, layer, amp / (amp_total + amp))
        amp_total += amp
    r, g, b, a = im.split()
    lut = [int(255 * (1 - strength + strength * v / 255)) for v in range(256)]
    mult = acc.point(lut)
    from PIL import ImageChops
    r, g, b = (ImageChops.multiply(c, mult) for c in (r, g, b))
    # multiply darkens: lift back so the mean stays the same
    lift = [min(255, int(v / (1 - strength / 2))) for v in range(256)]
    return Image.merge("RGBA", (r.point(lift), g.point(lift), b.point(lift), a))


def _svg_doc(content, vb, px_w, px_h, rim, seed):
    x0, y0, w, h = vb
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px_w}" height="{px_h}" '
            f'viewBox="{x0} {y0} {w} {h}"><defs>{grad_defs()}{filters(rim, seed)}</defs>{content}</svg>')


def build(m):
    """m: dict(id, style, height, px_h, fit, rim, motion, parts, extra...)"""
    os.makedirs(OUT, exist_ok=True)
    if "px_h" not in m:
        m["px_h"] = int(max(56, 2.6 * m["r"] * m["fit"]))
    k = m["px_h"] / m["height"]  # px per unit
    # generous canvas around the rest pose
    span = m.get("canvas", (m["height"] * 2.6, m["height"] * 1.6))
    vb = (-span[0] / 2 + m.get("canvas_dx", 0), -span[1] + m["height"] * 0.3, span[0], span[1])
    px_w, px_h = int(vb[2] * k), int(vb[3] * k)
    tmp = tempfile.mkdtemp()
    jobs = []
    seed = abs(hash(m["id"])) % 997
    for i, p in enumerate(m["parts"]):
        if p.get("raw"):
            content = p["svg"]
        else:
            body = f'<g filter="url(#paint)">{p["svg"]}</g>'
            if p["shade"]:
                body = f'<g filter="url(#shade)">{body}</g>'
            content = body + p["glow"]
        svg_path = os.path.join(tmp, f"{i}.svg")
        with open(svg_path, "w") as f:
            f.write(_svg_doc(content, vb, px_w, px_h, m["rim"], seed))
        jobs.append({"svg": svg_path, "png": os.path.join(tmp, f"{i}.png"), "w": px_w, "h": px_h})
    with open(os.path.join(tmp, "jobs.json"), "w") as f:
        json.dump(jobs, f)
    subprocess.run(["node", os.path.join(HERE, "render_parts.mjs"), os.path.join(tmp, "jobs.json")],
                   check=True, cwd=HERE)
    # trim, then shelf-pack normal + silhouette images
    images = []
    for p, j in zip(m["parts"], jobs):
        im = Image.open(j["png"]).convert("RGBA")
        if not p.get("raw"):
            im = paint_noise(im, seed + len(images), cell=max(4, k * 6))
        bb = im.getbbox()
        if bb is None:
            raise RuntimeError(f"{m['id']}: part {p['name']} is empty")
        bb = (max(bb[0] - 2, 0), max(bb[1] - 2, 0), min(bb[2] + 2, im.width), min(bb[3] + 2, im.height))
        crop = im.crop(bb)
        sil = Image.new("RGBA", crop.size, (255, 255, 255, 0))
        sil.putalpha(crop.getchannel("A"))
        images.append((p, bb, crop, sil))
    atlas_w = 1024 if px_h > 300 else 512
    while True:
        placements, x, y, row_h = [], 1, 1, 0
        for _, _, crop, sil in images:
            for img in (crop, sil):
                if x + img.width + 1 > atlas_w:
                    x, y, row_h = 1, y + row_h + 1, 0
                placements.append((x, y))
                x += img.width + 1
                row_h = max(row_h, img.height)
        total_h = y + row_h + 1
        if total_h <= atlas_w * 2 or atlas_w >= 2048:
            break
        atlas_w *= 2
    atlas = Image.new("RGBA", (atlas_w, total_h), (0, 0, 0, 0))
    parts_meta = []
    for idx, (p, bb, crop, sil) in enumerate(images):
        pa, ps = placements[idx * 2], placements[idx * 2 + 1]
        atlas.paste(crop, pa)
        atlas.paste(sil, ps)
        origin = (vb[0] + bb[0] / k, vb[1] + bb[1] / k)
        parts_meta.append({
            "name": p["name"], "parent": p["parent"], "z": p["z"], "anim": p["anim"],
            "pivot": [round(v, 2) for v in p["pivot"]],
            "origin": [round(origin[0], 2), round(origin[1], 2)],
            "size": [round(crop.width / k, 2), round(crop.height / k, 2)],
            "rect": [pa[0], pa[1], crop.width, crop.height],
            "sil": [ps[0], ps[1], sil.width, sil.height],
        })
    parts_meta.sort(key=lambda q: q["z"])
    atlas.save(os.path.join(OUT, m["id"] + ".png"))
    meta = {k2: m[k2] for k2 in ("style", "height", "fit", "motion") if k2 in m}
    meta.update(m.get("extra", {}))
    meta["parts"] = parts_meta
    with open(os.path.join(OUT, m["id"] + ".json"), "w") as f:
        json.dump(meta, f, indent=1)
    return os.path.join(OUT, m["id"] + ".png")


def preview(m, path_out):
    """Assembled rest pose (for review sheets)."""
    k = 3.0
    h = m["height"]
    vb = (-h * 0.9 + m.get("canvas_dx", 0), -h * 1.15, h * 1.8, h * 1.3)
    content = ""
    for p in sorted(m["parts"], key=lambda q: q["z"]):
        if p.get("raw"):
            content += p["svg"]
            continue
        body = f'<g filter="url(#paint)">{p["svg"]}</g>'
        if p["shade"]:
            body = f'<g filter="url(#shade)">{body}</g>'
        content += body + p["glow"]
    return _svg_doc(content, vb, int(vb[2] * k), int(vb[3] * k), m["rim"], 7)


# ================================================================ shared biped pieces

def leg(name, hip, foot, w, mat, boot, z, phase, amp=0.55, shade=False, boot_len=1.0):
    """Leg from hip to ankle with a boot/foot pointing forward."""
    hx, hy = hip
    fx, fy = foot
    knee = ((hx + fx) / 2 + w * 0.35, (hy + fy) / 2)
    svg = (limb(hip, knee, w * 1.15, w, mat) + limb(knee, (fx, fy - w * 0.4), w, w * 0.85, mat)
           + blob([(fx - w * 0.7, fy - w * 1.1), (fx + w * 0.4, fy - w * 1.2), (fx + w * 1.5 * boot_len, fy - w * 0.4),
                   (fx + w * 1.6 * boot_len, fy), (fx - w * 0.8, fy)], boot))
    return part(name, svg, hip, z, anim=swing(amp, phase), shade=shade)


def arm(name, shoulder, hand, w, mat, z, phase, amp=0.5, hand_mat=None, shade=False, parent="torso", fist=1.0):
    sx, sy = shoulder
    hx, hy = hand
    elbow = ((sx + hx) / 2 - w * 0.2, (sy + hy) / 2)
    svg = (limb(shoulder, elbow, w * 1.1, w * 0.95, mat) + limb(elbow, hand, w * 0.95, w * 0.85, mat)
           + circ(hx, hy, w * 0.75 * fist, hand_mat or mat))
    return part(name, svg, shoulder, z, parent=parent, anim=swing(amp, phase), shade=shade)

"""Shared helpers for hand-authored tower sprites (512x512 SVG).

View: top-down three-quarter, light from top-left, bold dark outlines,
cel-shaded diagonal gradients. Each tower module builds SVG strings with
these helpers; render.mjs turns them into transparent PNGs.
"""
import math

SIZE = 512
OL = "#1c1724"          # outline colour
PIVOT = (256, 372)      # centre of the pad's top face

# name: (light, mid, dark)
MATERIALS = {
    "wood":   ("#e0a466", "#a8682f", "#6b3d18"),
    "iron":   ("#8a93a3", "#555d6b", "#2c313b"),
    "steel":  ("#f2f6fa", "#a9b6c5", "#5d6b7c"),
    "dsteel": ("#9aa7b8", "#5b6677", "#2e3542"),
    "gold":   ("#fff3a8", "#f2c230", "#a8700f"),
    "brass":  ("#ffd98a", "#d49a35", "#8a5a18"),
    "white":  ("#ffffff", "#e8eef5", "#aab6c6"),
    "yellow": ("#fffbd0", "#ffd21f", "#d88f00"),
    "stone":  ("#d3cbbd", "#a69d8e", "#7a7164"),
    "stoneside": ("#857c6f", "#6d6559", "#4f4940"),
}


def defs(extra=""):
    grads = []
    for name, (a, b, c) in MATERIALS.items():
        grads.append(
            f'<linearGradient id="g_{name}" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{a}"/><stop offset="0.55" stop-color="{b}"/>'
            f'<stop offset="1" stop-color="{c}"/></linearGradient>'
        )
    return (
        "<defs>" + "".join(grads) +
        '<radialGradient id="g_glow"><stop offset="0" stop-color="#fffef0"/>'
        '<stop offset="0.35" stop-color="#ffe23d"/><stop offset="1" stop-color="#ffb800" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="g_core"><stop offset="0" stop-color="#ffffff"/>'
        '<stop offset="0.45" stop-color="#fff27a"/><stop offset="1" stop-color="#ffb300"/></radialGradient>'
        '<radialGradient id="g_shadow"><stop offset="0" stop-color="#000" stop-opacity="0.45"/>'
        '<stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
        '<filter id="blur4" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4"/></filter>'
        '<filter id="blur8" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>'
        '<filter id="blur16" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter>'
        + extra + "</defs>"
    )


def fill(mat):
    return f"url(#g_{mat})"


def shape(tag, mat=None, sw=5, color=None, extra="", **a):
    attrs = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in a.items())
    f = color if color else (fill(mat) if mat else "none")
    stroke = f'stroke="{OL}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"' if sw else ""
    return f'<{tag} {attrs} fill="{f}" {stroke} {extra}/>'


def rect(x, y, w, h, mat=None, rx=0, **k):
    return shape("rect", mat, x=x, y=y, width=w, height=h, rx=rx, **k)


def circle(cx, cy, r, mat=None, **k):
    return shape("circle", mat, cx=cx, cy=cy, r=r, **k)


def ellipse(cx, cy, rx, ry, mat=None, **k):
    return shape("ellipse", mat, cx=cx, cy=cy, rx=rx, ry=ry, **k)


def path(d, mat=None, **k):
    return shape("path", mat, d=d, **k)


def glow(inner, blur="blur8", opacity=0.9):
    """Blurred copy behind an emissive element."""
    return f'<g filter="url(#{blur})" opacity="{opacity}">{inner}</g>'


def highlight(d, opacity=0.35):
    return f'<path d="{d}" fill="#ffffff" opacity="{opacity}"/>'


def gear(cx, cy, r, teeth=10, depth=7, mat="brass", sw=4):
    pts = []
    n = teeth * 2
    for i in range(n * 2):
        ang = math.pi * 2 * i / (n * 2)
        rr = r if (i // 2) % 2 == 0 else r - depth
        pts.append(f"{cx + rr * math.cos(ang):.1f},{cy + rr * math.sin(ang):.1f}")
    return (path("M" + " L".join(pts) + "Z", mat, sw=sw) +
            circle(cx, cy, r * 0.38, "dsteel", sw=sw))


def cylinder(cx, cy, rx, h, mat, top_mat=None, sw=5, ratio=0.57):
    """Upright cylinder whose top ellipse is centred at (cx, cy)."""
    ry = rx * ratio
    side = (f"M{cx-rx},{cy} L{cx-rx},{cy+h} A{rx},{ry} 0 0 0 {cx+rx},{cy+h} "
            f"L{cx+rx},{cy} Z")
    return path(side, mat, sw=sw) + ellipse(cx, cy, rx, ry, top_mat or mat, sw=sw)


def pad():
    """Square stone build pad, shared by every tower."""
    x0, x1, y0, y1, t = 96, 416, 290, 466, 24
    out = [ellipse(256, y1 + 14, 190, 30, color="url(#g_shadow)", sw=0)]
    out.append(rect(x0, y0 + t, x1 - x0, y1 - y0, "stoneside", rx=30))
    out.append(rect(x0, y0, x1 - x0, y1 - y0, "stone", rx=30))
    # slab seams
    seams = []
    for x in (203, 309):
        seams.append(f"M{x},{y0+10} L{x},{y1-10}")
    for y in (349, 407):
        seams.append(f"M{x0+10},{y} L{x1-10},{y}")
    out.append(f'<path d="{" ".join(seams)}" stroke="#6f675b" stroke-width="3" opacity="0.55" fill="none"/>')
    out.append(highlight(f"M{x0+30},{y0+6} L{x1-40},{y0+6} L{x1-60},{y0+16} L{x0+20},{y0+16} Z", 0.4))
    # corner studs
    for (x, y) in ((x0 + 22, y0 + 20), (x1 - 22, y0 + 20), (x0 + 22, y1 - 20), (x1 - 22, y1 - 20)):
        out.append(circle(x, y, 7, "iron", sw=3))
    return "".join(out)


def svg(body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
            f'viewBox="0 0 {SIZE} {SIZE}"><title>{title}</title>{defs()}{body}</svg>\n')

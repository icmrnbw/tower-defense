"""Bolt Turret: brass + electric yellow crossbow turret on a round swivel base."""
from common import *

# Footprint follows the prompt guide (L1 ~55% of pad ... L5 ~85%); L4/L5 parts are
# drawn larger in local space, so their scale factor is lower.
SCALE = {"l1": 0.95, "l2": 1.05, "l3": 1.15, "l4a": 1.0, "l5a": 1.08, "l4b": 1.0, "l5b": 1.08}
AIM = 35  # degrees clockwise from straight up


def band(cx, y1, y2, rx, mat, ratio=0.57, sw=4):
    ry = rx * ratio
    return path(f"M{cx-rx},{y1} A{rx},{ry} 0 0 0 {cx+rx},{y1} L{cx+rx},{y2} "
                f"A{rx},{ry} 0 0 1 {cx-rx},{y2} Z", mat, sw=sw)


# ---------------------------------------------------------------- base

def base(state, s):
    cx, py = PIVOT
    tier = int(state[1])
    rx = {1: 62, 2: 66, 3: 70, 4: 74, 5: 76}[tier] * s
    h = {1: 24, 2: 28, 3: 30, 4: 34, 5: 36}[tier] * s
    top = py - h
    out = []
    if tier == 5:
        ring = ellipse(cx, py + 4, rx * 1.75, rx * 1.75 * 0.57, color="none", sw=0,
                       extra='stroke="#ffd21f" stroke-width="10"')
        out.append(glow(ring, "blur8", 0.9))
        out.append(ellipse(cx, py + 4, rx * 1.75, rx * 1.75 * 0.57, color="none", sw=0,
                           extra='stroke="#fff6b8" stroke-width="3" opacity="0.9"'))
    out.append(f'<ellipse cx="{cx}" cy="{py+6}" rx="{rx*1.35}" ry="{rx*0.8}" fill="url(#g_shadow)"/>')
    if tier >= 3:
        fr = rx * 1.22
        fmat = "dsteel" if tier == 3 else "gold"
        out.append(cylinder(cx, py - 6 * s, fr, 12 * s, fmat, "dsteel" if tier > 3 else "steel", sw=4))
    mat = {1: "wood", 2: "steel", 3: "steel", 4: "dsteel", 5: "dsteel"}[tier]
    out.append(cylinder(cx, top, rx, h, mat, "iron" if tier == 1 else "steel"))
    if tier == 1:
        out.append(band(cx, top + h * 0.35, top + h * 0.65, rx, "iron"))
    elif tier == 2:
        for i in range(-2, 3):
            out.append(circle(cx + i * rx * 0.38, top + h * 0.55 + abs(i) * -3 * s + rx * 0.57 * 0.85, 4 * s, "iron", sw=2))
    else:
        out.append(band(cx, top + h * 0.3, top + h * 0.55, rx, "gold"))
        if tier >= 4:
            for i in (-2, -1, 0, 1, 2):
                x = cx + i * rx * 0.4
                y = top + h * 0.78 + rx * 0.57 * (1 - (i * 0.4) ** 2) ** 0.5
                out.append(glow(circle(x, y, 6 * s, color="#ffe23d", sw=0), "blur4", 1))
                out.append(circle(x, y, 3.5 * s, color="#fffbd0", sw=0))
    # inner turntable ring on the top face
    out.append(ellipse(cx, top, rx * 0.72, rx * 0.72 * 0.57, color="none", sw=0,
                       extra=f'stroke="{OL}" stroke-width="3" opacity="0.35"'))
    if tier in (2, 3):
        out.append(pennant(cx - rx * 1.02, top + 2, s, tier))
    return "".join(out), (cx, top)


def pennant(x, y, s, tier):
    h = 120 * s
    pole = rect(x - 4 * s, y - h, 8 * s, h, "iron" if tier == 2 else "gold", rx=3, sw=3)
    tip = circle(x, y - h, 7 * s, "gold" if tier == 3 else "brass", sw=3)
    fy = y - h + 6 * s
    flag = path(f"M{x-3*s},{fy} C{x-40*s},{fy-8*s} {x-60*s},{fy+14*s} {x-88*s},{fy+10*s} "
                f"C{x-64*s},{fy+26*s} {x-40*s},{fy+34*s} {x-3*s},{fy+42*s} Z", "yellow", sw=4)
    bolt = path(f"M{x-30*s},{fy+8*s} L{x-38*s},{fy+22*s} L{x-28*s},{fy+21*s} L{x-34*s},{fy+34*s} "
                f"L{x-18*s},{fy+16*s} L{x-28*s},{fy+17*s} Z", color=OL, sw=0)
    return pole + flag + bolt + tip


# ---------------------------------------------------------------- turret parts (local: barrel points -y)

def bow(y, span, sweep, mat, tip_mat, w=11):
    d = f"M{-span},{y+sweep} Q{-span*0.45},{y-12} 0,{y-8} Q{span*0.45},{y-12} {span},{y+sweep}"
    string = (f'<path d="M{-span},{y+sweep} L0,-36 L{span},{y+sweep}" fill="none" stroke="{OL}" '
              f'stroke-width="4"/><path d="M{-span},{y+sweep} L0,-36 L{span},{y+sweep}" fill="none" '
              f'stroke="#e9e2cf" stroke-width="1.6"/>')
    limbs = (f'<path d="{d}" fill="none" stroke="{OL}" stroke-width="{w+9}" stroke-linecap="round"/>'
             f'<path d="{d}" fill="none" stroke="url(#g_{mat})" stroke-width="{w}" stroke-linecap="round"/>')
    tips = circle(-span, y + sweep, 7, tip_mat, sw=4) + circle(span, y + sweep, 7, tip_mat, sw=4)
    return string + limbs + tips


def bolt(x, back, tip, head="iron", shaft="wood", fletch="yellow", w=6, glowing=False):
    out = []
    if glowing:
        out.append(glow(rect(x - w, tip, w * 2, back - tip, color="#ffe23d", sw=0, rx=w), "blur8", 0.9))
    out.append(rect(x - w / 2, tip + 18, w, back - tip - 18, shaft, sw=3, rx=2))
    out.append(path(f"M{x-10},{back} L{x-w/2},{back-16} L{x+w/2},{back-16} L{x+10},{back} Z", fletch, sw=3))
    out.append(path(f"M{x-10},{tip+22} L{x},{tip} L{x+10},{tip+22} L{x},{tip+16} Z", head, sw=3))
    return "".join(out)


def rail(x, top, bottom, w, mat, groove=True):
    out = rect(x - w / 2, top, w, bottom - top, mat, rx=4)
    if groove:
        out += f'<path d="M{x},{top+8} L{x},{bottom}" stroke="{OL}" stroke-width="2.5" opacity="0.5"/>'
    return out


def energy_line(x, top, bottom):
    line = f'<path d="M{x},{top} L{x},{bottom}" stroke="#ffe23d" stroke-width="5" stroke-linecap="round"/>'
    return glow(line, "blur4", 1) + f'<path d="M{x},{top} L{x},{bottom}" stroke="#fffbd0" stroke-width="2" stroke-linecap="round"/>'


def ring(x, y, rx, ry, mat, back, w=9):
    """Ring around the barrel axis: back half drawn before barrel, front half after."""
    arc = (f"M{x-rx},{y} A{rx},{ry} 0 0 1 {x+rx},{y}" if back
           else f"M{x-rx},{y} A{rx},{ry} 0 0 0 {x+rx},{y}")
    return (f'<path d="{arc}" fill="none" stroke="{OL}" stroke-width="{w+8}" stroke-linecap="round"/>'
            f'<path d="{arc}" fill="none" stroke="url(#g_{mat})" stroke-width="{w}" stroke-linecap="round"/>')


def spark(points, w=4):
    d = "M" + " L".join(f"{x},{y}" for x, y in points)
    return (glow(f'<path d="{d}" fill="none" stroke="#ffe23d" stroke-width="{w+4}" stroke-linejoin="round"/>', "blur4", 1)
            + f'<path d="{d}" fill="none" stroke="#fffbd0" stroke-width="{w-1}" stroke-linejoin="round" stroke-linecap="round"/>')


def crest(y, s=1.0):
    sh = (f"M{-22*s},{y-20*s} L{22*s},{y-20*s} L{22*s},{y+2*s} Q{20*s},{y+18*s} 0,{y+28*s} "
          f"Q{-20*s},{y+18*s} {-22*s},{y+2*s} Z")
    emblem = (f"M{4*s},{y-14*s} L{-8*s},{y+4*s} L{1*s},{y+4*s} L{-4*s},{y+20*s} L{10*s},{y-2*s} L{1*s},{y-2*s} Z")
    return path(sh, "gold", sw=4) + path(emblem, color="#2b2233", sw=0) + glow(path(emblem, color="#ffe23d", sw=0), "blur4", 0.6)


def housing_l1():
    out = [rect(-52, -42, 104, 100, "wood", rx=16)]
    out.append(highlight("M-40,-34 L30,-34 L20,-26 L-44,-26 Z", 0.35))
    for y in (-24, 34):
        out.append(rect(-55, y, 110, 11, "iron", rx=3, sw=3))
        for x in (-40, 0, 40):
            out.append(circle(x, y + 5.5, 3, "brass", sw=1.5))
    out.append(rect(-52, 2, 104, 12, "yellow", sw=3))
    out.append(circle(0, -8, 9, "brass", sw=3))
    return "".join(out)


def housing_l2():
    out = [rect(-56, -44, 112, 106, "wood", rx=16)]
    for x0 in (-58, 4):
        out.append(rect(x0, -40, 54, 96, "steel", rx=12))
        for (dx, dy) in ((10, 8), (44, 8), (10, 86), (44, 86)):
            out.append(circle(x0 + dx, -40 + dy, 3.5, "iron", sw=2))
    out.append(highlight("M-50,-34 L-14,-34 L-16,-26 L-52,-26 Z", 0.5))
    out.append(rect(-58, 10, 116, 10, "yellow", sw=3))
    # power cell
    out.append(glow(rect(-22, 56, 44, 30, color="#ffe23d", sw=0, rx=10), "blur8", 1))
    out.append(rect(-20, 56, 40, 26, "iron", rx=8, sw=4))
    out.append(rect(-13, 61, 26, 16, color="url(#g_core)", rx=5, sw=2))
    return "".join(out)


def housing_l3():
    body = "M-46,-48 L46,-48 L64,-24 L64,48 L46,70 L-46,70 L-64,48 L-64,-24 Z"
    out = [path(body, "steel")]
    out.append(path("M-40,-40 L40,-40 L55,-20 L55,44 L40,62 L-40,62 L-55,44 L-55,-20 Z", color="none",
                    sw=0, extra='stroke="#e9b623" stroke-width="5"'))
    out.append(highlight("M-38,-42 L36,-42 L30,-34 L-44,-34 Z", 0.6))
    out.append(gear(0, 16, 30, teeth=10, depth=7))
    out.append(glow(circle(0, 16, 10, color="#ffe23d", sw=0), "blur4", 1))
    out.append(circle(0, 16, 7, color="url(#g_core)", sw=2))
    for x in (-50, 50):
        out.append(energy_line(x, -12, 40))
    return "".join(out)


def housing_heavy(gold_ratio):
    body = "M-56,-50 L56,-50 L72,-30 L72,56 L54,76 L-54,76 L-72,56 L-72,-30 Z"
    out = [path(body, "dsteel" if gold_ratio < 1 else "steel")]
    out.append(path("M-48,-42 L48,-42 L62,-26 L62,50 L48,66 L-48,66 L-62,50 L-62,-26 Z", color="none",
                    sw=0, extra='stroke="url(#g_gold)" stroke-width="7"'))
    out.append(highlight("M-50,-44 L48,-44 L42,-36 L-56,-36 Z", 0.45))
    # exhaust vents
    for i, x in enumerate((-30, -10, 10, 30)):
        out.append(glow(rect(x - 6, 30, 12, 34, color="#ff9a1f", sw=0, rx=4), "blur4", 0.9))
        out.append(rect(x - 5, 32, 10, 30, color="#3a1f12", rx=4, sw=3))
        out.append(rect(x - 2, 40, 4, 18, color="#ffcf3a", sw=0, rx=2))
    return "".join(out)


# ---------------------------------------------------------------- full turrets

def turret_l1():
    return (rail(0, -150, -30, 20, "wood") + housing_l1() + bow(-112, 92, 34, "wood", "brass", w=10)
            + bolt(0, -40, -178))


def turret_l2():
    return (rail(-15, -160, -30, 18, "iron") + rail(15, -160, -30, 18, "iron") + housing_l2()
            + bow(-118, 100, 36, "steel", "brass", w=11)
            + bolt(-15, -40, -186, head="steel") + bolt(15, -40, -186, head="steel"))


def turret_l3():
    return (rail(-16, -196, -30, 20, "steel") + rail(16, -196, -30, 20, "steel")
            + energy_line(-16, -190, -48) + energy_line(16, -190, -48)
            + housing_l3() + bow(-142, 112, 40, "steel", "gold", w=12)
            + bolt(-16, -44, -214, head="gold", shaft="iron") + bolt(16, -44, -214, head="gold", shaft="iron")
            + crest(-58))


def gatling(n, top, width, collar_mat):
    out = []
    xs = [-width / 2 + width * (i + 0.5) / n for i in range(n)]
    bw = width / n * 0.78
    out.append(rect(-width / 2 - 4, top + 10, width + 8, -40 - top - 10, "iron", rx=10, sw=5))
    for i, x in enumerate(xs):
        mat = "steel" if i % 2 == 0 else "dsteel"
        out.append(rect(x - bw / 2, top, bw, -40 - top, mat, rx=bw / 2, sw=3.5))
        out.append(circle(x, top + 6, bw * 0.28, color="#2b2233", sw=0))
        out.append(glow(circle(x, top + 6, bw * 0.3, color="#ffe23d", sw=0), "blur4", 0.9))
    for y, h in ((top + 14, 14), (top + (-40 - top) * 0.5, 12), (-58, 16)):
        out.append(rect(-width / 2 - 8, y, width + 16, h, collar_mat, rx=6, sw=4))
    return "".join(out)


def ammo_drum(x, y, r, mat):
    out = [glow(circle(x, y, r + 4, color="#ffd21f", sw=0), "blur8", 0.5), circle(x, y, r, mat)]
    out.append(circle(x, y, r * 0.72, "dsteel", sw=3))
    for i in range(8):
        a = math.pi * 2 * i / 8
        out.append(circle(x + r * 0.5 * math.cos(a), y + r * 0.5 * math.sin(a), r * 0.12, color="#ffe23d", sw=1.5))
    out.append(circle(x, y, r * 0.2, "gold", sw=3))
    return "".join(out)


def turret_l4a():
    out = [path("M50,-10 L78,-30 L92,-14 L60,8 Z", "dsteel", sw=4)]  # feed chute
    out.append(gatling(6, -205, 78, "gold"))
    out.append(housing_heavy(0))
    out.append(glow(circle(0, -22, 26, color="#ffd21f", sw=0), "blur8", 1))
    out.append(circle(0, -22, 22, "gold", sw=4))
    out.append(circle(0, -22, 15, color="url(#g_core)", sw=3))
    out.append(ammo_drum(84, -2, 34, "steel"))
    return "".join(out)


def crown_vent(y):
    d = (f"M-44,{y} L-44,{y+30} L44,{y+30} L44,{y} L28,{y+14} L14,{y-6} L0,{y+12} L-14,{y-6} L-28,{y+14} Z")
    out = [path(d, "gold", sw=5)]
    for x, yy in ((-44, y), (-14, y - 6), (14, y - 6), (44, y)):
        out.append(circle(x, yy, 5, color="url(#g_core)", sw=3))
    out.append(glow(rect(-34, y + 16, 68, 10, color="#ff9a1f", sw=0, rx=4), "blur4", 1))
    out.append(rect(-34, y + 17, 68, 8, color="#ffd54a", rx=4, sw=2.5))
    return "".join(out)


def ammo_belt(d):
    return (glow(f'<path d="{d}" fill="none" stroke="#ffd21f" stroke-width="16" stroke-dasharray="10 9"/>', "blur4", 1)
            + f'<path d="{d}" fill="none" stroke="{OL}" stroke-width="15" stroke-dasharray="10 9"/>'
            + f'<path d="{d}" fill="none" stroke="#fff2a0" stroke-width="9" stroke-dasharray="6 13" stroke-dashoffset="-2"/>')


def turret_l5a():
    out = []
    out.append(glow(f'<path d="M0,-40 L0,-232" stroke="#ffd21f" stroke-width="80" stroke-linecap="round"/>', "blur16", 0.45))
    out.append(ammo_belt("M112,-28 C150,-90 120,-170 66,-206"))
    out.append(ammo_belt("M-80,40 C-140,0 -130,-110 -70,-170"))
    out.append(path("M54,-14 L84,-36 L100,-18 L66,8 Z", "gold", sw=4))
    out.append(ring(0, -120, 72, 16, "gold", back=True, w=8))
    out.append(gatling(8, -232, 98, "gold"))
    out.append(ring(0, -120, 72, 16, "gold", back=False, w=8))
    out.append(glow(f'<ellipse cx="0" cy="-120" rx="74" ry="18" fill="none" stroke="#ffe23d" stroke-width="10"/>', "blur8", 0.9))
    out.append(housing_heavy(1))
    out.append(crown_vent(34))
    out.append(glow(circle(0, -22, 32, color="#ffd21f", sw=0), "blur8", 1))
    out.append(circle(0, -22, 24, "gold", sw=4))
    out.append(circle(0, -22, 16, color="url(#g_core)", sw=3))
    out.append(ammo_drum(92, -4, 38, "gold"))
    out.append(spark([(-70, -190), (-88, -206), (-76, -214), (-96, -236)]))
    out.append(spark([(60, -246), (74, -262), (62, -268), (80, -290)]))
    out.append(spark([(-92, -60), (-110, -70), (-102, -82), (-124, -92)], 3))
    return "".join(out)


def sleek_housing(mat, trim):
    body = "M-54,66 L54,66 L66,4 L36,-58 L-36,-58 L-66,4 Z"
    out = [path(body, mat)]
    out.append(path("M-44,56 L44,56 L54,6 L30,-46 L-30,-46 L-54,6 Z", color="none", sw=0,
                    extra=f'stroke="url(#g_{trim})" stroke-width="6"'))
    out.append(highlight("M-32,-50 L30,-50 L24,-42 L-38,-42 Z", 0.55))
    out.append(f'<path d="M0,-46 L0,56" stroke="{OL}" stroke-width="3" opacity="0.4"/>')
    return "".join(out)


def mag_rings(ys, rx, mat, glow_on, back):
    out = []
    for y in ys:
        if glow_on and not back:
            out.append(glow(f'<ellipse cx="0" cy="{y}" rx="{rx}" ry="{rx*0.25}" fill="none" stroke="#ffe23d" stroke-width="8"/>', "blur4", 1))
        out.append(ring(0, y, rx, rx * 0.25, mat, back, w=8))
    return "".join(out)


def spear(tip, back, energy=False):
    head = f"M-16,{tip+46} Q-12,{tip+16} 0,{tip} Q12,{tip+16} 16,{tip+46} L0,{tip+38} Z"
    if energy:
        return (glow(f'<path d="M0,{back} L0,{tip+20}" stroke="#ffd21f" stroke-width="26" stroke-linecap="round"/>', "blur8", 1)
                + glow(path(head, color="#ffd21f", sw=0), "blur8", 1)
                + f'<path d="M0,{back} L0,{tip+30}" stroke="#fff6b0" stroke-width="9" stroke-linecap="round"/>'
                + path(head, color="url(#g_core)", sw=3))
    return (rect(-4, tip + 40, 8, back - tip - 40, "iron", rx=3, sw=3) + path(head, "steel", sw=4)
            + highlight(f"M-10,{tip+40} Q-8,{tip+18} 0,{tip+6} L-2,{tip+36} Z", 0.6))


def turret_l4b():
    ys = [-90, -125, -160, -195]
    out = [mag_rings(ys, 28, "brass", True, back=True)]
    out.append(rect(-15, -224, 30, 190, "dsteel", rx=8))
    out.append(rect(-6, -218, 12, 180, color="#2b2233", rx=4, sw=0))
    out.append(energy_line(0, -214, -60))
    out.append(spear(-262, -60))
    out.append(mag_rings(ys, 28, "brass", True, back=False))
    out.append(sleek_housing("steel", "gold"))
    out.append(glow(circle(0, 14, 16, color="#ffd21f", sw=0), "blur8", 1))
    out.append(circle(0, 14, 12, color="url(#g_core)", sw=3))
    return "".join(out)


def crown_fins():
    out = []
    for sgn in (-1, 1):
        d = (f"M{sgn*52},-34 C{sgn*92},-14 {sgn*108},30 {sgn*112},86 "
             f"L{sgn*86},60 L{sgn*70},70 L{sgn*60},40 Z")
        out.append(path(d, "gold", sw=5))
        out.append(highlight(f"M{sgn*60},-22 C{sgn*86},-6 {sgn*98},26 {sgn*100},56 L{sgn*88},40 Z", 0.45))
    d = "M-26,64 L-30,90 L-14,80 L0,98 L14,80 L30,90 L26,64 Z"
    out.append(path(d, "gold", sw=5))
    out.append(circle(0, 84, 5, color="url(#g_core)", sw=3))
    return "".join(out)


def turret_l5b():
    ys = [-100, -142, -184, -226]
    out = [glow(f'<path d="M0,-30 L0,-300" stroke="#ffe23d" stroke-width="56" stroke-linecap="round"/>', "blur16", 0.55)]
    out.append(mag_rings(ys, 38, "gold", True, back=True))
    out.append(rect(-14, -250, 28, 216, "white", rx=8))
    out.append(rect(-6, -244, 12, 204, color="#2b2233", rx=4, sw=0))
    out.append(spear(-298, -56, energy=True))
    out.append(mag_rings(ys, 38, "gold", True, back=False))
    out.append(crown_fins())
    out.append(sleek_housing("white", "gold"))
    out.append(glow(circle(0, 14, 20, color="#ffd21f", sw=0), "blur8", 1))
    out.append(circle(0, 14, 14, color="url(#g_core)", sw=3))
    for x, y in ((-46, -170), (40, -270), (-30, -300), (52, -120)):
        out.append(glow(circle(x, y, 6, color="#ffe23d", sw=0), "blur4", 1) + circle(x, y, 2.5, color="#fffbd0", sw=0))
    return "".join(out)


TURRETS = {"l1": turret_l1, "l2": turret_l2, "l3": turret_l3,
           "l4a": turret_l4a, "l5a": turret_l5a, "l4b": turret_l4b, "l5b": turret_l5b}


def build(state, with_pad=True):
    s = SCALE[state]
    b, (cx, top) = base(state, s)
    t = f'<g transform="translate({cx},{top}) rotate({AIM}) scale({s:.3f})">{TURRETS[state]()}</g>'
    return svg((pad() if with_pad else "") + b + t, f"tower_bolt_{state}")

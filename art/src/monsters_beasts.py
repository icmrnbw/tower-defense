"""Beasts, flyers, spirits, worms, war machines and golems."""
from monster_kit import (MATS, OL, arm, blob, circ, ell, eye, flap, glowdot, glowpath, hl, hl_ell, leg, limb,
                         part, path, poly, shadow_part, smooth_d, stroke, swing)

PI = 3.14159


def qleg(name, hip, knee, foot, w, mat, paw, z, phase, amp=0.6, shade=False, parent=None, claws=False):
    """Jointed beast leg: hip -> knee -> foot, with a paw/hoof."""
    fx, fy = foot
    svg = (limb(hip, knee, w * 1.25, w * 0.85, mat) + limb(knee, (fx, fy - w * 0.35), w * 0.85, w * 0.7, mat)
           + ell(fx + w * 0.35, fy - w * 0.35, w * 0.75, w * 0.45, paw))
    if claws:
        svg += "".join(poly([(fx + w * 0.6 + i * 2.5, fy - 1.5), (fx + w * 1.2 + i * 2.5, fy + 0.5), (fx + w * 0.7 + i * 2.5, fy + 0.5)],
                            "bone", sw=1) for i in range(2))
    return part(name, svg, hip, z, parent=parent, anim=swing(amp, phase), shade=shade)


# ================================================================ warg / rift stalker

def hound(mid, fur, belly, eye_col, rim, r, fit, void=False):
    parts = [shadow_part(90)]
    if void:
        tail = (glowpath("M-32,-42 C-48,-56 -62,-40 -74,-56", "#b45cff", 3, "#f0d8ff")
                + glowpath("M-32,-40 C-50,-44 -58,-30 -72,-34", "#b45cff", 2.4, "#f0d8ff"))
        parts.append(part("tail", blob([(-30, -46), (-36, -40), (-30, -36)], fur), (-30, -40), 0.5,
                          anim=swing(0.2, 0.0, -0.1), glow=tail))
    else:
        tail = blob([(-30, -46), (-46, -58), (-64, -60), (-72, -52), (-58, -50), (-46, -42), (-32, -36)], fur)
        tail += stroke("M-40,-50 Q-52,-54 -64,-55", MATS[fur][2], 1.8, 0.6)
        parts.append(part("tail", tail, (-30, -40), 0.5, anim=swing(0.22, 0.0, -0.05)))
    parts.append(qleg("leg_bf", (-22, -36), (-14, -18), (-21, 0), 9, fur, fur, 0, PI + 0.6, shade=True, claws=True))
    parts.append(qleg("leg_ff", (20, -34), (24, -16), (22, 0), 8, fur, fur, 0, 0.6, shade=True, claws=True))
    body = blob([(-34, -40), (-28, -54), (-6, -59), (16, -58), (32, -52), (36, -38), (26, -26), (0, -24), (-26, -27)], fur)
    body += stroke("M-24,-30 Q2,-25 26,-29", MATS[belly][0], 3, 0.5)
    body += hl_ell(-4, -52, 14, 3, 0.22, -3)
    glow = ""
    if void:
        glow = (glowpath("M-20,-50 L-10,-44 L-2,-52 L10,-46", "#b45cff", 1.6, "#f0d8ff")
                + glowpath("M14,-40 L22,-34 L30,-42", "#b45cff", 1.4, "#f0d8ff"))
        for x0 in (-18, -4, 10):
            glow += glowpath(f"M{x0},-57 Q{x0 - 6},-72 {x0 - 14},-78", "#b45cff", 2.2, "#f0d8ff")
    else:
        body += "".join(poly([(x, -56 + abs(x) * 0.05), (x - 7, -66 - (6 if x % 2 else 0)), (x + 5, -57)], fur, sw=2)
                        for x in range(-22, 26, 8))
    parts.append(part("body", body, (0, -38), 2, anim=swing(0.05, 0.0, 0.0)))
    parts.append(qleg("leg_bn", (-24, -36), (-15, -17), (-24, 0), 10, fur, fur, 3, PI, claws=True, parent="body"))
    parts.append(qleg("leg_fn", (18, -34), (23, -16), (20, 0), 9, fur, fur, 3, 0.0, claws=True, parent="body"))
    head = (blob([(24, -40), (26, -56), (40, -62), (54, -56), (72, -50), (72, -44), (56, -42), (40, -36), (28, -36)], fur)
            + poly([(40, -42), (68, -42), (63, -34), (44, -33)], "#3a1418", sw=2.5)
            + "".join(poly([(x, -42), (x + 1.6, -38), (x + 3.2, -42)], "#fff8e6", sw=0.8) for x in (48, 54, 60, 65))
            + "".join(poly([(x, -34), (x + 1.4, -37.5), (x + 2.8, -34)], "#fff8e6", sw=0.8) for x in (50, 57))
            + circ(72, -48, 3, OL, sw=0)
            + blob([(32, -58), (34, -76), (46, -60)], fur)
            + stroke("M44,-56 L54,-54", OL, 2.4)
            + hl_ell(48, -56, 9, 2.2, 0.3, 10))
    eyes = eye(48, -52, 2.6, eye_col, pupil=False)
    if void:
        eyes += eye(42, -54, 1.8, eye_col, pupil=False) + eye(53, -55, 1.6, eye_col, pupil=False)
    parts.append(part("head", head, (28, -46), 4, parent="body", anim=swing(0.07, 0.6, 0.0), glow=eyes))
    return dict(id=mid, style="quad", height=66, r=r, fit=fit, rim=rim,
                motion={"bob": 3.5, "pitch": 0.06, "stride": 80}, parts=parts)


def warg():
    return hound("warg", "fur", "furtan", "#ffb020", "#fff0c0", 9, 3.6)


def void_hound():
    return hound("void_hound", "voidskin", "void", "#e09aff", "#d8a0ff", 28, 2.2, void=True)


# ================================================================ flyers: bat, wyvern, iron dragon

def bat():
    parts = [shadow_part(40)]
    wing = lambda pts: blob(pts, "batwing")
    wb = wing([(-2, -34), (-12, -60), (-38, -72), (-34, -60), (-46, -52), (-32, -48), (-34, -38), (-10, -28)])
    wb += stroke("M-2,-34 L-12,-60 L-38,-72 M-12,-60 L-44,-52 M-12,-60 L-32,-40", OL, 1.8, 0.8)
    parts.append(part("wing_b", wb, (-2, -34), 0, parent="body", anim=flap(0.75, 0.35, -0.15), shade=True))
    body = (blob([(-12, -28), (-14, -38), (-4, -44), (10, -42), (14, -32), (6, -22), (-6, -21)], "bat")
            + hl_ell(2, -36, 7, 3, 0.2) + stroke("M-6,-22 L-8,-16 M2,-22 L2,-16", OL, 2.4))
    parts.append(part("body", body, (0, -32), 2))
    head = (blob([(6, -32), (8, -44), (18, -46), (26, -38), (22, -28), (12, -26)], "bat")
            + blob([(8, -42), (4, -58), (14, -45)], "bat") + blob([(13, -45), (16, -60), (20, -44)], "bat")
            + blob([(6, -44), (6, -54), (11, -45)], "flesh", sw=0)
            + poly([(19, -29), (20, -24), (21.5, -29)], "#ffffff", sw=1) + poly([(23, -30), (23.8, -26), (25, -30)], "#ffffff", sw=1))
    parts.append(part("head", head, (8, -36), 3, parent="body", anim={"type": "drift", "amp": 0.08, "speed": 4},
                      glow=eye(19, -37, 2.4, "#c070ff", pupil=False)))
    wf = wing([(2, -34), (-4, -66), (-30, -86), (-26, -70), (-42, -64), (-28, -56), (-32, -44), (-8, -26)])
    wf += stroke("M2,-34 L-4,-66 L-30,-86 M-4,-66 L-40,-64 M-4,-66 L-30,-46", OL, 1.8, 0.8)
    parts.append(part("wing_f", wf, (2, -34), 4, parent="body", anim=flap(0.8, 0.0, -0.1)))
    return dict(id="bat", style="flyer", height=64, r=10, fit=3.4, rim="#e0b8ff",
                motion={"hover": 3.0, "hover_speed": 6, "flap_speed": 16, "stride": 60}, parts=parts)


def drake(mid, skin, wing_mat, belly, eye_col, rim, r, fit, armored=False, dragon=False):
    parts = [shadow_part(110)]
    wing = [(-4, -48), (-16, -92), (-46, -112), (-78, -104), (-70, -88), (-80, -76), (-62, -70), (-66, -56), (-40, -52), (-14, -40)]
    bones = "M-4,-48 L-16,-92 L-46,-112 M-16,-92 L-78,-104 M-16,-92 L-80,-76 M-16,-92 L-66,-56"
    parts.append(part("wing_b", blob([(x + 6, y + 4) for x, y in wing], wing_mat) + stroke(bones.replace("M-4", "M2"), OL, 2, 0.5),
                      (2, -44), 0, parent="body", anim=flap(0.55, 0.4, -0.1), shade=True))
    tail = path(smooth_d([(-24, -46), (-50, -46), (-76, -38), (-96, -30), (-80, -36), (-56, -36), (-26, -32)]), skin)
    tail += poly([(-96, -30), (-108, -36), (-100, -24)], "bone" if not dragon else "char", sw=2)
    if dragon:
        tail += "".join(poly([(x, -45 + (x + 24) * -0.25 * -1), (x - 4, -54 + (x + 24) * 0.18), (x - 8, -43 + (x + 24) * 0.25)], "char", sw=1.6)
                        for x in (-34, -50, -66))
    parts.append(part("tail", tail, (-24, -40), 1, parent="body", anim={"type": "drift", "amp": 0.16, "speed": 3}))
    parts.append(qleg("leg_b", (-12, -32), (-8, -20), (-14, -10), 7, skin, skin, 1.5, 0.0, amp=0.0, parent="body", claws=True, shade=True))
    body = blob([(-30, -42), (-18, -54), (6, -56), (24, -50), (28, -38), (12, -28), (-14, -28)], skin)
    body += "".join(stroke(f"M{x},-30 Q{x + 2},-36 {x},-42", MATS[belly][0], 2.6, 0.55) for x in range(-12, 16, 6))
    glow = ""
    if armored:
        body += "".join(blob([(x - 8, -50), (x - 2, -58), (x + 8, -56), (x + 6, -48)], "steel", sw=2) for x in (-16, -2, 12))
        body += "".join(circ(x, -52, 1.3, "iron", sw=0.8) for x in (-16, -2, 12))
    if dragon:
        body += "".join(poly([(x, -54), (x + 4, -66), (x + 8, -54)], "char", sw=1.8) for x in (-20, -8, 4, 16))
        glow = glowpath("M-16,-40 L-6,-44 L4,-38 L14,-42", "#ff7a2f", 1.5, "#ffe0a0")
    parts.append(part("body", body + hl_ell(0, -50, 14, 3, 0.25), (0, -42), 2, glow=glow))
    parts.append(qleg("leg_f", (12, -32), (16, -20), (10, -12), 7, skin, skin, 3, 0.0, amp=0.0, parent="body", claws=True))
    head = (limb((18, -46), (36, -66), 15, 10, skin)
            + blob([(32, -64), (36, -74), (52, -76), (68, -68), (72, -62), (58, -58), (40, -56)], skin)
            + stroke("M46,-62 L68,-63", OL, 2)
            + blob([(38, -72), (24, -82), (16, -90), (30, -78)], "bone" if not dragon else "char")
            + hl_ell(50, -72, 8, 2, 0.3))
    if dragon:
        head += blob([(44, -74), (36, -86), (34, -98), (46, -80)], "char")
        head += "".join(poly([(x, -62), (x + 1.4, -58.5), (x + 2.8, -62)], "#fff8e6", sw=0.8) for x in (54, 60, 65))
    if armored:
        head += blob([(36, -70), (42, -78), (56, -78), (58, -72), (44, -68)], "steel", sw=2)
    hglow = eye(52, -69, 2.4, eye_col, pupil=False)
    if dragon:
        hglow += glowdot(72, -60, 2.2, "#ff9a2f", "#fff0a0")
    parts.append(part("head", head, (20, -48), 4, parent="body", anim={"type": "drift", "amp": 0.07, "speed": 2.5}, glow=hglow))
    parts.append(part("wing_f", blob(wing, wing_mat) + stroke(bones, OL, 2, 0.55), (-4, -48), 5, parent="body",
                      anim=flap(0.6, 0.0, -0.05)))
    return dict(id=mid, style="flyer", height=96, r=r, fit=fit, rim=rim, canvas_dx=-10,
                motion={"hover": 4.0, "hover_speed": 3.0, "flap_speed": 7, "stride": 100}, parts=parts)


def wyvern():
    return drake("wyvern", "wyvern", "wyvern", "steel", "#ffd21f", "#d8ecff", 15, 3.2, armored=True)


def dragon():
    return drake("dragon", "char", "char", "ember", "#ff9a2f", "#ffb070", 36, 2.6, armored=True, dragon=True)


# ================================================================ spirits: wraith, frost wraith, lich

def spirit(mid, robe, inner, eye_col, rim, r, fit, crown=None, staff=False, height=92):
    parts = [shadow_part(46)]
    tail = blob([(-6, -36), (-26, -30), (-44, -16), (-36, -20), (-38, -8), (-24, -18), (-18, -10), (-12, -20), (2, -28)], robe)
    parts.append(part("tail", f'<g opacity="0.85">{tail}</g>', (-4, -32), 0, parent="body",
                      anim={"type": "drift", "amp": 0.14, "speed": 3}))
    parts.append(part("arm_b", f'<g opacity="0.9">{limb((-2, -62), (10, -44), 9, 12, robe)}</g>'
                      + "".join(stroke(f"M10,-44 L{12 + i * 3},{-38 + i}", OL, 2.4) + stroke(f"M10,-44 L{12 + i * 3},{-38 + i}", "#e8e0d0", 1.2)
                                for i in range(3)), (-2, -62), 1, parent="body",
                      anim={"type": "drift", "amp": 0.18, "speed": 2.2, "phase": 1.5}, shade=True))
    body = blob([(-14, -64), (-16, -46), (-12, -28), (-4, -16), (4, -22), (10, -14), (14, -26), (16, -44), (16, -62), (6, -74)], robe)
    body += path("M-4,-16 L0,-24 L4,-22 L7,-30 L10,-14", "none", sw=0)
    body += stroke("M2,-66 Q6,-44 2,-24", MATS[robe][2], 2, 0.5) + hl_ell(-4, -54, 4, 10, 0.2, 10)
    glow = ""
    if staff:
        body += "".join(circ(x, y, 2, "gold", sw=1) for x, y in ((4, -60), (6, -50), (5, -40)))
        glow = glowpath("M-6,-50 L-2,-44 L-6,-38 M8,-34 L12,-28", "#b45cff", 1.4, "#f0d8ff")
    parts.append(part("body", f'<g opacity="0.92">{body}</g>', (0, -50), 2,
                      anim={"type": "drift", "amp": 0.05, "speed": 2.0}, glow=glow))
    hood = blob([(-10, -70), (-8, -88), (6, -96), (20, -88), (22, -72), (12, -64), (0, -64)], robe)
    face = ell(14, -78, 6.5, 8.5, inner, sw=2)
    if staff:  # skull face
        face = ell(14, -78, 6.5, 8.5, "#140a24", sw=2) + blob([(9, -84), (17, -86), (20, -78), (16, -70), (10, -72)], "bone", sw=1.6)
    head = hood + face
    hglow = eye(15, -80, 1.9, eye_col, pupil=False) + eye(11, -80, 1.5, eye_col, pupil=False)
    if crown == "ice":
        head += "".join(poly([(x, -88 + abs(x - 6) * 0.3), (x + 2, -104 + abs(x - 6) * 0.8), (x + 4, -88 + abs(x - 6) * 0.3)], "ice", sw=1.6)
                        for x in (-6, 0, 6, 12))
    if crown == "gold":
        head += (poly([(-4, -88), (-2, -102), (3, -92), (7, -106), (11, -92), (16, -102), (18, -88)], "gold", sw=2)
                 + circ(7, -94, 2, "#b45cff", sw=1))
        hglow += glowdot(7, -94, 1.6, "#b45cff")
    parts.append(part("head", head, (4, -66), 4, parent="body", anim={"type": "drift", "amp": 0.06, "speed": 2.6}, glow=hglow))
    claws = "".join(stroke(f"M26,-56 L{30 + i * 2},{-52 + i * 3}", OL, 2.4) + stroke(f"M26,-56 L{30 + i * 2},{-52 + i * 3}", "#e8e0d0", 1.2)
                    for i in range(3))
    arm_f = f'<g opacity="0.92">{limb((6, -62), (24, -56), 9, 12, robe)}</g>' + claws
    aglow = ""
    if staff:
        arm_f = (limb((24, -14), (28, -100), 4, 4.5, "black", sw=2) + f'<g opacity="0.92">{limb((6, -62), (24, -56), 9, 12, robe)}</g>'
                 + circ(26, -58, 4, "bone", sw=1.6))
        aglow = glowdot(28, -104, 6, "#b45cff", "#ffffff") + glowpath("M22,-96 Q28,-108 34,-96", "#b45cff", 1.4)
    parts.append(part("arm_f", arm_f, (6, -62), 5, parent="body",
                      anim={"type": "drift", "amp": 0.16, "speed": 2.2}, glow=aglow))
    if staff:
        parts[-1]["anim"]["cast"] = -0.8
    return dict(id=mid, style="float", height=height, r=r, fit=fit, rim=rim,
                motion={"hover": 4.0, "hover_speed": 2.5, "stride": 60}, parts=parts)


def wraith():
    return spirit("wraith", "ghost", "#140a24", "#d070ff", "#e8dcff", 11, 3.4)


def frost_wraith():
    return spirit("frost_wraith", "ice", "#0a1a2a", "#7fe8ff", "#e8fbff", 26, 3.2, crown="ice")


def lich():
    return spirit("lich", "void", "#140a24", "#d070ff", "#d8a0ff", 40, 2.9, crown="gold", staff=True, height=108)


# ================================================================ worms

def wormish(mid, mat, plate, eye_col, rim, r, fit, segments, spacing, sand=False):
    rad = 16
    parts = [shadow_part(44)]
    seg = (circ(0, -rad, rad, mat) + path(f"M{-rad + 2},{-rad - 4} Q0,{-rad * 2 - 6} {rad - 2},{-rad - 4} Q0,{-rad * 2 + 4} {-rad + 2},{-rad - 4} Z", plate, sw=2)
           + stroke(f"M{-rad + 4},{-rad + 6} Q0,{-4} {rad - 4},{-rad + 6}", MATS[mat][2], 1.6, 0.6))
    if sand:
        seg += poly([(-4, -rad * 2 - 2), (0, -rad * 2 - 12), (4, -rad * 2 - 2)], "bone", sw=1.6)
    parts.append(part("seg", seg, (0, -rad), 1))
    parts.append(part("tail", blob([(8, -rad - 10), (-10, -rad - 6), (-26, -8), (-10, -4), (8, -4)], mat), (0, -rad), 0))
    head = (circ(4, -rad - 2, rad + 4, mat)
            + path(f"M-12,{-rad - 14} Q4,{-rad * 2 - 14} 20,{-rad - 14} Q4,{-rad * 2 - 2} -12,{-rad - 14} Z", plate, sw=2)
            + ell(20, -rad - 2, 7, 13, "flesh", sw=2.5)
            + ell(22, -rad - 2, 4, 9, "#3a0c14", sw=0)
            + "".join(poly([(18 + abs(i) * -0.3, -rad - 2 + i * 3.4), (24, -rad - 2 + i * 3.4 + 1.2), (18 + abs(i) * -0.3, -rad - 2 + i * 3.4 + 2.4)],
                           "#fff8e6", sw=0.8) for i in (-3, -2, -1, 0, 1, 2)))
    hglow = ""
    if sand:
        head += (blob([(16, -rad - 14), (34, -rad - 20), (40, -rad - 10), (28, -rad - 8)], "bone", sw=2)
                 + blob([(16, -rad + 10), (34, -rad + 16), (40, -rad + 6), (28, -rad + 4)], "bone", sw=2))
        hglow = eye(8, -rad - 12, 2.6, eye_col, pupil=False)
    parts.append(part("head", head, (0, -rad), 3, anim=swing(0.12, 0.0, -0.1), glow=hglow))
    return dict(id=mid, style="worm", height=40, r=r, fit=fit, rim=rim,
                motion={"stride": 70}, extra={"segments": segments, "spacing": spacing, "wave": 5.0, "taper": 0.07},
                parts=parts)


def worm():
    return wormish("worm", "worm", "stone", "#ff9a2f", "#ffd8b0", 13, 2.3, 4, 20)


def sandwyrm():
    return wormish("sandwyrm", "sand", "brass", "#ff7a2f", "#fff0b0", 26, 1.8, 6, 22, sand=True)


# ================================================================ goblin war wagon (splitter)

def wagon():
    parts = [shadow_part(96, 20)]
    flag = (stroke("M-34,-40 L-34,-96", OL, 4) + stroke("M-34,-40 L-34,-96", MATS["wood"][1], 2)
            + blob([(-34, -94), (-10, -90), (-18, -82), (-8, -74), (-34, -76)], "red")
            + circ(-22, -84, 3, "#fff8e6", sw=1.2))
    parts.append(part("flag", flag, (-34, -44), 0, parent="body", anim={"type": "drift", "amp": 0.06, "speed": 6}))
    heads = []
    for i, (x, y) in enumerate(((-20, -44), (-2, -46), (16, -44))):
        h = (blob([(x - 7, y), (x - 8, y - 10), (x, y - 16), (x + 9, y - 12), (x + 10, y - 2)], "goblin")
             + blob([(x - 6, y - 10), (x - 18, y - 16), (x - 8, y - 5)], "goblin", sw=2)
             + blob([(x + 6, y - 9), (x + 15, y - 5), (x + 7, y - 4)], "goblin", sw=2))
        if i == 1:
            h += blob([(x - 8, y - 11), (x - 4, y - 19), (x + 6, y - 19), (x + 10, y - 12)], "iron", sw=2)
        heads.append(part(f"head{i}", h, (x, y), 1, parent="body", anim={"type": "bob", "amp": 2.0, "freq": 2.0, "phase": i * 2.0},
                          glow=eye(x + 4, y - 9, 1.9, "#ffd21f")))
    parts += heads
    body = (poly([(-42, -46), (34, -46), (42, -24), (-40, -24)], "wood", sw=3)
            + "".join(stroke(f"M-41,{y} L{36 + (y + 46) * 0.3:.0f},{y}", MATS["wood"][2], 1.6, 0.8) for y in (-39, -32))
            + poly([(-30, -46), (-6, -46), (-10, -24), (-34, -24)], "red", sw=0, extra='opacity="0.75"')
            + limb((-44, -46), (36, -46), 4, 4, "iron", sw=2)
            + "".join(circ(x, -35, 1.6, "iron", sw=0.8) for x in (-36, -18, 0, 18))
            + poly([(36, -42), (54, -36), (40, -32)], "steel", sw=2) + poly([(38, -32), (56, -26), (42, -24)], "steel", sw=2)
            + circ(-2, -35, 6, "bone", sw=1.6) + circ(-4, -36, 1.4, OL, sw=0) + circ(0, -36, 1.4, OL, sw=0))
    parts.append(part("body", body, (0, -30), 2))
    for name, x in (("wheel_b", -24), ("wheel_f", 22)):
        w = (circ(x, -13, 13, "wood") + circ(x, -13, 9.5, "none", sw=0, extra=f'stroke="{OL}" stroke-width="2"')
             + "".join(stroke(f"M{x},-13 L{x + 11 * c:.1f},{-13 + 11 * s:.1f}", OL, 2.2) for c, s in ((1, 0), (0, 1), (0.7, -0.7), (-0.7, -0.7)))
             + "".join(stroke(f"M{x},-13 L{x - 11 * c:.1f},{-13 - 11 * s:.1f}", OL, 2.2) for c, s in ((1, 0), (0, 1), (0.7, -0.7), (-0.7, -0.7)))
             + circ(x, -13, 3.5, "iron", sw=1.6))
        parts.append(part(name, w, (x, -13), 4, anim={"type": "spin", "rate": 1.0}))
    return dict(id="wagon", style="cart", height=80, r=14, fit=3.6, rim="#ffd0a0",
                motion={"bob": 1.5, "stride": 82}, parts=parts)


# ================================================================ iron scarab

def beetle():
    parts = [shadow_part(120)]
    legs_far = [(-22, -28), (0, -26), (20, -26)]
    for i, (x, y) in enumerate(legs_far):
        parts.append(qleg(f"legf{i}", (x, y), (x + 12, y - 8), (x + 16, 0), 6, "black", "black", 0,
                          (PI if i % 2 == 0 else 0.0), amp=0.35, shade=True))
    shell = (blob([(-50, -30), (-44, -54), (-18, -70), (14, -68), (38, -54), (44, -32), (0, -22)], "shell")
             + stroke("M-30,-64 Q-4,-48 30,-60", OL, 2.4, 0.7)
             + path(smooth_d([(-48, -30), (0, -20), (44, -32)], closed=False), "none", sw=0, extra='stroke="#f2c230" stroke-width="3.2" fill="none"')
             + "".join(circ(x, y, 1.8, "gold", sw=0.8) for x, y in ((-36, -46), (-20, -58), (-2, -60), (16, -58), (30, -48)))
             + hl("M-34,-56 Q-16,-70 10,-68 Q-12,-62 -30,-50 Z", 0.35))
    parts.append(part("body", shell, (0, -34), 2, anim=swing(0.03, 0.0, 0.0, 2.0)))
    head = (blob([(36, -26), (38, -46), (54, -48), (62, -36), (54, -24)], "shell")
            + path("M52,-44 Q60,-70 82,-78 Q70,-64 60,-40 Z", "dsteel", sw=2.5)
            + path("M58,-30 Q72,-30 74,-22 Q66,-26 58,-26 Z", "black", sw=2) + path("M56,-26 Q70,-18 68,-12 Q62,-20 54,-22 Z", "black", sw=2))
    parts.append(part("head", head, (40, -34), 4, parent="body", anim=swing(0.05, 0.5, 0.0, 2.0),
                      glow=eye(52, -38, 2.6, "#9cff3a", pupil=False)))
    for i, (x, y) in enumerate([(-26, -26), (-4, -24), (16, -24)]):
        parts.append(qleg(f"legn{i}", (x, y), (x + 12, y - 8), (x + 16, 0), 7, "black", "black", 5,
                          (0.0 if i % 2 == 0 else PI), amp=0.35, parent="body"))
    return dict(id="beetle", style="quad", height=80, r=26, fit=2.1, rim="#c0f0ff",
                motion={"bob": 1.5, "stride": 40}, parts=parts)


# ================================================================ thornback behemoth

def thornback():
    parts = [shadow_part(140)]
    parts.append(qleg("leg_bf", (-34, -34), (-30, -18), (-34, 0), 18, "thorn", "bone", 0, PI, amp=0.3, shade=True))
    parts.append(qleg("leg_ff", (30, -34), (34, -18), (30, 0), 18, "thorn", "bone", 0, 0.0, amp=0.3, shade=True))
    tail = blob([(-50, -40), (-70, -38), (-84, -30), (-70, -28), (-50, -30)], "thorn") + circ(-86, -30, 8, "bone")
    tail += "".join(poly([(-86 + dx, -30 + dy), (-86 + dx * 2.2, -30 + dy * 2.2), (-86 + dx + dy * 0.3, -30 + dy - dx * 0.3)], "bone", sw=1.4)
                    for dx, dy in ((0, -8), (-8, 0), (0, 8), (-6, -6), (-6, 6)))
    parts.append(part("tail", tail, (-50, -36), 0.5, parent="body", anim=swing(0.12, 0.0)))
    shell = (blob([(-58, -36), (-50, -66), (-20, -86), (16, -86), (46, -68), (56, -40), (0, -26)], "thorn")
             + "".join(blob([(x - 12, -60 + abs(x) * 0.25), (x, -74 + abs(x) * 0.35), (x + 12, -60 + abs(x) * 0.25), (x, -52 + abs(x) * 0.2)], "moss", sw=2)
                       for x in (-30, -6, 18, 38) if abs(x) < 50)
             + "".join(poly([(x - 5, y), (x + 2, y - 22), (x + 5, y)], "bone", sw=2)
                       for x, y in ((-44, -60), (-28, -76), (-8, -84), (12, -84), (32, -74), (46, -58)))
             + path(smooth_d([(-58, -36), (0, -26), (56, -40)], closed=False), "none", sw=0,
                    extra=f'stroke="{MATS["thorn"][2]}" stroke-width="4" fill="none"')
             + hl("M-40,-66 Q-14,-86 14,-84 Q-12,-76 -34,-60 Z", 0.25))
    parts.append(part("body", shell, (0, -40), 2, anim=swing(0.03, 0.0, 0.0, 2.0)))
    head = (blob([(44, -34), (48, -58), (68, -64), (86, -54), (90, -40), (72, -30), (52, -28)], "thorn")
            + path("M70,-60 Q78,-84 92,-90 Q84,-72 80,-56 Z", "bone", sw=2.4)
            + blob([(76, -36), (88, -46), (90, -32)], "bone", sw=1.8)
            + stroke("M66,-36 L86,-38", OL, 2.4)
            + hl_ell(66, -56, 9, 3, 0.3, -10))
    parts.append(part("head", head, (48, -44), 4, parent="body", anim=swing(0.05, 0.6, 0.0, 2.0),
                      glow=eye(74, -50, 2.8, "#ff7a2f", pupil=False)))
    parts.append(qleg("leg_bn", (-38, -34), (-34, -16), (-40, 0), 20, "thorn", "bone", 5, 0.0, amp=0.3, parent="body"))
    parts.append(qleg("leg_fn", (28, -34), (32, -16), (26, 0), 20, "thorn", "bone", 5, PI, amp=0.3, parent="body"))
    return dict(id="thornback", style="quad", height=96, r=30, fit=2.4, rim="#e8ffb0",
                motion={"bob": 2.0, "stride": 50}, parts=parts)


# ================================================================ golems: ice titan, clockwork colossus

def ice_golem():
    parts = [shadow_part(90)]
    parts.append(leg("leg_b", (-10, -40), (-10, 0), 18, "ice", "ice", 0, PI, amp=0.3, shade=True))
    parts.append(arm("arm_b", (-14, -92), (-20, -40), 18, "ice", 1, 0.0, amp=0.25, shade=True, fist=1.4))
    torso = (poly([(-22, -38), (-30, -70), (-24, -98), (0, -110), (26, -102), (34, -72), (24, -40), (2, -32)], "ice", sw=3.2)
             + poly([(-24, -98), (0, -110), (26, -102), (8, -96), (-8, -100)], "#ffffff", sw=2)
             + stroke("M-18,-50 L-4,-70 L-12,-88 M12,-48 L20,-74", "#5a90c0", 1.8, 0.7)
             + hl("M-22,-94 L-4,-104 L-8,-92 L-20,-84 Z", 0.5))
    core = glowdot(4, -72, 6, "#7fe8ff") + glowpath("M4,-72 L-6,-60 M4,-72 L14,-58 M4,-72 L2,-88", "#7fe8ff", 1.4)
    parts.append(part("torso", torso, (0, -40), 2, anim=swing(0.025, 0.0, 0.06, 2.0), glow=core))
    parts.append(leg("leg_f", (10, -40), (12, 0), 18, "ice", "ice", 3, 0.0, amp=0.3))
    head = (poly([(4, -104), (2, -120), (14, -128), (28, -122), (30, -108), (18, -100)], "ice", sw=2.6)
            + poly([(2, -120), (14, -128), (28, -122), (14, -118)], "#ffffff", sw=1.6))
    parts.append(part("head", head, (12, -104), 4, parent="torso", anim=swing(0.03, 1.0, 0.0, 2.0),
                      glow=eye(22, -113, 2.4, "#7fe8ff", pupil=False)))
    fist = poly([(22, -46), (38, -50), (44, -32), (28, -24), (18, -32)], "ice", sw=3)
    parts.append(part("arm_f", limb((16, -94), (26, -46), 20, 16, "ice", sw=3) + fist
                      + poly([(4, -98), (20, -106), (30, -96), (22, -86)], "#ffffff", sw=2), (16, -94), 6,
                      parent="torso", anim=swing(0.25, PI)))
    return dict(id="ice_golem", style="biped", height=132, r=34, fit=3.0, rim="#e8fbff",
                motion={"bob": 2.5, "stride": 64}, parts=parts)


def clockwork():
    parts = [shadow_part(90)]
    parts.append(leg("leg_b", (-10, -44), (-10, 0), 14, "dsteel", "brass", 0, PI, amp=0.35, shade=True))
    parts.append(arm("arm_b", (-14, -92), (-20, -50), 13, "brass", 1, 0.0, amp=0.3, shade=True, hand_mat="dsteel", fist=1.3))
    torso = (blob([(-24, -44), (-28, -80), (-18, -104), (6, -110), (28, -100), (32, -72), (24, -44), (0, -38)], "brass")
             + circ(6, -76, 16, "dsteel", sw=3)
             + "".join(poly([(6 + 17 * c, -76 + 17 * s), (6 + 21 * c, -76 + 21 * s), (6 + 19 * c2, -76 + 19 * s2)], "brass", sw=1.4)
                       for c, s, c2, s2 in ((1, 0, 0.92, 0.38), (0, 1, 0.38, 0.92), (-1, 0, -0.92, -0.38), (0, -1, -0.38, -0.92),
                                            (0.7, 0.7, 0.4, 0.9), (-0.7, 0.7, -0.9, 0.4), (-0.7, -0.7, -0.4, -0.9), (0.7, -0.7, 0.9, -0.4)))
             + limb((-26, -46), (26, -46), 6, 6, "dsteel", sw=2)
             + "".join(circ(x, -46, 1.6, "brass", sw=0.8) for x in (-18, -6, 6, 18))
             + limb((-20, -104), (-22, -122), 7, 9, "dsteel", sw=2)
             + hl_ell(-6, -96, 10, 3, 0.4, -15))
    core = glowdot(6, -76, 8, "#e04ad8", "#ffe0fb") + glowpath("M-22,-60 L-22,-50 M28,-62 L28,-52", "#e04ad8", 1.4)
    parts.append(part("torso", torso, (0, -44), 2, anim=swing(0.025, 0.0, 0.05, 2.0), glow=core))
    parts.append(leg("leg_f", (10, -44), (12, 0), 14, "dsteel", "brass", 3, 0.0, amp=0.35))
    head = (blob([(0, -104), (0, -118), (12, -126), (26, -120), (28, -106), (16, -100)], "steel")
            + poly([(14, -116), (28, -114), (28, -108), (14, -108)], "#240a24", sw=2)
            + limb((12, -126), (14, -134), 3, 3, "brass", sw=1.4) + circ(14, -136, 3, "brass", sw=1.4))
    parts.append(part("head", head, (12, -102), 4, parent="torso", anim=swing(0.03, 1.0, 0.0, 2.0),
                      glow=glowpath("M17,-112 L26,-111", "#e04ad8", 2.2, "#ffe0fb") + glowdot(14, -136, 1.8, "#e04ad8")))
    hammer = (limb((18, -100), (28, -56), 15, 12, "brass", sw=2.6) + circ(28, -56, 7, "dsteel", sw=2)
              + poly([(20, -60), (44, -60), (46, -30), (18, -30)], "dsteel", sw=3)
              + "".join(limb((20, y), (45, y), 3, 3, "brass", sw=1.2) for y in (-52, -38))
              + circ(18, -98, 9, "dsteel", sw=2.4) + circ(18, -98, 3.5, "brass", sw=1.4))
    parts.append(part("arm_f", hammer, (18, -98), 6, parent="torso", anim=swing(0.3, PI)))
    return dict(id="clockwork", style="biped", height=140, r=30, fit=3.1, rim="#ffd0f8",
                motion={"bob": 2.5, "stride": 64}, parts=parts)


MONSTERS = {f.__name__: f for f in (warg, void_hound, bat, wyvern, dragon, wraith, frost_wraith, lich, worm,
                                    sandwyrm, wagon, beetle, thornback, ice_golem, clockwork)}

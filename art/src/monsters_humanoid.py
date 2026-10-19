"""Two-legged monsters: goblin, imp, orc, hobgoblin, shaman, troll, ogre, pharaoh colossus."""
import math

from monster_kit import (MATS, OL, arm, blob, circ, eye, flap, glowdot, glowpath, hl, hl_ell, leg, limb,
                         part, path, poly, shadow_part, smooth_d, stroke, swing)


# ================================================================ goblin (scuttler)

def goblin():
    skin = "goblin"
    parts = [shadow_part(44)]
    parts.append(leg("leg_b", (-3, -28), (-2, 0), 8, skin, "dleather", 0, 3.14159, shade=True))
    parts.append(arm("arm_b", (-4, -50), (-12, -32), 8, skin, 1, 0.0, shade=True))
    torso = (blob([(-11, -24), (-14, -38), (-9, -51), (3, -56), (12, -48), (12, -34), (8, -23), (-3, -20)], skin)
             + blob([(-12, -25), (-15, -39), (-10, -51), (-1, -56), (5, -46), (3, -30), (0, -23)], "leather")
             + stroke("M-6,-50 L-4,-30", MATS["dleather"][1], 1.5, 0.7)
             + stroke("M-13,-30 Q0,-26 12,-30", OL, 5) + stroke("M-13,-30 Q0,-26 12,-30", "#c8a050", 2.5)
             + poly([(-11, -27), (-7, -14), (-1, -26), (5, -13), (10, -27)], "dleather", sw=2.5)
             + circ(2, -29, 2.4, "brass", sw=1.5) + hl_ell(7, -44, 3, 5, 0.3, -20))
    parts.append(part("torso", torso, (0, -26), 2, anim=swing(0.04, 0.0, 0.12, 2.0)))
    parts.append(leg("leg_f", (4, -28), (6, 0), 8, skin, "dleather", 3, 0.0))
    head = (blob([(-1, -71), (-26, -88), (-4, -62)], skin)                        # far ear
            + blob([(0, -57), (-4, -70), (4, -82), (18, -84), (28, -75), (30, -64), (20, -55), (8, -53)], skin)
            + blob([(23, -74), (39, -66), (36, -61), (24, -62)], skin)            # hooked nose
            + blob([(4, -69), (-32, -78), (-14, -67), (2, -61)], skin)            # near ear
            + stroke("M-2,-69 L-24,-75", MATS["goblin"][2], 2.5, 0.8)
            + stroke("M15,-77 Q22,-81 28,-76", OL, 3.5)                           # brow
            + stroke("M18,-60 Q24,-58 29,-60", OL, 2.5)
            + poly([(21, -59.5), (23, -55.5), (24.5, -59.5)], "#fff6dc", sw=1.2)  # tooth
            + hl_ell(10, -78, 7, 3.5, 0.3, -15))
    parts.append(part("head", head, (6, -54), 4, parent="torso", anim=swing(0.07, 1.0, 0.0, 2.0),
                      glow=eye(21, -70, 3.6, "#ffd21f")))
    dagger = (poly([(14, -34), (30, -50), (34, -54), (31, -48), (17, -31)], "steel", sw=2.2)
              + limb((11, -28), (16, -34), 4, 4, "dleather", sw=2) + circ(16.5, -33, 2.4, "brass", sw=1.5))
    parts.append(part("weapon", dagger, (13, -31), 5, parent="arm_f"))
    parts.append(arm("arm_f", (6, -50), (13, -31), 8, skin, 6, 3.14159))
    return dict(id="goblin", style="biped", height=86, r=11, fit=3.6, rim="#ffe08a",
                motion={"bob": 3.0, "stride": 42}, parts=parts)


# ================================================================ imp (swarmling)

def imp():
    skin = "imp"
    parts = [shadow_part(34)]
    wing_b = blob([(-4, -42), (-16, -70), (-34, -76), (-30, -64), (-40, -58), (-28, -54), (-30, -44), (-12, -36)], "batwing")
    wing_b = f'<g transform="translate(-4,-42) scale(0.72) translate(4,42)">{wing_b}</g>'
    parts.append(part("wing_b", wing_b + "", (-4, -42), -1,
                      parent="torso", anim=flap(0.45, 0.6, 0.1), shade=True))
    parts.append(leg("leg_b", (-3, -20), (-2, 0), 6, skin, skin, 0, 3.14159, shade=True))
    parts.append(arm("arm_b", (-3, -36), (-9, -24), 5, skin, 1, 0.0, shade=True))
    tail_d = "M-6,-22 C-20,-18 -28,-30 -26,-44"
    tail = (stroke(tail_d, OL, 6) + stroke(tail_d, MATS["imp"][1], 3)
            + poly([(-26, -52), (-31, -42), (-21, -43)], "imp", sw=2))
    parts.append(part("tail", tail, (-6, -22), 1.5, parent="torso", anim={"type": "drift", "amp": 0.25, "speed": 5}))
    torso = (blob([(-9, -18), (-11, -30), (-6, -40), (5, -41), (10, -32), (9, -19), (0, -15)], skin)
             + hl_ell(3, -28, 4, 6, 0.25) + stroke("M-1,-24 Q4,-22 7,-25", MATS["imp"][2], 1.5, 0.7))
    parts.append(part("torso", torso, (0, -20), 2, anim=swing(0.05, 0.0, 0.1, 2.0)))
    parts.append(leg("leg_f", (3, -20), (4, 0), 6, skin, skin, 3, 0.0))
    wing_f = blob([(-2, -40), (-10, -72), (-30, -84), (-26, -70), (-38, -66), (-26, -60), (-28, -50), (-8, -34)], "batwing")
    wing_f = f'<g transform="translate(-2,-40) scale(0.72) translate(2,40)">{wing_f + stroke("M-2,-40 L-26,-80 M-8,-52 L-34,-66", OL, 2)}</g>'
    parts.append(part("wing_f", wing_f, (-2, -40), 1.8,
                      parent="torso", anim=flap(0.5, 0.0, 0.05)))
    head = (blob([(0, -45), (-4, -56), (2, -66), (14, -68), (22, -60), (22, -48), (14, -42), (4, -41)], skin)
            + blob([(2, -62), (-6, -72), (-8, -82), (0, -70), (6, -64)], "bone")
            + blob([(10, -66), (12, -76), (18, -84), (16, -72), (16, -65)], "bone")
            + blob([(0, -56), (-12, -60), (-2, -52)], skin)
            + path("M10,-49 Q17,-44 23,-51 Q17,-48 10,-49 Z", OL, sw=1.5)
            + poly([(13, -47.5), (14.5, -45), (16, -47.5)], "#ffffff", sw=0)
            + poly([(18, -48), (19.2, -45.8), (20.5, -48.4)], "#ffffff", sw=0)
            + hl_ell(8, -62, 5, 2.5, 0.35, -10))
    parts.append(part("head", head, (3, -40), 4, parent="torso", anim=swing(0.1, 1.2, 0.0, 2.0),
                      glow=eye(16, -57, 3.4, "#ffe23d")))
    prongs = "M26,-50 L33,-57 M29,-46 L38,-52 M32,-42 L41,-46 M26,-50 Q31,-46 32,-42"
    fork = (stroke("M4,-18 L30,-46", OL, 4.5) + stroke("M4,-18 L30,-46", MATS["wood"][1], 2.2)
            + stroke(prongs, OL, 4) + stroke(prongs, MATS["iron"][0], 2))
    parts.append(part("weapon", fork, (12, -27), 5, parent="arm_f"))
    parts.append(arm("arm_f", (4, -36), (12, -27), 5, skin, 6, 3.14159))
    return dict(id="imp", style="biped", height=80, r=6, px_h=72, fit=5.2, rim="#ffb0ff",
                motion={"bob": 2.5, "stride": 30, "flap_speed": 20}, parts=parts)


# ================================================================ orc brute

def orc():
    skin = "orc"
    parts = [shadow_part(70)]
    parts.append(leg("leg_b", (-6, -38), (-7, 0), 13, skin, "iron", 0, 3.14159, amp=0.45, shade=True))
    parts.append(arm("arm_b", (-10, -68), (-18, -42), 12, skin, 1, 0.0, amp=0.35, shade=True))
    torso = (blob([(-16, -34), (-21, -56), (-14, -73), (4, -79), (20, -71), (23, -52), (16, -34), (0, -30)], skin)
             + blob([(-8, -38), (-11, -60), (4, -72), (21, -63), (20, -44), (10, -36)], "iron", radial=False)
             + "".join(circ(x, y, 1.6, "steel", sw=1) for x, y in ((-6, -44), (-8, -58), (16, -46), (17, -60), (5, -68)))
             + hl_ell(6, -62, 7, 4, 0.25, -25)
             + limb((-18, -36), (20, -36), 8, 8, "leather", sw=3)
             + poly([(-14, -34), (-10, -18), (-2, -33), (4, -18), (10, -33)], "leather", sw=2.5)
             + circ(4, -36, 3.5, "brass", sw=2))
    parts.append(part("torso", torso, (0, -38), 2, anim=swing(0.035, 0.0, 0.08, 2.0)))
    parts.append(leg("leg_f", (6, -38), (8, 0), 13, skin, "iron", 3, 0.0, amp=0.45))
    head = (blob([(6, -76), (4, -90), (14, -98), (26, -96), (32, -86), (30, -73), (18, -69)], skin)
            + blob([(2, -88), (5, -100), (18, -105), (30, -99), (33, -90), (17, -92)], "iron")
            + limb((3, -91), (33, -91), 4, 4, "dsteel", sw=2)
            + blob([(8, -100), (-2, -108), (-8, -118), (-1, -104), (4, -98)], "bone")
            + stroke("M21,-87 L30,-84", OL, 3.5)
            + stroke("M18,-75 Q24,-73 31,-76", OL, 2.5)
            + blob([(26, -74), (29, -84), (31, -76)], "bone", sw=1.6)
            + blob([(19, -73), (21, -80), (23, -73)], "bone", sw=1.4)
            + hl_ell(14, -100, 7, 2.5, 0.35, -10))
    parts.append(part("head", head, (10, -74), 4, parent="torso", anim=swing(0.05, 1.0, 0.0, 2.0),
                      glow=eye(25, -82, 2.8, "#ff5a2a", pupil=False)))
    club = (limb((18, -38), (40, -58), 5, 6, "wood", sw=2.5)
            + limb((36, -54), (62, -72), 12, 17, "wood", sw=3)
            + "".join(poly([(x - 3, y), (x + 4 * dx, y + 4 * dy), (x + 3, y + 1)], "steel", sw=1.6)
                      for x, y, dx, dy in ((44, -66, -0.4, -1.5), (52, -54, 0.4, 1.5), (56, -76, -0.2, -1.5),
                                           (62, -62, 0.6, 1.5), (67, -73, 1.5, -0.4)))
            + limb((36, -55), (39, -59), 3, 3, "iron", sw=1.6))
    parts.append(part("weapon", club, (22, -44), 5, parent="arm_f"))
    pauldron = (blob([(2, -66), (4, -76), (14, -80), (24, -74), (24, -64), (14, -62)], "iron")
                + "".join(poly([(x, y), (x + 2, y - 7), (x + 4, y)], "steel", sw=1.6) for x, y in ((6, -76), (12, -79), (18, -78)))
                + hl_ell(12, -74, 5, 2, 0.4, -15))
    parts.append(part("arm_f", arm("x", (12, -68), (22, -44), 12, skin, 0, 0)["svg"] + pauldron, (12, -68), 6,
                      parent="torso", anim=swing(0.35, 3.14159)))
    return dict(id="orc", style="biped", height=108, r=15, fit=3.1, rim="#e8f0ff",
                motion={"bob": 3.0, "stride": 52}, parts=parts)


# ================================================================ hobgoblin shieldbearer

def hobgoblin():
    skin = "hob"
    parts = [shadow_part(60)]
    spear = (stroke("M-4,-14 L-2,-112", OL, 5) + stroke("M-4,-14 L-2,-112", MATS["wood"][1], 2.6)
             + poly([(-6, -110), (-2, -128), (2, -110), (-2, -106)], "steel", sw=2)
             + poly([(-6, -104), (-2, -100), (2, -104), (-2, -96)], "red", sw=1.5))
    parts.append(part("spear", spear, (-4, -40), -0.5, parent="arm_b"))
    parts.append(leg("leg_b", (-5, -36), (-5, 0), 10, "dleather", "iron", 0, 3.14159, amp=0.45, shade=True))
    parts.append(arm("arm_b", (-6, -62), (-4, -40), 9, skin, 1, 0.0, amp=0.2, shade=True))
    torso = (blob([(-12, -32), (-15, -52), (-10, -66), (4, -70), (15, -62), (15, -44), (12, -32)], "iron", radial=False)
             + "".join(stroke(f"M-12,{y} Q2,{y+3} 14,{y}", "#2a2f3a", 1.2, 0.6) for y in range(-62, -34, 5))
             + blob([(-4, -34), (-5, -58), (6, -62), (14, -56), (13, -34)], "blue")
             + stroke("M-4,-34 L-5,-58", "#ffd21f", 1.6) + stroke("M13,-34 L14,-56", "#ffd21f", 1.6)
             + limb((-13, -35), (15, -35), 6, 6, "leather", sw=2.5) + circ(4, -35, 3, "gold", sw=1.6))
    parts.append(part("torso", torso, (0, -36), 2, anim=swing(0.03, 0.0, 0.06, 2.0)))
    parts.append(leg("leg_f", (5, -36), (7, 0), 10, "dleather", "iron", 3, 0.0, amp=0.45))
    head = (blob([(0, -66), (-14, -76), (-4, -70)], skin)
            + blob([(2, -64), (0, -76), (8, -86), (20, -84), (25, -74), (22, -64), (12, -61)], skin)
            + blob([(-2, -76), (2, -90), (12, -96), (22, -90), (25, -80), (12, -79)], "steel", radial=False)
            + poly([(20, -84), (24, -84), (25, -68), (22, -68)], "steel", sw=1.8)
            + limb((-2, -78), (25, -79), 3.5, 3.5, "gold", sw=1.6)
            + stroke("M15,-65 L22,-66", OL, 2)
            + hl_ell(10, -90, 6, 2.2, 0.45, -15))
    parts.append(part("head", head, (6, -64), 4, parent="torso", anim=swing(0.05, 1.0, 0.0, 2.0),
                      glow=eye(17, -73, 2.8, "#ffe23d")))
    parts.append(arm("arm_f", (8, -62), (24, -44), 9, skin, 6, 3.14159, amp=0.12))
    shield = (blob([(20, -66), (32, -70), (42, -64), (42, -30), (32, -14), (22, -20), (20, -34)], "blue", radial=False, sw=3.5)
              + path(smooth_d([(23, -63), (32, -66), (39, -61), (39, -32), (32, -18), (24, -23), (23, -36)]), "none", sw=0,
                     extra='stroke="#f2c230" stroke-width="2.6"')
              + circ(31, -42, 6, "gold", sw=2) + circ(31, -42, 2.4, "steel", sw=1)
              + poly([(31, -60), (35, -52), (31, -54), (27, -52)], "#e8eef8", sw=1.2)
              + hl("M24,-62 L32,-65 L30,-58 L24,-54 Z", 0.35))
    parts.append(part("shield", shield, (24, -44), 7, parent="arm_f"))
    return dict(id="hobgoblin", style="biped", height=104, r=13, fit=3.3, rim="#a8c8ff",
                motion={"bob": 2.5, "stride": 44}, parts=parts)


# ================================================================ goblin shaman (mender)

def shaman():
    skin = "goblin"
    parts = [shadow_part(46)]
    parts.append(leg("leg_b", (-3, -16), (-2, 0), 7, skin, "dleather", 0, 3.14159, amp=0.4, shade=True))
    parts.append(arm("arm_b", (-4, -46), (-10, -30), 7, "robe", 1, 0.0, amp=0.3, hand_mat=skin, shade=True))
    robe = (blob([(-13, -10), (-16, -30), (-11, -48), (2, -54), (13, -46), (14, -26), (17, -9), (2, -6)], "robe")
            + path("M-13,-10 L-9,-4 L-5,-9 L-1,-3 L3,-8 L7,-3 L11,-8 L16,-4 L17,-9 Q2,-12 -13,-10 Z", "robe", sw=2.2)
            + stroke("M2,-50 Q4,-30 2,-10", MATS["robe"][2], 1.6, 0.6)
            + limb((-13, -30), (15, -30), 5, 5, "red", sw=2)
            + "".join(circ(x, y, 2.2, "bone", sw=1) for x, y in ((0, -47), (4, -45), (8, -44), (11, -46)))
            + poly([(4, -44), (8, -38), (12, -44)], "bone", sw=1.4)
            + hl_ell(6, -42, 3, 6, 0.25, -10))
    parts.append(part("torso", robe, (0, -18), 2, anim=swing(0.03, 0.0, 0.06, 2.0)))
    parts.append(leg("leg_f", (3, -16), (5, 0), 7, skin, "dleather", 1.8, 0.0, amp=0.4))
    head = (blob([(-1, -63), (-24, -78), (-4, -56)], skin)
            + blob([(0, -50), (-4, -62), (4, -74), (17, -76), (26, -67), (28, -57), (19, -49), (8, -47)], skin)
            + blob([(21, -66), (35, -59), (32, -54), (22, -55)], skin)
            + blob([(3, -62), (-28, -70), (-12, -60), (2, -55)], skin)
            + stroke("M-6,-73 L-18,-98", OL, 5) + stroke("M-6,-73 L-18,-98", "#e8463a", 3)
            + stroke("M0,-75 L-4,-102", OL, 5) + stroke("M0,-75 L-4,-102", "#3fd0b0", 3)
            + stroke("M5,-75 L10,-98", OL, 5) + stroke("M5,-75 L10,-98", "#ffd21f", 3)
            + limb((-4, -72), (14, -76), 5, 5, "red", sw=2)
            + "".join(stroke(f"M{x},-60 L{x+3},-54", "#e8eef8", 1.6, 0.9) for x in (8, 12))
            + stroke("M14,-70 Q20,-74 26,-69", OL, 3)
            + hl_ell(10, -70, 6, 3, 0.3, -15))
    parts.append(part("head", head, (5, -48), 4, parent="torso", anim=swing(0.07, 1.0, 0.0, 2.0),
                      glow=eye(19, -63, 3.2, "#7dff9a")))
    staff = (limb((15, -8), (17, -84), 4.5, 5.5, "wood", sw=2.2)
             + stroke("M16,-60 Q12,-64 16,-68", OL, 2) + circ(17, -88, 7, "bone", sw=2)
             + circ(15, -89, 1.6, OL, sw=0) + circ(19.5, -89, 1.6, OL, sw=0))
    crystal = ('<path d="M17,-112 L22,-100 L17,-94 L12,-100 Z" fill="#7dff9a" opacity="0.6" filter="url(#blur)"/>'
               + poly([(17, -112), (22, -100), (17, -94), (12, -100)], "#9dffb8", sw=2)
               + poly([(17, -110), (19, -100), (17, -96)], "#ffffff", sw=0)
               + glowdot(17, -102, 3, "#7dff9a"))
    parts.append(part("weapon", staff, (16, -34), 5, parent="arm_f", glow=crystal))
    parts.append(arm("arm_f", (6, -46), (16, -34), 7, "robe", 6, 3.14159, amp=0.25, hand_mat=skin))
    parts[-1]["anim"]["cast"] = -1.5
    return dict(id="shaman", style="biped", height=112, r=12, fit=3.6, rim="#b0ffd8",
                motion={"bob": 2.0, "stride": 36}, parts=parts)


# ================================================================ troll (regenerator)

def troll():
    skin = "troll"
    parts = [shadow_part(66)]
    parts.append(leg("leg_b", (-6, -40), (-8, 0), 14, skin, skin, 0, 3.14159, amp=0.45, shade=True, boot_len=1.2))
    parts.append(arm("arm_b", (-8, -80), (-10, -22), 13, skin, 1, 0.0, amp=0.3, shade=True, fist=1.3))
    torso = (blob([(-16, -34), (-22, -58), (-16, -82), (2, -92), (22, -84), (26, -62), (18, -40), (0, -34)], skin)
             + blob([(-20, -60), (-24, -72), (-16, -86), (-6, -90), (-10, -78), (-14, -68)], "moss")
             + blob([(6, -86), (14, -94), (22, -88), (14, -84)], "moss", sw=2)
             + hl_ell(10, -66, 8, 12, 0.18, -20)
             + stroke("M2,-56 Q10,-52 18,-56", MATS["troll"][2], 2, 0.6)
             + stroke("M0,-48 Q10,-44 19,-48", MATS["troll"][2], 2, 0.6)
             + blob([(-15, -38), (-12, -22), (-2, -30), (6, -20), (14, -36), (0, -42)], "leather"))
    parts.append(part("torso", torso, (0, -40), 2, anim=swing(0.04, 0.0, 0.16, 2.0)))
    parts.append(leg("leg_f", (6, -40), (6, 0), 14, skin, skin, 3, 0.0, amp=0.45, boot_len=1.2))
    head = (blob([(8, -80), (8, -94), (20, -104), (34, -98), (39, -88), (34, -78), (20, -74)], skin)
            + blob([(32, -94), (50, -86), (46, -80), (34, -82)], skin)
            + blob([(4, -96), (10, -108), (20, -110), (14, -100)], "moss", sw=2)
            + stroke("M23,-96 Q30,-99 36,-94", OL, 3.5)
            + stroke("M22,-79 Q30,-76 38,-80", OL, 3)
            + blob([(26, -79), (29, -90), (32, -79)], "bone", sw=1.6)
            + blob([(34, -80), (37, -88), (39, -80)], "bone", sw=1.4)
            + hl_ell(18, -100, 6, 2.5, 0.3, -15))
    parts.append(part("head", head, (14, -82), 4, parent="torso", anim=swing(0.06, 1.0, 0.0, 2.0),
                      glow=eye(30, -90, 2.4, "#ffb020", pupil=False)))
    parts.append(arm("arm_f", (12, -80), (22, -22), 14, skin, 6, 3.14159, amp=0.3, fist=1.35))
    return dict(id="troll", style="biped", height=112, r=13, fit=3.7, rim="#c8fff0",
                motion={"bob": 3.5, "stride": 50}, parts=parts)


# ================================================================ ogre warden

def ogre():
    skin = "ogre"
    parts = [shadow_part(84)]
    parts.append(leg("leg_b", (-8, -44), (-9, 0), 17, "steel", "iron", 0, 3.14159, amp=0.4, shade=True))
    parts.append(arm("arm_b", (-10, -86), (-16, -50), 15, skin, 1, 0.0, amp=0.3, shade=True, fist=1.2))
    torso = (blob([(-20, -40), (-26, -66), (-18, -90), (4, -97), (25, -88), (31, -64), (24, -40), (2, -34)], skin)
             + blob([(-16, -68), (-18, -88), (4, -96), (24, -88), (27, -70), (6, -64)], "steel", radial=False)
             + path(smooth_d([(-16, -68), (-18, -88), (4, -96), (24, -88), (27, -70), (6, -64)]), "none", sw=0,
                    extra='stroke="#f2c230" stroke-width="2.4"')
             + limb((-21, -42), (27, -42), 9, 9, "leather", sw=3)
             + blob([(0, -48), (8, -48), (8, -36), (0, -36)], "gold", sw=2)
             + poly([(-18, -40), (-12, -18), (-4, -38), (4, -16), (12, -38), (20, -18), (24, -40)], "dleather", sw=2.5)
             + hl_ell(8, -86, 9, 3, 0.35, -10))
    rune = glowpath("M6,-86 L6,-74 M2,-82 L10,-78 M2,-76 L10,-80", "#ffd21f", 1.6)
    parts.append(part("torso", torso, (0, -44), 2, anim=swing(0.03, 0.0, 0.06, 2.0), glow=rune))
    parts.append(leg("leg_f", (8, -44), (10, 0), 17, "steel", "iron", 3, 0.0, amp=0.4))
    head = (blob([(8, -92), (6, -104), (16, -112), (28, -110), (32, -100), (28, -90), (16, -88)], skin)
            + blob([(4, -104), (8, -118), (20, -122), (32, -116), (34, -104), (18, -106)], "steel", radial=False)
            + limb((4, -105), (34, -105), 4, 4, "gold", sw=1.6)
            + limb((18, -121), (18, -106), 3, 3, "gold", sw=1.5)
            + blob([(6, -114), (-6, -120), (-14, -134), (-2, -124), (4, -118)], "bone")
            + blob([(28, -118), (34, -130), (42, -138), (38, -124), (33, -114)], "bone")
            + stroke("M20,-93 Q26,-91 31,-94", OL, 2.6)
            + blob([(26, -93), (28, -99), (30, -93)], "bone", sw=1.3)
            + hl_ell(16, -117, 7, 2.5, 0.45, -10))
    parts.append(part("head", head, (12, -92), 4, parent="torso", anim=swing(0.04, 1.0, 0.0, 2.0),
                      glow=eye(25, -100, 2.6, "#ffd21f", pupil=False)))
    hammer = (limb((24, -40), (52, -112), 5, 5, "wood", sw=2.4)
              + limb((27, -47), (29, -52), 6, 6, "gold", sw=1.6)
              + poly([(36, -126), (62, -136), (70, -114), (44, -104)], "steel", sw=3)
              + limb((39, -122), (63, -131), 4, 4, "gold", sw=1.5) + limb((44, -109), (67, -118), 4, 4, "gold", sw=1.5)
              + hl_ell(50, -124, 8, 2, 0.4, -20))
    parts.append(part("weapon", hammer, (28, -56), 5, parent="arm_f",
                      glow=glowpath("M53,-123 L55,-117 M51,-119 L57,-121", "#ffd21f", 1.4)))
    pauldron = (blob([(4, -82), (6, -94), (18, -98), (30, -90), (30, -80), (16, -77)], "steel", radial=False)
                + path(smooth_d([(6, -84), (8, -93), (18, -96), (28, -89), (28, -82)]), "none", sw=0,
                       extra='stroke="#f2c230" stroke-width="2"'))
    parts.append(part("arm_f", arm("x", (16, -86), (28, -56), 16, skin, 0, 0, fist=1.2)["svg"] + pauldron, (16, -86), 6,
                      parent="torso", anim=swing(0.3, 3.14159)))
    return dict(id="ogre", style="biped", height=136, r=19, fit=3.0, rim="#fff0b0",
                motion={"bob": 3.5, "stride": 60}, parts=parts)


# ================================================================ pharaoh colossus (mummy king)

def pharaoh():
    wrap = "mummy"
    parts = [shadow_part(100)]
    parts.append(leg("leg_b", (-8, -50), (-9, 0), 18, wrap, wrap, 0, 3.14159, amp=0.35, shade=True))
    parts.append(arm("arm_b", (-12, -100), (-20, -62), 15, wrap, 1, 0.0, amp=0.25, shade=True))
    torso = (blob([(-20, -46), (-24, -76), (-18, -102), (4, -110), (24, -102), (28, -76), (22, -46), (0, -42)], wrap)
             + "".join(stroke(f"M-20,{y} Q4,{y+6} 26,{y-2}", MATS["mummy"][2], 1.5, 0.6) for y in range(-96, -50, 9))
             + path("M-18,-100 Q4,-80 26,-100 Q30,-94 26,-88 Q4,-66 -20,-88 Z", "gold", sw=2.5)
             + "".join(circ(4 + 18 * math.cos(a), -96 + 14 * math.sin(a), 2.2, "#3fd0d0", sw=1)
                       for a in (0.9, 1.3, 1.7, 2.1, 2.5))
             + poly([(-20, -50), (24, -50), (30, -20), (-24, -20)], "gold", sw=2.5)
             + "".join(poly([(x, -48), (x + 5, -48), (x + 7, -22), (x + 2, -22)], "#2a5ab8", sw=0) for x in (-16, -4, 8, 20))
             + limb((-22, -50), (26, -50), 7, 7, "gold", sw=2))
    parts.append(part("torso", torso, (0, -50), 2, anim=swing(0.025, 0.0, 0.05, 2.0)))
    parts.append(leg("leg_f", (8, -50), (10, 0), 18, wrap, wrap, 3, 0.0, amp=0.35))
    nemes = (blob([(-6, -112), (-2, -132), (14, -142), (32, -134), (36, -118), (34, -100), (28, -94),
                   (24, -110), (8, -108), (0, -96), (-10, -94)], "gold", radial=False)
             + "".join(stroke(f"M{x},-136 Q{x - 4},-118 {x - 8},-96", "#2a5ab8", 3, 0.9) for x in (2, 10))
             + stroke("M0,-120 Q16,-126 34,-118", "#2a5ab8", 3, 0.9))
    face = (blob([(14, -102), (12, -122), (22, -128), (34, -122), (36, -110), (30, -100)], "gold")
            + stroke("M24,-120 L34,-118", "#2a5ab8", 2.5) + stroke("M27,-108 L35,-108", OL, 1.6)
            + blob([(26, -100), (32, -100), (30, -86), (28, -86)], "gold", sw=1.8)
            + path("M28,-136 Q34,-142 32,-132 Q30,-130 28,-136 Z", "gold", sw=1.5))
    parts.append(part("head", nemes + face, (14, -104), 4, parent="torso", anim=swing(0.03, 1.0, 0.0, 2.0),
                      glow=eye(28, -116, 2.6, "#3ff0dc", pupil=False) + glowdot(31, -133, 1.6, "#3ff0dc")))
    hook = "M33,-136 Q34,-152 46,-150 Q54,-146 50,-136"
    crook = (limb((32, -30), (34, -136), 5, 5, "gold", sw=2.2)
             + "".join(limb((32.4, y), (32.6, y - 3), 6, 6, "#2a5ab8", sw=1.2) for y in range(-120, -40, 16))
             + stroke(hook, OL, 7) + stroke(hook, "#f2c230", 4))
    parts.append(part("weapon", crook, (30, -66), 5, parent="arm_f"))
    collar = blob([(8, -96), (12, -106), (22, -104), (28, -96), (20, -92)], "gold", sw=2)
    parts.append(part("arm_f", arm("x", (14, -98), (30, -66), 16, wrap, 0, 0)["svg"] + collar
                      + limb((26, -72), (32, -78), 9, 9, "gold", sw=2), (14, -98), 6, parent="torso",
                      anim=swing(0.25, 3.14159)))
    return dict(id="pharaoh", style="biped", height=152, r=32, fit=3.0, rim="#9ffff0",
                motion={"bob": 3.0, "stride": 70}, parts=parts)


MONSTERS = {f.__name__: f for f in (goblin, imp, orc, hobgoblin, shaman, troll, ogre, pharaoh)}

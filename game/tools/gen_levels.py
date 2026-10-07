#!/usr/bin/env python3
"""Generates the 50 campaign levels (data/levels/level_XX.json + index.json).

Layouts follow docs/GDD.md section 6. Paths are snakes on a 64px grid; pads are
placed greedily where they cover the most path. Balance knobs live in TUNING,
and per-level hp multipliers can be overridden in tools/tuning.json (written by
tools/balance.py after bot playtests).

Usage: python3 tools/gen_levels.py
"""
import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "levels")
CELL = 64
COLS, ROW_MIN, ROW_MAX = 20, 2, 10

WORLDS = [
    {"name": "Verdant Vale", "accent": "#9be37a", "menu_color": "#2c4a2a",
     "theme": {"grass": "#4a8a3f", "grass_alt": "#447f3a", "path": "#d9b77a", "path_edge": "#9c7a45", "pad": "#b9b0a2", "pad_edge": "#4f4940", "rock": "#99948c"},
     "names": ["First Steps", "Quick Feet", "Winding Brook", "Swarm Meadow", "Beetle Hollow", "Twin Trails", "Wings Over Vale", "Two Gates", "Crossroads", "Thornback's Lair"]},
    {"name": "Scorched Dunes", "accent": "#ffcf6a", "menu_color": "#4a3420",
     "theme": {"grass": "#d8b06a", "grass_alt": "#cfa660", "path": "#b98b52", "path_edge": "#8a5f33", "pad": "#c9b79a", "pad_edge": "#6b5236", "rock": "#b07a4a"},
     "names": ["Long Caravan", "Ember Road", "Mirage Fork", "Oasis Gate", "Sandwyrm Pit", "Sky Raiders", "Split Dunes", "Narrow Pass", "Temple Steps", "Colossus Court"]},
    {"name": "Frostpeak", "accent": "#a8e8ff", "menu_color": "#22344a",
     "theme": {"grass": "#dfeef8", "grass_alt": "#d3e6f3", "path": "#9fb8cc", "path_edge": "#6f8aa3", "pad": "#c5d2de", "pad_edge": "#4c5d70", "rock": "#8fa7bf"},
     "names": ["Thin Ice", "Cold Fork", "Glacier Cross", "Whiteout", "Wraith Hollow", "Three Rivers", "Iron Skies", "Frozen Cross", "Avalanche", "Titan's Throne"]},
    {"name": "Neon Foundry", "accent": "#ff5ad8", "menu_color": "#1a1424",
     "theme": {"grass": "#2b2f3a", "grass_alt": "#262a34", "path": "#4a4f5e", "path_edge": "#1a1d24", "pad": "#6b7080", "pad_edge": "#22252e", "rock": "#555a66"},
     "names": ["Power Up", "Assembly Line", "Deep Shaft", "Node Wars", "Overclock", "Parallel Lines", "Gunship Bay", "Warden Hall", "Short Circuit", "The Dreadnought"]},
    {"name": "Void Rift", "accent": "#c89bff", "menu_color": "#120a1e",
     "theme": {"grass": "#2a1840", "grass_alt": "#24143a", "path": "#6a4a8a", "path_edge": "#3a2550", "pad": "#8a78a8", "pad_edge": "#2a1a40", "rock": "#5a4a7a"},
     "names": ["Rift Walk", "Loop Back", "Phantom Choir", "Storm of Wings", "Stalker's Edge", "Escort Duty", "Four Gates", "Last Pads", "The Gauntlet", "The Void Sovereign"]},
]

# number: (layout, waves, pads)  from GDD section 6 (pads tightened on "limited pads" levels)
LAYOUT = {
    1: ("S", 6, 12), 2: ("S", 8, 12), 3: ("L", 8, 12), 4: ("S", 10, 12), 5: ("F", 10, 13),
    6: ("F", 12, 13), 7: ("SA", 12, 12), 8: ("M", 12, 14), 9: ("X", 14, 14), 10: ("FA", 15, 14),
    11: ("L", 12, 13), 12: ("S", 12, 12), 13: ("F", 14, 13), 14: ("M", 14, 14), 15: ("P", 15, 15),
    16: ("XA", 15, 14), 17: ("F", 15, 13), 18: ("L", 16, 10), 19: ("MA", 16, 14), 20: ("PA", 18, 15),
    21: ("S", 14, 12), 22: ("F", 15, 13), 23: ("X", 15, 14), 24: ("L", 16, 13), 25: ("FA", 16, 14),
    26: ("P3", 16, 16), 27: ("MA", 17, 14), 28: ("X", 17, 13), 29: ("PA", 18, 13), 30: ("FA", 20, 15),
    31: ("S", 15, 12), 32: ("F", 16, 13), 33: ("L", 16, 13), 34: ("M", 17, 14), 35: ("XA", 18, 14),
    36: ("P", 18, 14), 37: ("FA", 18, 14), 38: ("M", 19, 14), 39: ("XA", 19, 12), 40: ("PA", 20, 15),
    41: ("S", 16, 12), 42: ("F", 17, 13), 43: ("X", 18, 14), 44: ("MA", 18, 14), 45: ("P", 19, 15),
    46: ("LA", 20, 13), 47: ("X4", 20, 16), 48: ("PA", 20, 10), 49: ("MA", 22, 14), 50: ("P3A", 25, 16),
}

FIRST_SEEN = {"scuttler": 1, "runner": 2, "swarmling": 4, "brute": 5, "drone": 7, "shieldbearer": 11,
              "mender": 14, "splitter": 17, "regenerator": 21, "phantom": 24, "gunship": 27,
              "burrower": 33, "warden": 38}
BOSSES = {5: "iron_beetle", 10: "thornback", 15: "sandwyrm", 20: "pharaoh", 25: "frost_wraith",
          30: "glacier_titan", 35: "overclock_mech", 40: "dreadnought", 45: "rift_stalker", 50: "void_sovereign"}
INTERVAL = {"scuttler": 0.9, "runner": 0.55, "swarmling": 0.18, "brute": 2.0, "drone": 1.0, "shieldbearer": 1.6,
            "mender": 2.2, "splitter": 1.6, "regenerator": 1.6, "phantom": 1.2, "gunship": 2.4,
            "burrower": 1.8, "warden": 6.0}

TUNING = {
    "hp_base": 1.0, "hp_per_level": 0.05,        # enemy hp multiplier = base + per_level * (n-1)
    "gold_exponent": 0.7,                          # kill gold scales with hp_mult ** gold_exponent
    "budget_base": 8.0, "budget_per_level": 0.6,   # threat points in wave 1
    "budget_wave_growth": 0.12,                    # +12% per wave
    "gold_base": 300, "gold_per_level": 12,
}


def threat(enemies, eid):
    return enemies[eid].get("threat", 1.0)


def px(c, r):
    return [c * CELL + CELL // 2, r * CELL + CELL // 2]


# ---------------------------------------------------------------- path geometry

def seg_points(a, b, step=0.5):
    (x0, y0), (x1, y1) = a, b
    n = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) / step))
    return [(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n) for i in range(n + 1)]


def point_seg(p, a, b):
    (px_, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((px_ - ax) * dx + (py - ay) * dy) / L))
    return math.hypot(px_ - (ax + t * dx), py - (ay + t * dy))


def _cross(o, a, b):
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def min_dist(seg_a, seg_b):
    (a, b), (c, d) = seg_a, seg_b
    if (_cross(a, b, c) * _cross(a, b, d) < 0) and (_cross(c, d, a) * _cross(c, d, b) < 0):
        return 0.0
    return min(point_seg(a, c, d), point_seg(b, c, d), point_seg(c, a, b), point_seg(d, a, b))


def self_ok(pts, gap=1.9):
    segs = list(zip(pts, pts[1:]))
    for i in range(len(segs)):
        for j in range(i + 2, len(segs)):
            if min_dist(segs[i], segs[j]) < gap:
                return False
    return True


def apart(a_pts, b_pts, gap=1.9, ignore=()):
    """True when no part of polyline a comes within gap cells of b, except near the ignore points."""
    segs_b = list(zip(b_pts, b_pts[1:]))
    for s in zip(a_pts, a_pts[1:]):
        for p in seg_points(*s):
            if any(math.hypot(p[0] - ix, p[1] - iy) < 2.2 for ix, iy in ignore):
                continue
            if any(point_seg(p, *sb) < gap for sb in segs_b):
                return False
    return True


def snake(rng, start, end, turns, rows=(ROW_MIN, ROW_MAX), serpentine=False):
    """Orthogonal path from start (c, r) to end (c, r) moving left to right."""
    avail = list(range(start[0] + 2, end[0] - 1))
    for _ in range(600):
        n = max(turns, 1 if start[1] != end[1] else 0, 2 if abs(start[1] - end[1]) == 1 else 0)
        n = min(n, (len(avail) + 1) // 2)
        cols = sorted(rng.sample(avail, n)) if n else []
        if any(b - a < 2 for a, b in zip(cols, cols[1:])):
            continue
        c, r = start
        pts = [(c, r)]
        for i, nc in enumerate(cols):
            if i == len(cols) - 1:
                nr = end[1]
            elif serpentine:
                nr = rows[1] if r - rows[0] < (rows[1] - rows[0]) / 2 else rows[0]
            else:
                nr = rng.choice([x for x in range(rows[0], rows[1] + 1) if abs(x - r) >= 2] or [r])
            pts.append((nc, r))
            pts.append((nc, nr))
            r = nr
        if r != end[1]:
            continue
        pts.append(end)
        pts = dedupe(pts)
        if self_ok(pts):
            return pts
    raise RuntimeError("snake failed %s %s" % (start, end))


def dedupe(pts):
    out = []
    for p in pts:
        if out and out[-1] == p:
            continue
        if len(out) >= 2 and (out[-2][0] == out[-1][0] == p[0] or out[-2][1] == out[-1][1] == p[1]):
            out[-1] = p
            continue
        out.append(p)
    return out


def make_paths(rng, layout):
    kind = layout.rstrip("A")
    if kind == "S":
        r0, r1 = rng.randint(2, 10), rng.randint(2, 10)
        return [snake(rng, (-1, r0), (COLS, r1), rng.randint(3, 4))]
    if kind == "L":
        r0 = rng.choice([2, 10])
        return [snake(rng, (-1, r0), (COLS, rng.choice([2, 10])), 5, serpentine=True)]
    if kind == "F":
        for _ in range(300):
            r0 = rng.randint(4, 8)
            ra = rng.randint(2, r0 - 2)
            rb = rng.randint(r0 + 2, 10)
            if rb - ra < 4:
                continue
            rm = rng.randint(ra + 2, rb - 2)
            c1 = rng.randint(2, 5)
            c2 = rng.randint(c1 + 7, 16)
            a_mid = [(c1, r0), (c1, ra), (c2, ra), (c2, rm)]
            b_mid = [(c1, r0), (c1, rb), (c2, rb), (c2, rm)]
            if rng.random() < 0.5 and ra >= 4:
                cm = rng.randint(c1 + 2, c2 - 2)
                a_mid = [(c1, r0), (c1, ra), (cm, ra), (cm, ra - 2), (c2, ra - 2), (c2, rm)]
            ends = [x for x in range(2, 11) if abs(x - rm) != 1]
            tail = snake(rng, (c2, rm), (COLS, rng.choice(ends)), 1)
            head = [(-1, r0), (c1, r0)]
            pa = dedupe(head + a_mid[1:] + tail[1:])
            pb = dedupe(head + b_mid[1:] + tail[1:])
            if self_ok(pa) and self_ok(pb):
                return [pa, pb]
        raise RuntimeError("fork failed")
    if kind == "M":
        for _ in range(200):
            a = snake(rng, (-1, rng.randint(2, 10)), (COLS, rng.randint(2, 10)), 3)
            k = rng.randint(len(a) // 2, len(a) - 2)
            join = a[k]
            if join[0] < 7:
                continue
            top = rng.random() < 0.5
            c0 = rng.randint(3, max(3, join[0] - 3))
            start = (c0, -1 if top else 11)
            mid_r = join[1]
            b = dedupe([start, (c0, mid_r), join] + a[k + 1:])
            if self_ok(b) and apart(b[:3], a[:k], ignore=[px_c(*join)]):
                return [a, b]
        raise RuntimeError("merge failed")
    if kind.startswith("P"):
        lanes = 3 if kind == "P3" else 2
        bands = [(2, 4), (6, 6), (8, 10)] if lanes == 3 else [(2, 5), (7, 10)]
        for _ in range(200):
            out = []
            for b in bands:
                rows_ok = [b[0], b[1]] if b[1] - b[0] >= 2 else [b[0]]
                if b[1] - b[0] >= 3:
                    rows_ok = list(range(b[0], b[1] + 1))
                r0 = rng.choice(rows_ok)
                r1 = rng.choice([x for x in rows_ok if abs(x - r0) != 1])
                out.append(snake(rng, (-1, r0), (COLS, r1), 3 if b[1] > b[0] else 0, rows=b))
            if all(apart(out[i], out[j]) for i in range(lanes) for j in range(i + 1, lanes)):
                return out
        raise RuntimeError("parallel failed")
    if kind.startswith("X"):
        for _ in range(300):
            ca = rng.randint(3, 8)
            cb = rng.randint(ca + 4, 16)
            top = rng.sample([2, 3, 4], 2)
            bottom = rng.choice([(8, 10), (10, 8)])
            a = [(-1, top[0]), (ca, top[0]), (ca, bottom[0]), (COLS, bottom[0])]
            b = [(-1, bottom[1]), (cb, bottom[1]), (cb, top[1]), (COLS, top[1])]
            if abs(top[0] - top[1]) < 2:
                # keep the two top lanes apart by giving b's exit row more room
                b[-2:] = [(cb, 6 if top[0] <= 3 else 2), (COLS, 6 if top[0] <= 3 else 2)]
                if any(abs(b[-1][1] - r) < 2 for r in (top[0], bottom[0])):
                    continue
            if not (self_ok(a) and self_ok(b) and no_overlap(a, b)):
                continue
            if kind != "X4":
                return [a, b]
            spare = [c for c in range(2, 18) if min(abs(c - ca), abs(c - cb)) >= 2]
            if len(spare) < 2:
                continue
            cc, cd = sorted(rng.sample(spare, 2))
            if cd - cc < 2:
                continue
            c = [(cc, -1), (cc, 11)]
            d = [(cd, 11), (cd, -1)]
            paths = [a, b, c, d]
            if all(no_overlap(paths[i], paths[j]) for i in range(4) for j in range(i + 1, 4)):
                return paths
        raise RuntimeError("cross failed")
    raise ValueError(layout)


def px_c(c, r):
    return (c, r)


def no_overlap(a, b, gap=1.9):
    """Crossings are fine, but parallel segments must not run on top of each other."""
    for sa in zip(a, a[1:]):
        for sb in zip(b, b[1:]):
            horiz_a = sa[0][1] == sa[1][1]
            horiz_b = sb[0][1] == sb[1][1]
            if horiz_a != horiz_b:
                continue
            if min_dist(sa, sb) < gap:
                return False
    return True


def to_pixels(pts):
    out = []
    for c, r in pts:
        x = -40 if c < 0 else 1320 if c >= COLS else c * CELL + CELL // 2
        y = -40 if r < 0 else 760 if r > 10 else r * CELL + CELL // 2
        out.append([x, y])
    return out


def air_paths(rng, count, paths_px):
    """Air routes cut corners across a ground path, so towers guarding the lanes can reach them."""
    out = []
    for i in range(count):
        ground = paths_px[i % len(paths_px)]
        samples = [p for p in path_samples([ground], 32) if 60 < p[0] < 1220 and 90 < p[1] < 680]
        if len(samples) < 4:
            out.append([[-40, 360], [1320, 360]])
            continue
        k = len(samples)
        picks = [samples[int(k * f)] for f in (0.25, 0.5, 0.75)]
        pts = [[-40, int(picks[0][1])]] + [[int(x + rng.randint(-40, 40)), int(y + rng.randint(-40, 40))] for x, y in picks]
        pts.append([1320, int(picks[-1][1])])
        pts.sort(key=lambda p: p[0])
        out.append(pts)
    return out


# ---------------------------------------------------------------- pads

def path_samples(paths_px, step=16):
    pts = []
    for path in paths_px:
        for (x0, y0), (x1, y1) in zip(path, path[1:]):
            n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
            for i in range(n):
                x, y = x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n
                if -10 <= x <= 1290 and -10 <= y <= 730:
                    pts.append((x, y))
    return pts


def place_pads(rng, paths_px, count):
    samples = path_samples(paths_px)
    weight = [1.0] * len(samples)
    cands = []
    for x in range(48, 1240, 32):
        for y in range(104, 690, 32):
            d = min(point_seg((x, y), a, b) for path in paths_px for a, b in zip(path, path[1:]))
            if 66 <= d <= 130:
                cover = [i for i, (sx, sy) in enumerate(samples) if math.hypot(x - sx, y - sy) <= 160]
                cands.append(((x, y), cover))
    pads = []
    for _ in range(count):
        best, best_score = None, -1
        for (p, cover) in cands:
            if any(math.hypot(p[0] - q[0], p[1] - q[1]) < 84 for q in pads):
                continue
            score = sum(weight[i] for i in cover) + rng.random() * 3
            if score > best_score:
                best, best_score = (p, cover), score
        if best is None:
            break
        pads.append(best[0])
        for i in best[1]:
            weight[i] *= 0.45
    return pads


# ---------------------------------------------------------------- waves

def roster(n):
    return [e for e, lvl in FIRST_SEEN.items() if lvl <= n]


def make_waves(rng, n, wave_count, enemies, has_air, path_count):
    pool = roster(n)
    newest = max(pool, key=lambda e: FIRST_SEEN[e])
    ground = [e for e in pool if not enemies[e].get("flying")]
    air = [e for e in pool if enemies[e].get("flying")]
    budget0 = TUNING["budget_base"] + TUNING["budget_per_level"] * (n - 1)
    waves = []
    for w in range(wave_count):
        budget = budget0 * (1 + TUNING["budget_wave_growth"] * w) * (0.7 if w == 0 else 1.0)
        groups = []
        # one or two themes per wave; later waves mix more
        # heavy elites (warden, gunship...) only once the player has an economy going
        light = (lambda e: w >= 4 or threat(enemies, e) < 8)
        g_pool = [e for e in ground if light(e)] or ground
        a_pool = [e for e in air if light(e)]
        picks = [newest] if (w % 3 == 1 and FIRST_SEEN[newest] >= n - 3 and light(newest)) else []
        want = min(1 if w < 2 else 2 if w < wave_count * 0.6 else 3, len(g_pool) + len(a_pool))
        tries = 0
        while len(picks) < want and tries < 50:
            tries += 1
            choice = rng.choice(a_pool if (a_pool and has_air and rng.random() < 0.3) else g_pool)
            if choice not in picks:
                picks.append(choice)
        delay = 0.0
        for i, eid in enumerate(picks):
            share = budget / len(picks) * (0.6 if enemies[eid].get("flying") else 1.0)
            count = max(1, int(round(share / threat(enemies, eid))))
            count = min(count, 60 if eid == "swarmling" else 3 if eid == "warden" else 32)
            interval = INTERVAL[eid]
            groups.append({"enemy": eid, "count": count, "interval": interval, "delay": round(delay, 1), "path": "alt"})
            delay += min(count * interval * 0.5, 8.0) + 2.0
        waves.append({"groups": groups})
    if n in BOSSES:
        boss = BOSSES[n]
        last = waves[-1]
        for g in last["groups"]:
            g["delay"] = round(g["delay"] + 4.0, 1)
        last["groups"].insert(0, {"enemy": boss, "count": 1, "interval": 1.0, "delay": 0.0, "path": 0})
        last["boss"] = True
        if n % 10 == 5 and n > 5:
            pass
    elif n % 5 in (3, 4) and n > 10:
        # a mini-boss style elite pack before boss levels
        pass
    return waves


# ---------------------------------------------------------------- main

def main():
    enemies = json.load(open(os.path.join(ROOT, "data", "enemies.json")))
    overrides = {}
    tuning_path = os.path.join(ROOT, "tools", "tuning.json")
    if os.path.exists(tuning_path):
        overrides = json.load(open(tuning_path))
    os.makedirs(OUT, exist_ok=True)
    index = {"worlds": [{k: w[k] for k in ("name", "accent", "menu_color")} for w in WORLDS], "levels": []}
    for n in range(1, 51):
        rng = random.Random(1000 + n)
        world = (n - 1) // 10 + 1
        wd = WORLDS[world - 1]
        layout, wave_count, pad_count = LAYOUT[n]
        has_air = "A" in layout or n >= 7
        grid_paths = make_paths(rng, layout)
        paths_px = [to_pixels(p) for p in grid_paths]
        pads = place_pads(rng, paths_px, pad_count)
        level_id = "level_%02d" % n
        mods = {}
        if world == 2:
            mods["sandstorm"] = {"interval": 30.0, "duration": 10.0, "factor": 0.7}
            if n >= 13:
                mods["resist"] = {"fire": 0.5}
        if world == 3:
            samples = path_samples(paths_px, 64)
            inner = [s for s in samples if 100 < s[0] < 1180]
            mods["ice"] = [[int(x), int(y), 70] for x, y in rng.sample(inner, min(3, len(inner)))]
            if n >= 22:
                mods["resist"] = {"frost": 0.5}
        pad_list = [[x, y] for x, y in pads]
        if world == 4:
            for i in rng.sample(range(len(pad_list)), 3):
                pad_list[i].append(1)
        if world == 5:
            rifts = []
            if len(paths_px) >= 2:
                rifts.append({"path": 0, "at": 0.45, "to_path": 1, "to": 0.3})
                rifts.append({"path": 1, "at": 0.6, "to_path": 0, "to": 0.35})
            else:
                rifts.append({"path": 0, "at": 0.6, "to_path": 0, "to": 0.25})
            mods["rifts"] = rifts
        base_hp = TUNING["hp_base"] + TUNING["hp_per_level"] * (n - 1)
        hp_mult = base_hp * float(overrides.get(level_id, 1.0))
        level = {
            "id": level_id,
            "number": n,
            "name": wd["names"][(n - 1) % 10],
            "world": world,
            "layout": layout,
            "hp_mult": round(hp_mult, 3),
            "gold_mult": round(base_hp ** TUNING["gold_exponent"], 3),
            "start_gold": TUNING["gold_base"] + TUNING["gold_per_level"] * (n - 1),
            "lives": 20,
            "theme": wd["theme"],
            "paths": paths_px,
            "air_paths": air_paths(rng, 2 if n >= 20 else 1, paths_px),
            "pads": pad_list,
            "modifiers": mods,
            "waves": make_waves(rng, n, wave_count, enemies, has_air, len(paths_px)),
        }
        with open(os.path.join(OUT, level_id + ".json"), "w") as f:
            json.dump(level, f, separators=(",", ":"))
        index["levels"].append({"id": level_id, "name": level["name"], "number": n, "world": world})
    with open(os.path.join(OUT, "index.json"), "w") as f:
        json.dump(index, f, indent=1)
    print("wrote 50 levels")


if __name__ == "__main__":
    main()

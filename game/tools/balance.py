#!/usr/bin/env python3
"""Plays every level with the headless bot and nudges per-level enemy HP until the
bot's results land in the target band. Writes tools/tuning.json and regenerates levels.

Usage: GODOT=/path/to/godot python3 tools/balance.py [rounds] [level numbers...]
"""
import concurrent.futures as cf
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", "godot")
TUNING = os.path.join(ROOT, "tools", "tuning.json")


def play(level_id):
    out = subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", ROOT, "res://scenes/main.tscn", "--",
                          "--level=" + level_id, "--autotest=auto"], capture_output=True, text=True, timeout=900).stdout
    errors = [l for l in out.splitlines() if "SCRIPT ERROR" in l]
    for line in out.splitlines():
        if line.startswith("AUTOTEST RESULT "):
            r = json.loads(line[len("AUTOTEST RESULT "):])
            r["errors"] = len(errors)
            return r
    return {"level": level_id, "won": False, "stars": 0, "lives": 0, "wave": 0, "waves": 0, "errors": len(errors), "crash": True}


def target(n, r):
    """Returns the HP factor change: >1 harder, <1 easier, 1 keep."""
    if not r["won"]:
        progress = r["wave"] / max(r["waves"], 1)
        return 0.65 if progress < 0.4 else 0.78 if progress < 0.75 else 0.9
    if n <= 3:
        return 1.0                      # tutorial levels stay easy
    if r["lives"] >= 20:
        return 1.08                     # the bot should lose a few lives
    if n > 10 and r["stars"] >= 3:
        return 1.04
    return 1.0


def main():
    rounds = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    only = [int(x) for x in sys.argv[2:]]
    tuning = json.load(open(TUNING)) if os.path.exists(TUNING) else {}
    numbers = only or list(range(1, 51))
    for rnd in range(rounds):
        with cf.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
            results = list(ex.map(lambda n: (n, play("level_%02d" % n)), numbers))
        changed = []
        for n, r in results:
            lid = "level_%02d" % n
            f = target(n, r)
            print("%s won=%-5s stars=%d lives=%2d wave=%2d/%2d hp=%.2f err=%d leaks=%s" % (
                lid, r["won"], r["stars"], r["lives"], r["wave"], r["waves"], tuning.get(lid, 1.0), r.get("errors", 0), r.get("leaks", {})))
            if f != 1.0:
                tuning[lid] = round(tuning.get(lid, 1.0) * f, 3)
                changed.append(n)
        json.dump(tuning, open(TUNING, "w"), indent=1, sort_keys=True)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_levels.py")], check=True)
        print("round %d: adjusted %d levels %s" % (rnd + 1, len(changed), changed))
        if not changed:
            break
        numbers = changed


if __name__ == "__main__":
    main()

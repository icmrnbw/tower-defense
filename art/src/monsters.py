"""Monster designs: rigged, side-view fantasy creatures for every enemy in enemies.json.

Usage: python3 monsters.py [id ...]              build atlases into game/art/monsters/
       python3 monster_sheet.py OUT.png [id ...]  review sheet of the built rest poses
"""
import sys

from monster_kit import build
import monsters_humanoid
import monsters_beasts

MONSTERS = {}
for mod in (monsters_humanoid, monsters_beasts):
    MONSTERS.update(mod.MONSTERS)

if __name__ == "__main__":
    for mid in sys.argv[1:] or list(MONSTERS):
        print("built", build(MONSTERS[mid]()))

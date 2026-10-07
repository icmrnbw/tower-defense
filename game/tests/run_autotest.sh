#!/usr/bin/env bash
# Headless playtest: the bot plays one level and prints a JSON result.
# Usage: GODOT=/path/to/godot bash tests/run_autotest.sh [level_id] [auto|none]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
out="$("$GODOT" --headless --fixed-fps 60 res://scenes/main.tscn -- --level="${1:-level_01}" --autotest="${2:-auto}" 2>&1)"
echo "$out" | grep "AUTOTEST"
if echo "$out" | grep -q "SCRIPT ERROR"; then
  echo "$out" | grep -A1 "SCRIPT ERROR" | head -20 >&2
  exit 1
fi

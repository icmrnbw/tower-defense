#!/usr/bin/env bash
# Headless playtest: a scripted bot plays the level and prints the result.
# Usage: GODOT=/path/to/godot tests/run_autotest.sh [basic|none]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
out="$("$GODOT" --headless --fixed-fps 60 -- --autotest="${1:-basic}" 2>&1)"
echo "$out" | grep -v "^    leak"
if echo "$out" | grep -q "SCRIPT ERROR"; then
  echo "FAILED: script errors" >&2
  exit 1
fi
echo "$out" | grep -q "AUTOTEST RESULT"

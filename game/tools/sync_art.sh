#!/usr/bin/env bash
# Copies finished tower sprites from ../art (owned by the art pipeline) into the Godot project.
# Towers without sprites keep their code-drawn placeholder.
set -euo pipefail
cd "$(dirname "$0")/.."
for dir in ../art/towers/*/png; do
  id="$(basename "$(dirname "$dir")")"
  mkdir -p "art/towers/$id"
  cp "$dir"/tower_"$id"_*.png "art/towers/$id/"
done
ls art/towers

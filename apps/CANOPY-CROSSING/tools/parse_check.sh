#!/usr/bin/env bash
# Loads every script once so parse/compile errors surface together.
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
timeout 120 "$GODOT" --headless --path . res://tests/parse_check.tscn -- --no-boot 2>&1 | grep -E "SCRIPT ERROR|Parse Error|Compile Error|BAD|parse check|at: GDScript" | grep -v "Failed to compile depended"

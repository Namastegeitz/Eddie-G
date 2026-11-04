#!/usr/bin/env bash
# Loads every .gd file inside a running scene (so autoloads exist) and prints
# parse/compile errors. Run this first: a class_name script with a parse
# error can make other headless runs hang.
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
files=$(find autoload scripts tests tools -name '*.gd' ! -name '_parse_check.gd' 2>/dev/null | sort)
{
  echo 'extends Node'
  echo 'func _ready() -> void:'
  for f in $files; do echo "	if load(\"res://$f\") == null: print(\"PARSE FAIL $f\")"; done
  echo '	print("parse check done")'
  echo '	get_tree().quit()'
} > tools/_parse_check.gd
printf '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://tools/_parse_check.gd" id="1"]\n\n[node name="P" type="Node"]\nscript = ExtResource("1")\n' > tools/_parse_check.tscn
timeout 120 "$GODOT" --headless --path . --import > /tmp/csd_import.log 2>&1
timeout 120 "$GODOT" --headless --path . res://tools/_parse_check.tscn 2>&1 | grep -E "SCRIPT ERROR|Parse Error|PARSE FAIL|parse check done|at: GDScript::reload|WARNING" | head -60
rm -f tools/_parse_check.gd tools/_parse_check.tscn tools/_parse_check.gd.uid

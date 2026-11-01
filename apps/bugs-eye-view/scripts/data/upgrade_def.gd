class_name UpgradeDef
extends Resource
## A colony upgrade bought with banked crumbs. Multiplies one BugStats property.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 20
@export var required_colony: int = 1
## Bug ids this applies to; empty = every bug.
@export var applies_to: PackedStringArray = []
## Pairs of BugStats property name -> multiplier.
@export var modifiers: Dictionary = {}


func applies(bug_id: StringName) -> bool:
	return applies_to.is_empty() or applies_to.has(String(bug_id))

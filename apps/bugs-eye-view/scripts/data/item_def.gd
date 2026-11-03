class_name ItemDef
extends Resource
## A special pickup: bug food (common, short boosts) or a crumb gem (rare,
## powerful). The numbers live in resources/items/*.tres; what each effect
## does is in PowerUps (one-shot effects) and BugBase (timed effects).

enum Kind { FOOD, GEM }

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.FOOD
## speed, hearty, fresh, soft_step, wired, big_meal (food);
## cloak, freeze, calm, iron_shell, magnet, decoy (gems).
@export var effect: StringName = &""
## Seconds the effect lasts (0 = instant).
@export var duration: float = 8.0
## Strength: speed multiplier, visibility/noise multiplier, crumbs worth, radius...
@export var amount: float = 1.0
@export var points: int = 50
@export var color: Color = Color.WHITE
## Shown when picked up.
@export var blurb: String = ""

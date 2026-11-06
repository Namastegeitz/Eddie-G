class_name ItemDef
extends Resource
## A special pickup: bug food (common, short boosts), a crumb gem (rare,
## powerful), a power-up (tucked into hidden corners and high places) or a
## treasure (a lost trinket for your showcase, from common to legendary).
## The numbers live in resources/items/*.tres; what each effect does is in
## PowerUps (one-shot effects) and BugBase (timed effects).

enum Kind { FOOD, GEM, POWER, TREASURE }

const RARITY_NAMES: Array[String] = ["Common", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Array[Color] = [Color(0.85, 0.88, 0.92), Color(0.35, 0.65, 1.0), Color(0.78, 0.45, 1.0), Color(1.0, 0.78, 0.25)]

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.FOOD
## speed, hearty, fresh, soft_step, wired, big_meal (food);
## cloak, freeze, calm, iron_shell, magnet, decoy (gems);
## turbo, spring, radar, double, shrink (power-ups).
@export var effect: StringName = &""
## Seconds the effect lasts (0 = instant).
@export var duration: float = 8.0
## Strength: speed multiplier, visibility/noise multiplier, crumbs worth, radius...
@export var amount: float = 1.0
@export var points: int = 50
@export var color: Color = Color.WHITE
## Shown when picked up.
@export var blurb: String = ""
## Treasures and gems: 0 common, 1 rare, 2 epic, 3 legendary.
@export var rarity: int = 0
## Which room it turns up in (the showcase hint).
@export var found_in: String = ""


func rarity_name() -> String:
	return RARITY_NAMES[clampi(rarity, 0, 3)]


func rarity_color() -> Color:
	return RARITY_COLORS[clampi(rarity, 0, 3)]


## Whether it goes on the showcase (treasures and crumb gems).
func is_collectible() -> bool:
	return kind == Kind.TREASURE or kind == Kind.GEM


static func load_def(item_id: StringName) -> ItemDef:
	var path := "res://resources/items/%s.tres" % item_id
	return load(path) as ItemDef if ResourceLoader.exists(path) else null


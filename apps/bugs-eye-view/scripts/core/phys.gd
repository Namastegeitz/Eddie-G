class_name Phys
## Collision layer bits and group names shared by every system.

const WORLD := 1
const PLAYER := 2
const THREAT := 4
const HAZARD := 8
const PICKUP := 16
const PROP := 32
const ZONE := 64
const WEB := 128

const GROUP_PLAYER := &"player"
const GROUP_THREAT := &"threat"
const GROUP_HUMAN := &"human"
const GROUP_PET := &"pet"
const GROUP_CRUMB := &"crumb"
const GROUP_INTERACTABLE := &"interactable"
const GROUP_REBOUNDER := &"rebounder"
const GROUP_PROP := &"physics_prop"
const GROUP_PERCH := &"cat_perch"
const GROUP_HIDING := &"hiding_spot"
const GROUP_COVER := &"cover"
const GROUP_SKIN := &"skin_anchor"
const GROUP_ITEM := &"pickup_item"

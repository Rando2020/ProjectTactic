# ============================================================
#  THE APPOINTED · TILE SPEC
#  Movement / element / hazard table for the auto-generator.
#
#  Each entry:
#    texture           — res:// path to the base PNG
#    overlay           — optional res:// path drawn on top (status FX)
#    cost              — movement cost (1.0 = normal)
#    impassable        — true if no unit can stand here
#    height            — relative elevation in tactical-grid units
#    tags              — string array used by ElementSystem reactions
#    hazard            — { damage, ether_damage, status, element }
#    spawn_weight      — how often the generator picks this tile when
#                        building open terrain (0 = never auto-spawn)
# ============================================================
extends Resource
class_name TileSpec

const TILES := {
  "grass": {
    "texture": "res://design/assets/ui/tiles/grass.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": ["natural"],
    "spawn_weight": 60,
  },
  "dirt": {
    "texture": "res://design/assets/ui/tiles/dirt.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": ["natural"],
    "spawn_weight": 20,
  },
  "road": {
    "texture": "res://design/assets/ui/tiles/road.png",
    "cost": 0.8, "height": 0, "impassable": false,
    "tags": [],
    "spawn_weight": 8,
  },
  "stone": {
    "texture": "res://design/assets/ui/tiles/stone.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": [],
    "spawn_weight": 18,
  },
  "shrine": {
    "texture": "res://design/assets/ui/tiles/shrine.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": ["sacred"],
    "reactions": ["sanctify_tile", "void_scar"],
    "spawn_weight": 2,
  },
  "shallow_water": {
    "texture": "res://design/assets/ui/tiles/shallow_water.png",
    "cost": 1.5, "height": 0, "impassable": false,
    "tags": ["wet", "natural"],
    "spawn_weight": 6,
  },
  "deep_water": {
    "texture": "res://design/assets/ui/tiles/deep_water.png",
    "cost": 99.0, "height": -1, "impassable": true,
    "tags": ["wet"],
    "spawn_weight": 4,
  },
  "ice": {
    "texture": "res://design/assets/ui/tiles/ice.png",
    "overlay": "res://design/assets/ui/tiles/ice_overlay.png",
    "cost": 1.2, "height": 0, "impassable": false,
    "tags": ["ice", "slippery"],
    "spawn_weight": 3,
  },
  "burning": {
    "texture": "res://design/assets/ui/tiles/burning.png",
    "overlay": "res://design/assets/ui/tiles/burning_overlay.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": ["fire"],
    "hazard": { "damage": 8, "status": "burning", "element": "fire" },
    "spawn_weight": 0,
  },
  "electrified_water": {
    "texture": "res://design/assets/ui/tiles/electrified_water.png",
    "overlay": "res://design/assets/ui/tiles/electrified_overlay.png",
    "cost": 1.5, "height": 0, "impassable": false,
    "tags": ["wet", "thunder"],
    "hazard": { "damage": 12, "status": "stun", "element": "thunder" },
    "spawn_weight": 0,
  },
  "wall": {
    "texture": "res://design/assets/ui/tiles/wall.png",
    "cost": 99.0, "height": 3, "impassable": true,
    "tags": ["structural"],
    "spawn_weight": 4,
  },
  "high_ground": {
    "texture": "res://design/assets/ui/tiles/high_ground.png",
    "cost": 1.4, "height": 2, "impassable": false,
    "tags": [],
    "spawn_weight": 5,
  },
  "void_anchor": {
    "texture": "res://design/assets/ui/tiles/void_anchor.png",
    "overlay": "res://design/assets/ui/tiles/void_overlay.png",
    "cost": 1.0, "height": 0, "impassable": false,
    "tags": ["dark", "sacred"],
    "reactions": ["void_scar", "expose_anchor", "shatter_anchor"],
    "hazard": { "ether_damage": 6, "element": "dark" },
    "spawn_weight": 1,
  },
}

# Convenience lookups
static func texture_of(id: String) -> String:
  return TILES.get(id, {}).get("texture", "")

static func overlay_of(id: String) -> String:
  return TILES.get(id, {}).get("overlay", "")

static func cost_of(id: String) -> float:
  return TILES.get(id, {}).get("cost", 1.0)

static func is_impassable(id: String) -> bool:
  return TILES.get(id, {}).get("impassable", false)

static func height_of(id: String) -> int:
  return TILES.get(id, {}).get("height", 0)

static func tags_of(id: String) -> Array:
  return TILES.get(id, {}).get("tags", [])

static func hazard_of(id: String) -> Dictionary:
  return TILES.get(id, {}).get("hazard", {})

# Returns array of [id, weight] pairs for generator sampling
static func spawn_pool() -> Array:
  var pool := []
  for id in TILES.keys():
    var w: int = TILES[id].get("spawn_weight", 0)
    if w > 0:
      pool.append([id, w])
  return pool

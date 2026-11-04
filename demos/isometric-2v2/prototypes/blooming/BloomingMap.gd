extends RefCounted
## Data-only courtyard: production GridSystem owns movement, jump, occupancy and costs.
const WIDTH := 12
const HEIGHT := 11
const STAIR_COLUMNS := [2,3,8,9]

static func create_map() -> MapData:
 var result := MapData.new()
 result.id="blooming_ruins_practice"
 result.display_name="THE BLOOMING RUINS"
 result.region="Ashvale"
 result.objective_type="defeat_all"
 result.objective_label="Defeat both enemies"
 result.map_width=WIDTH; result.map_height=HEIGHT
 result.default_terrain="stone"
 result.environment_theme_id="blooming-ruins-v2"
 result.reward_gold=0; result.reward_jp=0
 result.max_party_size=2
 result.player_spawns=[{"unit_id":"zane","x":3,"y":8,"facing":"NE"},{"unit_id":"kael","x":2,"y":9,"facing":"NE"}]
 result.enemy_spawns=[{"unit_id":"storm_imp","x":6,"y":7,"facing":"SW"},{"unit_id":"void_cultist","x":8,"y":2,"facing":"SW"}]
 for y in HEIGHT:
  for x in WIDTH:
   var h := 4 if y<=2 else 0
   var terrain := "stone" if y<=2 or y>=7 or x in STAIR_COLUMNS else "road"
   if x in STAIR_COLUMNS and y in [3,4,5]:h=6-y; terrain="stone"
   var blocked := x in [0,11] or y==0 or (y==10 and x in [1,10])
   if y==3 and not x in STAIR_COLUMNS:blocked=true;h=0
   if Vector2i(x,y) in [Vector2i(5,6),Vector2i(9,8),Vector2i(1,7),Vector2i(1,4),Vector2i(7,4)]:blocked=true
   if blocked:terrain="wall"
   result.tile_overrides.append({"x":x,"y":y,"height":h,"terrain":terrain})
 return result

static func is_stair(cell: Vector2i) -> bool:
 return cell.x in STAIR_COLUMNS and cell.y in [3,4,5]

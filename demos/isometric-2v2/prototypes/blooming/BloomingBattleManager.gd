extends BattleManager
## Opt-in courtyard navigation only. Combat, movement prices and retreat are unchanged.
## Manhattan distance cannot guide an actor around the courtyard retaining wall.
func _best_reachable_tile(unit: Unit, target: Unit, maximize_distance: bool) -> Vector2i:
 if maximize_distance:return super._best_reachable_tile(unit,target,true)
 var occupied:Array=[]
 for id in units:
  var other:Unit=_living_unit(str(id))
  if other and other!=unit and other.hp>0:occupied.append(other.grid_pos)
 var tiles:Dictionary=tactical_grid.tiles
 var jump:int=unit.unit_data.base_stats.jump
 var reachable:=GridSystem.get_move_range(unit.grid_pos,unit.unit_data.base_stats.move,tiles,occupied,map_data.map_width,map_data.map_height,jump)
 # Reverse Dijkstra computes remaining legal terrain cost from every candidate.
 # Target is a terminal goal, never a traversable occupied intermediate cell.
 var distance:Dictionary={target.grid_pos:0}
 var frontier:Array[Vector2i]=[target.grid_pos]
 while not frontier.is_empty():
  var best_index:=0
  for i in range(1,frontier.size()):
   if distance[frontier[i]]<distance[frontier[best_index]]:best_index=i
  var current:Vector2i=frontier.pop_at(best_index)
  for offset in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   var previous:Vector2i=current+offset
   if not tiles.has(previous) or tiles[previous].blocks_movement:continue
   if previous in occupied:continue
   var rise:=absi(int(tiles[current].height)-int(tiles[previous].height))
   if rise>jump:continue
   var cost:int=int(distance[current])+int(tiles[current].move_cost)+rise
   if cost<int(distance.get(previous,2147483647)):
    distance[previous]=cost
    if not previous in frontier:frontier.append(previous)
 var best_tile:=unit.grid_pos
 var best_distance:int=int(distance.get(best_tile,2147483647))
 for cell:Vector2i in reachable:
  var remaining:int=int(distance.get(cell,2147483647))
  if remaining<best_distance:
   best_distance=remaining;best_tile=cell
 return best_tile

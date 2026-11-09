extends "res://prototypes/isometric/Unit.gd"
## Review-only presentation adapter. The staging tool selects this scene;
## normal project scenes never load it. No stats, damage, turn or save changes.
const ROOT := 'res://tests/candidate_assets/'
var candidate_pose := 'idle'
var _candidate_textures: Dictionary = {}
var _candidate_specs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + 'specs.json'))

func candidate_spec() -> Dictionary:
 if unit_data == null: return {}
 var role: String = unit_data.id
 var direction: String = {'N':'ne','E':'se','S':'sw','W':'nw'}.get(_view_facing(facing),'')
 if role == 'storm_imp':
  if direction != 'sw': return {}
  return _candidate_specs[role].get(candidate_pose,{})
 if role not in ['kael','zane']: return {}
 var key := direction
 if role == 'zane' and candidate_pose != 'idle' and direction == 'se':
  key = 'cast-' + candidate_pose + '-se'
 return _candidate_specs[role].get(key,{})

func _apply_candidate() -> void:
 if not is_instance_valid(_sprite): return
 var spec := candidate_spec()
 if spec.is_empty():
  if unit_data != null and unit_data.id == 'storm_imp':
   _sprite.texture = unit_data.sprite_sheet
   var size := _sprite.texture.get_size()
   _sprite.scale = Vector2.ONE * (95.0 / maxf(size.x,size.y))
   _sprite.position = Vector2(0,-size.y * _sprite.scale.y * 0.5)
   _sprite.offset = Vector2.ZERO
   _sprite.flip_h = false
  return
 var path: String = ROOT + str(spec.file)
 if not _candidate_textures.has(path): _candidate_textures[path] = load(path)
 _sprite.texture = _candidate_textures[path]
 _sprite.scale = Vector2.ONE * float(spec.scale)
 _sprite.position = Vector2.ZERO
 _sprite.offset = _sprite.texture.get_size() * 0.5 - Vector2(spec.pivot[0],spec.pivot[1])
 _sprite.flip_h = false

func _fit_illustrated_actor() -> void:
 super._fit_illustrated_actor()
 _apply_candidate()

func _refresh_directional_sprite() -> void:
 candidate_pose = 'idle'
 super._refresh_directional_sprite()
 _apply_candidate()

func set_melee_pose(pose: String) -> bool:
 if unit_data != null and unit_data.id in ['kael','zane']:
  if pose == 'idle': reset_melee_pose(); return true
  return false
 return super.set_melee_pose(pose)

func set_cast_pose(pose: String) -> bool:
 if unit_data == null: return false
 var direction := _view_facing(facing)
 if not ((unit_data.id == 'zane' and direction == 'E') or (unit_data.id == 'storm_imp' and direction == 'S')):
  return false
 if pose not in ['anticipation','release']: return false
 candidate_pose = 'windup' if pose == 'anticipation' else 'release'
 _apply_candidate()
 return true

func recover_melee_pose() -> void:
 super.recover_melee_pose()
 candidate_pose = 'idle'
 _refresh_directional_sprite()

func reset_melee_pose() -> void:
 super.reset_melee_pose()
 candidate_pose = 'idle'
 _refresh_directional_sprite()

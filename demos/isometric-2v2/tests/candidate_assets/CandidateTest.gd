extends Node
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr('FAIL: ' + label)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 var battle = load('res://prototypes/blooming/BloomingBattle.tscn').instantiate()
 add_child(battle)
 await get_tree().process_frame
 for id in ['zane','kael','Enemy_1']:
  var unit = battle.battle_manager.units[id]
  check(unit.has_method('candidate_spec'), id + ' uses opt-in candidate adapter')
 if failures > 0:
  print('Candidate battle: %d checks, %d failures' % [checks,failures])
  get_tree().quit(1)
  return
 var ui = battle.battle_ui
 check(ui._bloom_skin_toggle.text == 'Candidate art (review)' and ui._bloom_skin_toggle.disabled, 'candidate setting is truthful and cannot fake a skin switch')
 for role in ['zane','kael','storm_imp']:
  var portrait: Texture2D = ui._framed_portrait(role)
  check(portrait is AtlasTexture and '/candidate_assets/sources/' in portrait.atlas.resource_path, role + ' portrait uses candidate source')
  if portrait is AtlasTexture:
   check(Rect2(Vector2.ZERO,portrait.atlas.get_size()).encloses(portrait.region), role + ' portrait crop fits source')
  var preview := TextureRect.new()
  ui._set_preview_portrait(preview,AssetRegistry.get_character_portrait_candidates(role)[0])
  check(preview.texture == portrait, role + ' forecast portrait matches candidate identity')
  preview.free()
 for id in ['zane','kael','Enemy_1']:
  var unit = battle.battle_manager.units[id]
  var before = [unit.grid_pos,unit.hp,unit.mp]
  for direction in ['N','E','S','W']:
   unit.set_facing(direction)
   var spec: Dictionary = unit.candidate_spec()
   var expected := {'N':'ne','E':'se','S':'sw','W':'nw'}
   if id == 'Enemy_1' and direction != 'S':
    check(spec.is_empty(), 'unsupported Hollow facing retains existing art')
    check(unit._sprite.texture == unit.unit_data.sprite_sheet, 'unsupported Hollow facing actually restores original texture')
    check(unit._sprite.offset == Vector2.ZERO and not unit._sprite.flip_h, 'fallback has original offset and mirroring')
    check(unit._sprite.scale.is_equal_approx(Vector2.ONE * (95.0 / maxf(unit.unit_data.sprite_sheet.get_size().x,unit.unit_data.sprite_sheet.get_size().y))), 'fallback has original scale')
   else:
    check(not spec.is_empty(), id + ' has mapped ' + expected[direction])
    check(unit._sprite.texture.resource_path.ends_with(spec.file), id + ' renders actual mapped source')
    check(not unit._sprite.flip_h, id + ' never mirrors asymmetric source')
    check(unit._sprite.scale.is_equal_approx(Vector2.ONE * float(spec.scale)), id + ' uses manifest scale')
    check(unit._sprite.offset.is_equal_approx(unit._sprite.texture.get_size() * 0.5 - Vector2(spec.pivot[0],spec.pivot[1])), id + ' uses source foot pivot')
   check([unit.grid_pos,unit.hp,unit.mp] == before, 'visual facing preserves gameplay state')
  unit.set_facing('E' if id == 'zane' else 'S')
  var supports: bool = id != 'kael'
  check(unit.set_cast_pose('anticipation') == supports, id + ' truthful cast support')
  if supports:
   check('windup' in unit._sprite.texture.resource_path, id + ' actual windup texture')
   check(unit.set_cast_pose('release'), id + ' cast release accepted')
   check('release' in unit._sprite.texture.resource_path, id + ' actual release texture')
   unit.recover_melee_pose()
   check('release' not in unit._sprite.texture.resource_path, id + ' recovers idle')
   unit.set_cast_pose('anticipation')
   unit.reset_melee_pose()
   check(unit.candidate_pose == 'idle' and 'windup' not in unit._sprite.texture.resource_path, id + ' cancelled action restores idle')
   unit.set_facing('N')
   check(not unit.set_cast_pose('anticipation'), id + ' unsupported cast does not fake a direction')
  if id == 'Enemy_1':
   for unsupported in ['N','E','W']:
    unit.set_facing('S')
    unit.set_cast_pose('release')
    unit.set_facing(unsupported)
    check(unit._sprite.texture == unit.unit_data.sprite_sheet, 'release to ' + unsupported + ' restores actual original art')
    var size: Vector2 = unit.unit_data.sprite_sheet.get_size()
    var scale_value := 95.0 / maxf(size.x,size.y)
    check(unit._sprite.position.is_equal_approx(Vector2(0,-size.y * scale_value * 0.5)), 'fallback foot position restored')
    check(unit.candidate_pose == 'idle', 'facing change clears stale cast state')
   unit.set_facing('S')
   unit.set_cast_pose('release')
   unit.set_view_quarter(1)
   check(unit._sprite.texture == unit.unit_data.sprite_sheet, 'rotated unsupported facing restores original art')
   unit.set_view_quarter(0)
  check([unit.grid_pos,unit.hp,unit.mp] == before, id + ' cast art does not commit combat')
 battle.queue_free()
 await get_tree().process_frame
 print('Candidate battle: %d checks, %d failures' % [checks,failures])
 get_tree().quit(0 if failures == 0 else 1)

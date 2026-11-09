extends Node
var battle: Node
func _ready() -> void:
 run.call_deferred()
func capture(label: String) -> void:
 await get_tree().create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image()
 var error := image.save_png('user://' + label + '.png')
 if error != OK:
  printerr('FAIL: capture ' + label)
  get_tree().quit(1)
func run() -> void:
 if DisplayServer.get_name() == 'headless':
  printerr('FAIL: CaptureTest needs a real graphical renderer')
  get_tree().quit(1)
  return
 battle = load('res://prototypes/blooming/BloomingBattle.tscn').instantiate()
 add_child(battle)
 await get_tree().create_timer(1.0).timeout
 var banner := Label.new()
 banner.text = 'CANDIDATE REVIEW | Posed engine capture\nMissing facings use old art. Not gameplay or art approval.'
 banner.position = Vector2(battle.battle_ui._bloom_active_panel.get_global_rect().end.x + 24,get_viewport().get_visible_rect().size.y - 56)
 banner.add_theme_font_size_override('font_size',16)
 banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
 battle.battle_ui.add_child(banner)
 await get_tree().process_frame
 var bounds := banner.get_global_rect()
 if not get_viewport().get_visible_rect().encloses(bounds) or bounds.intersects(battle.battle_ui._bloom_active_panel.get_global_rect()) or bounds.intersects(battle.battle_ui._bloom_objective_panel.get_global_rect()):
  printerr('FAIL: candidate disclaimer overlaps HUD or viewport')
  get_tree().quit(1)
  return
 for direction in ['N','E','S','W']:
  for unit in battle.battle_manager.units.values(): unit.set_facing(direction)
  await capture('candidate-idle-' + direction)
 var zane = battle.battle_manager.units['zane']
 var enemy = battle.battle_manager.units['Enemy_1']
 zane.set_facing('E')
 enemy.set_facing('S')
 for pose in ['anticipation','release']:
  zane.set_cast_pose(pose)
  enemy.set_cast_pose(pose)
  await capture('candidate-cast-' + pose)
 zane.reset_melee_pose()
 enemy.reset_melee_pose()
 battle.queue_free()
 await get_tree().process_frame
 for voice in get_node('/root/AudioSettings').get_children():
  if voice is AudioStreamPlayer:
   voice.stop()
   voice.stream = null
 await get_tree().create_timer(0.5).timeout
 print('Candidate graphical captures: 6 saved')
 get_tree().quit()

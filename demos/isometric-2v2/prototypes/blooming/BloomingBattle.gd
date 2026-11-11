extends BattleScene
## Local opt-in art integration; existing 2v2 rules and audio remain authoritative.
func _ready() -> void:
 if GameState.practice_session.is_empty():GameState.begin_illustrated_chapel_practice()
 GameState.practice_session["illustrated_chapel"]=true
 GameState.practice_session["painted_chapel"]=false
 GameState.practice_session["rig3d"]=false
 GameState.practice_session["terrain3d"]=false
 GameState.practice_session["isolated_isometric"]=true
 GameState.practice_session["blooming_ruins"]=true
 GameState.practice_session["rotatable_stage"]=false
 unit_scene=preload("res://prototypes/isometric/Unit.tscn")
 super._ready()
 if is_instance_valid(comparison_panel):comparison_panel.queue_free()
 battle_ui.rail_layout_changed.connect(_frame_battlefield_camera)
 _frame_battlefield_camera.call_deferred()

func _create_illustrated_chapel_map() -> MapData:
 return preload("res://prototypes/blooming/BloomingMap.gd").create_map()

func _spawn_player_units() -> Array[Unit]:
 var result: Array[Unit]=[]
 result.append(_make_unit("zane","Zane","player",Vector2i(3,8),320,90,4,2,8,42,48,80,110,_test_skills("zane",["haste"])))
 result.append(_make_unit("kael","Kael","player",Vector2i(2,9),380,55,4,2,6,55,32,110,70,_test_skills("kael",["delay_strike","heavy_slash","cover_ally","iron_wall"])))
 for unit in result:unit.set_facing("N")
 return result

## A battle-local projection: never teach, equip or save test skills.
func _test_skills(id: String, extras: Array) -> Array[String]:
 var result := GameState.get_all_abilities(id)
 for ability in extras:
  if ability not in result:result.append(ability)
 return result

func _spawn_enemy_units() -> Array[Unit]:
 var result: Array[Unit]=[]
 result.append(_make_storm_imp(Vector2i(6,7)))
 result.append(_make_unit("void_cultist","Void Cultist","enemy",Vector2i(8,2),80,80,3,1,7,20,55,40,100,["void_pulse","dark_breath","shadow_mend"],{"holy":2.0,"dark":0.0,"fire":0.75,"blizzard":1.25}))
 for unit in result:unit.set_facing("S")
 return result

func _frame_battlefield_camera() -> void:
 if not is_instance_valid(_battle_camera) or not is_instance_valid(tactical_grid):return
 var screen:=get_viewport_rect().size
 var area: Rect2=battle_ui.gameplay_rect(screen)
 area=Rect2(area.position+Vector2(24,92),area.size-Vector2(48,230))
 var bounds:=tactical_grid.get_board_bounds()
 _camera_zoom_value=minf(area.size.x/bounds.size.x,area.size.y/bounds.size.y)
 _camera_zoom_value=maxf(0.1,_camera_zoom_value)
 _camera_base_position=bounds.get_center()+(screen*.5-area.get_center())/_camera_zoom_value
 _camera_bounds=bounds
 _battle_camera.zoom=Vector2.ONE*_camera_zoom_value
 _battle_camera.position=_camera_base_position

func _process(delta: float) -> void:
 _update_camera_shake(delta)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q,KEY_E]:
  request_stage_rotation(0)
  get_viewport().set_input_as_handled()

func request_stage_rotation(_step: int) -> bool:
 if is_instance_valid(battle_ui._bloom_hint):battle_ui._bloom_hint.text="Fixed courtyard view · directional units remain active"
 return false

func set_compact_skins(enabled: bool) -> bool:
 if battle_manager.is_resolving_action:return false
 GameState.practice_session["compact_skins"]=enabled
 for unit in battle_manager.units.values():
  if is_instance_valid(unit):unit._refresh_directional_sprite()
 battle_ui._portrait_cache.clear()
 var active=battle_manager.units.get(battle_manager.active_unit_id)
 if is_instance_valid(active):battle_ui._active_portrait.texture=battle_ui._framed_portrait(active.unit_data.id)
 battle_ui._refresh_turn_portraits()
 battle_ui.refresh_skin_portraits()
 return true

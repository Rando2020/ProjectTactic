extends Node
## Real menu/review/confirm flow; final direct VFX calls are explicit lifecycle probes.
var checks := 0
var failures: Array[String] = []
var capture_dir := ""
var battle: BattleScene
var records: Array[Dictionary] = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  printerr("FAIL: ", message)
func _ready() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):
   capture_dir = arg.trim_prefix("--capture-dir=")
   DirAccess.make_dir_recursive_absolute(capture_dir)
 run.call_deferred()
func capture(label: String) -> void:
 if capture_dir.is_empty(): return
 if DisplayServer.get_name() == "headless":
  check(false,"capture requires actual renderer")
  return
 await RenderingServer.frame_post_draw
 check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))==OK,"actual engine capture "+label)
 var manager := battle.battle_manager
 records.append({"label":label,"zane_mp":manager.units.zane.mp,"kael_hp":manager.units.kael.hp,"haste":manager.units.kael.has_status("haste"),"speed":manager.units.kael.get_effective_speed(),"queue":manager.turn_order.get_projected_order()})
func boot() -> void:
 battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
 get_tree().root.add_child(battle)
 for i in 600:
  if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN: return
  await get_tree().process_frame
 check(false,"normal player turn reached")
func release_battle() -> void:
 battle.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
func skill_button(ui, name_text: String) -> Button:
 for node in ui._ability_list.get_children():
  if not node is Button or node.is_queued_for_deletion(): continue
  for label in node.find_children("*","Label",true,false):
   if label.text == name_text:return node
 return null
func run() -> void:
 GameState.unit_registry.zane.jp = 37
 GameState.unit_registry.zane.learned_abilities.append("blizzard")
 GameState.save()
 var original_registry := GameState.unit_registry.duplicate(true)
 var save_before := FileAccess.get_file_as_bytes(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else PackedByteArray()
 await boot()
 var manager := battle.battle_manager
 var ui = battle.battle_ui
 var selection = ui._selection
 var zane: Unit = manager.units.zane
 var kael: Unit = manager.units.kael
 check(manager.units.size()==4,"2v2 roster unchanged")
 check("haste" in zane.unit_data.abilities,"candidate Zane has selectable Haste")
 for id in ["fire","thunderstrike","void_pulse"]:check(id in zane.unit_data.abilities,"preserves existing Zane "+id)
 for id in ["mighty_strike","defend"]:check(id in kael.unit_data.abilities,"preserves existing Kael "+id)
 check(AbilityDB.get_ability("delay_strike").is_empty(),"does not invent Delay Strike")
 var mp_before := zane.mp
 var hp_before := kael.hp
 var speed_before := kael.get_effective_speed()
 var queue_before := manager.turn_order.get_projected_order()
 var ct_before := manager.turn_order.units.map(func(u):return u.ct)
 selection.select_unit("zane")
 ui._ability_btn.pressed.emit()
 await get_tree().process_frame
 var button := skill_button(ui,"Haste")
 check(button!=null and not button.disabled,"real Skills menu exposes usable Haste")
 await capture("01-skills")
 if not button:finish();return
 button.pressed.emit()
 check(kael.grid_pos in battle.tactical_grid.ability_tiles,"Kael is a legal ally recipient")
 check(zane.grid_pos not in battle.tactical_grid.ability_tiles,"preserves existing minimum-range-one ally targeting")
 selection.set_cursor(manager.units.Enemy_1.grid_pos)
 selection.activate_cursor()
 check(not selection.has_review(),"hostile out-of-range target cannot stage Haste review")
 selection.set_cursor(Vector2i(3,7))
 selection.activate_cursor()
 check(not selection.has_review(),"empty tile cannot stage single-ally Haste review")
 selection.set_cursor(kael.grid_pos)
 selection.activate_cursor()
 check(selection.has_review() and ui._confirm_btn.visible,"ally target requires explicit review")
 check(zane.mp==mp_before and not kael.has_status("haste"),"review does not spend MP or apply status")
 check(not kael.has_node("HastePaintedAura"),"review does not play applied aura")
 await capture("02-target-review")
 selection.go_back()
 check(not selection.has_review() and manager.active_command=="ability_target","cancel returns to targeting")
 check(zane.mp==mp_before and not kael.has_status("haste"),"cancel preserves resources/status")
 selection.activate_cursor()
 ui._confirm_btn.pressed.emit()
 ui._confirm_btn.pressed.emit()
 var aura: Node2D
 for i in 600:
  aura = kael.get_node_or_null("HastePaintedAura")
  if aura:break
  await get_tree().process_frame
 check(aura!=null,"actual committed Haste creates painted recipient aura")
 if aura:
  check(aura.get_parent()==kael,"aura follows actual target and dies with battle")
  check(aura.z_index+aura.get_node("Rear").z_index<kael.visual.z_index and aura.z_index+aura.get_node("Front").z_index>kael.visual.z_index,"front/back effective depth straddles actual actor visual")
  check(aura.get_node("Rear").texture==aura.get_node("Front").texture,"both layers use same original texture")
  check(aura.get_node("Rear").region_rect.end.y==aura.get_node("Front").region_rect.position.y,"draw regions share exact seam")
  check(aura.position==Vector2.ZERO,"effect origin is target foot anchor")
  await get_tree().create_timer(0.2).timeout
  await capture("03-application-aura")
 for i in 600:
  if not manager.is_resolving_action:break
  await get_tree().process_frame
 check(zane.mp==mp_before-10,"duplicate confirm spends exactly 10 MP once")
 check(kael.hp==hp_before,"Haste does not invent damage or healing")
 check(kael.has_status("haste"),"authoritative existing Haste status applied")
 check(kael.statuses.filter(func(s):return s.status_id=="haste").size()==1,"duplicate confirm applies status once")
 check(kael.get_effective_speed()==int(speed_before*1.5),"existing 1.5x speed preserved")
 check(manager.turn_order.get_projected_order()!=queue_before,"actual upcoming turn order responds to Haste")
 check(manager.turn_order.units.map(func(u):return u.ct)==ct_before,"visual and projection do not advance actual CT")
 check(manager.active_unit_has_acted,"confirmed cast consumes action")
 check(not manager.active_unit_has_moved,"cast leaves independent movement available")
 await get_tree().create_timer(1.2).timeout
 check(not kael.has_node("HastePaintedAura"),"application aura ends without becoming persistent status loop")
 check(kael.has_status("haste"),"visual retirement does not remove gameplay buff")
 await capture("04-recovered")
 # Explicit scheduler/status lifecycle probes, not forced full combat turns.
 for i in 3:kael.tick_statuses()
 check(not kael.has_status("haste") and kael.get_effective_speed()==speed_before,"existing Haste expires after three target status ticks")
 check(manager.turn_order.get_projected_order()==queue_before,"expiry restores projected order without advancing CT")
 # Explicit effect-lifecycle probes, separate from the real cast above.
 GameState.practice_session["reduced_zane_motion"]=true
 get_node("/root/VFX").play_haste(kael.grid_pos)
 aura=kael.get_node("HastePaintedAura")
 var rest_scale := aura.scale
 await get_tree().create_timer(0.25).timeout
 check(aura.scale==rest_scale,"reduced motion uses fixed scale")
 get_node("/root/VFX").play_haste(kael.grid_pos)
 await get_tree().process_frame
 check(kael.get_children().filter(func(n):return n.name=="HastePaintedAura").size()==1,"reapplication replaces only prior target aura")
 aura=kael.get_node("HastePaintedAura")
 var old_global: Vector2=aura.global_position
 kael.position+=Vector2(5,2)
 check(aura.global_position==old_global+Vector2(5,2),"actor-owned aura follows visual movement")
 kael.receive_damage(99999,"pure")
 await get_tree().process_frame
 await get_tree().process_frame
 check(not is_instance_valid(aura),"defeated recipient retires application effect")
 get_node("/root/VFX").play_haste(zane.grid_pos)
 aura=zane.get_node("HastePaintedAura")
 await release_battle()
 check(not is_instance_valid(aura),"battle teardown frees effect")
 GameState.practice_session["reduced_zane_motion"]=false
 await boot()
 check("haste" in battle.battle_manager.units.zane.unit_data.abilities,"fresh battle retains candidate skill")
 check(battle.battle_manager.units.zane.mp==90 and not battle.battle_manager.units.kael.has_status("haste"),"fresh battle restores resources and statuses")
 check(not battle.battle_manager.units.kael.has_node("HastePaintedAura"),"fresh battle has no stale aura")
 await release_battle()
 check(GameState.unit_registry==original_registry,"candidate never changes saved skill ownership")
 var save_after := FileAccess.get_file_as_bytes(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else PackedByteArray()
 check(save_before==save_after,"save bytes unchanged")
 finish()
func finish() -> void:
 if not capture_dir.is_empty():
  var file := FileAccess.open(capture_dir.path_join("evidence.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":records,"normal_time_scale":Engine.time_scale},"  "))
 print("Haste candidate: %d checks, %d failures" % [checks,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)

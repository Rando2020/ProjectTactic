extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(ok,label):
 print("GUI ",label,": ",ok)
 if not ok: failures+=1
func key(k,pressed=true):
 var e=InputEventKey.new();e.keycode=k;e.pressed=pressed;Input.parse_input_event(e)
func click(pos):
 var e=InputEventMouseButton.new();e.position=pos;e.global_position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e)
 e=InputEventMouseButton.new();e.position=pos;e.global_position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;Input.parse_input_event(e)
func run():
 root.size=Vector2i(1920,1080)
 var battle=load("res://prototypes/isometric/Skirmish.tscn").instantiate();root.add_child(battle)
 for i in 10: await process_frame
 var ui=battle.battle_ui;var m=battle.battle_manager;var s=ui._selection
 key(KEY_ENTER);await process_frame;key(KEY_ENTER,false)
 await process_frame
 check(s.selected_id=="zane","Enter selects active")
 check(root.gui_get_focus_owner()==ui._move_btn,"Move focused")
 key(KEY_DOWN);await process_frame;key(KEY_DOWN,false)
 check(root.gui_get_focus_owner()==ui._attack_btn,"Down navigates command GUI")
 check(s.cursor_cell==m.units.zane.grid_pos,"Menu Down does not move cursor")
 key(KEY_ENTER);await process_frame
 key(KEY_ENTER,false)
 await process_frame
 check(m.active_command=="attack","Enter activates focused Attack")
 check(root.gui_get_focus_owner()==null,"targeting releases GUI focus")
 key(KEY_ESCAPE);key(KEY_ESCAPE,false)
 await process_frame
 check(m.active_command.is_empty() and s.selected_id=="zane","Escape returns menu")
 ui._on_move()
 for i in 3: await process_frame
 click(ui._cancel_btn.get_global_rect().get_center())
 await process_frame
 check(m.active_command.is_empty() and not m.active_unit_has_moved,"GUI Back click no movement leakage")
 check(s.selected_id=="zane","GUI Back click retains selection")
 click(ui._chapel_command_panel.get_global_rect().position+Vector2(10,10))
 await process_frame
 check(s.selected_id=="zane" and m.active_command.is_empty(),"Panel background consumes click")
 ui._on_ability()
 for i in 3: await process_frame
 check(root.gui_get_focus_owner()!=null and root.gui_get_focus_owner().get_parent()==ui._ability_list,"Ability GUI focus")
 key(KEY_ESCAPE);key(KEY_ESCAPE,false)
 await process_frame
 check(m.active_command.is_empty() and not ui._ability_panel.visible,"Ability Escape back")
 print("GUI touch mouse emulation=",ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"))
 battle.queue_free()
 await create_timer(1).timeout
 print("GUI failures=",failures)
 quit(failures)

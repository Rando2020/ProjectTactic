## Headless smoke tests for ElementalSystem.
## Run: godot --headless --path . -s res://tests/test_element_resolver.gd
extends SceneTree
var _pass:=0; var _fail:=0
func _init()->void:
	_run_tests()
	print("Tests: %d pass, %d fail" % [_pass,_fail])
	quit(1 if _fail>0 else 0)
func _run_tests()->void:
	var es:=ElementalSystem.new()
	_eq(es.apply_element(Vector2i(0,0),"void",[]),"","no reaction unknown element")
	_eq(es.get_surface_state(Vector2i(0,0)),"","state unchanged")
	_eq(es.apply_element(Vector2i(1,0),"water",[]),"apply_wet","water→apply_wet")
	_eq(es.get_surface_state(Vector2i(1,0)),"wet","state=wet")
	es.surface_states[Vector2i(2,0)]="wet"
	_eq(es.apply_element(Vector2i(2,0),"ice",[]),"freeze_tile","ice on wet→freeze")
	es.surface_states[Vector2i(3,0)]="ice"
	_eq(es.apply_element(Vector2i(3,0),"thunder",[]),"shatter_tile","thunder on ice→shatter")
	_eq(es.get_surface_state(Vector2i(3,0)),"","shatter clears state")
	es.surface_states[Vector2i(5,5)]="wet"
	_eq(es.apply_element(Vector2i(5,5),"thunder",[],{},Vector2i(10,10)),"electrify_chain","thunder on wet→chain")
	_eq(es.get_surface_state(Vector2i(5,5)),"electrified_water","origin=electrified")
	_eq(es.get_reaction_label("shatter_tile"),"💥 Shatter!","label correct")
	var fx:=es.get_unit_effects("electrify_chain")
	_true(fx.has("damage"),"chain has damage"); _true(fx.has("status"),"chain has status")
	_eq(fx["status"],"stun","chain status=stun")
	es.free()
func _eq(got,exp,label)->void:
	if got==exp:print("PASS %s"%label);_pass+=1
	else:print("FAIL %s (got=%s exp=%s)"% [label,str(got),str(exp)]);_fail+=1
func _true(v,label)->void:
	if v:print("PASS %s"%label);_pass+=1
	else:print("FAIL %s"%label);_fail+=1

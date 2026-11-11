extends BattleManager
## Courtyard-only test equipment. Campaign equipment and learned skill ownership are untouched.
const Patterns = preload("res://prototypes/blooming/weapons/WeaponPatterns.gd")
var _test_weapons: Dictionary = {}
func test_weapon_options(unit_id: String) -> Array:
	return Patterns.LOADOUTS.get(unit_id,[]).duplicate()
func test_weapon_id(unit_id: String) -> String:
	return str(_test_weapons.get(unit_id,"sword")) if Patterns.LOADOUTS.has(unit_id) else ""
func equip_test_weapon(unit_id: String, weapon: String) -> bool:
	var actor := _living_unit(unit_id)
	if current_phase!=Phase.PLAYER_TURN or is_resolving_action or active_unit_has_acted or active_unit_id!=unit_id or not actor or weapon not in test_weapon_options(unit_id):return false
	cancel_pending_action() # Invalidates any reviewed target before equipment changes.
	_test_weapons[unit_id]=weapon
	command_hint_changed.emit("TEST: %s. Enemies only; free swaps before acting." % Patterns.LABELS[weapon])
	_emit_action_state()
	return true
func _weapon_targets(actor: Unit, aim: Vector2i) -> Array[Unit]:
	var result: Array[Unit] = []
	for cell: Vector2i in Patterns.footprint(test_weapon_id(actor.unit_id),actor.grid_pos,aim,tactical_grid.tiles):
		var unit := _unit_at_pos(cell)
		if is_instance_valid(unit) and unit.hp>0 and unit.team!=actor.team:result.append(unit)
	return result
func select_command(command: String) -> void:
	super.select_command(command)
	if command!="attack" or active_command!="attack" or is_resolving_action or active_unit_has_acted:return
	var actor := _living_unit(active_unit_id)
	if not actor or test_weapon_id(actor.unit_id).is_empty():return
	var cells := Patterns.aim_cells(test_weapon_id(actor.unit_id),actor.grid_pos,tactical_grid.tiles)
	tactical_grid.show_attack_range(cells)
	attack_range_ready.emit(cells)
	command_hint_changed.emit("%s: aim along a grid edge. Red area hits enemies only." % Patterns.LABELS[test_weapon_id(actor.unit_id)])
func _attack_preview_for_tile(aim: Vector2i) -> Dictionary:
	var actor := _living_unit(active_unit_id)
	if not actor or test_weapon_id(actor.unit_id).is_empty():return super._attack_preview_for_tile(aim)
	if actor.has_status("iron_wall") or aim not in tactical_grid.attack_tiles:return {}
	var recipients := _weapon_targets(actor,aim)
	if recipients.is_empty():return {}
	var primary := _unit_at_pos(aim)
	if primary not in recipients:primary=recipients[0]
	var mods := {"allow_cover":test_weapon_id(actor.unit_id)=="sword"}
	var forecast := ForecastCalculator.attack(actor,primary,tactical_grid.get_tile(actor.grid_pos),tactical_grid.get_tile(primary.grid_pos),mods)
	var primary_recipient: Unit = units.get(str(forecast.get("recipient_id",primary.unit_id)),primary)
	forecast["actor_portrait"]=_portrait_path(actor)
	forecast["target_portrait"]=_portrait_path(primary_recipient)
	forecast=_with_target_context(_with_position_context(forecast,actor,primary),actor,primary)
	forecast["ability_name"]=Patterns.LABELS[test_weapon_id(actor.unit_id)]
	forecast["jp_gain"]=0
	forecast["weapon_area"]=Patterns.footprint(test_weapon_id(actor.unit_id),actor.grid_pos,aim,tactical_grid.tiles)
	var protection_note := str(forecast.get("note",""))
	forecast["note"]=(protection_note+". " if not protection_note.is_empty() else "")+"TEST weapon · enemies only · %d target(s) · aim %d,%d. Existing damage per target; not balanced." % [recipients.size(),aim.x,aim.y]
	var affected: Array[Dictionary]=[]
	var counter_names: Array[String]=[]
	for target: Unit in recipients:
		var one := ForecastCalculator.attack(actor,target,tactical_grid.get_tile(actor.grid_pos),tactical_grid.get_tile(target.grid_pos),mods)
		var recipient: Unit = units.get(str(one.get("recipient_id",target.unit_id)),target)
		if bool(one.get("can_counter",false)):counter_names.append(recipient.display_name)
		affected.append({"unit_id":recipient.unit_id,"target_name":recipient.display_name,"hp_before":one.hp_before,"hp_after":one.hp_after,"max_hp":one.max_hp,"damage":one.damage,"hit_pct":one.hit_pct,"status_preview":one.get("status_preview",""),"can_counter":one.get("can_counter",false),"role":"primary" if target==primary else "weapon area"})
	forecast["can_counter"]=not counter_names.is_empty()
	if not counter_names.is_empty():forecast["note"]+=" Counter possible: "+", ".join(counter_names)+"."
	forecast["weapon_summary"]="Targets: "+", ".join(affected.map(func(row):return row.target_name))+"\nEnemies only"
	if not counter_names.is_empty():forecast["weapon_summary"]+=" · Counter possible: "+", ".join(counter_names)
	forecast["affected_targets"]=affected
	return forecast
func _on_tile_hovered(aim: Vector2i) -> void:
	super._on_tile_hovered(aim)
	if active_command!="attack":return
	var actor := _living_unit(active_unit_id)
	if not actor or test_weapon_id(actor.unit_id).is_empty():return
	var cells: Array[Vector2i]=[]
	if aim in tactical_grid.attack_tiles:cells=Patterns.footprint(test_weapon_id(actor.unit_id),actor.grid_pos,aim,tactical_grid.tiles)
	tactical_grid.show_aoe_preview(cells)
func _on_tile_clicked(aim: Vector2i) -> void:
	if active_command=="attack" and not test_weapon_id(active_unit_id).is_empty():
		await _commit_weapon_attack(aim)
	else:await super._on_tile_clicked(aim)
func _on_unit_clicked(unit_id: String) -> void:
	if active_command=="attack" and not test_weapon_id(active_unit_id).is_empty():
		var target := _living_unit(unit_id)
		if target:await _commit_weapon_attack(target.grid_pos)
	else:await super._on_unit_clicked(unit_id)
func _commit_weapon_attack(aim: Vector2i) -> void:
	if current_phase!=Phase.PLAYER_TURN or is_resolving_action or active_unit_has_acted:return
	var actor := _living_unit(active_unit_id)
	if not actor or _attack_preview_for_tile(aim).is_empty():return
	var recipients := _weapon_targets(actor,aim)
	var weapon := test_weapon_id(actor.unit_id)
	_face_toward(actor,aim)
	last_ability_used=Patterns.LABELS[weapon]
	if not await _present_action(actor,aim,"slash",recipients[0]):return
	# Geometry is authoritative again at contact; no stale or defeated recipient.
	var records: Array[Dictionary]=[]
	var counters: Array[Unit]=[]
	for target: Unit in _weapon_targets(actor,aim):
		var result := combat_resolver.resolve_attack(actor,target,tactical_grid.get_tile(actor.grid_pos),tactical_grid.get_tile(target.grid_pos),"slash",false,{"allow_cover":weapon=="sword"},_presentation_feedback_owner())
		records.append(_presentation_record(target,result))
		var recipient := CombatFormula.outcome_recipient(target,result)
		if not is_instance_valid(recipient):continue
		log_message.emit("%s · %s → %s: %s" % [actor.display_name,weapon.capitalize(),recipient.display_name,"miss" if result.get("missed",false) else "%d damage" % result.get("hp_damage",0)])
		if result.get("counter",false):counters.append(recipient)
	_present_action_outcomes(records)
	for target: Unit in counters:
		if is_instance_valid(actor) and actor.hp>0 and is_instance_valid(target) and target.hp>0:_execute_counter_attack(target,actor)
	tactical_grid.clear_highlights()
	active_command=""
	active_unit_has_acted=true
	if actor.hp<=0:
		await _recover_action()
		_end_player_turn()
	else:await _finish_player_action()
func _auto_try_attack(actor: Unit) -> bool:
	if not actor or test_weapon_id(actor.unit_id).is_empty():return await super._auto_try_attack(actor)
	if active_unit_has_acted or actor.has_status("iron_wall"):return false
	select_command("attack")
	await _timer(0.08).timeout
	if current_phase!=Phase.PLAYER_TURN or active_unit_id!=actor.unit_id:return true
	var best_aim:=Vector2i(-1,-1)
	var best_score:=-1.0
	for aim: Vector2i in Patterns.aim_cells(test_weapon_id(actor.unit_id),actor.grid_pos,tactical_grid.tiles):
		var recipients:=_weapon_targets(actor,aim)
		if recipients.is_empty():continue
		var score:=0.0
		for target: Unit in recipients:
			var formula:=CombatFormula.calculate_physical_attack(actor,target,tactical_grid.get_tile(actor.grid_pos),tactical_grid.get_tile(target.grid_pos),{"allow_cover":test_weapon_id(actor.unit_id)=="sword"})
			var recipient:=CombatFormula.outcome_recipient(target,formula)
			var damage:=int(formula.get("hp_damage",0))
			score+=float(damage)+(1000.0 if is_instance_valid(recipient) and damage>=recipient.hp else 0.0)
		if score>best_score:best_score=score;best_aim=aim
	if best_aim==Vector2i(-1,-1):
		cancel_pending_action()
		return false
	_on_tile_hovered(best_aim)
	await _timer(0.10).timeout
	await _commit_weapon_attack(best_aim)
	return true

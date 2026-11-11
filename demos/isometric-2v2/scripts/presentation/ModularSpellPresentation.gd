## Per-ticket modular spell cosmetics. Only the manager applies costs/outcomes.
extends "res://scripts/presentation/ZaneActionPresentation.gd"
const Frames := preload("res://scripts/presentation/ModularSpellFrames.gd")
const SupportGlyph := preload("res://scripts/presentation/SupportSpellGlyph.gd")
const SpellAudio := preload("res://scripts/presentation/CourtyardSkillAudio.gd")
const CAST_SECONDS := 0.64
const FORM_SECONDS := 0.18
const ACTION_SECONDS := 0.20
const COLLISION_SECONDS := 0.24
const DECAY_SECONDS := 0.32
var _stage_sprite: Sprite2D
var _stage_ground := Vector2i.ZERO
var _tails: Array[Dictionary] = []
var _elapsed_tail := 0.0
var _support := false
var _active_phase := ""
var _projectile_spell := false
var _travel_progress := 0.0

func present(actor: Unit, action_context: Dictionary, permitted: Callable) -> void:
	context = action_context.duplicate(true)
	_actor = weakref(actor)
	_permitted = permitted
	var manager = instance_from_id(int(str(context.action_key).get_slice(":",0)))
	if not is_instance_valid(manager):
		cancel()
		return
	_manager = weakref(manager)
	var scene = manager.get_parent()
	if is_instance_valid(scene) and scene.has_method("apply_zane_impact_kick"): _scene = weakref(scene)
	_presenting = true
	_support = str(context.ability_id) in ["shadow_mend","defend","haste"]
	_projectile_spell = str(context.ability_id) in ["void_pulse","dark_breath"]
	actor.face_action(context.destination)
	actor.set_cast_pose("anticipation")
	_stage_ground = actor.grid_pos
	_set_spell_stage("casting")
	_sound("charge")
	if not await _wait_spell(CAST_SECONDS):
		_presenting = false
		cancel()
		return
	actor.set_cast_pose("release")
	_stage_ground = actor.grid_pos if _projectile_spell or _support else context.destination
	_set_spell_stage("formation")
	if not await _wait_spell(FORM_SECONDS):
		_presenting = false
		cancel()
		return
	_set_spell_stage("action")
	# The lightning source is a grounded pillar, not a flying projectile. A short
	# caster-to-target tracer establishes cause without translating its ground ring.
	if not _support and not _projectile_spell:
		var origin := _grid_point(actor.grid_pos)+Vector2(0,-28)
		var end := _grid_point(context.destination)+Vector2(0,-40.8)
		var link := _line(PackedVector2Array([origin,origin.lerp(end,0.45)+Vector2(0,-8),end]),_color(),2,"spell_link")
		_fade(link,ACTION_SECONDS)
	_sound("release")
	if not await _wait_spell(ACTION_SECONDS):
		_presenting = false
		cancel()
		return
	_remove_fx(_stage_sprite)
	_stage_sprite = null
	_presenting = false
	_lead_in_complete = true

func _color() -> Color:
	match str(context.ability_id):
		"thunderstrike": return Color(0.48,0.75,1.0,0.85)
		"shadow_mend": return Color(0.64,1.0,0.81,0.85)
		"haste": return Color(1.0,0.91,0.48,0.95)
		"defend": return Color(1.0,0.82,0.40,0.85)
		_: return Color(0.76,0.44,1.0,0.85)

func _set_spell_stage(phase: String) -> void:
	_remove_fx(_stage_sprite)
	_stage_sprite = _make_spell_effect(phase)
	_own(_stage_sprite,"spell_sheet_"+phase)
	_stage_sprite.position = _grid_point(_stage_ground)
	_active_phase = phase
	_travel_progress = 0.0
	_position_spell_stage()
	_phase(phase)
	if _cancelled or not _current_ticket(): return
	if not _stage_sprite.available():
		# Defensive fallback only; support glyphs always have drawable geometry.
		var ring := _ring(_grid_point(_stage_ground),21.0 if _support else 15.0)
		_fade(ring,0.28)

func _make_spell_effect(phase: String) -> Sprite2D:
	var effect: Sprite2D
	if str(context.ability_id) in ["haste", "defend"]:
		effect = SupportGlyph.new()
		effect.set_reduced_motion(bool(context.get("reduced_motion", false)))
	else:
		effect = Frames.new()
	effect.configure(str(context.ability_id), phase)
	return effect

func _support_result_text(result: Dictionary) -> String:
	if bool(result.get("missed", false)): return "MISS"
	if float(result.get("affinity", 1.0)) == 0.0: return "IMMUNE"
	match str(context.ability_id):
		"shadow_mend": return "+%d HP" % int(result.get("healed", 0))
		"defend": return "GUARD\nUntil next turn"
		"haste":
			var status: Variant = result.get("status_applied", {})
			if status is Dictionary and str(status.get("id", "")) == "haste":
				var duration := int(status.get("duration", 0))
				return "HASTE\n%d %s" % [duration, "turn" if duration == 1 else "turns"] if duration > 0 else "HASTE"
			if status is String and status == "haste": return "HASTE"
			return "NO STATUS"
	return ""

func _ring(p: Vector2, radius: float) -> Line2D:
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU*float(i)/24.0
		points.append(p+Vector2(cos(angle)*radius,sin(angle)*radius*0.48))
	return _line(points,_color(),2,"support_ring" if _support else "spell_ring")

func _wait_spell(seconds: float) -> bool:
	var tree := get_tree()
	var clock := PhaseClock.new()
	_wait_clock = clock
	tree.process_frame.connect(clock.advance)
	var elapsed := 0.0
	while elapsed < seconds:
		if not _valid_presentation(): break
		await clock.tick
		if not _valid_presentation(): break
		elapsed += minf(maxf(get_process_delta_time(),0.0),seconds/8.0)
		if is_instance_valid(_stage_sprite):
			_stage_sprite.show_progress(elapsed/seconds)
			_travel_progress = clampf(elapsed/seconds,0,1)
			_position_spell_stage()
	if tree.process_frame.is_connected(clock.advance): tree.process_frame.disconnect(clock.advance)
	if _wait_clock == clock: _wait_clock = null
	return elapsed >= seconds and _valid_presentation()

func _position_spell_stage() -> void:
	if not is_instance_valid(_stage_sprite): return
	if _projectile_spell and _active_phase == "action":
		var actor = _actor.get_ref()
		var contact_frame: Dictionary = Frames.Catalog.DATA[str(context.ability_id)]["collision"][0]
		var contact_offset := Vector2(0,-120.0*float(contact_frame.scale))
		var origin := _grid_point(actor.grid_pos)+contact_offset
		var destination := _grid_point(context.destination)+contact_offset
		_stage_sprite.position = origin.lerp(destination,_travel_progress)
		_stage_sprite.rotation = (destination-origin).angle()+PI/4.0
	else:
		_stage_sprite.position = _grid_point(_stage_ground)
		_stage_sprite.rotation = 0.0

func _process(delta: float) -> void:
	if _cancelled: return
	if not _living_actor() or (not _finished and not _current_ticket()):
		cancel()
		return
	if is_instance_valid(_stage_sprite): _position_spell_stage()
	if not _outcomes_presented: return
	_elapsed_tail += minf(maxf(delta,0.0),0.03)
	var decay := _elapsed_tail >= COLLISION_SECONDS
	for item: Dictionary in _tails:
		var sprite = item.sprite
		if not is_instance_valid(sprite): continue
		sprite.position = _grid_point(item.tile)
		if bool(item.get("hit",true)):
			if decay and sprite.stage != "dissipation": sprite.configure(str(context.ability_id),"dissipation")
			sprite.show_progress((_elapsed_tail-COLLISION_SECONDS)/DECAY_SECONDS if decay else _elapsed_tail/COLLISION_SECONDS)
		else:
			sprite.show_progress(_elapsed_tail/(COLLISION_SECONDS+DECAY_SECONDS))
	if _elapsed_tail >= COLLISION_SECONDS+DECAY_SECONDS and _finished: queue_free()

func present_outcomes(records: Array[Dictionary]) -> void:
	if _cancelled or _finished or _outcomes_presented or not _current_ticket(): return
	_outcomes_presented = true
	_elapsed_tail = 0.0
	var numbers: Array[Label] = []
	var anchors: Array[Vector2] = []
	var any_hit := false
	for record: Dictionary in records:
		var result: Dictionary = record.outcome
		var hp := int(result.get("applied_hp_damage",0))
		var missed := bool(result.get("missed",false))
		var immune := not missed and float(result.get("affinity",1.0)) == 0.0
		var text := _support_result_text(result) if _support else ("MISS" if missed else ("IMMUNE" if immune else ("-%d HP" % hp if hp>0 else "0 HP")))
		for field in [["temper_damage","Temper"],["ether_damage","Ether"]]:
			var loss := int(result.get(field[0],0))
			if loss > 0: text += "\n-%d %s" % [loss,field[1]]
		var status: Variant = result.get("status_applied",{})
		if status is Dictionary and not status.is_empty() and str(context.ability_id) not in ["defend","haste"]:
			text += "\n%s · %s turns" % [str(status.get("display_name",status.get("id",""))).capitalize(),str(status.get("duration",""))]
		elif status is String and not status.is_empty() and str(context.ability_id) not in ["defend","haste"]: text += "\n"+status.capitalize()
		if not missed and not immune and not _support:
			if bool(result.get("critical",false)): text += "\nCRIT"
			var affinity := float(result.get("affinity",1.0))
			if affinity > 1.0: text += " [WEAK]"
			elif affinity < 1.0: text += " [RESIST]"
		numbers.append(_number(text,_color()))
		anchors.append(_outcome_anchor(record))
		var sprite := _make_spell_effect("dissipation" if missed or immune else "collision")
		_own(sprite,"spell_tail")
		_tails.append({"sprite":sprite,"tile":record.grid_pos,"hit":not missed and not immune})
		sprite.position = _grid_point(record.grid_pos)
		if not sprite.available():
			var ring := _ring(sprite.position,25.0)
			_fade(ring,0.42)
		var damaging := not _support and not missed and not immune and (hp>0 or int(result.get("temper_damage",0))+int(result.get("ether_damage",0))>0)
		if damaging:
			any_hit = true
			var target = record.target_ref.get_ref() if record.target_ref != null else null
			if is_instance_valid(target) and target.hp>0 and not target.is_queued_for_deletion(): _react(target)
		if str(context.ability_id)=="thunderstrike" and record.grid_pos != context.destination:
			var arc := _line(PackedVector2Array([_grid_point(context.destination)+Vector2(0,-28),_grid_point(record.grid_pos)+Vector2(0,-28)]),_color(),3,"chain_contact")
			_fade(arc,0.22)
	_place_numbers(numbers,anchors)
	_phase("support" if _support else "impact")
	if _cancelled or not _current_ticket(): return
	_sound("heal" if _support else ("contact" if any_hit else "release"))
	if any_hit and not bool(context.reduced_motion) and not _cancelled and _current_ticket():
		var scene = _scene.get_ref() if _scene != null else null
		if is_instance_valid(scene): scene.apply_zane_impact_kick(Vector2.DOWN,2.0,0.09)
		var juice := get_node_or_null("/root/BattleJuiceEffects")
		if juice != null: juice.trigger_pause(45)

func _number(text: String, color: Color) -> Label:
	var label := super._number(text,color)
	label.add_theme_font_size_override("font_size",28)
	return label

func _sound(kind: String) -> void:
	# A phase observer may invalidate this ticket synchronously before a cue.
	if _cancelled or not _current_ticket(): return
	var voice := SpellAudio.play(str(context.ability_id),kind,self)
	if not is_instance_valid(voice): return
	_voices.append(voice)
	cue_started.emit(str(context.ability_id)+"_"+kind)

func finish() -> void:
	if _cancelled or _finished: return
	_finished = true
	_remove_fx(_stage_sprite)
	if not _outcomes_presented: queue_free()

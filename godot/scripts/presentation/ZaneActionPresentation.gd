## Disposable cosmetics for ONE admitted ticket. Combat/lifecycle remain authoritative.
extends Node2D

signal cue_started(cue_id: String)
signal phase_presented(phase: String)

const FireballSprite := preload("res://scripts/vfx/FireballSprite.gd")
const Audio := preload("res://scripts/presentation/ZaneImpactAudio.gd")
const OutcomeLayout := preload("res://scripts/presentation/ZaneOutcomeLayout.gd")
const REACTION_META := &"zane_impact_reaction"

class PhaseClock:
	extends RefCounted
	signal tick
	func advance() -> void:
		tick.emit()

var _wait_clock: PhaseClock
var context: Dictionary = {}
var _actor: WeakRef
var _manager: WeakRef
var _scene: WeakRef
var _permitted: Callable
var _presenting := false
var _cancelled := false
var _finished := false
var _outcomes_presented := false
var _lead_in_complete := false
var _tail_deadline := 0
var _fx: Array[CanvasItem] = []
var _voices: Array[AudioStreamPlayer] = []
var _tweens: Array[Tween] = []
var _reactions: Array[Dictionary] = []
var _charge: Polygon2D
var _charge_voice: AudioStreamPlayer
var _projectile: Polygon2D
var _trail: Line2D
var _flight_start := Vector2.ZERO
var _flight_end := Vector2.ZERO
var _flight_direction := Vector2.RIGHT

func present(actor: Unit, action_context: Dictionary, permitted: Callable) -> void:
	context = action_context.duplicate(true)
	_actor = weakref(actor)
	_permitted = permitted
	var manager = instance_from_id(int(str(context.action_key).get_slice(":",0)))
	if not is_instance_valid(manager):
		cancel()
		return
	_manager = weakref(manager)
	var scene := manager.get_parent() as Node
	if is_instance_valid(scene) and scene.has_method("apply_zane_impact_kick"): _scene = weakref(scene)
	_presenting = true
	actor.face_action(context.destination)
	var fire := str(context.ability_id) == "fire"
	if fire:
		actor.set_cast_pose("anticipation")
		_charge = _fire_sprite(0, 4, 0.20, 36.0, "charge")
		_charge.position = to_local(actor.cast_origin_world())
	else:
		actor.set_melee_pose("anticipation")
	_phase("charge")
	_charge_voice = _cue("fire_charge" if fire else "sword_load")
	if not await _wait_permitted(0.20):
		_presenting = false
		cancel()
		return
	_stop_voice(_charge_voice)
	_charge_voice = null
	_remove_fx(_charge)
	_charge = null
	_phase("release")
	_cue("fire_release" if fire else "sword_release")
	if fire:
		# Same-frame cast release sampling updates the actual imported socket.
		actor.set_cast_pose("release")
		_projectile = _fire_sprite(4, 4, 0.22, 42.0, "projectile")
		_projectile.material = _hot_core_material()
		_projectile.position = to_local(actor.cast_origin_world())
		var destination := _grid_point(context.destination) + Vector2(0,-30)
		_flight_direction = (destination - _projectile.position).normalized()
		_projectile.rotation = _flight_direction.angle() + PI / 4.0
		_trail = _line(PackedVector2Array([_projectile.position,_projectile.position]),Color(1,0.38,0.07,0.7),4,"trail")
		var taper := Curve.new()
		taper.add_point(Vector2(0,0))
		taper.add_point(Vector2(1,1))
		_trail.width_curve = taper
		var heat := Gradient.new()
		heat.colors = PackedColorArray([Color(1,0.20,0.03,0),Color(1,0.65,0.20,0.9)])
		_trail.gradient = heat
		_flight_start = _projectile.position
		_flight_end = destination
		if not await _wait_permitted(0.22,true):
			_presenting = false
			cancel()
			return
		_stop_flight()
	_presenting = false
	if _cancelled: cancel()
	else: _lead_in_complete = true

func _wait_permitted(seconds: float, move_projectile: bool = false) -> bool:
	# Count only this phase's elapsed time, respecting (never writing) time_scale.
	# An owned gate also lets cancellation wake awaits BEFORE a manager is freed.
	var tree := get_tree()
	var clock := PhaseClock.new()
	_wait_clock = clock
	tree.process_frame.connect(clock.advance)
	var previous := Time.get_ticks_usec()
	var elapsed := 0.0
	var valid := true
	while elapsed < seconds:
		if not _valid_presentation():
			valid = false
			break
		await clock.tick
		if not _valid_presentation():
			valid = false
			break
		var current := Time.get_ticks_usec()
		elapsed += float(current-previous)/1000000.0 * maxf(0,Engine.time_scale)
		previous = current
		if move_projectile and is_instance_valid(_projectile):
			_projectile.position = _flight_start.lerp(_flight_end,clampf(elapsed/seconds,0,1))
	if tree.process_frame.is_connected(clock.advance): tree.process_frame.disconnect(clock.advance)
	if _wait_clock == clock: _wait_clock = null
	return valid and _valid_presentation()

func _valid_presentation() -> bool:
	if _cancelled or not _living_actor(): return false
	if _permitted.is_valid() and not _permitted.call(): return false
	return _current_ticket()

func _living_actor() -> bool:
	var actor = _actor.get_ref() if _actor != null else null
	return is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_queued_for_deletion() and actor.hp > 0 and not actor.is_defeated

func _current_ticket() -> bool:
	var manager = _manager.get_ref() if _manager != null else null
	return is_instance_valid(manager) and manager.is_inside_tree() and manager.action_lifecycle.ticket == int(context.ticket) and manager.action_lifecycle.phase != "idle"

func _process(_dt: float) -> void:
	if _cancelled: return
	if not _living_actor() or (not _finished and not _current_ticket()):
		cancel()
		return
	var actor = _actor.get_ref()
	if is_instance_valid(_charge): _charge.position = to_local(actor.cast_origin_world())
	if is_instance_valid(_trail) and is_instance_valid(_projectile):
		var point := _projectile.position
		_trail.points = PackedVector2Array([point - _flight_direction * 22, point - _flight_direction * 8, point])

func present_outcomes(records: Array[Dictionary]) -> void:
	if _cancelled or _finished or _outcomes_presented or not _current_ticket(): return
	if not _living_actor():
		cancel()
		return
	_outcomes_presented = true
	_tail_deadline = Time.get_ticks_msec() + 550
	var fire := str(context.ability_id) == "fire"
	if fire:
		for tile: Vector2i in context.footprint.slice(0,3):
			var p := _grid_point(tile)
			var fan := _line(PackedVector2Array([p+Vector2(-22,0),p+Vector2(0,-10),p+Vector2(22,0)]),Color(1,0.45,0.12,0.65),3,"fan_tile")
			_fade(fan,0.25)
	else:
		_blade_trail()
	var any_impact := false
	var any_immune := false
	var numbers: Array[Label] = []
	var anchors: Array[Vector2] = []
	for record: Dictionary in records.slice(0,3):
		var result: Dictionary = record.outcome
		var missed := bool(result.get("missed",false))
		var immune := not missed and float(result.get("affinity",1.0)) == 0.0
		var hp := int(result.get("applied_hp_damage",0))
		var armor := int(result.get("temper_damage",0)) + int(result.get("ether_damage",0))
		var impact := not missed and not immune and (hp > 0 or armor > 0)
		any_impact = any_impact or impact
		any_immune = any_immune or immune
		var text := "MISS" if missed else ("IMMUNE" if immune else ("-%d HP" % hp if hp > 0 else "0 HP"))
		var color := Color(0.74,0.80,0.88) if missed else (Color(0.55,0.77,1) if immune else Color(1,0.77,0.37))
		for field in [["temper_damage","Temper"],["ether_damage","Ether"]]:
			var loss := int(result.get(field[0],0))
			if loss > 0: text += "\n-%d %s" % [loss,field[1]]
		if result.get("critical",false) and impact:
			text += "\nCRIT"
			_phase("critical")
		if not missed and not immune:
			var affinity := float(result.get("affinity",1.0))
			if affinity > 1.0: text += " [WEAK]"
			elif affinity < 1.0: text += " [RESIST]"
		numbers.append(_number(text,color))
		anchors.append(_outcome_anchor(record))
		if armor > 0 and impact: _phase("armor")
		if impact:
			_recipient_accent(record.grid_pos,fire)
			var reference: WeakRef = record.target_ref
			var target = reference.get_ref() if reference != null else null
			if not result.get("defeated",false) and is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion() and target.hp > 0 and not target.is_defeated:
				_react(target)
	_place_numbers(numbers,anchors)
	if any_impact:
		_phase("impact")
		_cue("fire_hit" if fire else "sword_hit")
		if fire: _embers(_grid_point(context.destination)+Vector2(0,-20))
		if not bool(context.reduced_motion):
			var scene = _scene.get_ref() if _scene != null else null
			if is_instance_valid(scene):
				var actor = _actor.get_ref()
				var direction := (_grid_point(context.destination) - to_local(actor.global_position)).normalized()
				scene.apply_zane_impact_kick(direction,3.0 if fire else 2.0,0.12 if fire else 0.10)
				_phase("kick")
		_phase("pause")
		var juice := get_node_or_null("/root/BattleJuiceEffects")
		if juice != null: juice.trigger_pause(60 if fire else 80)
	elif fire:
		_cue("fire_immune" if any_immune else "fire_miss")
		_phase("deflect" if any_immune else "dissipate")

func _react(target: Unit) -> void:
	if is_instance_valid(target._rig3d): target._rig3d.play("hit")
	_phase("hurt:" + target.unit_id)
	if bool(context.reduced_motion): return
	var visual = target.visual
	var drawable := visual as CanvasItem
	if is_instance_valid(target._rig3d):
		var output: CanvasItem = target._rig3d.get("output") as CanvasItem
		if is_instance_valid(output): drawable = output
	if not is_instance_valid(drawable): return
	var baseline_scale: Vector2 = visual.scale
	var baseline_color: Color = drawable.self_modulate
	var previous: Variant = visual.get_meta(REACTION_META,{})
	if previous is Dictionary and previous.has("owner"):
		var previous_ref: Variant = previous.get("tween")
		if previous_ref is WeakRef:
			var previous_tween = previous_ref.get_ref()
			if previous_tween is Tween and previous_tween.is_valid(): previous_tween.kill()
		if previous.get("scale") is Vector2: baseline_scale = previous.scale
		if previous.get("color") is Color: baseline_color = previous.color
		visual.scale = baseline_scale
		drawable.self_modulate = baseline_color
	var baseline := {"ref":weakref(visual),"color_ref":weakref(drawable),"scale":baseline_scale,"color":baseline_color}
	_reactions.append(baseline)
	var tween := _tween()
	visual.set_meta(REACTION_META,{"owner":str(context.action_key),"scale":baseline_scale,"color":baseline_color,"tween":weakref(tween)})
	tween.set_parallel(true)
	tween.tween_property(visual,"scale",visual.scale*Vector2(1.04,0.96),0.05)
	tween.tween_property(drawable,"self_modulate",Color(1.25,1.10,0.82),0.05)
	tween.chain().tween_property(visual,"scale",baseline.scale,0.15)
	tween.parallel().tween_property(drawable,"self_modulate",baseline.color,0.15)

func _blade_trail() -> void:
	var actor = _actor.get_ref()
	if not is_instance_valid(actor): return
	var origin := to_local(actor.cast_origin_world())
	var rig = actor._rig3d
	if is_instance_valid(rig):
		var socket = rig.model.find_child("Kael_v2_weapon_socket",true,false)
		if socket != null: origin = to_local(rig.output.to_global(rig.camera.unproject_position(socket.global_position)))
	var direction := (_grid_point(context.destination) - origin).normalized()
	var normal := direction.orthogonal()
	var line := _line(PackedVector2Array([origin-direction*15-normal*8,origin,origin+direction*20+normal*4]),Color(1,0.91,0.67,0.85),2,"blade_trail")
	_fade(line,0.14)

func _recipient_accent(tile: Vector2i, fire: bool) -> void:
	var p := _grid_point(tile)+Vector2(0,-25)
	if fire:
		var burst := FireballSprite.new()
		burst.configure(8, 8, 0.50, 84.0)
		_own(burst, "fire_impact")
		burst.position = _grid_point(tile)
		_fade(burst, 0.50)
		return
	var accent := _line(PackedVector2Array([p+Vector2(-7,6),p,p+Vector2(7,-6)]),Color(1,0.52,0.13) if fire else Color(1,0.91,0.70),2,"recipient_accent")
	_fade(accent,0.18)

func _number(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_outline_color",Color(0.04,0.03,0.02))
	label.add_theme_constant_override("outline_size",4)
	_own(label,"outcome")
	return label

func _outcome_anchor(record: Dictionary) -> Vector2:
	var reference: WeakRef = record.target_ref
	var target = reference.get_ref() if reference != null else null
	if is_instance_valid(target):
		# Unit-local HUD height must pass through its actual scale/parent transform.
		return to_local(target.to_global(Vector2(0,minf(-86,target._hud_bar_y-32))))
	return _grid_point(record.grid_pos)+Vector2(0,-86)

func _place_numbers(labels: Array[Label], anchors: Array[Vector2]) -> void:
	if labels.is_empty(): return
	var canvas := get_global_transform_with_canvas()
	var inverse := canvas.affine_inverse()
	var zoom := canvas.get_scale().abs()
	var padding := Vector2.ONE*4*zoom
	var preferred: Array[Rect2] = []
	for i in labels.size():
		var label_extent := labels[i].get_combined_minimum_size()*zoom+padding*2
		# Above the recipient, not across their body. Preserve full multiline size.
		preferred.append(Rect2(canvas*anchors[i]-Vector2(label_extent.x*0.5,label_extent.y+12*zoom.y),label_extent))
	var safe := get_viewport_rect().grow(-12)
	var sidebar := preload("res://scripts/ui/BattleHudLayout.gd").right_sidebar_rect(get_viewport_rect().size)
	safe.size.x = minf(safe.end.x,sidebar.position.x-12)-safe.position.x
	var placed := OutcomeLayout.place(preferred,safe,_outcome_hud_rects(),22*zoom.y)
	for i in labels.size():
		var label := labels[i]
		label.position = inverse*(placed[i].position+padding)
		var tween := _tween()
		tween.set_parallel(true)
		tween.tween_property(label,"position:y",label.position.y-22,0.5)
		tween.tween_property(label,"modulate:a",0.0,0.25).set_delay(0.25)
		if placed[i].position.distance_squared_to(preferred[i].position) <= 16: continue
		var target := canvas*anchors[i]
		var start := Vector2(clampf(target.x,placed[i].position.x,placed[i].end.x),clampf(target.y,placed[i].position.y,placed[i].end.y))
		var origin := inverse*start
		var color := label.get_theme_color("font_color")
		color.a = 0.55
		var link := _line(PackedVector2Array([origin,inverse*target]),color,1.2,"outcome_link")
		tween.tween_method(func(rise: float) -> void: link.set_point_position(0,origin+Vector2(0,-rise)),0.0,22.0,0.5)
		tween.tween_property(link,"modulate:a",0.0,0.25).set_delay(0.25)

func _outcome_hud_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var manager = _manager.get_ref() if _manager != null else null
	if not is_instance_valid(manager): return result
	# Read actual top-level HUD bounds, including expanded comparison controls.
	# Do not assume UI scale, panel content height or a particular scene name.
	for layer in manager.get_parent().get_children():
		if not layer is CanvasLayer: continue
		for control in layer.get_children():
			if control is Control and control.is_visible_in_tree() and control.modulate.a > 0.01:
				if control.has_method("occlusion_rect"):
					result.append(control.occlusion_rect())
				else:
					result.append(control.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,control.size))
	# Keep full labels clear of real unit names, HP bars and status icons too.
	for unit in manager.units.values():
		if not is_instance_valid(unit): continue
		var header_bounds := Rect2()
		for control in unit.find_children("*","Control",true,false):
			if control.z_index < 13 or not control.is_visible_in_tree(): continue
			var rect := Rect2(Vector2.ZERO,control.size)
			if control is Label: rect = rect.grow(control.get_theme_constant("outline_size"))
			var bounds: Rect2 = control.get_global_transform_with_canvas()*rect
			header_bounds = header_bounds.merge(bounds) if header_bounds.has_area() else bounds
		if header_bounds.has_area(): result.append(header_bounds)
	return result

func _embers(p: Vector2) -> void:
	for i in 8:
		var ember := _disc(1.3,Color(1,0.58,0.13,0.8),"ember")
		ember.position = p
		var direction := Vector2.from_angle(TAU*float(i)/8.0)
		var tween := _tween()
		tween.set_parallel(true)
		tween.tween_property(ember,"position",p+direction*(12+3*(i%3))+Vector2(0,-9),0.35)
		tween.tween_property(ember,"modulate:a",0.0,0.35)

func _grid_point(tile: Vector2i) -> Vector2:
	var manager = _manager.get_ref() if _manager != null else null
	if is_instance_valid(manager):
		var grid = manager.tactical_grid
		return to_local(grid.to_global(grid._unit_foot_pos(tile)))
	return Vector2.ZERO

func _fire_sprite(first: int, count: int, duration: float, width: float, role: String) -> Polygon2D:
	# Keep the existing socket-tracked owner and its lifecycle metadata.
	var anchor := _disc(0.0, Color.TRANSPARENT, role)
	var sprite := FireballSprite.new()
	sprite.configure(first, count, duration, width)
	anchor.add_child(sprite)
	return anchor

func _disc(radius: float, color: Color, role: String) -> Polygon2D:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 12: points.append(Vector2.from_angle(TAU*float(i)/12.0)*radius)
	polygon.polygon = points
	polygon.color = color
	_own(polygon,role)
	return polygon

func _line(points: PackedVector2Array, color: Color, width: float, role: String) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	_own(line,role)
	return line

func _own(node: CanvasItem, role: String) -> void:
	node.set_meta("zane_effect_role",role)
	add_child(node)
	_fx.append(node)

func _tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween

func _fade(node: CanvasItem, seconds: float) -> void:
	_tween().tween_property(node,"modulate:a",0.0,seconds)

func _cue(id: String) -> AudioStreamPlayer:
	var voice := Audio.play_cue(id,self)
	if is_instance_valid(voice): _voices.append(voice)
	return voice

func _phase(phase: String) -> void:
	phase_presented.emit(phase)

func _stop_voice(voice: Variant) -> void:
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null
		voice.queue_free()

func _remove_fx(node: Variant) -> void:
	if is_instance_valid(node):
		node.hide()
		node.queue_free()

func _stop_flight() -> void:
	_remove_fx(_projectile)
	_remove_fx(_trail)
	_projectile = null
	_trail = null

func finish() -> void:
	if _cancelled or _finished: return
	_finished = true
	_stop_flight()
	_remove_fx(_charge)
	_stop_voice(_charge_voice)
	var remaining := maxf(0,float(_tail_deadline-Time.get_ticks_msec())/1000.0)
	if remaining <= 0:
		queue_free()
	else:
		var reference: WeakRef = weakref(self)
		get_tree().create_timer(minf(remaining,0.55)).timeout.connect(func() -> void:
			var owner = reference.get_ref()
			if is_instance_valid(owner): owner.queue_free()
		)

func cancel() -> void:
	if not _cancelled:
		_cancelled = true
		for tween in _tweens:
			if tween != null and tween.is_valid(): tween.kill()
		for voice in _voices: _stop_voice(voice)
		for fx in _fx: _remove_fx(fx)
		_restore_reactions()
		var manager = _manager.get_ref() if _manager != null else null
		var scene = _scene.get_ref() if _scene != null else null
		if is_instance_valid(manager) and is_instance_valid(scene) and manager._action_presentation_context.get("action_key","") == context.get("action_key",""):
			scene.apply_zane_impact_kick(Vector2.ZERO,0,0)
	if _wait_clock != null: _wait_clock.advance()
	if not _presenting: queue_free()

func _restore_reactions() -> void:
	for reaction in _reactions:
		var visual = reaction.ref.get_ref()
		if is_instance_valid(visual):
			var current: Variant = visual.get_meta(REACTION_META,{})
			if current is Dictionary and str(current.get("owner","")) == str(context.get("action_key","")):
				visual.scale = reaction.scale
				var drawable = reaction.color_ref.get_ref()
				if is_instance_valid(drawable): drawable.self_modulate = reaction.color
				visual.remove_meta(REACTION_META)
	_reactions.clear()

func _exit_tree() -> void:
	for voice in _voices: _stop_voice(voice)
	_restore_reactions()

func _hot_core_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode unshaded;
varying vec2 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
    float radial = clamp(length(local_point) / 5.0, 0.0, 1.0);
    vec3 hue = mix(vec3(1.0, 0.98, 0.82), vec3(1.0, 0.30, 0.04), smoothstep(0.15, 1.0, radial));
    COLOR = vec4(hue, 1.0 - smoothstep(0.80, 1.0, radial));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

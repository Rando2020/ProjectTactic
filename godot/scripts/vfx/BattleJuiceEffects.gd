## BattleJuiceEffects.gd
## Executes ImpactJuice hit recipes on live units. Presentation only.
## Autoloaded as BattleJuiceEffects.
##
##   BattleJuiceEffects.punch(target_unit, ImpactJuice.hit_profile(ctx))
##
## Beats: white flash (few frames) -> sharp sound -> knockback along the hit
## direction -> hitstop freeze. Directional particles live in VFXManager and
## camera shake lives in BattleScene (it owns Camera2D.offset); both read the
## same profile so every beat agrees on tier and direction.

extends Node

## Legacy intensity names kept for trigger_hit callers.
const INTENSITY_PRESETS = {
	"light": {"shake": 2, "wobble": 0.1, "pause": 60},
	"normal": {"shake": 4, "wobble": 0.15, "pause": 80},
	"heavy": {"shake": 6, "wobble": 0.2, "pause": 100},
	"critical": {"shake": 8, "wobble": 0.25, "pause": 120},
}

const FLASH_SHADER_CODE := """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a);
}
"""

const REST_META := &"juice_rest_position"
const FLASH_META := &"juice_flash_material"

var _is_paused: bool = false
var _pause_until_usec: int = 0
var _flash_shader: Shader
var _flashing_units: Dictionary = {}  # unit_id -> true while flashing
var _knock_tweens: Dictionary = {}    # instance_id -> Tween


func _ready() -> void:
	# Hitstop pauses the tree; juice itself must keep ticking to release it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_flash_shader = Shader.new()
	_flash_shader.code = FLASH_SHADER_CODE


## Full punchy hit on one target from an ImpactJuice.hit_profile() recipe.
func punch(target: Node, profile: Dictionary) -> void:
	if not is_instance_valid(target):
		return
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(str(profile.get("sound_cue", "juice_whack")), -2.0, float(profile.get("sound_pitch", 1.0)))
		if bool(profile.get("layer_crack", false)):
			audio.play_sfx("juice_shatter", -9.0, 0.75)
	flash_white(target, float(profile.get("flash_sec", 0.05)))
	knockback(target, profile.get("direction", Vector2.ZERO), float(profile.get("knockback_px", 0.0)),
		float(profile.get("knockback_out_sec", 0.06)), float(profile.get("knockback_back_sec", 0.18)))
	trigger_pause(int(profile.get("hitstop_ms", 0)))


## Turn the target's visual pure white for a few frames, then snap back.
func flash_white(target: Node, seconds: float) -> void:
	var visual := _visual_of(target)
	if visual == null:
		return
	var unit_id := str(target.get("unit_id")) if "unit_id" in target else str(target.get_instance_id())
	_flashing_units[unit_id] = true
	var material: ShaderMaterial = visual.get_meta(FLASH_META) if visual.has_meta(FLASH_META) else null
	if material == null and _can_take_flash_material(visual):
		material = ShaderMaterial.new()
		material.shader = _flash_shader
		visual.material = material
		visual.set_meta(FLASH_META, material)
	if material != null:
		material.set_shader_parameter("flash", 1.0)
	else:
		# Rigs / pre-materialed visuals: overbright modulate reads as a white pop.
		visual.self_modulate = Color(2.6, 2.6, 2.6, 1.0)
	await _wait_unpaused_aware(seconds)
	if is_instance_valid(visual):
		if material != null:
			material.set_shader_parameter("flash", 0.0)
		else:
			visual.self_modulate = Color.WHITE
	_flashing_units.erase(unit_id)


## Shove the visual (never the grid position) along the hit direction and spring back.
func knockback(target: Node, direction: Vector2, distance_px: float, out_sec: float = 0.06, back_sec: float = 0.18) -> void:
	var visual := _visual_of(target)
	if visual == null or distance_px <= 0.0 or direction.length_squared() < 0.0001:
		return
	if not ("position" in visual):
		return
	var key := visual.get_instance_id()
	var existing: Tween = _knock_tweens.get(key)
	if existing and existing.is_valid():
		existing.kill()
	if not visual.has_meta(REST_META):
		visual.set_meta(REST_META, visual.position)
	var rest: Vector2 = visual.get_meta(REST_META)
	var pushed := rest + direction.normalized() * distance_px * Vector2(1.0, 0.6)
	var tween := visual.create_tween()
	_knock_tweens[key] = tween
	tween.tween_property(visual, "position", pushed, out_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position", rest, back_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(visual):
			visual.position = rest
			visual.remove_meta(REST_META)
		_knock_tweens.erase(key)
	)


## Hitstop. Overlapping requests extend one freeze instead of racing to unpause.
func trigger_pause(duration_ms: int = 80) -> void:
	if duration_ms <= 0 or not is_inside_tree():
		return
	var tree := get_tree()
	_pause_until_usec = maxi(_pause_until_usec, Time.get_ticks_usec() + duration_ms * 1000)
	if _is_paused:
		return
	_is_paused = true
	tree.paused = true
	while Time.get_ticks_usec() < _pause_until_usec:
		await tree.process_frame
	tree.paused = false
	_is_paused = false


## Legacy entry point. Resolves ids lazily (the old _ready() cache was always null).
func trigger_hit(target_unit_ids: Array, intensity: String = "normal",
		pause_duration: int = 80, flash_duration: int = 300,
		_shake_duration: int = 150) -> void:
	var tier := intensity if ImpactJuice.HIT_TIERS.has(intensity) else "normal"
	for unit_id in target_unit_ids:
		var unit := _find_unit(str(unit_id))
		if unit:
			flash_white(unit, minf(flash_duration / 1000.0, float(ImpactJuice.HIT_TIERS[tier].flash_frames) * ImpactJuice.FRAME))
	trigger_pause(pause_duration)


func trigger_flash(unit_id: String, duration_ms: int = 300) -> void:
	var unit := _find_unit(unit_id)
	if unit:
		flash_white(unit, duration_ms / 1000.0)


func is_paused() -> bool:
	return _is_paused


func get_flashing_units() -> Array:
	return _flashing_units.keys()


## Sprites and rects draw themselves, so a material whitens them. Container
## rigs draw through children, so they use the overbright-modulate fallback.
func _can_take_flash_material(visual: CanvasItem) -> bool:
	if visual.material != null:
		return false
	return visual is Sprite2D or visual is Control or visual.get_child_count() == 0


func _visual_of(target: Node) -> CanvasItem:
	if not is_instance_valid(target):
		return null
	var visual = target.get("visual") if "visual" in target else target
	return visual as CanvasItem


func _find_unit(unit_id: String) -> Node:
	for node in get_tree().get_nodes_in_group("units"):
		if str(node.get("unit_id")) == unit_id:
			return node
	var scene := get_tree().current_scene
	var manager := scene.get_node_or_null("BattleManager") if scene else null
	if manager and "units" in manager:
		return manager.units.get(unit_id)
	return null


func _wait_unpaused_aware(seconds: float) -> void:
	# Counts real time so a hitstop holds the flash frame rather than skipping it.
	var end := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < end or _is_paused:
		await get_tree().process_frame

extends Node3D
## Isolated art preview, not Tactic combat logic. Grid movement uses a display-only
## clear zone; static scenery does not silently introduce gameplay collision rules.
var actor: Node3D
var player: AnimationPlayer
var busy := false
var cell := Vector2i(2, 2)

func asset(id: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var packed := load("res://models/" + id + ".glb") as PackedScene
	assert(packed != null, "Missing asset: " + id)
	var model := packed.instantiate() as Node3D
	add_child(model)
	model.position = at
	model.rotation.y = yaw
	return model

func locate_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := locate_animation(child)
		if found != null:
			return found
	return null

func _ready() -> void:
	for x in range(6):
		for z in range(6):
			asset("floor-inlaid" if (x + z) % 7 == 0 else "floor-plain", Vector3(x * 2 - 5, 0, z * 2 - 5))
	for x in range(6):
		if x != 3:
			asset("wall-broken", Vector3(x * 2 - 5, 0, -5.8))
		if x < 4:
			asset("wall-full", Vector3(-5.8, 0, x * 2 - 5), PI / 2)
	for pos in [Vector3(-5.8, 0, -5.8), Vector3(5.8, 0, -5.8), Vector3(-5.8, 0, 5.8)]:
		asset("pillar", pos)
	asset("archway", Vector3(1, 0, -5.8))
	asset("banner", Vector3(-3, 0, -4.6))
	asset("banner", Vector3(4.6, 0, -4.6))
	asset("stairs-rise-1m", Vector3(4, 0, 1))
	asset("platform-rise-1m", Vector3(4, 0, -1))
	for x in [-1, 3]:
		asset("brazier", Vector3(x, 0, -4.6))
		var fire := OmniLight3D.new()
		fire.position = Vector3(x, 1.3, -4.6)
		fire.light_color = Color(1, 0.35, 0.08)
		fire.light_energy = 1.5
		fire.omni_range = 3
		add_child(fire)
	actor = asset("zane-rig-prototype", Vector3(-1, 0, -1))
	player = locate_animation(actor)
	assert(player != null, "Character AnimationPlayer missing")
	for clip in ["idle", "walk", "attack"]:
		assert(player.has_animation(clip), "Missing clip: " + clip)
	player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	player.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
	player.play("idle")
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(15, 20, 20)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 19
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color(1, 0.84, 0.65)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.045, 0.065, 0.095)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.45, 0.60, 0.8)
	settings.ambient_light_energy = 0.55
	environment.environment = settings
	add_child(environment)
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "THE APPOINTED  /  ASHVALE\nMesh candidate preview • Arrow keys: move • Space: attack\nCharacter animation prototype — no combat simulation"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	layer.add_child(label)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or busy:
		return
	match event.keycode:
		KEY_UP: move_cell(Vector2i(0, -1))
		KEY_DOWN: move_cell(Vector2i(0, 1))
		KEY_LEFT: move_cell(Vector2i(-1, 0))
		KEY_RIGHT: move_cell(Vector2i(1, 0))
		KEY_SPACE: attack()

func move_cell(delta: Vector2i) -> void:
	if busy:
		return
	var next := cell + delta
	# Reserved clear 3x3 region, separate from walls, stairs and props.
	if next.x < 1 or next.x > 3 or next.y < 1 or next.y > 3:
		return
	busy = true
	cell = next
	# glTF character forward is +Z after Blender coordinate conversion.
	actor.rotation.y = atan2(float(delta.x), float(delta.y))
	player.play("walk", 0.1)
	var tween := create_tween()
	tween.tween_property(actor, "position", Vector3(cell.x * 2 - 5, 0, cell.y * 2 - 5), 1.0)
	await tween.finished
	player.play("idle", 0.12)
	busy = false

func attack() -> void:
	if busy:
		return
	busy = true
	player.play("attack", 0.1)
	await player.animation_finished
	player.play("idle", 0.12)
	busy = false

extends Node3D

const Encounter := preload("res://demos/blooming_ruins/Encounter.gd")
const TERRAIN := preload("res://demos/blooming_ruins/assets/terrain.png")
const SPRITES := preload("res://demos/blooming_ruins/assets/sprites.png")
var sim: RefCounted
var camera: Camera3D
var visuals: Dictionary = {}
var markers: Node3D
var mode := "Move"
var busy := false
var info: Label
var forecast_label: Label
var timeline: Label
var message: Label
var objective: Label
var buttons: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var cursor := Vector2i(2, 9)

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	sim = Encounter.new()
	build_materials()
	build_world()
	build_ui()
	refresh()
	if OS.get_environment("BLOOM_CAPTURE") != "": capture.call_deferred()

func _exit_tree() -> void:
	if sim: sim.dispose()

func build_materials() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled, unshaded; uniform sampler2D atlas: source_color; uniform vec2 quadrant; uniform bool ground = false; varying vec3 world; varying vec3 normal_world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; normal_world=MODEL_NORMAL_MATRIX*NORMAL;} void fragment(){vec2 uv=ground ? world.xz*0.19 : (abs(normal_world.x)>0.5 ? world.zy : world.xy)*0.22; ALBEDO=texture(atlas,quadrant+vec2(0.003)+fract(uv)*0.494).rgb*(ground ? 0.92 : 0.85); ROUGHNESS=1.0;}"
	for i in 4:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("atlas", TERRAIN)
		mat.set_shader_parameter("quadrant", Vector2(i % 2, i / 2) * 0.5)
		mat.set_shader_parameter("ground", i != 2)
		materials.append(mat)

func world(cell: Vector2i) -> Vector3:
	var height: float = float(sim.tiles[cell].height) * 0.65
	if cell.x in [2, 9] and cell.y in [3, 4]: height -= 0.24
	return Vector3(cell.x * 2.0, height, cell.y * 2.0)

func box(at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = at
	add_child(mesh)
	return mesh

func build_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("354541")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("d2c2d9")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("fff0cf")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 31
	camera.position = Vector3(34, 28, 39)
	add_child(camera)
	camera.look_at(Vector3(11, 0, 9))
	camera.current = true
	var backdrop := StandardMaterial3D.new()
	backdrop.albedo_color = Color("354541")
	backdrop.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box(Vector3(11, -1.7, 10), Vector3(100, 0.3, 100), backdrop)
	box(Vector3(11, -0.75, 10), Vector3(24, 1.5, 22), materials[2])
	box(Vector3(11, 0.97, 2), Vector3(24, 1.95, 6), materials[2])
	for cell: Vector2i in sim.tiles:
		var pos := world(cell)
		if cell.x in [2, 9] and cell.y in [3, 4]:
			var top: float = float(sim.tiles[cell].height) * 0.65
			for step in 4:
				var h: float = top - 0.65 + float(step + 1) * 0.1625
				box(Vector3(pos.x, h * 0.5, pos.z + 0.75 - step * 0.5), Vector3(2, h, 0.51), materials[0])
		else:
			var mesh := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(2, 2)
			mesh.mesh = plane
			mesh.position = pos + Vector3.UP * 0.015
			mesh.material_override = materials[0 if cell.y <= 2 or cell.y >= 8 or cell.x in [2, 9] else 1]
			add_child(mesh)
		var body := StaticBody3D.new()
		body.position = pos - Vector3.UP * 0.05
		body.set_meta("cell", cell)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2, 0.1, 2)
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		if sim.tiles[cell].blocked:
			box(pos + Vector3.UP * 0.65, Vector3(1.9, 1.3, 0.75), materials[2])
			box(pos + Vector3.UP * 1.33, Vector3(1.95, 0.15, 0.85), materials[0])
	# Low perimeter masonry leaves a clear entrance. All decor remains outside routes.
	for x in range(0, 12):
		if x not in [1, 2, 3, 9]:
			wall(Vector2i(x, 10), Vector3(0, 0, 0.85), 0.7)
		if x not in [8, 9, 10]: wall(Vector2i(x, 0), Vector3(0, 0, -0.85), 1.1)
	for z in range(1, 10):
		if z % 3 != 1:
			wall(Vector2i(0, z), Vector3(-0.85, 0, 0), 0.8)
			wall(Vector2i(11, z), Vector3(0.85, 0, 0), 0.8)
	# Gate is deliberately assembled from a few textured primitives.
	var gate := world(Encounter.GATE)
	for side in [-1, 1]:
		box(gate + Vector3(side * 1.4, 1.75, -0.6), Vector3(0.65, 3.5, 0.8), materials[2])
		box(gate + Vector3(side * 1.4, 3.5, -0.6), Vector3(0.9, 0.25, 1), materials[0])
	for i in 7:
		var angle := float(i) * PI / 6
		var arch := box(gate + Vector3(cos(angle) * 1.4, 3.4 + sin(angle) * 1.4, -0.6), Vector3(0.72, 0.6, 0.8), materials[0])
		arch.rotation.z = angle - PI / 2
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("f5c46b")
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var diamond := box(gate + Vector3(0, 3.1, 0), Vector3(0.35, 0.35, 0.15), gold)
	diamond.rotation.z = PI / 4
	var decor := RandomNumberGenerator.new()
	decor.seed = 85
	for i in 150:
		var cell := Vector2i(decor.randi_range(0, 11), decor.randi_range(0, 10))
		if cell.x in [2, 9] or (cell.x > 0 and cell.x < 11 and cell.y not in [0, 10] and not sim.tiles[cell].blocked): continue
		var plant := sprite(4, 0.0028 + decor.randf() * 0.0011)
		plant.position = world(cell) + Vector3(decor.randf_range(-0.8, 0.8), 0.02, decor.randf_range(-0.8, 0.8))
		add_child(plant)
	for x in [-2, 1, 4, 7, 10, 13]:
		var tree := sprite(5, 0.011)
		tree.position = Vector3(x * 2, -1.5, -3)
		add_child(tree)
	markers = Node3D.new()
	add_child(markers)
	for unit: Unit in sim.units:
		var root := Node3D.new()
		root.position = world(unit.grid_pos)
		add_child(root)
		var art := sprite(int(unit.get_meta("sprite")), 0.0052)
		root.add_child(art)
		var pick_body := StaticBody3D.new()
		pick_body.name = "PickBody"
		pick_body.collision_layer = 2
		pick_body.collision_mask = 0
		pick_body.set_meta("unit_id", unit.unit_id)
		var pick_shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.5
		capsule.height = 3.0
		pick_shape.shape = capsule
		pick_shape.position.y = 1.5
		pick_body.add_child(pick_shape)
		root.add_child(pick_body)
		var ring := marker_mesh(Color("57c5df") if unit.team == "player" else Color("d56a66"), 0.9)
		root.add_child(ring)
		var hp := Label3D.new()
		hp.name = "Health"
		hp.position.y = 3.5
		hp.font_size = 36
		hp.pixel_size = 0.009
		hp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(hp)
		visuals[unit.unit_id] = root

func wall(cell: Vector2i, offset: Vector3, height: float) -> void:
	var pos := world(cell) + offset
	box(pos + Vector3.UP * height * 0.5, Vector3(1.7, height, 0.5), materials[2])
	box(pos + Vector3.UP * (height + 0.05), Vector3(1.8, 0.13, 0.6), materials[0])

func sprite(index: int, pixel_scale: float) -> Sprite3D:
	var art := Sprite3D.new()
	art.texture = SPRITES
	art.region_enabled = true
	var cell := Vector2(SPRITES.get_width() / 3.0, SPRITES.get_height() / 2.0)
	art.region_rect = Rect2(Vector2(index % 3, index / 3) * cell, cell)
	# Insets avoid neighboring silhouettes touching the atlas cell boundary.
	art.region_rect = art.region_rect.grow(-5)
	if index == 5:
		# The generated tree extends beyond a perfect atlas cell; isolate its bounds.
		var atlas_size := Vector2(SPRITES.get_width(), SPRITES.get_height())
		art.region_rect = Rect2(Vector2(0.73, 0.51) * atlas_size, Vector2(0.20, 0.47) * atlas_size)
	art.pixel_size = pixel_scale
	art.offset.y = art.region_rect.size.y * 0.5 - 15
	art.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	art.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	art.alpha_scissor_threshold = 0.35
	art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.no_depth_test = false
	return art

func marker_mesh(color: Color, extent: float = 1.88) -> MeshInstance3D:
	var mark := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(extent, extent)
	mark.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark.material_override = material
	mark.position.y = 0.04
	return mark

func label(parent: Node, text: String, size: int = 18) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_color_override("font_color", Color("eee3ca"))
	control.add_theme_font_size_override("font_size", size)
	parent.add_child(control)
	return control

func panel(parent: Node, anchors: int, offsets: Rect2) -> VBoxContainer:
	var card := PanelContainer.new()
	parent.add_child(card)
	card.set_anchors_preset(anchors)
	card.offset_left = offsets.position.x
	card.offset_top = offsets.position.y
	card.offset_right = offsets.end.x
	card.offset_bottom = offsets.end.y
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.06, 0.94)
	style.border_color = Color("a68b58")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	card.add_child(column)
	return column

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := panel(canvas, Control.PRESET_TOP_LEFT, Rect2(18, 18, 390, 80))
	label(title, "THE BLOOMING RUINS", 25)
	objective = label(title, "Defeat the patrol, then reach the golden gate.", 16)
	var top := panel(canvas, Control.PRESET_TOP_RIGHT, Rect2(-520, 18, 500, 80))
	label(top, "NEXT TO ACT", 14)
	timeline = label(top, "", 16)
	var bottom := panel(canvas, Control.PRESET_BOTTOM_WIDE, Rect2(18, -172, -36, 154))
	info = label(bottom, "", 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bottom.add_child(row)
	for action in ["Move", "Attack", "Heal", "Wait", "Restart"]:
		var button := Button.new()
		button.text = action
		button.custom_minimum_size = Vector2(110, 38)
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(command.bind(action))
		row.add_child(button)
		buttons[action] = button
	forecast_label = label(bottom, "", 17)
	message = label(bottom, "Click a blue tile to move. Attack, then Wait. Wheel: zoom · R: restart", 16)
	buttons.Move.grab_focus()

func command(action: String) -> void:
	if action == "Restart":
		get_tree().reload_current_scene()
		return
	if busy or not sim.result.is_empty() or sim.active.team != "player": return
	if action == "Wait":
		sim.next_turn()
		mode = "Move"
		refresh()
		enemy_turns()
		return
	mode = action
	refresh()

func refresh() -> void:
	for child in markers.get_children(): child.queue_free()
	for unit: Unit in sim.units:
		visuals[unit.unit_id].visible = unit.hp > 0
		visuals[unit.unit_id].get_node("PickBody").collision_layer = 2 if unit.hp > 0 else 0
		visuals[unit.unit_id].get_node("Health").text = "%d / %d" % [unit.hp, unit.unit_data.base_stats.hp]
	var active: Unit = sim.active
	info.text = "%s  ·  HP %d/%d  ·  MP %d  ·  Move %s  /  Action %s" % [active.display_name, active.hp, active.unit_data.base_stats.hp, active.mp, "used" if sim.moved else "ready", "used" if sim.acted else "ready"]
	var names: Array[String] = []
	for entry in sim.order.get_projected_order(4): names.append(entry.display_name)
	timeline.text = " → ".join(names)
	for key in buttons:
		buttons[key].disabled = key != "Restart" and (busy or active.team != "player" or not sim.result.is_empty())
	buttons.Move.disabled = buttons.Move.disabled or sim.moved
	buttons.Attack.disabled = buttons.Attack.disabled or sim.acted or (active.unit_id == "mira" and active.mp < 6)
	buttons.Heal.disabled = buttons.Heal.disabled or sim.acted or active.unit_id != "mira" or active.mp < 8
	buttons.Attack.text = "Light · 6 MP" if active.unit_id == "mira" else "Attack"
	buttons.Heal.text = "Heal · 8 MP"
	forecast_label.text = "%s · %s" % [mode, "Select a reachable tile" if mode == "Move" else "Hover a unit to inspect, click to commit"]
	if not sim.result.is_empty():
		objective.text = "Gate secured. The path ahead is yours." if sim.result == "VICTORY" else "Your party has fallen. Try a different approach."
		info.text = sim.result + "  ·  Restart to play again"
		return
	if active.team != "player": return
	if mode == "Move" and not sim.moved:
		for cell: Vector2i in sim.reachable(active):
			var mark := marker_mesh(Color("65d0e0"))
			mark.position += world(cell)
			markers.add_child(mark)
	elif mode == "Attack" and not sim.acted:
		for target: Unit in sim.units:
			if sim.can_attack(active, target):
				var mark := marker_mesh(Color("e78570"))
				mark.position += world(target.grid_pos)
				markers.add_child(mark)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.size = maxf(22, camera.size - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.size = minf(44, camera.size + 1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var cell: Variant = pick(event.position)
			if cell != null: click(cell)
	elif event is InputEventMouseMotion:
		var cell: Variant = pick(event.position)
		if cell != null: inspect(cell)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R: command("Restart")
		elif event.keycode == KEY_1: command("Move")
		elif event.keycode == KEY_2: command("Attack")
		elif event.keycode == KEY_3: command("Heal")
		elif event.keycode == KEY_SPACE: command("Wait")

func pick(screen: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen) * 200)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return null
	if hit.collider.has_meta("unit_id"):
		for unit: Unit in sim.units:
			if unit.unit_id == hit.collider.get_meta("unit_id"): return unit.grid_pos
	return hit.collider.get_meta("cell")

func inspect(cell: Vector2i) -> void:
	if busy or not sim.result.is_empty(): return
	cursor = cell
	var target: Unit = sim.occupant(cell)
	if not target:
		forecast_label.text = "%s · Elevation %d · %s" % [mode, int(sim.tiles[cell].height), "Blocked" if sim.tiles[cell].blocked else "Walkable"]
		return
	if mode == "Attack" and sim.can_attack(sim.active, target):
		var f: Dictionary = sim.forecast(sim.active, target)
		forecast_label.text = "%s · %d HP on hit · Hit %d%% · Crit %d%% of hits · %s" % [target.display_name, int(f.hp_damage), int(f.hit_pct), int(f.crit_pct), "6 MP" if sim.active.unit_id == "mira" else "No MP cost"]
	elif mode == "Heal" and target.team == "player":
		forecast_label.text = "%s · Restore up to 45 HP · 8 MP · Range 3" % target.display_name
	else:
		forecast_label.text = "%s · HP %d/%d · Elevation %d" % [target.display_name, target.hp, target.unit_data.base_stats.hp, int(sim.tiles[cell].height)]

func click(cell: Vector2i) -> void:
	if busy or sim.active.team != "player" or not sim.result.is_empty(): return
	if mode == "Move":
		var path: Array = sim.move_active(cell)
		if path.is_empty(): return
		await animate_move(sim.active, path)
	elif mode == "Attack":
		var target: Unit = sim.occupant(cell)
		var outcome: Dictionary = sim.attack_active(target)
		if outcome.is_empty():
			message.text = "No valid target: check range, obstacles and MP."
			return
		message.text = outcome.message
		await hit_feedback(target, int(outcome.damage))
	elif mode == "Heal":
		var target: Unit = sim.occupant(cell)
		if sim.heal_active(target): message.text = "Mira restores %s. 8 MP spent." % target.display_name
		else: message.text = "Heal needs a living ally within 3 tiles and 8 MP."
	refresh()

func animate_move(unit: Unit, path: Array) -> void:
	busy = true
	refresh()
	var tween := create_tween()
	for cell: Vector2i in path:
		tween.tween_property(visuals[unit.unit_id], "position", world(cell), 0.15)
	await tween.finished
	busy = false

func hit_feedback(target: Unit, damage: int) -> void:
	busy = true
	refresh()
	var number := Label3D.new()
	number.text = "-%d" % damage if damage > 0 else "MISS"
	number.font_size = 60
	number.pixel_size = 0.012
	number.modulate = Color("ffd28f")
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.position = world(target.grid_pos) + Vector3.UP * 3
	add_child(number)
	var tween := create_tween()
	tween.tween_property(number, "position:y", number.position.y + 1, 0.55)
	await tween.finished
	number.queue_free()
	busy = false

func enemy_turns() -> void:
	while sim.result.is_empty() and sim.active.team == "enemy":
		busy = true
		refresh()
		await get_tree().create_timer(0.45).timeout
		var actor: Unit = sim.active
		var target: Unit
		var closest := 999
		for unit: Unit in sim.units:
			if unit.team != "player" or unit.hp <= 0: continue
			var delta := unit.grid_pos - actor.grid_pos
			var distance := absi(delta.x) + absi(delta.y)
			if distance < closest:
				closest = distance
				target = unit
		if not target: break
		if not sim.can_attack(actor, target):
			var best := actor.grid_pos
			for cell: Vector2i in sim.reachable(actor):
				var delta := target.grid_pos - cell
				var distance := absi(delta.x) + absi(delta.y)
				if distance < closest:
					closest = distance
					best = cell
			var path: Array = sim.move_active(best)
			if not path.is_empty(): await animate_move(actor, path)
		var outcome: Dictionary = sim.attack_active(target)
		if not outcome.is_empty():
			message.text = outcome.message
			await hit_feedback(target, int(outcome.damage))
		sim.next_turn()
	busy = false
	refresh()

func capture() -> void:
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BLOOM_CAPTURE"))
	print("BLOOM_RENDER_CAPTURED")
	get_tree().quit()

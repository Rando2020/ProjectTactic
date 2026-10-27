extends Node3D
## Isolated presentation sandbox. NOVA should supply authoritative TacticalGrid data.
var data: Dictionary
var cells: Dictionary = {}
var token: MeshInstance3D
var current := Vector2i(2, 4)
var camera: Camera3D
var overlay: Node3D
var azimuth := 0.62
var status: Label

func cell_world(cell: Vector2i) -> Vector3:
	var entry: Dictionary = cells[cell]
	var elevation := float(entry.height)
	if entry.model == "stairs": elevation = 0.5
	return Vector3((cell.x - 2) * 2, elevation, (cell.y - 2) * 2)

func can_step(from: Vector2i, to: Vector2i) -> bool:
	if not cells.has(from) or not cells.has(to): return false
	if bool(cells[from].blocked) or bool(cells[to].blocked): return false
	if absi(from.x - to.x) + absi(from.y - to.y) != 1: return false
	# The stair has only north/south entry, even at its lower height.
	if (cells[from].model == "stairs" or cells[to].model == "stairs") and from.x != to.x: return false
	if int(cells[from].height) == int(cells[to].height): return true
	for link in data.explicit_links:
		var a := Vector2i(int(link[0][0]), int(link[0][1]))
		var b := Vector2i(int(link[1][0]), int(link[1][1]))
		if (from == a and to == b) or (from == b and to == a): return true
	return false

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/grid.json"))
	overlay = Node3D.new()
	add_child(overlay)
	for entry in data.cells:
		var key := Vector2i(int(entry.x), int(entry.z))
		cells[key] = entry
	for key in cells:
		var entry: Dictionary = cells[key]
		var ground := load("res://models/%s.glb" % entry.model) as PackedScene
		assert(ground != null)
		var instance := ground.instantiate() as Node3D
		add_child(instance)
		# high_ground includes its full 1m rise; do not add cell height twice.
		instance.position = Vector3((key.x - 2) * 2, 0, (key.y - 2) * 2)
		if entry.has("prop"):
			var prop := (load("res://models/%s.glb" % entry.prop) as PackedScene).instantiate() as Node3D
			add_child(prop)
			prop.position = cell_world(key)
		var mark := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.86, 0.012, 1.86)
		mark.mesh = box
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1, 0.2, 0.2, 0.2) if entry.blocked else Color(0.3, 0.8, 1, 0.12)
		mark.material_override = material
		overlay.add_child(mark)
		mark.position = cell_world(key) + Vector3(0, 0.035, 0)
		# Midpoint marker only on stairs so it doesn't cut through their risers.
		if entry.model == "stairs": box.size = Vector3(1.6, 0.012, 0.08)
	token = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	token.mesh = sphere
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1, 0.65, 0.1)
	token.material_override = gold
	add_child(token)
	token.position = cell_world(current) + Vector3(0, 0.25, 0)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14
	camera.current = true
	add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.14, 0.12, 0.19)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.75, 0.69, 0.85)
	world.environment.ambient_light_energy = 0.65
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(20, 20)
	status.text = "ACT 1 / 3D TILE BRIDGE\nArrows: test token • G: grid overlay • A/D: orbit\nRed cells: blocked • Stairs connect to raised stone\nPresentation sandbox; no combat or physics collision"
	layer.add_child(status)
	update_camera()

func update_camera() -> void:
	camera.position = Vector3(sin(azimuth) * 17, 14, cos(azimuth) * 17)
	camera.look_at(Vector3(0, 0.4, 0))

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_A): azimuth -= delta * 0.7
	if Input.is_physical_key_pressed(KEY_D): azimuth += delta * 0.7
	update_camera()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var step := Vector2i.ZERO
	match event.keycode:
		KEY_UP: step = Vector2i(0, -1)
		KEY_DOWN: step = Vector2i(0, 1)
		KEY_LEFT: step = Vector2i(-1, 0)
		KEY_RIGHT: step = Vector2i(1, 0)
		KEY_G: overlay.visible = not overlay.visible
	if can_step(current, current + step):
		current += step
		token.position = cell_world(current) + Vector3(0, 0.25, 0)

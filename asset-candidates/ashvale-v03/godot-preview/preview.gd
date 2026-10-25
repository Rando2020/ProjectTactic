extends Node3D

var camera: Camera3D
var azimuth := 0.62
var distance := 13.0

func _ready() -> void:
	var model := load("res://models/SC_chapel_approach.glb") as PackedScene
	assert(model != null)
	add_child(model.instantiate())
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	update_camera()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color(1, 0.79, 0.58)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 145, 0)
	fill.light_color = Color(0.32, 0.53, 1)
	fill.light_energy = 0.75
	add_child(fill)
	for x in [-1.16, 1.16]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 1.85, -1.12)
		light.light_color = Color(1, 0.25, 0.035)
		light.light_energy = 2.3
		light.omni_range = 3
		add_child(light)
	var world := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.035, 0.055, 0.085)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.36, 0.47, 0.65)
	settings.ambient_light_energy = 0.5
	world.environment = settings
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "ASHVALE / CHAPEL APPROACH\nA / D: orbit   W / S: zoom\nEnvironment art candidate — no combat or collision"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	layer.add_child(label)

func update_camera() -> void:
	camera.position = Vector3(sin(azimuth) * 16, 12, cos(azimuth) * 16)
	camera.look_at(Vector3(0, 1, -0.3))
	camera.size = distance

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_A): azimuth -= delta * 0.7
	if Input.is_physical_key_pressed(KEY_D): azimuth += delta * 0.7
	if Input.is_physical_key_pressed(KEY_W): distance = maxf(6, distance - delta * 4)
	if Input.is_physical_key_pressed(KEY_S): distance = minf(20, distance + delta * 4)
	update_camera()

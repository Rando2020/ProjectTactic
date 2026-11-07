extends Node3D
var camera: Camera3D
var angle := 0.61
func _ready() -> void:
	var scene := load("res://models/courtyard-section.glb") as PackedScene
	assert(scene != null)
	add_child(scene.instantiate())
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.5
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-30,0)
	sun.light_color = Color(1,.88,.75)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(.16,.15,.18)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(.72,.68,.85)
	world.environment.ambient_light_energy = .55
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "COURTYARD / TEXTURED MESH STUDY\nA / D: orbit • W / S: zoom\nArt study — no movement or collision"
	label.position = Vector2(20,20)
	layer.add_child(label)
	update_camera()
func update_camera() -> void:
	camera.position = Vector3(sin(angle)*12,9,cos(angle)*12)
	camera.look_at(Vector3(0,.4,0))
func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_A): angle -= delta*.6
	if Input.is_physical_key_pressed(KEY_D): angle += delta*.6
	if Input.is_physical_key_pressed(KEY_W): camera.size = maxf(3,camera.size-delta*2)
	if Input.is_physical_key_pressed(KEY_S): camera.size = minf(12,camera.size+delta*2)
	update_camera()

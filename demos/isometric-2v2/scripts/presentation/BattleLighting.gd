extends RefCounted

# Shared miniature-stage lighting for terrain and character viewports.
static func install(viewport: SubViewport) -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -35, 0)
	key.light_color = Color("ffdfb3")
	key.light_energy = 1.1
	key.shadow_enabled = true
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_color = Color("8aaacf")
	fill.light_energy = 0.35
	viewport.add_child(fill)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a6b6c8")
	world.environment.ambient_light_energy = 0.45
	viewport.add_child(world)

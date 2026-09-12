extends Node3D

## Authored presentation prototype for the first Ashvale hybrid battlefield.
## This scene is intentionally visual-only: the existing tactical grid remains authoritative.

const TILE_SPACING := 2.0
const TILE_ORIGIN := Vector3(-7.0, 0.0, -5.0)

const TERRAIN := {
	"grass": "res://assets/3d/ashvale/grass-flat.obj",
	"dirt": "res://assets/3d/ashvale/dirt-path-straight.obj",
	"water": "res://assets/3d/ashvale/shallow-water.obj",
	"raised": "res://assets/3d/ashvale/grass-raised.obj",
	"stairs": "res://assets/3d/ashvale/stone-stairs.obj",
	"stone": "res://assets/3d/ashvale/stone-flat.obj",
	"scorch": "res://assets/3d/ashvale/scorched-ground.obj",
	"bridge": "res://assets/3d/ashvale/wood-bridge.obj",
}

const UNITS := [
	{"name":"Zane", "texture":"res://assets/sprites/units/zane-idle-isometric.png", "pos":Vector3(-5.0, 0.34, 5.0)},
	{"name":"Mira", "texture":"res://assets/sprites/units/mira-idle-isometric.png", "pos":Vector3(-3.0, 0.34, 5.0)},
	{"name":"Kael", "texture":"res://assets/sprites/units/kael-idle-isometric.png", "pos":Vector3(-5.0, 0.34, 3.0)},
	{"name":"Lyra", "texture":"res://assets/sprites/units/lyra-idle-isometric.png", "pos":Vector3(-3.0, 0.34, 3.0)},
	{"name":"NullDrake", "texture":"res://assets/sprites/units/null-drake-idle-isometric.png", "pos":Vector3(5.0, 1.15, -5.0)},
	{"name":"StormImp", "texture":"res://assets/sprites/units/storm-imp-idle-isometric.png", "pos":Vector3(5.0, 0.34, -3.0)},
	{"name":"VoidCultist", "texture":"res://assets/sprites/units/void-cultist-idle-isometric.png", "pos":Vector3(3.0, 0.34, -5.0)},
]

const PROPS := [
	{"name":"RuinedWallA", "mesh":"res://assets/3d/ashvale/ruined-wall-short.obj", "pos":Vector3(4.0, 0.28, -5.0), "rot":0.0},
	{"name":"RuinedWallB", "mesh":"res://assets/3d/ashvale/ruined-wall-corner.obj", "pos":Vector3(6.0, 0.28, -3.0), "rot":90.0},
	{"name":"Arch", "mesh":"res://assets/3d/ashvale/stone-arch.obj", "pos":Vector3(4.0, 0.28, -3.0), "rot":0.0},
	{"name":"DeadTree", "mesh":"res://assets/3d/ashvale/dead-tree.obj", "pos":Vector3(-6.2, 0.28, -4.7), "rot":-12.0},
	{"name":"Cart", "mesh":"res://assets/3d/ashvale/broken-cart.obj", "pos":Vector3(-4.4, 0.28, 2.9), "rot":24.0},
	{"name":"Brazier", "mesh":"res://assets/3d/ashvale/brazier.obj", "pos":Vector3(3.8, 0.28, -1.0), "rot":0.0},
	{"name":"BushA", "mesh":"res://assets/3d/ashvale/bush.obj", "pos":Vector3(-6.2, 0.28, 0.8), "rot":0.0},
	{"name":"BushB", "mesh":"res://assets/3d/ashvale/bush.obj", "pos":Vector3(6.0, 0.28, 3.3), "rot":0.0},
	{"name":"Crate", "mesh":"res://assets/3d/ashvale/crate.obj", "pos":Vector3(4.8, 0.28, -4.5), "rot":12.0},
	{"name":"Grave", "mesh":"res://assets/3d/ashvale/gravestone.obj", "pos":Vector3(6.2, 0.28, 0.8), "rot":-8.0},
]

const LAYOUT := [
	["grass","grass","grass","water","grass","stone","raised","grass"],
	["grass","dirt","grass","water","grass","stone","stairs","grass"],
	["grass","dirt","grass","water","dirt","dirt","grass","grass"],
	["grass","dirt","grass","bridge","dirt","scorch","grass","grass"],
	["grass","dirt","dirt","water","dirt","grass","grass","grass"],
	["grass","grass","grass","water","grass","grass","grass","grass"],
]


func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_props()
	_build_tactical_markers()
	_build_units()
	_build_hud()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.045, 0.055, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.38, 0.43, 0.48, 1.0)
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.18, 0.21, 0.22, 1.0)
	environment.fog_light_energy = 0.45
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.name = "WarmKey"
	sun.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	sun.light_color = Color(1.0, 0.84, 0.66, 1.0)
	sun.light_energy = 1.22
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "CoolFill"
	fill.rotation_degrees = Vector3(-68.0, 132.0, 0.0)
	fill.light_color = Color(0.32, 0.42, 0.58, 1.0)
	fill.light_energy = 0.34
	add_child(fill)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.5
	camera.position = Vector3(13.5, 14.0, 15.5)
	camera.rotation_degrees = Vector3(-35.0, 40.0, 0.0)
	camera.current = true
	add_child(camera)


func _build_terrain() -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "Terrain"
	add_child(terrain_root)
	for row in range(LAYOUT.size()):
		var line: Array = LAYOUT[row]
		for column in range(line.size()):
			var kind: String = str(line[column])
			var instance := _mesh_instance("Tile_%d_%d_%s" % [row, column, kind], TERRAIN[kind])
			if not instance:
				continue
			instance.position = TILE_ORIGIN + Vector3(column * TILE_SPACING, 0.0, row * TILE_SPACING)
			terrain_root.add_child(instance)


func _build_props() -> void:
	var props_root := Node3D.new()
	props_root.name = "Props"
	add_child(props_root)
	for spec in PROPS:
		var instance := _mesh_instance(str(spec["name"]), str(spec["mesh"]))
		if not instance:
			continue
		instance.position = spec["pos"]
		instance.rotation_degrees.y = float(spec["rot"])
		props_root.add_child(instance)


func _mesh_instance(node_name: String, resource_path: String) -> MeshInstance3D:
	var resource: Resource = load(resource_path)
	if not resource is Mesh:
		push_error("Ashvale mock could not load Mesh: %s" % resource_path)
		return null
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = resource as Mesh
	return instance


func _build_units() -> void:
	var units_root := Node3D.new()
	units_root.name = "Units"
	add_child(units_root)
	for spec in UNITS:
		var texture: Resource = load(str(spec["texture"]))
		if not texture is Texture2D:
			push_error("Ashvale mock could not load unit texture: %s" % str(spec["texture"]))
			continue
		var sprite := Sprite3D.new()
		sprite.name = str(spec["name"])
		sprite.position = spec["pos"]
		sprite.texture = texture as Texture2D
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.009
		sprite.shaded = false
		units_root.add_child(sprite)


func _build_tactical_markers() -> void:
	var markers := Node3D.new()
	markers.name = "TacticalMarkers"
	add_child(markers)
	_add_marker(markers, "Selected_Zane", Vector3(-5.0, 0.29, 5.0), Color(0.92, 0.72, 0.25, 0.34), 0.72, 32)
	for cell in [Vector3(-3.0, 0.29, 3.0), Vector3(-1.0, 0.29, 3.0), Vector3(-3.0, 0.29, 1.0)]:
		_add_marker(markers, "Move", cell, Color(0.18, 0.55, 0.95, 0.26), 0.82, 4)
	for cell in [Vector3(5.0, 1.10, -5.0), Vector3(5.0, 0.29, -3.0)]:
		_add_marker(markers, "Attack", cell, Color(0.90, 0.18, 0.12, 0.25), 0.82, 4)


func _add_marker(parent: Node3D, marker_name: String, marker_position: Vector3, color: Color,
		radius: float, segments: int) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.035
	mesh.radial_segments = segments
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = marker_name
	instance.position = marker_position
	instance.mesh = mesh
	parent.add_child(instance)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(24.0, 20.0)
	title.size = Vector2(520.0, 38.0)
	title.text = "ASHVALE  •  THE BROKEN ROAD"
	title.add_theme_color_override("font_color", Color(0.92, 0.84, 0.65, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	hud.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.position = Vector2(26.0, 56.0)
	subtitle.size = Vector2(650.0, 26.0)
	subtitle.text = "Hybrid 3D terrain + isometric unit sprites • presentation prototype"
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76, 1.0))
	subtitle.add_theme_font_size_override("font_size", 13)
	hud.add_child(subtitle)

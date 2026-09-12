class_name Ashvale3DBackdrop
extends Node2D

## Presentation-only 3D renderer for the authored Ashvale debug encounter.
## The existing TacticalGrid remains authoritative for input, movement, height,
## targeting, highlights, units, combat and saves. This node renders terrain to
## a transparent SubViewport and places that texture between the legacy terrain
## and the existing highlight/unit layers.

@export var enabled: bool = true
@export var ashvale_map_id: String = "ashvale_road_01"
@export var render_size: Vector2i = Vector2i(1024, 768)

const TILE_WORLD: float = 2.0
const MODEL_HEIGHT_STEP: float = 0.82
const BASE_TILE_TOP_Y: float = 0.26
const CAMERA_PITCH_DEG: float = 30.0
const CAMERA_HORIZONTAL_DISTANCE: float = 24.0
const KIT_ROOT: String = "res://assets/3d/ashvale/"

const TERRAIN_MESHES := {
	"grass": "grass-flat.obj",
	"grass_flowers": "grass-flat.obj",
	"brush": "grass-flat.obj",
	"road": "dirt-flat.obj",
	"stone": "stone-flat.obj",
	"high_ground": "stone-flat.obj",
	"shallow_water": "shallow-water.obj",
	"burning": "scorched-ground.obj",
	"scorched": "scorched-ground.obj",
	"shrine": "stone-flat.obj",
}

const PROP_MESHES := {
	"leafy_bush": "bush.obj",
	"tree_stump": "dead-tree.obj",
	"ruin_block": "ruined-wall-short.obj",
	"mossy_rock": "broken-pillar.obj",
}

var _viewport: SubViewport
var _visual_root: Node3D
var _camera: Camera3D
var _texture_sprite: Sprite2D
var _mesh_cache: Dictionary = {}
var _configured: bool = false
var _height_visual_scale: float = 1.0


func _ready() -> void:
	visible = false
	call_deferred("_attach_after_battle_setup")


func _attach_after_battle_setup() -> void:
	# BattleScene initializes the map in the parent's _ready(). Waiting one frame
	# keeps this renderer entirely presentation-only and avoids a dependency on
	# BattleScene's initialization order.
	await get_tree().process_frame
	if not enabled or DisplayServer.get_name() == "headless":
		return
	var grid: Node = get_node_or_null("../BattleManager/TacticalGrid")
	if grid == null or grid.get("map_data") == null:
		return
	var map_data: Resource = grid.get("map_data")
	if str(map_data.get("id")) != ashvale_map_id:
		return
	configure(map_data, grid)


func configure(map_data: Resource, grid: Node) -> void:
	if _configured:
		return
	_build_render_world()
	_build_map(map_data, grid)
	_position_texture(map_data, grid)
	_configure_camera(map_data, grid)
	visible = true
	_configured = true
	# The Ashvale backdrop is static. Render it once, then let Camera2D move and
	# zoom the resulting Sprite2D with the rest of the tactical canvas.
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func refresh() -> void:
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _build_render_world() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "AshvaleTerrainViewport"
	_viewport.size = render_size
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	_visual_root = Node3D.new()
	_visual_root.name = "TerrainRoot"
	_viewport.add_child(_visual_root)

	var key := DirectionalLight3D.new()
	key.name = "WarmKey"
	key.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	key.light_color = Color(1.0, 0.86, 0.72, 1.0)
	key.light_energy = 1.18
	key.shadow_enabled = true
	_viewport.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.name = "CoolFill"
	fill.rotation_degrees = Vector3(-32.0, 146.0, 0.0)
	fill.light_color = Color(0.48, 0.58, 0.78, 1.0)
	fill.light_energy = 0.42
	fill.shadow_enabled = false
	_viewport.add_child(fill)

	_camera = Camera3D.new()
	_camera.name = "AshvaleCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_viewport.add_child(_camera)

	_texture_sprite = Sprite2D.new()
	_texture_sprite.name = "Ashvale3DTexture"
	_texture_sprite.centered = true
	_texture_sprite.texture = _viewport.get_texture()
	_texture_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_texture_sprite)


func _build_map(map_data: Resource, grid: Node) -> void:
	var tile_size: Vector2 = Vector2(grid.get("tile_size"))
	var height_step: float = float(grid.get("height_step"))
	var pixels_per_world := (tile_size.x * 0.5) / (TILE_WORLD / sqrt(2.0))
	var vertical_pixels_per_world := pixels_per_world * cos(deg_to_rad(CAMERA_PITCH_DEG))
	_height_visual_scale = height_step / max(MODEL_HEIGHT_STEP * vertical_pixels_per_world, 0.001)
	_visual_root.scale = Vector3(1.0, _height_visual_scale, 1.0)
	_visual_root.position.y = -BASE_TILE_TOP_Y * _height_visual_scale

	var width: int = int(map_data.get("map_width"))
	var height: int = int(map_data.get("map_height"))
	var tiles: Dictionary = grid.get("tiles")
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var tile: Dictionary = tiles.get(pos, {})
			_add_terrain_tile(pos, tile)

	var prop_overrides: Array = map_data.get("prop_overrides")
	for prop_data: Dictionary in prop_overrides:
		_add_map_prop(prop_data, tiles)


func _add_terrain_tile(pos: Vector2i, tile: Dictionary) -> void:
	var terrain: String = str(tile.get("terrain", "grass"))
	var logical_height: int = int(tile.get("height", 0))
	var mesh_name: String = str(TERRAIN_MESHES.get(terrain, "grass-flat.obj"))
	var raised := logical_height > 0 and terrain in ["grass", "grass_flowers", "brush", "stone", "high_ground", "shrine"]
	if raised:
		mesh_name = "stone-raised.obj" if terrain in ["stone", "high_ground", "shrine"] else "grass-raised.obj"

	var instance := _make_mesh_instance(mesh_name)
	if instance == null:
		return
	var model_y := float(logical_height) * MODEL_HEIGHT_STEP
	if raised:
		model_y = float(logical_height - 1) * MODEL_HEIGHT_STEP
	instance.position = Vector3(float(pos.x) * TILE_WORLD, model_y, float(pos.y) * TILE_WORLD)
	_visual_root.add_child(instance)

	if terrain == "brush":
		_add_decorative_prop("bush.obj", pos, logical_height, 0.56, 0.0)
	elif terrain == "shrine":
		_add_decorative_prop("brazier.obj", pos, logical_height, 0.78, 0.0)


func _add_map_prop(prop_data: Dictionary, tiles: Dictionary) -> void:
	var prop_name: String = str(prop_data.get("prop", ""))
	if not PROP_MESHES.has(prop_name):
		return
	var pos := Vector2i(int(prop_data.get("x", 0)), int(prop_data.get("y", 0)))
	var tile: Dictionary = tiles.get(pos, {})
	var logical_height: int = int(tile.get("height", 0))
	var rotation := float((pos.x * 37 + pos.y * 53) % 4) * 90.0
	var scale_value := 0.72 if prop_name in ["leafy_bush", "tree_stump"] else 0.82
	_add_decorative_prop(str(PROP_MESHES[prop_name]), pos, logical_height, scale_value, rotation)


func _add_decorative_prop(mesh_name: String, pos: Vector2i, logical_height: int,
		scale_value: float, rotation_y: float) -> void:
	var instance := _make_mesh_instance(mesh_name)
	if instance == null:
		return
	instance.position = Vector3(
		float(pos.x) * TILE_WORLD,
		BASE_TILE_TOP_Y + float(logical_height) * MODEL_HEIGHT_STEP,
		float(pos.y) * TILE_WORLD
	)
	instance.rotation_degrees.y = rotation_y
	instance.scale = Vector3.ONE * scale_value
	_visual_root.add_child(instance)


func _make_mesh_instance(mesh_name: String) -> MeshInstance3D:
	var mesh := _load_mesh(KIT_ROOT + mesh_name)
	if mesh == null:
		return null
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance


func _load_mesh(path: String) -> Mesh:
	if _mesh_cache.has(path):
		return _mesh_cache[path] as Mesh
	var resource := load(path)
	var mesh := resource as Mesh
	_mesh_cache[path] = mesh
	return mesh


func _configure_camera(map_data: Resource, grid: Node) -> void:
	var width: float = float(int(map_data.get("map_width")))
	var height: float = float(int(map_data.get("map_height")))
	var center_x := (width - 1.0) * 0.5
	var center_y := (height - 1.0) * 0.5
	var target := Vector3(center_x * TILE_WORLD, 0.0, center_y * TILE_WORLD)
	var side := CAMERA_HORIZONTAL_DISTANCE / sqrt(2.0)
	var camera_height := CAMERA_HORIZONTAL_DISTANCE * tan(deg_to_rad(CAMERA_PITCH_DEG))
	_camera.position = target + Vector3(side, camera_height, side)
	_camera.look_at(target, Vector3.UP)

	var tile_size: Vector2 = Vector2(grid.get("tile_size"))
	var pixels_per_world := (tile_size.x * 0.5) / (TILE_WORLD / sqrt(2.0))
	_camera.size = float(render_size.y) / pixels_per_world


func _position_texture(map_data: Resource, grid: Node) -> void:
	var width: float = float(int(map_data.get("map_width")))
	var height: float = float(int(map_data.get("map_height")))
	var center_x := (width - 1.0) * 0.5
	var center_y := (height - 1.0) * 0.5
	var tile_size: Vector2 = Vector2(grid.get("tile_size"))
	var map_origin: Vector2 = Vector2(grid.get("map_origin"))
	_texture_sprite.position = map_origin + Vector2(
		(center_x - center_y) * tile_size.x * 0.5,
		(center_x + center_y) * tile_size.y * 0.5
	)

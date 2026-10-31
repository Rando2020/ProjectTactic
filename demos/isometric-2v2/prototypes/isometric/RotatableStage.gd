extends Node2D
## Presentation only: one shared orthographic world for terrain, actor cards and ranges.
## The tactical grid and BattleManager remain the sole rules/turn authority.
const TILE_WORLD := 2.0
const PIXELS_PER_WORLD := 52.0
const VIEW_CENTER := Vector2(500, 400)
const RENDER_SIZE := Vector2i(1536, 1024)
const KIT_ROOT := "res://assets/3d/ashvale/"
var grid: TacticalGrid
var quarter_turn := 0
var camera: Camera3D
var viewport: SubViewport
var world_root: Node3D
var terrain_root: Node3D
var actor_root: Node3D
var range_root: Node3D
var texture_sprite: Sprite2D
var _actors: Dictionary = {}
var _ranges_signature := ""
var _terrain_signature := ""
var missing_meshes: Array[String] = []

func configure(p_grid: TacticalGrid) -> void:
	grid = p_grid
	z_index = -10
	viewport = SubViewport.new()
	viewport.name = "RotatableStageViewport"
	viewport.size = RENDER_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world_root = Node3D.new()
	viewport.add_child(world_root)
	terrain_root = Node3D.new()
	world_root.add_child(terrain_root)
	actor_root = Node3D.new()
	world_root.add_child(actor_root)
	range_root = Node3D.new()
	world_root.add_child(range_root)
	preload("res://scripts/presentation/BattleLighting.gd").install(viewport)
	# Soft miniature lighting: legibility first, rather than hard billboard shadows.
	for light in viewport.get_children():
		if light is DirectionalLight3D:
			light.shadow_enabled = false
			light.light_energy *= 0.82
		elif light is WorldEnvironment:
			light.environment.ambient_light_color = Color("d8d2c0")
			light.environment.ambient_light_energy = 0.72
	camera = Camera3D.new()
	camera.name = "RotatableCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = RENDER_SIZE.y / PIXELS_PER_WORLD
	camera.near = 0.1
	camera.far = 100.0
	camera.current = true
	viewport.add_child(camera)
	texture_sprite = Sprite2D.new()
	texture_sprite.texture = viewport.get_texture()
	texture_sprite.position = VIEW_CENTER
	add_child(texture_sprite)
	set_angle(0)
	_build_terrain()
	_sync_ranges()

func set_angle(index: int) -> void:
	quarter_turn = posmod(index, 4)
	if not is_instance_valid(camera): return
	var yaw := deg_to_rad(45.0 + quarter_turn * 90.0)
	var target := Vector3(4, 0, 4)
	camera.position = target + Vector3(sin(yaw)*24.0, 24.0*tan(deg_to_rad(30.0)), cos(yaw)*24.0)
	camera.look_at(target, Vector3.UP)

func projected_point(cell: Vector2) -> Vector2:
	if not is_instance_valid(camera): return VIEW_CENTER
	return VIEW_CENTER + camera.unproject_position(Vector3(cell.x*TILE_WORLD,0,cell.y*TILE_WORLD)) - Vector2(RENDER_SIZE)*0.5

func unproject_ground(local: Vector2) -> Vector2:
	if not is_instance_valid(camera): return Vector2.ZERO
	var pixel := local - VIEW_CENTER + Vector2(RENDER_SIZE)*0.5
	var origin := camera.project_ray_origin(pixel)
	var ray := camera.project_ray_normal(pixel)
	if absf(ray.y) < 0.0001: return Vector2.ZERO
	var p := origin + ray * (-origin.y / ray.y)
	return Vector2(p.x, p.z) / TILE_WORLD

func _process(_delta: float) -> void:
	if not is_instance_valid(grid) or not is_instance_valid(viewport): return
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	if not is_visible_in_tree(): return
	_sync_actors()
	_sync_ranges()
	var signature := str(grid.tiles)
	if signature != _terrain_signature:
		_build_terrain()

func _mesh(piece: String, at: Vector3, scale_value := Vector3.ONE, yaw := 0.0) -> MeshInstance3D:
	var path := KIT_ROOT + piece
	if not ResourceLoader.exists(path):
		missing_meshes.append(piece)
		return null
	var m := MeshInstance3D.new()
	m.mesh = load(path) as Mesh
	m.position = at
	m.scale = scale_value
	m.rotation_degrees.y = yaw
	terrain_root.add_child(m)
	return m

func _build_terrain() -> void:
	for child in terrain_root.get_children():
		terrain_root.remove_child(child)
		child.queue_free()
	missing_meshes.clear()
	_terrain_signature = str(grid.tiles)
	# A continuous chamfer-like stepped plinth ties all ornament to one diorama.
	# The gold rim makes the legal 5x5 floor boundary distinct from decorative stone.
	_box(Vector3(4,-1.0,4),Vector3(11.4,0.7,11.4),Color("484a46"))
	_box(Vector3(4,-0.57,4),Vector3(10.9,0.16,10.9),Color("777868"))
	_box(Vector3(4,-0.37,4),Vector3(10.5,0.28,10.5),Color("565b52"))
	for cell: Vector2i in grid.tiles:
		var terrain: String = str(grid.tiles[cell].get("terrain", "stone"))
		var burned := terrain in ["burning", "scorched"]
		var instance := _mesh("stone-flat.obj", Vector3(cell.x*TILE_WORLD,-0.26,cell.y*TILE_WORLD))
		if instance: instance.material_override = _stone_material(Color("403c36") if burned else Color("777d72"))
		# Four softly varying pavers within each logical tile; wide outer seams still
		# expose the tactical grid. These are geometry, not a fixed painted camera.
		for sy in 2:
			for sx in 2:
				var variation := float(posmod(cell.x*31+cell.y*17+sx*13+sy*7,11))/110.0
				var color := Color("34312d") if burned else Color("9a9a86").lightened(variation)
				var center := Vector3(cell.x*TILE_WORLD+(sx-0.5)*0.95,0.002,cell.y*TILE_WORLD+(sy-0.5)*0.95)
				_box(center,Vector3(0.918,0.014,0.918),color)
		# Small irregular seams and chips add wear without noisy high-contrast texture.
		if (cell.x+cell.y*3)%3 == 0:
			var start := Vector3(cell.x*TILE_WORLD-0.75,0.011,cell.y*TILE_WORLD+0.23)
			_stone_line(start,start+Vector3(0.37,0,-0.16),Color("696e60"),0.018)
			_stone_line(start+Vector3(0.37,0,-0.16),start+Vector3(0.53,0,0.04),Color("696e60"),0.015)
		if not burned and (cell.x==0 or cell.y==0 or cell.x==4 or cell.y==4) and (cell.x+cell.y)%2 == 0:
			var p := Vector3(cell.x*TILE_WORLD-0.7,0.012,cell.y*TILE_WORLD-0.62)
			_moss_chip(p,0.22)
			_moss_chip(p+Vector3(0.2,0,0.14),0.12)
	# Low outside coping, connected to the same foundation, never an extra legal tile.
	for edge in [-1.25,9.25]:
		_box(Vector3(4,-0.04,edge),Vector3(10.5,0.32,0.48),Color("7e8273"))
		_box(Vector3(edge,-0.04,4),Vector3(0.48,0.32,10.5),Color("7e8273"))
		_box(Vector3(4,0.126,edge),Vector3(9.8,0.012,0.045),Color("b6a679"))
		_box(Vector3(edge,0.126,4),Vector3(0.045,0.012,9.8),Color("b6a679"))
		for other in [-1.25,9.25]:
			_box(Vector3(edge,0.12,other),Vector3(0.66,0.65,0.66),Color("858975"))
			_box(Vector3(edge,0.48,other),Vector3(0.78,0.12,0.78),Color("aaa38a"))
	# Two grounded remnants retain the chapel identity; short enough to leave
	# tactical silhouettes visible from opposite camera angles.
	for p in [Vector3(1.3,0.12,-1.25),Vector3(6.7,0.12,9.25)]:
		var wall := _mesh("ruined-wall-short.obj",p,Vector3(0.42,0.32,0.28),0)
		if wall: wall.material_override = _stone_material(Color("90927e"))

func _stone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func _box(at: Vector3, size_value: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = _stone_material(color)
	terrain_root.add_child(node)

func _stone_line(start: Vector3, end: Vector3, color: Color, width: float) -> void:
	var length := start.distance_to(end)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width,0.002,length)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = (start+end)*0.5
	node.rotation.y = atan2(end.x-start.x,end.z-start.z)
	node.material_override = _stone_material(color)
	terrain_root.add_child(node)

func _moss_chip(at: Vector3, radius: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(-radius,0,-radius*0.3),Vector3(radius*0.4,0,-radius*0.7),Vector3(radius,0,radius*0.2),Vector3(-radius*0.1,0,radius)]
	for index in [0,2,1,0,3,2]:
		surface.set_normal(Vector3.UP)
		surface.add_vertex(points[index])
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.position = at
	node.material_override = _stone_material(Color("667153"))
	terrain_root.add_child(node)

func _sync_actors() -> void:
	var alive: Dictionary = {}
	for child in grid.unit_layer.get_children():
		var unit := child as Unit
		if not is_instance_valid(unit) or unit.is_queued_for_deletion() or unit.hp <= 0: continue
		var source: Sprite2D = unit._sprite
		if not is_instance_valid(source) or source.texture == null: continue
		alive[unit.unit_id] = true
		var proxy: Sprite3D = _actors.get(unit.unit_id)
		if not is_instance_valid(proxy):
			proxy = Sprite3D.new()
			proxy.name = "Actor_" + unit.unit_id
			proxy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			proxy.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
			proxy.alpha_scissor_threshold = 0.12
			proxy.shaded = false
			proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			proxy.double_sided = true
			proxy.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			actor_root.add_child(proxy)
			_actors[unit.unit_id] = proxy
		var point := unproject_ground(unit.position)
		proxy.position = Vector3(point.x*TILE_WORLD,0.025,point.y*TILE_WORLD)
		proxy.texture = source.texture
		proxy.pixel_size = 1.0 / PIXELS_PER_WORLD
		proxy.scale = Vector3(source.scale.x*unit.scale.x,source.scale.y*unit.scale.y,1)
		# 3D card y goes up; Sprite2D positions and offsets go down.
		proxy.offset = Vector2(source.offset.x + source.position.x/maxf(absf(source.scale.x),0.001), -source.offset.y - source.position.y/maxf(absf(source.scale.y),0.001))
		proxy.flip_h = source.flip_h
		proxy.flip_v = source.flip_v
		proxy.modulate = source.modulate * source.self_modulate * unit.modulate * unit.self_modulate
		proxy.visible = unit.visible
	for id in _actors.keys():
		if not alive.has(id):
			var proxy: Sprite3D = _actors[id]
			if is_instance_valid(proxy): proxy.queue_free()
			_actors.erase(id)

func _sync_ranges() -> void:
	var signature := str([grid.move_tiles,grid.attack_tiles,grid.ability_tiles,grid.aoe_preview_tiles,grid.path_preview_tiles,grid.active_unit_tile,grid.active_unit_team,grid.selected_tile,grid.target_tile])
	if signature == _ranges_signature: return
	_ranges_signature = signature
	for child in range_root.get_children():
		range_root.remove_child(child)
		child.queue_free()
	for cell in grid.move_tiles: _range_tile(cell,Color(0.05,0.8,1,0.36),0.88,0.012)
	for cell in grid.attack_tiles: _range_tile(cell,Color(1,0.35,0.12,0.42),0.88,0.014)
	for cell in grid.ability_tiles: _range_tile(cell,Color(0.65,0.28,1,0.4),0.88,0.016)
	for cell in grid.aoe_preview_tiles: _range_tile(cell,Color(1,0.15,0.08,0.55),0.93,0.020)
	for cell in grid.path_preview_tiles: _range_tile(cell,Color(0.2,1,0.8,0.65),0.4,0.024)
	if grid.tiles.has(grid.active_unit_tile):
		_range_border(grid.active_unit_tile,Color("80d9ff") if grid.active_unit_team == "player" else Color("ff9a7e"),0.95,0.029)
	if grid.tiles.has(grid.selected_tile): _range_border(grid.selected_tile,Color("fff2c5"),0.83,0.033)
	if grid.tiles.has(grid.target_tile): _range_border(grid.target_tile,Color("ffdf80"),0.68,0.037)

func _range_tile(cell: Vector2i, color: Color, fraction: float, y: float) -> void:
	if not grid.tiles.has(cell): return
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*TILE_WORLD*fraction
	var node := MeshInstance3D.new()
	node.mesh = plane
	node.position = Vector3(cell.x*TILE_WORLD,y,cell.y*TILE_WORLD)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = _range_material(color)
	range_root.add_child(node)

func _range_border(cell: Vector2i, color: Color, fraction: float, y: float) -> void:
	var half := TILE_WORLD*fraction*0.5
	for side in range(4):
		var plane := PlaneMesh.new()
		plane.size = Vector2(TILE_WORLD*fraction,0.035) if side < 2 else Vector2(0.035,TILE_WORLD*fraction)
		var node := MeshInstance3D.new()
		node.mesh = plane
		node.position = Vector3(cell.x*TILE_WORLD,y,cell.y*TILE_WORLD)
		if side < 2: node.position.z += half * (-1 if side == 0 else 1)
		else: node.position.x += half * (-1 if side == 2 else 1)
		node.material_override = _range_material(color)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		range_root.add_child(node)

func _range_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

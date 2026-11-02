extends "res://demos/blooming_ruins/Stage.gd"
## Isolated visual acceptance scene. Production battle integration is a separate step.
const PACK := "res://assets/environments/blooming-ruins-v2/"
const SURFACES := preload("res://assets/environments/blooming-ruins-v2/surfaces.png")
const DISTANCE := preload("res://assets/environments/blooming-ruins-v2/distance.png")
var art_regions: Dictionary = {}
var art_textures: Dictionary = {}
var portrait: TextureRect

func build_materials() -> void:
	super.build_materials()
	for material in materials:
		material.set_shader_parameter("atlas", SURFACES)
	# Give stair treads the quiet coping surface rather than huge paving joints.
	materials[3].set_shader_parameter("ground", true)
	var shader: Shader = materials[0].shader
	shader.code = shader.code.replace("source_color;", "source_color, filter_linear_mipmap;")
	shader.code = shader.code.replace("ground ? world.xz*0.19", "abs(normal_world.y)>0.5 ? world.xz*0.19")
	shader.code = shader.code.replace("ROUGHNESS=1.0;", "if(abs(normal_world.y)<0.5){ALBEDO*=vec3(0.91,0.88,1.0);} ROUGHNESS=1.0;")

func build_world() -> void:
	super.build_world()
	camera.size = 28
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PACK + "manifest.json"))
	for entry: Dictionary in manifest.assets:
		if not entry.has("regions"): continue
		var texture := load(PACK + str(entry.file)) as Texture2D
		for key: String in entry.regions:
			art_regions[key] = entry.regions[key]
			art_textures[key] = texture
	# Remove only the old decorative sprites; unit sprites live beneath their own roots.
	for child in get_children():
		if child is Sprite3D:
			remove_child(child)
			child.queue_free()
		elif child is MeshInstance3D and child.mesh is BoxMesh:
			var dimensions: Vector3 = child.mesh.size
			if dimensions.x > 90:
				child.hide()
			elif dimensions.x < 3 and child.position.y > 1 and absf(child.position.x - 18) < 2 and absf(child.position.z + 0.6) < 0.1:
				child.hide() # replaced by painted gateway; objective diamond stays visible
			elif dimensions.z < 0.6 and dimensions.x == 2:
				child.material_override = materials[3]
	var backdrop := MeshInstance3D.new()
	backdrop.name = "DistantPaintedValley"
	var quad := QuadMesh.new()
	quad.size = Vector2(76, 44)
	backdrop.mesh = quad
	var backdrop_material := StandardMaterial3D.new()
	backdrop_material.albedo_texture = DISTANCE
	backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	backdrop.material_override = backdrop_material
	backdrop.transform = camera.transform
	backdrop.position = camera.position - camera.basis.z * 75
	add_child(backdrop)
	# Narrow scenery ledges ground the framing trees; they are outside the selectable grid.
	box(Vector3(-2, -1, 10), Vector3(2, 2, 22), materials[2])
	box(Vector3(24, -1, 10), Vector3(2, 2, 22), materials[2])
	# Fixed-camera scenery sits outside routes or on already blocked masonry cells.
	for x in [-2.0, 2.0, 6.0, 10.0, 14.0, 23.5]:
		place("cypress", Vector3(x, -0.4, -3), 0.014)
	for z in [5.0, 11.0, 17.0]:
		place("cypress", Vector3(-2, 0, z), 0.013)
		place("cypress", Vector3(24, 0, z), 0.014)
	for point in [Vector3(-1, 0, 7), Vector3(-1, 0, 18), Vector3(24, 0, 8)]:
		place("column", point, 0.010)
	for point in [Vector3(6, 0, 12), Vector3(16, 0, 12), Vector3(8, 1.95, 2)]:
		place("broken-column", point, 0.008)
	for point in [Vector3(-0.8, 1.95, 0), Vector3(13, 1.95, -1.0), Vector3(23.2, 0, 21)]:
		place("ruined-pier", point, 0.009)
	place("arch", world(Encounter.GATE) + Vector3(0, 0, -1.1), 0.012)
	place("banner", Vector3(15.0, 2.4, -0.7), 0.007)
	place("banner", Vector3(21.5, 2.4, -0.7), 0.007)
	place("banner", Vector3(-1.1, 0.7, 15), 0.007)
	for point in [Vector3(3, 1.95, 0), Vector3(22, 1.95, 1), Vector3(10, 0, 5)]:
		place("pots", point, 0.004)
	var random := RandomNumberGenerator.new()
	random.seed = 8051
	for cell: Vector2i in sim.tiles:
		var border := cell.x in [0, 11] or cell.y in [0, 10] or bool(sim.tiles[cell].blocked)
		if cell.x in [2, 9]: continue
		if border:
			for i in 3:
				var id := "pink-shrub" if i == 0 else "pink-flowers"
				place(id, world(cell) + Vector3(random.randf_range(-0.8, 0.8), 0.03, random.randf_range(-0.8, 0.8)), random.randf_range(0.0032, 0.0045))
		elif cell.y in [3, 7] and cell.x % 3 == 1:
			place("grass", world(cell) + Vector3(0.8, 0.03, 0.8), 0.0027)
	for x in [0, 3, 5, 7, 10, 11]:
		place("hanging-ivy", Vector3(x * 2, 1.8, 5.05), 0.0045)
		place("hanging-ivy", Vector3(x * 2, -0.05, 21.1), 0.0035)
	for point in [Vector3(6, 0, 14), Vector3(14, 0, 12), Vector3(22.8, 0, 15)]:
		place("rubble", point, 0.003)
	place("low-wall", Vector3(14, 0, 12), 0.004)
	place("cream-shrub", Vector3(22, 1.95, 2), 0.004)

func place(asset_id: String, at: Vector3, pixel_scale: float) -> Sprite3D:
	var region: Dictionary = art_regions[asset_id]
	var rect: Array = region.rect
	var prop := Sprite3D.new()
	prop.name = asset_id
	prop.texture = art_textures[asset_id]
	prop.region_enabled = true
	prop.region_rect = Rect2(rect[0], rect[1], rect[2], rect[3])
	prop.pixel_size = pixel_scale
	prop.offset.y = -float(rect[3]) * 0.5 if region.pivot == "top-center" else float(rect[3]) * 0.5
	prop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prop.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	prop.alpha_scissor_threshold = 0.5
	prop.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	prop.position = at
	add_child(prop)
	return prop

func build_ui() -> void:
	super.build_ui()
	var bottom: PanelContainer = info.get_parent().get_parent()
	bottom.offset_left = 190
	portrait = TextureRect.new()
	bottom.get_parent().add_child(portrait)
	portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait.offset_left = 18
	portrait.offset_right = 180
	portrait.offset_top = -172
	portrait.offset_bottom = -18
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := TextureRect.new()
	portrait.add_child(frame)
	frame.texture = load(PACK + "portrait-frame.svg")
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for action in buttons:
		buttons[action].theme = load(PACK + "bloom-theme.tres")
	var icons := {"Move": "move", "Attack": "attack", "Heal": "skill", "Wait": "wait"}
	for action in icons:
		buttons[action].icon = load(PACK + str(icons[action]) + ".svg")
		buttons[action].add_theme_constant_override("icon_max_width", 20)
	message.text = "ART PACK PREVIEW · Move / Attack / Heal / Wait · Wheel: zoom · R: restart"

func refresh() -> void:
	super.refresh()
	if portrait:
		portrait.texture = AssetRegistry.load_first_texture(AssetRegistry.get_character_portrait_candidates(sim.active.unit_id))

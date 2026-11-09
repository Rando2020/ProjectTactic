## Read-only, ticket-owned cosmetic playback. Does not resolve hits or costs.
extends Sprite2D
const ROOT := "res://prototypes/isometric/assets/melee/frames/"
const DURATIONS := {"slash":[0.05,0.065,0.065,0.08], "impact":[0.06,0.07,0.08,0.10]}
var effect := "slash"
var frame_index := 0
var elapsed := 0.0
var _frames: Array[Texture2D] = []
var _proxy: MeshInstance3D
var _material: StandardMaterial3D

func use_stage_depth(stage: Node3D, camera: Camera3D, ground: Vector3, pixels_per_world: float, height_pixels: float) -> void:
	# A camera-facing textured card IN the stage world, rather than an overlay
	# painted over every actor. Existing actor depth prepasses occlude rear arcs.
	_proxy = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1024,1024) * scale / pixels_per_world
	_proxy.mesh = quad
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_material.albedo_texture = texture
	_proxy.material_override = _material
	_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(_proxy)
	_proxy.global_basis = camera.global_basis * Basis(Vector3.BACK,-rotation)
	_proxy.global_position = ground + camera.global_basis.y * height_pixels / pixels_per_world
	if effect == "impact": _proxy.global_position += camera.global_basis.z * 0.04
	self_modulate.a = 0.0

func _exit_tree() -> void:
	if is_instance_valid(_proxy): _proxy.queue_free()


func configure(value: String, direction: Vector2 = Vector2.RIGHT) -> void:
	effect = value
	_frames.clear()
	for i in range(1,5):
		var path := ROOT + effect + "/%02d.png" % i
		if ResourceLoader.exists(path): _frames.append(load(path) as Texture2D)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The crescent bows right in source art. Rotate that forward axis into the
	# actual screen projection, not grid compass labels or a guessed hand socket.
	rotation = direction.angle() if effect == "slash" else 0.0
	scale = Vector2.ONE * (0.13 if effect == "slash" else 0.10)
	elapsed = 0.0
	show_progress(0.0)

func available() -> bool:
	return _frames.size() == 4 and not _frames.has(null)

func show_progress(seconds: float) -> void:
	var cursor := seconds
	frame_index = 0
	for duration in DURATIONS[effect]:
		if cursor < float(duration): break
		cursor -= float(duration)
		frame_index += 1
	if frame_index >= 4:
		frame_index = 3
		hide()
	elif available(): texture = _frames[frame_index]
	if is_instance_valid(_proxy):
		_proxy.visible = visible and not is_queued_for_deletion()
		_material.albedo_texture = texture

func _process(delta: float) -> void:
	elapsed += delta
	show_progress(elapsed)

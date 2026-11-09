## Presentation only. Unit and ActionLifecycle retain all gameplay authority.
## Phase sampling intentionally has no callbacks into combat or saved state.
extends Node2D

const MODEL_PATH := "res://assets/3d/characters/kael_v2/kael_v2.glb"
const REQUIRED_CLIPS := ["idle", "slash", "thrust", "heavy", "cast", "hit", "recovery"]
const CONTACT := 15.0 / 24.0
const CAST_RELEASE := 21.0 / 24.0
const PREPARE_SECONDS := 0.20
const RECOVERY_SECONDS := 0.22
const HIT_SECONDS := 0.24
const WALK_CYCLE_SECONDS := 0.50 # TacticalGrid owns the existing half-second move.
const DEFEAT_SECONDS := 0.65 # Finish collapse before Unit's 0.83-second fade/removal.
const DISPLAY_SIZE := 138.24 # Existing 192 * 0.72 canvas footprint.

var skin_id := "kael"
var asset_path := MODEL_PATH
var state := "idle"
var age := 0.0
var viewport: SubViewport
var output: Sprite2D
var camera: Camera3D
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var cast_socket: Node3D
var _attachments: Array[BoneAttachment3D] = []
var _available := false
var _pixel_style := true
var _high_quality := false

func _ready() -> void:
	# Missing/corrupt configuration must not replace the visible sprite.
	if not ResourceLoader.exists(asset_path):
		return
	var packed := load(asset_path) as PackedScene
	if packed == null:
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	model = Node3D.new()
	viewport.add_child(model)
	model.add_child(packed.instantiate())
	_find_nodes(model)
	if player == null or skeleton == null or cast_socket == null:
		return
	for clip in REQUIRED_CLIPS:
		if not player.has_animation(clip):
			return
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	viewport.add_child(camera)
	# Same azimuth/pitch as PracticeTerrain3D; imported character faces +Z.
	camera.position = Vector3(4, 0.95 + sqrt(32.0) * tan(deg_to_rad(30)), 4)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	preload("res://scripts/presentation/BattleLighting.gd").install(viewport)
	output = Sprite2D.new()
	output.texture = viewport.get_texture()
	output.centered = false
	output.scale = Vector2.ONE * (DISPLAY_SIZE / 192.0)
	output.position = -camera.unproject_position(Vector3.ZERO) * output.scale
	add_child(output)
	_available = true
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		_high_quality = bool(gs.practice_session.get("high_quality", false))
	_apply_render_profile()
	_sample()

func _find_nodes(node: Node) -> void:
	if node is Skeleton3D:
		skeleton = node
	if node is AnimationPlayer:
		player = node
	if node is BoneAttachment3D:
		_attachments.append(node)
	if node.name == "Kael_v2_cast_socket" and node is Node3D:
		cast_socket = node
	for child in node.get_children():
		_find_nodes(child)

func is_available() -> bool:
	return _available

func play(next: String) -> void:
	if not _available or (state == "defeat" and next != "defeat"):
		return
	state = next
	age = 0.0
	_sample()

func face(delta: Vector2i) -> void:
	if _available and delta != Vector2i.ZERO:
		model.rotation.y = atan2(float(delta.x), float(delta.y))
		_update_socket_transforms()

func _process(dt: float) -> void:
	if not _available:
		return
	age += maxf(0, dt)
	if state == "hit" and age >= HIT_SECONDS:
		play("idle")
	else:
		_sample()

func _sample() -> void:
	var clip := "idle"
	var sample_time := fmod(age, player.get_animation("idle").length)
	match state:
		"anticipation":
			clip = "slash"
			sample_time = minf(age / PREPARE_SECONDS, 1.0) * (CONTACT - 0.001)
		"contact":
			clip = "slash"
			sample_time = CONTACT
		"recovery":
			clip = "slash"
			sample_time = lerpf(CONTACT, player.get_animation(clip).length, minf(age / RECOVERY_SECONDS, 1.0))
		"cast_anticipation":
			clip = "cast"
			sample_time = minf(age / PREPARE_SECONDS, 1.0) * CAST_RELEASE
		"cast_release":
			clip = "cast"
			sample_time = CAST_RELEASE
		"cast_recovery":
			clip = "cast"
			sample_time = lerpf(CAST_RELEASE, player.get_animation(clip).length, minf(age / RECOVERY_SECONDS, 1.0))
		"hit":
			clip = "hit"
			sample_time = minf(age / HIT_SECONDS, 1.0) * player.get_animation(clip).length
		"walk":
			if player.has_animation("walk"):
				clip = "walk"
				sample_time = fmod(age / WALK_CYCLE_SECONDS, 1.0) * player.get_animation(clip).length
			# An older seven-clip asset safely uses idle; it never invents root motion.
		"defeat":
			sample_time = 0.0
			if player.has_animation("defeat"):
				clip = "defeat"
				sample_time = minf(age / DEFEAT_SECONDS, 1.0) * player.get_animation(clip).length
			# Clamp the endpoint forever. Only Unit owns fade/removal; never queue idle.
	if player.current_animation != clip:
		player.play(clip)
	player.seek(sample_time, true)
	player.advance(0)
	_update_socket_transforms()

func _update_socket_transforms() -> void:
	skeleton.force_update_all_bone_transforms()
	# Seeking a release and querying its origin occur in the same VFX call.
	# Do not wait for next frame's Skeleton3D notification to move attachments.
	for attachment in _attachments:
		attachment.on_skeleton_update()

func hand_world_position() -> Vector2:
	if not _available:
		return global_position + Vector2(0, -30)
	_update_socket_transforms()
	return output.to_global(camera.unproject_position(cast_socket.global_position))

## Style is separate from quality: high quality never changes the pixel grid.
## UI is not a child of this SubViewport and is never downsampled here.
func set_pixel_style(enabled: bool) -> void:
	_pixel_style = enabled
	_apply_render_profile()

func set_high_quality(enabled: bool) -> void:
	_high_quality = enabled
	_apply_render_profile()

func _apply_render_profile() -> void:
	if not _available:
		return
	var resolution := 160 if _pixel_style else (384 if _high_quality else 192)
	viewport.size = Vector2i(resolution, resolution)
	viewport.msaa_3d = Viewport.MSAA_4X if _high_quality else Viewport.MSAA_DISABLED
	output.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if _pixel_style else CanvasItem.TEXTURE_FILTER_LINEAR
	output.scale = Vector2.ONE * (DISPLAY_SIZE / float(resolution))
	output.position = -camera.unproject_position(Vector3.ZERO) * output.scale

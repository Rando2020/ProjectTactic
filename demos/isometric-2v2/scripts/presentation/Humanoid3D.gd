## Original procedural prototype. Rigid mesh pieces share one actual Skeleton3D.
## Presentation only: no combat outcomes, persistence or movement authority.
extends Node2D

var skin_id := "kael"
var state := "idle"
var age := 0.0
var rig: Skeleton3D
var model: Node3D
var viewport: SubViewport
var output: Sprite2D
var camera: Camera3D
var joints: Dictionary = {}
var target_yaw := 0.4

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	model = Node3D.new()
	viewport.add_child(model)
	rig = Skeleton3D.new()
	model.add_child(rig)
	_bone("hips", -1, Vector3(0, 0.85, 0))
	_bone("chest", 0, Vector3(0, 0.32, 0))
	_bone("head", 1, Vector3(0, 0.43, 0))
	_bone("arm_r", 1, Vector3(-0.29, 0.22, 0))
	_bone("hand_r", 3, Vector3(0, -0.36, 0))
	_bone("arm_l", 1, Vector3(0.29, 0.22, 0))
	_bone("hand_l", 5, Vector3(0, -0.36, 0))
	_bone("leg_r", 0, Vector3(-0.16, -0.08, 0))
	_bone("shin_r", 7, Vector3(0, -0.35, 0))
	_bone("leg_l", 0, Vector3(0.16, -0.08, 0))
	_bone("shin_l", 9, Vector3(0, -0.35, 0))
	var armor := Color("8c724c") if skin_id == "kael" else (Color("39324b") if skin_id == "void_cultist" else Color("386c70"))
	var cloth := Color("472d36") if skin_id == "kael" else Color("212738")
	var trim := Color("c4a66d") if skin_id == "kael" else Color("adc3c1")
	_piece("hips", Vector3(0.39, 0.24, 0.28), Vector3.ZERO, cloth)
	_piece("chest", Vector3(0.48, 0.43, 0.3), Vector3(0, 0.1, 0), armor)
	_piece("chest", Vector3(0.36, 0.06, 0.33), Vector3(0, -0.1, 0), trim)
	_piece("chest", Vector3(0.44, 0.7, 0.06), Vector3(0, -0.08, 0.2), cloth)
	_piece("head", Vector3(0.27, 0.3, 0.25), Vector3(0, 0.1, 0), Color("b88c70"))
	_piece("head", Vector3(0.3, 0.13, 0.29), Vector3(0, 0.24, 0.02), Color("372a25"))
	if skin_id == "zane":
		_piece("head", Vector3(0.32, 0.06, 0.31), Vector3(0, 0.15, 0), trim)
	for side in ["r", "l"]:
		_piece("arm_" + side, Vector3(0.24 if skin_id == "kael" else 0.19, 0.2, 0.28), Vector3.ZERO, trim)
		_piece("arm_" + side, Vector3(0.16, 0.32, 0.18), Vector3(0, -0.18, 0), armor)
		_piece("hand_" + side, Vector3(0.14, 0.29, 0.17), Vector3(0, -0.14, 0), cloth)
		_piece("leg_" + side, Vector3(0.2, 0.35, 0.22), Vector3(0, -0.17, 0), armor)
		_piece("shin_" + side, Vector3(0.17, 0.33, 0.2), Vector3(0, -0.16, 0), cloth)
		_piece("shin_" + side, Vector3(0.2, 0.12, 0.34), Vector3(0, -0.33, -0.06), armor)
	# Layered equipment gives the shared silhouette readable identity.
	_piece("chest", Vector3(0.14, 0.40, 0.05), Vector3(0, 0.09, -0.18), trim)
	_piece("hips", Vector3(0.19, 0.28, 0.08), Vector3(-0.16, -0.18, -0.14), armor)
	_piece("hips", Vector3(0.19, 0.28, 0.08), Vector3(0.16, -0.18, -0.14), armor)
	if skin_id == "kael":
		_piece("hand_l", Vector3(0.08, 0.63, 0.46), Vector3(0.12, -0.15, 0), armor)
		_piece("hand_l", Vector3(0.10, 0.40, 0.07), Vector3(0.15, -0.15, -0.02), trim)
	if skin_id == "void_cultist":
		_piece("head", Vector3(0.34, 0.37, 0.32), Vector3(0, 0.13, 0.03), armor)
		_piece("head", Vector3(0.17, 0.05, 0.04), Vector3(0, 0.13, -0.15), Color("c4a0ef"))
		_piece("hips", Vector3(0.55, 0.57, 0.37), Vector3(0, -0.26, 0.04), cloth)
	# Shared hand socket; the sword follows the wrist with no per-skin animation.
	if skin_id == "void_cultist":
		_piece("hand_r", Vector3(0.07, 1.25, 0.07), Vector3(0,-0.22,-0.1), trim)
		_piece("hand_r", Vector3(0.20, 0.25, 0.18), Vector3(0,0.45,-0.1), Color("ad87cd"))
	else:
		_piece("hand_r", Vector3(0.045, 0.85, 0.1), Vector3(0, -0.22, -0.44), Color("d4dbe0"), Vector3(PI/2, 0, 0))
		_piece("hand_r", Vector3(0.24, 0.045, 0.06), Vector3(0, -0.22, -0.06), trim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	viewport.add_child(camera)
	camera.position = Vector3(3, 2.7, 4)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.current = true
	preload("res://scripts/presentation/BattleLighting.gd").install(viewport)
	output = Sprite2D.new()
	output.texture = viewport.get_texture()
	output.centered = false
	output.scale = Vector2.ONE * 0.72
	output.position = -camera.unproject_position(Vector3.ZERO) * output.scale
	add_child(output)
	set_high_quality(bool(GameState.practice_session.get("high_quality", false)))
	_sample(0.0)

func _bone(label: String, parent: int, origin: Vector3) -> void:
	var index := rig.get_bone_count()
	rig.add_bone(label)
	rig.set_bone_parent(index, parent)
	rig.set_bone_rest(index, Transform3D(Basis.IDENTITY, origin))
	rig.set_bone_pose_position(index, origin)
	joints[label] = index

func _piece(bone: String, size: Vector3, offset: Vector3, color: Color, angles := Vector3.ZERO) -> void:
	var attachment := BoneAttachment3D.new()
	rig.add_child(attachment)
	attachment.bone_name = bone
	var mesh := MeshInstance3D.new()
	mesh.mesh = _faceted_piece(size)
	mesh.position = offset
	mesh.rotation = angles
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material_override = material
	attachment.add_child(mesh)

func play(next: String) -> void:
	if state == "defeat" and next != "defeat":
		return
	state = next
	age = 0.0
	_sample(0.0)

func face(delta: Vector2i) -> void:
	if delta != Vector2i.ZERO:
		target_yaw = atan2(-float(delta.x), -float(delta.y))

func _process(dt: float) -> void:
	age += dt
	if state == "hit" and age >= 0.24:
		play("idle")
	_sample(age)

func _rotate(bone: String, angles: Vector3) -> void:
	rig.set_bone_pose_rotation(joints[bone], Quaternion.from_euler(angles))

func _sample(t: float) -> void:
	for bone in joints:
		_rotate(bone, Vector3.ZERO)
	model.rotation = Vector3(0, target_yaw, 0)
	match state:
		"walk":
			var stride := sin(t * 15.0) * 0.48
			_rotate("leg_r", Vector3(stride, 0, 0))
			_rotate("leg_l", Vector3(-stride, 0, 0))
			_rotate("arm_r", Vector3(-stride * 0.5, 0, 0))
			_rotate("arm_l", Vector3(stride * 0.5, 0, 0))
		"anticipation":
			var f := clampf(t / 0.16, 0, 1)
			_rotate("chest", Vector3(0, -0.45 * f, 0))
			_rotate("arm_r", Vector3(-2.2 * f, 0, -0.3 * f))
			_rotate("hand_r", Vector3(-0.55 * f, 0, 0))
		"contact", "recovery":
			var weight := 1.0 if state == "contact" else 1.0 - clampf(t / 0.18, 0, 1)
			_rotate("chest", Vector3(0.12, 0.45, 0) * weight)
			_rotate("arm_r", Vector3(-0.85, 0.3, -0.25) * weight)
		"cast_anticipation", "cast_release", "cast_recovery":
			var weight := clampf(t / 0.18, 0, 1) if state == "cast_anticipation" else 1.0
			if state == "cast_recovery": weight = 1.0 - clampf(t / 0.18, 0, 1)
			_rotate("arm_l", Vector3(-1.3, 0, 0.2) * weight)
			_rotate("hand_l", Vector3(-0.35, 0, 0) * weight)
			_rotate("chest", Vector3(0, 0.15, 0) * weight)
		"hit":
			_rotate("chest", Vector3(-0.3 * sin(minf(t / 0.24, 1) * PI), 0, 0))
		"defeat":
			model.rotation.z = -minf(t / 0.5, 1) * PI / 2
		_:
			_rotate("chest", Vector3(sin(t * 2.0) * 0.018, 0, 0))

func hand_world_position() -> Vector2:
	# Bone-global pose is in Skeleton3D space, not the battlefield canvas.
	rig.force_update_all_bone_transforms()
	var hand := rig.get_bone_global_pose(joints["hand_l"]) * Vector3(0, -0.25, 0)
	return output.to_global(camera.unproject_position(rig.to_global(hand)))

func set_high_quality(enabled: bool) -> void:
	var factor := 2 if enabled else 1
	viewport.size = Vector2i(192, 192) * factor
	output.scale = Vector2.ONE * (0.72 / factor)
	output.position = -camera.unproject_position(Vector3.ZERO) * output.scale

func _faceted_piece(size: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var ring: Array[Vector2] = [Vector2(-0.32,-0.5), Vector2(0.32,-0.5), Vector2(0.5,-0.32), Vector2(0.5,0.32), Vector2(0.32,0.5), Vector2(-0.32,0.5), Vector2(-0.5,0.32), Vector2(-0.5,-0.32)]
	for i in range(8):
		var a := Vector3(ring[i].x * size.x, -size.y/2, ring[i].y * size.z)
		var b := Vector3(ring[(i+1)%8].x * size.x, -size.y/2, ring[(i+1)%8].y * size.z)
		var c := b + Vector3(0,size.y,0)
		var d := a + Vector3(0,size.y,0)
		for v in [b,c,a,c,d,a,b,a,Vector3(0,-size.y/2,0),d,c,Vector3(0,size.y/2,0)]: st.add_vertex(v)
	st.generate_normals()
	return st.commit()

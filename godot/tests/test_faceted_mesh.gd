extends Node
func _ready() -> void:
	var rig = preload("res://scripts/presentation/Humanoid3D.gd").new()
	var mesh: ArrayMesh = rig._faceted_piece(Vector3.ONE)
	var arrays := mesh.surface_get_arrays(0)
	var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][0]
	print("Front normal: ", normal)
	assert(normal.z < 0, "Front face must point outward")
	assert(mesh.get_aabb().size.is_equal_approx(Vector3.ONE))
	rig.free()
	print("Faceted mesh bounds and outward normal passed")
	get_tree().quit()

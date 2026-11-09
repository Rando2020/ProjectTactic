extends Node
## Test-only phase probe. Reads existing socket transforms, never seeks the rig.
## A headless dummy renderer does not emit draw signals: process samples are
## geometry evidence only. Real pre/post-draw callbacks are labeled separately.
var actor: Unit
var tactical_grid: Node2D
var presenter: Node
var slow_frame_ms := 0
var samples: Array[Dictionary] = []
var initial_hand := Vector2.ZERO
var render_phases := {"pre_draw": 0, "post_draw": 0}

func _ready() -> void:
	process_priority = 100 # Observe after both the pose producer and default-priority VFX.
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_on_pre_draw)
	RenderingServer.frame_post_draw.disconnect(_on_post_draw)

func observe(candidate: Node) -> void:
	if not candidate.has_signal("phase_presented"): return
	candidate.phase_presented.connect(_on_phase.bind(candidate))

func _on_phase(phase: String, candidate: Node) -> void:
	if phase == "charge":
		presenter = candidate
		initial_hand = _hand()

func _hand() -> Vector2:
	var rig = actor._rig3d
	return rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))

func _record(stage: String, delta: float = 0.0) -> void:
	if not is_instance_valid(presenter) or not is_instance_valid(actor): return
	if samples.size() >= 64: return
	var hand := _hand()
	var row := {"frame": Engine.get_process_frames(), "stage": stage, "delta": delta,
		"hand": [hand.x, hand.y], "age": actor._rig3d.age,
		"state": actor._rig3d.state, "motion": hand.distance_to(initial_hand)}
	if is_instance_valid(presenter._charge):
		var charge: Vector2 = presenter._charge.global_position
		row["role"] = "charge"
		row["point"] = [charge.x, charge.y]
		var authored: bool = presenter._charge is Sprite2D and presenter._charge.has_method("available")
		var expected: Vector2 = tactical_grid.to_global(tactical_grid._unit_foot_pos(actor.grid_pos)) if authored else hand
		row["anchor"] = "ground" if authored else "hand"
		row["expected"] = [expected.x, expected.y]
		row["error"] = charge.distance_to(expected)
	elif is_instance_valid(presenter._projectile):
		var origin: Vector2 = presenter.to_global(presenter._flight_start)
		row["role"] = "projectile"
		row["origin"] = [origin.x, origin.y]
		row["error"] = origin.distance_to(hand)
	else: return
	samples.append(row)

func _process(delta: float) -> void:
	_record("process_end", delta)
	# Test-only main-thread workload. The next real engine frame is slow; do not
	# manually advance bones, fabricate dt, alter phase clocks or time_scale.
	if slow_frame_ms > 0 and is_instance_valid(presenter) and is_instance_valid(presenter._charge):
		OS.delay_msec(slow_frame_ms)

func _on_pre_draw() -> void:
	render_phases.pre_draw += 1
	_record("pre_draw")

func _on_post_draw() -> void:
	render_phases.post_draw += 1
	_record("post_draw")

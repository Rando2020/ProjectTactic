class_name AshvaleBattlePresentation
extends Node2D

## Orchestrates the Ashvale vertical-slice presentation without changing battle
## rules. It listens to existing BattleManager signals and translates them into
## restrained visual cues: turn focus, movement traces, enemy intent connectors
## and quiet environmental accents.

@export var enabled: bool = true
@export var ashvale_map_id: String = "ashvale_road_01"

const PLAYER_COLOR := Color(0.44, 0.86, 1.0, 0.96)
const ENEMY_COLOR := Color(1.0, 0.38, 0.24, 0.96)
const ABILITY_COLOR := Color(0.72, 0.46, 1.0, 0.96)
const WATER_GLINT := Color(0.54, 0.88, 1.0, 0.34)
const FIRE_GLOW := Color(1.0, 0.48, 0.16, 0.13)

@onready var battle_manager: BattleManager = get_node("../BattleManager") as BattleManager
@onready var tactical_grid: TacticalGrid = get_node("../BattleManager/TacticalGrid") as TacticalGrid

var _active: bool = false
var _ambient_layer: Node2D
var _intent_layer: Node2D
var _moment_layer: Node2D


func _ready() -> void:
	z_index = 1500
	z_as_relative = false
	visible = false
	_build_layers()
	_connect_battle_signals()


func _build_layers() -> void:
	_ambient_layer = Node2D.new()
	_ambient_layer.name = "AmbientAccents"
	_ambient_layer.z_index = -650
	add_child(_ambient_layer)

	_intent_layer = Node2D.new()
	_intent_layer.name = "IntentTelegraphs"
	_intent_layer.z_index = 80
	add_child(_intent_layer)

	_moment_layer = Node2D.new()
	_moment_layer.name = "MomentCues"
	_moment_layer.z_index = 180
	add_child(_moment_layer)


func _connect_battle_signals() -> void:
	if not battle_manager:
		return
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.unit_moved.connect(_on_unit_moved)
	battle_manager.enemy_intent_changed.connect(_on_enemy_intent_changed)
	battle_manager.ability_mode_started.connect(_on_ability_mode_started)
	battle_manager.battle_won.connect(_on_battle_finished)
	battle_manager.battle_lost.connect(_on_battle_lost)


func _on_battle_started(_display_name: String, _objective: String) -> void:
	if not enabled or not battle_manager or not battle_manager.map_data:
		return
	_active = str(battle_manager.map_data.get("id")) == ashvale_map_id
	visible = _active
	if not _active:
		return
	_build_environment_accents()


func _on_turn_started(unit_id: String, team: String) -> void:
	if not _active:
		return
	var active_unit: Unit = _unit_by_id(unit_id)
	if active_unit:
		_spawn_turn_focus(active_unit.grid_pos, PLAYER_COLOR if team == "player" else ENEMY_COLOR)


func _on_unit_moved(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	if not _active:
		return
	var unit: Unit = _unit_by_id(unit_id)
	var color: Color = PLAYER_COLOR if unit and unit.team == "player" else ENEMY_COLOR
	_spawn_move_trace(from, to, color)


func _on_ability_mode_started(_usable_ids: Array) -> void:
	if not _active:
		return
	var unit: Unit = _unit_by_id(battle_manager.active_unit_id)
	if unit and unit.team == "player":
		_spawn_turn_focus(unit.grid_pos, ABILITY_COLOR, 1.18)


func _on_enemy_intent_changed(intent: Dictionary) -> void:
	if not _active:
		return
	_clear_layer(_intent_layer)
	if intent.is_empty():
		return
	if str(intent.get("kind", "")) == "board":
		var rows: Array = intent.get("rows", []) as Array
		var count: int = mini(rows.size(), 4)
		for i in range(count):
			var row: Dictionary = rows[i] as Dictionary
			_add_intent_telegraph(row, false)
	else:
		_add_intent_telegraph(intent, true)


func _add_intent_telegraph(intent: Dictionary, acting_now: bool) -> void:
	var kind: String = str(intent.get("kind", "hold"))
	if kind in ["hold", "retreat", "heal"]:
		return
	var actor_id: String = str(intent.get("actor_id", ""))
	var target_id: String = str(intent.get("target_id", ""))
	if actor_id.is_empty() or target_id.is_empty():
		return
	var actor: Unit = _unit_by_id(actor_id)
	var target: Unit = _unit_by_id(target_id)
	if not actor or not target:
		return

	var danger: String = str(intent.get("danger", "normal"))
	var color: Color = _danger_color(danger)
	var start: Vector2 = _unit_world(actor.grid_pos) + Vector2(0.0, -26.0)
	var finish: Vector2 = _unit_world(target.grid_pos) + Vector2(0.0, -24.0)
	var midpoint: Vector2 = start.lerp(finish, 0.5) + Vector2(0.0, -22.0)

	var line := Line2D.new()
	line.points = PackedVector2Array([start, midpoint, finish])
	line.width = 3.2 if acting_now else 1.8
	line.default_color = Color(color.r, color.g, color.b, 0.88 if acting_now else 0.38)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_intent_layer.add_child(line)

	var direction: Vector2 = (finish - midpoint).normalized()
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(5.0, 5.0),
		Vector2(-5.0, 5.0),
	])
	arrow.position = finish - direction * 8.0
	arrow.rotation = direction.angle() + PI * 0.5
	arrow.color = Color(color.r, color.g, color.b, 0.95 if acting_now else 0.58)
	_intent_layer.add_child(arrow)

	_add_target_halo(target.grid_pos, color, danger == "lethal" or acting_now)


func _add_target_halo(pos: Vector2i, color: Color, strong: bool) -> void:
	var ring := Line2D.new()
	var poly: PackedVector2Array = _diamond_points(1.16 if strong else 1.05)
	ring.points = PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]])
	ring.width = 3.0 if strong else 1.8
	ring.default_color = Color(color.r, color.g, color.b, 0.82 if strong else 0.42)
	ring.position = _tile_world(pos)
	_intent_layer.add_child(ring)


func _spawn_turn_focus(pos: Vector2i, color: Color, size_scale: float = 1.0) -> void:
	var ring := Line2D.new()
	var poly: PackedVector2Array = _diamond_points(1.06 * size_scale)
	ring.points = PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]])
	ring.width = 3.0
	ring.default_color = color
	ring.position = _tile_world(pos)
	ring.scale = Vector2(0.82, 0.82)
	_moment_layer.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.16, 1.16), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.34)
	tween.chain().tween_callback(ring.queue_free)


func _spawn_move_trace(from: Vector2i, to: Vector2i, color: Color) -> void:
	var line := Line2D.new()
	var start: Vector2 = _unit_world(from)
	var finish: Vector2 = _unit_world(to)
	line.points = PackedVector2Array([start, start.lerp(finish, 0.5) + Vector2(0.0, -9.0), finish])
	line.width = 3.0
	line.default_color = Color(color.r, color.g, color.b, 0.72)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_moment_layer.add_child(line)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "width", 1.0, 0.42)
	tween.tween_property(line, "modulate:a", 0.0, 0.42)
	tween.chain().tween_callback(line.queue_free)


func _build_environment_accents() -> void:
	_clear_layer(_ambient_layer)
	if not tactical_grid:
		return
	for key: Variant in tactical_grid.tiles.keys():
		var pos: Vector2i = key
		var tile: Dictionary = tactical_grid.tiles[pos] as Dictionary
		var terrain: String = str(tile.get("terrain", ""))
		if terrain == "shallow_water" and (pos.x + pos.y) % 2 == 0:
			_add_water_glint(pos)
		elif terrain in ["shrine", "burning"]:
			_add_warm_ground_glow(pos)


func _add_water_glint(pos: Vector2i) -> void:
	var glint := Line2D.new()
	glint.points = PackedVector2Array([Vector2(-13.0, 0.0), Vector2(13.0, 0.0)])
	glint.width = 1.4
	glint.default_color = WATER_GLINT
	glint.position = _tile_world(pos) + Vector2(0.0, -2.0)
	_ambient_layer.add_child(glint)
	var tween := create_tween().set_loops()
	tween.tween_property(glint, "modulate:a", 0.28, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glint, "modulate:a", 0.78, 0.9).set_trans(Tween.TRANS_SINE)


func _add_warm_ground_glow(pos: Vector2i) -> void:
	var glow := Polygon2D.new()
	glow.polygon = _diamond_points(1.10)
	glow.color = FIRE_GLOW
	glow.position = _tile_world(pos)
	_ambient_layer.add_child(glow)
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.56, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


func _on_battle_finished(_rewards: Dictionary) -> void:
	_clear_layer(_intent_layer)


func _on_battle_lost() -> void:
	_clear_layer(_intent_layer)


func _unit_by_id(unit_id: String) -> Unit:
	if unit_id.is_empty() or not battle_manager:
		return null
	var candidate: Variant = battle_manager.units.get(unit_id)
	return candidate as Unit


func _danger_color(danger: String) -> Color:
	match danger:
		"lethal":
			return Color(1.0, 0.16, 0.12, 1.0)
		"high":
			return Color(1.0, 0.42, 0.14, 1.0)
		"medium":
			return Color(0.96, 0.62, 0.20, 1.0)
		_:
			return Color(0.88, 0.50, 0.28, 1.0)


func _tile_world(pos: Vector2i) -> Vector2:
	var tile: Dictionary = tactical_grid.get_tile(pos)
	var height: int = int(tile.get("height", 0))
	return tactical_grid.map_origin + Vector2(
		(float(pos.x) - float(pos.y)) * float(tactical_grid.tile_size.x) * 0.5,
		(float(pos.x) + float(pos.y)) * float(tactical_grid.tile_size.y) * 0.5 - float(height) * tactical_grid.height_step
	)


func _unit_world(pos: Vector2i) -> Vector2:
	return _tile_world(pos) + Vector2(0.0, float(tactical_grid.tile_size.y) * 0.28)


func _diamond_points(scale_value: float) -> PackedVector2Array:
	var half_w: float = float(tactical_grid.tile_size.x) * 0.5 * scale_value
	var half_h: float = float(tactical_grid.tile_size.y) * 0.5 * scale_value
	return PackedVector2Array([
		Vector2(0.0, -half_h),
		Vector2(half_w, 0.0),
		Vector2(0.0, half_h),
		Vector2(-half_w, 0.0),
	])


func _clear_layer(layer: Node2D) -> void:
	if not layer:
		return
	for child in layer.get_children():
		child.queue_free()

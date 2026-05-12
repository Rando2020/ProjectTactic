## Unit.gd
## CharacterBody2D representing one combatant on the tactical grid.
## Holds runtime stats. Emits signals for all state changes.
## Does NOT call BattleManager directly — only emits signals.
##
## AI AGENT: Implement all TODO sections.

class_name Unit
extends CharacterBody2D

# ── Signals ──────────────────────────────────────────────────────────────────

signal hp_changed(unit_id: String, new_hp: int, max_hp: int)
signal temper_changed(unit_id: String, new_temper: int, max_temper: int)
signal ether_changed(unit_id: String, new_ether: int, max_ether: int)
signal status_applied(unit_id: String, status_id: String)
signal status_removed(unit_id: String, status_id: String)
signal unit_defeated(unit_id: String)
signal turn_started(unit_id: String)
signal turn_ended(unit_id: String)
signal moved(unit_id: String, from: Vector2i, to: Vector2i)

# ── Properties ────────────────────────────────────────────────────────────────

@export var unit_data: UnitData

var unit_id: String
var display_name: String
var team: String                # "player", "enemy", "ally"
var grid_pos: Vector2i
var facing: String = "S"       # "N", "E", "S", "W"

## Runtime stats (modified during battle)
var hp: int
var mp: int
var temper: int
var ether: int
var ct: int = 0                # Charge Time for turn order

## Whether this unit has acted this turn
var has_acted: bool = false
var has_moved: bool = false

## Active status effects
var statuses: Array[StatusEffect] = []

## Current job (may differ from base job in save data)
var current_job_id: String

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var status_icons: HBoxContainer = $StatusIcons


func _ready() -> void:
	if unit_data:
		_initialize_from_data(unit_data)


func _initialize_from_data(data: UnitData) -> void:
	unit_id = data.id
	display_name = data.display_name
	team = data.faction
	current_job_id = data.base_job_id
	hp = data.base_stats.hp
	mp = data.base_stats.mp
	temper = data.base_stats.max_temper
	ether = data.base_stats.max_ether
	ct = 0
    # Load the sprite sheet into the AnimatedSprite2D if provided. In the
    # scaffold we only assign the texture; proper animation frames would be
    # configured in the editor when assets are available.
    if data.sprite_sheet:
        sprite.texture = data.sprite_sheet
    # Set up the health bar to reflect maximum and current HP. ProgressBar
    # expects value and max_value properties.
    if health_bar:
        health_bar.max_value = data.base_stats.hp
        health_bar.value = hp


## Apply damage through the Temper/Ether armor system
## Returns a DamageResult dict with hp_damage, temper_damage, ether_damage
func receive_damage(amount: int, damage_type: String) -> Dictionary:
    # Implements the Temper/Ether armor system. Damage is first absorbed by
    # the appropriate armor layer (Temper for physical, Ether for magical).
    # A portion of the damage (35%) is absorbed up to the remaining armor,
    # reducing the armor value; 25% of the absorbed amount further reduces
    # HP. Pure damage bypasses armor entirely.
    var result := {
        "hp_damage": 0,
        "temper_damage": 0,
        "ether_damage": 0,
        "defeated": false
    }
    var raw_damage: int = amount
    match damage_type:
        "physical":
            var armor_absorbed: int = min(temper, int(raw_damage * 0.35))
            temper = max(temper - armor_absorbed, 0)
            var hp_damage: int = max(1, raw_damage - int(armor_absorbed * 0.25))
            hp = max(hp - hp_damage, 0)
            result["hp_damage"] = hp_damage
            result["temper_damage"] = armor_absorbed
        "magical":
            var armor_absorbed: int = min(ether, int(raw_damage * 0.35))
            ether = max(ether - armor_absorbed, 0)
            var hp_damage: int = max(1, raw_damage - int(armor_absorbed * 0.25))
            hp = max(hp - hp_damage, 0)
            result["hp_damage"] = hp_damage
            result["ether_damage"] = armor_absorbed
        _:
            # Pure damage bypasses armor
            hp = max(hp - raw_damage, 0)
            result["hp_damage"] = raw_damage
    # Emit stat change signals
    hp_changed.emit(unit_id, hp, unit_data.base_stats.hp)
    temper_changed.emit(unit_id, temper, unit_data.base_stats.max_temper)
    ether_changed.emit(unit_id, ether, unit_data.base_stats.max_ether)
    # Clamp to zero and check defeat
    if hp <= 0 and not result["defeated"]:
        unit_defeated.emit(unit_id)
        result["defeated"] = true
    # Update health bar visual
    if health_bar:
        health_bar.value = hp
    return result


## Restore HP up to max
func heal(amount: int) -> void:
    # Restore HP up to the maximum specified by the base stats
    hp = min(hp + amount, unit_data.base_stats.hp)
    if health_bar:
        health_bar.value = hp
    hp_changed.emit(unit_id, hp, unit_data.base_stats.hp)


## Restore Temper up to max
func restore_temper(amount: int) -> void:
    temper = min(temper + amount, unit_data.base_stats.max_temper)
    temper_changed.emit(unit_id, temper, unit_data.base_stats.max_temper)


## Restore Ether up to max
func restore_ether(amount: int) -> void:
    ether = min(ether + amount, unit_data.base_stats.max_ether)
    ether_changed.emit(unit_id, ether, unit_data.base_stats.max_ether)


## Apply a status effect
func apply_status(status: StatusEffect) -> void:
	# TODO: Check if already has status, stack or refresh duration
	statuses.append(status)
	status_applied.emit(unit_id, status.status_id)


## Remove a status effect by ID
func remove_status(status_id: String) -> void:
	statuses = statuses.filter(func(s): return s.status_id != status_id)
	status_removed.emit(unit_id, status_id)


## Returns true if unit has a specific status
func has_status(status_id: String) -> bool:
	return statuses.any(func(s): return s.status_id == status_id)


## Tick down status durations. Called at turn end.
func tick_statuses() -> void:
    # Decrement duration on all active statuses. If a status reaches 0
    # duration, remove it and emit the removal signal. We assume each
    # StatusEffect has a `duration` property and a `status_id`. If these
    # properties are not defined, this loop will silently leave the list
    # unchanged.
    var to_remove: Array[String] = []
    for s in statuses:
        if s.has_variable("duration"):
            s.duration -= 1
            if s.duration <= 0:
                to_remove.append(s.status_id)
    for sid in to_remove:
        remove_status(sid)


## Move unit to new grid position (visual + logical)
func move_to(new_pos: Vector2i) -> void:
	var old_pos := grid_pos
	grid_pos = new_pos
    # Animate movement (tween position) to the world position using GridSystem
    var start_world: Vector2 = position
    var end_world: Vector2 = GridSystem.grid_to_world(new_pos, get_parent().tile_size if get_parent().has_method("tile_size") else Vector2i(64, 64))
    # Immediately set current position for consistency
    position = start_world
    var tween := create_tween()
    tween.tween_property(self, "position", end_world, 0.25)
    # Update facing based on direction of movement
    var delta := new_pos - old_pos
    if delta != Vector2i.ZERO:
        if abs(delta.x) > abs(delta.y):
            set_facing(delta.x > 0 ? "E" : "W")
        else:
            set_facing(delta.y > 0 ? "S" : "N")
    moved.emit(unit_id, old_pos, new_pos)
    has_moved = true


## Set facing direction and flip sprite accordingly
func set_facing(new_facing: String) -> void:
	facing = new_facing
    # Flip the sprite horizontally for east/west facing. For north/south the
    # sprite is not flipped. Additional animation changes could be applied
    # here when assets are available.
    if sprite:
        if facing == "E":
            sprite.flip_h = false
        elif facing == "W":
            sprite.flip_h = true


## Called by BattleManager at the start of this unit's turn
func begin_turn() -> void:
	has_acted = false
	has_moved = false
	turn_started.emit(unit_id)


## Called by BattleManager to end this unit's turn
func end_turn() -> void:
	tick_statuses()
	turn_ended.emit(unit_id)


## Returns effective speed (modified by Slow/Haste statuses)
func get_effective_speed() -> int:
	var base_speed: int = unit_data.base_stats.speed if unit_data else 6
	if has_status("haste"):
		return int(base_speed * 1.5)
	if has_status("slow"):
		return int(base_speed * 0.5)
	return base_speed


## Returns true if unit can still take actions this turn
func can_act() -> bool:
	return not has_acted and hp > 0 and not has_status("stun") and not has_status("petrify")


## Returns true if unit can still move this turn
func can_move() -> bool:
	return not has_moved and hp > 0 and not has_status("immobilize") and not has_status("petrify")

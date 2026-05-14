extends Node2D

const ENCOUNTER_PATH := "res://data/first_grassy_field.json"
const CHARACTERS_PATH := "res://data/main_characters.json"
const JOBS_PATH := "res://data/jobs.json"
const ABILITIES_PATH := "res://data/abilities.json"
const STATUS_EFFECTS_PATH := "res://data/status_effects.json"
const SURFACES_PATH := "res://data/surfaces.json"
const SURFACE_REACTIONS_PATH := "res://data/surface_reactions.json"

const PTGameDatabaseScript := preload("res://scripts/data/PTGameDatabase.gd")
const PTPathfinderScript := preload("res://scripts/battle/PTPathfinder.gd")
const PTCombatResolverScript := preload("res://scripts/battle/PTCombatResolver.gd")
const PTStatusEffectSystemScript := preload("res://scripts/battle/PTStatusEffectSystem.gd")
const PTSurfaceSystemScript := preload("res://scripts/battle/PTSurfaceSystem.gd")
const PTEnemyAIScript := preload("res://scripts/ai/PTEnemyAI.gd")
const PTBattleVFXScript := preload("res://scripts/vfx/PTBattleVFX.gd")

const TILE_TEXTURES := {
	"grass": "res://assets/tiles/terrain_grass.png",
	"dirt": "res://assets/tiles/terrain_dirt.png",
	"stone": "res://assets/tiles/terrain_stone.png",
	"bridge": "res://assets/tiles/terrain_bridge.png",
	"water": "res://assets/tiles/terrain_water.png",
	"crystal": "res://assets/tiles/terrain_crystal.png",
	"cliff": "res://assets/tiles/terrain_cliff.png",
	"stairs": "res://assets/tiles/terrain_stairs.png",
}

const UNIT_TEXTURES := {
	"unitKnight": "res://assets/tokens/unit_knight.png",
	"unitScout": "res://assets/tokens/unit_scout.png",
	"unitArcanist": "res://assets/tokens/unit_arcanist.png",
	"unitHealer": "res://assets/tokens/unit_healer.png",
	"enemyLancer": "res://assets/tokens/enemy_lancer.png",
	"enemyRogue": "res://assets/tokens/enemy_rogue.png",
	"enemyShadow": "res://assets/tokens/enemy_shadow.png",
}

const ENEMY_JOB_BY_CLASS := {
	"Lancer": "bramble_lancer",
	"Rogue": "brush_rogue",
	"Shadow": "shade_knife",
	"Shaman": "bog_shaman",
}

var encounter: Dictionary
var characters: Array
var jobs_by_id := {}
var abilities_by_id := {}
var status_effects := {}
var surfaces := {}
var surface_reactions := {}
var tiles := {}
var units: Array = []
var selected_unit := -1
var selected_ability_id := ""
var command := "inspect"
var hovered_tile := -1
var battle_message := "Select a unit, then choose Move, Attack, or a skill."
var battle_finished := false

var grid_width := 8
var grid_height := 6
var tile_width := 112.0
var tile_height := 60.0
var height_step := 16.0
var board_origin := Vector2(590, 130)

var board := Node2D.new()
var highlight_layer := Node2D.new()
var unit_layer := Node2D.new()
var battle_vfx: Node2D
var ui := CanvasLayer.new()


func _ready() -> void:
	_load_data()
	_build_scene()
	_build_ui()


func _process(_delta: float) -> void:
	var tile := screen_to_tile(get_global_mouse_position())
	if tile != hovered_tile:
		hovered_tile = tile
		_redraw_highlights()


func _unhandled_input(event: InputEvent) -> void:
	if battle_finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var tile := screen_to_tile(get_global_mouse_position())
		if tile >= 0:
			_handle_tile_click(tile)


func _load_data() -> void:
	encounter = _read_json(ENCOUNTER_PATH)
	characters = _read_json(CHARACTERS_PATH)
	for job in _read_json(JOBS_PATH):
		jobs_by_id[job["id"]] = job
	for ability in _read_json(ABILITIES_PATH):
		abilities_by_id[ability["id"]] = ability
	status_effects = _read_json(STATUS_EFFECTS_PATH)
	surfaces = _read_json(SURFACES_PATH)
	surface_reactions = _read_json(SURFACE_REACTIONS_PATH)

	grid_width = encounter["grid"]["width"]
	grid_height = encounter["grid"]["height"]
	tile_width = encounter["grid"]["tileWidth"]
	tile_height = encounter["grid"]["tileHeight"]
	height_step = encounter["grid"]["heightStep"]
	for tile in encounter["tiles"]:
		tiles[tile["tile"]] = tile


func _read_json(path: String) -> Variant:
	return PTGameDatabaseScript.read_json(path)


func _build_scene() -> void:
	add_child(board)
	add_child(highlight_layer)
	add_child(unit_layer)
	battle_vfx = PTBattleVFXScript.new()
	add_child(battle_vfx)
	add_child(ui)
	_draw_stage_backdrop()
	_draw_board()
	_spawn_units()
	selected_unit = first_alive_unit("player")
	_redraw_highlights()


func _draw_stage_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.06, 0.08, 0.075, 1.0)
	backdrop.size = Vector2(1280, 800)
	add_child(backdrop)
	move_child(backdrop, 0)

	var title := Label.new()
	title.text = "Grasslands Demo Battle"
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)

	var objective := Label.new()
	objective.text = "Objective: " + encounter.get("objective", "Defeat all enemies")
	objective.position = Vector2(30, 58)
	objective.add_theme_font_size_override("font_size", 15)
	add_child(objective)


func _draw_board() -> void:
	for tile_id in range(grid_width * grid_height):
		var tile: Dictionary = tiles[tile_id]
		var sprite := Sprite2D.new()
		sprite.texture = load(TILE_TEXTURES.get(tile["terrain"], TILE_TEXTURES["grass"]))
		sprite.position = tile_to_screen(tile_id)
		sprite.z_index = tile_id
		board.add_child(sprite)


func _spawn_units() -> void:
	var player_lookup := {}
	for character in characters:
		player_lookup[character["name"]] = character
	for player in encounter["players"]:
		var data: Dictionary = player_lookup[player["name"]]
		_add_unit({
			"name": player["name"],
			"team": "player",
			"tile": player["tile"],
			"hp": data["hp"],
			"maxHp": data["hp"],
			"mp": data["mp"],
			"maxMp": data["mp"],
			"move": data["move"],
			"jump": data["jump"],
			"speed": data["speed"],
			"attack": data.get("attack", 18),
			"defense": data.get("defense", 12),
			"spirit": data.get("spirit", 12),
			"level": data.get("level", 1),
			"jobId": data["jobId"],
			"avatarId": data["avatarId"],
			"abilityIds": data["abilityIds"],
			"statuses": [],
			"hasMoved": false,
			"hasActed": false,
		})
	for enemy in encounter["enemies"]:
		var job_id: String = ENEMY_JOB_BY_CLASS.get(enemy["class"], "")
		var job: Dictionary = {}
		if jobs_by_id.has(job_id):
			job = jobs_by_id[job_id]
		_add_unit({
			"name": enemy["name"],
			"team": "enemy",
			"tile": enemy["tile"],
			"hp": enemy["hp"],
			"maxHp": enemy["hp"],
			"mp": enemy.get("mp", job.get("baseMp", 20)),
			"maxMp": enemy.get("mp", job.get("baseMp", 20)),
			"move": job.get("move", 3),
			"jump": job.get("jump", 2),
			"speed": job.get("speed", 20),
			"attack": enemy.get("attack", 16),
			"defense": enemy.get("defense", 10),
			"spirit": enemy.get("spirit", 10),
			"level": enemy.get("level", 4),
			"jobId": job_id,
			"avatarId": _enemy_avatar_for_class(enemy["class"]),
			"abilityIds": job.get("abilityIds", []),
			"aiProfile": enemy.get("aiProfile", "bruiser"),
			"statuses": [],
			"hasMoved": false,
			"hasActed": false,
		})


func _enemy_avatar_for_class(class_name: String) -> String:
	match class_name:
		"Lancer":
			return "enemyLancer"
		"Rogue":
			return "enemyRogue"
		"Shadow":
			return "enemyShadow"
		"Shaman":
			return "enemyShadow"
	return "enemyRogue"


func _add_unit(data: Dictionary) -> void:
	var root := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = load(UNIT_TEXTURES[data["avatarId"]])
	sprite.position = Vector2(0, -46)
	root.add_child(sprite)

	var label := Label.new()
	label.text = data["name"]
	label.position = Vector2(-42, 12)
	label.add_theme_font_size_override("font_size", 11)
	root.add_child(label)

	unit_layer.add_child(root)
	data["node"] = root
	units.append(data)
	_place_unit(units.size() - 1, false)


func _place_unit(index: int, animate := true) -> void:
	var unit: Dictionary = units[index]
	var target := tile_to_screen(unit["tile"])
	unit["node"].z_index = 100 + unit["tile"]
	if animate:
		var tween := create_tween()
		tween.tween_property(unit["node"], "position", target, 0.18).set_trans(Tween.TRANS_SINE)
	else:
		unit["node"].position = target


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(930, 24)
	panel.size = Vector2(320, 720)
	ui.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Battle Commands"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var move_button := _command_button("Move", "move")
	var attack_button := _command_button("Attack", "attack")
	var wait_button := _command_button("End Unit Turn", "wait")
	box.add_child(move_button)
	box.add_child(attack_button)
	box.add_child(wait_button)

	var skills := VBoxContainer.new()
	skills.name = "Skills"
	box.add_child(skills)

	var info := RichTextLabel.new()
	info.name = "Info"
	info.bbcode_enabled = true
	info.fit_content = true
	info.custom_minimum_size = Vector2(280, 390)
	box.add_child(info)
	_update_ui()


func _command_button(label: String, new_command: String) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(func() -> void:
		if new_command == "wait":
			_end_selected_unit_turn()
		else:
			if selected_unit < 0:
				return
			if new_command == "move" and units[selected_unit]["hasMoved"]:
				battle_message = units[selected_unit]["name"] + " has already moved."
				_update_ui()
				return
			if new_command == "attack" and units[selected_unit]["hasActed"]:
				battle_message = units[selected_unit]["name"] + " has already acted."
				_update_ui()
				return
			command = new_command
			selected_ability_id = ""
			battle_message = "Choose a target tile."
		_redraw_highlights()
		_update_ui()
	)
	return button


func _update_ui() -> void:
	var panel := ui.get_node("Panel/Box")
	var info: RichTextLabel = panel.get_node("Info")
	var skills: VBoxContainer = panel.get_node("Skills")
	for child in skills.get_children():
		child.queue_free()
	if selected_unit < 0:
		info.text = "No unit selected."
		return

	var unit: Dictionary = units[selected_unit]
	var job_name: String = unit["jobId"]
	if jobs_by_id.has(unit["jobId"]):
		job_name = jobs_by_id[unit["jobId"]]["name"]
	info.text = "[b]%s[/b]\n%s\nHP %d/%d\nMP %d/%d\nMove %d  Jump %d\nCommand: %s\nTile: %d\n\n%s" % [
		unit["name"], job_name, unit["hp"], unit["maxHp"], unit["mp"], unit["maxMp"], unit["move"], unit["jump"], command, unit["tile"], battle_message
	]
	info.text += "\n\nMoved: %s\nActed: %s" % [
		"yes" if unit["hasMoved"] else "no",
		"yes" if unit["hasActed"] else "no"
	]
	var status_names: Array[String] = []
	for status in unit.get("statuses", []):
		var status_id := String(status.get("id", ""))
		if status_effects.has(status_id):
			status_names.append("%s(%d)" % [status_effects[status_id].get("name", status_id), int(status.get("duration", 1))])
		else:
			status_names.append(status_id)
	if not status_names.is_empty():
		info.text += "\nStatus: " + ", ".join(status_names)
	for ability_id in unit["abilityIds"]:
		if not abilities_by_id.has(ability_id):
			continue
		var ability: Dictionary = abilities_by_id[ability_id]
		var button := Button.new()
		button.text = "%s  MP %d  R %d" % [ability["name"], ability["mpCost"], ability["range"]]
		button.disabled = unit["hasActed"] or unit["mp"] < ability["mpCost"]
		button.tooltip_text = "%s\n%s\nVFX: %s\nSFX: %s" % [
			ability["category"], ability["description"], ability["vfxId"], ability["sfxId"]
		]
		button.pressed.connect(func() -> void:
			command = "ability"
			selected_ability_id = ability_id
			battle_message = "Targeting " + ability["name"]
			_redraw_highlights()
			_update_ui()
		)
		skills.add_child(button)


func _handle_tile_click(tile: int) -> void:
	var clicked_unit := unit_at_tile(tile)
	if selected_unit >= 0 and command == "move" and can_move_to(selected_unit, tile):
		units[selected_unit]["tile"] = tile
		units[selected_unit]["hasMoved"] = true
		_place_unit(selected_unit)
		if battle_vfx != null:
			battle_vfx.flash_tile(tile_to_screen(tile), Color(0.2, 0.65, 1.0, 0.5))
		command = "inspect"
		battle_message = units[selected_unit]["name"] + " moved. Choose an action or end the unit turn."
	elif selected_unit >= 0 and command == "attack" and clicked_unit >= 0:
		_try_damage_target(clicked_unit, 1, 25, "Attack")
	elif selected_unit >= 0 and command == "ability" and clicked_unit >= 0:
		_try_ability(clicked_unit)
	elif clicked_unit >= 0 and units[clicked_unit]["team"] == "player":
		selected_unit = clicked_unit
		command = "inspect"
		selected_ability_id = ""
		battle_message = "Selected " + units[clicked_unit]["name"]
	_check_battle_end()
	_redraw_highlights()
	_update_ui()


func _try_ability(target_index: int) -> void:
	if units[selected_unit]["hasActed"]:
		battle_message = units[selected_unit]["name"] + " has already acted."
		return
	if selected_ability_id == "" or not abilities_by_id.has(selected_ability_id):
		battle_message = "Choose a skill first."
		return
	var ability: Dictionary = abilities_by_id[selected_ability_id]
	if units[selected_unit]["mp"] < ability["mpCost"]:
		battle_message = "Not enough MP."
		return
	var error: String = PTCombatResolverScript.can_target(units[selected_unit], units[target_index], ability, grid_width)
	if error != "":
		battle_message = error
		return

	units[selected_unit]["mp"] -= ability["mpCost"]
	_resolve_ability_effect(selected_unit, target_index, ability)
	units[selected_unit]["hasActed"] = true
	command = "inspect"
	selected_ability_id = ""
	_after_player_action()


func _resolve_ability_effect(caster_index: int, target_index: int, ability: Dictionary) -> void:
	var caster_tile: Dictionary = tiles[units[caster_index]["tile"]]
	var target_tile: Dictionary = tiles[units[target_index]["tile"]]
	var result: Dictionary = PTCombatResolverScript.resolve(units[caster_index], units[target_index], ability, caster_tile, target_tile)
	var damage: int = int(result.get("damage", 0))
	var healing: int = int(result.get("healing", 0))
	if damage > 0:
		_apply_damage(target_index, damage)
		if battle_vfx != null:
			battle_vfx.float_text(tile_to_screen(units[target_index]["tile"]), str(damage), Color(1.0, 0.22, 0.15, 1.0))
	elif healing > 0:
		units[target_index]["hp"] = min(units[target_index]["maxHp"], units[target_index]["hp"] + healing)
		if battle_vfx != null:
			battle_vfx.float_text(tile_to_screen(units[target_index]["tile"]), "+" + str(healing), Color(0.3, 1.0, 0.55, 1.0))
	if result.get("statuses", []).size() > 0:
		units[target_index] = PTStatusEffectSystemScript.apply_statuses(units[target_index], result["statuses"])
	if battle_vfx != null:
		battle_vfx.flash_tile(tile_to_screen(units[target_index]["tile"]), Color(0.72, 0.28, 1.0, 0.45))
	battle_message = "%s used %s. VFX %s / SFX %s" % [
		units[caster_index]["name"], ability["name"], ability["vfxId"], ability["sfxId"]
	]


func _try_damage_target(target_index: int, attack_range: int, damage: int, label: String) -> void:
	if units[selected_unit]["hasActed"]:
		battle_message = units[selected_unit]["name"] + " has already acted."
		return
	if units[target_index]["team"] == units[selected_unit]["team"]:
		battle_message = "Choose an enemy target."
		return
	if tile_distance(units[selected_unit]["tile"], units[target_index]["tile"]) > attack_range:
		battle_message = "Target is out of range."
		return
	var attack_ability := {
		"name": label,
		"category": "Melee",
		"power": damage,
		"range": attack_range,
		"mpCost": 0,
		"vfxId": "vfx_sword_slash",
		"sfxId": "sfx_weapon_hit",
	}
	_resolve_ability_effect(selected_unit, target_index, attack_ability)
	battle_message = "%s used %s." % [units[selected_unit]["name"], label]
	units[selected_unit]["hasActed"] = true
	command = "inspect"
	_after_player_action()


func _apply_damage(target_index: int, damage: int) -> void:
	units[target_index]["hp"] = max(0, units[target_index]["hp"] - damage)
	if units[target_index]["hp"] <= 0:
		units[target_index]["node"].visible = false


func _end_selected_unit_turn() -> void:
	if selected_unit < 0:
		return
	units[selected_unit]["hasMoved"] = true
	units[selected_unit]["hasActed"] = true
	battle_message = units[selected_unit]["name"] + " waits."
	_advance_after_player_unit_done()


func _after_player_action() -> void:
	if selected_unit < 0:
		return
	if units[selected_unit]["hasMoved"] and units[selected_unit]["hasActed"]:
		_advance_after_player_unit_done()


func _advance_after_player_unit_done() -> void:
	_check_battle_end()
	if battle_finished:
		_redraw_highlights()
		_update_ui()
		return
	if all_alive_players_done():
		_enemy_turn()
	else:
		selected_unit = next_available_player(selected_unit)
		if selected_unit >= 0:
			battle_message += " " + units[selected_unit]["name"] + " is ready."
	command = "inspect"
	selected_ability_id = ""
	_redraw_highlights()
	_update_ui()


func _enemy_turn() -> void:
	battle_message = "Enemies advance."
	for i in range(units.size()):
		if units[i]["team"] != "enemy" or units[i]["hp"] <= 0:
			continue
		_tick_unit_start(i)
		if units[i]["hp"] <= 0:
			continue
		var action: Dictionary = PTEnemyAIScript.choose_action(i, units, tiles, abilities_by_id, grid_width, grid_height)
		match String(action.get("type", "wait")):
			"ability":
				_enemy_use_ability(i, int(action["target"]), String(action["abilityId"]))
			"move":
				units[i]["tile"] = int(action["tile"])
				_place_unit(i)
				if battle_vfx != null:
					battle_vfx.flash_tile(tile_to_screen(units[i]["tile"]), Color(1.0, 0.45, 0.16, 0.35))
				var follow_up: Dictionary = PTEnemyAIScript.choose_action(i, units, tiles, abilities_by_id, grid_width, grid_height)
				if String(follow_up.get("type", "wait")) == "ability":
					_enemy_use_ability(i, int(follow_up["target"]), String(follow_up["abilityId"]))
			_:
				battle_message = units[i]["name"] + " waits."
	reset_player_actions()
	selected_unit = first_alive_unit("player")
	if selected_unit >= 0:
		_tick_unit_start(selected_unit)
	if selected_unit >= 0 and not battle_finished:
		battle_message += " Player turn. " + units[selected_unit]["name"] + " is ready."
	_check_battle_end()
	command = "inspect"
	selected_ability_id = ""
	_redraw_highlights()
	_update_ui()


func _enemy_attack(enemy_index: int, target_index: int) -> void:
	var fallback := {
		"name": "Strike",
		"category": "Melee",
		"power": 18,
		"range": 1,
		"mpCost": 0,
		"vfxId": "vfx_hit_spark",
		"sfxId": "sfx_weapon_hit",
	}
	_resolve_ability_effect(enemy_index, target_index, fallback)
	battle_message = units[enemy_index]["name"] + " strikes " + units[target_index]["name"] + "."


func _enemy_use_ability(enemy_index: int, target_index: int, ability_id: String) -> void:
	if not abilities_by_id.has(ability_id):
		_enemy_attack(enemy_index, target_index)
		return
	var ability: Dictionary = abilities_by_id[ability_id]
	var error: String = PTCombatResolverScript.can_target(units[enemy_index], units[target_index], ability, grid_width)
	if error != "":
		_enemy_attack(enemy_index, target_index)
		return
	units[enemy_index]["mp"] -= int(ability.get("mpCost", 0))
	_resolve_ability_effect(enemy_index, target_index, ability)


func best_step_toward(unit_index: int, target_tile: int) -> int:
	var unit: Dictionary = units[unit_index]
	var current: int = unit["tile"]
	var candidates := [
		current - grid_width,
		current + grid_width,
		current - 1,
		current + 1,
	]
	var best_tile := -1
	var best_distance := 9999
	for tile in candidates:
		if tile < 0 or tile >= grid_width * grid_height:
			continue
		if abs(tile_col(tile) - tile_col(current)) + abs(tile_row(tile) - tile_row(current)) != 1:
			continue
		if not can_enemy_move_to(tile):
			continue
		var dist := tile_distance(tile, target_tile)
		if dist < best_distance:
			best_distance = dist
			best_tile = tile
	return best_tile


func can_enemy_move_to(tile: int) -> bool:
	return tiles.has(tile) and tiles[tile]["walkable"] and unit_at_tile(tile) < 0


func can_move_to(unit_index: int, tile: int) -> bool:
	if units[unit_index]["hasMoved"]:
		return false
	var moving_unit: Dictionary = units[unit_index].duplicate(true)
	moving_unit["move"] = max(1, int(moving_unit.get("move", 3)) + PTStatusEffectSystemScript.movement_modifier(moving_unit, status_effects))
	var reachable: Dictionary = PTPathfinderScript.movement_range(moving_unit, tiles, grid_width, grid_height, occupied_tiles(unit_index))
	return reachable.has(tile)


func occupied_tiles(ignore_index: int = -1) -> Dictionary:
	var occupied := {}
	for i in range(units.size()):
		if i == ignore_index or units[i]["hp"] <= 0:
			continue
		occupied[units[i]["tile"]] = i
	return occupied


func _tick_unit_start(unit_index: int) -> void:
	if units[unit_index]["hp"] <= 0:
		return
	units[unit_index] = PTStatusEffectSystemScript.start_turn_tick(units[unit_index], status_effects)
	if tiles.has(units[unit_index]["tile"]):
		units[unit_index] = PTSurfaceSystemScript.apply_surface_tick(units[unit_index], tiles[units[unit_index]["tile"]], surfaces)
	if units[unit_index]["hp"] <= 0:
		units[unit_index]["node"].visible = false


func unit_at_tile(tile: int) -> int:
	for i in range(units.size()):
		if units[i]["hp"] > 0 and units[i]["tile"] == tile:
			return i
	return -1


func first_alive_unit(team: String) -> int:
	for i in range(units.size()):
		if units[i]["team"] == team and units[i]["hp"] > 0:
			return i
	return -1


func all_alive_players_done() -> bool:
	for unit in units:
		if unit["team"] == "player" and unit["hp"] > 0:
			if not unit["hasMoved"] or not unit["hasActed"]:
				return false
	return true


func next_available_player(after_index: int) -> int:
	if units.is_empty():
		return -1
	for offset in range(1, units.size() + 1):
		var index := (after_index + offset) % units.size()
		if units[index]["team"] == "player" and units[index]["hp"] > 0:
			if not units[index]["hasMoved"] or not units[index]["hasActed"]:
				return index
	return first_alive_unit("player")


func reset_player_actions() -> void:
	for i in range(units.size()):
		if units[i]["team"] == "player" and units[i]["hp"] > 0:
			units[i]["hasMoved"] = false
			units[i]["hasActed"] = false


func nearest_alive_unit(from_index: int, team: String) -> int:
	var best := -1
	var best_distance := 9999
	for i in range(units.size()):
		if units[i]["team"] != team or units[i]["hp"] <= 0:
			continue
		var distance := tile_distance(units[from_index]["tile"], units[i]["tile"])
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func _check_battle_end() -> void:
	if first_alive_unit("enemy") < 0:
		battle_finished = true
		battle_message = "Victory! The grasslands are clear."
	elif first_alive_unit("player") < 0:
		battle_finished = true
		battle_message = "Defeat. The party has fallen."


func tile_distance(a: int, b: int) -> int:
	return abs(tile_col(a) - tile_col(b)) + abs(tile_row(a) - tile_row(b))


func tile_col(tile: int) -> int:
	return tile % grid_width


func tile_row(tile: int) -> int:
	return int(tile / grid_width)


func tile_to_screen(tile: int) -> Vector2:
	var col := float(tile_col(tile))
	var row := float(tile_row(tile))
	var height := float(tiles[tile]["height"])
	return board_origin + Vector2(
		(col - row) * tile_width * 0.5,
		(col + row) * tile_height * 0.5 - height * height_step
	)


func screen_to_tile(position: Vector2) -> int:
	var local := position - board_origin
	var col := (local.x / (tile_width * 0.5) + local.y / (tile_height * 0.5)) * 0.5
	var row := (local.y / (tile_height * 0.5) - local.x / (tile_width * 0.5)) * 0.5
	var tile_col_id := int(floor(col + 0.5))
	var tile_row_id := int(floor(row + 0.5))
	if tile_col_id < 0 or tile_col_id >= grid_width or tile_row_id < 0 or tile_row_id >= grid_height:
		return -1
	return tile_row_id * grid_width + tile_col_id


func _redraw_highlights() -> void:
	for child in highlight_layer.get_children():
		child.queue_free()
	if selected_unit < 0:
		return

	for tile in range(grid_width * grid_height):
		var color := Color(1, 1, 1, 0.08)
		if tile == units[selected_unit]["tile"]:
			color = Color(1.0, 0.75, 0.18, 0.52)
		elif command == "move" and not units[selected_unit]["hasMoved"] and can_move_to(selected_unit, tile):
			color = Color(0.2, 0.65, 1.0, 0.38)
		elif command == "attack" and not units[selected_unit]["hasActed"] and unit_at_tile(tile) >= 0 and units[unit_at_tile(tile)]["team"] == "enemy":
			color = Color(1.0, 0.15, 0.12, 0.42)
		elif command == "ability" and not units[selected_unit]["hasActed"] and unit_at_tile(tile) >= 0:
			color = Color(0.72, 0.28, 1.0, 0.42)
		elif tile != hovered_tile:
			continue
		_add_diamond(tile, color)


func _add_diamond(tile: int, color: Color) -> void:
	var poly := Polygon2D.new()
	var half_w := tile_width * 0.5
	var half_h := tile_height * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(-half_w, 0),
	])
	poly.color = color
	poly.position = tile_to_screen(tile)
	poly.z_index = 80 + tile
	highlight_layer.add_child(poly)

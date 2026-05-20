class_name RunManager
extends Node

signal run_started(seed: int, heat_level: int)
signal run_ended(victory: bool)
signal stage_reward_ready(rewards: Dictionary)
signal run_node_changed(node: Dictionary)
signal boon_options_ready(options: Array[Dictionary])

var is_run_active: bool = false
var current_stage: int = 0
var run_seed: int = 0
var heat_level: int = 0
var run_aether: int = 0
var active_boons: Array[Dictionary] = []
var current_run: Dictionary = {}
var rng := RandomNumberGenerator.new()

func start_new_run(p_heat_level: int = 0, seed: int = -1) -> void:
	is_run_active = true
	current_stage = 0
	heat_level = max(p_heat_level, 0)
	run_aether = 0
	active_boons.clear()
	if seed >= 0:
		run_seed = seed
		rng.seed = seed
	else:
		rng.randomize()
		run_seed = int(rng.randi())
		rng.seed = run_seed
	current_run = FloorGenerator.generate_run(run_seed, 4)
	run_started.emit(run_seed, heat_level)
	run_node_changed.emit(get_current_node())

func get_current_node() -> Dictionary:
	if current_run.is_empty():
		return {}
	return FloorGenerator.get_current_node(current_run)

func complete_current_node() -> Dictionary:
	if current_run.is_empty():
		return {}
	current_run = FloorGenerator.complete_current_node(current_run)
	var node := get_current_node()
	if current_run.get("completed", false):
		end_run(true)
	else:
		run_node_changed.emit(node)
	return node

func get_selected_map_id(default_map_id: String = "ashvale_road_01") -> String:
	var node := get_current_node()
	if node.has("map_id"):
		return node.map_id
	return default_map_id

func end_run(victory: bool) -> void:
	is_run_active = false
	var meta: Node = get_node_or_null("/root/MetaProgression")
	if meta and run_aether > 0:
		meta.add_currency(Currency.SOUL_SHARDS, int(run_aether / 10))
		meta.save()
	run_ended.emit(victory)

func award_stage_reward(stage_index: int, is_elite: bool = false, is_boss: bool = false) -> Dictionary:
	var rewards := {
		Currency.SOUL_SHARDS: 4 + stage_index + heat_level,
		Currency.RUN_AETHER: 15 + (stage_index * 5),
	}
	if is_elite:
		rewards[Currency.OBSIDIAN] = 2 + int(heat_level / 2)
	if is_boss:
		rewards[Currency.OBSIDIAN] = rewards.get(Currency.OBSIDIAN, 0) + 5 + heat_level
		rewards[Currency.BOSS_TOKENS] = 1 + int(heat_level / 3)
	_apply_rewards(rewards)
	stage_reward_ready.emit(rewards)
	return rewards

func award_current_node_reward() -> Dictionary:
	var node := get_current_node()
	var floor_number := int(node.get("floor", current_stage + 1))
	var rewards := award_stage_reward(floor_number, bool(node.get("is_elite", false)), bool(node.get("is_boss", false)))
	return rewards

func _apply_rewards(rewards: Dictionary) -> void:
	var meta: Node = get_node_or_null("/root/MetaProgression")
	for currency_id: String in rewards.keys():
		var amount: int = int(rewards[currency_id])
		if currency_id == Currency.RUN_AETHER:
			run_aether += amount
		elif meta:
			meta.add_currency(currency_id, amount)
	if meta:
		meta.save()

func add_boon(boon: Dictionary) -> void:
	active_boons.append(boon)
	if not current_run.is_empty():
		var run_boons: Array = current_run.get("active_boons", [])
		run_boons.append(boon)
		current_run["active_boons"] = run_boons

func generate_boon_options(option_count: int = 3) -> Array[Dictionary]:
	var node := get_current_node()
	var floor_number := int(node.get("floor", current_stage + 1))
	var options := BoonDB.generate_boon_options(rng, floor_number, option_count)
	boon_options_ready.emit(options)
	return options

func get_reward_multiplier() -> float:
	return 1.0 + float(heat_level) * 0.12

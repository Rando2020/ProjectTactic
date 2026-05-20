extends Node

signal run_started(seed: int, heat_level: int)
signal run_ended(victory: bool)
signal stage_reward_ready(rewards: Dictionary)

var is_run_active: bool = false
var current_stage: int = 0
var run_seed: int = 0
var heat_level: int = 0
var run_aether: int = 0
var active_boons: Array[Dictionary] = []
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

	# Create RunState and store in GameState for MapGenerator + EliteSystem
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		gs.active_run = RunState.create(run_seed)
		gs.active_run.heat_level = heat_level

	run_started.emit(run_seed, heat_level)

func end_run(victory: bool) -> void:
	is_run_active = false
	var meta: Node = get_node_or_null("/root/MetaProgression")
	if meta and run_aether > 0:
		meta.add_currency(Currency.SOUL_SHARDS, int(run_aether / 10))
		if victory:
			# Bonus shards for completing the run
			meta.add_currency(Currency.SOUL_SHARDS, 20 + heat_level * 5)
			meta.add_currency(Currency.BOSS_TOKENS, 1)
		meta.save()
	# Clear run state
	var gs: Node = get_node_or_null("/root/GameState")
	if gs: gs.active_run = null
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
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.active_run:
		gs.active_run.active_boons.append(boon)

func get_reward_multiplier() -> float:
	return 1.0 + float(heat_level) * 0.12

## Returns heat_level — used by EliteSystem to scale difficulty
func get_heat_level() -> int:
	return heat_level

## How many floors total in this run
func get_total_floors() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.active_run: return gs.active_run.TOTAL_FLOORS
	return 10

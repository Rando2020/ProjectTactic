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

func start_new_run(p_heat_level: int = 0, run_seed_override: int = -1, vow_id: String = "", sigil_id: String = "") -> void:
	is_run_active = true
	current_stage = 0
	heat_level = max(p_heat_level, 0)
	run_aether = 0
	active_boons.clear()
	if run_seed_override >= 0:
		run_seed = run_seed_override
		rng.seed = run_seed_override
	else:
		rng.randomize()
		run_seed = int(rng.randi())
		rng.seed = run_seed

	# Create RunState and store in GameState for MapGenerator + EliteSystem
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		gs.active_run = RunState.create(run_seed)
		if not vow_id.is_empty():
			gs.active_run.equipped_vow_id = vow_id
		if not sigil_id.is_empty():
			gs.active_run.equipped_sigil_id = sigil_id
		if gs.has_method("seed_run_loadout"):
			gs.seed_run_loadout(gs.active_run)
		gs.active_run.heat_level = heat_level
		# Initialize run state tracking
		gs.unit_registry.clear()
		gs.run_floor_reached = 1
		gs.run_jp_earned = 0
		gs.pending_rewards.clear()
		gs.pending_loot.clear()
		gs.run_inventory.clear()
		gs.last_run_death.clear()

	run_started.emit(run_seed, heat_level)

func end_run(victory: bool) -> void:
	is_run_active = false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.active_run and gs.has_method("apply_loadout_xp"):
		var end_xp := VowSigilSystem.xp_for_run_end(gs.active_run.current_floor, victory, heat_level)
		gs.apply_loadout_xp(end_xp, "run_complete" if victory else "run_end")
	var meta: Node = get_node_or_null("/root/MetaProgression")
	if meta and run_aether > 0:
		meta.add_currency(Currency.SOUL_SHARDS, floori(float(run_aether) / 10.0))
		if victory:
			# Bonus shards for completing the run
			meta.add_currency(Currency.SOUL_SHARDS, 20 + heat_level * 5)
			meta.add_currency(Currency.BOSS_TOKENS, 1)
		meta.save()
	# Clear run state
	if gs: gs.active_run = null
	run_ended.emit(victory)

func award_stage_reward(stage_index: int, is_elite: bool = false, is_boss: bool = false) -> Dictionary:
	var rewards := {
		Currency.SOUL_SHARDS: 4 + stage_index + heat_level,
		Currency.RUN_AETHER: 15 + (stage_index * 5),
	}
	if is_elite:
		rewards[Currency.OBSIDIAN] = 2 + floori(float(heat_level) / 2.0)
	if is_boss:
		rewards[Currency.OBSIDIAN] = rewards.get(Currency.OBSIDIAN, 0) + 5 + heat_level
		rewards[Currency.BOSS_TOKENS] = 1 + floori(float(heat_level) / 3.0)
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

## Returns heat_level  used by EliteSystem to scale difficulty
func get_heat_level() -> int:
	return heat_level

## How many floors total in this run
func get_total_floors() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.active_run: return gs.active_run.TOTAL_FLOORS
	return 10

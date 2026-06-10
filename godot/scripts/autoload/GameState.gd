extends Node
# ============================================================
#  THE APPOINTED: AS ABOVE
#  GameState.gd  Main narrative state management
# ============================================================

#  Game state lives here. Other scripts connect to Godot signals
#  to respond to state changes.

#  TO SET UP:
#  Project  Project Settings  Autoload
#  Add: res://scripts/autoload/GameState.gd as "GameState"
# ============================================================

#  Signals
# UI connects to these to update when state changes

signal revelation_tier_changed(new_tier: int)
signal clarity_changed(new_clarity: int)
signal character_crack_event(char_id: String)
signal character_true_name_revealed(char_id: String, true_name: String)
signal boss_defeated(boss_id: String, killed_by: String)
signal soul_encountered(soul_id: String)
signal hub_character_met(hub_char_id: String)
signal run_started(run_number: int)
signal run_ended(run_number: int)

#  State Variables

# Meta
var game_title: String = "The Appointed: As Above"
var total_runs: int = 0
var current_run: int = 0

# Revelation
var revelation_tier: int = GameConfig.RevelationTier.TIER_1
var revelation_points: int = 0

# Clarity (per-run, resets each run)
var clarity: int = GameConfig.CLARITY.START

# Characters (the seven)
var characters: Dictionary = {}

# Relationships (intimacy between party members)
var relationships: Dictionary = {}

# Hub characters
var hub_characters: Dictionary = {}

# Soul encounters
var soul_encounters: Dictionary = {}

# Boss encounters
var boss_encounters: Dictionary = {}

# Narrative flags
var narrative_flags: Dictionary = {}

# Run history
var run_history: Array = []

#  Roguelike Run State

# Active run for roguelike progression
var active_run: RunState = null

# Battle results and rewards
var pending_rewards: Dictionary = {}           # Rewards from current battle
var pending_loot: Array = []                   # Items from current battle
var run_inventory: Array = []                  # All items collected this run
var run_floor_reached: int = 0                 # Highest floor reached this run
var last_run_death: Dictionary = {}            # Death context for ResultsScreen
var selected_map_index: int = 0                # For debug/editor map selection
var pending_boon_offers: Array = []            # Boon choices for next screen
var unit_registry: Dictionary = {}             # Persistent unit state across battles (uid -> {base_hp, current_hp, status, etc.})

# Run statistics
var run_jp_earned: int = 0                     # Total JP earned this run
var runs_completed: int = 0                    # Total successful runs
var best_floor_reached: int = 0                # Highest floor ever reached

#  Initialization

func _ready():
	_initialize_state()

func _initialize_state():
	_init_characters()
	_init_relationships()
	_init_hub_characters()
	_init_soul_encounters()
	_init_boss_encounters()
	_init_narrative_flags()

func _init_characters():
	var char_ids = ["aeryn", "cael", "brennan", "solan", "mira", "tobias", "seren"]
	for char_id in char_ids:
		characters[char_id] = {
			"id": char_id,
			"human_name": "",  # Will be set by Characters.gd
			"true_name": null,
			"true_name_fragments": 0,
			"costume_integrity": 100,
			"current_job": "",
			"level": 1,
			"intimacy_unlocked": {},
			"hub_visits": 0,
			"crack_event_triggered": false,
			"resolution_reached": false,
			"current_dialogue_tier": 1,
		}

func _init_relationships():
	# All 21 pairwise relationships (7 choose 2)
	var pairs = [
		["aeryn", "cael"], ["aeryn", "brennan"], ["aeryn", "solan"],
		["aeryn", "mira"], ["aeryn", "tobias"], ["aeryn", "seren"],
		["cael", "brennan"], ["cael", "solan"], ["cael", "mira"],
		["cael", "tobias"], ["cael", "seren"],
		["brennan", "solan"], ["brennan", "mira"], ["brennan", "tobias"],
		["brennan", "seren"],
		["solan", "mira"], ["solan", "tobias"], ["solan", "seren"],
		["mira", "tobias"], ["mira", "seren"],
		["tobias", "seren"]
	]
	for pair in pairs:
		var key = "_".join(pair)
		relationships[key] = {
			"intimacy": 0,
			"moments_shared": [],
			"tension_dialogue_unlocked": false
		}

func _init_hub_characters():
	var hub_ids = ["azrael", "lilith", "aurora", "ereshkigal", "somnus", "osiris", "anamnesis", "archivist"]
	for hub_id in hub_ids:
		hub_characters[hub_id] = {
			"met": false,
			"conversations": 0,
			"gifts_given": [],
			"dialogue_tier": 1
		}
	# Special fields
	hub_characters.archivist["knows_the_truth"] = false
	hub_characters.somnus["dream_reveals_given"] = []
	hub_characters.anamnesis["visits"] = 0
	hub_characters.anamnesis["fragments_returned"] = []
	hub_characters.osiris["introduced"] = false

func _init_soul_encounters():
	var soul_ids = ["adam", "eve", "cain", "moses", "elijah", "david", "job"]
	for soul_id in soul_ids:
		soul_encounters[soul_id] = {
			"met": false,
			"encounter_state": null,  # "early", "middle", "late"
			"departed": false
		}

func _init_boss_encounters():
	var boss_ids = ["the_righteous_one", "the_keeper", "the_devoted", "the_wrathful", "the_mirror"]
	for boss_id in boss_ids:
		boss_encounters[boss_id] = {
			"total_fights": 0,
			"last_killed_by": null,
			"player_fled": false,
			"talk_path_attempted": false,
			"talk_path_completed": false,
			"current_dialogue_loop": null
		}
	# Mirror special fields
	boss_encounters.the_mirror["total_appearances"] = 0
	boss_encounters.the_mirror["characters_targeted"] = []
	boss_encounters.the_mirror["last_target"] = null

func _init_narrative_flags():
	# Tier 1
	narrative_flags["first_enemy_hesitation"] = false
	narrative_flags["first_run_complete"] = false
	# Tier 2
	narrative_flags["enemy_spoke_words"] = false
	# Crack events
	for char_id in ["aeryn", "cael", "brennan", "solan", "mira", "tobias", "seren"]:
		narrative_flags[char_id + "_crack_event_complete"] = false
	# More flags added as needed during gameplay

#  Run Lifecycle

func begin_run():
	current_run += 1
	total_runs += 1
	clarity = GameConfig.CLARITY.START
	run_started.emit(current_run)

func end_run(summary: Dictionary):
	# summary: {soulsHelped, bossesDefeated, bossesFled, clarityAtEnd, etc.}
	run_history.append({
		"run": current_run,
		"summary": summary
	})
	run_ended.emit(current_run)


#  Roguelike Battle Flow

func apply_victory(map_id: String, rewards: Dictionary, player_unit_ids: Array[String]) -> void:
	"""Called when a battle ends in victory. Updates pending rewards for UI."""
	pending_rewards = rewards.duplicate()
	pending_loot.clear()
	last_run_death.clear()


func apply_defeat(death_info: Dictionary) -> void:
	"""Called when a battle ends in defeat. Stores death context."""
	last_run_death = death_info.duplicate()
	pending_rewards.clear()
	pending_loot.clear()

#  Revelation

func gain_revelation(points: int, source: String = ""):
	revelation_points += points
	var new_tier = GameConfig.calculate_tier_from_points(revelation_points)
	if new_tier != revelation_tier:
		revelation_tier = new_tier
		revelation_tier_changed.emit(revelation_tier)

#  Clarity

func gain_clarity(amount: int, reason: String = ""):
	clarity = clampi(clarity + amount, GameConfig.CLARITY.MIN, GameConfig.CLARITY.MAX)
	clarity_changed.emit(clarity)

func lose_clarity(amount: int, reason: String = ""):
	clarity = clampi(clarity - amount, GameConfig.CLARITY.MIN, GameConfig.CLARITY.MAX)
	clarity_changed.emit(clarity)

#  Character Arcs

func trigger_crack_event(char_id: String):
	if not characters.has(char_id):
		return

	var char = characters[char_id]
	char.crack_event_triggered = true
	char.costume_integrity = max(0, char.costume_integrity + GameConfig.COSTUME_INTEGRITY.CRACK_EVENT)

	gain_clarity(GameConfig.CLARITY.CRACK_EVENT_TRIGGERED)
	gain_revelation(30, "crack_event_" + char_id)
	narrative_flags[char_id + "_crack_event_complete"] = true

	character_crack_event.emit(char_id)

func lower_costume(char_id: String, amount: int):
	if not characters.has(char_id):
		return
	var char = characters[char_id]
	char.costume_integrity = max(0, char.costume_integrity + amount)  # amount is negative

func add_true_name_fragment(char_id: String):
	if not characters.has(char_id):
		return
	var char = characters[char_id]
	char.true_name_fragments += 1
	lower_costume(char_id, GameConfig.COSTUME_INTEGRITY.TRUE_NAME_FRAGMENT)
	gain_clarity(GameConfig.CLARITY.TRUE_NAME_FRAGMENT)

func reveal_true_name(char_id: String, true_name: String):
	if not characters.has(char_id):
		return
	var char = characters[char_id]
	char.true_name = true_name
	char.costume_integrity = 0
	gain_revelation(50, "true_name_" + char_id)
	gain_clarity(GameConfig.CLARITY.TRUE_NAME_FRAGMENT)
	character_true_name_revealed.emit(char_id, true_name)

func reach_resolution(char_id: String):
	if not characters.has(char_id):
		return
	characters[char_id].resolution_reached = true
	gain_revelation(100, "resolution_" + char_id)

#  Relationships

func get_relationship_key(char_a: String, char_b: String) -> String:
	var pair = [char_a, char_b]
	pair.sort()
	return "_".join(pair)

func gain_intimacy(char_a: String, char_b: String, amount: int):
	var key = get_relationship_key(char_a, char_b)
	if not relationships.has(key):
		return
	relationships[key].intimacy += amount
	if relationships[key].intimacy >= 15:
		relationships[key].tension_dialogue_unlocked = true

func add_shared_moment(char_a: String, char_b: String, moment_id: String):
	var key = get_relationship_key(char_a, char_b)
	if not relationships.has(key):
		return
	if moment_id not in relationships[key].moments_shared:
		relationships[key].moments_shared.append(moment_id)

#  Hub Characters

func meet_hub_character(hub_char_id: String):
	if not hub_characters.has(hub_char_id):
		return
	if hub_characters[hub_char_id].met:
		return  # Already met
	hub_characters[hub_char_id].met = true
	gain_revelation(10, "hub_met_" + hub_char_id)
	hub_character_met.emit(hub_char_id)

func hub_conversation(hub_char_id: String):
	if not hub_characters.has(hub_char_id):
		return
	hub_characters[hub_char_id].conversations += 1
	gain_clarity(GameConfig.CLARITY.HUB_RELATIONSHIP_MOMENT)

	# Auto-advance dialogue tier
	var convos = hub_characters[hub_char_id].conversations
	var current_tier = hub_characters[hub_char_id].dialogue_tier
	if convos >= 8:
		hub_characters[hub_char_id].dialogue_tier = min(5, current_tier + 1)
	elif convos >= 4:
		hub_characters[hub_char_id].dialogue_tier = min(4, current_tier + 1)

func give_hub_gift(hub_char_id: String, gift_id: String):
	if not hub_characters.has(hub_char_id):
		return
	if gift_id in hub_characters[hub_char_id].gifts_given:
		return  # Already gave this gift
	hub_characters[hub_char_id].gifts_given.append(gift_id)
	gain_revelation(15, "gift_" + hub_char_id)

func archivist_learns_truth():
	hub_characters.archivist.knows_the_truth = true
	gain_revelation(40, "archivist_truth")
	narrative_flags.archivist_tier4_conversation = true

#  Souls

func meet_soul(soul_id: String):
	if not soul_encounters.has(soul_id):
		return
	if soul_encounters[soul_id].met:
		return
	soul_encounters[soul_id].met = true
	soul_encounters[soul_id].encounter_state = "early"
	gain_revelation(20, "soul_" + soul_id)
	gain_clarity(GameConfig.CLARITY.SOUL_CONVERSATION)
	soul_encountered.emit(soul_id)

func advance_soul_encounter(soul_id: String, new_state: String):
	if not soul_encounters.has(soul_id):
		return
	soul_encounters[soul_id].encounter_state = new_state
	gain_revelation(25, "soul_advance_" + soul_id)

func soul_departs(soul_id: String):
	if not soul_encounters.has(soul_id):
		return
	soul_encounters[soul_id].departed = true
	soul_encounters[soul_id].encounter_state = "departed"
	gain_revelation(40, "soul_depart_" + soul_id)
	narrative_flags[soul_id + "_departed"] = true

#  Bosses

func boss_fight_complete(boss_id: String, killed_by_char_id: String):
	if not boss_encounters.has(boss_id):
		return
	boss_encounters[boss_id].total_fights += 1
	boss_encounters[boss_id].last_killed_by = killed_by_char_id
	boss_encounters[boss_id].current_dialogue_loop = total_runs
	boss_defeated.emit(boss_id, killed_by_char_id)

func boss_talk_path_attempted(boss_id: String):
	if not boss_encounters.has(boss_id):
		return
	boss_encounters[boss_id].talk_path_attempted = true

func boss_talk_path_complete(boss_id: String):
	if not boss_encounters.has(boss_id):
		return
	boss_encounters[boss_id].talk_path_completed = true
	gain_revelation(60, "boss_talk_" + boss_id)
	gain_clarity(GameConfig.CLARITY.BOSS_DIALOGUE_UNLOCKED)

func player_fled_boss(boss_id: String):
	if not boss_encounters.has(boss_id):
		return
	boss_encounters[boss_id].player_fled = true
	lose_clarity(abs(GameConfig.CLARITY.FALLEN_ARGUMENT_FLED))

func mirror_appeared(target_char_id: String):
	var mirror = boss_encounters.the_mirror
	mirror.total_appearances += 1
	if target_char_id not in mirror.characters_targeted:
		mirror.characters_targeted.append(target_char_id)
	mirror.last_target = target_char_id

#  Narrative Flags

func set_flag(flag_name: String, value: bool = true):
	narrative_flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return narrative_flags.get(flag_name, false)

#  Getters

func get_character(char_id: String) -> Dictionary:
	return characters.get(char_id, {})

func get_relationship(char_a: String, char_b: String) -> Dictionary:
	var key = get_relationship_key(char_a, char_b)
	return relationships.get(key, {})

func get_hub_character(hub_char_id: String) -> Dictionary:
	return hub_characters.get(hub_char_id, {})

func get_soul_encounter(soul_id: String) -> Dictionary:
	return soul_encounters.get(soul_id, {})

func get_boss_encounter(boss_id: String) -> Dictionary:
	return boss_encounters.get(boss_id, {})

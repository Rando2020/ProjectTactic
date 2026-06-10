## RunBonuses.gd
## Pure RefCounted. Reads active_boons from the current run,
## returns a flat bonuses dict that CombatResolver and BattleManager consume.
## Call RunBonuses.compute() once per battle  cache the result.

class_name RunBonuses
extends RefCounted

## Compute bonuses from a boon list. Returns a flat Dictionary.
static func compute(active_boons: Array = []) -> Dictionary:
	var bonuses := {
		"elemental_mult":      { "fire":1.0,"water":1.0,"thunder":1.0,"holy":1.0,"dark":1.0,"wind":1.0,"blizzard":1.0 },
		"jp_multiplier":       1.0,
		"heal_bonus":          0,
		"surge_window_bonus":  0.0,
		"surge_damage_bonus":  0.0,
		"react_echo_chance":   0.0,
		"chain_bonus":         0,
		"phoenix_vitality":    false,
		"phoenix_used":        false,
		"first_hit_guard":     false,
		"min_hp_guard":        false,
		"death_flare_damage":  0,
		"brand_bonus":         0.0,
		"on_elite_kill_hp":    0,
		"on_elite_kill_tmpr":  0,
		"between_battle_heal": 0.0,
		"max_temper_bonus":    0,
		"double_strike_chance":0.0,
		"battle_start_effects":[],
		"vaelthorn_kill_hp":   0,
		"vaelthorn_kill_ether":0,
		"stun_drain":          0,
		"move_bonus":          0,
		"battle_damage_mult":  1.0,
		## Tactical boon fields  attack shape-changers
		"cleave":                   false,  # hit 3 tiles wide on every attack
		"piercing_line":            false,  # pierce through to unit behind target
		"knockback_chance":         0.0,    # % chance to push target 1 tile back
		"echo_strike_chance":       0.0,    # % chance to hit same target a second time
		"battle_fury_bonus":        0.0,    # bonus damage % when attacker moved first
		"coup_de_grace_threshold":  0.0,    # HP% threshold for CdG bonus (0 = off)
		"coup_de_grace_bonus":      0.0,    # bonus damage % vs low-HP targets
		"sundering_amount":         0,      # flat max-Temper reduction per hit
		"bloodthirst_pct":          0.0,    # % of damage dealt returned as HP
		"ruinous_field_interval":   0,      # ignite tile every N hits (0 = off)
		"reaping_step_range":       0,      # free-move tiles on kill (0 = off)
		"iron_momentum_min_move":   0,      # min tiles moved to prime iron momentum (0 = off)
		"wrath_crescendo_per_kill": 0.0,    # damage% bonus per kill this battle
	}

	for boon: Dictionary in active_boons:
		var fx: Dictionary = boon.get("effect", {})
		match fx.get("type",""):

			"elemental_bonus", "elemental_damage_bonus":
				var el: String = fx.get("element","")
				if el and bonuses["elemental_mult"].has(el):
					bonuses["elemental_mult"][el] += fx.get("bonus", 0.0)
				bonuses["heal_bonus"]  += int(fx.get("heal_bonus", 0))
				bonuses["chain_bonus"] += int(fx.get("chain_bonus", 0))

			"jp_multiplier":
				bonuses["jp_multiplier"] *= fx.get("mult", 1.0)

			"surge_boost":
				bonuses["surge_window_bonus"] += fx.get("window_bonus", 0.0)
				bonuses["surge_damage_bonus"] += fx.get("damage_bonus", 0.0)

			"stat_bonus":
				if fx.get("stat","") in ["temper","max_temper"]:
					bonuses["max_temper_bonus"] += int(fx.get("amount", 0))
				elif fx.get("stat","") in ["move", "movement"]:
					bonuses["move_bonus"] += int(fx.get("amount", 0))
				bonuses["move_bonus"] += int(fx.get("move_bonus", 0))

			"reaction_echo":
				bonuses["react_echo_chance"] += fx.get("chance", 0.0)

			"on_elite_kill":
				bonuses["on_elite_kill_hp"]   += int(fx.get("heal_hp", 0))
				bonuses["on_elite_kill_tmpr"] += int(fx.get("heal_temper", 0))

			"between_battle_heal":
				bonuses["between_battle_heal"] += fx.get("percent", 0.0)

			"once_per_battle":
				if fx.get("outcome","") == "survive_at_1_hp":
					bonuses["phoenix_vitality"] = true

			"battle_start":
				bonuses["battle_start_effects"].append(fx)
				if fx.has("damage_bonus"):
					bonuses["battle_damage_mult"] *= 1.0 + float(fx.get("damage_bonus", 0.0))
				if fx.get("trigger","") in ["vaelthorn_curse_all", "curse_all"]:
					var ok = fx.get("on_kill", {})
					bonuses["vaelthorn_kill_hp"]    += int(ok.get("hp", 0))
					bonuses["vaelthorn_kill_ether"] += int(ok.get("ether", 0))

			"passive":
				match fx.get("id",""):
					"brand":        bonuses["brand_bonus"]          += fx.get("bonus", 0.5)
					"double_strike":bonuses["double_strike_chance"]  += fx.get("chance", 0.25)
					"first_hit_guard": bonuses["first_hit_guard"]    = true
					"luminarch_covenant": bonuses["min_hp_guard"]    = true
					"death_flare":  bonuses["death_flare_damage"]   += int(fx.get("damage", 28))
					"torvahk_fury": bonuses["stun_drain"]           += int(fx.get("stun_drain", 20))

			"tactical":
				match fx.get("id",""):
					"cleave":
						bonuses["cleave"] = true
					"piercing_line":
						bonuses["piercing_line"] = true
					"knockback":
						bonuses["knockback_chance"] += fx.get("chance", 0.0)
					"echo_strike":
						bonuses["echo_strike_chance"] += fx.get("chance", 0.0)
					"battle_fury":
						bonuses["battle_fury_bonus"] += fx.get("bonus", 0.0)
					"coup_de_grace":
						# Use the highest threshold (most forgiving), stack the bonus
						bonuses["coup_de_grace_threshold"] = maxf(
							bonuses["coup_de_grace_threshold"], fx.get("threshold", 0.0))
						bonuses["coup_de_grace_bonus"] += fx.get("bonus", 0.0)
					"sundering":
						bonuses["sundering_amount"] += int(fx.get("amount", 0))
					"bloodthirst":
						bonuses["bloodthirst_pct"] += fx.get("percent", 0.0)
					"ruinous_field":
						var rf_interval: int = int(fx.get("interval", 3))
						if bonuses["ruinous_field_interval"] == 0:
							bonuses["ruinous_field_interval"] = rf_interval
						else:
							# Shorter interval = more frequent = better
							bonuses["ruinous_field_interval"] = mini(
								bonuses["ruinous_field_interval"], rf_interval)
					"reaping_step":
						bonuses["reaping_step_range"] = maxi(
							bonuses["reaping_step_range"], int(fx.get("range", 3)))
					"iron_momentum":
						var im_min: int = int(fx.get("min_move", 3))
						if bonuses["iron_momentum_min_move"] == 0:
							bonuses["iron_momentum_min_move"] = im_min
						else:
							# Lower threshold = easier to trigger = better
							bonuses["iron_momentum_min_move"] = mini(
								bonuses["iron_momentum_min_move"], im_min)
					"wrath_crescendo":
						bonuses["wrath_crescendo_per_kill"] += fx.get("per_kill", 0.0)
	return bonuses


## Convenience: fetch bonuses for the current run from GameState.
static func for_current_run() -> Dictionary:
	var gs: Node = null
	if Engine.has_singleton("GameState"):
		gs = Engine.get_singleton("GameState")
	elif Engine.get_main_loop():
		gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if not gs or not gs.get("active_run") or not gs.active_run:
		return compute(_v02_playtest_starter_boons())
	var active_boons: Array = gs.active_run.active_boons.duplicate(true)
	if active_boons.is_empty():
		active_boons.append_array(_v02_playtest_starter_boons())
	return compute(active_boons)


static func _v02_playtest_starter_boons() -> Array[Dictionary]:
	if not ProjectSettings.get_setting("project_tactic/playtest/auto_battle", false):
		return []
	return [{
		"id": "battle_fury",
		"name": "Battle Fury",
		"rarity": "rare",
		"icon": "*",
		"category": "tactical",
		"desc": "Moving before attacking this turn adds 30% bonus damage to that strike.",
		"effect": {"type": "tactical", "id": "battle_fury", "bonus": 0.30},
		"lane": "movement",
	}]

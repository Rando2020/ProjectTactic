## RunBonuses.gd
## Pure RefCounted. Reads active_boons from the current run,
## returns a flat bonuses dict that CombatResolver and BattleManager consume.
## Call RunBonuses.compute() once per battle — cache the result.

class_name RunBonuses
extends RefCounted

## Compute bonuses from a boon list. Returns a flat Dictionary.
static func compute(active_boons: Array = []) -> Dictionary:
	var b := {
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
	}

	for boon: Dictionary in active_boons:
		var fx: Dictionary = boon.get("effect", {})
		match fx.get("type",""):

			"elemental_bonus", "elemental_damage_bonus":
				var el: String = fx.get("element","")
				if el and b["elemental_mult"].has(el):
					b["elemental_mult"][el] += fx.get("bonus", 0.0)
				b["heal_bonus"]  += int(fx.get("heal_bonus", 0))
				b["chain_bonus"] += int(fx.get("chain_bonus", 0))

			"jp_multiplier":
				b["jp_multiplier"] *= fx.get("mult", 1.0)

			"surge_boost":
				b["surge_window_bonus"] += fx.get("window_bonus", 0.0)
				b["surge_damage_bonus"] += fx.get("damage_bonus", 0.0)

			"stat_bonus":
				if fx.get("stat","") in ["temper","max_temper"]:
					b["max_temper_bonus"] += int(fx.get("amount", 0))

			"reaction_echo":
				b["react_echo_chance"] += fx.get("chance", 0.0)

			"on_elite_kill":
				b["on_elite_kill_hp"]   += int(fx.get("heal_hp", 0))
				b["on_elite_kill_tmpr"] += int(fx.get("heal_temper", 0))

			"between_battle_heal":
				b["between_battle_heal"] += fx.get("percent", 0.0)

			"once_per_battle":
				if fx.get("outcome","") == "survive_at_1_hp":
					b["phoenix_vitality"] = true

			"battle_start":
				b["battle_start_effects"].append(fx)
				if fx.get("trigger","") == "vaelthorn_curse_all":
					var ok = fx.get("on_kill", {})
					b["vaelthorn_kill_hp"]    += int(ok.get("hp", 0))
					b["vaelthorn_kill_ether"] += int(ok.get("ether", 0))

			"passive":
				match fx.get("id",""):
					"brand":        b["brand_bonus"]          += fx.get("bonus", 0.5)
					"double_strike":b["double_strike_chance"]  += fx.get("chance", 0.25)
					"first_hit_guard": b["first_hit_guard"]    = true
					"luminarch_covenant": b["min_hp_guard"]    = true
					"death_flare":  b["death_flare_damage"]   += int(fx.get("damage", 28))
					"torvahk_fury": b["stun_drain"]           += int(fx.get("stun_drain", 20))
	return b


## Convenience: fetch bonuses for the current run from GameState.
static func for_current_run() -> Dictionary:
	var gs: Node = Engine.get_singleton("GameState") if Engine.has_singleton("GameState") \
		else (Engine.get_main_loop().root.get_node_or_null("/root/GameState") if Engine.get_main_loop() else null)
	if not gs or not gs.get("active_run") or not gs.active_run:
		return compute([])
	return compute(gs.active_run.active_boons)

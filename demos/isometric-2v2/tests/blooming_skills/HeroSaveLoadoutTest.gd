extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Saved custom loadouts must remain authoritative outside the local additions.
func run() -> void:
	GameState._init_defaults()
	GameState.unit_registry.zane.learned_abilities = ["haste", "cure"]
	GameState.unit_registry.zane.equipped_abilities = ["cure", "haste"]
	GameState.unit_registry.kael.learned_abilities = ["heavy_slash", "unresolved_saved_skill"]
	GameState.unit_registry.kael.equipped_abilities = ["defend", "heavy_slash"]
	var registry := GameState.unit_registry.duplicate(true)
	GameState.save()
	var saved := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	for iteration in 2:
		await boot()
		check(manager.units.zane.unit_data.abilities == ["cure", "haste"], "custom equipped Zane choices retained without duplicate Haste")
		check(manager.units.kael.unit_data.abilities == ["defend", "heavy_slash", "delay_strike", "cover_ally", "iron_wall"], "custom equipped Kael choices retained without duplicate Heavy Slash")
		check(GameState.unit_registry == registry, "full custom registry unchanged by spawning")
		check(GameState.knows_ability("kael", "unresolved_saved_skill"), "unresolved saved ownership retained")
		check(not GameState.knows_ability("kael", "delay_strike"), "practice-only skill never becomes owned")
		check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved, "custom save bytes unchanged by spawning")
		await cleanup()
	finish()

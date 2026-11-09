extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func _ready() -> void: call_deferred("run")
func run() -> void:
	var battle = preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	for i in 20: await get_tree().process_frame
	var manager = battle.battle_manager
	var initial_turn: String = manager.active_unit_id
	for compact in [true,false,true]:
		check(battle.set_compact_skins(compact), "skin comparison changes")
		var active = manager.units.get(manager.active_unit_id)
		if is_instance_valid(active):
			check(battle.battle_ui._active_portrait.texture == battle.battle_ui._framed_portrait(active.unit_data.id), "active portrait refreshes immediately")
		var melee = manager.units.kael
		var idle_texture: Texture2D = melee._sprite.texture
		for pose in ["anticipation", "contact"]:
			check(melee.set_melee_pose(pose) == not compact, "authored melee poses only in original mode")
			if compact:
				check(melee._sprite.texture == idle_texture, "compact attack preserves class identity")
				check(melee._idle_visual.is_empty(), "compact attack does not capture original pose")
			else:
				check(melee._sprite.texture.resource_path.contains("character-vanguard-"), "original authored melee retained")
		check(melee.set_melee_pose("idle"), "idle cleanup accepted")
		check(melee._sprite.texture == idle_texture, "melee cleanup restores correct skin")
		for id in ["zane", "kael"]:
			var ui = battle.battle_ui
			ui._set_preview_portrait(ui._preview_actor_portrait, AssetRegistry.get_character_portrait_candidates(id)[0])
			check(ui._preview_actor_portrait.texture == ui._framed_portrait(id), "forecast matches appearance")
			check(manager._portrait_path(manager.units[id]).contains("compact/frames") == compact, "action banner matches appearance")
		for mode in [false,true]:
			battle.set_stage_mode(mode)
			for angle in 4:
				if mode: battle.rotate_stage(1)
				for id in ["zane","kael"]:
					var unit = manager.units[id]
					for facing in ["N","E","S","W"]:
						unit.set_facing(facing)
						check(unit._sprite.texture != null, "texture exists")
						check(unit.uses_compact_skin() == compact, "correct skin")
						if compact:
							check(unit._sprite.texture.resource_path.contains("compact/frames"), "compact path")
							check(unit._sprite.texture.get_size() == Vector2(800,800), "normalized frame")
							check(not unit._sprite.flip_h, "mirror baked and documented")
							check(unit._sprite.offset == Vector2(0,-340), "same foot anchor")
					check(battle.battle_ui._framed_portrait(unit.unit_data.id) != null, "portrait exists")
				check(manager.active_unit_id == initial_turn, "skins do not spend turn")
	manager.is_resolving_action = true
	check(not battle.set_compact_skins(false), "skin change blocked while resolving")
	manager.is_resolving_action = false
	battle.queue_free()
	await get_tree().process_frame
	print("Compact skins: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

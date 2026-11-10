extends Node

var failures := 0
func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var gs = get_tree().root.get_node("GameState")
	check(gs.has_method("get_character_stats"), "Shared character stats API must exist")
	check(gs.has_method("equip_item"), "Validated equipment API must exist")
	if failures:
		get_tree().quit(1)
		return
	var baseline: Dictionary = gs.serialize_state()
	gs._init_defaults()
	var before: Dictionary = gs.get_character_stats("kael")
	check(not gs.equip_item("kael", "missing", "main_hand"), "Unowned items rejected")
	check(not gs.equip_item("kael", "training-blade", "head"), "Wrong slot rejected")
	check(gs.equip_item("kael", "training-blade", "main_hand"), "Owned starter weapon equips")
	var equipped: Dictionary = gs.get_character_stats("kael")
	check(equipped.physical == before.physical + 6, "Weapon changes shared physical stat")
	var factory = load("res://scenes/Battle.tscn").instantiate()
	var unit: Unit = factory._make_party_unit("kael", Vector2i.ZERO)
	for stat in ["hp", "mp", "physical", "magic", "speed", "max_temper", "max_ether", "attack_range_min", "attack_range_max"]:
		check(unit.unit_data.base_stats.get(stat) == equipped[stat], "Battle and roster agree on " + stat)
	check(unit.hp == equipped.hp, "Spawn initializes resources from final stats")
	unit.free()
	factory.free()
	check(not gs.equip_item("mira", "training-blade", "main_hand"), "One item cannot equip to two units")
	var encoded: Dictionary = JSON.parse_string(JSON.stringify(gs.serialize_state()))
	gs.restore_state(encoded)
	check(gs.get_character_stats("kael").physical == equipped.physical, "Equipment survives save serialization")
	check(gs.unequip_item("kael", "main_hand"), "Unequip succeeds")
	check(gs.get_character_stats("kael").physical == before.physical, "Unequip removes bonus without drift")
	check(gs.equip_item("kael", "copper-band", "accessory"), "HP accessory equips")
	gs.unit_registry.kael.current_hp = gs.get_character_stats("kael").hp
	gs.unequip_item("kael", "accessory")
	check(gs.unit_registry.kael.current_hp == before.hp, "Unequip clamps current HP to new maximum")
	gs.equip_item("kael", "copper-band", "accessory")
	check(gs.unit_registry.kael.current_hp == before.hp, "Re-equipping does not heal")
	gs.unit_registry.kael.equipment = {"main_hand": "Training Blade"}
	check(gs.get_character_stats("kael").physical == before.physical, "Legacy display names never grant phantom bonuses")
	var screen = load("res://scenes/CharacterScreen.tscn").instantiate()
	screen._selected_uid = "kael"
	get_tree().root.add_child(screen)
	screen._set_tab("Equipment")
	for frame in range(6): await get_tree().process_frame
	var equip_button: Button
	for button in screen.find_children("*", "Button", true, false):
		if button.text.begins_with("Training Blade") and not button.is_queued_for_deletion():
			equip_button = button
	check(equip_button != null, "Equipment screen exposes owned starter blade")
	if equip_button:
		equip_button.pressed.emit()
	for frame in range(6): await get_tree().process_frame
	check(gs.equipment_owner("training-blade") == "kael", "Actual equipment button commits ownership")
	check(screen._stats_for("kael").physical == equipped.physical, "UI refresh reflects equipped stats")
	gs.unit_registry.kael.job_jp = {"squire": 90}
	screen._set_tab("Jobs")
	for frame in range(6): await get_tree().process_frame
	screen._on_change_job("warder")
	check(gs.unit_registry.kael.current_job_id == "warder", "Job screen changes earned job")
	gs.save()
	check(gs.load_save() and gs.equipment_owner("training-blade") == "kael", "Disk save and reload retain equipment")
	screen.queue_free()
	for frame in range(6): await get_tree().process_frame
	gs.restore_state(baseline)
	print("Character equipment: ", failures, " failures")
	get_tree().quit(1 if failures else 0)

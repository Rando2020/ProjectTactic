extends CanvasLayer
class_name PTBattleHUD


signal command_selected(command: String)
signal ability_selected(ability_id: String)


var info: RichTextLabel
var skills: VBoxContainer


func build() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(930, 24)
	panel.size = Vector2(320, 720)
	add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Battle Commands"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for command in ["move", "attack", "wait"]:
		var button := Button.new()
		button.text = "End Unit Turn" if command == "wait" else command.capitalize()
		button.pressed.connect(func() -> void: command_selected.emit(command))
		box.add_child(button)

	info = RichTextLabel.new()
	info.name = "Info"
	info.fit_content = true
	info.bbcode_enabled = true
	info.custom_minimum_size = Vector2(280, 230)
	box.add_child(info)

	var skills_title := Label.new()
	skills_title.text = "Skills"
	box.add_child(skills_title)

	skills = VBoxContainer.new()
	skills.name = "Skills"
	box.add_child(skills)


func set_unit(unit: Dictionary, job_name: String, command: String, message: String) -> void:
	if info == null:
		return
	info.text = "[b]%s[/b]\n%s\nHP %d/%d\nMP %d/%d\nMove %d  Jump %d\nCommand: %s\nTile: %d\n\n%s\n\nMoved: %s\nActed: %s" % [
		unit["name"], job_name, unit["hp"], unit["maxHp"], unit["mp"], unit["maxMp"],
		unit["move"], unit["jump"], command, unit["tile"], message,
		"yes" if unit["hasMoved"] else "no",
		"yes" if unit["hasActed"] else "no"
	]


func set_abilities(unit: Dictionary, abilities_by_id: Dictionary) -> void:
	if skills == null:
		return
	for child in skills.get_children():
		child.queue_free()
	for ability_id in unit.get("abilityIds", []):
		if not abilities_by_id.has(ability_id):
			continue
		var ability: Dictionary = abilities_by_id[ability_id]
		var button := Button.new()
		button.text = "%s  MP %d  R %d" % [ability["name"], ability["mpCost"], ability["range"]]
		button.disabled = unit["hasActed"] or unit["mp"] < ability["mpCost"]
		button.tooltip_text = "%s\n%s\nVFX: %s\nSFX: %s" % [
			ability["category"], ability["description"], ability["vfxId"], ability["sfxId"]
		]
		button.pressed.connect(func() -> void: ability_selected.emit(ability_id))
		skills.add_child(button)

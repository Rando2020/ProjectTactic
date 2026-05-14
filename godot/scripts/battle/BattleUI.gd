class_name BattleUI
extends CanvasLayer

var battle_manager: BattleManager

var _phase_label: Label
var _unit_name: Label
var _hp_label: Label
var _mp_label: Label
var _temper_label: Label
var _ether_label: Label
var _hp_bar: ProgressBar
var _log_labels: Array[Label] = []
var _timeline_labels: Array[Label] = []
var _move_btn: Button
var _attack_btn: Button
var _wait_btn: Button
var _result_label: Label

const LOG_SIZE := 8
const TIMELINE_SLOTS := 6


func setup(manager: BattleManager) -> void:
	battle_manager = manager
	battle_manager.log_message.connect(_on_log)
	battle_manager.phase_changed.connect(_on_phase_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.turn_order.timeline_updated.connect(_on_timeline_updated)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Dark background panel on right half
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.14)
	bg.position = Vector2(640, 0)
	bg.size = Vector2(640, 720)
	add_child(bg)

	var root := VBoxContainer.new()
	root.position = Vector2(648, 8)
	root.size = Vector2(624, 704)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Mission header
	var mission_lbl := Label.new()
	mission_lbl.text = "ASHVALE ROAD"
	mission_lbl.add_theme_font_size_override("font_size", 20)
	mission_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	mission_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(mission_lbl)

	_phase_label = Label.new()
	_phase_label.text = "Initializing…"
	_phase_label.add_theme_font_size_override("font_size", 13)
	_phase_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_phase_label)

	root.add_child(_separator())

	# Active unit panel
	root.add_child(_section_label("ACTIVE UNIT"))

	_unit_name = Label.new()
	_unit_name.text = "—"
	_unit_name.add_theme_font_size_override("font_size", 22)
	_unit_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	root.add_child(_unit_name)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size.y = 14
	_hp_bar.value = 100
	root.add_child(_hp_bar)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	root.add_child(stats_row)
	_hp_label     = _stat_label(stats_row, "HP")
	_mp_label     = _stat_label(stats_row, "MP")
	_temper_label = _stat_label(stats_row, "TMP")
	_ether_label  = _stat_label(stats_row, "ETH")

	root.add_child(_separator())

	# Command buttons
	root.add_child(_section_label("COMMANDS"))
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	root.add_child(btn_row)
	_move_btn   = _cmd_btn(btn_row, "Move",   _on_move)
	_attack_btn = _cmd_btn(btn_row, "Attack", _on_attack)
	_cmd_btn(btn_row, "Wait", _on_wait)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.add_theme_font_size_override("font_size", 13)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root.add_child(_result_label)

	root.add_child(_separator())

	# Turn timeline
	root.add_child(_section_label("TURN ORDER (next %d)" % TIMELINE_SLOTS))
	var timeline_row := HBoxContainer.new()
	timeline_row.add_theme_constant_override("separation", 4)
	root.add_child(timeline_row)
	for i in range(TIMELINE_SLOTS):
		var slot := _timeline_slot(timeline_row)
		_timeline_labels.append(slot)

	root.add_child(_separator())

	# Battle log
	root.add_child(_section_label("BATTLE LOG"))
	for i in range(LOG_SIZE):
		var lbl := Label.new()
		lbl.text = ""
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(lbl)
		_log_labels.append(lbl)


# ── Builder helpers ───────────────────────────────────────────────────────────

func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.25, 0.28, 0.32))
	return sep


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	return lbl


func _stat_label(parent: Control, prefix: String) -> Label:
	var lbl := Label.new()
	lbl.text = "%s: —" % prefix
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	return lbl


func _cmd_btn(parent: Control, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 40)
	btn.disabled = true
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _timeline_slot(parent: Control) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(88, 52)
	var lbl := Label.new()
	lbl.text = "—"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(lbl)
	parent.add_child(panel)
	return lbl


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_log(text: String) -> void:
	for i in range(LOG_SIZE - 1, 0, -1):
		_log_labels[i].text = _log_labels[i - 1].text
	_log_labels[0].text = "> " + text


func _on_phase_changed(phase: String) -> void:
	_phase_label.text = phase.replace("_", " ")
	var is_player := phase == "PLAYER_TURN"
	if _move_btn:   _move_btn.disabled   = not is_player
	if _attack_btn: _attack_btn.disabled = not is_player


func _on_turn_started(unit_id: String, _team: String) -> void:
	if not battle_manager:
		return
	var unit: Unit = battle_manager.units.get(unit_id)
	if not unit:
		return
	_unit_name.text = unit.display_name
	var max_hp := unit.unit_data.base_stats.hp
	_hp_bar.max_value = max_hp
	_hp_bar.value = unit.hp
	_hp_label.text    = "HP: %d/%d" % [unit.hp, max_hp]
	_mp_label.text    = "MP: %d" % unit.mp
	_temper_label.text = "TMP: %d" % unit.temper
	_ether_label.text  = "ETH: %d" % unit.ether


func _on_timeline_updated(ordered_units: Array) -> void:
	for i in range(TIMELINE_SLOTS):
		if i < ordered_units.size():
			_timeline_labels[i].text = ordered_units[i].get("display_name", "?")
		else:
			_timeline_labels[i].text = "—"


func _on_battle_won(rewards: Dictionary) -> void:
	_phase_label.text = "VICTORY!"
	_result_label.text = "+%dg  +%dJP" % [rewards.get("gold", 0), rewards.get("jp", 0)]
	if _move_btn:   _move_btn.disabled   = true
	if _attack_btn: _attack_btn.disabled = true


func _on_battle_lost() -> void:
	_phase_label.text = "DEFEATED"
	_result_label.text = "All units fallen."
	if _move_btn:   _move_btn.disabled   = true
	if _attack_btn: _attack_btn.disabled = true


# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_move() -> void:
	if battle_manager: battle_manager.select_command("move")

func _on_attack() -> void:
	if battle_manager: battle_manager.select_command("attack")

func _on_wait() -> void:
	if battle_manager: battle_manager.select_command("wait")

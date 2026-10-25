extends "res://tests/browser_qa/BattleBrowserQA.gd"
## Additive duel observations; existing Quickstep/showcase observer is untouched.
var _completed_sword: Dictionary = {}

func _ready() -> void:
	super._ready()
	battle.get_node("BattleManager").turn_ended.connect(_on_duel_turn_ended)

func _on_presentation_signal(value: String, kind: String, reference: WeakRef) -> void:
	super._on_presentation_signal(value, kind, reference)
	if kind != "phase" or value != "charge": return
	var owner = reference.get_ref()
	var sentinel := get_node_or_null("/root/ZaneDuelTerminalSentinel")
	if not is_instance_valid(owner) or sentinel == null: return
	var context: Dictionary = owner.context
	if str(context.get("actor_id", "")) != "zane" or str(context.get("ability_id", "")) != "": return
	# Sword has one actual admitted recipient at its destination. Bind identity
	# now, before defeat, turn handoff or another action can change the roster.
	for unit: Unit in battle.battle_manager.units.values():
		if is_instance_valid(unit) and unit.team == "enemy" and unit.grid_pos == context.destination:
			sentinel.observe_sword_owner(owner, battle, unit)
			break

func _on_duel_turn_ended(actor_id: String) -> void:
	var manager: BattleManager = battle.get_node("BattleManager")
	if actor_id != "zane" or not manager.active_unit_has_acted or not _completed_sword.is_empty(): return
	# This existing signal fires AFTER lifecycle recovery and serial increment,
	# BEFORE action flags clear and normal initiative/AI/Results advances.
	_completed_sword = snapshot()
	_completed_sword.erase("completed_sword")
	_completed_sword.erase("sword_presentation")
	var sentinel := get_node_or_null("/root/ZaneDuelTerminalSentinel")
	var effects := get_node_or_null("/root/VFX")
	if sentinel != null and effects != null:
		# finish_action may already have queued this owner on a slow frame.
		# Inspect the exact still-valid original owner, not _owners()'s filtered
		# drawable list. queue_free is deferred until after this signal returns.
		var key := "%s:%s" % [manager.get_instance_id(), manager.action_lifecycle.ticket]
		for owner in effects.get_children():
			if not owner.has_signal("phase_presented"): continue
			if str(owner.context.get("action_key", "")) == key and str(owner.context.get("actor_id", "")) == "zane" and str(owner.context.get("ability_id", "")) == "":
				_completed_sword["sword_owner"] = {"key": key, "instance_id": str(owner.get_instance_id()), "queued_at_handoff": owner.is_queued_for_deletion()}
				sentinel.observe_completed_sword(_completed_sword, owner, battle)
				break

func _unit_record(unit: Unit) -> Dictionary:
	var record := super._unit_record(unit)
	record["archetype"] = unit.unit_data.id if unit.unit_data != null else ""
	return record

func snapshot() -> Dictionary:
	var record := super.snapshot()
	var targets: Array = []
	var grid: TacticalGrid = battle.tactical_grid
	for candidate: Unit in battle.battle_manager.units.values():
		if is_instance_valid(candidate) and candidate.hp > 0 and candidate.grid_pos in grid.attack_tiles:
			var target := _unit_record(candidate)
			target["point"] = _point(grid.get_global_transform_with_canvas() * grid._grid_to_local(candidate.grid_pos))
			targets.append(target)
	record["legal_attack_targets"] = targets
	record["duel"] = {"mode": GameState.practice_session.get("mode", ""),
		"rig3d": GameState.practice_session.get("rig3d", false),
		"zane_showcase": GameState.practice_session.get("zane_showcase", false)}
	record["completed_sword"] = _completed_sword.duplicate(true)
	var sentinel := get_node_or_null("/root/ZaneDuelTerminalSentinel")
	record["sword_cleanup"] = sentinel.sword_cleanup.duplicate(true) if sentinel != null else {}
	record["sword_presentation"] = sentinel.sword_presentation.duplicate(true) if sentinel != null else {}
	return record

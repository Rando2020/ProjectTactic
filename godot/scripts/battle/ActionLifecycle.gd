## One admission and contact permit per primary combat action.
## Combat calculations stay in CombatResolver; this object owns only sequencing.
extends RefCounted

var phase := "idle"
var ticket := 0
var _actor: WeakRef
var _target: WeakRef

func begin(actor: Node, target: Node = null) -> int:
	if phase != "idle" or not _living(actor) or (target != null and not _living(target)):
		return 0
	ticket += 1
	_actor = weakref(actor)
	_target = weakref(target) if target != null else null
	phase = "anticipation"
	return ticket

func contact(action_ticket: int) -> bool:
	if action_ticket != ticket or phase != "anticipation":
		return false
	if not _living(_actor.get_ref()) or (_target != null and not _living(_target.get_ref())):
		finish(action_ticket)
		return false
	phase = "contact"
	return true

func recover(action_ticket: int) -> bool:
	if action_ticket != ticket or phase != "contact":
		return false
	phase = "recovery"
	var actor = _actor.get_ref() if _actor != null else null
	if is_instance_valid(actor) and actor.has_method("recover_melee_pose"):
		actor.recover_melee_pose()
	return true

func finish(action_ticket: int) -> void:
	if action_ticket == ticket:
		if _actor != null:
			var actor = _actor.get_ref()
			if is_instance_valid(actor) and actor.has_method("reset_melee_pose"):
				actor.reset_melee_pose()
		phase = "idle"
		_actor = null
		_target = null

func cancel() -> void:
	finish(ticket)
	ticket += 1 # A late callback can never finish a newer action.

func _living(unit: Node) -> bool:
	return is_instance_valid(unit) and unit.is_inside_tree() and not unit.is_queued_for_deletion() and unit.get("hp") > 0

func presentation_valid(action_ticket: int) -> bool:
	return action_ticket == ticket and phase == "anticipation" and _actor != null and _living(_actor.get_ref()) and (_target == null or _living(_target.get_ref()))

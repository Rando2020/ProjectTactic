extends Node
## Read-only, bounded original-owner cleanup and terminal evidence. No controls.
const EVIDENCE_LIMIT := 512
var completed_sword: Dictionary = {}
var sword_presentation: Dictionary = {}
var _sampled_labels: Dictionary = {}
var sword_cleanup: Dictionary = {}
var _owner_ref: WeakRef
var _battle_ref: WeakRef
var _effect_refs: Array[WeakRef] = []
var _voice_refs: Array[WeakRef] = []
var _reaction_refs: Array[WeakRef] = []

func observe_sword_owner(owner: Node, battle: Node, recipient: Unit) -> void:
	if not sword_presentation.is_empty(): return
	if not is_instance_valid(owner) or not is_instance_valid(recipient): return
	var context: Dictionary = owner.context
	if str(context.get("actor_id", "")) != "zane" or str(context.get("ability_id", "")) != "": return
	_owner_ref = weakref(owner)
	_battle_ref = weakref(battle)
	sword_presentation = {"key": str(context.action_key), "owner_instance_id": str(owner.get_instance_id()),
		"recipient_id": recipient.unit_id, "recipient_instance_id": str(recipient.get_instance_id()),
		"opened_frame": Engine.get_process_frames(), "samples": [], "overflow": false, "binding_error": ""}

func _observe_outcome_labels() -> void:
	if sword_presentation.is_empty() or not sword_presentation.binding_error.is_empty() or not sword_cleanup.is_empty(): return
	var owner = _owner_ref.get_ref()
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion(): return
	if str(owner.context.get("action_key", "")) != sword_presentation.key:
		sword_presentation.binding_error = "original owner changed action key"
		return
	# Direct children of the exact admitted owner only. No expected-text lookup,
	# foreign action samples, or strong references to production objects.
	for child in owner.get_children():
		if not child is Label or str(child.get_meta("zane_effect_role", "")) != "outcome": continue
		if child.is_queued_for_deletion() or not child.is_visible_in_tree() or child.modulate.a <= 0.01 or child.self_modulate.a <= 0.01: continue
		var identity := str(child.get_instance_id())
		if _sampled_labels.has(identity): continue
		if sword_presentation.samples.size() >= EVIDENCE_LIMIT:
			sword_presentation.overflow = true
			return
		_sampled_labels[identity] = true
		sword_presentation.samples.append({"frame": Engine.get_process_frames(), "key": sword_presentation.key,
			"owner_instance_id": sword_presentation.owner_instance_id, "recipient_id": sword_presentation.recipient_id,
			"recipient_instance_id": sword_presentation.recipient_instance_id,
			"role": "outcome", "instance_id": identity, "text": child.text, "visible": true,
			"point": [child.global_position.x, child.global_position.y]})

func observe_completed_sword(observation: Dictionary, owner: Node, battle: Node) -> void:
	if not completed_sword.is_empty(): return
	completed_sword = observation.duplicate(true)
	if sword_presentation.is_empty() or _owner_ref.get_ref() != owner:
		# Fail closed; cleanup still observes the actual handoff owner.
		sword_presentation = {"binding_error": "handoff owner was not observed at admission", "samples": [], "overflow": false}
	_owner_ref = weakref(owner)
	_battle_ref = weakref(battle)
	# Copy weak references only. Never retain or clean up production objects.
	if owner._fx.size() + owner._voices.size() + owner._reactions.size() > EVIDENCE_LIMIT:
		sword_presentation.overflow = true
		return
	for effect in owner._fx:
		if is_instance_valid(effect): _effect_refs.append(weakref(effect))
	for voice in owner._voices:
		if is_instance_valid(voice): _voice_refs.append(weakref(voice))
	for reaction: Dictionary in owner._reactions: _reaction_refs.append(reaction.ref)

func _observe_cleanup() -> void:
	if completed_sword.is_empty() or not sword_cleanup.is_empty(): return
	var key: String = completed_sword.sword_owner.key
	var owner = _owner_ref.get_ref()
	var battle = _battle_ref.get_ref()
	var owner_alive: bool = is_instance_valid(owner) and owner.is_inside_tree()
	var live_effects := 0
	var voices := 0
	var reactions := 0
	for reference in _effect_refs:
		var effect = reference.get_ref()
		if is_instance_valid(effect) and effect.is_inside_tree(): live_effects += 1
	for reference in _voice_refs:
		var voice = reference.get_ref()
		if is_instance_valid(voice) and voice.playing: voices += 1
	for reference in _reaction_refs:
		var visual = reference.get_ref()
		if is_instance_valid(visual):
			var mark: Variant = visual.get_meta(&"zane_impact_reaction", {})
			if mark is Dictionary and str(mark.get("owner", "")) == key: reactions += 1
	var battle_removed: bool = not is_instance_valid(battle) or not battle.is_inside_tree()
	var kick: Variant = null if battle_removed else battle._zane_kick_remaining
	if owner_alive or live_effects > 0 or voices > 0 or reactions > 0 or (kick != null and kick != 0): return
	sword_cleanup = {"frame": Engine.get_process_frames(), "key": key,
		"owner_instance_id": completed_sword.sword_owner.instance_id,
		"owner_alive": owner_alive, "live_effects": live_effects, "playing_voices": voices,
		"reaction_marks": reactions, "camera_kick_remaining": kick, "battle_removed": battle_removed}

	sword_presentation["closed_frame"] = sword_cleanup.frame
	_owner_ref = null
	_battle_ref = null
	_effect_refs.clear()
	_voice_refs.clear()
	_reaction_refs.clear()
	_sampled_labels.clear()

func snapshot() -> Dictionary:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene) or not scene is ResultsScreen: return {}
	return {"schema": 2, "frame": Engine.get_process_frames(), "phase": "RESULTS",
		"duel": {"mode": GameState.practice_session.get("mode", "")},
		"completed_sword": completed_sword.duplicate(true), "sword_cleanup": sword_cleanup.duplicate(true),
		"sword_presentation": sword_presentation.duplicate(true),
		"terminal": {"state": GameState.practice_session.get("state", ""), "scene": scene.scene_file_path}}

func _process(_delta: float) -> void:
	_observe_outcome_labels()
	_observe_cleanup()
	if not OS.has_feature("web"): return
	var observation := snapshot()
	if not observation.is_empty():
		JavaScriptBridge.eval("window.__projectTacticQA = " + JSON.stringify(observation) + ";", true)

class_name RandomLegalPolicy
extends RefCounted

## Deterministic baseline that samples uniformly from the normalized legal action list.
## This is intentionally weak. Its value is as a reproducible control policy.

var policy_id := "random-legal-v1"
var _rng := RandomNumberGenerator.new()


func configure(seed: int) -> void:
	_rng.seed = seed


func choose_action(actions: Array[Dictionary]) -> Dictionary:
	if actions.is_empty():
		return {}
	var index := _rng.randi_range(0, actions.size() - 1)
	return actions[index].duplicate(true)

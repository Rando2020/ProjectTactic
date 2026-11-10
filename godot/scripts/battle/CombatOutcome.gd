## Read-only probabilities for ONE direct hit; excludes counters and follow-up procs.
## Damage values come from the existing forecast, never from another damage formula.
class_name CombatOutcome
extends RefCounted

static func project(preview: Dictionary) -> Dictionary:
	if bool(preview.get("is_heal", false)) or bool(preview.get("is_buff", false)) or preview.has("amount_label"):
		return {}
	var hp := maxi(0, int(preview.get("hp_before", 0)))
	if hp == 0:
		return {}
	var normal := maxi(0, int(preview.get("damage", 0)))
	var critical := maxi(0, int(preview.get("crit_damage", normal)))
	var hit := clampf(float(preview.get("hit_pct", 100)) / 100.0, 0.0, 1.0)
	# Resolver rolls critical chance only after the hit succeeds.
	var crit := clampf(float(preview.get("crit_pct", 0)) / 100.0, 0.0, 1.0)
	var normal_probability := hit * (1.0 - crit)
	var critical_probability := hit * crit
	var ko_probability := 0.0
	if normal >= hp:
		ko_probability += normal_probability
	if critical >= hp:
		ko_probability += critical_probability
	return {
		"miss_probability": 1.0 - hit,
		"normal_probability": normal_probability,
		"critical_probability": critical_probability,
		"normal_hp_after": maxi(0, hp - normal),
		"critical_hp_after": maxi(0, hp - critical),
		"ko_probability": ko_probability,
		"expected_hp_loss": normal_probability * mini(hp, normal) + critical_probability * mini(hp, critical),
	}

static func ko_label(outcome: Dictionary) -> String:
	if outcome.is_empty():
		return ""
	var probability: float = outcome.ko_probability
	if probability <= 0.0:
		return ""
	if probability >= 1.0:
		return "Guaranteed KO on this hit"
	return "KO chance %.1f%% on this hit" % (probability * 100.0)

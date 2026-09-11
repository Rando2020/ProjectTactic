class_name AdaptiveIntentBias
extends RefCounted

## Applies a bounded, inspectable nudge to pre-existing enemy intent candidates.
## The base tactical score always remains the majority of the decision.

const MAX_TOTAL_DELTA := 24.0
const MAX_RELATIVE_DELTA := 0.18
const TARGET_PRIORITY_POINTS := 18.0
const RANGED_PRESSURE_POINTS := 8.0
const AOE_EXTRA_TARGET_POINTS := 7.0
const MIN_CONFIDENCE := 0.25
const TELEGRAPH_DELTA := 4.0


static func score_candidate(candidate: Dictionary, model: AdaptiveOpponentModel) -> Dictionary:
	var result := candidate.duplicate(true)
	var base := float(candidate.get("base_score", 0.0))
	result["base_score"] = base
	result["adaptive_delta"] = 0.0
	result["adaptive_score"] = base
	result["adaptation"] = {}
	if model == null or model.confidence() < MIN_CONFIDENCE:
		return result

	var reasons: Array[String] = []
	var raw_delta := 0.0
	var target_id := str(candidate.get("target_id", ""))
	if not target_id.is_empty():
		var priority := model.target_priority(target_id)
		if priority > 0.0:
			raw_delta += priority * TARGET_PRIORITY_POINTS
			if priority >= 0.45:
				reasons.append("high observed contribution")
		var ranged := model.ranged_pressure_signal(target_id)
		if ranged > 0.0:
			raw_delta += ranged * RANGED_PRESSURE_POINTS
			if ranged >= 0.45:
				reasons.append("repeated ranged pressure")

	var area_targets := maxi(int(candidate.get("area_target_count", 1)), 1)
	if area_targets > 1:
		var aoe_signal := model.aoe_adaptation_signal()
		if aoe_signal > 0.0:
			raw_delta += aoe_signal * float(area_targets - 1) * AOE_EXTRA_TARGET_POINTS
			if aoe_signal >= 0.35:
				reasons.append("repeated player clustering")

	var relative_cap := maxf(absf(base) * MAX_RELATIVE_DELTA, 4.0)
	var cap := minf(MAX_TOTAL_DELTA, relative_cap)
	var delta := clampf(raw_delta, 0.0, cap)
	result["adaptive_delta"] = delta
	result["adaptive_score"] = base + delta
	if delta >= TELEGRAPH_DELTA and not reasons.is_empty():
		result["adaptation"] = {
			"delta": delta,
			"confidence": model.confidence(),
			"reasons": reasons,
			"summary": "Adapted to %s" % ", ".join(reasons),
		}
	return result


static func rank_candidates(candidates: Array[Dictionary], model: AdaptiveOpponentModel) -> Array[Dictionary]:
	var scored: Array[Dictionary] = []
	for candidate in candidates:
		scored.append(score_candidate(candidate, model))
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := float(a.get("adaptive_score", a.get("base_score", 0.0)))
		var b_score := float(b.get("adaptive_score", b.get("base_score", 0.0)))
		if is_equal_approx(a_score, b_score):
			return str(a.get("candidate_id", "")) < str(b.get("candidate_id", ""))
		return a_score > b_score
	)
	return scored

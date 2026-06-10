class_name TelemetryTuning
extends RefCounted

const IDEAL_MAX_TURNS := 22
const SLOW_TURNS := 28
const IDEAL_MAX_PLAYER_TURNS := 16
const SLOW_PLAYER_TURNS := 22
const DAMAGE_TAKEN_FLOOR := 120
const DAMAGE_TAKEN_RATIO := 0.55
const CLOSE_CALL_LIMIT := 3
const MIN_BOON_TRIGGERS := 1
const MIN_BOON_SAMPLE_PLAYER_TURNS := 12
const MIN_BOON_SAMPLE_DAMAGE := 250
const TERRAIN_DAMAGE_IMPACT := 20
const TERRAIN_HAZARD_IMPACT := 2
const MIN_TERRAIN_SAMPLE_PLAYER_TURNS := 12


static func targets() -> Dictionary:
	return {
		"ideal_max_turns": IDEAL_MAX_TURNS,
		"slow_turns": SLOW_TURNS,
		"ideal_max_player_turns": IDEAL_MAX_PLAYER_TURNS,
		"slow_player_turns": SLOW_PLAYER_TURNS,
		"damage_taken_floor": DAMAGE_TAKEN_FLOOR,
		"damage_taken_ratio": DAMAGE_TAKEN_RATIO,
		"close_call_limit": CLOSE_CALL_LIMIT,
		"min_boon_triggers": MIN_BOON_TRIGGERS,
		"min_boon_sample_player_turns": MIN_BOON_SAMPLE_PLAYER_TURNS,
		"min_boon_sample_damage": MIN_BOON_SAMPLE_DAMAGE,
		"terrain_damage_impact": TERRAIN_DAMAGE_IMPACT,
		"terrain_hazard_impact": TERRAIN_HAZARD_IMPACT,
		"min_terrain_sample_player_turns": MIN_TERRAIN_SAMPLE_PLAYER_TURNS,
	}


static func notes(telemetry: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var turns := int(telemetry.get("turns_taken", 0))
	var player_turns := int(telemetry.get("player_turns", 0))
	var damage_dealt := int(telemetry.get("damage_dealt", 0))
	var damage_taken := int(telemetry.get("damage_taken", 0))
	var healing_used := int(telemetry.get("healing_used", 0))
	var allies_downed := int(telemetry.get("allies_downed", 0))
	var close_calls := int(telemetry.get("close_calls", 0))
	var boon_triggers := int(telemetry.get("boon_triggers", 0))
	var terrain_damage := int(telemetry.get("terrain_damage", 0))
	var terrain_hazards := int(telemetry.get("terrain_hazards_triggered", 0))
	var outcome := str(telemetry.get("outcome", "in_progress"))
	var sample_ready := outcome != "in_progress" \
			or player_turns >= MIN_BOON_SAMPLE_PLAYER_TURNS \
			or damage_dealt >= MIN_BOON_SAMPLE_DAMAGE
	var terrain_sample_ready := outcome != "in_progress" \
			or player_turns >= MIN_TERRAIN_SAMPLE_PLAYER_TURNS
	var damage_pressure: int = max(DAMAGE_TAKEN_FLOOR, int(float(damage_dealt) * DAMAGE_TAKEN_RATIO))

	if turns > SLOW_TURNS or player_turns > SLOW_PLAYER_TURNS:
		out.append("Too slow: battle length is above the v0.2 target.")
	elif turns > IDEAL_MAX_TURNS or player_turns > IDEAL_MAX_PLAYER_TURNS:
		out.append("Long but acceptable: pacing is near the upper v0.2 edge.")
	if allies_downed > 0 or close_calls >= CLOSE_CALL_LIMIT or damage_taken > damage_pressure:
		out.append("Too punishing: incoming pressure may be crowding out player agency.")
	if healing_used > 0 and damage_taken > damage_dealt:
		out.append("Recovery strain: healing is compensating for too much incoming damage.")
	if sample_ready and boon_triggers < MIN_BOON_TRIGGERS:
		out.append("Boons not firing: reward build choices may feel quiet.")
	if terrain_hazards >= TERRAIN_HAZARD_IMPACT or terrain_damage >= TERRAIN_DAMAGE_IMPACT:
		out.append("Terrain mattered: hazard positioning affected the fight.")
	elif terrain_sample_ready and terrain_hazards == 0 and terrain_damage == 0:
		out.append("Terrain quiet: long fights need more hazard pressure or board incentives.")
	if out.is_empty():
		if outcome == "in_progress":
			out.append("Live sample: keep playing before tuning final pacing.")
		else:
			out.append("Healthy test: telemetry stayed within the v0.2 target range.")
	return out


static func target_summary() -> String:
	return "v0.2 Targets: <=%d turns ideal, <=%d player turns, <%d%% damage pressure, %d+ boon triggers after %d player turns or %d damage, %d+ terrain damage matters." % [
		IDEAL_MAX_TURNS,
		IDEAL_MAX_PLAYER_TURNS,
		int(round(DAMAGE_TAKEN_RATIO * 100.0)),
		MIN_BOON_TRIGGERS,
		MIN_BOON_SAMPLE_PLAYER_TURNS,
		MIN_BOON_SAMPLE_DAMAGE,
		TERRAIN_DAMAGE_IMPACT,
	]

## ImpactJuice.gd
## Pure-logic recipes for hit and spell "juice". RefCounted, headless-testable.
## Never touches nodes, never changes combat authority: it only turns an
## already-resolved outcome into presentation numbers that VFXManager /
## BattleJuiceEffects / BattleScene execute.
##
## Punchy hit (5 beats):  flash white -> sharp sound -> directional particles
##                        -> knockback -> screen shake + hitstop freeze.
## Staged spell (8 beats): charge -> spikes along path -> grow toward target
##                        -> fan out (tilted side spikes) -> crack the floor
##                        -> big finish (flash ring + cluster) -> shatter -> linger.

class_name ImpactJuice
extends RefCounted

const FRAME := 1.0 / 60.0
const TIERS: Array[String] = ["light", "normal", "heavy", "critical", "finisher"]
const MAX_HITSTOP_MS := 140

## Per-tier hit numbers. Hitstop is capped so turns never feel laggy.
const HIT_TIERS := {
	"light":    {"flash_frames": 2, "hitstop_ms": 45,  "shake_px": 2.0, "shake_sec": 0.10, "knockback_px": 4.0,  "sparks": 8,  "spark_speed": 140.0, "pitch": 1.12},
	"normal":   {"flash_frames": 3, "hitstop_ms": 65,  "shake_px": 3.5, "shake_sec": 0.13, "knockback_px": 7.0,  "sparks": 12, "spark_speed": 170.0, "pitch": 1.00},
	"heavy":    {"flash_frames": 3, "hitstop_ms": 85,  "shake_px": 5.0, "shake_sec": 0.16, "knockback_px": 10.0, "sparks": 16, "spark_speed": 200.0, "pitch": 0.94},
	"critical": {"flash_frames": 4, "hitstop_ms": 110, "shake_px": 7.0, "shake_sec": 0.20, "knockback_px": 14.0, "sparks": 22, "spark_speed": 240.0, "pitch": 0.88},
	"finisher": {"flash_frames": 5, "hitstop_ms": 140, "shake_px": 8.0, "shake_sec": 0.24, "knockback_px": 18.0, "sparks": 28, "spark_speed": 260.0, "pitch": 0.82},
}

## Fraction of target max HP that reaches each tier (light below the first).
const TIER_HP_FRACTIONS := [0.08, 0.18, 0.32]

## Element skins for the staged spell. Shape params feed one spike generator.
## width: base half-width as a fraction of length. jag: edge noise (0 = clean).
## lean: how far spikes tilt with travel direction. linger: atmosphere kind.
const SPELL_SKINS := {
	"blizzard": {"core": Color(0.92, 0.98, 1.0), "body": Color(0.45, 0.80, 1.0), "glow": Color(0.55, 0.85, 1.0, 0.55), "width": 0.20, "jag": 0.10, "lean": 0.35, "linger": "snow",   "crack": Color(0.70, 0.92, 1.0, 0.85), "hit_cue": "juice_shatter"},
	"fire":     {"core": Color(1.0, 0.95, 0.60), "body": Color(1.0, 0.45, 0.08), "glow": Color(1.0, 0.55, 0.10, 0.55), "width": 0.28, "jag": 0.25, "lean": 0.55, "linger": "embers", "crack": Color(1.0, 0.40, 0.05, 0.80), "hit_cue": "fire_hit"},
	"thunder":  {"core": Color(1.0, 1.0, 0.90),  "body": Color(0.80, 0.85, 1.0), "glow": Color(0.75, 0.80, 1.0, 0.60), "width": 0.12, "jag": 0.45, "lean": 0.20, "linger": "static", "crack": Color(0.90, 0.92, 1.0, 0.90), "hit_cue": "juice_whack"},
	"wind":     {"core": Color(0.95, 1.0, 0.95),  "body": Color(0.55, 0.95, 0.70), "glow": Color(0.55, 0.95, 0.70, 0.45), "width": 0.10, "jag": 0.05, "lean": 0.85, "linger": "motes",  "crack": Color(0.70, 1.0, 0.80, 0.55), "hit_cue": "juice_whack"},
	"holy":     {"core": Color(1.0, 1.0, 0.92),   "body": Color(1.0, 0.88, 0.45), "glow": Color(1.0, 0.92, 0.55, 0.55), "width": 0.14, "jag": 0.0,  "lean": 0.05, "linger": "motes",  "crack": Color(1.0, 0.95, 0.70, 0.75), "hit_cue": "juice_shatter"},
	"dark":     {"core": Color(0.85, 0.55, 1.0),  "body": Color(0.30, 0.08, 0.45), "glow": Color(0.55, 0.15, 0.85, 0.55), "width": 0.18, "jag": 0.35, "lean": 0.45, "linger": "smoke",  "crack": Color(0.55, 0.20, 0.85, 0.80), "hit_cue": "juice_whack"},
}

## Beat timings (seconds). Lead-in beats fit the existing 0.20s anticipation +
## 0.22s travel lifecycle; finale beats start at contact.
const LEAD_IN := {"charge": 0.20, "travel": 0.22}
const FINALE := {"flash": 0.0, "crack": 0.0, "cluster": 0.05, "shatter": 0.34, "linger": 0.30, "linger_len": 0.95}


## Tier from authoritative applied damage. Crits bump one tier; a KO is the finisher.
static func tier_for(hp_damage: int, max_hp: int, critical: bool = false, defeated: bool = false) -> String:
	if defeated:
		return "finisher"
	var fraction := float(maxi(hp_damage, 0)) / float(maxi(max_hp, 1))
	var index := 0
	for threshold in TIER_HP_FRACTIONS:
		if fraction >= float(threshold):
			index += 1
	if critical:
		index += 1
	return TIERS[mini(index, 3)]


## Build the punchy-hit recipe for one resolved outcome.
## ctx keys: hp_damage, max_hp, critical, defeated, kind ("melee"|"arrow"|"spell"),
## element, from (Vector2), to (Vector2), reduced_motion, seed.
static func hit_profile(ctx: Dictionary) -> Dictionary:
	var tier := tier_for(int(ctx.get("hp_damage", 0)), int(ctx.get("max_hp", 1)),
		bool(ctx.get("critical", false)), bool(ctx.get("defeated", false)))
	var row: Dictionary = HIT_TIERS[tier]
	var kind := str(ctx.get("kind", "melee"))
	var direction := hit_direction(ctx.get("from", Vector2.ZERO), ctx.get("to", Vector2.ZERO))
	var rng := RandomNumberGenerator.new()
	# Derived from the outcome, never from randi(): the global RNG is combat's.
	rng.seed = int(ctx.get("seed", hash([ctx.get("hp_damage", 0), ctx.get("from", Vector2.ZERO), ctx.get("to", Vector2.ZERO)])))
	var reduced := bool(ctx.get("reduced_motion", false))
	var element := str(ctx.get("element", ""))

	var cue := "juice_whack"
	if kind == "arrow":
		cue = "juice_thwip"
	elif kind == "spell" and SPELL_SKINS.has(element):
		cue = str(SPELL_SKINS[element].hit_cue)
	var pitch := float(row.pitch) * rng.randf_range(0.94, 1.06)

	var knockback := float(row.knockback_px)
	if kind == "arrow":
		knockback *= 0.7  # arrows pin rather than shove
	return {
		"tier": tier,
		"flash_sec": float(row.flash_frames) * FRAME,
		"hitstop_ms": mini(int(row.hitstop_ms) / (2 if reduced else 1), MAX_HITSTOP_MS),
		"shake_px": 0.0 if reduced else float(row.shake_px),
		"shake_sec": float(row.shake_sec),
		"knockback_px": 0.0 if reduced else knockback,
		"knockback_out_sec": 0.06,
		"knockback_back_sec": 0.18,
		"direction": direction,
		"sparks": int(row.sparks),
		"spark_speed": float(row.spark_speed),
		"spark_spread_deg": 38.0 if kind != "spell" else 70.0,
		"sound_cue": cue,
		"sound_pitch": pitch,
		"layer_crack": tier in ["critical", "finisher"],
	}


## Normalized screen direction of the hit. Falls back to "away from camera".
static func hit_direction(from: Vector2, to: Vector2) -> Vector2:
	var delta := to - from
	if delta.length_squared() < 0.0001:
		return Vector2(0.0, -1.0)
	return delta.normalized()


static func skin_for(element: String) -> Dictionary:
	var key := "blizzard" if element == "ice" else element
	return SPELL_SKINS.get(key, SPELL_SKINS["blizzard"])


static func has_staged_spell(element: String) -> bool:
	return SPELL_SKINS.has("blizzard" if element == "ice" else element)


## Lead-in: spikes erupt from caster to target. Sizes ramp up toward the target
## (GROW), every other spike gets a smaller side spike tilted outward (FAN OUT).
## Positions are in screen space; y is the ground line, spikes rise upward.
static func path_layout(from: Vector2, to: Vector2, tier: String = "normal", seed_value: int = 0) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var distance := from.distance_to(to)
	var count := clampi(int(distance / 22.0), 3, 14)
	var scale := _tier_scale(tier)
	var direction := hit_direction(from, to)
	var normal := Vector2(-direction.y, direction.x)
	var spikes: Array[Dictionary] = []
	var travel := float(LEAD_IN.travel)
	for i in range(count):
		# Start a little past the caster's feet, stop short of the target's.
		var t := lerpf(0.12, 0.86, float(i) / float(maxi(count - 1, 1)))
		var base := from.lerp(to, t) + normal * rng.randf_range(-3.0, 3.0)
		var length := lerpf(16.0, 50.0, t) * scale * rng.randf_range(0.9, 1.1)
		var lean := direction.x * 0.35 * rng.randf_range(0.6, 1.0)
		spikes.append({"pos": base, "length": length, "tilt": lean, "side": 0, "delay": t * travel, "role": "path"})
		if i % 2 == 1 or t > 0.6:
			for side in [-1, 1]:
				# Ground-plane offset (iso squashes y) then tilt away from the path.
				var off: Vector2 = normal * float(side) * rng.randf_range(11.0, 17.0) * Vector2(1.0, 0.5)
				spikes.append({
					"pos": base + off,
					"length": length * rng.randf_range(0.5, 0.65),
					"tilt": float(side) * rng.randf_range(0.45, 0.70),
					"side": side,
					"delay": t * travel + 0.025,
					"role": "fan",
				})
	return spikes


## Finale: the big cluster around the target. Larger than any path spike,
## arranged on an iso ellipse, each tilted outward from the centre.
static func cluster_layout(center: Vector2, tier: String = "normal", seed_value: int = 0) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7919
	var scale := _tier_scale(tier)
	var count := 7 + TIERS.find(tier) * 2
	var spikes: Array[Dictionary] = []
	# A tall centre spike, then an outward-leaning ring.
	spikes.append({"pos": center + Vector2(0, 2), "length": 82.0 * scale, "tilt": 0.0, "side": 0, "delay": float(FINALE.cluster), "role": "cluster"})
	for i in range(count):
		var angle := TAU * float(i) / float(count) + rng.randf_range(-0.2, 0.2)
		var radius := rng.randf_range(18.0, 32.0) * scale
		var offset := Vector2(cos(angle), sin(angle) * 0.5) * radius
		var outward := signf(cos(angle)) if absf(cos(angle)) > 0.15 else 0.0
		spikes.append({
			"pos": center + offset,
			"length": rng.randf_range(52.0, 68.0) * scale,
			"tilt": outward * rng.randf_range(0.35, 0.65),
			"side": int(outward),
			"delay": float(FINALE.cluster) + rng.randf_range(0.0, 0.06),
			"role": "cluster",
		})
	return spikes


## Ground cracks radiating from the target (and a seam back along the path).
## Each crack is a jagged polyline on the iso ground plane.
static func crack_layout(center: Vector2, from: Vector2, tier: String = "normal", seed_value: int = 0) -> Array[PackedVector2Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 104729
	var cracks: Array[PackedVector2Array] = []
	var arms := 4 + TIERS.find(tier)
	var reach := 40.0 * _tier_scale(tier)
	for i in range(arms):
		var angle := TAU * float(i) / float(arms) + rng.randf_range(-0.35, 0.35)
		cracks.append(_jagged(center, angle, reach * rng.randf_range(0.7, 1.15), rng))
	var back := (from - center)
	if back.length() > 12.0:
		cracks.append(_jagged(center, back.angle(), minf(back.length() * 0.6, reach * 1.8), rng))
	return cracks


## Spike outline (local space, base at origin, tip pointing up). Shared by every
## element; skin width/jag decide whether it reads as ice, flame, bolt or thorn.
static func spike_polygon(length: float, skin: Dictionary, seed_value: int = 0) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := maxf(length * float(skin.get("width", 0.2)), 1.5)
	var jag := float(skin.get("jag", 0.0))
	var pts := PackedVector2Array()
	pts.append(Vector2(-half, 0.0))
	pts.append(Vector2(-half * 0.55 + rng.randf_range(-jag, jag) * half, -length * 0.45))
	pts.append(Vector2(rng.randf_range(-jag, jag) * half * 0.5, -length))
	pts.append(Vector2(half * 0.55 + rng.randf_range(-jag, jag) * half, -length * 0.55))
	pts.append(Vector2(half, 0.0))
	return pts


static func _jagged(origin: Vector2, angle: float, length: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array([origin])
	var steps := 4
	for s in range(1, steps + 1):
		var t := float(s) / float(steps)
		var a := angle + rng.randf_range(-0.45, 0.45)
		var p := origin + Vector2(cos(a), sin(a) * 0.5) * length * t
		pts.append(p)
	return pts


static func _tier_scale(tier: String) -> float:
	return 0.85 + 0.12 * float(maxi(TIERS.find(tier), 0))

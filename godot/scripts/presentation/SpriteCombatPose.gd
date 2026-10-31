## Cosmetic pose offsets around the foot origin. Never changes the tactical Unit.
extends RefCounted
var sprite: Sprite2D
var base_scale := Vector2.ONE
var state := "idle"
var clock := 0.0
var side := 1.0

func bind(target: Sprite2D) -> void:
 sprite = target
 base_scale = target.scale
 clock = 0.0

func pose(value: String, screen_direction: Vector2, reduced: bool = false) -> bool:
 if not is_instance_valid(sprite): return false
 if value not in ["idle", "anticipation", "contact", "recovery", "cast_anticipation", "cast_release", "cast_recovery"]: return false
 state = value
 clock = 0.0
 side = -1.0 if screen_direction.x < 0.0 else 1.0
 apply(0.0, reduced)
 return true

func apply(delta: float, reduced: bool) -> void:
 if not is_instance_valid(sprite): return
 # The outcome presenter owns scale while a hit reaction is active.
 if sprite.has_meta(&"zane_impact_reaction"): return
 clock += delta
 var stretch := Vector2.ONE
 var lean := 0.0
 if not reduced:
  match state:
   "idle": stretch.y = 1.0 + sin(clock * 2.2) * 0.006
   "anticipation":
    stretch = Vector2(1.025, 0.97)
    lean = -0.055 * side
   "contact": lean = 0.085 * side
   "cast_anticipation": stretch = Vector2(0.98, 1.025)
   "cast_release": lean = 0.035 * side
   "recovery", "cast_recovery": lean = 0.02 * side
 sprite.scale = base_scale * stretch
 sprite.rotation = lean

func reset() -> void:
 state = "idle"
 clock = 0.0
 if is_instance_valid(sprite):
  sprite.rotation = 0.0
  sprite.scale = base_scale

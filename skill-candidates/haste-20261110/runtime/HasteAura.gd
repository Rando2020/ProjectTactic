extends Node2D
## Two draw regions of ONE unchanged source PNG, not authored animation frames.
## Rear passes behind the actor; front stays around its boots. No global overlay.
const TEXTURE := preload("res://candidate_skills/haste-aura.png")
const PIVOT := Vector2(887, 554)
const SPLIT_Y := 554.0
const WORLD_SCALE := 0.10
const DURATION := 1.1
var reduced_motion := false
var elapsed := 0.0
func _ready() -> void:
 var unit := get_parent() as Unit
 if unit and is_instance_valid(unit.visual): z_index = unit.visual.z_index
 var size := TEXTURE.get_size()
 _layer("Rear", Rect2(0, 0, size.x, SPLIT_Y), -1)
 _layer("Front", Rect2(0, SPLIT_Y, size.x, size.y - SPLIT_Y), 1)
 _sample(0.0)
func _layer(label: String, region: Rect2, depth: int) -> void:
 var sprite := Sprite2D.new()
 sprite.name = label
 sprite.texture = TEXTURE
 sprite.region_enabled = true
 sprite.region_rect = region
 sprite.region_filter_clip_enabled = true
 sprite.centered = false
 sprite.position = region.position - PIVOT
 sprite.z_index = depth
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(sprite)
func _process(delta: float) -> void:
 if not is_instance_valid(get_parent()) or get_parent().hp <= 0:
  queue_free()
  return
 elapsed += maxf(delta, 0.0)
 _sample(elapsed)
 if elapsed >= DURATION: queue_free()
func _sample(time: float) -> void:
 var progress := clampf(time / DURATION, 0.0, 1.0)
 var expansion := 1.0 if reduced_motion else lerpf(0.92, 1.06, progress)
 scale = Vector2.ONE * WORLD_SCALE * expansion
 modulate.a = minf(clampf(time / 0.16, 0.0, 1.0), clampf((DURATION - time) / 0.38, 0.0, 1.0))

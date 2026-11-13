extends "res://scripts/vfx/VFXManager.gd"
## Application-only painted candidate; mechanics and all other VFX remain inherited.
const AURA = preload("res://candidate_skills/HasteAura.gd")
func play_haste(grid_pos: Vector2i) -> void:
 var battle := get_node_or_null("/root/BattleScene")
 var manager = battle.get_node_or_null("BattleManager") if battle else null
 if manager:
  for unit in manager.units.values():
   if is_instance_valid(unit) and unit.grid_pos == grid_pos and unit.hp > 0:
    var prior: Node2D = unit.get_node_or_null("HastePaintedAura")
    if prior:
     prior.hide()
     unit.remove_child(prior)
     prior.queue_free()
    var aura := AURA.new()
    aura.name = "HastePaintedAura"
    aura.reduced_motion = bool(GameState.practice_session.get("reduced_zane_motion", false))
    unit.add_child(aura)
    return
 # Keep the original non-candidate behavior when no current actor can own cleanup.
 super.play_haste(grid_pos)

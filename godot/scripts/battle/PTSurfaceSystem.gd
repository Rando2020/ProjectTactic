extends RefCounted
class_name PTSurfaceSystem


static func apply_surface_tick(unit: Dictionary, tile_data: Dictionary, surface_defs: Dictionary) -> Dictionary:
	var surface_id := String(tile_data.get("surface", ""))
	if surface_id == "" or not surface_defs.has(surface_id):
		return unit
	var definition: Dictionary = surface_defs[surface_id]
	if definition.get("tickDamage", 0) > 0:
		unit["hp"] = max(0, int(unit["hp"]) - int(definition["tickDamage"]))
	if definition.has("appliesStatus"):
		PTStatusEffectSystem.apply_statuses(unit, [definition["appliesStatus"]])
	return unit


static func merge_surface(existing_surface: String, new_surface: String, reactions: Dictionary) -> String:
	var key := existing_surface + "+" + new_surface
	if reactions.has(key):
		return String(reactions[key])
	key = new_surface + "+" + existing_surface
	if reactions.has(key):
		return String(reactions[key])
	return new_surface if new_surface != "" else existing_surface

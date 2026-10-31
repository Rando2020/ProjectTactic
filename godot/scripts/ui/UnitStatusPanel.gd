## Read-only inspection. Uses live Unit stats, never spends a combat action.
extends AcceptDialog
var portrait: TextureRect
var details: Label

func _ready() -> void:
 theme = preload("res://scripts/ui/AppointedTheme.gd").build()
 title = "Unit Status"
 min_size = Vector2i(480, 360)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 20)
 add_child(row)
 portrait = TextureRect.new()
 portrait.custom_minimum_size = Vector2(144, 210)
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 row.add_child(portrait)
 details = Label.new()
 details.add_theme_font_size_override("font_size", 20)
 row.add_child(details)

func inspect(unit: Unit) -> void:
 if not is_instance_valid(unit) or unit.unit_data == null: return
 portrait.texture = AssetRegistry.load_first_texture(AssetRegistry.get_character_portrait_candidates(unit.unit_data.id))
 var effects: Array[String] = []
 for effect: StatusEffect in unit.statuses:
  effects.append("%s (%d)" % [effect.status_id.capitalize(), effect.duration])
 var registry: Dictionary = GameState.unit_registry.get(unit.unit_id, {})
 var job_id := str(registry.get("current_job_id", unit.current_job_id))
 var job_name := str(JobTreeData.get_job(job_id).get("name", job_id.capitalize()))
 details.text = "%s\n%s\n\nHP  %d / %d\nMP  %d / %d\nTemper  %d    Ether  %d\nFacing  %s\n\n%s" % [unit.display_name, job_name, unit.hp, unit.unit_data.base_stats.hp, unit.mp, unit.unit_data.base_stats.mp, unit.temper, unit.ether, unit.facing, ", ".join(effects) if not effects.is_empty() else "No status effects"]
 popup_centered()

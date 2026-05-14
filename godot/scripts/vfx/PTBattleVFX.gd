extends Node2D
class_name PTBattleVFX


func flash_tile(position: Vector2, color: Color = Color(1, 1, 1, 0.65)) -> void:
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(0, -28),
		Vector2(52, 0),
		Vector2(0, 28),
		Vector2(-52, 0),
	])
	marker.color = color
	marker.position = position
	add_child(marker)
	var tween := create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.35)
	tween.finished.connect(marker.queue_free)


func float_text(position: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = position + Vector2(-18, -78)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 34, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(label.queue_free)

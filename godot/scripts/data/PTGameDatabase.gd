extends RefCounted
class_name PTGameDatabase


static func read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Could not parse " + path)
		return {}
	return parsed


static func by_id(rows: Array) -> Dictionary:
	var result := {}
	for row in rows:
		if row.has("id"):
			result[String(row["id"])] = row
	return result


static func character_lookup(rows: Array) -> Dictionary:
	var result := {}
	for row in rows:
		result[String(row["name"])] = row
	return result

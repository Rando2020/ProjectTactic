extends SceneTree

const ROOTS := [
	"res://scripts",
]

var _failures: Array[String] = []
var _loaded_count := 0


func _initialize() -> void:
	for root_path: String in ROOTS:
		_scan_directory(root_path)

	if not _failures.is_empty():
		push_error("Godot script validation failed for %d file(s):" % _failures.size())
		for failure: String in _failures:
			push_error("  " + failure)
		quit(1)
		return

	print("Godot script validation: OK (%d scripts loaded)" % _loaded_count)
	quit(0)


func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_failures.append("%s (directory could not be opened)" % path)
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif entry.ends_with(".gd"):
			_validate_script(full_path)

		entry = dir.get_next()
	dir.list_dir_end()


func _validate_script(path: String) -> void:
	var script := ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
	if script == null:
		_failures.append(path)
		return
	if script is Script and not (script as Script).can_instantiate():
		_failures.append("%s (script cannot instantiate)" % path)
		return
	_loaded_count += 1

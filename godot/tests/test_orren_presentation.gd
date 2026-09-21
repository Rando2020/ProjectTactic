extends SceneTree

const OrrenPresentation = preload("res://scripts/story/OrrenPresentation.gd")
const AudioSettingsScript = preload("res://scripts/systems/AudioSettings.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	_expect_true(OrrenPresentation.has_orren("first"), "Orren is visually present at first meeting")
	_expect_true(OrrenPresentation.has_orren("attachment"), "Orren is visually present during attachment")
	_expect_true(not OrrenPresentation.has_orren("absence"), "Orren is visually absent at Empty Stair")
	_expect_true(not OrrenPresentation.should_play_motif("absence"), "Empty Stair suppresses Orren audio cue")
	_expect_true(OrrenPresentation.should_play_motif("last_seen"), "ordinary last meeting still plays Orren cue")
	_expect_eq(OrrenPresentation.node_asset_part("last_seen"), "lantern", "Orren-present route node uses lantern")
	_expect_eq(OrrenPresentation.node_asset_part("absence"), "map_case", "Empty Stair route node uses map case")

	for path: String in [
		OrrenPresentation.portrait_asset_path(),
		OrrenPresentation.lantern_asset_path(),
		OrrenPresentation.map_case_asset_path(),
	]:
		_expect_true(not path.is_empty(), "Orren asset path is registered: %s" % path)
		_expect_true(ResourceLoader.exists(path), "Orren asset imports successfully: %s" % path)

	_expect_true(AudioSettingsScript.SFX_STREAMS.has("orren_motif"), "Orren audio motif is registered")

	if _fail > 0:
		push_error("Orren presentation test failed: %d failure(s), %d pass(es)" % [_fail, _pass])
		quit(1)
		return

	print("Orren presentation contract: OK (%d assertions)" % _pass)
	quit(0)


func _expect_true(value: bool, label: String) -> void:
	if value:
		_pass += 1
		return
	_fail += 1
	push_error("FAIL: %s" % label)


func _expect_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_pass += 1
		return
	_fail += 1
	push_error("FAIL: %s | expected=%s actual=%s" % [label, str(expected), str(actual)])

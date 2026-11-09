extends SceneTree

# Removing, corrupting, or leaving any recovered source as an LFS pointer must
# fail this contract; so must a PNG that cannot be loaded by the real engine.
# Historical SHA-256 values and dimensions are documented in asset_recovery.md.
const RECOVERED_ASSETS := {
	"res://assets/generated/icons/run-node-battle-icon.png": [
		"2a489de43fd734ca2e8eada80e713972e40bf98f8a7df59efc1d306149e9bf5a", Vector2(64, 64)],
	"res://assets/generated/icons/run-node-boss-icon.png": [
		"903b848a52ab06263d63a6efa791dafa99706bd4ab6eca9446345ca1e8a96164", Vector2(64, 64)],
	"res://assets/generated/icons/run-node-elite-icon.png": [
		"79bc01a3ca09e76fdaaa4b9de664394495b103ec7e7517d4a2bfd5b954671166", Vector2(64, 64)],
	"res://assets/generated/icons/run-node-wanderer-icon.png": [
		"80a0a8821d16e7b0efbd97d66bad3fcfd3e2d25b369714f6a10191e25618947e", Vector2(64, 64)],
	"res://assets/backgrounds/hub-background-last-hearth.png": [
		"ead7f40504bc2cc0a08abf466adfa38ac1995e0fef5c9ef0054737549460e32b", Vector2(1280, 720)],
}

var assertions := 0
var failures := 0


func _initialize() -> void:
	for asset_path: String in RECOVERED_ASSETS:
		if not FileAccess.file_exists(asset_path):
			_expect_true(false, "%s source PNG exists" % asset_path)
			continue
		_expect_true(FileAccess.get_sha256(asset_path) == RECOVERED_ASSETS[asset_path][0],
			"%s matches the historical LFS SHA-256" % asset_path)
		var texture := ResourceLoader.load(asset_path, "Texture2D") as Texture2D
		_expect_true(texture != null, "%s loads as a Texture2D" % asset_path)
		if texture != null:
			_expect_true(texture.get_size() == RECOVERED_ASSETS[asset_path][1],
				"%s retains its original dimensions" % asset_path)
	if failures > 0:
		push_error("Recovered asset contract failed: %d failure(s), %d assertions" % [failures, assertions])
		quit(1)
		return
	print("Recovered asset contract: OK (%d assets, %d assertions)" % [RECOVERED_ASSETS.size(), assertions])
	quit(0)


func _expect_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("FAIL: %s" % message)

class_name OrrenPresentation
extends RefCounted

const PRESENT_STAGES: Array[String] = [
	"first",
	"sacrifice",
	"attachment",
	"last_seen",
	"interlude",
]

const ABSENCE_STAGES: Array[String] = [
	"absence",
	"after_grief",
]


static func has_orren(stage_id: String) -> bool:
	return stage_id in PRESENT_STAGES


static func should_play_motif(stage_id: String) -> bool:
	return has_orren(stage_id)


static func motif_cue_id() -> String:
	# Reuse an existing cue until Orren receives a dedicated original audio asset.
	# Keeping this indirection means presentation code will not change later.
	return "ui_confirm"


static func node_asset_part(stage_id: String) -> String:
	return "map_case" if stage_id in ABSENCE_STAGES else "lantern"


static func portrait_asset_path() -> String:
	return AssetRegistry.get_story_character_asset("orren", "portrait")


static func lantern_asset_path() -> String:
	return AssetRegistry.get_story_character_asset("orren", "lantern")


static func map_case_asset_path() -> String:
	return AssetRegistry.get_story_character_asset("orren", "map_case")


static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if path.ends_with(".svg"):
		if not FileAccess.file_exists(path):
			return null
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return null
		var svg_text := file.get_as_text()
		file.close()
		var image := Image.new()
		var err := image.load_svg_from_string(svg_text, 1.0)
		if err != OK:
			return null
		return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		return load(path)
	return null

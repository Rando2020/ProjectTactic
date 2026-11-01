## Cosmetic only: explicit variable-size crops and semantic anchors, no gameplay.
extends Sprite2D
const Catalog := preload("res://scripts/presentation/ModularSpellCatalog.gd")
const ROOT := "res://prototypes/isometric/assets/modular-spells/"
var stage := "casting"
var frame_index := 0
var _entries: Array = []
var _textures: Array[Texture2D] = []

func configure(ability_id: String, phase: String) -> void:
	stage = phase
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_entries = Catalog.DATA.get("shared" if phase == "casting" else ability_id,{}).get(phase,[])
	_textures.clear()
	for entry: Dictionary in _entries:
		var path: String = ROOT + str(entry.file)
		_textures.append(load(path) as Texture2D if ResourceLoader.exists(path) else null)
	show_progress(0.0)

func available() -> bool:
	return not _entries.is_empty() and not _textures.has(null)

func frame_count() -> int:
	return _entries.size()

func show_progress(progress: float) -> void:
	if not available(): return
	frame_index = mini(_entries.size()-1,int(clampf(progress,0,1)*_entries.size()))
	var entry: Dictionary = _entries[frame_index]
	texture = _textures[frame_index]
	centered = false
	offset = -Vector2(entry.anchor[0],entry.anchor[1])
	scale = Vector2.ONE * float(entry.get("scale",0.28))
	# Last source frame still contains bright sparks: fade optically, don't alter art.
	modulate.a = 1.0 - smoothstep(0.55,1.0,progress) if stage == "dissipation" else 1.0

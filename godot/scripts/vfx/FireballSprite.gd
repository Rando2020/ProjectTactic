## Original approved fireball atlas. Cosmetic only; callers own timing and cleanup.
extends Sprite2D

const SHEET := preload("res://assets/vfx/fireball-sequence-v1.png")
const COLUMN_EDGES := [0, 360, 720, 1080, 1443]
const ROW_EDGES := [0, 272, 545, 817, 1090]

var _first := 0
var _count := 4
var _duration := 0.20
var _elapsed := 0.0
var _loop := false
var _flight := false
var _width := 36.0
var _displayed := -1

func configure(first: int, count: int, duration: float, width: float, loop: bool = false) -> void:
	_first = first
	_count = count
	_duration = maxf(duration, 0.001)
	_width = width
	_loop = loop
	_flight = first == 4
	_elapsed = 0.0
	_displayed = -1
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_set_frame(first)

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := fmod(_elapsed, _duration) / _duration if _loop else minf(_elapsed / _duration, 0.999)
	_set_frame(_first + mini(int(progress * _count), _count - 1))
	if not _loop and _elapsed >= _duration and _first >= 8:
		queue_free()

func _set_frame(index: int) -> void:
	if index == _displayed: return
	_displayed = index
	var column := index % 4
	var row := floori(float(index) / 4.0)
	var region := Rect2(COLUMN_EDGES[column], ROW_EDGES[row], COLUMN_EDGES[column + 1] - COLUMN_EDGES[column], ROW_EDGES[row + 1] - ROW_EDGES[row])
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = region
	atlas.filter_clip = true
	texture = atlas
	# Flight pivots at its hot core; charge and impact pivot at their base.
	offset = -region.size * (Vector2(0.78, 0.35) if _flight else Vector2(0.5, 0.88))
	scale = Vector2.ONE * _width / region.size.x

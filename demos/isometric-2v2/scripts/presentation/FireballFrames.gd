## Cosmetic frame playback only. No combat, MP, targeting or turn-state writes.
extends Sprite2D

const ROOT := "res://prototypes/isometric/assets/fireball/frames/"
const FILES := ["01_charge", "02_charge", "03_charge", "04_charge", "05_travel", "06_travel", "07_travel", "08_travel", "09_impact", "10_impact", "11_impact", "12_impact", "13_dissipate", "14_dissipate", "15_dissipate", "16_dissipate"]
const SOURCE_TRAVEL_ANGLE := -PI / 4.0
var stage := "charge"
var frame_index := 0
var _frames: Array[Texture2D] = []
var _tail := false
var _tail_elapsed := 0.0
var _tail_hit := false
const TAIL_DURATION := 0.50

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for file in FILES:
		var path: String = ROOT + file + ".png"
		if ResourceLoader.exists(path): _frames.append(load(path) as Texture2D)
	set_stage("charge")

func available() -> bool:
	return _frames.size() == 16 and not _frames.has(null)

func set_stage(value: String, direction: Vector2 = Vector2.RIGHT) -> void:
	stage = value
	_tail = false
	rotation = direction.angle() - SOURCE_TRAVEL_ANGLE if stage == "travel" else 0.0
	# Fixed ground anchor for charge/impact/smoke; head anchor for travel.
	offset = Vector2(-64,0) if stage == "travel" else Vector2(0,-144)
	scale = Vector2.ONE * (0.19 if stage == "travel" else (0.24 if stage == "charge" else 0.28))
	show_progress(0.0)

func show_progress(progress: float) -> void:
	var base := {"charge":0,"travel":4,"impact":8,"dissipate":12}.get(stage,0) as int
	frame_index = base + mini(3,int(clampf(progress,0,1)*4.0))
	if available(): texture = _frames[frame_index]

func start_tail(hit: bool) -> void:
	_tail_hit = hit
	set_stage("impact" if hit else "dissipate")
	_tail_elapsed = 0.0
	_tail = true

func _process(delta: float) -> void:
	if not _tail: return
	_tail_elapsed += delta
	if _tail_elapsed >= TAIL_DURATION:
		_tail = false
		hide()
		return
	if stage == "impact" and _tail_elapsed >= 0.25:
		stage = "dissipate"
	if stage == "impact": show_progress(_tail_elapsed/0.25)
	else: show_progress((_tail_elapsed-0.25)/0.25 if _tail_hit else _tail_elapsed/TAIL_DURATION)

extends Node2D
var registry: Dictionary
var elapsed := 0.0
var current := 0
var preview: Sprite2D
var views: Array
func _ready():
	registry = JSON.parse_string(FileAccess.get_file_as_string('res://registration.json'))
	views = registry.views
	RenderingServer.set_default_clear_color(Color('#101b24'))
	_label('Zane | four-direction review', Vector2(30,20), 28)
	_label('One approved reference + three candidates. No game integration or animation claim.', Vector2(30,60), 17)
	for i in range(4):
		var v: Dictionary = views[i]
		var origin = Vector2(155+i*295,370)
		_label(v.direction + (' / reference' if v.accepted else ' / candidate'), Vector2(35+i*295,105), 19)
		_add_actor(v, origin, 2.5)
		_label('85 px visible height', Vector2(40+i*295,420), 16)
		_add_actor(v, Vector2(155+i*295,560), 1.0)
	_label('Direction switch preview (same origin, no mirroring)',Vector2(30,605),17)
	preview = _add_actor(views[0],Vector2(600,740),1.0)
	set_process(true)
	queue_redraw()
	if '--capture' in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png('res://review-capture.png')
		get_tree().quit()
func _add_actor(v: Dictionary, point: Vector2, zoom: float) -> Sprite2D:
	var sprite = Sprite2D.new()
	add_child(sprite)
	sprite.position = point
	_apply(sprite,v,zoom)
	return sprite
func _apply(sprite: Sprite2D, v: Dictionary, zoom: float):
	sprite.texture = load('res://'+v.file) as Texture2D
	var factor: float = registry.target_height / float(v.alpha_bounds[3]-v.alpha_bounds[1]) * zoom
	sprite.scale = Vector2.ONE * factor
	sprite.offset = sprite.texture.get_size()*0.5 - Vector2(v.anchor[0],v.anchor[1])
	sprite.flip_h = false
func _process(delta):
	elapsed += delta
	if elapsed >= 1.2:
		elapsed=0
		current=(current+1)%4
		_apply(preview,views[current],1.0)
func _label(t: String,p: Vector2,size: int):
	var label = Label.new()
	label.text=t
	label.position=p
	label.add_theme_font_size_override('font_size',size)
	add_child(label)
func _draw():
	for i in range(4):
		var x=155+i*295
		draw_rect(Rect2(x-130,140,260,250),Color('#d4c5b1') if i%2==0 else Color('#263a48'))
		draw_line(Vector2(x-120,370),Vector2(x+120,370),Color('#efc877'),1)
		draw_rect(Rect2(x-130,450,260,120),Color('#d4c5b1') if i%2==0 else Color('#263a48'))
		draw_line(Vector2(x-120,560),Vector2(x+120,560),Color('#efc877'),1)

extends Node2D
## Diagnostic only. No production map, collision, picking or material is changed.
const TILE := Vector2(128, 64)
const CELLS_PER_TEXTURE := 4.0
const BOARD_CELLS := 8
const ORIGIN := Vector2(660, 200)
var texture: Texture2D

func project_cell(cell: Vector2) -> Vector2:
	return ORIGIN + Vector2((cell.x-cell.y)*TILE.x*0.5, (cell.x+cell.y)*TILE.y*0.5)

func _ready() -> void:
	texture=load("res://source/chapel-paving-continuous-v1.png")
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	if "--self-test" in OS.get_cmdline_user_args():
		var checks=0
		assert(texture != null); checks+=1
		assert(texture.get_size()==Vector2(1254,1254)); checks+=1
		assert(project_cell(Vector2(1,0))-ORIGIN==Vector2(64,32)); checks+=1
		assert(project_cell(Vector2(0,1))-ORIGIN==Vector2(-64,32)); checks+=1
		assert(project_cell(Vector2(1,1))-ORIGIN==Vector2(0,64)); checks+=1
		assert(CELLS_PER_TEXTURE==4.0); checks+=1
		assert(BOARD_CELLS/CELLS_PER_TEXTURE==2.0); checks+=1
		for y in BOARD_CELLS:
			for x in BOARD_CELLS:
				var p=project_cell(Vector2(x,y))
				assert(project_cell(Vector2(x+1,y))-p==Vector2(64,32)); checks+=1
				assert(project_cell(Vector2(x,y+1))-p==Vector2(-64,32)); checks+=1
		print("Paving diagnostic: ",checks," checks, 0 failures. No rendered acceptance implied.")
		get_tree().quit(0)
	queue_redraw()

func _draw() -> void:
	if texture==null:return
	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(38,48),"CHAPEL PAVING / MATERIAL CANDIDATE",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color(0.95,0.91,0.80))
	draw_string(font,Vector2(38,82),"128 x 64 diagnostic geometry | one texture per 4 x 4 cells | not a gameplay screenshot",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(0.75,0.79,0.88))
	var points=PackedVector2Array([project_cell(Vector2.ZERO),project_cell(Vector2(8,0)),project_cell(Vector2(8,8)),project_cell(Vector2(0,8))])
	var uv=PackedVector2Array([Vector2.ZERO,Vector2(2,0),Vector2(2,2),Vector2(0,2)])
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture)
	# Thin grid is a diagnostic overlay, not baked into the source material.
	for i in BOARD_CELLS+1:
		draw_line(project_cell(Vector2(i,0)),project_cell(Vector2(i,BOARD_CELLS)),Color(0.16,0.18,0.25,0.18),1.0)
		draw_line(project_cell(Vector2(0,i)),project_cell(Vector2(BOARD_CELLS,i)),Color(0.16,0.18,0.25,0.18),1.0)
	for cell in [Vector2(2,3),Vector2(3,3),Vector2(4,3)]:
		var q=PackedVector2Array([project_cell(cell),project_cell(cell+Vector2(1,0)),project_cell(cell+Vector2.ONE),project_cell(cell+Vector2(0,1))])
		draw_colored_polygon(q,Color(0.12,0.60,0.95,0.24))
	draw_string(font,Vector2(38,825),"Inspect repeated seams and highlight readability on a display-capable machine before acceptance.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(0.75,0.79,0.88))

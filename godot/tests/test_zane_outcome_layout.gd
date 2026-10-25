## Pure geometry contract; Label metrics are Godot's actual unwrapped 20px bounds.
extends SceneTree

const Layout := preload("res://scripts/presentation/ZaneOutcomeLayout.gd")
const Hud := preload("res://scripts/ui/BattleHudLayout.gd")
const Settings := preload("res://scripts/ui/UISettings.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var texts := ["-44 HP\n-17 Ether", "-33 HP\n-13 Ether [RESIST]", "-999 HP\n-123 Temper\n-456 Ether\nCRIT [WEAK]", "MISS", "IMMUNE", "0 HP\n-4 Temper"]
	var sizes: Array[Vector2] = []
	for text: String in texts:
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size",20)
		root.add_child(label)
		sizes.append(label.get_combined_minimum_size())
		check(label.get_theme_font_size("font_size") == 20, "layout measures original 20px font without shrinking")
		label.queue_free()
	var settings = Settings.shared()
	for viewport: Vector2 in [Vector2(1280,720),Vector2(1328,861),Vector2(1366,768),Vector2(1920,1080),Vector2(3840,2160)]:
		for mode in range(4):
			settings.set_mode(mode,false)
			var safe := Rect2(Vector2(12,12),Vector2(Hud.right_sidebar_rect(viewport).position.x-24,viewport.y-24))
			var ui_scale: float = settings.effective_scale(viewport)
			# Expanded comparison panel and lower-left loadout are actual HUD shapes,
			# including the native screenshot's controls instead of an empty canvas.
			var obstacles: Array[Rect2] = [Rect2(12,12,290*ui_scale,350*ui_scale),Rect2(12,viewport.y-110*ui_scale,260*ui_scale,98*ui_scale)]
			for zoom: float in [0.6,1.0,1.5]:
				for direction: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
					var perpendicular := Vector2i(-direction.y,direction.x)
					for count in [2,3]:
						for origin: Vector2 in [safe.get_center(),safe.position+Vector2(40,55),safe.end-Vector2(25,20)]:
							for fixture in [[0,1,2],[2,3,4],[4,5,2]]:
								var preferred: Array[Rect2] = []
								for i in count:
									var tile: Vector2i = direction*2 + perpendicular*(i-1)
									var anchor: Vector2 = origin + Vector2(tile.x-tile.y,tile.x+tile.y)*Vector2(48,24)*zoom
									var label_extent: Vector2 = sizes[fixture[i]]*zoom+Vector2.ONE*8*zoom
									preferred.append(Rect2(anchor-Vector2(label_extent.x*0.5,label_extent.y+64*zoom),label_extent))
								var rects: Array[Rect2] = Layout.place(preferred,safe,obstacles,22*zoom)
								var title := "%s/UI%d/zoom%.1f/%s/%d labels" % [viewport,mode,zoom,direction,count]
								check(rects.size() == count,title+": one layout rectangle per recipient")
								check(rects == Layout.place(preferred,safe,obstacles,22*zoom),title+": deterministic and no RNG")
								for i in rects.size():
									check(rects[i].size.is_equal_approx(preferred[i].size),title+": full measured text/outline size preserved")
									var swept: Rect2 = rects[i].merge(Rect2(rects[i].position+Vector2(0,-22*zoom),rects[i].size))
									check(safe.encloses(swept),title+": full float trajectory stays in viewport and left of HUD rail")
									for obstacle in obstacles: check(not swept.intersects(obstacle),title+": full float trajectory avoids visible HUD")
									for j in range(i):
										var other_sweep: Rect2 = rects[j].merge(Rect2(rects[j].position+Vector2(0,-22*zoom),rects[j].size))
										check(not swept.intersects(other_sweep),title+": swept multiline rectangles stay separated")
	settings.set_mode(0,false)
	await process_frame
	print("Zane outcome layout: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

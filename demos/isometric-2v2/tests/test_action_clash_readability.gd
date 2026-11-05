## Real HUD construction keeps the banner fonts and inheritance faithful to play.
## Settled card geometry catches container growth hidden by banner_rect().
extends Node
const Overlay = preload("res://scripts/ui/ActionClashOverlay.gd")
const Settings = preload("res://scripts/ui/UISettings.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func check_click_through(node: Node) -> void:
	if node is Control: check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE, "banner control stays click-through: " + node.name)
	for child in node.get_children(): check_click_through(child)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	for dimensions in [Vector2i(1920,1080), Vector2i(2560,1440)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		var hud = load("res://prototypes/blooming/BloomingHUD.gd").new()
		viewport.add_child(hud)
		var overlay = hud.get("_action_clash")
		check_click_through(overlay)
		for mode in [1,2,3,1,3]:
			Settings.shared().set_mode(mode, false)
			Settings.shared().apply_tree(overlay, Vector2(dimensions))
			for tier in ["light", "signature", "boss"]:
				for action in ["Thunderstrike", "Piercing Strike", "Attack", "Piercing Focus Strike Burst"]:
					if action == "Piercing Focus Strike Burst" and mode != 1: continue
					overlay.show_action({"actor":"Thunder Mage", "target":"Hollow Lancer", "action":action, "context":"MELEE", "tier":tier, "reduced_motion":true})
					for frame in range(5): await get_tree().process_frame
					var label: Label = overlay.get("_action_name")
					var card: Control = overlay.get("_card")
					var factor: float = Settings.shared().effective_scale(Vector2(dimensions))
					var tag := "%s mode%d %s %s" % [dimensions,mode,tier,action]
					print("MEASURE %s card=%s title=%s lines=%d font=%d" % [tag,card.size,label.size,label.get_line_count(),label.get_theme_font_size("font_size")])
					check(card.size.is_equal_approx(Overlay.BASE_SIZE),tag+" fixed card footprint")
					var actual: Rect2 = overlay.occlusion_rect()
					var expected: Rect2 = Overlay.banner_rect(Vector2(dimensions),Settings.shared().effective_scale(Vector2(dimensions)),tier)
					check(actual.is_equal_approx(expected),tag+" settled occlusion matches footprint")
					check(label.get_theme_font_size("font_size")==roundi(22*Settings.shared().effective_scale(Vector2(dimensions))),tag+" no font drift")
					for field in ["_actor_name", "_target_name"]:
						var name_label: Label = overlay.get(field)
						check(name_label.get_theme_font_size("font_size") == roundi(18*factor),tag+" name font unchanged")
						for word in name_label.text.split(" "):
							check(name_label.get_theme_font("font").get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,name_label.get_theme_font_size("font_size")).x <= name_label.size.x,tag+" name wraps at words")
					check(overlay.get("_action_context").get_theme_font_size("font_size") == roundi(16*factor),tag+" context font unchanged")
					for field in ["_actor_image", "_target_image"]:
						check(overlay.get(field).custom_minimum_size == Vector2(76,90),tag+" portrait unchanged")
					if action == "Thunderstrike": check(label.get_line_count()==1,tag+" unbroken action")
					if action == "Piercing Focus Strike Burst": check(label.get_line_count()==2,tag+" natural multiword wrapping")
		viewport.queue_free()
		await get_tree().process_frame
	await check_long_actions()
	await check_layout_quiescence()
	await check_child_containment()
	print("Action readability: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)


## Longer real moves retain their pre-existing growth at large font sizes.
## Compare fresh settled cards to avoid inheriting a prior action's grown size.
func check_long_actions() -> void:
	for dimensions in [Vector2i(1920,1080), Vector2i(2560,1440)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		var hud = load("res://prototypes/blooming/BloomingHUD.gd").new()
		viewport.add_child(hud)
		for mode in [1,2,3]:
			Settings.shared().set_mode(mode,false)
			for action in ["Thunderstrike","Elemental Convergence","Luminous Barrier","Resonance Fracture","Expose Weakness"]:
				for people in [["Zane","AREA"],["Rapha","Hollow Lancer"],["Kael","Hollow Sentinel"],["Thunder Mage","Hollow Lancer"]]:
					var measurements: Array[Dictionary] = []
					for original in [true,false]:
						var overlay = Overlay.new()
						hud.add_child(overlay)
						Settings.shared().apply_tree(overlay,Vector2(dimensions))
						overlay.show_action({"actor":people[0],"target":people[1],"action":action,"context":"SPELL", "tier":"signature","reduced_motion":true})
						if original:
							# Exact original center layout; all other production values unchanged.
							overlay.get("_action_name").get_parent().custom_minimum_size.x = 190
						for frame in range(5): await get_tree().process_frame
						var rect: Rect2 = overlay.occlusion_rect()
						var snapshot := {"rect":rect,"card":overlay.get("_card").size}
						for field in ["_action_name","_actor_name","_target_name"]:
							snapshot[field] = overlay.get(field).get_line_count()
						measurements.append(snapshot)
						overlay.queue_free()
						await get_tree().process_frame
					var before := measurements[0]
					var after := measurements[1]
					var tag := "%s mode%d %s %s/%s" % [dimensions,mode,action,people[0],people[1]]
					print("COMPARE %s baseline=%s candidate=%s" % [tag,before,after])
					for field in ["_action_name","_actor_name","_target_name"]:
						check(after[field] <= before[field],tag+" no extra wrapping "+field)
					check(before.rect.encloses(after.rect),tag+" no extra settled occlusion")
					if mode == 1:
						check(before == after,tag+" standard layout identical")
					if mode == 3 and action != "Thunderstrike":
						check(after._action_name == 2 and after.card == Vector2(710,151),tag+" pre-existing long-title height preserved")
		viewport.queue_free()
		await get_tree().process_frame


func check_layout_quiescence() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	add_child(viewport)
	Settings.shared().set_mode(3,false)
	var hud = load("res://prototypes/blooming/BloomingHUD.gd").new()
	viewport.add_child(hud)
	var overlay = hud.get("_action_clash")
	var card: PanelContainer = overlay.get("_card")
	var sorts := [0]
	card.sort_children.connect(func() -> void: sorts[0] += 1)
	overlay.show_action({"actor":"Zane","target":"AREA","action":"Elemental Convergence","context":"SPELL","tier":"signature","reduced_motion":true})
	for frame in range(8): await get_tree().process_frame
	check(card.size == Vector2(710,151),"quiescence long title uses its real content minimum")
	overlay.show_action({"actor":"Zane","target":"AREA","action":"Thunderstrike","context":"SPELL","tier":"signature","reduced_motion":true})
	for frame in range(8): await get_tree().process_frame
	check(card.size == Overlay.BASE_SIZE,"long-to-short transition returns to base footprint")
	var settled_sorts: int = sorts[0]
	for frame in range(20): await get_tree().process_frame
	check(sorts[0] == settled_sorts,"card sorting becomes idle after settled long-to-short transition")
	check(card.size == Overlay.BASE_SIZE,"idle card retains base footprint")
	print("QUIESCENCE settled_sorts=%d after_20_idle_frames=%d size=%s" % [settled_sorts,sorts[0],card.size])
	viewport.queue_free()
	await get_tree().process_frame


func check_descendants(card: Control, node: Node, tag: String) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree():
			check(card.get_global_rect().grow(0.1).encloses(child.get_global_rect()),tag+" contains "+str(child.get_path())+" card="+str(card.get_global_rect())+" child="+str(child.get_global_rect()))
		check_descendants(card,child,tag)

func check_child_containment() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	add_child(viewport)
	var hud = load("res://prototypes/blooming/BloomingHUD.gd").new()
	viewport.add_child(hud)
	var overlay = hud.get("_action_clash")
	var card: PanelContainer = overlay.get("_card")
	for mode in [3,1,3]:
		Settings.shared().set_mode(mode,false)
		check_descendants(card,card,"immediately after scale mode%d" % mode)
		for frame in range(8):
			await get_tree().process_frame
			check_descendants(card,card,"scale mode%d frame%d" % [mode,frame])
		for action in ["Elemental Convergence","Thunderstrike"]:
			overlay.show_action({"actor":"Zane","target":"Storm Imp","action":action,"context":"SPELL","tier":"signature","reduced_motion":true})
			check_descendants(card,card,"immediately after show mode%d %s" % [mode,action])
			# Check every frame, including the initial queued-container-layout phase.
			for frame in range(10):
				await get_tree().process_frame
				check_descendants(card,card,"mode%d %s frame%d" % [mode,action,frame])
			check_descendants(card,card,"settled mode%d %s" % [mode,action])
	viewport.queue_free()
	await get_tree().process_frame

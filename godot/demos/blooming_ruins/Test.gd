extends Node
const Encounter := preload("res://demos/blooming_ruins/Encounter.gd")
@export var scene_path := "res://demos/blooming_ruins/BloomingRuins.tscn"
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(title)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var sim := Encounter.new()
	check(sim.active.unit_id == "zane", "Zane begins by shared CT speed")
	check(sim.tiles.size() == 132, "complete terrain grid")
	check(sim.reachable(sim.active, 132).has(Encounter.GATE), "objective reachable through stairs from spawn")
	check(not sim.neighbors(Vector2i(6, 3)).has(Vector2i(6, 2)), "cliff is not walkable")
	check(sim.neighbors(Vector2i(2, 3)).has(Vector2i(2, 2)), "left stairs connect terrace")
	check(sim.neighbors(Vector2i(9, 4)).has(Vector2i(9, 3)), "right stairs connect terrace")
	var path := sim.move_active(Vector2i(2, 6))
	check(path.size() == 3 and sim.moved, "move uses real path and budget")
	check(sim.move_active(Vector2i(2, 5)).is_empty(), "second move rejected")
	check(not sim.reachable(sim.active).has(Vector2i(3, 6)), "walls excluded from pathfinding")
	sim.active.grid_pos = Vector2i(5, 6)
	var enemy: Unit = sim.units[3]
	check(sim.can_attack(sim.active, enemy), "adjacent opponent can be attacked")
	var before := enemy.hp
	var attack: Dictionary = sim.attack_active(enemy)
	check(not attack.is_empty() and sim.acted, "attack spends action")
	check(enemy.hp <= before and enemy.hp >= 0, "HP bounded")
	check(sim.attack_active(enemy).is_empty(), "second action rejected")
	sim.active = sim.units[1]
	sim.acted = false
	sim.active.grid_pos = Vector2i(5, 7)
	sim.units[0].hp = 120
	check(sim.heal_active(sim.units[0]), "Mira heals ally in range")
	check(sim.units[0].hp == 130 and sim.active.mp == 32, "heal capped and MP spent once")
	sim.acted = false
	sim.active.mp = 0
	check(not sim.heal_active(sim.units[0]), "heal rejects insufficient MP")
	for unit: Unit in sim.units:
		if unit.team == "enemy": unit.hp = 0
	sim.check_result()
	check(sim.result.is_empty(), "defeating patrol alone is not victory")
	sim.units[0].grid_pos = Encounter.GATE
	sim.check_result()
	check(sim.result == "VICTORY", "gate secured after patrol defeated")
	sim.dispose()
	var losing := Encounter.new()
	for unit: Unit in losing.units:
		if unit.team == "player": unit.hp = 0
	losing.check_result()
	check(losing.result == "DEFEAT", "party defeat detected")
	losing.dispose()
	var scene: Node = load(scene_path).instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if scene.has_method("place"):
		check(scene.art_regions.size() == 14, "all fourteen scenery regions are imported")
		check(scene.get_node_or_null("DistantPaintedValley") != null, "distant scenery is installed")
	var screen_point: Vector2 = scene.camera.unproject_position(scene.world(Vector2i(2, 9)) + Vector3.UP * 1.5)
	check(scene.pick(screen_point) == Vector2i(2, 9), "clicking character body selects its own cell")
	await scene.click(Vector2i(2, 6))
	check(scene.sim.active.grid_pos == Vector2i(2, 6), "scene click moves actual active unit")
	check(scene.visuals.zane.position.is_equal_approx(scene.world(Vector2i(2, 6))), "sprite movement lands at terrain elevation")
	check(scene.buttons.Move.disabled, "UI disables spent movement")
	check(not scene.buttons.Attack.disabled, "action remains available after moving")
	scene.command("Wait")
	await get_tree().create_timer(0.1).timeout
	check(scene.sim.active.unit_id != "zane", "Wait advances shared initiative")
	check(not scene.sim.moved and not scene.sim.acted, "next turn resets action economy")
	scene.command("Wait")
	scene.command("Wait")
	var deadline := Time.get_ticks_msec() + 15000
	while (scene.busy or scene.sim.active.team == "enemy") and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not scene.busy and scene.sim.active.team == "player", "enemy turns finish and return control")
	check(scene.sim.units[3].grid_pos != Vector2i(5, 5), "enemy actually pursues party")
	check(scene.sim.units[0].hp < 130, "enemy resolves real damage against player")
	print("Blooming Ruins: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

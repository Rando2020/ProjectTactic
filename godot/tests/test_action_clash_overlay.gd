## Focused test of the portrait accent; runs against the actual Godot script.
## It verifies composition, fallback, reentrant action replacement, and safe-area
## bounds without advancing initiative or invoking the combat resolver.
extends SceneTree

const Overlay := preload("res://scripts/ui/ActionClashOverlay.gd")
const Manager := preload("res://scripts/battle/BattleManager.gd")

var checks := 0
var failures := 0


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + description)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay = Overlay.new()
	root.add_child(overlay)
	await process_frame
	check(not overlay.visible, "clash is hidden before an accepted action")
	check(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "clash cannot capture tactical input")
	var manager = Manager.new()
	check(manager.has_signal("action_clash_started"), "battle lifecycle exposes one portrait event")
	manager.free()

	overlay.show_action({
		"actor": "Kael",
		"target": "Hollow Lancer",
		"action": "Attack",
		"context": "MELEE  ·  Back attack",
		"reduced_motion": true,
	})
	check(overlay.visible, "committed action shows accent")
	check((overlay.get("_actor_name") as Label).text == "Kael", "actor identity displayed")
	check((overlay.get("_target_name") as Label).text == "Hollow Lancer", "defender identity displayed")
	check((overlay.get("_action_name") as Label).text == "Attack", "actual committed action labeled")
	check((overlay.get("_actor_fallback") as Label).visible, "portrait-less actor has labeled fallback")
	check((overlay.get("_target_fallback") as Label).visible, "portrait-less target has labeled fallback")
	check(is_equal_approx(overlay.modulate.a, 1.0), "reduced motion does not animate entry")

	overlay.show_action({
		"actor": "Zane",
		"target": "AREA",
		"action": "Fire",
		"context": "SPELL",
		"reduced_motion": true,
	})
	check((overlay.get("_actor_name") as Label).text == "Zane", "new action replaces previous actor immediately")
	check((overlay.get("_target_name") as Label).text == "AREA", "AoE never invents a single defender")
	check((overlay.get("_action_name") as Label).text == "Fire", "new action replaces previous title")

	for size in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(3840, 2160)]:
		root.size = size
		overlay._resize()
		var card := overlay.get("_card") as PanelContainer
		var end_x := card.position.x + card.size.x * card.scale.x
		var end_y := card.position.y + card.size.y * card.scale.y
		check(end_x <= float(size.x) * 0.68 + 1.0, "%s keeps clash left of right HUD" % size)
		check(end_y <= float(size.y), "%s does not overflow below the viewport" % size)

	overlay.hide_clash()
	check(not overlay.visible, "action accent can be dismissed without combat side effects")
	overlay.queue_free()
	await process_frame
	print("Action clash portrait contract: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

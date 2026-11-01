extends Node

## ImpactJuice: pure recipe contract + live integration through the real
## resolver, juice autoload and VFX autoload.

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	_test_tiers()
	_test_hit_profile()
	_test_spell_layouts()
	await _test_live_physical_hit()
	await _test_live_spell()
	await _test_staged_lead_in()
	_test_motion_setting()
	await _test_reduced_motion_live()
	await _test_cluster_layering()
	print("Impact juice: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


# --- Pure recipe -------------------------------------------------------------

func _test_tiers() -> void:
	check(ImpactJuice.tier_for(2, 100) == "light", "tiny hit is light")
	check(ImpactJuice.tier_for(10, 100) == "normal", "10% hit is normal")
	check(ImpactJuice.tier_for(20, 100) == "heavy", "20% hit is heavy")
	check(ImpactJuice.tier_for(40, 100) == "critical", "40% hit is critical")
	check(ImpactJuice.tier_for(10, 100, true) == "heavy", "crit bumps one tier")
	check(ImpactJuice.tier_for(90, 100, true) == "critical", "crit bump never reaches finisher on its own")
	check(ImpactJuice.tier_for(1, 100, false, true) == "finisher", "KO is always the finisher")
	check(ImpactJuice.tier_for(0, 0) == "light", "zero max HP is safe")
	var previous := {}
	for tier in ImpactJuice.TIERS:
		var row: Dictionary = ImpactJuice.HIT_TIERS[tier]
		check(int(row.flash_frames) >= 2 and int(row.flash_frames) <= 5, "%s white flash lasts a few frames" % tier)
		check(int(row.hitstop_ms) <= ImpactJuice.MAX_HITSTOP_MS, "%s hitstop stays under the cap" % tier)
		if not previous.is_empty():
			for key in ["hitstop_ms", "shake_px", "knockback_px", "sparks"]:
				check(float(row[key]) >= float(previous[key]), "%s %s escalates" % [tier, key])
			check(float(row.pitch) < float(previous.pitch), "%s sounds heavier (lower pitch)" % tier)
		previous = row


func _test_hit_profile() -> void:
	var base := {"hp_damage": 25, "max_hp": 100, "kind": "melee", "from": Vector2(0, 0), "to": Vector2(30, 40), "seed": 4}
	var p := ImpactJuice.hit_profile(base)
	check(p.tier == "heavy", "profile tier comes from applied damage")
	check(p.direction.is_equal_approx(Vector2(0.6, 0.8)), "knockback direction is the normalized hit direction")
	check(is_equal_approx(p.flash_sec, 3.0 * ImpactJuice.FRAME), "flash time is whole frames")
	check(p.sound_cue == "juice_whack", "melee plays the whack")
	check(p.sound_pitch >= 0.94 * 0.94 and p.sound_pitch <= 0.94 * 1.06, "pitch jitter stays near the tier pitch")
	check(ImpactJuice.hit_profile(base).sound_pitch == p.sound_pitch, "same seed, same pitch")
	var arrow := base.duplicate()
	arrow.kind = "arrow"
	var pa := ImpactJuice.hit_profile(arrow)
	check(pa.sound_cue == "juice_thwip", "arrows use the lighter cue")
	check(pa.knockback_px < p.knockback_px, "arrows shove less than melee")
	var ice := base.duplicate()
	ice.kind = "spell"
	ice.element = "blizzard"
	var pi := ImpactJuice.hit_profile(ice)
	check(pi.sound_cue == "juice_shatter", "ice spells shatter")
	check(pi.spark_spread_deg > p.spark_spread_deg, "spell bursts are wider than weapon sparks")
	var reduced := base.duplicate()
	reduced.reduced_motion = true
	var pr := ImpactJuice.hit_profile(reduced)
	check(pr.shake_px == 0.0 and pr.knockback_px == 0.0, "reduced motion removes shake and knockback")
	check(pr.hitstop_ms < p.hitstop_ms and pr.flash_sec == p.flash_sec, "reduced motion shortens freeze, keeps flash")
	var same := base.duplicate()
	same.to = Vector2.ZERO
	check(ImpactJuice.hit_profile(same).direction == Vector2(0, -1), "zero-length hit still has a direction")
	var crit := base.duplicate()
	crit.critical = true
	check(ImpactJuice.hit_profile(crit).layer_crack, "critical hits layer an extra crack")
	check(not p.layer_crack, "ordinary hits stay single-layer")


func _test_spell_layouts() -> void:
	var from := Vector2(0, 0)
	var to := Vector2(220, 110)
	var path := ImpactJuice.path_layout(from, to, "normal", 11)
	var main: Array[Dictionary] = []
	var fans: Array[Dictionary] = []
	for s in path:
		if s.role == "path": main.append(s)
		else: fans.append(s)
	check(main.size() >= 3, "path has spikes")
	check(float(main[-1].length) > float(main[0].length) * 2.0, "spikes GROW toward the target")
	var ordered := true
	for i in range(1, main.size()):
		if float(main[i].delay) < float(main[i - 1].delay): ordered = false
	check(ordered, "spikes pop in order from caster to target")
	check(float(main[-1].delay) <= float(ImpactJuice.LEAD_IN.travel), "path finishes inside the travel window")
	check(fans.size() >= 2, "side spikes FAN OUT")
	var outward := true
	for f in fans:
		if signf(float(f.tilt)) != float(f.side): outward = false
	check(outward, "side spikes tilt outward, away from the path")
	var longest_path := 0.0
	for s in path: longest_path = maxf(longest_path, float(s.length))
	var cluster := ImpactJuice.cluster_layout(to, "normal", 11)
	var tallest := 0.0
	for c in cluster: tallest = maxf(tallest, float(c.length))
	check(tallest > longest_path, "the BIG FINISH cluster outsizes the path")
	check(ImpactJuice.cluster_layout(to, "finisher", 11).size() > cluster.size(), "bigger hits, bigger cluster")
	check(ImpactJuice.path_layout(from, to, "normal", 11) == path, "layouts are deterministic per seed")
	check(ImpactJuice.crack_layout(to, from, "normal", 11).size() >= 5, "the floor cracks radially plus a seam back to the caster")
	var poly := ImpactJuice.spike_polygon(40.0, ImpactJuice.skin_for("blizzard"), 3)
	var top := 0.0
	for pt in poly: top = minf(top, pt.y)
	check(is_equal_approx(top, -40.0), "spike tip reaches its full length")
	var thin := ImpactJuice.spike_polygon(40.0, ImpactJuice.skin_for("wind"), 3)
	check(absf(thin[0].x) < absf(poly[0].x), "skins change the silhouette")
	for element in ["fire", "blizzard", "ice", "thunder", "wind", "holy", "dark"]:
		check(ImpactJuice.has_staged_spell(element), "%s has a staged spell" % element)
	check(not ImpactJuice.has_staged_spell("cure"), "heals keep their own VFX")


# --- Live integration --------------------------------------------------------

func _make_battle() -> Node:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	manager.units.zane.grid_pos = Vector2i(3, 4)
	_enemy(manager, "storm_imp").grid_pos = Vector2i(4, 4)
	return battle


func _enemy(manager: BattleManager, archetype: String) -> Unit:
	for unit: Unit in manager.units.values():
		if unit.get_meta("archetype_id", "") == archetype:
			return unit
	return null


func _dispose(battle: Node) -> void:
	await battle.battle_manager._recover_action()
	battle.queue_free()
	while get_tree().paused:
		await get_tree().process_frame
	await get_tree().process_frame


func _test_live_physical_hit() -> void:
	var battle := _make_battle()
	var manager: BattleManager = battle.battle_manager
	var attacker: Unit = manager.units.zane
	var target: Unit = _enemy(manager, "storm_imp")
	target.facing = "E"  # attacker is west: rear arc, guaranteed hit
	target.hp = 999
	var visual := target.visual as CanvasItem
	var rest: Vector2 = visual.position
	var impacts: Array[Dictionary] = []
	manager.combat_resolver.impact_presented.connect(func(i: Dictionary) -> void: impacts.append(i))
	var result := manager.combat_resolver.resolve_attack(attacker, target, {}, {}, "slash")
	check(not result.get("missed", false), "rear attack lands")
	check(not result.has("impact"), "mechanical result stays free of presentation data")
	check(impacts.size() == 1, "one impact recipe per resolved hit")
	check(str(impacts[0].tier) in ImpactJuice.TIERS, "impact tier is valid")
	check(impacts[0].direction.x > 0.0, "impact direction points from attacker to target")
	check(get_tree().paused, "HITSTOP freezes the tree on contact")
	check(BattleJuiceEffects.get_flashing_units().has(target.unit_id), "target FLASHES white on contact")
	var mat := visual.material as ShaderMaterial
	check(mat != null and float(mat.get_shader_parameter("flash")) == 1.0, "flash is a true white mix, not a tint")
	var paused_frames := 0
	while get_tree().paused and paused_frames < 120:
		paused_frames += 1
		await get_tree().process_frame
	check(not get_tree().paused, "hitstop releases")
	var moved := false
	for i in range(8):
		await get_tree().process_frame
		if visual.position.distance_to(rest) > 1.0: moved = true
	check(moved, "KNOCKBACK shoves the visual after the freeze")
	await get_tree().create_timer(0.4).timeout
	check(visual.position.distance_to(rest) < 0.5, "knockback springs back to rest")
	check(target.grid_pos == Vector2i(4, 4), "knockback never moves the grid position")
	check(float(mat.get_shader_parameter("flash")) == 0.0, "flash clears")
	check(not BattleJuiceEffects.get_flashing_units().has(target.unit_id), "flash bookkeeping clears")
	await _dispose(battle)


func _test_live_spell() -> void:
	var battle := _make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = _enemy(manager, "storm_imp")
	target.hp = 999
	target.unit_data = target.unit_data.duplicate(true)
	target.unit_data.elemental_affinities.blizzard = 1.0
	var vfx := get_node("/root/VFX")
	var before := _spike_count(vfx)
	var impacts: Array[Dictionary] = []
	manager.combat_resolver.impact_presented.connect(func(i: Dictionary) -> void: impacts.append(i))
	var result := manager.combat_resolver.resolve_spell(caster, target, "ice", 120)
	if result.get("missed", false):
		check(impacts.is_empty(), "missed spells present no impact")
	else:
		check(impacts.size() == 1, "spell hit presents its impact")
		while get_tree().paused:
			await get_tree().process_frame
		await get_tree().create_timer(0.12).timeout
		check(_spike_count(vfx) > before + 6, "BIG FINISH raises a cluster of spikes around the target")
		var cracks := 0
		for child in vfx.get_children():
			if child is Line2D and child.points.size() == 5: cracks += 1
		check(cracks >= 5, "the floor CRACKS")
		await get_tree().create_timer(0.5).timeout
		check(_spike_count(vfx) <= before, "spikes SHATTER and clean up")
		var shards := 0
		var linger := 0
		for child in vfx.get_children():
			if child is Polygon2D and child.polygon.size() == 3: shards += 1
			if child is CPUParticles2D: linger += 1
		check(linger >= 1, "FROST lingers as particles")
		await get_tree().create_timer(1.8).timeout
		var leftovers := 0
		for child in vfx.get_children():
			if child is CPUParticles2D or (child is Polygon2D and child.polygon.size() == 3): leftovers += 1
		check(leftovers == 0, "every staged-spell node frees itself")
	await _dispose(battle)


func _test_staged_lead_in() -> void:
	var battle := _make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = _enemy(manager, "storm_imp")
	target.grid_pos = Vector2i(7, 4)
	var vfx: VFXManager = get_node("/root/VFX")
	seed(4242)
	var expected := randi()
	seed(4242)
	var before := _spike_count(vfx)
	var done := [false]
	var run_lead := func() -> void:
		await vfx.present_action(caster, target.grid_pos, "cast", Callable(), {}, "blizzard")
		done[0] = true
	run_lead.call()
	await get_tree().create_timer(0.30).timeout
	check(_spike_count(vfx) > before + 3, "lead-in erupts a spike path toward the target")
	var waited := 0
	while not done[0] and waited < 120:
		waited += 1
		await get_tree().process_frame
	check(done[0], "lead-in completes inside the lifecycle window")
	check(randi() == expected, "staged lead-in never advances the global combat RNG")
	await get_tree().create_timer(0.6).timeout
	check(_spike_count(vfx) <= before, "path spikes shatter by themselves after contact")
	# Self-target and unknown elements keep the legacy orb path.
	var before_self := _spike_count(vfx)
	await vfx.present_action(caster, caster.grid_pos, "cast", Callable(), {}, "blizzard")
	check(_spike_count(vfx) == before_self, "self-casts do not draw a path")
	await _dispose(battle)


## Spike roots are Node2D with three Polygon2D children (glow, body, core).
func _spike_count(vfx: Node) -> int:
	var n := 0
	for child in vfx.get_children():
		if child is Node2D and not (child is Polygon2D) and not (child is Line2D) and child.get_child_count() == 3:
			if child.get_child(0) is Polygon2D:
				n += 1
	return n


# --- Accessibility + readability ---------------------------------------------

func _test_motion_setting() -> void:
	var settings = load("res://scripts/ui/UISettings.gd").new()
	settings.settings_path = "user://test_impact_juice_ui.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	settings.set_mode(2)
	settings.set_reduced_motion(true)
	var reloaded = load("res://scripts/ui/UISettings.gd").new()
	reloaded.settings_path = settings.settings_path
	reloaded.load_settings()
	check(reloaded.reduced_motion, "reduced motion persists across sessions")
	check(reloaded.mode == 2, "saving motion keeps the UI size preference")
	reloaded.set_mode(1)
	var again = load("res://scripts/ui/UISettings.gd").new()
	again.settings_path = settings.settings_path
	again.load_settings()
	check(again.reduced_motion and again.mode == 1, "saving UI size keeps the motion preference")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))


func _test_reduced_motion_live() -> void:
	var shared = load("res://scripts/ui/UISettings.gd").shared()
	var previous: bool = shared.reduced_motion
	shared.set_reduced_motion(true, false)
	var battle := _make_battle()
	var manager: BattleManager = battle.battle_manager
	var target: Unit = _enemy(manager, "storm_imp")
	target.facing = "E"
	target.hp = 999
	var impacts: Array[Dictionary] = []
	manager.combat_resolver.impact_presented.connect(func(i: Dictionary) -> void: impacts.append(i))
	var visual := target.visual as CanvasItem
	var rest: Vector2 = visual.position
	manager.combat_resolver.resolve_attack(manager.units.zane, target, {}, {}, "slash")
	check(impacts.size() == 1 and float(impacts[0].shake_px) == 0.0, "global reduced motion removes screen shake")
	var moved := false
	for i in range(30):
		await get_tree().process_frame
		if visual.position.distance_to(rest) > 0.5: moved = true
	check(not moved, "global reduced motion removes knockback")
	shared.set_reduced_motion(previous, false)
	await _dispose(battle)


func _test_cluster_layering() -> void:
	var battle := _make_battle()
	var manager: BattleManager = battle.battle_manager
	var target: Unit = _enemy(manager, "storm_imp")
	var vfx: VFXManager = get_node("/root/VFX")
	var occluder := target.visual as CanvasItem
	var occ_z := vfx._absolute_z(occluder)
	var profile := ImpactJuice.hit_profile({"hp_damage": 30, "max_hp": 100, "kind": "spell", "element": "blizzard", "seed": 1})
	var existing := {}
	for child in vfx.get_children(): existing[child] = true
	vfx.play_spell_finale(manager.units.zane.grid_pos, target.grid_pos, "blizzard", profile, 77, occluder)
	await get_tree().create_timer(0.15).timeout
	var behind := 0
	var front := 0
	var front_ok := true
	for child in vfx.get_children():
		if existing.has(child) or not (child is Node2D) or child.get_child_count() != 3:
			continue
		if child.z_index < occ_z:
			behind += 1
		elif child.z_index > occ_z:
			front += 1
			if child.modulate.a >= 1.0: front_ok = false
	check(behind >= 3, "cluster spikes behind the enemy draw behind it")
	check(front >= 1, "some spikes still wrap in front of the enemy")
	check(front_ok, "front spikes are see-through so the enemy stays readable")
	await get_tree().create_timer(0.6).timeout
	await _dispose(battle)

extends Node

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func reset() -> void:
	GameState.unit_registry.clear()
	GameState.practice_session.clear()
	GameState._practice_runtime.clear()
	GameState.active_run = null
	GameState._init_defaults()

func strings(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is Label or node is Button:
		result.append(node.text)
	for child in node.get_children():
		result.append_array(strings(child))
	return result

func same_json(left: Dictionary, right: Dictionary) -> bool:
	# Godot JSON loads numbers as floats; compare persisted values, not Variant types.
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))

func row_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button:
			return child
	return null

func run() -> void:
	reset()
	check(GameState.SAVE_VERSION == 1, "primary SAVE_VERSION remains one; no migration")
	var fire := AbilityDB.get_ability("fire")
	var alias := AbilityDB.get_ability("fireball")
	check(not alias.is_empty() and alias == fire, "fireball resolves to exactly existing Fire definition")
	check(fire.get("id") == "fire", "canonical definition includes Fire identity")
	check(fire.get("mp_cost") == 12 and fire.get("range") == 3 and fire.get("base_power") == 100 and fire.get("aoe_type") == "fan", "Fire mechanics unchanged")
	for unresolved in ["slash", "holy_strike", "void_scar", "future_skill"]:
		check(AbilityDB.get_ability(unresolved).is_empty(), unresolved + " has no invented alias or definition")
	var reg: Dictionary = GameState.unit_registry.mira
	reg.base_abilities = ["fireball", "cure", "holy_strike", "future_base"]
	reg.learned_abilities = ["fire", "fireball", "holy_strike", "future_skill", "blizzard", "thunderstrike", "void_pulse", "defend"]
	reg.equipped_abilities = ["holy_strike", "fireball", "fire", "cure"]
	reg.jp = 100000
	check(GameState.knows_ability("mira", "fire") and GameState.knows_ability("mira", "fireball"), "alias-aware ownership sees base alias and learned canonical")
	check(GameState.knows_ability("mira", "holy_strike") and GameState.knows_ability("mira", "future_skill"), "unresolved ownership remains queryable")
	check(GameState.get_all_abilities("mira") == ["fire", "cure"], "effective loadout filters unresolved and deduplicates alias")
	check(not GameState.learn_ability("mira", "fireball") and reg.jp == 100000, "owned alias cannot be bought twice")
	GameState.set_equipped_abilities("mira", ["holy_strike", "fireball", "fire", "cure", "blizzard", "thunderstrike", "void_pulse"])
	check(reg.equipped_abilities == ["fire", "cure", "blizzard", "thunderstrike"], "explicit setter counts valid unique identities before four-slot cap")
	check(reg.learned_abilities == ["fire", "fireball", "holy_strike", "future_skill", "blizzard", "thunderstrike", "void_pulse", "defend"], "setter leaves raw learned entitlements untouched")
	reg.equipped_abilities = []
	check(GameState.get_all_abilities("mira") == ["fire", "cure", "blizzard", "thunderstrike", "void_pulse", "defend"], "legacy empty equipment still uses all valid known, including more than four")
	reg.equipped_abilities = ["fire", "cure", "blizzard", "thunderstrike", "void_pulse", "defend"]
	check(GameState.get_all_abilities("mira").size() == 6, "reading an oversized legacy explicit loadout does not silently migrate or cap it")
	reg.equipped_abilities = ["holy_strike"]
	check(GameState.get_all_abilities("mira").is_empty(), "owned unresolved-only equipment does not broaden into all-known")
	reg.equipped_abilities = ["not_owned"]
	check(GameState.get_all_abilities("mira").size() == 6, "legacy wholly unowned equipment still falls back to all-known")
	# The old fallback price must not turn unavailable catalog entries into purchases.
	reset()
	reg = GameState.unit_registry.kael
	reg.jp = 100000
	reg.learnable_abilities = ["future_skill", "cover_ally"]
	check(not GameState.learn_ability("kael", "future_skill"), "unknown ability cannot be purchased at any JP")
	check(not GameState.learn_ability("kael", "cover_ally"), "missing price is unavailable, never a 9999-JP purchase")
	check(reg.jp == 100000 and reg.learned_abilities.is_empty(), "rejected purchases leave JP and ownership intact")
	var has_projections := GameState.has_method("get_known_abilities") and GameState.has_method("get_equipped_abilities") and GameState.has_method("get_learnable_abilities")
	var has_quote := GameState.has_method("get_ability_purchase_quote")
	check(has_projections, "shared pure known/equipped/current-job projections exist")
	check(has_quote, "shared purchase quote exists")
	if has_projections and has_quote:
		await test_contracts()
	print("Starter identity: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func test_contracts() -> void:
	reset()
	var fresh: Dictionary = {}
	for uid in GameState.unit_registry:
		fresh[uid] = GameState.get_learnable_abilities(uid)
	check(fresh.mira == ["fire", "blizzard", "thunderstrike", "void_pulse"], "fresh Arcanist catalog follows existing current-job definition")
	check(fresh.zane == fresh.mira, "same-job fresh catalogs agree")
	var initial := GameState.serialize_state()
	check(GameState.restore_state(initial), "fresh primary restore succeeds")
	for uid in fresh:
		check(GameState.get_learnable_abilities(uid) == fresh[uid], uid + " fresh and restore catalogs agree")
		GameState.set_current_job(uid, GameState.unit_registry[uid].current_job_id)
		check(GameState.get_learnable_abilities(uid) == fresh[uid], uid + " reselecting job keeps catalog")
	var reg: Dictionary = GameState.unit_registry.kael
	reg.jp = 100
	reg.job_jp = {"squire": 89}
	GameState.set_current_job("kael", "warder")
	check(reg.current_job_id == "squire", "89 Squire history does not unlock Warder")
	reg.job_jp.squire = 90
	GameState.set_current_job("kael", "warder")
	check(reg.current_job_id == "warder", "90 Squire history unlocks Warder")
	var original_base: Array = reg.base_abilities.duplicate()
	reg.learned_abilities = ["cure"]
	reg.equipped_abilities = ["cure", "defend"]
	GameState.set_current_job("kael", "arcanist")
	check(reg.base_abilities == original_base and reg.learned_abilities == ["cure"] and reg.equipped_abilities == ["cure", "defend"] and reg.jp == 100, "job switch preserves base/cross-job ownership, equipment and available JP")
	var history: Dictionary = reg.job_jp.duplicate(true)
	reg.jp = 99
	var quote: Dictionary = GameState.get_ability_purchase_quote("kael", "fireball")
	check(quote.get("canonical_id") == "fire" and quote.get("jp_cost") == 100 and not quote.get("eligible", true), "Fire quote uses canonical id and explicit 100 cost at 99 JP")
	check(not GameState.learn_ability("kael", "fireball") and reg.jp == 99, "99 JP cannot buy Fire")
	reg.jp = 100
	quote = GameState.get_ability_purchase_quote("kael", "fire")
	check(quote.get("eligible", false), "100 JP can buy Fire")
	var screen := CharacterScreen.new()
	screen._gs = GameState
	screen._selected_uid = "kael"
	var row := screen._learn_row("fireball", AbilityDB.get_ability("fireball"))
	check(row_button(row).text == "Learn 100 JP" and not row_button(row).disabled, "UI shows exact Fire quote price")
	check("Fire" in strings(row), "UI displays canonical Fire name")
	row.free()
	check(GameState.learn_ability("kael", "fireball") and reg.jp == 0 and "fire" in reg.learned_abilities, "purchase charges exactly quoted 100 JP and stores canonical Fire")
	check(not GameState.learn_ability("kael", "fire") and not GameState.learn_ability("kael", "fireball") and reg.jp == 0, "duplicate canonical and alias clicks cannot charge again")
	check(reg.job_jp == history, "spending JP never changes historical job JP")
	quote = GameState.get_ability_purchase_quote("kael", "thunderstrike")
	check(quote.get("jp_cost") == 0 and quote.get("eligible", false), "explicit zero price remains free")
	row = screen._learn_row("thunderstrike", AbilityDB.get_ability("thunderstrike"))
	check(row_button(row).text == "Learn Free" and not row_button(row).disabled, "UI shows a true zero as Free")
	row.free()
	check(GameState.learn_ability("kael", "thunderstrike") and reg.jp == 0, "free purchase charges zero")
	reg.jp = 100
	quote = GameState.get_ability_purchase_quote("kael", "blizzard")
	check(quote.get("eligible", false), "Blizzard initially eligible")
	GameState.set_current_job("kael", "squire")
	check(not GameState.learn_ability("kael", "blizzard") and reg.jp == 100, "stale job quote cannot commit after job switch")
	row = screen._learn_row("cover_ally", AbilityDB.get_ability("cover_ally"))
	check(row_button(row).disabled and row_button(row).text == "Not available for JP yet", "staged unpriced row shows truthful disabled reason")
	row.free()
	row = screen._ability_summary("holy_strike", {}, true)
	check(row_button(row) == null and "Unavailable — progress retained" in strings(row), "unresolved known row retains progress without Equip or fabricated stats")
	row.free()
	row = screen._learn_row("future_skill", {})
	check(row_button(row).disabled and row_button(row).text == "Ability not available yet", "unknown catalog row is disabled honestly")
	row.free()
	check(GameState.knows_ability("kael", "defend"), "unpriced owned Defend remains owned")
	GameState.set_equipped_abilities("kael", ["defend"])
	check(GameState.get_all_abilities("kael") == ["defend"], "unpriced owned Defend remains equippable/usable")
	reg.job_jp.arcanist = 90
	GameState.set_current_job("kael", "luminary")
	reg.learned_abilities.erase("cure")
	quote = GameState.get_ability_purchase_quote("kael", "cure")
	check(quote.get("jp_cost") == 80 and quote.get("eligible", false), "Cure quote is existing 80 JP")
	check(GameState.learn_ability("kael", "cure") and reg.jp == 20, "Cure charges existing 80 JP")
	# A quote is not a grant API. Saved secret ownership must not pass purchase gating.
	reg.current_job_id = "void_knight"
	reg.jp = 100000
	quote = GameState.get_ability_purchase_quote("kael", "dark_echo")
	check(not quote.get("eligible", true) and quote.get("reason") == "Learned from a teacher, not JP", "secret catalog entries never become accidental JP purchases")
	reg.learned_abilities.append("dark_echo")
	check(GameState.knows_ability("kael", "dark_echo"), "saved secret ownership survives without price checks")
	screen.free()
	await test_preservation()
	await test_edges_and_real_ui()

func test_preservation() -> void:
	reset()
	var reg: Dictionary = GameState.unit_registry.mira
	reg.base_abilities = ["fireball", "future_base", "holy_strike", "cure"]
	reg.learned_abilities = ["fire", "fireball", "future_skill", "holy_strike", "blizzard"]
	reg.equipped_abilities = ["future_skill", "fireball", "fire", "cure"]
	reg.jp = 321
	reg.job_jp = {"arcanist": 180, "luminary": 90}
	GameState.story_flags = ["story_fixture", "leaf_retained"]
	GameState.gold = 456
	GameState.runs_completed = 7
	GameState.best_floor_reached = 9
	GameState.last_run_death = {"unit": "kael", "detail": ["retained"]}
	var before := GameState.serialize_state()
	GameState.save()
	var disk_hash := FileAccess.get_sha256(GameState.SAVE_PATH)
	for i in range(2):
		GameState.get_known_abilities("mira")
		GameState.get_equipped_abilities("mira")
		GameState.get_all_abilities("mira")
		GameState.get_learnable_abilities("mira")
		GameState.get_ability_purchase_quote("mira", "blizzard")
		GameState.knows_ability("mira", "future_base")
	var read_screen := CharacterScreen.new()
	read_screen._gs = GameState
	read_screen._selected_uid = "mira"
	read_screen._detail_panel = VBoxContainer.new()
	read_screen.add_child(read_screen._detail_panel)
	read_screen._build_abilities_tab(reg)
	read_screen._build_status_tab(reg)
	check(read_screen._known_abilities(reg) == ["fire", "future_base", "holy_strike", "cure", "future_skill", "blizzard"], "UI known projection deduplicates alias while retaining unavailable rows")
	read_screen.free()
	check(GameState.serialize_state() == before, "queries and UI reads preserve every serialized field including raw unknown arrays and JP/history/story")
	check(FileAccess.get_sha256(GameState.SAVE_PATH) == disk_hash, "all read projections leave disk hash unchanged")
	check(GameState.load_save(), "primary save loads")
	check(same_json(GameState.serialize_state(), before), "primary load preserves raw base/learned/equipped and all fixture fields")
	check(FileAccess.get_sha256(GameState.SAVE_PATH) == disk_hash, "load does not rewrite disk")
	check(GameState.restore_state(GameState.serialize_state()) and same_json(GameState.serialize_state(), before), "second primary roundtrip is idempotent without migration")
	check(GameState.knows_ability("mira", "future_base") and GameState.knows_ability("mira", "future_skill"), "raw unresolved base and learned entitlement remains queryable after reload")
	check(GameState.begin_practice(0, 314159), "practice begins from preserved baseline")
	disk_hash = FileAccess.get_sha256(GameState.SAVE_PATH) # begin_practice is an explicit normal save.
	GameState.start_practice_encounter()
	GameState.unit_registry.mira.jp += 100
	GameState.unit_registry.mira.learned_abilities.append("thunderstrike")
	GameState.set_equipped_abilities("mira", ["fire", "blizzard"])
	check(FileAccess.get_sha256(GameState.SAVE_PATH) == disk_hash, "practice mutation saves baseline bytes, not temporary equipment or JP")
	GameState.finish_practice(false)
	check(GameState.retry_practice(), "practice retry restores checkpoint")
	var checkpoint_expected := before.duplicate(true)
	checkpoint_expected.last_run_death = {} # Existing practice checkpoint intentionally clears death presentation.
	check(same_json(GameState.serialize_state(), checkpoint_expected), "practice retry preserves original raw identity records and progression")
	check(GameState.leave_practice(), "practice leaves")
	check(same_json(GameState.serialize_state(), before) and FileAccess.get_sha256(GameState.SAVE_PATH) == disk_hash, "practice exit restores exact baseline state and disk hash")
	await get_tree().process_frame


func test_edges_and_real_ui() -> void:
	reset()
	var db := AbilityDB.new()
	check(db.has_method("purchase_price"), "price validation is pure and shared")
	if db.has_method("purchase_price"):
		for invalid in [{}, {"jp_cost": null}, {"jp_cost": -1}, {"jp_cost": 1.5}, {"jp_cost": 100.0}, {"jp_cost": "100"}, {"jp_cost": true}]:
			check(db.call("purchase_price", invalid) == null, "missing/invalid explicit price rejected: " + str(invalid))
		check(db.call("purchase_price", {"jp_cost": 0}) == 0, "integer zero is not missing")
		check(db.call("purchase_price", {"jp_cost": 80}) == 80, "explicit integer price preserved")
	var defaults := GameState.serialize_state()
	var absent := defaults.duplicate(true)
	absent.unit_resources.mira.erase("base_abilities")
	check(GameState.restore_state(absent), "old save without base field restores")
	check(GameState.unit_registry.mira.base_abilities == defaults.unit_resources.mira.base_abilities, "absent base ownership retains original character defaults")
	var empty := defaults.duplicate(true)
	empty.unit_resources.mira.base_abilities = []
	check(GameState.restore_state(empty) and GameState.unit_registry.mira.base_abilities.is_empty(), "explicit saved empty base stays empty, not reseeded")
	check(GameState.unit_registry.mira.equipment == defaults.unit_resources.mira.equipment and GameState.unit_registry.zane.base_abilities == defaults.unit_resources.zane.base_abilities, "base restore does not replace unrelated defaults")
	reset()
	var reg: Dictionary = GameState.unit_registry.mira
	reg.base_abilities = ["fireball"]
	reg.learned_abilities = []
	check(GameState.knows_ability("mira", "fire") and GameState.knows_ability("mira", "fireball"), "alias-only ownership recognizes both names")
	reg.base_abilities = ["fire"]
	check(GameState.knows_ability("mira", "fireball"), "canonical-only ownership recognizes old alias")
	reg.learned_abilities = ["fireball", "future_skill", "defend", "long_shot", "quickstep"]
	check(GameState.get_known_abilities("mira") == ["fire", "future_skill", "defend", "long_shot", "quickstep"], "known projection canonicalizes and deduplicates without losing unresolved entitlement")
	var projected: Array = GameState.get_known_abilities("mira")
	projected.clear()
	check(reg.base_abilities == ["fire"] and reg.learned_abilities.size() == 5, "projection cannot mutate raw arrays")
	GameState.set_equipped_abilities("mira", ["defend", "long_shot", "quickstep"])
	check(GameState.get_all_abilities("mira") == ["defend", "long_shot", "quickstep"], "all three valid unpriced starters stay equippable")
	reg.current_job_id = "shadow"
	reg.learnable_abilities = ["fire", "future_skill"]
	reg.jp = 0
	var quote: Dictionary = GameState.get_ability_purchase_quote("mira", "dark_breath")
	check(quote.jp_cost == 0 and quote.eligible and GameState.learn_ability("mira", "dark_breath") and reg.jp == 0, "Shadow existing explicit zero price works despite stale raw catalog")
	check(not GameState.get_ability_purchase_quote("missing", "fire").eligible, "missing character has no purchase entitlement")
	reg.current_job_id = "arcanist"
	reg.jp = 100
	quote = GameState.get_ability_purchase_quote("mira", "blizzard")
	check(quote.eligible, "affordable quote before resource change")
	reg.jp = 99
	check(not GameState.learn_ability("mira", "blizzard") and reg.jp == 99, "stale affordable quote revalidates JP at commit")
	reg.jp = 100
	reg.equipped_abilities = ["fireball", "fire", "future_skill", "defend", "long_shot"]
	var raw_owned: Array = reg.learned_abilities.duplicate()
	var screen := CharacterScreen.new()
	screen._selected_uid = "mira"
	add_child(screen)
	screen._on_learn("blizzard")
	check(reg.jp == 0 and reg.equipped_abilities == ["fire", "defend", "long_shot", "blizzard"], "real UI learn auto-equips using unique canonical setter cap")
	screen._on_learn("blizzard")
	check(reg.jp == 0 and reg.learned_abilities.count("blizzard") == 1, "real UI duplicate click spends once")
	check(reg.learned_abilities.slice(0, raw_owned.size()) == raw_owned, "UI purchase leaves raw prior alias and unresolved ownership untouched")
	screen._toggle_equipped("fireball")
	check(reg.equipped_abilities == ["defend", "long_shot", "blizzard"], "real UI remove alias removes canonical equipped identity")
	screen._toggle_equipped("fireball")
	check(reg.equipped_abilities == ["defend", "long_shot", "blizzard", "fire"], "real UI equips canonical Fire once")
	screen._toggle_equipped("quickstep")
	check(reg.equipped_abilities == ["defend", "long_shot", "blizzard", "quickstep"], "real UI full-slot replacement remains four unique entries")
	var before := GameState.serialize_state()
	screen._toggle_equipped("future_skill")
	check(GameState.serialize_state() == before, "unresolved UI equip attempt is nonmutating")
	screen.queue_free()
	await get_tree().process_frame
	GameState.save()
	check(GameState.load_save() and GameState.get_all_abilities("mira") == ["defend", "long_shot", "blizzard", "quickstep"], "UI learn/equip survives primary save/reload")
	GameState.set_current_job("mira", "squire")
	check(GameState.get_all_abilities("mira") == ["defend", "long_shot", "blizzard", "quickstep"], "cross-job learned/equipped Blizzard retained")
	# Real BattleScene consumers see the same projected IDs; no duplicate alias or unknown skill.
	reset()
	GameState.unit_registry.mira.learned_abilities = ["fire", "future_skill", "blizzard"]
	GameState.unit_registry.mira.equipped_abilities = ["holy_strike", "fireball", "fire", "cure", "blizzard"]
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var expected := {"kael": ["mighty_strike", "defend"], "mira": ["fire", "cure", "blizzard"], "zane": ["fire", "thunderstrike", "void_pulse"], "lyra": ["long_shot", "quickstep"]}
	for uid in expected:
		var unit: Unit = battle.battle_manager.units[uid]
		check(unit.unit_data.abilities == expected[uid], uid + " actual battle spawn uses canonical usable loadout")
	battle.queue_free()
	await get_tree().process_frame

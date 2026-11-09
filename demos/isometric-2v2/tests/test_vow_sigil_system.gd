extends SceneTree

const VowSigilDefs := preload("res://scripts/roguelike/VowSigilSystem.gd")
const RunBonuses := preload("res://scripts/roguelike/RunBonuses.gd")

var _pass := 0
var _fail := 0

func _init() -> void:
	_run_tests()
	print("Vow/Sigil tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _run_tests() -> void:
	var run := RunState.create(12345)
	_eq(run.equipped_vow_id, VowSigilDefs.DEFAULT_VOW_ID, "run default vow")
	_eq(run.equipped_sigil_id, VowSigilDefs.DEFAULT_SIGIL_ID, "run default sigil")
	run.equipped_vow_id = "vow_torvahk"
	run.equipped_sigil_id = "sigil_arcanist"
	var bonus := run.get_loadout_bonus()
	_true(float(bonus.get("guardian_weights", {}).get("torvahk", 1.0)) > 1.0, "torvahk vow weights guardian")
	_true(float(bonus.get("element_weights", {}).get("thunder", 1.0)) > 1.0, "torvahk vow weights thunder")
	_true(float(bonus.get("tag_weights", {}).get("magic", 1.0)) > 1.0, "arcanist sigil weights magic")
	run.grant_loadout_xp(35)
	_eq(run.equipped_vow_level, 2, "vow levels from xp")
	_eq(run.equipped_sigil_level, 2, "sigil levels from xp")
	run.grant_loadout_xp(50)
	var leveled_bonus := run.get_loadout_bonus()
	_eq(run.equipped_vow_level, 3, "vow reaches rarity-bias level")
	_true(float(leveled_bonus.get("rarity_weights", {}).get("rare", 1.0)) > 1.0, "level 3 adds rarity weighting")
	_true(VowSigilDefs.xp_progress_text(run.equipped_vow_xp).contains("160"), "progress text shows next threshold")
	var saved := run.to_dict()
	var loaded := RunState.from_dict(saved)
	_eq(loaded.equipped_vow_id, "vow_torvahk", "vow save roundtrip")
	_eq(loaded.equipped_sigil_id, "sigil_arcanist", "sigil save roundtrip")
	run.run_deployment = [{"unit_id":"zane", "x":1, "y":6, "facing":"S"}]
	loaded = RunState.from_dict(run.to_dict())
	_eq(loaded.run_deployment.size(), 1, "deployment save roundtrip")
	var bs := BoonSystem.new()
	var offers := bs.generate_offers(99, 4, [], bonus)
	_eq(offers.size(), 3, "weighted offers still returns three")
	var cleave := bs.get_boon("marauder_cleave")
	_eq(str(cleave.get("category", "")), "style", "style boon lookup")
	var bonuses := RunBonuses.compute([cleave, bs.get_boon("vanguard_bulwark"), bs.get_boon("arcanist_overflow")])
	_eq(bonuses.get("cleave", false), true, "style cleave applies")
	_eq(int(bonuses.get("max_temper_bonus", 0)), 30, "style temper applies")
	_true(float(bonuses.get("react_echo_chance", 0.0)) > 0.0, "style reaction echo applies")
	var movement_one := bs.get_boon("windrunner_step")
	var movement_two := bs.get_boon("duelist_footwork")
	var movement_three := bs.get_boon("reaping_step")
	_eq(BoonSystem.boon_lane(movement_one), "movement", "move stat boon is movement lane")
	_eq(BoonSystem.boon_lane(movement_three), "movement", "move tactical boon is movement lane")
	_eq(BoonSystem.boon_lane_limit("movement"), 2, "movement lane limit is two")
	_eq(BoonSystem.needs_lane_replacement([movement_one], movement_two), false, "second movement boon does not replace")
	_eq(BoonSystem.needs_lane_replacement([movement_one, movement_two], movement_three), true, "third movement boon requires replacement")

func _eq(got, exp, label: String) -> void:
	if got == exp:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s (got=%s exp=%s)" % [label, str(got), str(exp)])
		_fail += 1

func _true(value: bool, label: String) -> void:
	if value:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s" % label)
		_fail += 1

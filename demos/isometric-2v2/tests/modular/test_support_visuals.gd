extends Node
const Presentation = preload("res://scripts/presentation/ModularSpellPresentation.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _ready() -> void:
	var p = Presentation.new()
	check(p.has_method("_make_spell_effect"), "Haste and Defend need real support effects, not missing sheet fallback")
	check(p.has_method("_support_result_text"), "Haste needs truthful status-only result text")
	if p.has_method("_make_spell_effect"):
		for ability in ["haste", "defend"]:
			p.context = {"ability_id":ability, "reduced_motion":false}
			for phase in ["casting", "formation", "action", "collision", "dissipation"]:
				var fx = p._make_spell_effect(phase)
				check(fx.available(), ability+" visible "+phase)
				check(fx.has_method("set_reduced_motion"), "support effect supports reduced motion")
				fx.free()
		p.context = {"ability_id":"haste"}
		check(p._support_result_text({"status_applied":{"id":"haste", "duration":3}})=="HASTE\n3 turns", "truthful Haste duration")
		check(p._support_result_text({})=="NO STATUS", "no false Haste success")
		p.context = {"ability_id":"defend"}
		check(p._support_result_text({})=="GUARD\nUntil next turn", "guard lifecycle text")
	p.free()
	print("Support visual checks: failures=", failures)
	get_tree().quit(1 if failures else 0)

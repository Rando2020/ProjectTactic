extends SceneTree
## Isolated instrumentation test, not evidence of a gameplay cast.
class Presenter extends Node2D:
	signal phase_presented(phase: String)
	signal cue_started(cue: String)
	var context := {"action_key": "fixture:1", "actor_id": "zane", "ability_id": "haste"}
	var _actor: WeakRef

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var observer = load("res://courtyard_browser_qa/Observer.gd").new()
	root.add_child(observer)
	var presenter := Presenter.new()
	root.add_child(presenter)
	var glyph = load("res://scripts/presentation/SupportSpellGlyph.gd").new()
	glyph.configure("haste", "casting")
	glyph.set_meta("zane_effect_role", "spell_sheet_casting")
	presenter.add_child(glyph)
	presenter.phase_presented.emit("casting")
	glyph.show_progress(0.5)
	observer._sample_animation()
	var voice: AudioStreamPlayer = load("res://scripts/presentation/CourtyardSkillAudio.gd").play("haste", "charge", presenter)
	presenter.cue_started.emit("haste_charge")
	var events: Array = observer._events
	var failures := 0
	if observer._animation_samples.size() != 1: failures += 1
	elif observer._animation_samples[0].stage != "casting" or observer._animation_samples[0].progress != 0.5: failures += 1
	if events.size() != 2: failures += 1
	else:
		if events[0].name != "casting" or events[0].effects != ["spell_sheet_casting"]: failures += 1
		if events[0].pose != "" or events[0].visuals[0].stage != "casting" or not events[0].visuals[0].available: failures += 1
		if events[1].name != "haste_charge" or events[1].action_key != "fixture:1": failures += 1
		if events[1].voices.size() != 1: failures += 1
		elif not events[1].voices[0].playing or events[1].voices[0].bus != "FX" or not events[1].voices[0].stream: failures += 1
	voice.stop()
	presenter.cue_started.emit("stopped_fixture")
	if observer._events[-1].voices[0].playing: failures += 1
	if not events[1].voices[0].playing: failures += 1 # History is a value snapshot, not a live reference.
	presenter.queue_free()
	observer.queue_free()
	await process_frame
	print("Courtyard observer feedback: %d failures" % failures)
	quit(1 if failures else 0)

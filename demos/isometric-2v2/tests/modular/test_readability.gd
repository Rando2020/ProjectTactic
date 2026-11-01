extends Node
const Frames = preload("res://scripts/presentation/ModularSpellFrames.gd")
const Catalog = preload("res://scripts/presentation/ModularSpellCatalog.gd")
const Presentation = preload("res://scripts/presentation/ModularSpellPresentation.gd")
const Fire = preload("res://scripts/presentation/FireballFrames.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error(label)
func _ready() -> void:
 check(Presentation.CAST_SECONDS >= 0.60,"shared caster buildup must read at normal speed")
 check(Fire.CHARGE_DURATION >= 0.60,"Fire buildup must read at normal speed")
 var f = Frames.new()
 for spell in ["thunderstrike","void_pulse","dark_breath","shadow_mend"]:
  for phase in ["casting","formation","action","collision","dissipation"]:
   f.configure(spell,phase)
   var minimum: float = 0.34 if phase=="casting" else (0.62 if spell=="thunderstrike" else (0.56 if spell=="dark_breath" else 0.52))
   for i in f.frame_count():
    f.show_progress(float(i)/f.frame_count())
    check(f.scale.x >= minimum-0.001,"visible authored scale "+spell+" "+phase)
    var entry: Dictionary = Catalog.DATA["shared" if phase=="casting" else spell][phase][i]
    check(f.offset == -Vector2(entry.anchor[0],entry.anchor[1]),"semantic anchor retained")
    check(f.modulate.a > 0 or phase=="dissipation","casting/action remains visible")
 f.free()
 var fire = Fire.new()
 for phase in ["charge","travel","impact","dissipate"]:
  fire.set_stage(phase)
  check(fire.scale.x >= (0.39 if phase=="travel" else (0.46 if phase=="charge" else 0.55)),"Fire occupied art enlarged "+phase)
 fire.free()
 print("Spell readability: failures=",failures)
 get_tree().quit(1 if failures else 0)

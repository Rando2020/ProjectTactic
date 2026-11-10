# Haste skill candidate for the courtyard

This is an **opt-in review build**, not a live release. It adds the already implemented Haste ability to Zane's existing Fire, Thunderstrike and Void Pulse options in a disposable copy of the real 2v2 courtyard. Kael retains Mighty Strike and Defend. Storm Imp and Void Cultist retain their existing AI and skills.

## What is new

- Existing Haste becomes accessible through the actual Skills menu, target forecast, review, cancel and Confirm controls.
- The archived painted aura is used unchanged as an application effect. Two non-overlapping draw regions place the rear arc behind the recipient and the front arc around their boots. The effect follows the actor, rather than a screen-space position.
- A 1.1-second fade with mild scale expansion uses one static source PNG. This is **not** an authored frame animation or a persistent status loop. Reduced motion keeps the scale fixed.
- Effect reapplication, battle teardown and defeat cannot leave a detached aura.
- Candidate loadout changes are on spawned units only. Saved skills, AbilityDB, combat resolver, turn scheduler, original artwork and production project files are unchanged.

## Mechanics preserved

The real Haste costs 10 MP, targets another ally within the existing range of 1–3, applies its existing three-turn status, and uses the implemented 1.5× effective-speed calculation. The actual projected turn queue refreshes without advancing CT. It does not grant an immediate extra turn or add a charge-turn mechanic.

Self-targeting is **not** enabled: the current ability range excludes the caster's tile, despite resolver support for a hypothetical self-cast. This candidate deliberately does not change that rule. Delay Strike and Heavy Slash are not existing main-branch abilities, so they have not been invented or substituted for Mighty Strike.

## Stage and run

From the repository root, choose a new destination outside the production project:

```sh
python skill-candidates/haste-20261110/stage.py /tmp/projecttactic-haste-review
XDG_DATA_HOME=/tmp/projecttactic-haste-data godot --headless --path /tmp/projecttactic-haste-review --import
XDG_DATA_HOME=/tmp/projecttactic-haste-data godot --path /tmp/projecttactic-haste-review
```

The staging tool refuses an existing destination and checks the source art SHA-256. The copy has its own `ProjectTactic-HasteCandidate-20261110` save namespace. The existing ResultsScreen replay route returns to the staged courtyard, so the candidate loadout is present in fresh fights.

## Verify

```sh
python -m unittest discover -s skill-candidates/haste-20261110/tests -p 'test_*.py'
XDG_DATA_HOME=/tmp/projecttactic-haste-data godot --headless --path /tmp/projecttactic-haste-review res://candidate_skills/tests/SkillTest.tscn
# Actual rendered captures, with a working display (not --headless):
XDG_DATA_HOME=/tmp/projecttactic-haste-data godot --audio-driver Dummy --path /tmp/projecttactic-haste-review res://candidate_skills/tests/SkillTest.tscn -- --capture-dir=/tmp/projecttactic-haste-evidence
```

The engine test uses the actual Skills button, target review, cancellation and duplicate Confirm signals. It verifies one 10 MP charge, one status application, real speed/queue changes, no invented HP changes, layer seam/depth, reduced motion, effect reapplication, teardown, a fresh battle and unchanged saved ownership. Final direct VFX calls are explicitly lifecycle probes, not additional player actions. Fresh-battle checks are not a full victory/replay playthrough. Native capture is not browser/mobile acceptance.

## Art and boundaries

The exact source remains `assets/source/haste-aura-candidate-2026-11-04/art/haste-application-aura-candidate.png`, SHA-256 `3812f27c4f55e4217e22e31ea545896d68e28a8327ad0bd00aecc46e93f14235`. It is copied unchanged only into the disposable project. No source approval flag has changed. Pivot, split and world size are candidate integration choices documented in `manifest.json`.

This does not deploy or change `/courtyard/` or `/tactics/`, integrate character candidates, add stage art, promise audible audio acceptance, or claim final production-art approval.

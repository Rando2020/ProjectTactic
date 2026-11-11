# Courtyard protection practice

`ProtectionSkillsTest.tscn` drives the real courtyard skill buttons, selection
controller, forecasts, combat manager and owner-turn lifecycle. Kael receives
Cover and Iron Wall only in the encounter-local practice loadout. The test checks
that owned/equipped abilities and the save file bytes stay unchanged.

Run from the repository root with Godot 4.6.3:

```sh
XDG_DATA_HOME=$(mktemp -d) XDG_CONFIG_HOME=$(mktemp -d) XDG_CACHE_HOME=$(mktemp -d) \
  godot --headless --path demos/isometric-2v2 \
  res://tests/blooming_skills/ProtectionSkillsTest.tscn
```

Expected headless result: `Protection practice: 143 checks, 0 failures`.

For rendered review, use an available display or the CI Xvfb runner. Do not use
`--headless` with capture mode, because the headless display has no framebuffer.
Use an absolute output directory:

```sh
XDG_DATA_HOME=$(mktemp -d) XDG_CONFIG_HOME=$(mktemp -d) XDG_CACHE_HOME=$(mktemp -d) \
  xvfb-run -a godot --audio-driver Dummy --rendering-method gl_compatibility \
  --path demos/isometric-2v2 res://tests/blooming_skills/ProtectionSkillsTest.tscn \
  -- --capture-dir=/tmp/protection-practice-captures
```

Expected rendered result: `Protection practice: 152 checks, 0 failures`.
Expected frames:

- `protection-skills-menu.png`: Cover and Iron Wall in Kael's real Skills menu.
- `cover-ally-review.png`: Cover target, lifetime and direct-hit-only explanation.
- `cover-feedback.png`: real contact frame with generic aura and `COVER: Kael`.
- `cover-applied.png`: committed Cover and retained movement.
- `iron-wall-review.png`: self review before spending the 10 MP cost.
- `iron-wall-feedback.png`: real status application and generic aura.
- `iron-wall-active.png`: locked action commands with Move and Wait retained.

The checks also cover insufficient MP, invalid Cover targets, cancellation,
repeated confirmation, interrupted anticipation, a target moving after review,
a new lock invalidating an open menu/review, actual Move/Wait commits, two future
owner turns, protection expiry and fresh encounter reset. A hostile direct spell
checks the real interceptor's HP and presentation recipient. These are existing
generic aura/text effects, not new painted skill animations.

Courtyard weapon coverage uses the actual attack review/commit path. Sword follows
the interceptor for forecasts, damage, counters and logs. Spear and greatsword
ignore Cover, including when the guard is inside their footprint; each actual
recipient is hit once. Iron Wall also blocks stale weapon forecasts and auto
attack admission. This adds no required screenshot files.

Protection feedback assertions compare effect anchors against the real units’
global transforms and compare absolute canvas depth with the actual terrain
composite and actor. Both skills must dispatch their three aura shapes above
those layers; Cover text must also be above them. Rendered feedback frames still
require visual inspection, rather than treating node existence as pixel evidence.

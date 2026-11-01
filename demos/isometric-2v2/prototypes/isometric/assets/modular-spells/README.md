# Modular spell presentation assets

The shared Tier 1 casting module is the same four exact transparent crops for all
new modular spells. Lightning has twelve separate formation/action/collision/decay
poses. Variable crop rectangles and source hashes are preserved in the source
manifest; originals are archived here and excluded from game exports.

Runtime uses `ModularSpellCatalog.gd`, explicit semantic ground anchors and nearest
texture filtering. The lightning source depicts a ground-rooted electric pillar,
not a descending bolt or flying projectile: formation/action therefore stay on
the target tile, with a short caster-to-target tracer. Chain arcs are shown only
for actual resolved collateral recipients. No spell changes damage, MP or turns.

Timing is presentation-only: shared cast .32s, formation .18s, action .20s,
collision .24s, decay .32s. Per-frame advancement is bounded so slow frames don't
skip authored poses; at low rendering rates this intentionally stretches visual
time, as the existing Fire implementation does. Final bright sparks fade via
sprite alpha without altering the source PNG. Completed tails use immutable tile
anchors and reproject after camera rotation, without retaining a defeated target.

`ModularSpellAudio.gd` synthesizes original deterministic PCM cues at runtime.
They are not sampled from commercial games. Automated tests do not constitute
listening acceptance or browser/physical-phone validation.

Void Pulse and Dark Breath use three caster-formation frames, three directional
projectile frames, three target-collision frames and three dissipation frames.
Their action art points -45 degrees in source and is rotated around its head
anchor to the projected caster-to-target direction. Dark Breath is deliberately a
narrow single-target stream, not a cone. Shadow Mend is a self-centered teal/violet
restorative spiral; its contact displays actual restored HP and never invokes a
hurt reaction or hit-pause. Defend uses a procedural hollow gold brace ring rather
than the shared magic cast and labels its duration as **Until next turn**.

Tests: `res://tests/modular/test_frames.gd` verifies all stage/frame boundaries;
`res://tests/modular/test_presentation.tscn` samples every pose in real Skirmish
manager dispatch for all four spells, tests lightning at 30 and 8 FPS, complete
retirement and pre-contact cancellation. Source test currently 105 checks passing, including no-late-cue cancellation assertions.

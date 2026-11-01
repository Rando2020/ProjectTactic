# Modular spell integration QA — 2026-11-01

## Runtime scope

- Same four exact RGBA casting poses shared by Thunderstrike, Void Pulse, Dark Breath and Shadow Mend.
- Twelve unique poses per spell; all source sheets and source manifests retained.
- Thunderstrike is a target-grounded electric pillar with contact arcs only to authoritative chain recipients.
- Void Pulse/Dark Breath form at caster and project a narrow directional effect to the target. No new cone or area rule.
- Shadow Mend uses healing feedback, not damage flash/hit-pause. Defend uses a procedural gold brace and “Until next turn.”
- Mighty Strike retains authored melee and adds a modest canonical-only emphasis. Existing Fire/basic attacks unchanged.
- Presentation is ticket-owned, does not apply MP/damage/status/turn changes, and guards audio against synchronous cancellation.

## Validation

- `tests/modular/test_frames.gd`: all 52 unique frames load; boundaries for four authored spell stage sets pass.
- `tests/modular/test_presentation.tscn`: actual Skirmish dispatch samples all 16 poses per spell; Thunderstrike at 30 and 8 FPS; complete tails; cancellation before contact in casting/formation/action; no late release cue after invalidation.
- `tests/modular/test_sync_cancel.tscn`: synchronous phase/cue cancellation cannot emit stale contact sound, hit-pause, camera kick or fallback brace ring; authoritative admitted contact remains applied once.
- Parent coordinator separately owns full combat/player/AI/packed regression and native graphical acceptance.
- Final source runtime was checked after native sizing feedback: lightning .42, shared cast .23, Void/Breath/Mend .34, modular number font28. Original anchors preserved, projectile arrival follows scaled body-center height40.8.
- `SkillVisualQA.tscn` is a QA-only real-manager fixture, normal engine time1.0. `-- --manual` waits for Space per spell. It is excluded from shipping presets.

## Asset identity

`runtime-verification.json` records actual encoded-PNG and decoded-RGBA SHA256 for all52 unique runtime frames. All64 manifest references (including repeated shared frames) compare exactly to their archived original RGBA rectangles.

The supplied historical shared/lightning manifest `sha256` values describe an earlier PNG encoding:28 references differ in encoded bytes while every decoded source crop agrees. Those source manifests were preserved, not silently rewritten. New36 effect-frame byte hashes agree with their manifests.

Source SHA256:

- Shared cast: `d62c3f8908220e775b4dd3425ceb4eddf9d1468ca782d23f88e0f91569fb4f4d`
- Lightning: `a15ef3fe248089ddc525e95844078a3bff5bbf84e326a0e4eae26c6b9174ff54`
- Void Pulse: `cdb10ebba14b3b00d42b2bc84aaa5f55f1d92a4ca8149c26d28aa4a4ec658ea7`
- Dark Breath: `cc757093fe194fd1c4805023fc3840d8e8e2ae509cd3696b5d0597e71282aadf`
- Shadow Mend: `06e336004e70d30ab8c775ccaf906c2f6e42c858f2324813f33c8fd0c0f8a073`

## Limits

Source automated checks are not browser GPU, physical-phone, or listening acceptance. Audio cues are original deterministic synthesized PCM, but this worker has not claimed to hear them. Native normal-time screenshots are coordinator-owned evidence, not a continuous video. No new charge-time, initiative shift, skill or balance rule was added.

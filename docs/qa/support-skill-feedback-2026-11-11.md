# Haste and Defend support feedback

## Implementation

- Haste now uses an original procedural clock face, moving clock hand, forward chevrons and grounded gold ring. Its casting, formation and release remain on the caster; completion is anchored to the actual outcome recipient, including ally casts.
- Defend uses an original procedural shield and shoulder-brace brackets, replacing the missing `brace` sheet lookup. Completion says `GUARD / Until next turn`.
- Haste completion says `HASTE / N turns` using the actual applied outcome duration. Self-Haste currently returns four turns because BattleManager adds the current-turn allowance; ally Haste returns three. Failed/no new status reports `NO STATUS`, never fabricated HP damage or successful status application.
- These are procedural glyph animations, **not finished bespoke painted animation sheets**. The original frame-based Thunderstrike, Void Pulse, Dark Breath and Shadow Mend remain intact. Fire is unchanged.
- Reduced motion keeps the emblem and ground ring stationary without rotating hands or growing the emblem. Cosmetic support never requests hurt reactions, camera kick or hit-pause. Ticket cancellation owns and removes every glyph and voice.
- Audio uses the independently synthesized per-ability `CourtyardSkillAudio` cues and emits an ability/phase cue only after retaining a valid voice.

## Asset review

Inspected the actual Haste candidate PNG plus its README, manifest/review provenance. It is a single generated gold ellipse with upward blade-like strokes, explicitly marked unapproved and unintegrated, without validated frame timing, pivot or front/back occlusion. It remains untouched at `assets/source/haste-aura-candidate-2026-11-04`. Its provenance says OpenAI image generation on November 4, 2026 and explicitly disclaims a blanket license grant. No unapproved art or third-party source was imported for this change.

## Local verification

Godot 4.6.3 headless, writable XDG directories:

- `tests/modular/test_support_visuals.tscn`: red first with two missing-implementation failures; green after implementation, zero failures.
- `tests/modular/test_support_runtime.tscn`: 96 checks, zero failures. Actual manager executions cover self/ally Haste, Defend, normal/reduced motion, ground anchors, truthful outcomes, no damage/hurt/pause, phases, retirement and cancellation at casting/formation/action.
- `tests/modular/test_sync_cancel.tscn`: 9 checks, zero failures. Exact Thunderstrike cue assertions updated for per-ability IDs without weakening cancellation expectations.

- `tests/modular/test_presentation.tscn`: 105 checks, zero failures; authored modular frame coverage is unchanged.

## Render evidence still required

No local rendered screenshots are claimed. There is no display or Xvfb; a temporary Xorg dummy-display startup failed to create its listening sockets, on this workspace. Headless execution proves runtime behavior but not appearance.

The support runtime test accepts `--capture-dir=/absolute/path` under a real render-enabled display, records intermediate casting/formation/action/collision/dissipation PNGs, and fails if capture mode produces no frames. Use that path in rendered CI for final visual review on the actual battlefield.

Rendered CI on 445325a passed 115 skill checks and produced all 14 requested action PNGs. Review exposed support text behind screen-space name badges; the follow-up reserves those exact badge bounds before placing modular spell outcomes, with a failing-first overlap regression. Final screenshots and Web acceptance must be rechecked on that follow-up commit.

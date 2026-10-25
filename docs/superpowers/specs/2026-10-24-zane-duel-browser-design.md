# Optional Zane duel browser QA

Add an independent `zane-duel` QA export/smoke scenario. The production API is
`GameState.begin_zane_duel_practice() -> bool`, with session mode `zane_duel` and
existing `rig3d=true`; never enable the full-party `zane_showcase` flag.

Reuse the unchanged read-only observer through a separate subclass, adding only
unit archetypes, observed legal attack targets and practice mode. A bootstrap uses
the production helper, then changes to a QA Battle scene through normal scene
replacement, so Results really removes the old Battle.

The real CDP exercise loads exactly Zane `(4,5)` and Storm Imp `(6,5)`, captures the
actual imported 3D model, selects one observed legal step `(5,5)`, then performs one
legal sword attack in the same initial turn. No Wait/AI manipulation. Assert zero
sword MP cost, one action/lifecycle ticket, real primary/counter resource deltas,
exact rendered outcome labels and truthful cues. A miss is valid, not hit coverage.

Move+sword ends the turn synchronously, and owned presentation tails outlive that
handoff. Keep two explicit read-only observations: the original authoritative
`turn_ended` record (costs, outcomes, lifecycle and returned pose), then original
sword-owner cleanup. The sentinel captures weak references to that owner's effects,
audio and reaction recipients. It requires the original owner/effects gone, voices
stopped, owner-keyed reaction metadata gone and camera kick finished (or real Battle
removal). A later enemy/counter presentation is not mistaken for the sword owner.
Nothing resets resources, invokes a game action, forces idle, or rewrites evidence.

If normal Results appears after a completed sword, retain its verified completion
and original-owner cleanup rather than poll a dead Battle. If Results appears before
any sword completion, fail promptly with minimal actual terminal evidence. No
results controls, replay actions or broader results observer are exposed.

This is movement plus first-sword coverage, not full duel completion coverage.
Subsequent enemy AI, Fire, victory/defeat, replay and actual title entry remain native
production contracts; the browser report states this boundary. Actual WebGL2 Chrome
acceptance/screenshots remain the external CI gate. No combat/state/RNG mutation,
JavaScript gameplay callback bridge, browser flag or workflow changes. Existing
Quickstep/full-party Zane scenarios and base observer remain unchanged.

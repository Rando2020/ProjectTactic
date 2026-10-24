# Zane shared presentation profile verification

## Bounded change

Base: `8472f7bfebf0fb0214855da329add579bd7d0c97`. This range adds only the frozen original Zane asset/provenance, a nine-line profile, and the existing Unit imported-character list/branch. Zane was already supported by the opt-in practice3D guard, so that guard is unchanged. No shared-engine, gameplay/class/story, phase/timer, render/foot-anchor, save/settings, or cleanup implementation changes.

`SharedRigPresentation.gd` remains byte-identical to base (SHA-256 `65eab94c716c52639c705da6f4386b159d9a51cd594dbea652d1a4b72801e7d3`). Kael/Mira wrappers, frozen GLBs, original-source comparator/fixture and combat-execution test are unchanged.

## Frozen asset and identity

Source and destination both match parent-authoritative SHA-256 `9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5`, 960,764 bytes. The local `.gitattributes` exception scopes ordinary Git storage to `zane_v2.glb` only. No mutable builder source is copied.

`godot/assets/3d/characters/zane_v2/README.md` records original construction/shared-motion source references, current manifest-mapped Vanguard identity, exact reference hashes and limits. The three referenced idle/anticipation/contact image hashes were independently matched against the unchanged project files. The conflicting blond placeholder is not identity authority. No ability/class/actor-id change is introduced.

## Test-first evidence

Before implementation:
- Zane scene: **1 check / 1 intended missing-profile failure**.
- Existing Kael suite: **113 checks / 1 intended Zane-routing failure**.
- Existing Mira suite: **115 checks / 1 intended Zane-routing failure**.
- Playable loop: **425 checks / 3 intended presentation-only failures** (imported Zane skeleton, pixel viewport, shared authored windup).

After implementation:
- Kael: **113/113**, clean log.
- Independent original-source comparator: **2,622/2,622**, clean log.
- Mira: **115/115**, clean log.
- Zane: **116/116**, clean log.
- Terrain cleanup: **10 cycles**, clean log.
- Script validation: **66 scripts loaded**, clean log.
- Unmodified combat execution: **53/53**, clean log for this run. Its known baseline seeded-hit flake was not weakened or duplicated here; approved deterministic fixture `24fff65` belongs to next integration.
- Playable loop: **425/425**. Exit-time audio-resource warnings remain intermittent; verbose run identifies only the same three WAV/playback resources documented and reproduced on the original baseline, not rig/viewport resources. This result is not represented as log-clean.
- Static stability: pass with **19 existing warnings**.
- Asset import is clean after the first pass regenerated unrelated baseline untracked UID files from cache. Those generated files are excluded from the commit.

Zane tests use the actual frozen PackedScene and real Unit/VFX/ActionLifecycle. They cover source hash, sixteen bones/nine durations, render footprint/facing/feet, phase sampling, synchronous projected cast socket, walk/root-motion and defeat hold, required/optional/malformed scenes, opt-out sprites, aliases, Kael/Mira/cultist preservation, cancellation authority, unchanged resources/position/save state and repeated viewport disposal.

## Existing test changes are presentation-only

- Kael's one old Zane-procedural routing assertion now expects the Zane profile.
- Mira's other-actor routing assertion distinguishes imported Zane from unchanged procedural cultist.
- Playable-loop `_check_shared_rigs` expects imported Zane's sixteen bones/160px viewport and shared authored windup; cultist retains the procedural shoulder check.
- All contact, recovery, cancellation, resource/gameplay and death/cleanup assertions remain intact. `_check_casting_and_frame` is unchanged and now exercises the real Zane imported cast origin with his existing Void Pulse loadout.

## Scope / handoff

Builder's positive dense clip/blend/gait checks are asset evidence, not a newly added runtime blend policy. Existing manually sampled generic choreography stays unchanged; bespoke fencing, GPU performance, native visual acceptance and arbitrary-speed foot locking are not claimed. Parent inspected the art targets and owns the separate integration/code review. No publication, live-source edits, GUI access, rebase or prior-commit rewrite occurred.

Evidence logs: `/tmp/shared-rig-zane-*.log`. Reproduce with isolated XDG directories and `godot --headless --path godot --scene res://tests/test_zane_presentation.tscn`, plus the existing scene suites named above. Never run save-changing suites against player data.

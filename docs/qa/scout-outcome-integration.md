# Scout + outcome-plumbing integration — 24 October 2026

## Boundary

New isolated branch `scout-outcome-integration-2026-10-24`, rooted at approved `c5563585f49a2c09b8b19b6b3f83b8474fbd459e`. Applies the approved Scout patch `9ce5157a612c1c0cf5ae4fd02caacd65e9794f3b` and recovery-only test `31cd7fc722a62458e8d8f8435e13f44baf75e4c7`. Their original checkout/branch and `projecttactic-next` are unchanged. This is the following gameplay slice, not part of the character/outcome-log release. No rollout, publication, merge, export or GUI work is authorized here.

The earlier Scout design/verification reports are historical records of their original base. Recovery coverage is now closed and retained byte-for-byte; this report records the newer integration boundary.

## Conflicts and exact adaptation

1. **BattleManager:** three overlapping hunks around the new result-returning execution path. Retained `_execute_ability_with_result` and the unchanged bool `_execute_ability` wrapper. The unchanged approved `_execute_quickstep` helper remains a bool implementation; its result is wrapped as `{executed: accepted, outcome: {}}`. Long Shot's primary admission/contact failures now return `{executed: false, outcome: {}}`, not bare booleans. These are the only new production adaptations beyond the reviewed Scout behavior.
2. **Runner expectation set:** unioned Scout with the existing outcome/Mira/Zane/shared-rig registrations, retaining every existing test. The runner itself and updated playable fixture auto-merged; its Zane assertions and all preexisting runner behavior remain.
3. Applied the approved 23-line recovery patch unchanged. Git's multi-commit no-commit sequence stopped on its local index state after resolving the first patch; the remaining exact patch was checked and applied with `git apply --index`, without resetting the resolved work.

Quickstep remains 5 MP + action for one ordinary movement after moving, no buff/free attack. Long Shot remains 60 power, 0 MP and 3–5 range. Canonical precedence and empty unknown IDs remain as approved. No save/job/story/CT/AI expansion or other skill changes.

Byte/method comparisons confirm unchanged `CombatResolver.gd`, `Unit.gd`, `ActionLifecycle.gd`, 184-check outcome and 58-check Silence fixtures; unchanged bool wrapper, AoE/chain executor, outcome formatter and Silence gate; unchanged approved Quickstep eligibility/executor/self-selection and 122-check Scout fixture. Applied outcomes, per-hop logging, and secondary-target semantics are retained.

## Tests and evidence

- Fresh unmodified c556358 base: all 15 contracts pass.
- New real-scene result/bool-boundary regression observed **101 checks / 53 failures** before integration, then **101/0** after adaptation.
- Extended integration fixture: **115/0**, including direct result envelopes, bool admission parity, early/MP/action/turn/contact rejection, no rejected/duplicate logs, legal Long Shot applied results, actual Fire fan/Thunderstrike chain secondaries beyond caster range, and ordinary self-heal actual outcome. A first Fire log expectation was corrected to retain its two existing Burn notices, not suppress them.
- Focused approved contracts rerun: **Scout 122/0, outcome 184/0, Silence 58/0**.
- Full combined runner: **17 contracts, 6,837 checks and 10 terrain cycles, zero failures**; playable 427/0. No existing fixtures removed or weakened.
- Whole Python suite 36/36 (runner 6/6); static stability passes with 19 existing warnings; narrative passes, parser loads 66 scripts, HUD 30 assertions pass.

Existing outcome/cancel/playable shutdown diagnostics remain visible. Verbose inspection of the new integration fixture's shutdown warning identifies only `spell-cast.wav` / WAV playback, the same preexisting audio shutdown category, not gameplay or rig resources. No script errors. No browser/native/live-game acceptance is claimed.

Evidence: `/workspace/shared/scout-outcome-integration-evidence/` (`base-suite.log`, `integration-red.log`, `integration-green.log`, focused logs, `combined-suite.log`, `additional-validation.log`). All 218 local LFS assets were hydrated only after SHA-256 matched the frozen base pointers; no asset changes included. Fresh independent review is required for this async-plumbing overlap before integration/rollout.

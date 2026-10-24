# Hit-based secondary status implementation plan

> Execute inline under debugging/TDD; independent parent review before any integration.

**Goal:** Apply damaging ability secondary status on each recipient's actual hit, not on misses.
**Architecture:** Shared `AbilityDB.secondary_status_requires_hit(ability: Dictionary) -> bool`; BattleManager uses existing resolver `missed`, ForecastCalculator uses the same predicate. Preserve support and two explicitly approved readiness exceptions.
**Tech stack:** Godot 4.6.3 / GDScript.
**Spec:** `docs/superpowers/specs/2026-10-24-hit-secondary-status-design.md`.

## Constraints and review focus
No formula/cost/action/timing/expiry/Silence/terrain/boon redesign. No deployment or merge. Real action accounting, per-target mixed outcomes, hit-at-zero-damage, support/readiness exceptions and truthful logs must be covered. Chain falloff must not reclassify an originally damaging ability as status-only when its effective power rounds to zero.

## Task 1 — hit contract
- [x] Audit exact base and authored data; report ambiguous passive effects; obtain parent's narrow exception approval.
- [x] Establish baseline aggregate and static results.
- [x] Add `test_hit_secondary_status.gd/.tscn`: real input paths; deterministic physical/magical/area/chain outcomes; MP/action accounting; support/readiness/zero-damage/duration/terrain regressions. Watch intended RED.
- [x] Explicitly update only legacy miss-status expectations in `test_spell_outcome_feedback.gd`; retain outcome/cost checks.
- [x] Add shared predicate in AbilityDB; gate only physical/magical authored statuses in BattleManager; use predicate for concise forecast wording.
- [x] Add new scene to aggregate runner and its harness test expectations (runner RED then GREEN).
- [x] Run focused suite, existing 184 feedback checks and complete aggregate plus static/script/Python checks; record warnings and overlap.
- [ ] Review diff, obtain independent parent review, commit scoped change, report branch/hash and evidence without publication.

## Ledger
Baseline: exact requested tree. Aggregate 15 contracts passes; static passes with 19 pre-existing warnings. Existing shutdown ObjectDB/resource warnings remain visible. Exception ruling: parent approved exactly blaze_counter_ready and arc_counter_ready; no suffix wildcard or claim of passive implementation.

RED: new contract 125 checks / 18 expected failures; existing feedback 184 checks / exactly 2 intentional miss-status failures; runner registration 6 tests / 1 failure. GREEN focused new contract 125 / 0, Python 36 / 36, static pass with the same 19 baseline warnings. No resolver implementation or formula changed.

Integration overlap: Quickstep integration also edits BattleManager executor and AbilityDB plus aggregate runner expectations. Healing-preview branch edits ForecastCalculator (different function), BattleManager preview context (different function), and runner registration. Reconcile the union of contract scenes and retain this secondary gate around ordinary damage branches; do not carry legacy miss-status assertions back in.

Full verification: aggregate 16/16 contracts, 6,723 assertions/checks plus 10 terrain cycles, zero failures. Updated feedback retains 184 checks; Silence 58, combat execution 56, new status contract 125. Python 36/36. Production parse 66 scripts; Orren 31, asset manifest 94, HUD 30, element resolver 9, vow/sigil 23 all pass. Narrative/art validators pass; diff whitespace check passes. Existing ObjectDB/resource shutdown diagnostics persist intermittently, including the new harness; no script errors. No GUI or live-release acceptance claimed.

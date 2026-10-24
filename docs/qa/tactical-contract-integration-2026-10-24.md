# Tactical-choice contracts integration — 24 October 2026

## Boundary and provenance

Isolated branch `nova/tactical-choice-contracts`, based on released main
`c80a025930a7e27c6fc2def169b82b1e23d1e3f5`. Its tree is identical to the prior
`c556358` spell-feedback checkpoint. Previous source, releases and exports are
preserved. This integration does not include the separate starter-identity task.

Approved components applied in order:

- Scout `115e2abecb80fc82375df69ef4400e0093fc9b23` → `f76141a`.
- Targeted healing `305d94244ac988578e2c5626f3837e1e583682ff` → `75dbca3`.
- Decorated healing notes `86646a5896ddfa1ea9e235623eef3511563fde72` → `5bb8663`.
- Hit-based secondary status `7f6c8c58c29375b301cc6fc3651ec3d3d49324dc` → `d58b3be`.
- Delivery reconciliation `d682be52e90f9afc7af16491d77406f1193f3992` → `11a777d`.

## Every integration conflict and adaptation

Scout applied without conflicts. Both healing commits auto-merged their
BattleManager/ForecastCalculator and runner hunks; no manual code adaptation.
Delivery documentation applied unchanged.

Hit-status had exactly three content conflicts:

1. `AbilityDB.gd`: both additions occupied the end of the class. Retained Scout's
   exact `get_range` implementation and the hit-status component's exact
   `secondary_status_requires_hit` implementation, in that order.
2. `check_playable_loop.py`: retained both healing and hit-status registrations.
   Scout and every previous fixture remain present in their existing order.
3. `test_check_playable_loop.py`: unioned the expected names, without duplicating
   spell outcome or removing any prior fixture.

Executor and forecast changes auto-merged. The result-returning executor still
wraps Quickstep admission as `{executed, outcome}`; the bool wrapper is unchanged.
Long Shot admission/contact range checks remain primary-only. Per-recipient hit
gating retains the source-ability predicate for chain falloff, including a hop
whose power rounds to zero. Existing MP/action/phase costs, terrain/on-cast
effects and the two exact readiness exceptions are preserved. The hit component's
two deliberate MISS-status expectation updates remain in the 184-check outcome
fixture; they were not reverted to the older assertions.

## Narrow additional regression and correction

The real Quickstep ability-button hover was already correct: it uses the raw
movement forecast. A targeted generic decorated-preview probe reproduced a
separate issue: with attack boons active, it advertised Battle Fury, Iron
Momentum, Coup de Grace, Cleave/Piercing and JP multiplication for a movement
grant that deals zero damage and earns zero JP.

The 30-check integration fixture failed exactly its two bonus-decoration
assertions before correction and passes afterward. An initial control assumed
armor fully absorbed a physical attack; the control was corrected to use high
physical resistance before recording the intended two-failure RED result.

The correction is only a movement-grant early return in
`_with_run_bonus_context`. It preserves the existing action/MP/movement note and
does not change execution or boon state. It deliberately does **not** classify
actions by positive forecast damage: the zero-HP-damage Long Shot control retains
its attack-boon context. The fixture also checks real hover, canonical ranges,
the shared status predicate, on-hit wording, repeatability, RNG and state purity.
It is registered in the bounded runner; missing registration was independently
observed as a failing runner unit test before adding it.

## Verification and remaining gates

The untouched released baseline passed cold import and all fifteen contracts
after scoped hydration of 218 current runtime LFS paths (174 unique objects).
No asset payloads or generated import sidecars are part of this source change.
Focused integration RED/GREEN and runner registration evidence are retained in
the integration evidence directory. Final combined regression, export-isolation
results and fresh independent integration review are recorded with the exact
frozen revision in the handoff, rather than inferred from component approvals.

Explicit exclusions remain: empty-area healing preview and the zero-power
Smoke Screen MISS-plus-Blind behavior. Neither is silently fixed or represented
as covered by the damaging-secondary correction. This is not a complete combat
redesign. Browser/native acceptance and any source publication or deployment
are separate gates; this integration work performs none of those actions.

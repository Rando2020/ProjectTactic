# AI Ability Action Surface

## Purpose

This experiment is the first implementation task selected by ProjectTactic's AI Game Director from real self-play evidence.

The Director observed that all existing automated player decisions were limited to basic attack, movement, and wait. That made the project's most important roguelike tactics layer invisible to evaluation: character abilities, elemental matchups, healing, statuses, area attacks, MP tradeoffs, and kit expression.

This system exposes those real choices to one new evaluation policy without changing production combat balance or changing the existing greedy/random controls.

## Files

- `godot/scripts/ai/self_play/SelfPlayDecisionSurface.gd`
  - keeps the original basic action surface as the default
  - opt-in policies can request legal ability actions
  - reads abilities from the unit's real `UnitData`
  - reads definitions from `AbilityDB`
  - uses `ForecastCalculator` for the same combat math used by previews/resolution
  - uses BattleManager's real AoE target resolution for fan, cross, line, chain, radius, and other supported shapes
  - executes through `select_command()`, `select_ability()`, `_on_unit_clicked()`, and `_on_tile_clicked()`
- `godot/scripts/ai/self_play/AbilityAwarePolicy.gd`
  - separate deterministic heuristic policy
  - opts into abilities explicitly
  - compares damage, lethal targets, healing, statuses, affected targets, and MP cost
  - does not replace or modify `greedy-damage-v1`
- `godot/scripts/ai/self_play/SelfPlayController.gd`
  - asks a policy whether it opts into expanded ability actions
  - records ability-specific features in telemetry
- `godot/tests/test_self_play_baselines.gd`
  - verifies the policy opts in and can prefer a useful ability
- `godot/tests/self_play_baseline_runner.gd`
  - adds an `ability` real-battle mode
  - requires at least one recorded `ability:*` decision
- `tools/check_self_play_baselines.py`
  - repeats the ability-aware seed and compares the full deterministic trajectory
  - feeds greedy, random, and ability evidence to the AI Producer
- `tools/check_ai_game_director.py`
  - feeds all three policy evidence files back to the Game Director
  - requires the Director to stop selecting the completed visibility experiment and advance to its next highest-information experiment

## Architecture boundary

The ability-aware layer is an observer/controller adapter. It does not become a second combat engine.

```text
UnitData abilities
      |
      v
AbilityDB definitions
      |
      v
SelfPlayDecisionSurface
      |             \
      |              -> ForecastCalculator
      |              -> BattleManager AoE target rules
      v
AbilityAwarePolicy chooses
      |
      v
BattleManager normal command / targeting path
      |
      v
CombatResolver + game rules
      |
      v
BattleTelemetry evidence
```

When production ability behavior changes, the evaluator should inherit that behavior from those real systems instead of duplicating formulas.

## Control preservation

`SelfPlayDecisionSurface.legal_actions()` defaults `include_abilities` to false.

The existing policies do not expose `uses_ability_actions()`, so:

- `greedy-damage-v1` continues to see basic attack, move, and wait only
- `random-legal-v1` continues to see basic attack, move, and wait only
- `ability-aware-v1` explicitly opts into abilities

This keeps the original trajectories useful as controls. The ability experiment cannot claim an improvement merely because the definition of the old policy silently changed.

## Normalized ability evidence

An ability action records:

- `action_id` as `ability:<ability-id>`
- ability id and display name
- spell/type identity
- target or target center
- total expected immediate damage across useful targets
- expected effective healing after overheal is removed
- lethal target count
- useful target count
- status/buff target count
- MP cost

These are evaluation features, not a final utility function.

Delayed status value, displacement, turn-order manipulation, terrain reactions, summon value, counterfactual safety, and multi-turn setup value require later evaluators.

## Ability-aware policy

`ability-aware-v1` is intentionally transparent rather than sophisticated.

It strongly values lethal outcomes, then immediate damage, healing, status application, multi-target value, and resource cost. It still understands basic attack, movement toward damage opportunities, and wait.

The purpose is not to create the optimal player. The purpose is to make ability choices visible and produce interpretable comparison evidence.

A later search policy or reasoning model should be compared against these deterministic controls instead of replacing them.

## Self-improvement feedback

The important acceptance test is not only whether ability-aware self-play runs successfully.

After `ability.json` is produced, the Game Director consumes:

- greedy evidence
- random-legal evidence
- ability-aware evidence

Because ability actions are no longer an unobserved blind spot, the Director must choose a different experiment. Under the current north-star priorities, the expected next prompt is `exp-deterministic-scenario-matrix` on branch `feature/ai-tactical-scenario-matrix`.

This is the first closed-loop demonstration of:

```text
AI identifies blind spot
-> AI writes implementation prompt
-> implementation generates new evidence
-> AI recognizes the blind spot changed
-> AI writes a different next prompt
```

## Best practice

Do not interpret better ability-aware performance as proof that abilities are fun or balanced. The meaningful question is whether abilities create additional credible tactical lines and whether human players find those lines expressive, understandable, and satisfying.

## Risks and tech debt

- Immediate forecast value underestimates buffs, control, delayed statuses, displacement, terrain setup, and action-economy effects.
- AoE center enumeration increases legal action count and can become expensive as ranges/maps grow. Search policies will eventually need pruning or action abstraction.
- Some ability definitions may expose production inconsistencies. The evaluator should report them rather than silently compensate with a parallel formula.
- One Ashvale encounter still cannot establish broad balance.
- Human acceptance remains required before changing player-facing balance from self-play findings.

## Next evolution

If this experiment passes, the Game Director should receive the new evidence and select the next experiment itself. The current expected candidate is a small deterministic scenario matrix that varies terrain, formation, composition, and objective pressure while preserving the three current policies as controls.

Do not merge automatically.

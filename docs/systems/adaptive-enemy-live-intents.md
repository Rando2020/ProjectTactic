# Adaptive Enemy Live Intent Experiment

This stacked experiment wires the validated adaptive-opponent foundation into the real Battle scene without changing default player-facing behavior.

## Architecture

`Battle.tscn` now uses `AdaptiveBattleManager`, a small subclass of the existing `BattleManager`.

The subclass defaults `adaptive_enemy_enabled` to `false`. With the flag off, `_evaluate_enemy_intent()` delegates directly to the existing deterministic BattleManager logic and existing self-play trajectories are expected to remain unchanged.

With the flag on, the subclass:

1. observes only committed player moves, attacks, abilities, AoE abilities, waits, and completed-turn formations;
2. updates the decaying `AdaptiveOpponentModel`;
3. preserves heal, retreat, hold, and obvious lethal decisions from the base AI;
4. enumerates reasonable nonlethal offensive alternatives using the existing BattleManager rules;
5. asks `AdaptiveIntentBias` to apply its bounded scoring nudge;
6. adds a readable `adaptation` explanation to the chosen intent when learned behavior materially affected the decision.

No new combat resolver, pathfinder, damage formula, ability rule, or target legality rule is introduced.

## Why a subclass

`BattleManager.gd` is already a large central file. The adaptive experiment belongs at explicit seams around observation and enemy intent rather than expanding the core manager with another full subsystem.

The subclass also gives us a clean rollback: point `Battle.tscn` back at `BattleManager.gd` and the entire live integration disappears while the reusable opponent-model foundation remains available.

## Observed player behavior

Only completed behavior is recorded:

- committed movement and whether it closed distance;
- completed basic attacks;
- completed single-target and AoE abilities;
- waits;
- actual post-resolution damage/healing where available;
- end-of-turn player formation.

Hovered targets, canceled commands, and future inputs are never treated as observations.

## Decision scope

Adaptation is intentionally subordinate to the base AI.

The original AI keeps control over:

- self-preservation through heal and retreat;
- hold when no useful action exists;
- obvious lethal opportunities;
- all legality, pathing, forecast, range, and combat math.

Adaptive scoring only helps choose among close nonlethal offensive alternatives.

This prevents the opponent model from replacing authored tactical identity with a generic optimizer.

## Telegraphing

When learned bias is material, the intent contains an `adaptation` object and its note/summary includes a phrase such as:

`Adapted to high observed contribution, repeated ranged pressure.`

The final player-facing language can become more thematic later. The first requirement is that the behavior remains explainable in tests and debug UI.

## Validation

The live CI gate requires:

- Godot static/import validation;
- the adaptive-opponent model regression suite;
- a real Battle scene smoke test proving adaptation is off by default;
- the same scene consuming a high-confidence learned profile and producing a transparent adapted intent;
- the existing full self-play baseline suite with adaptation disabled, so the scene-script substitution cannot silently change the established controls.

## Next experiment

If this gate remains deterministic, add an A/B self-play mode:

- control: adaptive flag off;
- learned: adaptive flag on with observations accumulated naturally from earlier turns/battles;
- compare target diversity, player policy changes, HP pressure, turn count, intent changes, and adaptation frequency.

Do not optimize for the enemy winning more often. The success criterion is whether the system creates readable pressure that rewards the player for changing habits.

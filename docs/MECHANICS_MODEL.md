# Mechanics Model

This file describes the current design target, not a promise that every item is fully polished today.

## Turn Economy

The demo currently uses team phases: players move/act, then enemies move/act. The architecture includes CT helpers so the next step can become individual turn order:

1. Units gain charge from speed.
2. A unit becomes ready at 100 charge.
3. Acting spends the ready state.
4. Strong skills can later add charge delay.

This keeps the readable tactics feel while leaving room for faster, reactive battles.

## Actions

Each unit currently has:

- One move.
- One action.
- Optional MP costs.
- Wait/end turn.

Future extension:

- Light action, heavy action, reaction.
- Skill charge times.
- Opportunity or follow-up attacks.

## Movement

Movement range uses:

- Base move.
- Terrain cost.
- Occupied tiles.
- Walkability.
- Jump limit between heights.
- Status movement modifiers.

## Combat

Damage is original to Project Tactics:

- Ability power gives the skill its identity.
- Unit attack and target defense shape final damage.
- Height gives a modest advantage or penalty.
- Guarded targets reduce incoming damage.

Healing uses:

- Ability power.
- Caster spirit.
- A small height advantage bonus when healing from level or higher ground.

## Status Effects

Current statuses:

- Guarded.
- Warded.
- Evasive.
- Slowed.
- Marked.
- Poisoned.
- Shaken.

Statuses have duration. Poison currently ticks damage. Slowed affects movement. Guarded affects incoming damage.

## Surfaces

Current surface hooks:

- Mud.
- Ember.
- Spark.

Surfaces can apply damage or statuses on turn start. Reactions are data-defined, so later skills can create or transform terrain effects.

## AI

Enemy AI currently:

- Finds nearest living player.
- Chooses the strongest usable ability in range.
- Moves toward the target if no ability is available.
- Attempts a follow-up ability after moving.

Next AI step:

- Respect `ai_profiles.json`.
- Prefer high ground.
- Avoid standing in damaging surfaces.
- Focus weak targets only for skirmishers/casters.

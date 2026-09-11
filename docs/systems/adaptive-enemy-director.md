# Adaptive Enemy Director

## Purpose

The Appointed should eventually feel like it is learning the player without cheating.

This system is intentionally separate from the project-level ChatGPT creative director. ChatGPT learns the game project across code, experiments, creator feedback, and story decisions. The Adaptive Enemy Director learns only fair, observable player tendencies needed to create tactical rivalry inside the game.

The desired player thought is:

> They noticed what I keep doing. I need to change.

Not:

> The game read my input or secretly gave the enemy better numbers.

## Current foundation

The first implementation contains two development-safe pieces:

- `AdaptiveOpponentModel.gd` records decaying tendencies from completed player actions.
- `AdaptiveIntentBias.gd` converts those tendencies into a capped, inspectable scoring nudge for otherwise normal enemy-intent candidates.

This PR does **not** yet wire the bias into production `BattleManager` choices. That integration should be a separate experiment after the model's learning behavior and caps are validated.

## What the model can learn

The first profile tracks only observable, completed behavior:

- basic attack vs ability usage;
- ranged-action preference;
- aggression while at low HP;
- movement that closes distance;
- player-unit damage/healing contribution;
- player clustering over completed turns;
- per-unit elemental usage;
- a bounded recent-action history for debugging.

It does not know what command the player hovered, canceled, considered, or will choose next.

## Forgetting and adaptation

Old behavior decays every observed player turn. New behavior therefore competes with and eventually replaces stale reads.

This is important for fairness. If the player used ranged pressure for several battles, the game may begin respecting that tendency. If the player deliberately changes style, the old read should lose value rather than permanently labeling the player.

The model is serializable through `to_dict()` / `load_dict()` so a later PR can decide the correct persistence scope:

- battle-local;
- run-local;
- rival/faction-local across selected encounters;
- or a carefully bounded save-level memory.

Do not choose permanent save-level adaptation without playtesting whether it feels like growth or punishment.

## Intent-bias rules

`AdaptiveIntentBias` never replaces the base tactical score.

Current hard limits:

- no adaptive influence below 25% model confidence;
- at most 18% of a candidate's base score;
- at most 24 absolute score points;
- no negative score manipulation in the first version;
- no learned bonus without completed observations;
- meaningful learned influence carries an explanation suitable for future intent UI.

Initial learned nudges can reward an enemy candidate for:

- targeting a repeatedly high-contribution player unit;
- pressuring a unit that repeatedly creates ranged pressure;
- choosing a close AoE alternative after repeated player clustering.

A base option that is clearly stronger should remain stronger. Adaptation is intended to break close tactical ties and create pressure, not override sound combat rules.

## Fairness contract

The adaptive system may use:

- completed player actions;
- past damage/healing contribution;
- past positions and formation tendencies;
- public run/build information the enemy design is intentionally allowed to react to;
- prior encounters if the chosen persistence scope explicitly supports that fiction.

It must not use:

- future player inputs;
- hovered or canceled commands as if they were committed behavior;
- future RNG rolls;
- hidden information unavailable by design;
- artificial stat inflation disguised as learning;
- exact hard counters triggered after a single success.

## Telegraphing

When adaptation becomes player-facing, it should be legible.

Possible surfaces include:

- enemy-intent notes such as `Studying Mira: repeated ranged pressure`;
- formation changes before battle;
- rival dialogue that acknowledges a repeated tactic;
- new enemy priorities visible through intent previews;
- faction-specific countermeasures introduced gradually across a run.

Do not surface raw percentages unless useful for a debug view. The player should understand the behavior fictionally and tactically.

## Future phases

### Phase 1: validated tendency model
Current PR. Pure model, bounded scoring, deterministic tests.

### Phase 2: BattleManager integration
Feed committed player actions into the model and let the model nudge existing enemy intent candidates behind a development feature flag. Preserve the current deterministic intent path as fallback.

### Phase 3: run-level persistence
Store an opponent profile in run state, with explicit decay between encounters. Compare battle-local vs run-local adaptation in human playtests.

### Phase 4: tactical counter families
Use learned tendencies to choose among authored responses, for example:

- cluster pressure -> AoE/control priorities;
- ranged dominance -> flank/line-of-sight pressure;
- repeated rushdown -> brace, screen, or bait formations;
- low-HP greed -> finish pressure;
- repeated elemental package -> resistant composition only when telegraphed and never as a total hard counter.

### Phase 5: rival and faction memory
Specific recurring enemies or factions can develop recognizable adaptation personalities. One rival might obsessively punish the player's carry; another might learn formation habits; another might deliberately fake adaptation to manipulate expectations.

This is where the system can become narrative as well as tactical.

## Evaluation

Automated tests should measure:

- no bias before sufficient evidence;
- deterministic learning from the same observations;
- hard influence caps;
- stale reads weakening when player behavior shifts;
- profile serialization round-trip;
- close decisions changing while obvious base decisions remain stable;
- no use of future/hidden state.

Human playtests must answer:

- Did the player notice the enemy adapting?
- Did adaptation feel earned and fair?
- Did it cause the player to change strategy?
- Did changing strategy successfully reduce the value of the enemy's old read?
- Did the system create rivalry and curiosity rather than frustration?

## Known risks

A model can become technically clever while making the game exhausting. Constant counter-adaptation can punish mastery and erase the pleasure of a build coming online.

The Director should therefore create pressure selectively. Some encounters should let the player enjoy being powerful. Others should ask whether that power has become predictable.

Adaptation is a pacing tool, not a requirement that every enemy counter everything the player enjoys.

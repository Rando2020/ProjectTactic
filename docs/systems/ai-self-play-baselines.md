# AI Self-Play Baselines

## Purpose

ProjectTactic now has a passive battle telemetry layer and an AI producer that can consume evidence. This system adds the first repeatable automated players so the project can generate tactical evidence without waiting for a human to manually play every seed.

The goal of this phase is not to build a strong AI. It is to establish weak, understandable, deterministic baselines that use the real battle rules. Stronger search and learned policies need these controls for comparison.

## Files

- `godot/scripts/ai/self_play/SelfPlayDecisionSurface.gd`
  - reads the current real `BattleManager` state
  - enumerates legal basic attacks, legal movement tiles, and wait
  - computes policy-facing features from the existing combat prediction and grid systems
  - executes chosen actions through BattleManager's normal command path
- `godot/scripts/ai/self_play/RandomLegalPolicy.gd`
  - deterministic seeded uniform choice over the normalized legal list
  - intentionally weak control policy
- `godot/scripts/ai/self_play/GreedyDamagePolicy.gd`
  - deterministic heuristic baseline
  - prioritizes lethal attacks, immediate damage, then movement that enables damage
- `godot/scripts/ai/self_play/SelfPlayController.gd`
  - disables only BattleManager's legacy built-in auto player for the explicit test run
  - listens for real player turns
  - preserves player turns emitted synchronously while a prior automated action is unwinding
  - exposes an explicit stop-and-quiesce boundary for safe test teardown
  - asks the policy for a choice
  - records the choice through `BattleTelemetry.record_decision()`
  - executes the action and handles move-then-act turns
  - stops on battle completion or a bounded turn limit
- `godot/tests/test_self_play_baselines.gd`
  - lightweight deterministic policy-selection regression
  - does not load the battle runtime
- `godot/tests/SelfPlayBaselineRunner.tscn`
  - normal Godot project-scene entry point for real-battle tests
  - ensures project autoloads initialize the same way they do during gameplay
- `godot/tests/self_play_baseline_runner.gd`
  - instantiates the real `Battle.tscn`
  - drives the hardcoded Ashvale debug battle in headless mode
  - quiesces the controller before evidence export and teardown
  - exports `self_play` evidence for greedy and random-legal policies
- `tools/check_self_play_baselines.py`
  - imports Godot in isolated user data
  - runs the lightweight policy test separately from the project-scene battle tests
  - runs greedy, random, and a repeated greedy scenario through the real-battle runner
  - asserts identical seeded greedy trajectories
  - validates both baseline evidence files through the AI producer
  - writes a compact baseline summary
- `.github/workflows/ai-self-play-baselines.yml`
  - pins Godot 4.6.2
  - runs static checks and the real-battle baselines
  - uploads evidence and producer reports

## Architecture

The boundary is:

```text
BattleManager and game rules
          |
          v
SelfPlayDecisionSurface
          |
          v
Policy chooses one normalized action
          |
          +--> BattleTelemetry records the decision
          |
          v
SelfPlayDecisionSurface executes through BattleManager
          |
          v
Battle result and telemetry evidence
          |
          v
AI Producer
```

This keeps four responsibilities separate:

1. **Game rules** decide what is legal and how combat resolves.
2. **Decision surface** translates current game state into normalized choices.
3. **Policy** decides which choice it prefers.
4. **Telemetry** observes what happened.

A future policy can therefore become much smarter without modifying combat code.

## Runtime boundaries proven by the harness

### Real battles must use normal project startup

The standalone policy regression can run with `godot --script` because it only loads policy code. The real battle cannot use that startup path safely because ProjectTactic's battle runtime depends on project autoload globals.

Real self-play therefore launches `SelfPlayBaselineRunner.tscn` as a normal project scene. This gives `BattleManager`, combat services, and autoload singletons the same initialization model used by gameplay before `Battle.tscn` is instantiated.

Do not collapse the real-battle regression back into a standalone `--script` test unless the battle runtime is later refactored to remove those startup dependencies.

### Player turns can transition synchronously

BattleManager can complete a command, resolve a turn, advance turn order, and emit the next player's `turn_started` signal before the self-play coroutine that issued the previous command has fully unwound.

`SelfPlayController` therefore keeps one pending player unit id whenever a new player turn arrives while the controller is already driving an action. When the current action finishes, the controller verifies that the queued unit is still the active player turn and dispatches it. This prevents legitimate turns from being dropped while keeping enemy turns and completed battles authoritative.

This synchronization behavior is part of the harness contract. Future policy implementations should not add their own turn loops around BattleManager.

### Battle completion must quiesce the controller

A battle result can be emitted from inside the same command execution that a self-play coroutine is awaiting. Destroying the battle or releasing the RefCounted controller immediately can therefore resume a suspended coroutine into released state on the next frame.

The runner now calls `SelfPlayController.wait_until_idle()` after the outcome or bounded stall is observed. The controller stops accepting new decisions, unwinds the active action coroutine, and only then allows telemetry export and scene destruction.

## Initial action space

This first version deliberately limits player policy choices to:

- basic attack against each enemy currently in legal range
- movement to each currently legal reachable tile
- wait

Abilities are intentionally deferred. Adding every ability, AOE center, item, interaction, and special mechanic in the first pass would make it harder to establish whether the harness itself is deterministic.

The decision surface already provides features useful for later policies:

- expected attack damage
- lethal flag
- target HP
- distance to nearest enemy
- whether an attack is available after a move
- best predicted attack damage after a move
- destination height

## Baseline policies

### Random Legal v1

`random-legal-v1` samples uniformly from the normalized legal action list with its own seeded `RandomNumberGenerator`.

Why it exists:

- establishes a low-skill control
- reveals whether a scenario resolves even with poor decisions
- provides a comparison for stronger policies
- catches accidental policy dependence on dictionary iteration order because the legal list is sorted first

It is not intended to represent a novice human player.

### Greedy Damage v1

`greedy-damage-v1` follows a transparent heuristic:

1. Prefer lethal attacks.
2. Otherwise prefer the highest immediate expected basic-attack damage.
3. If no attack is available, prefer movement that enables the strongest attack.
4. Otherwise reduce distance to an enemy, with only a tiny high-ground tiebreaker.
5. Wait only when no better option exists.

Why it exists:

- establishes an understandable aggressive baseline
- can expose encounters that collapse into obvious damage races
- gives later terrain, control, defensive, and search policies something to outperform

It is not meant to be the production enemy AI.

## Real battle validation

The regression instantiates `res://scenes/Battle.tscn`, not a duplicated combat simulator. The existing Ashvale debug map, unit spawning, TacticalGrid, TurnOrder, CombatResolver, ObjectiveTracker, and BattleManager are used.

The normal runner scene creates the battle, disables only `BattleManager.auto_battle_enabled`, and attaches the self-play controller. `SelfPlayController` then drives player turns through `select_command()`, `_on_tile_clicked()`, and `_on_unit_clicked()`, preserving the same resolution paths used by the battle UI.

The battle scene's camera `_process()` callback is disabled for the test because camera shake consumes global random values for presentation. This prevents visual randomness from perturbing the gameplay RNG sequence during determinism checks. Rendering rules and combat state are not changed.

The checker runs the greedy scenario twice with the same seed and compares:

- metrics
- checks
- observations
- policy identity
- initial state
- final state
- complete structured event sequence

A difference fails the baseline regression.

Observed integration results while stabilizing the harness:

- `greedy-damage-v1`: Ashvale victory, 12 player turns, 24 recorded decisions, 175 player-team HP lost
- `random-legal-v1`: Ashvale victory, 36 player turns, 70 recorded decisions, 438 player-team HP lost

These are integration proofs and baseline comparison points, not balance targets.

## Evidence

Each automated battle produces normal ProjectTactic AI evidence with `source: "self_play"`.

The artifact contains at minimum:

- `greedy.json`
- `random.json`
- `baseline-summary.json`
- AI producer report files

Example analysis entry point:

```bash
python tools/ai/producer.py analyze \
  --evidence .ai-reports/self-play-baselines/greedy.json \
             .ai-reports/self-play-baselines/random.json
```

## Best practice

Do not optimize the game around the greedy baseline's win rate. A simple aggressive policy is a measuring instrument, not the target player experience.

The useful questions are comparative, for example:

- Does a terrain-aware policy materially outperform greedy damage on maps that are supposed to reward positioning?
- Does a control policy find viable alternatives to raw damage?
- Does the same action dominate across most player states?
- Does one job or boon erase meaningful differences between policies?

## Pragmatic workaround

BattleManager currently owns both battle orchestration and several useful tactical helper methods. The decision adapter calls those existing helpers rather than duplicating combat formulas. The methods use underscore naming but are ordinary GDScript methods.

This is acceptable for the first development harness because it avoids editing the large BattleManager solely to expose instrumentation APIs. A future refactor should extract a formal read-only battle query interface when the action surface expands.

Godot 4.6.2 headless normal-scene runs can also emit an exact shutdown diagnostic of the form `ERROR: N resources still in use at exit (run with --verbose for details).` after the runner has passed every assertion and the Godot process itself returned zero. The Python harness permits only this exact diagnostic, only for a real-battle process that contains both the successful test sentinel and a `SELF_PLAY_RESULT` record. Nonzero exits, `SCRIPT ERROR:`, failed test sentinels, and every other `ERROR:` line remain fatal.

This exception is intentionally not used for project import, standalone policy tests, or AI producer commands.

## Risks and tech debt

- The first action surface excludes active abilities and items, so it cannot yet measure build expression accurately.
- The hardcoded Ashvale debug battle is only one scenario and cannot establish game balance.
- Random-legal can terminate by bounded stall rather than battle completion; that is valid evidence about the weakness of the control policy, not a production gameplay failure.
- Global gameplay RNG and presentation RNG are not fully separated in the game architecture. The harness disables BattleScene camera processing to protect the deterministic test, but the broader architectural separation should be improved later.
- BattleManager's synchronous turn transitions are now handled by the self-play controller, but they remain an orchestration detail that future battle refactors must preserve or explicitly change.
- The adapter currently calls BattleManager helper methods directly. That is intentionally lower risk than modifying the 90KB-plus manager during this phase, but it is technical debt.
- Godot's headless runner still reports shutdown-time retained resources in some successful real-battle processes. The harness exception is tightly scoped, but the retained resources should be identified later with a verbose engine-level cleanup investigation rather than broadening the exception.

## Next evolution

The next useful policies are:

1. terrain-seeking
2. defensive survival
3. status/control
4. objective-rush

Before adding a model, expand the decision surface to abilities and add a small scenario matrix with multiple maps, formations, jobs, and seeds. Then aggregate policy results into tactical-depth metrics such as decision diversity, action dominance, positional value, and win-rate deltas by strategy.

Only after those deterministic baselines exist should a reasoning model or search agent be asked to discover new tactics autonomously.

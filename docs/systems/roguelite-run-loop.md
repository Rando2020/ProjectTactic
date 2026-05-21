# Roguelite Run Loop

## Purpose

The roguelite run loop turns Vaelthar from a one-off tactics prototype into a replayable route-based tactics game. The first implementation is intentionally small: a fixed route, a few node types, and a 1-of-3 reward draft after nodes.

## Current Flow

```txt
Start Run
→ Choose route node
→ Resolve battle, shrine, or event
→ Pick 1 of 3 rewards
→ Choose next route node
→ Reach boss node
→ End run and bank Echo Shards
```

## Files

```txt
src/game/data/runNodes.js
src/game/data/runRewards.js
src/game/data/runModifiers.js
src/game/systems/run/createRun.js
src/game/systems/run/advanceRun.js
src/game/systems/run/applyDraftReward.js
src/game/screens/RunMapScreen.jsx
src/game/screens/RewardDraftScreen.jsx
src/game/GameShell.jsx
src/game/state/initialGameState.js
```

## Data Model

`currentRun` lives on game state and currently tracks:

| Field | Purpose |
|---|---|
| `id` | Unique run identifier |
| `seed` | Seed label for deterministic route work later |
| `status` | `active`, `reward`, or `complete` |
| `currentNodeId` | Selected node |
| `completedNodeIds` | Route progress |
| `availableNodeIds` | Nodes the player can choose next |
| `selectedRewardIds` | Drafted boons, relics, pacts, and resources |
| `pendingRewardNodeId` | Node that generated the current draft |
| `pendingRewardIds` | Current 1-of-3 reward choices |
| `activeModifierIds` | Route-level pressure and flavor modifiers |
| `echoShardsEarned` | Meta currency earned this run |

## Node Types

| Type | Current Behavior | Future Behavior |
|---|---|---|
| `battle` | Sends player to deployment and battle | Add node-specific encounter tuning |
| `elite` | Sends player to a harder route battle | Add elite enemies and stronger rewards |
| `shrine` | Resolves directly into reward draft | Add Guardian pact costs |
| `event` | Resolves directly into reward draft | Add tradeoff choices |
| `boss` | Sends player to capstone battle | Add boss phases and route completion summary |

## Rewards

The first reward draft includes:

| Reward | Type | Intent |
|---|---|---|
| Emberwake | Boon | Fire build seed |
| Stormthread | Boon | Thunder and wet-terrain build seed |
| Glassbound Edge | Relic | Armor-break build seed |
| Guardian Oath: First Flame | Pact | SURGE build seed |
| Echo Shard Cache | Resource | Meta progression currency |
| Void Bargain | Pact | Risk-reward build seed |

Most reward effects are currently tracked as selected run rewards. They do not yet fully modify battle calculations. This is intentional for the first PR so the route loop can land before deeper combat coupling.

## Known Placeholders

- Route is hand-authored, not procedural.
- Reward effects are mostly tracked, not fully consumed by battle systems.
- Shrine and event nodes resolve directly into reward drafts.
- Boss uses an existing battle map as a placeholder.
- Echo Shards are banked only when the run reaches a terminal node.
- Run failure handling is not implemented yet.

## Next Steps

1. Add a run results screen for victory, failure, and Echo Shard banking.
2. Make reward effects influence battle math, JP, terrain, SURGE, and enemy modifiers.
3. Add event choice screens with costs and consequences.
4. Add node-specific enemy overrides.
5. Add procedural route generation after the fixed route feels good.
6. Add validation for node IDs, reward IDs, modifier IDs, and mission IDs.

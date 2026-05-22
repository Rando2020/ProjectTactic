# Godot Roguelite Run Loop Handoff

## Current Direction

ProjectTactic is now Godot-first. React remains a read-only reference for older validated concepts. New run-loop work should land under `godot/` unless a task is explicitly scoped as documentation.

## Current Runtime Shape

The current Godot loop is:

```txt
HubScene
→ Start Descent
→ StageSelect / run node selection placeholder
→ Battle
→ Results
→ Hub
→ Spend meta-currencies
→ Start again with more power or heat
```

The goal is to evolve that into:

```txt
Hub
→ Start Run
→ Run Node Screen
→ Battle / Boon / Wanderer / Event / Boss
→ Reward / Result Resolution
→ Next Node
→ Run Victory or Defeat
→ Meta Progression
→ Hub
```

## Source of Truth

| Area | Source |
|---|---|
| Production engine | `godot/` |
| Run state | `godot/scripts/roguelite/RunManager.gd` plus `GameState.active_run` |
| Run generation | `godot/scripts/roguelike/RunState.gd` and current run/floor generation helpers |
| Meta currencies | `godot/scripts/roguelite/MetaProgression.gd` and `Currency.gd` |
| Battle orchestration | `godot/scripts/battle/BattleManager.gd` and `BattleScene.gd` |
| UI routing | `godot/scripts/ui/HubManager.gd`, `StageSelect.gd`, `ResultsScreen.gd` |
| Reference-only browser concepts | `src/` |

## Current Known Capabilities

The Godot side already has important roguelite foundations:

- Hub entry point.
- Stage select / run start path.
- Battle scene and battle manager.
- Results screen.
- Meta progression service.
- Run manager service.
- Run/floor state generation.
- Boon database.
- Elite affix data.
- Wanderer data.
- Secret skill data.
- Job progression data.
- Enemy intent work in battle manager.
- Some meta-currency reward flow.

## Main Gap

The project needs a true **Run Node Screen** that sits between the hub and battle.

That screen should not be a static stage select. It should read the active run, display the current floor/node, and route the player based on node type.

## Next Implementation Target

Create or replace the current stage selection behavior with a Godot run node UI.

Recommended files:

```txt
godot/scenes/RunNodeScreen.tscn
godot/scripts/ui/RunNodeScreen.gd
```

Optional adapter if existing StageSelect should be reused:

```txt
godot/scripts/ui/StageSelect.gd
```

## Run Node Screen Requirements

### Must Display

- Current run seed.
- Current floor.
- Total floors.
- Node type.
- Node title.
- Map/stage name for battle nodes.
- Active heat level.
- Run aether.
- Active boons.
- Preview reward or risk text.

### Must Route By Node Type

| Node Type | Route |
|---|---|
| `battle` | `Battle.tscn` |
| `elite-battle` or `elite_battle` | `Battle.tscn` with elite metadata |
| `boss` | `Battle.tscn` with boss metadata |
| `boon-pick` or `boon_pick` | Future `BoonChoice.tscn` |
| `wanderer` | Future `WandererScene.tscn` |
| `event` | Future `RunEventScene.tscn` or placeholder resolution |

### Must Not Do

- Generate floor plans in the scene.
- Define boon data in the scene.
- Define wanderer data in the scene.
- Decide permanent meta-currency amounts in the scene.
- Duplicate reward math already owned by services.

## First Pragmatic Version

Do not overbuild the first screen.

Version 1 should support:

1. Read current run from `/root/RunManager` and `/root/GameState`.
2. Get current node.
3. Display node summary.
4. Press `Enter Node`.
5. Route battle nodes into `Battle.tscn`.
6. Resolve non-battle nodes with placeholder behavior if their dedicated scene is not ready.
7. Return to hub if no active run exists.

## Boon Choice Follow-up

After the run node screen works, create:

```txt
godot/scenes/BoonChoice.tscn
godot/scripts/ui/BoonChoice.gd
```

Requirements:

- Ask `BoonDB` or `RunManager` for three boon options.
- Show name, rarity, Guardian/element, description, and effect summary.
- On selection, call the run service to store the boon.
- Complete the node.
- Return to Run Node Screen.

## Wanderer Follow-up

After Boon Choice works, create:

```txt
godot/scenes/WandererScene.tscn
godot/scripts/ui/WandererScene.gd
```

Requirements:

- Read wanderer data from the service/data layer.
- Display name, tone, offer, cost, and reward.
- Allow accept/decline.
- Store reward if accepted.
- Complete the node.
- Return to Run Node Screen.

## Battle Reward Integration Follow-up

Battle victory should eventually resolve through one clean flow:

```txt
Battle victory
→ GameState applies XP / JP / gold / item rewards
→ RunManager awards run aether / meta currency / elite or boss bonuses
→ ResultsScreen displays both tactical and roguelite rewards
→ Node completes
→ Return to Run Node Screen or Hub
```

Results UI should display rewards. It should not decide reward amounts.

## Permanent Upgrade Integration Follow-up

When player units spawn into battle, read permanent upgrades from `MetaProgression` and apply them before combat begins.

Start with:

- max HP
- physical
- magic

Do not implement every upgrade before the playable loop is stable.

## Recommended Build Order

1. `feature/godot-run-node-screen`
2. `feature/godot-boon-choice-screen`
3. `feature/godot-wanderer-screen`
4. `fix/godot-battle-reward-integration`
5. `feature/godot-permanent-upgrades-in-battle`
6. `feature/godot-elite-affix-integration`
7. `fix/godot-run-loop-validation`

## Codex Prompt For Next Branch

Use this prompt for the next implementation branch:

```txt
Create feature/godot-run-node-screen from main. Implement a Godot RunNodeScreen that reads the active run from RunManager/GameState, displays current floor/node/run stats/active boons, and routes battle nodes to Battle.tscn. Keep scene code thin. Do not generate floor plans in the scene. Use existing RunManager, GameState, RunState, and existing UI patterns from HubManager and StageSelect. Add or update docs if any route assumptions are introduced. Open a PR into main and do not merge.
```

## Risk

The biggest risk is maintaining two competing run architectures. Do not add new runtime run systems in React. Do not create a second Godot run manager. Extend the existing Godot services instead.

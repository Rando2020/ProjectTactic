# ProjectTactic Architecture

ProjectTactic is now a **Godot-first tactical RPG / roguelite prototype**.

The former React/Vite implementation remains in `src/` only as a read-only design reference. Do not add new runtime gameplay to React. The production game should live under `godot/`.

For Claude Code and other agents, read `CLAUDE.md` first. For concrete porting tasks, use `AI_TASK_PACKETS.md` and `docs/systems/js-to-godot-migration-backlog.md`.

## Core rule for Codex and future agents

Build scenes as thin presentation/orchestration layers. Put reusable gameplay rules in GDScript simulation services.

```txt
Scenes call services.
Services own rules.
Data tables live in DB/helper scripts.
Save and progression live in autoloads.
```

## Repository ownership

| Path | Status | Ownership |
|---|---|---|
| `godot/` | Primary target | Production game implementation |
| `godot/scenes/` | Active | Godot scene files and scene composition |
| `godot/scripts/battle/` | Active | Battle flow and tactical combat orchestration |
| `godot/scripts/grid/` | Active | Grid rendering, tile math, movement support |
| `godot/scripts/roguelite/` | Active | Run generation, boons, elite affixes, meta progression, job helpers |
| `godot/scripts/ui/` | Active | Godot UI controllers |
| `godot/scripts/systems/` | Active | Long-lived global systems such as save state |
| `src/` | Read-only | Historical React reference only |
| `docs/` | Active | Design, architecture, implementation handoff |

## Godot autoloads

Configured in `godot/project.godot`:

| Autoload | Path | Responsibility |
|---|---|---|
| `GameState` | `res://scripts/systems/GameState.gd` | Existing campaign/battle save data, JP, learned abilities, completed stages. |
| `MetaProgression` | `res://scripts/roguelite/MetaProgression.gd` | Persistent roguelite currencies, permanent upgrades, unlock flags, heat state. |
| `RunManager` | `res://scripts/roguelite/RunManager.gd` | Current run seed, floor plan, current node, active boons, run aether, run rewards. |
| `SaveSystem` | `res://scripts/state/SaveSystem.gd` | Current run persistence and run-related save data. |
| `AudioSettings` | `res://scripts/systems/AudioSettings.gd` | Existing audio settings. |
| `VFX` | `res://scripts/vfx/VFXManager.gd` | Existing visual effects manager. |

## Simulation services already handled

These files exist so scene code can call into them instead of rebuilding logic locally.

### `Currency.gd`

Stable lowercase kebab-case currency IDs and display labels.

Handled:

- `soul-shards`
- `obsidian`
- `glyphs`
- `boss-tokens`
- `run-aether`
- Guardian sigils via ids like `phoenix-sigils` and `titan-sigils`

Scene responsibility:

- Display names and counts.
- Pass cost dictionaries to `MetaProgression.spend()`.

Do not:

- Hard-code alternate currency IDs in UI.
- Create duplicate currency display helpers inside scenes.

### `MetaProgression.gd`

Persistent roguelite progression store.

Handled:

- Meta-currency totals.
- Permanent upgrades.
- Unlock flags.
- Heat unlock and selected heat state.
- Save/load to persistent user data.
- Stage reward calculation.

Scene responsibility:

- Read currency totals.
- Ask whether a purchase can be afforded.
- Call spend/add methods.
- Refresh UI after purchases.

Do not:

- Save meta-currencies from scene scripts directly.
- Recalculate boss token rewards inside Results UI.

### `RunManager.gd`

Current run lifecycle and run state.

Handled:

- Start run.
- Track current floor/node.
- Advance and complete nodes.
- Track active boons.
- Track run aether.
- Emit signals when the current node changes or boon options are ready.

Scene responsibility:

- Call `start_new_run()` from the hub.
- Query current node data for display.
- Route battle nodes to `Battle.tscn`.
- Route boon nodes to a future boon choice screen.
- Route wanderer nodes to a future wanderer screen.

Do not:

- Generate floor plans inside Stage Select.
- Hard-code floor/node sequencing inside UI.

### Run/floor generation services

The repository has current run-generation logic already landed on `main`. The DB-style helper services added in this architecture pass should be treated as callable data/reference layers for future scenes and adapters.

Handled:

- Seeded floor/run/node generation.
- Battle, elite battle, boss, boon pick, and wanderer nodes.
- Current node lookup.
- Node completion and advancement.

Scene responsibility:

- Render the plan or current node.
- Let the player choose/confirm available nodes once branching is added.

Do not:

- Put procedural floor rules into UI scenes.

### Boon services

Handled:

- Boon data.
- Guardian association.
- Rarity weights by floor.
- Boon option generation.

Scene responsibility:

- Display options.
- On selection, call the run service to store the boon.

Do not:

- Store boon definitions in the boon selection scene.

### Elite affix services

Handled:

- Elite tiers.
- Prefixes and suffixes.
- Weighted affix generation.

Scene responsibility:

- Ask enemy generation code for affixes.
- Display elite labels and tooltips.
- Pass affix metadata into battle units.

Do not:

- Hard-code elite behavior in a UI scene.

### Wanderer and secret skill services

Handled:

- Wanderer data.
- Floor-based wanderer pools.
- Random wanderer selection.
- Secret skill reward data.

Scene responsibility:

- Show dialogue.
- Present accept/decline/pay/challenge choices.
- Report outcome to the run service or future encounter resolver.

Do not:

- Put wanderer definitions directly in a scene script.

### Job progression services

Handled:

- JP thresholds.
- Base, advanced, and ascended job unlock requirements.
- Job unlock checks using character level, job levels, and unlock flags.

Scene responsibility:

- Display job trees.
- Call unlock checks.
- Show missing requirements.

Do not:

- Duplicate job requirement formulas in UI.

## Scene work Codex should build next

### 1. Run Node Screen

Replace the current static Stage Select behavior with a run-node screen.

Should do:

- Read current run node data from the run service.
- Show current floor, node type, map id, and reward preview.
- Route by node type:
  - `battle`, `elite-battle`, `boss` → `Battle.tscn`
  - `boon-pick` → future `BoonChoice.tscn`
  - `wanderer` → future `WandererScene.tscn`

Should not:

- Generate a new run plan.
- Own reward calculations.

### 2. Boon Choice Scene

Create `godot/scenes/BoonChoice.tscn` and `godot/scripts/ui/BoonChoice.gd`.

Should do:

- Read the current boon node from the run service.
- Display three boon options.
- On selection, store the boon on the active run.
- Advance the node and route to the next node screen.

Should not:

- Define boon data.

### 3. Wanderer Scene

Create `godot/scenes/WandererScene.tscn` and `godot/scripts/ui/WandererScene.gd`.

Should do:

- Display the current wanderer from the run service.
- Present condition and reward.
- Resolve placeholder choices for now.
- Advance the node.

Should not:

- Define wanderer data locally.

### 4. Battle Reward Integration

Update battle victory flow.

Should do:

- On victory, identify the current run node.
- Award normal battle rewards through existing `GameState.apply_victory()`.
- Award roguelite rewards through the run/meta progression services.
- Store a reward breakdown so `ResultsScreen.gd` can display both JP/gold and meta-currency.
- Call node completion after the player has a chance to see rewards.

Should not:

- Let `ResultsScreen.gd` decide reward amounts.

### 5. Apply Permanent Upgrades

Update player unit creation.

Should do:

- In `BattleScene.gd`, when making player units, read `/root/MetaProgression`.
- Apply `get_stat_bonus("max_hp")`, `get_stat_bonus("physical")`, and `get_stat_bonus("magic")` before assigning stats.

Should not:

- Store permanent stat bonuses on individual scene instances only.

### 6. Elite Enemy Integration

Build a clean enemy generation adapter.

Should do:

- Use the elite affix service for battle nodes with elite bonus.
- Apply HP multipliers and labels first.
- Add behavior hooks later.

Should not:

- Implement every elite behavior before the demo loop works.

## Build order recommendation

1. Keep the hub stable.
2. Add reward integration and permanent stat bonuses.
3. Add Run Node screen.
4. Add Boon Choice screen.
5. Add Wanderer screen.
6. Add enemy affix application.
7. Add randomized map/enemy placement.
8. Connect job unlock flags to actual job UI.

## React reference policy

React files under `src/` are reference only. Use them to understand older validated systems, but do not continue feature development there.

Acceptable:

- Reading React data files to port behavior.
- Preserving React files as documentation.
- Mentioning React references in docs.

Not acceptable:

- Adding new runtime systems to React.
- Deploying React as the main game.
- Treating React UI as source of truth over Godot services.

## Root cleanup policy

The repo root should not contain random copied Godot scene or script stubs. Godot files belong under `godot/`. Documentation belongs under `docs/`. React reference files belong under `src/`.

If a copied file appears at root by mistake, delete it in the next cleanup PR.

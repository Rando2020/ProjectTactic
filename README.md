# ProjectTactic

ProjectTactic is now a **Godot-first tactical RPG / roguelite prototype**.

The current direction is a darker, modern tactics game inspired by the readability and job progression depth of classic tactical RPGs, with roguelite structure inspired by run-based games like Hades and Slay the Spire. The main playable target is Godot. The older React/Vite prototype remains in `src/` as a read-only design reference and historical validation layer.

## Current Primary Target

```txt
godot/
└─ project.godot
   └─ run/main_scene = res://scenes/HubScene.tscn
```

Godot is the production path. New gameplay systems, scene work, UI flows, battle loop improvements, and roguelite features should be implemented in `godot/` unless explicitly scoped as documentation or reference work.

## React Status

`src/` is retained as a **read-only design reference**.

Do not:

- Add new game systems to React.
- Deploy the React prototype as the primary build.
- Treat React screens as the production game.
- Port scene behavior back into React.

Use React only to reference validated logic and content such as:

- Wanderers.
- Boons.
- Elite affixes.
- Floor/run generation.
- Job progression concepts.
- Older UI flow ideas.

## Running the Godot Prototype

1. Open Godot 4.x.
2. Import or open the project at:

```txt
godot/project.godot
```

3. Run the project.
4. The project should boot to:

```txt
res://scenes/HubScene.tscn
```

## Current Godot Loop

```txt
Hub
→ Start Descent
→ Stage Select / run node selection placeholder
→ Tactical Battle
→ Results
→ Hub
→ Spend meta-currencies
→ Start again at higher power or heat
```

## Current Godot Runtime Files

```txt
godot/project.godot
godot/scenes/HubScene.tscn
godot/scenes/StageSelect.tscn
godot/scenes/Battle.tscn
godot/scenes/ResultsScreen.tscn
godot/scenes/CharacterScreen.tscn
godot/scripts/ui/HubManager.gd
godot/scripts/ui/StageSelect.gd
godot/scripts/ui/ResultsScreen.gd
godot/scripts/battle/BattleScene.gd
godot/scripts/battle/BattleManager.gd
godot/scripts/grid/TacticalGrid.gd
godot/scripts/systems/GameState.gd
godot/scripts/roguelite/Currency.gd
godot/scripts/roguelite/MetaProgression.gd
godot/scripts/roguelite/RunManager.gd
godot/scripts/roguelite/FloorGenerator.gd
godot/scripts/roguelite/BoonDB.gd
godot/scripts/roguelite/EliteAffixDB.gd
godot/scripts/roguelite/WandererDB.gd
godot/scripts/roguelite/SecretSkillDB.gd
godot/scripts/roguelite/JobProgressionDB.gd
```

## Godot Simulation Services

The Godot port is organized around data and simulation services that scenes can call.

| Service | Purpose |
|---|---|
| `MetaProgression.gd` | Persistent currencies, hub purchases, heat unlocks, permanent upgrade tiers. |
| `RunManager.gd` | Current run state, run seed, floor plan, current node, active boons, stage rewards. |
| `FloorGenerator.gd` | Seeded run/floor/node generation. |
| `BoonDB.gd` | Boon definitions and reward option generation. |
| `EliteAffixDB.gd` | Elite tiers, prefixes, suffixes, and affix generation. |
| `WandererDB.gd` | Wanderer encounter definitions and floor-based selection. |
| `SecretSkillDB.gd` | Secret skill definitions taught by wanderers. |
| `JobProgressionDB.gd` | Job level thresholds and job unlock checks. |

## Scene Responsibilities

Scenes should present and orchestrate. They should not duplicate simulation logic.

| Scene / UI | Should do | Should not do |
|---|---|---|
| `HubScene.tscn` + `HubManager.gd` | Display currencies, call `MetaProgression`, start runs. | Recalculate run rewards or duplicate progression tables. |
| `StageSelect.tscn` | Show next battle/run node choices. | Own floor generation rules. |
| `Battle.tscn` + battle scripts | Resolve tactical combat and report victory/defeat. | Own meta-currency save rules. |
| `ResultsScreen.tscn` | Show battle rewards and route back to hub. | Decide permanent unlock rules. |
| Future Boon screen | Show boon options from `BoonDB` / `RunManager`. | Hard-code boon pools in UI. |
| Future Wanderer screen | Display `WandererDB` encounters and resolve choice input. | Store wanderer definitions locally in the scene. |

See `ARCHITECTURE.md` for the exact Codex handoff rules.

## Current Production Priorities

1. Finish Godot hub reward integration.
2. Apply permanent meta-upgrades to player unit spawn stats.
3. Replace Stage Select with a true run-node screen.
4. Wire boons into battle stats and tactical effects.
5. Wire elite affixes into enemy generation and battle behavior.
6. Add randomized stage generation and randomized enemy spawns.
7. Connect job unlock flags to the Godot job tree.
8. Keep React as read-only reference only.

## Legal and Creative Boundary

ProjectTactic can be inspired by classic tactics and modern roguelite design patterns, but it should not use copyrighted files, ripped assets, proprietary data, copied maps, copied class names, copied formulas, or traced UI from existing commercial games.

All ProjectTactic assets, maps, UI, writing, and code should be original or legally safe placeholders.

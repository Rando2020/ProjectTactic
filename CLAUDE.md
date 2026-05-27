# Claude Code Instructions

ProjectTactic is a **Godot-first game project**.

## Hard Rule

Do not build new gameplay, UI, systems, or runtime features in JavaScript, React, Vite, or `src/game/` unless the user explicitly asks for React reference work.

The playable game target is:

```txt
godot/
```

The React/JavaScript code is historical reference only:

```txt
src/
archive_react/
VaeltharChronicles.jsx
```

Use those files to understand intent, data shapes, old UI flows, or feature behavior. Then implement the real feature in GDScript and Godot scenes.

## Where To Build

| Work Type | Build Here |
|---|---|
| Battle flow, AI, combat intent | `godot/scripts/battle/` |
| Grid, tile visuals, terrain logic | `godot/scripts/grid/`, `godot/scripts/data/TileData.gd` |
| Godot UI screens | `godot/scripts/ui/`, `godot/scenes/` |
| Roguelite run map, boons, loot, wanderers | `godot/scripts/roguelike/`, `godot/scripts/roguelite/` |
| Save/meta progression | `godot/scripts/systems/`, `godot/scripts/state/` |
| Asset registry | `godot/scripts/data/AssetRegistry.gd` |
| Design docs and handoff notes | `docs/` |

## React Reference Policy

Allowed:

- Read React files.
- Compare React behavior against Godot behavior.
- Port React data/logic into Godot.
- Add docs that describe what still needs porting.

Not allowed unless explicitly requested:

- Adding new `.jsx`, `.js`, `.ts`, or `.tsx` gameplay features.
- Creating new React screens.
- Fixing React UI instead of Godot UI.
- Adding runtime dependencies for the old React prototype.

## Current JS-To-Godot Migration Priorities

1. Town node system: Sanctum, Armory, Tavern, Vault, Oracle.
2. Party composition screen: choose/swap active units before a run or at Tavern nodes.
3. Full Wanderer encounter screen: richer dialogue, conditions, payments, challenge outcomes.
4. Mystery event table: treasure, shrine, caravan, ambush, trap, curse site, mimic.
5. Options screen: audio/display controls from the title screen.
6. Dedicated loot-claim screen: polished post-battle equipment and reward flow.

## Validation

Before handing off Godot work, run:

```cmd
tools\check_godot_stability.cmd --skip-godot
```

The full checker may hit the known Godot headless signal 11 crash on this machine:

```cmd
tools\check_godot_stability.cmd
```

If the static pass succeeds and the full pass only reports the known headless crash, use the Godot editor reload/playtest as the final validator.

## Commit Scope

Keep commits scoped to the Godot feature being ported. Do not bundle unrelated React cleanup with Godot implementation work.

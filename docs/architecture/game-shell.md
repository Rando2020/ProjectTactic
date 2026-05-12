# Game Shell Architecture

Vaelthar is moving from a single-file battle prototype into a browser-first tactical RPG structure.

## Purpose

The game shell creates the first complete campaign loop:

1. Main Menu
2. World Map
3. Town Hub
4. Tactical Battle
5. Results Screen
6. Character Sheet
7. Job Tree
8. Save or Continue

This is the foundation for turning the combat prototype into a playable tactics RPG vertical slice.

## Source Files

```text
src/game/GameShell.jsx
src/game/screens/MainMenu.jsx
src/game/screens/WorldMapScreen.jsx
src/game/screens/TownScreen.jsx
src/game/screens/BattleScreen.jsx
src/game/screens/ResultsScreen.jsx
src/game/screens/CharacterSheetScreen.jsx
src/game/screens/JobTreeScreen.jsx
src/game/components/TacticalGrid.jsx
src/game/components/CommandMenu.jsx
src/game/components/DeploymentScreen.jsx
src/game/systems/objectives.js
src/game/systems/pathfinding.js
src/game/systems/deployment.js
src/game/state/initialGameState.js
src/game/state/progressionReducer.js
src/game/state/saveSystem.js
src/game/styles/gameShell.css
```

## Data Connections

The shell reads from the existing game data modules:

```text
src/game/data/maps.js
src/game/data/towns.js
src/game/data/units.js
src/game/data/terrain.js
src/game/data/progression.js
```

## Current Capabilities

- Boots to the new Game Shell tab by default.
- Keeps the previous Battle Prototype available as a separate tab.
- Shows unlocked missions from map data.
- Renders battle maps with pseudo-isometric CSS tiles, terrain, height, and unit tokens.
- Supports movement range using unit move, jump, terrain movement cost, blocked tiles, and occupied tiles.
- Supports command-driven battle actions: Move, Attack, Ability, Item, and Wait.
- Resolves `defeat_all` mission objectives from living enemy units.
- Enables Claim Victory only after the objective is complete.
- Applies XP, JP, gold, item, mission, and story flag rewards.
- Supports pre-battle deployment helpers with roster-constrained validation.
- Shows basic character sheets and job tree lock requirements.
- Saves and loads local game state through localStorage.

## Known Placeholders

- Movement range now exists, but path preview and final movement animation are not implemented yet.
- Enemy units use lightweight temporary stats.
- Attack damage is simple placeholder pressure, not final combat math.
- Ability targeting currently logs a placeholder action.
- Item use currently applies a placeholder Vitae Draught heal without consuming inventory.
- CT turn order, enemy AI, ability targeting, and damage preview are still pending.
- Visuals are CSS placeholders, not final pixel assets.

## Next Evolution

1. Add CT turn order and timeline UI.
2. Add path preview and movement animation.
3. Add damage preview and hit confirmation.
4. Add enemy AI intent preview.
5. Consume inventory items during battle.
6. Add real ability targeting by job and ability data.
7. Connect post-battle rewards to mission unlocks and town unlocks.
8. Add save slots and autosave checkpoints.

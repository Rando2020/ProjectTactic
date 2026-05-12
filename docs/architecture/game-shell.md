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
- Renders battle maps with terrain, height, units, and adjacency movement.
- Provides a debug battle completion path to test rewards.
- Applies XP, JP, gold, item, mission, and story flag rewards.
- Shows basic character sheets and job tree lock requirements.
- Saves and loads local game state through localStorage.

## Known Placeholders

- Tactical movement is currently adjacent-tile only.
- Enemy units use lightweight temporary stats.
- Battle completion is a debug button, not a real win condition yet.
- Attacks, CT turn order, enemy AI, ability targeting, and damage preview are still pending.
- Visuals are CSS placeholders, not final pixel assets.

## Next Evolution

1. Add movement range pathfinding.
2. Add command menu actions: Move, Attack, Ability, Item, Wait.
3. Add CT turn order and timeline UI.
4. Add damage preview and hit confirmation.
5. Add enemy AI intent preview.
6. Replace debug win with objective resolution.
7. Connect post-battle rewards to mission unlocks and town unlocks.
8. Add save slots and autosave checkpoints.

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
src/game/components/FacingPicker.jsx
src/game/systems/objectives.js
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
- Renders battle maps with terrain, height, units, and movement range.
- Supports command-driven battle actions: Move, Attack, Ability, Item, and Wait.
- Uses a CT timeline with a visible upcoming turn order.
- Supports movement range, enemy AI intent, ability targeting, damage forecast, hit confirmation, and final facing selection.
- Resolves `defeat_all` mission objectives from living enemy units.
- Enables Claim Victory only after the objective is complete.
- Applies XP, JP, gold, item, mission, and story flag rewards.
- Shows basic character sheets and job tree lock requirements.
- Saves and loads local game state through localStorage.

## Known Placeholders

- Enemy units use lightweight temporary stats.
- Item use currently applies a placeholder Vitae Draught heal without consuming inventory.
- Visuals are CSS placeholders, not final pixel assets.

## Next Evolution

1. Extract the player turn flow into a small battle phase/state helper.
2. Consume inventory items during battle.
3. Refine tactical feedback for terrain reactions, enemy intent, and action outcomes.
4. Connect post-battle rewards to mission unlocks and town unlocks.
5. Add save slots and autosave checkpoints.
6. Replace CSS placeholders with original tactical RPG art assets.

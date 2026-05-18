# Vaelthar: Eidolon Chronicles

Vaelthar is a browser-first tactical RPG prototype built with React and Vite. The goal is a unique tactics roguelite with readable grid combat, job progression, elemental terrain reactions, Guardian resonance, SURGE timing, and run-based reward drafting.

The browser prototype under `src/game/` is the primary production path. The Godot work under `godot/` is a secondary sandbox unless a task is explicitly Godot-focused.

## Run Locally

```bash
npm install
npm run dev
```

Open `http://localhost:5173`.

## Build

```bash
npm run build
npm run preview
```

Build output goes to `dist/`.

---

## Current Playable Flow

```txt
Main Menu
→ World Map
→ Town Hub
→ Deployment
→ Tactical Battle
→ Results Screen
→ Party / Jobs / Inventory / Codex / Summons / Quests
→ Save / Load
```

The battle loop now supports:

```txt
Select active unit
→ Move / Attack / Ability / Item / Wait
→ Preview range, target, terrain, and damage
→ Confirm or cancel
→ Resolve SURGE, damage, terrain reactions, status ticks, JP, and enemy turns
→ Claim victory
→ Apply progression and rewards
```

---

## Current Runtime Capabilities

### Campaign Shell

- Main menu, world map, town hub, deployment, battle, results, party, jobs, inventory, codex, summons, quests, inn, and story screens.
- Local browser save/load.
- Mission selection from the world map.
- Deployment screen before battle.
- Mission completion and results flow.

### Tactical Battle

- CT-style turn flow through `turnOrder.js`.
- Turn timeline UI.
- Movement range using Move, Jump, terrain cost, blocking, and occupied tiles.
- Damage forecast and attack confirmation.
- Ability picker.
- SURGE timing window.
- Enemy intent preview and basic enemy AI.
- Battle speed controls.
- Keyboard shortcuts for core commands.
- Combat popups for damage, healing, criticals, Temper damage, and Ether pressure.

### Progression and Resources

- HP, MP, Temper, and Ether.
- XP, character levels, JP, job levels, job unlocks, ascended jobs, and mastered jobs.
- Battle-earned JP now applies to roster progression after victory.
- Results screen shows base JP, action JP, clear bonus JP, and total JP by character.
- Vitae Draught consumes inventory in battle and disables Item when depleted.

### Terrain and Reactions

- Terrain data includes height, movement cost, tags, hazards, and reaction hooks.
- Elemental reactions can transform battlefield state.
- Terrain info and reaction warnings surface during battle.

### Assets and Art Direction

- Asset registry scaffolding exists.
- Prompt libraries exist for placeholder asset generation.
- Runtime visuals still use many CSS and symbol placeholders.
- Asset registry wiring is a future priority.

---

## Key Files

### Runtime

```txt
src/game/GameShell.jsx
src/game/screens/BattleScreen.jsx
src/game/screens/ResultsScreen.jsx
src/game/components/DeploymentScreen.jsx
src/game/components/TacticalGrid.jsx
src/game/components/CommandMenu.jsx
src/game/components/TurnTimeline.jsx
src/game/components/DamageForecast.jsx
src/game/components/AbilityPicker.jsx
src/game/components/TerrainInfo.jsx
src/game/components/UnitCard.jsx
src/game/components/SurgeWindow.jsx
src/game/state/initialGameState.js
src/game/state/progressionReducer.js
src/game/state/saveSystem.js
```

### Systems

```txt
src/game/systems/grid.js
src/game/systems/pathfinding.js
src/game/systems/targeting.js
src/game/systems/turnOrder.js
src/game/systems/combatResolver.js
src/game/systems/damageFormula.js
src/game/systems/aiController.js
src/game/systems/elementalSystem.js
src/game/systems/objectives.js
src/game/systems/deployment.js
```

### Data

```txt
src/game/data/maps.js
src/game/data/towns.js
src/game/data/units.js
src/game/data/enemies.js
src/game/data/abilities.js
src/game/data/terrain.js
src/game/data/progression.js
src/game/data/story.js
src/game/data/quests.js
src/game/data/missions.js
src/assets/assetRegistry.js
```

---

## Architecture Rules

| Path | Purpose |
|---|---|
| `src/game/data/` | Static content: jobs, units, enemies, maps, terrain, story, towns, missions |
| `src/game/systems/` | Pure gameplay logic: grid, pathfinding, combat, turn order, reactions, AI, objectives |
| `src/game/state/` | Initial state, save/load, reducers, campaign progression |
| `src/game/screens/` | Full screen flows |
| `src/game/components/` | Reusable UI and battle components |
| `src/assets/` | Browser placeholder and final assets |
| `godot/` | Secondary Godot sandbox |
| `docs/` | Architecture, design, lore, mechanics, production, prompts |

Do not add major new systems directly to the root prototype unless it is explicitly temporary.

---

## Current Priorities

### 1. Add the roguelite run loop

Target flow:

```txt
Start Run
→ Choose route node
→ Fight battle
→ Pick 1 of 3 rewards
→ Choose next node
→ Elite or boss
→ End run
→ Apply meta progression
```

Recommended files:

```txt
src/game/data/runNodes.js
src/game/data/runRewards.js
src/game/data/runModifiers.js
src/game/systems/run/createRun.js
src/game/systems/run/advanceRun.js
src/game/systems/run/applyDraftReward.js
src/game/screens/RunMapScreen.jsx
src/game/screens/RewardDraftScreen.jsx
docs/systems/roguelite-run-loop.md
```

### 2. Make rewards deployment-aware

Current mission rewards are roster-wide. Future reward logic should distinguish deployed units, participating units, benched units, and story-required units.

### 3. Improve item use

Current item support is self-use Vitae Draught only. Add item targeting, multiple item types, and item data definitions.

### 4. Add path preview and movement animation

Movement range works, but the player still needs readable path preview and animated movement.

### 5. Wire runtime assets

Use the asset registry to replace symbolic placeholders with generated placeholder portraits, unit sprites, tile overlays, icons, VFX, and UI panels.

### 6. Add validation and tests

Add validation for maps, units, enemies, abilities, terrain reactions, item IDs, reward payloads, asset registry paths, and save schema compatibility.

---

## Recommended Next Branches

```txt
feature/roguelite-run-loop
fix/deployment-aware-rewards
feature/battle-item-targeting
feature/path-preview-and-movement-animation
feature/runtime-asset-registry-wiring
fix/build-and-data-validation
```

The next best action is `feature/roguelite-run-loop`. The battle loop is now stable enough to build the run structure that makes the game feel distinct.

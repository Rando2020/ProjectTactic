# Vaelthar: Eidolon Chronicles

A browser-first tactical RPG prototype built in React + Vite.

Design influences: classic tactical RPG readability, character-job progression, elemental combo combat, Guardian summons, and a darker grounded fantasy tone. The project should stay browser-playable while the prototype evolves into clean data, systems, state, screens, and UI layers.

## Play It Locally

```bash
npm install
npm run dev
```

Open `http://localhost:5173`.

## Build for Deployment

```bash
npm run build
npm run preview
```

Build output goes to `/dist` and can be deployed as a static site.

---

## Current App Navigation

```txt
index.html
└─ src/main.jsx
   └─ src/App.jsx
      ├─ Game Shell           ← default vertical-slice shell
      ├─ Character Compendium ← character/job reference area
      └─ Battle Prototype     ← previous generated combat prototype
```

The previous root-level `VaeltharChronicles.jsx` remains available as the Battle Prototype. New campaign-facing work should move into `src/game/`.

---

## Current Vertical Slice Loop

The repo now includes the first campaign shell:

```txt
Main Menu
→ World Map
→ Town Hub
→ Tactical Battle
→ Results Screen
→ Character Sheets
→ Job Tree
→ Save / Load
```

The battle screen now supports a first playable command loop:

```txt
Select player unit
→ Choose Move / Attack / Ability / Item / Wait
→ Preview and confirm action
→ Choose final facing
→ Defeat all enemies
→ Claim Victory
→ Apply rewards
```

## Key Runtime Files

```txt
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

## Data Modules

```txt
src/game/data/maps.js
src/game/data/towns.js
src/game/data/units.js
src/game/data/terrain.js
src/game/data/progression.js
src/game/data/story.js
src/game/data/quests.js
src/game/data/missions.js
src/game/data/loadingTips.js
```

## Documentation

```txt
docs/architecture/game-shell.md
docs/design/art-direction.md
docs/design/tile-manifest.md
docs/design/sprite-manifest.md
```

---

## Repository Pathways

```txt
ProjectTactic/
├─ README.md
├─ ARCHITECTURE.md
├─ ASSET_PIPELINE.md
├─ index.html
├─ package.json
├─ vite.config.js
├─ src/
│  ├─ main.jsx
│  ├─ App.jsx
│  └─ game/
│     ├─ GameShell.jsx
│     ├─ VaeltharChronicles.jsx
│     ├─ components/
│     ├─ data/
│     ├─ screens/
│     ├─ state/
│     ├─ styles/
│     └─ systems/
├─ docs/
│  ├─ architecture/
│  ├─ design/
│  ├─ lore/
│  ├─ mechanics/
│  ├─ characters/
│  └─ production/
├─ prompts/
│  ├─ midjourney/
│  └─ suno/
└─ assets/
   ├─ concept/
   ├─ placeholders/
   ├─ characters/
   ├─ environments/
   ├─ ui/
   ├─ audio/
   └─ music/
```

## Architecture Rules

| Path | Purpose |
|---|---|
| `src/game/data/` | Static game content: jobs, units, enemies, maps, terrain, story, towns, missions |
| `src/game/systems/` | Pure gameplay logic: grid math, combat math, timing, status, combo, AI, progression, objectives |
| `src/game/state/` | Initial state, save/load, reducers, campaign progression |
| `src/game/screens/` | Full screen flows: menu, world, town, battle, results, character, jobs |
| `src/game/components/` | Reusable React UI and battle components |
| `docs/` | Architecture, production, lore, mechanics, QA, roadmap, art direction |
| `prompts/` | AI prompt recipes for visual/audio generation |
| `assets/` | Placeholder and final game assets |

Do not add major new systems directly to the root prototype unless it is explicitly a temporary spike.

---

## Game Systems Currently Represented

### SURGE / DEFLECT Timing

- **SURGE**: timed offensive input for bonus damage.
- **DEFLECT**: timed defensive input to reduce incoming damage.
- Each element has its own rhythm profile.

### Temper / Ether Armor

- **Temper**: physical defense layer.
- **Ether**: magical defense layer.
- Armor affects status pressure and damage breakpoints.

### Tactical Grid MVP

- Battle maps render from `BATTLE_MAPS`.
- Terrain definitions come from `terrain.js`.
- Units spawn from map data.
- Movement range uses terrain cost, unit move, occupied tiles, and jump limits.
- Height and terrain are visible on the board.
- Move and Attack commands highlight valid tactical selections.

### Command Menu MVP

Current commands:

- **Move**: reposition selected player unit within movement range.
- **Attack**: target enemies in weapon range with damage, hit, crit, armor, and facing preview.
- **Ability**: use job ability data for target selection and elemental reactions.
- **Item**: placeholder Vitae Draught heal, then choose final facing.
- **Wait**: hold position, choose final facing, and end the unit's CT turn.

### Objective Resolution MVP

- `defeat_all` objectives resolve when all enemy units reach `0 HP`.
- `Claim Victory` is disabled until the objective is complete.
- Completed missions apply XP, JP, gold, items, mission flags, and story flags.

### Elemental Surface Reactions

Examples:

- Wet + Ice = Freeze
- Wet + Thunder = Electrify
- Frozen + Thunder = Shatter
- Burning + Water = Extinguish
- Cursed + Holy = Holy Purge
- Blessed + Dark = Null Corrupt

### Job and Character Progression

The repo tracks character levels, XP, JP, job levels, ascended jobs, unlock requirements, and character armor values.

### Guardians

The combat prototype includes 32 Guardians across 8 elements and 4 tiers, including corrupted Guardian resonance windows.

---

## Current Production Priorities

1. Keep the browser prototype running.
2. Stabilize the Game Shell as the default production path.
3. Extract the growing battle screen into smaller phase, action, and presentation modules.
4. Improve facing feedback on the grid and forecast panel.
5. Consume inventory items during battle actions.
6. Connect mission rewards to new mission and town unlocks.
7. Add an asset registry mapping terrain, jobs, units, and enemies to placeholder art.
8. Bring the Godot implementation closer to browser parity.

See `docs/architecture/game-shell.md`, `docs/design/art-direction.md`, `docs/design/tile-manifest.md`, and `docs/design/sprite-manifest.md` for implementation direction.

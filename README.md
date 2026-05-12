# Vaelthar: Eidolon Chronicles

A browser-first tactical RPG prototype built in React + Vite.

Design influences: classic tactical RPGs, character-job progression, elemental combo combat, Guardian summons, and a darker fantasy tone. This repo should stay browser-playable while the prototype is gradually refactored into clean data, systems, and UI layers.

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

## Current Boot Path

```txt
index.html
└─ src/main.jsx
   └─ src/App.jsx
      └─ src/game/VaeltharChronicles.jsx
         └─ ../../VaeltharChronicles.jsx temporary prototype bridge
```

The root `VaeltharChronicles.jsx` is the current generated prototype. It should be treated as temporary until systems are extracted into `/src/game`.

---

## Repository Pathways

```txt
ProjectTactic/
├─ README.md
├─ ARCHITECTURE.md
├─ ASSET_PIPELINE.md
├─ .gitignore
├─ .gitattributes
├─ index.html
├─ package.json
├─ vite.config.js
├─ src/
│  ├─ main.jsx
│  ├─ App.jsx
│  └─ game/
│     ├─ VaeltharChronicles.jsx
│     ├─ data/
│     ├─ systems/
│     └─ components/
├─ docs/
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
| `src/game/data/` | Static game content: elements, statuses, jobs, enemies, items, maps, story data |
| `src/game/systems/` | Pure gameplay logic: combat math, timing, status, combo, progression, AI |
| `src/game/components/` | React rendering: battle panels, HUD, skill menu, prompts, logs |
| `docs/` | Design, production, lore, mechanics, QA, roadmap |
| `prompts/` | AI prompt recipes for visual/audio generation |
| `assets/` | Placeholder and final game assets |

Do not add major new systems directly to the root prototype unless it is a temporary spike.

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

### Elemental Surface Reactions

Examples:

- Wet + Ice = Freeze
- Wet + Thunder = Electrify
- Frozen + Thunder = Shatter
- Burning + Water = Extinguish
- Cursed + Holy = Holy Purge
- Blessed + Dark = Null Corrupt

### Job and Character Progression

The prototype tracks character levels, JP, job levels, ascended jobs, unlock requirements, and character armor values.

### Guardians

The prototype includes 32 Guardians across 8 elements and 4 tiers, including corrupted Guardian resonance windows.

---

## Current Production Priorities

1. Keep the browser prototype running.
2. Extract constants into `src/game/data`.
3. Extract combat/status/combo logic into `src/game/systems`.
4. Extract UI regions into `src/game/components`.
5. Add tactical grid movement and map data.
6. Add story/town data.
7. Add save/load.
8. Add deployment workflow.

See `ARCHITECTURE.md`, `ASSET_PIPELINE.md`, and `docs/production/roadmap.md` for the working plan.

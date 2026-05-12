# ProjectTactic Architecture

ProjectTactic currently uses a browser-first Vite + React prototype. The immediate goal is to keep the game playable while gradually extracting the generated one-file prototype into durable data, systems, and UI layers.

## Current boot path

```txt
index.html
└─ src/main.jsx
   └─ src/App.jsx
      └─ src/game/VaeltharChronicles.jsx
         └─ ../../VaeltharChronicles.jsx temporary prototype bridge
```

## Target structure

```txt
src/
├─ main.jsx
├─ App.jsx
└─ game/
   ├─ VaeltharChronicles.jsx
   ├─ data/
   ├─ systems/
   └─ components/
```

## Layer rules

| Layer | Purpose | Should contain | Should avoid |
|---|---|---|---|
| `data/` | Static game content | elements, jobs, enemies, items, guardians | React state, DOM, mutation |
| `systems/` | Pure gameplay logic | damage, status, combo, progression, AI | JSX, CSS, local UI state |
| `components/` | React rendering | panels, HUD, buttons, logs, prompts | damage math, job unlock math |
| root prototype | Temporary bridge | current generated game file | long-term feature development |

## Migration strategy

1. Keep the current prototype playable.
2. Extract static tables first into `src/game/data`.
3. Extract pure logic second into `src/game/systems`.
4. Extract visual sections last into `src/game/components`.
5. Remove the root-level bridge only after the game imports cleanly from `/src/game`.

## Non-negotiables

- Do not add new major systems directly into the root `VaeltharChronicles.jsx` unless it is a throwaway test.
- Any new mechanic should have a matching note in `docs/mechanics`.
- Any generated art/audio should have a matching prompt in `prompts`.
- Large assets should use Git LFS and go under `assets`, not `src`.

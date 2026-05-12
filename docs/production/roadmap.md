# Roadmap

## Phase 0 - Stabilize the browser prototype

- Align Vite file paths.
- Keep the existing generated prototype playable.
- Add project pathways for code, docs, prompts, and assets.
- Add Git hygiene and Git LFS rules.

## Phase 1 - Extract the one-file prototype

- Move static constants into `src/game/data`.
- Move combat math into `src/game/systems`.
- Move UI sections into `src/game/components`.
- Add simple smoke tests or build checks.

## Phase 2 - Tactical RPG foundation

- Add tactical grid movement.
- Add unit placement and map data.
- Add turn order timeline.
- Add target preview and damage preview.
- Add enemy AI intent preview.

## Phase 3 - Progression and content

- Add job level progression.
- Add ascended class unlocks.
- Add town data and shops.
- Add story chapter data.
- Add save/load.

## Phase 4 - Player-facing polish

- Add loading screen.
- Add settings menu.
- Add accessibility options.
- Add controller/keyboard mapping.
- Add deployment workflow.

## Current priority

Make the current browser version run reliably, then extract data and systems before adding major new features.

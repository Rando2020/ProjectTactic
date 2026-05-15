# Asset Production Pipeline

This pipeline explains how ProjectTactic should move from text prompts to usable game assets without losing organization or legal safety.

## Goals

- Generate original placeholder assets quickly.
- Keep assets legally safe and distinct from any copyrighted tactical RPG.
- Make the browser prototype playable before chasing final art polish.
- Keep React/Vite and Godot asset organization compatible.
- Track each asset from prompt to generated file to in-game registry.

## Step 1: Generate first-pass images

Start with the prompt files in this folder.

Recommended generation order:

1. Terrain tiles
2. Tile highlights and HUD chrome
3. Player unit idle poses
4. Enemy idle poses
5. Attack poses and VFX
6. Portrait crops
7. Guardian illustrations

Terrain and UI should come first because they unblock playable battle readability.

## Step 2: Normalize outputs

Each generated image should be cleaned into predictable sizes before importing.

Recommended baseline sizes:

| Asset type | Size |
|---|---:|
| Terrain tile | 64x64 |
| Isometric tile | 96x64 |
| Unit sprite frame | 128x128 |
| Portrait | 256x256 |
| UI icon | 64x64 |
| VFX frame | 128x128 |
| Guardian illustration | 1024x1024 |

Pragmatic workaround: use whatever the generator returns at first, but immediately crop and rename before adding to the repo.

## Step 3: Store assets in stable folders

Use these folders for the browser prototype:

```txt
src/assets/tiles/
src/assets/characters/
src/assets/ui/
src/assets/vfx/
src/assets/icons/
```

Use these folders for the Godot demo:

```txt
godot/assets/tiles/
godot/assets/characters/
godot/assets/ui/
godot/assets/vfx/
godot/assets/icons/
```

Do not scatter generated assets across random download folders or root-level directories.

## Step 4: Create an asset registry

After assets exist, add a small registry so game systems reference IDs instead of file paths.

Recommended browser registry:

```txt
src/assets/assetRegistry.js
```

Recommended Godot registry:

```txt
godot/scripts/data/AssetRegistry.gd
```

The registry should map stable gameplay IDs to asset paths.

Example:

```js
export const assetRegistry = {
  tiles: {
    grass: '/src/assets/tiles/grass-tile-placeholder.png',
    stoneRoad: '/src/assets/tiles/stone-road-tile-placeholder.png'
  },
  units: {
    zane: {
      idle: '/src/assets/characters/zane-idle-placeholder.png',
      portrait: '/src/assets/characters/zane-portrait-placeholder.png'
    }
  }
}
```

## Step 5: Wire assets into gameplay

The first integration targets should be:

1. Tactical grid terrain tiles
2. Unit idle sprites
3. Tile highlight overlays
4. Command button icons
5. Turn order portraits
6. Damage number floats
7. VFX overlays

## Step 6: Review art consistency

Each asset batch should be reviewed for:

- Isometric readability
- Color palette cohesion
- Silhouette clarity
- UI contrast
- Legal originality
- File naming consistency
- Performance cost in browser

## Known placeholders

The current prompt library is meant to create first-pass assets, not final production art. The prompts may need tuning once a final art bible is created.

## Risk

The biggest risk is generating attractive images that are not usable in-game. Prioritize clean cropping, consistent scale, and transparent backgrounds over painterly detail.

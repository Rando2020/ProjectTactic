# Demo Terrain Pack

This pass creates the first cohesive battlefield asset batch for ProjectTactic's Godot demo. The goal is not final art. The goal is a consistent, readable terrain layer that supports screenshots, camera tuning, movement readability, elevation tests, and roguelite combat staging.

## Status

This branch adds a generator script that produces legally safe placeholder PNG files under `godot/assets/tiles/`, `godot/assets/props/`, and `godot/assets/overlays/` using the locked demo art direction from `docs/prompts/demo-asset-generation.md`.

The generated files are intentionally simple. They establish file paths, shape language, and color families so scenes and registry IDs can stabilize before higher-fidelity art is imported.

## Generate the terrain pack locally

From the repo root:

```bash
python tools/generate_demo_terrain_pack.py
```

The script requires Pillow:

```bash
pip install pillow
```

## Files generated

### Terrain tiles

```txt
godot/assets/tiles/grass-tile.png
godot/assets/tiles/dirt-tile.png
godot/assets/tiles/road-tile.png
godot/assets/tiles/stone-tile.png
godot/assets/tiles/wall-tile.png
godot/assets/tiles/shallow-water-tile.png
godot/assets/tiles/shrine-tile.png
godot/assets/tiles/high-ground-tile.png
godot/assets/tiles/height-edge-grass.png
godot/assets/tiles/height-edge-stone.png
godot/assets/tiles/brush-tile.png
godot/assets/tiles/grass-flowers-tile.png
godot/assets/tiles/burning-tile.png
godot/assets/tiles/frozen-tile.png
godot/assets/tiles/cracked-stone-tile.png
godot/assets/tiles/void-corruption-tile.png
godot/assets/tiles/elite-spawn-tile.png
godot/assets/tiles/boss-arena-tile.png
godot/assets/tiles/wet-overlay.png
godot/assets/tiles/electrified-overlay.png
```

### Props

```txt
godot/assets/props/leafy-bush.png
godot/assets/props/ruin-block.png
godot/assets/props/mossy-rock.png
godot/assets/props/tree-stump.png
godot/assets/props/broken-banner.png
godot/assets/props/ash-pillar.png
```

### Overlays

```txt
godot/assets/overlays/elite-overlay-marked.png
godot/assets/overlays/elite-overlay-champion.png
```

## Acceptance checks

After generating assets and opening Godot:

1. Godot imports the new PNGs without errors.
2. `grass`, `road`, `stone`, `water`, `wall`, and `high_ground` all resolve through `AssetRegistry.gd`.
3. `Ashvale Road` and procedural maps render with no missing terrain textures.
4. Height-edge assets are visually distinguishable from flat terrain.
5. Hazard tiles read clearly at battle camera zoom.
6. Elite and boss tiles are visually distinct but not noisy.

## Follow-up task

After this branch lands, the next asset pass should be `feature/demo-unit-pack`, covering the four heroes, core enemies, and first boss as isometric billboard sprites.

# Terrain v2: opt-in art battlefield

Six separate runtime RGBA PNGs live in `godot/assets/tiles/terrain_v2/`:
`grass`, `dirt`, `stone`, `cracked_stone`, `shallow_water`, `scorched`.
Each is exactly 96 x 48, centered, with a fully opaque diamond and transparent
exterior. Height faces remain procedural. No existing art file was overwritten.

## Open the lab

Choose **Terrain Lab** on the title screen, or run `scenes/TerrainArtLab.tscn`
in Godot with F6. This is an interactive visual test battlefield, not a combat
encounter. It contains 64 tiles, six material regions, a height step, tile
selection, existing character sprites and 1x/2x zoom. It never writes a save,
starts a run, awards rewards or changes terrain movement rules.

The kit uses imported Texture2D resources. `TacticalGrid.terrain_textures` is an
optional override; all existing maps keep their original art by default.

Three `review_*.png` files are byte-identical copies of existing Zane/Mira/Kael
sprites. Their original import descriptors contain `valid=false`; sibling
review copies provide working imported textures without changing the originals.
The lab shows their base 80px player size, without stat-dependent Unit scaling.

## Art pipeline and generation prompts

Built-in image generation was used, one call per material, with the approved
six-tile design sheet as the style reference. Shared brief:

> One standalone flat isometric top-face tile, consistent 2:1 diamond, straight
> edges, no sides, thickness, cast shadows, objects, UI or text. Hand-painted
> fantasy tactics style; quiet broad forms readable at 96 x 48. Similar tone at
> center and edges, diffuse lighting, transparent exterior, no baked checkerboard.

Material prompts: muted meadow grass with broad tufts; compact warm dirt with
few pebbles; weathered cool stone paving; cracked stone with sparse moss; muted
teal shallow water with soft ripples; charcoal earth with restrained ember seams.

The generator returned RGB source images with baked checkerboards, despite the
transparency request. These are NOT the runtime assets. The offline Godot
packager samples an inspected inset of each diamond (excluding background and
rims), downsamples and assigns an exact pixel-center diamond alpha mask. This
is deterministic asset preparation, not runtime per-frame image processing.
Generated originals are preserved separately; runtime PNGs are committed in Git.

`tests/prepare_terrain_tiles.gd` takes source and destination PNG paths. Its
inset is specific to the inspected source composition, not a general background
remover. Do not apply it blindly to new art. No source image is overwritten.

## Tests and visual review

Run `python tools/check_terrain_art.py --godot /path/to/godot --proof` on Linux/WSL.
It isolates user data and rejects engine errors even if Godot exits zero.

- Imported texture dimensions and exact alpha mask for all six tiles.
- Four-tile adjacency: every interior pixel covered exactly once, no gaps or
  overlapping opaque pixels. Shared masks make this true for mixed materials too.
- Lab loads all six materials and actual unit textures, selects a height tile,
  and leaves the complete campaign/run snapshot unchanged.
- `terrain-v2-proof.png`: native-size CPU pixel composition of repeated 3x3
  regions with existing unit art. This is a visual proof, not a live screenshot.

Visual assessment: character silhouettes remain readable at native size;
Kael has lower contrast against scorched earth. Geometric seams are eliminated,
but repeated stone patterns and deliberate material boundaries remain visible.
No transition/autotile set or performance improvement is claimed.

Browser live rendering, filter behavior at fractional zoom, and moving combat
units require manual QA on a compatible WebGL2/secure browser. The known cloud
browser limitation is unchanged. Do not treat a successful export as visual QA.

## Next prompt

Review Terrain Lab at 1x/2x in Godot and a compatible browser. Check material
transitions, height faces, click alignment, movement overlays and unit contrast.
If this kit is approved, integrate only the grass/dirt/stone subset into one
real battle and profile before/after. Preserve fallback assets and do not merge.

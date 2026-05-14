# Isometric Tile Art Spec

The Godot battle grid now renders tiles as isometric blocks instead of top-down squares.

## Runtime Shape

Current projection values live in `godot/scripts/grid/TacticalGrid.gd`:

- tile top diamond: `96 x 48`
- side thickness: `16`
- height step: `14`
- default origin: `(320, 64)`

Each generated/runtime tile has three visible surfaces:

- top diamond
- left/front face
- right/front face

This lets us replace the temporary polygon colors with generated tile art that has the same three-contact-point read.

## Tile Art Target

For future PNG tile assets, use one complete isometric block per tile:

- canvas: `96 x 64` minimum
- top diamond: `96 x 48`
- side faces: extend about `16 px` below the top diamond
- transparent background
- visual foot/contact point at the center of the top diamond

Raised terrain should still be one tile asset per terrain type. The runtime offsets the whole tile upward using the logical `height` value, so the art itself should not include stacked vertical height unless we intentionally create cliff/wall variants.

## Runtime Integration Plan

The current renderer uses polygons as placeholders:

- top face: `_tile_top_polys`
- side faces: generated from terrain color
- highlights: diamond overlays
- units: placed with `_grid_to_local`
- clicks: resolved with `_local_to_grid`

When tile PNGs are ready, add a terrain art lookup to `TacticalGrid.gd` and draw a `Sprite2D` at `_grid_to_local(pos)` with the same depth sort. Keep the polygon fallback for missing art.

# Forgotten Field second art pass

This stacked change completes the manifest-defined Forgotten Field environment set without adding new runtime IDs or scene-specific asset paths. It is based on the first art pass and preserves every legacy and procedural fallback.

## Accepted assets

- Brush and memory-shrine terrain tiles on 96 x 64 transparent canvases, preserving the 96 x 48 top footprint.
- Leafy bush, mossy rock, tree stump, and ruin block props on 96 x 96 transparent canvases with compact silhouettes.
- The blocked tactical overlay on a 96 x 48 transparent canvas with a center-clear gray cross-hatched perimeter.

Ashvale already contains both terrain IDs and all four prop IDs. Adding the files at their existing manifest paths makes the playable battle consume them without map or scene changes.

## Rejected candidates

- The first brush candidate was too dense and tall for unit readability.
- The first shrine candidate read as a raised square platform rather than a walkable 96 x 48 tile.
- The first leafy bush obscured too much of a unit silhouette.
- The first ruin block read as an upright wall or monument.

Each rejected candidate was replaced with a lower-profile version before integration.

## Validation

- `tools/validate_first_art_pass.py` now validates all eight terrain tiles, four props, five overlays, and two unit indicators.
- `godot/tests/test_asset_manifest.gd` now checks preferred and fallback candidates for the completed environment set.
- The Web workflow exports both the normal game and a temporary direct-Ashvale QA build, then captures two browser frames after Godot's loading overlay is hidden.
- Visual review covers prop-to-unit scale, tile adjacency, shrine and brush distinction, blocked-state alignment, and browser transfer cost.

## Risks and next batch

- The stump and mossy rock are intentionally the largest props and should not be placed on critical unit spawn tiles.
- The blocked overlay is pattern-led and may need a brighter outer rim during accessibility testing on pale stone.
- The shrine is brighter than ordinary stone by design, but should be rechecked if a snow or pale-stone environment is introduced.
- The next recommended batch is the first character replacement pair: Vanguard and Hollow Lancer idle poses, with the existing procedural and legacy unit fallbacks retained.

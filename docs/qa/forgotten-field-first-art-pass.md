# Forgotten Field first art pass

This stacked change supplies the smallest visually complete generated-art batch for the existing Ashvale battle. It consumes the asset-manifest contract introduced by PR #63 and leaves all procedural and legacy-path fallbacks intact.

## Accepted assets

- Six transparent environment tiles: grass, flowering grass, road, stone, high ground, and shallow water.
- Four transparent tactical overlays: selected, move, attack, and ability.
- Two optional unit indicators: player and enemy. Both retain distinct silhouettes when reduced to the runtime size of 18 px.
- All tile art uses a 96 px wide canvas. Terrain canvases are 96 x 64 to include the manifest's 16 px side depth while preserving the 96 x 48 battlefield top footprint. Overlay canvases are exactly 96 x 48.

## Rejected or deferred

- The first high-ground generation was rejected because its pillars and arena-like ornamentation did not tile cleanly. The accepted replacement is a simple raised stone platform.
- Brush, shrine, props, blocked-state overlay, and all character/VFX packs remain deferred. Their manifest paths continue to resolve to existing fallbacks where defined.

## Validation

- `python tools/validate_first_art_pass.py` checks manifest paths, exact canvases, useful transparency, overlay center clarity, 18 px indicator silhouettes, and player/enemy distinction.
- `godot --headless --path godot --script res://tests/test_asset_manifest.gd` verifies preferred-path loading and an intentionally missing preferred file falling through to a valid legacy texture.
- The Godot validation workflow imports resources, parses production scripts, runs the asset contract checks, and exports the Web preset.
- The same workflow makes a temporary direct-battle QA export without changing the committed main scene, serves it locally, waits through Chrome DevTools until Godot's loading overlay is hidden, and captures the playable Ashvale battle at 1920 x 1080 with device scale factor 1. The two PNGs are uploaded as the `forgotten-field-browser-captures` workflow artifact.

## Replacement workflow

1. Regenerate one asset from the matching prompt pack under `prompts/assets/`.
2. Normalize it with `tools/normalize_game_asset.py` to the exact canvas named in `godot/data/asset_manifest.json`.
3. Replace only that PNG. Do not change the stable manifest path unless the contract is versioned.
4. Run the Python art validator, the Godot manifest test, the headless script validator, and the Web export.
5. Review the two fresh CI browser captures at normal 1920 x 1080 viewport scale.

## Risks and follow-ups

- Generated textures can expose seams when identical tiles meet. The first pass favors low-contrast edges, but a later authored transition pass should add directional road, water-edge, and elevation variants.
- Overlays are intentionally thin and center-clear. Color-vision and low-quality browser scaling checks should continue as more terrain palettes are added.
- The optional indicators pass automated 18 px silhouette checks, but should be rechecked against final character sprites before character art replaces the current units.
- Godot 4.6 rejected the base branch's `String.truncate_to_word_length()` call during clean Web validation. This branch replaces it with a local 40-character word-boundary helper so the intended boon-card text remains unchanged in spirit and the clean export can compile.
- The existing combat-formula fixture expects 46 projected temper damage while the current runtime returns 45. This pre-existing gameplay-test mismatch is intentionally not changed here.
- Several pre-existing Git LFS object IDs return 404 from the repository's LFS server. CI therefore retains its existing pointer-file checkout behavior; restoring those legacy audio and image objects is a separate repository-maintenance task.
- The next recommended batch is directional road and shallow-water edge variants, followed by brush, shrine, and four Forgotten Field props.

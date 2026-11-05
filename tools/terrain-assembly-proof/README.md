# Terrain assembly diagnostic

Standalone Godot 4.6.3 review project. Does not load or alter the game. Candidate art remains unapproved. Proposed registration metadata is intentionally local to this proof, not a replacement for the source manifest.

## Run

- `godot --headless --path tools/terrain-assembly-proof --import`
- `godot --headless --path tools/terrain-assembly-proof -- --self-test`
- `godot --path tools/terrain-assembly-proof`
- Display-backed capture: `xvfb-run -a godot --path tools/terrain-assembly-proof -- --capture-dir=/absolute/output`

Headless tests check projection and alpha-aware vs rectangular occlusion. They do not prove visual compatibility. Capture explicitly fails when run headless.

## Cases

1. Existing low wall, new corner and broken end at 80px visible height.
2. Shared source scale 0.18. This does not imply matched stone dimensions.
3. A one-point corner/end join attempt. The right corner base endpoint and left broken-end base endpoint are estimated from original source pixels. End caps, thickness, elevation and axis direction still require review. This is not a modular kit acceptance.
4. Candidate corner footprint proposal with front/back 46px diagnostic silhouettes and loose decorative scatter. Coral cells are a gameplay footprint hypothesis, not collision.
5. Transparent-canvas and solid-stone head probes reproduce false positives from rectangle-only fading. Alpha probe uses source alpha >= 0.5, matching Blooming's cutoff. This is a diagnostic proposal, not a live occlusion patch. Both sampled points are asserted to match the actual 46px silhouette tips, and both actors are behind the wall by depth. The existing game uses a nominal -32px head offset; this fixture uses its own exact silhouette tip. A second capture applies 0.30 alpha after detecting the opaque behind-wall head. Single head probes are not complete body visibility tests.

## Known numeric findings

Existing Blooming wall: 705x438 atlas region displayed at 80px height => 128.77px width. Corner at 80px visible height => 161.30px width. Broken end at 80px visible height => 104.26px width. Equal visible height therefore does not standardize segment spans or capstone scale.

At shared 0.18 source scale, corner visible dimensions are 156.78x77.76px, broken end 127.62x97.92px. Corner branch projected endpoints differ by approximately (432,-220) source pixels, slope 0.509 rather than exact 0.5. Uniform scale cannot change a drawn slope. Measurements are hand-selected visual registration probes, not certified geometry.

## Sources and preservation

- Candidate originals from merged PR #101: https://github.com/Rando2020/ProjectTactic/pull/101
- Existing Blooming atlas: `demos/isometric-2v2/assets/environments/blooming-ruins-v2/props.png` in the separate prototype worktree; source manifest archived at https://github.com/Rando2020/ProjectTactic/blob/8d5284e239f7573715bd507de21bf45f5896bc20/godot/assets/environments/blooming-ruins-v2/manifest.json
- SHA-256 hashes are recorded in `proposed-registration.json` and verified by `verify_sources.py`.
- No source pixels edited; no mirrored or rotated art; no generated collision.

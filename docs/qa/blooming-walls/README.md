# Joinable courtyard wall candidate

Isolated follow-up to #104's incompatible image endpoints, based on #110 at
`e2c0b6a457f1332c98b56afef808268631fcfee6`. Existing PRs, default scenes, main,
source images and gameplay are unchanged. This draft is not a deployment.

## Geometry and rendering

Straight, mitered 90-degree corner and terminal pieces use the same 0.26-cell body,
0.34-cell cap and 1.25 logical-height rise (40px), including a 0.18 cap rise.
Terminals do not acquire taller caps. Eight pieces form a central terrace wall
and two corner returns, with the two 2-cell stair openings preserved.

The kit starts with shared 3D coordinates and projects them into depth-sorted 2D
polygons. This is deliberate for the existing mixed renderer: putting these walls
in the floor viewport would make every 2D actor draw in front. This is not a
physics mesh or a freely rotating 3D environment. Painterly surfaces sample the
unchanged Blooming stone atlas with world-space texture phase.

Head/torso probes hit actual projected wall polygons, not transparent image
rectangles. Sorting accounts for the visible actor body's +10 child depth.
Midpoint sorting and two body probes remain bounded approximations, not complete
whole-body occlusion. Other existing cutout fading is unchanged.

## Run

From the repository root, use Godot 4.6.3:

```
godot --headless --path demos/isometric-2v2 --editor --import
godot --headless --path demos/isometric-2v2 res://tests/blooming_walls/ContractTest.tscn
godot --headless --path demos/isometric-2v2 res://tests/blooming_walls/ActorDepthTest.tscn
godot --path demos/isometric-2v2 res://prototypes/blooming/walls/ReviewBattle.tscn
```

The actual-encounter capture harness is `tests/blooming_walls/Capture.tscn`.
Pass `-- --capture-dir=/absolute/output --label=after`; add `--baseline-walls`
and use `--label=before` for the original. It captures overview, center joins,
left stairs, right corner and movement highlights, plus identical tactical-state
JSON. It intentionally refuses headless mode rather than produce fake evidence.
The `Joinable courtyard walls` workflow captures with native Godot/xvfb.

## Provenance and acceptance

The November 7 local-only package was not available after an environment refresh.
This candidate was reconstructed from its recorded source creation steps on
November 9. It is freshly validated; it is not claimed byte-identical to the old
ZIP. The previous review's shader double-sampling and actor-child depth fixes
are retained. No new raster artwork was generated or altered.

Contract checks cover exact socket position/normal/cross-section, shared rise,
finite projected geometry, clear/solid/front/hidden/moving actor fading,
unchanged map and stair picking, repeat installation and original-art restoration.
ActorDepthTest uses the actual battle and Zane sprite rather than a blank probe.

Before accepting the artwork, inspect the native before/after captures at gameplay
and closeup scales. Browser/mobile/touch, continuous actor movement across wall
segments, full-match acceptance and performance remain separate gates. Nothing in
headless success constitutes visual approval.

Fresh focused validation on November 9: ContractTest 314/314 and ActorDepthTest
6/6 passed. Import completed without script errors. The remaining local supported
suite and exact-head CI are in progress at initial publication; results must be
checked before promotion. The source starts as a separate draft.

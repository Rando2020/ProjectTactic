# First-battle terrain candidate

This is a draft integration on top of PR #41, pending live browser visual acceptance.
No PR has been merged. Existing assets are unchanged.

## Scope and entry

Start or Continue a run on floor 1, deploy, and enter the normal battle. The actual
BattleScene, party, enemies, movement, targeting, turns, victory and save callbacks
are retained. Only the first run floor receives the candidate art. Later floors,
completed runs and standalone maps retain their original textures.

For an original-art comparison, disable `use_first_battle_terrain` on the root of
`godot/scenes/Battle.tscn` in the editor, then replay the same seed. The switch is
not saved into player progress. Terrain Lab remains available from the title.

| Gameplay terrain | Candidate texture |
| --- | --- |
| grass | grass |
| road | dirt |
| stone | stone |
| high_ground | stone |
| shallow_water | shallow_water |

Aliases change presentation only. Road flammability, movement costs, water rules,
height faces, objectives, enemy generation and rewards are untouched. Brush and
all other unlisted materials keep their original art. The kit loads four distinct
imported textures, shared across five aliases, without per-tile image decoding.

Missing assets are omitted from the override dictionary. A null override now also
falls through to the existing texture loader. The existing procedural top remains
the final fallback. The regression fails with the previous null-override behavior
and passes with this fix.

## Verified locally, Godot 4.6.2

- 37 terrain assertions: the existing alpha/adjacency and Terrain Lab checks plus
  actual floor-one battle initialization, all four party textures and foot anchors,
  all 80 tile centers at 0.6/1.0/1.5 zoom including raised tiles, movement-highlight
  placement, unchanged logical tiles/occupancy/save state during art comparison,
  imported-resource reuse, null/absent fallbacks, fire mutation, and scope/opt-out.
- 36 native integration checkpoint assertions passed, including cold-process
  restoration and actual victory/boon/abandon/Continue callbacks. These are not
  browser refresh or IndexedDB tests.
- Static check passed with the existing warning set. The battle test reports an
  ObjectDB cleanup warning at shutdown, also seen in existing integration tests.

Reproduce:

```sh
python3 tools/check_terrain_art.py --godot /path/to/godot
python3 tools/check_integration_checkpoints.py --godot /path/to/godot
node tools/check_godot_stability.mjs
```

The terrain workflow runs both native suites and the existing reusable Web export.

## Performance and visual limits

On an identical seed-42 80-cell battle, nine warmed CPU redraw samples per mode
initially measured a 1.320 ms median for original art and 1.292 ms for candidate
art. Both modes retained 186 direct grid children. This is a small headless CPU
sample, not an FPS/GPU benchmark or evidence of a meaningful speedup. Timings are
printed by the test for subsequent runs rather than enforced as a flaky threshold.

The cloud browser could not reach the local export server (`ERR_CONNECTION_REFUSED`).
Terrain Lab and the candidate battle have NOT received live browser approval.
The older local Web export was not treated as validation of this change. Coordinate
round-trips verify geometry, not real pointer events or fractional-zoom rasterization.
Loaded party sprites and foot anchors verify placement, not perceptual contrast.
The PR #41 composited proof remains useful for preliminary terrain readability;
actual battle sprites have stat-based scaling, so it is not a battle screenshot.

Before approval, inspect Terrain Lab at 1x/2x and a real first battle in a browser
with WebGL2 on HTTPS/localhost. Check mixed material boundaries, raised faces,
brush transitions, all party/enemy silhouettes, move/attack overlays, and pointer
selection at minimum/default/maximum zoom. Record hardware/browser and frame-time
samples with the art switch on and off. Do not expand the rollout until accepted.

## Next implementation prompt

Validate this draft in a compatible browser using the Web artifact. Play one
complete first-floor battle, check unit contrast, real pointer alignment and
frame times with original and candidate terrain, and refresh before battle and
after victory. Fix only reproduced defects, record evidence on the PR, and do not
merge or expand terrain to additional floors.

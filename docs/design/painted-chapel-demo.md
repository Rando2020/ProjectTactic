# Painted chapel demo

## Purpose
Use the approved compact stone battlefield as one background image for a playable Zane versus Storm Imp demo. This is a pragmatic fixed-camera presentation, not a modular terrain kit.

Choose **Painted Chapel / Play Art Preview** on the title screen. The existing Illustrated Chapel entry keeps its modular terrain and elevations.

## Files and integration
- `godot/assets/environments/ruined-chapel/chapel-painted-background.png`: approved 1536 x 1024 background, stored as a normal Git blob for reproducible checkouts.
- `godot/scripts/presentation/PaintedChapel.gd`: isolated 5 x 5 demo map, background placement and terrain mutation tints.
- `godot/scripts/data/MapData.gd`: optional background path, image-space grid origin and tile dimensions.
- `godot/scripts/grid/TacticalGrid.gd`: background drawing beneath the existing interactive highlights and units. Existing picking, movement and combat coordinates remain authoritative.
- `godot/scripts/ui/StartScreen.gd` and `godot/scripts/battle/BattleScene.gd`: opt-in practice entry, map selection and legal compact spawns.
- `godot/tests/test_painted_chapel.tscn`: real battle scene checks registered in Godot Validate.

## Geometry contract
Only the open lower floor is playable. Grid cells are 128 x 64 diamonds; cell (0,0) is centered at image pixel (960,474). The arena boundary corners are (960,442), (1280,602), (960,762), (640,602). Zane starts at (1,3), Storm Imp at (3,3). Logical elevations are zero. The stairs, upper platform, walls and pillars are scenery and are outside the playable grid.

Tile seams in the generated image are illustrative and may not exactly match logical cells. Thin runtime grid outlines identify the actual playable cells; movement and targeting overlays use those same coordinates. The camera frames the entire compact diorama. No full-screen Fire tint is introduced.

## Source and limits
The image was generated from the user's selected Zane reference sheet, specifically its bottom-left and bottom-middle battlefield examples, then approved for the demo. The reference collage itself is not a runtime asset.

Background SHA-256: `e5f8f4997d6b46cb71752fac55b73e1e078335ba7cf52336fe4d355f8c0454fc`.

This static image does not provide movable walls, traversable stairs, parallax, dynamic torch lighting or foreground occlusion. The demo keeps sprite fallbacks and the approved portrait from PR #85. It depends on that unmerged integration candidate; no merge or live deployment is included.

## Validation
The painted demo's headless runtime suite passes 90 checks: image loading, all 25 cell-center picking round trips, flat terrain, off-board rejection, legal spawns, movement bounds and execution, Fire targeting/cancellation/damage/12 MP cost, redraw cleanup, retry and saved-profile preservation. The test reports one shutdown-only SceneTreeTimer ObjectDB warning after scene teardown; no assertion or script error accompanies it. Browser visual acceptance is still pending because the previous managed browser lacked WebGL2 and a secure context.

## Next acceptance
Run the branch Web build in a WebGL2-capable browser over localhost or HTTPS. Inspect unit feet and highlight alignment, actual HUD occlusion, mouse/keyboard controls and retry. Refine the grid origin if necessary before treating this demo as visually accepted. Later, replace the backdrop with reusable terrain pieces while retaining the combat grid.

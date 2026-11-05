# Continuous lower-ground regression

`RenderedGroundTest.tscn` uses actual Godot SubViewport pixel output. Run with a display and `-- --capture-dir=/absolute/output`. It intentionally exits 2 under headless rendering. `OriginalSurface.gdshader` is the unchanged reference at combat head `0d109fdd7f43dca7b72f758b6b86cc3760b4b58e`.

The first comparison renders the same lower-floor world patch with surface 0 and surface 1. It must produce identical pixels, so terrain tags cannot reintroduce a visible cell-border seam. A separate assertion requires soil to remain visibly different from paving. The remaining comparisons require unchanged upper-landing, stair-top, stair-riser, retaining-face, both two-cell path-lane centers, and outer-perimeter pixels against the reference shader. An elevated patch over the soil-positive world coordinates directly tests the height gate. These checks do not establish whole-scene visual quality or performance.

`ContractTest.tscn` runs headlessly. It checks the actual lower mesh top and material binding: the inherited presenter transforms model y=.26 to world y=0. The shader uniform must match the transformed mesh, not the untransformed model height. Gameplay road/stone tags and the four-level staircase must remain intact.

`Capture.tscn` renders the real integrated encounter overview and movement highlights with no moves committed. Pass `-- --capture-dir=/absolute/output --label=after`. Add `--original-ground --label=before` to reproduce the frozen original shader in the same integrated scene without editing source files. Selection is staged programmatically for repeatable screenshots; this is not a mouse-input acceptance test. Map/grid geometry and source art are not altered.

The Isometric combat UI workflow runs the contract, pixel regression, and both capture modes, then uploads them in `blooming-combat-ui-evidence/ground`.

Run `res://prototypes/blooming/GeometryTest.tscn` and the existing `tests/blooming` and `tests/blooming_hud` scenes separately to verify gameplay, elevation, picking, lifecycle, and UI contracts.

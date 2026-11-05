# Prop contact shade verification

Run the headless `ContractTest.tscn` to check ten supported props, transformed support heights, bounded radii, material synchronization, repeated configure, viewport refresh, and unchanged tile data.

`RenderedTest.tscn` requires a real display and exits 2 headlessly. Pass `-- --capture-dir=/absolute/output`. It compares actual SubViewport pixels with contacts enabled/disabled. Nine checks cover visible lower/upper contact, the 18% darkening cap (8-bit tolerance), no brightening, distant/wrong-height/side/underside/stair preservation, zero-contact equality to the frozen #107 shader, and non-additive overlap. `BaselineSurface.gdshader` is byte-identical to PR107 head `50ab3df9da8d3b561699ec28fc54437341d61942`.

`Capture.tscn` inherits the actual encounter capture harness from the ground regression. Use `--label=after`; for the same scene without this effect add `--without-contacts --label=before`. It captures overview, movement highlights, and three close views by changing only the test camera. The original camera is restored before movement highlights. Selection is programmatically staged, so these are presentation checks rather than pointer acceptance.

The existing Isometric combat UI workflow runs the contract, renderer checks, and both capture modes; its `blooming-combat-ui-evidence` artifact contains a `contact` folder. Source art, mesh geometry, map/grid, unit/decor placement, and soil-transition formulas remain unchanged.

# Continuous lower courtyard ground

This is a separate opt-in Blooming presentation patch. It changes no map, grid, collision, movement cost, source art, default scene, existing PR branch, or deployment route.

## Cause and correction

The original shader already uses world-space texture coordinates. Its `surface==1` gate, however, paints soil only on road-tagged meshes. At the common edge of cells (6,6) and (6,7), model/world xz=(12,13), the road mask is guaranteed fully soil while the stone cell remains fully paved. This creates a straight logical-cell boundary unrelated to the garden shape.

The new field applies to both ordinary lower-floor materials. A world-height uniform is derived from the actual mesh transform: PracticeTerrain3D scales and offsets model y=.26 to world y=0. Upper surfaces, stair material 3, and vertical faces keep their prior rendering.

The soil area is bounded by x=1..21 and z=5..15, with irregular continuous world-space noise. Paved two-cell stair approaches are centered at x=5 and x=17, half-width 2, matching grid columns 2–3 and 8–9 at two model units per cell. At each protected cell center the base mask is at most -1; maximum noise is .85, leaving it below the -.12 blend start. The court's outer cell centers stay paved by the same bound.

## Evidence

Base GitHub commit: `8d66158c681fa88354bf773fe1c684e5e63b0ba2` on `feature/blooming-combat-ui-confirmation`. Local source commit `0d109fdd7f43dca7b72f758b6b86cc3760b4b58e` has exactly the same root tree: `27f60f494ca2cc17be8090da3bdc3b00a12a2576`.

- Baseline native regression: road versus stone disagreed at all 12,544 compared pixels (max channel difference .784314).
- Final native regression: 13 checks, zero failures. Both soil interior and transition patches are tag-independent. Soil remains present, and elevated soil-positive coordinates remain paved. Upper landing, tread, riser, retaining face, four approach centers, and outer-center reference comparisons match pixel-for-pixel. See `native-render-tests.json`.
- Actual transformed mesh/material contract: 8 checks, zero failures.
- Geometry: 431 checks. Path edges: 17,360. Integration: 82. Lifecycle: 73. Combat flow: 23. All passed; replay, HUD factory/layout, self-review, and 10-cycle terrain cleanup also passed.
- Before/after integrated overview and movement-highlight images were visually reviewed. Soil no longer ends at logical road/stone cell borders. Stair steps and elevated terrace remain distinct, and movement overlays remain readable.
- The capture's tactical state is identical before/after: 128x64 tiles, 32px height step, stair landing 4/foot 0, unchanged road/stone tags, Zane at (3,8), and 62 highlight nodes. See `tactical-state.json`.
- The reproducible `--original-ground` capture's overview exactly matches the untouched baseline image. The highlight snapshot differed by 77 pixels; this timing-sensitive presentation is not claimed to be generally pixel-deterministic.
- Five original PNGs plus map/grid are byte-identical to base. See `source-integrity.json`.
- All 31 supported headless invocations in the local validation batch passed (20 current isometric/script contracts plus the 11 Blooming/ground/cleanup scenes). The retired 1v1 route is excluded as in existing CI. SkillPreviewTest emitted a shutdown resource-in-use diagnostic despite exit 0; this is not presented as a warning-free whole-project sweep.
- Independent read-only review found no blocking implementation or incremental workflow defect. Its suggested elevated soil-positive regression was added and passed.

## Reproduce

With a real display, run `res://tests/blooming_ground/RenderedGroundTest.tscn` and pass `-- --capture-dir=/absolute/output`. Headless execution intentionally fails instead of claiming render coverage. For actual encounter captures run `Capture.tscn` with the same output flag and `--label=after`; add `--original-ground --label=before` for the reference. Run `ContractTest.tscn` headlessly.

The Isometric combat UI workflow runs these tests and captures both versions. Its `blooming-combat-ui-evidence` artifact contains the `ground` folder with PNGs and JSON plus root-level logs.

## Boundaries

Native verification used Godot 4.6.3 Compatibility OpenGL on llvmpipe. No browser/mobile performance, touch, full-match playability, wall-socket geometry, new generated assets, or audio approval is inferred. Screenshots stage selection programmatically; they are not pointer-input acceptance tests. Some baseline/early capture runs emitted shutdown ObjectDB warnings; final local capture completed without one. Existing whole-project route-test exclusions remain outside this presentation patch. This is not a claim that every texture or architectural socket is seamless.

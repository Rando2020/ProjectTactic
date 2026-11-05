# Grounded courtyard props

This is a restrained contact-shade pass on the existing #107 courtyard, not a new terrain kit or relighting system. Six cypresses, three stone columns/piers, and the pots share a small soft darkening where they meet their support surface. There are no new bitmap assets, meshes, decorative placements, gameplay changes, or UI changes.

## Receiver and scope

Existing decoration anchors supply world x/z and transformed support y. Radii are .45 model units for cypresses, .48 for column/broken column/pots, and .55 for the ruined pier. The mask reaches zero at its radius, takes the maximum when footprints overlap, and retains at least 82% of the original surface color. Only positive-y ordinary top faces at the matching height receive it. Sides, undersides, and stair material 3 are excluded. The arch, walls, banners, ivy, and bushes are deliberately outside this pass.

Materials use zero contacts by default. BloomingTerrain synchronizes ten contacts after garden creation and refreshes the cached viewport after rebuild. Current fixed-courtyard supports and positions remain authoritative; this does not implement moving-prop shadows or arbitrary terrain deformation.

## Verified locally

- Baseline contact contract failed because the contact list did not exist. Native baseline had exactly two failures: lower and upper contact patches did not darken.
- Final contract: 28 checks, zero failures. Final native pixel regression: 9 checks, zero failures. Original ground renderer regression remains 13/13.
- All 32 supported local headless invocations passed, including script validation, current isometric/Blooming/HUD contracts, both terrain contracts, and cleanup. The retired 1v1 route remains excluded as in the existing workflow. Final import passed; native regression intentionally rejects headless execution.
- Independent read-only review reran contact28, geometry431, and ground8 checks, verified baseline/image integrity and CI shell/YAML, and found no blocker. It recommended retaining this modest improvement.
- An underside probe caught the inherited absolute-normal condition affecting downward faces. The contact pass now requires positive y; the added regression passed after the correction.
- Pixel tests enforce the actual 18% color-retention bound, including 8-bit quantization tolerance, rather than an unrelated absolute-channel delta.
- The disabled-contact integrated overview is pixel-identical to the untouched #107 baseline. Enabling contacts changes 1,856 pixels in the 1180x812 overview. All 510,249 background-color pixels, the right rail, and footer remain unchanged. Tactical JSON is identical, including 62 movement-highlight nodes and stair heights 4/0.
- Actual native overview, highlights, and three magnified camera views were captured with contacts enabled/disabled. Trunks and stone bases read more grounded; the effect is intentionally small, with no obvious discs or cliff bleed in these views.
- Five original PNGs, map, and grid remain byte-identical. The frozen test shader exactly matches #107. Soil-transition formulas, geometry, picking, units, and source decoration placements are untouched.

## Reproduction and evidence

See `demos/isometric-2v2/tests/blooming_contact/README.md`. The Isometric combat UI workflow runs the headless contract, native pixel tests, and both integrated capture modes. Download `blooming-combat-ui-evidence`; `contact/` contains overview/highlight pairs and front-cypress, left-column, and upper-cypress close views. Adjacent root logs record each run. JSON files here retain the local renderer and image comparisons.

Base: GitHub PR107 head `50ab3df9da8d3b561699ec28fc54437341d61942`, equivalent local commit `00d7c306851bdf34e9278be18368bb0cc1d3836b`, root tree `c785b9d80290589a58aec0a9157511b2023178a3`.

## Limits

This is static ambient contact shading, not physically cast sunlight. Untreated shrubs, arch, and walls retain their prior appearance; the result is a modest cohesion improvement, not final environment approval. Contacts remain under props that fade to reveal a unit; because they are drawn in the terrain, they cannot cover units or highlights. Existing tile borders and surface texture detail remain visible. The default strength is capped at 18%; no performance or browser/mobile acceptance is inferred. Some native encounter captures emit the already-observed ObjectDB shutdown warning. Nothing is merged or deployed by this work.

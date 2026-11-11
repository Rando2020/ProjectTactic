# Review evidence and scope

Date: 2026-11-11. Base repository commit: `71a40dbca21dbbef288c470cf0b2d3819d22e0eb`.

## Findings

- **Identity / one-frame visual check: passed for study scope.** Both candidates retain brown swept hair, cream scarf, navy split coat, brown boots/belts, bronze trim, a sword in the anatomical right hand (viewer left), and the larger pauldron on the anatomical left shoulder (viewer right). No mirroring was applied.
- **Small-scale readability: promising.** The head, scarf, separate boots, hand and short sword are easier to distinguish at 85 px visible height than on the tall painterly source. The pixel treatment is closer to the user's compact nostalgic example. The HD treatment has clearer contours and more continuous detail when enlarged.
- **Exact identity/style approval: pending.** The large head and shorter body read more chibi than the approved illustration. The coat tails and sword are shorter, trim is reduced, and the distinctive pauldron ornament is simplified. The HD face is rounder and more youthful. These are visible design tradeoffs, not hidden defects declared solved.
- **Source PNG / alpha checks: passed.** All three images decode as RGBA, have empty transparent margins, and contain non-empty silhouettes. The PNGs were preserved unchanged after generation, not recolored, mirrored, cropped, repainted or quantized by a script. PNG foreground alpha is mostly near-opaque rather than exclusively 255. The rendered light/dark/terrain-color comparison shows no obvious colored halo at review size.
- **Pixel-grid / palette discipline: not passed as production pixel art.** The nostalgic candidate is a high-resolution generated pixel-style image, with many source colors and anti-aliased transitions. It is not a verified native 48x64/64x80 pixel grid, despite that requested prompt. A palette/grid cleanup step is still needed for a pixel-exact production style. The original PNG is not mislabeled as a native low-resolution export.
- **Direction: one front-right idle view only.** No opposite or rear direction was generated. Body angle still needs to be calibrated against the game's camera; text prompts do not establish a strict isometric angle.
- **Animation, loop seams and action switching: not applicable to this one-pose style test, and not validated for production.** No breathing, walk, run, attack, transitions or generated in-between frames are delivered.
- **Game ground registration and integration: not performed.** The comparison normalizes alpha>=128 silhouette height only. It does not establish common ground-plane pivots, source-to-world scale, depth sorting or actual battle camera fit.

## Evidence

The source PNGs were individually inspected. The comparison report was rendered and visually inspected at 1260 x 820, including all three backgrounds at 85 px visible height. Embedded fonts fixed an initial report-renderer font substitution problem. The final report shows readable text and unclipped sprites.

A local Chromium capture was attempted but blocked by `socket() failed: Operation not permitted`, including one reviewed retry. The deliverable image is therefore a PDF-rendered comparison report, not a browser screenshot or an engine screenshot. The offline HTML is supplied for review but browser rendering/interactions were not verified here. No full game tests or Godot playback pass is implied by PNG validation.

## Provenance and terms

- Approved reference: repository `assets/source/production-catalog-2026-11-04/references/zane-front-approved.png`, SHA-256 `d299d45c28f164620beee1d88871edea780ce4ad3c4873f1bea86735b64ab236`.
- Actual generation: built-in ImageGen; selected final prompts are `nostalgia_compact` and `hd_compact` in `prompts.json`. Earlier prompts are retained as exploratory history, but their rejected tall outputs are not deliverables.
- The small commercial-game before/after image was used solely to communicate compact proportions and visual treatment. It is intentionally not copied into this source pack, and the generated character uses the project's original Zane design.
- sprite-gen documentation currently identifies Apache-2.0; Codex to 2D Sprites identifies MIT. These are the tool/documentation licenses, **not licenses being assigned to these generated images**. No third-party code was copied or executed, no new account or paid API was used, and no new third-party terms were accepted for this test. A production release still needs the project's ordinary asset-rights/provenance review.

## Recommendation

Use the nostalgic compact silhouette as the leading direction to review, with the HD treatment as a useful alternative finish. Do not expand to the roster or imply animation success yet. First settle a slightly less youthful face and whether to preserve one signature pauldron detail, then prove independently authored front/rear/left/right anchors before a small real gait test.

# Zane: northeast idle sword correction

Source-only character art candidate, 2026-11-07. **Not approved gameplay art.**

## What is new

One new 1254 × 1254 RGBA sprite: `output/zane-ne-lowered-sword-candidate-v02.png`.
It corrects the existing northeast rear candidate's raised horizontal sword into a lowered idle position. The sword remains in Zane's anatomical right hand. The large starburst pauldron remains on his anatomical left shoulder. The whole character still faces northeast in a rear three-quarter view.

The other three views are preserved reference pixels, not newly generated assets. The approved southeast original, unapproved southwest and northwest candidates, and superseded northeast comparison are bundled so this correction can be judged as part of the existing four-direction set. Nothing has been replaced in the game or in the previous review package.

## Review

Open `review.html` locally. Keep the bundled folders beside it; it loads the original local PNGs and needs no server, network access, upload, or dependencies. It shows the old/new northeast side by side, four directions at enlarged and 85-pixel visible heights, and a direction-switching comparison. Light/dark/checkered backdrops are review backgrounds, not image pixels. Browser scaling is only for display. The source PNGs are not trimmed, mirrored, resampled, recolored, or alpha-repaired.

The comparison uses the previous review's alpha ≥ 128 bounding boxes and manual horizontal foot centers. The vertical baseline is the lowest sufficiently opaque pixel. **This is not a calibrated boot-contact/ground-plane pivot.** Display registration must not be copied blindly into gameplay.

## Visual findings

- Improved: northeast sword angle now matches the relaxed lowered-weapon family rather than an attack-ready horizontal pose.
- Preserved: right weapon hand, left major pauldron, rear three-quarter direction, chestnut hair, cream scarf, navy/gold coat, and brown boots.
- Remaining: southeast/southwest turn angles and sword projection still differ; scarf folds, coat panels/ornament and pouch details still drift between views. The northeast coat remains broader than the approved front. These are a candidate family, not a consistent approved animation set.
- Not done: walk/attack/cast/idle animation, calibrated foot contacts, native engine captures, battle integration, main-branch changes, merge, or deployment.

## Technical checks

Run `python validate_assets.py` (Pillow required). `validation.json` contains the recorded result.

- All five PNGs match recorded SHA-256 values and are RGBA 1254 × 1254.
- The new PNG has **1,260,629 fully transparent pixels (80.1664%)**. Transparency is genuine alpha, not an opaque matte or a painted checkerboard.
- No visible silhouette reaches the border at alpha ≥ 128.
- There is **one border pixel with alpha 1/255** and faint alpha outside the main silhouette. This is preserved and explicitly disclosed, not silently repaired. The approved front and old southwest also have faint alpha noise. Edge cleanup needs review before production use.
- These data checks establish file integrity and transparency, not visual acceptance or animation readiness.

## Provenance

Generated with the built-in image generation tool on 2026-11-07. Exact prompt: `prompts/zane-ne-lowered-sword-v02.txt`. Three provided references were used: approved southeast front, existing northeast target, and northwest lowered-weapon stance. The raw generation was copied byte-for-byte into `output/`.

Existing reference source: [November 4 Zane review](https://github.com/Rando2020/ProjectTactic/tree/assets/zane-four-direction-review/assets/source/zane-direction-review-2026-11-04). The approved front originated at `demos/isometric-2v2/prototypes/isometric/assets/zane-front.png`. Reference hashes are independently matched to that review's registration records. No third-party stock or newly licensed material was added.

## Next acceptance gate

Review the candidate with the other three views, correct remaining costume/turn-angle drift, calibrate both boot contacts, and inspect directional switching in the actual battlefield. Explicit visual acceptance is required before replacing the gameplay atlas or producing animation from this candidate.

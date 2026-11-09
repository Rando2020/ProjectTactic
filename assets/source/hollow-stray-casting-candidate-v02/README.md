# Hollow Stray casting candidate v02

**Status: source candidate for review. Not art-approved or installed in gameplay.**

Three new painterly RGBA source images develop the existing Hollow Stray identity used by the `storm_imp` gameplay slot: southwest idle, cast windup, and spell release. The separate horned alternative has not been selected. This pack does not settle that identity choice or change the existing game.

## Files

- `originals/*candidate-v02.png`: three 1254 × 1254 generated originals, unchanged source alpha.
- `originals/reference-hollow-stray-v01.png`: existing 128 × 128 runtime identity reference, preserved for comparison.
- `manifest.json`: direction, source anchor, display scale, review-only pose timing, and remaining work.
- `prompts/`: exact prompts used with built-in image generation on 2026-11-09.
- `index.html`: local visual review of all poses, canvas sizes, grayscale toggle, and three-pose timing. Open directly in a browser or serve the repository root. The staging panel references the repository’s existing chapel art, not a gameplay screenshot.
- `qa/`: alpha statistics, geometry validation, Godot load/texture tests, and reproducible validation scripts.

## Runtime scale and foot anchor

The original pixels are not cropped, resampled, or masked. Apply source scale `120/1183` and a shared source anchor `(695, 1204)` to place the figure in a logical 128 × 128 canvas at `(64, 124)`. This avoids deriving alignment from nearly invisible alpha specks. All three poses share the same transform; no per-frame auto-centering is applied.

For `Sprite2D` / `AnimatedSprite2D` with centered textures, use source-space offset `(-68, -577)` because each source is 1254 square. Set node scale to `(0.1014370245, 0.1014370245)` for the logical 128 canvas. Apply the game's additional `95/128` display scale for its current 95 px enemy canvas. The parent node's origin is the foot anchor.

Review timing is idle 1000 ms → windup 260 ms → release 180 ms → idle/recovery 560 ms. This is **three discrete poses, not a finished fluid animation**. A spell release event is suggested at the release transition. No new spell artwork is generated or baked into the character.

## Validation completed

- Each source is RGBA, 1254 × 1254, with more than 70% fully transparent pixels.
- The visible silhouette (`alpha >= 16`) has clear image margins and fits the 128 × 128 reference contract. At this scale, the lowermost visible pixels vary by about 0.30 px across the three poses.
- The conductor stays in the same hand and shoulder armor, hood, sash, and faceless identity remain recognizable across poses on full-resolution inspection.
- Godot 4.6.3 loaded all three PNGs, detected alpha, and created ImageTextures successfully.

## Known limits and next steps

- Sparse alpha=1 specks touch source edges; body alpha is mostly 252–253/255. True transparency is present, but edge-alpha cleanup still needs a deliberate acceptance pass. Source alpha is preserved, not silently thresholded.
- Subtle cloth, hood, and body-shape changes remain between generated poses. Frame-perfect animation cleanup is not complete.
- One direction only. No movement, hurt, KO, portrait, or remaining facings are supplied in this batch.
- Chromium preview launch failed because the environment disallows the process socket, including an approved retry. Therefore the HTML review, 95 px rendered readability, and in-game staging are **not claimed as tested**. The source image review and numerical checks are not a substitute for gameplay acceptance.
- Approve the art identity and these key poses, then perform alpha/shape cleanup, add controlled in-between frames and directions, and review in the actual courtyard before any live asset replacement.

## Provenance

The reference is the existing ProjectTactic asset `godot/assets/characters/enemy-hollow-stray-idle-v01.png`. The existing Hollow Lancer supplied family rendering guidance only. The three new images were made with the built-in image generation tool; no third-party sprite extraction or external generation API was used. Existing sources, fallback art, live demo, and other pending PRs are unchanged. This isolated source-candidate folder is published for review, without runtime manifest changes.

# ProjectTactic: six painterly job emblems

Generated 7 November 2026. **Normalized candidates, not approved or integrated.**

This is a real asset pack: six separately generated RGBA masters and 24 standalone PNG exports, not a concept atlas. It covers the current three Basic and three Advanced jobs. Ascended jobs, character sprites, animation and UI state implementation are outside this pack.

## Files

- `originals/`: six untouched generated masters, one icon per PNG.
- `exports/`: each icon at 128, 64, 48 and 32 square pixels, transparent RGBA.
- `review/job-emblems-overview.png`: labeled preview with native-size samples on dark ink, cream and grayscale. Review-only, not a runtime atlas.
- `manifest.json`: source/export hashes, dimensions, alpha measurements and existing-job mappings.
- `prompts.json`: exact generation prompts, original output paths, tool and date.
- `build_exports.py`: deterministic mechanical export and QA script. Requires ImageMagick, Pillow and NumPy. Run `python build_exports.py` from any directory. It never calls an image model.
- `references/`: the six recovered placeholder icons, existing approved Zane front identity reference for contextual comparison, and the verified job-definition excerpt.

## Verified job mappings

Verified against `godot/scripts/data/JobTreeData.gd` at commit `c763f976b04c361ad687721a6e61e27c3b0826a1` in Rando2020/ProjectTactic:

| Existing job ID | Generated icon | Existing icon filename |
|---|---|---|
| `squire` | upright sword | `job-knight-icon.png` |
| `arcanist` | violet memory-lens focus | `job-mage-icon.png` |
| `scout` | bow and arrow | `job-archer-icon.png` |
| `warder` | broad iron shield | `job-guardian-icon.png` |
| `luminary` | warm healing lantern | `job-cleric-icon.png` |
| `shadow` | violet crescent blade | `job-rogue-icon.png` |

Current source link: https://github.com/Rando2020/ProjectTactic/blob/c763f976b04c361ad687721a6e61e27c3b0826a1/godot/scripts/data/JobTreeData.gd

The symbols are visual proposals grounded in existing descriptions. They do not imply new weapons, equipment rules, ability definitions or character identity changes. In particular, the Luminary lantern and Shadow crescent are job symbols rather than new equipped items.

## Art and provenance

All six masters were newly generated with the built-in image generation tool. The Squire emblem established the common painting style; the other five used that actual generated image as their style reference. The approved Zane front was inspected as context for ivory cloth, brass fittings and lavender/navy shading, but no character pixels were copied into the icons. The existing icon sources are small flat placeholders and were preserved for comparison, not overwritten.

Each output uses warm upper-left light, worn brass, ivory highlights, lavender shadow and a distinct silhouette. Source designs are independently generated original fantasy imagery; no commercial game artwork was imported.

## Export contract and checks

Original bytes are retained. Exports crop to visible bounds at alpha >=8, use aspect-preserving Lanczos downscaling to 80% of their canvas's longest dimension, then transparent centered padding. A few original margins contain negligible alpha-1 speckles; the visible-bounds crop excludes outer speckles without altering pixels inside the crop. Alpha is preserved, not reconstructed through chroma keying. No repainting or background-removal script was used.

All 24 exports pass: exact square dimensions, RGBA mode, fully transparent outer edges, alpha 0 and 255 present. SHA-256 values are recorded. Visible inspection found six different readable silhouettes and consistent lighting/material treatment. At 32 px the main symbol remains distinct; fine painted detail and tiny stones intentionally disappear. Always accompany the icon with a live job label or accessible tooltip. Do not use jewel color alone as the class identifier.

## Remaining acceptance

- User/art-direction approval is pending.
- No game manifest, job data, runtime asset or existing PR was changed.
- No Godot import, UI layout, browser, device or live-build test was run for this pack.
- Before promotion, review the exact job screen at its real display scale, including selected/disabled/focus states and light/dark backgrounds. Frames, labels and dynamic states remain engine-owned.
- Preserve the existing files/fallbacks until a separate integration change is authorized and tested. Do not merge this pack or PR #103 by implication.

This pack is for visual review and source-only repository submission, not a claim that the game now uses these icons.

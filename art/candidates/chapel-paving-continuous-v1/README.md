# Chapel paving material candidate v1

**One newly generated terrain image, not accepted runtime art.** A continuous warm
ivory / lavender limestone surface for the painterly chapel courtyard. It is meant
to cover several logical gameplay cells rather than repeat a diamond-shaped image
on every cell. The source pixels are preserved exactly as generated.

## Deliverable

- `source/chapel-paving-continuous-v1.png`: 1254 x 1254 RGB diffuse color map.
- `source/prompt.txt`: exact built-in image-generation prompt.
- `manifest.json`: provenance, source hashes, proposed registration and status.
- `proof/`: isolated Godot diagnostic plus a read-only image inspection script.
- `evidence/`: source statistics, final Godot import log and geometry log.

The actual Blooming surfaces PNG was supplied to image generation as the style
reference and visually inspected first. Its SHA-256 matched the repository's
manifest: `51d5ee51f24d8b88dd410e8371650940c7ab44745fe6cb4053d84961792d17a1`.
[Pinned reference](https://github.com/Rando2020/ProjectTactic/blob/e2c0b6a457f1332c98b56afef808268631fcfee6/demos/isometric-2v2/assets/environments/blooming-ruins-v2/surfaces.png).

## Registration and compatibility

The current playable Blooming grid is **128 x 64 pixels**, with height step 32 and
2 world units per cell. The older #104 assembly proof is 96 x 48 and is not the
production scale. This isolated proof uses the current 128 x 64 projection and
proposes one full image per 4 x 4 cells (8 x 8 world units). The 8 x 8-cell preview
therefore repeats the image twice per axis, not once per cell.

The current `BloomingSurface.gdshader` creates its slab joints procedurally from
a bounded coping-quadrant sample. This new full paving surface is **not a drop-in
replacement for the existing four-quadrant atlas**. A future integration would
need a separate material/sampler decision and preservation of the ground blend,
stairs, retaining faces and contact shade. No such change is made here.

## Checks performed

- Source opens as RGB, 1254 x 1254. SHA-256 is checked by the inspection script.
- The generated source was visually inspected for palette, material and absence
  of baked isometric thickness, labels, props or logical-cell grid.
- Mean left/right edge difference is 6.094/255; top/bottom is 7.668/255. These are
  1.230 and 1.348 times the corresponding mean interior adjacent-pixel differences.
  **Opposite edges are not identical. This is not a seamlessness certification.**
- Final Godot 4.6.3 headless import exits 0 without errors or warnings in its log.
- Isolated Godot loading/projection diagnostic: 135 assertions, 0 failures. This
  confirms the new source can load and the proof's 128 x 64 projection is coherent.
  It is not a gameplay or rendering test.

## Reproduce

From this directory, with Godot 4.6.3 and Python Pillow/NumPy installed:

```
python proof/inspect_source.py
godot --headless --path . --editor --import
godot --headless --path . -- --self-test
godot --path .
```

The display-backed scene shows an 8 x 8-cell isometric board, repeated material,
thin diagnostic cell lines and a sample translucent movement overlay. The source
image itself contains none of those overlays. The diagnostic's UV/render output
still needs inspection on a display-capable machine.

## Limits and next gate

The current environment could not start native X11 or Chromium capture because
local display/browser sockets were unavailable. No rendered screenshot, repeated
seam acceptance, native shader acceptance, actual encounter comparison, mobile or
browser performance result is claimed. Statistical boundary checks cannot verify
whether stone joints continue convincingly across the wrap.

Next: view the repeat diagnostic, inspect both wrap axes at gameplay scale, compare
against the current procedural paving, and decide whether this image belongs in
the material set before doing any integration. If seams are visible, request a
targeted image-generation revision. The candidate deliberately leaves the current
shader, map geometry, navigation, collision, characters, all existing PRs and live
deployment unchanged.

## Existing work checked first

- [#104](https://github.com/Rando2020/ProjectTactic/pull/104): standalone assembly
  evidence identifies mismatched wall thickness, capstone scale and projected
  axes. Its wall kit is not approved. No wall/socket operation was attempted.
- [#107](https://github.com/Rando2020/ProjectTactic/pull/107): continuous lower-floor
  soil blending; no new art.
- [#110](https://github.com/Rando2020/ProjectTactic/pull/110): subtle prop contact
  shading; no new art.

All three were draft, open and unmerged when checked for this candidate. Their
successful checks do not validate this new image.

# Approved character sheet sources and compact prototype frames

Both supplied sets are retained here without modifying their original PNG bytes.
`painterly/originals/` contains the earlier taller illustrated figures;
`compact/originals/` contains the later compact figures selected for the demo on
2026-10-31. `sources.json` records the source identities, dates and SHA-256 hashes.
These are ProjectTactic user-supplied/generated design assets, not extracted FFT
assets. This folder grants no independent third-party license.

## Runtime frame contract

`compact/frames/<role>/` contains `N.png`, `E.png`, `S.png`, `W.png` and
`portrait.png` for swordsman, rogue, mage and dragoon. Combat roles and narrative
identities are not defined by these class appearance studies.

- Every directional PNG is transparent RGBA on an 800×800 canvas.
- Ground/foot anchor: **(400, 740)**. Head-to-sole normalization: **600 pixels**.
- A runtime scale of `86.0 / 600.0` gives an approximately 86-world-pixel body.
- Logical view mappings are `N→NE`, `E→SE`, `S→SW`, `W→NW`. Rotate the logical
  facing through the view transform before choosing the frame.
- The portrait is a head/upper-body crop of the same `E` frame, not another art
  identity. Original PNGs remain available for other portrait presentation.

## Honest directional limitations

The sheets are four static views, not walk/attack animation sequences. Both top
poses face generally right; they do not supply a true opposing front view.
`E` uses the cleaner top-left front-right figure and `S` is a documented mirror.
For swordsman, mage and dragoon, `N` and `W` use the distinct authored rear-right
and rear-left figures. In the rogue sheet the right-hand figures touch, so `N`
mirrors the clean rear-left `W` figure rather than cutting a neighboring pose.
Mirroring reverses asymmetric costume and weapon handedness. These are
**provisional directional skins**, not four bespoke anatomically consistent
directions. The unused top-right and rogue bottom-right figures are preserved
in the original sheet for later refinement.

No image generation, repainting or inpainting was used for extraction. The
script separates major alpha-connected figures and includes nearby detached
fragments belonging to the same figure, then crops, nearest-neighbor scales,
and translates onto the shared canvas. Weapons and capes are retained inside
transparent margins. See `frames.json` for the inspected source anchors,
individual scale factors, bounds, mirror flags and output hashes.

## Reproduce and validate

With Pillow, NumPy and SciPy available:

```sh
python extract_frames.py
python test_extraction.py
```

Validation checks source byte identity, transparent unclipped frame bounds,
explicit mirror derivation, same-identity portraits and deterministic rebuilds.
It does not prove animation quality or physical-phone rendering performance.

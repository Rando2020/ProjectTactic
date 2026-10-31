# Fireball effect preparation kit

Prepared from the supplied original sheet, not regenerated artwork. The source preparation is preserved below; the prototype now consumes these frames as presentation-only Fire effects.

## Contents

- `originals/fireball-original.png`: byte-identical source; retained unchanged.
- `frames/`: 16 transparent 512×512 PNGs, grouped in order as charge, travel, impact, and dissipation.
- `manifest.json`: source identity, exact crop bounds, source anchors, output pivots, proposed preview durations, and SHA-256 hashes.
- `qa/contact-sheet.png`: generated on extraction for review, not a gameplay texture.
- `extract_frames.py`: deterministic extraction and validation, requiring Pillow, NumPy and SciPy. These were already installed in the preparation environment.

## Extraction decision and limitations

The sheet is not a clean uniform atlas. Its dimensions are not divisible by four, and the last travel and largest impact bounding boxes overlap. Their alpha-connected core components are nevertheless separate. This kit identifies one coherent component per frame via a visually selected source seed; it does not cut a rectangular 4×4 grid.

All 532,488 retained visible pixels preserve their exact original RGBA values. No alpha threshold, new paint, interpolation, or generated pixels are applied to the effect frames. The 64,760 detached nonzero-alpha pixels outside the selected components are excluded: mostly isolated sparks and very faint halo/speckle elements, but also some detached droplets/smoke fragments. This is deliberately a **core-only extraction**, not a claim of lossless extraction of all artwork. The original retains everything. It avoids assigning ambiguous detached pixels to the wrong frame.

All sixteen frames were inspected on a dark contact sheet. No neighboring core component is included. The retained cores have transparent margins; no visible retained pixel touches an output edge. The first three frames' faint ring glow and the final smoke are retained only where connected to the selected core.

## Integration contract

Use separate stage playback, not one animation attached to one position:

1. Charge frames 01–04 at the caster's casting/ground anchor.
2. Travel frames 05–08 along the caster-to-target trajectory. The source artwork points upper-right. Other trajectories require rotation/mirroring or more artwork; this is not four bespoke directions.
3. Impact frames 09–12 at the target. The supplied ground anchors are a starting estimate for visual tuning.
4. Dissipation frames 13–16 at that same target ground position.

For a centered 512×512 Sprite2D, set `offset = (256,256) - canvas_pivot` so its node position represents the pivot. Ground-stage pivots are `(256,400)`; travel pivots are `(320,256)`, at the fireball head. Keep the charge, impact and smoke upright relative to the stage rather than rotating those textures with the projectile.

Durations are proposed preview values only. Do not change spell MP, hit/damage timing, combat resolution, initiative or replay behavior merely to match this clip. Preserve current effect fallback until actual game-side visual validation. The preparation kit supplies no audio; integration retains the existing audio cues.

## Verification

Run `python3 extract_frames.py` to rebuild and validate. The script verifies the original SHA, distinct selected components, exact per-pixel source identity, no other-component bleed, output bounds, alpha format, and hashes. Contact-sheet generation uses resampling only for the QA preview, never the source effect frames.

The extraction checks alone do not establish gameplay acceptance or physical-phone performance.

## Prototype integration (2026-10-31)

`FireballFrames.gd` plays four frames per stage. Fire only opts into the ticket-owned presenter when `isolated_isometric` is active. Original rig gameplay retains its procedural effect. The 2D demo retains .20-second anticipation and .22-second travel, followed by a .50-second cosmetic impact/smoke tail. Hit, MP12, fan footprint, immunity, RNG, recovery and initiative remain authoritative in the existing combat engine. No turn-charge, friendly-fire or timing-system rules were added. Ground stages stay screen-upright; only the upper-right travel artwork rotates onto the actual projected path.

The runtime uses 0.24 charge, 0.19 travel, and 0.28 impact/smoke scale in effect coordinates. Painted and four rotated stage views use existing projected ground coordinates. Original artwork and both character sets are retained; original Fire source is excluded from browser export. Missing/incomplete frame sets retain the old procedural effect fallback.

Source Library original: `libfile_0953684bc2008191b9448fe9ca08a1d5`; preparation kit: `libfile_e587c77b7b80819199506b455a753b92`. User-supplied project artwork; no new asset generation or external sprite download.

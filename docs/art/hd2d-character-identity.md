# HD-2D Character Identity Pass

## Direction

ProjectTactic uses detailed painterly portraits for character identity and
dialogue, crisp pixel units for tactical play, and lit 3D terrain for battlefield
depth. Portraits and sprites share silhouette, costume landmarks, palette, and
lighting direction without requiring identical detail.

## Runtime assets

Detailed portraits live in `godot/assets/ui/portraits/`. The character screen,
asset registry, Guide dialogue, and Orren encounter use these paths with existing
fallback behavior preserved.

## Source sheets

Generated pixel animation concepts live in
`source-art/generated/character-sheets/`. They are intentionally not wired as
runtime sprites yet. Each sheet must be normalized into fixed-size frames with a
shared ground point and verified under nearest-neighbor filtering before it can
replace the existing battle sprites.

The lantern/VFX source composition lives in `source-art/generated/story/` and
must be separated into individual transparent textures before integration.

## Zane normalization contract

Zane is the first runtime proof. His 2172x724 six-pose source sheet is split into
six 362x724 transparent cells under
`godot/assets/sprites/units/zane-hd2d-v01/`:

- `zane-idle-01.png`
- `zane-idle-02.png`
- `zane-walk-01.png`
- `zane-walk-02.png`
- `zane-attack-01.png`
- `zane-guard-01.png`

The live battle currently uses `zane-idle-01.png`; the asset registry also owns
the attack path. `Unit.gd` forces nearest-neighbor filtering so browser camera
zoom does not blur authored pixels. Animation sequencing remains a follow-up and
must use these named frames rather than interpreting the original source sheet
at runtime.

## Current placeholders and risks

- Pixel sheets are candidate source art, not production atlases.
- Portrait crops require browser review at roster, dialogue, and forecast sizes.
- Orren's large encounter portrait may need a focal crop after visual testing.
- No combat rules, story progression, or save data were changed.

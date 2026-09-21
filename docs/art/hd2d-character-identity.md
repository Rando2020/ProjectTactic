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

The live battle uses these frames through a presentation-only `AnimatedSprite2D`
controller. Idle loops continuously; movement briefly selects the walk loop;
physical attacks and spell casts select attack; receiving a hit selects guard.
Every transient state returns to idle. `Unit.gd` forces nearest-neighbor filtering
so browser camera zoom does not blur authored pixels.

The other generated party sheets require a new generation pass: their poses
overlap neighboring cells and cannot be safely normalized by equal-width crops.
They remain source candidates only and are not referenced by runtime code.

## Mira anchor frame

Mira's animation rebuild now starts from individually generated poses. The
approved full-resolution anchor lives at
`source-art/generated/character-frames/mira-vey-v01/mira-idle-01-source.png`.
Its 512x512 nearest-neighbor runtime derivative lives at
`godot/assets/sprites/units/mira-hd2d-v01/mira-idle-01.png` and preserves RGBA
transparency. Battle and asset registries use this stable idle path while later
poses are generated from the anchor as an identity reference.

`mira-idle-02-source.png` was generated as an identity-preserving edit of that
anchor. Its runtime derivative, `mira-idle-02.png`, preserves the same canvas,
ground line, costume, palette, and camera while introducing only restrained
breathing and secondary-cloth motion. The asset registry now exposes both frames
as Mira's looping idle animation.

Mira's first movement pair follows the same one-pose-per-file workflow.
`mira-walk-01-source.png` and `mira-walk-02-source.png` are separate,
identity-preserving edits rather than crops from a generated sheet. Their
512x512 RGBA runtime derivatives live beside the idle pair as
`mira-walk-01.png` and `mira-walk-02.png`. Both retain the anchor's camera,
lighting, scale, transparent canvas, and shared ground line while alternating
the leading foot and secondary cloth motion. The asset registry exposes the
pair as Mira's walk loop, which the unit presentation controller selects during
grid movement.

## Current placeholders and risks

- Pixel sheets are candidate source art, not production atlases.
- Portrait crops require browser review at roster, dialogue, and forecast sizes.
- Orren's large encounter portrait may need a focal crop after visual testing.
- No combat rules, story progression, or save data were changed.

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

`mira-cast-01-source.png` is Mira's first identity-preserving action pose. It
keeps the anchor's costume landmarks and grounded stance while opening the
spellbook, extending her casting hand, and containing a compact ivory-violet
effect close to that hand. Its 512x512 RGBA derivative,
`mira-cast-01.png`, is registered as both Mira's action fallback and `attack`
animation. The current presentation controller therefore selects it for spell
casts and returns to the idle loop afterward.

`mira-guard-01-source.png` completes Mira's initial presentation-state set.
The pose retains the closed spellbook as a defensive focus, lowers her stance,
and pulls both arms inward without adding an attacker, damage, or magic. Its
512x512 RGBA derivative, `mira-guard-01.png`, is registered as Mira's `guard`
animation, so receiving a hit now triggers a character-specific reaction before
returning to idle.

## Kael anchor frame

Kael now follows the same one-pose-per-file production workflow. His approved
full-resolution anchor, `source-art/generated/character-frames/kael-v01/kael-idle-01-source.png`,
uses the detailed portrait as the identity authority and the older candidate
sheet only as an equipment-and-silhouette reference. The frame establishes his
scarred face, dark beard, gray-brown fur mantle, muted forest-green scarf,
battered plate, tall shield, and compact warhammer as reproducible landmarks.

The 512x512 RGBA runtime derivative lives at
`godot/assets/sprites/units/kael-hd2d-v01/kael-idle-01.png`. Both Kael's idle
and temporary action fallback point to this asset, and the registry exposes it
as a one-frame idle animation. Later poses should be generated from this anchor
rather than cropped from the overlapping candidate sheet.

`kael-idle-02-source.png` is an identity-preserving breathing edit of that
anchor. Its 512x512 RGBA derivative, `kael-idle-02.png`, keeps the boots and
ground line stable while limiting motion to the armored chest, fur mantle,
scarf, cloak folds, and a slight inward shield tilt. The registry now exposes
both frames as Kael's looping idle animation.

## Current placeholders and risks

- Pixel sheets are candidate source art, not production atlases.
- Portrait crops require browser review at roster, dialogue, and forecast sizes.
- Orren's large encounter portrait may need a focal crop after visual testing.
- No combat rules, story progression, or save data were changed.

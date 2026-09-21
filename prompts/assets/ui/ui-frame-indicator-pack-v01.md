# UI Frame and Indicator Pack v01

- Asset ID: `ui-frame-indicator-pack`
- Intended use: battle HUD framing and optional team markers
- Generation tool: image generator or vector workflow
- Generation date: fill at generation time
- Status: prompt-ready

## Prompt

Create an original modular UI pack for a dark manuscript-inspired tactical RPG. Materials are charcoal stone, oxidized iron, parchment insets, and hairline pale-gold repair. Ornament is sparse and never competes with combat information. Produce separate transparent assets for command frame, turn-order frame, unit-card frame, tooltip frame, player unit indicator, and enemy unit indicator.

Frames should support nine-slice use with clean stretchable center regions and readable corners at 1x browser scale. Unit indicators are separate 64 × 64 transparent assets: player uses an upward open chevron with iron-blue core; enemy uses a downward split chevron with ember-rust core. Team state must read by geometry in grayscale.

## File names

Use `ui-{surface}-frame-v01.png` for frames and `ui-unit-indicator-{player|enemy}-v01.png` for markers.

## Exclusions

No text, icons inside frames, glossy mobile UI, ornate filigree covering content, pure-black crushed detail, modern sci-fi geometry, or opaque canvas background.

## Review checklist

- Nine-slice centers are clean and stretchable
- Indicators remain readable at 18 px runtime size
- Player and enemy shapes differ without color
- Palette matches Forgotten Field without blending into it

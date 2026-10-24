# Tactical Overlays v01

- Asset ID: `ui-tactical-overlay`
- Intended use: grid selection, movement, attack, ability, and blocked states
- Generation tool: image generator or vector-to-PNG workflow
- Generation date: fill at generation time
- Status: prompt-ready

## Prompt

Create five transparent tactical overlay assets for a dark manuscript-inspired isometric strategy game. Every overlay is an exact 96 × 48 diamond with an empty transparent center, crisp outer edge, and restrained engraved-rune detail. The states must be distinguishable by shape and pattern as well as color: selected uses a double pale-gold ring, move uses cyan corner ticks, attack uses ember-red inward chevrons, ability uses violet broken arcs, blocked uses gray cross-hatching. High contrast at browser scale, clean antialiasing, no text.

Export each state separately as `ui-tactical-overlay-{selected|move|attack|ability|blocked}-v01.png`.

## Exclusions

No terrain texture, unit art, labels, numbers, opaque fill, rectangular border, drop shadow outside the diamond, neon sci-fi HUD, or particles beyond the canvas.

## Review checklist

- Exact 96 × 48 canvas and corner alignment
- State remains identifiable in grayscale
- Transparent center preserves terrain readability
- No edge cropping when pulsed to 1.2 scale

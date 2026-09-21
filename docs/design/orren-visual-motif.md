# Orren Visual Motif

## Purpose

Orren should become recognizable before the player consciously decides he matters.

His presentation therefore uses three repeated cues:

1. **Green lantern** — the fastest visual recognition cue.
2. **Silver map case** — the object that survives his disappearance.
3. **Soft navigation chime** — a quiet recurring audio cue whenever Orren himself is present.

The Empty Stair removes the first and third cues before the prose explains anything.

## Visual identity

### Orren

Current placeholder portrait direction:

- grounded human traveler, not ornate hero art;
- charcoal travel clothes;
- muted silver hardware;
- a narrow green accent rather than a full green costume;
- the lantern glow should be more recognizable than his face at small sizes.

The placeholder is deliberately original vector art and can later be replaced by a higher-detail portrait without changing any runtime IDs.

### Green lantern

The lantern is the attachment cue.

Use it:

- on Orren-present Wanderer route nodes after the player has met him;
- in Orren encounter presentation;
- with a very slow alpha pulse rather than a bright VFX loop.

Do not use the lantern as a general Wanderer icon.

### Silver map case

The map case is Orren's continuity object.

Before Grief it appears beside the lantern.

At the Empty Stair it becomes the only strong Orren object left on screen.

After Grief it can continue to represent copied routes and inherited knowledge without implying that Orren himself remains.

## Audio motif

The runtime cue ID is `orren_motif`.

For now it intentionally reuses the existing soft navigation sound at low volume rather than adding a new binary audio asset.

Play it for:

- first;
- sacrifice;
- attachment;
- last_seen;
- same-run interlude.

Do **not** play it for:

- absence;
- after_grief.

The missing sound is part of the reveal.

A future original two- or three-note motif can replace the source asset behind the stable `orren_motif` ID.

## Empty Stair reveal order

The encounter should communicate absence in this order:

1. Route node no longer shows the green lantern. It shows the silver map case.
2. Entering the encounter produces no Orren chime.
3. The portrait space is empty.
4. The lantern slot is dark.
5. The map case remains fully visible.
6. Only then does the title and prose explain the Empty Stair.

The text therefore no longer begins by explicitly stating that the lantern is missing.

The player should ideally notice the problem before reading it.

## Runtime ownership

- Assets: `godot/assets/characters/`, `godot/assets/ui/`
- Asset IDs: `godot/scripts/data/AssetRegistry.gd`
- Presentation rules: `godot/scripts/story/OrrenPresentation.gd`
- Encounter UI: `godot/scripts/ui/StageSelect.gd`
- Audio cue ID: `godot/scripts/systems/AudioSettings.gd`
- Presentation validation: `godot/tests/test_orren_presentation.gd`

## Known placeholders

- Orren portrait is a vector placeholder, not final character art.
- The audio cue reuses an existing UI sound.
- There is no bespoke animation beyond the lantern pulse.
- The Empty Stair does not yet have a dedicated illustrated environment background.

These placeholders are intentional. The recognition loop should be validated before spending time on final art.

## Next evolution

If playtesting confirms players begin noticing the lantern automatically:

1. replace the portrait with final original character art;
2. create a dedicated original Orren audio motif;
3. give the Empty Stair a bespoke environmental illustration;
4. preserve the same stable asset and cue IDs so story code does not change.

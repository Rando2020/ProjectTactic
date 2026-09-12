# Ashvale Cinematic Battle UI

## Goal

Move ProjectTactic's live battle presentation toward the approved Ashvale target image without replacing the combat systems that already work.

The battle should read as a dark tactical diorama with clear information zones:

- party roster on the left,
- turn order across the top,
- mission and objective framing top-right,
- enemy intent on the right,
- primary commands bottom-left,
- ability choices bottom-center,
- terrain/context information bottom-right,
- forecast information centered over the battlefield only when relevant.

## Architecture

`CinematicBattleUI.gd` subclasses the existing `BattleUI.gd`.

This is intentional. `BattleUI.gd` remains the functional source of truth for:

- Move / Attack / Ability / Wait callbacks,
- confirm and cancel flow,
- keyboard shortcuts,
- enemy intent formatting,
- forecast data,
- battle-state labels,
- settings,
- victory/spoils flow,
- BattleManager signal connections.

The cinematic layer calls the base builder, reparents the existing live controls into a new layout, and adds a read-only party roster. It does not create a second command state machine.

## Visual direction

Target mood:

- charcoal/black translucent panels,
- restrained antique-gold borders,
- warm cream typography,
- cyan/blue player accents,
- orange/red threat accents,
- Trajan-style display typography,
- large unobstructed battlefield center,
- information density around the edges rather than over the units.

This is intended to complement the Ashvale 3D terrain backdrop and existing isometric unit sprites.

## Current implementation

- Four-character party roster with portrait/sprite preview, job label, HP and MP.
- Active party member receives a brighter blue border.
- Existing turn-order slots moved into a top-center strip.
- Existing mission/phase/objective labels moved to a top-right mission card.
- Existing enemy intent panel moved to a dedicated right-side threat area.
- Existing command buttons moved into a vertical bottom-left command panel.
- Existing ability selector moved into a bottom-center ability area.
- Existing terrain hover information moved into a bottom-right field-read card.
- Existing forecast, settings, victory/spoils and intro-banner systems retained and repositioned.

## Guardrails

- Do not fork command logic.
- Do not change combat balance as part of UI work.
- Do not make tactical overlays harder to read for visual polish.
- Do not hide enemy intent information behind animation or hover-only interactions.
- Keep keyboard shortcuts functional.
- Preserve a straightforward rollback to `BattleUI.gd` if the cinematic shell causes usability problems.

## Next visual passes

1. Generate/replace dedicated portrait art rather than reusing battlefield sprites where necessary.
2. Convert the ability selector from a vertical list into compact icon cards after the shell is validated.
3. Add dedicated command and ability icons.
4. Improve field-read cards with terrain thumbnail, height, movement cost and tactical effects.
5. Add responsive breakpoints for smaller browser windows.
6. Run browser playtesting for clickability, readability and battlefield occlusion before merging.

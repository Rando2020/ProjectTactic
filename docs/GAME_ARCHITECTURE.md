# Project Tactics Architecture

Project Tactics is moving toward a data-driven tactical RPG prototype. The current playable focus is the Godot grasslands demo in `godot/`, with the original C++ prototype kept as a reference path.

## Runtime Layers

### Data

Location: `godot/data/`

The game should treat jobs, abilities, encounters, statuses, equipment, surfaces, and progression as editable data. The first demo already loads:

- `main_characters.json`
- `jobs.json`
- `abilities.json`
- `first_grassy_field.json`
- `status_effects.json`
- `surfaces.json`
- `surface_reactions.json`
- `equipment.json`
- `progression.json`
- `ai_profiles.json`

### Battle Rules

Location: `godot/scripts/battle/`

- `PTGridMath.gd`: tile ids, rows/columns, isometric projection, distance.
- `PTPathfinder.gd`: movement range using terrain cost, occupancy, and jump limits.
- `PTBattleMath.gd`: original damage, healing, height bonus, and CT helpers.
- `PTCombatResolver.gd`: target validation and ability effect resolution.
- `PTStatusEffectSystem.gd`: status application, duration ticks, and movement modifiers.
- `PTSurfaceSystem.gd`: surface ticks and surface reaction hooks.

### AI

Location: `godot/scripts/ai/`

- `PTEnemyAI.gd`: picks a target, chooses an available ability, moves toward range, then follows up.

### Presentation Hooks

Locations:

- `godot/scripts/vfx/PTBattleVFX.gd`
- `godot/scripts/audio/PTBattleAudio.gd`
- `godot/scripts/ui/PTBattleHUD.gd`

These are intentionally small. The gameplay can now call VFX/audio/UI hooks without waiting for final art, sound, or a polished HUD.

## Current Demo

Scene: `godot/scenes/Main.tscn`

Main script: `godot/scripts/TacticsBattle.gd`

The grasslands battle now supports:

- Six player units.
- Five enemy units.
- Job-linked ability lists.
- MP costs.
- Damage and healing based on unit stats, ability power, guard, and height.
- Status application and status ticks.
- Enemy movement and ability selection.
- Movement range that respects walkability, occupancy, terrain cost, and jump.
- Floating damage/heal text and tile flashes.

## Clean-Room Direction

References from classic tactics games should guide categories, pacing, and user expectations. Project Tactics should keep original names, stats, formulas, art, story, and data.

Good inspirations to keep abstract:

- Charge-based turn pressure.
- Job and ability progression.
- Height-aware grid tactics.
- Facing, flanking, and follow-up opportunities.
- Action-point-like choices.
- Surface and environmental reactions.

Avoid:

- Proprietary assets.
- Exact tables, scripts, text, maps, classes, or formulas.
- Decompilation-derived code.

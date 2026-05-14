# Project Tactics Godot Prototype

This folder is a Godot 4 prototype that uses the generated Project-Tactics assets and
the same JSON data shape as the C++ prototype.

## Open

1. Open Godot 4.x.
2. Choose **Import**.
3. Select `godot/project.godot`.
4. Run the project.

Godot was not available on PATH in the Codex environment, so this project was scaffolded
but not launched here.

## Current Controls

- Click a player unit to select it.
- Click **Move**, then click a highlighted tile.
- Click **Attack** or a hostile skill, then click an enemy in range.
- Click a heal/support skill, then click an ally in range.
- Hover skill buttons to see their mapped VFX and SFX IDs.
- End each unit turn; enemies will move and use abilities when the party is done.

## Architecture

- `scripts/battle/PTGridMath.gd`: tile ids, distance, and isometric projection.
- `scripts/battle/PTPathfinder.gd`: movement range with terrain, jump, and occupancy.
- `scripts/battle/PTBattleMath.gd`: original combat/healing formulas.
- `scripts/battle/PTCombatResolver.gd`: target validation and ability results.
- `scripts/battle/PTStatusEffectSystem.gd`: status application and ticking.
- `scripts/battle/PTSurfaceSystem.gd`: surface ticks and reaction hooks.
- `scripts/ai/PTEnemyAI.gd`: enemy target/action choice.
- `scripts/data/PTGameDatabase.gd`: JSON loading helpers.
- `scripts/vfx/PTBattleVFX.gd`: tile flashes and floating text.
- `scripts/audio/PTBattleAudio.gd`: placeholder SFX hook.
- `scripts/ui/PTBattleHUD.gd`: reusable HUD shell for the next UI pass.

## Data

- `data/first_grassy_field.json`: first encounter map, tile heights, terrain, and spawns.
- `data/main_characters.json`: player unit loadouts.
- `data/jobs.json`: job/class definitions.
- `data/abilities.json`: skill definitions mapped to icon, VFX, and SFX IDs.
- `data/status_effects.json`: statuses like guarded, slowed, marked, poisoned.
- `data/surfaces.json`: surface rules for mud, ember, and spark.
- `data/equipment.json`: first equipment table.
- `data/progression.json`: level and job-point pacing model.

## Art

- `assets/tiles`: generated isometric terrain tiles.
- `assets/tokens`: generated unit/enemy tokens.
- `assets/sheets`: generated source sheets for terrain, units, UI, and VFX.

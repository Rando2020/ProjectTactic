# Content Pipeline

## Content philosophy
All combat, story, town, quest, enemy, item, job, and map content should be data-driven wherever possible.

## Recommended workflow
1. Write the design in docs.
2. Add the data object.
3. Validate the object with simple helper functions.
4. Render the content in a generic component.
5. Only then add custom UI polish.

## Data file ownership
- `data/maps.js`: battlefields, spawns, objectives, rewards.
- `data/terrain.js`: tile behavior, movement cost, elemental reactions.
- `data/units.js`: player units and recruits.
- `data/jobs.js`: job roles, unlocks, passives, abilities.
- `data/abilities.js`: tactical actions and targeting rules.
- `data/enemies.js`: enemy stats, AI profiles, drops.
- `data/items.js`: consumables and key items.
- `data/equipment.js`: weapons, armor, accessories.
- `data/story.js`: chapter beat structure.
- `data/quests.js`: objectives, rewards, flags.
- `data/towns.js`: world map/town content.
- `data/factions.js`: trust, reputation, consequences.
- `data/glossary.js`: lore and system terms.

## Content naming rules
Use snake_case IDs and readable display names.

Examples:
- `ashvale_road_01`
- `mirefen_reaction_trial`
- `sunder_strike`
- `null_drake`

## Asset naming rules
Use stable IDs that match data whenever possible.

Examples:
- `portrait_zane.png`
- `unit_null_drake_idle.png`
- `tile_shallow_water.png`
- `icon_thunder.svg`

## Acceptance checklist for new content
- Has stable ID.
- Has display name.
- Has clear player-facing purpose.
- Has unlock requirements if not available by default.
- Has test scenario or debug path.
- Does not use copyrighted names or assets.

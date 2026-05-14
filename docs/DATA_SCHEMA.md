# Data Schema Notes

These are lightweight schemas for the current JSON files. They are meant to help keep content creation consistent as more battles are added.

## Character

File: `godot/data/main_characters.json`

Required:

- `name`
- `avatarId`
- `jobId`
- `abilityIds`
- `hp`
- `mp`
- `move`
- `jump`
- `speed`

Recommended:

- `attack`
- `defense`
- `spirit`
- `level`
- `xp`

## Job

File: `godot/data/jobs.json`

Required:

- `id`
- `name`
- `spriteId`
- `baseHp`
- `baseMp`
- `move`
- `jump`
- `speed`
- `abilityIds`

## Ability

File: `godot/data/abilities.json`

Required:

- `id`
- `name`
- `category`
- `range`
- `area`
- `mpCost`
- `power`
- `description`
- `vfxId`
- `sfxId`

Optional:

- `appliesStatuses`
- `createsSurface`
- `chargeDelay`
- `cooldown`

Current categories:

- `Melee`
- `Ranged`
- `Magic`
- `Control`
- `Debuff`
- `Heal`
- `Support`
- `Guard`
- `Mobility`

## Encounter

File example: `godot/data/first_grassy_field.json`

Required:

- `name`
- `objective`
- `grid`
- `tiles`
- `players`
- `enemies`

Each tile:

- `tile`
- `terrain`
- `height`
- `walkable`

Optional tile fields:

- `moveCost`
- `surface`
- `cover`

Each enemy can override:

- `hp`
- `mp`
- `attack`
- `defense`
- `spirit`
- `aiProfile`

## Status Effect

File: `godot/data/status_effects.json`

Fields:

- `name`
- `description`
- `moveModifier`
- `tickDamage`

## Surface

File: `godot/data/surfaces.json`

Fields:

- `name`
- `moveCost`
- `tickDamage`
- `appliesStatus`

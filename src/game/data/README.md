# Game Data

This folder is for static game content extracted from the prototype.

Recommended modules:

- `elements.js` - element colors, icons, timing profile keys.
- `statuses.js` - status definitions and resistance metadata.
- `reactions.js` - elemental surface reaction table.
- `combos.js` - 2-way and 3-way combo definitions.
- `guardians.js` - Guardian summon data and unlock requirements.
- `jobs.js` - base jobs, ascended jobs, skills, passives, JP requirements.
- `items.js` - consumables and inventory metadata.
- `enemies.js` - wave enemies, boss stats, enemy AI tags.
- `party.js` - playable character defaults.

Rule: data files should not mutate state or contain React components.

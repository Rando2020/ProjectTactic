# Ashvale UI Asset Polish

This pass converts the cinematic battle shell into a more authored game HUD without changing battle rules.

## Added assets

- Dedicated original portrait SVGs for Zane, Mira, Kael, and Lyra.
- Original command icons for Move, Attack, Ability, Item, and Wait.
- Original field-read thumbnails for grass, road, stone, water, high ground, and scorched terrain.

All assets are original ProjectTactic placeholders and use lowercase kebab-case names.

## Runtime integration

`PolishedCinematicBattleUI.gd` subclasses `CinematicBattleUI.gd` and preserves the existing `BattleUI.gd` command/state wiring.

It adds:

- dedicated roster portraits,
- icon-backed command buttons,
- horizontal ability cards with element, MP, range, and area information,
- individual enemy intent cards with enemy art when available,
- a visual terrain read card with tile thumbnail and parsed height/movement metadata.

`Battle.tscn` mounts the polished subclass. The class can be reverted to `CinematicBattleUI.gd` without changing combat or save data.

## Evolution

The SVG portraits are production-safe original placeholders, not final illustration targets. They intentionally establish stable paths and presentation framing so later painted portraits can replace them without UI code changes.

Future polish should focus on browser visual acceptance, final character portrait illustration, richer ability-specific icons, and VFX/readability tuning rather than another HUD architecture rewrite.

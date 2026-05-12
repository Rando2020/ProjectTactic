# Tile Manifest

This manifest tracks the first legally safe placeholder tile set for the tactical board.

## Naming Rules

- Use lowercase kebab-case.
- Include material or terrain type.
- Include `tile` in the name.
- Use `placeholder` until final art is approved.

Example:

```text
forest-grass-tile-placeholder.png
```

## Starter Terrain Set

| Tile ID | Asset Name | Gameplay Use | Priority |
|---|---|---|---|
| grass | forest-grass-tile-placeholder.png | Default lowland ground | High |
| road | dirt-road-tile-placeholder.png | Fast readable pathing | High |
| stone | worn-stone-tile-placeholder.png | Stable defensive terrain | High |
| high_ground | raised-stone-tile-placeholder.png | Height advantage | High |
| wall | ruined-wall-tile-placeholder.png | Blocking terrain | High |
| shrine | ether-shrine-tile-placeholder.png | Arcane defense and story flavor | High |
| shallow_water | shallow-water-tile-placeholder.png | Wet and conductive reactions | High |
| deep_water | deep-water-tile-placeholder.png | Blocked water | Medium |
| ice | frozen-ground-tile-placeholder.png | Frozen reaction terrain | Medium |
| burning | burning-ground-tile-placeholder.png | Fire hazard terrain | Medium |
| cursed | cursed-earth-tile-placeholder.png | Null corruption hazard | Medium |
| stairs | stone-stairs-tile-placeholder.png | Height transitions | Medium |
| bridge | wood-bridge-tile-placeholder.png | Marsh and town maps | Medium |
| market_road | market-road-tile-placeholder.png | Town maps | Low |
| inn_floor | inn-wood-floor-tile-placeholder.png | Town interiors | Low |

## Next Implementation Step

Create a data-to-asset map in `src/game/data/assets.js` so terrain IDs can resolve to placeholder art without hardcoding asset paths inside components.

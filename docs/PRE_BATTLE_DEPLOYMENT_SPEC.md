# Pre-Battle Deployment Specification

## Intent
Before a tactical battle begins, the player should choose which units deploy, where they stand, and which direction they face. This mirrors classic tactical RPG preparation while supporting modern clarity and map-specific strategy.

## Player flow
1. Open mission briefing.
2. Review objective, enemy hints, terrain notes, and max party size.
3. Enter deployment screen.
4. Select a roster unit.
5. Place the unit on a valid deployment tile.
6. Rotate facing.
7. Validate required units and party size.
8. Start battle.

## Map metadata
Each battle map can define deployment rules:

```js
{
  maxPartySize: 3,
  requiredUnitIds: ['zane'],
  recommendedUnitIds: ['zane', 'mira', 'kael'],
  deployment: {
    label: 'Mirefen Marsh Entry',
    briefing: 'Choose whether to cluster near the dry path or split across the reeds.',
    defaultFacing: 'N',
    zones: [
      {
        id: 'dry_bank',
        name: 'Dry Bank',
        tiles: [{ x: 1, y: 6 }, { x: 2, y: 6 }]
      }
    ]
  }
}
```

## Validation rules
- Required units must be deployed.
- Deployed units cannot exceed `maxPartySize`.
- Units must be placed on valid deployment tiles.
- Only one unit may occupy a deployment tile.
- Facing must be one of `N`, `E`, `S`, or `W`.

## UX rules
- Valid deployment tiles should be highlighted before placement.
- Placed units should show facing direction.
- Required units should be labeled clearly.
- Invalid deployment state should block battle start and show the reason.
- The player should be able to remove optional units before starting.

## Future enhancements
- Equipment change from deployment screen.
- Job change from deployment screen.
- Recommended formation button.
- Enemy preview toggle.
- Terrain threat overlay.
- Save deployment presets per mission.

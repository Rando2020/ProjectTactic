# Tactical Grid Specification

## Grid basics
- Default vertical slice map size: 10 columns by 8 rows.
- Coordinates use `{ x, y }`, with `{0,0}` in the top-left.
- Each tile has terrain, height, tags, and optional occupant.
- Height impacts line of sight, ranged attacks, jump limits, and damage bonuses.

## Tile schema
```js
{
  x: 0,
  y: 0,
  terrain: 'grass',
  height: 0,
  tags: ['natural'],
  hazard: null,
  occupantId: null
}
```

## Movement
Movement is calculated by pathfinding cost, not raw distance.

Rules:
- A unit may move up to `unit.stats.move` cost.
- A tile may be blocked by terrain or an occupant.
- A height change above `unit.stats.jump` is blocked.
- Terrain can increase or reduce movement cost.

## Facing
Each unit has one of four facings: `north`, `east`, `south`, `west`.

Facing modifiers:
- Front attack: normal accuracy and damage.
- Side attack: moderate accuracy bonus.
- Back attack: higher accuracy and damage bonus.

## Targeting
Every ability must define:
- Range type: self, adjacent, weapon, line, arc, radius, global.
- Minimum range.
- Maximum range.
- Area of effect shape.
- Height tolerance.
- Target allegiance: self, ally, enemy, tile, any.

## Enemy intent
Enemy intent should be previewed before the enemy acts. The player should see:
- Which unit is targeted.
- Which tiles are threatened.
- Expected damage range.
- Status risk.

## Undo policy
- Player may undo movement before confirming an action.
- Player may not undo after damage or RNG resolution unless battle rewind is enabled.
- Battle rewind is a separate system and should preserve prior game states.

import { keyOf } from '../systems/grid.js'

export default function BattleGrid({ map, grid = [], units = [], highlightedTiles = [], selectedUnitId, onSelectTile, onSelectUnit }) {
  const highlightKeys = new Set(highlightedTiles.map((tile) => keyOf(tile.x, tile.y)))
  const unitByTile = new Map(units.filter((unit) => unit.hp > 0).map((unit) => [keyOf(unit.x, unit.y), unit]))

  return (
    <section style={{ ...styles.grid, gridTemplateColumns: `repeat(${map.size.width}, 54px)` }}>
      {grid.map((tile) => {
        const unit = unitByTile.get(keyOf(tile.x, tile.y))
        const isHighlighted = highlightKeys.has(keyOf(tile.x, tile.y))
        const isSelected = unit?.id === selectedUnitId
        return (
          <button
            key={keyOf(tile.x, tile.y)}
            type="button"
            style={{
              ...styles.tile,
              ...terrainStyle(tile.terrain),
              outline: isSelected ? '3px solid #ffd86b' : isHighlighted ? '2px solid #7bdcff' : '1px solid rgba(255,255,255,0.12)',
              transform: `translateY(${-4 * (tile.height || 0)}px)`
            }}
            onClick={() => unit ? onSelectUnit?.(unit) : onSelectTile?.(tile)}
            title={`${tile.x},${tile.y} ${tile.terrain} h${tile.height || 0}`}
          >
            <span style={styles.coord}>{tile.x},{tile.y}</span>
            {unit && (
              <span style={{ ...styles.unit, borderColor: unit.team === 'player' ? '#7bdcff' : '#ff6b6b' }}>
                {unit.name.slice(0, 1)}
              </span>
            )}
          </button>
        )
      })}
    </section>
  )
}

function terrainStyle(terrain) {
  const stylesByTerrain = {
    grass: { background: 'linear-gradient(135deg, #21482d, #173321)' },
    road: { background: 'linear-gradient(135deg, #5f4c36, #3b2f24)' },
    stone: { background: 'linear-gradient(135deg, #5c6270, #353946)' },
    shrine: { background: 'linear-gradient(135deg, #40315f, #17152a)' },
    shallow_water: { background: 'linear-gradient(135deg, #126c8a, #093f5a)' },
    deep_water: { background: 'linear-gradient(135deg, #06324f, #031a2d)' },
    ice: { background: 'linear-gradient(135deg, #9fdcff, #4f91c1)' },
    burning: { background: 'linear-gradient(135deg, #9f341b, #421107)' },
    electrified_water: { background: 'linear-gradient(135deg, #198ab3, #b89420)' },
    wall: { background: 'linear-gradient(135deg, #1f2230, #0a0b13)' },
    high_ground: { background: 'linear-gradient(135deg, #6f6a56, #3d3a2e)' },
    void_anchor: { background: 'linear-gradient(135deg, #4d1c71, #12071c)' }
  }
  return stylesByTerrain[terrain] || stylesByTerrain.grass
}

const styles = {
  grid: {
    display: 'grid',
    gap: 6,
    padding: 18,
    borderRadius: 24,
    background: 'rgba(0,0,0,0.28)',
    border: '1px solid rgba(255,255,255,0.12)',
    boxShadow: '0 24px 80px rgba(0,0,0,0.38)',
    overflow: 'auto'
  },
  tile: {
    position: 'relative',
    width: 54,
    height: 54,
    border: 0,
    borderRadius: 10,
    color: 'white',
    cursor: 'pointer',
    transition: 'transform 120ms ease, outline 120ms ease, filter 120ms ease'
  },
  coord: {
    position: 'absolute',
    left: 5,
    top: 4,
    fontSize: 9,
    color: 'rgba(255,255,255,0.55)',
    fontVariantNumeric: 'tabular-nums'
  },
  unit: {
    position: 'absolute',
    inset: 10,
    display: 'grid',
    placeItems: 'center',
    borderRadius: 999,
    border: '2px solid white',
    background: 'rgba(5, 7, 20, 0.9)',
    fontWeight: 900,
    boxShadow: '0 8px 20px rgba(0,0,0,0.35)'
  }
}

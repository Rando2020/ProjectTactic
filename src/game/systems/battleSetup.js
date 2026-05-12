import { getBattleMap } from '../data/maps.js'
import { instantiatePlayerUnit } from '../data/units.js'
import { instantiateEnemy } from '../data/enemies.js'
import { buildGrid } from './grid.js'
import { initializeTimeline } from './turnOrder.js'

export function createBattleState(mapId = 'ashvale_road_01') {
  const map = getBattleMap(mapId)
  if (!map) throw new Error(`Unknown battle map: ${mapId}`)

  const grid = buildGrid(map)
  const players = (map.playerSpawns || []).map((spawn) => instantiatePlayerUnit(spawn.unitId, spawn)).filter(Boolean)
  const enemies = (map.enemySpawns || []).map((spawn) => instantiateEnemy(spawn.unitId, spawn)).filter(Boolean)
  const units = initializeTimeline([...players, ...enemies])

  return {
    id: `${map.id}_run_${Date.now()}`,
    phase: 'battle',
    map,
    grid,
    units,
    selectedUnitId: null,
    activeUnitId: null,
    selectedAbilityId: 'basic_attack',
    highlightedTiles: [],
    combatLog: [`Battle started: ${map.name}`],
    turnNumber: 1,
    result: 'ongoing'
  }
}

export function appendBattleLog(state, message) {
  return {
    ...state,
    combatLog: [...(state.combatLog || []), message].slice(-12)
  }
}

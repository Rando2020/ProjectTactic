import { getBattleMap } from '../data/maps.js'
import { instantiatePlayerUnit } from '../data/units.js'
import { instantiateEnemy } from '../data/enemies.js'
import { buildGrid, keyOf } from './grid.js'
import { initializeTimeline } from './turnOrder.js'

export const FACINGS = ['N', 'E', 'S', 'W']

export function getDeploymentTiles(map) {
  return (map.deployment?.zones || [])
    .flatMap((zone) => zone.tiles.map((tile) => ({ ...tile, zoneId: zone.id, zoneName: zone.name })))
}

export function getDeploymentTileKeys(map) {
  return new Set(getDeploymentTiles(map).map((tile) => keyOf(tile.x, tile.y)))
}

export function getDefaultDeployment(map) {
  const availableTiles = getDeploymentTiles(map)
  const unitIds = map.recommendedUnitIds || map.playerSpawns?.map((spawn) => spawn.unitId) || []
  const maxPartySize = map.maxPartySize || unitIds.length

  return unitIds.slice(0, maxPartySize).map((unitId, index) => {
    const defaultSpawn = map.playerSpawns?.find((spawn) => spawn.unitId === unitId)
    const tile = availableTiles[index] || defaultSpawn || availableTiles[0]
    return {
      unitId,
      x: tile?.x ?? defaultSpawn?.x ?? 0,
      y: tile?.y ?? defaultSpawn?.y ?? 0,
      facing: defaultSpawn?.facing || map.deployment?.defaultFacing || 'N'
    }
  })
}

export function validateDeployment(map, deployment = []) {
  const errors = []
  const deploymentTileKeys = getDeploymentTileKeys(map)
  const requiredUnitIds = map.requiredUnitIds || []
  const maxPartySize = map.maxPartySize || deployment.length
  const occupied = new Set()

  if (deployment.length > maxPartySize) {
    errors.push(`Too many units deployed. Max party size is ${maxPartySize}.`)
  }

  for (const requiredUnitId of requiredUnitIds) {
    if (!deployment.some((slot) => slot.unitId === requiredUnitId)) {
      errors.push(`${requiredUnitId} is required for this mission.`)
    }
  }

  for (const slot of deployment) {
    const tileKey = keyOf(slot.x, slot.y)
    if (!deploymentTileKeys.has(tileKey)) {
      errors.push(`${slot.unitId} is outside the deployment zone.`)
    }
    if (occupied.has(tileKey)) {
      errors.push(`Multiple units are assigned to tile ${tileKey}.`)
    }
    occupied.add(tileKey)
    if (!FACINGS.includes(slot.facing)) {
      errors.push(`${slot.unitId} has invalid facing ${slot.facing}.`)
    }
  }

  return { valid: errors.length === 0, errors }
}

export function assignUnitToDeploymentTile({ map, deployment, unitId, tile, facing }) {
  const deploymentTileKeys = getDeploymentTileKeys(map)
  const tileKey = keyOf(tile.x, tile.y)
  if (!deploymentTileKeys.has(tileKey)) return deployment

  const withoutTileOccupant = deployment.filter((slot) => keyOf(slot.x, slot.y) !== tileKey || slot.unitId === unitId)
  const existing = withoutTileOccupant.find((slot) => slot.unitId === unitId)

  if (existing) {
    return withoutTileOccupant.map((slot) =>
      slot.unitId === unitId
        ? { ...slot, x: tile.x, y: tile.y, facing: facing || slot.facing || map.deployment?.defaultFacing || 'N' }
        : slot
    )
  }

  if (withoutTileOccupant.length >= (map.maxPartySize || Infinity)) return withoutTileOccupant

  return [
    ...withoutTileOccupant,
    { unitId, x: tile.x, y: tile.y, facing: facing || map.deployment?.defaultFacing || 'N' }
  ]
}

export function rotateDeploymentFacing(deployment, unitId) {
  return deployment.map((slot) => {
    if (slot.unitId !== unitId) return slot
    const currentIndex = FACINGS.indexOf(slot.facing)
    return { ...slot, facing: FACINGS[(currentIndex + 1) % FACINGS.length] }
  })
}

export function createBattleStateFromDeployment(mapId, deployment) {
  const map = getBattleMap(mapId)
  if (!map) throw new Error(`Unknown battle map: ${mapId}`)

  const validation = validateDeployment(map, deployment)
  if (!validation.valid) {
    throw new Error(`Invalid deployment: ${validation.errors.join(' ')}`)
  }

  const grid = buildGrid(map)
  const players = deployment.map((slot) => instantiatePlayerUnit(slot.unitId, slot)).filter(Boolean)
  const enemies = (map.enemySpawns || []).map((spawn) => instantiateEnemy(spawn.unitId, spawn)).filter(Boolean)
  const units = initializeTimeline([...players, ...enemies])

  return {
    id: `${map.id}_run_${Date.now()}`,
    phase: 'battle',
    map,
    grid,
    units,
    selectedUnitId: players[0]?.id || null,
    activeUnitId: null,
    selectedAbilityId: 'basic_attack',
    highlightedTiles: [],
    combatLog: [`Deployment complete: ${map.name}`],
    turnNumber: 1,
    result: 'ongoing'
  }
}

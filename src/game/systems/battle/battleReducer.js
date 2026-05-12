import { buildGrid, getTile } from '../grid.js'
import { advanceCtUntilReady, buildTurnTimeline, finishUnitTurn, normalizeTurnUnits } from './turnOrder.js'
import { getMovementRange, isTileInMovementRange } from './movementRange.js'
import { applyAttackPreview, getAttackDamagePreview, isAttackTargetInRange } from './damagePreview.js'

export const BATTLE_PHASES = {
  BOOT: 'boot',
  COMMAND: 'command',
  TARGETING: 'targeting',
  RESOLVED: 'resolved',
}

function getUnit(units, unitId) {
  return units.find((unit) => unit.id === unitId)
}

function getActiveUnit(state) {
  return getUnit(state.units, state.activeUnitId)
}

function refreshTurnState(state, units = state.units) {
  const advanced = advanceCtUntilReady(units)
  const activeUnit = advanced.readyUnit

  return {
    ...state,
    units: advanced.units,
    activeUnitId: activeUnit?.id ?? null,
    selectedUnitId: activeUnit?.team === 'player' ? activeUnit.id : null,
    activeCommand: null,
    movementRange: [],
    damagePreview: null,
    targetId: null,
    phase: activeUnit ? BATTLE_PHASES.COMMAND : BATTLE_PHASES.BOOT,
    turnTimeline: buildTurnTimeline(advanced.units),
  }
}

export function createBattleState({ map, units }) {
  const normalizedUnits = normalizeTurnUnits(units).map((unit) => ({
    ...unit,
    ct: unit.ct ?? 0,
    hasMoved: false,
    hasActed: false,
    acted: false,
  }))

  return refreshTurnState({
    map,
    grid: buildGrid(map),
    units: normalizedUnits,
    activeUnitId: null,
    selectedUnitId: null,
    activeCommand: null,
    movementRange: [],
    damagePreview: null,
    targetId: null,
    turnTimeline: [],
    battleLog: ['Battle started. CT is charging.'],
    phase: BATTLE_PHASES.BOOT,
  }, normalizedUnits)
}

function addLog(state, message) {
  return {
    ...state,
    battleLog: [message, ...state.battleLog].slice(0, 8),
  }
}

function updateUnit(state, unitId, updater) {
  return {
    ...state,
    units: state.units.map((unit) => unit.id === unitId ? updater(unit) : unit),
  }
}

function finishActiveTurn(state, turnFlags = {}) {
  const activeUnit = getActiveUnit(state)
  if (!activeUnit) return refreshTurnState(state)

  const nextUnits = state.units.map((unit) => (
    unit.id === activeUnit.id
      ? finishUnitTurn(unit, { hasMoved: unit.hasMoved, hasActed: unit.hasActed, ...turnFlags })
      : unit
  ))

  return refreshTurnState({ ...state, units: nextUnits }, nextUnits)
}

function selectCommand(state, commandId) {
  const activeUnit = getActiveUnit(state)
  if (!activeUnit || activeUnit.team !== 'player') return state

  if (commandId === 'move') {
    if (activeUnit.hasMoved) return addLog(state, `${activeUnit.name} has already moved this turn.`)
    const movementRange = getMovementRange({ map: state.map, grid: state.grid, units: state.units, unit: activeUnit })
    return {
      ...state,
      selectedUnitId: activeUnit.id,
      activeCommand: 'move',
      movementRange,
      damagePreview: null,
      targetId: null,
      phase: BATTLE_PHASES.TARGETING,
    }
  }

  if (commandId === 'attack') {
    if (activeUnit.hasActed) return addLog(state, `${activeUnit.name} has already acted this turn.`)
    return {
      ...state,
      selectedUnitId: activeUnit.id,
      activeCommand: 'attack',
      movementRange: [],
      damagePreview: null,
      targetId: null,
      phase: BATTLE_PHASES.TARGETING,
    }
  }

  if (commandId === 'ability') {
    const nextState = addLog(state, `${activeUnit.name} readies a job ability. Job ability targeting is the next implementation layer.`)
    return finishActiveTurn(updateUnit(nextState, activeUnit.id, (unit) => ({ ...unit, hasActed: true })))
  }

  if (commandId === 'item') {
    const maxHp = activeUnit.stats?.hp ?? activeUnit.hp
    const nextState = updateUnit(state, activeUnit.id, (unit) => ({
      ...unit,
      hp: Math.min(maxHp, unit.hp + 120),
      hasActed: true,
    }))
    return finishActiveTurn(addLog(nextState, `${activeUnit.name} used a Vitae Draught placeholder.`))
  }

  if (commandId === 'wait') {
    return finishActiveTurn(addLog(state, `${activeUnit.name} waits.`), { waited: true })
  }

  return state
}

function moveActiveUnit(state, destination) {
  const activeUnit = getActiveUnit(state)
  if (!activeUnit || activeUnit.team !== 'player' || state.activeCommand !== 'move') return state

  const destinationTile = getTile(state.grid, destination.x, destination.y)
  if (!isTileInMovementRange(state.movementRange, destinationTile)) return state

  const nextState = updateUnit(state, activeUnit.id, (unit) => ({
    ...unit,
    x: destination.x,
    y: destination.y,
    facing: destination.facing ?? unit.facing,
    hasMoved: true,
  }))

  return addLog({
    ...nextState,
    activeCommand: null,
    movementRange: [],
    phase: BATTLE_PHASES.COMMAND,
  }, `${activeUnit.name} moved to ${destination.x},${destination.y}.`)
}

function previewAttack(state, targetId) {
  const activeUnit = getActiveUnit(state)
  const target = getUnit(state.units, targetId)
  if (!activeUnit || !target || target.team === activeUnit.team) return state
  if (!isAttackTargetInRange(activeUnit, target)) return addLog(state, `${target.name} is out of attack range.`)

  return {
    ...state,
    targetId,
    damagePreview: getAttackDamagePreview(activeUnit, target),
  }
}

function confirmAttack(state) {
  const activeUnit = getActiveUnit(state)
  const target = getUnit(state.units, state.targetId)
  const preview = state.damagePreview ?? getAttackDamagePreview(activeUnit, target)
  if (!activeUnit || !target || !preview) return state

  const nextState = {
    ...state,
    units: state.units.map((unit) => {
      if (unit.id === target.id) return applyAttackPreview(unit, preview)
      if (unit.id === activeUnit.id) return { ...unit, hasActed: true }
      return unit
    }),
    activeCommand: null,
    damagePreview: null,
    targetId: null,
    phase: BATTLE_PHASES.RESOLVED,
  }

  const resultText = preview.willDefeat
    ? `${activeUnit.name} defeats ${target.name} for ${preview.hpDamage} HP damage.`
    : `${activeUnit.name} hits ${target.name} for ${preview.hpDamage} HP damage and strips ${preview.armorBreak} Temper.`

  return finishActiveTurn(addLog(nextState, resultText))
}

function runEnemyTurn(state) {
  const activeUnit = getActiveUnit(state)
  if (!activeUnit || activeUnit.team !== 'enemy') return state

  const livingPlayers = state.units.filter((unit) => unit.team === 'player' && unit.hp > 0)
  if (!livingPlayers.length) return finishActiveTurn(addLog(state, `${activeUnit.name} has no targets.`), { waited: true })

  const adjacentTarget = livingPlayers.find((unit) => isAttackTargetInRange(activeUnit, unit))
  if (adjacentTarget) {
    const preview = getAttackDamagePreview(activeUnit, adjacentTarget)
    const nextState = {
      ...state,
      units: state.units.map((unit) => {
        if (unit.id === adjacentTarget.id) return applyAttackPreview(unit, preview)
        if (unit.id === activeUnit.id) return { ...unit, hasActed: true }
        return unit
      }),
    }
    return finishActiveTurn(addLog(nextState, `${activeUnit.name} attacks ${adjacentTarget.name} for ${preview.hpDamage} HP damage.`))
  }

  return finishActiveTurn(addLog(state, `${activeUnit.name} studies the battlefield.`), { waited: true })
}

export function battleReducer(state, action) {
  switch (action.type) {
    case 'selectUnit':
      return { ...state, selectedUnitId: action.unitId }
    case 'selectCommand':
      return selectCommand(state, action.commandId)
    case 'moveActiveUnit':
      return moveActiveUnit(state, action.destination)
    case 'previewAttack':
      return previewAttack(state, action.targetId)
    case 'confirmAttack':
      return confirmAttack(state)
    case 'cancelCommand':
      return { ...state, activeCommand: null, movementRange: [], damagePreview: null, targetId: null, phase: BATTLE_PHASES.COMMAND }
    case 'runEnemyTurn':
      return runEnemyTurn(state)
    case 'refreshTurns':
      return refreshTurnState(state)
    default:
      return state
  }
}

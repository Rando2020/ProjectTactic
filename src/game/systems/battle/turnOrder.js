export const CT_THRESHOLD = 100

const TURN_CT_COSTS = {
  moveAndAct: 100,
  actOnly: 80,
  moveOnly: 80,
  wait: 60,
}

export function getLivingUnits(units = []) {
  return units.filter((unit) => unit.hp > 0)
}

export function getSpeed(unit) {
  return unit.stats?.speed ?? unit.speed ?? 6
}

export function normalizeTurnUnit(unit) {
  return {
    ...unit,
    ct: unit.ct ?? 0,
    hasMoved: unit.hasMoved ?? false,
    hasActed: unit.hasActed ?? false,
  }
}

export function normalizeTurnUnits(units = []) {
  return units.map(normalizeTurnUnit)
}

export function getNextReadyUnit(units = []) {
  return getLivingUnits(units)
    .filter((unit) => (unit.ct ?? 0) >= CT_THRESHOLD)
    .sort((a, b) => {
      if ((b.ct ?? 0) !== (a.ct ?? 0)) return (b.ct ?? 0) - (a.ct ?? 0)
      return getSpeed(b) - getSpeed(a)
    })[0] ?? null
}

export function advanceCtUntilReady(units = [], maxTicks = 64) {
  let nextUnits = normalizeTurnUnits(units)
  let ticks = 0
  let readyUnit = getNextReadyUnit(nextUnits)

  while (!readyUnit && ticks < maxTicks) {
    nextUnits = nextUnits.map((unit) => {
      if (unit.hp <= 0) return unit
      return { ...unit, ct: Math.min(CT_THRESHOLD + 50, (unit.ct ?? 0) + getSpeed(unit)) }
    })
    ticks += 1
    readyUnit = getNextReadyUnit(nextUnits)
  }

  return { units: nextUnits, readyUnit, ticksAdvanced: ticks }
}

export function getTurnCtCost(turnFlags = {}) {
  const hasMoved = Boolean(turnFlags.hasMoved)
  const hasActed = Boolean(turnFlags.hasActed)

  if (turnFlags.waited) return TURN_CT_COSTS.wait
  if (hasMoved && hasActed) return TURN_CT_COSTS.moveAndAct
  if (hasActed) return TURN_CT_COSTS.actOnly
  if (hasMoved) return TURN_CT_COSTS.moveOnly
  return TURN_CT_COSTS.wait
}

export function finishUnitTurn(unit, turnFlags = {}) {
  const ctCost = getTurnCtCost(turnFlags)
  return {
    ...unit,
    ct: Math.max(0, (unit.ct ?? CT_THRESHOLD) - ctCost),
    hasMoved: false,
    hasActed: false,
    acted: false,
  }
}

export function buildTurnTimeline(units = [], limit = 8) {
  let projected = normalizeTurnUnits(units)
  const timeline = []
  let guard = 0

  while (timeline.length < limit && guard < limit * 80) {
    const ready = getNextReadyUnit(projected)
    if (ready) {
      timeline.push({
        id: ready.id,
        name: ready.name,
        team: ready.team,
        ct: ready.ct ?? 0,
        speed: getSpeed(ready),
      })
      projected = projected.map((unit) => unit.id === ready.id ? finishUnitTurn(unit, { waited: true }) : unit)
    } else {
      projected = projected.map((unit) => unit.hp > 0 ? { ...unit, ct: (unit.ct ?? 0) + getSpeed(unit) } : unit)
    }
    guard += 1
  }

  return timeline
}

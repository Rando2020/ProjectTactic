const CT_THRESHOLD = 100

export function initializeTimeline(units = []) {
  return units.map((unit) => ({ ...unit, ct: unit.ct ?? 0 }))
}

export function tickTimeline(units = [], threshold = CT_THRESHOLD) {
  const livingUnits = units.filter((unit) => unit.hp > 0)
  if (!livingUnits.length) return { units, activeUnit: null }

  let nextUnits = [...units]
  let activeUnit = livingUnits.find((unit) => (unit.ct ?? 0) >= threshold)

  while (!activeUnit) {
    nextUnits = nextUnits.map((unit) => {
      if (unit.hp <= 0) return unit
      return { ...unit, ct: (unit.ct ?? 0) + (unit.stats?.speed ?? unit.speed ?? 6) }
    })
    activeUnit = nextUnits.filter((unit) => unit.hp > 0).find((unit) => (unit.ct ?? 0) >= threshold)
  }

  return { units: nextUnits, activeUnit }
}

export function endTurn(units = [], unitId, threshold = CT_THRESHOLD) {
  return units.map((unit) => {
    if (unit.id !== unitId) return unit
    return { ...unit, ct: Math.max(0, (unit.ct ?? threshold) - threshold) }
  })
}

export function getPreviewTimeline(units = [], turns = 8) {
  let simulated = initializeTimeline(units)
  const timeline = []

  for (let i = 0; i < turns; i += 1) {
    const result = tickTimeline(simulated)
    if (!result.activeUnit) break
    timeline.push(result.activeUnit)
    simulated = endTurn(result.units, result.activeUnit.id)
  }

  return timeline
}

export function sortByReadiness(units = []) {
  return [...units]
    .filter((unit) => unit.hp > 0)
    .sort((a, b) => (b.ct ?? 0) - (a.ct ?? 0) || (b.stats?.speed ?? 0) - (a.stats?.speed ?? 0))
}

export function getLivingUnits(units = [], team = null) {
  return units.filter((unit) => unit.hp > 0 && (!team || unit.team === team))
}

export function isObjectiveComplete(objective, units = []) {
  if (!objective) return false

  if (objective.type === 'defeat_all') {
    return getLivingUnits(units, 'enemy').length === 0
  }

  return false
}

export function getObjectiveProgress(objective, units = []) {
  if (!objective) return 'No objective loaded.'

  if (objective.type === 'defeat_all') {
    const remainingEnemies = getLivingUnits(units, 'enemy').length
    return remainingEnemies === 0
      ? 'Objective complete: all enemies defeated.'
      : `Defeat all enemies. Remaining enemies: ${remainingEnemies}.`
  }

  return objective.label ?? 'Objective in progress.'
}

export function isPartyDefeated(units = []) {
  return getLivingUnits(units, 'player').length === 0
}

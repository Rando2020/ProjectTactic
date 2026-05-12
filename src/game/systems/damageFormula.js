const FACING_BONUS = {
  front: 1,
  side: 1.12,
  back: 1.28
}

export function getRelativeFacing({ attacker, defender }) {
  if (!attacker || !defender) return 'front'
  const dx = attacker.x - defender.x
  const dy = attacker.y - defender.y
  const attackDirection = Math.abs(dx) > Math.abs(dy)
    ? dx > 0 ? 'E' : 'W'
    : dy > 0 ? 'S' : 'N'

  if (attackDirection === defender.facing) return 'front'
  const opposite = { N: 'S', S: 'N', E: 'W', W: 'E' }
  if (opposite[attackDirection] === defender.facing) return 'back'
  return 'side'
}

export function getArmorTypeForAbility(ability) {
  if (ability.type === 'magic' || ability.type === 'heal' || ability.element === 'holy' || ability.element === 'dark') return 'ether'
  return 'temper'
}

export function calculateDamagePreview({ attacker, defender, ability, targetTile }) {
  if (!attacker || !ability) return null

  const isHealing = ability.type === 'heal' || ability.effects?.some((effect) => effect.type === 'heal_hp')
  if (isHealing) {
    const amount = ability.effects?.find((effect) => effect.type === 'heal_hp')?.amount ?? ability.power ?? 0
    return { type: 'heal', amount, hitChance: 1, critChance: 0, facing: 'front', armorType: null, armorDamage: 0 }
  }

  if (!defender) {
    return { type: 'tile', amount: 0, hitChance: 1, critChance: 0, facing: 'front', armorType: null, armorDamage: 0, targetTile }
  }

  const attackStat = ability.type === 'magic' ? attacker.stats?.magic : ability.type === 'hybrid' ? Math.max(attacker.stats?.magic ?? 0, attacker.stats?.physical ?? 0) : attacker.stats?.physical
  const defenseStat = ability.type === 'magic' ? defender.stats?.magic : defender.stats?.physical
  const facing = getRelativeFacing({ attacker, defender })
  const facingMultiplier = FACING_BONUS[facing] ?? 1
  const armorType = getArmorTypeForAbility(ability)
  const activeArmor = armorType === 'ether' ? defender.ether ?? 0 : defender.temper ?? 0
  const armorMitigation = Math.min(0.45, activeArmor / 400)
  const raw = (ability.power ?? 0) + (attackStat ?? 0) * 1.15 - (defenseStat ?? 0) * 0.35
  const amount = Math.max(1, Math.round(raw * facingMultiplier * (1 - armorMitigation)))
  const armorDamage = ability.effects?.find((effect) => effect.type === `${armorType}_damage`)?.amount ?? Math.round(amount * 0.25)

  return {
    type: 'damage',
    amount,
    hitChance: Math.min(0.98, facing === 'back' ? 0.95 : facing === 'side' ? 0.9 : 0.84),
    critChance: facing === 'back' ? 0.18 : facing === 'side' ? 0.12 : 0.07,
    facing,
    armorType,
    armorDamage
  }
}

export function applyDamagePreview(defender, preview) {
  if (!defender || !preview) return defender
  if (preview.type === 'heal') {
    return { ...defender, hp: Math.min(defender.stats.hp, defender.hp + preview.amount) }
  }
  const next = { ...defender, hp: Math.max(0, defender.hp - preview.amount) }
  if (preview.armorType === 'ether') next.ether = Math.max(0, (next.ether ?? 0) - preview.armorDamage)
  if (preview.armorType === 'temper') next.temper = Math.max(0, (next.temper ?? 0) - preview.armorDamage)
  return next
}

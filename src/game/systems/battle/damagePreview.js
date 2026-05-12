import { manhattan } from '../grid.js'

export function isAttackTargetInRange(attacker, target, range = 1) {
  if (!attacker || !target || target.hp <= 0) return false
  return manhattan(attacker, target) <= range
}

export function getFacingBonus(attacker, target) {
  if (!attacker || !target) return { label: 'Front', multiplier: 1 }

  const dx = attacker.x - target.x
  const dy = attacker.y - target.y
  const attackVector = Math.abs(dx) > Math.abs(dy)
    ? (dx > 0 ? 'E' : 'W')
    : (dy > 0 ? 'S' : 'N')

  const opposite = { N: 'S', S: 'N', E: 'W', W: 'E' }
  if (target.facing === opposite[attackVector]) return { label: 'Back', multiplier: 1.25 }
  if (target.facing === attackVector) return { label: 'Front', multiplier: 1 }
  return { label: 'Side', multiplier: 1.1 }
}

export function getAttackDamagePreview(attacker, target) {
  if (!attacker || !target) return null

  const facing = getFacingBonus(attacker, target)
  const basePower = Math.max(20, Math.round((attacker.stats?.physical ?? attacker.physical ?? 40) * 1.15))
  const rawDamage = Math.round(basePower * facing.multiplier)
  const armorBreak = Math.min(target.temper ?? 0, Math.round(rawDamage * 0.35))
  const hpDamage = Math.max(1, rawDamage - Math.round(armorBreak * 0.25))
  const remainingHp = Math.max(0, target.hp - hpDamage)

  return {
    action: 'Attack',
    attackerId: attacker.id,
    targetId: target.id,
    targetName: target.name,
    facingLabel: facing.label,
    rawDamage,
    armorBreak,
    hpDamage,
    remainingHp,
    willDefeat: remainingHp <= 0,
    hitChance: 100,
  }
}

export function applyAttackPreview(target, preview) {
  if (!target || !preview) return target
  return {
    ...target,
    temper: Math.max(0, (target.temper ?? 0) - preview.armorBreak),
    hp: Math.max(0, target.hp - preview.hpDamage),
  }
}

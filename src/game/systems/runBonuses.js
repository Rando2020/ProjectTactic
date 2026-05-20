export function computeRunBonuses(activeBoons=[]) {
  const b = { elementalDamage:{fire:0,ice:0,thunder:0,holy:0,dark:0,water:0,earth:0}, jpMultiplier:1, healBetweenBattles:0, maxTemperBonus:0, surgeWindowBonus:0, surgeDamageBonus:0.25, reactionEchoChance:0, chainBonus:0, healBonus:0, doubleStrikeChance:0, revealElites:false, onEliteKill:null, battleStartEffects:[], phoenixVitality:false, damageBonus:0, firstHitGuard:false, minHpGuard:null, deathFlare:0, darkDrainsEther:false, weaknessMultiplier:1.5 }
  for (const boon of activeBoons) {
    const fx = boon.effect ?? {}
    switch(fx.type) {
      case 'elemental_damage_bonus': case 'elemental_bonus':
        if(fx.element&&b.elementalDamage[fx.element]!==undefined) b.elementalDamage[fx.element]+=(fx.bonus??0)
        if(fx.heal_bonus||fx.healBonus) b.healBonus+=(fx.heal_bonus??fx.healBonus??0)
        if(fx.chain_bonus||fx.chainBonus) b.chainBonus+=(fx.chain_bonus??fx.chainBonus??0)
        break
      case 'jp_multiplier': b.jpMultiplier*=(fx.mult??1); break
      case 'between_battle_heal': b.healBetweenBattles+=(fx.percent??0); break
      case 'stat_bonus': if(fx.stat==='temper'||fx.stat==='max_temper') b.maxTemperBonus+=(fx.amount??0); break
      case 'surge_boost': b.surgeWindowBonus+=(fx.window_bonus??fx.windowBonus??0); b.surgeDamageBonus=Math.max(b.surgeDamageBonus,fx.damage_bonus??fx.damageBonus??0.25); break
      case 'reaction_echo': case 'reaction_echo_chance': b.reactionEchoChance+=(fx.chance??0); break
      case 'reveal_elites': b.revealElites=true; break
      case 'passive':
        if(fx.id==='double_strike') b.doubleStrikeChance+=(fx.chance??0.25)
        if(fx.id==='luminarch_covenant') b.minHpGuard=1
        if(fx.id==='ashvale_resolve') b.firstHitGuard=true
        if(fx.id==='death_flare') b.deathFlare=(fx.damage??28)
        if(fx.id==='brand') b.brandBonus=(fx.bonus??0.5)
        if(fx.id==='arcanist_eye') b.weaknessMultiplier=(fx.weaknessMultiplier??fx.weakness_multiplier??2.0)
        break
      case 'on_elite_kill': b.onEliteKill=fx; break
      case 'once_per_battle': if(fx.outcome==='survive_at_1_hp') b.phoenixVitality=true; break
      case 'battle_start':
        b.battleStartEffects.push(fx)
        if(fx.damageBonus||fx.damage_bonus) b.damageBonus+=(fx.damageBonus??fx.damage_bonus??0)
        if(fx.darkDrainsEther||fx.dark_drains_ether) b.darkDrainsEther=true
        break
    }
  }
  return b
}
export function applyElementalBonus(element, baseDamage, runBonuses) {
  const bonus=(runBonuses?.elementalDamage?.[element]??0)+(runBonuses?.damageBonus??0)
  return bonus>0 ? Math.round(baseDamage*(1+bonus)) : baseDamage
}

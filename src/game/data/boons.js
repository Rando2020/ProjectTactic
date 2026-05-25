export const BOON_RARITIES = {
  common:    { label:'Common',    color:'#94a3b8', border:'rgba(148,163,184,.45)', glow:'rgba(148,163,184,.1)',  weight:55 },
  rare:      { label:'Rare',      color:'#fbbf24', border:'rgba(251,191,36,.65)',  glow:'rgba(251,191,36,.15)', weight:30 },
  legendary: { label:'Legendary', color:'#a855f7', border:'rgba(168,85,247,.75)',  glow:'rgba(168,85,247,.2)',  weight:12 },
  unique:    { label:'Unique',    color:'#ef4444', border:'rgba(239,68,68,.85)',   glow:'rgba(239,68,68,.25)',  weight:3  },
}

export const BOONS = [
  // ── IGNARETH (Fire) ──────────────────────────────────────────────────────
  { id:'ignareth_warmth',   name:"Ignareth's Warmth",   element:'fire',    rarity:'common',    guardian:'ignareth',
    icon:'🔥', description:'Fire abilities deal +20% damage. Burning terrain lasts 1 extra turn.',
    flavour:'The flame remembers every surface it has touched.',
    effect:{ type:'elemental_damage_bonus', element:'fire', bonus:0.20 } },
  { id:'ignareth_brand',    name:"Ignareth's Brand",    element:'fire',    rarity:'rare',      guardian:'ignareth',
    icon:'🔥', description:'Burning enemies take 50% extra physical damage.',
    flavour:'Ash cannot protect what the flame has already claimed.',
    effect:{ type:'passive', id:'brand', damageBonus:0.50, condition:'target_burning' } },
  { id:'ignareth_roar',     name:"Ignareth's Roar",     element:'fire',    rarity:'legendary', guardian:'ignareth',
    icon:'🔥', description:'First fire ability each battle auto-SURGEs. Burning tiles detonate when stepped on (35 dmg).',
    flavour:'"IGNARETH!" — Last words of the Null Conclave\'s Third Anchor.',
    effect:{ type:'passive', id:'ignareth_roar', autoSurgeFirst:true, element:'fire', detonateBurning:35 } },
  { id:'ignareth_unchained',name:'Ignareth Unchained',  element:'fire',    rarity:'unique',    guardian:'ignareth',
    icon:'🔥', description:'All terrain ignites at battle start. Fire abilities deal 2× damage. Party takes 8% max HP fire damage each turn.',
    flavour:'The Eternal Flame does not distinguish friend from kindling.',
    effect:{ type:'battle_start', trigger:'ignite_all_terrain', elementalDamage:{fire:1.0}, selfDamagePercent:0.08 } },
  // ── NEREVAN (Water) ──────────────────────────────────────────────────────
  { id:'nerevan_touch',     name:"Nerevan's Touch",     element:'water',   rarity:'common',    guardian:'nerevan',
    icon:'🌊', description:'Water abilities deal +20% damage. Units on wet terrain gain Regen (1t) per turn.',
    flavour:'The tide remembers where it has been.',
    effect:{ type:'elemental_damage_bonus', element:'water', bonus:0.20 } },
  { id:'nerevan_pull',      name:"Nerevan's Pull",      element:'water',   rarity:'rare',      guardian:'nerevan',
    icon:'🌊', description:'Electrify chains arc across 2 extra tiles. Wet terrain effects last 2 extra turns.',
    flavour:'Two waves from one stone — that is Nerevan\'s gift.',
    effect:{ type:'reaction_boost', reaction:'electrify_chain', chainBonus:2 } },
  { id:'nerevan_reflection',name:"Nerevan's Reflection",element:'water',   rarity:'legendary', guardian:'nerevan',
    icon:'🌊', description:'40% chance for any water-triggered reaction to cascade into a second reaction.',
    flavour:'The Mirefen does not flood. It remembers its original depth.',
    effect:{ type:'reaction_echo_chance', chance:0.40, element:'water' } },
  { id:'nerevan_veil',      name:"Nerevan's Veil",      element:'water',   rarity:'unique',    guardian:'nerevan',
    icon:'🌊', description:'Battle starts with a 3×3 tide. Party recovers 12% max HP per turn while standing on water.',
    flavour:'"The Mirefen does not flood. It remembers its original depth." — Reedfolk proverb',
    effect:{ type:'battle_start', trigger:'summon_tide', waterHealPercent:0.12 } },
  // ── TORVAHK (Thunder) ────────────────────────────────────────────────────
  { id:'torvahk_rhythm',    name:"Torvahk's Rhythm",   element:'thunder', rarity:'common',    guardian:'torvahk',
    icon:'⚡', description:'Thunder abilities deal +20% damage. Electrify chain arcs to 1 extra tile.',
    flavour:'The Storm Father counts time in lightning strikes.',
    effect:{ type:'elemental_damage_bonus', element:'thunder', bonus:0.20, chainBonus:1 } },
  { id:'torvahk_patience',  name:"Torvahk's Patience", element:'thunder', rarity:'rare',      guardian:'torvahk',
    icon:'⚡', description:'SURGE window +30% wider. SURGE bonus increases to +40% damage.',
    flavour:'"Never waste a moment. Strike the gap, not the steel." — Stormglass doctrine',
    effect:{ type:'surge_boost', windowBonus:0.30, damageBonus:0.40 } },
  { id:'torvahk_fury',      name:"Torvahk's Fury",     element:'thunder', rarity:'legendary', guardian:'torvahk',
    icon:'⚡', description:'After each stun, the stunned unit loses 20 HP and Stun lasts +1 turn.',
    flavour:'The Stormglass Bastion was built inside Torvahk\'s silence between strikes.',
    effect:{ type:'passive', id:'torvahk_fury', stunDrain:20, stunDurationBonus:1 } },
  { id:'torvahk_unchained', name:'Torvahk Unchained',  element:'thunder', rarity:'unique',    guardian:'torvahk',
    icon:'⚡', description:'Each turn, lightning arcs to the nearest enemy (30 dmg, 30% stun). Electrified water deals 55 damage.',
    flavour:'"They recorded 47 lightning strikes. They were all the same bolt."',
    effect:{ type:'battle_start', trigger:'lightning_aura', arcDamage:30, arcStunChance:0.30, electrifyDamage:55 } },
  // ── LUMINARCH (Holy) ─────────────────────────────────────────────────────
  { id:'luminarch_light',   name:"Luminarch's Light",  element:'holy',    rarity:'common',    guardian:'luminarch',
    icon:'✨', description:'Holy abilities deal +20% damage. Heals restore 15 extra HP.',
    flavour:'The old abbey records describe light that judged and healed in the same motion.',
    effect:{ type:'elemental_damage_bonus', element:'holy', bonus:0.20, healBonus:15 } },
  { id:'luminarch_grace',   name:"Luminarch's Grace",  element:'holy',    rarity:'rare',      guardian:'luminarch',
    icon:'✨', description:'Party begins each battle with Blessed (3t). Restore 30% HP between battles.',
    flavour:'"The light does not chase. It is already where the shadow falls."',
    effect:{ type:'battle_start', apply_status:{id:'blessed',turns:3}, target:'party', healBetweenBattles:0.30 } },
  { id:'luminarch_judgment',name:"Luminarch's Judgment",element:'holy',   rarity:'legendary', guardian:'luminarch',
    icon:'✨', description:'When an enemy dies, holy light flares — dealing 28 damage to all adjacent enemies.',
    flavour:'"The light does not chase. It is already where the shadow falls."',
    effect:{ type:'passive', id:'luminarch_judgment', deathFlare:28, element:'holy' } },
  { id:'luminarch_covenant',name:"Luminarch's Covenant",element:'holy',   rarity:'unique',    guardian:'luminarch',
    icon:'✨', description:'Party can never be reduced below 1 HP by a single hit. Void Anchors heal party 50 HP when struck.',
    flavour:'"We found Luminarch\'s seal at the base of the Thornspire."',
    effect:{ type:'passive', id:'luminarch_covenant', minHpGuard:1, anchorHeal:50 } },
  // ── VAELTHORN (Dark) ─────────────────────────────────────────────────────
  { id:'vaelthorn_shadow',  name:"Vaelthorn's Shadow",  element:'dark',   rarity:'common',    guardian:'vaelthorn',
    icon:'💀', description:'Dark abilities deal +20% damage. Void Scar drains +20 extra Ether.',
    flavour:'Vaelthorn does not corrupt. It reveals what was already there.',
    effect:{ type:'elemental_damage_bonus', element:'dark', bonus:0.20 } },
  { id:'vaelthorn_bargain', name:"Vaelthorn's Bargain", element:'dark',   rarity:'rare',      guardian:'vaelthorn',
    icon:'💀', description:'Sacrifice 20% max HP at battle start. Deal 40% more damage that battle.',
    flavour:'"Power always has a cost. Vaelthorn just shows you the bill first."',
    effect:{ type:'battle_start', trigger:'vaelthorn_bargain', hpSacrificePercent:0.20, damageBonus:0.40 } },
  { id:'vaelthorn_echo',    name:"Vaelthorn's Echo",    element:'dark',   rarity:'legendary', guardian:'vaelthorn',
    icon:'💀', description:'Every time an enemy status expires, they take 35 dark damage.',
    flavour:'The shadow doesn\'t end when the light returns. It remembers the shape it made.',
    effect:{ type:'passive', id:'vaelthorn_echo', onStatusExpire:{damage:35,element:'dark'} } },
  { id:'vaelthorn_unchained',name:'Vaelthorn Unchained',element:'dark',   rarity:'unique',    guardian:'vaelthorn',
    icon:'💀', description:'All enemies begin Cursed (2t). Dark abilities drain Ether alongside HP. Every kill restores 25 Ether + 10 HP.',
    flavour:'"The Null Conclave did not corrupt Vaelthorn. Vaelthorn was waiting for them."',
    effect:{ type:'battle_start', trigger:'vaelthorn_curse_all', onKill:{restoreEther:25,restoreHp:10}, darkDrainsEther:true } },
  // ── FACTION BOONS ────────────────────────────────────────────────────────
  { id:'bellkeeper_resonance',name:"Bellkeeper's Resonance",element:null, rarity:'rare',      faction:'bellkeepers',
    icon:'🔔', description:'Elemental reactions have 30% chance to award +8 JP. Reaction chains spread 1 extra tile.',
    flavour:'"The Bellkeepers record every resonance event. Every one. Since the First Sealing."',
    effect:{ type:'passive', id:'bellkeeper_resonance', reactionJpChance:0.30, reactionJpAmount:8, chainBonus:1 } },
  { id:'reedfolk_reading',   name:"Reedfolk's Reading", element:'water',  rarity:'rare',      faction:'mirefen_reedfolk',
    icon:'🌿', description:'Enemy elite affixes revealed before battle. Wet terrain effects last 2 extra turns.',
    flavour:'"The water tells us what is coming. We read the ripples, not the stone."',
    effect:{ type:'reveal_elites' } },
  { id:'stormglass_timing',  name:'Stormglass Timing',  element:'thunder',rarity:'rare',      faction:'stormglass_bastion',
    icon:'⏱️', description:'SURGE activates automatically on critical hits. Missed attacks still deal 40% damage.',
    flavour:'"The Bastion\'s doctrine: never waste a moment."',
    effect:{ type:'passive', id:'stormglass_timing', autoSurgeOnCrit:true, missedAttackPercent:0.40 } },
  { id:'ashvale_resolve',    name:'Ashvale Resolve',    element:null,     rarity:'rare',      faction:'ashvale_watch',
    icon:'🛡️', description:'Party cannot be reduced below 1 HP on the first hit they receive each battle.',
    flavour:'"We don\'t have Guardians here. We have each other." — Ashvale Watch captain',
    effect:{ type:'passive', id:'ashvale_resolve', firstHitGuard:1 } },
  // ── NEUTRAL / UNIVERSAL ──────────────────────────────────────────────────
  { id:'jp_accelerator',    name:'JP Accelerator',     element:null,     rarity:'rare',
    icon:'📈', description:'All JP gains are doubled this run.',
    flavour:'Some veterans say the war taught them more in a day than a decade of training.',
    effect:{ type:'jp_multiplier', mult:2.0 } },
  { id:'swift_recovery',    name:'Swift Recovery',     element:null,     rarity:'common',
    icon:'💚', description:'After each battle, restore 25% max HP to all party members.',
    flavour:'Rest where you can. There is no shame in surviving.',
    effect:{ type:'between_battle_heal', percent:0.25 } },
  { id:'iron_temper',       name:'Iron Temper',        element:null,     rarity:'common',
    icon:'🛡️', description:'All party members gain +40 max Temper this run.',
    flavour:'The Watch trains three hours a day for exactly this.',
    effect:{ type:'stat_bonus', stat:'temper', amount:40, target:'party' } },
  { id:'surge_extend',      name:'Resonant Surge',     element:null,     rarity:'common',
    icon:'⚡', description:'SURGE window +20% wider. SURGE bonus increases to +35%.',
    flavour:'The resonance leaves a gap in time. Learn to find it.',
    effect:{ type:'surge_boost', windowBonus:0.20, damageBonus:0.35 } },
  { id:'double_strike',     name:'Double Strike',      element:null,     rarity:'rare',
    icon:'⚔️', description:'Basic attacks have 25% chance to hit twice.',
    flavour:'"The second hit is always the one they didn\'t see."',
    effect:{ type:'passive', id:'double_strike', chance:0.25 } },
  { id:'void_sight',        name:'Void Sight',         element:null,     rarity:'rare',
    icon:'👁️', description:'Enemy elite affixes and tiers are revealed before each battle.',
    flavour:'Seeing what comes does not make it easier. It makes it possible.',
    effect:{ type:'reveal_elites' } },
  { id:'elemental_echo',    name:'Elemental Echo',     element:null,     rarity:'legendary',
    icon:'🌀', description:'25% chance for any terrain reaction to trigger a second time.',
    flavour:'In Mirefen, some reactions echo three times. No one knows why.',
    effect:{ type:'reaction_echo_chance', chance:0.25 } },
  { id:'champions_grit',    name:"Champion's Grit",    element:null,     rarity:'rare',
    icon:'💪', description:'Each Elite killed restores 30 HP and 20 Temper to the killing unit.',
    flavour:'Every elite carries what they were before the corruption. Take it back.',
    effect:{ type:'on_elite_kill', healHp:30, healTemper:20 } },
  { id:'phoenix_vitality',  name:'Phoenix Vitality',   element:'fire',   rarity:'legendary',
    icon:'🔥', description:'Once per battle, the first party member at 0 HP survives at 1 HP instead.',
    flavour:'Not every flame goes out when you stop feeding it.',
    effect:{ type:'once_per_battle', trigger:'fatal_hit', outcome:'survive_at_1_hp' } },
  // ── Movement Boons ──
  { id:'windrunner_step',   name:'Windrunner Step',    element:null,     rarity:'common',
    icon:'💨', description:'All party members gain +1 Move this run. Repositioning feels better immediately.',
    flavour:'The wind remembers every dancer.',
    effect:{ type:'stat_bonus', stat:'move', amount:1, target:'party' }, lane:'movement' },
  { id:'battle_fury',       name:'Battle Fury',        element:null,     rarity:'rare',
    icon:'⚔️', description:'Moving before attacking this turn adds +30% bonus damage to that strike.',
    flavour:'"The hunt rewards the swift." — Ashvale doctrine',
    effect:{ type:'tactical', id:'battle_fury', bonus:0.30 }, lane:'movement' },
  { id:'reaping_step',      name:'Reaping Step',       element:null,     rarity:'legendary',
    icon:'🌪️', description:'Killing an enemy grants a free move of up to 3 tiles.',
    flavour:'The earth remembers every footfall. Especially the last one.',
    effect:{ type:'tactical', id:'reaping_step', range:3 }, lane:'movement' },
]

export const getBoon             = (id)   => BOONS.find(b => b.id === id)
export const getBoonsByRarity    = (r)    => BOONS.filter(b => b.rarity === r)
export const getBoonsByGuardian  = (g)    => BOONS.filter(b => b.guardian === g)

// Movement boon detection (mirrors BoonSystem.boon_lane in GDScript)
const MOVEMENT_TACTICAL_IDS = ['battle_fury', 'iron_momentum', 'reaping_step']

export function getBoonLane(boon) {
  if (!boon) return ''

  // Explicit lane property
  if (boon.lane) return boon.lane

  const effect = boon.effect || {}

  // Stat bonus for movement
  if (effect.type === 'stat_bonus' && ['move', 'movement'].includes(effect.stat)) {
    return 'movement'
  }

  // Move bonus in effect
  if ((effect.move_bonus ?? 0) > 0) {
    return 'movement'
  }

  // Tactical movement abilities
  if (effect.type === 'tactical' && MOVEMENT_TACTICAL_IDS.includes(effect.id)) {
    return 'movement'
  }

  return ''
}

export const BOON_LANE_LIMITS = {
  'movement': 2,
}

export function getBoonsInLane(activeBoons, lane) {
  if (!lane) return []
  return activeBoons.filter(b => getBoonLane(b) === lane)
}

export function needsLaneReplacement(activeBoons, incomingBoon) {
  const lane = getBoonLane(incomingBoon)
  if (!lane) return false
  const limit = BOON_LANE_LIMITS[lane] ?? 999
  return getBoonsInLane(activeBoons, lane).length >= limit
}

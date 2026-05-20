export const ELITE_TIERS = {
  marked:   { label:'Marked',   color:'#fde047', hpMult:1.4, jpMult:1.5 },
  elite:    { label:'Elite',    color:'#f97316', hpMult:1.7, jpMult:2.0 },
  champion: { label:'Champion', color:'#ef4444', hpMult:2.2, jpMult:3.0 },
}
export const PREFIXES = {
  volatile:  { id:'volatile',  label:'Volatile',   description:'Explodes on death — 45 fire damage to adjacent.', onDeath:{ type:'explosion', damage:45 }, statMods:{} },
  fortified: { id:'fortified', label:'Fortified',  description:'+80% HP. Physical damage reduced 25%.', statMods:{ hpMult:1.8, physicalResist:0.25 } },
  empowered: { id:'empowered', label:'Empowered',  description:'Deals 40% more damage.', statMods:{ damageMult:1.4 } },
  siphoning: { id:'siphoning', label:'Siphoning',  description:'Hits drain 20 MP from target.', onHit:{ type:'mp_drain', amount:20 }, statMods:{} },
  cursed:    { id:'cursed',    label:'Cursed',     description:'35% chance to apply Bleed (2t) on hit.', onHit:{ type:'status', status:'bleed', turns:2, chance:0.35 }, statMods:{} },
  berserker: { id:'berserker', label:'Berserking', description:'Below 50% HP: +3 speed, +25% damage.', statMods:{}, conditional:{ trigger:'hp_below_half', speedBonus:3, damageMult:1.25 } },
  vampiric:  { id:'vampiric',  label:'Vampiric',   description:'Heals 30% of damage dealt.', onHit:{ type:'lifesteal', percent:0.30 }, statMods:{} },
  shielded:  { id:'shielded',  label:'Shielded',   description:'Starts with a 1-hit Ether shield.', statMods:{ etherShield:1 } },
}
export const SUFFIXES = {
  of_frost:     { id:'of_frost',     label:'of Frost',      description:'Adjacent tiles become ice. Hits apply Slow.', onSpawn:{ type:'freeze_adjacent' }, onHit:{ type:'status', status:'slow', turns:1, chance:0.6 } },
  of_the_storm: { id:'of_the_storm', label:'of the Storm',  description:'Nearby water becomes electrified.', onSpawn:{ type:'electrify_water', radius:3 } },
  of_flames:    { id:'of_flames',    label:'of Flames',     description:'Spawns on burning ground. Immune to fire.', onSpawn:{ type:'ignite_spawn' }, statMods:{ immunities:['fire'] } },
  of_the_pack:  { id:'of_the_pack',  label:'of the Pack',   description:'+20% dmg to all enemies within 2 tiles.', aura:{ type:'pack_leader', radius:2, damageMult:1.2 } },
  of_iron:      { id:'of_iron',      label:'of Iron',       description:'Immune to all status effects.', statMods:{ statusImmune:true } },
  of_shadows:   { id:'of_shadows',   label:'of Shadows',    description:'30% dodge chance.', statMods:{ dodgeChance:0.3 } },
  of_the_void:  { id:'of_the_void',  label:'of the Void',   description:'Immune to dark/resonance. Voids nearby tiles.', statMods:{ immunities:['dark','resonance'] } },
  of_the_tide:  { id:'of_the_tide',  label:'of the Tide',   description:'Floods adjacent tiles with shallow water.', onSpawn:{ type:'flood_adjacent', terrain:'shallow_water' } },
}
export const ELITE_SPAWN_RATES = { normal:0.70, marked:0.18, elite:0.09, champion:0.03 }
export const PREFIX_LIST = Object.keys(PREFIXES)
export const SUFFIX_LIST = Object.keys(SUFFIXES)

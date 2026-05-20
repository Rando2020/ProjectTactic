export const RARITIES = {
  common:   { label:'Common',   color:'#94a3b8', affixes:1, weight:55, border:'rgba(148,163,184,.4)' },
  uncommon: { label:'Uncommon', color:'#4ade80', affixes:2, weight:28, border:'rgba(74,222,128,.5)'  },
  rare:     { label:'Rare',     color:'#fbbf24', affixes:3, weight:14, border:'rgba(251,191,36,.6)'  },
  resonant: { label:'Resonant', color:'#c084fc', affixes:4, weight:3,  border:'rgba(192,132,252,.7)' },
}
const BASES = [
  { id:'blade',    name:'Blade',    slot:'weapon',    icon:'⚔️' },
  { id:'staff',    name:'Staff',    slot:'weapon',    icon:'🪄' },
  { id:'tome',     name:'Spelltome',slot:'weapon',    icon:'📖' },
  { id:'talisman', name:'Talisman', slot:'accessory', icon:'🔮' },
  { id:'ring',     name:'Ring',     slot:'accessory', icon:'💍' },
  { id:'ward',     name:'Ward',     slot:'charm',     icon:'🛡️' },
  { id:'rune',     name:'Runestone',slot:'charm',     icon:'🪨' },
]
const ADJS = { common:['Dull','Worn','Plain','Rough'], uncommon:['Sharp','Polished','Keen','Bright'], rare:['Gleaming','Wrathful','Tempest','Ancient'], resonant:['Eidolon','Resonant','Vaelthar','Shattered'] }
const AFFIXES = [
  { id:'phys_up',   label:'+{n} Physical',      stat:'physical',  roll:[4,18],  weight:15 },
  { id:'mag_up',    label:'+{n} Magic',          stat:'magic',     roll:[4,18],  weight:15 },
  { id:'hp_up',     label:'+{n} Max HP',         stat:'maxHp',     roll:[20,60], weight:14 },
  { id:'temper_up', label:'+{n} Max Temper',     stat:'maxTemper', roll:[10,35], weight:10 },
  { id:'fire_dmg',  label:'+{n}% Fire Damage',   element:'fire',   roll:[8,28],  weight:8  },
  { id:'thun_dmg',  label:'+{n}% Thunder Damage',element:'thunder',roll:[8,28],  weight:8  },
  { id:'holy_dmg',  label:'+{n}% Holy Damage',   element:'holy',   roll:[8,28],  weight:6  },
  { id:'dark_dmg',  label:'+{n}% Dark Damage',   element:'dark',   roll:[8,28],  weight:6  },
  { id:'jp_gain',   label:'+{n}% JP Gain',       jpBonus:true,     roll:[10,30], weight:7  },
  { id:'speed_up',  label:'+{n} Speed',          stat:'speed',     roll:[1,3],   weight:5  },
  { id:'on_kill_hp',label:'On kill: +{n} HP',    trigger:'on_kill',roll:[15,35], weight:6  },
]
function seededRng(seed) {
  let s = (seed >>> 0) || 1
  return () => { s = Math.imul(s,1664525)+1013904223|0; return (s>>>0)/4294967296 }
}
function wPick(arr, rng, key='weight') {
  let total = arr.reduce((s,i)=>s+(i[key]??1),0), r = rng()*total
  for (const i of arr) { r -= (i[key]??1); if (r<=0) return i }
  return arr[arr.length-1]
}
export function generateItem(seed, rarityBonus=0, slotHint=null) {
  const rng = seededRng(seed)
  const rarList = Object.entries(RARITIES).map(([id,r])=>({id,...r,weight:id==='common'?Math.max(1,r.weight-rarityBonus*40):r.weight+(rarityBonus*10)}))
  const rarity  = wPick(rarList, rng).id
  const rDef    = RARITIES[rarity]
  const bases   = slotHint ? BASES.filter(b=>b.slot===slotHint) : BASES
  const base    = bases[Math.floor(rng()*bases.length)]
  const adjs    = ADJS[rarity]; const adj = adjs[Math.floor(rng()*adjs.length)]
  const affixes = []; const used = new Set()
  for (let i = 0; i < rDef.affixes*3 && affixes.length < rDef.affixes; i++) {
    const pool = AFFIXES.filter(a=>!used.has(a.id))
    const a    = wPick(pool, rng)
    const n    = Math.round(a.roll[0]+rng()*(a.roll[1]-a.roll[0]))
    used.add(a.id); affixes.push({ ...a, value:n, label:a.label.replace('{n}',n) })
  }
  return { id:`item_${seed}_${rarity}`, name:`${adj} ${base.name}`, slot:base.slot, icon:base.icon, rarity, rarityDef:rDef, affixes }
}
export function generateBattleLoot(defeatedUnits, runSeed, floorIndex=0) {
  const drops = []; const rarityBonus = Math.min(0.6, floorIndex * 0.12)
  defeatedUnits.forEach((unit, index) => {
    const rng = seededRng(((runSeed*997+index*6271)>>>0)+1)
    const isElite = !!unit.eliteTier
    if (rng() < (isElite ? 0.75 : 0.12)) {
      const eBonus = unit.eliteTier==='champion'?0.5:isElite?0.3:0
      drops.push(generateItem((runSeed*997+index*6271+2)>>>0, rarityBonus+eBonus))
    }
  })
  return drops
}
export const getRarityDef = (rarity) => RARITIES[rarity] ?? RARITIES.common

import { getTerrain } from '../data/terrain.js'
import { applyDamagePreview } from './damageFormula.js'

export const REACTION_EFFECTS = {
  freeze_tile:    { label:'❄️ Freeze!',        description:'Water locks to ice. Units are immobilized.',                   newTerrain:'ice',               unitStatus:{id:'immobilize',turns:2},               element:'ice',     chain:false, color:'rgba(100,200,255,0.55)' },
  freeze_bridge:  { label:'❄️ Ice Bridge!',    description:'Deep water freezes — now crossable.',                         newTerrain:'ice',               unitStatus:null,                                    element:'ice',     chain:false, color:'rgba(100,200,255,0.55)' },
  electrify_chain:{ label:'⚡ Electrify!',     description:'Thunder arcs across all connected water. Units are struck.',  newTerrain:'electrified_water', unitDamage:32, unitStatus:{id:'stun',turns:1,chance:0.45}, element:'thunder', chain:true,  chainTag:'wet', color:'rgba(255,230,50,0.55)' },
  shatter_tile:   { label:'💥 Shatter!',       description:'Frozen ground explodes. Heavy damage, ice destroyed.',        newTerrain:'grass',             unitDamage:52,                                      element:'thunder', chain:false, color:'rgba(200,200,255,0.7)' },
  melt_tile:      { label:'💧 Melt!',          description:'Ice melts to shallow water.',                                 newTerrain:'shallow_water',                                                         element:'water',   chain:false, color:'rgba(50,180,255,0.45)' },
  steam_cloud:    { label:'☁️ Steam!',         description:'Fire extinguished. Steam clouds the area.',                   newTerrain:'grass',                                                                 element:'water',   chain:false, color:'rgba(200,220,255,0.45)' },
  cryo_douse:     { label:'❄️ Cryo Douse!',   description:'Fire flash-frozen. Ground becomes slick ice.',                newTerrain:'ice',                                                                   element:'ice',     chain:false, color:'rgba(100,200,255,0.55)' },
  muddy_tile:     { label:'🌊 Mud!',           description:'Earth absorbs water. Movement slowed.',                        newTerrain:'shallow_water',     unitStatus:{id:'slow',turns:2},                     element:'earth',   chain:false, color:'rgba(120,90,50,0.55)' },
  ground_charge:  { label:'⚡ Grounded!',      description:'Charge absorbed into earth. Tile neutralised.',               newTerrain:'grass',                                                                 element:'earth',   chain:false, color:'rgba(180,220,100,0.45)' },
  void_scar:      { label:'💀 Void Scar!',     description:'Dark energy strips Ether from all units on the shrine.',      newTerrain:null,  unitEtherDamage:28, unitDamage:14,                               element:'dark',    chain:false, color:'rgba(150,50,255,0.55)' },
  sanctify_tile:  { label:'✨ Sanctified!',    description:'Holy energy floods the shrine. Units gain Blessed.',           newTerrain:null,                unitStatus:{id:'blessed',turns:3},                  element:'holy',    chain:false, color:'rgba(255,220,80,0.5)' },
  expose_anchor:  { label:'⭐ Anchor Exposed!', description:'Void Anchor destabilised. Massive holy damage.',              newTerrain:null,                unitDamage:72,                                      element:'holy',    chain:false, color:'rgba(255,200,50,0.7)' },
  shatter_anchor: { label:'💥 Anchor Shattered!',description:'Void Anchor destroyed.',                                    newTerrain:'grass',                                                                 element:'resonance',chain:false,color:'rgba(200,100,255,0.7)' },
  burning_spread: { label:'🔥 Fire Spreads!',  description:'Flames leap to adjacent natural tiles.',                      newTerrain:'burning',                                                               element:'fire',    chain:false, color:'rgba(255,90,20,0.55)' },
}

export const TERRAIN_OVERLAY_COLORS = {
  ice:'rgba(120,210,255,0.32)', burning:'rgba(255,90,20,0.38)',
  electrified_water:'rgba(255,230,40,0.38)', void_anchor:'rgba(160,50,255,0.32)',
}

// JP awards for battle events
export const JP_AWARDS = {
  action_used: 6, weakness_hit: 4, status_applied: 4,
  armor_broken: 6, reaction_chain: 8, battle_clear: 18, boss_clear: 35,
}

function getAdjacentTiles(map, grid, tile) {
  return [{x:0,y:-1},{x:1,y:0},{x:0,y:1},{x:-1,y:0}]
    .map(d=>({x:tile.x+d.x,y:tile.y+d.y}))
    .filter(p=>p.x>=0&&p.y>=0&&p.x<map.size.width&&p.y<map.size.height)
    .map(p=>grid.find(t=>t.x===p.x&&t.y===p.y))
    .filter(Boolean)
}

function findConnectedTiles(originTile, grid, map, tag) {
  const visited = new Set([`${originTile.x},${originTile.y}`])
  const queue = [originTile], result = [originTile]
  while (queue.length) {
    const cur = queue.shift()
    for (const n of getAdjacentTiles(map, grid, cur)) {
      const k=`${n.x},${n.y}`; if (visited.has(k)) continue; visited.add(k)
      if (n.terrainDef?.tags?.includes(tag)) { result.push(n); queue.push(n) }
    }
  }
  return result
}

function applyUnitEffect(unit, def) {
  let next = { ...unit }
  if (def.unitDamage)      next = applyDamagePreview(next, { type:'damage', amount:def.unitDamage, armorType:null, armorDamage:0 })
  if (def.unitEtherDamage) next.ether = Math.max(0, (next.ether??0) - def.unitEtherDamage)
  if (def.unitStatus) {
    if (Math.random() < (def.unitStatus.chance??1))
      next.statuses = [...(next.statuses||[]), { id:def.unitStatus.id, turns:def.unitStatus.turns??1 }]
  }
  return next
}

export function applyReaction({ reactionId, originTile, grid, units, map }) {
  const def = REACTION_EFFECTS[reactionId]
  if (!def) return { updatedGrid:grid, updatedUnits:units, flashKeys:new Set(), logMessages:[`Unknown reaction: ${reactionId}`] }

  const affectedTiles = def.chain && def.chainTag
    ? findConnectedTiles(originTile, grid, map, def.chainTag)
    : [originTile]

  const flashKeys = new Set(affectedTiles.map(t=>`${t.x},${t.y}`))
  let updatedGrid = grid
  if (def.newTerrain) {
    const newDef = getTerrain(def.newTerrain)
    updatedGrid = grid.map(t => flashKeys.has(`${t.x},${t.y}`) ? {...t,terrain:def.newTerrain,terrainDef:newDef} : t)
  }

  // Burning spread — 35% chance to spread to adjacent natural tiles, max 2 tiles
  if (reactionId === 'apply_burning' || def.newTerrain === 'burning') {
    const naturalTiles = getAdjacentTiles(map, updatedGrid, originTile)
      .filter(t => t.terrainDef?.tags?.includes('natural') && t.terrain !== 'burning')
    let spreadCount = 0
    for (const t of naturalTiles) {
      if (spreadCount >= 2) break
      if (Math.random() < 0.35) {
        const burningDef = getTerrain('burning')
        updatedGrid = updatedGrid.map(g => g.x===t.x&&g.y===t.y ? {...g,terrain:'burning',terrainDef:burningDef} : g)
        flashKeys.add(`${t.x},${t.y}`); spreadCount++
      }
    }
  }

  let updatedUnits = units
  const hitNames = []
  for (const tile of affectedTiles) {
    for (const u of units.filter(u=>u.hp>0&&u.x===tile.x&&u.y===tile.y)) {
      updatedUnits = updatedUnits.map(x => x.id===u.id ? applyUnitEffect(x,def) : x)
      hitNames.push(u.name)
    }
  }

  const hitText  = hitNames.length ? ` Hits: ${hitNames.join(', ')}.` : ''
  const chainText= affectedTiles.length>1 ? ` (${affectedTiles.length} tiles)` : ''
  return { updatedGrid, updatedUnits, flashKeys, logMessages:[`${def.label}${chainText}${hitText}`] }
}

export function processReactionEvents({ events, grid, units, map }) {
  let updatedGrid=grid, updatedUnits=units
  const allFlashKeys=new Set(), logMessages=[]
  for (const ev of events) {
    if (ev.type!=='terrain_reaction'||!ev.reaction||!ev.tile) continue
    const r=applyReaction({reactionId:ev.reaction,originTile:ev.tile,grid:updatedGrid,units:updatedUnits,map})
    updatedGrid=r.updatedGrid; updatedUnits=r.updatedUnits
    r.flashKeys.forEach(k=>allFlashKeys.add(k)); logMessages.push(...r.logMessages)
  }
  return { updatedGrid, updatedUnits, allFlashKeys, logMessages }
}

export function processTurnStartHazards({ activeUnit, grid, units }) {
  const tile=grid.find(t=>t.x===activeUnit.x&&t.y===activeUnit.y)
  if (!tile?.terrainDef?.hazard) return { updatedUnits:units, logMessages:[] }
  const { damage=0, etherDamage=0, status } = tile.terrainDef.hazard
  let updatedUnits=units; const logMessages=[]
  if (damage>0||etherDamage>0) {
    updatedUnits=updatedUnits.map(u=>{ if(u.id!==activeUnit.id)return u; let n={...u}; if(damage>0)n=applyDamagePreview(n,{type:'damage',amount:damage,armorType:null,armorDamage:0}); if(etherDamage>0)n.ether=Math.max(0,(n.ether??0)-etherDamage); return n })
    logMessages.push(`${activeUnit.name} takes ${damage} from ${tile.terrainDef.name}!`)
  }
  if (status) updatedUnits=updatedUnits.map(u=>u.id!==activeUnit.id?u:{...u,statuses:[...(u.statuses||[]),{id:status,turns:1}]})
  return { updatedUnits, logMessages }
}

// Track JP events from combat results
export function extractJpEvents(events, attackerUnit, targetUnit, ability) {
  const jpEvents = [{ reason:'action_used', amount:JP_AWARDS.action_used }]
  const ev = events?.find(e=>e.type==='ability_used')
  if (ev?.preview) {
    if (ev.preview.armorType && (targetUnit?.temper===0||targetUnit?.ether===0))
      jpEvents.push({ reason:'armor_broken', amount:JP_AWARDS.armor_broken })
    if (ability?.element && ability.element!=='none' && targetUnit?.affinities?.includes(ability.element))
      jpEvents.push({ reason:'weakness_hit', amount:JP_AWARDS.weakness_hit })
  }
  const hasReaction = events?.some(e=>e.type==='terrain_reaction')
  if (hasReaction) jpEvents.push({ reason:'reaction_chain', amount:JP_AWARDS.reaction_chain })
  const hasStatus = events?.some(e=>e.type==='status_applied')
  if (hasStatus) jpEvents.push({ reason:'status_applied', amount:JP_AWARDS.status_applied })
  return jpEvents
}

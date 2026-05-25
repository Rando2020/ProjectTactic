import { BOONS, BOON_RARITIES } from '../data/boons.js'
import { WANDERERS, getWanderersForFloor } from '../data/wanderers.js'
import { MYSTERY_EVENT_TYPES, getMysteryEvent } from '../data/mysteryEvents.js'

const FLOOR_MAPS = {
  1: ['ashvale_road_01'],
  2: ['mirefen_marsh_01', 'ashvale_road_01'],
  3: ['mirefen_marsh_01', 'ashvale_road_01'],
  4: ['mirefen_marsh_01', 'ashvale_road_01'],
}

function seededRng(seed) {
  let s=(seed>>>0)||1
  return ()=>{ s=Math.imul(s,1664525)+1013904223|0; return (s>>>0)/4294967296 }
}
function pickRng(arr, rng) { return arr[Math.floor(rng()*arr.length)] }

function generateBoonPick(rng, floor=1) {
  const weights = { common:Math.max(10,55-(floor-1)*10), rare:30+(floor-1)*5, legendary:12+(floor-1)*3, unique:floor>=3?(floor-2)*2:0 }
  const pool    = Object.entries(weights).flatMap(([id,w])=>Array(w).fill(id))
  const boons=[]; const used=new Set()
  for (let i=0;i<3;i++) {
    for (let attempt=0;attempt<6;attempt++) {
      const rarity=pool[Math.floor(rng()*pool.length)]
      const candidates=BOONS.filter(b=>b.rarity===rarity&&!used.has(b.id))
      if (!candidates.length) continue
      const boon=candidates[Math.floor(rng()*candidates.length)]
      used.add(boon.id); boons.push(boon); break
    }
  }
  while (boons.length<3) {
    const fb=BOONS.filter(b=>b.rarity==='common'&&!used.has(b.id))
    if (!fb.length) break
    const b=fb[Math.floor(rng()*fb.length)]; used.add(b.id); boons.push(b)
  }
  return { type:'boon_pick', options:boons, floor }
}

function generateWandererEvent(rng, floor) {
  const wanderer = getWanderersForFloor(floor, rng)
  if (!wanderer) return { type:'event', eventType:'standard' }
  return { type:'wanderer', wanderer, floor }
}

function generateBattle(floorNum, rng, isElite=false, isBoss=false, preferredMapId=null) {
  const pool = preferredMapId ? [preferredMapId, ...(FLOOR_MAPS[floorNum] ?? FLOOR_MAPS[1]).filter(id => id !== preferredMapId)] : FLOOR_MAPS[floorNum] ?? FLOOR_MAPS[1]
  return { type:isBoss?'boss':isElite?'elite_battle':'battle', mapId:pickRng(pool,rng), eliteRateBonus:isElite?0.5:isBoss?1.0:0, completed:false }
}

function generateMysteryEvent(floorNum, totalFloors, rng) {
  const event = getMysteryEvent(floorNum, rng, totalFloors)
  if (!event) return { type:'event', eventType:'standard' }
  return { type:'mystery', eventId:event.id, eventName:event.name, completed:false }
}

export function generateRun(seed, floors=10, stage={}) {
  const rng  = seededRng(seed)
  const plan = []
  const preferredMapId = stage.missionId ?? null
  for (let f=1;f<=floors;f++) {
    const nodes=[]
    if (f===floors) {
      nodes.push(generateBattle(f,rng,false,true,preferredMapId))
    } else if (f===1) {
      nodes.push(generateBattle(f,rng,false,false,preferredMapId))
      nodes.push(generateBoonPick(rng,f))
    } else if (f===2) {
      nodes.push(generateBattle(f,rng,false,false,preferredMapId))
      nodes.push(generateWandererEvent(rng,f))  // wanderer replaces generic event
      nodes.push(generateBattle(f,rng,false,false,preferredMapId))
      nodes.push(generateBoonPick(rng,f))
    } else {
      nodes.push(generateBattle(f,rng,false,false,preferredMapId))
      // Mix of wanderer and mystery events on deeper floors
      if (rng() < 0.5) {
        nodes.push(generateWandererEvent(rng,f))
      } else {
        nodes.push(generateMysteryEvent(f,floors,rng))
      }
      nodes.push(generateBattle(f,rng,true,false,preferredMapId))
      nodes.push(generateBoonPick(rng,f))
    }
    plan.push({ floor:f, nodes, completed:false })
  }
  return { runId:`run_${seed.toString(36)}`, seed, stageId:stage.missionId??'ashvale_road_01', stageName:stage.name??'Guardian Descent', totalFloors:floors, currentFloor:1, currentNodeIndex:0, plan, activeBoons:[], equipment:{}, elitesSlain:0, runGold:0, deaths:0, startedAt:Date.now() }
}

export function getCurrentNode(run) {
  const floor=run.plan[run.currentFloor-1]; if(!floor) return null
  return floor.nodes[run.currentNodeIndex]??null
}

export function advanceRun(run) {
  const floor=run.plan[run.currentFloor-1]; const next={...run}
  if (run.currentNodeIndex<floor.nodes.length-1) next.currentNodeIndex=run.currentNodeIndex+1
  else if (run.currentFloor<run.totalFloors) { next.currentFloor=run.currentFloor+1; next.currentNodeIndex=0 }
  else next.completed=true
  return next
}

export function completeCurrentNode(run) {
  const updated={...run,plan:run.plan.map((fl,fi)=>{
    if (fi!==run.currentFloor-1) return fl
    return {...fl,nodes:fl.nodes.map((n,ni)=>ni===run.currentNodeIndex?{...n,completed:true}:n)}
  })}
  return advanceRun(updated)
}

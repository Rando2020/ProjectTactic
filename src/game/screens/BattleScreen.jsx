import { useCallback, useEffect, useRef, useState } from 'react'
import TacticalGrid   from '../components/TacticalGrid.jsx'
import CommandMenu    from '../components/CommandMenu.jsx'
import TurnTimeline   from '../components/TurnTimeline.jsx'
import BattleForecastHud from '../components/BattleForecastHud.jsx'
import AbilityPicker  from '../components/AbilityPicker.jsx'
import FacingPicker   from '../components/FacingPicker.jsx'
import TerrainInfo    from '../components/TerrainInfo.jsx'
import UnitCard       from '../components/UnitCard.jsx'
import SurgeWindow    from '../components/SurgeWindow.jsx'
import { buildGrid, getFacingAfterMove }             from '../systems/grid.js'
import { getReachableTiles }                         from '../systems/pathfinding.js'
import { getTargetableTiles }                        from '../systems/targeting.js'
import { resolveAbilityUse }                         from '../systems/combatResolver.js'
import { calculateDamagePreview }                    from '../systems/damageFormula.js'
import { initializeTimeline, tickTimeline, endTurn } from '../systems/turnOrder.js'
import { chooseEnemyAction, previewEnemyIntent }     from '../systems/aiController.js'
import { processReactionEvents, processTurnStartHazards, REACTION_EFFECTS, extractJpEvents, JP_AWARDS } from '../systems/elementalSystem.js'
import { isObjectiveComplete, isPartyDefeated, getObjectiveProgress } from '../systems/objectives.js'
import { instantiatePlayerUnit } from '../data/units.js'
import { instantiateEnemy }      from '../data/enemies.js'
import { getAbility, getUnitAbilities } from '../data/abilities.js'
import { getTerrainReaction }    from '../data/terrain.js'

const PHASE = { TICK:'TICK', PLAYER_TURN:'PLAYER_TURN', ENEMY_TURN:'ENEMY_TURN', VICTORY:'VICTORY', DEFEAT:'DEFEAT' }
const SPEED_OPTIONS = [{ value:1,label:'1×' },{ value:2,label:'2×' },{ value:4,label:'4×' },{ value:'skip',label:'Skip' }]
const BLOCKS_MOVE   = new Set(['immobilize','petrify','stun'])
const BLOCKS_ACTION = new Set(['stun','petrify','sleep'])
const STATUS_TICK_DAMAGE = { bleed:12, burning:15, poison:8 }
const STATUS_TICK_HEAL   = { regen:20 }
const KEY_CMDS = { m:'move', a:'attack', s:'ability', i:'item', w:'wait' }
const FACING_KEYS = { ArrowUp:'N', ArrowRight:'E', ArrowDown:'S', ArrowLeft:'W' }
const VITAE_DRAUGHT_ID = 'vitae_draught'

function buildInitialUnits(activeMission, deploymentSlots) {
  const spawns  = deploymentSlots || activeMission.playerSpawns
  const players = spawns.map(s => instantiatePlayerUnit(s.unitId, s)).filter(Boolean)
  const enemies = activeMission.enemySpawns.map(s => instantiateEnemy(s.unitId, s)).filter(Boolean)
  return initializeTimeline([...players, ...enemies])
}

function tickUnitStatuses(unit) {
  const logs = []; let next = { ...unit }; const remaining = []
  for (const st of unit.statuses ?? []) {
    if (STATUS_TICK_DAMAGE[st.id]) { next.hp=Math.max(0,next.hp-STATUS_TICK_DAMAGE[st.id]); logs.push(`${unit.name} takes ${STATUS_TICK_DAMAGE[st.id]} from ${st.id}.`) }
    if (STATUS_TICK_HEAL[st.id])   { next.hp=Math.min(unit.stats?.hp??next.hp,next.hp+STATUS_TICK_HEAL[st.id]); logs.push(`${unit.name} regenerates ${STATUS_TICK_HEAL[st.id]} HP.`) }
    const t=(st.turns??1)-1
    if(t>0)remaining.push({...st,turns:t}); else logs.push(`${unit.name}: ${st.id} wore off.`)
  }
  next.statuses=remaining; return { unit:next, logs }
}

let _pid = 0

export default function BattleScreen({ gameState, setGameState, activeMission, deploymentSlots, completeActiveMission, setScreen, onDefeat }) {
  const [grid,  setGrid]  = useState(() => buildGrid(activeMission))
  const gridRef  = useRef(grid);  gridRef.current  = grid
  const [units, setUnits] = useState(() => buildInitialUnits(activeMission, deploymentSlots))
  const unitsRef = useRef(units); unitsRef.current = units

  const [phase,          setPhase]          = useState(PHASE.TICK)
  const [activeUnitId,   setActiveUnitId]   = useState(null)
  const [selectedUnitId, setSelectedUnitId] = useState(null)
  const [activeCommand,      setActiveCommand]      = useState(null)
  const [selectedAbilityId,  setSelectedAbilityId]  = useState(null)
  const [moveTileKeys,       setMoveTileKeys]        = useState(null)
  const [attackTileKeys,     setAttackTileKeys]      = useState(null)
  const [intentTileKeys,     setIntentTileKeys]      = useState(null)
  const [reactionFlashKeys,  setReactionFlashKeys]   = useState(null)
  const [pendingTarget,      setPendingTarget]       = useState(null)
  const [surgeActive,        setSurgeActive]         = useState(false)
  const [surgeMultiplier,    setSurgeMultiplier]     = useState(1.0)
  const [hasMoved,  setHasMoved]  = useState(false)
  const [preMovPos, setPreMovPos] = useState(null)
  const [hasActed,  setHasActed]  = useState(false)
  const [hoveredTile, setHoveredTile] = useState(null)
  const [hoveredUnit, setHoveredUnit] = useState(null)
  const [popups,      setPopups]      = useState({})
  const [forecast,     setForecast]     = useState(null)
  const [lastReaction, setLastReaction] = useState(null)
  const [battleSpeed,  setBattleSpeed]  = useState(1)
  const [autoBattle,   setAutoBattle]   = useState(false)
  const [battleLog,    setBattleLog]    = useState([`${activeMission.name} — battle started.`])
  // JP tracking: { characterId: totalJp }
  const [battleJp,    setBattleJp]    = useState({})

  const addLog = useCallback(msg => setBattleLog(l=>[msg,...l].slice(0,14)), [])

  function delay(base) { return battleSpeed==='skip'?0:Math.round(base/battleSpeed) }

  function flashReaction(keys, label) {
    if (!keys?.size) return
    setReactionFlashKeys(keys); setLastReaction(label)
    setTimeout(()=>setReactionFlashKeys(null), 900)
    setTimeout(()=>setLastReaction(null), 3500)
  }

  function doReactions(events, currentUnits, currentGrid) {
    const r=processReactionEvents({events,grid:currentGrid,units:currentUnits,map:activeMission})
    if (r.allFlashKeys.size>0) {
      const ev=events.find(e=>e.type==='terrain_reaction')
      flashReaction(r.allFlashKeys, ev?REACTION_EFFECTS[ev.reaction]?.label:null)
    }
    r.logMessages.forEach(addLog)
    return { updatedGrid:r.updatedGrid, updatedUnits:r.updatedUnits }
  }

  function awardJp(unitId, jpEvents) {
    const total = jpEvents.reduce((sum,e)=>sum+e.amount, 0)
    if (total <= 0) return
    setBattleJp(prev=>({ ...prev, [unitId]:(prev[unitId]??0)+total }))
    addLog(`+${total} JP (${jpEvents.map(e=>e.reason).join(', ')})`)
  }

  function checkEnd(cur) {
    if(isPartyDefeated(cur))                              {setPhase(PHASE.DEFEAT); return true}
    if(isObjectiveComplete(activeMission.objective,cur))  {setPhase(PHASE.VICTORY); return true}
    return false
  }

  function applyStatusTick(unitId) {
    setUnits(prev=>{
      const u=prev.find(x=>x.id===unitId); if(!u)return prev
      const{unit:ticked,logs}=tickUnitStatuses(u); logs.forEach(addLog)
      if(ticked.hp<u.hp)spawnPopup(u,u.hp-ticked.hp,'damage')
      return prev.map(x=>x.id===unitId?ticked:x)
    })
  }

  function spawnPopup(unit,value,type='damage'){
    if(!unit)return
    const key=`${unit.x},${unit.y}`,id=++_pid
    setPopups(prev=>({...prev,[key]:[...(prev[key]??[]),{id,value,type}]}))
    setTimeout(()=>setPopups(prev=>{const l=(prev[key]??[]).filter(p=>p.id!==id);return l.length?{...prev,[key]:l}:Object.fromEntries(Object.entries(prev).filter(([k])=>k!==key))}),1150)
  }

  function spawnCombatPopups(events,prevU,nextU){
    const ev=events?.find(e=>e.type==='ability_used'); if(!ev?.preview)return
    const tgt=prevU.find(u=>u.id===ev.targetUnitId),after=nextU.find(u=>u.id===ev.targetUnitId)
    if(!tgt||!after)return
    const hpd=tgt.hp-after.hp; if(hpd>0)spawnPopup(tgt,hpd,ev.preview.critChance>0.5?'crit':'damage')
    const tmpd=(tgt.temper??0)-(after.temper??0); if(tmpd>0)spawnPopup(tgt,tmpd,'temper')
    if(ev.preview.type==='heal'&&ev.preview.amount>0)spawnPopup(tgt,ev.preview.amount,'heal')
  }

  function buildForecast(targetUnitId,tile){
    const attacker=unitsRef.current.find(u=>u.id===activeUnitId); if(!attacker)return
    const abilityId=selectedAbilityId||(activeCommand==='attack'?'basic_attack':null); if(!abilityId)return
    const ability=getAbility(abilityId),target=targetUnitId?unitsRef.current.find(u=>u.id===targetUnitId):null
    const targetTile=tile??(target?gridRef.current.find(t=>t.x===target.x&&t.y===target.y):null)
    const preview=target?calculateDamagePreview({attacker,defender:target,ability,targetTile}):null
    let reactionWarning=null
    if(targetTile&&ability.element&&ability.element!=='none'&&ability.element!=='guard'){
      const rId=getTerrainReaction(targetTile.terrain,ability.element)
      if(rId){const def=REACTION_EFFECTS[rId];if(def){const chainCount=def.chain?gridRef.current.filter(t=>t.terrainDef?.tags?.includes(def.chainTag)).length:1;reactionWarning={...def,chainCount,element:ability.element}}}
    }
    setForecast({preview,attacker,target,ability,reactionWarning})
  }

  // TICK
  useEffect(()=>{
    if(phase!==PHASE.TICK)return
    if(!unitsRef.current.some(u=>u.hp>0))return
    const{units:ticked,activeUnit}=tickTimeline(unitsRef.current); if(!activeUnit)return
    const{updatedUnits:afterHazard,logMessages}=processTurnStartHazards({activeUnit,grid:gridRef.current,units:ticked})
    logMessages.forEach(addLog)
    setUnits(afterHazard); setActiveUnitId(activeUnit.id); setSelectedUnitId(null)
    setActiveCommand(null); setSelectedAbilityId(null); setMoveTileKeys(null); setAttackTileKeys(null)
    setIntentTileKeys(null); setForecast(null); setHasMoved(false); setPreMovPos(null); setHasActed(false)
    setPendingTarget(null); setSurgeActive(false)
    const ua=afterHazard.find(u=>u.id===activeUnit.id)
    if(!ua||ua.hp<=0){addLog(`${activeUnit.name} was felled by terrain.`);if(!checkEnd(afterHazard))setPhase(PHASE.TICK);return}
    if(activeUnit.team==='player'){setSelectedUnitId(activeUnit.id);setPhase(PHASE.PLAYER_TURN);addLog(`${activeUnit.name}'s turn.`)}
    else setPhase(PHASE.ENEMY_TURN)
  },[phase,addLog,activeMission])

  // AUTO BATTLE - automatically skip player turns
  useEffect(()=>{
    if(!autoBattle||phase!==PHASE.PLAYER_TURN||!activeUnitId)return
    const t=setTimeout(()=>{
      hRef.current.handleWait()
    },delay(300))
    return()=>clearTimeout(t)
  },[autoBattle,phase,activeUnitId,battleSpeed,delay])

  // ENEMY TURN
  useEffect(()=>{
    if(phase!==PHASE.ENEMY_TURN||!activeUnitId)return
    const cur=unitsRef.current,grd=gridRef.current,unit=cur.find(u=>u.id===activeUnitId)
    if(!unit||unit.hp<=0){setPhase(PHASE.TICK);return}
    const intent=previewEnemyIntent({map:activeMission,grid:grd,units:cur,unit})
    if(intent?.threatenedTiles?.length){setIntentTileKeys(new Set(intent.threatenedTiles.map(t=>`${t.x},${t.y}`)));addLog(intent.label)}
    const t=setTimeout(()=>{
      setUnits(prev=>{
        const u=prev.find(x=>x.id===activeUnitId); if(!u||u.hp<=0)return prev
        if(u.statuses?.some(s=>BLOCKS_ACTION.has(s.id))){addLog(`${u.name} is stunned and skips.`);return endTurn(prev,activeUnitId)}
        const action=chooseEnemyAction({map:activeMission,grid:grd,units:prev,unit:u})
        let next=prev,nextGrid=grd
        if(action.type==='move'){
          next=prev.map(x=>x.id!==activeUnitId?x:{...x,x:action.to.x,y:action.to.y,facing:getFacingAfterMove(x,action.to)})
          addLog(`${u.name} moves to (${action.to.x},${action.to.y}).`)
        } else if(action.type==='ability'){
          const res=resolveAbilityUse({units:prev,grid:grd,attackerId:activeUnitId,abilityId:action.abilityId,targetUnitId:action.targetUnitId})
          const ab=getAbility(action.abilityId),tgt=prev.find(x=>x.id===action.targetUnitId),dmg=res.events?.find(e=>e.type==='ability_used')?.preview
          const el=ab?.element!=='none'?` [${ab?.element}]`:''
          addLog(`${u.name}: ${ab?.name}${el} → ${tgt?.name??'?'} (${dmg?.amount??'?'} dmg)`)
          spawnCombatPopups(res.events,prev,res.units)
          const reacted=doReactions(res.events,res.units,grd); next=reacted.updatedUnits; nextGrid=reacted.updatedGrid
        } else addLog(`${u.name} waits.`)
        setGrid(nextGrid)
        const withTick=next.map(x=>{if(x.id!==activeUnitId)return x;const{unit:tk,logs}=tickUnitStatuses(x);logs.forEach(addLog);return tk})
        return endTurn(withTick,activeUnitId)
      })
      setIntentTileKeys(null)
      setTimeout(()=>{if(!checkEnd(unitsRef.current))setPhase(PHASE.TICK)},delay(300))
    },delay(800))
    return()=>clearTimeout(t)
  },[phase,activeUnitId,activeMission,addLog,battleSpeed])

  // Player commands
  function handleCommand(commandId){
    if(phase!==PHASE.PLAYER_TURN)return
    if(activeCommand==='facing')return
    const unit=unitsRef.current.find(u=>u.id===activeUnitId); if(!unit)return
    if(commandId!=='wait'&&unit.statuses?.some(s=>BLOCKS_ACTION.has(s.id))){addLog(`${unit.name} is stunned.`);beginFacingSelection();return}
    setActiveCommand(commandId); setSelectedAbilityId(null); setForecast(null); setPendingTarget(null)
    if(commandId==='move'){
      if(unit.statuses?.some(s=>BLOCKS_MOVE.has(s.id))){addLog(`${unit.name} is immobilized.`);setActiveCommand(null);return}
      const reachable=getReachableTiles({map:activeMission,grid:gridRef.current,units:unitsRef.current,unit})
      setMoveTileKeys(new Set(reachable.map(e=>`${e.tile.x},${e.tile.y}`))); setAttackTileKeys(null)
    } else if(commandId==='attack'){ armAbility('basic_attack',unit)
    } else if(commandId==='ability'){ setMoveTileKeys(null); setAttackTileKeys(null)
    } else if(commandId==='item'){ executeItem(unit) }
  }

  function armAbility(abilityId,unit){
    const ability=getAbility(abilityId); if(!ability)return
    setSelectedAbilityId(abilityId)
    const targetable=getTargetableTiles({map:activeMission,grid:gridRef.current,caster:unit,ability})
    const isAlly=ability.target==='ally'
    const keys=new Set(targetable.map(t=>unitsRef.current.find(u=>u.hp>0&&u.team===(isAlly?'player':'enemy')&&u.x===t.x&&u.y===t.y)).filter(Boolean).map(u=>`${u.x},${u.y}`))
    setAttackTileKeys(keys); setMoveTileKeys(null)
    if(keys.size===0)addLog(`No targets in range for ${ability.name}.`)
  }

  function handleAbilityPick(abilityId){
    const unit=unitsRef.current.find(u=>u.id===activeUnitId); if(!unit)return
    const ab=getAbility(abilityId),el=ab?.element!=='none'?` [${ab?.element}]`:''
    addLog(`${unit.name} readies ${ab?.name??abilityId}${el}.`); armAbility(abilityId,unit)
  }

  function handleMoveClick(tile){
    if(phase!==PHASE.PLAYER_TURN||hasMoved)return
    const unit=unitsRef.current.find(u=>u.id===activeUnitId); if(!unit)return
    setPreMovPos({x:unit.x,y:unit.y,facing:unit.facing}); setHasMoved(true)
    setUnits(prev=>prev.map(u=>u.id!==activeUnitId?u:{...u,x:tile.x,y:tile.y,facing:getFacingAfterMove(u,tile)}))
    addLog(`${unit.name} moved to (${tile.x},${tile.y}). Choose an action or Wait.`)
    setMoveTileKeys(null); setActiveCommand(null)
  }

  function handleUndoMove(){
    if(!hasMoved||!preMovPos)return
    const unit=unitsRef.current.find(u=>u.id===activeUnitId); if(!unit)return
    setUnits(prev=>prev.map(u=>u.id!==activeUnitId?u:{...u,...preMovPos}))
    addLog(`${unit.name} movement undone.`); setHasMoved(false); setPreMovPos(null)
    setActiveCommand(null); setMoveTileKeys(null); setAttackTileKeys(null); setSelectedAbilityId(null); setPendingTarget(null)
  }

  function handleAttackClick(targetId){
    if(phase!==PHASE.PLAYER_TURN||hasActed||activeCommand==='facing')return
    const abilityId=selectedAbilityId||'basic_attack'
    const targetUnit=unitsRef.current.find(u=>u.id===targetId); if(!targetUnit)return
    setPendingTarget({targetId,abilityId,key:`${targetUnit.x},${targetUnit.y}`})
    buildForecast(targetId,null)
    // Open SURGE window
    setSurgeActive(true); setSurgeMultiplier(1.0)
  }

  function handleSurgeResult({surged,multiplier}){
    setSurgeActive(false); setSurgeMultiplier(multiplier)
    if(surged) addLog('⚡ SURGE! +25% damage bonus!')
  }

  function confirmAttack(){
    if(!pendingTarget)return
    const{targetId,abilityId}=pendingTarget
    const unit=unitsRef.current.find(u=>u.id===activeUnitId); if(!unit)return
    const prevU=unitsRef.current
    const result=resolveAbilityUse({units:prevU,grid:gridRef.current,attackerId:activeUnitId,abilityId,targetUnitId:targetId,surgeMultiplier})
    const ability=getAbility(abilityId),target=prevU.find(u=>u.id===targetId)
    const dmg=result.events?.find(e=>e.type==='ability_used')?.preview
    const el=ability?.element!=='none'?` [${ability?.element}]`:''
    const surgeTag=surgeMultiplier>1?` ⚡SURGE`:'';
    addLog(`${unit.name}: ${ability?.name}${el} → ${target?.name} (${dmg?.amount??'?'} dmg, ${dmg?.armorDamage??0} armor)${surgeTag}`)
    spawnCombatPopups(result.events,prevU,result.units)
    // Award JP
    const jpEvents=extractJpEvents(result.events,unit,target,ability)
    awardJp(activeUnitId,jpEvents)
    const{updatedGrid,updatedUnits}=doReactions(result.events,result.units,gridRef.current)
    setGrid(updatedGrid); setUnits(updatedUnits)
    setForecast(null); setAttackTileKeys(null); setActiveCommand(null); setSelectedAbilityId(null); setPendingTarget(null)
    setHasActed(true); setSurgeActive(false)
    beginFacingSelection()
  }

  function executeItem(unit){
    const available = gameState.inventory?.[VITAE_DRAUGHT_ID] ?? 0
    if(available <= 0){
      addLog('No Vitae Draughts remaining.')
      setActiveCommand(null)
      return
    }

    setGameState?.(current => ({
      ...current,
      inventory: {
        ...current.inventory,
        [VITAE_DRAUGHT_ID]: Math.max(0, (current.inventory?.[VITAE_DRAUGHT_ID] ?? 0) - 1),
      },
    }))
    setUnits(prev=>prev.map(u=>u.id!==unit.id?u:{...u,hp:Math.min(u.stats?.hp??u.hp,u.hp+120)}))
    spawnPopup(unit,120,'heal'); addLog(`${unit.name} used Vitae Draught (+120 HP). ${available - 1} remaining.`)
    setHasActed(true); beginFacingSelection()
  }

  function handleWait(){
    const unit=unitsRef.current.find(u=>u.id===activeUnitId)
    if(unit)addLog(`${unit.name} holds position.`)
    beginFacingSelection()
  }

  function beginFacingSelection(){
    setActiveCommand('facing'); setMoveTileKeys(null); setAttackTileKeys(null); setForecast(null); setSelectedAbilityId(null); setPendingTarget(null); setSurgeActive(false)
  }

  function chooseFacing(facing){
    const unit=unitsRef.current.find(u=>u.id===activeUnitId)
    if(!unit)return
    setUnits(prev=>prev.map(u=>u.id!==activeUnitId?u:{...u,facing}))
    addLog(`${unit.name} faces ${facing}.`)
    endPlayerTurn()
  }

  function endPlayerTurn(){
    applyStatusTick(activeUnitId); setHasMoved(false); setPreMovPos(null); setHasActed(false)
    setUnits(prev=>{const next=endTurn(prev,activeUnitId);setTimeout(()=>{if(!checkEnd(unitsRef.current))setPhase(PHASE.TICK)},80);return next})
    setSelectedUnitId(null); setActiveCommand(null); setMoveTileKeys(null); setAttackTileKeys(null); setForecast(null); setSelectedAbilityId(null); setPendingTarget(null); setSurgeMultiplier(1.0)
  }

  // Handle victory — pass JP to completeActiveMission
  function handleVictory(){
    completeActiveMission({
      battleJp,
      clearBonus: JP_AWARDS.battle_clear,
      defeatedUnits: unitsRef.current.filter(u => u.team === 'enemy' && u.hp <= 0),
    })
  }

  // Keyboard
  const hRef=useRef({})
  hRef.current={handleCommand,handleWait,handleUndoMove,confirmAttack,chooseFacing,cancelConfirm:()=>{setPendingTarget(null);setForecast(null);setSurgeActive(false)},phase,hasMoved,hasActed,pendingTarget,activeCommand}
  useEffect(()=>{
    function onKey(e){
      const h=hRef.current; const tag=document.activeElement?.tagName
      if(tag==='INPUT'||tag==='TEXTAREA')return
      if(h.phase!==PHASE.PLAYER_TURN)return
      if(h.activeCommand==='facing'){const facing=FACING_KEYS[e.key];if(facing){e.preventDefault();h.chooseFacing(facing)};return}
      if(e.key==='Escape'){if(h.pendingTarget)h.cancelConfirm();else if(h.activeCommand){setActiveCommand(null);setMoveTileKeys(null);setAttackTileKeys(null);setSelectedAbilityId(null);setPendingTarget(null)};return}
      if((e.key==='Enter'||e.key===' ')&&h.pendingTarget&&!surgeActive){e.preventDefault();h.confirmAttack();return}
      if(e.key.toLowerCase()==='z'&&h.hasMoved&&!h.hasActed){h.handleUndoMove();return}
      const cmd=KEY_CMDS[e.key.toLowerCase()];if(cmd){e.preventDefault();cmd==='wait'?h.handleWait():h.handleCommand(cmd)}
    }
    window.addEventListener('keydown',onKey); return()=>window.removeEventListener('keydown',onKey)
  },[surgeActive])

  const activeUnit=units.find(u=>u.id===activeUnitId),selectedUnit=units.find(u=>u.id===selectedUnitId&&u.hp>0)
  const isPlayerPhase=phase===PHASE.PLAYER_TURN,isStunned=activeUnit?.statuses?.some(s=>BLOCKS_ACTION.has(s.id))
  const showPicker=isPlayerPhase&&activeCommand==='ability'&&!selectedAbilityId
  const showFacingPicker=isPlayerPhase&&activeCommand==='facing'
  const hasVitaeDraught=(gameState.inventory?.[VITAE_DRAUGHT_ID] ?? 0) > 0
  const disabledCmds=!isPlayerPhase||showFacingPicker?['move','attack','ability','item','wait']:isStunned?['move','attack','ability','item']:[...(hasMoved?['move']:[]),...(hasActed?['attack','ability','item']:[]),...(!hasVitaeDraught?['item']:[])]
  const unitWithDefs=selectedUnit?{...selectedUnit,abilityDefs:getUnitAbilities(selectedUnit)}:null
  const inspectUnit=hoveredUnit?units.find(u=>u.id===hoveredUnit):null
  const totalBattleJp=Object.values(battleJp).reduce((s,v)=>s+v,0)

  return(<main style={s.panel}>
    <SurgeWindow active={surgeActive} onResult={handleSurgeResult} abilityElement={getAbility(selectedAbilityId||'basic_attack')?.element}/>

    <div style={s.header}>
      <div>
        <p style={s.eyebrow}>Tactical Battle</p>
        <h2 style={s.title}>{activeMission.name}</h2>
        <p style={{fontSize:13,margin:0,opacity:.8}}>{getObjectiveProgress(activeMission.objective,units)}</p>
        {phase===PHASE.ENEMY_TURN&&activeUnit&&<p style={{fontSize:13,color:'#fca5a5',margin:'4px 0 0'}}>⚔ {activeUnit.name}'s turn…</p>}
        {isStunned&&isPlayerPhase&&<p style={{fontSize:13,color:'#fde047',margin:'4px 0 0'}}>⚡ {activeUnit?.name} is stunned!</p>}
        {lastReaction&&<p style={{fontSize:14,color:'#ffd86b',fontWeight:800,margin:'4px 0 0'}}>{lastReaction}</p>}
        {phase===PHASE.DEFEAT&&<p style={{color:'#f87171',fontWeight:800,margin:'4px 0 0'}}>⚰ Party defeated.</p>}
        {phase===PHASE.VICTORY&&<p style={{color:'#86efac',fontWeight:800,margin:'4px 0 0'}}>✓ Victory! +{JP_AWARDS.battle_clear} JP</p>}
        {totalBattleJp>0&&<p style={{fontSize:11,color:'#c9a756',margin:'2px 0 0'}}>Battle JP: {totalBattleJp}</p>}
        {isPlayerPhase&&!isStunned&&!showFacingPicker&&<p style={{fontSize:10,color:'rgba(247,240,223,.3)',margin:'6px 0 0'}}>M·Move  A·Attack  S·Ability  I·Item ({gameState.inventory?.[VITAE_DRAUGHT_ID] ?? 0})  W·Wait  Z·Undo  Esc·Cancel  Enter·Confirm  Space·SURGE</p>}
        {showFacingPicker&&<p style={{fontSize:10,color:'rgba(247,240,223,.45)',margin:'6px 0 0'}}>Choose final facing with the panel or arrow keys.</p>}
      </div>
      <div style={{display:'flex',flexDirection:'column',gap:8,alignItems:'flex-end'}}>
        <div style={s.speedRow}>
          <span style={s.speedLabel}>Speed</span>
          {SPEED_OPTIONS.map(opt=><button key={opt.value} style={{...s.speedBtn,...(battleSpeed===opt.value?s.speedActive:{})}} onClick={()=>setBattleSpeed(opt.value)}>{opt.label}</button>)}
        </div>
        <button style={{...s.speedBtn,...(autoBattle?s.autoBattleActive:{})}} onClick={()=>setAutoBattle(!autoBattle)}>
          {autoBattle ? '⚔ Auto ON' : '⚔ Auto OFF'}
        </button>
        <div style={s.btnRow}>
          <button onClick={()=>gameState.activeRun?onDefeat?.():setScreen('worldMap')}>Retreat</button>
          {phase===PHASE.DEFEAT&&<button onClick={()=>onDefeat?.()} style={s.defeatBtn}>Return to Hub</button>}
          {phase===PHASE.VICTORY&&<button onClick={handleVictory} style={s.victoryBtn}>Claim Victory ✓</button>}
        </div>
      </div>
    </div>

    {pendingTarget&&!surgeActive&&(
      <div style={s.confirmBanner}>
        <span>Confirm attack on <strong>{units.find(u=>u.id===pendingTarget.targetId)?.name}?</strong></span>
        <div style={{display:'flex',gap:8}}>
          <button onClick={confirmAttack} style={s.confirmBtn}>✓ Confirm (Enter)</button>
          <button onClick={()=>{setPendingTarget(null);setForecast(null)}} style={s.cancelBtn}>✕ Cancel (Esc)</button>
        </div>
      </div>
    )}

    <div style={s.layout}>
      <TurnTimeline units={units} activeUnitId={activeUnitId} variant="rail"/>
      <section>
        <div style={s.gridCard}>
          <TacticalGrid map={activeMission} units={units} selectedUnitId={selectedUnitId} activeUnitId={activeUnitId} activeCommand={activeCommand}
            moveTileKeys={moveTileKeys} attackTileKeys={attackTileKeys} intentTileKeys={intentTileKeys}
            reactionFlashKeys={reactionFlashKeys} pendingTargetKey={pendingTarget?.key} popups={popups}
            onSelectUnit={id=>{if(isPlayerPhase&&id===activeUnitId)setSelectedUnitId(id)}}
            onSelectMoveTile={handleMoveClick} onSelectAttackTarget={handleAttackClick}
            onHoverUnit={id=>{setHoveredUnit(id);setHoveredTile(null);buildForecast(id,null)}}
            onHoverTile={tile=>{setHoveredTile(tile);setHoveredUnit(null)}}
            onLeave={()=>{setHoveredUnit(null);setHoveredTile(null)}}
            showCoordinates={gameState.settings?.showTileCoordinates??true}/>
        </div>
        <BattleForecastHud preview={forecast?.preview} attacker={forecast?.attacker} target={forecast?.target} ability={forecast?.ability} reactionWarning={forecast?.reactionWarning} pendingTarget={pendingTarget}/>
      </section>
      <aside style={s.sidebar}>
        {showFacingPicker?<FacingPicker unit={activeUnit} onChoose={chooseFacing}/>
          :showPicker?<AbilityPicker unit={unitWithDefs} onSelect={handleAbilityPick} onCancel={()=>{setActiveCommand(null);setSelectedAbilityId(null)}}/>
          :<CommandMenu selectedUnit={selectedUnit} activeCommand={activeCommand} disabledCommands={disabledCmds} hasMoved={hasMoved} onSelectCommand={handleCommand} onWait={handleWait} onUndoMove={handleUndoMove}/>}
        {inspectUnit?<UnitCard unit={inspectUnit}/>:<TerrainInfo tile={hoveredTile}/>}
        <section style={s.card}>
          <h3 style={{margin:'0 0 10px',fontSize:15}}>Units</h3>
          {units.map(unit=>(<div key={unit.id} style={{marginBottom:8,opacity:unit.hp<=0?.28:1}}>
            <div style={{display:'flex',justifyContent:'space-between'}}>
              <span style={{fontSize:13,fontWeight:800,textDecoration:unit.hp<=0?'line-through':'none'}}>{unit.name}</span>
              <span style={{fontSize:11,color:unit.team==='player'?'#7bdcff':'#ff6b6b'}}>{unit.id===activeUnitId?'← active':`[${unit.team}]`}</span>
            </div>
            {unit.hp>0&&<>
              <div style={{fontSize:11,color:'rgba(247,240,223,.55)'}}>HP {unit.hp} · TMP {unit.temper} · ETH {unit.ether}</div>
              {unit.statuses?.length>0&&<div style={{display:'flex',flexWrap:'wrap',gap:3,marginTop:2}}>
                {unit.statuses.map(st=><span key={st.id} style={{fontSize:10,padding:'1px 5px',borderRadius:4,background:'rgba(251,191,36,.15)',border:'1px solid rgba(251,191,36,.3)',color:'#fbbf24'}}>{st.id} {st.turns}t</span>)}
              </div>}
              {battleJp[unit.id]>0&&<div style={{fontSize:10,color:'#c9a756'}}>+{battleJp[unit.id]} JP this battle</div>}
            </>}
          </div>))}
        </section>
        <section style={s.card}>
          <h3 style={{margin:'0 0 8px',fontSize:15}}>Battle Log</h3>
          <ul style={{padding:0,margin:0,listStyle:'none',fontSize:12,lineHeight:1.9}}>
            {battleLog.map((entry,i)=><li key={i} style={{color:i===0?'#f8f5ff':'rgba(247,240,223,.42)',fontWeight:entry.includes('!')||entry.includes('✓')||entry.includes('SURGE')?700:400}}>{entry}</li>)}
          </ul>
        </section>
      </aside>
    </div>
  </main>)
}

const s={
  panel:{border:'1px solid rgba(255,255,255,.12)',background:'rgba(10,14,24,.76)',borderRadius:24,padding:22,boxShadow:'0 24px 80px rgba(0,0,0,.35)'},
  header:{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:18,marginBottom:16,flexWrap:'wrap'},
  eyebrow:{color:'#c9a756',fontSize:12,fontWeight:900,letterSpacing:'.18em',textTransform:'uppercase',margin:0},
  title:{fontSize:22,margin:'4px 0'},
  btnRow:{display:'flex',gap:8,flexWrap:'wrap'},
  speedRow:{display:'flex',alignItems:'center',gap:5},
  speedLabel:{fontSize:11,color:'rgba(247,240,223,.5)',marginRight:4},
  speedBtn:{padding:'5px 10px',borderRadius:8,border:'1px solid rgba(255,255,255,.18)',background:'rgba(255,255,255,.07)',color:'#f7f0df',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'inherit'},
  speedActive:{background:'rgba(201,167,86,.28)',borderColor:'rgba(201,167,86,.7)',color:'#ffd86b'},
  autoBattleActive:{background:'rgba(248,113,113,.3)',borderColor:'rgba(248,113,113,.7)',color:'#fca5a5'},
  victoryBtn:{background:'linear-gradient(135deg,#22c55e,#16a34a)',border:'none',color:'white',fontWeight:900,padding:'10px 18px',borderRadius:999,cursor:'pointer'},
  defeatBtn:{background:'linear-gradient(135deg,#ef4444,#991b1b)',border:'none',color:'white',fontWeight:900,padding:'10px 18px',borderRadius:999,cursor:'pointer'},
  confirmBanner:{display:'flex',justifyContent:'space-between',alignItems:'center',gap:12,padding:'10px 16px',marginBottom:14,borderRadius:14,background:'rgba(134,239,172,.1)',border:'1px solid rgba(134,239,172,.35)',flexWrap:'wrap'},
  confirmBtn:{padding:'7px 14px',borderRadius:10,border:'1px solid rgba(134,239,172,.5)',background:'rgba(134,239,172,.15)',color:'#86efac',fontWeight:800,fontSize:13,cursor:'pointer',fontFamily:'inherit'},
  cancelBtn:{padding:'7px 14px',borderRadius:10,border:'1px solid rgba(248,113,113,.4)',background:'rgba(248,113,113,.1)',color:'#f87171',fontWeight:800,fontSize:13,cursor:'pointer',fontFamily:'inherit'},
  layout:{display:'grid',gridTemplateColumns:'196px minmax(0,1fr) 268px',gap:16,alignItems:'start'},
  gridCard:{border:'1px solid rgba(255,255,255,.11)',background:'rgba(255,255,255,.04)',borderRadius:18,padding:16},
  sidebar:{display:'grid',alignContent:'start',gap:12},
  card:{border:'1px solid rgba(255,255,255,.11)',background:'rgba(255,255,255,.055)',borderRadius:18,padding:16},
}

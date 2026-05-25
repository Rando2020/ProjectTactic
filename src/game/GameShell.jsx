import { useMemo, useState } from 'react'
import { createInitialGameState } from './state/initialGameState.js'
import { saveGame, loadGame, hasSave, deleteSave } from './state/saveSystem.js'
import { applyMissionRewards } from './state/progressionReducer.js'
import { getBattleMap } from './data/maps.js'
import { completeCurrentNode, generateRun, getCurrentNode } from './systems/floorGenerator.js'
import { generateBattleLoot } from './systems/lootSystem.js'
import { needsLaneReplacement, getBoonsInLane, getBoonLane } from './data/boons.js'
import MainMenu             from './screens/MainMenu.jsx'
import WorldMapScreen       from './screens/WorldMapScreen.jsx'
import TownScreen           from './screens/TownScreen.jsx'
import BattleScreen         from './screens/BattleScreen.jsx'
import ResultsScreen        from './screens/ResultsScreen.jsx'
import CharacterSheetScreen from './screens/CharacterSheetScreen.jsx'
import JobTreeScreen        from './screens/JobTreeScreen.jsx'
import RunMapScreen         from './screens/RunMapScreen.jsx'
import BoonPickScreen       from './screens/BoonPickScreen.jsx'
import BoonReplacementModal from './screens/BoonReplacementModal.jsx'
import LootScreen           from './screens/LootScreen.jsx'
import WandererScreen       from './screens/WandererScreen.jsx'
import DeploymentScreen     from './components/DeploymentScreen.jsx'
import StoryScene           from './components/StoryScene.jsx'
import QuestLog             from './components/QuestLog.jsx'
import CodexScreen          from './components/CodexScreen.jsx'
import SummonArchive        from './components/SummonArchive.jsx'
import PartyScreen          from './components/PartyScreen.jsx'
import InventoryScreen      from './components/InventoryScreen.jsx'
import JobBoard             from './components/JobBoard.jsx'
import InnScreen            from './components/InnScreen.jsx'

const BATTLE_SCREENS = new Set(['deployment','battle'])
const NAV = [['Menu','mainMenu'],['World','worldMap'],['Run','runMap'],['Town','town'],['Party','party'],['Jobs','jobTree'],['Inventory','inventory'],['Codex','codex'],['Summons','summons'],['Quests','quests']]
const RUN_FLOORS = 10

function hubState(state) {
  return {
    ...state,
    currentScreen: 'town',
    activeRun: null,
    pendingLoot: null,
  }
}

export default function GameShell() {
  const [gameState, setGameState] = useState(() => loadGame() ?? createInitialGameState())
  const [notice, setNotice] = useState('')
  const [deploymentSlots, setDeploymentSlots] = useState(null)
  const [pendingBoonReplacement, setPendingBoonReplacement] = useState(null)
  const activeMission = useMemo(() => getBattleMap(gameState.activeMissionId), [gameState.activeMissionId])

  function setScreen(s) { setGameState(g => ({ ...g, currentScreen: s })) }
  function startNewGame() { setGameState(hubState(createInitialGameState())); setDeploymentSlots(null); setNotice('New campaign started at the hub.') }
  function continueGame() { const s=loadGame(); if(s){setGameState(hubState(s));setDeploymentSlots(null);setNotice('Save loaded. Returned to hub.')}else startNewGame() }
  function persistGame() { saveGame(gameState); setNotice('Game saved.') }
  function clearSave() { deleteSave(); setNotice('Save deleted.') }

  function selectMission(missionId) {
    setDeploymentSlots(null)
    setGameState(g => ({ ...g, activeMissionId:missionId, currentScreen:'deployment' }))
  }
  function handleStartBattle(slots) { setDeploymentSlots(slots); setScreen('battle') }

  function completeActiveMission(battleResult = {}) {
    const mission = getBattleMap(gameState.activeMissionId)
    // Merge battle JP into rewards
    const enhancedMission = { ...mission, rewards:{ ...mission.rewards, battleJp: battleResult.battleJp ?? {}, clearBonus: battleResult.clearBonus ?? 0 } }
    setGameState(g => {
      const rewarded = applyMissionRewards(g, enhancedMission)
      if (!g.activeRun) return rewarded

      const drops = generateBattleLoot(battleResult.defeatedUnits ?? [], g.activeRun.seed, g.activeRun.currentFloor)
      return {
        ...rewarded,
        currentScreen: 'loot',
        pendingLoot: {
          missionName: mission.name,
          gold: enhancedMission.rewards.gold ?? 0,
          items: drops,
          floor: g.activeRun.currentFloor,
        },
      }
    })
    setNotice(gameState.activeRun ? 'Victory! Loot is ready.' : 'Victory! Rewards collected.')
  }

  function startRun(stageMissionId = gameState.activeMissionId) {
    const seed = Date.now() >>> 0
    const stage = getBattleMap(stageMissionId) ?? getBattleMap(gameState.activeMissionId)
    setGameState(g => ({
      ...g,
      activeMissionId: stage?.id ?? g.activeMissionId,
      activeRun: generateRun(seed, RUN_FLOORS, { missionId: stage?.id, name: stage?.name }),
      pendingLoot: null,
      claimedRunItems: [],
      lastRunSummary: null,
      currentScreen: 'runMap',
    }))
    setNotice(`${RUN_FLOORS}-floor run started.`)
  }

  function abandonRun(message = 'Run abandoned. Returned to hub.') {
    setDeploymentSlots(null)
    setGameState(g => hubState({
      ...g,
      lastRunSummary: g.activeRun ? {
        status: 'defeat',
        stageName: g.activeRun.stageName,
        floorsCleared: Math.max(0, (g.activeRun.currentFloor ?? 1) - 1),
        totalFloors: g.activeRun.totalFloors ?? RUN_FLOORS,
        runGold: g.activeRun.runGold ?? 0,
        boons: g.activeRun.activeBoons ?? [],
        items: g.claimedRunItems ?? [],
      } : g.lastRunSummary,
    }))
    setNotice(message)
  }

  function enterRunNode() {
    setGameState(g => {
      const run = g.activeRun
      if (!run) return { ...g, currentScreen: 'runMap' }
      const node = getCurrentNode(run)
      if (!node) return { ...g, currentScreen: 'runMap' }

      if (['battle', 'elite_battle', 'boss'].includes(node.type)) {
        return { ...g, activeMissionId: node.mapId, currentScreen: 'deployment' }
      }
      if (node.type === 'boon_pick') return { ...g, currentScreen: 'boonPick' }
      if (node.type === 'wanderer') return { ...g, currentScreen: 'wanderer' }

      return { ...g, activeRun: completeCurrentNode(run), currentScreen: 'runMap' }
    })
  }

  function chooseRunBoon(boon) {
    // Check if this boon would exceed a lane limit
    const activeBoons = gameState.activeRun?.activeBoons ?? []
    if (needsLaneReplacement(activeBoons, boon)) {
      // Show replacement modal
      const lane = getBoonLane(boon)
      const existingInLane = getBoonsInLane(activeBoons, lane)
      setPendingBoonReplacement({ incomingBoon: boon, existingBoons: existingInLane })
      return
    }

    // No replacement needed, add the boon normally
    addBoonToRun(boon)
  }

  function addBoonToRun(boon) {
    setGameState(g => {
      if (!g.activeRun) return { ...g, currentScreen: 'runMap' }
      const runWithBoon = {
        ...g.activeRun,
        activeBoons: [...(g.activeRun.activeBoons ?? []), boon],
      }
      return {
        ...g,
        activeRun: completeCurrentNode(runWithBoon),
        currentScreen: 'runMap',
      }
    })
    setNotice(`${boon.name} added to the run.`)
  }

  function confirmBoonReplacement(incomingBoon, replacedBoonId) {
    setGameState(g => {
      if (!g.activeRun) return { ...g, currentScreen: 'runMap' }
      // Replace the old boon with the new one
      const newBoons = (g.activeRun.activeBoons ?? [])
        .filter(b => b.id !== replacedBoonId)
        .concat(incomingBoon)
      const runWithBoon = {
        ...g.activeRun,
        activeBoons: newBoons,
      }
      return {
        ...g,
        activeRun: completeCurrentNode(runWithBoon),
        currentScreen: 'runMap',
      }
    })
    const replacedBoon = (gameState.activeRun?.activeBoons ?? []).find(b => b.id === replacedBoonId)
    const replacedName = replacedBoon?.name ?? 'old boon'
    setNotice(`Replaced ${replacedName} with ${incomingBoon.name}.`)
    setPendingBoonReplacement(null)
  }

  function cancelBoonReplacement() {
    setPendingBoonReplacement(null)
  }

  function claimLoot() {
    setGameState(g => {
      const items = g.pendingLoot?.items ?? []
      const completedRun = g.activeRun ? completeCurrentNode({
        ...g.activeRun,
        equipment: {
          ...(g.activeRun.equipment ?? {}),
          inventory: [...(g.activeRun.equipment?.inventory ?? []), ...items],
        },
        runGold: (g.activeRun.runGold ?? 0) + (g.pendingLoot?.gold ?? 0),
      }) : null
      const completed = completedRun?.completed
      const allItems = [...(g.claimedRunItems ?? []), ...items]

      return {
        ...g,
        activeRun: completed ? null : completedRun,
        claimedRunItems: allItems,
        pendingLoot: null,
        lastRunSummary: completed ? {
          status: 'victory',
          stageName: completedRun.stageName,
          floorsCleared: completedRun.totalFloors,
          totalFloors: completedRun.totalFloors,
          runGold: completedRun.runGold ?? 0,
          boons: completedRun.activeBoons ?? [],
          items: allItems,
        } : g.lastRunSummary,
        currentScreen: completed ? 'results' : 'runMap',
      }
    })
    setNotice('Loot claimed.')
  }

  function finishWandererNode(result = {}) {
    setGameState(g => {
      if (!g.activeRun) return { ...g, currentScreen: 'runMap' }
      const reward = result.reward
      const learnedSecretSkills = reward?.type === 'secret_skill'
        ? Array.from(new Set([...(g.learnedSecretSkills ?? []), reward.skillId]))
        : g.learnedSecretSkills ?? []
      return {
        ...g,
        gold: Math.max(0, (g.gold ?? 0) - (result.cost ?? 0)),
        learnedSecretSkills,
        activeRun: completeCurrentNode(g.activeRun),
        currentScreen: 'runMap',
      }
    })
    setNotice('Wanderer encounter resolved.')
  }

  const p = { gameState, setGameState, activeMission, setScreen, selectMission, completeActiveMission, persistGame }
  const { currentScreen } = gameState
  const showNav = !BATTLE_SCREENS.has(currentScreen)
  const activeRunNode = gameState.activeRun ? getCurrentNode(gameState.activeRun) : null

  return (
    <div style={{ minHeight:'100vh',background:'radial-gradient(circle at top left,#172033 0,#090b12 42%,#05060a 100%)',color:'#f7f0df',fontFamily:'Inter,ui-sans-serif,system-ui,-apple-system,sans-serif' }}>
      <div style={{ maxWidth:1280,margin:'0 auto',padding:24 }}>
        {showNav && (
          <header style={{ display:'flex',alignItems:'center',justifyContent:'space-between',gap:16,marginBottom:20,flexWrap:'wrap' }}>
            <div>
              <div style={{ letterSpacing:'.22em',textTransform:'uppercase',color:'#c9a756',fontSize:12 }}>Vaelthar</div>
              <h1 style={{ margin:'4px 0 0',fontSize:26 }}>Eidolon Chronicles</h1>
            </div>
            <nav style={{ display:'flex',gap:6,flexWrap:'wrap',justifyContent:'flex-end' }}>
              {NAV.map(([label,screen]) => (
                <button key={screen} style={{ padding:'8px 13px',borderRadius:999,border:'1px solid rgba(255,255,255,.18)',background:currentScreen===screen?'rgba(201,167,86,.22)':'rgba(255,255,255,.07)',color:'#f7f0df',fontWeight:700,fontSize:13,cursor:'pointer',borderColor:currentScreen===screen?'rgba(201,167,86,.6)':'' }} onClick={()=>setScreen(screen)}>{label}</button>
              ))}
              <button style={{ padding:'8px 13px',borderRadius:999,border:'1px solid rgba(255,255,255,.18)',background:'rgba(255,255,255,.07)',color:'#f7f0df',fontWeight:700,fontSize:13,cursor:'pointer' }} onClick={persistGame}>Save</button>
            </nav>
          </header>
        )}
        {notice&&<div style={{ border:'1px solid rgba(201,167,86,.35)',background:'rgba(201,167,86,.1)',padding:12,borderRadius:12,marginBottom:16,fontSize:13 }}>{notice}</div>}
        {currentScreen==='mainMenu'        && <MainMenu hasSave={hasSave()} onNewGame={startNewGame} onContinue={continueGame} onDeleteSave={clearSave} onWorld={()=>setScreen('worldMap')}/>}
        {currentScreen==='worldMap'        && <WorldMapScreen {...p} onStartStageRun={startRun}/>}
        {currentScreen==='runMap'          && <RunMapScreen {...p} onStartRun={startRun} onEnterRunNode={enterRunNode}/>}
        {currentScreen==='boonPick'        && <BoonPickScreen {...p} onChooseBoon={chooseRunBoon}/>}
        {currentScreen==='loot'            && <LootScreen {...p} onClaimLoot={claimLoot}/>}
        {currentScreen==='wanderer'&&activeRunNode?.wanderer && (
          <WandererScreen
            {...p}
            run={gameState.activeRun}
            wanderer={activeRunNode.wanderer}
            onAccept={finishWandererNode}
            onDecline={() => finishWandererNode()}
            onLeave={() => setScreen('runMap')}
          />
        )}
        {currentScreen==='town'            && <TownScreen {...p}/>}
        {currentScreen==='deployment'&&activeMission && <DeploymentScreen map={activeMission} onStartBattle={handleStartBattle} onCancel={()=>gameState.activeRun?abandonRun():setScreen('worldMap')}/>}
        {currentScreen==='battle'&&activeMission && <BattleScreen {...p} deploymentSlots={deploymentSlots} onDefeat={() => abandonRun('Defeat. Returned to hub to start over.')}/>}
        {currentScreen==='results'         && <ResultsScreen {...p}/>}
        {currentScreen==='characterSheet'  && <CharacterSheetScreen {...p}/>}
        {currentScreen==='jobTree'         && <JobTreeScreen {...p}/>}
        {currentScreen==='party'           && <PartyScreen {...p}/>}
        {currentScreen==='inventory'       && <InventoryScreen {...p}/>}
        {currentScreen==='codex'           && <CodexScreen {...p}/>}
        {currentScreen==='summons'         && <SummonArchive {...p}/>}
        {currentScreen==='quests'          && <QuestLog {...p}/>}
        {currentScreen==='story'           && <StoryScene {...p}/>}
        {currentScreen==='jobBoard'        && <JobBoard {...p}/>}
        {currentScreen==='inn'             && <InnScreen {...p}/>}
      </div>
      {pendingBoonReplacement && (
        <BoonReplacementModal
          incomingBoon={pendingBoonReplacement.incomingBoon}
          existingBoons={pendingBoonReplacement.existingBoons}
          onConfirm={confirmBoonReplacement}
          onCancel={cancelBoonReplacement}
        />
      )}
    </div>
  )
}

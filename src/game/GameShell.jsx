import { useMemo, useState } from 'react'
import { createInitialGameState } from './state/initialGameState.js'
import { saveGame, loadGame, hasSave, deleteSave } from './state/saveSystem.js'
import { applyMissionRewards } from './state/progressionReducer.js'
import { getBattleMap } from './data/maps.js'
import { getRunNode } from './data/runNodes.js'
import { createRun } from './systems/run/createRun.js'
import { selectRunNode as selectRunNodeState, completeRunNode, skipRunReward as skipRunRewardState } from './systems/run/advanceRun.js'
import { applyDraftReward } from './systems/run/applyDraftReward.js'
import MainMenu             from './screens/MainMenu.jsx'
import WorldMapScreen       from './screens/WorldMapScreen.jsx'
import TownScreen           from './screens/TownScreen.jsx'
import BattleScreen         from './screens/BattleScreen.jsx'
import ResultsScreen        from './screens/ResultsScreen.jsx'
import CharacterSheetScreen from './screens/CharacterSheetScreen.jsx'
import JobTreeScreen        from './screens/JobTreeScreen.jsx'
import RunMapScreen         from './screens/RunMapScreen.jsx'
import RewardDraftScreen    from './screens/RewardDraftScreen.jsx'
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

export default function GameShell() {
  const [gameState, setGameState] = useState(() => loadGame() ?? createInitialGameState())
  const [notice, setNotice] = useState('')
  const [deploymentSlots, setDeploymentSlots] = useState(null)
  const activeMission = useMemo(() => getBattleMap(gameState.activeMissionId), [gameState.activeMissionId])

  function setScreen(s) { setGameState(g => ({ ...g, currentScreen: s })) }
  function startNewGame() { setGameState(createInitialGameState()); setNotice('New campaign started.') }
  function continueGame() { const s=loadGame(); if(s){setGameState(s);setNotice('Save loaded.')}else startNewGame() }
  function persistGame() { saveGame(gameState); setNotice('Game saved.') }
  function clearSave() { deleteSave(); setNotice('Save deleted.') }

  function selectMission(missionId) {
    setDeploymentSlots(null)
    setGameState(g => ({ ...g, activeMissionId:missionId, activeRunNodeId:null, currentScreen:'deployment' }))
  }
  function handleStartBattle(slots) { setDeploymentSlots(slots); setScreen('battle') }

  function startRun() {
    const run = createRun('first-route')
    setDeploymentSlots(null)
    setGameState(g => ({ ...g, currentRun:run, activeRunNodeId:null, currentScreen:'runMap' }))
    setNotice('Run started: The Burning Bell route.')
  }

  function selectRunNode(nodeId) {
    setGameState(g => {
      if (!g.currentRun) return g
      return { ...g, currentRun: selectRunNodeState(g.currentRun, nodeId), currentScreen:'runMap' }
    })
  }

  function startRunNode(nodeId) {
    const node = getRunNode(nodeId)
    if (!node) return

    if (node.missionId) {
      setDeploymentSlots(null)
      setGameState(g => ({ ...g, activeMissionId:node.missionId, activeRunNodeId:node.id, currentScreen:'deployment' }))
      setNotice(`${node.name} selected.`)
      return
    }

    setGameState(g => {
      if (!g.currentRun) return g
      return { ...g, currentRun: completeRunNode(g.currentRun, node.id), activeRunNodeId:node.id, currentScreen:'rewardDraft' }
    })
    setNotice(`${node.name} resolved. Choose a reward.`)
  }

  function completeActiveMission(battleResult = {}) {
    const mission = getBattleMap(gameState.activeMissionId)
    const enhancedMission = { ...mission, rewards:{ ...mission.rewards, battleJp: battleResult.battleJp ?? {}, clearBonus: battleResult.clearBonus ?? 0 } }

    setGameState(g => {
      const rewardedState = applyMissionRewards(g, enhancedMission)
      if (!g.activeRunNodeId || !g.currentRun) return rewardedState

      const nextRun = completeRunNode(g.currentRun, g.activeRunNodeId)
      const runComplete = nextRun.status === 'complete'
      return {
        ...rewardedState,
        currentRun: nextRun,
        activeRunNodeId: null,
        currentScreen: runComplete ? 'runMap' : 'rewardDraft',
        metaProgression: runComplete
          ? {
              ...(rewardedState.metaProgression ?? {}),
              completedRuns: (rewardedState.metaProgression?.completedRuns ?? 0) + 1,
              echoShards: (rewardedState.metaProgression?.echoShards ?? 0) + (nextRun.echoShardsEarned ?? 0),
            }
          : rewardedState.metaProgression,
      }
    })
    setNotice(gameState.activeRunNodeId ? 'Run node complete. Choose a draft reward.' : 'Victory! Rewards collected.')
  }

  function chooseRunReward(rewardId) {
    setGameState(g => {
      if (!g.currentRun) return g
      return { ...g, currentRun: applyDraftReward(g.currentRun, rewardId), currentScreen:'runMap' }
    })
    setNotice('Reward drafted. Choose the next route node.')
  }

  function skipRunReward() {
    setGameState(g => {
      if (!g.currentRun) return g
      return { ...g, currentRun: skipRunRewardState(g.currentRun), currentScreen:'runMap' }
    })
    setNotice('Reward skipped. Choose the next route node.')
  }

  const p = { gameState, setGameState, activeMission, setScreen, selectMission, completeActiveMission, persistGame, startRun, selectRunNode, startRunNode, chooseRunReward, skipRunReward }
  const { currentScreen } = gameState
  const showNav = !BATTLE_SCREENS.has(currentScreen)

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
        {currentScreen==='worldMap'        && <WorldMapScreen {...p}/>}
        {currentScreen==='runMap'          && <RunMapScreen {...p}/>}
        {currentScreen==='rewardDraft'     && <RewardDraftScreen {...p}/>}
        {currentScreen==='town'            && <TownScreen {...p}/>}
        {currentScreen==='deployment'&&activeMission && <DeploymentScreen map={activeMission} onStartBattle={handleStartBattle} onCancel={()=>setScreen(gameState.activeRunNodeId ? 'runMap' : 'worldMap')}/>}
        {currentScreen==='battle'&&activeMission && <BattleScreen {...p} deploymentSlots={deploymentSlots}/>}
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
    </div>
  )
}
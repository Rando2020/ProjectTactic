import { useMemo, useState } from 'react'
import { createInitialGameState } from './state/initialGameState.js'
import { saveGame, loadGame, hasSave, deleteSave } from './state/saveSystem.js'
import { applyMissionRewards } from './state/progressionReducer.js'
import { getBattleMap } from './data/maps.js'
import MainMenu from './screens/MainMenu.jsx'
import WorldMapScreen from './screens/WorldMapScreen.jsx'
import TownScreen from './screens/TownScreen.jsx'
import BattleScreen from './screens/BattleScreen.jsx'
import ResultsScreen from './screens/ResultsScreen.jsx'
import CharacterSheetScreen from './screens/CharacterSheetScreen.jsx'
import JobTreeScreen from './screens/JobTreeScreen.jsx'

const shellStyles = {
  minHeight: '100vh',
  background: 'radial-gradient(circle at top left, #172033 0, #090b12 42%, #05060a 100%)',
  color: '#f7f0df',
  fontFamily: 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
}

export default function GameShell() {
  const [gameState, setGameState] = useState(() => loadGame() ?? createInitialGameState())
  const [notice, setNotice] = useState('')

  const activeMission = useMemo(() => getBattleMap(gameState.activeMissionId), [gameState.activeMissionId])

  function setScreen(currentScreen) {
    setGameState((state) => ({ ...state, currentScreen }))
  }

  function startNewGame() {
    const nextState = createInitialGameState()
    setGameState(nextState)
    setNotice('New campaign started.')
  }

  function continueGame() {
    const saved = loadGame()
    if (saved) {
      setGameState(saved)
      setNotice('Save loaded.')
    } else {
      setNotice('No save found. Starting a new campaign.')
      startNewGame()
    }
  }

  function persistGame() {
    saveGame(gameState)
    setNotice('Game saved locally.')
  }

  function clearSave() {
    deleteSave()
    setNotice('Local save deleted.')
  }

  function selectMission(missionId) {
    setGameState((state) => ({ ...state, activeMissionId: missionId, currentScreen: 'battle' }))
  }

  function completeActiveMission() {
    const mission = getBattleMap(gameState.activeMissionId)
    setGameState((state) => applyMissionRewards(state, mission))
  }

  const commonProps = {
    gameState,
    setGameState,
    activeMission,
    setScreen,
    selectMission,
    completeActiveMission,
    persistGame,
  }

  return (
    <div style={shellStyles}>
      <div style={{ maxWidth: 1280, margin: '0 auto', padding: '24px' }}>
        <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 20 }}>
          <div>
            <div style={{ letterSpacing: '0.22em', textTransform: 'uppercase', color: '#c9a756', fontSize: 12 }}>Vaelthar</div>
            <h1 style={{ margin: '4px 0 0', fontSize: 28 }}>Eidolon Chronicles</h1>
          </div>
          <nav style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
            <button onClick={() => setScreen('mainMenu')}>Menu</button>
            <button onClick={() => setScreen('worldMap')}>World</button>
            <button onClick={() => setScreen('town')}>Town</button>
            <button onClick={() => setScreen('characterSheet')}>Characters</button>
            <button onClick={() => setScreen('jobTree')}>Jobs</button>
            <button onClick={persistGame}>Save</button>
          </nav>
        </header>

        {notice && (
          <div style={{ border: '1px solid rgba(201,167,86,.35)', background: 'rgba(201,167,86,.1)', padding: 12, borderRadius: 12, marginBottom: 16 }}>
            {notice}
          </div>
        )}

        {gameState.currentScreen === 'mainMenu' && (
          <MainMenu
            hasSave={hasSave()}
            onNewGame={startNewGame}
            onContinue={continueGame}
            onDeleteSave={clearSave}
            onWorld={() => setScreen('worldMap')}
          />
        )}
        {gameState.currentScreen === 'worldMap' && <WorldMapScreen {...commonProps} />}
        {gameState.currentScreen === 'town' && <TownScreen {...commonProps} />}
        {gameState.currentScreen === 'battle' && <BattleScreen {...commonProps} />}
        {gameState.currentScreen === 'results' && <ResultsScreen {...commonProps} />}
        {gameState.currentScreen === 'characterSheet' && <CharacterSheetScreen {...commonProps} />}
        {gameState.currentScreen === 'jobTree' && <JobTreeScreen {...commonProps} />}
      </div>
    </div>
  )
}

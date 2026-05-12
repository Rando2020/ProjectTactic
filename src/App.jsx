import { useState } from 'react'
import VaeltharChronicles from './game/VaeltharChronicles.jsx'
import GameShell from './game/GameShell.jsx'
import CharacterCompendium from './features/character/CharacterCompendium.jsx'
import './game/styles/gameShell.css'

const isDev = new URLSearchParams(window.location.search).has('dev')

export default function App() {
  const [view, setView] = useState('gameShell')

  return (
    <div className="app-shell">
      {isDev && (
        <div className="app-toolbar">
          <button
            type="button"
            className={`app-tab ${view === 'gameShell' ? 'is-active' : ''}`}
            onClick={() => setView('gameShell')}
          >
            Game Shell
          </button>
          <button
            type="button"
            className={`app-tab ${view === 'compendium' ? 'is-active' : ''}`}
            onClick={() => setView('compendium')}
          >
            Character Compendium
          </button>
          <button
            type="button"
            className={`app-tab ${view === 'battle' ? 'is-active' : ''}`}
            onClick={() => setView('battle')}
          >
            Battle Prototype
          </button>
        </div>
      )}

      {view === 'gameShell' && <GameShell />}
      {isDev && view === 'compendium' && <CharacterCompendium />}
      {isDev && view === 'battle' && <VaeltharChronicles />}
    </div>
  )
}

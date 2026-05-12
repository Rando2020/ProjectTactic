import { useState } from 'react'
import VaeltharChronicles from './game/VaeltharChronicles.jsx'
import GameShell from './game/GameShell.jsx'
import CharacterCompendium from './features/character/CharacterCompendium.jsx'
import './game/styles/gameShell.css'

export default function App() {
  const [view, setView] = useState('gameShell')

  return (
    <div className="app-shell">
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

      {view === 'gameShell' && <GameShell />}
      {view === 'compendium' && <CharacterCompendium />}
      {view === 'battle' && <VaeltharChronicles />}
    </div>
  )
}

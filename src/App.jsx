import { useState } from 'react'
import VaeltharChronicles from './game/VaeltharChronicles.jsx'
import CharacterCompendium from './features/character/CharacterCompendium.jsx'

export default function App() {
  const [view, setView] = useState('compendium')

  return (
    <div className="app-shell">
      <div className="app-toolbar">
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

      {view === 'compendium' ? <CharacterCompendium /> : <VaeltharChronicles />}
    </div>
  )
}

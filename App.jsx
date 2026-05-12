import { useState } from 'react'
import VaeltharChronicles from './VaeltharChronicles'
import TacticsBoardPrototype from './TacticsBoardPrototype'

function TitleScreen({ onStartCore, onStartTactics }) {
  return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', color: '#f5f6ff', background: 'radial-gradient(circle at 30% 20%, #202856 0%, #080b1f 50%, #040412 100%)', fontFamily: 'system-ui' }}>
      <div style={{ textAlign: 'center', maxWidth: 720, padding: 24 }}>
        <h1 style={{ fontSize: 44, marginBottom: 8, letterSpacing: 1 }}>Vaelthar: Eidolon Chronicles</h1>
        <p style={{ opacity: .85, marginBottom: 20 }}>Tactical fantasy RPG prototype — elemental timing meets battlefield strategy.</p>
        <div style={{ display: 'grid', gap: 10, justifyContent: 'center' }}>
          <button onClick={onStartCore} style={{ padding: '10px 18px', fontSize: 16 }}>Start Core Combat</button>
          <button onClick={onStartTactics} style={{ padding: '10px 18px', fontSize: 16 }}>Open Tactics Sandbox</button>
        </div>
      </div>
    </div>
  )
}

export default function App() {
  const [mode, setMode] = useState('title')

  if (mode === 'title') {
    return <TitleScreen onStartCore={() => setMode('chronicles')} onStartTactics={() => setMode('tactics')} />
  }

  return (
    <>
      <div style={{ position: 'fixed', top: 8, right: 8, zIndex: 9999, display: 'flex', gap: 8 }}>
        <button onClick={() => setMode('title')}>Title</button>
        <button onClick={() => setMode('chronicles')}>Core Combat</button>
        <button onClick={() => setMode('tactics')}>Tactics Prototype</button>
      </div>
      {mode === 'chronicles' ? <VaeltharChronicles /> : <TacticsBoardPrototype />}
    </>
  )
}

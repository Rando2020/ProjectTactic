import { getUnlockedCodexEntries } from '../data/codex.js'

export default function CodexScreen({ storyFlags, onBack }) {
  const entries = getUnlockedCodexEntries(storyFlags)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Archive</p>
            <h1 className="v-title">Codex</h1>
            <p className="v-copy">Mechanics and lore unlock as the player discovers them.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back</button>
        </header>

        {entries.length === 0 ? (
          <div className="v-panel">
            <h2>No entries unlocked yet</h2>
            <p className="v-copy">Continue the prologue to unlock the first Codex topics.</p>
          </div>
        ) : (
          <div className="v-grid">
            {entries.map((entry) => (
              <article key={entry.id} className="v-list-card">
                <span className="v-pill">{entry.category}</span>
                <h2 style={{ margin: '10px 0 8px' }}>{entry.title}</h2>
                <p className="v-copy">{entry.summary}</p>
                <p className="v-copy" style={{ color: 'var(--gold)' }}>{entry.gameplayNote}</p>
              </article>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}

import { getGuardians } from '../data/summons.js'

export default function SummonArchive({ storyFlags, onBack }) {
  const flags = new Set(storyFlags)
  const guardians = getGuardians()

  const isVisible = (guardian) => {
    if (guardian.status === 'locked') return flags.has('stormglass_unlocked')
    if (guardian.status === 'rumored') return flags.has('mirefen_unlocked') || flags.has('stormglass_unlocked')
    return true
  }

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Shrine Archive</p>
            <h1 className="v-title">Guardians</h1>
            <p className="v-copy">Track Guardian lore, summon roles, corruption status, and future Resonance unlock conditions.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back to Town</button>
        </header>

        <div className="v-grid">
          {guardians.filter(isVisible).map((guardian) => (
            <article key={guardian.id} className="v-panel">
              <span className="v-pill">{guardian.element} · {guardian.tier}</span>
              <h2 style={{ marginBottom: 4 }}>{guardian.name}</h2>
              <p className="v-subtitle">Status: {guardian.status}</p>
              <p className="v-copy">{guardian.description}</p>
              <p className="v-copy"><strong>Combat role:</strong> {guardian.combatRole}</p>
              <p className="v-copy"><strong>Unlock:</strong> {guardian.unlock}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}

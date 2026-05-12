import { getJobs } from '../data/jobs.js'

export default function JobBoard({ onBack }) {
  const jobs = getJobs()

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Guild Hall</p>
            <h1 className="v-title">Job Board</h1>
            <p className="v-copy">Preview classes, unlock requirements, growth direction, passives, reactions, and ascended paths.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back to Town</button>
        </header>

        <div className="v-grid">
          {jobs.map((job) => (
            <article key={job.id} className="v-panel">
              <span className="v-pill">{job.tier} · {job.role}</span>
              <h2 style={{ marginBottom: 4 }}>{job.name}</h2>
              <p className="v-subtitle">Unlock: {job.unlock}</p>
              <p className="v-copy">{job.description}</p>

              <div className="v-grid-3" style={{ margin: '14px 0' }}>
                <div className="v-list-card"><span className="v-pill">Move</span><h3>{job.moveMod >= 0 ? `+${job.moveMod}` : job.moveMod}</h3></div>
                <div className="v-list-card"><span className="v-pill">Jump</span><h3>{job.jumpMod >= 0 ? `+${job.jumpMod}` : job.jumpMod}</h3></div>
                <div className="v-list-card"><span className="v-pill">Ascends</span><h3>{job.ascendsTo || 'None'}</h3></div>
              </div>

              <p className="v-copy"><strong>Weapons:</strong> {job.weaponTypes.join(', ')}</p>
              <p className="v-copy"><strong>Abilities:</strong> {job.abilities.join(' · ')}</p>
              <p className="v-copy"><strong>Reaction:</strong> {job.reaction}</p>
              <p className="v-copy"><strong>Passive:</strong> {job.passive}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}

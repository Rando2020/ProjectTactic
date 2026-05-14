import { getPartyMembers } from '../data/party.js'
import { getJob, STARTING_JOB_LEVELS } from '../data/jobs.js'
import { getCharacterArcWithArchetype } from '../data/characterArcs.js'

export default function PartyScreen({ partyIds, onBack }) {
  const members = getPartyMembers(partyIds)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Preparation</p>
            <h1 className="v-title">Party</h1>
            <p className="v-copy">Review the current roster, combat role, job, armor profile, and future build direction.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back to Town</button>
        </header>

        <div className="v-grid">
          {members.map((member) => {
            const job = getJob(member.jobId)
            const jobLevels = STARTING_JOB_LEVELS[member.id] || {}
            const arc = getCharacterArcWithArchetype(member.id)
            return (
              <article key={member.id} className="v-panel">
                <span className="v-pill">Lv. {member.level} · {member.role}</span>
                <h2 style={{ marginBottom: 4 }}>{member.name}</h2>
                <p className="v-subtitle">Current Job: {job?.name || member.jobId}</p>
                <p className="v-copy">{member.bio}</p>

                {arc && (
                  <div className="v-list-card" style={{ margin: '16px 0' }}>
                    <span className="v-pill">Cycle Role · {arc.archetype?.name}</span>
                    <p className="v-copy" style={{ marginTop: 8 }}>{member.storyHook || arc.historicalEcho}</p>
                    <p className="v-copy" style={{ marginTop: 8 }}><strong>Breaks the cycle by:</strong> {arc.destroysTheCycleBy}</p>
                  </div>
                )}

                <div className="v-grid-3" style={{ margin: '16px 0' }}>
                  <div className="v-list-card"><span className="v-pill">HP</span><h3>{member.hp}</h3></div>
                  <div className="v-list-card"><span className="v-pill">Temper</span><h3>{member.temper}</h3></div>
                  <div className="v-list-card"><span className="v-pill">Ether</span><h3>{member.ether}</h3></div>
                </div>

                <div className="v-stack">
                  <div>
                    <strong>Traits</strong>
                    <p className="v-copy">{member.traits.join(' · ')}</p>
                  </div>
                  <div>
                    <strong>Known job levels</strong>
                    <p className="v-copy">
                      {Object.entries(jobLevels).map(([jobId, level]) => `${getJob(jobId)?.name || jobId} Lv. ${level}`).join(' · ') || 'None'}
                    </p>
                  </div>
                  {arc && (
                    <div>
                      <strong>Signature line</strong>
                      <p className="v-copy">“{arc.sampleLine}”</p>
                    </div>
                  )}
                </div>
              </article>
            )
          })}
        </div>
      </section>
    </main>
  )
}

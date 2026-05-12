import { QUESTS } from '../data/quests.js'

export default function QuestLog({ activeQuestIds, completedQuestIds, onBack }) {
  const activeSet = new Set(activeQuestIds)
  const completedSet = new Set(completedQuestIds)
  const quests = Object.values(QUESTS)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Journal</p>
            <h1 className="v-title">Quest Log</h1>
            <p className="v-copy">Track main objectives, rewards, and progression gates.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back</button>
        </header>

        <div className="v-stack">
          {quests.map((quest) => {
            const status = completedSet.has(quest.id) ? 'Completed' : activeSet.has(quest.id) ? 'Active' : 'Locked'
            return (
              <article key={quest.id} className="v-list-card">
                <span className="v-pill">{status}</span>
                <h2 style={{ margin: '10px 0 6px' }}>{quest.title}</h2>
                <p className="v-copy" style={{ marginTop: 0 }}>{quest.description}</p>
                <ul style={{ marginBottom: 0 }}>
                  {quest.objectives.map((objective) => (
                    <li key={objective.id} style={{ color: 'rgba(248,245,255,0.82)', marginBottom: 6 }}>{objective.text}</li>
                  ))}
                </ul>
              </article>
            )
          })}
        </div>
      </section>
    </main>
  )
}

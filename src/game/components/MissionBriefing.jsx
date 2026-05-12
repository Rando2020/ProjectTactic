import { getMission } from '../data/missions.js'

export default function MissionBriefing({ missionId, onBack, onLaunch }) {
  const mission = getMission(missionId)

  if (!mission) {
    return (
      <main className="v-shell">
        <section className="v-card">
          <p className="v-eyebrow">Mission unavailable</p>
          <h1 className="v-title">No mission found</h1>
          <button className="v-btn" onClick={onBack}>Back</button>
        </section>
      </main>
    )
  }

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Mission Briefing</p>
            <h1 className="v-title">{mission.title}</h1>
            <p className="v-subtitle">{mission.subtitle} · Recommended Lv. {mission.recommendedLevel} · {mission.difficulty}</p>
          </div>
          <div className="v-btn-row">
            <button className="v-btn" onClick={onBack}>Back</button>
            <button className="v-btn v-btn-primary" onClick={() => onLaunch(mission.id)}>Launch Mission</button>
          </div>
        </header>

        <div className="v-grid">
          <section className="v-panel">
            <span className="v-pill">Objective</span>
            <h2>{mission.objective}</h2>
            <p className="v-copy">Biome: {mission.biome}</p>
            <p className="v-copy">Terrain: {mission.map.terrain}. {mission.map.elevationNotes}</p>
          </section>

          <section className="v-panel">
            <span className="v-pill">Enemy preview</span>
            <div className="v-stack" style={{ marginTop: 12 }}>
              {mission.enemyPreview.map((enemy) => (
                <div key={enemy} className="v-list-card">{enemy}</div>
              ))}
            </div>
          </section>
        </div>

        <div className="v-grid" style={{ marginTop: 18 }}>
          <section className="v-panel">
            <span className="v-pill">Bonus objectives</span>
            <ul>
              {mission.bonusObjectives.map((objective) => (
                <li key={objective} style={{ marginBottom: 8, color: 'rgba(248,245,255,0.82)' }}>{objective}</li>
              ))}
            </ul>
          </section>

          <section className="v-panel">
            <span className="v-pill">Rewards</span>
            <p className="v-copy">JP: {mission.rewards.jp}</p>
            <p className="v-copy">Gold: {mission.rewards.gold}</p>
            <p className="v-copy">Items: {mission.rewards.items.join(', ')}</p>
          </section>
        </div>
      </section>
    </main>
  )
}

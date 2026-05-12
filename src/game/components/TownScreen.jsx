import { getQuestsForTown } from '../data/quests.js'
import { getMissionsForTown } from '../data/missions.js'

const serviceModeMap = {
  Inn: 'inn',
  Market: 'inventory',
  'Reed Market': 'inventory',
  Barracks: 'party',
  Glasswright: 'jobs',
  'Training Yard': 'jobs',
  'Timing Trials': 'jobs',
  'Mission Board': 'missionBoard',
  Shrine: 'summons'
}

const getServiceTarget = (service) => serviceModeMap[service] || 'party'

export default function TownScreen({
  town,
  activeQuestIds,
  completedQuestIds,
  onBackToWorld,
  onStartMission,
  onOpenQuestLog,
  onOpenCodex,
  onOpenSettings,
  onOpenService
}) {
  const quests = getQuestsForTown(town.id)
  const missions = getMissionsForTown(town.id)
  const activeSet = new Set(activeQuestIds)
  const completedSet = new Set(completedQuestIds)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">{town.region}</p>
            <h1 className="v-title">{town.name}</h1>
            <p className="v-subtitle">{town.subtitle}</p>
          </div>
          <div className="v-btn-row">
            <button className="v-btn" onClick={onOpenQuestLog}>Quest Log</button>
            <button className="v-btn" onClick={onOpenCodex}>Codex</button>
            <button className="v-btn" onClick={onOpenSettings}>Settings</button>
            <button className="v-btn" onClick={onBackToWorld}>World Map</button>
          </div>
        </header>

        <p className="v-copy" style={{ fontSize: 18 }}>{town.description}</p>
        <p className="v-subtitle" style={{ marginBottom: 22 }}>“{town.ambientLine}”</p>

        <div className="v-grid">
          <section className="v-panel">
            <h2>People</h2>
            <div className="v-stack">
              {town.npcs.map((npc) => (
                <article key={npc.id} className="v-list-card">
                  <h3 style={{ margin: 0 }}>{npc.name}</h3>
                  <p className="v-subtitle" style={{ marginTop: 4 }}>{npc.role}</p>
                  <p className="v-copy" style={{ marginBottom: 0 }}>“{npc.line}”</p>
                </article>
              ))}
            </div>
          </section>

          <section className="v-panel">
            <h2>Services</h2>
            <div className="v-grid" style={{ gridTemplateColumns: 'repeat(2, minmax(0, 1fr))' }}>
              <button className="v-btn" onClick={() => onOpenService('party')}>Party</button>
              <button className="v-btn" onClick={() => onOpenService('inventory')}>Inventory</button>
              <button className="v-btn" onClick={() => onOpenService('jobs')}>Job Board</button>
              <button className="v-btn" onClick={() => onOpenService('summons')}>Shrine Archive</button>
              {town.services.map((service) => (
                <button key={service} className="v-btn" onClick={() => onOpenService(getServiceTarget(service))}>
                  {service}
                </button>
              ))}
            </div>

            <h2 style={{ marginTop: 24 }}>Mission Board</h2>
            <div className="v-stack">
              {missions.map((mission) => {
                const quest = quests.find((q) => q.id === mission.questId)
                const isActive = activeSet.has(mission.questId)
                const isComplete = completedSet.has(mission.questId)
                return (
                  <article key={mission.id} className="v-list-card">
                    <span className="v-pill">{mission.difficulty} · Lv. {mission.recommendedLevel}</span>
                    <h3 style={{ marginBottom: 6 }}>{mission.title}</h3>
                    <p className="v-copy" style={{ marginTop: 0 }}>{mission.objective}</p>
                    {quest && <p className="v-subtitle">Quest: {quest.title}</p>}
                    <button
                      className="v-btn v-btn-primary"
                      disabled={!isActive || isComplete}
                      onClick={() => onStartMission(mission.id)}
                    >
                      {isComplete ? 'Completed' : isActive ? 'Open Briefing' : 'Locked'}
                    </button>
                  </article>
                )
              })}
            </div>
          </section>
        </div>
      </section>
    </main>
  )
}

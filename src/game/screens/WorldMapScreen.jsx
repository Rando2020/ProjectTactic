import { BATTLE_MAPS } from '../data/maps.js'

export default function WorldMapScreen({ gameState, selectMission, setScreen }) {
  const missions = Object.values(BATTLE_MAPS).filter((mission) => gameState.unlockedMissions.includes(mission.id))

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Campaign route</p>
          <h2>World Map</h2>
        </div>
        <button onClick={() => setScreen('town')}>Visit Town</button>
      </div>

      <div className="card-grid">
        {missions.map((mission) => (
          <article key={mission.id} className="content-card">
            <p className="eyebrow">{mission.region}</p>
            <h3>{mission.name}</h3>
            <p>{mission.objective.label}</p>
            <ul>
              <li>Map: {mission.size.width} × {mission.size.height}</li>
              <li>Enemies: {mission.enemySpawns.length}</li>
              <li>Rewards: {mission.rewards.gold}g, {mission.rewards.jp} JP</li>
            </ul>
            <button onClick={() => selectMission(mission.id)}>Deploy</button>
          </article>
        ))}
      </div>
    </main>
  )
}

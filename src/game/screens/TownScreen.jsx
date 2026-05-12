import { TOWNS } from '../data/towns.js'

export default function TownScreen({ gameState, setScreen }) {
  const unlockedTownIds = new Set(gameState.unlockedTowns ?? [])
  if (unlockedTownIds.has('ashvale_crossing')) unlockedTownIds.add('ashvale')
  const towns = Object.values(TOWNS ?? {}).filter((town) => unlockedTownIds.has(town.id))

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Preparation hub</p>
          <h2>Towns</h2>
        </div>
        <button onClick={() => setScreen('worldMap')}>Return to World</button>
      </div>

      <div className="card-grid">
        {towns.length === 0 && <p>No towns unlocked yet.</p>}
        {towns.map((town) => (
          <article key={town.id} className="content-card">
            <p className="eyebrow">{town.region}</p>
            <h3>{town.name}</h3>
            <p>{town.description}</p>
            <ul>
              {(town.services ?? []).map((service) => <li key={service}>{service}</li>)}
            </ul>
          </article>
        ))}
      </div>
    </main>
  )
}

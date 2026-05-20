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
          <h2>Hub</h2>
        </div>
        <button onClick={() => setScreen('worldMap')}>Stage Select</button>
      </div>

      <section className="content-card" style={{ marginBottom: 18 }}>
        <p className="eyebrow">Run flow</p>
        <h3>Choose a stage, clear 10 floors, bank the spoils.</h3>
        <p>Winning a run shows the full spoils report. Losing a battle returns the party here and the run starts over.</p>
        <div className="button-row">
          <button onClick={() => setScreen('worldMap')}>Choose Stage</button>
          <button onClick={() => setScreen('party')}>Party</button>
          <button onClick={() => setScreen('inventory')}>Inventory</button>
        </div>
      </section>

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

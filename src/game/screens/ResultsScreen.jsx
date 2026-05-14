export default function ResultsScreen({ gameState, setScreen, persistGame }) {
  const result = gameState.lastResult

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Mission complete</p>
          <h2>{result?.missionName ?? 'Battle Results'}</h2>
        </div>
        <div className="button-row">
          <button onClick={persistGame}>Save Progress</button>
          <button onClick={() => setScreen('worldMap')}>Return to World</button>
        </div>
      </div>

      {!result && <p>No mission result recorded yet.</p>}
      {result && (
        <div className="card-grid">
          <article className="content-card">
            <h3>Rewards</h3>
            <ul>
              <li>XP: {result.rewards.xp}</li>
              <li>JP: {result.rewards.jp}</li>
              <li>Gold: {result.rewards.gold}</li>
              <li>Items: {result.rewards.items.length ? result.rewards.items.join(', ') : 'None'}</li>
            </ul>
          </article>

          <article className="content-card">
            <h3>Campaign Flags</h3>
            <ul>
              {result.rewards.flags.map((flag) => <li key={flag}>{flag}</li>)}
            </ul>
          </article>

          <article className="content-card">
            <h3>Inventory</h3>
            <ul>
              {Object.entries(gameState.inventory).map(([itemId, count]) => <li key={itemId}>{itemId}: {count}</li>)}
            </ul>
          </article>
        </div>
      )}
    </main>
  )
}

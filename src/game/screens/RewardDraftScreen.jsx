import { getRunReward } from '../data/runRewards.js'

export default function RewardDraftScreen({ gameState, chooseRunReward, skipRunReward, setScreen }) {
  const run = gameState.currentRun
  const rewards = run?.pendingRewardIds?.map(getRunReward).filter(Boolean) ?? []

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Draft reward</p>
          <h2>Choose 1 of 3</h2>
        </div>
        <div className="button-row">
          <button onClick={() => setScreen('runMap')}>Run Map</button>
          <button onClick={skipRunReward}>Skip Reward</button>
        </div>
      </div>

      {!run && <p>No active run found.</p>}
      {run && rewards.length === 0 && (
        <article className="content-card">
          <h3>No pending rewards</h3>
          <p>Return to the run map to continue the route.</p>
          <button onClick={() => setScreen('runMap')}>Return to Run Map</button>
        </article>
      )}

      {rewards.length > 0 && (
        <div className="card-grid">
          {rewards.map((reward) => (
            <article key={reward.id} className="content-card">
              <p className="eyebrow">{reward.rarity} · {reward.type} · {reward.element}</p>
              <h3>{reward.name}</h3>
              <p><strong>{reward.summary}</strong></p>
              <p>{reward.description}</p>
              <button onClick={() => chooseRunReward(reward.id)}>Choose {reward.name}</button>
            </article>
          ))}
        </div>
      )}
    </main>
  )
}

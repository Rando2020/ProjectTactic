import { FIRST_RUN_NODES, getRunNode } from '../data/runNodes.js'
import { getRunModifiers } from '../data/runModifiers.js'
import { RUN_REWARDS, getRunReward } from '../data/runRewards.js'

function getNodeStatus(run, node) {
  if (!run) return 'locked'
  if (run.completedNodeIds?.includes(node.id)) return 'complete'
  if (run.currentNodeId === node.id) return 'current'
  if (run.availableNodeIds?.includes(node.id)) return 'available'
  return 'locked'
}

export default function RunMapScreen({ gameState, startRun, selectRunNode, startRunNode, setScreen }) {
  const run = gameState.currentRun
  const currentNode = run ? getRunNode(run.currentNodeId) : null
  const selectedRewards = run?.selectedRewardIds?.map(getRunReward).filter(Boolean) ?? []
  const activeModifiers = getRunModifiers(run?.activeModifierIds ?? [])

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Roguelite route</p>
          <h2>First Run: The Burning Bell</h2>
        </div>
        <div className="button-row">
          <button onClick={() => setScreen('worldMap')}>World Map</button>
          <button onClick={startRun}>{run ? 'Restart Run' : 'Start Run'}</button>
        </div>
      </div>

      {!run && (
        <article className="content-card">
          <h3>No active run</h3>
          <p>Start a route to chain battles, shrine choices, elite pressure, and draft rewards into a repeatable tactics roguelite loop.</p>
          <button onClick={startRun}>Start First Run</button>
        </article>
      )}

      {run && (
        <>
          <div className="card-grid">
            <article className="content-card">
              <p className="eyebrow">Run status</p>
              <h3>{run.status}</h3>
              <ul>
                <li>Seed: {run.seed}</li>
                <li>Current node: {currentNode?.name ?? 'None'}</li>
                <li>Echo Shards pending: {run.echoShardsEarned ?? 0}</li>
                <li>Completed nodes: {run.completedNodeIds.length}</li>
              </ul>
            </article>

            <article className="content-card">
              <p className="eyebrow">Build so far</p>
              <h3>Drafted rewards</h3>
              {selectedRewards.length === 0 && <p>No boons, relics, or pacts drafted yet.</p>}
              {selectedRewards.length > 0 && (
                <ul>
                  {selectedRewards.map((reward) => <li key={reward.id}><strong>{reward.name}</strong>: {reward.summary}</li>)}
                </ul>
              )}
            </article>

            <article className="content-card">
              <p className="eyebrow">Route pressure</p>
              <h3>Active modifiers</h3>
              {activeModifiers.length === 0 && <p>No route modifiers active yet.</p>}
              {activeModifiers.length > 0 && (
                <ul>
                  {activeModifiers.map((modifier) => <li key={modifier.id}><strong>{modifier.name}</strong>: {modifier.summary}</li>)}
                </ul>
              )}
            </article>
          </div>

          <section className="content-card" style={{ marginTop: 16 }}>
            <h3>Route Nodes</h3>
            <div className="card-grid">
              {FIRST_RUN_NODES.map((node) => {
                const status = getNodeStatus(run, node)
                const isSelectable = status === 'available' || status === 'current'
                return (
                  <article key={node.id} className="content-card" style={{ opacity: status === 'locked' ? .45 : 1 }}>
                    <p className="eyebrow">Depth {node.depth} · {node.label} · {status}</p>
                    <h3>{node.name}</h3>
                    <p>{node.description}</p>
                    {node.missionId && <p><strong>Mission:</strong> {node.missionId}</p>}
                    <div className="button-row">
                      <button disabled={!isSelectable} onClick={() => selectRunNode(node.id)}>Select</button>
                      <button disabled={run.currentNodeId !== node.id || run.status !== 'active'} onClick={() => startRunNode(node.id)}>
                        {node.missionId ? 'Deploy' : 'Resolve'}
                      </button>
                    </div>
                  </article>
                )
              })}
            </div>
          </section>
        </>
      )}
    </main>
  )
}

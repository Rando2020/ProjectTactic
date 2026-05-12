export default function BattleResultScreen({ result, onContinue, onRetry, onReturnToTown }) {
  if (!result) {
    return (
      <main className="v-shell">
        <section className="v-card">
          <p className="v-eyebrow">Battle Result</p>
          <h1 className="v-title">No result available</h1>
          <button className="v-btn" onClick={onReturnToTown}>Return to Town</button>
        </section>
      </main>
    )
  }

  const completedBonus = new Set(result.completedBonusObjectives)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Battle Result</p>
            <h1 className="v-title">{result.victory ? 'Victory' : 'Defeat'}</h1>
            <p className="v-subtitle">{result.title} · {result.difficulty} · Lv. {result.recommendedLevel}</p>
          </div>
          <div className="v-btn-row">
            {result.victory ? (
              <button className="v-btn v-btn-primary" onClick={onContinue}>Apply Rewards</button>
            ) : (
              <button className="v-btn v-btn-primary" onClick={onRetry}>Retry Mission</button>
            )}
            <button className="v-btn" onClick={onReturnToTown}>Return to Town</button>
          </div>
        </header>

        <section className="v-panel" style={{ marginBottom: 18 }}>
          <span className="v-pill">Main Objective</span>
          <h2 style={{ marginBottom: 6 }}>{result.victory ? 'Cleared' : 'Failed'}</h2>
          <p className="v-copy" style={{ margin: 0 }}>{result.objective}</p>
        </section>

        <div className="v-grid">
          <section className="v-panel">
            <h2>Bonus Objectives</h2>
            <div className="v-stack">
              {result.bonusObjectives.map((objective) => {
                const complete = completedBonus.has(objective)
                return (
                  <article key={objective} className="v-list-card" style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                    <span>{objective}</span>
                    <strong style={{ color: complete ? 'var(--gold)' : 'rgba(248,245,255,0.48)' }}>
                      {complete ? 'Complete' : 'Missed'}
                    </strong>
                  </article>
                )
              })}
            </div>
          </section>

          <section className="v-panel">
            <h2>Rewards</h2>
            <div className="v-grid-3">
              <article className="v-list-card"><span className="v-pill">JP</span><h3>{result.rewards.jp}</h3></article>
              <article className="v-list-card"><span className="v-pill">Gold</span><h3>{result.rewards.gold}</h3></article>
              <article className="v-list-card"><span className="v-pill">Items</span><h3>{result.rewards.items.length}</h3></article>
            </div>
            {result.rewards.items.length > 0 && (
              <p className="v-copy">Items earned: {result.rewards.items.join(', ')}</p>
            )}
          </section>
        </div>

        {result.victory && (
          <section className="v-panel" style={{ marginTop: 18 }}>
            <h2>Progression Unlocks</h2>
            <div className="v-grid-3">
              <article className="v-list-card"><span className="v-pill">Story Flags</span><p className="v-copy">{result.unlocks.flags.length ? result.unlocks.flags.join(', ') : 'None'}</p></article>
              <article className="v-list-card"><span className="v-pill">Towns</span><p className="v-copy">{result.unlocks.townIds.length ? result.unlocks.townIds.join(', ') : 'None'}</p></article>
              <article className="v-list-card"><span className="v-pill">Quests</span><p className="v-copy">{result.unlocks.questIds.length ? result.unlocks.questIds.join(', ') : 'None'}</p></article>
            </div>
          </section>
        )}
      </section>
    </main>
  )
}

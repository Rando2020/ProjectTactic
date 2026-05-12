export default function InnScreen({ town, gold, onRest, onBack }) {
  const restCost = 40
  const canRest = gold >= restCost

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Rest Point</p>
            <h1 className="v-title">{town.name} Inn</h1>
            <p className="v-copy">Restore the party before a mission. Later this can heal HP, MP, Temper, Ether, and clear minor status effects.</p>
          </div>
          <div className="v-btn-row">
            <span className="v-pill">Gold {gold}</span>
            <button className="v-btn" onClick={onBack}>Back to Town</button>
          </div>
        </header>

        <section className="v-panel">
          <span className="v-pill">Full Rest</span>
          <h2>Recover party resources</h2>
          <p className="v-copy">Cost: {restCost} gold</p>
          <p className="v-copy">Placeholder effect: records a rest event and spends gold. Future effect should restore combat resources and update party state.</p>
          <button className="v-btn v-btn-primary" disabled={!canRest} onClick={() => onRest(restCost)}>
            {canRest ? 'Rest Party' : 'Not Enough Gold'}
          </button>
        </section>
      </section>
    </main>
  )
}

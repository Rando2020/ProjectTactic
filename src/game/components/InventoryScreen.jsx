import { getInventoryEntries } from '../data/items.js'

export default function InventoryScreen({ inventory, gold, onBack }) {
  const entries = getInventoryEntries(inventory)

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Preparation</p>
            <h1 className="v-title">Inventory</h1>
            <p className="v-copy">Manage consumables and review tactical item roles before launching a mission.</p>
          </div>
          <div className="v-btn-row">
            <span className="v-pill">Gold {gold}</span>
            <button className="v-btn" onClick={onBack}>Back to Town</button>
          </div>
        </header>

        {entries.length === 0 ? (
          <section className="v-panel">
            <h2>Empty inventory</h2>
            <p className="v-copy">Visit a market or complete missions to collect consumables.</p>
          </section>
        ) : (
          <div className="v-grid">
            {entries.map(({ item, quantity }) => (
              <article key={item.id} className="v-panel">
                <span className="v-pill">{item.rarity} · {item.type}</span>
                <h2 style={{ marginBottom: 4 }}>{item.name} × {quantity}</h2>
                <p className="v-copy">{item.description}</p>
                <p className="v-subtitle">Combat use: {item.combatUse}</p>
                <p className="v-copy">Value: {item.value} gold</p>
              </article>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}

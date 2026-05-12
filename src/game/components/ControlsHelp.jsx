export default function ControlsHelp({ onBack }) {
  const rows = [
    ['Mouse / Tap', 'Select menus, advance dialogue, trigger SURGE or DEFLECT prompts'],
    ['Enter / Space', 'Advance dialogue or confirm the focused action'],
    ['Escape', 'Back out of menus or open pause later'],
    ['Arrow keys / WASD', 'Future grid navigation and menu movement'],
    ['Q', 'Quest log shortcut placeholder'],
    ['C', 'Codex shortcut placeholder'],
    ['S', 'Settings shortcut placeholder']
  ]

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Player support</p>
            <h1 className="v-title">Controls</h1>
            <p className="v-copy">Placeholder keyboard/controller help so input support can expand without redesigning menus.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back</button>
        </header>

        <div className="v-stack">
          {rows.map(([input, action]) => (
            <article key={input} className="v-list-card" style={{ display: 'grid', gridTemplateColumns: '180px 1fr', gap: 16 }}>
              <strong style={{ color: 'var(--gold)' }}>{input}</strong>
              <span style={{ color: 'rgba(248,245,255,0.82)' }}>{action}</span>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}

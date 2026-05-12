import { getRandomLoadingTip } from '../data/loadingTips.js'

export default function LoadingScreen({ label = 'Loading Vaelthar', onComplete }) {
  const tip = getRandomLoadingTip()

  return (
    <main className="v-shell" aria-live="polite">
      <section className="v-card" style={{ display: 'grid', gap: 22 }}>
        <div>
          <p className="v-eyebrow">{label}</p>
          <h1 className="v-title">Preparing the next scene</h1>
          <p className="v-copy">Loading screens should teach, reassure, and preserve momentum instead of showing a blank pause.</p>
        </div>

        <div className="v-panel">
          <span className="v-pill">Tip</span>
          <h2 style={{ marginBottom: 8 }}>{tip.title}</h2>
          <p className="v-copy" style={{ margin: 0 }}>{tip.body}</p>
        </div>

        <div aria-label="Loading progress" style={{ height: 14, borderRadius: 999, overflow: 'hidden', background: 'rgba(255,255,255,0.1)' }}>
          <div style={{ width: '72%', height: '100%', borderRadius: 999, background: 'linear-gradient(90deg, var(--violet), var(--orange))' }} />
        </div>

        <button className="v-btn v-btn-primary" onClick={onComplete}>Continue</button>
      </section>
    </main>
  )
}

import { COLORBLIND_MODES, DIFFICULTY_PRESETS } from '../data/settings.js'

export default function SettingsPanel({ settings, onChange, onBack }) {
  const update = (key, value) => onChange({ ...settings, [key]: value })

  return (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Options</p>
            <h1 className="v-title">Settings</h1>
            <p className="v-copy">Modern RPG settings should support pacing, accessibility, readability, and player control.</p>
          </div>
          <button className="v-btn" onClick={onBack}>Back</button>
        </header>

        <div className="v-grid">
          <section className="v-panel">
            <h2>Difficulty</h2>
            <div className="v-stack">
              {Object.entries(DIFFICULTY_PRESETS).map(([id, preset]) => (
                <button
                  key={id}
                  className={`v-btn ${settings.difficulty === id ? 'v-btn-primary' : ''}`}
                  onClick={() => update('difficulty', id)}
                  style={{ textAlign: 'left', borderRadius: 18 }}
                >
                  <strong>{preset.label}</strong>
                  <br />
                  <span style={{ color: 'rgba(255,255,255,0.74)' }}>{preset.description}</span>
                </button>
              ))}
            </div>
          </section>

          <section className="v-panel">
            <h2>Accessibility and UX</h2>
            <div className="v-stack">
              <label><input type="checkbox" checked={settings.reducedMotion} onChange={(e) => update('reducedMotion', e.target.checked)} /> Reduced motion</label>
              <label><input type="checkbox" checked={settings.highContrast} onChange={(e) => update('highContrast', e.target.checked)} /> High contrast</label>
              <label><input type="checkbox" checked={settings.largeText} onChange={(e) => update('largeText', e.target.checked)} /> Larger text</label>
              <label><input type="checkbox" checked={settings.autoSave} onChange={(e) => update('autoSave', e.target.checked)} /> Auto-save</label>
              <label><input type="checkbox" checked={settings.showBattleForecast} onChange={(e) => update('showBattleForecast', e.target.checked)} /> Battle forecast</label>
              <label>
                Colorblind mode<br />
                <select value={settings.colorblindMode} onChange={(e) => update('colorblindMode', e.target.value)} style={selectStyle}>
                  {COLORBLIND_MODES.map((mode) => <option key={mode.id} value={mode.id}>{mode.label}</option>)}
                </select>
              </label>
            </div>
          </section>
        </div>
      </section>
    </main>
  )
}

const selectStyle = {
  width: '100%',
  marginTop: 8,
  padding: 12,
  borderRadius: 12,
  border: '1px solid rgba(255,255,255,0.18)',
  background: '#101225',
  color: 'white'
}

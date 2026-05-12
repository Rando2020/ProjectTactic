export default function DamagePreviewPanel({ preview, onConfirm, onCancel }) {
  if (!preview) {
    return (
      <section className="content-card damage-preview-card">
        <p className="eyebrow">Damage Preview</p>
        <p className="muted">Select an enemy while Attack is active to preview HP damage, Temper break, facing bonus, and KO result.</p>
      </section>
    )
  }

  return (
    <section className="content-card damage-preview-card is-armed">
      <p className="eyebrow">Confirm Attack</p>
      <h3>{preview.targetName}</h3>
      <div className="preview-stat-grid">
        <span><strong>{preview.hpDamage}</strong><small>HP Damage</small></span>
        <span><strong>{preview.armorBreak}</strong><small>Temper Break</small></span>
        <span><strong>{preview.hitChance}%</strong><small>Hit Chance</small></span>
        <span><strong>{preview.facingLabel}</strong><small>Facing</small></span>
      </div>
      <p className={preview.willDefeat ? 'danger-text' : 'muted'}>
        {preview.willDefeat ? 'Projected KO.' : `${preview.remainingHp} HP projected after hit.`}
      </p>
      <div className="button-row">
        <button type="button" onClick={onConfirm}>Confirm</button>
        <button type="button" onClick={onCancel}>Cancel</button>
      </div>
    </section>
  )
}

import { FACING_LABELS, FACING_WARNINGS } from '../systems/damageFormula.js'

const EC = {
  fire: '#f97316',
  ice: '#67e8f9',
  thunder: '#fde047',
  water: '#38bdf8',
  holy: '#fef08a',
  dark: '#a855f7',
  earth: '#a3a3a3',
  none: 'rgba(248,245,255,.45)'
}

export default function DamageForecast({ preview, attacker, target, ability, reactionWarning }) {
  const facing = preview?.facing ?? 'front'
  const facingLabel = FACING_LABELS[facing] ?? FACING_LABELS.front
  const facingTone = facing === 'back' ? '#f87171' : facing === 'side' ? '#fbbf24' : '#86efac'

  return (
    <section style={s.p}>
      <p style={s.ey}>Forecast</p>
      {(!preview || !attacker || !ability) ? (
        <p style={s.m}>Select a target to preview.</p>
      ) : (
        <>
          <h3 style={{ fontSize: 14, fontWeight: 800, margin: '0 0 4px' }}>
            {attacker.name} - {ability.name}
          </h3>
          {target && (
            <p style={{ fontSize: 12, margin: '0 0 10px', color: 'rgba(248,245,255,.7)' }}>
              Target: <strong>{target.name}</strong>
            </p>
          )}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 6, marginBottom: 8 }}>
            {[
              ['Dmg', preview.amount, '#f8f5ff'],
              ['Hit', `${Math.round((preview.hitChance || 0) * 100)}%`, null],
              ['Crit', `${Math.round((preview.critChance || 0) * 100)}%`, null],
              ['Angle', facingLabel, facingTone]
            ].map(([label, value, color]) => (
              <div key={label} style={s.stat}>
                <span style={s.statLabel}>{label}</span>
                <strong style={{ ...s.statValue, color: color || '#f8f5ff' }}>{value}</strong>
              </div>
            ))}
          </div>
          {preview.armorType && (
            <p style={s.armor}>
              {preview.armorDamage} {preview.armorType === 'temper' ? 'Temper' : 'Ether'} pressure.
            </p>
          )}
          {target && (
            <div style={{ ...s.angle, borderColor: facingTone, color: facingTone }}>
              <strong>{facingLabel} attack</strong>
              <span>{FACING_WARNINGS[facing] ?? FACING_WARNINGS.front}</span>
            </div>
          )}
        </>
      )}
      {reactionWarning && (
        <div style={{ ...s.reaction, border: `1px solid ${EC[reactionWarning.element] ?? '#ffd86b'}` }}>
          <p style={{ margin: '0 0 3px', fontSize: 13, fontWeight: 800, color: EC[reactionWarning.element] ?? '#ffd86b' }}>
            {reactionWarning.label}
          </p>
          <p style={s.reactionText}>{reactionWarning.description}</p>
          {reactionWarning.chainCount > 1 && (
            <p style={s.chain}>Will chain to {reactionWarning.chainCount} tiles.</p>
          )}
        </div>
      )}
    </section>
  )
}

const s = {
  p: { padding: 14, borderRadius: 18, background: 'rgba(5,7,20,.84)', border: '1px solid rgba(255,255,255,.12)', color: '#f8f5ff' },
  ey: { margin: '0 0 6px', color: '#b8b3ff', fontSize: 11, fontWeight: 900, letterSpacing: '.16em', textTransform: 'uppercase' },
  m: { color: 'rgba(248,245,255,.45)', fontSize: 12, margin: 0 },
  stat: { padding: '7px 8px', borderRadius: 10, background: 'rgba(255,255,255,.07)' },
  statLabel: { display: 'block', color: 'rgba(248,245,255,.55)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '.06em' },
  statValue: { display: 'block', marginTop: 2, fontSize: 16 },
  armor: { fontSize: 11, color: '#ffd86b', fontWeight: 700, margin: 0 },
  angle: { display: 'grid', gap: 2, marginTop: 10, padding: '8px 10px', border: '1px solid', borderRadius: 10, background: 'rgba(255,255,255,.055)', fontSize: 11, lineHeight: 1.45 },
  reaction: { marginTop: 10, padding: '8px 10px', borderRadius: 10, background: 'rgba(255,255,255,.06)' },
  reactionText: { margin: 0, fontSize: 11, color: 'rgba(248,245,255,.65)', lineHeight: 1.5 },
  chain: { margin: '4px 0 0', fontSize: 11, color: '#fde047', fontWeight: 700 }
}

import { FACING_LABELS } from '../systems/damageFormula.js'

function pct(value, max) {
  if (!max || max <= 0) return 0
  return Math.max(0, Math.min(100, Math.round((value / max) * 100)))
}

function barColor(team) {
  return team === 'player' ? '#7bdcff' : '#ff6b6b'
}

function UnitPanel({ unit, label }) {
  if (!unit) {
    return (
      <article style={s.unitPanel}>
        <span style={s.label}>{label}</span>
        <strong style={s.emptyName}>No unit</strong>
      </article>
    )
  }

  const hpMax = unit.stats?.hp ?? unit.hp ?? 1
  const armorMax = unit.stats?.temper ?? unit.stats?.ether ?? 1
  const armorValue = unit.temper ?? unit.ether ?? 0
  const armorLabel = unit.temper !== undefined ? 'TMP' : 'ETH'

  return (
    <article style={s.unitPanel}>
      <span style={s.label}>{label}</span>
      <div style={s.identityRow}>
        <span style={{ ...s.face, borderColor: barColor(unit.team), color: barColor(unit.team) }}>
          {(unit.name ?? '?').slice(0, 1)}
        </span>
        <div style={{ minWidth: 0 }}>
          <strong style={s.unitName}>{unit.name}</strong>
          <span style={s.unitMeta}>{unit.team === 'player' ? 'Ally' : 'Enemy'} - Lv {unit.level ?? 1}</span>
        </div>
      </div>
      <div style={s.bars}>
        <div>
          <div style={s.barTop}><span>HP</span><span>{unit.hp}/{hpMax}</span></div>
          <div style={s.track}><span style={{ ...s.fill, width: `${pct(unit.hp, hpMax)}%`, background: barColor(unit.team) }} /></div>
        </div>
        <div>
          <div style={s.barTop}><span>{armorLabel}</span><span>{armorValue}/{armorMax}</span></div>
          <div style={s.track}><span style={{ ...s.fill, width: `${pct(armorValue, armorMax)}%`, background: '#c9a756' }} /></div>
        </div>
      </div>
    </article>
  )
}

export default function BattleForecastHud({ preview, attacker, target, ability, reactionWarning, pendingTarget }) {
  const hasForecast = !!preview && !!attacker && !!ability
  const facing = preview?.facing ?? 'front'
  const facingLabel = FACING_LABELS[facing] ?? FACING_LABELS.front
  const projectedHp = target && preview?.type !== 'heal'
    ? Math.max(0, (target.hp ?? 0) - (preview?.amount ?? 0))
    : target && preview?.type === 'heal'
      ? Math.min(target.stats?.hp ?? target.hp, (target.hp ?? 0) + (preview?.amount ?? 0))
      : null

  return (
    <section style={s.hud}>
      <UnitPanel unit={attacker} label="Acting" />

      <article style={s.intentPanel}>
        <span style={s.label}>Intent</span>
        {!hasForecast ? (
          <div style={s.noForecast}>
            <strong>Select a target</strong>
            <span>Move, attack, ability, and hover a unit to preview the result.</span>
          </div>
        ) : (
          <>
            <div style={s.intentHeader}>
              <strong style={s.ability}>{ability.name}</strong>
              <span style={s.angle}>{facingLabel}</span>
            </div>
            <div style={s.bigNumber}>
              <strong>{preview.amount}</strong>
              <span>{preview.type === 'heal' ? 'Healing' : 'Damage'}</span>
            </div>
            <div style={s.odds}>
              <span>Hit {Math.round((preview.hitChance ?? 0) * 100)}%</span>
              <span>Crit {Math.round((preview.critChance ?? 0) * 100)}%</span>
              {preview.armorType && <span>{preview.armorDamage} {preview.armorType === 'temper' ? 'Temper' : 'Ether'}</span>}
            </div>
            {projectedHp !== null && (
              <p style={s.projected}>
                Target HP after action: <strong>{projectedHp}</strong>
              </p>
            )}
            {reactionWarning && (
              <p style={s.reaction}>
                {reactionWarning.label}
                {reactionWarning.chainCount > 1 ? ` - chains to ${reactionWarning.chainCount} tiles` : ''}
              </p>
            )}
            {pendingTarget && <p style={s.confirmHint}>Confirm with Enter, cancel with Esc.</p>}
          </>
        )}
      </article>

      <UnitPanel unit={target} label="Target" />
    </section>
  )
}

const s = {
  hud: {
    display: 'grid',
    gridTemplateColumns: 'minmax(210px,.9fr) minmax(250px,1.2fr) minmax(210px,.9fr)',
    gap: 10,
    marginTop: 12,
    padding: 12,
    borderRadius: 18,
    border: '1px solid rgba(255,255,255,.14)',
    background: 'linear-gradient(180deg,rgba(9,12,22,.94),rgba(5,7,13,.96))',
    boxShadow: '0 -16px 50px rgba(0,0,0,.28)',
  },
  unitPanel: { minHeight: 132, borderRadius: 14, border: '1px solid rgba(255,255,255,.12)', background: 'rgba(255,255,255,.055)', padding: 12 },
  label: { display: 'block', marginBottom: 8, color: 'rgba(247,240,223,.46)', fontSize: 10, fontWeight: 900, letterSpacing: '.14em', textTransform: 'uppercase' },
  emptyName: { color: 'rgba(247,240,223,.35)', fontSize: 14 },
  identityRow: { display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 },
  face: { width: 42, height: 42, borderRadius: 10, border: '1px solid', display: 'grid', placeItems: 'center', fontWeight: 900, fontSize: 22, background: 'rgba(5,7,20,.68)', flex: '0 0 auto' },
  unitName: { display: 'block', fontSize: 15, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' },
  unitMeta: { display: 'block', marginTop: 2, color: 'rgba(247,240,223,.52)', fontSize: 11 },
  bars: { display: 'grid', gap: 8, marginTop: 12 },
  barTop: { display: 'flex', justifyContent: 'space-between', gap: 8, color: 'rgba(247,240,223,.66)', fontSize: 11, fontVariantNumeric: 'tabular-nums' },
  track: { height: 8, borderRadius: 999, background: 'rgba(255,255,255,.12)', overflow: 'hidden' },
  fill: { display: 'block', height: '100%', borderRadius: 999 },
  intentPanel: { minHeight: 132, borderRadius: 14, border: '1px solid rgba(201,167,86,.28)', background: 'rgba(201,167,86,.08)', padding: 12, textAlign: 'center' },
  noForecast: { display: 'grid', gap: 6, color: 'rgba(247,240,223,.55)', fontSize: 12, lineHeight: 1.4 },
  intentHeader: { display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8, flexWrap: 'wrap' },
  ability: { fontSize: 15 },
  angle: { padding: '3px 8px', borderRadius: 999, border: '1px solid rgba(255,255,255,.15)', color: '#ffd86b', fontSize: 11, fontWeight: 900 },
  bigNumber: { display: 'grid', placeItems: 'center', gap: 0, margin: '6px 0' },
  odds: { display: 'flex', justifyContent: 'center', gap: 8, flexWrap: 'wrap', color: 'rgba(247,240,223,.68)', fontSize: 12 },
  projected: { margin: '7px 0 0', color: 'rgba(247,240,223,.72)', fontSize: 12 },
  reaction: { margin: '6px 0 0', color: '#fde047', fontSize: 12, fontWeight: 800 },
  confirmHint: { margin: '6px 0 0', color: '#86efac', fontSize: 11, fontWeight: 800 },
}

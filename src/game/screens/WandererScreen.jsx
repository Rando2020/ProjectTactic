/**
 * WandererScreen.jsx
 * Disgaea-inspired wandering character encounter UI.
 * Shows portrait, dialogue, condition status, and interaction options.
 */
import { useState } from 'react'

const TYPE_COLORS = {
  teacher:    '#c9a756',
  challenger: '#f97316',
  merchant:   '#4ade80',
  scholar:    '#38bdf8',
  innocent:   '#a78bfa',
  hostile:    '#ef4444',
}

const TYPE_LABELS = {
  teacher:    'Wandering Teacher',
  challenger: 'Challenger',
  merchant:   'Wandering Merchant',
  scholar:    'Scholar',
  innocent:   'Lost Innocent',
  hostile:    '⚠ Hostile Wanderer',
}

const ELEMENT_COLORS = {
  fire:'#f97316', water:'#38bdf8', thunder:'#fde047',
  holy:'#fef08a', dark:'#a855f7', resonance:'#67e8f9',
}

export default function WandererScreen({ wanderer, gameState, run, onAccept, onDecline, onLeave }) {
  const [phase, setPhase] = useState('intro')   // intro | offer | result
  const [result, setResult] = useState(null)
  const [selectedOption, setSelectedOption] = useState(null)

  const typeColor  = TYPE_COLORS[wanderer.type]   ?? '#c9a756'
  const elemColor  = ELEMENT_COLORS[wanderer.element] ?? '#c9a756'
  const gold       = gameState.gold ?? 0
  const isHostile  = wanderer.type === 'hostile'

  function handlePrimary() {
    setSelectedOption('primary')
    if (wanderer.type === 'hostile') {
      setResult({ type: 'battle', message: wanderer.accept ?? '"Then we fight."' })
      onAccept({ type: 'battle', wanderer })
    } else if (wanderer.condition?.type === 'pay') {
      if (gold < wanderer.condition.cost) {
        setResult({ type: 'failed', message: wanderer.poor ?? '"Not enough gold."' })
        return
      }
      setResult({ type: 'success', message: wanderer.paid ?? '"Here. Don\'t waste it."', reward: wanderer.reward })
      onAccept({ type: 'paid', cost: wanderer.condition.cost, reward: wanderer.reward })
    } else if (wanderer.condition?.type === 'free') {
      setResult({ type: 'success', message: wanderer.reveal ?? '"Here is what I know."', reward: wanderer.reward })
      onAccept({ type: 'free', reward: wanderer.reward })
    } else if (wanderer.condition?.type === 'challenge') {
      setResult({ type: 'battle', message: wanderer.accept ?? '"Good. Let\'s see what you can do."' })
      onAccept({ type: 'challenge', wanderer })
    } else {
      setResult({ type: 'pending', message: wanderer.condition_pending ?? '"Show me first."' })
      onAccept({ type: 'condition', wanderer })
    }
    setPhase('result')
  }

  function handleAlt() {
    setSelectedOption('alt')
    const alt = wanderer.altCondition
    if (!alt) return
    if (alt.type === 'pay') {
      if (gold < alt.cost) {
        setResult({ type: 'failed', message: wanderer.poor ?? '"Not enough gold."' })
        setPhase('result'); return
      }
      setResult({ type: 'success', message: wanderer.paid ?? '"As you wish."', reward: wanderer.reward })
      onAccept({ type: 'paid', cost: alt.cost, reward: wanderer.reward })
    } else if (alt.type === 'answer_riddle') {
      setPhase('riddle')
      return
    }
    setPhase('result')
  }

  const canAffordPrimary = wanderer.condition?.type === 'pay' ? gold >= wanderer.condition.cost : true
  const canAffordAlt     = wanderer.altCondition?.type === 'pay' ? gold >= wanderer.altCondition.cost : true

  return (
    <main style={s.panel}>
      <div style={s.layout}>

        {/* Portrait + identity */}
        <aside style={{ ...s.portrait, borderColor: typeColor + '66', boxShadow:`0 0 32px ${typeColor}22` }}>
          <div style={{ fontSize:56, marginBottom:12, filter:`drop-shadow(0 0 12px ${elemColor})` }}>{wanderer.portrait}</div>
          <h2 style={{ fontSize:18, fontWeight:900, margin:'0 0 4px', color:typeColor }}>{wanderer.name}</h2>
          <p style={{ fontSize:11, color:'rgba(247,240,223,.5)', margin:'0 0 10px', fontStyle:'italic' }}>{wanderer.title}</p>
          <span style={{ fontSize:10, padding:'3px 10px', borderRadius:6, background:`${typeColor}22`, border:`1px solid ${typeColor}55`, color:typeColor, fontWeight:700, letterSpacing:'.08em', textTransform:'uppercase' }}>
            {TYPE_LABELS[wanderer.type] ?? wanderer.type}
          </span>
          {wanderer.element && (
            <p style={{ fontSize:11, color:elemColor, marginTop:10, fontWeight:700 }}>
              {wanderer.element.charAt(0).toUpperCase() + wanderer.element.slice(1)} Affinity
            </p>
          )}
          {wanderer.teaches && (
            <div style={{ marginTop:14, padding:'8px 10px', borderRadius:10, background:'rgba(255,255,255,.06)', border:'1px solid rgba(255,255,255,.1)', textAlign:'left' }}>
              <p style={{ fontSize:9, color:'rgba(247,240,223,.4)', margin:'0 0 3px', textTransform:'uppercase', letterSpacing:'.1em' }}>Teaches</p>
              <p style={{ fontSize:12, fontWeight:800, margin:0 }}>{wanderer.teaches.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</p>
            </div>
          )}
        </aside>

        {/* Main interaction */}
        <div style={{ flex:1 }}>

          {/* Dialogue box */}
          <div style={s.dialogue}>
            <p style={{ fontSize:10, color:'rgba(247,240,223,.4)', marginBottom:8, textTransform:'uppercase', letterSpacing:'.1em' }}>
              {wanderer.name}:
            </p>
            <p style={{ fontSize:14, lineHeight:1.7, color:'#f7f0df', fontStyle:'italic', margin:0 }}>
              {phase === 'result' ? (result?.message ?? wanderer.greeting) : wanderer.greeting}
            </p>
          </div>

          {/* Condition status */}
          {phase === 'intro' && wanderer.condition && (
            <div style={{ marginTop:14, padding:'10px 14px', borderRadius:12, background:'rgba(255,255,255,.04)', border:'1px solid rgba(255,255,255,.1)' }}>
              <p style={{ fontSize:11, color:'rgba(247,240,223,.5)', margin:'0 0 4px', textTransform:'uppercase', letterSpacing:'.08em' }}>Condition</p>
              <p style={{ fontSize:13, fontWeight:700, margin:'0 0 2px' }}>{wanderer.condition.label}</p>
              {wanderer.condition.description && <p style={{ fontSize:11, color:'rgba(247,240,223,.55)', margin:0 }}>{wanderer.condition.description}</p>}
            </div>
          )}

          {/* Gold display */}
          <div style={{ marginTop:10, fontSize:12, color:'#c9a756' }}>Your gold: {gold}g</div>

          {/* Action buttons */}
          {phase === 'intro' && (
            <div style={{ marginTop:18, display:'flex', flexDirection:'column', gap:10 }}>
              {/* Primary option */}
              <button onClick={handlePrimary} disabled={!canAffordPrimary && wanderer.condition?.type === 'pay'}
                style={{ ...s.actionBtn, borderColor: isHostile ? '#ef444455' : `${typeColor}55`, background: isHostile ? 'rgba(239,68,68,.12)' : `${typeColor}18`, color: isHostile ? '#f87171' : typeColor, opacity: (!canAffordPrimary && wanderer.condition?.type === 'pay') ? 0.5 : 1 }}>
                <span style={{ fontSize:15, marginRight:8 }}>{isHostile ? '⚔️' : '→'}</span>
                <span>{wanderer.condition?.label ?? 'Accept'}</span>
                {wanderer.condition?.type === 'pay' && <span style={{ marginLeft:'auto', fontSize:11, opacity:.7 }}>{wanderer.condition.cost}g</span>}
              </button>

              {/* Alt option */}
              {wanderer.altCondition && (
                <button onClick={handleAlt} disabled={!canAffordAlt && wanderer.altCondition?.type === 'pay'}
                  style={{ ...s.actionBtn, opacity: (!canAffordAlt && wanderer.altCondition?.type === 'pay') ? 0.5 : 1 }}>
                  <span style={{ fontSize:15, marginRight:8 }}>◆</span>
                  <span>{wanderer.altCondition.label}</span>
                  {wanderer.altCondition?.type === 'pay' && <span style={{ marginLeft:'auto', fontSize:11, opacity:.7 }}>{wanderer.altCondition.cost}g</span>}
                </button>
              )}

              {/* Decline */}
              <button onClick={onDecline} style={s.declineBtn}>
                Pass — move on
              </button>
            </div>
          )}

          {/* Result state */}
          {phase === 'result' && (
            <div style={{ marginTop:18 }}>
              {result?.type === 'success' && (
                <div style={{ padding:'12px 16px', borderRadius:12, background:'rgba(134,239,172,.1)', border:'1px solid rgba(134,239,172,.3)', marginBottom:14 }}>
                  <p style={{ fontSize:13, color:'#86efac', fontWeight:700, margin:0 }}>✓ {result.reward?.type === 'secret_skill' ? 'Secret skill learned!' : 'Reward received!'}</p>
                </div>
              )}
              {result?.type === 'failed' && (
                <div style={{ padding:'12px 16px', borderRadius:12, background:'rgba(248,113,113,.08)', border:'1px solid rgba(248,113,113,.3)', marginBottom:14 }}>
                  <p style={{ fontSize:13, color:'#f87171', margin:0 }}>Not enough gold.</p>
                </div>
              )}
              {result?.type === 'pending' && (
                <div style={{ padding:'12px 16px', borderRadius:12, background:'rgba(201,167,86,.08)', border:'1px solid rgba(201,167,86,.3)', marginBottom:14 }}>
                  <p style={{ fontSize:13, color:'#c9a756', margin:0 }}>Condition active — complete it this floor.</p>
                </div>
              )}
              <button onClick={onLeave} style={{ ...s.actionBtn, marginTop:8 }}>Continue →</button>
            </div>
          )}
        </div>
      </div>
    </main>
  )
}

const s = {
  panel:      { border:'1px solid rgba(255,255,255,.12)', background:'rgba(10,14,24,.88)', borderRadius:24, padding:24, color:'#f7f0df', fontFamily:'Inter,ui-sans-serif,system-ui,sans-serif' },
  layout:     { display:'grid', gridTemplateColumns:'220px 1fr', gap:24 },
  portrait:   { border:'2px solid', borderRadius:20, padding:20, textAlign:'center', background:'rgba(5,7,20,.8)' },
  dialogue:   { padding:16, borderRadius:14, background:'rgba(255,255,255,.04)', border:'1px solid rgba(255,255,255,.1)', marginBottom:4 },
  actionBtn:  { display:'flex', alignItems:'center', padding:'12px 16px', borderRadius:12, border:'1px solid rgba(255,255,255,.18)', background:'rgba(255,255,255,.06)', color:'#f7f0df', fontWeight:700, fontSize:14, cursor:'pointer', fontFamily:'inherit', textAlign:'left', width:'100%' },
  declineBtn: { display:'flex', alignItems:'center', padding:'10px 16px', borderRadius:12, border:'1px solid rgba(255,255,255,.1)', background:'transparent', color:'rgba(247,240,223,.4)', fontSize:13, cursor:'pointer', fontFamily:'inherit' },
}

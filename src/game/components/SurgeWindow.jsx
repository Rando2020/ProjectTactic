/**
 * SurgeWindow.jsx
 * SURGE timing minigame — Phase 1 (keyboard/click only, no visual bar yet).
 * Shows a pulsing prompt. Player presses Space during the green window for +25% damage.
 * Emits result via onResult({ surged: bool, multiplier: float })
 */
import { useEffect, useRef, useState } from 'react'

const WINDOW_DURATION = 1200   // total window ms
const GREEN_START     = 0.25   // 25% through = green zone opens
const GREEN_END       = 0.75   // 75% through = green zone closes

export default function SurgeWindow({ active, onResult, abilityElement }) {
  const [progress, setProgress] = useState(0)
  const [state, setState] = useState('waiting') // waiting | success | missed
  const startRef = useRef(null)
  const rafRef   = useRef(null)
  const resultFiredRef = useRef(false)

  const ELEMENT_COLORS = { fire:'#f97316',ice:'#67e8f9',thunder:'#fde047',water:'#38bdf8',holy:'#fef08a',dark:'#a855f7',earth:'#a3a3a3',none:'#c9a756' }
  const accent = ELEMENT_COLORS[abilityElement] || ELEMENT_COLORS.none

  useEffect(() => {
    if (!active) { setProgress(0); setState('waiting'); resultFiredRef.current = false; return }

    startRef.current = performance.now()
    resultFiredRef.current = false

    function tick(now) {
      const elapsed = now - startRef.current
      const pct = Math.min(1, elapsed / WINDOW_DURATION)
      setProgress(pct)
      if (pct < 1) { rafRef.current = requestAnimationFrame(tick) }
      else {
        // Window closed without press — miss
        if (!resultFiredRef.current) {
          resultFiredRef.current = true; setState('missed')
          onResult?.({ surged: false, multiplier: 1.0 })
        }
      }
    }
    rafRef.current = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(rafRef.current)
  }, [active])

  useEffect(() => {
    if (!active) return
    function onKey(e) {
      if (e.key !== ' ' && e.key !== 'Enter') return
      e.preventDefault()
      if (resultFiredRef.current) return
      resultFiredRef.current = true
      cancelAnimationFrame(rafRef.current)
      const pct = (performance.now() - startRef.current) / WINDOW_DURATION
      const surged = pct >= GREEN_START && pct <= GREEN_END
      setState(surged ? 'success' : 'missed')
      onResult?.({ surged, multiplier: surged ? 1.25 : 1.0 })
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [active, onResult])

  if (!active && state === 'waiting') return null

  const inGreenZone = progress >= GREEN_START && progress <= GREEN_END
  const barColor = state === 'success' ? '#4ade80' : state === 'missed' ? '#f87171' : inGreenZone ? '#4ade80' : accent

  return (
    <div style={s.overlay}>
      <div style={s.panel}>
        <p style={{ ...s.label, color: state === 'success' ? '#4ade80' : state === 'missed' ? '#f87171' : inGreenZone ? '#4ade80' : '#f8f5ff' }}>
          {state === 'success' ? '⚡ SURGE!' : state === 'missed' ? '✕ Missed' : inGreenZone ? '▶ PRESS SPACE!' : 'SURGE Window'}
        </p>
        <div style={s.track}>
          {/* Green zone indicator */}
          <div style={{ position:'absolute', left:`${GREEN_START*100}%`, width:`${(GREEN_END-GREEN_START)*100}%`, top:0, bottom:0, background:'rgba(74,222,128,.25)', borderRadius:4, zIndex:1 }}/>
          {/* Progress fill */}
          <div style={{ position:'absolute', left:0, top:0, bottom:0, width:`${progress*100}%`, background:barColor, borderRadius:4, transition:state!=='waiting'?'background .1s':'none', zIndex:2 }}/>
          {/* Cursor */}
          <div style={{ position:'absolute', left:`${progress*100}%`, top:-4, bottom:-4, width:3, background:'#fff', borderRadius:2, transform:'translateX(-50%)', zIndex:3, boxShadow:`0 0 8px ${barColor}` }}/>
        </div>
        <p style={s.hint}>{state === 'waiting' ? 'Press Space during the green zone for +25% damage' : state === 'success' ? '+25% damage bonus applied!' : 'Normal damage'}</p>
      </div>
    </div>
  )
}

const s = {
  overlay: { position:'fixed', bottom:120, left:'50%', transform:'translateX(-50%)', zIndex:100, pointerEvents:'none' },
  panel:   { padding:'12px 18px', borderRadius:16, background:'rgba(5,7,20,.95)', border:'1px solid rgba(255,255,255,.2)', minWidth:300, textAlign:'center' },
  label:   { margin:'0 0 8px', fontSize:16, fontWeight:900, letterSpacing:'.08em' },
  track:   { position:'relative', height:12, background:'rgba(255,255,255,.12)', borderRadius:6, overflow:'visible', margin:'0 0 8px' },
  hint:    { margin:0, fontSize:11, color:'rgba(248,245,255,.55)' },
}

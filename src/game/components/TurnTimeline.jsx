import { useMemo } from 'react'
import { getPreviewTimeline } from '../systems/turnOrder.js'
export default function TurnTimeline({units=[],activeUnitId=null}){
  const timeline=useMemo(()=>getPreviewTimeline(units,8),[units])
  return(<aside style={s.p}>
    <p style={s.ey}>Turn Order</p>
    <div style={{display:'grid',gap:4}}>
      {timeline.map((u,i)=>(
        <div key={`${u.id}-${i}`} style={{display:'grid',gridTemplateColumns:'12px 1fr auto',alignItems:'center',gap:8,padding:'4px 6px',borderRadius:8,background:u.id===activeUnitId||i===0?'rgba(201,167,86,.16)':'transparent'}}>
          <span style={{width:10,height:10,borderRadius:999,background:u.team==='player'?'#7bdcff':'#ff6b6b',display:'block'}}/>
          <span style={{fontWeight:800,fontSize:12}}>{u.name}</span>
          <span style={{color:'rgba(248,245,255,.6)',fontSize:12,fontVariantNumeric:'tabular-nums'}}>{Math.round(u.ct??0)}</span>
        </div>
      ))}
      {timeline.length===0&&<p style={{color:'rgba(247,240,223,.4)',fontSize:12}}>No units.</p>}
    </div>
  </aside>)
}
const s={p:{padding:16,borderRadius:18,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},ey:{margin:'0 0 10px',color:'#b8b3ff',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'}}

import { useMemo } from 'react'
import { getPreviewTimeline } from '../systems/turnOrder.js'
export default function TurnTimeline({units=[],activeUnitId=null,variant='card'}){
  const timeline=useMemo(()=>getPreviewTimeline(units,8),[units])
  const rail = variant === 'rail'
  return(<aside style={rail?s.rail:s.p}>
    <p style={rail?s.railEy:s.ey}>{rail ? 'Turns' : 'Turn Order'}</p>
    <div style={rail?s.railList:{display:'grid',gap:4}}>
      {timeline.map((u,i)=>(
        <div key={`${u.id}-${i}`} style={rail?{...s.railItem,...((u.id===activeUnitId||i===0)?s.railActive:{})}:{display:'grid',gridTemplateColumns:'12px 1fr auto',alignItems:'center',gap:8,padding:'4px 6px',borderRadius:8,background:u.id===activeUnitId||i===0?'rgba(201,167,86,.16)':'transparent'}}>
          {rail ? (
            <>
              <span style={s.turnNum}>{i+1}</span>
              <span style={{...s.portrait,borderColor:u.team==='player'?'#7bdcff':'#ff6b6b',color:u.team==='player'?'#7bdcff':'#ff6b6b'}}>{u.name.slice(0,1)}</span>
              <span style={s.railName}>{u.name}</span>
              <span style={s.ct}>{Math.round(u.ct??0)}</span>
            </>
          ) : (
            <>
              <span style={{width:10,height:10,borderRadius:999,background:u.team==='player'?'#7bdcff':'#ff6b6b',display:'block'}}/>
              <span style={{fontWeight:800,fontSize:12}}>{u.name}</span>
              <span style={{color:'rgba(248,245,255,.6)',fontSize:12,fontVariantNumeric:'tabular-nums'}}>{Math.round(u.ct??0)}</span>
            </>
          )}
        </div>
      ))}
      {timeline.length===0&&<p style={{color:'rgba(247,240,223,.4)',fontSize:12}}>No units.</p>}
    </div>
  </aside>)
}
const s={
  p:{padding:16,borderRadius:18,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},
  ey:{margin:'0 0 10px',color:'#b8b3ff',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'},
  rail:{position:'sticky',top:16,alignSelf:'start',padding:10,borderRadius:16,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},
  railEy:{margin:'0 0 8px',color:'#b8b3ff',fontSize:10,fontWeight:900,letterSpacing:'.14em',textTransform:'uppercase',textAlign:'center'},
  railList:{display:'grid',gap:6},
  railItem:{display:'grid',gridTemplateColumns:'18px 38px minmax(0,1fr) 30px',alignItems:'center',gap:7,padding:'5px 6px',borderRadius:10,background:'rgba(255,255,255,.045)',minWidth:178},
  railActive:{background:'rgba(201,167,86,.18)',boxShadow:'inset 0 0 0 1px rgba(201,167,86,.3)'},
  turnNum:{color:'rgba(247,240,223,.55)',fontSize:12,fontWeight:900,textAlign:'center'},
  portrait:{width:34,height:34,borderRadius:8,border:'1px solid',display:'grid',placeItems:'center',fontWeight:900,background:'rgba(255,255,255,.055)'},
  railName:{fontWeight:800,fontSize:12,whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'},
  ct:{color:'rgba(248,245,255,.62)',fontSize:11,fontVariantNumeric:'tabular-nums',textAlign:'right'}
}

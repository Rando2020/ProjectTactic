const EL={fire:'#f97316',ice:'#67e8f9',thunder:'#fde047',water:'#38bdf8',holy:'#fef08a',dark:'#a855f7',earth:'#a3a3a3'}
function Bar({label,current,max,color}){const pct=max>0?Math.max(0,Math.min(100,(current/max)*100)):0;return(
  <div style={{display:'grid',gridTemplateColumns:'30px 1fr 32px',alignItems:'center',gap:5}}>
    <span style={{fontSize:10,color:'rgba(248,245,255,.55)',textAlign:'right'}}>{label}</span>
    <div style={{height:7,borderRadius:4,background:'rgba(255,255,255,.12)',overflow:'hidden'}}><div style={{height:'100%',borderRadius:4,width:`${pct}%`,background:color,transition:'width .2s'}}/></div>
    <span style={{fontSize:10,color:'rgba(248,245,255,.6)',textAlign:'right'}}>{current}</span>
  </div>
)}
export default function UnitCard({unit}){
  if(!unit)return<section style={s.p}><p style={s.ey}>Unit Info</p><p style={s.m}>Hover a unit to inspect.</p></section>
  return(<section style={s.p}>
    <p style={s.ey}>{unit.team==='enemy'?'Enemy':'Ally'}</p>
    <h3 style={{fontSize:15,fontWeight:800,margin:'0 0 2px'}}>{unit.name}</h3>
    {unit.role&&<p style={{fontSize:11,color:'rgba(248,245,255,.5)',margin:'0 0 8px'}}>{unit.role}</p>}
    <div style={{display:'grid',gap:5,margin:'8px 0'}}>
      <Bar label="HP" current={unit.hp} max={unit.stats?.hp??unit.hp} color="#4ade80"/>
      <Bar label="TMP" current={unit.temper} max={unit.stats?.temper??unit.temper} color="#f97316"/>
      <Bar label="ETH" current={unit.ether} max={unit.stats?.ether??unit.ether} color="#a78bfa"/>
    </div>
    <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:5,margin:'6px 0'}}>
      {[['Phys',unit.stats?.physical],['Mag',unit.stats?.magic],['Spd',unit.stats?.speed],['Mov',unit.stats?.move]].map(([l,v])=>(
        <div key={l} style={{padding:'5px 4px',borderRadius:8,background:'rgba(255,255,255,.07)',textAlign:'center'}}>
          <span style={{display:'block',fontSize:9,color:'rgba(248,245,255,.5)',textTransform:'uppercase',letterSpacing:'.06em'}}>{l}</span>
          <strong style={{display:'block',fontSize:13,marginTop:1}}>{v??'?'}</strong>
        </div>))}
    </div>
    {unit.affinities?.length>0&&<div style={{display:'flex',flexWrap:'wrap',gap:4,marginTop:5}}>
      <span style={{fontSize:9,color:'rgba(248,245,255,.4)',textTransform:'uppercase',letterSpacing:'.08em',marginRight:2}}>Affinity</span>
      {unit.affinities.map(el=><span key={el} style={{fontSize:10,padding:'1px 6px',borderRadius:4,border:`1px solid ${EL[el]??'#fff'}44`,background:'rgba(255,255,255,.06)',color:EL[el]??'#fff'}}>{el}</span>)}
    </div>}
    {unit.statuses?.length>0&&<div style={{display:'flex',flexWrap:'wrap',gap:4,marginTop:5}}>
      {unit.statuses.map(st=><span key={st.id} style={{fontSize:10,padding:'1px 6px',borderRadius:4,border:'1px solid rgba(251,191,36,.3)',background:'rgba(251,191,36,.12)',color:'#fbbf24'}}>{st.id} {st.turns}t</span>)}
    </div>}
  </section>)
}
const s={p:{padding:14,borderRadius:18,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},ey:{margin:'0 0 4px',color:'#c9a756',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'},m:{color:'rgba(248,245,255,.45)',fontSize:12,margin:0}}

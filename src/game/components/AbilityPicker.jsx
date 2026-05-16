const EC = { fire:'#f97316',ice:'#67e8f9',thunder:'#fde047',water:'#38bdf8',holy:'#fef08a',dark:'#a855f7',earth:'#a3a3a3',resonance:'#c084fc',guard:'#4ade80',none:'rgba(248,245,255,.45)' }
const TL = { physical:'Phys',magic:'Magic',hybrid:'Hybrid',heal:'Heal',support:'Support' }
function EB(el){const c=EC[el]||EC.none;return <span style={{fontSize:10,fontWeight:800,padding:'2px 6px',borderRadius:4,background:`${c}22`,border:`1px solid ${c}66`,color:c}}>{el==='none'?'—':el[0].toUpperCase()+el.slice(1)}</span>}
export default function AbilityPicker({unit,onSelect,onCancel}){
  if(!unit)return null
  return(<section style={s.p}>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
      <p style={s.ey}>Choose Ability</p>
      <button style={s.cb} onClick={onCancel}>✕</button>
    </div>
    <p style={s.mp}>MP {unit.mp??0}</p>
    <div style={{display:'grid',gap:6}}>
      {unit.abilityDefs?.map(ab=>{
        const ok=(unit.mp??0)>=(ab.mpCost??0)
        return(<button key={ab.id} style={{...s.b,...(ok?{}:{opacity:.38,cursor:'not-allowed'})}} disabled={!ok} onClick={()=>onSelect(ab.id)}>
          <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:4}}><strong style={{fontSize:13,flex:1}}>{ab.name}</strong>{EB(ab.element)}<span style={{fontSize:10,color:'rgba(248,245,255,.45)'}}>{TL[ab.type]??ab.type}</span></div>
          <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            {ab.power>0&&<span style={s.st}>Pwr {ab.power}</span>}
            <span style={s.st}>MP {ab.mpCost??0}</span>
            <span style={s.st}>Rng {typeof ab.range==='number'?`1–${ab.range}`:ab.range?.min===ab.range?.max?ab.range?.min:`${ab.range?.min}–${ab.range?.max}`}</span>
            {!ok&&<span style={{...s.st,color:'#f87171'}}>Need MP</span>}
          </div>
          {ab.element!=='none'&&ab.element!=='guard'&&<div style={{fontSize:10,color:EC[ab.element]||'#fff',marginTop:3}}>⚡ May trigger terrain reaction</div>}
        </button>)
      })}
    </div>
  </section>)
}
const s={p:{padding:14,borderRadius:18,background:'rgba(5,7,20,.92)',border:'1px solid rgba(255,255,255,.15)',color:'#f8f5ff'},ey:{margin:0,color:'#c9a756',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'},mp:{fontSize:12,color:'rgba(248,245,255,.55)',margin:'0 0 8px'},cb:{background:'none',border:'none',color:'rgba(248,245,255,.5)',cursor:'pointer',fontSize:14,padding:0,fontFamily:'inherit'},b:{width:'100%',textAlign:'left',padding:'10px 12px',borderRadius:12,border:'1px solid rgba(255,255,255,.15)',background:'rgba(255,255,255,.07)',color:'#f8f5ff',cursor:'pointer',fontFamily:'inherit'},st:{fontSize:11,color:'rgba(248,245,255,.6)'}}

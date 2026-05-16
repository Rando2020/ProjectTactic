const CMDS=[{id:'move',label:'Move',desc:'Reposition within move range.'},{id:'attack',label:'Attack',desc:'Strike a target in range.'},{id:'ability',label:'Ability',desc:'Use a job ability.'},{id:'item',label:'Item',desc:'Use a Vitae Draught.'},{id:'wait',label:'Wait',desc:'End turn and hold position.'}]
export default function CommandMenu({selectedUnit,activeCommand,onSelectCommand,onWait,onUndoMove,hasMoved=false,disabledCommands=[]}){
  if(!selectedUnit)return<section style={s.p}><h3 style={s.h}>Command Menu</h3><p style={s.m}>Select a player unit.</p></section>
  return(<section style={s.p}>
    <p style={s.ey}>Active Unit</p>
    <h3 style={s.h}>{selectedUnit.name}</h3>
    <p style={s.m}>HP {selectedUnit.hp} · TMP {selectedUnit.temper} · ETH {selectedUnit.ether}</p>
    {hasMoved&&onUndoMove&&<button style={s.ub} onClick={onUndoMove}>↩ Undo Move</button>}
    <div style={{display:'grid',gap:6,marginTop:8}}>
      {CMDS.map(c=>{
        const dis=disabledCommands.includes(c.id)||(c.id==='move'&&hasMoved),act=activeCommand===c.id
        return<button key={c.id} style={{...s.b,...(act?s.a:{}),...(dis?s.d:{})}} disabled={dis} onClick={()=>c.id==='wait'?onWait?.():onSelectCommand(c.id)}>
          <strong style={{fontSize:13}}>{c.id==='move'&&hasMoved?'Moved ✓':c.label}</strong>
          <span style={{color:'rgba(248,245,255,.58)',fontSize:11}}>{c.desc}</span>
        </button>
      })}
    </div>
  </section>)
}
const s={p:{padding:16,borderRadius:18,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},ey:{margin:0,color:'#c9a756',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'},h:{margin:'6px 0 2px',fontSize:16},m:{margin:'0 0 10px',color:'rgba(248,245,255,.6)',fontSize:12},b:{display:'grid',gap:2,width:'100%',borderRadius:12,textAlign:'left',padding:'9px 12px',cursor:'pointer',border:'1px solid rgba(255,255,255,.15)',background:'rgba(255,255,255,.07)',color:'#f8f5ff',fontFamily:'inherit'},a:{borderColor:'rgba(250,204,21,.85)',background:'rgba(250,204,21,.14)'},d:{opacity:.38,cursor:'not-allowed'},ub:{width:'100%',marginBottom:8,padding:'8px 12px',borderRadius:10,border:'1px solid rgba(251,191,36,.55)',background:'rgba(251,191,36,.12)',color:'#fbbf24',fontWeight:800,fontSize:12,cursor:'pointer',fontFamily:'inherit'}}

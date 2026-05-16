import { getTerrainReaction } from '../data/terrain.js'
import { REACTION_EFFECTS } from '../systems/elementalSystem.js'
const ELS=['fire','ice','thunder','water','holy','dark','earth','resonance']
export default function TerrainInfo({tile}){
  if(!tile)return<section style={s.p}><p style={s.ey}>Terrain</p><p style={s.m}>Hover a tile to inspect.</p></section>
  const def=tile.terrainDef
  const rxns=ELS.map(el=>({el,id:getTerrainReaction(tile.terrain,el)})).filter(r=>r.id)
  return(<section style={s.p}>
    <p style={s.ey}>Terrain</p>
    <h3 style={{fontSize:15,fontWeight:800,margin:'0 0 8px'}}>{def.name}</h3>
    <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:5,marginBottom:8}}>
      {[['Height',tile.height],['Move',def.moveCost??1],['Def',def.defense?`+${def.defense}%`:'—'],['Blocked',def.blocksMovement?'Yes':'No']].map(([l,v])=>(
        <div key={l} style={{padding:'5px 6px',borderRadius:8,background:'rgba(255,255,255,.07)',textAlign:'center'}}>
          <span style={{display:'block',fontSize:9,color:'rgba(248,245,255,.5)',textTransform:'uppercase',letterSpacing:'.06em'}}>{l}</span>
          <strong style={{display:'block',fontSize:13,marginTop:1}}>{v}</strong>
        </div>))}
    </div>
    {def.hazard&&<p style={{fontSize:11,color:'#f97316',fontWeight:700,margin:'4px 0'}}>⚠ Hazard: {def.hazard.damage} dmg/turn</p>}
    {rxns.length>0&&<div style={{marginTop:6,paddingTop:6,borderTop:'1px solid rgba(255,255,255,.1)'}}>
      <p style={{fontSize:10,color:'rgba(248,245,255,.45)',textTransform:'uppercase',letterSpacing:'.1em',margin:'0 0 5px'}}>Reactions</p>
      {rxns.map(({el,id})=><p key={el} style={{fontSize:11,margin:'3px 0',display:'flex',alignItems:'center',gap:5}}>
        <span style={{fontSize:10,padding:'1px 5px',borderRadius:4,background:'rgba(255,255,255,.1)',color:'#fde047'}}>{el}</span> → {REACTION_EFFECTS[id]?.label??id}
      </p>)}
    </div>}
  </section>)
}
const s={p:{padding:14,borderRadius:18,background:'rgba(5,7,20,.84)',border:'1px solid rgba(255,255,255,.12)',color:'#f8f5ff'},ey:{margin:'0 0 6px',color:'#c9a756',fontSize:11,fontWeight:900,letterSpacing:'.16em',textTransform:'uppercase'},m:{color:'rgba(248,245,255,.45)',fontSize:12,margin:0}}

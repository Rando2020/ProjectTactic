import { useMemo } from 'react'
import { buildGrid, getUnitAt } from '../systems/grid.js'
import { TERRAIN_OVERLAY_COLORS } from '../systems/elementalSystem.js'
const TC={grass:'#244733',road:'#6b5131',stone:'#4b5563',shrine:'#68512a',shallow_water:'#155e75',deep_water:'#0f2942',ice:'#2a6a8a',burning:'#7f1d1d',electrified_water:'#1a3a1a',wall:'#111827',high_ground:'#374151',void_anchor:'#2d1a4f'}
const TI={ice:'❄',burning:'🔥',electrified_water:'⚡',void_anchor:'👁',shrine:'✦',shallow_water:'~',deep_water:'≋'}
const PC={damage:'#f8f5ff',crit:'#fde047',heal:'#4ade80',temper:'#f97316',ether:'#a78bfa'}
function HpBars({unit}){
  const mH=unit.stats?.hp??unit.hp??1,mT=unit.stats?.temper??unit.temper??1,mE=unit.stats?.ether??unit.ether??1
  return<div style={{position:'absolute',bottom:0,left:2,right:2,display:'grid',gap:1,padding:'0 1px 2px',zIndex:3}}>
    {[[unit.hp,mH,'#4ade80'],[unit.temper,mT,'#f97316'],[unit.ether,mE,'#a78bfa']].map(([c,m,col],i)=>(
      <div key={i} style={{height:3,borderRadius:2,background:'rgba(0,0,0,.5)',overflow:'hidden'}}>
        <div style={{height:'100%',borderRadius:2,width:`${Math.max(0,(c/m)*100)}%`,background:col,transition:'width .2s'}}/>
      </div>))}
  </div>
}
export default function TacticalGrid({map,units,selectedUnitId,activeCommand,moveTileKeys,attackTileKeys,intentTileKeys,reactionFlashKeys,pendingTargetKey,popups={},onSelectUnit,onSelectMoveTile,onSelectAttackTarget,onHoverUnit,onHoverTile,onLeave,showCoordinates=true}){
  const grid=useMemo(()=>buildGrid(map),[map])
  function handleClick(tile){
    const u=getUnitAt(units,tile.x,tile.y),key=`${tile.x},${tile.y}`
    if(u){if(attackTileKeys?.has(key)){onSelectAttackTarget?.(u.id);return}onSelectUnit?.(u.id);return}
    if(moveTileKeys?.has(key))onSelectMoveTile?.(tile)
  }
  return(<div>
    <div style={{display:'grid',gridTemplateColumns:`repeat(${map.size.width},minmax(44px,1fr))`,gap:5,overflowX:'auto'}}>
      {grid.map(tile=>{
        const u=getUnitAt(units,tile.x,tile.y),key=`${tile.x},${tile.y}`
        const isSel=u?.id===selectedUnitId,isMove=moveTileKeys?.has(key)&&!u,isAtk=u&&attackTileKeys?.has(key)
        const isFlash=reactionFlashKeys?.has(key),isIntent=intentTileKeys?.has(key),isPend=key===pendingTargetKey
        const overlay=TERRAIN_OVERLAY_COLORS[tile.terrain],icon=TI[tile.terrain],pops=popups[key]??[]
        const border=isPend?'2px solid #86efac':isSel?'2px solid #facc15':isAtk?'2px solid #f97316':isFlash?'2px solid #fff':isMove?'2px solid #67e8f9':'1px solid rgba(255,255,255,.12)'
        return(<button key={key} onClick={()=>handleClick(tile)}
          onMouseEnter={()=>{u?onHoverUnit?.(u.id):onHoverTile?.(tile)}}
          onMouseLeave={()=>onLeave?.()}
          style={{position:'relative',minHeight:58,border,background:TC[tile.terrain]||'#243447',borderRadius:10,boxShadow:`inset 0 ${Math.max(1,tile.height+1)*-2}px 0 rgba(0,0,0,.3)`,color:'#fff',overflow:'visible',cursor:'pointer',padding:0}}
          title={`${tile.terrainDef.name} h${tile.height}`}>
          {overlay&&<span style={{position:'absolute',inset:0,background:overlay,borderRadius:9,pointerEvents:'none',zIndex:1}}/>}
          {isFlash&&<span style={{position:'absolute',inset:0,background:'rgba(255,255,255,.35)',borderRadius:9,pointerEvents:'none',zIndex:2}}/>}
          {isIntent&&!u&&<span style={{position:'absolute',inset:0,background:'rgba(248,113,113,.2)',borderRadius:9,pointerEvents:'none',zIndex:1}}/>}
          {showCoordinates&&<span style={{position:'absolute',top:3,left:5,fontSize:9,opacity:.5,zIndex:4}}>{key}</span>}
          <span style={{position:'absolute',right:5,top:3,fontSize:9,opacity:.6,zIndex:4}}>h{tile.height}</span>
          {icon&&!u&&<span style={{position:'absolute',bottom:5,right:5,fontSize:11,opacity:.75,zIndex:4}}>{icon}</span>}
          {isMove&&<span style={{position:'absolute',inset:0,display:'grid',placeItems:'center',fontSize:18,opacity:.45,zIndex:4}}>·</span>}
          {u&&<div style={{position:'relative',height:'100%',display:'grid',placeItems:'center',zIndex:4}}>
            <div style={{textAlign:'center'}}>
              <div style={{fontSize:15,filter:isSel?'drop-shadow(0 0 5px #facc15)':'none'}}>{u.team==='player'?'◆':'◇'}</div>
              <div style={{fontSize:9,lineHeight:1.2,fontWeight:800}}>{u.name.split(' ')[0]}</div>
              {u.statuses?.length>0&&<div style={{fontSize:8,color:'#fbbf24',lineHeight:1}}>{u.statuses.map(s=>s.id[0].toUpperCase()).join('')}</div>}
              {u.hp<=0&&<div style={{fontSize:9,color:'#f87171'}}>✕</div>}
            </div>
            <HpBars unit={u}/>
          </div>}
          {pops.map(p=><div key={p.id} style={{position:'absolute',top:-8,left:'50%',transform:'translateX(-50%)',fontSize:p.type==='crit'?16:13,fontWeight:900,color:PC[p.type]||'#fff',textShadow:'0 1px 4px rgba(0,0,0,.9)',pointerEvents:'none',zIndex:10,animation:'floatUp 1.1s ease-out forwards',whiteSpace:'nowrap'}}>
            {p.type==='heal'?'+':''}{p.value}{p.type==='crit'?' CRIT!':''}
          </div>)}
        </button>)
      })}
    </div>
    <style>{`@keyframes floatUp{0%{opacity:1;transform:translateX(-50%) translateY(0)}70%{opacity:1}100%{opacity:0;transform:translateX(-50%) translateY(-28px)}}`}</style>
    <div style={{marginTop:8,display:'flex',flexWrap:'wrap',gap:10,fontSize:11,color:'rgba(247,240,223,.45)'}}>
      <span>◆ Player</span><span>◇ Enemy</span>
      <span style={{color:'#67e8f9'}}>■ Move</span><span style={{color:'#f97316'}}>■ Attack</span>
      <span style={{color:'#facc15'}}>■ Selected</span><span style={{color:'#86efac'}}>■ Confirm</span>
      <span>❄ Ice</span><span>🔥 Burning</span><span>⚡ Electrified</span>
    </div>
  </div>)
}

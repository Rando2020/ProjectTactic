#!/usr/bin/env python3
"""Actual exported-mesh floor/blade-surface/frustum regression gate, 96Hz.
Not continuous collision certification. Keeps the exact shipping camera fixed.
"""
from pathlib import Path
import sys,json,math,time
import numpy as np
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];OUT=HERE;sys.dont_write_bytecode=True;sys.path.insert(0,str(ROOT/'tools'));import validate_zane_impact_asset as v
m=v.GLB(ROOT/'godot/assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb');geo=m.geometry()
skin=[g for g in geo if 'joints' in g]
sword=[g for g in geo if 'joints' not in g and len(g['indices']) == 232]
blade=[]
for g in sword:
 t=g['vertices'][g['indices'],:3]
 mask=(t[:,:,1].min(axis=1)>=.13999)&(abs(t[:,:,0]).max(axis=1)<=.052)&(abs(t[:,:,2]).max(axis=1)<=.0171)
 if mask.any():blade.append((g,g['indices'][mask]))
assert sum(len(x[1]) for x in blade)==40,sum(len(x[1]) for x in blade)
right=np.array([1/math.sqrt(2),0,-1/math.sqrt(2)]);up=np.array([-1/(2*math.sqrt(2)),math.sqrt(3)/2,-1/(2*math.sqrt(2))]);center=np.array([0,.95,0]);facing={}
for face,angle in [('N',math.pi),('E',math.pi/2),('S',0),('W',-math.pi/2)]:
 c,s=math.cos(angle),math.sin(angle);rot=np.array([[c,0,s],[0,1,0],[-s,0,c]]);facing[face]=np.stack([right,up])@rot
# Moller-Trumbore finite-segment crossings, both triangle edge sets. Non-coplanar only.
def edge_hits(orig,end,tri):
 d=end-orig;e1=tri[:,1]-tri[:,0];e2=tri[:,2]-tri[:,0];h=np.cross(np.broadcast_to(d,e2.shape),e2);a=np.einsum('ij,ij->i',e1,h);good=abs(a)>1e-11
 if not good.any():return False
 tri,e1,e2,h,a=tri[good],e1[good],e2[good],h[good],a[good];f=1/a;s=orig-tri[:,0];u=f*np.einsum('ij,ij->i',s,h);q=np.cross(s,e1);vv=f*(q@d);t=f*np.einsum('ij,ij->i',e2,q)
 return bool(((u>=-1e-9)&(vv>=-1e-9)&(u+vv<=1+1e-9)&(t>=-1e-9)&(t<=1+1e-9)).any())
def triangle_hits(bt,ts):
 for a,b in [(0,1),(1,2),(2,0)]:
  if edge_hits(bt[a],bt[b],ts):return True
 for a,b in [(0,1),(1,2),(2,0)]:
  # Vary segment, fixed blade triangle using equivalent vectorization.
  orig=ts[:,a];d=ts[:,b]-orig;e1=bt[1]-bt[0];e2=bt[2]-bt[0];h=np.cross(d,e2);aa=h@e1;good=abs(aa)>1e-11
  if not good.any():continue
  f=1/aa[good];s=orig[good]-bt[0];u=f*np.einsum('ij,ij->i',s,h[good]);q=np.cross(s,e1);vv=f*np.einsum('ij,ij->i',d[good],q);t=f*(q@e2)
  if ((u>=-1e-9)&(vv>=-1e-9)&(u+vv<=1+1e-9)&(t>=-1e-9)&(t<=1+1e-9)).any():return True
 return False
report={'model_sha256':v.sha(m.data),'sampling_hz':96,'floor_tolerance':-.0001,'camera':{'ortho':3.2,'target':[0,.95,0],'pitch':30,'yaw':45},'blade_triangles_checked':40,'blade_method':'Actual blade surface triangles vs actual deformed skin triangles, AABB broad phase and two-way segment/triangle narrow phase. Sampled surfaces only, not continuous collision or containment certification.','clips':{}}
start=time.time()
for clip in m.animations:
 floor=1e9;floorat=None;bounds={f:np.array([[1e9,1e9],[-1e9,-1e9]]) for f in facing};contacts=[];duration=m.duration(clip);samples=np.linspace(0,duration,int(round(duration*96))+1)
 for t in samples:
  pose=m.pose(clip,float(t));verts=[m.deform(g,pose) for g in geo];allv=np.concatenate(verts);low=float(allv[:,1].min())
  if low<floor:floor=low;floorat=float(t)
  for f,proj in facing.items():
   xy=allv@proj.T-center@np.stack([right,up]).T;bounds[f][0]=np.minimum(bounds[f][0],xy.min(0));bounds[f][1]=np.maximum(bounds[f][1],xy.max(0))
  skintris=np.concatenate([m.deform(g,pose)[g['indices']] for g in skin]);lo=skintris.min(1);hi=skintris.max(1)
  collision=False
  for g,idx in blade:
   for bt in m.deform(g,pose)[idx]:
    sel=((hi>=bt.min(0)-1e-9)&(lo<=bt.max(0)+1e-9)).all(1)
    if sel.any() and triangle_hits(bt,skintris[sel]):collision=True;break
   if collision:break
  if collision:contacts.append(round(float(t),8))
 report['clips'][clip]={'samples':len(samples),'min_y':round(floor,8),'min_y_at':round(floorat,8),'all_facing_projected_bounds':{f:a.round(8).tolist() for f,a in bounds.items()},'blade_skin_surface_crossing_sample_times':contacts}
 print(clip,report['clips'][clip]['min_y'],'blade contact samples',len(contacts),flush=True)
report['elapsed_seconds']=round(time.time()-start,3);report['floor_pass']=min(c['min_y'] for c in report['clips'].values())>=-.0001;report['all_facing_framing_pass']=all(abs(x)<=1.6 for c in report['clips'].values() for a in c['all_facing_projected_bounds'].values() for row in a for x in row);report['blade_surface_crossing_detected']=any(c['blade_skin_surface_crossing_sample_times'] for c in report['clips'].values());report['minimum_frustum_margin_world']=round(1.6-max(abs(x) for c in report['clips'].values() for a in c['all_facing_projected_bounds'].values() for row in a for x in row),8);report['minimum_frustum_margin_display_px']=round(report['minimum_frustum_margin_world']*138.24/3.2,8);(OUT/'motion_clearance_report.json').write_text(json.dumps(report,indent=2)+'\n');print({k:v for k,v in report.items() if k!='clips'})

assert report['floor_pass'],'Exported mesh penetrates floor'
assert report['all_facing_framing_pass'],'Actual fixed gameplay camera clips the model'
assert not report['blade_surface_crossing_detected'],'Blade crosses deformed character surface'
assert report['minimum_frustum_margin_world']>=.05,'Insufficient fixed-camera blade margin'

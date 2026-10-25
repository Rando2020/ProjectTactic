#!/usr/bin/env python3
"""Strict new-asset checks, never a weakening or replacement of baseline tests."""
import argparse,sys,json,hashlib,struct
from pathlib import Path
import numpy as np
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(ROOT/'tools'))
import validate_zane_impact_asset as v
OUT=ROOT/'godot/assets/3d/characters/zane_painterly_v1';MODEL=OUT/'zane_painterly_v1.glb';IMPACT=ROOT/'godot/assets/3d/characters/zane_impact_v1/zane_impact_v1.glb'
IMPACT_SHA='669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90'
def validate(write_metadata=False,motion=True):
 old,new=v.GLB(IMPACT),v.GLB(MODEL);assert v.sha(old.data)==IMPACT_SHA
 original=v.GLB(v.BASELINE);assert v.sha(original.data)==v.BASELINE_SHA256
 comp=v.compatibility(original,new);impact_comp=v.compatibility(old,new)
 for name in impact_comp['bone_order']+v.SOCKETS+['Kael_v2_RIG']:
  assert np.array_equal(v.trs(old.doc['nodes'][old.names[name]]),v.trs(new.doc['nodes'][new.names[name]])),f'Exact rest changed: {name}'
 assert np.array_equal(old.accessor(old.doc['skins'][0]['inverseBindMatrices']),new.accessor(new.doc['skins'][0]['inverseBindMatrices']))
 for index in range(len(new.doc['accessors'])):new.accessor(index)
 assert set(old.animations)==set(new.animations) and len(new.animations)==9
 max_delta=0
 for name in old.animations:
  bc,nc=old.channels(name),new.channels(name);assert bc.keys()==nc.keys()
  for key in bc:
   for index in (0,1):
    # Stronger than tolerance: same exported sample times and values exactly.
    assert np.array_equal(bc[key][index],nc[key][index]),f'Inherited clip changed: {name} {key} {index}'
   max_delta=max(max_delta,float(np.max(np.abs(bc[key][1]-nc[key][1]))))
 geo=new.geometry();tris=sum(len(g['indices']) for g in geo);assert tris<=24000;assert len(geo)<=8;assert len(new.doc['materials'])<=8
 assert len(new.doc.get('images',[]))==1 and 'bufferView' in new.doc['images'][0]
 iv=new.doc['bufferViews'][new.doc['images'][0]['bufferView']];start=iv.get('byteOffset',0);embedded=new.binary[start:start+iv['byteLength']]
 assert embedded[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',embedded[16:24])==(1024,1024),'Expected 1024-square PNG atlas'
 assert embedded==(HERE/'textures/zane_painterly_atlas.png').read_bytes(),'Embedded atlas differs from editable source PNG'
 for mesh in new.doc['meshes']:
  for p in mesh['primitives']:
   assert 'TEXCOORD_0' in p['attributes'] and 'COLOR_0' in p['attributes']
   uv=new.accessor(p['attributes']['TEXCOORD_0']);assert np.min(uv)>=0 and np.max(uv)<=1
   if 'WEIGHTS_0' in p['attributes']:
    weights=new.accessor(p['attributes']['WEIGHTS_0']);assert np.min(weights)>=0 and np.max(weights)<=1
    joints=new.accessor(p['attributes']['JOINTS_0']);assert np.min(joints)>=0 and np.max(joints)<16
    v.close(weights.sum(axis=1),np.ones(len(weights)),'Non-normalized skin weights')
 for mat in new.doc['materials']:
  assert mat.get('alphaMode','OPAQUE')=='OPAQUE';assert 'baseColorTexture' in mat['pbrMetallicRoughness'];assert not mat.get('extensions',{}).get('KHR_materials_unlit')
 manifest=json.loads((ROOT/'godot/assets/3d/characters/zane_impact_v1/presentation.json').read_text())
 manifest.update(profile_id='zane_painterly_v1',model='res://assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb',model_sha256=v.sha(new.data),compatibility_report_sha256=v.report_sha(comp),clip_durations={n:new.duration(n) for n in new.animations},gait_calibration=v.measure_gait(new),motion_source={'profile_id':'zane_impact_v1','model_sha256':IMPACT_SHA,'unchanged_clips':list(old.animations)},motion_declaration_note='changed_clips/unchanged_clips are inherited impact changes relative to original zane_v2. Every impact clip is preserved exactly by this visual rebuild.',visual_source={'builder':'assets/source/zane-painterly-v1/build_zane.py','atlas':'assets/source/zane-painterly-v1/textures/zane_painterly_atlas.png','atlas_sha256':v.sha((HERE/'textures/zane_painterly_atlas.png').read_bytes()),'triangles':tris,'materials':len(new.doc['materials']),'surfaces':len(geo),'images':len(new.doc['images'])})
 if not write_metadata:assert json.loads((OUT/'presentation.json').read_text())==manifest,'Stale or altered manifest'
 report={'status':'asset-structure-and-motion-compatible','model_sha256':v.sha(new.data),'motion_source_sha256':IMPACT_SHA,'source_geometry':'Original authored visual meshes; original project rig/actions retained','motion_max_sample_delta':max_delta,'clip_durations':manifest['clip_durations'],'compatibility':impact_comp,'gait_calibration':manifest['gait_calibration'],'triangles':tris,'materials':len(new.doc['materials']),'surfaces':len(geo),'embedded_images':len(new.doc['images'])}
 if motion:
  report['exported_motion']=v.exported_motion_report(new)
  if min(report['exported_motion']['minimum_exported_vertex_y'].values())<-.0001:
   report['status']='failed-floor-clearance';report['failure']='Exported mesh penetrates unchanged floor tolerance -0.0001'
   (HERE/'validation_report.json').write_text(json.dumps(report,indent=2)+'\n')
   raise AssertionError(report['failure'])
  (HERE/'validation_report.json').write_text(json.dumps(report,indent=2)+'\n')
 else:report['warning']='DRAFT structure-only report; floor/clipping/image review not complete.'
 if write_metadata:(OUT/'presentation.json').write_text(json.dumps(manifest,indent=2)+'\n')
 return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-metadata',action='store_true');p.add_argument('--structure-only',action='store_true');a=p.parse_args();r=validate(a.write_metadata,not a.structure_only);print(json.dumps({k:v for k,v in r.items() if k not in ('compatibility','exported_motion')},indent=2))

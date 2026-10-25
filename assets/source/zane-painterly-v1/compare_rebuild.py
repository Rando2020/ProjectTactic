#!/usr/bin/env python3
"""Check fresh-builder equivalence despite Blender's nondeterministic triangle rows.
Usage: python3 assets/source/zane-painterly-v1/compare_rebuild.py frozen.glb rebuilt.glb
Keeps winding, topology, every vertex attribute, animation and material unchanged.
"""
from pathlib import Path
import sys,json,numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'tools'))
import validate_zane_impact_asset as v
def compare(a,b):
 x,y=v.GLB(a),v.GLB(b);assert x.doc==y.doc,'Scene/material/accessor metadata changed'
 indices={p['indices'] for mesh in x.doc['meshes'] for p in mesh['primitives']}
 for i in range(len(x.doc['accessors'])):
  a,b=x.accessor(i),y.accessor(i)
  if i in indices:
   def canonical(arr):
    return sorted(min((int(t[0]),int(t[1]),int(t[2])),(int(t[1]),int(t[2]),int(t[0])),(int(t[2]),int(t[0]),int(t[1]))) for t in arr.reshape(-1,3))
   assert canonical(a)==canonical(b),f'Oriented triangle topology changed: {i}'
  else:assert np.array_equal(a,b),f'Geometry/animation accessor changed: {i}'
 for im in x.doc.get('images',[]):
  bv=x.doc['bufferViews'][im['bufferView']];start=bv.get('byteOffset',0);end=start+bv['byteLength'];assert x.binary[start:end]==y.binary[start:end],'Image bytes changed'
 return {'frozen_sha256':v.sha(x.data),'rebuilt_sha256':v.sha(y.data),'byte_equal':x.data==y.data,'all_semantic_data_equal':True,'only_permitted_difference':'Ordering/cyclic starting vertex of oriented triangle index rows'}
if __name__=='__main__':print(json.dumps(compare(*sys.argv[1:]),indent=2))

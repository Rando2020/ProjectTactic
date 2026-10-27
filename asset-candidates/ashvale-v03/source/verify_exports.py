import bpy,json,sys,os,struct
from pathlib import Path
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,os.environ.get('BLENDER_ASSET_QA_SCRIPTS',str(Path.home()/'.codex/skills/blender-asset-qa/scripts')))
import qa_check
reports=[]
for p in sorted((R/'models').glob('*.glb')):
    raw=p.read_bytes();magic,version,total=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and total==len(raw)
    length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length])
    assert doc['meshes']
    assert all('COLOR_0' in prim['attributes'] for m in doc['meshes'] for prim in m['primitives'])
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(p))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert all(o.data.uv_layers for o in objects)
    # Scene arrangement intentionally places separate props; check reusable meshes independently.
    qa=qa_check.run(objects=[o.name for o in objects],profile='game') if not p.stem.startswith('SC_') else None
    reports.append(dict(asset=p.stem,bytes=len(raw),meshes=len(doc['meshes']),roundtrip=True,vertex_colors=True,qa=qa))
(R/'review/export-checks.json').write_text(json.dumps(reports,indent=2))
for r in reports:
    if r['qa']:print(r['asset'],'ERRORS',r['qa']['errors'],'WARNINGS',r['qa']['warnings'])
print('ROUNDTRIP_COUNT',len(reports))

import bpy, json, struct, sys, os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,os.environ.get('BLENDER_ASSET_QA_SCRIPTS',str(Path.home()/'.codex/skills/blender-asset-qa/scripts')))
import qa_check
reports=[]
for path in sorted((ROOT/'models').glob('*.glb')):
    raw=path.read_bytes()
    magic,version,total=struct.unpack_from('<III',raw)
    assert magic==0x46546C67 and version==2 and total==len(raw)
    n,kind=struct.unpack_from('<II',raw,12)
    doc=json.loads(raw[20:20+n])
    assert len(doc.get('meshes',[]))>0
    clips=[a.get('name') for a in doc.get('animations',[])]
    if path.stem=='zane-rig-prototype':
        assert set(['idle','walk','attack'])<=set(clips),clips
        assert len(doc.get('skins',[]))==1
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(path))
    # Blender's glTF importer creates viewport-only bone-shape meshes; they are
    # not part of the GLB payload and must not enter exported-asset measurements.
    shapes={p.custom_shape for o in bpy.context.scene.objects if o.type=='ARMATURE' for p in o.pose.bones if p.custom_shape}
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in shapes]
    assert meshes and all(len(o.data.vertices)>0 and len(o.data.uv_layers)>0 for o in meshes)
    report=qa_check.run(objects=[o.name for o in meshes],profile='game')
    reports.append({'asset':path.stem,'bytes':len(raw),'gltf_meshes':len(doc['meshes']),'skins':len(doc.get('skins',[])),'clips':clips,'roundtrip_loaded':True,'qa':report})
(ROOT/'review/export-checks.json').write_text(json.dumps(reports,indent=2))
print('ROUNDTRIP_OK',len(reports))
for r in reports:print(r['asset'],'errors',len(r['qa']['errors']),'warnings',len(r['qa']['warnings']))

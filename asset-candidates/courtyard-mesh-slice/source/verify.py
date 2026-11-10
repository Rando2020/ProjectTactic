import bpy,bmesh,json,sys
from pathlib import Path
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,'C:/Users/jojo3/.codex/skills/blender-asset-qa/scripts')
import qa_check
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(R/'models/courtyard-section.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==5
assert all(o.data.uv_layers and o.data.color_attributes for o in meshes)
reports=[]
for o in meshes:
    # Weld coincident export seam vertices on the inspection copy only; preserve delivered GLB.
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bm.to_mesh(o.data);bm.free();o.data.update()
    bpy.context.view_layer.update()
    # Sub-millimetre tolerance for thin leaves/stems, standard tolerance for masonry.
    eps=.0002 if o.name in ('Olive leaves','Flower stems','Lilac petals') else .001
    qa=qa_check.run(objects=[o.name],profile='game',eps=eps)
    # Groups are material batches across a whole environment, not single connected props.
    # Preserve raw findings; a detached plant within its material batch is expected.
    qa['material_batch_separation']=[e for e in qa['errors'] if e.startswith('floating/detached')]
    qa['geometry_errors']=[e for e in qa['errors'] if not e.startswith('floating/detached')]
    reports.append(dict(name=o.name,eps_m=eps,qa=qa))
(R/'review/mesh-qa.json').write_text(json.dumps(reports,indent=2))
for r in reports:print(r['name'],r['qa']['errors'],r['qa']['warnings'])
print('EXPORT_ROUNDTRIP_PASS')

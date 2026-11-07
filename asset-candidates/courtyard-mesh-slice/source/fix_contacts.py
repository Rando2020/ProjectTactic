"""Resolve coplanar intersections between separate stone islands; retain closed surfaces."""
import bpy,bmesh,sys,json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
P=Path('C:/Users/jojo3/.codex/skills/blender-asset-qa/scripts')
sys.path.insert(0,str(P))
source=(P/'qa_check.py').read_text()
source=source.replace('zf = _describe(zf_pairs)',"globals()['debug_pairs']=[([tuple(verts[v]) for v in tris[i]],[tuple(verts[v]) for v in tris[j]]) for i,j in zf_pairs]\n    zf = _describe(zf_pairs)")
ns={'__name__':'qa_debug','__file__':str(P/'qa_check.py')};exec(compile(source,str(P/'qa_check.py'),'exec'),ns)
bpy.ops.wm.open_mainfile(filepath=str(R/'source/courtyard-section.blend'))
ns['run'](objects=['Painted limestone'],profile='game')
print('CONTACT_COORDINATES',json.dumps(ns['debug_pairs']))
from mathutils import Vector
o=bpy.data.objects['Painted limestone'];bm=bmesh.new();bm.from_mesh(o.data)
done=set()
for pair in ns['debug_pairs']:
    target=o.matrix_world.inverted()@Vector(pair[0][0])
    seed=min(bm.verts,key=lambda v:(v.co-target).length_squared)
    if seed in done:continue
    island={seed};stack=[seed]
    while stack:
        v=stack.pop()
        for e in v.link_edges:
            other=e.other_vert(v)
            if other not in island:island.add(other);stack.append(other)
    for v in island:v.co.z-=.04
    done.update(island)
bm.to_mesh(o.data);bm.free();o.data.update();bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    if o.type=='MESH':o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'models/courtyard-section.glb'),export_format='GLB',use_selection=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/courtyard-section.blend'))
S=bpy.context.scene;cam=S.camera
for name,p in [('section',(7,-10,9)),('reverse',(-7,9,7))]:
    cam.location=p;cam.rotation_euler=(Vector((0,0,.4))-cam.location).to_track_quat('-Z','Y').to_euler()
    S.render.filepath=str(R/'review'/f'{name}.png');bpy.ops.render.render(write_still=True)
for o in S.objects:
    if o.type=='MESH':
        mod=o.modifiers.new('Wire review','WIREFRAME');mod.thickness=.002;mod.use_even_offset=False
cam.location=(7,-10,9);cam.rotation_euler=(Vector((0,0,.4))-cam.location).to_track_quat('-Z','Y').to_euler()
S.render.filepath=str(R/'review/wire.png');bpy.ops.render.render(write_still=True)

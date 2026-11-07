import bpy
from pathlib import Path
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/chapel-master.blend'))
for o in list(bpy.context.scene.objects):
    if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(R/'models/SC_chapel_approach.glb'))
s=bpy.context.scene;s.cycles.samples=24
s.render.filepath=str(R/'review/roundtrip-materials.png');bpy.ops.render.render(write_still=True)
for o in s.objects:
    if o.type=='MESH':
        m=o.modifiers.new('Topology_review','WIREFRAME');m.thickness=.008;m.use_replace=True
s.render.resolution_x=1100;s.render.resolution_y=900
s.render.filepath=str(R/'review/roundtrip-wire.png');bpy.ops.render.render(write_still=True)
print('ROUNDTRIP_RENDER_PASS')

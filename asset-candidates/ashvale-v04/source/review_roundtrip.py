import bpy
from mathutils import Vector
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
        m=o.modifiers.new('Topology_review','WIREFRAME');m.thickness=.003;m.use_replace=True;m.use_even_offset=False
s.render.resolution_x=1100;s.render.resolution_y=900
s.render.filepath=str(R/'review/roundtrip-wire.png');bpy.ops.render.render(write_still=True)
for asset,focus,scale in [('PR_torn_ashvale_banner',1.65,3.8),('PR_splitwood_barricade',.65,2.7)]:
    for o in list(s.objects):
        if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(R/'models'/f'{asset}.glb'))
    s.camera.location=(4,-8,focus+2.5)
    s.camera.rotation_euler=(Vector((0,0,focus))-s.camera.location).to_track_quat('-Z','Y').to_euler()
    s.camera.data.ortho_scale=scale
    s.render.resolution_x=800;s.render.resolution_y=900
    s.render.filepath=str(R/'review'/f'{asset}-detail.png');bpy.ops.render.render(write_still=True)
print('ROUNDTRIP_RENDER_PASS')

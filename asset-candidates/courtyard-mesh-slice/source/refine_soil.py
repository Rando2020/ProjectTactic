import bpy
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/courtyard-section.blend'))
m=bpy.data.materials['Ochre earth']
next(n for n in m.node_tree.nodes if n.type=='TEX_IMAGE').image=bpy.data.images.load(str(R/'textures/painted-soil.png'),check_existing=True)
o=bpy.data.objects['Ochre earth']
for c in o.data.color_attributes['Paint'].data:
    c.color=(c.color[0]/.30*.65,c.color[1]/.19*.62,c.color[2]/.075*.58,1)
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    if o.type=='MESH':o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'models/courtyard-section.glb'),export_format='GLB',use_selection=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/courtyard-section.blend'))
S=bpy.context.scene;cam=S.camera
for name,p in [('section',(7,-10,9)),('reverse',(-7,9,7))]:
    cam.location=p;cam.rotation_euler=(Vector((0,0,.4))-cam.location).to_track_quat('-Z','Y').to_euler()
    S.render.filepath=str(R/'review'/f'{name}.png');bpy.ops.render.render(write_still=True)

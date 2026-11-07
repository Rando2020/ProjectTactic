import bpy
from pathlib import Path
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/courtyard-section.blend'))
for o in list(bpy.context.scene.objects):
    if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(R/'models/courtyard-section.glb'))
bpy.context.scene.render.filepath=str(R/'review/export-roundtrip.png')
bpy.ops.render.render(write_still=True)

import bpy,bmesh
from mathutils import Vector
from pathlib import Path
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/courtyard-section.blend'))
o=bpy.data.objects['Painted limestone']
if not o.get('export_contact_fixed'):
    bm=bmesh.new();bm.from_mesh(o.data)
    target=o.matrix_world.inverted()@Vector((1.0482248,1.4763031,-.05446035))
    seed=min(bm.verts,key=lambda v:(v.co-target).length_squared)
    island={seed};stack=[seed]
    while stack:
        v=stack.pop()
        for e in v.link_edges:
            other=e.other_vert(v)
            if other not in island:island.add(other);stack.append(other)
    for v in island:v.co.z-=.03
    bm.to_mesh(o.data);bm.free();o.data.update();o['export_contact_fixed']=True
    bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/courtyard-section.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    if o.type=='MESH':
        bm=bmesh.new();bm.from_mesh(o.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.0001)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(o.data);bm.free();o.data.update()
        o.select_set(True)
        o.data.color_attributes.active_color=o.data.color_attributes['Paint']
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/courtyard-section.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'models/courtyard-section.glb'),export_format='GLB',use_selection=True,export_animations=False,export_vertex_color='ACTIVE')

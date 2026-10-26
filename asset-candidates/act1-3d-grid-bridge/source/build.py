"""Act 1 reference-informed meshes. Blender 4.5; seed 814. No raster tracing."""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
for d in ['models','review','references','data']: (R/d).mkdir(parents=True,exist_ok=True)
random.seed(814)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
S=bpy.context.scene;S.unit_settings.system='METRIC'
m=bpy.data.materials.new('Act1_painted_planes');m.use_nodes=True
n=m.node_tree.nodes;v=n.new('ShaderNodeVertexColor');v.layer_name='Paint'
b=next(x for x in n if x.type=='BSDF_PRINCIPLED');b.inputs['Roughness'].default_value=.93
m.node_tree.links.new(v.outputs['Color'],b.inputs['Base Color'])
cream=(.71,.52,.34);purple=(.28,.19,.29);soil=(.42,.28,.085);olive=(.17,.23,.065);pink=(.65,.28,.59)
parts=[];assets={};manifest=[]
def finish_part(o,top,side):
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
    o.data.materials.append(m)
    c=o.data.color_attributes.new(name='Paint',type='FLOAT_COLOR',domain='CORNER')
    for p in o.data.polygons:
        base=top if p.normal.z>.5 else side
        tint=random.uniform(.92,1.08)
        for i in p.loop_indices:c.data[i].color=(*(x*tint for x in base),1)
    parts.append(o);o.select_set(False)
    return o
def block(p,size,top=cream,side=purple,bevel=.055):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    # Horizontal corner variations retain exact, level tile elevations.
    for vert in o.data.vertices:
        dx=random.uniform(-.018,.018);dy=random.uniform(-.018,.018)
        if size[0]<1.98: vert.co.x+=dx
        if size[1]<1.98: vert.co.y+=dy
    mod=o.modifiers.new('Cut_edges','BEVEL');mod.width=bevel;mod.segments=1
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish_part(o,top,side)
def ico(p,scale,top,side):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=p);o=bpy.context.object;o.scale=scale
    o.rotation_euler=(random.uniform(-.15,.15),random.uniform(-.15,.15),random.uniform(0,math.tau))
    return finish_part(o,top,side)
def grass(x,y,z=0):
    for j in range(4):
        o=ico((x+(j-1.5)*.055,y,z+.085),(.020,.035,.11),olive,(.075,.12,.05))
def flower(x,y,z=0):
    ico((x,y,z+.12),(.025,.025,.125),olive,olive)
    ico((x,y,z+.25),(.075,.065,.09),pink,(.36,.16,.37))
def save(name,reference):
    global parts
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    S.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.export_scene.gltf(filepath=str(R/'models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_animations=False)
    manifest.append(dict(id=name,file=f'models/{name}.glb',reference=reference,triangles=sum(len(p.vertices)-2 for p in o.data.polygons),dimensions_blender=list(o.dimensions),pivot='cell center, walking plane z=0; raised geometry top z=1'))
    assets[name]=o;o.hide_render=True;o.hide_set(True);parts=[]
block((0,0,-.16),(2,2,.32),soil,(.24,.16,.09),.02)
patches=[(-.72,-.72),(-.28,-.78),(.32,-.70),(.73,-.52),(-.76,-.18),(.68,.06),(-.66,.43),(-.28,.68),(.20,.76),(.70,.64)]
for i,(x,y) in enumerate(patches):
    grass(x,y)
    if i%2==0:flower(x,y+.13)
save('grass_flowers','sheet01_01_terrain_1061x829.png')
block((0,0,-.20),(2,2,.24),cream,purple,.04)
for x,y,sx,sy in [(-.52,-.49,.91,.94),(.46,-.48,.96,.96),(-.48,.49,.98,.93),(.51,.51,.90,.91)]:
    block((x,y,-.035),(sx,sy,.07),cream,purple,.018)
save('stone','sheet01_09_terrain_328x259.png')
block((0,0,.28),(1.98,1.98,.88),(.47,.39,.49),purple,.12)
block((-.015,0,.83),(1.82,1.80,.34),(.57,.48,.58),purple,.07)
save('high_ground','sheet01_03_terrain_644x567.png')
for row in range(2):
    for col in range(3):
        block((-.66+col*.66,0,.21+row*.38),(.65,.53,.42),cream,purple,.055)
save('ruin_wall','sheet02_03_terrain_739x705.png')
block((0,0,.035),(.40,.36,.07),olive,olive,.025)
for i in range(7):
    a=i*math.tau/7;x=.16*math.cos(a);y=.16*math.sin(a);flower(x,y,.055)
save('flower_clump','sheet02_12_prop_214x204.png')
for i in range(4):
    h=(i+1)*.25
    block((0,-.75+i*.5,h*.5),(1.98,.51,h),cream,purple,.025)
save('stairs','inferred transition; no original stair reference')
(R/'manifest.json').write_text(json.dumps(dict(tile_size_m=2,height_step_m=1,source_axis='Z up',export_axis='Y up',assets=manifest),indent=2))
# Shared layout: Blender Y becomes Godot -Z on glTF export.
cells=[]
for row in range(5):
    for col in range(5):
        high=row==0 and col in [2,3]
        stair=row==1 and col==2
        wall=(row,col) in [(1,4),(2,4),(4,0)]
        model='high_ground' if high else 'stairs' if stair else 'stone' if col==2 else 'grass_flowers'
        cell=dict(x=col,z=row,model=model,height=1 if high else 0,blocked=wall,move_cost=1,cover='full' if wall else 'none')
        if wall:cell['prop']='ruin_wall'
        cells.append(cell)
data=dict(tile_size=2,height_step=1,width=5,depth=5,start=[2,4],cells=cells,explicit_links=[[[2,1],[2,0]]])
(R/'data/grid.json').write_text(json.dumps(data,indent=2))
for c in cells:
    for name in [c['model']]+([c['prop']] if 'prop' in c else []):
        o=assets[name].copy();o.data=assets[name].data;S.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.location=((c['x']-2)*2,(2-c['z'])*2,0)
        if name=='stairs':o.rotation_euler.z=0
S.render.engine='CYCLES';S.cycles.samples=24
S.world.color=(.28,.25,.35)
def area(name,pos,power,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
    o=bpy.data.objects.new(name,d);S.collection.objects.link(o);o.location=pos;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
area('Soft daylight',(-4,-5,10),1800,8,(1,.85,.72));area('Lavender fill',(5,3,7),1000,7,(.66,.65,1))
cam=bpy.data.cameras.new('Camera');o=bpy.data.objects.new('Camera',cam);S.collection.objects.link(o);S.camera=o;cam.type='ORTHO';cam.ortho_scale=15
o.location=(11,-15,14);o.rotation_euler=(Vector((0,0,.25))-o.location).to_track_quat('-Z','Y').to_euler()
S.render.resolution_x=1300;S.render.resolution_y=1000;S.render.resolution_percentage=100
S.view_settings.view_transform='Standard';S.view_settings.look='Medium High Contrast'
S.render.image_settings.file_format='PNG';S.render.filepath=str(R/'review/environment.png')
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/act1.blend'));bpy.ops.render.render(write_still=True)
o.location=(-11,15,12);o.rotation_euler=(Vector((0,0,.25))-o.location).to_track_quat('-Z','Y').to_euler();S.render.filepath=str(R/'review/reverse.png');bpy.ops.render.render(write_still=True)
for obj in S.objects:
    if obj.type=='MESH' and not obj.hide_render:
        mod=obj.modifiers.new('Topology','WIREFRAME');mod.thickness=.005;mod.use_even_offset=False
S.render.filepath=str(R/'review/wire.png');bpy.ops.render.render(write_still=True)

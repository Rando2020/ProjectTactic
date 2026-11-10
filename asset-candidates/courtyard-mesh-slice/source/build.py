import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
random.seed(923)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
S=bpy.context.scene;S.unit_settings.system='METRIC'
objects=[]
def material(name,color,texture=False):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    n=m.node_tree.nodes;l=m.node_tree.links;b=n.get('Principled BSDF');b.inputs['Roughness'].default_value=.9
    v=n.new('ShaderNodeVertexColor');v.layer_name='Paint'
    if texture:
        t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(R/'textures/painted-limestone.png'),check_existing=True)
        mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
        l.new(t.outputs['Color'],mix.inputs[1]);l.new(v.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],b.inputs['Base Color'])
    else:l.new(v.outputs['Color'],b.inputs['Base Color'])
    return m
stone=material('Painted limestone',(.84,.80,.76),True)
earth=material('Ochre earth',(.30,.19,.075),True)
green=material('Olive leaves',(.16,.22,.065))
petal=material('Lilac petals',(.61,.29,.56))
stem=material('Flower stems',(.07,.12,.038))
def finish(o,m):
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
    o.data.materials.append(m)
    # World-space planar UVs: grain scale stays consistent across differently sized stones.
    uv=o.data.uv_layers.active.data
    off=Vector((random.random(),random.random()))
    for f in o.data.polygons:
        for li in f.loop_indices:
            p=o.data.vertices[o.data.loops[li].vertex_index].co
            if abs(f.normal.z)>.5: q=Vector((p.x,p.y))
            elif abs(f.normal.x)>.5:q=Vector((p.y,p.z))
            else:q=Vector((p.x,p.z))
            uv[li].uv=q*.65+off
    c=o.data.color_attributes.new(name='Paint',type='FLOAT_COLOR',domain='CORNER')
    base=m.diffuse_color[:3];variation=random.uniform(.85,1.09)
    for f in o.data.polygons:
        tint=variation*random.uniform(.94,1.05)
        side=(.68,.65,.87) if m==stone and f.normal.z<.3 else (1,1,1)
        for li in f.loop_indices:c.data[li].color=(*(base[i]*tint*side[i] for i in range(3)),1)
    objects.append(o);o.select_set(False);return o
def rock(name,pos,size,chip=False,m=stone):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for v in o.data.vertices:
        v.co+=Vector((random.uniform(-.05,.05),random.uniform(-.04,.04),random.uniform(-.025,.025)))
    bevel=o.modifiers.new('Broad chipped planes','BEVEL');bevel.width=min(size)*.16;bevel.segments=2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    if chip:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=min(size)*random.uniform(.28,.48),location=Vector(pos)+Vector((size[0]*random.choice([-.50,.50]),-size[1]*.50,size[2]*.50)))
        cutter=bpy.context.object;bpy.context.view_layer.objects.active=o
        mod=o.modifiers.new('Missing corner','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    o.rotation_euler=(random.uniform(-.012,.012),random.uniform(-.012,.012),random.uniform(-.025,.025))
    return finish(o,m)
def mesh(name,verts,faces,m):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update();o=bpy.data.objects.new(name,d);S.collection.objects.link(o);return finish(o,m)
def rod(a,b,r,m):
    a=Vector(a);b=Vector(b);bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=r,radius2=r*.5,depth=(b-a).length,location=(a+b)*.5)
    o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return finish(o,m)
def leaf(p,angle,length,width):
    p=Vector(p);axis=Vector((math.cos(angle),math.sin(angle),0));cross=Vector((-math.sin(angle),math.cos(angle),0))
    verts=[]
    for t,w in [(0,.10),(.35,1),(.75,.65),(1,.015)]:
        center=p+axis*(length*.65*t*t)+Vector((0,0,length*(1.4*t-.65*t*t)))
        verts.extend([center+cross*width*w,center-cross*width*w,center+Vector((0,0,.012))])
    faces=[]
    for j in range(3):
        a=j*3;b=a+3
        faces.extend([(a,b,b+2,a+2),(a+2,b+2,b+1,a+1),(a+1,b+1,b,a)])
    faces.extend([(0,2,1),(9,10,11)])
    return mesh('Tapered leaf',verts,faces,green)
def flower(x,y,h):
    rod((x,y,-.015),(x+.025,y,h),.009,stem)
    for layer in range(2):
        for j in range(5):
            a=j*math.tau/5+layer*.65
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x+.025+math.cos(a)*.025,y+math.sin(a)*.025,h+layer*.045))
            o=bpy.context.object;o.scale=(.043,.027,.027);o.rotation_euler=(.3,a,a);finish(o,petal)
# The surface is one continuous mesh, not a repeated tile array.
verts=[];faces=[];nx=30;ny=24
for y in range(ny+1):
    for x in range(nx+1):
        px=-3+x*.2;py=-2.4+y*.2
        verts.append((px,py,-.055+.017*math.sin(px*3+py*2)+random.uniform(-.008,.008)))
for y in range(ny):
    for x in range(nx):
        a=y*(nx+1)+x;faces.append((a,a+1,a+nx+2,a+nx+1))
o=mesh('Continuous soil',verts,faces,earth)
bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Soil depth','SOLIDIFY');mod.thickness=.16;mod.offset=1;bpy.ops.object.modifier_apply(modifier=mod.name)
# Solidify creates side faces: unwrap these after the modifier as well.
o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
# Staggered wall: broken descending end, tall pier and surviving return.
for row,count in enumerate([6,6,5,4]):
    for col in range(1,count):
        x=-2.3+col*.72+(row%2)*.22
        rock('Wall stone',(x,1.25,row*.34+.14),(.70,.57,.36),chip=(col+row)%3==0)
for row in range(5):rock('Pier stone',(-2.32,1.23,.17+row*.35),(.83,.76,.36),chip=True)
for row in range(2):
    for j in range(2):rock('Wall return',(-2.32,.48-j*.65,.15+row*.34),(.60,.60,.33),chip=j==1)
# Worn paving is unevenly spaced; soil occupies real gaps and missing slabs.
for row in range(4):
    for col in range(5):
        if (row,col) in [(0,0),(1,4),(3,0),(3,4),(2,0)]:continue
        x=-1.8+col*.83+(row%2)*.22;y=-1.98+row*.67
        o=rock('Worn paving',(x,y,-.045),(.77+random.uniform(-.06,.06),.61,.14),chip=(row+col)%3==0)
        o.rotation_euler.z=random.uniform(-.045,.045)
for i in range(18):
    x=random.uniform(.8,2.3);y=random.uniform(.65,1.8)
    rock('Fallen masonry',(x,y,.06),(.20+random.random()*.25,.20+random.random()*.17,.19),chip=True)
clusters=[(-2,.55),(-1.5,.82),(-.8,.85),(.1,.90),(1.55,.35),(2.1,1.15),(-2.5,-.8),(2.3,-1.65)]
for cx,cy in clusters:
    for i in range(16):
        x=cx+random.uniform(-.20,.20);y=cy+random.uniform(-.18,.18)
        leaf((x,y,-.06),random.random()*math.tau,random.uniform(.25,.55),random.uniform(.025,.052))
    for i in range(9):flower(cx+(i%3-1)*.13+random.uniform(-.012,.012),cy+(i//3-1)*.13,random.uniform(.25,.53))
for i in range(40):
    x=random.uniform(-2.6,2.6);y=random.uniform(-2.2,.65)
    if -.9<x<1.2:continue
    rock('Small stone',(x,y,-.01),(.055+random.random()*.07,.06,.06))
# Join by material: preserve geometry while reducing draw calls.
groups=[]
material_groups=[(mat,[o for o in objects if o.data.materials[0]==mat]) for mat in [stone,earth,green,petal,stem]]
for mat,group in material_groups:
    bpy.ops.object.select_all(action='DESELECT')
    for o in group:o.select_set(True)
    bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join();o=bpy.context.object;o.name=mat.name;groups.append(o)
bpy.ops.object.select_all(action='DESELECT')
for o in groups:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'models/courtyard-section.glb'),export_format='GLB',use_selection=True,export_animations=False)
report=[dict(name=o.name,triangles=sum(len(f.vertices)-2 for f in o.data.polygons)) for o in groups]
(R/'manifest.json').write_text(json.dumps(dict(units='meters',source_up='Z',export_up='Y',objects=report,collision=False,texture='AI-generated limestone base color, sRGB; multiplied with authored vertex tint'),indent=2))
S.world.use_nodes=True;S.world.node_tree.nodes['Background'].inputs[0].default_value=(.36,.31,.46,1);S.world.node_tree.nodes['Background'].inputs[1].default_value=.5
for name,p,col,power,size in [('Warm sky',(-3,-4,7),(1,.83,.64),1000,4),('Cool fill',(4,3,6),(.68,.71,1),650,5)]:
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.color=col;d.size=size;o=bpy.data.objects.new(name,d);S.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((0,0,.4))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',d);S.collection.objects.link(cam);S.camera=cam;d.type='ORTHO';d.ortho_scale=7.5
def aim(p):cam.location=p;cam.rotation_euler=(Vector((0,0,.4))-cam.location).to_track_quat('-Z','Y').to_euler()
aim((7,-10,9));S.render.engine='CYCLES';S.cycles.samples=32;S.cycles.use_denoising=True;S.view_settings.view_transform='AgX'
S.render.resolution_x=1400;S.render.resolution_y=1100;S.render.resolution_percentage=100
for im in bpy.data.images:
    if im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/courtyard-section.blend'))
for name,p in [('section',(7,-10,9)),('reverse',(-7,9,7))]:
    aim(p);S.render.filepath=str(R/'review'/f'{name}.png');bpy.ops.render.render(write_still=True)
for o in groups:
    mod=o.modifiers.new('Wire review','WIREFRAME');mod.thickness=.002;mod.use_even_offset=False
aim((7,-10,9));S.render.filepath=str(R/'review/wire.png');bpy.ops.render.render(write_still=True)

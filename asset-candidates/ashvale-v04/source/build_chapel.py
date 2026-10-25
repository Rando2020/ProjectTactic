"""Original chapel approach; Blender 4.5.9. Dimensions are authored/inferred.
2 m grid contract retained. All geometry is reproducible from seed 301.
"""
import bpy, bmesh, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
random.seed(301)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
S=bpy.context.scene;S.unit_settings.system='METRIC'
parts=[];assets={};report=[]

def mat(name,color,rough=.85,metal=0,paint=False,emit=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    n=m.node_tree.nodes;b=next(x for x in n if x.type=='BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value=(*color,1);b.inputs['Roughness'].default_value=rough;b.inputs['Metallic'].default_value=metal
    if paint:
        v=n.new('ShaderNodeVertexColor');v.layer_name='Paint'
        m.node_tree.links.new(v.outputs['Color'],b.inputs['Base Color'])
    if emit:
        b.inputs['Emission Color'].default_value=(*color,1);b.inputs['Emission Strength'].default_value=emit
    return m
stone=mat('Slate_painted_planes',(.25,.32,.33),paint=True)
trim=mat('Warm_cut_edges',(.43,.40,.31),paint=True)
wood=mat('Weathered_wood',(.21,.12,.067),paint=True)
bark=mat('Blue_charcoal_bark',(.09,.12,.135),paint=True)
iron=mat('Forged_blue_iron',(.045,.075,.09),.52,.65,True)
brass=mat('Muted_ochre_metal',(.35,.21,.07),.6,.6,True)
glass=mat('Amber_lantern_panels',(1,.31,.055),.5,0,False,2.2)
moss=mat('Dry_moss',(.13,.17,.085),paint=True)
earth=mat('Packed_charcoal_earth',(.075,.065,.045),paint=True)
cloth=mat('Faded_oxblood',(.22,.025,.035),.96,paint=True)
thread=mat('Faded_gold_thread',(.32,.19,.085),.9,paint=True)
# Image albedo plus broad vertex tint. No baked lighting or shader-only noise.
stone.diffuse_color=(.8,.86,.84,1)
nodes=stone.node_tree.nodes
tex=nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(R/'textures/chapel-painted-slate.png'))
mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
stone.node_tree.links.new(tex.outputs['Color'],mix.inputs[1])
stone.node_tree.links.new(next(n for n in nodes if n.type=='VERTEX_COLOR').outputs['Color'],mix.inputs[2])
stone.node_tree.links.new(mix.outputs['Color'],next(n for n in nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'])
def paint_image(material,filename,tint):
    material.diffuse_color=(*tint,1)
    n=material.node_tree.nodes;l=material.node_tree.links
    image=n.new('ShaderNodeTexImage');image.image=bpy.data.images.load(str(R/'textures'/filename),check_existing=True)
    blend=n.new('ShaderNodeMixRGB');blend.blend_type='MULTIPLY';blend.inputs[0].default_value=1
    l.new(image.outputs['Color'],blend.inputs[1]);l.new(next(x for x in n if x.type=='VERTEX_COLOR').outputs['Color'],blend.inputs[2])
    l.new(blend.outputs['Color'],next(x for x in n if x.type=='BSDF_PRINCIPLED').inputs['Base Color'])
paint_image(trim,'chapel-painted-limestone.png',(.60,.57,.48))
paint_image(wood,'chapel-painted-timber.png',(.78,.67,.52))
paint_image(bark,'chapel-painted-timber.png',(.42,.49,.52))

def register(o,name,m):
    o.name=name;o.data.materials.append(m);parts.append(o);return o
def mesh(name,v,f,m):
    d=bpy.data.meshes.new(name);d.from_pydata(v,[],f);d.update()
    o=bpy.data.objects.new(name,d);S.collection.objects.link(o);return register(o,name,m)
def block(name,p,size,m=stone,bevel=.06,warp=.015):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    # Offset corners before bevel so blocks have deliberately uneven edges.
    for v in o.data.vertices:
        v.co+=Vector((random.uniform(-warp,warp),random.uniform(-warp,warp),random.uniform(-warp,warp)))
    mod=o.modifiers.new('Chipped_edges','BEVEL');mod.width=bevel;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Broad, intentional corner spalls, physically removed from selected masonry.
    if name in ('Spring_cap','Buttress_cap','Broken_shoulder','Drip_course'):
        corner=Vector(p)+Vector((size[0]*.38,-size[1]*.48,size[2]*.23))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=min(size[0]*.20,.15),location=corner)
        cutter=bpy.context.object;cutter.scale=(1.25,.9,.8)
        bpy.context.view_layer.objects.active=o
        cut=o.modifiers.new('Edge_spall','BOOLEAN');cut.operation='DIFFERENCE';cut.solver='EXACT';cut.object=cutter
        bpy.ops.object.modifier_apply(modifier=cut.name);bpy.data.objects.remove(cutter,do_unlink=True)
    return register(o,name,m)
def loft(name,rings,m,n=10):
    v=[]
    for x,y,z,rx,ry in rings:
        v += [(x+rx*math.cos(i*math.tau/n),y+ry*math.sin(i*math.tau/n),z) for i in range(n)]
    f=[tuple(reversed(range(n)))]
    for k in range(len(rings)-1):
        f += [(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i) for i in range(n)]
    f.append(tuple(range((len(rings)-1)*n,len(rings)*n)))
    return mesh(name,v,f,m)
def tube(name,points,radii,m,n=8):
    v=[]
    for j,(p,r) in enumerate(zip(points,radii)):
        p=Vector(p);a=Vector(points[max(0,j-1)]);b=Vector(points[min(len(points)-1,j+1)])
        q=(b-a).normalized().to_track_quat('Z','Y')
        for i in range(n):v.append(p+q@Vector((r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n),0)))
    f=[tuple(reversed(range(n)))]
    for j in range(len(points)-1):f += [(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for i in range(n)]
    f.append(tuple(range((len(points)-1)*n,len(points)*n)))
    return mesh(name,v,f,m)
def rod(name,a,b,r,m):return tube(name,[a,b],[r,r],m)
def surface(o):
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
    material=o.data.materials[0]
    # Align timber grain with plank length; tree projection follows its tall axis.
    if material in (wood,bark):
        uv=o.data.uv_layers.active.data
        for face in o.data.polygons:
            for li in face.loop_indices:
                p=o.data.vertices[o.data.loops[li].vertex_index].co
                if abs(face.normal.z)>max(abs(face.normal.x),abs(face.normal.y)):
                    uv[li].uv=(p.x*.5+.5,p.y*.5+.5)
                else:
                    u=(p.x if abs(face.normal.y)>=abs(face.normal.x) else p.y)*.50+.5
                    uv[li].uv=(u,p.z*.25+.07)
    else:
        offset=Vector((random.uniform(.04,.14),random.uniform(.04,.14)))
        for uv in o.data.uv_layers.active.data:uv.uv=uv.uv*.78+offset
    c=o.data.color_attributes.new(name='Paint',type='FLOAT_COLOR',domain='CORNER')
    # Sparse, broad color planes, no baked directional light. Vertex colors export in GLB.
    object_tint=random.uniform(.86,1.12)
    for face in o.data.polygons:
        base=o.data.materials[face.material_index].diffuse_color[:3]
        tint=object_tint*random.uniform(.90,1.10)
        for li in face.loop_indices:c.data[li].color=(*(min(.9,x*tint) for x in base),1)
    o.select_set(False)
def finish(name):
    global parts
    bpy.ops.object.select_all(action='DESELECT')
    if name=='EN_twisted_ash_tree':
        for o in parts:o.select_set(True)
        bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();tree=bpy.context.object
        mod=tree.modifiers.new('Connected_wood','REMESH');mod.mode='VOXEL';mod.voxel_size=.028
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=tree.modifiers.new('Broad_planes','DECIMATE');mod.ratio=.35
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bm=bmesh.new();bm.from_mesh(tree.data)
        remaining=set(bm.verts);components=[]
        while remaining:
            seed=remaining.pop();group={seed};stack=[seed]
            while stack:
                current=stack.pop()
                for edge in current.link_edges:
                    other=edge.other_vert(current)
                    if other in remaining:remaining.remove(other);group.add(other);stack.append(other)
            components.append(group)
        main=max(components,key=len)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if v not in main],context='VERTS')
        bm.to_mesh(tree.data);bm.free()
        parts=[tree];tree.select_set(False)
    for o in parts:surface(o)
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    S.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    if not name.startswith('EN_flagstone'):
        low=min(v.co.z for v in o.data.vertices)
        for v in o.data.vertices:v.co.z-=low
    bpy.ops.export_scene.gltf(filepath=str(R/'models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_animations=False)
    tris=sum(len(p.vertices)-2 for p in o.data.polygons)
    report.append(dict(id=name,triangles=tris,dimensions=list(o.dimensions),file=f'models/{name}.glb'))
    assets[name]=o;o.hide_render=True;o.hide_set(True);parts=[]

# Floor: flat walking plane at zero, recessed joints, individually cut slabs.
block('Substrate',(0,0,-.19),(2,2,.22),earth,.025,0)
for row in range(3):
    for col in range(3):
        w=.625;d=.625;x=(col-1)*.66;y=(row-1)*.66
        o=block('Flagstone',(x,y,-.07),(w,d,.14),stone,.035,.012)
        # Authored top remains approximately level; visual only, no physics mesh.
        if (row+col)%3==0:
            block('Moss_joint',(x+.29,y,-.025),(.045,.36,.025),moss,.008,.002)
finish('EN_flagstone_2m')

# A second bond pattern breaks the uniform checkerboard when tiles alternate.
block('Substrate',(0,0,-.19),(2,2,.22),earth,.025,0)
for row,(low,high) in enumerate([(-.98,-.35),(-.32,.31),(.34,.98)]):
    cuts=[-.98,-.14,.98] if row!=1 else [-.98,-.53,.40,.98]
    for a,b in zip(cuts,cuts[1:]):
        block('Long_flagstone',((a+b)/2,(low+high)/2,-.07),(b-a-.025,high-low,.14),stone,.034,.012)
finish('EN_flagstone_bond_2m')

# Gothic gate: clear 2.2 m opening, pointed crown, battered masonry piers.
for sign in (-1,1):
    x=sign*1.49
    block('Plinth',(x,0,.15),(.96,1.13,.30),trim,.075,.012)
    for j in range(7):
        block('Pier_course',(x+sign*.014*math.sin(j),0,.47+j*.34),(.73-j*.012,.83,.345),stone,.055,.018)
    block('Spring_cap',(x,0,2.78),(.94,1.05,.20),trim,.04,.012)
    # Paired slender engaged shafts frame the silhouette.
    for xx in (x-.24,x+.24):
        loft('Engaged_shaft',[(xx,-.42,.26,.105,.105),(xx,-.42,2.59,.085,.085)],trim,8)
    block('Outer_shoulder',(sign*1.92,.12,1.20),(.37,.91,2.22),stone,.055,.025)

def curve(t,sign):
    # Quadratic arch from spring point to cusp.
    a=Vector((sign*1.10,2.63));b=Vector((sign*1.08,3.43));c=Vector((0,4.04))
    p=(1-t)**2*a+2*(1-t)*t*b+t*t*c
    tangent=2*(1-t)*(b-a)+2*t*(c-b)
    normal=Vector((sign*abs(tangent.y),abs(tangent.x))).normalized()
    return p,normal
for sign in (-1,1):
    for k in range(10):
        a,na=curve(k/10+.002,sign);b,nb=curve((k+1)/10-.002,sign)
        poly=[a,b,b+nb*.38,a+na*.38]
        v=[(p.x,y,p.y) for y in (-.45,.45) for p in poly]
        o=mesh('Arch_wedge',v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],trim if k%4==1 else stone)
        # A thin parallel moulding creates a readable front edge, attached to arch.
        aa=a+na*.08;bb=b+nb*.08
        aa,bb=aa.lerp(bb,.07),bb.lerp(aa,.07)
        rod('Arch_edge',(aa.x,-.464,aa.y),(bb.x,-.464,bb.y),.048,trim)
    # Stepped, asymmetrically broken side crown.
    h=3.32 if sign<0 else 3.02
    block('Broken_shoulder',(sign*1.58,.08,(2.87+h)/2),(.7,.86,h-2.87),stone,.05,.035)
    loft('Side_pinnacle',[(sign*1.72,.12,h-.03,.20,.21),(sign*1.72,.12,h+.14,.22,.23),(sign*1.69,.12,h+.67,.03,.04)],stone,6)
loft('Keystone',[(0,0,3.86,.16,.50),(0,0,4.30,.24,.50),(0,0,4.43,.13,.43)],trim,8)
block('Crown_socket',(0,.03,4.46),(.38,.54,.18),stone,.025,.008)
loft('Crown_spire',[(0,.03,4.48,.13,.14),(.03,.03,4.86,.015,.018)],iron,6)
finish('AR_chapel_gate_4m')

# Buttress: a strong sloping silhouette instead of stacked equal cubes.
block('Buttress_foot',(0,0,.15),(1.14,1.48,.30),trim,.075,.012)
for j in range(7):
    d=1.20-j*.105;w=.82-j*.04
    block('Battered_course',(0,.16+j*.035,.48+j*.35),(w,d,.355),stone,.045,.018)
    if j in (2,5):block('Drip_course',(0,.16+j*.035,.66+j*.35),(w+.13,d+.10,.105),trim,.025,.005)
block('Buttress_cap',(0,.40,2.96),(.73,.72,.20),trim,.03,.01)
loft('Broken_finial',[(0,.40,3.01,.29,.30),(.025,.40,3.49,.12,.15),(.05,.40,3.57,.09,.10)],stone,6)
finish('AR_battered_buttress')

# Forged lantern on a crooked, tapered post; panels opaque to keep overdraw low.
loft('Stone_foot',[(0,0,0,.27,.27),(0,0,.16,.30,.30),(0,0,.31,.18,.18)],stone,8)
tube('Iron_post',[(0,0,.22),(-.03,0,1.2),(.01,0,2.25),(.16,0,2.57),(.50,0,2.62),(.64,0,2.43)],[.065,.047,.044,.041,.036,.027],iron)
tube('Brace',[(0,0,1.99),(.24,0,2.10),(.43,0,2.35),(.5,0,2.6)],[.023]*4,brass)
rod('Hanger',(.64,0,2.44),(.64,0,2.23),.023,iron)
loft('Lantern_roof',[(.64,0,2.23,.05,.05),(.64,0,2.12,.24,.22),(.64,0,2.08,.24,.22)],iron,6)
loft('Amber_core',[(.64,0,1.63,.13,.12),(.64,0,2.08,.19,.17)],glass,6)
for i in range(6):
    t=i*math.tau/6
    rod('Lantern_rib',(.64+.14*math.cos(t),.13*math.sin(t),1.61),(.64+.20*math.cos(t),.18*math.sin(t),2.10),.025,iron)
loft('Lantern_base',[(.64,0,1.56,.08,.075),(.64,0,1.63,.19,.18),(.64,0,1.67,.17,.16)],iron,6)
finish('PR_crooked_lantern')

# Connected branch paths; root flare sits at zero. Uneven tapered silhouette.
tube('Trunk',[(0,0,.14),(-.13,.04,.65),(.04,.01,1.3),(.08,.03,2.0),(.35,.04,2.65),(.21,.05,3.18),(.40,.08,3.77)],[.28,.24,.19,.15,.10,.064,.013],bark,12)
branches=[([(.03,.02,1.35),(-.45,.03,1.88),(-.79,-.02,2.17),(-1.12,-.10,2.63)],[.17,.12,.075,.012]),
          ([(-.55,.02,1.99),(-1.01,.15,2.05),(-1.48,.19,2.32)],[.085,.055,.009]),
          ([(.12,.03,2.1),(.59,-.12,2.21),(.90,-.17,2.57),(1.2,-.19,2.87)],[.12,.085,.05,.008]),
          ([(.28,.04,2.72),(-.12,.25,3.07),(-.43,.29,3.49)],[.073,.046,.008]),
          ([(.04,.01,1.25),(.23,.49,1.72),(.13,.82,2.19)],[.12,.06,.009])]
for points,radii in branches:tube('Branch',points,radii,bark)
for i in range(5):
    t=i*math.tau/5
    tube('Root',[(0,0,.30),(.35*math.cos(t),.35*math.sin(t),.13),(.68*math.cos(t),.68*math.sin(t),.055)],[.16,.09,.015],bark)
finish('EN_twisted_ash_tree')

# Timber barricade with uneven split tips, broad grain grooves and iron binding.
for x in (-.66,.66):
    o=block('Trestle',(x,0,.50),(.17,.9,1.0),wood,.035,.02);o.rotation_euler.y=x*.10
for j in range(6):
    x=-.85+j*.34;h=1.17+random.uniform(-.17,.18)
    v=[(x-.145,-.18,.12),(x+.145,-.18,.12),(x+.135,-.18,h-.11),(x+.05,-.18,h),(x-.13,-.18,h-.05)]
    v += [(a,.02,c) for a,b,c in v]
    f=[(4,3,2,1,0),(5,6,7,8,9)]+[(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)]
    mesh('Split_plank',v,f,wood)
    for k in range(2):rod('Dark_grain',(x-.07+k*.11,-.186,.25),(x-.05+k*.10,-.186,h-.17),.009,bark)
for z in (.38,.91):
    block('Iron_strap',(0,-.21,z),(2.08,.045,.07),iron,.01,0)
    for x in (-.85,-.17,.51):rod('Rivet',(x,-.235,z),(x,-.25,z),.024,brass)
finish('PR_splitwood_barricade')

# Folded banner: real thick cloth with a broken hem, no transparency planes.
loft('Banner_plinth',[(0,0,0,.31,.29),(0,0,.18,.27,.25),(0,0,.27,.17,.16)],stone,8)
rod('Banner_post',(0,0,.20),(0,0,3.10),.043,iron)
rod('Banner_crossbar',(-.66,-.015,2.77),(.66,-.015,2.77),.034,brass)
loft('Banner_finial',[(0,0,3.05,.07,.07),(0,0,3.30,.008,.008)],brass,6)
v=[];cols=48;rows=64
for j in range(rows+1):
    t=j/rows
    for i in range(cols+1):
        u=i/cols
        # Zero wave at the bar, larger folds toward the trailing bottom.
        x=(u-.5)*1.10+.075*t*t
        y=-.045-.16*math.sin(u*math.tau*2.1+.4*t)*math.sin(t*math.pi*.8)-.035*t
        rag=(.08*math.sin(u*math.pi*11)+.045*math.cos(u*math.pi*7))*(max(0,t-.82)/.18)**2
        z=2.75-1.63*t+rag-.07*math.sin(math.pi*u)*t
        v.append((x,y,z))
f=[];emblem=[]
for j in range(rows):
    for i in range(cols):
        if j>=rows-4 and i in (8,9,26,27,40,41):continue
        a=j*(cols+1)+i
        f.append((a,a+1,a+cols+2,a+cols+1))
        u=(i+.5)/cols;t=(j+.5)/rows
        diamond=abs(u-.5)/.29+abs(t-.34)/.18
        emblem.append(.78<diamond<1.18 or i in (1,cols-2))
o=mesh('Torn_oxblood_cloth',v,f,cloth);o.data.materials.append(thread)
for face,gold in zip(o.data.polygons,emblem):face.material_index=1 if gold else 0
bpy.context.view_layer.objects.active=o
mod=o.modifiers.new('Woven_thickness','SOLIDIFY');mod.thickness=.014
bpy.ops.object.modifier_apply(modifier=mod.name)
finish('PR_torn_ashvale_banner')

# Fallen masonry on an irregular dust bed; static scatter footprint ~1.8 m.
loft('Rubble_dust',[(0,0,0,.77,.51),(0,0,.065,.89,.60),(0,0,.10,.72,.44)],earth,11)
for i,(x,y,z,sx,sy,sz) in enumerate([(-.40,-.12,.20,.60,.34,.32),(.24,.10,.22,.66,.44,.36),(-.06,-.10,.44,.52,.34,.30),(.55,-.25,.16,.32,.31,.22),(-.60,.22,.16,.27,.26,.21)]):
    o=block('Fallen_stone',(x,y,z),(sx,sy,sz),trim if i==2 else stone,.06,.025)
    o.rotation_euler=(.06*(i%2),.12*(i-2),i*.43)
finish('EN_fallen_masonry')

# Set dressing assembled separately from reusable models.
show=[]
def place(name,p,angle=0):
    src=assets[name];o=src.copy();o.data=src.data;S.collection.objects.link(o);o.name='Scene_'+name
    o.hide_render=False;o.hide_set(False);o.location=p;o.rotation_euler.z=angle;show.append(o);return o
for x in range(4):
    for y in range(4):place('EN_flagstone_2m' if (x+y)%3==0 else 'EN_flagstone_bond_2m',((x-1.5)*2,(y-1.5)*2,0),(x+y)%4*math.pi/2)
place('AR_chapel_gate_4m',(0,2.65,0))
place('AR_battered_buttress',(-2.8,2.6,0));place('AR_battered_buttress',(2.8,2.6,0))
place('PR_crooked_lantern',(-1.8,1.2,0));place('PR_crooked_lantern',(1.8,1.2,0),math.pi)
place('EN_twisted_ash_tree',(-3,0,0),-.5);place('EN_twisted_ash_tree',(3,2,0),1.8)
place('PR_splitwood_barricade',(2.6,-1.7,0),-.35)
place('PR_torn_ashvale_banner',(-2.35,1.75,0),-.12)
place('PR_torn_ashvale_banner',(2.50,.40,0),.20)
place('EN_fallen_masonry',(-2.5,-1.85,0),.4)
place('EN_fallen_masonry',(3.15,1.45,0),1.7)
bpy.ops.object.select_all(action='DESELECT')
for o in show:o.select_set(True)
bpy.context.view_layer.objects.active=show[0]
bpy.ops.export_scene.gltf(filepath=str(R/'models/SC_chapel_approach.glb'),export_format='GLB',use_selection=True,export_animations=False)
manifest={'status':'art-candidate-v04','tile_m':2,'elevation_m':1,'units':'meters','export_up':'Y','source_up':'Z','assets':report,'scene':'models/SC_chapel_approach.glb','materials':'Painted slate, limestone and timber albedo with vertex tint; standard metallic/roughness, amber emissive','collision':'none; use authoritative tactical grid','inferred':'All designs, dimensions beyond grid contract, backs and wear patterns are authored. No matched orthographic reference supplied.'}
(R/'asset-manifest.json').write_text(json.dumps(manifest,indent=2))

S.world.use_nodes=True;bg=S.world.node_tree.nodes['Background'];bg.inputs[0].default_value=(.065,.10,.16,1);bg.inputs[1].default_value=.35
def area(name,p,color,power,size):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.color=color;d.shape='DISK';d.size=size
    o=bpy.data.objects.new(name,d);S.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area('Warm_moon',(-4,-4,10),(1,.77,.52),1600,5)
area('Blue_rim',(4,5,7),(.30,.52,1),2200,4)
for x in (-1.16,1.16):
    d=bpy.data.lights.new('Lantern_pool','POINT');d.energy=85;d.color=(1,.24,.035);d.shadow_soft_size=.28
    o=bpy.data.objects.new('Lantern_pool',d);S.collection.objects.link(o);o.location=(x,1.12,1.85)
d=bpy.data.cameras.new('Art_review');cam=bpy.data.objects.new('Art_review',d);S.collection.objects.link(cam);S.camera=cam
cam.location=(11,-15,12);cam.rotation_euler=(Vector((0,.3,1))-cam.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=13
S.render.engine='CYCLES';S.cycles.samples=40;S.cycles.use_denoising=True;S.view_settings.view_transform='AgX'
S.render.resolution_x=1500;S.render.resolution_y=1250;S.render.resolution_percentage=100
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/chapel-master.blend'))
S.render.filepath=str(R/'review/chapel-approach.png');bpy.ops.render.render(write_still=True)
# Neutral light gate closeup keeps lighting from concealing construction.
for o in show:o.hide_render=True
hero=assets['AR_chapel_gate_4m'];hero.hide_render=False;hero.hide_set(False)
cam.location=(7,-12,7);cam.rotation_euler=(Vector((0,0,2.2))-cam.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=6.7
S.render.resolution_x=1000;S.render.resolution_y=1000
S.render.filepath=str(R/'review/gate-detail.png');bpy.ops.render.render(write_still=True)
print('CHAPEL_BUILD_PASS',len(report))

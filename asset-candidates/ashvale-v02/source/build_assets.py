"""Original Ashvale candidate meshes. Run with Blender 4.5 LTS, factory startup.
All dimensions below are authored/inferred except 2 m grid / 1 m elevation.
"""
import bpy, math, random, json, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
random.seed(173)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system='METRIC'
scene.unit_settings.scale_length=1
scene.render.fps=30
ASSETS={}
parts=[]

def material(name,color,rough=.8,metal=0,texture=False,emission=0):
    m=bpy.data.materials.new(name); m.use_nodes=True
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough
    bs.inputs['Metallic'].default_value=metal
    m.diffuse_color=(*color,1)
    if texture:
        tex=m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image=bpy.data.images.load(str(ROOT/'textures/ashvale-painted-stone.png'),check_existing=True)
        tex.image.colorspace_settings.name='sRGB'
        m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    if emission:
        bs.inputs['Emission Color'].default_value=(*color,1)
        bs.inputs['Emission Strength'].default_value=emission
    return m

stone=material('M_PaintedSlate',(.32,.34,.36),texture=True)
darkstone=material('M_CutSlate',(.115,.145,.17))
steel=material('M_BlueSteel',(.12,.19,.24),.48,.75)
edge=material('M_SteelEdges',(.29,.37,.40),.42,.8)
brass=material('M_AgedBrass',(.39,.24,.085),.55,.65)
cloth=material('M_Oxblood',(.30,.026,.039),.95)
clothlight=material('M_EmberCloth',(.48,.055,.045),.92)
leather=material('M_DarkLeather',(.045,.035,.031),.9)
ember=material('M_Ember',(.9,.23,.035),.65,0,2.0)
black=material('M_Visor',(.008,.015,.022),.72)
tex=steel.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(ROOT/'textures/vanguard-painted-steel.png'))
steel.node_tree.links.new(tex.outputs['Color'],next(n for n in steel.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'])

def register(o,name,mat,bone=None):
    o.name=name; o.data.name=name+'_Mesh'
    o.data.materials.append(mat)
    if bone:
        vg=o.vertex_groups.new(name=bone)
        vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    parts.append(o)
    return o

def cube(name,loc,size,mat=stone,bevel=.035,bone=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object; o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Hand_cut_edges','BEVEL');mod.width=bevel;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return register(o,name,mat,bone)

def mesh(name,verts,faces,mat=stone,bone=None):
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);scene.collection.objects.link(o)
    return register(o,name,mat,bone)

def ringbody(name,rings,mat,bone=None,n=8):
    # Each ring is (x,y,z,xradius,yradius), outward winding.
    v=[(x+rx*math.cos(2*math.pi*i/n),y+ry*math.sin(2*math.pi*i/n),z) for x,y,z,rx,ry in rings for i in range(n)]
    faces=[tuple(reversed(range(n)))]
    for k in range(len(rings)-1):
        faces += [(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i) for i in range(n)]
    faces += [tuple(range((len(rings)-1)*n,len(rings)*n))]
    return mesh(name,v,faces,mat,bone)

def rod(name,a,b,r,mat,bone=None,r2=None,n=8):
    d=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=n,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(Vector(a)+Vector(b))/2)
    o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return register(o,name,mat,bone)

def unwrap(objs):
    for o in objs:
        if o.type!='MESH':continue
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.025)
        bpy.ops.object.mode_set(mode='OBJECT')
        # Keep sampling off the unverified generated texture borders.
        for uv in o.data.uv_layers.active.data:uv.uv=uv.uv*.84+Vector((.08,.08))

def finish(name,rig=None):
    global parts
    objs=list(parts);unwrap(objs)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.join();o=bpy.context.object;o.name=name
    scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    if rig:
        mod=o.modifiers.new('Skin','ARMATURE');mod.object=rig;o.parent=rig
    ASSETS[name]=[o]+([rig] if rig else [])
    parts=[]
    return o

# Modular environmental sources, all authored at their local origin.
for variant in range(2):
    cube('Substrate',(0,0,-.14),(2,2,.28),darkstone,.02)
    for x in range(2):
        for y in range(2):
            c=cube('Flagstone',(x-.5,y-.5,-.035),(.973,.973,.12),stone,.045)
            if variant:c.rotation_euler.z=random.uniform(-.009,.009)
    if variant:
        for i in range(3):
            c=cube('Mineral_inlay',(-.55+i*.12,.50-i*.12,.031),(.15,.025,.006),brass,.002);c.rotation_euler.z=-.65
    finish('floor-'+('plain' if variant==0 else 'inlaid'))

for broken in (False,True):
    for row in range(5 if not broken else 3):
        count=3 if row%2==0 else 4
        w=2/count
        for i in range(count):
            z=.23+row*.46
            c=cube('Wall_block',(-1+w*(i+.5),0,z),(w-.025,.43,.44),stone,.045)
    if broken:
        for i in range(2):cube('Ragged_cap',(-.70+i*.57,.02,1.51+i*.10),(.53,.4,.28),stone,.07)
    else:cube('Cornice',(0,0,2.36),(2,.54,.14),darkstone,.025)
    finish('wall-'+('broken' if broken else 'full'))

cube('Foot',(0,0,.12),(.82,.82,.24),darkstone)
cube('Plinth',(0,0,.31),(.68,.68,.16),stone)
for j in range(4):cube('Shaft',(0,0,.67+j*.45),(.48,.48,.43),stone,.055)
cube('Collar',(0,0,2.38),(.66,.66,.20),brass,.025)
cube('Capital',(0,0,2.56),(.84,.84,.18),stone)
finish('pillar')

for j in range(5):
    h=(j+1)*.2
    cube('Step',(0,-.8+j*.4,h/2),(2,.4,h),stone,.015)
finish('stairs-rise-1m')
cube('Raised_foundation',(0,0,.47),(2,2,.94),darkstone,.025)
for x in range(2):
    for y in range(2):cube('Platform_flag',(x-.5,y-.5,.95),(.973,.973,.10),stone,.025)
finish('platform-rise-1m')

for side in (-1,1):
    for j in range(5):cube('Pier',(side*1.02,0,.2+j*.4),(.40,.62,.385),stone,.025)
    cube('Pier_base',(side*1.02,0,.1),(.54,.76,.20),darkstone,.02)
for i in range(9):
    t0=i*math.pi/9+.009;t1=(i+1)*math.pi/9-.009
    v=[]
    for y in (-.32,.32):
        for r,t in ((.82,t0),(1.23,t0),(1.23,t1),(.82,t1)):
            v.append((r*math.cos(t),y,2+r*math.sin(t)))
    mesh('Voussoir',v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],stone)
finish('archway')

cube('Banner_foot',(0,0,.12),(.6,.6,.24),stone)
rod('Pole',(0,0,.2),(0,0,2.9),.035,brass)
rod('Crossbar',(-.56,0,2.65),(.56,0,2.65),.028,brass)
v=[]
for j in range(9):
    for i in range(7):
        x=-.5+i/6
        v.append((x,-.035+math.sin(i*.9+j*.3)*.06,2.62-j*.17-(.13 if j==8 and i%2 else 0)))
f=[(j*7+i,j*7+i+1,(j+1)*7+i+1,(j+1)*7+i) for j in range(8) for i in range(6)]
o=mesh('Cloth',v,f,cloth);m=o.modifiers.new('Cloth_thickness','SOLIDIFY');m.thickness=.012
bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
cube('Emblem',(0,-.11,2.01),(.07,.02,.56),brass,.004)
cube('Emblem_cross',(0,-.125,2.12),(.29,.02,.06),brass,.004)
finish('banner')

ringbody('Base',[(0,0,0,.36,.36),(0,0,.16,.32,.32),(0,0,.2,.18,.18)],darkstone)
rod('Stem',(0,0,.16),(0,0,.78),.085,steel)
ringbody('Bowl',[(0,0,.68,.17,.17),(0,0,.92,.40,.40),(0,0,.98,.43,.43)],steel)
ringbody('Coals',[(0,0,.98,.30,.30),(0,0,1.04,.26,.26)],ember)
for i in range(6):
    t=i*math.pi/3
    rod('Cage',(math.cos(t)*.37,math.sin(t)*.37,.91),(math.cos(t)*.31,math.sin(t)*.31,1.25),.022,brass)
finish('brazier')

for i in range(7):
    s=random.uniform(.18,.29)
    o=cube('Rubble',((i%3-1)*.48,(i//3-1)*.43,s/2),(s,s*.8,s),stone,.04)
    o.rotation_euler.z=random.uniform(0,3)
finish('rubble')

def sword(x=0,y=0,z=0,bone=None):
    rod('Grip',(x,y,z),(x,y,z+.25),.035,leather,bone)
    cube('Guard',(x,y,z+.27),(.38,.10,.075),brass,.02,bone)
    mesh('Blade',[(x-.09,y-.025,z+.30),(x+.09,y-.025,z+.30),(x+.075,y-.025,z+1.05),(x,y-.025,z+1.24),
                  (x-.075,y-.025,z+1.05),(x,y-.065,z+.32),(x,y-.04,z+1.05),
                  (x-.09,y+.025,z+.30),(x+.09,y+.025,z+.30),(x+.075,y+.025,z+1.05),(x,y+.025,z+1.24),(x-.075,y+.025,z+1.05)],
         [(0,1,5),(1,2,6,5),(2,3,6),(3,4,6),(4,0,5,6),(7,11,10,9,8),(0,7,8,1),(1,8,9,2),(2,9,10,3),(3,10,11,4),(4,11,7,0)],edge,bone)
sword();finish('vanguard-sword')

# Rigid armored biped prototype: layered geometry provides joint coverage.
bones=[('root',(0,0,0),(0,0,.2),None),('pelvis',(0,0,.90),(0,0,1.1),'root'),
       ('chest',(0,0,1.1),(0,0,1.55),'pelvis'),('head',(0,0,1.55),(0,0,1.9),'chest')]
for side,x in [('L',.20),('R',-.20)]:
    bones += [('thigh.'+side,(x,0,.96),(x,0,.54),'pelvis'),('shin.'+side,(x,0,.54),(x,0,.16),'thigh.'+side),
              ('foot.'+side,(x,0,.16),(x,-.22,.10),'shin.'+side),
              ('upper_arm.'+side,(x*1.9,0,1.48),(x*2.6,0,1.14),'chest'),
              ('forearm.'+side,(x*2.6,0,1.14),(x*2.8,-.02,.86),'upper_arm.'+side),
              ('hand.'+side,(x*2.8,-.02,.86),(x*2.8,-.04,.74),'forearm.'+side)]
arm=bpy.data.armatures.new('Zane_Skeleton');rig=bpy.data.objects.new('Zane_Rig',arm);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,h,t,parent in bones:
    b=arm.edit_bones.new(name);b.head=h;b.tail=t
    if parent:b.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
ringbody('Undercoat',[(0,0,.87,.23,.14),(0,0,1.13,.22,.15),(0,0,1.43,.32,.18),(0,0,1.54,.23,.13)],leather,'chest')
ringbody('Cuirass',[(0,0,1.05,.235,.16),(0,0,1.27,.31,.21),(0,0,1.47,.35,.20),(0,0,1.55,.22,.14)],steel,'chest')
for i in range(3):
    ringbody('Abdominal_lame',[(0,0,1.04+i*.065,.235+i*.014,.17+i*.008),(0,0,1.10+i*.065,.25+i*.014,.18+i*.008)],steel,'chest')
for side in (-1,1):
    for j in range(3):
        o=cube('Chest_lamella',(side*(.11+j*.025),-.191,1.32+j*.055),(.18,.035,.043),steel,.01,'chest')
        o.rotation_euler.y=side*.20
cube('Belt',(0,-.015,1.01),(.48,.34,.09),leather,.015,'pelvis')
cube('Buckle',(0,-.194,1.01),(.13,.035,.10),brass,.01,'pelvis')
ringbody('Helm',[(0,0,1.57,.13,.12),(0,0,1.68,.17,.16),(0,0,1.84,.15,.145),(0,0,1.93,.06,.07)],steel,'head')
cube('Visor',(0,-.146,1.75),(.25,.035,.055),black,.008,'head')
cube('Nose_guard',(0,-.177,1.69),(.035,.04,.16),brass,.007,'head')
ringbody('Gorget',[(0,0,1.49,.22,.18),(0,0,1.61,.145,.13)],clothlight,'chest')
for side,x in [('L',.20),('R',-.20)]:
    ringbody('Tasset',[(x,0,.73,.13,.14),(x,0,.84,.15,.16),(x,0,1.0,.16,.15)],cloth,'thigh.'+side)
    ringbody('Thigh_armor',[(x,0,.55,.105,.115),(x,0,.87,.14,.15)],steel,'thigh.'+side)
    ringbody('Knee',[(x,-.075,.45,.065,.055),(x,-.10,.54,.135,.10),(x,-.075,.64,.075,.06)],steel,'shin.'+side)
    ringbody('Greave',[(x,0,.17,.12,.12),(x,0,.48,.10,.11)],steel,'shin.'+side)
    cube('Boot',(x,-.07,.10),(.26,.43,.20),leather,.045,'foot.'+side)
    for k in range(3):
        cube('Sabatons',(x,-.23+k*.075,.205+k*.025),(.21+k*.012,.10,.065),steel,.018,'foot.'+side)
    sx=x*1.9
    ringbody('Pauldron',[(sx,0,1.36,.16,.18),(sx,0,1.49,.22 if side=='L' else .18,.20),(sx,0,1.60,.14,.16),(sx,0,1.63,.055,.07)],steel,'upper_arm.'+side)
    cube('Pauldron_trim',(sx,-.17,1.49),(.32,.07,.08),brass,.015,'upper_arm.'+side)
    for j in range(2):cube('Shoulder_lames',(sx,0,1.34-j*.06),(.32-j*.02,.31,.075),steel,.02,'upper_arm.'+side)
    rod('Upper_arm',(sx,0,1.42),(x*2.6,0,1.14),.10,leather,'upper_arm.'+side)
    rod('Vambrace',(x*2.6,0,1.14),(x*2.8,-.02,.87),.115,steel,'forearm.'+side,r2=.085)
    cube('Gauntlet',(x*2.8,-.025,.80),(.17,.17,.20),edge,.04,'hand.'+side)
    # Folded split skirt follows thighs; overlapping panels cover articulation.
    v=[]
    for j in range(6):
        t=j/5
        for i in range(7):
            u=i/6
            v.append((x+(u-.5)*(.25+.08*t),.155+.045*t+.025*math.cos(u*math.tau*2),1.06-.43*t+.035*t*math.cos(u*math.tau)))
    f=[(j*7+i,j*7+i+1,(j+1)*7+i+1,(j+1)*7+i) for j in range(5) for i in range(6)]
    o=mesh('Folded_coat_tail',v,f,cloth,'thigh.'+side)
    m=o.modifiers.new('Woven_thickness','SOLIDIFY');m.thickness=.012
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
    # Brass rivets are sparse accents, readable at tactical distance.
    for dx in (-.08,.08):
        rod('Shoulder_rivet',(sx+dx,-.207,1.49),(sx+dx,-.222,1.49),.012,brass,'upper_arm.'+side,n=6)
# Short asymmetric shoulder mantle, modeled folds and uneven hem.
v=[]
for j in range(7):
    t=j/6
    for i in range(9):
        u=i/8
        v.append((-.21+u*(.48+.08*t),.16+.105*t+.025*math.cos(u*math.tau*3),1.54-.49*t+.045*math.sin(u*math.pi)-.04*t*u))
f=[(j*9+i,j*9+i+1,(j+1)*9+i+1,(j+1)*9+i) for j in range(6) for i in range(8)]
o=mesh('Folded_mantle',v,f,cloth,'chest')
m=o.modifiers.new('Mantle_thickness','SOLIDIFY');m.thickness=.014
bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
# Raised central breastplate ridge and narrow worn brass seam.
mesh('Breastplate_ridge',[(-.18,-.19,1.29),(0,-.254,1.24),(.18,-.19,1.29),(.20,-.18,1.47),(0,-.255,1.51),(-.20,-.18,1.47)],[(0,1,4,5),(1,2,3,4)],steel,'chest')
rod('Breastplate_seam',(0,-.258,1.27),(0,-.258,1.49),.009,brass,'chest',n=6)
# Grip at right gauntlet. Blade points forward and slightly down in rest pose.
first=len(parts)
sword(bone='hand.R')
q=Vector((0,-1,-.28)).normalized().to_track_quat('Z','Y')
anchor=Vector((-.56,-.04,.80))
for o in parts[first:]:
    world=o.matrix_world.copy()
    for vert in o.data.vertices:
        vert.co=anchor+q@(world@vert.co-Vector((0,0,.12)))
    o.matrix_world.identity()
char=finish('zane-rig-prototype',rig)
for clip,length in [('idle',60),('walk',30),('attack',30)]:
    rig.animation_data_clear()
    for p in rig.pose.bones:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
    for frame in range(1,length+2):
        t=(frame-1)/length;wave=math.sin(t*math.tau)
        for p in rig.pose.bones:p.rotation_euler=(0,0,0);p.location=(0,0,0)
        if clip=='idle':rig.pose.bones['chest'].rotation_euler.x=.022*wave
        if clip=='walk':
            for side,sign in [('L',1),('R',-1)]:
                rig.pose.bones['thigh.'+side].rotation_euler.x=.36*wave*sign
                rig.pose.bones['shin.'+side].rotation_euler.x=-.28*max(0,-wave*sign)
                rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.24*wave*sign
            rig.pose.bones['pelvis'].location.z=.025*math.sin(t*math.tau*2)
        if clip=='attack':
            swing=math.sin(math.pi*t)**2
            rig.pose.bones['chest'].rotation_euler.z=.35*math.sin(t*math.tau)
            rig.pose.bones['upper_arm.R'].rotation_euler.x=-.85*swing
            rig.pose.bones['upper_arm.R'].rotation_euler.z=-.45*math.sin(t*math.tau)
            rig.pose.bones['forearm.R'].rotation_euler.x=-.35*swing
        for p in rig.pose.bones:
            p.keyframe_insert(data_path='rotation_euler',frame=frame,group=p.name)
            p.keyframe_insert(data_path='location',frame=frame,group=p.name)
    act=rig.animation_data.action;act.name=clip;act.use_fake_user=True
    tr=rig.animation_data.nla_tracks.new();tr.name=clip;tr.strips.new(clip,1,act);tr.mute=True
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)

manifest={'status':'candidate-v02','units':'meters','tile_size':2,'elevation_step':1,'blender_version':bpy.app.version_string,'assets':[],'character_limitations':['rigid armor skinning, no fingers or facial rig','walk is a draft cycle; foot locking not validated','sword is rigidly weighted to right hand; attack timing is provisional','no claim of resemblance to final Zane face'], 'animations':{'idle':{'duration':2,'loop':True},'walk':{'duration':1,'loop':True},'attack':{'duration':1,'loop':False,'impact_time_proposed':.5}}}
for name,objs in ASSETS.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.hide_set(False);o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    if name=='zane-rig-prototype':rig.animation_data.action=None
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True)
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs if o.type=='MESH')
    manifest['assets'].append({'id':name,'file':f'models/{name}.glb','triangles_blender':tris,'dimensions_blender':list(objs[0].dimensions),'origin':'tile center XY / ground Z=0','collision':'not embedded; grid remains authoritative','materials':[m.name for m in objs[0].data.materials]})
    for o in objs:o.hide_render=True;o.hide_set(True)
(ROOT/'asset-manifest.json').write_text(json.dumps(manifest,indent=2))
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)

# Composed actual-mesh courtyard for visual review.
def place(name,loc,angle=0):
    source=ASSETS[name][0];o=source.copy();o.data=source.data;scene.collection.objects.link(o)
    o.name='Showcase_'+name;o.hide_render=False;o.hide_set(False);o.location=loc;o.rotation_euler.z=angle
    return o
for x in range(6):
    for y in range(6):place('floor-inlaid' if (x+y)%7==0 else 'floor-plain',((x-2.5)*2,(y-2.5)*2,0))
for i in range(6):
    if i!=3:place('wall-broken',(-5+i*2,5.8,0))
    if i<4:place('wall-full',(-5.8,-5+i*2,0),math.pi/2)
for loc in [(-5.8,5.8,0),(5.8,5.8,0),(-5.8,-5.8,0)]:place('pillar',loc)
place('archway',(1,5.8,0));place('banner',(-3,4.6,0));place('banner',(4.6,4.6,0))
place('brazier',(-1,4.6,0));place('brazier',(3,4.6,0));place('stairs-rise-1m',(4,-1,0))
place('platform-rise-1m',(4,1,0))
place('rubble',(-4.7,3,0));place('rubble',(4.7,3.1,0))
rig.hide_set(False);rig.hide_render=False;char.hide_set(False);char.hide_render=False
rig.location=(0,-1,0);rig.rotation_euler.z=-.25
scene.world.color=(.10,.10,.10)
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.21,.30,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
def light(name,loc,color,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size
    o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler()
light('Warm_Key',(-5,-6,11),(1,.77,.52),2100,7)
light('Cool_Fill',(7,2,9),(.36,.55,1),1700,6)
for x in (-1,3):
    d=bpy.data.lights.new('Brazier_Light','POINT');d.energy=65;d.color=(1,.25,.04);d.shadow_soft_size=.3
    o=bpy.data.objects.new('Brazier_Light',d);scene.collection.objects.link(o);o.location=(x,4.6,1.5)
camdata=bpy.data.cameras.new('Review_Camera');cam=bpy.data.objects.new('Review_Camera',camdata);scene.collection.objects.link(cam);scene.camera=cam
cam.location=(15,-20,20);cam.rotation_euler=(Vector((0,0,.2))-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=20
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
for image in bpy.data.images:
    if image.source=='FILE':
        image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source/ashvale-master.blend'))
scene.render.filepath=str(ROOT/'review/courtyard.png');bpy.ops.render.render(write_still=True)
# Character-specific review uses the same real geometry, neutral floor omitted.
for o in scene.objects:
    if o.name.startswith('Showcase_'):o.hide_render=True
rig.location=(0,0,0);rig.rotation_euler.z=0
cam.location=(3,-5,2.8);cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();camdata.ortho_scale=2.6
scene.render.resolution_x=800;scene.render.resolution_y=900
scene.render.filepath=str(ROOT/'review/zane-rig.png');bpy.ops.render.render(write_still=True)
print('ASSET_BUILD_DONE',len(ASSETS))




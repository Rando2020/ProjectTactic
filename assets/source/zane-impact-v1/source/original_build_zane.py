"""Original Zane model on immutable ProjectTactic 16-bone/9-clip rig. Headless Blender 4.3.2."""
import bpy,math,os,json,sys,hashlib
from mathutils import Vector,Euler
O=os.path.dirname(os.path.abspath(__file__));S=O+'/source/shared_kael_v2_1.blend'
assert hashlib.sha256(open(O+'/source/shared_kael_v2_1.glb','rb').read()).hexdigest()=='c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117'
bpy.ops.wm.open_mainfile(filepath=S);s=bpy.context.scene;rig=bpy.data.objects['Kael_v2_RIG'];s.frame_set(1)
# Preserve source rig name for exact animation node identity; every visual mesh is new.
keep={rig,*[o for o in bpy.data.objects if o.name in ('Kael_v2_weapon_socket','Kael_v2_cast_socket','Kael_v2_shield_socket')]}
for o in list(bpy.data.objects):
 if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
rig.data.pose_position='REST';parts=[];M={}
def mat(n,c,metal=0,rough=.7):
 m=bpy.data.materials.new('Zane_'+n);m.diffuse_color=(*c,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*c,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough;M[n]=m
for n,c,met in [('Steel',(.24,.265,.275),.65),('SteelShadow',(.11,.135,.15),.55),('Edge',(.42,.43,.40),.65),('Gold',(.43,.30,.13),.6),('Ivory',(.60,.55,.43),0),('IvoryShade',(.40,.36,.28),0),('Slate',(.055,.095,.145),0),('SlateLight',(.105,.15,.21),0),('Mantle',(.047,.045,.043),0),('MantleLight',(.09,.078,.061),0),('Leather',(.11,.058,.030),0),('Dark',(.025,.029,.030),0),('Hair',(.055,.026,.013),0),('HairLight',(.12,.062,.028),0),('Skin',(.49,.30,.19),0),('SkinLight',(.59,.39,.25),0),('Eye',(.025,.037,.04),0),('White',(.72,.70,.60),0),('Stage',(.025,.037,.043),0)]:mat(n,c,met)
def fin(o,n,m,bone=None):
 o.name=n;o.data.materials.append(M[m]);o['zane_original_mesh']=True
 if bone:
  vg=o.vertex_groups.new(name=bone);vg.add(range(len(o.data.vertices)),1,'REPLACE');parts.append(o)
 return o
def mesh(n,vs,fs,m,b='spine'):
 d=bpy.data.meshes.new(n);d.from_pydata(vs,[],fs);d.update();o=bpy.data.objects.new(n,d);bpy.context.collection.objects.link(o);return fin(o,n,m,b)
def ico(n,p,scale,m,b='spine',sub=1):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=p);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return fin(o,n,m,b)
def ell(n,p,scale,m,b='spine',seg=10,rings=6):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,radius=1,location=p);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return fin(o,n,m,b)
def tube(n,a,b,r,m,bone='spine',r2=None,seg=8):
 a,b=Vector(a),Vector(b);d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=seg,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)*.5);o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return fin(o,n,m,bone)
def line(n,coords,r,m,b='spine'):
 return [tube(n,coords[i],coords[i+1],r,m,b,seg=6) for i in range(len(coords)-1)]
def plate(n,pts,m,b='spine',depth=.016):
 vs=list(pts)+[(x,y+depth,z) for x,y,z in pts];N=len(pts);fs=[tuple(range(N-1,-1,-1)),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)];return mesh(n,vs,fs,m,b)
def body(n,rows,m,b='spine',N=10):
 vs=[(math.cos(i*2*math.pi/N)*w,cy+math.sin(i*2*math.pi/N)*d,z) for z,w,d,cy in rows for i in range(N)];fs=[(j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i) for j in range(len(rows)-1) for i in range(N)];fs += [tuple(range(N-1,-1,-1)),tuple((len(rows)-1)*N+i for i in range(N))];return mesh(n,vs,fs,m,b)
# Fitted layered tunic, not Kael's barrel plate. Broad pale/sapphire planes survive reduction.
body('Zane fitted ivory coat',[(.99,.195,.115,0),(1.15,.22,.135,0),(1.38,.265,.15,.01),(1.48,.21,.115,.01)],'Ivory')
body('Zane quilted waist',[(.94,.21,.13,0),(1.08,.21,.13,0)],'Slate','pelvis')
plate('Zane diagonal slate sash',[(-.21,-.14,1.43),(-.255,-.13,1.36),(.12,-.165,1.06),(.205,-.145,1.09)],'Slate',depth=.012)
line('Sash restrained trim',[(-.20,-.153,1.435),(.204,-.16,1.09)],.007,'Gold')
# Offset pectoral plate leaves tunic visible; original four-piece segmented construction.
plate('Right pectoral steel',[(-.22,-.153,1.39),(-.235,-.16,1.22),(-.07,-.186,1.16),(-.025,-.18,1.35)],'Steel')
line('Pectoral forged lip',[(-.22,-.163,1.39),(-.025,-.19,1.35),(-.07,-.196,1.16)],.008,'Gold')
for z in [1.265,1.205]:plate('Lateral plate rib',[(-.23,-.159,z+.025),(-.24,-.156,z-.02),(-.09,-.192,z-.055),(-.075,-.188,z-.012)],'SteelShadow')
# Split short panels: thigh-weighted, no full skirt or long book-bearing coat.
for side,sgn in [('R',-1),('L',1)]:
 x=sgn*.135
 pts=[(x-.095,-.147,1.0),(x-.115,-.198,.73),(x-.065,-.204,.59),(x+.035,-.214,.63),(x+.11,-.15,.93)]
 plate('Zane ivory split panel '+side,pts,'Ivory','thigh.'+side)
 line('Ivory hem '+side,[pts[1],pts[2],pts[3]],.006,'IvoryShade','thigh.'+side)
# Narrow blue front fall, ending above knee so it reads unlike Mira's long coat.
plate('Zane slate front point',[(-.075,-.187,.99),(-.055,-.197,.69),(0,-.207,.63),(.075,-.192,.72),(.10,-.178,.99)],'Slate','thigh.L')
line('Front point trim',[(-.055,-.205,.70),(0,-.215,.63),(.075,-.20,.72)],.006,'Gold','thigh.L')
# Functional belt, scabbard frog and one compact side pouch, without Kael twin pouches.
body('Zane leather belt',[(.99,.224,.151,0),(1.047,.224,.151,0)],'Leather','pelvis')
plate('Zane square brass buckle',[(-.045,-.16,1.047),(-.045,-.16,.99),(.045,-.16,.99),(.045,-.16,1.047)],'Gold','pelvis')
plate('Zane buckle inset',[(-.029,-.179,1.036),(-.029,-.179,1.001),(.029,-.179,1.001),(.029,-.179,1.036)],'Dark','pelvis')
ell('Zane side pouch',(.245,.02,.96),(.055,.075,.08),'Leather','pelvis')
line('Zane crossing hip belt',[(-.22,-.16,1.0),(.17,-.175,.905),(.24,-.10,.97)],.017,'Leather','pelvis')
# Layered anatomical volumes with independent articulated hard surfaces.
for side,sgn in [('R',-1),('L',1)]:
 for bn,ra,rb in [('thigh',.102,.085),('shin',.078,.061),('upper_arm',.092,.077),('forearm',.078,.057)]:
  b=rig.data.bones[bn+'.'+side];tube('Zane '+bn+' dark articulation '+side,b.head_local,b.tail_local,ra,'Dark',bn+'.'+side,rb)
 # Thigh leather is deliberately slimmer than Kael armor.
 b=rig.data.bones['thigh.'+side];tube('Zane fitted trousers '+side,b.head_local.lerp(b.tail_local,.1),b.head_local.lerp(b.tail_local,.88),.096,'Leather','thigh.'+side,.084)
 x=rig.data.bones['shin.'+side].head_local.x
 plate('Zane tapered greave '+side,[(x-.08,-.082,.48),(x-.058,-.095,.205),(x,-.125,.17),(x+.064,-.092,.205),(x+.083,-.08,.49),(x,-.13,.535)],'Steel','shin.'+side)
 line('Zane greave center facet '+side,[(x,-.137,.49),(x,-.132,.22)],.007,'Edge','shin.'+side)
 plate('Zane petal poleyn '+side,[(x-.087,-.095,.605),(x-.08,-.13,.53),(x,-.16,.505),(x+.082,-.13,.53),(x+.087,-.095,.605),(x,-.147,.64)],'Steel','shin.'+side)
 line('Zane poleyn rim '+side,[(x-.08,-.14,.53),(x,-.169,.505),(x+.082,-.14,.53)],.006,'Gold','shin.'+side)
 fx=rig.data.bones['foot.'+side].head_local.x
 # Compact convex sole sits within source foot envelope (whose defeat pitch is frozen).
 ell('Zane fitted boot '+side,(fx,-.057,.091),(.09,.163,.090),'Leather','foot.'+side)
 ell('Zane steel toe '+side,(fx,-.15,.085),(.091,.103,.056),'Steel','foot.'+side)
 for yy,zz in [(-.17,.128),(-.10,.157)]:line('Zane toe articulation '+side,[(fx-.07,yy,zz-.018),(fx,yy-.02,zz),(fx+.07,yy,zz-.018)],.006,'Gold','foot.'+side)
 # Smaller swept shell, geometric tessellation differs from Kael's horizontal domes.
 sx=rig.data.bones['upper_arm.'+side].head_local.x
 pts=[(sx-sgn*.10,-.12,1.48),(sx+sgn*.04,-.155,1.53),(sx+sgn*.15,-.12,1.46),(sx+sgn*.16,-.105,1.34),(sx+sgn*.07,-.15,1.30),(sx-sgn*.08,-.13,1.35)]
 plate('Zane swept shoulder '+side,pts,'Steel','upper_arm.'+side,.12)
 line('Zane shoulder lip '+side,[pts[2],pts[3],pts[4]],.009,'Gold','upper_arm.'+side)
 for frac in [.37,.56]:
  b=rig.data.bones['upper_arm.'+side];p=b.head_local.lerp(b.tail_local,frac);ell('Zane upper arm lame '+side,p,(.105,.10,.072),'Steel','upper_arm.'+side)
 b=rig.data.bones['forearm.'+side];a=b.head_local.lerp(b.tail_local,.18);c=b.head_local.lerp(b.tail_local,.86);tube('Zane vambrace '+side,a,c,.088,'Steel','forearm.'+side,.062)
 tube('Zane wrist edging '+side,c,c+(c-a).normalized()*.025,.069,'Gold','forearm.'+side,.067)
 hand=rig.data.bones['hand.'+side].head_local
 ell('Zane glove '+side,hand+Vector((0,0,-.025)),(.060,.057,.086),'Leather','hand.'+side)
 ell('Zane knuckle facets '+side,hand+Vector((0,-.044,-.015)),(.058,.022,.045),'Steel','hand.'+side)
# Short asymmetric draped mantle: triangulated folded surface, visually distinct from both companions.
vs=[(-.23,.10,1.45),(-.34,.13,1.33),(-.37,.18,1.08),(-.35,.22,.80),(-.21,.25,.73),(-.10,.26,.85),(.0,.25,.78),(.12,.25,.85),(.18,.19,1.03),(.25,.13,1.38),(.18,.09,1.47),(-.05,.22,1.42),(-.16,.27,1.15),(.06,.27,1.15)]
fs=[(0,1,12,11),(1,2,3,12),(3,4,5,12),(5,6,13,12),(6,7,8,13),(8,9,10,13),(10,11,13),(11,12,13)]
vs=[(x,y,.98+(z-.73)*.5 if z<1.05 else z) for x,y,z in vs]
mantle=mesh('Zane folded short charcoal mantle',vs,fs,'Mantle','spine');mantle.data.materials.append(M['MantleLight'])
for i,p in enumerate(mantle.data.polygons):p.material_index=1 if i in [2,6] else 0
# Waist-length mantle follows torso; no cloth simulation or added garment bones.
for n,coords in [('mantle edge R',[vs[0],vs[1],vs[2]]),('mantle edge L',[vs[10],vs[9],vs[8]])]:line('Zane '+n,coords,.006,'MantleLight')
# Draped scarf collar. No fur and no green cloth.
for z,w in [(1.485,.20),(1.445,.22),(1.407,.205)]:
 line('Zane charcoal cowl',[(-w,-.06,z+.014),(-.13,-.145,z-.02),(0,-.185,z-.04),(.15,-.145,z+.005),(.21,-.045,z+.03)],.027,'Mantle')
ell('Zane mantle fastening',(.196,-.13,1.407),(.026,.015,.033),'Gold')
# Grounded face, close stubble, irregular swept brown locks; not Kael's beard/fur mass.
ell('Zane face',(0,-.012,1.675),(.119,.104,.169),'Skin','head',12,8)
ell('Zane jaw',(0,-.023,1.568),(.096,.078,.065),'Skin','head')
for x in [-.116,.116]:ell('Zane ear',(x,.0,1.675),(.022,.022,.039),'Skin','head')
ico('Zane nose',(0,-.118,1.663),(.023,.028,.039),'SkinLight','head',2)
for x in [-.046,.046]:
 ell('Zane eye socket',(x,-.105,1.705),(.031,.011,.020),'SkinLight','head');ell('Zane eye',(x,-.118,1.706),(.019,.006,.009),'White','head');ell('Zane iris',(x,-.124,1.706),(.007,.004,.008),'Eye','head')
 line('Zane brow',[(x-.023,-.119,1.727),(x+.022,-.121,1.723)],.009,'Hair','head')
for x in [-.073,.073]:ico('Zane jaw stubble',(x,-.052,1.588),(.031,.037,.045),'Hair','head',2)
ico('Zane short chin stubble',(0,-.062,1.553),(.068,.044,.032),'Hair','head',2)
line('Zane mouth',[(-.029,-.111,1.605),(.025,-.114,1.604)],.004,'Hair','head')
ell('Zane hair foundation',(0,.012,1.794),(.128,.108,.068),'Hair','head',12,6)
# Swept facets with asymmetric side part and readable pointed hair silhouette.
for i,(x,y,z,lean) in enumerate([(-.105,.015,1.786,-.035),(-.075,-.015,1.822,-.025),(-.038,-.025,1.839,-.025),(0,-.012,1.845,-.03),(.042,.0,1.838,-.04),(.083,.023,1.814,-.04),(-.07,.071,1.80,-.025),(.0,.086,1.81,-.02),(.07,.082,1.79,-.025)]):
 ico('Zane swept hair lock', (x,y,z),(.040,.069,.032),'HairLight' if i in [1,2,4] else 'Hair','head',1)
 tip=(x+lean,y-.058,z-.030);tube('Zane tapered fringe',tip,(x+.015,y+.016,z+.015),.008,'Hair','head',.034,5)
for x in [-.113,.113]:ico('Zane sideburn',(x,.015,1.737),(.020,.065,.071),'Hair','head',1)
ell('Zane nape',(0,.065,1.735),(.114,.058,.092),'Hair','head')
# Join independently authored weighted pieces into one portable skin.
bpy.ops.object.select_all(action='DESELECT')
for p in parts:p.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();skin=bpy.context.object;skin.name='Zane_v2_SKIN';bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);skin.parent=rig;skin.location=(0,0,0);m=skin.modifiers.new('Frozen shared 16-bone rig','ARMATURE');m.object=rig
skin['provenance']='Original procedural Zane geometry and rigid/segmented weights; no Kael visual mesh retained.'
# Independent Godot transition probes exposed only the two UV boot bottom poles.
# Relieve those two poles by 7.6 mm; do not move rig, bones, sockets or entire boots.
foot_groups={skin.vertex_groups[n].index for n in ['foot.R','foot.L']}
relieved=[]
for v in skin.data.vertices:
 if v.co.z<.002 and any(g.group in foot_groups for g in v.groups):
  v.co.z+=.0076;relieved.append(v.index)
skin['transition_safe_sole_poles']=relieved

# Sword equipment is a new fixed attachment; never rotate the legacy socket itself.
wp=bpy.data.objects['Kael_v2_weapon_socket'];eq=[]
def gear(o):eq.append(o);return o
Q=Euler((math.radians(-45),0,math.radians(115))).to_matrix();C=Vector((-.045,-.055,0))
def P(v):return C+Q@Vector(v)
gear(tube('Zane leather sword grip',P((0,-.10,0)),P((0,.10,0)),.026,'Leather',None,seg=10))
for yy in [-.06,-.02,.02,.06]:gear(tube('Zane grip wrap',P((0,yy,0)),P((0,yy+.01,0)),.027,'Gold',None,seg=8))
gear(ico('Zane octagonal pommel',P((0,-.125,0)),(.043,.043,.043),'Gold',None,1))
gear(tube('Zane straight crossguard',P((-.145,.12,0)),P((.145,.12,0)),.023,'Gold',None,seg=8))
for xx in [-.145,.145]:gear(ico('Zane guard quillon',P((xx,.12,0)),(.026,.026,.026),'Gold',None,1))
# Diamond cross-section blade: broad bright bevels, dark fuller; compact 0.69 m blade.
rows=[(.145,.052),(.21,.058),(.70,.035),(.835,0)]
bv=[]
for yy,w in rows:
 for x,z in [(-w,0),(0,-.018),(w,0),(0,.018)]:bv.append(P((x,yy,z)))
bf=[]
for j in range(3):
 for k in range(4):bf.append((j*4+k,j*4+(k+1)%4,(j+1)*4+(k+1)%4,(j+1)*4+k))
bf.append((3,2,1,0));blade=gear(mesh('Zane original straight steel sword',bv,bf,'Edge',None));blade.data.materials.append(M['Steel'])
for i,p in enumerate(blade.data.polygons):p.material_index=i%2
gear(tube('Zane blade fuller',P((0,.23,-.019)),P((0,.70,-.019)),.004,'SteelShadow',None,seg=6))
for o in eq:o.parent=wp;o['zane_equipment']=True
rig.data.pose_position='POSE';s.frame_set(1);bpy.context.view_layer.update()
# Remove unused source/join-temporary datablocks; the model contains no hidden Kael visual mesh.
for collection in (bpy.data.meshes,bpy.data.materials,bpy.data.cameras,bpy.data.lights):
 for block in list(collection):
  if block.users==0 and not block.name.startswith('Zane_'):collection.remove(block)
rig['presentation_identity']='Zane original shared-rig prototype'
# Only the original rig, new skin/equipment and unchanged sockets are exported.
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in rig.children_recursive:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=O+'/zane_v2.glb',export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_anim_slide_to_zero=True,export_force_sampling=True,export_optimize_animation_size=False)
# Consistent neutral presentation, original untextured low-poly world render.
bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=1.3,depth=.06,location=(0,0,-.03));fin(bpy.context.object,'Zane review platform','Stage')
for name,loc,power,color,size in [('Cool key',(-3,-4,5),450,(.78,.87,1),4),('Warm rim',(2,2,3),650,(1,.72,.43),3),('Fill',(3,-2,2),110,(.7,.82,1),3)]:
 d=bpy.data.lights.new(name,'AREA');o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=loc;d.energy=power;d.color=color;d.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Zane tactics ortho');cam=bpy.data.objects.new('Zane tactics ortho',d);bpy.context.collection.objects.link(cam);cam.location=(3.2,-6,3.6);cam.rotation_euler=(Vector((0,0,.95))-cam.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=3.7;s.camera=cam
s.world.color=(.05,.05,.05);s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.use_denoising=False;s.cycles.seed=0;s.cycles.use_animated_seed=False;s.render.resolution_x=s.render.resolution_y=640;s.render.resolution_percentage=100;s.render.fps=24;s.view_settings.view_transform='AgX';s.render.image_settings.file_format='PNG';s.render.film_transparent=False
s['asset_status']='Zane v2 original shared-rig prototype, NOT finished production art or live-game integration.'
bpy.ops.wm.save_as_mainfile(filepath=O+'/zane_v2.blend')
if '--no-render' not in sys.argv:
 for label,f in [('idle',1),('slash_contact',58),('cast_contact',196),('defeat_hold',374)]:
  s.frame_set(f);s.render.filepath=O+'/renders/'+label+'_clean.png';bpy.ops.render.render(write_still=True)
print('ZANE_BUILD_COMPLETE')

#!/usr/bin/env python3
"""Zane painterly v1: original sculpted low-poly geometry on immutable impact rig.

blender -b -t 2 --python assets/source/zane-painterly-v1/build_zane.py
The art source stays segmented/editable. Export joins a duplicate skin, leaving
named anatomical/clothing construction objects in a hidden source collection.
"""
import bpy, bmesh, math, json, hashlib, argparse, sys
from pathlib import Path
from mathutils import Vector, Euler
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[2]
BASE=ROOT/'assets/source/zane-impact-v1/zane_impact_v1.blend'
parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=ROOT/'godot/assets/3d/characters/zane_painterly_v1');parser.add_argument('--source-output',type=Path,default=HERE/'zane_painterly_v1.blend')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []);OUT=args.output;OUT.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='eba9f0cce135345fe9ce4c7b9197b63a97f999947c6346f7a6212e735a7df6d9','Frozen impact source Blend changed'
bpy.ops.wm.open_mainfile(filepath=str(BASE)); scene=bpy.context.scene; scene.frame_set(1)
rig=bpy.data.objects['Kael_v2_RIG']; rig.data.pose_position='REST'
SOCKETS=['Kael_v2_cast_socket','Kael_v2_weapon_socket','Kael_v2_shield_socket']
keep={rig,*[bpy.data.objects[n] for n in SOCKETS]}
for o in list(bpy.data.objects):
 if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.object.select_all(action='DESELECT')
for m in list(bpy.data.materials):
 if m.users==0:bpy.data.materials.remove(m)
parts=[]; gear=[]; materials={}; tile={}; names=['navy','cream','steel','leather','skin','hair','brass','dark']
tex=bpy.data.images.load(str(HERE/'textures/zane_painterly_atlas.png'));tex.pack()
groups={}
for i,n in enumerate(names):
 group='metal' if n in ('steel','brass') else 'fabric' if n in ('navy','cream','dark') else 'organic'
 if group not in groups:
  m=bpy.data.materials.new('ZanePaint_'+group);m.use_nodes=True;m.diffuse_color=(.3,.3,.3,1)
  nt=m.node_tree;bs=nt.nodes.get('Principled BSDF');bs.inputs['Metallic'].default_value=.22 if group=='metal' else 0
  bs.inputs['Roughness'].default_value={'metal':.66,'fabric':.88,'organic':.82}[group]
  im=nt.nodes.new('ShaderNodeTexImage');im.image=tex;im.interpolation='Linear';nt.links.new(im.outputs['Color'],bs.inputs['Base Color'])
  groups[group]=m
 materials[n]=groups[group];tile[n]=i

def finish(o,n,m,b='spine',tone=1):
 o.name=n;bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.materials.clear();o.data.materials.append(materials[m]);o['authoring_part']=n
 # Atlas tile UVs: object-local dominant-plane projection. Polygon islands share
 # the same tile deliberately (trim-sheet mapping), without accidental tile bleed.
 bpy.context.view_layer.objects.active=o;o.select_set(True)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 # Primitive operators create UVMap; remove it so exporters cannot pick it.
 for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
 uv=o.data.uv_layers.new(name='PaintAtlas');uv.active_render=True
 coords=[v.co.copy() for v in o.data.vertices]
 lo=[min(v[k] for v in coords) for k in range(3)];hi=[max(v[k] for v in coords) for k in range(3)]
 idx=tile[m];tx=idx%4;ty=idx//4
 o.data.color_attributes.new(name='PaintPlanes',type='BYTE_COLOR',domain='CORNER')
 # Adding CustomData layers invalidates prior RNA layer handles in Blender 4.3.
 uv=o.data.uv_layers['PaintAtlas'];col=o.data.color_attributes['PaintPlanes']
 for p in o.data.polygons:
  normal=p.normal;major=max(range(3),key=lambda a:abs(normal[a]));axes=[a for a in range(3) if a!=major]
  # Fixed directional value planes (not random noise); geometry defines the shape.
  light=.86+.11*max(0,normal.z)+.07*max(0,-normal.y)+.025*normal.x
  for li in p.loop_indices:
   v=coords[o.data.loops[li].vertex_index]
   u=(v[axes[0]]-lo[axes[0]])/max(.0001,hi[axes[0]]-lo[axes[0]])
   vv=(v[axes[1]]-lo[axes[1]])/max(.0001,hi[axes[1]]-lo[axes[1]])
   uv.data[li].uv=((tx+.06+.88*u)/4,1-(ty+.025+.95*vv)/2)
   col.data[li].color=(min(1,light*tone),min(1,light*tone),min(1,light*tone),1)
 if b:
  vg=o.vertex_groups.new(name=b);vg.add(range(len(o.data.vertices)),1,'REPLACE');parts.append(o)
 else:gear.append(o)
 o.select_set(False);return o

def mesh(n,vs,fs,m,b='spine',tone=1):
 d=bpy.data.meshes.new(n);d.from_pydata(vs,[],fs);d.update();o=bpy.data.objects.new(n,d);bpy.context.collection.objects.link(o);return finish(o,n,m,b,tone)

def rings(n,rows,m,b='spine',N=12,tone=1):
 # rows: center, radial x/y radii. Elliptical forms with flat, sculpted planes.
 vs=[]
 for p,rx,ry in rows:
  for i in range(N):
   a=2*math.pi*i/N;vs.append((p[0]+rx*math.cos(a),p[1]+ry*math.sin(a),p[2]))
 fs=[(j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i) for j in range(len(rows)-1) for i in range(N)]
 fs += [tuple(range(N-1,-1,-1)),tuple((len(rows)-1)*N+i for i in range(N))]
 return mesh(n,vs,fs,m,b,tone)

def ell(n,p,sc,m,b='spine',seg=12,ring=7,tone=1):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=ring,radius=1,location=p);o=bpy.context.object;o.scale=sc;return finish(o,n,m,b,tone)

def tube(n,a,b,r,m,bone='spine',r2=None,seg=8,tone=1):
 a,b=Vector(a),Vector(b);d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=seg,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return finish(o,n,m,bone,tone)

def path(n,pts,r,m,b='spine',tone=1):
 return [tube(n+' %02d'%i,pts[i],pts[i+1],r,m,b,seg=6,tone=tone) for i in range(len(pts)-1)]

def plate(n,pts,m,b='spine',depth=.012,bulge=.012,tone=1,trim=False):
 # Convex/folded sculpted panel: bevel perimeter + raised directional fan, not a box.
 p=[Vector(v) for v in pts];c=sum(p,Vector())/len(p);N=len(p)
 inn=[v.lerp(c,.10)+Vector((0,-bulge*.30,0)) for v in p];center=c+Vector((0,-bulge,0))
 vs=p+inn+[center]+[v+Vector((0,depth,0)) for v in p]
 fs=[]
 for i in range(N):
  j=(i+1)%N;fs.extend([(i,j,N+j,N+i),(N+i,N+j,2*N),(i,2*N+1+i,2*N+1+j,j)])
 fs.append(tuple(range(3*N,2*N,-1)))
 o=mesh(n,vs,fs,m,b,tone)
 if trim:path(n+' brass piping',pts+[pts[0]],.0045,'brass',b)
 return o

def ribbon(n,pts,width,m,b='spine',depth=.012):
 # width in XZ plane. Front/back crossing straps bend with torso planes.
 ps=[Vector(p) for p in pts];vs=[]
 for i,p in enumerate(ps):
  tangent=ps[min(i+1,len(ps)-1)]-ps[max(0,i-1)];side=Vector((-tangent.z,0,tangent.x)).normalized()*width/2
  vs.extend([p-side,p+side])
 fs=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(ps)-1)]
 o=mesh(n,vs,fs,m,b);mod=o.modifiers.new('Real strap thickness','SOLIDIFY');mod.thickness=depth
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name);return o

def limb(n,bn,profile,m):
 b=rig.data.bones[bn];a=b.head_local;c=b.tail_local;d=(c-a).normalized();u=Vector((0,-1,0));v=d.cross(u).normalized();vs=[];N=12
 for t,ru,rv in profile:
  p=a.lerp(c,t)
  for i in range(N):
   an=2*math.pi*i/N;vs.append(p+u*math.cos(an)*ru+v*math.sin(an)*rv)
 fs=[(j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i) for j in range(len(profile)-1) for i in range(N)];fs += [tuple(range(N-1,-1,-1)),tuple((len(profile)-1)*N+i for i in range(N))]
 return mesh(n,vs,fs,m,bn)

# Fitted coat body and lighter flanks: substantial jacket construction.
rings('Coat | sculpted navy torso', [((0,0,.995),.197,.121),((0,0,1.12),.196,.125),((0,0,1.29),.241,.147),((0,.012,1.43),.247,.131),((0,.012,1.48),.18,.112)],'navy',N=16)
rings('Waist underlayer', [((0,0,.94),.192,.113),((0,0,1.08),.202,.121)],'dark','pelvis')
for side,s in [('R',-1),('L',1)]:
 plate('Cream fitted flank '+side,[(s*.133,-.126,1.42),(s*.206,-.09,1.43),(s*.234,-.082,1.28),(s*.196,-.112,1.105),(s*.123,-.137,1.13)],'cream',bulge=.016)
 path('Flank brass binding '+side,[(s*.133,-.140,1.42),(s*.124,-.157,1.30),(s*.123,-.151,1.13)],.005,'brass')
 # Long split coat leaves thighs and knee mechanics readable. Outer/back panels
 # follow thigh bone; two rows avoid a rigid broad rectangle silhouette.
 pts=[(s*.031,-.148,1.015),(s*.197,-.127,1.005),(s*.255,-.123,.87),(s*.352,-.116,.61),(s*.318,-.155,.50 if side=='L' else .535),(s*.176,-.207,.555),(s*.075,-.208,.77)]
 plate('Navy long front coat tail '+side,pts,'navy','thigh.'+side,depth=.015,bulge=.020,trim=True)
 plate('Cream coat facing '+side,[(s*.025,-.151,1.002),(s*.082,-.174,.87),(s*.159,-.198,.635),(s*.071,-.205,.526),(s*.043,-.211,.572),(s*.018,-.188,.72)],'cream','thigh.'+side,depth=.012,bulge=.009)
 # Crease is a narrow raised navy ribbon, intentionally broad shading plane.
 ribbon('Tail sewn fold '+side,[(s*.18,-.149,.94),(s*.204,-.192,.76),(s*.272,-.186,.56)],.019,'navy','thigh.'+side,.006)
 back=[(s*.018,.133,.998),(s*.197,.110,.995),(s*.273,.149,.785),(s*.296,.198,.50),(s*.156,.241,.435),(s*.032,.194,.59)]
 # Reverse back face so its convex raised panel faces outward.
 back=[(x,-y,z) for x,y,z in back]
 o=plate('Navy rear split coat tail '+side,back,'navy','thigh.'+side,.014,.018,trim=False)
 for v in o.data.vertices:v.co.y=-v.co.y
 path('Rear hem brass '+side,[(s*.296,.201,.50),(s*.156,.247,.435),(s*.032,.20,.59)],.0045,'brass','thigh.'+side)
 plate('Cream rear lining visible '+side,[(s*.04,.182,.94),(s*.09,.212,.72),(s*.151,.249,.45),(s*.087,.234,.51),(s*.038,.205,.61)],'cream','thigh.'+side,.008,.003)
# Crossing harness: diagonal leather mass and metallic fastening rather than armor slab.
ribbon('Cross-body broad sword harness',[(-.183,-.135,1.457),(-.13,-.168,1.35),(.01,-.174,1.23),(.177,-.15,1.082)],.036,'leather',depth=.013)
ribbon('Cross-body return harness',[(.173,-.131,1.448),(.10,-.167,1.30),(-.02,-.171,1.15),(-.167,-.148,1.07)],.027,'leather',depth=.011)
ribbon('Harness behind back',[(-.18,.13,1.44),(-.08,.163,1.29),(.15,.145,1.08)],.037,'leather')
# diamond buckle over diagonal strap
plate('Harness brass clasp',[(-.112,-.189,1.337),(-.136,-.19,1.31),(-.109,-.19,1.286),(-.084,-.19,1.314)],'brass',depth=.009,bulge=.002)
plate('Harness clasp leather inset',[(-.111,-.20,1.325),(-.122,-.20,1.311),(-.109,-.20,1.299),(-.097,-.20,1.313)],'leather',depth=.003,bulge=.002)
# Waist belt layers and shaped iconic star/hexagonal brass buckle.
rings('Thick saddle leather belt',[((0,0,.986),.218,.15),((0,0,1.052),.215,.150)],'leather','pelvis',16)
for z in [.991,1.046]:
 path('Belt stitched edge',[(math.cos(a)*.219,math.sin(a)*.153,z) for a in [math.pi+i*math.pi/12 for i in range(13)]],.002,'brass','pelvis',.75)
plate('Hero angular belt buckle',[(-.053,-.166,1.025),(-.031,-.168,1.061),(.029,-.168,1.061),(.055,-.166,1.022),(.028,-.17,.982),(-.03,-.17,.982)],'brass','pelvis',.013,.01)
plate('Buckle inset sculpted steel',[(-.031,-.188,1.025),(0,-.197,1.049),(.031,-.188,1.025),(0,-.197,.998)],'steel','pelvis',.006,.01,.78)
for s in [-1,1]:
 ribbon('Angular hip strap '+str(s),[(s*.08,-.164,.983),(s*.19,-.172,.927),(s*.257,-.125,.889)],.032,'leather','pelvis')
 for x,z in [(s*.12,1.021),(s*.18,1.021)]:ell('Belt rivet',(x,-.15,z),(.005,.004,.005),'brass','pelvis',8,4)
plate('Sword frog leather', [(-.218,-.08,1.01),(-.268,-.085,.984),(-.29,-.079,.883),(-.232,-.11,.907)],'leather','pelvis',.025,.005)

# Legs and boots. Existing bone positions/contact envelope are not changed.
for side,s in [('R',-1),('L',1)]:
 thigh='thigh.'+side;shin='shin.'+side;foot='foot.'+side
 limb('Trouser tailored upper '+side,thigh,[(0,.095,.096),(.18,.109,.105),(.48,.105,.096),(.75,.087,.079),(1.03,.079,.077)],'dark')
 limb('Trouser knee folds '+side,shin,[(-.03,.075,.077),(.14,.079,.079),(.38,.066,.065),(.82,.056,.057),(1,.056,.055)],'dark')
 x=s*.216
 # Raised diamond poleyn, bevelled side wings and a separate lower lame.
 plate('Forged knee cap '+side,[(x-.086,-.086,.607),(x-.085,-.121,.554),(x,-.16,.505),(x+.085,-.121,.554),(x+.086,-.086,.607),(x,-.13,.647)],'steel',shin,.026,.028)
 path('Knee rolled brass edge '+side,[(x-.084,-.126,.555),(x,-.166,.501),(x+.084,-.126,.555)],.005,'brass',shin)
 plate('Knee overlapping lame '+side,[(x-.073,-.097,.532),(x-.067,-.113,.487),(x,-.133,.466),(x+.064,-.11,.49),(x+.073,-.097,.532)],'steel',shin,.015,.012,.87)
 # Full dimensional leather shin, inset forged long ridge.
 limb('Leather tall boot shaft '+side,shin,[(.21,.074,.076),(.40,.073,.073),(.79,.061,.061),(1.02,.062,.061)],'leather')
 plate('Long tapered steel greave '+side,[(x-.063,-.093,.482),(x-.048,-.105,.272),(s*.248-.043,-.096,.18),(s*.248,-.132,.17),(s*.248+.043,-.096,.18),(x+.052,-.102,.276),(x+.065,-.093,.482),(x,-.133,.50)],'steel',shin,.016,.015,.85)
 path('Greave sculpted center ridge '+side,[(x,-.154,.476),(s*.242,-.151,.221)],.004,'steel',shin,1.07)
 for t in [.13,.32]:
  bn=rig.data.bones[shin];p=bn.head_local.lerp(bn.tail_local,t)
  tube('Knee leather retaining strap '+side,p+Vector((0,0,.012)),p-Vector((0,0,.012)),.083 if t==.13 else .078,'leather',shin,seg=12)
 fx=s*.2484
 # Anatomically shaped boot rings follow the sole envelope; no cuboid footwear.
 vs=[];ys=[.095,.055,-.055,-.155,-.22]; widths=[.064,.079,.087,.083,.052];tops=[.087,.126,.157,.104,.063]
 for yy,w,h,sole in zip(ys,widths,tops,[.020,.014,.008,.016,.020]):
  vs.extend([(fx-w,yy,sole),(fx-w,yy,h*.72),(fx-w*.55,yy,h),(fx+w*.55,yy,h),(fx+w,yy,h*.72),(fx+w,yy,sole)])
 fs=[(j*6+i,j*6+(i+1)%6,(j+1)*6+(i+1)%6,(j+1)*6+i) for j in range(4) for i in range(6)];fs += [(5,4,3,2,1,0),tuple(24+i for i in range(6))]
 mesh('Sculpted leather boot '+side,vs,fs,'leather',foot)
 # Sole edges held inside old boot radius; clear floor in immutable motions.
 for yy,w in zip(ys,widths):pass
 plate('Boot broad toe steel '+side,[(fx-.077,-.154,.084),(fx-.049,-.219,.064),(fx+.049,-.219,.064),(fx+.077,-.154,.084),(fx+.052,-.126,.119),(fx-.052,-.126,.119)],'steel',foot,.011,.009,.90)
 for yy,z,w in [(-.07,.16,.085),(.023,.143,.078)]:
  path('Boot leather cross strap '+side,[(fx-w,yy,z-.04),(fx-w*.5,yy-.01,z),(fx+w*.5,yy-.01,z),(fx+w,yy,z-.04)],.010,'leather',foot)
  plate('Boot buckle '+side,[(fx+s*w*.78,yy-.017,z-.025),(fx+s*w*.78,yy-.018,z-.004),(fx+s*w*.42,yy-.018,z-.004),(fx+s*w*.42,yy-.017,z-.025)],'brass',foot,.005,.001)
 # Sculpted sleeves, with directed gathered fabric folds rather than spheres.
 upper='upper_arm.'+side;fore='forearm.'+side;hand='hand.'+side
 limb('Gathered navy undersleeve '+side,upper,[(0,.084,.09),(.18,.098,.095),(.43,.09,.084),(.67,.083,.08),(.82,.087,.083),(1.03,.072,.074)],'dark')
 limb('Forearm leather underwrap '+side,fore,[(0,.07,.071),(.18,.08,.075),(.4,.072,.071),(.72,.064,.059),(1,.053,.051)],'leather')
 for frac in [.48,.72]:
  bn=rig.data.bones[upper];p=bn.head_local.lerp(bn.tail_local,frac)
  path('Sleeve diagonal sculpted fold '+side,[(p.x-s*.064,p.y-.049,p.z+.034),(p.x,p.y-.092,p.z+.005),(p.x+s*.065,p.y-.045,p.z-.024)],.011,'dark',upper,.89)
 # Shoulder shell wraps front/top/back with sloped multi-plane silhouette.
 sx=s*.27
 cross=[[(sx-s*.075,-.103,1.47),(sx+s*.02,-.13,1.514),(sx+s*.138,-.078,1.455),(sx+s*.132,-.118,1.353),(sx+s*.035,-.150,1.316),(sx-s*.07,-.117,1.37)],
        [(sx-s*.075,.080,1.47),(sx+s*.025,.108,1.52),(sx+s*.132,.091,1.459),(sx+s*.127,.075,1.363),(sx+s*.033,.105,1.326),(sx-s*.07,.086,1.37)]]
 front=plate('Pauldron sculpted front '+side,cross[0],'steel',upper,.025,.026)
 back=[(x,-y,z) for x,y,z in cross[1]];o=plate('Pauldron sculpted rear '+side,back,'steel',upper,.018,.020,.93)
 for v in o.data.vertices:v.co.y=-v.co.y
 mid=[tuple((Vector(f)+Vector(b))*.5+Vector((0,0,.015 if i<3 else 0))) for i,(f,b) in enumerate(zip(*cross))]
 mesh('Pauldron curved closed crown '+side,cross[0]+mid+cross[1],[(row*6+i,row*6+(i+1)%6,(row+1)*6+(i+1)%6,(row+1)*6+i) for row in range(2) for i in range(6)],'steel',upper,tone=.79)
 path('Pauldron brass lower bevel '+side,[cross[0][2],cross[0][3],cross[0][4],cross[0][5]],.006,'brass',upper)
 # Two nested armor lames with separate gap/readable thickness.
 for j in range(2):
  z=1.335-j*.071;cx=s*(.355+j*.035)
  pts=[(cx-s*.070,-.09,z+.04),(cx+s*.052,-.087,z+.018),(cx+s*.108,-.076,z-.064),(cx+s*.017,-.128,z-.040),(cx-s*.064,-.109,z-.012)]
  plate('Articulated shoulder lame %s %s'%(side,j),pts,'steel',upper,.038,.016,.93-j*.07)
  path('Lame brass edge '+side,[pts[2],pts[3],pts[4]],.004,'brass',upper)
 # Long faceted vambrace follows rest arm direction; keeps exposed wrist and elbow.
 bn=rig.data.bones[fore];a=bn.head_local.lerp(bn.tail_local,.16);c=bn.head_local.lerp(bn.tail_local,.84)
 plate('Forearm forged shield '+side,[(a.x-s*.07,a.y-.051,a.z+.009),(a.x+s*.075,a.y-.044,a.z+.019),(c.x+s*.055,c.y-.054,c.z-.009),(c.x,c.y-.084,c.z-.043),(c.x-s*.056,c.y-.058,c.z-.014)],'steel',fore,.036,.021)
 path('Vambrace center crest '+side,[(a.x,a.y-.096,a.z),(c.x,c.y-.104,c.z-.03)],.005,'steel',fore,1.08)
 for t in [.17,.82]:
  p=bn.head_local.lerp(bn.tail_local,t);d=(bn.tail_local-bn.head_local).normalized()
  tube('Vambrace leather cuff '+side,p-d*.012,p+d*.012,.081 if t<.2 else .063,'leather',fore,seg=12)
 # Palm/fingers visibly separated but unarticulated, preserving one hand bone.
 h=rig.data.bones[hand].head_local
 ell('Leather glove palm '+side,h+Vector((0,0,-.037)),(.052,.043,.067),'leather',hand,12,6)
 for j in range(4):
  dx=(j-1.5)*.023;z=-.083+abs(j-1.5)*.005
  p=h+Vector((dx,-.013,z));q=h+Vector((dx,-.041,z-.027))
  tube('Glove curled finger '+side,p,q,.013,'leather',hand,.011,8)
  ell('Glove knuckle '+side,h+Vector((dx,-.044,-.047)),(.013,.006,.017),'leather',hand,8,4,.86)
 ell('Glove opposing thumb '+side,h+Vector((-s*.049,-.015,-.035)),(.018,.026,.037),'leather',hand,8,5)

# Scarf: continuous band with asymmetric angular drape and overlapping rolled folds.
rings('Neck skin', [((0,.012,1.44),.072,.067),((0,.008,1.60),.077,.065)],'skin','head',12)
# A ring with hand-authored bottom/top edge sag, outside and inside thickness.
N=16;vs=[]
for layer in range(4):
 for i in range(N):
  a=2*math.pi*i/N;front=max(0,-math.sin(a));rx=[.164,.175,.126,.12][layer];ry=[.126,.144,.101,.094][layer]
  z=[1.462,1.535,1.553,1.474][layer] - front*[.055,.025,.018,.040][layer] + .012*math.cos(a)
  vs.append((rx*math.cos(a),ry*math.sin(a),z))
fs=[(j*N+i,j*N+(i+1)%N,((j+1)%4)*N+(i+1)%N,((j+1)%4)*N+i) for j in range(4) for i in range(N)]
mesh('Cream scarf thick folded collar',vs,fs,'cream')
plate('Scarf broad diagonal fold',[(-.156,-.085,1.529),(-.108,-.135,1.474),(-.014,-.164,1.43),(.11,-.145,1.491),(.174,-.08,1.55),(.093,-.119,1.518),(-.018,-.145,1.472)],'cream',depth=.02,bulge=.006)
path('Scarf rolled light edge',[(-.158,-.094,1.532),(-.115,-.145,1.485),(-.01,-.176,1.445),(.116,-.151,1.502),(.175,-.084,1.551)],.008,'cream',tone=1.06)
plate('Scarf tucked hanging end',[(-.136,-.094,1.512),(-.172,-.09,1.458),(-.13,-.133,1.359),(-.075,-.153,1.39),(-.11,-.148,1.472)],'cream',depth=.016,bulge=.008,tone=.95)

# Angular face built from intentional anatomical landmarks, not a scaled sphere.
# Ring order: front center, front-left-quarter, cheek-left, side/back, symmetric.
face_rows=[(1.548,.045,-.076,.040),(1.572,.073,-.091,.057),(1.625,.091,-.101,.077),(1.665,.106,-.105,.083),(1.705,.108,-.096,.084),(1.757,.106,-.085,.081),(1.811,.092,-.046,.070)]
vs=[]
for z,w,front,back in face_rows:
 vs += [(0,front,z),(-w*.64,front+(-.008 if 1.65<z<1.69 else .007),z),(-w,front+.037,z),(-w*.99,.031,z),(-w*.70,back,z),(0,back+.01,z),(w*.70,back,z),(w*.99,.031,z),(w,front+.037,z),(w*.64,front+(-.008 if 1.65<z<1.69 else .007),z)]
fs=[]
for j in range(len(face_rows)-1):
 for i in range(10):
  a=j*10+i;b=j*10+(i+1)%10;c=(j+1)*10+(i+1)%10;d=(j+1)*10+i
  # Broad cheek/jaw planes; occasional diagonals establish sculpted anatomy.
  if j in (1,2) and i in (0,1,8,9):fs += [(a,b,c),(a,c,d)]
  else:fs.append((a,b,c,d))
fs += [tuple(range(9,-1,-1)),tuple(60+i for i in range(10))]
mesh('Face | sculpted anatomical planes',vs,fs,'skin','head')
# Cheek/temple accent surfaces use skin geometry, not random-colored facets.
for s in [-1,1]:
 ell('Sculpted ear '+str(s),(s*.114,.005,1.689),(.025,.026,.044),'skin','head',10,6)
 plate('Ear concha shade '+str(s),[(s*.122,-.018,1.712),(s*.131,-.018,1.686),(s*.119,-.018,1.667),(s*.113,-.022,1.689)],'skin','head',.002,.002,.72)
 # Narrow focused eyes under angular brow shelf; no oversized round eyeballs.
 x=s*.044
 plate('Eye socket shadow '+str(s),[(x-.028,-.109,1.708),(x-.021,-.115,1.722),(x+.023,-.111,1.723),(x+.028,-.109,1.711),(x+.019,-.116,1.702),(x-.019,-.116,1.702)],'skin','head',.003,.002,.66)
 plate('Almond eye '+str(s),[(x-.021,-.119,1.712),(x-.012,-.121,1.717),(x+.015,-.119,1.717),(x+.022,-.117,1.711),(x+.012,-.121,1.707),(x-.012,-.121,1.707)],'cream','head',.001,.001,.97)
 ell('Dark iris '+str(s),(x+s*.003,-.124,1.712),(.0080,.0035,.0075),'dark','head',10,5,.52)
 path('Sculpted upper eyelid '+str(s),[(x-.023,-.121,1.713),(x-.012,-.124,1.720),(x+.018,-.121,1.718),(x+.023,-.119,1.713)],.0032,'dark','head',.72)
 # Inner eyebrows lower = resolve, not startled expression.
 plate('Swept eyebrow '+str(s),[(s*.019,-.117,1.734),(s*.071,-.103,1.743),(s*.081,-.099,1.732),(s*.022,-.119,1.724)],'dark','head',.004,.002,.73)
# Structured bridge, wedge nose, alar wings.
mesh('Nose | angular bridge and tip',[(0,-.102,1.735),(-.014,-.109,1.711),(.014,-.109,1.711),(-.017,-.132,1.666),(.017,-.132,1.666),(0,-.140,1.676),(0,-.132,1.659),(-.025,-.117,1.664),(.025,-.117,1.664)],[(0,1,5),(0,5,2),(1,3,5),(2,5,4),(3,6,5),(4,5,6),(3,7,6),(4,6,8),(7,8,6)],'skin','head',1.05)
for s in [-1,1]:ell('Nostril '+str(s),(s*.015,-.132,1.660),(.005,.003,.0025),'skin','head',8,4,.55)
plate('Upper lip angular',[(-.031,-.103,1.621),(-.012,-.109,1.625),(0,-.109,1.622),(.012,-.109,1.625),(.03,-.103,1.621),(.017,-.111,1.616),(-.016,-.111,1.616)],'skin','head',.002,.001,.79)
path('Mouth resolute seam',[(-.029,-.109,1.617),(-.01,-.114,1.616),(.011,-.114,1.617),(.028,-.108,1.619)],.0018,'dark','head',.78)
plate('Lower lip light',[(-.022,-.109,1.612),(0,-.113,1.608),(.022,-.109,1.613),(.016,-.113,1.617),(-.016,-.113,1.615)],'skin','head',.002,.001,1.02)
# Chin/jaw value planes are part of the contiguous face mesh.

# Sculpted hair cap with a high asymmetric swept crest and tapered lock volumes.
rings('Hair | close cropped cap',[((0,.026,1.733),.112,.071),((0,.023,1.792),.124,.098),((-.007,.02,1.836),.111,.086),((-.015,.021,1.86),.074,.056)],'hair','head',16,.80)
ell('Hair close cropped nape',(0,.068,1.739),(.111,.044,.079),'hair','head',14,8,.73)
for s in [-1,1]:
 plate('Hair tapered sideburn '+str(s),[(s*.102,-.037,1.775),(s*.113,-.013,1.77),(s*.110,-.005,1.704),(s*.095,-.035,1.725)],'hair','head',.012,.003,.82)

def lock(n,pts,widths,tone=1):
 # Leaf-like solid tapered sweep, five-sided sections with a strong raised ridge.
 vs=[];N=5
 for j,(p,w) in enumerate(zip(pts,widths)):
  p=Vector(p);t=Vector(pts[min(j+1,len(pts)-1)])-Vector(pts[max(0,j-1)])
  a=t.normalized().cross(Vector((0,0,1)))
  if a.length<.1:a=Vector((1,0,0))
  a.normalize();b=t.normalized().cross(a).normalized()
  for k in range(N):
   ang=2*math.pi*k/N;vs.append(p+a*math.cos(ang)*w+b*math.sin(ang)*w*.62)
 fs=[(j*N+k,j*N+(k+1)%N,(j+1)*N+(k+1)%N,(j+1)*N+k) for j in range(len(pts)-1) for k in range(N)];fs += [tuple(range(N-1,-1,-1)),tuple((len(pts)-1)*N+k for k in range(N))]
 return mesh(n,vs,fs,'hair','head',tone)
# Individually authored sweep paths: varied rise, curl and overhang rather than
# uniform rows. The center quiff peaks above the cropped side foundation.
crests=[
 (-.112,-.025,1.80,-.025,-.02,.063,.039),
 (-.079,-.044,1.805,.071,-.036,.079,.043),
 (-.031,-.046,1.812,.090,-.019,.084,.046),
 (.024,-.027,1.806,.094,-.002,.067,.041),
 (-.087,.021,1.822,.059,-.005,.093,.046),
 (-.030,.027,1.835,.084,-.001,.092,.047),
 (.032,.031,1.821,.101,.013,.073,.044),
 (-.070,.074,1.807,.033,.035,.080,.042),
 (-.012,.084,1.817,.071,.040,.074,.043),
 (.056,.077,1.794,.081,.032,.063,.037),
 (-.111,.053,1.778,-.026,.023,.070,.032)]
for i,(x,y,z,dx,dy,h,w) in enumerate(crests):
 lock('Hair sculpted curled crest %02d'%i,[(x,y,z),(x+dx*.28,y+dy*.30,z+h*.52),(x+dx*.78,y+dy*.80,z+h*.82),(x+dx,y+dy,z+h),(x+dx+.012,y+dy-.008,z+h+.008)],[w,w*.96,w*.67,w*.24,.0007],1.09 if i in (1,3,7,9,12) else .94)
# Lower swept front fringe gives recognizable brows/forehead rather than a helmet.
for i,(x,z) in enumerate([(-.105,1.80),(-.073,1.794),(-.035,1.817),(.004,1.815),(.049,1.809),(.090,1.81)]):
 lock('Hair forward swept fringe '+str(i),[(x,.0,z+.022),(x+.018,-.058,z+.012),(x+.033,-.086,z-.005),(x+.024,-.099,z-.024)],[.029,.032,.019,.001],1.02 if i%2 else .87)
for s in [-1,1]:
 for j in range(2):lock('Hair side sweep %s-%s'%(s,j),[(s*.097,.02+j*.022,1.78+j*.015),(s*.134,.028+j*.02,1.822+j*.01),(s*.156,.01+j*.02,1.85+j*.01)],[.025,.022,.001],.94)

# Skin the lower coat to the existing knee chain, not a rigid thigh-only slab.
# The unchanged defeat pose bends thighs sharply; a broad 35% shin transition
# lets the long lining fold with the leg instead of passing through the floor.
bpy.context.view_layer.update()
for o in parts:
 if any(k in o.name for k in ('coat tail','coat facing','rear lining','Rear hem brass','Tail sewn fold')):
  group=next((g for g in o.vertex_groups if g.name.startswith('thigh.')),None)
  if group:
   sg=o.vertex_groups.new(name=group.name.replace('thigh.','shin.'))
   for v in o.data.vertices:
    z=(o.matrix_world@v.co).z;w=.35*max(0,min(1,(.80-z)/.28))
    group.add([v.index],1-w,'REPLACE')
    if w>0:sg.add([v.index],w,'REPLACE')
   o['cloth_skinning']='Authored thigh-to-shin transition; original bones only'

# Join character export duplicate while preserving named editable construction.
author=bpy.data.collections.new('AUTHORING | segmented sculpt and paint');scene.collection.children.link(author)
for p in parts:
 cp=p.copy();cp.data=p.data.copy();author.objects.link(cp);cp.name='EDIT | '+p.name
 cp.hide_render=True;cp.hide_set(True)
author.hide_render=True;author.hide_viewport=True
bpy.ops.object.select_all(action='DESELECT')
for p in parts:p.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();skin=bpy.context.object;skin.name='Zane_painterly_v1_SKIN';bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
skin.parent=rig;skin.location=(0,0,0)
mod=skin.modifiers.new('Immutable impact sixteen-bone binding','ARMATURE');mod.object=rig
# All bone groups retain skin bone ordering, including unused root.
for b in rig.data.bones:
 if b.name not in skin.vertex_groups:skin.vertex_groups.new(name=b.name)
skin['provenance']='Original sculpted geometry; original authored atlas; same impact rig/actions/sockets. No reference pixels copied.'

# Straight sword uses the exact existing attachment alignment, with authored bevels.
wp=bpy.data.objects['Kael_v2_weapon_socket'];Q=Euler((math.radians(-45),0,math.radians(115))).to_matrix();C=Vector((-.045,-.055,0))
def P(v):return C+Q@Vector(v)
tube('Sword leather grip',P((0,-.10,0)),P((0,.10,0)),.025,'leather',None,seg=10)
for yy in [-.075,-.045,-.015,.015,.045,.075]:tube('Sword raised grip wrap',P((0,yy,0)),P((0,yy+.009,0)),.027,'dark',None,seg=10)
ell('Sword faceted pommel',P((0,-.125,0)),(.036,.036,.043),'brass',None,10,5)
# Sculpted slightly hooked crossguard, still straight sword silhouette.
for s in [-1,1]:
 tube('Sword brass crossguard',P((0,.115,0)),P((s*.125,.105,0)),.023,'brass',None,.018,8)
 tube('Sword swept quillon',P((s*.125,.105,0)),P((s*.145,.077,0)),.019,'brass',None,.013,8)
rows=[(.14,.047),(.21,.051),(.70,.030),(.855,.0005)];vs=[]
for y,w in rows:
 for x,z in [(-w,0),(-w*.69,-.010),(0,-.017),(w*.69,-.01),(w,0),(0,.017)]:vs.append(P((x,y,z)))
fs=[(j*6+k,j*6+(k+1)%6,(j+1)*6+(k+1)%6,(j+1)*6+k) for j in range(3) for k in range(6)];fs.append((5,4,3,2,1,0))
mesh('Sword long bevelled blade',vs,fs,'steel',None,1.10)
tube('Sword engraved fuller',P((0,.235,-.018)),P((0,.69,-.018)),.0032,'dark',None,seg=6)
for o in gear:o.parent=wp;o['equipment_alignment']='Exact original socket-local alignment'
# Merge equipment into one node, retaining socket-local coordinates and all textures.
bpy.ops.object.select_all(action='DESELECT')
for o in gear:o.select_set(True)
bpy.context.view_layer.objects.active=gear[0];bpy.ops.object.join();sword=bpy.context.object;sword.name='Zane_painterly_v1_SWORD'
# V4 camera-safety refinement: shorten only the exposed visual blade by 6cm.
# Grip/guard/socket and logical gameplay reach remain unchanged. Work in the
# original design coordinates so the result matches the edited saved source.
blade_matrix=sword.matrix_basis.copy();blade_inverse=blade_matrix.inverted()
for vertex in sword.data.vertices:
 p=Q.transposed()@(blade_matrix@vertex.co-C)
 if p.y>.13999:
  p.y=.14+(p.y-.14)*(.655/.715);vertex.co=blade_inverse@(C+Q@p)
sword.data.update();sword['blade_framing_revision']='V4: 6cm shorter visible blade; unchanged guard/grip/socket/gameplay reach.'

rig.data.pose_position='POSE';scene.frame_set(1);bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in rig.children_recursive:o.select_set(True)
output=OUT/'zane_painterly_v1.glb'
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_anim_slide_to_zero=True,export_force_sampling=True,export_optimize_animation_size=False,export_vertex_color='ACTIVE',export_all_vertex_colors=False,export_copyright='Original Zane visual rebuild for ProjectTactic; retained project-owned rig and motion.')
# glTF ACTIVE vertex colors are multiplied automatically at delivery. Mirror that
# exact multiplication in the editable source preview after exporting, so source
# material view does not look brighter than the imported GLB.
for material in groups.values():
 nt=material.node_tree;bs=nt.nodes.get('Principled BSDF');im=next(n for n in nt.nodes if n.type=='TEX_IMAGE')
 vc=nt.nodes.new('ShaderNodeVertexColor');vc.layer_name='PaintPlanes';vc.label='Exported COLOR_0 value planes'
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1.0
 nt.links.new(im.outputs['Color'],mul.inputs[1]);nt.links.new(vc.outputs['Color'],mul.inputs[2]);nt.links.new(mul.outputs[0],bs.inputs['Base Color'])
scene['asset_status']='Editable painterly Zane candidate. Actual 3D; not yet verified in-game.'
scene['art_direction']='Approved Zane-3D-Look-Target and Zane-Painterly-Style-Concept, original sculpt/paint interpretation.'
scene.render.fps=24;bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(args.source_output))
print('PAINTERLY_EXPORT',hashlib.sha256(output.read_bytes()).hexdigest())

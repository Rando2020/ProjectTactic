#!/usr/bin/env python3
"""Actual offline 3D renders of imported exported GLB. Never target/concept images."""
import bpy,math,json,argparse,sys,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=HERE/'renders');p.add_argument('--quick',action='store_true');p.add_argument('--samples',type=int,default=192);p.add_argument('--asset',type=Path);p.add_argument('--views',default='');p.add_argument('--revision',default='candidate');p.add_argument('--turntable-only',action='store_true');p.add_argument('--turntable-frames',type=int,default=48);p.add_argument('--turntable',action='store_true');a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
a.output.mkdir(parents=True,exist_ok=True)
asset=a.asset or ROOT/'godot/assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb'
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(asset));s=bpy.context.scene;r=bpy.data.objects['Kael_v2_RIG']
for tr in r.animation_data.nla_tracks:tr.mute=True
r.animation_data.action=None;r.rotation_mode='XYZ'
s.render.engine='CYCLES';s.cycles.samples=24 if a.quick else a.samples;s.cycles.use_denoising=False;s.cycles.seed=0;s.render.resolution_x=s.render.resolution_y=840;s.render.resolution_percentage=100;s.render.image_settings.file_format='PNG';s.render.fps=24
s.world=bpy.data.worlds.new('Neutral studio world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.18,.21,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
s.view_settings.view_transform='AgX'
for name,loc,power,color,size in [('Neutral broad key',(-3,-4,5),450,(1,.96,.90),4),('Neutral fill',(3,-2,3),240,(.9,.95,1),4),('Soft separation',(1,3,4),500,(1,.96,.90),3)]:
 d=bpy.data.lights.new(name,'AREA');o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=loc;d.energy=power;d.color=color;d.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;m=bpy.data.materials.new('Neutral gray ground');m.diffuse_color=(.105,.12,.13,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.105,.12,.13,1);m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.92;floor.data.materials.append(m)
d=bpy.data.cameras.new('Review camera');cam=bpy.data.objects.new('Review camera',d);bpy.context.collection.objects.link(cam);s.camera=cam;d.type='ORTHO'
manifest={'revision':a.revision,'asset':str(asset),'sha256':hashlib.sha256(asset.read_bytes()).hexdigest(),'claim':'ACTUAL OFFLINE 3D RENDERS of imported GLB, not game capture','renderer':'Blender Cycles','samples':s.cycles.samples,'lighting':'Neutral; no painted or dynamic fire glow','views':[]}
def render(label,clip='idle',frame=1,location=(3,-6,2.5),target=(0,0,.97),ortho=2.45,res=840,angle=0):
 if a.views and label not in a.views.split(','):return
 r.animation_data.action=bpy.data.actions[clip+'_Kael_v2_RIG'];r.rotation_euler.z=angle;s.frame_set(frame-1);cam.location=location;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=ortho;s.render.resolution_x=s.render.resolution_y=res;s.render.filepath=str(a.output/(label+'.png'))
 projected_bounds=None
 if label.startswith('turntable_'):
  bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();xy=[]
  for obj in r.children_recursive:
   if obj.type=='MESH':
    evaluated=obj.evaluated_get(deps)
    for corner in evaluated.bound_box:
     q=world_to_camera_view(s,cam,evaluated.matrix_world@Vector(corner));xy.append((q.x,q.y))
  projected_bounds=[[min(p[0] for p in xy),min(p[1] for p in xy)],[max(p[0] for p in xy),max(p[1] for p in xy)]]
  assert all(.005<=v<=.995 for row in projected_bounds for v in row),('Turntable crops evaluated model bounds',label,projected_bounds)
 bpy.ops.render.render(write_still=True);manifest['views'].append({'file':label+'.png','clip':clip,'source_frame':frame,'camera':list(location),'target':list(target),'ortho':ortho,'resolution':res,'facing':angle,'conservative_model_projected_bounds':projected_bounds,'image_sha256':hashlib.sha256((a.output/(label+'.png')).read_bytes()).hexdigest()})
if not a.turntable_only:render('01_three_quarter')
if not a.quick and not a.turntable_only:
 render('02_front',location=(0,-6,1.25))
 render('03_rear',location=(-3,6,2.5))
 render('04_face_detail',location=(.5,-5,1.90),target=(0,0,1.67),ortho=.64,res=840)
camloc=(4,-4,.95+math.sqrt(32)*math.tan(math.radians(30)))
if not a.turntable_only:render('05_game_ortho_idle',location=camloc,ortho=3.2,res=384,target=(0,0,.95))
if not a.quick and not a.turntable_only:
 for label,clip,frame in [('06_walk_stride','walk',7),('07_walk_contact','walk',13),('08_slash_load','slash',10),('09_slash_contact','slash',16),('10_slash_follow','slash',19),('11_cast_load','cast',12),('12_cast_release','cast',22),('13_cast_recoil','cast',28),('14_defeat_kneel','defeat',36)]:render(label,clip,frame,location=camloc,ortho=3.2,res=640,target=(0,0,.95))
if a.turntable or a.turntable_only:
 for i in range(a.turntable_frames):render('turntable_%03d'%i,location=(3,-6,2.5),ortho=2.8,res=512,angle=i*2*math.pi/a.turntable_frames)
(a.output/'render_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

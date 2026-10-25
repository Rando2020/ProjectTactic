"""Render the exported GLB, never the editable .blend, at the shipping camera.

blender -b -t 2 --python assets/source/zane-impact-v1/render_review.py -- --output /tmp/zane-renders
The renders have a 138.24 px display footprint when the full square is resized
to that width. This is offline export QA, not a Godot/gameplay capture.
"""
import argparse
import bpy
import json
import math
from pathlib import Path
import sys
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('/tmp/zane-impact-renders'))
parser.add_argument('--baseline', action='store_true')
parser.add_argument('--motion', action='store_true')
parser.add_argument('--gait-segments', action='store_true', help='Render short/long distance-matched samples only')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
args.output.mkdir(parents=True, exist_ok=True)
asset = ROOT / ('godot/assets/3d/characters/zane_v2/zane_v2.glb' if args.baseline else 'godot/assets/3d/characters/zane_impact_v1/zane_impact_v1.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(asset))
scene = bpy.context.scene
rig = bpy.data.objects['Kael_v2_RIG']
rig.rotation_mode = 'XYZ'
for track in rig.animation_data.nla_tracks:
    track.mute = True
rig.animation_data.action = None
scene.render.engine = 'CYCLES'
scene.cycles.samples = 64
scene.cycles.use_denoising = False
scene.cycles.seed = 0
scene.render.resolution_x = scene.render.resolution_y = 160
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.render.image_settings.file_format = 'PNG'
scene.render.fps = 24
scene.world = bpy.data.worlds.new('Review world')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.055, .072, .077, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .5
scene.view_settings.view_transform = 'AgX'
for name, location, power, color, size in [('Warm key', (-3, -4, 5), 450, (1, .86, .67), 4), ('Cool fill', (3, -2, 3), 180, (.62, .77, 1), 4), ('Warm rim', (1, 3, 4), 550, (1, .78, .5), 3)]:
    data = bpy.data.lights.new(name, 'AREA')
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    data.energy, data.color, data.size = power, color, size
    obj.rotation_euler = (Vector((0, 0, 1))-obj.location).to_track_quat('-Z', 'Y').to_euler()
camera_data = bpy.data.cameras.new('Shipping projection')
camera = bpy.data.objects.new('Shipping projection', camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (4, -4, .95 + math.sqrt(32)*math.tan(math.radians(30)))
camera.rotation_euler = (Vector((0, 0, .95))-camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.type, camera_data.ortho_scale = 'ORTHO', 3.2
scene.camera = camera
# A neutral ground supports perception of actual sole clearance.
bpy.ops.mesh.primitive_plane_add(size=200)
plane = bpy.context.object
material = bpy.data.materials.new('Review ground')
material.diffuse_color = (.13, .155, .15, 1)
plane.data.materials.append(material)

def render(label, clip, frame, facing=0):
    rig.animation_data.action = bpy.data.actions[clip+'_Kael_v2_RIG']
    rig.rotation_euler.z = facing
    source_time = frame-1
    scene.frame_set(int(source_time), subframe=source_time-int(source_time))
    scene.render.filepath = str(args.output / (label+'.png'))
    bpy.ops.render.render(write_still=True)

poses = [('idle', 'idle', 1), ('sword_load', 'slash', 10), ('sword_contact', 'slash', 16), ('sword_follow', 'slash', 19), ('sword_recovery', 'slash', 30), ('cast_load', 'cast', 12), ('cast_release', 'cast', 22), ('cast_recoil', 'cast', 28), ('cast_recovery', 'cast', 34)]
if not args.gait_segments:
    for face, angle in [('S', 0), ('E', math.pi/2), ('N', math.pi), ('W', -math.pi/2)]:
        for label, clip, frame in poses:
            render(face+'_'+label, clip, frame, angle)
    for f in (1, 4, 7, 10, 13, 16, 19, 22, 25):
        render('gait_%02d' % f, 'walk', f)
if args.motion:
    for clip, count in [('walk', 25), ('slash', 36), ('cast', 42)]:
        for f in range(1, count+1):
            render('motion_%s_%03d' % (clip, f), clip, f)
if args.gait_segments:
    scene.render.film_transparent = True
    plane.hide_render = True
    manifest = json.loads((ROOT / 'godot/assets/3d/characters/zane_impact_v1/presentation.json').read_text())
    step = manifest['gait_calibration']['step_canvas_px']['S']
    for distance in (64.0, 192.0):
        duration = min(1, max(.5, distance/180))
        count = round(duration*24)
        for index in range(count+1):
            phase = (distance*index/count/(2*step)) % 1
            render('segment_%d_%03d' % (distance, index), 'walk', 1+phase*24)
from bpy_extras.object_utils import world_to_camera_view
anchor = world_to_camera_view(scene, camera, Vector((0, 0, 0)))
json.dump({'asset': str(asset), 'camera_size': 3.2, 'display_size': 138.24, 'render_resolution': 160, 'root_anchor_px': [anchor.x*160, (1-anchor.y)*160], 'renderer': 'Blender Cycles; exported GLB; not gameplay capture'}, open(args.output/'render_manifest.json', 'w'), indent=2)

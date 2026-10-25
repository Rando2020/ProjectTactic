"""Dense floor and blade/body checks on a fresh import of the shipping GLB.

blender -b -t 2 --python assets/source/zane-impact-v1/validate_export.py -- --report /tmp/export-clearance.json
A conservative blade-edge/skin-triangle test excludes intentional hand.R grip.
It supplements visual review; it is not full self-collision or cloth simulation.
"""
import argparse
import bpy
import hashlib
import json
from pathlib import Path
import sys
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--report', type=Path, default=Path('/tmp/zane-impact-export-clearance.json'))
parser.add_argument('--baseline', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
model = ROOT / ('godot/assets/3d/characters/zane_v2/zane_v2.glb' if args.baseline else 'godot/assets/3d/characters/zane_impact_v1/zane_impact_v1.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(model))
rig = bpy.data.objects['Kael_v2_RIG']
skin = next(o for o in bpy.data.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers))
blade = bpy.data.objects['Zane original straight steel sword']
for track in rig.animation_data.nla_tracks:
    track.mute = True
hand = skin.vertex_groups['hand.R'].index
body_polys = [list(p.vertices) for p in skin.data.polygons if not any(any(g.group == hand and g.weight > .5 for g in skin.data.vertices[i].groups) for i in p.vertices)]
blade_edges = list({tuple(sorted((p.vertices[i], p.vertices[(i+1) % len(p.vertices)]))) for p in blade.data.polygons for i in range(len(p.vertices))})
meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.name != 'Icosphere']
report = {'model_sha256': hashlib.sha256(model.read_bytes()).hexdigest(), 'samples_hz': 96, 'method': 'Fresh GLB import; dense evaluated vertices and blade-edge rays against evaluated body triangles, excluding intentional hand.R grip. No full-body self-collision claim.', 'clips': {}}
failures = []
for clip in ('idle', 'slash', 'thrust', 'heavy', 'cast', 'hit', 'recovery', 'walk', 'defeat'):
    action = bpy.data.actions[clip+'_Kael_v2_RIG']
    rig.animation_data.action = action
    duration = action.frame_range[1]-action.frame_range[0]
    low, clearance, crossings = 100, 100, []
    for step in range(round(duration*4)+1):
        frame = action.frame_range[0]+step/4
        bpy.context.scene.frame_set(int(frame), subframe=frame-int(frame))
        graph = bpy.context.evaluated_depsgraph_get()
        es = skin.evaluated_get(graph)
        sm = es.to_mesh()
        vertices = [es.matrix_world @ v.co for v in sm.vertices]
        bvh = BVHTree.FromPolygons(vertices, body_polys, all_triangles=False)
        es.to_mesh_clear()
        for obj in meshes:
            eo = obj.evaluated_get(graph)
            mesh = eo.to_mesh()
            vs = [eo.matrix_world @ v.co for v in mesh.vertices]
            if vs:
                low = min(low, min(v.z for v in vs))
            if obj == blade:
                bv = vs
            eo.to_mesh_clear()
        for v in bv:
            nearest = bvh.find_nearest(v)
            if nearest[3] is not None:
                clearance = min(clearance, nearest[3])
        hits = 0
        for a, b in blade_edges:
            delta = bv[b]-bv[a]
            length = delta.length
            if length < 1e-7:
                continue
            point, normal, index, distance = bvh.ray_cast(bv[a], delta.normalized(), length)
            if point is not None and 1e-5 < distance < length-1e-5:
                hits += 1
        if hits:
            crossings.append({'source_frame': round(frame+1, 4), 'edge_crossings': hits})
    report['clips'][clip] = {'minimum_floor_clearance_world': round(low, 8), 'minimum_blade_vertex_body_distance_world': round(clearance, 8), 'samples': round(duration*4)+1, 'blade_body_crossings': crossings}
    if low < -.0001 or crossings:
        failures.append(clip)
report['pass'] = not failures
report['failing_clips'] = failures
args.report.parent.mkdir(parents=True, exist_ok=True)
args.report.write_text(json.dumps(report, indent=2)+'\n')
print('ZANE_EXPORT_REVIEW', json.dumps({'pass': report['pass'], 'failing_clips': failures, 'report': str(args.report)}))
if failures:
    sys.exit(1)

#!/usr/bin/env python3
"""Validate the *exported* Zane variant against the immutable original GLB.

No Blender/Godot import cache or third-party GLTF parser is needed. NumPy is
used for exported matrix/skin sampling, not to infer rig compatibility from a
source scene. The report is deterministic and suitable for CI/provenance.
"""
import argparse
import bisect
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
BASELINE_SHA256 = '9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5'
BASELINE = ROOT / 'godot/assets/3d/characters/zane_v2/zane_v2.glb'
DIRECTORY = ROOT / 'godot/assets/3d/characters/zane_impact_v1'
MODEL = DIRECTORY / 'zane_impact_v1.glb'
MANIFEST = DIRECTORY / 'presentation.json'
CHANGED = ['walk', 'slash', 'cast']
UNCHANGED = ['idle', 'thrust', 'heavy', 'hit', 'recovery', 'defeat']
SOCKETS = ['Kael_v2_cast_socket', 'Kael_v2_weapon_socket', 'Kael_v2_shield_socket']
MARKERS = {'slash_load': 10, 'slash_contact': 16, 'cast_load': 12, 'cast_release': 22, 'cast_recoil': 28}
RUNTIME = {'prepare': .20, 'snap': .04, 'travel': .22, 'recovery': .22, 'walk_speed_px_s': 180.0, 'walk_min': .50, 'walk_max': 1.00, 'walk_settle': .10}
TOLERANCE = 1e-5


class ValidationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ValidationError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def report_sha(report):
    return sha(json.dumps(report, sort_keys=True, separators=(',', ':'), allow_nan=False).encode())


def close(a, b, message, tolerance=TOLERANCE):
    a, b = np.asarray(a, dtype=float), np.asarray(b, dtype=float)
    require(a.shape == b.shape and np.all(np.isfinite(a)) and np.all(np.isfinite(b)) and np.allclose(a, b, atol=tolerance, rtol=0), message)


def quaternion_matrix(q):
    x, y, z, w = np.asarray(q) / np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w), 0],
                     [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w), 0],
                     [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y), 0],
                     [0, 0, 0, 1]], dtype=float)


def trs(node):
    if 'matrix' in node:
        return np.array(node['matrix']).reshape(4, 4).T
    out = quaternion_matrix(node.get('rotation', [0, 0, 0, 1]))
    out[:3, :3] *= np.array(node.get('scale', [1, 1, 1]))[None, :]
    out[:3, 3] = node.get('translation', [0, 0, 0])
    return out


class GLB:
    def __init__(self, path):
        self.path = Path(path)
        require(self.path.is_file(), f'missing output: {self.path}')
        self.data = self.path.read_bytes()
        require(self.data[:4] == b'glTF' and len(self.data) >= 28, 'not a GLB')
        magic, version, total = struct.unpack_from('<III', self.data)
        require(version == 2 and total == len(self.data), 'invalid GLB header')
        length, kind = struct.unpack_from('<II', self.data, 12)
        require(kind == 0x4e4f534a, 'GLB JSON chunk absent')
        self.doc = json.loads(self.data[20:20+length])
        offset = 20 + length
        length, kind = struct.unpack_from('<II', self.data, offset)
        require(kind == 0x004e4942, 'GLB binary chunk absent')
        self.binary = self.data[offset+8:offset+8+length]
        self.names = {n['name']: i for i, n in enumerate(self.doc['nodes']) if 'name' in n}
        require(len(self.names) == len(self.doc['nodes']), 'node names must be present and unique')
        self.parents = {}
        for i, n in enumerate(self.doc['nodes']):
            for child in n.get('children', []):
                require(child not in self.parents, 'multiple parents')
                self.parents[child] = i
        self.animations = {a['name']: a for a in self.doc.get('animations', [])}
        require(len(self.animations) == len(self.doc.get('animations', [])), 'duplicate clip names')
        self._accessors = {}
        self._channels = {}

    def accessor(self, index):
        if index in self._accessors:
            return self._accessors[index]
        a = self.doc['accessors'][index]
        require('sparse' not in a, 'sparse accessors are not part of this contract')
        v = self.doc['bufferViews'][a['bufferView']]
        types = {5120: 'i1', 5121: 'u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
        widths = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
        dtype = np.dtype(types[a['componentType']])
        width = widths[a['type']]
        offset = v.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = v.get('byteStride', width * dtype.itemsize)
        arr = np.ndarray((a['count'], width), dtype=dtype, buffer=self.binary, offset=offset, strides=(stride, dtype.itemsize)).copy()
        require(np.all(np.isfinite(arr)), 'non-finite accessor')
        self._accessors[index] = arr
        return arr

    def channels(self, name):
        if name in self._channels:
            return self._channels[name]
        a = self.animations[name]
        channels = {}
        for c in a['channels']:
            s = a['samplers'][c['sampler']]
            target = c['target']
            key = (self.doc['nodes'][target['node']]['name'], target['path'])
            require(key not in channels, f'duplicate animation channel: {name}/{key}')
            require(target['path'] in ('translation', 'rotation', 'scale'), 'no gameplay/method/morph animation tracks')
            require(s.get('interpolation', 'LINEAR') == 'LINEAR', 'expected sampled linear export')
            times, values = self.accessor(s['input'])[:, 0], self.accessor(s['output'])
            require(len(times) == len(values) and len(times) >= 2 and np.all(np.diff(times) > 0), 'invalid animation time ordering')
            channels[key] = (times, values)
        self._channels[name] = channels
        return channels

    def duration(self, name):
        times = [v[0] for v in self.channels(name).values()]
        close([float(t[0]) for t in times], [0] * len(times), f'clip does not start at zero: {name}')
        duration = max(float(t[-1]) for t in times)
        close([float(t[-1]) for t in times], [duration] * len(times), f'inconsistent clip channel durations: {name}')
        return duration

    def pose(self, name, time):
        updates = {}
        for (node, path), (times, values) in self.channels(name).items():
            i = max(0, min(len(times)-2, bisect.bisect_right(times, time)-1))
            u = min(1, max(0, (time-times[i])/(times[i+1]-times[i])))
            a, b = values[i].astype(float), values[i+1].astype(float)
            if path == 'rotation':
                dot = float(a @ b)
                if dot < 0:
                    b, dot = -b, -dot
                if dot < .9995:
                    theta = math.acos(min(1, dot))
                    value = (math.sin((1-u)*theta)*a + math.sin(u*theta)*b) / math.sin(theta)
                else:
                    value = a*(1-u)+b*u
                value /= np.linalg.norm(value)
            else:
                value = a*(1-u)+b*u
            updates.setdefault(self.names[node], {})[path] = value
        cache = {}
        def global_transform(i):
            if i not in cache:
                n = dict(self.doc['nodes'][i])
                n.update(updates.get(i, {}))
                local = trs(n)
                cache[i] = global_transform(self.parents[i]) @ local if i in self.parents else local
            return cache[i]
        return [global_transform(i) for i in range(len(self.doc['nodes']))]

    def geometry(self):
        """Exported mesh primitives, with bind data; no source-scene geometry."""
        out = []
        for i, n in enumerate(self.doc['nodes']):
            if 'mesh' not in n:
                continue
            for p in self.doc['meshes'][n['mesh']]['primitives']:
                attrs = p['attributes']
                v = self.accessor(attrs['POSITION'])
                item = {'node': i, 'name': n['name'], 'vertices': np.column_stack((v, np.ones(len(v)))), 'indices': self.accessor(p['indices']).reshape(-1, 3)}
                if 'skin' in n:
                    skin = self.doc['skins'][n['skin']]
                    item.update(joints=skin['joints'], inverse=self.accessor(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1), joint_ids=self.accessor(attrs['JOINTS_0']).astype(int), weights=self.accessor(attrs['WEIGHTS_0']))
                out.append(item)
        return out

    @staticmethod
    def deform(item, pose):
        if 'joints' not in item:
            return (pose[item['node']] @ item['vertices'].T).T[:, :3]
        matrices = np.array([pose[j] @ inv for j, inv in zip(item['joints'], item['inverse'])])
        transforms = (matrices[item['joint_ids']] * item['weights'][:, :, None, None]).sum(axis=1)
        return np.einsum('nij,nj->ni', transforms, item['vertices'])[:, :3]


def compatibility(base, model):
    require(len(base.doc['skins']) == len(model.doc['skins']) == 1, 'exactly one shared skin required')
    bs, ms = base.doc['skins'][0], model.doc['skins'][0]
    bones = [base.doc['nodes'][i]['name'] for i in bs['joints']]
    require(len(bones) == 16 and bones == [model.doc['nodes'][i]['name'] for i in ms['joints']], 'bone name/order difference')
    details = []
    for name in bones + SOCKETS + ['Kael_v2_RIG']:
        require(name in model.names, f'missing rig/socket: {name}')
        bi, mi = base.names[name], model.names[name]
        bp, mp = base.parents.get(bi), model.parents.get(mi)
        bp = base.doc['nodes'][bp]['name'] if bp is not None else None
        mp = model.doc['nodes'][mp]['name'] if mp is not None else None
        require(bp == mp, f'bone/socket hierarchy difference: {name}')
        bm, mm = trs(base.doc['nodes'][bi]), trs(model.doc['nodes'][mi])
        close(bm, mm, f'bone/socket rest difference: {name}')
        details.append({'name': name, 'parent': bp, 'rest': [[round(float(x), 7) for x in row] for row in bm]})
    close(base.accessor(bs['inverseBindMatrices']), model.accessor(ms['inverseBindMatrices']), 'skin inverse bind difference')
    return {'bone_count': 16, 'bone_order': bones, 'nodes': details, 'inverse_bind_sha256': sha(base.accessor(bs['inverseBindMatrices']).tobytes()), 'sockets': SOCKETS, 'tolerance': TOLERANCE}


def measure_gait(model):
    """A step is one foot's forward-to-back stance excursion (half a cycle).

    glTF forward is +Z. Godot camera is orthographic size 3.2, yaw 45,
    pitch 30; projection is independent of renderer resolution/quality.
    Foot origins rather than a guessed sprite/tile width define the ruler.
    """
    poses = [model.pose('walk', t) for t in (0, .5)]
    excursions = []
    vectors = []
    for side in ('R', 'L'):
        i = model.names['foot.'+side]
        delta = poses[1][i][:3, 3] - poses[0][i][:3, 3]
        vectors.append(delta)
        excursions.append(abs(float(delta[2])))
    step = sum(excursions)/2
    right = np.array([1/math.sqrt(2), 0, -1/math.sqrt(2)])
    up = np.array([-1/(2*math.sqrt(2)), math.sqrt(3)/2, -1/(2*math.sqrt(2))])
    px = {}
    for face, angle in [('N', math.pi), ('E', math.pi/2), ('S', 0), ('W', -math.pi/2)]:
        c, s = math.cos(angle), math.sin(angle)
        rotation = np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
        projected = [math.hypot(float(right @ (rotation @ d)), float(up @ (rotation @ d))) * (138.24/3.2) for d in vectors]
        px[face] = round(sum(projected)/2, 8)
    return {'method': 'exported foot-origin stance excursion, average L/R, orthographic projection', 'world_step': round(step, 8), 'world_stride': round(2*step, 8), 'step_canvas_px': px, 'camera_size': 3.2, 'camera_pitch_degrees': 30.0, 'camera_yaw_degrees': 45.0, 'display_size': 138.24, 'stance_source_frames': [1, 13]}


def exported_motion_report(model):
    geometry = model.geometry()
    floors, sockets = {}, {}
    for clip in model.animations:
        low, positions = float('inf'), []
        duration = model.duration(clip)
        for t in np.linspace(0, duration, int(round(duration*96))+1):
            pose = model.pose(clip, float(t))
            low = min(low, *(float(model.deform(g, pose)[:, 1].min()) for g in geometry))
            positions.append(pose[model.names[SOCKETS[0]]][:3, 3].tolist())
        floors[clip] = round(low, 8)
        arr = np.array(positions)
        sockets[clip] = {'min': arr.min(axis=0).round(8).tolist(), 'max': arr.max(axis=0).round(8).tolist(), 'max_sample_delta_world': round(float(np.linalg.norm(np.diff(arr, axis=0), axis=1).max()), 8)}
    marker_positions = {}
    for marker, frame in MARKERS.items():
        clip = marker.split('_')[0]
        pose = model.pose(clip, (frame-1)/24)
        marker_positions[marker] = pose[model.names[SOCKETS[0]]][:3, 3].round(8).tolist()
    return {'marker_cast_socket_positions': marker_positions, 'samples_hz': 96, 'minimum_exported_vertex_y': floors, 'cast_socket_trajectory_bounds': sockets, 'floor_tolerance_world': -.0001}


def measure_gait_drift(model, gait):
    """Ideal-distance sampling of stance-origin drift, not runtime foot locking.

    Includes both required short/long segments and the one-second duration cap.
    Rendering/pixel quantization, frame aliasing, and stop-blend drift require
    native gameplay captures and are deliberately not claimed by this metric.
    """
    right = np.array([1/math.sqrt(2), 0, -1/math.sqrt(2)])
    up = np.array([-1/(2*math.sqrt(2)), math.sqrt(3)/2, -1/(2*math.sqrt(2))])
    reports = {}
    for face, angle in [('N', math.pi), ('E', math.pi/2), ('S', 0), ('W', -math.pi/2)]:
        c, s = math.cos(angle), math.sin(angle)
        rotation = np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
        project = np.array([right, -up]) @ rotation * (138.24/3.2)
        direction = project @ np.array([0, 0, 1])
        direction /= np.linalg.norm(direction)
        samples = {}
        for distance in (64.0, 192.0):
            duration = min(1, max(.5, distance/180))
            groups = {}
            for elapsed in np.linspace(0, duration, int(duration*120)+1):
                displacement = distance*elapsed/duration
                cycle = displacement/(2*gait['step_canvas_px'][face])
                phase = cycle % 1
                pose = model.pose('walk', phase)
                for side, offset in [('R', 0), ('L', .5)]:
                    stance_phase = (cycle+offset) % 1
                    if stance_phase > .58:
                        continue
                    key = (side, math.floor(cycle+offset))
                    point = project @ pose[model.names['foot.'+side]][:3, 3] + direction*displacement
                    groups.setdefault(key, []).append(point)
            drifts = [max(float(np.linalg.norm(p-points[0])) for p in points) for points in groups.values() if len(points) >= 2]
            samples[str(int(distance))] = {'distance_canvas_px': distance, 'duration_s': duration, 'cycle_count': round(distance/(2*gait['step_canvas_px'][face]), 6), 'max_support_origin_drift_canvas_px': round(max(drifts), 6), 'support_samples_hz': 120}
        reports[face] = samples
    return {'method': 'Ideal straight-segment distance-matched exported foot origins during authored 58% support windows. Not IK, not a runtime-render drift claim.', 'samples': reports}


def validate(baseline_path=BASELINE, model_path=MODEL, manifest_path=MANIFEST):
    require(Path(baseline_path).is_file(), 'missing baseline')
    require(sha(Path(baseline_path).read_bytes()) == BASELINE_SHA256, 'corrupted frozen baseline hash')
    require(Path(manifest_path).is_file(), 'missing presentation manifest')
    m = json.loads(Path(manifest_path).read_text())
    base, model = GLB(baseline_path), GLB(model_path)
    require(m.get('schema_version') == 1 and m.get('profile_id') == 'zane_impact_v1', 'wrong schema/profile')
    require(m.get('model') == 'res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb', 'wrong resource path')
    require(m.get('baseline_sha256') == BASELINE_SHA256, 'manifest baseline hash mismatch')
    require(m.get('model_sha256') == sha(model.data), 'variant hash mismatch')
    require(m.get('authoring_fps') == 24, 'authoring fps changed')
    require(m.get('changed_clips') == CHANGED and m.get('unchanged_clips') == UNCHANGED, 'clip allowlist changed')
    require(m.get('marker_frames') == MARKERS, 'source marker frames changed')
    for key, frame in MARKERS.items():
        close(m.get('source_markers', {}).get(key, -1), (frame-1)/24, f'inconsistent marker seconds: {key}', 1e-10)
    require(m.get('runtime') == RUNTIME, 'runtime timings changed')
    require(m.get('walk_contacts') == [0.0, .5], 'walk contact phases changed')
    require(m.get('cast_socket') == SOCKETS[0], 'wrong cast socket')
    require(m.get('forward_axis') == '+Z' and m.get('root_motion') == 'in_place', 'axis/root-motion declaration changed')
    comp = compatibility(base, model)
    require(m.get('compatibility_report_sha256') == report_sha(comp), 'compatibility report hash mismatch')
    require(set(model.animations) == set(base.animations), 'missing or extra required clip')
    durations, changed = {}, []
    for name in base.animations:
        durations[name] = model.duration(name)
        close(durations[name], base.duration(name), f'clip duration changed: {name}')
        close(m.get('clip_durations', {}).get(name, -1), durations[name], f'manifest clip duration mismatch: {name}')
        bc, mc = base.channels(name), model.channels(name)
        require(set(bc) == set(mc), f'animation channels changed: {name}')
        differs = False
        for key in bc:
            bt, bv = bc[key]
            mt, mv = mc[key]
            close(bt, mt, f'animation sample times changed: {name}/{key}')
            if bv.shape != mv.shape or not np.allclose(bv, mv, atol=TOLERANCE, rtol=0):
                differs = True
        if differs:
            require(name in CHANGED, f'unapproved animation keys changed: {name}')
            changed.append(name)
    require(set(changed) == set(CHANGED), 'all three approved motions must be authored differently')
    walk = model.channels('walk')
    close(walk[('root', 'translation')][1], np.zeros_like(walk[('root', 'translation')][1]), 'walk root motion detected')
    close(walk[('root', 'rotation')][1], np.tile([0, 0, 0, 1], (len(walk[('root', 'rotation')][1]), 1)), 'walk root rotation detected')
    gait = measure_gait(model)
    for key in ['world_step', 'world_stride', 'camera_size', 'display_size']:
        close(m.get('gait_calibration', {}).get(key, -1), gait[key], f'gait calibration mismatch: {key}')
    for face, value in gait['step_canvas_px'].items():
        close(m.get('gait_calibration', {}).get('step_canvas_px', {}).get(face, -1), value, f'unmeasured gait step: {face}')
        require(value > 0, 'gait step must be positive')
    motion = exported_motion_report(model)
    require(min(motion['minimum_exported_vertex_y'].values()) >= -.0001, 'exported mesh penetrates floor')
    return {'status': 'compatible', 'model_sha256': sha(model.data), 'baseline_sha256': BASELINE_SHA256, 'bone_count': 16, 'sockets': SOCKETS, 'changed_clips': CHANGED, 'unchanged_clips': UNCHANGED, 'clip_durations': durations, 'compatibility_report_sha256': report_sha(comp), 'compatibility': comp, 'gait_calibration': gait, 'exported_motion': motion, 'gait_drift': measure_gait_drift(model, gait)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, default=BASELINE)
    parser.add_argument('--model', type=Path, default=MODEL)
    parser.add_argument('--manifest', type=Path, default=MANIFEST)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    try:
        report = validate(args.baseline, args.model, args.manifest)
    except (ValidationError, KeyError, ValueError, IndexError, struct.error) as error:
        print(f'Zane impact asset: FAIL: {error}', file=sys.stderr)
        return 1
    output = json.dumps(report, indent=2, allow_nan=False) + '\n'
    if args.report:
        args.report.write_text(output)
    print(output)
    return 0


if __name__ == '__main__':
    sys.exit(main())

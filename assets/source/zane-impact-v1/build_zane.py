#!/usr/bin/env python3
"""Reproducible editable variant from an immutable copied Zane source scene.

Run Blender 4.3.2: blender -b -t 2 --python assets/source/zane-impact-v1/build_zane.py
Then Python: python3 tools/validate_zane_impact_asset.py
All modifications are confined to copied source and new outputs.
"""
import bpy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = HERE / 'source/zane_v2.blend'
OUTPUT = ROOT / 'godot/assets/3d/characters/zane_impact_v1'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == '374b52c41275feeb45b1df49ad240fc2923de3d4be8636a74a054c0c925131af'
assert hashlib.sha256((HERE / 'source/original_build_zane.py').read_bytes()).hexdigest() == '276696b68912613dc9a4c19f97b4e35372655a40f4d90f9095716f50e31348eb'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
scene.frame_set(1)
rig = bpy.data.objects['Kael_v2_RIG']
skin = bpy.data.objects['Zane_v2_SKIN']
skin.name = 'Zane_impact_v1_SKIN'
rig.data.pose_position = 'REST'
# Deterministic vertex-plane refinement. The frozen rest/bind data is untouched.
material_by_vertex = {}
for face in skin.data.polygons:
    name = skin.data.materials[face.material_index].name
    for i in face.vertices:
        material_by_vertex.setdefault(i, set()).add(name)
for vertex in skin.data.vertices:
    x, y, z = vertex.co
    materials = material_by_vertex[vertex.index]
    # Fitted pale torso: stronger chest-to-waist taper, preserving arm clearance.
    if 'Zane_Ivory' in materials and z > 1.08:
        vertex.co.x *= .92 + .16 * min(1, max(0, (z-1.08)/.35))
    # Dominant sword shoulder's swept edge vs a tighter casting-side shell.
    if ('Zane_Steel' in materials or 'Zane_Gold' in materials) and z > 1.29 and abs(x) > .28:
        if x < 0:
            vertex.co.x -= .042 * min(1, max(0, (-x-.28)/.16))
            vertex.co.z += .027 * min(1, max(0, (z-1.29)/.19))
        else:
            vertex.co.x = .27+(x-.27)*.87
    # Long narrow shin facets, not inflated round greaves. Feet are not edited.
    if .20 < z < .49 and 'Zane_Steel' in materials:
        center = -.216 if x < 0 else .216
        vertex.co.x = center+(x-center)*.86
    # Sharper pale front hems and an asymmetric charcoal rear chevron.
    if z < .90 and 'Zane_Ivory' in materials:
        vertex.co.x *= .94
    if 'Zane_Mantle' in materials or 'Zane_MantleLight' in materials:
        if y > .13 and z < 1.30:
            vertex.co.x += -.050 if x < -.20 else .015
            if x < -.20:
                vertex.co.z -= .025
skin.data.update()
# Deliberate broad tonal blocks; no textured detail or emissive character paint.
colors = {'Ivory': (.70, .65, .53), 'IvoryShade': (.39, .34, .25), 'Steel': (.23, .28, .31), 'SteelShadow': (.095, .125, .15), 'Edge': (.53, .55, .51), 'Gold': (.48, .315, .115), 'Slate': (.045, .09, .15), 'SlateLight': (.11, .18, .25), 'Mantle': (.032, .035, .039), 'MantleLight': (.085, .085, .075), 'HairLight': (.15, .066, .026)}
for key, color in colors.items():
    mat = bpy.data.materials.get('Zane_'+key)
    if mat is None:  # Unused colors were purged from the recovered source.
        continue
    mat.diffuse_color = (*color, 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = .48 if key in ('Steel', 'Edge') else .72
skin['presentation_variant'] = 'Zane impact v1; refined tapered planes, three original baked actions'
rig.data.pose_position = 'POSE'
spec = importlib.util.spec_from_file_location('zane_author_actions', HERE / 'author_actions.py')
actions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(actions)
actions.author(rig)
scene.frame_set(1)
bpy.context.view_layer.update()
OUTPUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for obj in rig.children_recursive:
    obj.select_set(True)
model = OUTPUT / 'zane_impact_v1.glb'
bpy.ops.export_scene.gltf(filepath=str(model), export_format='GLB', use_selection=True, export_animations=True, export_animation_mode='NLA_TRACKS', export_anim_slide_to_zero=True, export_force_sampling=True, export_optimize_animation_size=False)
scene['asset_status'] = 'Zane impact v1 editable presentation variant; immutable shared rest/sockets/six clips.'
scene.render.fps = 24
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(HERE / 'zane_impact_v1.blend'))
# Manifest is derived from actual exported data by the same validator library.
# Blender ships numpy; loading a script from the checkout avoids import caches.
vspec = importlib.util.spec_from_file_location('zane_asset_validator', ROOT / 'tools/validate_zane_impact_asset.py')
v = importlib.util.module_from_spec(vspec)
vspec.loader.exec_module(v)
base, variant = v.GLB(v.BASELINE), v.GLB(model)
compatibility = v.compatibility(base, variant)
manifest = {'schema_version': 1, 'profile_id': 'zane_impact_v1', 'model': 'res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb', 'model_sha256': v.sha(model.read_bytes()), 'baseline_sha256': v.BASELINE_SHA256, 'authoring_fps': 24, 'changed_clips': v.CHANGED, 'unchanged_clips': v.UNCHANGED, 'source_markers': {name: (frame-1)/24 for name, frame in v.MARKERS.items()}, 'marker_frames': v.MARKERS, 'runtime': v.RUNTIME, 'walk_contacts': [0.0, .5], 'cast_socket': v.SOCKETS[0], 'clip_durations': {name: variant.duration(name) for name in variant.animations}, 'compatibility_report_sha256': v.report_sha(compatibility), 'forward_axis': '+Z', 'root_motion': 'in_place', 'gait_calibration': v.measure_gait(variant)}
(OUTPUT / 'presentation.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('ZANE_IMPACT_BUILD_COMPLETE', v.sha(model.read_bytes()))

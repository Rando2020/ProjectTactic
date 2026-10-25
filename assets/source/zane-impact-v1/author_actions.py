"""Bespoke presentation actions; no rest edits, constraints, or gameplay events.

World-target two-link solves are baked into the existing Euler/location channels.
This is offline authoring, NOT runtime IK or foot locking. Coordinates below are
Blender (+Z up, -Y forward), exported by Blender to glTF +Y up / +Z forward.
"""
import math
import bpy
from mathutils import Vector, Matrix

FPS = 24
MARKERS = {'slash_load': 10, 'slash_contact': 16, 'cast_load': 12, 'cast_release': 22, 'cast_recoil': 28}


def author(rig):
    scene = bpy.context.scene
    scene.frame_set(1)
    bpy.context.view_layer.update()
    base = {p.name: (p.location.copy(), p.rotation_euler.copy()) for p in rig.pose.bones}
    rests = {b.name: b.matrix_local.to_quaternion() for b in rig.data.bones}
    blade = bpy.data.objects['Zane original straight steel sword']
    # A blade axis measured from actual equipment, relative to the hand pose.
    a, b = blade.matrix_world @ blade.data.vertices[0].co, blade.matrix_world @ blade.data.vertices[12].co
    blade_axis_in_hand = rig.pose.bones['hand.R'].matrix.to_quaternion().inverted() @ (b-a).normalized()
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    previous = {}

    def reset():
        for p in rig.pose.bones:
            p.location, p.rotation_euler = base[p.name]
            p.scale = (1, 1, 1)

    def aim(name, direction):
        p = rig.pose.bones[name]
        head = p.matrix.translation.copy()
        rest_direction = rig.data.bones[name].tail_local - rig.data.bones[name].head_local
        q = rest_direction.rotation_difference(Vector(direction)) @ rests[name]
        p.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4()
        bpy.context.view_layer.update()

    def ik(upper, lower, target, guide):
        start = rig.pose.bones[upper].matrix.translation.copy()
        target = Vector(target)
        direction = target-start
        axis = direction.normalized()
        l1, l2 = rig.data.bones[upper].length, rig.data.bones[lower].length
        distance = min(max(direction.length, abs(l1-l2)+.0001), l1+l2-.00001)
        along = (l1*l1-l2*l2+distance*distance)/(2*distance)
        height = math.sqrt(max(0, l1*l1-along*along))
        bend = Vector(guide) - axis*Vector(guide).dot(axis)
        bend.normalize()
        knee = start+axis*along+bend*height
        aim(upper, knee-start)
        aim(lower, target-rig.pose.bones[lower].matrix.translation)

    def orient_rest(name):
        p = rig.pose.bones[name]
        p.matrix = Matrix.Translation(p.matrix.translation) @ rests[name].to_matrix().to_4x4()
        bpy.context.view_layer.update()

    def sword(direction):
        # Rotation about the wrist, not a modification of the immutable socket.
        p = rig.pose.bones['hand.R']
        q = blade_axis_in_hand.rotation_difference(Vector(direction).normalized())
        p.matrix = Matrix.Translation(p.matrix.translation) @ q.to_matrix().to_4x4()
        bpy.context.view_layer.update()

    def legs(pelvis_drop=0, phase=None):
        for side in ('R', 'L'):
            if phase is None:
                target = (rig.data.bones['foot.'+side].head_local.x, -.01 if side == 'R' else .035, .14)
            else:
                ph = (phase + (0 if side == 'R' else .5)) % 1
                # Contact -> long linear backward stance -> quick raised return.
                if ph <= .58:
                    y, lift = -.36 + .72*(ph/.58), 0
                else:
                    u = (ph-.58)/.42
                    y, lift = .36-.72*(u*u*(3-2*u)), .115*math.sin(math.pi*u)
                target = (rig.data.bones['foot.'+side].head_local.x, y, .14+lift)
            ik('thigh.'+side, 'shin.'+side, target, (0, -1, 0))
            orient_rest('foot.'+side)

    def key(frame):
        for p in rig.pose.bones:
            e = p.rotation_euler.copy()
            if p.name in previous:
                e.make_compatible(previous[p.name])
            p.rotation_euler = e
            previous[p.name] = e.copy()
            p.keyframe_insert('rotation_euler', frame=frame, group=p.name)
            p.keyframe_insert('location', frame=frame, group=p.name)

    def new_action(name):
        nonlocal previous
        old = bpy.data.actions[name]
        old.name = name+'_original_reference'
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        rig.animation_data.action = action
        previous = {}
        return action

    def bake_pose(frame, torso=(0, 0, 0), hip=0, right=None, edge=None, left=None, palm=None):
        reset()
        rig.pose.bones['pelvis'].location.y = -.025
        rig.pose.bones['pelvis'].rotation_euler.y = math.radians(hip)
        rig.pose.bones['spine'].rotation_euler = tuple(math.radians(v) for v in torso)
        rig.pose.bones['head'].rotation_euler.y = math.radians(-torso[1]*.55)
        bpy.context.view_layer.update()
        legs()
        if right is not None:
            ik('upper_arm.R', 'forearm.R', right, (-1, -.15, .10))
        if edge is not None:
            sword(edge)
        if left is not None:
            ik('upper_arm.L', 'forearm.L', left, (1, .10, -.20))
        if palm is not None:
            aim('hand.L', palm)
        key(frame)

    slash = new_action('slash')
    bake_pose(1)
    bake_pose(5, torso=(2, -13, -3), hip=6, right=(-.65, -.15, 1.40), edge=(-.48, .10, .87), left=(.42, -.10, 1.0))
    bake_pose(7, torso=(3, -20, -4), hip=9, right=(-.62, -.13, 1.58), edge=(-.52, .14, .84), left=(.39, -.14, 1.08))
    bake_pose(10, torso=(4, -27, -5), hip=11, right=(-.47, -.08, 1.63), edge=(-.52, .16, .83), left=(.36, -.17, 1.14))
    bake_pose(14, torso=(4, -28, -5), hip=11, right=(-.46, -.08, 1.64), edge=(-.52, .16, .83), left=(.35, -.17, 1.14))
    bake_pose(16, torso=(10, 22, 5), hip=-9, right=(-.37, -.55, 1.23), edge=(.30, -.72, -.62), left=(.40, -.13, 1.12))
    bake_pose(19, torso=(10, 29, 6), hip=-10, right=(-.04, -.56, 1.08), edge=(.62, -.72, -.31), left=(.40, -.04, 1.08))
    bake_pose(24, torso=(5, 13, 2), hip=-5, right=(-.23, -.40, 1.05), edge=(.28, -.78, -.55), left=(.42, -.08, 1.0))
    bake_pose(30, torso=(2, 3, 0), hip=0, right=(-.43, -.21, 1.0), edge=(-.65, -.40, -.30))
    bake_pose(36)
    slash.pose_markers.new('slash_load').frame = 10
    slash.pose_markers.new('slash_contact').frame = 16

    cast = new_action('cast')
    bake_pose(1)
    bake_pose(7, torso=(-3, -8, -3), hip=4, right=(-.51, -.06, .98), edge=(-.72, -.18, .10), left=(.39, -.18, 1.18), palm=(-.20, -.70, .20))
    bake_pose(12, torso=(-11, -17, -5), hip=7, right=(-.49, -.10, 1.02), edge=(-.76, -.15, .06), left=(.21, -.22, 1.27), palm=(-.10, -.50, .40))
    bake_pose(19, torso=(-12, -19, -5), hip=8, right=(-.50, -.10, 1.02), edge=(-.76, -.15, .06), left=(.19, -.22, 1.29), palm=(-.08, -.55, .40))
    bake_pose(22, torso=(14, 15, 4), hip=-6, right=(-.54, -.05, 1.02), edge=(-.72, -.22, .12), left=(.10, -.56, 1.43), palm=(.0, -1, -.06))
    bake_pose(25, torso=(-12, -4, -3), hip=3, right=(-.51, -.03, 1.01), edge=(-.72, -.18, .10), left=(.24, -.47, 1.46), palm=(.0, -1, .05))
    bake_pose(28, torso=(-16, -9, -4), hip=6, right=(-.50, -.04, 1.00), edge=(-.72, -.18, .10), left=(.36, -.40, 1.40), palm=(.0, -1, .08))
    bake_pose(34, torso=(-4, -4, -1), hip=2, right=(-.49, -.08, .96), edge=(-.72, -.20, .10), left=(.42, -.23, 1.20), palm=(.10, -.70, -.40))
    bake_pose(42)
    for name in ('cast_load', 'cast_release', 'cast_recoil'):
        cast.pose_markers.new(name).frame = MARKERS[name]

    walk = new_action('walk')
    for f in range(1, 26):
        reset()
        phase = (f-1)/24
        rig.pose.bones['pelvis'].location.y = -.045 + .010*(1-math.cos(phase*4*math.pi))
        rig.pose.bones['pelvis'].rotation_euler.y = math.radians(3)*math.sin(phase*2*math.pi)
        rig.pose.bones['spine'].rotation_euler.x = math.radians(5)
        rig.pose.bones['spine'].rotation_euler.y = -math.radians(4)*math.sin(phase*2*math.pi)
        rig.pose.bones['head'].rotation_euler.y = math.radians(2)*math.sin(phase*2*math.pi)
        for side, offset in [('R', 0), ('L', math.pi)]:
            p = rig.pose.bones['upper_arm.'+side]
            p.rotation_euler.x = base[p.name][1].x + math.radians(10)*math.sin(phase*2*math.pi+offset)
        bpy.context.view_layer.update()
        legs(phase=phase)
        key(f)
    walk.pose_markers.new('right_contact').frame = 1
    walk.pose_markers.new('left_contact').frame = 13
    walk.pose_markers.new('loop').frame = 25
    for action in (slash, cast, walk):
        for curve in action.fcurves:
            for k in curve.keyframe_points:
                k.interpolation = 'LINEAR'
    rig.animation_data.action = None
    for track in rig.animation_data.nla_tracks:
        track.mute = False
        if track.name in ('slash', 'cast', 'walk'):
            strip = track.strips[0]
            start, end = strip.frame_start, strip.frame_end
            strip.action = bpy.data.actions[track.name]
            strip.action_frame_start = 1
            strip.action_frame_end = {'slash': 36, 'cast': 42, 'walk': 25}[track.name]
            strip.frame_start, strip.frame_end = start, end
    scene.frame_set(1)

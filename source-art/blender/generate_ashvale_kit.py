"""Generate the ProjectTactic Ashvale modular terrain kit in Blender.
Run from Blender: blender --background --python generate_ashvale_kit.py

Design rules:
- 1 tactical tile = 2m x 2m
- 1 elevation step = 1m
- Low-poly, bevel-friendly, muted diorama palette
- Export one GLB per asset to godot/assets/3d/ashvale/
"""
from pathlib import Path
import bpy, math
from mathutils import Vector

ROOT = Path(bpy.path.abspath("//")) if bpy.data.filepath else Path.cwd()
OUT = ROOT / "godot" / "assets" / "3d" / "ashvale"
OUT.mkdir(parents=True, exist_ok=True)

PALETTE = {
    "grass": (0.23,0.32,0.20,1), "dirt": (0.32,0.24,0.17,1),
    "stone": (0.28,0.29,0.30,1), "darkstone": (0.18,0.19,0.20,1),
    "wood": (0.28,0.18,0.12,1), "water": (0.18,0.34,0.40,0.82),
    "ember": (0.48,0.18,0.08,1), "moss": (0.27,0.37,0.22,1),
    "iron": (0.20,0.21,0.22,1),
}

def material(name):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = PALETTE[name]
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = PALETTE[name]
    bsdf.inputs["Roughness"].default_value = 0.88
    if name == "water":
        bsdf.inputs["Alpha"].default_value = 0.82
        mat.surface_render_method = 'DITHERED'
    return mat

def cube(name, size, loc=(0,0,0), mat="stone", bevel=0.025):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new("soft-bevel","BEVEL");mod.width=bevel;mod.segments=1
    o.data.materials.append(material(mat))
    return o

def cylinder(name,radius,depth,loc=(0,0,0),mat="wood",verts=8,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=depth,location=loc,rotation=rot)
    o=bpy.context.object;o.name=name;o.data.materials.append(material(mat));return o

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def export_asset(name, builder):
    clear();builder();
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/f"{name}.glb"),export_format='GLB',use_selection=True,
                              export_apply=True,export_yup=True)


def flat(top):
    return lambda: (cube('base',(2,2,.18),(0,0,.09),'darkstone'), cube('top',(1.96,1.96,.08),(0,0,.22),top))

def raised(top):
    return lambda: (cube('cliff',(2,2,1),(0,0,.5),'darkstone'),cube('top',(1.96,1.96,.08),(0,0,1.04),top))

assets={
'grass-flat':flat('grass'),'dirt-flat':flat('dirt'),'stone-flat':flat('stone'),'scorched-ground':flat('ember'),
'grass-raised':raised('grass'),'stone-raised':raised('stone')}
for n,b in assets.items():export_asset(n,b)

export_asset('shallow-water',lambda:(cube('bed',(2,2,.14),(0,0,.07),'darkstone'),cube('water',(1.96,1.96,.05),(0,0,.185),'water',0)))

def cliff():
    raised('grass')()
    for x,h in [(-.65,.52),(0,.72),(.65,.45)]:cube('rock',(.48,.16,h),(x,-.9,.1+h/2),'stone')
export_asset('grass-cliff',cliff)

def stairs():
    for i in range(4):
        h=.25*(i+1);cube('step',(2,.5,h),(0,-.75+i*.5,h/2),'stone')
export_asset('stone-stairs',stairs)

def bridge():
    for i in range(6):cube('plank',(1.8,.27,.12),(0,-.68+i*.27,.31),'wood')
    for x in (-.82,.82):cube('rail',(.09,1.8,.15),(x,0,.455),'wood')
export_asset('wood-bridge',bridge)
export_asset('ruined-wall-short',lambda:cube('wall',(2,.34,1.15),(0,0,.575),'stone'))
export_asset('ruined-wall-corner',lambda:(cube('wall-a',(2,.34,1.2),(0,0,.6),'stone'),cube('wall-b',(.34,2,1.2),(0,0,.6),'stone')))

def pillar():
    for z,s in [(0,.7),(.7,.56),(1.26,.42)]:cube('pillar',(s,s,.7),(0,0,z+.35),'stone')
export_asset('broken-pillar',pillar)

def arch():
    cube('pier-l',(.34,.42,2),(-.76,0,1),'stone');cube('pier-r',(.34,.42,2),(.76,0,1),'stone');cube('beam',(1.86,.42,.36),(0,0,1.93),'stone')
export_asset('stone-arch',arch)

def tree():
    cylinder('trunk',.16,1.7,(0,0,.85),'wood',7)
    for i,(ang,dx) in enumerate([(-.8,-.12),(.4,.1),(1.4,0)]):cylinder(f'branch-{i}',.07,.85,(dx,0,1.35),'wood',6,(ang,0,0))
export_asset('dead-tree',tree)
export_asset('gravestone',lambda:(cube('base',(.9,.32,.12),(0,0,.06),'darkstone'),cube('slab',(.62,.2,.86),(0,0,.55),'stone')))

def brazier():
    cylinder('bowl',.32,.38,(0,0,.19),'iron',8)
    bpy.ops.mesh.primitive_cone_add(vertices=7,radius1=.22,radius2=0,depth=.48,location=(0,0,.62));bpy.context.object.data.materials.append(material('ember'))
export_asset('brazier',brazier)
export_asset('crate',lambda:cube('crate',(.85,.85,.85),(0,0,.425),'wood'))

def cart():
    cube('bed',(1.2,.75,.18),(0,0,.45),'wood')
    for x in (-.58,.58):cylinder('wheel',.34,.12,(x,0,.33),'wood',10,(0,math.pi/2,0))
export_asset('broken-cart',cart)

def bush():
    for i,(loc,scale) in enumerate([((0,0,.25),.46),((.3,.05,.34),.34),((-.28,.05,.34),.33)]):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=scale,location=loc);bpy.context.object.name=f'bush-{i}';bpy.context.object.data.materials.append(material('moss'))
export_asset('bush',bush)

def road_straight():
    flat('grass')();cube('road',(.72,1.96,.04),(0,0,.29),'dirt',0)
export_asset('dirt-path-straight',road_straight)

def road_corner():
    flat('grass')();cube('road-a',(.72,1.25,.04),(0,-.35,.29),'dirt',0);cube('road-b',(1.25,.72,.04),(.35,0,.29),'dirt',0)
export_asset('dirt-path-corner',road_corner)

print(f"Exported 22 Ashvale GLBs to {OUT}")

import bpy
import math
import os

OUT_DIR = "/tmp/df_belt"
GLB_PATH = "/home/azurice/Files/dimension-factory/assets/models/belt.glb"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(GLB_PATH), exist_ok=True)

# ---------- clean scene ----------
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials):
    bpy.data.materials.remove(m)

# ---------- materials ----------
def mat(name, color, metallic=0.0, roughness=0.5, emission=None, emission_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = [n for n in m.node_tree.nodes if n.bl_idname == 'ShaderNodeBsdfPrincipled'][0]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return m

frame_mat = mat("frame", (0.16, 0.17, 0.19), metallic=0.85, roughness=0.35)
rail_mat = mat("rail", (0.38, 0.40, 0.44), metallic=0.9, roughness=0.25)
roller_mat = mat("roller", (0.30, 0.31, 0.34), metallic=0.9, roughness=0.4)
belt_mat = mat("belt", (0.10, 0.10, 0.11), metallic=0.0, roughness=0.9)
chev_mat = mat("chevron", (0.9, 0.75, 0.1), metallic=0.0, roughness=0.4,
               emission=(0.9, 0.75, 0.1), emission_strength=1.5)

# ---------- helpers (Blender Z-up: X=传送方向, Y=宽度, Z=高度) ----------
def box(name, loc, size, material, bevel=0.02):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bevel", 'BEVEL')
        mod.width = bevel
        mod.segments = 2
    o.data.materials.append(material)
    return o

def roller(name, x):
    # cylinder axis along Y (width): rotate 90 deg around X
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.78, location=(x, 0, 0.15),
                                        rotation=(math.radians(90), 0, 0), vertices=24)
    o = bpy.context.object
    o.name = name
    bevel = o.modifiers.new("bevel", 'BEVEL')
    bevel.width = 0.01
    bevel.segments = 2
    o.data.materials.append(roller_mat)
    bpy.ops.object.shade_smooth()
    return o

parts = []

# ---------- build (1x1 cell footprint, 输出方向 +X) ----------
parts.append(box("base", (0, 0, 0.06), (0.92, 0.92, 0.12), frame_mat, bevel=0.03))

for x in (-0.36, 0.36):
    parts.append(roller("roller", x))

parts.append(box("belt", (0, 0, 0.19), (0.72, 0.80, 0.05), belt_mat, bevel=0.015))

# belt tread grooves (thin dark strips across belt, along Y)
groove_mat = mat("groove", (0.04, 0.04, 0.045), metallic=0.0, roughness=0.95)
for gx in (-0.27, -0.135, 0.0, 0.135, 0.27):
    parts.append(box("groove", (gx, 0, 0.216), (0.025, 0.78, 0.004), groove_mat, bevel=0.0))

for y in (-0.44, 0.44):
    parts.append(box("rail", (0, y, 0.22), (0.84, 0.06, 0.12), rail_mat, bevel=0.02))
    for x in (-0.42, 0.42):
        parts.append(box("cap", (x, y, 0.22), (0.06, 0.08, 0.14), frame_mat, bevel=0.015))

for x in (-0.36, 0.36):
    for y in (-0.36, 0.36):
        parts.append(box("foot", (x, y, 0.015), (0.12, 0.12, 0.05), frame_mat, bevel=0.01))

# chevrons on belt, pointing +X: concave-quad mesh, no rotation ambiguity
def chevron(name, cx):
    # ">" outline: tip at +X, notch at center-back
    pts = [(cx - 0.06, 0.10), (cx + 0.06, 0.0), (cx - 0.06, -0.10), (cx - 0.025, 0.0)]
    z = 0.217
    h = 0.012
    verts = [(x, y, z) for x, y in pts] + [(x, y, z + h) for x, y in pts]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7),
             (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(chev_mat)
    return o

for cx in (-0.22, 0.0, 0.22):
    parts.append(chevron("chevron", cx))

# ---------- lighting ----------
world = bpy.data.worlds.new("world")
bpy.context.scene.world = world
world.use_nodes = True
bg = [n for n in world.node_tree.nodes if n.bl_idname == 'ShaderNodeBackground'][0]
bg.inputs[0].default_value = (0.10, 0.10, 0.13, 1.0)
bg.inputs[1].default_value = 0.8

bpy.ops.object.light_add(type='SUN', location=(3, -2, 5))
sun = bpy.context.object
sun.data.energy = 4.0
sun.rotation_euler = (math.radians(35), math.radians(10), math.radians(120))

bpy.ops.object.light_add(type='AREA', location=(-2, 2, 3))
area = bpy.context.object
area.data.energy = 120
area.data.shape = 'DISK'
area.data.size = 2.0

# ---------- camera ----------
bpy.ops.object.camera_add()
cam = bpy.context.object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 1.6
cam.location = (1.5, -1.5, 1.3)
target = bpy.data.objects.new("target", None)
bpy.context.collection.objects.link(target)
target.location = (0, 0, 0.12)
c = cam.constraints.new('TRACK_TO')
c.target = target
bpy.context.scene.camera = cam

# ---------- render ----------
scene = bpy.context.scene
try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except Exception:
    scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.filepath = os.path.join(OUT_DIR, "preview.png")
bpy.ops.render.render(write_still=True)

# three-view verification renders (all orthographic)
cam.data.ortho_scale = 1.3
target.location = (0, 0, 0.1)
for name, loc in (("front", (3, 0, 0.1)), ("side", (0, -3, 0.1)), ("top", (0, 0, 3))):
    cam.location = loc
    if name == "top":
        target.location = (0, 0, 0)
    scene.render.filepath = os.path.join(OUT_DIR, "%s.png" % name)
    bpy.ops.render.render(write_still=True)

# ---------- export glb ----------
bpy.ops.object.select_all(action='DESELECT')
for o in parts:
    o.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=GLB_PATH,
    use_selection=True,
    export_yup=True,
    export_apply=True,
)
print("DONE", scene.render.filepath, GLB_PATH)

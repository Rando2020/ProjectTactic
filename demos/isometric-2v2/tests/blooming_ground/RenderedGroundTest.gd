extends Node
## Actual renderer regression. Frozen reference is from combat head 0d109fd.
## Headless import/checks are intentionally insufficient for these pixel assertions.
const CURRENT = preload("res://prototypes/blooming/BloomingSurface.gdshader")
const ORIGINAL = preload("res://tests/blooming_ground/OriginalSurface.gdshader")
const ATLAS = preload("res://assets/environments/blooming-ruins-v2/surfaces.png")
var output_dir := "user://ground-render-tests"
var failures: Array[String] = []
var results: Array[Dictionary] = []
var checks := 0

func _ready() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="): output_dir=arg.trim_prefix("--capture-dir=")
 call_deferred("run")

func patch(shader: Shader, surface: int, center: Vector3, extent: float, side: bool=false) -> SubViewport:
 var view := SubViewport.new()
 view.size=Vector2i(128,128)
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(view)
 var mesh := MeshInstance3D.new()
 if side:
  var quad := QuadMesh.new(); quad.size=Vector2.ONE*extent; mesh.mesh=quad
 else:
  var plane := PlaneMesh.new(); plane.size=Vector2.ONE*extent; mesh.mesh=plane
 var material := ShaderMaterial.new(); material.shader=shader
 material.set_shader_parameter("atlas",ATLAS)
 material.set_shader_parameter("surface",surface)
 mesh.material_override=material; mesh.position=center; view.add_child(mesh)
 var camera := Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=extent; camera.near=0.01; camera.far=30
 camera.position=center+(Vector3(0,0,8) if side else Vector3(0,8,0))
 view.add_child(camera)
 camera.look_at(center,Vector3.UP if side else Vector3.FORWARD)
 camera.current=true
 return view

func compare(name: String, a_shader: Shader, a_surface: int, b_shader: Shader, b_surface: int, center: Vector3, extent: float, side: bool=false, expect_difference: bool=false) -> void:
 var a:=patch(a_shader,a_surface,center,extent,side)
 var b:=patch(b_shader,b_surface,center,extent,side)
 for i in 3: await RenderingServer.frame_post_draw
 var ai:=a.get_texture().get_image()
 var bi:=b.get_texture().get_image()
 var error := 0.0
 var different := 0
 for y in range(8,120):
  for x in range(8,120):
   var ca:=ai.get_pixel(x,y); var cb:=bi.get_pixel(x,y)
   var distance:=maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b)))
   error=maxf(error,distance)
   if distance>1.0/255.0: different+=1
 checks+=1
 var passed := different>10000 if expect_difference else different==0
 if not passed:
  failures.append(name)
  printerr("FAIL: ",name," different pixels ",different,"; expected difference ",expect_difference,"; max channel error ",error)
 else: print("PASS: ",name)
 assert(ai.save_png(output_dir.path_join(name+"-a.png"))==OK)
 assert(bi.save_png(output_dir.path_join(name+"-b.png"))==OK)
 results.append({"name":name,"different_pixels":different,"max_channel_error":error,"center":str(center),"extent":extent,"expected_difference":expect_difference})
 a.queue_free(); b.queue_free()
 await get_tree().process_frame

func run() -> void:
 if DisplayServer.get_name()=="headless":
  printerr("FAIL: rendered ground tests require a display, not headless diagnostics")
  get_tree().quit(2); return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
 # Same world patch must not change when its gameplay road/stone tag changes.
 # PracticeTerrain3D scales and offsets the lower model surface from .26 to world y=0.
 await compare("lower-floor-tag-independent",CURRENT,0,CURRENT,1,Vector3(12,0,13),2)
 await compare("soil-transition-tag-independent",CURRENT,0,CURRENT,1,Vector3(12,0,15),2)
 # Do not allow a vacuous seam fix that removes the garden entirely.
 await compare("garden-soil-present",CURRENT,0,ORIGINAL,0,Vector3(12,0,13),2,false,true)
 # Changes must stay off the upper landing, treads, risers and retaining faces.
 await compare("upper-landing-preserved",CURRENT,0,ORIGINAL,0,Vector3(12,3.54,3),2)
 # Same soil-positive xz as the ground check: this specifically protects the height guard.
 await compare("elevated-garden-patch-preserved",CURRENT,0,ORIGINAL,0,Vector3(12,3.54,13),2)
 await compare("stair-tread-preserved",CURRENT,3,ORIGINAL,3,Vector3(5,1.08,10),2)
 await compare("stair-riser-preserved",CURRENT,3,ORIGINAL,3,Vector3(5,.8,10),1,true)
 await compare("retaining-face-preserved",CURRENT,0,ORIGINAL,0,Vector3(12,1,5),2,true)
 # Both columns of both approach lanes keep their cell-center paving.
 for x in [4.0,6.0,16.0,18.0]:
  await compare("path-center-"+str(int(x)),CURRENT,0,ORIGINAL,0,Vector3(x,0,14),.01)
 await compare("lower-perimeter-preserved",CURRENT,0,ORIGINAL,0,Vector3(0,0,12),.01)
 var file:=FileAccess.open(output_dir.path_join("render-tests.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"results":results},"\t"))
 print("Blooming ground rendered: %d checks, %d failures"%[checks,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)

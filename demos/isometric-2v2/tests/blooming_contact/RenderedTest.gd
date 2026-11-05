extends "res://tests/blooming_ground/RenderedGroundTest.gd"
const BASELINE=preload("res://tests/blooming_contact/BaselineSurface.gdshader")
func setup_contacts(view: SubViewport, points: Array[Vector4]) -> void:
 var material: ShaderMaterial=(view.get_child(0) as MeshInstance3D).material_override
 var packed:=PackedVector4Array(points); packed.resize(16)
 material.set_shader_parameter("contact_count",points.size())
 material.set_shader_parameter("contact_points",packed)
func probe(name: String, center: Vector3, a_points: Array[Vector4], b_points: Array[Vector4], expect_darkening: bool=false, surface: int=0, side: bool=false, underside: bool=false) -> void:
 var a:=patch(CURRENT,surface,center,2,side)
 var b:=patch(CURRENT,surface,center,2,side)
 if underside:
  (a.get_child(0) as MeshInstance3D).rotation.x=PI
  (b.get_child(0) as MeshInstance3D).rotation.x=PI
 setup_contacts(a,a_points); setup_contacts(b,b_points)
 for i in 3: await RenderingServer.frame_post_draw
 var ai:=a.get_texture().get_image(); var bi:=b.get_texture().get_image()
 var changed:=0; var brightened:=0; var excessive:=0; var maximum:=0.0
 for y in range(8,120):
  for x in range(8,120):
   var ca:=ai.get_pixel(x,y); var cb:=bi.get_pixel(x,y)
   var distance:=maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b)))
   maximum=maxf(maximum,distance)
   if distance>1.0/255.0: changed+=1
   if ca.r>cb.r+1.0/255.0 or ca.g>cb.g+1.0/255.0 or ca.b>cb.b+1.0/255.0: brightened+=1
   if ca.r<cb.r*.82-1.0/255.0 or ca.g<cb.g*.82-1.0/255.0 or ca.b<cb.b*.82-1.0/255.0: excessive+=1
 var passed: bool=(changed>1000 and brightened==0 and excessive==0) if expect_darkening else changed==0
 checks+=1
 if not passed: failures.append(name); printerr("FAIL: ",name," changed=",changed," brightened=",brightened," excessive=",excessive," maximum=",maximum)
 else: print("PASS: ",name)
 assert(ai.save_png(output_dir.path_join(name+"-a.png"))==OK)
 assert(bi.save_png(output_dir.path_join(name+"-b.png"))==OK)
 results.append({"name":name,"changed":changed,"brightened":brightened,"excessive":excessive,"max_channel_error":maximum,"expect_darkening":expect_darkening})
 a.queue_free(); b.queue_free(); await get_tree().process_frame
func run() -> void:
 if DisplayServer.get_name()=="headless":printerr("FAIL: contacts require actual rendering");get_tree().quit(2);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
 var contact: Array[Vector4]=[Vector4(12,13,0,.6)]
 await compare("zero-contact-identical",CURRENT,0,BASELINE,0,Vector3(12,0,13),2)
 await probe("lower-contact-visible",Vector3(12,0,13),contact,[],true)
 await probe("upper-contact-visible",Vector3(12,3.54,13),[Vector4(12,13,3.54,.6)],[],true)
 await probe("outside-footprint-identical",Vector3(15,0,13),contact,[])
 await probe("wrong-height-identical",Vector3(12,3.54,13),contact,[])
 await probe("side-face-identical",Vector3(12,0,13),contact,[],false,0,true)
 await probe("underside-identical",Vector3(12,0,13),contact,[],false,0,false,true)
 await probe("stair-material-identical",Vector3(12,0,13),contact,[],false,3)
 await probe("overlap-not-additive",Vector3(12,0,13),[contact[0],contact[0]],contact)
 var file:=FileAccess.open(output_dir.path_join("contact-render-tests.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":results},"\t"))
 print("Blooming contact rendered: %d checks, %d failures"%[checks,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)

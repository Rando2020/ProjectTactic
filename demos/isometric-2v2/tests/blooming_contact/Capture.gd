extends "res://tests/blooming_ground/Capture.gd"
var without_contacts:=false
func _ready() -> void:
 without_contacts="--without-contacts" in OS.get_cmdline_user_args()
 super._ready()
func capture(suffix: String) -> void:
 if without_contacts:
  var terrain=battle.tactical_grid.terrain_view
  for material: ShaderMaterial in terrain._materials.values():
   material.set_shader_parameter("contact_count",0)
  terrain._viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 await super.capture(suffix)
 if suffix=="overview":
  var camera: Camera2D=battle._battle_camera
  var original_zoom:=camera.zoom;var original_position:=camera.global_position
  var grid:=battle.tactical_grid
  var area: Rect2=battle.battle_ui.gameplay_rect(get_viewport().get_visible_rect().size)
  for sample in [{"name":"front-cypress","cell":Vector2(11,9)},{"name":"left-column","cell":Vector2(0,6)},{"name":"upper-cypress","cell":Vector2(0,1)}]:
   camera.zoom=original_zoom*3
   camera.global_position=grid.to_global(grid.terrain_view.projected_point(sample.cell))+(get_viewport().get_visible_rect().size*.5-area.get_center())/camera.zoom
   await super.capture(sample.name)
  camera.zoom=original_zoom;camera.global_position=original_position

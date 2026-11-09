extends "res://tests/blooming_ground/Capture.gd"
var installer: Node
var baseline:=false
func _ready() -> void:
 baseline="--baseline-walls" in OS.get_cmdline_user_args()
 super._ready()
func capture(suffix: String) -> void:
 if not baseline and not is_instance_valid(installer):
  installer=preload("res://prototypes/blooming/walls/WallCandidate.gd").new()
  battle.add_child(installer);installer.configure(battle.tactical_grid)
 await super.capture(suffix)
 if suffix=="overview":
  var camera: Camera2D=battle._battle_camera
  var original_zoom:=camera.zoom;var original_position:=camera.global_position
  var grid:=battle.tactical_grid
  var area: Rect2=battle.battle_ui.gameplay_rect(get_viewport().get_visible_rect().size)
  for sample in [{"name":"center-joins","cell":Vector2(5.5,2.5)},{"name":"left-stairs","cell":Vector2(2.5,3)},{"name":"right-corner","cell":Vector2(9.5,2)}]:
   camera.zoom=original_zoom*2.5
   camera.global_position=grid.to_global(grid.terrain_view.projected_point(sample.cell,4.0))+(get_viewport().get_visible_rect().size*.5-area.get_center())/camera.zoom
   await super.capture(sample.name)
  camera.zoom=original_zoom;camera.global_position=original_position

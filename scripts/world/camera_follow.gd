class_name CameraFollow
extends Camera2D
@export var target_path: NodePath = ^"../Mario"
@export_range(0.01, 1.0, 0.01) var follow_speed: float = 0.1

var _target: Node2D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		push_warning("CameraFollow: no se encontró el objetivo en '%s'." % target_path)


func _process(_delta: float) -> void:
	if _target == null:
		return
	if _target.global_position.x > global_position.x:
		global_position.x = lerpf(global_position.x, _target.global_position.x, follow_speed)

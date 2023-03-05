extends Camera2D

export var target_path:NodePath = "../Krot"

var target:Node2D

func _ready():
	target = get_node(target_path)

func _process(delta):
	if is_instance_valid(target):
		global_position = target.global_position
	var half_size = zoom * get_viewport_rect().size / 2.0
	global_position.x = clamp(global_position.x, limit_left + half_size.x, limit_right - half_size.x)
	global_position.y = clamp(global_position.y, limit_top + half_size.y, limit_bottom - half_size.y)

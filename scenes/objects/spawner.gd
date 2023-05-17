extends VisibilityNotifier2D

var on_camera:bool = false
var intersecting_bodies:int = 0

func _ready():
	var _err
	_err = connect("screen_entered", self, "_on_screen_entered")
	_err = connect("screen_exited", self, "_on_screen_exited")
	_err = $Area2D.connect("body_entered", self, "_on_body_entered")
	_err = $Area2D.connect("body_exited", self, "_on_body_exited")
	
func _on_screen_entered():
	on_camera = true
	
func _on_screen_exited():
	on_camera = false
	
func _on_body_entered(body):
	if (body.collision_layer & $Area2D.collision_mask) > 0:
		intersecting_bodies += 1

func _on_body_exited(body):
	if (body.collision_layer & $Area2D.collision_mask) > 0:
		intersecting_bodies -= 1

# Returns true if it is legal to spawn a farmer in this region (there is nothing in the way and it's off screen)
func can_spawn()->bool:
	return !on_camera and intersecting_bodies == 0

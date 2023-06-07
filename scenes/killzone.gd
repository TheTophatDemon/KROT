extends Area2D

func _ready():
	var _err = connect("body_entered", self, "_on_body_entered")
	
func _on_body_entered(body):
	if body.has_method("_on_killzone_enter"):
		body._on_killzone_enter(self)

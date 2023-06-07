extends AudioStreamPlayer

export var fade_speed:float = 10.0

var fading:bool = false

func start_fade():
	fading = true
	
func _process(delta):
	if fading:
		volume_db -= delta * fade_speed

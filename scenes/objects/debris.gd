extends CPUParticles2D

func _ready():
	emitting = true
	one_shot = true

func _process(_delta):
	if !emitting:
		queue_free()

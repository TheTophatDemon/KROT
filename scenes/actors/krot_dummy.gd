extends AnimatedSprite

var walk_speed = rand_range(32.0, 96.0)

func _ready():
	if randf() < 0.5:
		play("walk") 
	else: 
		play("carry")
	
func _process(delta):
	translate(Vector2(0.0, delta * walk_speed))
	if position.y > 350.0:
		position.y = -50.0

extends Area2D

var shooter:Node2D = null
var velocity = Vector2.ZERO

func _ready():
	var _err = connect("body_entered", self, "_on_entered")
	$Trail.emitting = true

func _on_entered(thing):
	if thing != shooter and (thing.collision_layer & collision_mask) > 0:
		$ImpactSounds.play()
		visible = false
		$Trail.emitting = false
		collision_layer = 0
		collision_mask = 0
		#Destroy itself after 0.5 secs
		get_tree().create_timer(0.5).connect("timeout", self, "queue_free")
		
		if thing.has_method("_on_bullet_hit"):
			thing._on_bullet_hit(self)

func _process(delta):
	translate(velocity * delta)

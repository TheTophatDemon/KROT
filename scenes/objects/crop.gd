extends Area2D

const DEBRIS = preload("res://scenes/objects/crop_debris.tscn")
const ANIM_GROW = "grow"
const ANIM_HARVESTED = "harvested"

onready var spr:AnimatedSprite = $AnimatedSprite

export var ripe = false
export var harvested = false
export var random_growth = false #If true, spawns in random stage of growth.

func _ready():
	var _err = connect("body_entered", self, "_on_body_entered")
	_err = spr.connect("animation_finished", self, "_on_animation_finished")
	
	if !ripe:
		spr.play(ANIM_GROW)
		if random_growth:
			spr.frame = randi() % spr.frames.get_frame_count(ANIM_GROW)
		else:
			spr.frame = 0
	else:
		spr.play(ANIM_HARVESTED)
		$AnimationPlayer.play("drop")
	
	
func _on_animation_finished():
	if !ripe and spr.animation == ANIM_GROW:
		#Turn ripe when the last frame is reached
		ripe = true
		spr.play(ANIM_HARVESTED)
	
func _on_body_entered(body):
	if body.get_collision_layer_bit(Globals.COL_BIT_MOLES):
		body.pick_up(self)

func _process(delta):
	pass
			
func destroy():
	var debris = DEBRIS.instance()
	get_parent().add_child(debris)
	debris.global_position = global_position
	queue_free()

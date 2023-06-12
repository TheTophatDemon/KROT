extends Area2D

const DEBRIS = preload("res://scenes/objects/crop_debris.tscn")
const ANIM_GROW = "grow"
const ANIM_HARVESTED = "harvested"

onready var spr:AnimatedSprite = $AnimatedSprite

export var ripe = false
export var harvested = false
export var random_growth = false #If true, spawns in random stage of growth.

var picker_upper = null

func _ready():
	var _err = connect("body_entered", self, "_on_body_entered")
	_err = connect("body_exited", self, "_on_body_exited")
	_err = spr.connect("animation_finished", self, "_on_animation_finished")
	
	if random_growth and randf() < 0.25: ripe = true
	if !ripe:
		spr.play(ANIM_GROW)
		if random_growth:
			spr.frame = (randi() % (spr.frames.get_frame_count(ANIM_GROW)))
		else:
			spr.frame = 0
	else:
		spr.play(ANIM_HARVESTED)
		if has_node("AnimationPlayer"): $AnimationPlayer.play("drop")
	
	
func _on_animation_finished():
	if !ripe and spr.animation == ANIM_GROW:
		#Turn ripe when the last frame is reached
		ripe = true
		spr.play(ANIM_HARVESTED)
	
func _on_body_entered(body):
	if body.get_collision_layer_bit(Globals.COL_BIT_MOLES):
		picker_upper = body
		
func _on_body_exited(body):
	if body == picker_upper:
		picker_upper = null

func _process(delta):
	# Continously probe the actor over the plant to grab it
	# This allows plants to be picked up immediately after eating neighboring plants when they both intersect.
	if is_instance_valid(picker_upper):
		picker_upper.pick_up(self)
			
func destroy():
	var debris = DEBRIS.instance()
	get_parent().add_child(debris)
	debris.global_position = global_position
	queue_free()

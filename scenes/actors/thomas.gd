extends "res://scenes/actors/actor.gd"

const WALK_THRESHOLD = 10.0
const WANDER_RANGE = 1024.0
const SMOKER_DISTANCE = 16.0
const CHUG_INTERVAL = 0.1

onready var smoker = $SmokerAnchor/Smoker
onready var agent = $NavigationAgent2D
onready var chug_sounds = $ChugSounds
onready var killzone = $KillZone

var last_seen_target_pos:Vector2
var target_dist:float = 9999.0
var target_in_sight = false
var wander_timer:float = 0.0
var chug_timer:float = 0.0

func _ready():
	sprite_frames = {
		SpriteDirection.NORTH: preload("res://gfx/thomas_north.res"),
		SpriteDirection.SOUTH: preload("res://gfx/thomas_south.res"),
		SpriteDirection.EAST: preload("res://gfx/thomas_east.res"),
		SpriteDirection.WEST: preload("res://gfx/thomas_west.res")
	}
	
	accel = 1024.0
	friction = 512.0
	max_speed = 192.0

	smoker.emitting = true
	anim_state = "default"
	
	var _err = agent.connect("velocity_computed", self, "_set_nav_velocity")
	
	agent.set_target_location(global_position)
	
func _set_nav_velocity(safe_velocity:Vector2):
	velocity = safe_velocity
	
func _process(delta):
	# Shift the smoke particles from left to right depending on the sprite.
	smoker.global_position = $SmokerAnchor.global_position + \
		Vector2(SPRITE_DIR_VECTORS[sprite_direction].x * SMOKER_DISTANCE, 0.0)
	
	# Change the kill zone depending on sprite direction
	for shape in killzone.get_children():
		if shape.name == SPRITE_DIR_NAMES[sprite_direction]:
			shape.disabled = false
		else:
			shape.disabled = true
	
	# Chug noises
	chug_timer += delta
	if chug_timer > CHUG_INTERVAL:
		chug_timer = 0.0
		chug_sounds.play()
	
	# Wander
	wander_timer -= delta
	if wander_timer <= 0.0 or !agent.is_target_reachable():
		wander_timer = 6.0
		var offset = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)).normalized() * WANDER_RANGE
		agent.set_target_location(global_position + offset)
		
	if !agent.is_target_reached():
		var new_dir = (agent.get_next_location() - global_position).normalized()
		if input != Vector2.ZERO:
			#The change in direction is interpolated to avoid rapidly changing sprite angle
			input = input.slerp(new_dir, 0.5)
		else:
			input = new_dir
	else:
		input = Vector2.ZERO
		
	var walking = (velocity.length_squared() > WALK_THRESHOLD)
	anim_state = "default" if walking else ""
	
#func _input(event):
#	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		agent.set_target_location(get_global_mouse_position())

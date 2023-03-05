extends KinematicBody2D

enum SpriteDirection {
	NORTH, SOUTH, EAST, WEST
}

const SPRITE_DIR_NAMES = {
	SpriteDirection.NORTH: "north",
	SpriteDirection.SOUTH: "south",
	SpriteDirection.EAST: "east",
	SpriteDirection.WEST: "west",
}

const SPRITE_DIR_VECTORS = {
	SpriteDirection.NORTH: Vector2.UP,
	SpriteDirection.SOUTH: Vector2.DOWN,
	SpriteDirection.EAST:  Vector2.RIGHT,
	SpriteDirection.WEST:  Vector2.LEFT,
}

export var sprite_frames = {
	SpriteDirection.NORTH: null,
	SpriteDirection.SOUTH: null,
	SpriteDirection.EAST: null,
	SpriteDirection.WEST: null
}

onready var anim_spr = $AnimatedSprite

var accel:float
var friction:float
var max_speed:float

var facing:Vector2 = Vector2.DOWN
var velocity:Vector2 = Vector2()
var input:Vector2 = Vector2()
var sprite_direction = SpriteDirection.SOUTH

var anim_state:String = "stand"
	
func _process(delta):
	if !is_zero_approx(input.length_squared()):
		facing = facing.slerp(input, 0.5)
		velocity += input * accel * delta
		
	#Apply friction & speed limit
	var old_speed = velocity.length()
	if old_speed > 0:
		var new_speed = clamp(old_speed - friction * delta, 0, max_speed)
		velocity *= new_speed / old_speed
	
	var _res = move_and_slide(velocity)
	
	#Determine sprite angle
	var angle = rad2deg(facing.angle())
	
	if angle > 45 and angle < 135:
		sprite_direction = SpriteDirection.SOUTH
	elif angle >= 135 or angle < -135:
		sprite_direction = SpriteDirection.WEST
	elif angle >= -135 and angle < -45:
		sprite_direction = SpriteDirection.NORTH
	else:
		sprite_direction = SpriteDirection.EAST
		
	#Switch animations
	if anim_spr.frames != sprite_frames[sprite_direction]:
		anim_spr.frames = sprite_frames[sprite_direction]
	if anim_state != anim_spr.animation:
		anim_spr.play(anim_state)

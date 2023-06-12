extends "res://scenes/actors/actor.gd"

const BULLET_PREFAB = preload("res://scenes/objects/bullet.tscn")

const WALK_THRESHOLD = 10.0
const WANDER_RANGE = 256.0
const ALERT_THRESHOLD = 0.5
const HALF_FOV = deg2rad(90.0)
const SIGHT_LENGTH = 192.0
const SHOOT_DISTANCE = 160.0 #Distance to target required to begin shooting
const BULLET_SPEED = 192.0
const BULLET_DISTANCE = 16.0 #Distance from the eyes that the bullets spawn at
const STUMBLE_TIME = 0.5

enum State {
	WANDER,
	ALERT,
	HUNT,
	SHOOT,
	STUMBLE
}

onready var agent = $NavigationAgent2D
onready var sight = $Sight
onready var exclam_anim = $Exclamation/AnimationPlayer
onready var vis_detector = $VisibilityNotifier2D

onready var alert_sound = $AlertSound
onready var gun_sounds = $GunSounds
onready var hurt_sounds = $HurtSounds

var state = State.WANDER
var wander_timer:float = 0.0
var alert:float = 0.0 #Timer from first sight until the farmer starts hunting the player
var shoot_timer:float = 0.0
var last_seen_target_pos:Vector2
var target_dist:float = 9999.0
var target_in_sight = false
var stumble_timer:float = 0.0

func _ready():
	sprite_frames = {
		SpriteDirection.NORTH: preload("res://gfx/farmer_north.res"),
		SpriteDirection.SOUTH: preload("res://gfx/farmer_south.res"),
		SpriteDirection.EAST: preload("res://gfx/farmer_east.res"),
		SpriteDirection.WEST: preload("res://gfx/farmer_west.res")
	}
	
	accel = 2048.0
	friction = 512.0
	max_speed = 96.0
	
	var _err = agent.connect("velocity_computed", self, "_set_nav_velocity")
	_err = exclam_anim.connect("animation_finished", self, "_on_animation_finished", [exclam_anim])
	_err = anim_spr.connect("animation_finished", self, "_on_animation_finished", ["", null])
	
	agent.set_target_location(global_position)
	
func _set_nav_velocity(safe_velocity:Vector2):
	velocity = safe_velocity
	
func _on_animation_finished(anim_name:String, anim_player:AnimationPlayer):
	if anim_player == exclam_anim and anim_name == "fade_in":
		change_state(State.HUNT)
	elif anim_player == null:
		if state == State.SHOOT and anim_state == "shoot":
			change_state(State.HUNT)
			
func _on_bullet_hit(bullet):
	if bullet.shooter != self:
		change_state(State.STUMBLE)
		stumble_timer = STUMBLE_TIME
		
# Called when the player attempts to dig out of the ground while underneath this farmer
func _on_dug_under():
	change_state(State.STUMBLE)
	stumble_timer = STUMBLE_TIME
	
func _on_killzone_enter(_killzone):
	change_state(State.STUMBLE)
	stumble_timer = STUMBLE_TIME
			
func shoot():
	gun_sounds.play()
	var spread = rand_range(PI / 16.0, PI / 8.0)
	for i in [-1, 0, 1]:
		var bullet = BULLET_PREFAB.instance()
		get_parent().add_child(bullet)
		bullet.global_position = $Shooter.global_position + SPRITE_DIR_VECTORS[sprite_direction] * BULLET_DISTANCE
		bullet.velocity = sight.cast_to.rotated(spread  * i).normalized() * BULLET_SPEED
		bullet.shooter = self
	
func change_state(new_state:int):
	
	match new_state:
		State.STUMBLE:
			input = Vector2.ZERO
			velocity = Vector2.ZERO
			hurt_sounds.play()
		State.ALERT:
			input = Vector2.ZERO
			exclam_anim.play("fade_in")
			alert_sound.play()
		State.SHOOT:
			input = Vector2.ZERO
	
	state = new_state
	
func pursue_target(delta):
	if !agent.is_target_reached():
		var new_dir = (agent.get_next_location() - global_position).normalized()
		if input != Vector2.ZERO:
			#The change in direction is interpolated to avoid rapidly changing sprite angle
			input = input.slerp(new_dir, 0.5)
		else:
			input = new_dir
	else:
		input = Vector2.ZERO
	
func _process(delta):
	#Align sight to the player
	var player = get_tree().get_nodes_in_group(Globals.GROUP_PLAYERS)[0]
	target_in_sight = false	
	if !player.is_dead() and player.get_collision_layer_bit(Globals.COL_BIT_SURFACE):
		var diff = ((player.global_position + Vector2.UP * 16.0) - sight.global_position)
		target_dist = diff.length()
		var in_fov = abs(diff.angle_to(SPRITE_DIR_VECTORS[sprite_direction])) < HALF_FOV
		if (in_fov or target_dist < 32.0 or state == State.HUNT) and target_dist > 0.0:
			sight.cast_to = SIGHT_LENGTH * diff / target_dist
			sight.enabled = true
			last_seen_target_pos = player.global_position
			if state == State.HUNT and target_dist < SIGHT_LENGTH:
				agent.set_target_location(last_seen_target_pos)
			facing = diff / target_dist
			if sight.is_colliding() and sight.get_collider().get_collision_layer_bit(Globals.COL_BIT_SURFACE):
				target_in_sight = true
		else:
			sight.enabled = false
		
	match state:
		State.WANDER:
			pursue_target(delta)
			wander_timer -= delta
			if wander_timer <= 0.0 or !agent.is_target_reachable():
				wander_timer = rand_range(2.0, 6.0)
				var offset = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)).normalized() * rand_range(1.0, WANDER_RANGE)
				agent.set_target_location(global_position + offset)
			if target_in_sight:
				alert += delta
				if alert > ALERT_THRESHOLD:
					change_state(State.ALERT)
			else:
				alert = max(0.0, alert - delta)
		State.STUMBLE:
			stumble_timer -= delta
			if stumble_timer <= 0:
				stumble_timer = 0.0
				change_state(State.HUNT)
		State.HUNT:
			pursue_target(delta)
			if target_dist < SHOOT_DISTANCE:
				shoot_timer -= delta
				if shoot_timer < 0.0 and target_in_sight and vis_detector.is_on_screen():
					shoot_timer = rand_range(1.0, 2.0)
					change_state(State.SHOOT)
					#Shoot bullets after some time
					var _err = get_tree().create_timer(0.5).connect("timeout", self, "shoot")
			if agent.is_target_reached():
				alert = max(0.0, alert - delta)
				if alert <= 0.0:
					change_state(State.WANDER)
			else:
				alert = ALERT_THRESHOLD
	
	#Animation states
	match state:
		State.SHOOT:
			anim_state = "shoot"
		State.STUMBLE:
			anim_state = "stumble"
		_:
			var walking = (velocity.length_squared() > WALK_THRESHOLD)
			anim_state = "walk" if walking else "stand"
	
func _physics_process(_delta):
	agent.set_velocity(velocity)
	
#func _input(event):
#	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		agent.set_target_location(get_global_mouse_position())

extends "res://scenes/actors/actor.gd"

const CROP_PREFAB = preload("res://scenes/objects/crop_dropped.tscn")

const WALK_THRESHOLD = 10.0
const DIG_SOUND_FREQ = [0.1, 0.1] #Min, max
const DIVE_TIME = 0.25
const EAT_TIME = 1.5
const HUNGER_RATE = 1.0 / 60.0
const HUNGER_DECREASE_RATE = 4.0 / 60.0 #The amount that hunger decreases after eating
const OVERGROUND_WALK_SPEED = 160.0
const UNDERGROUND_WALK_SPEED = 128.0

signal die()
signal deposited_crop()
signal movement()
signal eat()
signal dive()

onready var dig_particles = $DigParticles
onready var mound_particles = $MoundParticles
onready var dig_sounds = $DigSounds
onready var dive_sounds = $DiveSounds
onready var harvest_sound = $HarvestSound
onready var eat_sound = $EatSound
onready var eat_particles = $EatParticles
onready var die_sound = $DieSound

enum State {
	DEFAULT,
	UNDERGROUND,
	CARRYING,
	EATING,
	DYING
}

var diving = false
var state = State.DEFAULT

var dig_sound_timer = 0.0

#The player dies when this reaches 1.0
var hunger:float = 0.25 
var god_mode = false

var score:int = 0
var life_time:float = 0.0

var dive_check_shape:Shape2D

func _ready():
	sprite_frames = {
		SpriteDirection.NORTH: preload("res://gfx/krot_north.res"),
		SpriteDirection.SOUTH: preload("res://gfx/krot_south.res"),
		SpriteDirection.EAST: preload("res://gfx/krot_east.res"),
		SpriteDirection.WEST: preload("res://gfx/krot_west.res")
	}
	
	# The shape used to detect if something above ground is preventing us from emerging.
	dive_check_shape = CircleShape2D.new()
	# Slightly larger than the player's radius in order to prevent clipping bugs.
	dive_check_shape.radius = 11
	
	accel = 2048.0
	friction = 512.0
	max_speed = OVERGROUND_WALK_SPEED
	
	var _err = anim_spr.connect("animation_finished", self, "_on_anim_finished")
	
func _on_anim_finished():
	if anim_spr.animation.begins_with("dive_"):
		pass
		
func end_dive():
	diving = false
	mound_particles.emitting = false
	if state == State.UNDERGROUND:
		change_state(State.DEFAULT)
	else:
		change_state(State.UNDERGROUND)
	dig_particles.emitting = false
	
#Picks up the given crop.
func pick_up(crop):
	if crop.ripe and !diving and state == State.DEFAULT:
		change_state(State.CARRYING)
		harvest_sound.play()
		crop.queue_free()
	elif state == State.UNDERGROUND and !crop.harvested:
		crop.destroy()
		
func _on_bullet_hit(_bullet):
	if !god_mode and !diving:
		change_state(State.DYING)
		
func start_eating():
	eat_sound.play()
	eat_particles.emitting = true
	#Put particles in correct position relative to the body
	anim_spr.z_index = 1 if sprite_direction == SpriteDirection.NORTH else 0
	eat_particles.position = Vector2(0.0, -16.0) + SPRITE_DIR_VECTORS[sprite_direction] * 8.0
	#Change state back later
	var _err = get_tree().create_timer(EAT_TIME).connect("timeout", self, "change_state", [State.DEFAULT])
		
func change_state(new_state:int):
	if new_state != state:
		#Transition out of old state
		match state:
			State.EATING:
				eat_particles.emitting = false
			State.UNDERGROUND:
				max_speed = OVERGROUND_WALK_SPEED
		#Transition into new state
		match new_state:
			State.EATING: start_eating()
			State.DYING:
				anim_spr.play("die")
				die_sound.play()
				emit_signal("die")
				collision_layer = 0
				collision_mask = 0
				anim_spr.z_index = -1
			State.DEFAULT:
				anim_spr.visible = true
				set_collision_layer_bit(Globals.COL_BIT_SURFACE, true)
				set_collision_mask_bit(Globals.COL_BIT_HUMANS, true)
				set_collision_mask_bit(Globals.COL_BIT_SOLIDS, true)
			State.UNDERGROUND:
				anim_spr.visible = false
				set_collision_layer_bit(Globals.COL_BIT_SURFACE, false)
				set_collision_mask_bit(Globals.COL_BIT_HUMANS, false)
				set_collision_mask_bit(Globals.COL_BIT_SOLIDS, false)
				max_speed = UNDERGROUND_WALK_SPEED
				
	if state != State.DYING: #Nobody can escape death.
		state = new_state
	
func _process(delta):
	#Process hunger
	if !god_mode:
		if state == State.EATING:
			hunger = max(0.0, hunger - delta * HUNGER_DECREASE_RATE)
		elif state != State.DYING:
			hunger += delta * HUNGER_RATE
			if hunger >= 1.0:
				hunger = 1.0
				change_state(State.DYING)
	else:
		hunger = 0.0
	
	life_time += delta
	
	if state != State.DYING:
		#Diving in and out of underground
		if Input.is_action_just_pressed("dive") and not diving and state != State.EATING: 
			var can_dive = true
			if state == State.UNDERGROUND:
				#Check if there is a farmer above the player
				var space_state = get_world_2d().direct_space_state
				
				var params = Physics2DShapeQueryParameters.new()
				params.shape_rid = dive_check_shape
				params.collide_with_bodies = true
				params.collision_layer = (1 << Globals.COL_BIT_HUMANS) | (1 << Globals.COL_BIT_SOLIDS)
				params.transform = $CollisionShape2D.global_transform
				var intersecting_objs = space_state.intersect_shape(params)
				
				#Stun farmers
				for result in intersecting_objs:
					can_dive = false
					var obj = result["collider"]
					if obj.has_method("_on_dug_under"):
						obj._on_dug_under()
			
			if can_dive:
				diving = true
				anim_spr.visible = true
				dive_sounds.play()
				mound_particles.emitting = true
				emit_signal("dive")
				
				if state == State.CARRYING:
					#Drop the crop
					var crop = CROP_PREFAB.instance()
					get_parent().add_child(crop)
					crop.global_position = global_position
					crop.rotate(randf() * PI * 2.0)
				
				#Finish the dive after a time
				var _err = get_tree().create_timer(DIVE_TIME).connect("timeout", self, "end_dive")
			
		#Eating
		if Input.is_action_pressed("eat") and state == State.CARRYING:
			emit_signal("eat")
			change_state(State.EATING)
	
	#Movement input
	match state:
		State.DEFAULT, State.CARRYING, State.UNDERGROUND:
			input = Vector2(
				(Input.get_action_strength("walk_east")) - (Input.get_action_strength("walk_west")),
				(Input.get_action_strength("walk_south")) - (Input.get_action_strength("walk_north"))
			).normalized()
			if input.length_squared() > 0.0:
				emit_signal("movement")
		_:
			input = Vector2.ZERO
	
	#Animation states
	var walking = (velocity.length_squared() > WALK_THRESHOLD)
	
	match state:
		State.EATING:
			anim_state = "eat"
			mound_particles.emitting = false
		State.DYING:
			anim_state = "die"
			mound_particles.emitting = false
		State.DEFAULT:
			anim_state = "walk" if walking else "stand"
			mound_particles.emitting = false
		State.CARRYING:
			anim_state = "carry" if walking else "hold"
			mound_particles.emitting = false
		State.UNDERGROUND:
			if walking:
				mound_particles.emitting = true
				dig_sound_timer -= delta
				if dig_sound_timer < 0.0:
					dig_sound_timer = rand_range(DIG_SOUND_FREQ[0], DIG_SOUND_FREQ[1])
					dig_sounds.play()
			else:
				mound_particles.emitting = false
	if diving:
		anim_state = "dive"
		dig_particles.emitting = true

func is_carrying():
	return state == State.CARRYING
	
func is_dead():
	return state == State.DYING
	
func deposit_crop():
	if state == State.CARRYING:
		change_state(State.DEFAULT)
		emit_signal("deposited_crop")
		score += 1

func _input(event):
	if event.is_action_pressed("cheat"):
		god_mode = !god_mode
		if god_mode:
			anim_spr.modulate = Color.yellow
		else:
			anim_spr.modulate = Color.white

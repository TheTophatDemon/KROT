extends Control

const STATS_TEMPLATE = \
"[center]Score: %s\n" + \
"[color=#FFFF00](Best: %s)[/color]\n" + \
"Time: %s seconds\n" + \
"[color=#FFFF00](Best: %s)[/color][/center]"

onready var hunger_meter = $HungerMeter
onready var hunger_meter_anim = hunger_meter.get_node("AnimationPlayer")

onready var death_msg = $DeathMessage
onready var pause_msg = $PauseMessage
onready var guides = $Guides
onready var world = get_node("/root/World")


var player = null

func _ready():
	death_msg.modulate.a = 0.0
	death_msg.visible = true
	pause_msg.visible = false
	var _err = death_msg.get_node("AnimationPlayer").connect("animation_finished", self, "_on_death_animation_finished")
	player = get_node("%Krot")
	_err = player.connect("die", self, "_on_player_death")
	rect_size = get_viewport_rect().size / 2.0
	rect_position = get_viewport_rect().position - rect_size / 2.0
	hunger_meter.visible = true
	
	if Globals.first_game:
		guides.visible = true
		start_tutorial()
		Globals.first_game = false
	else:
		guides.visible = false

func start_tutorial():
	var guides_anim = $Guides/AnimationPlayer
	guides_anim.play("1_guide_movement")
	yield(player, "movement")
	guides_anim.play("2_guide_eating")
	yield(player, "eat")
	guides_anim.play("3_guide_diving")
	yield(player, "dive")
	yield(player, "dive")
	guides_anim.play("4_guide_scoring")
	yield(player, "deposited_crop")
	guides_anim.play("5_guide_end")

func _on_death_animation_finished(_anim:String):
	get_tree().paused = false
	world.end_game()
	
func _process(delta):
	
	if is_instance_valid(player):
		# Set the hunger meter
		hunger_meter.value = 1.0 - player.hunger
		# Fade out the tutorial if the player is already scoring.
		if player.score >= 2:
			guides.modulate.a -= delta * 2.0
			if guides.modulate.a <= 0.0:
				guides.visible = false
			
	# Flash the hunger meter when it is low
	if hunger_meter.value < 0.25:
		hunger_meter_anim.play("flash")
	else:
		hunger_meter_anim.play("default")
	
func _on_player_death():
	death_msg.get_node("AnimationPlayer").play("fade_in")
	death_msg.get_node("Stats").bbcode_text = \
		STATS_TEMPLATE % [player.score, world.high_score, floor(player.life_time), world.best_time]
	get_tree().paused = false
	pause_msg.visible = false
	
func _input(event):
	if event.is_action_pressed("ui_accept") and !death_msg.get_node("AnimationPlayer").is_playing():
		# Pause the game.
		get_tree().paused = !get_tree().paused
		pause_msg.visible = get_tree().paused

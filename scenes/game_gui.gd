extends Control

const STATS_TEMPLATE = \
"[center]Score: %s\n" + \
"[color=#FFFF00](Best: %s)[/color]\n" + \
"Time: %s seconds\n" + \
"[color=#FFFF00](Best: %s)[/color][/center]"

onready var hunger_meter = $HungerMeter
onready var hunger_meter_anim = hunger_meter.get_node("AnimationPlayer")

onready var death_msg = $DeathMessage
onready var world = get_node("/root/World")

var player = null

func _ready():
	death_msg.modulate.a = 0.0
	var _err = death_msg.get_node("AnimationPlayer").connect("animation_finished", self, "_on_death_animation_finished")
	player = get_node("%Krot")
	_err = player.connect("die", self, "_on_player_death")

func _on_death_animation_finished(_anim:String):
	world.end_game()
	
func _process(delta):
	if is_instance_valid(player):
		hunger_meter.value = 1.0 - player.hunger
	if hunger_meter.value < 0.25:
		hunger_meter_anim.play("flash")
	else:
		hunger_meter_anim.play("default")
	
func _on_player_death():
	death_msg.get_node("AnimationPlayer").play("fade_in")
	death_msg.get_node("Stats").bbcode_text = \
		STATS_TEMPLATE % [player.score, world.high_score, floor(player.life_time), world.best_time]
	rect_size = get_viewport_rect().size / 2.0
	rect_position = get_viewport_rect().position - rect_size / 2.0

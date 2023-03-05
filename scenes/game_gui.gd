extends Control

var hunger_value:float = 0.0

onready var hunger_meter = $HungerMeter
onready var hunger_meter_anim = hunger_meter.get_node("AnimationPlayer")

onready var death_msg = $DeathMessage

func _ready():
	death_msg.modulate.a = 0.0
	var _err = death_msg.get_node("AnimationPlayer").connect("animation_finished", self, "_on_death_animation_finished")

func _on_death_animation_finished(_anim:String):
	get_tree().change_scene("res://scenes/title.tscn")
	
func _on_player_death():
	death_msg.get_node("AnimationPlayer").play("fade_in")

func _process(_delta):
	rect_size = get_viewport_rect().size / 2.0
	rect_position = get_viewport_rect().position - rect_size / 2.0
	
	hunger_meter.value = 1.0 - hunger_value
	if hunger_meter.value < 0.25:
		hunger_meter_anim.play("flash")
	else:
		hunger_meter_anim.play("default")

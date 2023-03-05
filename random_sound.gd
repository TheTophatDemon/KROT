extends Node2D

export var pitch_scale_min = 0.9
export var pitch_scale_max = 1.1

#Plays one of the child node AudioPlayers at random

func play():
	var index = randi() % get_child_count()
	var sound = get_child(index)
	sound.pitch_scale = rand_range(pitch_scale_min, pitch_scale_max)
	sound.play()

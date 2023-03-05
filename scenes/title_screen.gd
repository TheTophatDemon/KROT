extends Control
	
func start_game():
	get_tree().change_scene("res://scenes/game.tscn")
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
			start_game()

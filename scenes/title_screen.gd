extends Control
	
func _ready():
	$RichTextLabel.bbcode_text = tr("ENTER")
	
func start_game():
	get_tree().change_scene("res://scenes/game.tscn")
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
			start_game()
	if event.is_action_pressed("walk_east"):
		TranslationServer.set_locale("ru")
		$RichTextLabel.bbcode_text = tr("ENTER")
	elif event.is_action_pressed("walk_west"):
		TranslationServer.set_locale("en")
		$RichTextLabel.bbcode_text = tr("ENTER")

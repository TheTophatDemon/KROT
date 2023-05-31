extends Control
	
func _ready():
	$Blinker.play("blink")
	$PressStart.bbcode_text = tr("ENTER")
	$English.visible = false
	$Russian.visible = true
	
func start_game():
	get_tree().change_scene("res://scenes/game.tscn")
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
			start_game()
	if event.is_action_pressed("russian"):
		TranslationServer.set_locale("ru")
		$English.visible = true
		$Russian.visible = false
	elif event.is_action_pressed("english"):
		TranslationServer.set_locale("en")
		$Russian.visible = true
		$English.visible = false
	$PressStart.bbcode_text = tr("ENTER")

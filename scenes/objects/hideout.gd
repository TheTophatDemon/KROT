extends Area2D

export var player_path:NodePath

onready var player = get_node(player_path)
onready var arrow = $Arrow
onready var score = $ScoreParent/Score
onready var particles = $Particles
onready var score_sound = $ScoreSound

func _ready():
	arrow.visible = false
	arrow.get_node("AnimationPlayer").play("bounce")
	
	score.visible = false
	
	var _err = connect("body_entered", self, "_on_body_entered")
	
func _process(delta):
	if is_instance_valid(player):
		if player.is_carrying():
			arrow.visible = true
		else:
			arrow.visible = false

func _on_body_entered(body):
	if is_instance_valid(player) and body.name == player.name and player.is_carrying():
		player.deposit_crop()
		particles.emitting = true
		score.visible = true
		score.text = "%s: %s" % [tr("SCORE"), player.score]
		score.get_node("AnimationPlayer").play("appear")
		score_sound.play()

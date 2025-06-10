extends Control
@export var text_tutorial: String = "Sample tutorial text"
@export var autorun: bool = true

func _ready():
	$NinePatchRect/CenterContainer/TutorialText.text = text_tutorial
	
	if autorun:
		$AnimationPlayer.play("Appear")
	else:
		visible = false
		

func _on_Timer_timeout():
	$AnimationPlayer.play("Disappear")


func run():
	$AnimationPlayer.play("Appear")
	$Timer.start()
	# visible = true

func turn_on_visible():
	visible = true
	

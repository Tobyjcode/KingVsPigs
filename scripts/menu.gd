extends Control

func _ready():
	# Corrected paths to the buttons after menu redesign
	$Panel/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed():
	# Quit the game
	get_tree().quit() 

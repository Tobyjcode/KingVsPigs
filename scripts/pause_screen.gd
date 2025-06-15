extends Control

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var back_to_menu_button = $VBoxContainer/BackToMenuButton

func _ready():
	print("PauseScreen ready, connecting signals...")
	resume_button.pressed.connect(_on_resume_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	visible = false

func _on_resume_pressed():
	print("Resume button pressed!")
	visible = false
	get_tree().paused = false

func _on_back_to_menu_pressed():
	print("Back to Menu button pressed!")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

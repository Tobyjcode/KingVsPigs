extends Node2D

@onready var start_door = $door2  # Use the correct name for your start door node
@onready var player: CharacterBody2D = $Player  # Use the correct name for your player node
@onready var pause_screen: Control = $PauseScreen

const DOOR = preload("res://scenes/door.tscn")
const PLAYER = preload("res://scenes/player.tscn")

func _ready():
	if start_door.is_start_door:
		player.global_position = start_door.global_position  # Move player to start door
		start_door.connect("start_door_opened", Callable(player, "play_door_out"))
		start_door.start_open_sequence()

	# Make buttons more visible when focused
	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	focus_style.border_width_left = 2
	focus_style.border_width_top = 2
	focus_style.border_width_right = 2
	focus_style.border_width_bottom = 2
	focus_style.border_color = Color(1, 1, 1, 0.8)
	
	pause_screen.get_node("VBoxContainer/ResumeButton").add_theme_stylebox_override("focus", focus_style)
	pause_screen.get_node("VBoxContainer/BackToMenuButton").add_theme_stylebox_override("focus", focus_style)
	
	# Set initial focus
	pause_screen.get_node("VBoxContainer/ResumeButton").grab_focus()

func _input(event):
	if event.is_action_pressed("pause"):
		if pause_screen.visible:
			# If pause screen is visible, resume the game
			pause_screen.visible = false
			get_tree().paused = false
		else:
			# If pause screen is not visible, pause the game
			pause_screen.visible = true
			get_tree().paused = true

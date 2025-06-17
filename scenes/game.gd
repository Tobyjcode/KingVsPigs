extends Node2D

@onready var start_door = $door2  # Use the correct name for your start door node
@onready var player: CharacterBody2D = $Player  # Use the correct name for your player node
@onready var pause_screen: Control = $PauseScreen
@onready var mobile_integration = preload("res://scripts/mobile_integration.gd").new()

const DOOR = preload("res://scenes/door.tscn")
const PLAYER = preload("res://scenes/player.tscn")

func _ready():
	add_child(mobile_integration)
	if start_door.is_start_door:
		player.global_position = start_door.global_position  # Move player to start door
		start_door.connect("start_door_opened", Callable(player, "play_door_out"))
		start_door.start_open_sequence()
	var mobile_controls = get_node_or_null("MobileControls")
	if mobile_controls:
		var should_show = OS.has_feature("mobile") or OS.has_feature("web") or OS.get_name() == "Android"
		mobile_controls.visible = should_show
		print("MobileControls visible:", should_show, "| Platform:", OS.get_name())

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
			# Set up focus style and grab focus when pause screen becomes visible
			setup_pause_screen_focus()

func setup_pause_screen_focus():
	# Create focus style
	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	focus_style.border_width_left = 2
	focus_style.border_width_top = 2
	focus_style.border_width_right = 2
	focus_style.border_width_bottom = 2
	focus_style.border_color = Color(1, 1, 1, 0.8)
	
	# Get buttons
	var resume_button = pause_screen.get_node("VBoxContainer/ResumeButton")
	var back_to_menu_button = pause_screen.get_node("VBoxContainer/BackToMenuButton")
	
	# Set up focus mode
	resume_button.focus_mode = Control.FOCUS_ALL
	back_to_menu_button.focus_mode = Control.FOCUS_ALL
	
	# Apply focus style
	resume_button.add_theme_stylebox_override("focus", focus_style)
	back_to_menu_button.add_theme_stylebox_override("focus", focus_style)
	
	# Set up focus navigation
	resume_button.focus_neighbor_top = back_to_menu_button.get_path()
	resume_button.focus_neighbor_bottom = back_to_menu_button.get_path()
	back_to_menu_button.focus_neighbor_top = resume_button.get_path()
	back_to_menu_button.focus_neighbor_bottom = resume_button.get_path()
	
	# Set initial focus
	resume_button.grab_focus()

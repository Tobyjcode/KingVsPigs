extends Control

@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var time_label = $Panel/VBoxContainer/TimeLabel
@onready var menu_button = $Panel/VBoxContainer/MenuButton
@onready var feedback_button = $Panel/VBoxContainer/NextLevelButton
@onready var audio_player = $AudioStreamPlayer
@onready var victory = get_node_or_null("Victory")
@onready var total_time_label = $Panel/VBoxContainer/TotalTimeLabel

func _ready():
	# Set up focus style
	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	focus_style.border_width_left = 2
	focus_style.border_width_top = 2
	focus_style.border_width_right = 2
	focus_style.border_width_bottom = 2
	focus_style.border_color = Color(1, 1, 1, 0.8)
	
	# Set up buttons
	menu_button.focus_mode = Control.FOCUS_ALL
	feedback_button.focus_mode = Control.FOCUS_ALL
	
	# Apply focus style
	menu_button.add_theme_stylebox_override("focus", focus_style)
	feedback_button.add_theme_stylebox_override("focus", focus_style)
	
	# Set up focus navigation
	menu_button.focus_neighbor_top = feedback_button.get_path()
	menu_button.focus_neighbor_bottom = feedback_button.get_path()
	feedback_button.focus_neighbor_top = menu_button.get_path()
	feedback_button.focus_neighbor_bottom = menu_button.get_path()
	
	# Set initial focus
	menu_button.grab_focus()
	
	# Display score and time from Globals
	score_label.text = "Score: " + str(Globals.diamond_score)
	time_label.text = "Time: " + str(snapped(Globals.level_time, 0.01)) + " seconds"
	var total_time = "Total Time: " + str(snapped(Globals.total_level_time, 0.01)) + " seconds"
	total_time_label.text = "Total Time: " + str(snapped(Globals.total_level_time, 0.01)) + " seconds"

	# Play victory sound
	audio_player.play()

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_next_level_button_pressed():
	get_tree().change_scene_to_file("res://scenes/survey.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if menu_button.has_focus():
			_on_menu_button_pressed()
		elif feedback_button.has_focus():
			_on_next_level_button_pressed() 

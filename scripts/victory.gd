extends Control

@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var time_label = $Panel/VBoxContainer/TimeLabel
@onready var menu_button = $Panel/VBoxContainer/MenuButton
@onready var feedback_button = $Panel/VBoxContainer/NextLevelButton
@onready var audio_player = $AudioStreamPlayer
@onready var victory: AudioStreamPlayer2D = $Victory

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
	
	# Display score and time
	var score_manager = get_node_or_null("/root/ScoreManager")
	if score_manager:
		var score = score_manager.get_score()
		var time = score_manager.get_time()
		score_label.text = "Score: " + str(score)
		time_label.text = "Time: " + str(time) + " seconds"
	else:
		score_label.text = "Score: N/A"
		time_label.text = "Time: N/A"

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

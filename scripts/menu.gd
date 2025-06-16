extends Control

@onready var start_button = $Panel/VBoxContainer/StartButton
@onready var highscores_button = $Panel/VBoxContainer/HighscoresButton
@onready var survey_button = $Panel/VBoxContainer/SurveyButton
@onready var options_button = $Panel/VBoxContainer/OptionsButton
@onready var admin_button = $Panel/VBoxContainer/AdminButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton

var feedback_timer: Timer = null

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	highscores_button.pressed.connect(_on_highscores_pressed)
	survey_button.pressed.connect(_on_survey_pressed)
	options_button.pressed.connect(_on_options_pressed)
	admin_button.pressed.connect(_on_admin_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Make buttons more touch-friendly
	var buttons = [start_button, highscores_button, survey_button, 
				  options_button, admin_button, quit_button]
	
	for button in buttons:
		# Add touch feedback
		button.pressed.connect(_on_button_pressed.bind(button))
		button.button_up.connect(_on_button_released.bind(button))
		
		# Enable focus and hover for all platforms
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_entered.connect(_on_button_focus_entered.bind(button))
		button.mouse_exited.connect(_on_button_focus_exited.bind(button))
		
		# Create and apply focus style
		var focus_style = StyleBoxFlat.new()
		focus_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		focus_style.border_width_left = 2
		focus_style.border_width_top = 2
		focus_style.border_width_right = 2
		focus_style.border_width_bottom = 2
		focus_style.border_color = Color(1, 1, 1, 0.8)
		button.add_theme_stylebox_override("focus", focus_style)
	
	# Set initial focus to start button
	start_button.grab_focus()

func _input(event):
	# Handle keyboard navigation for all platforms
	if event.is_action_pressed("ui_accept"):
		if start_button.has_focus():
			_on_start_pressed()
		elif highscores_button.has_focus():
			_on_highscores_pressed()
		elif survey_button.has_focus():
			_on_survey_pressed()
		elif options_button.has_focus():
			_on_options_pressed()
		elif admin_button.has_focus():
			_on_admin_pressed()
		elif quit_button.has_focus():
			_on_quit_pressed()

func _on_button_pressed(button):
	# Visual feedback when button is pressed
	button.modulate = Color(0.8, 0.8, 0.8)  # Darken the button

func _on_button_released(button):
	# Reset button appearance
	button.modulate = Color(1, 1, 1)

func _on_button_focus_entered(button):
	button.modulate = Color(1.2, 1.2, 1.2)

func _on_button_focus_exited(button):
	button.modulate = Color(1, 1, 1)

func _on_start_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_highscores_pressed():
	# Change to the highscores scene
	get_tree().change_scene_to_file("res://scenes/highscore_ui.tscn")

func _on_survey_pressed():
	# Change to the survey scene
	get_tree().change_scene_to_file("res://scenes/survey.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func get_user_id():
	if Engine.has_singleton("FirebaseAuth"):
		var auth = Engine.get_singleton("FirebaseAuth")
		if auth.is_logged_in():
			return auth.get_user_id()
	return ""

func show_feedback(message: String, is_error: bool = false):
	if $Panel/VBoxContainer.has_node("FeedbackLabel"):
		$Panel/VBoxContainer/FeedbackLabel.text = message
		if is_error:
			$Panel/VBoxContainer/FeedbackLabel.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		else:
			$Panel/VBoxContainer/FeedbackLabel.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
		# Clear any previous timer
		if feedback_timer:
			feedback_timer.stop()
			feedback_timer.queue_free()
		# Add a timer to clear the message
		feedback_timer = Timer.new()
		feedback_timer.one_shot = true
		feedback_timer.wait_time = 2.0
		feedback_timer.timeout.connect(func():
			$Panel/VBoxContainer/FeedbackLabel.text = ""
			feedback_timer.queue_free()
			feedback_timer = null
		)
		add_child(feedback_timer)
		feedback_timer.start()
	else:
		print(message)

func is_admin(user_id, callback):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/admins/%s.json" % user_id
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_result, response_code, _headers, body):
			var is_admin = response_code == 200 and body.get_string_from_utf8().strip_edges() == "true"
			callback.call(is_admin)
			http.queue_free()
	)
	http.request(url)

func _on_admin_pressed():
	var user_id = get_user_id()
	is_admin(user_id, func(is_admin):
		# Always open the admin survey viewer scene.
		# The scene itself will check if the user is a Firebase admin and skip the code entry if so.
		get_tree().change_scene_to_file("res://scenes/admin_survey_viewer.tscn")
	)

func _on_quit_pressed():
	# Quit the game
	get_tree().quit() 

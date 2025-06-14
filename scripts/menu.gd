extends Control

@onready var start_button = $Panel/VBoxContainer/StartButton
@onready var survey_button = $Panel/VBoxContainer/SurveyButton
@onready var options_button = $Panel/VBoxContainer/OptionsButton
@onready var admin_button = $Panel/VBoxContainer/AdminButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton

var feedback_timer: Timer = null

func _ready():
	# Corrected paths to the buttons after menu redesign
	start_button.pressed.connect(_on_start_pressed)
	survey_button.pressed.connect(_on_survey_pressed)
	options_button.pressed.connect(_on_options_pressed)
	admin_button.pressed.connect(_on_admin_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")

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
		if is_admin:
			get_tree().change_scene_to_file("res://scenes/admin_survey_viewer.tscn")
		else:
			show_feedback("Sorry, this section is for admins only.", true)
	)

func _on_quit_pressed():
	# Quit the game
	get_tree().quit() 

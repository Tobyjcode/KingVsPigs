extends Control

@onready var http = $HTTPRequest
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel
@onready var rating_slider = $Panel/VBoxContainer/RatingContainer/RatingSlider
@onready var rating_value_label = $Panel/VBoxContainer/RatingContainer/RatingValueLabel
@onready var most_enjoyed_comment = $Panel/VBoxContainer/MostEnjoyedComment
@onready var least_enjoyed_comment = $Panel/VBoxContainer/LeastEnjoyedComment
@onready var controls_option = $Panel/VBoxContainer/ControlsOption
@onready var clarity_option = $Panel/VBoxContainer/ClarityOption
@onready var difficulty_option = $Panel/VBoxContainer/DifficultyOption
@onready var bugs_comment = $Panel/VBoxContainer/BugsComment
@onready var visual_audio_option = $Panel/VBoxContainer/VisualAudioOption
@onready var game_types_comment = $Panel/VBoxContainer/GameTypesComment
@onready var improvements_comment = $Panel/VBoxContainer/ImprovementsComment
@onready var submit_button = $Panel/VBoxContainer/ButtonContainer/SubmitButton
@onready var back_button = $Panel/VBoxContainer/ButtonContainer/BackButton

var firebase_api_key = "AIzaSyCmdy8DSoDesCFhX9hb3lO9Qseq-STnEWg"
var redirect_timer = Timer.new()

func _ready():
	await get_tree().process_frame

	# Populate OptionButtons
	controls_option.clear()
	controls_option.add_item("Very intuitive")
	controls_option.add_item("Somewhat intuitive")
	controls_option.add_item("Not intuitive")

	clarity_option.clear()
	clarity_option.add_item("Always")
	clarity_option.add_item("Most of the time")
	clarity_option.add_item("Sometimes")
	clarity_option.add_item("Rarely")

	difficulty_option.clear()
	difficulty_option.add_item("Too easy")
	difficulty_option.add_item("Just right")
	difficulty_option.add_item("Too hard")

	visual_audio_option.clear()
	visual_audio_option.add_item("Excellent")
	visual_audio_option.add_item("Good")
	visual_audio_option.add_item("Average")
	visual_audio_option.add_item("Poor")

	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if rating_slider:
		rating_slider.value_changed.connect(_on_rating_changed)

	add_child(redirect_timer)
	redirect_timer.one_shot = true
	redirect_timer.timeout.connect(_on_redirect_timer_timeout)

	# Initialize rating label
	if rating_value_label:
		rating_value_label.text = str(int(rating_slider.value))

func _on_rating_changed(value):
	if rating_value_label:
		rating_value_label.text = str(int(value))

func _on_submit_pressed():
	var rating = int(rating_slider.value)
	var most_enjoyed = most_enjoyed_comment.text.strip_edges()
	var least_enjoyed = least_enjoyed_comment.text.strip_edges()
	var controls = controls_option.get_item_text(controls_option.selected)
	var clarity = clarity_option.get_item_text(clarity_option.selected)
	var difficulty = difficulty_option.get_item_text(difficulty_option.selected)
	var bugs = bugs_comment.text.strip_edges()
	var visual_audio = visual_audio_option.get_item_text(visual_audio_option.selected)
	var game_types = game_types_comment.text.strip_edges()
	var improvements = improvements_comment.text.strip_edges()

	# Require at least the main fields
	if most_enjoyed == "" or least_enjoyed == "" or improvements == "":
		show_feedback("Please fill in all required fields.", true)
		return

	submit_button.disabled = true
	show_feedback("Submitting feedback...")

	save_survey_data(
		rating, most_enjoyed, least_enjoyed, controls, clarity, difficulty,
		bugs, visual_audio, game_types, improvements
	)

func get_system_info():
	var os_name = OS.get_name()
	var os_version = OS.get_version()
	var browser_info = "Unknown"
	if OS.get_name() == "HTML5":
		var user_agent = JavaScriptBridge.eval("navigator.userAgent")
		if "Chrome" in user_agent:
			browser_info = "Chrome"
		elif "Firefox" in user_agent:
			browser_info = "Firefox"
		elif "Safari" in user_agent:
			browser_info = "Safari"
		elif "Edge" in user_agent:
			browser_info = "Edge"
		elif "MSIE" in user_agent or "Trident" in user_agent:
			browser_info = "Internet Explorer"
	return {
		"os": os_name,
		"os_version": os_version,
		"browser": browser_info
	}

func get_user_id():
	return GlobalStorage.get_user_id()

func save_survey_data(
	rating, most_enjoyed, least_enjoyed, controls, clarity, difficulty,
	bugs, visual_audio, game_types, improvements
):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/surveys.json"
	var system_info = get_system_info()
	var user_id = get_user_id()

	var data = {
		"rating": rating,
		"most_enjoyed": most_enjoyed,
		"least_enjoyed": least_enjoyed,
		"controls": controls,
		"clarity": clarity,
		"difficulty": difficulty,
		"bugs": bugs,
		"visual_audio": visual_audio,
		"game_types": game_types,
		"improvements": improvements,
		"timestamp": Time.get_unix_time_from_system(),
		"user_id": user_id,
		"system_info": system_info,
		"level_time": Globals.level_time,
		"total_level_time": Globals.total_level_time
	}

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	print("Sending survey data to Firebase...")
	print("URL: ", url)
	print("Data: ", json)

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		show_feedback("Error connecting to server. Please try again.", true)
		submit_button.disabled = false
		print("HTTP request error: ", error)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func show_feedback(message: String, is_error: bool = false):
	if feedback_label:
		feedback_label.text = message
		if is_error:
			feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		else:
			feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	print("Request completed. Response code: ", response_code)
	print("Response body: ", body.get_string_from_utf8())

	if response_code == 200:
		show_feedback("Thank you for your feedback!")
		redirect_timer.start(2.0)
	else:
		show_feedback("Error submitting survey. Please try again.", true)
		submit_button.disabled = false

func _on_redirect_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

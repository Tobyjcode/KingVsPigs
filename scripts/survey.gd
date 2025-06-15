extends Control

@onready var http = $HTTPRequest
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel
@onready var rating_slider = $Panel/VBoxContainer/RatingContainer/RatingSlider
@onready var rating_label = $Panel/VBoxContainer/RatingContainer/RatingLabel
@onready var gameplay_comment = $Panel/VBoxContainer/GameplayComment
@onready var difficulty_comment = $Panel/VBoxContainer/DifficultyComment
@onready var submit_button = $Panel/VBoxContainer/ButtonContainer/SubmitButton
@onready var back_button = $Panel/VBoxContainer/ButtonContainer/BackButton

var firebase_api_key = "AIzaSyCmdy8DSoDesCFhX9hb3lO9Qseq-STnEWg"
var redirect_timer = Timer.new()

func _ready():
	# Wait for the next frame to ensure all nodes are ready
	await get_tree().process_frame
	
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
	if rating_label:
		rating_label.text = "Rating: 5"

func _on_rating_changed(value):
	if rating_label:
		rating_label.text = "Rating: " + str(int(value))

func _on_submit_pressed():
	var rating = int(rating_slider.value)
	var gameplay = gameplay_comment.text.strip_edges()
	var difficulty = difficulty_comment.text.strip_edges()
	
	if gameplay == "" or difficulty == "":
		show_feedback("Please fill in all fields.", true)
		return
	
	# Disable submit button to prevent double submission
	submit_button.disabled = true
	show_feedback("Submitting feedback...")
	
	# Save survey data to Firebase
	save_survey_data(rating, gameplay, difficulty)

func get_system_info():
	var os_name = OS.get_name()
	var os_version = OS.get_version()
	var browser_info = "Unknown"
	
	# Try to detect browser if running in HTML5
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

func save_survey_data(rating, gameplay, difficulty):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/surveys.json"
	var system_info = get_system_info()
	var user_id = get_user_id()
	
	var data = {
		"rating": rating,
		"gameplay_feedback": gameplay,
		"difficulty_feedback": difficulty,
		"timestamp": Time.get_unix_time_from_system(),
		"user_id": user_id,
		"system_info": system_info
	}
	
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	print("Sending survey data to Firebase...")  # Debug print
	print("URL: ", url)  # Debug print
	print("Data: ", json)  # Debug print
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		show_feedback("Error connecting to server. Please try again.", true)
		submit_button.disabled = false
		print("HTTP request error: ", error)  # Debug print

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func show_feedback(message: String, is_error: bool = false):
	if feedback_label:
		feedback_label.text = message
		if is_error:
			feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		else:
			feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	print("Request completed. Response code: ", response_code)  # Debug print
	print("Response body: ", body.get_string_from_utf8())  # Debug print
	
	if response_code == 200:
		show_feedback("Thank you for your feedback!")
		redirect_timer.start(2.0)  # Redirect after 2 seconds
	else:
		show_feedback("Error submitting survey. Please try again.", true)
		submit_button.disabled = false

func _on_redirect_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

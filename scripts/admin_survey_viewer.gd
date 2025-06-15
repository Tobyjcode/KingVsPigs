extends Control

@onready var http = $HTTPRequest
@onready var survey_list = $Panel/VBoxContainer/ScrollContainer/SurveyList
@onready var refresh_button = $Panel/VBoxContainer/RefreshButton
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var access_panel = $AccessPanel
@onready var code_input = $AccessPanel/VBoxContainer/LineEdit
@onready var access_button = $AccessPanel/VBoxContainer/AccessButton

var is_firebase_admin = false
var delete_pending_id = null

func _ready():
	refresh_button.pressed.connect(_on_refresh_pressed)
	access_button.pressed.connect(_on_access_pressed)
	
	# Check if user is a Firebase admin
	var user_id = ""
	if Engine.has_singleton("FirebaseAuth"):
		var auth = Engine.get_singleton("FirebaseAuth")
		if auth.is_logged_in():
			user_id = auth.get_user_id()
	
	if user_id != "":
		_check_firebase_admin(user_id)
	else:
		# Not logged in, show code entry
		$Panel.visible = false
		access_panel.visible = true

func _check_firebase_admin(user_id):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/admins/%s.json" % user_id
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_result, response_code, _headers, body):
			if response_code == 200 and body.get_string_from_utf8().strip_edges() == "true":
				is_firebase_admin = true
				access_panel.visible = false
				$Panel.visible = true
				load_surveys()
			else:
				# Not a Firebase admin, show code entry
				$Panel.visible = false
				access_panel.visible = true
			http.queue_free()
	)
	http.request(url)

func _on_refresh_pressed():
	load_surveys()

func _on_access_pressed():
	var input_code = code_input.text
	if input_code == "123321":
		access_panel.visible = false
		$Panel.visible = true
		load_surveys()
	else:
		status_label.text = "Invalid access code"
		code_input.text = ""  # Clear the input field

func load_surveys():
	status_label.text = "Loading surveys..."
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/surveys.json"
	http.request(url)

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	if delete_pending_id != null:
		# Handle delete response
		if response_code == 200:
			status_label.text = "Survey deleted."
			delete_pending_id = null
			load_surveys()
		else:
			status_label.text = "Error deleting survey."
			delete_pending_id = null
		return

	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		display_surveys(response)
	else:
		status_label.text = "Error loading surveys. Please try again."

func display_surveys(surveys):
	# Clear existing items
	for child in survey_list.get_children():
		child.queue_free()
	
	if surveys == null:
		status_label.text = "No surveys found."
		return
	
	status_label.text = "Surveys loaded successfully."
	
	# Sort surveys by timestamp (newest first)
	var survey_array = []
	for key in surveys:
		var survey = surveys[key]
		survey["id"] = key
		survey_array.append(survey)
	
	survey_array.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	
	# Create survey items
	for survey in survey_array:
		var survey_item = create_survey_item(survey)
		survey_list.add_child(survey_item)

func create_survey_item(survey):
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Add timestamp
	var timestamp = Label.new()
	var date = Time.get_datetime_string_from_unix_time(survey.timestamp)
	timestamp.text = "Date: " + date
	container.add_child(timestamp)
	
	# Add rating
	var rating = Label.new()
	rating.text = "Rating: " + str(survey.rating) + "/10"
	container.add_child(rating)
	
	# Add level time
	var level_time = Label.new()
	level_time.text = "Level Time: " + (str(snapped(survey.level_time, 0.01)) + " seconds" if survey.has("level_time") else "")
	container.add_child(level_time)

	# Add total level time
	var total_time = Label.new()
	total_time.text = "Total Time: " + (str(snapped(survey.total_level_time, 0.01)) + " seconds" if survey.has("total_level_time") else "")
	container.add_child(total_time)
	
	# Add most enjoyed
	var gameplay = Label.new()
	gameplay.text = "Most Enjoyed: " + (survey.most_enjoyed if survey.has("most_enjoyed") else "")
	container.add_child(gameplay)
	
	# Add least enjoyed
	var least_enjoyed = Label.new()
	least_enjoyed.text = "Least Enjoyed: " + (survey.least_enjoyed if survey.has("least_enjoyed") else "")
	container.add_child(least_enjoyed)
	
	# Add difficulty
	var difficulty = Label.new()
	difficulty.text = "Difficulty & Pacing: " + (survey.difficulty if survey.has("difficulty") else "")
	container.add_child(difficulty)
	
	# Add controls
	var controls = Label.new()
	controls.text = "Controls: " + (survey.controls if survey.has("controls") else "")
	container.add_child(controls)
	
	# Add clarity
	var clarity = Label.new()
	clarity.text = "Clarity: " + (survey.clarity if survey.has("clarity") else "")
	container.add_child(clarity)
	
	# Add bugs
	var bugs = Label.new()
	bugs.text = "Bugs/Issues: " + (survey.bugs if survey.has("bugs") else "")
	container.add_child(bugs)
	
	# Add visual/audio
	var visual_audio = Label.new()
	visual_audio.text = "Visual/Audio: " + (survey.visual_audio if survey.has("visual_audio") else "")
	container.add_child(visual_audio)
	
	# Add game types
	var game_types = Label.new()
	game_types.text = "Game Types: " + (survey.game_types if survey.has("game_types") else "")
	container.add_child(game_types)
	
	# Add improvements
	var improvements = Label.new()
	improvements.text = "Improvements: " + (survey.improvements if survey.has("improvements") else "")
	container.add_child(improvements)
	
	# Add system info
	var system_info = Label.new()
	var sys = survey.system_info
	system_info.text = "System: " + sys.os + " " + sys.os_version + " | Browser: " + sys.browser
	container.add_child(system_info)
	
	# Add user ID
	var user_id = Label.new()
	user_id.text = "User ID: " + survey.user_id
	container.add_child(user_id)
	
	# Add delete button
	var delete_button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func(): _on_delete_survey_pressed(survey.id))
	container.add_child(delete_button)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _on_delete_survey_pressed(survey_id):
	status_label.text = "Deleting survey..."
	delete_pending_id = survey_id
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/surveys/%s.json" % survey_id
	http.request(url, [], HTTPClient.METHOD_DELETE)

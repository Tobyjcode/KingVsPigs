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
	
	# Add gameplay feedback
	var gameplay = Label.new()
	gameplay.text = "Gameplay Feedback: " + survey.gameplay_feedback
	gameplay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(gameplay)
	
	# Add difficulty feedback
	var difficulty = Label.new()
	difficulty.text = "Difficulty Feedback: " + survey.difficulty_feedback
	difficulty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(difficulty)
	
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

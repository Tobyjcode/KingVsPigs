extends Control

@onready var name_edit = $Panel/VBoxContainer/NameEdit
@onready var email_edit = $Panel/VBoxContainer/EmailEdit
@onready var age_edit = $Panel/VBoxContainer/AgeEdit
@onready var country_option = $Panel/VBoxContainer/CountryOption
@onready var password_edit = $Panel/VBoxContainer/PasswordEdit
@onready var guest_button = $Panel/VBoxContainer/ButtonContainer/GuestButton
@onready var create_user_button = $Panel/VBoxContainer/ButtonContainer/CreateUserButton
@onready var login_button = $Panel/VBoxContainer/LoginButton
@onready var http = $HTTPRequest
@onready var male_check = $Panel/VBoxContainer/GenderRadioContainer/MaleCheck
@onready var female_check = $Panel/VBoxContainer/GenderRadioContainer/FemaleCheck
@onready var other_check = $Panel/VBoxContainer/GenderRadioContainer/OtherCheck
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel

var firebase_api_key = "AIzaSyCmdy8DSoDesCFhX9hb3lO9Qseq-STnEWg" # Replace with your actual API key
var pending_action = ""
var redirect_timer = Timer.new()
var countries = [
	"Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan",
	"Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia",
	"Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia", "Cameroon",
	"Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo", "Costa Rica", "Croatia",
	"Cuba", "Cyprus", "Czechia", "Denmark", "Djibouti", "Dominica", "Dominican Republic", "Ecuador", "Egypt", "El Salvador",
	"Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Fiji", "Finland", "France", "Gabon", "Gambia",
	"Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", "Haiti",
	"Honduras", "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Israel", "Italy",
	"Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya", "Kiribati", "Kuwait", "Kyrgyzstan", "Laos", "Latvia",
	"Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg", "Madagascar", "Malawi", "Malaysia",
	"Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco",
	"Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand",
	"Nicaragua", "Niger", "Nigeria", "North Korea", "North Macedonia", "Norway", "Oman", "Pakistan", "Palau", "Palestine",
	"Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar", "Romania", "Russia",
	"Rwanda", "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia",
	"Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan",
	"Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria", "Taiwan", "Tajikistan", "Tanzania",
	"Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu", "Uganda",
	"Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan", "Vanuatu", "Vatican City", "Venezuela", "Vietnam",
	"Yemen", "Zambia", "Zimbabwe"
]
var country_type_buffer = ""
var country_type_timer = null
var profile_http = null # Add this variable to manage a separate HTTPRequest for profile saving

func _ready():
	guest_button.pressed.connect(_on_guest_pressed)
	create_user_button.pressed.connect(_on_create_user_pressed)
	login_button.pressed.connect(_on_login_pressed)
	male_check.pressed.connect(_on_gender_checked.bind(male_check))
	female_check.pressed.connect(_on_gender_checked.bind(female_check))
	other_check.pressed.connect(_on_gender_checked.bind(other_check))
	male_check.toggled.connect(_on_gender_toggled.bind("MaleCheck"))
	female_check.toggled.connect(_on_gender_toggled.bind("FemaleCheck"))
	other_check.toggled.connect(_on_gender_toggled.bind("OtherCheck"))
	
	# Setup timer for delayed redirect
	add_child(redirect_timer)
	redirect_timer.one_shot = true
	redirect_timer.timeout.connect(_on_redirect_timer_timeout)
	
	# Setup feedback label
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green color for success
	feedback_label.add_theme_font_size_override("font_size", 20)  # Larger font size

	# Add all countries to OptionButton
	for country in countries:
		country_option.add_item(country)
	country_option.focus_entered.connect(_on_country_option_focus)
	country_option.gui_input.connect(_on_country_option_gui_input)

	# Configure virtual keyboard behavior
	if OS.has_feature("mobile"):
		# Make sure the panel is visible when keyboard appears
		get_tree().get_root().connect("size_changed", _on_viewport_size_changed)
		
		# Connect virtual keyboard signals
		for line_edit in [name_edit, email_edit, password_edit, age_edit]:
			line_edit.virtual_keyboard_enabled = true
			line_edit.connect("focus_entered", _on_line_edit_focus_entered.bind(line_edit))
			line_edit.connect("focus_exited", _on_line_edit_focus_exited.bind(line_edit))

func _on_guest_pressed():
	pending_action = "guest"
	login_anonymous()

func _on_create_user_pressed():
	var name = name_edit.text.strip_edges()
	var email = email_edit.text.strip_edges()
	var age = age_edit.text.strip_edges()
	var country = country_option.text
	var password = password_edit.text.strip_edges()
	var gender = ""
	if male_check.button_pressed:
		gender = "Male"
	elif female_check.button_pressed:
		gender = "Female"
	elif other_check.button_pressed:
		gender = "Other"

	if name == "" or email == "" or password == "" or age == "" or gender == "" or country_option.selected < 0:
		show_feedback("Please fill in all fields.", true)
		return

	pending_action = "register"
	print("Registering user:", name, email, age, country, gender)
	register_user(email, password)

func _on_login_pressed():
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func register_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" % firebase_api_key
	var data = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_POST, json)

func login_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s" % firebase_api_key
	var data = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_POST, json)

func login_anonymous():
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" % firebase_api_key
	var data = {
		"returnSecureToken": true
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_POST, json)

func _on_gender_checked(checked_box):
	if checked_box == male_check:
		female_check.button_pressed = false
		other_check.button_pressed = false
	elif checked_box == female_check:
		male_check.button_pressed = false
		other_check.button_pressed = false
	elif checked_box == other_check:
		male_check.button_pressed = false
		female_check.button_pressed = false

func save_user_profile(local_id, id_token):
	if profile_http:
		profile_http.queue_free()
	profile_http = HTTPRequest.new()
	add_child(profile_http)
	profile_http.request_completed.connect(_on_profile_save_completed)
	var data = {
		"name": name_edit.text.strip_edges(),
		"age": age_edit.text.strip_edges(),
		"country": country_option.text,
		"gender": "Male" if male_check.button_pressed else "Female" if female_check.button_pressed else "Other",
		"email": email_edit.text.strip_edges()
	}
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s.json?auth=%s" % [local_id, id_token]
	var json = JSON.stringify(data)
	profile_http.request(url, [], HTTPClient.METHOD_PUT, json)

func _on_redirect_timer_timeout():
	if pending_action == "register":
		get_tree().change_scene_to_file("res://scenes/login.tscn")
	elif pending_action == "guest":
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func show_feedback(message: String, is_error: bool = false):
	print("Showing feedback:", message) # Debug print
	feedback_label.text = message
	feedback_label.show()
	if is_error:
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	else:
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	# Optionally, set a background color:
	feedback_label.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.1, 0.8))

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("Auth response:", response_code, body.get_string_from_utf8())
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response == null:
		show_feedback("Error: Invalid server response.", true)
		print("Error: Could not parse JSON response.")
		return

	if response_code == 200 and pending_action == "register":
		var local_id = response.get("localId", "")
		var id_token = response.get("idToken", "")
		if local_id != "" and id_token != "":
			save_user_profile(local_id, id_token)
		else:
			show_feedback("Registration failed: missing user ID.", true)
		redirect_timer.start(3.0)
		show_feedback("Successfully registered! Redirecting...")
	elif response_code == 200 and pending_action == "guest":
		show_feedback("Guest login successful! Redirecting...")
		redirect_timer.start(3.0)
	else:
		var error_message = "Error: " + (response.get("error", {}).get("message", "Unknown error occurred") if response.has("error") else "Unknown error occurred")
		show_feedback(error_message, true)
		print("Error:", response)

func _on_gender_toggled(button_pressed, name):
	if not button_pressed:
		return
	for i in $Panel/VBoxContainer/GenderRadioContainer.get_children():
		if i.name != name and i is CheckBox:
			i.button_pressed = false

func _on_country_option_focus():
	country_type_buffer = ""

func _on_country_option_gui_input(event):
	if event is InputEventKey and event.unicode != 0:
		var char = char(event.unicode).to_lower()
		if country_type_timer:
			country_type_timer.stop()
		else:
			country_type_timer = Timer.new()
			country_type_timer.one_shot = true
			country_type_timer.wait_time = 1.0
			country_type_timer.timeout.connect(_on_country_type_timer_timeout)
			add_child(country_type_timer)
		country_type_buffer += char
		_country_option_jump_to(country_type_buffer)
		country_type_timer.start()

func _on_country_type_timer_timeout():
	country_type_buffer = ""

func _country_option_jump_to(prefix):
	for i in range(country_option.item_count):
		var item_text = country_option.get_item_text(i).to_lower()
		if item_text.begins_with(prefix):
			country_option.selected = i
			break

func _on_profile_save_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Profile saved successfully.")
	else:
		print("Profile save failed:", body.get_string_from_utf8())
		show_feedback("Warning: Profile not saved! You may not be able to login by username.", true)
	if profile_http:
		profile_http.queue_free()
		profile_http = null

func _on_viewport_size_changed():
	# Adjust panel position when keyboard appears/disappears
	var viewport_size = get_viewport_rect().size
	var panel = $Panel
	if panel:
		# Keep panel visible above keyboard
		panel.position.y = min(panel.position.y, viewport_size.y - panel.size.y - 20)

func _on_line_edit_focus_entered(line_edit):
	# Scroll to make sure the focused line edit is visible
	var viewport_size = get_viewport_rect().size
	var line_edit_global_pos = line_edit.global_position
	if line_edit_global_pos.y + line_edit.size.y > viewport_size.y - 100:
		var scroll_amount = line_edit_global_pos.y + line_edit.size.y - (viewport_size.y - 100)
		$Panel.position.y -= scroll_amount

func _on_line_edit_focus_exited(line_edit):
	# Reset panel position when keyboard is dismissed
	$Panel.position.y = 0

extends Control

@onready var name_edit = $Panel/VBoxContainer/NameEdit
@onready var email_edit = $Panel/VBoxContainer/EmailEdit
@onready var age_edit = $Panel/VBoxContainer/AgeEdit
@onready var country_edit = $Panel/VBoxContainer/CountryEdit
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

func _on_guest_pressed():
	pending_action = "guest"
	login_anonymous()

func _on_create_user_pressed():
	print("Create User button pressed")
	var name = name_edit.text.strip_edges()
	var email = email_edit.text.strip_edges()
	var age = age_edit.text.strip_edges()
	var country = country_edit.text.strip_edges()
	var password = password_edit.text.strip_edges()
	var gender = ""
	if male_check.button_pressed:
		gender = "Male"
	elif female_check.button_pressed:
		gender = "Female"
	elif other_check.button_pressed:
		gender = "Other"
	if name == "" or email == "" or age == "" or country == "" or password == "" or gender == "":
		print("Please fill in all fields.")
		return
	pending_action = "register"
	print("name:", name, "email:", email, "age:", age, "country:", country, "password:", password, "gender:", gender)
	register_user(email, password)

func _on_login_pressed():
	var name = name_edit.text.strip_edges()
	var password = password_edit.text.strip_edges()
	if name == "" or password == "":
		print("Please enter name and password to login.")
		return
	pending_action = "login"
	var email = name + "@kingvspigs.com"
	login_user(email, password)

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

func save_user_profile(local_id, id_token, name, age, country, gender):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s.json?auth=%s" % [local_id, id_token]
	var data = {
		"name": name,
		"age": age,
		"country": country,
		"gender": gender
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_PUT, json)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		feedback_label.text = "Successful! " + pending_action.capitalize() + "."
		print("Success!", pending_action, response)
		if pending_action == "register":
			var local_id = response.get("localId", "")
			var id_token = response.get("idToken", "")
			if local_id != "" and id_token != "":
				save_user_profile(
					local_id,
					id_token,
					name_edit.text.strip_edges(),
					age_edit.text.strip_edges(),
					country_edit.text.strip_edges(),
					"Male" if male_check.button_pressed else "Female" if female_check.button_pressed else "Other"
				)
	else:
		var error_msg = "Error during %s: %s" % [pending_action, response]
		feedback_label.text = error_msg
		print(error_msg)

func _on_gender_toggled(button_pressed, name):
	if not button_pressed:
		return
	for i in $Panel/VBoxContainer/GenderRadioContainer.get_children():
		if i.name != name and i is CheckBox:
			i.button_pressed = false

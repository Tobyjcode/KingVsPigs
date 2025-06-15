extends Control

@onready var user_edit = $Panel/VBoxContainer/UserEdit
@onready var password_edit = $Panel/VBoxContainer/PasswordEdit
@onready var login_button = $Panel/VBoxContainer/LoginButton
@onready var forgot_password_button = $Panel/VBoxContainer/ForgotPasswordButton
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel
@onready var http = $HTTPRequest
@onready var back_button = $Panel/VBoxContainer/BackButton

var firebase_api_key = "AIzaSyCmdy8DSoDesCFhX9hb3lO9Qseq-STnEWg"
var pending_action = ""
var id_token = ""
var local_id = ""
var redirect_timer = Timer.new()

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	add_child(redirect_timer)
	redirect_timer.one_shot = true
	redirect_timer.timeout.connect(_on_redirect_timer_timeout)

func _on_login_pressed():
	var user = user_edit.text.strip_edges()
	var password = password_edit.text.strip_edges()
	if user == "" or password == "":
		feedback_label.text = "Please enter your username/email and password."
		return
	pending_action = "login"
	if user.contains("@"):
		login_user(user, password)
	else:
		# Try to find email by username (force lowercase)
		feedback_label.text = "Looking up username..."
		find_email_by_username(user.to_lower(), func(email):
			if email != "":
				login_user(email, password)
			else:
				feedback_label.text = "Username not found."
		)

func login_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s" % firebase_api_key
	var data = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_POST, json)

func _on_forgot_password_pressed():
	var user = user_edit.text.strip_edges()
	var email = user
	if user == "":
		feedback_label.text = "Please enter your email to reset your password."
		return
	if not user.contains("@"):
		email = user + "@kingvspigs.com"
	pending_action = "reset_password"
	reset_password(email)

func reset_password(email):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=%s" % firebase_api_key
	var data = {
		"requestType": "PASSWORD_RESET",
		"email": email
	}
	var json = JSON.stringify(data)
	http.request(url, [], HTTPClient.METHOD_POST, json)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP request completed! Code:", response_code)
	print("Body:", body.get_string_from_utf8())
	var response = JSON.parse_string(body.get_string_from_utf8())
	if pending_action == "login":
		if response_code == 200:
			local_id = response.get("localId", "")
			id_token = response.get("idToken", "")
			GlobalStorage.user_id = local_id  # Store UID globally!
			GlobalStorage.set_player_name(response.get("displayName", ""))
			feedback_label.text = "Login successful! Redirecting..."
			print("Logged in! Firebase UID:", local_id)
			print("GlobalStorage.user_id:", GlobalStorage.user_id)
			redirect_timer.start(2.0)
		else:
			feedback_label.text = "Login failed. Please check your password."
			print("Login failed:", response)  # Developer debug info
	elif pending_action == "reset_password":
		if response_code == 200:
			feedback_label.text = "Password reset email sent! Check your inbox."
		else:
			feedback_label.text = "Failed to send reset email. Please check your email address."
			print("Reset failed:", response)  # Developer debug info

func _on_redirect_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/signup.tscn")

func find_email_by_username(username, callback):
	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users.json?orderBy=\"name\"&equalTo=\"%s\"" % username
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_result, response_code, _headers, body):
			print("Username lookup response:", response_code, body.get_string_from_utf8())
			if response_code == 200:
				var users = JSON.parse_string(body.get_string_from_utf8())
				if users and users.size() > 0:
					for key in users:
						var user = users[key]
						if user.has("email"):
							callback.call(user["email"])
							http.queue_free()
							return
				# Not found
				callback.call("")
			else:
				callback.call("")
			http.queue_free()
	)
	http.request(url)

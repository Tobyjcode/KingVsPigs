extends Control

signal consent_given
signal consent_declined

@onready var consent_button = $Panel/VBoxContainer/ConsentButton
@onready var decline_button = $Panel/VBoxContainer/DeclineButton
@onready var high_contrast = $Panel/VBoxContainer/HighContrastButton
@onready var description = $Panel/VBoxContainer/Description
@onready var delete_data_button = $Panel/VBoxContainer/DeleteDataButton
@onready var age_verification = $Panel/VBoxContainer/AgeVerification
@onready var privacy_policy_button = $Panel/VBoxContainer/PrivacyPolicyButton

func _ready():
	# Connect button signals
	consent_button.pressed.connect(_on_consent_pressed)
	decline_button.pressed.connect(_on_decline_pressed)
	high_contrast.toggled.connect(_on_high_contrast_toggled)
	delete_data_button.pressed.connect(_on_delete_data_pressed)
	privacy_policy_button.pressed.connect(_on_privacy_policy_pressed)
	
	# Set up initial button sizes for accessibility
	consent_button.custom_minimum_size.y = 80
	decline_button.custom_minimum_size.y = 80
	
	# Set initial colors
	consent_button.modulate = Color(0.2, 0.8, 0.2)  # Green
	decline_button.modulate = Color(0.8, 0.2, 0.2)  # Red
	delete_data_button.visible = false
	
	var config = ConfigFile.new()
	if config.load("user://privacy_consent.cfg") == OK:
		delete_data_button.visible = true

func _on_consent_pressed():
	if not age_verification.button_pressed:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Please confirm you are 16 or older, or have parental consent."
		add_child(dialog)
		dialog.popup_centered()
		return
		
	var datetime = Time.get_datetime_dict_from_system()
	var consent_data = {
		"consent_given": true,
		"timestamp": "%d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		],
		"version": "1.0",
		"age_verified": age_verification.button_pressed,
		"survey_consent": true
	}
	
	var config = ConfigFile.new()
	config.set_value("privacy", "consent", consent_data)
	config.save("user://privacy_consent.cfg")
	
	emit_signal("consent_given")
	queue_free()

func _on_privacy_policy_pressed():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = """Privacy Policy for King vs Pigs

1. Data We Collect
- Game progress and scores
- Survey responses (if you participate)
- Basic device information
- Age verification status

2. How We Use Your Data
- Save your game progress
- Display highscores
- Improve game experience
- Ensure age-appropriate content

3. Your Rights (GDPR)
- Access your data
- Delete your data
- Withdraw consent
- Data portability

4. Data Storage
- Secure Firebase storage
- No third-party sharing
- Deletion upon request

Contact: support@kingvspigs.com"""

	# Set the size properly
	dialog.min_size = Vector2(500, 400)  # Use min_size instead of custom_minimum_size
	
	# Add to scene and show
	add_child(dialog)
	dialog.popup_centered()

func _on_delete_data_pressed():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = """This will delete:
	- Your game progress
	- Your scores
	- Your survey responses
	- Your account preferences
	
	Are you sure you want to proceed?"""
	dialog.confirmed.connect(func():
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("privacy_consent.cfg")
		
		# Delete Firebase data if logged in
		if GlobalStorage.get_user_id() != "anonymous":
			_delete_firebase_data()
			
		var confirmation = AcceptDialog.new()
		confirmation.dialog_text = "All your data has been deleted."
		add_child(confirmation)
		confirmation.popup_centered()
	)
	add_child(dialog)
	dialog.popup_centered()

func _delete_firebase_data():
	var user_id = GlobalStorage.get_user_id()
	if user_id == "anonymous":
		return
		
	var urls = [
		"https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s.json" % user_id,
		"https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/highscores/%s.json" % user_id,
		"https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/surveys/%s.json" % user_id
	]
	
	for url in urls:
		var http = HTTPRequest.new()
		add_child(http)
		http.request(url, [], HTTPClient.METHOD_DELETE)
		await http.request_completed
		http.queue_free()

func _on_decline_pressed():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = """Without consent, the following features will be limited:
	- Progress saving
	- Highscores
	- Survey participation
	- Account features
	
	You can change this decision anytime in the options menu."""
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	emit_signal("consent_declined")

func _on_high_contrast_toggled(button_pressed):
	if button_pressed:
		description.modulate = Color.BLACK
		$Panel.modulate = Color.WHITE
	else:
		description.modulate = Color(0.1, 0.1, 0.1)
		$Panel.modulate = Color(0.8, 0.8, 0.8)

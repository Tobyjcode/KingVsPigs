extends Node

var user_id: String = "anonymous"
var player_name: String = "Anonymous"
var has_consent: bool = false
var consent_timestamp: String = ""

func _ready():
	load_consent_status()

func load_consent_status():
	var config = ConfigFile.new()
	if config.load("user://privacy_consent.cfg") == OK:
		var consent_data = config.get_value("privacy", "consent", {})
		has_consent = consent_data.get("consent_given", false)
		consent_timestamp = consent_data.get("timestamp", "")
		print("Loaded consent status: ", has_consent)

func get_user_id() -> String:
	return user_id if has_consent else "anonymous"

func get_player_name() -> String:
	return player_name if has_consent else "Anonymous"

func set_player_name(new_name: String):
	if has_consent:
		player_name = new_name

func can_store_data() -> bool:
	return has_consent

func can_collect_analytics() -> bool:
	return has_consent

func can_show_highscores() -> bool:
	return has_consent

func delete_user_data():
	# Delete local data
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("privacy_consent.cfg")
	
	# Reset all local variables
	has_consent = false
	user_id = "anonymous"
	player_name = "Anonymous"
	
	# Emit signal for other nodes that need to know about data deletion
	data_deleted.emit()

# Signal for when user data is deleted
signal data_deleted

func get_consent_info() -> Dictionary:
	return {
		"has_consent": has_consent,
		"timestamp": consent_timestamp
	}

func update_consent(consent_data: Dictionary):
	has_consent = consent_data.get("consent_given", false)
	consent_timestamp = consent_data.get("timestamp", "")
	
	var config = ConfigFile.new()
	config.set_value("privacy", "consent", consent_data)
	config.save("user://privacy_consent.cfg")

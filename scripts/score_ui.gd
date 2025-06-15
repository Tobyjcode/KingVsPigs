extends CanvasLayer

# Remove the preload since Globals is an autoload/singleton
# const Globals = preload("res://scripts/globals.gd")

var highscore_manager: Node
var highscores = []

@onready var score_ui_container: HBoxContainer = $ScoreUIContainer
@onready var score_group = $ScoreUIContainer/ScoreGroup
@onready var diamond_score_ui: Label = $ScoreUIContainer/ScoreGroup/DiamondScoreUI
@onready var restart_message: TextureRect = $RestartMessage
@onready var name_input_dialog = $NameInputDialog
@onready var name_line_edit = $NameInputDialog/LineEdit

func _ready():
	score_ui_container.scale = Vector2(4, 4) # Adjust as needed
	update_diamond_score()
	
	# Set player name from Firebase if available (BEFORE any score submission)
	set_player_name_from_db()

	# Get or create the highscore manager
	highscore_manager = get_node_or_null("/root/HighscoreManager")
	if not highscore_manager:
		highscore_manager = load("res://scripts/highscore_manager.gd").new()
		highscore_manager.name = "HighscoreManager"
		get_tree().root.add_child(highscore_manager)

func add_diamond(amount: int = 1):
	Globals.diamond_score += amount
	update_diamond_score()

func set_diamond_score(amount: int):
	Globals.diamond_score = amount
	update_diamond_score()

func update_diamond_score():
	diamond_score_ui.text = str(Globals.diamond_score)

func submit_score():
	name_line_edit.text = ""
	name_input_dialog.popup_centered()
	name_line_edit.grab_focus()
	name_line_edit.select_all()

func _on_NameInputDialog_confirmed():
	var name = name_line_edit.text.strip_edges()
	if name == "":
		name = "Anonymous"
	HighscoreManager.submit_score(Globals.diamond_score, name)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			highscores = []
			for key in json:
				var score_data = json[key]
				if typeof(score_data) == TYPE_DICTIONARY:
					score_data["id"] = key
					# If player_name is missing or empty, try to fetch it from users DB
					if not score_data.has("player_name") or score_data.player_name == "":
						var user_id = score_data.get("user_id", "")
						if user_id != "":
							var http = HTTPRequest.new()
							add_child(http)
							http.request_completed.connect(func(_r, code, _h, b):
								if code == 200:
									var name = b.get_string_from_utf8().strip_edges().replace('"', '')
									if name != "":
										score_data["player_name"] = name
									else:
										score_data["player_name"] = "Anonymous"
								else:
									score_data["player_name"] = "Anonymous"
								http.queue_free()
							)
							http.request("https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s/name.json" % user_id)
						else:
							score_data["player_name"] = "Anonymous"
					# Fallback if still missing
					if not score_data.has("player_name") or score_data.player_name == "":
						score_data["player_name"] = score_data.get("email", "Anonymous")
					highscores.append(score_data)
				# else: skip non-dictionary entries
			# Sort highscores by score in descending order
			highscores.sort_custom(func(a, b): return a.score > b.score)

func set_player_name_from_db():
	if Engine.has_singleton("FirebaseAuth"):
		var auth = Engine.get_singleton("FirebaseAuth")
		if auth.is_logged_in():
			var user_id = auth.get_user_id()
			var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s/name.json" % user_id
			var http = HTTPRequest.new()
			add_child(http)
			http.request_completed.connect(
				func(_result, response_code, _headers, body):
					if response_code == 200:
						var name = body.get_string_from_utf8().strip_edges().replace('\"', '')
						if name != "":
							Globals.player_name = name
						else:
							Globals.player_name = auth.get_user_email() # fallback to email
						print("Player name for leaderboard:", Globals.player_name)
					else:
						Globals.player_name = auth.get_user_email() # fallback to email
						print("Failed to fetch player name from DB, using email")
					http.queue_free()
			)
			http.request(url)
		else:
			Globals.player_name = "Anonymous"
	else:
		Globals.player_name = "Anonymous"

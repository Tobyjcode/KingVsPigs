extends Control

@onready var scores_container = $Panel/VBoxContainer/ScoresContainer
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var name_input_dialog = $NameInputDialog
@onready var name_line_edit = $NameInputDialog/LineEdit

var highscore_manager: Node
var highscores = []
var pending_score = 0

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
	# Get or create the highscore manager
	highscore_manager = get_node_or_null("/root/HighscoreManager")
	if not highscore_manager:
		highscore_manager = load("res://scripts/highscore_manager.gd").new()
		highscore_manager.name = "HighscoreManager"
		get_tree().root.add_child(highscore_manager)
	
	highscore_manager.highscores_updated.connect(_on_highscores_updated)
	update_highscores()

	if Engine.has_singleton("FirebaseAuth"):
		var auth = Engine.get_singleton("FirebaseAuth")
		if auth.is_logged_in():
			var user_id = auth.get_user_id()
			var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s/name.json" % user_id
			var http = HTTPRequest.new()
			add_child(http)
			http.request_completed.connect(
				func(_result, response_code, _headers, body):
					var name = ""
					if response_code == 200:
						name = body.get_string_from_utf8().strip_edges().replace('\"', '')
					if name == "":
						name = auth.get_user_email() # fallback to email
					Globals.player_name = name
					http.queue_free()
			)
			http.request(url)
		else:
			Globals.player_name = "Anonymous"
	else:
		Globals.player_name = "Anonymous"

func update_highscores():
	# Clear existing scores
	for child in scores_container.get_children():
		child.queue_free()
	
	# Add loading indicator
	var loading = Label.new()
	loading.text = "Loading highscores..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scores_container.add_child(loading)
	
	# Fetch latest highscores
	highscore_manager.fetch_highscores()

func _on_highscores_updated():
	# Clear existing scores
	for child in scores_container.get_children():
		child.queue_free()
	
	# Display highscores
	var top_scores = highscore_manager.get_top_scores(10)
	if top_scores.is_empty():
		var no_scores = Label.new()
		no_scores.text = "No highscores yet!"
		no_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_container.add_child(no_scores)
		return
	
	for i in range(top_scores.size()):
		var score_data = top_scores[i]
		if typeof(score_data) == TYPE_DICTIONARY:
			var score_label = Label.new()
			score_label.text = "%d. %s - %d diamonds" % [
				i + 1,
				score_data.player_name,
				score_data.score
			]
			score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			scores_container.add_child(score_label)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			highscores = []
			for key in json:
				var score_data = json[key]
				if typeof(score_data) == TYPE_DICTIONARY:
					score_data["id"] = key
					highscores.append(score_data)
				else:
					print("Invalid score data for key: ", key)
			# Sort highscores by score in descending order
			highscores.sort_custom(func(a, b): return a.score > b.score)
			emit_signal("highscores_updated")

func submit_score():
	# Show the name input dialog when submitting a score
	pending_score = Globals.diamond_score
	name_input_dialog.popup_centered()
	name_line_edit.text = "" # Clear previous input

func _on_NameInputDialog_confirmed():
	var player_name = name_line_edit.text.strip_edges()
	if player_name == "":
		player_name = "Anonymous"
	if highscore_manager:
		highscore_manager.submit_score(pending_score, player_name)

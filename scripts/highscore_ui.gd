extends Control

@onready var scores_container = $Panel/VBoxContainer/ScrollContainer/ScoresContainer
@onready var back_button = $Panel/VBoxContainer/BackButton

var highscore_manager: Node
var highscores = []
var user_id = GlobalStorage.get_user_id()
var player_name = GlobalStorage.get_player_name()

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	HighscoreManager.highscores_updated.connect(_on_highscores_updated)
	update_highscores()

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
	HighscoreManager.fetch_highscores()

func _on_highscores_updated():
	# Clear existing scores
	for child in scores_container.get_children():
		child.queue_free()
	
	# Display highscores
	var top_scores = HighscoreManager.get_top_scores(30)
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

func get_user_id() -> String:
	return GlobalStorage.get_user_id()

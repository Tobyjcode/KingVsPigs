extends Node

signal highscores_updated

var http_request: HTTPRequest
var highscores = []
var firebase_url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/highscores.json"

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	fetch_highscores()

func submit_score(score: int):
	var user_id = GlobalStorage.get_user_id()
	if user_id == "" or user_id == "anonymous":
		_submit_score_with_name(score, "Anonymous", user_id)
		return

	print("Submitting score for UID:", user_id)

	var url = "https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s/name.json" % user_id
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, response_code, _headers, body):
		var player_name = "Anonymous"
		if response_code == 200:
			player_name = body.get_string_from_utf8().strip_edges().replace('"', '')
			if player_name == "":
				player_name = "Anonymous"
		_submit_score_with_name(score, player_name, user_id)
		http.queue_free()
	)
	http.request(url)

func _submit_score_with_name(score: int, player_name: String, user_id: String):
	var data = {
		"score": score,
		"player_name": player_name,
		"user_id": user_id,
		"timestamp": Time.get_unix_time_from_system()
	}
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(firebase_url, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("Error submitting score: ", error)

func fetch_highscores():
	var error = http_request.request(firebase_url)
	if error != OK:
		print("Error fetching highscores: ", error)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			highscores = []
			for key in json:
				var score_data = json[key]
				if typeof(score_data) == TYPE_DICTIONARY and score_data.has("score"):
					score_data["id"] = key
					if (not score_data.has("player_name") or score_data.player_name == "") and score_data.has("user_id"):
						var user_id = score_data.user_id
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
								highscores.sort_custom(func(a, b): return a.score > b.score)
								emit_signal("highscores_updated")
							)
							http.request("https://kingvspigs-default-rtdb.europe-west1.firebasedatabase.app/users/%s/name.json" % user_id)
						else:
							score_data["player_name"] = "Anonymous"
					elif not score_data.has("player_name") or score_data.player_name == "":
						score_data["player_name"] = "Anonymous"
					highscores.append(score_data)
				else:
					print("Skipping non-score entry for key: ", key)
			highscores.sort_custom(func(a, b): return a.score > b.score)
			emit_signal("highscores_updated")

func get_top_scores(limit: int = 10) -> Array:
	return highscores.slice(0, min(limit, highscores.size()))

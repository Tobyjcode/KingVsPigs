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

func submit_score(score: int, player_name: String = "Anonymous"):
	var user_id = get_user_id()
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
				else:
					print("Invalid score data for key: ", key)
			# Sort highscores by score in descending order
			highscores.sort_custom(func(a, b): return a.score > b.score)
			emit_signal("highscores_updated")

func get_user_id() -> String:
	if Engine.has_singleton("FirebaseAuth"):
		var auth = Engine.get_singleton("FirebaseAuth")
		if auth.is_logged_in():
			return auth.get_user_id()
	return "anonymous"

func get_top_scores(limit: int = 10) -> Array:
	return highscores.slice(0, min(limit, highscores.size()))

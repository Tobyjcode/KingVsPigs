extends Node

var user_id: String = "anonymous"
var player_name: String = "Anonymous"

func get_user_id():
    return user_id

func get_player_name():
    return player_name

func set_player_name(new_name: String):
    player_name = new_name

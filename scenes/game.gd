extends Node2D

@onready var start_door = $door2  # Use the correct name for your start door node
@onready var player: CharacterBody2D = $Player  # Use the correct name for your player node

const DOOR = preload("res://scenes/door.tscn")
const PLAYER = preload("res://scenes/player.tscn")

func _ready():
	if start_door.is_start_door:
		start_door.connect("start_door_opened", Callable(player, "play_door_out"))
		start_door.start_open_sequence()

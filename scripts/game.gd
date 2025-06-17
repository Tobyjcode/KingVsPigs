extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var pause_screen = $PauseScreen

func _ready():
	# Set up camera to follow player
	if player and camera:
		camera.position = player.position
		camera.make_current()
	
	# Connect pause screen signals
	if pause_screen:
		pause_screen.visibility_changed.connect(_on_pause_screen_visibility_changed)

func _process(_delta):
	# Update camera position to follow player
	if player and camera:
		camera.position = player.position

func _input(event):
	if event.is_action_pressed("pause"):
		if pause_screen:
			pause_screen.visible = !pause_screen.visible
			get_tree().paused = pause_screen.visible

func _on_pause_screen_visibility_changed():
	get_tree().paused = pause_screen.visible 

extends Area2D

@export var next_level: PackedScene
@export var required_coins: int = 0
@export var is_start_door: bool = false  # New property to identify start doors

var player = null
var door_sound = null

signal start_door_opened

func _ready():
	# Connect the body signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create door sound player
	door_sound = AudioStreamPlayer2D.new()
	door_sound.stream = load("res://Assets/Sounds/effects/enviroment/door_1.wav")
	add_child(door_sound)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player = null

func _process(_delta):
	if Input.is_action_just_pressed("game_use") and player != null:
		if required_coins > 0 and player.coins < required_coins:
			print("Need more coins!")
			return

		door_sound.play()
		$AnimatedSprite2D.play("open")
		# Tell the player to play the doorIn animation
		if player.has_method("play_door_in"):
			player.play_door_in()
		elif player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("doorIn")
		await get_tree().create_timer(0.4).timeout  # Wait for the open animation to finish
		if next_level:
			get_tree().change_scene_to_packed(next_level) 

func start_open_sequence():
	$AnimatedSprite2D.play("open")
	await get_tree().create_timer(0.4).timeout
	emit_signal("start_door_opened")
	$AnimatedSprite2D.play("close") 

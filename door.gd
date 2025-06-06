extends Area2D

@export var next_level: PackedScene
@export var required_coins: int = 0

var player = null

func _ready():
	# Connect the body signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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

		$AnimatedSprite2D.play("open")
		await get_tree().create_timer(0.4).timeout  # Wait for the open animation to finish
		if next_level:
			get_tree().change_scene_to_packed(next_level) 

extends Control

@export var text_tutorial: String = "Sample tutorial text"
@export var autorun: bool = true
@export var detection_radius: float = 100.0  # How close the player needs to be

var player: Node2D = null
var has_played: bool = false
var world_position: Vector2  # Store the world position where this tutorial should appear

func _ready():
	$NinePatchRect/CenterContainer/TutorialText.text = text_tutorial
	
	if autorun:
		$AnimationPlayer.play("Appear")
	else:
		visible = false
		# Find the player node if not autorunning
		player = get_tree().get_first_node_in_group("player")
		# Store the initial world position
		world_position = get_parent().global_position

func _process(_delta):
	if not autorun and player and not has_played:
		# Calculate distance to player using world coordinates
		var distance = world_position.distance_to(player.global_position)
		
		# If player is close enough, play the animation
		if distance <= detection_radius:
			run()
			has_played = true

func _on_Timer_timeout():
	$AnimationPlayer.play("Disappear")

func run():
	$AnimationPlayer.play("Appear")
	$Timer.start()

func turn_on_visible():
	visible = true

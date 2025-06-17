extends Node

# Simple integration script for mobile controls
# Add this to your main game scene

@onready var mobile_controls_manager = preload("res://scripts/mobile_controls_manager.gd").new()

func _ready():
	# Add mobile controls manager to the scene
	add_child(mobile_controls_manager)
	
	# Show mobile controls if on mobile
	if OS.has_feature("mobile") or OS.has_feature("web"):
		mobile_controls_manager.show_mobile_controls()

func _input(event):
	# Handle pause button for mobile
	if event is InputEventScreenTouch and event.pressed:
		# Check if pause button was pressed
		if event.position.x < 100 and event.position.y < 100:
			# Pause the game
			get_tree().paused = true
			# You can show your pause menu here 

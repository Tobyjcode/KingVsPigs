extends Node

@onready var mobile_screen_manager = preload("res://scripts/mobile_screen_manager.gd").new()
@onready var mobile_controls_manager = preload("res://scripts/mobile_controls_manager.gd").new()

func _ready():
	add_child(mobile_screen_manager)
	add_child(mobile_controls_manager)
	
	if OS.has_feature("mobile") or OS.has_feature("web"):
		mobile_controls_manager.show_mobile_controls()
		setup_mobile_settings()
		print("Mobile setup done!")

func setup_mobile_settings():
	if OS.has_feature("mobile"):
		var viewport = get_viewport()
		viewport.set_handle_input_locally(false)
		
		RenderingServer.set_default_clear_color(Color.BLACK)
		setup_mobile_input()

func setup_mobile_input():
	if OS.has_feature("mobile"):
		Input.set_use_accumulated_input(false)

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x < 100 and event.position.y < 100:
			handle_pause_button()

func handle_pause_button():
	var pause_screen = get_tree().get_first_node_in_group("PauseScreen")
	if pause_screen and pause_screen.has_method("show_pause_screen"):
		pause_screen.show_pause_screen()
	else:
		get_tree().paused = !get_tree().paused
		print("Game paused: ", get_tree().paused)

func get_mobile_screen_manager():
	return mobile_screen_manager

func get_mobile_controls_manager():
	return mobile_controls_manager

func is_mobile_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web")

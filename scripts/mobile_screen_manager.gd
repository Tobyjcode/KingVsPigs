extends Node

# Handles different mobile screen sizes
# Just adjusts things based on screen size

var is_mobile := false
var current_screen_size := Vector2.ZERO
var is_landscape := false

func _ready():
	is_mobile = OS.has_feature("mobile") or OS.has_feature("web")
	
	if is_mobile:
		setup_mobile_screen()
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func setup_mobile_screen():
	current_screen_size = get_viewport().get_visible_rect().size
	is_landscape = current_screen_size.x > current_screen_size.y
	
	print("Mobile screen:")
	print("  Size: ", current_screen_size)
	print("  Orientation: ", "Landscape" if is_landscape else "Portrait")
	print("  Aspect: ", current_screen_size.x / current_screen_size.y)
	
	if is_mobile:
		var viewport = get_viewport()
		viewport.set_handle_input_locally(false)
		RenderingServer.set_default_clear_color(Color.BLACK)

func _on_viewport_size_changed():
	if is_mobile:
		var new_size = get_viewport().get_visible_rect().size
		if new_size != current_screen_size:
			current_screen_size = new_size
			is_landscape = current_screen_size.x > current_screen_size.y
			
			print("Screen changed to: ", current_screen_size)
			print("New orientation: ", "Landscape" if is_landscape else "Portrait")
			
			var mobile_controls = get_tree().get_first_node_in_group("MobileControls")
			if mobile_controls and mobile_controls.has_method("update_button_positions"):
				mobile_controls.update_button_positions()

func get_screen_category() -> String:
	var width = current_screen_size.x
	
	if width < 600:
		return "small"
	elif width < 900:
		return "medium"
	elif width < 1200:
		return "large"
	else:
		return "xlarge"

func get_optimal_button_size() -> Vector2:
	var category = get_screen_category()
	
	match category:
		"small":
			return Vector2(60, 60)
		"medium":
			return Vector2(70, 70)
		"large":
			return Vector2(80, 80)
		"xlarge":
			return Vector2(90, 90)
		_:
			return Vector2(70, 70)

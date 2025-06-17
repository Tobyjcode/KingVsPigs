extends Control

func _ready():
	print("=== MOBILE TEST SCENE ===")
	print("OS Name: ", OS.get_name())
	print("Mobile feature: ", OS.has_feature("mobile"))
	print("Web feature: ", OS.has_feature("web"))
	print("Touch available: ", DisplayServer.is_touchscreen_available())
	
	# Force show mobile controls for testing
	var mobile_controls = preload("res://scenes/mobile_controls.tscn").instantiate()
	add_child(mobile_controls)
	mobile_controls.show()
	print("Mobile controls added to test scene")
	
	# Add a test label to show we're in the test scene
	var test_label = Label.new()
	test_label.text = "Mobile Test Scene - Controls should be visible below"
	test_label.position = Vector2(50, 50)
	add_child(test_label) 
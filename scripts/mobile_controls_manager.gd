extends Node

var mobile_controls_scene: PackedScene
var current_mobile_controls: Control
var is_mobile := false

func setup_mobile_controls():
	if not is_mobile or not mobile_controls_scene:
		print("Not setting up mobile controls - is_mobile: ", is_mobile, " scene: ", mobile_controls_scene)
		return
	
	current_mobile_controls = mobile_controls_scene.instantiate()
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(current_mobile_controls)
		print("Mobile controls added to scene!")
	else:
		print("No current scene found!")

func show_mobile_controls():
	if current_mobile_controls:
		print("Mobile controls shown")

func hide_mobile_controls():
	if current_mobile_controls:
		print("Mobile controls hidden")

func update_mobile_controls():
	if current_mobile_controls and current_mobile_controls.has_method("update_button_positions"):
		current_mobile_controls.update_button_positions()

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_mobile_controls()

func are_controls_active() -> bool:
	return current_mobile_controls != null and current_mobile_controls.visible

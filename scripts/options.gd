extends Control

@onready var music_slider = $Panel/VBoxContainer/MusicSlider
@onready var sfx_slider = $Panel/VBoxContainer/SFXSlider
@onready var mute_check = $Panel/VBoxContainer/MuteCheck
@onready var fullscreen_check = $Panel/VBoxContainer/FullscreenCheck
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var move_left_button = $Panel/VBoxContainer/ControlsContainer/MoveLeftHBox/MoveLeftButton
@onready var move_right_button = $Panel/VBoxContainer/ControlsContainer/MoveRightHBox/MoveRightButton
@onready var jump_button = $Panel/VBoxContainer/ControlsContainer/JumpHBox/JumpButton
@onready var attack_button = $Panel/VBoxContainer/ControlsContainer/AttackHBox/AttackButton
@onready var reset_button = $Panel/VBoxContainer/ResetButton

var rebinding_action := ""

const DEFAULT_KEYS = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"attack": KEY_E
}

func _ready():
	music_slider.value = get_music_volume()
	sfx_slider.value = get_sfx_volume()
	mute_check.button_pressed = is_muted()
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	move_left_button.pressed.connect(func(): _start_rebinding("move_left"))
	move_right_button.pressed.connect(func(): _start_rebinding("move_right"))
	jump_button.pressed.connect(func(): _start_rebinding("jump"))
	attack_button.pressed.connect(func(): _start_rebinding("attack"))

	_update_control_buttons()

	# Apply audio settings on load
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)

func _start_rebinding(action):
	rebinding_action = action
	_update_control_buttons()

func _on_input_event(viewport, event, shape_idx):
	if rebinding_action == "":
		return
	if event is InputEventKey and event.pressed:
		# Remove all previous events for this action
		for e in InputMap.action_get_events(rebinding_action):
			InputMap.action_erase_event(rebinding_action, e)
		InputMap.action_add_event(rebinding_action, event)
		rebinding_action = ""
		_update_control_buttons()
		return
	if event is InputEventMouseButton and event.pressed:
		for e in InputMap.action_get_events(rebinding_action):
			InputMap.action_erase_event(rebinding_action, e)
		InputMap.action_add_event(rebinding_action, event)
		rebinding_action = ""
		_update_control_buttons()
		return

func _update_control_buttons():
	move_left_button.text = _get_action_key_text("move_left") if rebinding_action != "move_left" else "Press a key..."
	move_right_button.text = _get_action_key_text("move_right") if rebinding_action != "move_right" else "Press a key..."
	jump_button.text = _get_action_key_text("jump") if rebinding_action != "jump" else "Press a key..."
	attack_button.text = _get_action_key_text("attack") if rebinding_action != "attack" else "Press a key..."

func _get_action_key_text(action):
	var events = InputMap.action_get_events(action)
	if events.size() == 1:
		var e = events[0]
		if e is InputEventKey and e.keycode == DEFAULT_KEYS.get(action, 0):
			return "%s (default)" % OS.get_keycode_string(e.keycode)
		if e is InputEventMouseButton:
			match e.button_index:
				1: return "Left Mouse (default)"
				2: return "Right Mouse (default)"
				3: return "Middle Mouse (default)"
	# Otherwise, show the current binding
	for e in events:
		if e is InputEventKey:
			return OS.get_keycode_string(e.keycode)
		if e is InputEventMouseButton:
			match e.button_index:
				1: return "Left Mouse"
				2: return "Right Mouse"
				3: return "Middle Mouse"
	return "-"

func _on_music_volume_changed(value):
	set_music_volume(value)
	if not mute_check.button_pressed:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(value))

func _on_sfx_volume_changed(value):
	set_sfx_volume(value)
	if not mute_check.button_pressed:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(value))

func _on_mute_toggled(pressed):
	set_muted(pressed)
	if pressed:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(0))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(0))
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(music_slider.value))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(sfx_slider.value))

func _on_fullscreen_toggled(pressed):
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# Audio
func get_music_volume():
	return ProjectSettings.get_setting("application/music_volume", 0.5)

func set_music_volume(value):
	ProjectSettings.set_setting("application/music_volume", value)
	ProjectSettings.save()

func get_sfx_volume():
	return ProjectSettings.get_setting("application/sfx_volume", 0.5)

func set_sfx_volume(value):
	ProjectSettings.set_setting("application/sfx_volume", value)
	ProjectSettings.save()

func is_muted():
	return ProjectSettings.get_setting("application/muted", false)

func set_muted(value):
	ProjectSettings.set_setting("application/muted", value)
	ProjectSettings.save()

# Helper
func linear2db(value):
	if value <= 0.0:
		return -80
	return 20 * log(value)

func _on_reset_pressed():
	music_slider.value = 0.5
	sfx_slider.value = 0.5
	mute_check.button_pressed = false
	fullscreen_check.button_pressed = false
	_reset_controls_to_default()
	_update_control_buttons()
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)

func _reset_controls_to_default():
	_set_action_to_key("move_left", KEY_A)
	_set_action_to_key("move_right", KEY_D)
	_set_action_to_key("jump", KEY_SPACE)
	_set_action_to_key("attack", KEY_E)

func _set_action_to_key(action, keycode):
	for e in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, e)
	var ev = InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

func _unhandled_input(event):
	if rebinding_action == "":
		return
	if event is InputEventKey and event.pressed:
		for e in InputMap.action_get_events(rebinding_action):
			InputMap.action_erase_event(rebinding_action, e)
		InputMap.action_add_event(rebinding_action, event)
		rebinding_action = ""
		_update_control_buttons()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		for e in InputMap.action_get_events(rebinding_action):
			InputMap.action_erase_event(rebinding_action, e)
		InputMap.action_add_event(rebinding_action, event)
		rebinding_action = ""
		_update_control_buttons()
		get_viewport().set_input_as_handled()

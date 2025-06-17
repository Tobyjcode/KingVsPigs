extends Control

# Mobile touch controls for the game
# Just some simple buttons that work on phones

signal action_pressed(action_name: String)
signal action_released(action_name: String)

var is_mobile := false
var touch_buttons := {}
var button_labels := {}
var screen_size := Vector2.ZERO

# Button setup - these are the controls we need
var button_configs := {
	"move_left": {
		"sprite": "transparentDark00.png",
		"text": "←",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"move_right": {
		"sprite": "transparentDark01.png",
		"text": "→",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"jump": {
		"sprite": "transparentDark02.png",
		"text": "↑",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"attack": {
		"sprite": "transparentDark03.png",
		"text": "⚔",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"sprint": {
		"sprite": "transparentDark04.png",
		"text": "🏃",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"game_use": {
		"sprite": "transparentDark05.png",
		"text": "⚡",
		"color": Color.WHITE,
		"size": Vector2(70, 70)
	},
	"pause": {
		"sprite": "transparentDark06.png",
		"text": "⏸",
		"color": Color.WHITE,
		"size": Vector2(50, 50)
	}
}

@onready var left_btn = $CanvasLayer/Left
@onready var right_btn = $CanvasLayer/Right
@onready var jump_btn = $CanvasLayer/Jump
@onready var attack_btn = $CanvasLayer/Attack
@onready var enter_door_btn = $CanvasLayer/EnterDoor
@onready var run_btn = $CanvasLayer/Run
@onready var restart_btn = $CanvasLayer/Restart

func _ready():
	update_button_positions()
	get_viewport().size_changed.connect(update_button_positions)

func _on_button_pressed(btn):
	btn.modulate = Color(1, 1, 0.7)

func _on_button_released(btn):
	btn.modulate = Color(1, 1, 1)

func show_controls():
	show()

func hide_controls():
	hide()

func update_screen_size():
	screen_size = get_viewport().get_visible_rect().size
	print("Screen: ", screen_size)

func get_button_position(action_name: String) -> Vector2:
	var config = button_configs[action_name]
	var button_size = config.size
	
	# Button positions - left side for movement, right side for actions
	var positions = {
		"move_left": Vector2(0.08, 0.8),      # Left movement
		"move_right": Vector2(0.18, 0.8),     # Right movement  
		"jump": Vector2(0.13, 0.7),           # Jump above movement
		"attack": Vector2(0.75, 0.8),         # Attack on right
		"sprint": Vector2(0.28, 0.8),         # Sprint next to movement
		"game_use": Vector2(0.85, 0.7),       # Use above attack
		"pause": Vector2(0.05, 0.05)          # Pause in corner
	}
	
	var pos_percent = positions[action_name]
	var final_position = Vector2(
		screen_size.x * pos_percent.x,
		screen_size.y * pos_percent.y
	)
	
	# Center the button
	final_position -= button_size / 2
	
	return final_position

func get_button_scale() -> float:
	# Scale buttons based on screen size
	var base_size = 800.0
	var scale_factor = screen_size.x / base_size
	
	# Keep scale reasonable
	scale_factor = clamp(scale_factor, 0.7, 1.5)
	
	return scale_factor

func create_mobile_controls():
	print("Creating mobile controls...")
	for action_name in button_configs:
		create_button(action_name)
	print("Created ", touch_buttons.size(), " buttons")

func create_button(action_name: String):
	var config = button_configs[action_name]
	var scale_factor = get_button_scale()
	
	# Make the touch button
	var button = TouchScreenButton.new()
	button.position = get_button_position(action_name)
	button.scale = Vector2.ONE * scale_factor
	
	# Try to load the sprite, fallback to colored button if not found
	var texture = load("res://Assets/Sprites/transparent-dark/" + config.sprite)
	if texture:
		button.texture = texture
		print("Loaded texture for ", action_name)
	else:
		button.texture = create_fallback_texture(config.size, Color.DARK_GRAY)
		print("Using fallback texture for ", action_name)
	
	# Add text label on top
	var label = Label.new()
	label.text = config.text
	label.add_theme_font_size_override("font_size", roundi(20.0 * scale_factor))
	label.add_theme_color_override("font_color", config.color)
	label.position = button.position + Vector2(25, 25) * scale_factor
	label.size = Vector2(20, 20) * scale_factor
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Connect button events
	button.pressed.connect(_on_button_pressed.bind(action_name))
	button.released.connect(_on_button_released.bind(action_name))
	
	# Store references
	touch_buttons[action_name] = button
	button_labels[action_name] = label
	
	# Add to scene
	add_child(button)
	add_child(label)
	print("Created button: ", action_name, " at ", button.position)

func create_fallback_texture(texture_size: Vector2, color: Color) -> Texture2D:
	# Make a simple colored button if sprite is missing
	var image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _input(event):
	if not is_mobile:
		return
	
	# Handle touch events
	if event is InputEventScreenTouch:
		for action_name in touch_buttons:
			var button = touch_buttons[action_name]
			var button_rect = Rect2(button.position, button.scale * 64)
			if button_rect.has_point(event.position):
				if event.pressed:
					_on_button_pressed(action_name)
				else:
					_on_button_released(action_name)

# Update button positions when screen changes
func update_button_positions():
	var screen_size = get_viewport().get_visible_rect().size
	var scale = clamp(screen_size.x / 1200.0, 0.7, 1.5)
	var margin = 64 * scale
	var button_gap_x = 120 * scale
	var button_gap_y = 120 * scale

	# Left cluster (bottom left, 2x2 grid)
	run_btn.position = Vector2(screen_size.x * 0.05, screen_size.y * 0.7)         # Sprint (top left)
	restart_btn.position = Vector2(screen_size.x * 0.15, screen_size.y * 0.7)     # Restart (top right)
	left_btn.position = Vector2(screen_size.x * 0.05, screen_size.y * 0.8)        # Left (bottom left)
	right_btn.position = Vector2(screen_size.x * 0.15, screen_size.y * 0.8)       # Right (bottom right)

	# Right cluster (bottom right, 2x2 grid)
	var base_x = screen_size.x - margin
	var base_y = screen_size.y - margin

	# Attack: a bit more to the right and a micro tiny bit up
	attack_btn.position = Vector2(base_x + button_gap_x * 0.2, base_y - button_gap_y * 0.07)

	# Jump: to the left and a bit higher
	jump_btn.position = Vector2(base_x - button_gap_x * 1.25, base_y - button_gap_y * 0.7)

	# Key: micro nudge to the right
	var key_x = (jump_btn.position.x + attack_btn.position.x) / 2 - button_gap_x * 0.38 + button_gap_x * 0.03
	var key_y = min(jump_btn.position.y, attack_btn.position.y) - button_gap_y * 0.6
	enter_door_btn.position = Vector2(key_x, key_y)

	# Scale all buttons
	for btn in [left_btn, right_btn, jump_btn, attack_btn, enter_door_btn, run_btn, restart_btn]:
		btn.scale = Vector2.ONE * scale

# Handle screen changes
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_button_positions()

func _on_viewport_size_changed():
	update_button_positions()

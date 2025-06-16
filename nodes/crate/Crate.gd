extends RigidBody2D

@export var fragment_count: int = 4
@export var diamond_chance: float = 0.9
@export var fragment_min_speed: float = 180
@export var fragment_max_speed: float = 260
@export var fragment_arc: float = 0.7 # 0=flat, 1=upward
@export var fragment_lifetime: float = 1.5

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit: AudioStreamPlayer2D = $Hit

var crate_frag_scene = preload("res://nodes/crate/CrateFrag.tscn")
var diamond_scene = preload("res://nodes/diamond.tscn")

var should_free = false

func _ready():
	$HitBox.area_entered.connect(_on_HitBox_area_entered)
	hit.finished.connect(_on_Hit_finished) # Connect the finished signal

func _on_HitBox_area_entered(area):
	print("Area entered:", area, "Groups:", area.get_groups(), "Monitoring:", area.monitoring)
	if area.is_in_group("player_attack"):
		print("Breaking crate!")
		break_into_fragments()

func break_into_fragments():
	# Play hit animation and sound
	animated_sprite.play("Hit")
	hit.stop()
	hit.play()
	await animated_sprite.animation_finished

	# Spawn fragments in a nice arc
	for i in range(fragment_count):
		var frag = crate_frag_scene.instantiate()
		get_parent().add_child(frag)
		frag.global_position = global_position
		# Launch in a circle, but with upward arc
		var angle = (2 * PI * i) / fragment_count
		angle = lerp_angle(angle, -PI/2, fragment_arc) # Blend toward upward
		var speed = randf_range(fragment_min_speed, fragment_max_speed)
		frag.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
		frag.get_node("AnimatedSprite2D").animation = str(randi() % 4)
		if frag.has_method("start_fade_timer"):
			frag.start_fade_timer(fragment_lifetime)

	# 90% chance to spawn a diamond
	if randf() < diamond_chance:
		var diamond = diamond_scene.instantiate()
		get_parent().add_child(diamond)
		diamond.global_position = global_position
		if diamond.has_method("set_velocity"):
			diamond.set_velocity(Vector2(0, -120))

	# Mark for freeing after sound
	should_free = true
	# If the sound is not playing for some reason, free immediately
	if not hit.playing:
		queue_free()

func _on_Hit_finished():
	if should_free:
		queue_free()

func _on_animation_finished():
	queue_free()

func _on_audio_finished():
	pass 

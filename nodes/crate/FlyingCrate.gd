extends RigidBody2D

@export var fragment_count: int = 4
@export var explode_delay: float = 0.7
@export var diamond_chance: float = 0.9

var crate_frag_scene = preload("res://nodes/crate/CrateFrag.tscn")
var diamond_scene = preload("res://nodes/diamond.tscn")

func _ready():
	# Start the timer for explosion
	await get_tree().create_timer(explode_delay).timeout
	explode()

func explode():
	# Spawn fragments
	for i in range(fragment_count):
		var frag = crate_frag_scene.instantiate()
		get_parent().add_child(frag)
		frag.global_position = global_position
		# Give each fragment a random velocity
		var angle = randf_range(0, 2*PI)
		var speed = randf_range(150, 300)
		frag.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
		frag.get_node("AnimatedSprite2D").animation = str(randi() % 4)
	# 90% chance to spawn a diamond
	if randf() < diamond_chance:
		var diamond = diamond_scene.instantiate()
		get_parent().add_child(diamond)
		diamond.global_position = global_position
		if diamond.has_method("set_velocity"):
			diamond.set_velocity(Vector2(0, -120))
	queue_free()
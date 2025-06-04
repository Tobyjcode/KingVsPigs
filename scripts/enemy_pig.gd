extends CharacterBody2D

const SPEED = 80.0
const PATROL_DISTANCE = 100.0
const DETECTION_RANGE = 150.0
const ATTACK_RANGE = 30.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_position: Vector2
var patrol_direction = 1
var is_attacking = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	start_position = position
	animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Check if player is in range
	if player and position.distance_to(player.position) < DETECTION_RANGE:
		# If close enough, attack
		if position.distance_to(player.position) < ATTACK_RANGE:
			if not is_attacking:
				is_attacking = true
				animated_sprite.play("attack")
				player.hit()
			# Always face the player during attack
			var direction = 1 if player.position.x > position.x else -1
			animated_sprite.flip_h = direction > 0
			velocity.x = 0
			move_and_slide()
			return
		else:
			# If player moves out of attack range, stop attacking
			if is_attacking:
				is_attacking = false
		# Move towards player
		var direction = 1 if player.position.x > position.x else -1
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction > 0
		animated_sprite.play("run")
	else:
		# Patrol behavior
		if is_attacking:
			is_attacking = false
		var distance_from_start = abs(position.x - start_position.x)
		if distance_from_start >= PATROL_DISTANCE:
			patrol_direction *= -1
		velocity.x = patrol_direction * SPEED
		# Flip based on patrol direction (velocity.x)
		if velocity.x != 0:
			animated_sprite.flip_h = velocity.x > 0
		animated_sprite.play("run")
	move_and_slide()

func _on_AnimatedSprite2D_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false 

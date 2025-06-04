extends CharacterBody2D

const SPEED = 80.0
const PATROL_DISTANCE = 100.0
const DETECTION_RANGE = 150.0
const ATTACK_RANGE = 30.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_position: Vector2
var patrol_direction = 1
var is_attacking = false
var is_on_cooldown = false
var is_hit = false
var is_winding_up = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var attack_windup_timer: Timer = $AttackWindupTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var hit_timer: Timer = $HitTimer
@onready var attack_area = $AttackArea

func _ready():
	start_position = position
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_windup_timer.timeout.connect(_on_attack_windup_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	hit_timer.timeout.connect(_on_hit_timer_timeout)

func _physics_process(delta):
	if is_hit:
		return
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Check if player is in range
	if player and position.distance_to(player.position) < DETECTION_RANGE:
		# If close enough, start windup if not already attacking or winding up or cooling down
		if position.distance_to(player.position) < ATTACK_RANGE:
			if not is_attacking and not is_on_cooldown and not is_winding_up:
				is_winding_up = true
				animated_sprite.play("attack")
				attack_windup_timer.start()
			# Always face the player during attack or windup
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

func _on_attack_windup_timeout():
	is_winding_up = false
	is_attacking = true
	if player and position.distance_to(player.position) < ATTACK_RANGE:
		player.hit()
	attack_cooldown_timer.start()

func _on_attack_cooldown_timeout():
	is_attacking = false
	is_on_cooldown = false

func _on_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false
		is_on_cooldown = true

func _on_hit_timer_timeout():
	is_hit = false

func hit():
	if not is_hit:
		print("Piggy got hit!")
		is_hit = true
		animated_sprite.play("hit")
		hit_timer.start()

func attack():
	attack_area.monitoring = true
	var bodies = attack_area.get_overlapping_bodies()
	print("Bodies in attack area: ", bodies)
	for body in bodies:
		if body.has_method("hit"):
			print("Hitting: ", body)
			body.hit()
	attack_area.monitoring = false

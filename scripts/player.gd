extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false
var is_hit = false
var is_on_cooldown = false
var is_winding_up = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_timer: Timer = $HitTimer
@onready var attack_area = $AttackArea
@onready var jump_sound = $JumpSound
@onready var hit_sound = $HitSound
@onready var attack_sound = $AttackSound

func _ready():
	animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	hit_timer.timeout.connect(_on_HitTimer_timeout)

func _physics_process(delta):
	if is_hit:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle attack
	if not is_attacking and Input.is_action_just_pressed("attack"):
		is_attacking = true
		animated_sprite.play("attack")
		attack_sound.play()
		attack()

	# Prevent movement and jumping while attacking or hit
	if is_attacking or is_hit:
		velocity.x = 0
		move_and_slide()
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_attacking:
		# Attack animation is already playing
		pass
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_AnimatedSprite2D_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false

func hit():
	if not is_hit:
		is_hit = true
		animated_sprite.play("hit")
		hit_sound.play()
		hit_timer.start()

func _on_HitTimer_timeout():
	is_hit = false

func attack():
	attack_area.monitoring = true
	var bodies = attack_area.get_overlapping_bodies()
	print("Bodies in attack area: ", bodies)
	for body in bodies:
		if body.has_method("hit"):
			print("Hitting: ", body)
			body.hit()
	attack_area.monitoring = false

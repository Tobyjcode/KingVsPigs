extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false
var is_hit = false
var is_on_cooldown = false
var is_winding_up = false
var lives := 3
var is_dead := false
var is_entering_door = false
var knockback_velocity := Vector2.ZERO
var is_falling := false

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_timer: Timer = $HitTimer
@onready var attack_area = $AttackArea
@onready var jump_sound = $JumpSound
@onready var hit_sound = $HitSound
@onready var attack_sound = $AttackSound
@onready var restart_message: TextureRect = $RestartMessage
@onready var attack_timer: Timer = $AttackTimer
@onready var walking: AudioStreamPlayer2D = $Walking

func _ready():
	animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	hit_timer.timeout.connect(_on_HitTimer_timeout)
	if attack_timer:
		attack_timer.timeout.connect(_on_AttackTimer_timeout)
	var hud = get_tree().get_first_node_in_group("ScoreUI")
	if hud:
		if hud.has_method("show_restart_message"):
			hud.show_restart_message()
	animated_sprite.play("idle")

func _physics_process(delta):
	if is_dead:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if is_entering_door:
		return

	# FALLING/knockback logic comes BEFORE is_hit!
	if is_falling:
		velocity = knockback_velocity
		knockback_velocity.y += gravity * delta
		move_and_slide()
		return

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
		if walking.playing:
			walking.stop()
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
			if walking.playing:
				walking.stop()
		else:
			animated_sprite.play("run")
			if not walking.playing:
				walking.play()
	else:
		animated_sprite.play("jump")
		if walking.playing:
			walking.stop()
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_AnimatedSprite2D_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false
		check_attack_area()  # Check one final time when animation ends
	elif animated_sprite.animation == "doorIn":
		is_entering_door = false
	elif animated_sprite.animation == "hit":
		animated_sprite.play("fall")
	elif animated_sprite.animation == "fall":
		animated_sprite.play("ground")
	elif animated_sprite.animation == "ground":
		is_falling = false

func hit(attacker = null):
	if not is_hit and not is_dead:
		is_hit = true
		animated_sprite.play("hit")
		hit_sound.play()
		hit_timer.start()
		lives -= 1
		update_hearts()
		# Knockback effect
		var knockback_dir = 1
		if attacker and attacker.has_method("global_position"):
			knockback_dir = sign(global_position.x - attacker.global_position.x)
			if knockback_dir == 0:
				knockback_dir = 1
		knockback_velocity = Vector2(200 * knockback_dir, -100)
		is_falling = true
		if lives <= 0:
			die()

func _on_HitTimer_timeout():
	is_hit = false

func attack():
	attack_area.monitoring = true
	if attack_timer:
		attack_timer.start()
	check_attack_area()

func check_attack_area():
	var bodies = attack_area.get_overlapping_bodies()
	print("Bodies in attack area: ", bodies)
	for body in bodies:
		if body.has_method("hit"):
			print("Hitting: ", body)
			body.hit()

func _on_AttackTimer_timeout():
	if attack_area:
		attack_area.monitoring = false

func update_hearts():
	var hud = get_tree().get_first_node_in_group("ScoreUI")
	if hud:
		var lifebars = hud.get_node("ScoreUIContainer/LifeBars/Lifebars")
		for i in range(3):
			var heart = lifebars.get_child(i)
			if i < lives:
				heart.play_idle()
			else:
				heart.play_hit()

func die():
	print("Player died! (die() called)")
	is_dead = true
	animated_sprite.play("dead")
	var death_screen = get_tree().get_root().find_child("DeathScreen", true, false)
	if death_screen:
		death_screen.visible = true

func play_door_in():
	is_entering_door = true
	velocity = Vector2.ZERO  # Stop movement
	animated_sprite.play("doorIn")

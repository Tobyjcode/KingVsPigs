extends CharacterBody2D

const SPEED = 130.0
const RUN_SPEED = 220.0
const JUMP_VELOCITY = -400.0

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
var timer_running := false
var is_invincible = false
var invincibility_timer: Timer

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_timer: Timer = $HitTimer
@onready var attack_area = $AttackArea
@onready var attack_shape = $AttackArea/CollisionPolygon2D
@onready var jump_sound = get_node_or_null("JumpSound")
@onready var hit_sound = get_node_or_null("HitSound")
@onready var attack_sound = get_node_or_null("AttackSound")
@onready var restart_message = get_node_or_null("RestartMessage")
@onready var attack_timer = get_node_or_null("AttackTimer")
@onready var walking = get_node_or_null("Walking")
@onready var die_sound = get_node_or_null("DieSound")

func _ready():
	visible = false  # Make player invisible at start
	animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	hit_timer.timeout.connect(_on_HitTimer_timeout)
	if attack_timer:
		attack_timer.timeout.connect(_on_AttackTimer_timeout)
	
	# Create invincibility timer
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = 1.0  # 1 second of invincibility
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)
	
	var hud = get_tree().get_first_node_in_group("ScoreUI")
	if hud:
		if hud.has_method("show_restart_message"):
			hud.show_restart_message()
	Globals.level_time = 0.0
	timer_running = true
	animated_sprite.play("idle")
	attack_area.monitoring = false
	attack_shape.disabled = true

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
		attack_area.monitoring = true
		attack_shape.disabled = false
		animated_sprite.play("attack")
		if attack_sound:
			attack_sound.play()
		attack()
		if attack_timer:
			attack_timer.start()

	# Prevent movement and jumping while attacking or hit
	if is_attacking or is_hit:
		velocity.x = 0
		move_and_slide()
		return

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if jump_sound:
			jump_sound.play()

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
		attack_area.scale.x = 1
	elif direction < 0:
		animated_sprite.flip_h = true
		attack_area.scale.x = -1
	
	# Play animations
	if is_attacking:
		if walking and walking.playing:
			walking.stop()
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
			if walking and walking.playing:
				walking.stop()
		else:
			animated_sprite.play("run")
			if walking and not walking.playing:
				walking.play()
	else:
		animated_sprite.play("jump")
		if walking and walking.playing:
			walking.stop()
	
	# Apply movement
	if direction:
		var current_speed = SPEED
		if Input.is_action_pressed("sprint"):
			current_speed = RUN_SPEED
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_AnimatedSprite2D_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false
		check_attack_area()
	elif animated_sprite.animation == "doorIn":
		is_entering_door = false
		var hud = get_tree().get_first_node_in_group("ScoreUI")
		if hud and hud.has_method("submit_score"):
			hud.submit_score()
	elif animated_sprite.animation == "hit":
		animated_sprite.play("fall")
	elif animated_sprite.animation == "fall":
		animated_sprite.play("ground")
	elif animated_sprite.animation == "ground":
		is_falling = false

func hit(attacker = null):
	if not is_hit and not is_dead and not is_invincible:
		is_hit = true
		is_invincible = true
		animated_sprite.play("hit")
		if hit_sound:
			hit_sound.play()
		hit_timer.start()
		invincibility_timer.start()
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
	check_attack_area()

func check_attack_area():
	var bodies = attack_area.get_overlapping_bodies()
	print("Bodies in attack area: ", bodies)
	for body in bodies:
		if body.has_method("hit"):
			print("Hitting: ", body)
			body.hit()

func _on_AttackTimer_timeout():
	attack_area.monitoring = false
	attack_shape.disabled = true
	is_attacking = false

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
	if die_sound:
		die_sound.play()
	
	# Automatically submit highscore
	if Engine.has_singleton("HighscoreManager"):
		HighscoreManager.submit_score(Globals.diamond_score)
	else:
		var highscore_manager = get_node_or_null("/root/HighscoreManager")
		if highscore_manager:
			highscore_manager.submit_score(Globals.diamond_score)
	
	var death_screen = get_tree().get_root().find_child("DeathScreen", true, false)
	if death_screen:
		death_screen.visible = true

func play_door_in():
	is_entering_door = true
	velocity = Vector2.ZERO  # Stop movement
	animated_sprite.play("doorIn")

func play_door_out():
	is_entering_door = true
	visible = true
	animated_sprite.play("doorOut")
	await get_tree().create_timer(0.8).timeout  # Adjust to match your animation
	is_entering_door = false

func submit_score():
	var hud = get_tree().get_first_node_in_group("ScoreUI")
	if hud and hud.has_method("submit_score"):
		hud.submit_score()

func _process(delta):
	if timer_running:
		Globals.level_time += delta

func on_victory():
	print("Victory triggered! Level time:", Globals.level_time, "Total time before:", Globals.total_level_time)
	timer_running = false
	Globals.total_level_time += Globals.level_time
	print("Total time after:", Globals.total_level_time)
	get_tree().change_scene_to_file("res://scenes/levels/victoryscene.tscn")

func _on_Door_body_entered(body):
	if body == self:
		on_victory()

func end_level():
	timer_running = false
	Globals.total_level_time += Globals.level_time

func _on_invincibility_timeout():
	is_invincible = false

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
var lives := 3
var is_dead = false
var knockback_velocity := Vector2.ZERO
var is_falling = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var attack_windup_timer: Timer = $AttackWindupTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var hit_timer: Timer = $HitTimer
@onready var attack_area = $AttackArea
@onready var walking = get_node_or_null("Walking")
@onready var attack_shape = $AttackArea/CollisionPolygon2D
@onready var attack_sound = get_node_or_null("PiggyAttackAudioStreamPlayer2D")
@onready var die_sound = get_node_or_null("PiggyDieAudioStreamPlayer2D2")
@onready var hit_sound = get_node_or_null("PiggyHitAudioStreamPlayer2D3")

func _ready():
	start_position = position
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_windup_timer.timeout.connect(_on_attack_windup_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	hit_timer.timeout.connect(_on_hit_timer_timeout)

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		attack_area.monitoring = false
		attack_area.monitorable = false
		return
	if is_falling:
		velocity = knockback_velocity
		knockback_velocity.y += gravity * delta
		move_and_slide()
		return
	if is_hit:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if player and position.distance_to(player.position) < DETECTION_RANGE:
		if position.distance_to(player.position) < ATTACK_RANGE:
			if not is_attacking and not is_on_cooldown and not is_winding_up and not is_dead:
				is_attacking = true
				is_winding_up = true
				animated_sprite.play("attack")
				if attack_sound:
					attack_sound.play()
				attack_windup_timer.start()
			
			var direction = 1 if player.position.x > position.x else -1
			animated_sprite.flip_h = direction > 0
			velocity.x = 0
			move_and_slide()
			return
		else:
			if is_attacking:
				is_attacking = false
		
		var direction = 1 if player.position.x > position.x else -1
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction > 0
		animated_sprite.play("run")
	else:
		if is_attacking:
			is_attacking = false
		var distance_from_start = abs(position.x - start_position.x)
		if distance_from_start >= PATROL_DISTANCE:
			patrol_direction *= -1
		velocity.x = patrol_direction * SPEED
		if velocity.x != 0:
			animated_sprite.flip_h = velocity.x > 0
		animated_sprite.play("run")
	move_and_slide()

func _on_attack_windup_timeout():
	is_winding_up = false
	if not is_dead and player and position.distance_to(player.position) < ATTACK_RANGE:
		player.hit()

func _on_attack_cooldown_timeout():
	is_on_cooldown = false

func _on_animation_finished():
	if animated_sprite.animation == "hit":
		animated_sprite.play("fall")
	elif animated_sprite.animation == "fall":
		animated_sprite.play("ground")
	elif animated_sprite.animation == "ground":
		is_falling = false
	elif animated_sprite.animation == "attack":
		is_attacking = false
		is_on_cooldown = true
		attack_cooldown_timer.start()
	elif animated_sprite.animation == "dead":
		pass

func _on_hit_timer_timeout():
	is_hit = false

func hit():
	if is_dead or is_hit:
		return
	is_hit = true
	lives -= 1
	if lives <= 0:
		is_dead = true
		animated_sprite.play("dead")
		velocity = Vector2.ZERO
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)
		attack_windup_timer.stop()
		attack_cooldown_timer.stop()
		if die_sound:
			die_sound.play()
	else:
		animated_sprite.play("hit")
		if hit_sound:
			hit_sound.play()
		var dir = sign(global_position.x - player.global_position.x)
		if dir == 0:
			dir = 1
		knockback_velocity = Vector2(150 * dir, -80)
		is_falling = true
	hit_timer.start()

func attack():
	attack_area.monitoring = true
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("hit"):
			body.hit()
	attack_area.monitoring = false

extends CharacterBody2D

enum State { IDLE, BEFORE_JUMP, HIT, FALL, GROUND, JUMP, LOOKING_OUT }

const SPEED = 80.0
const JUMP_FORCE = 300.0
const ATTACK_COOLDOWN = 1.6
const CLOSE_RANGE = 100.0  # Distance to consider player "close"
const LOOK_UP_INTERVAL_MIN = 2.0  # Minimum time between looking up
const LOOK_UP_INTERVAL_MAX = 4.0  # Maximum time between looking up
const LOOK_UP_DURATION = 1.0  # How long to stay looking up

var cur_state = State.IDLE
var next_state = null
var _dir = 1
var _jmp_dir = 1
var atk_cd = -0.1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var triggered = false
var rng = RandomNumberGenerator.new()
var player_in_view = false
var look_up_timer = 0.0
var is_looking_up = false
var is_player_close = false
var was_looking_out = false

var piggy_scene = preload("res://scenes/piggy.tscn")
var crate_frag_scene = preload("res://nodes/crate/CrateFrag.tscn")

@onready var animated_sprite = $SpriteAnchor/AnimatedSprite2D
@onready var sprite_anchor = $SpriteAnchor
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	rng.randomize()
	cur_state = State.IDLE
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_set_animation_for_state(State.IDLE)
	look_up_timer = rng.randf_range(LOOK_UP_INTERVAL_MIN, LOOK_UP_INTERVAL_MAX)

func _physics_process(delta):
	atk_cd -= delta
	look_up_timer -= delta

	# Check if player is close
	if player and player_in_view:
		var distance = global_position.distance_to(player.global_position)
		is_player_close = distance < CLOSE_RANGE

	var state = cur_state
	match cur_state:
		State.IDLE:
			state = state_idle(delta)
		State.BEFORE_JUMP:
			state = state_before_jump()
		State.HIT:
			state = state_hit()
		State.FALL:
			state = state_fall()
		State.GROUND:
			state = state_ground()
		State.JUMP:
			state = state_jump()
		State.LOOKING_OUT:
			state = state_looking_out()
	if next_state != null:
		if next_state != cur_state:
			_set_animation_for_state(next_state)
		cur_state = next_state
		next_state = null
	else:
		cur_state = state
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

	if cur_state == State.LOOKING_OUT:
		was_looking_out = true
	else:
		was_looking_out = false

func _set_animation_for_state(state):
	match state:
		State.IDLE:
			animated_sprite.play("hide")
		State.LOOKING_OUT:
			animated_sprite.play("idle")
		State.BEFORE_JUMP:
			animated_sprite.play("jumpantip")
		State.JUMP:
			animated_sprite.play("jump")
		State.FALL:
			animated_sprite.play("fall")
		State.GROUND:
			animated_sprite.play("ground")
		State.HIT:
			animated_sprite.play("fall")

func state_idle(delta):
	if look_up_timer <= 0:
		next_state = State.LOOKING_OUT
		return next_state

	# Attack behavior
	if player and player_in_view and atk_cd <= 0:
		var x_delta = global_position.x - player.global_position.x
		_dir = -1 if x_delta > 0 else 1
		sprite_anchor.scale.x = -_dir

		# More aggressive when player is close
		if is_player_close:
			atk_cd = ATTACK_COOLDOWN * 0.5  # Attack more frequently when close
			ready_jump(_dir)
		else:
			ready_jump(_dir)
	return cur_state

func state_before_jump():
	if velocity.y < 0:
		return State.JUMP
	return cur_state

func state_hit():
	velocity.x *= 0.1
	return cur_state

func state_fall():
	if is_on_floor():
		print("is_on_floor() true, switching to GROUND")
		return State.GROUND
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 16))
	params.exclude = [self]
	var result = space_state.intersect_ray(params)
	if result:
		print("Raycast hit ground, switching to GROUND")
		return State.GROUND
	print("Still falling")
	return cur_state

func state_ground():
	velocity.x *= 0.15
	return cur_state

func state_jump():
	if is_on_floor():
		return State.GROUND
	elif velocity.y > 0:
		return State.FALL
	return cur_state

func state_looking_out():
	# Do nothing, just wait for the animation to finish
	# Attack behavior
	if player and player_in_view and atk_cd <= 0:
		var x_delta = global_position.x - player.global_position.x
		_dir = -1 if x_delta > 0 else 1
		sprite_anchor.scale.x = -_dir
		ready_jump(_dir)
	return cur_state

func ready_jump(dir):
	if cur_state in [State.IDLE, State.LOOKING_OUT]:
		if atk_cd > 0:
			return
		atk_cd = ATTACK_COOLDOWN
		_jmp_dir = dir
		next_state = State.BEFORE_JUMP

func spawn_fragments():
	print("Spawning crate fragments!")
	var fragment_count = 4
	var fragment_arc = 0.7
	var fragment_min_speed = 80
	var fragment_max_speed = 120
	var fragment_lifetime = 1.5
	for i in range(fragment_count):
		var frag = crate_frag_scene.instantiate()
		get_tree().get_root().add_child(frag)
		frag.global_position = global_position
		var angle = (2 * PI * i) / fragment_count
		angle = lerp_angle(angle, -PI/2, fragment_arc)
		var speed = randf_range(fragment_min_speed, fragment_max_speed)
		frag.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
		frag.get_node("AnimatedSprite2D").animation = str(randi() % 4)
		if frag.has_method("start_fade_timer"):
			frag.start_fade_timer(fragment_lifetime)

func on_hit_box_entered(area):
	print("Hitbox entered by: ", area)
	if area.is_in_group("attack_box") and area.name != "BoxAtkBox":
		_dir = 1 if area.global_position.x < global_position.x else -1
		next_state = State.HIT
		_set_animation_for_state(State.HIT)
		
		# Spawn crate fragments!
		spawn_fragments()
		
		# Spawn a regular piggy
		var piggy = piggy_scene.instantiate()
		get_parent().add_child(piggy)
		piggy.global_position = global_position
		piggy.get_node("AnimatedSprite2D").flip_h = _dir < 0
		
		# Wait a short moment to ensure fragments are visible, then free
		await get_tree().create_timer(0.05).timeout
		queue_free()

func on_view_range_entered(body):
	if body.is_in_group("player"):
		player_in_view = true
		triggered = true

func on_view_range_exited(body):
	if body.is_in_group("player"):
		player_in_view = false

func _on_animation_finished():
	match animated_sprite.animation:
		"idle":
			look_up_timer = rng.randf_range(LOOK_UP_INTERVAL_MIN, LOOK_UP_INTERVAL_MAX)
			next_state = State.IDLE
		"ground":
			look_up_timer = rng.randf_range(LOOK_UP_INTERVAL_MIN, LOOK_UP_INTERVAL_MAX)
			next_state = State.IDLE
		"jumpantip":
			next_state = State.JUMP
		"fall":
			next_state = State.GROUND
		"jump":
			sprite_anchor.scale.x = -_jmp_dir
			velocity.x = _jmp_dir * SPEED * 2
			velocity.y = -JUMP_FORCE

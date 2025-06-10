extends CharacterBody2D

enum State { IDLE, BEFORE_JUMP, HIT, FALL, GROUND, JUMP, LOOKING_OUT }

const SPEED = 80.0
const JUMP_FORCE = 300.0
const ATTACK_COOLDOWN = 1.6

var cur_state = State.IDLE
var next_state = null
var _dir = 1
var _jmp_dir = 1
var atk_cd = -0.1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var triggered = false
var rng = RandomNumberGenerator.new()
var player_in_view = false

@onready var animated_sprite = $SpriteAnchor/AnimatedSprite2D
@onready var sprite_anchor = $SpriteAnchor
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	rng.randomize()
	cur_state = State.IDLE
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("idle")

func _physics_process(delta):
	atk_cd -= delta
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

func _set_animation_for_state(state):
	match state:
		State.IDLE, State.LOOKING_OUT:
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
			animated_sprite.play("fall") # fallback, or add a hit anim if you have one

func state_idle(delta):
	if not triggered:
		return cur_state
	if player and player_in_view and atk_cd <= 0:
		var x_delta = global_position.x - player.global_position.x
		_dir = -1 if x_delta > 0 else 1
		sprite_anchor.scale.x = -_dir
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
		return State.GROUND
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

func _on_animation_finished():
	match animated_sprite.animation:
		"ground":
			next_state = State.IDLE
		"jumpantip":
			next_state = State.JUMP
		"fall":
			next_state = State.GROUND
		"jump":
			sprite_anchor.scale.x = -_jmp_dir
			velocity.x = _jmp_dir * SPEED * 2
			velocity.y = -JUMP_FORCE

func on_hit_box_entered(area):
	if area.is_in_group("attack_box") and area.name != "BoxAtkBox":
		_dir = 1 if area.global_position.x < global_position.x else -1
		next_state = State.HIT
		_set_animation_for_state(State.HIT)

func on_view_range_entered(body):
	if body.is_in_group("player"):
		player_in_view = true
		triggered = true

func on_view_range_exited(body):
	if body.is_in_group("player"):
		player_in_view = false

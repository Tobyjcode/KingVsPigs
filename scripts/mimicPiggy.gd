extends CharacterBody2D

enum State { IDLE, BEFORE_JUMP, HIT, FALL, GROUND, JUMP, LOOKING_OUT }

var state = State.IDLE
var next_state = null
var atk_cd = -0.1
var _dir = 1
var _jmp_dir = 1
var speed = 100.0
var jump_force = 300.0
var hit = false
var dir := Vector2.ZERO
var invincible_timer := 0.0
var trigger = true # <--- Set this at the top for testing
var rng = RandomNumberGenerator.new()
var player_in_view = false
var player

@onready var sprite_anchor = $SpriteAnchor
@onready var hitbox = $Hitbox

func _ready():
	change_state(State.IDLE)
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	rng.randomize()

func _physics_process(delta):
	atk_cd -= delta
	var new_state = state
	match state:
		State.IDLE:
			new_state = state_idle(delta)
		State.BEFORE_JUMP:
			new_state = state_before_jump()
		State.HIT:
			new_state = state_hit()
		State.FALL:
			new_state = state_fall()
		State.GROUND:
			new_state = state_ground()
		State.JUMP:
			new_state = state_jump()
		State.LOOKING_OUT:
			new_state = state_looking_out()
		_:
			pass
	if next_state != null:
		new_state = next_state
		next_state = null
	if new_state != state:
		change_state(new_state)
	move_and_slide()

func state_idle(delta):
	if not triggered:
		return state
	if player and player_in_view and atk_cd <= 0:
		var x_delta = global_position.x - player.global_position.x
		_dir = -1 if x_delta > 0 else 1
		sprite_anchor.scale.x = -_dir
		ready_jump(_dir)
	return state

func state_before_jump():
	speed_handler()
	if velocity.y < 0:
		return State.JUMP
	return state

func state_hit():
	speed_handler(0.1)
	return state

func state_fall():
	if is_on_floor():
		return State.GROUND
	return state

func state_ground():
	speed_handler(0.15)
	return state

func state_jump():
	if is_on_floor():
		return State.GROUND
	elif velocity.y > 0:
		return State.FALL
	return state

func state_looking_out():
	if player and player_in_view and atk_cd <= 0:
		var x_delta = global_position.x - player.global_position.x
		_dir = -1 if x_delta > 0 else 1
		sprite_anchor.scale.x = -_dir
		ready_jump(_dir)
	return state

func speed_handler(factor := 1.0):
	# Implement friction/acceleration if needed
	pass

func ready_jump(dir):
	if state in [State.IDLE, State.LOOKING_OUT]:
		if atk_cd > 0.0:
			return
		atk_cd = 1.6
		_jmp_dir = dir
		next_state = State.BEFORE_JUMP

func on_animation_finished(anim_name):
	var state_enum = State.values().find(anim_name)
	if state_enum == State.GROUND:
		next_state = State.IDLE
	elif state_enum == State.BEFORE_JUMP:
		next_state = State.JUMP
	if state_enum == State.HIT:
		generate_fragments()
		generate_pig()
		queue_free()
	elif state_enum == State.BEFORE_JUMP:
		sprite_anchor.scale = Vector2(-_jmp_dir, 1)
		velocity.x = _jmp_dir * speed * 2
		velocity.y = -jump_force

func generate_fragments():
	var parent = get_parent()
	for i in range(4):
		var frag = preload("res://nodes/crate/CrateFrag.tscn").instantiate()
		frag.global_position = global_position
		# Set fragment velocity here if needed
		parent.add_child(frag)

func generate_pig():
	var parent = get_parent()
	var pig = preload("res://scenes/Pig.tscn").instantiate()
	pig.face_dir = sprite_anchor.scale.x > 0
	pig.global_position = global_position + Vector2.UP * 2
	parent.add_child(pig)

func _on_hitbox_area_entered(area):
	if invincible_timer <= 0 and not hit and area.is_in_group("attack_box") and area.name != "BoxAtkBox":
		hit = true
		_dir = -1 if area.global_position.x > global_position.x else 1
		next_state = State.HIT

func change_state(new_state):
	state = new_state

func state_wander(delta):
	if invincible_timer < 0:
		invincible_timer = rng.randi_range(2, 5)
	invincible_timer -= delta
	speed_handler()
	velocity.x = _dir * speed

func on_view_range_entered(body):
	if body.is_in_group("player"):
		player_in_view = true
		player = body

func on_view_range_exited(body):
	if body.is_in_group("player"):
		player_in_view = false

extends Node

enum State { IDLE, ALERT, ATTACK }

var cur_state = State.IDLE
var next_state = null
var _target = null
var _dir = 1
var _timer = 2.0
var triggered = false
var rng = RandomNumberGenerator.new()
@onready var body = get_parent()

func _ready():
	rng.randomize()
	cur_state = State.IDLE

func _physics_process(delta):
	var state = cur_state
	match cur_state:
		State.IDLE:
			state = state_idle(delta)
		State.ATTACK:
			state = state_attack()
		_:
			pass
	if next_state != null:
		cur_state = next_state
		next_state = null
	else:
		cur_state = state

func state_idle(delta):
	if not triggered:
		return cur_state
	if _timer > 0:
		_timer -= delta
	else:
		if body.state == body.State.LOOKING_OUT:
			body.next_state = body.State.IDLE
			_timer = rng.randi_range(4, 8)
		elif body.state == body.State.IDLE:
			body.next_state = body.State.LOOKING_OUT
			_timer = rng.randi_range(2, 4)
	return cur_state

func state_attack():
	if _target == null:
		return State.IDLE
	var x_delta = body.global_position.x - _target.global_position.x
	_dir = -1 if x_delta > 0 else 1
	body.ready_jump(_dir)
	return cur_state

func on_atk_range_entered(area):
	body.can_attack = true
	next_state = State.ATTACK

func on_atk_range_exited(area):
	body.can_attack = false
	next_state = State.IDLE

func on_view_range_entered(area):
	next_state = State.ALERT
	body.next_state = body.State.LOOKING_OUT
	_target = area

func on_view_range_exited(area):
	_target = null
	body.next_state = body.State.IDLE
	next_state = State.IDLE
	triggered = true

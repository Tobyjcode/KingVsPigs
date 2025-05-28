extends Node

enum State { IDLE, WANDER, ATTACK }

@export var dir := -1
var cur_state = State.IDLE
var trans_timer = 0.0
var trigger = false
var target = null
var aim_timer = 0.8
var rng = RandomNumberGenerator.new()
@onready var body = get_parent() # Assumes this is a child of CratePig

func _ready():
	cur_state = State.IDLE

func _physics_process(delta):
	match cur_state:
		State.IDLE:
			state_idle(delta)
		State.WANDER:
			state_wander(delta)
		State.ATTACK:
			state_attack(delta)

func state_idle(delta):
	if trans_timer < 0 and trigger:
		trans_timer = rng.randi_range(2, 4)
		cur_state = State.WANDER
	else:
		trans_timer -= delta

func state_wander(delta):
	if trans_timer < 0:
		trans_timer = rng.randi_range(2, 5)
		cur_state = State.IDLE
	trans_timer -= delta
	if body.is_on_wall() or (body.is_on_floor() and not $RayCast2D.is_colliding()):
		dir = -dir
	body.movement_handler(dir)

func state_attack(delta):
	if target:
		var direction = 1 if target.global_position.x > body.global_position.x else -1
		body.movement_handler(direction, 0)
		if body.state != body.State.THROWING:
			if aim_timer < 0:
				body.change_state(body.State.THROWING)
				body.dir = (target.global_position - body.global_position).normalized()
			else:
				aim_timer -= delta

func on_view_range_entered(area):
	trigger = true
	target = area
	cur_state = State.ATTACK

func on_view_range_exited(_area):
	if aim_timer < 0.7:
		return
	aim_timer = 0.8
	cur_state = State.IDLE

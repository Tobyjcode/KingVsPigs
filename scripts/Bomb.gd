extends CharacterBody2D

@export var fly_left: bool = true

var gravity = 150
var is_boom = false
var can_boom = false
var player_near = false
var jumped = false

func _ready():
	velocity = Vector2(-20, -1) if fly_left else Vector2(0, -1)
	add_to_group("enemies")

func boom():
	$BoomDetector.monitorable = true
	$BoomDetector.monitoring = true
	$Ani.play("Boom")

func turn_off_detector():
	$BoomDetector.monitorable = false
	$BoomDetector.monitoring = false
	collision_mask = 6

func _physics_process(delta):
	if is_on_floor():
		velocity.x = 0
	elif player_near and !jumped:
		velocity = Vector2(0, -20)
		jumped = true
	elif player_near:
		velocity = Vector2.ZERO
	else:
		velocity.y += gravity * delta
		set_velocity(velocity)
		set_up_direction(Vector2.UP)
		move_and_slide()
		velocity.y = velocity.y
	
	if player_near and can_boom and !is_boom:
		$Ani.play("On")
		is_boom = true

func _on_StartDetector_body_entered(body):
	if body.is_in_group("player"):
		player_near = true

func _on_StartDetector_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		jumped = false

func _on_BoomDetector_body_entered(body):
	if body.has_method("hit"):
		body.hit()

func hit():
	boom()

func _on_StartDetecting_timeout():
	can_boom = true
	
	

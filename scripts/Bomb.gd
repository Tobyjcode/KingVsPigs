extends CharacterBody2D

@export var fly_left: bool = true

var gravity = 150
var is_boom = false
var can_boom = false
var player_near = false
var jumped = false
var is_hit = false
var knockback_velocity = Vector2.ZERO
var is_falling = false
var was_hit = false
var boom_timer = null

func _ready():
	velocity = Vector2(-20, -1) if fly_left else Vector2(0, -1)
	add_to_group("enemies")
	collision_layer = 8  # Layer 8 (enemy layer that player can hit)
	collision_mask = 5   # Mask 1 (world) and 4 (player)
	boom_timer = Timer.new()
	boom_timer.one_shot = true
	boom_timer.wait_time = 0.5  # 0.5s fuse after landing
	boom_timer.connect("timeout", Callable(self, "boom"))
	add_child(boom_timer)

func boom():
	$BoomDetector.monitorable = true
	$BoomDetector.monitoring = true
	$Ani.play("Boom")

func turn_off_detector():
	$BoomDetector.monitorable = false
	$BoomDetector.monitoring = false
	collision_mask = 6

func _physics_process(delta):
	if is_falling:
		velocity = knockback_velocity
		knockback_velocity.y += gravity * delta
		move_and_slide()
		if is_on_floor() and was_hit and !is_boom:
			$Ani.play("On")
			can_boom = true
			is_boom = true
			was_hit = false
			if boom_timer:
				boom_timer.start()
		return
		
	if is_hit:
		return
		
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
	if is_hit:
		return
	is_hit = true
	was_hit = true
	# Get player for knockback direction
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Make bomb fly away from player
		var dir = sign(global_position.x - player.global_position.x)
		if dir == 0:
			dir = 1
		knockback_velocity = Vector2(300 * dir, -100)  # Custom knockback for bomb when being launched
		is_falling = true

func _on_StartDetecting_timeout():
	can_boom = true
	
	

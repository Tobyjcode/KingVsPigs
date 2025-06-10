extends PigActor

@export var super_fast: bool = false
@onready var bomb_scene = load("res://scenes/Bomb.tscn")

func _ready():
	$AttackTime.wait_time = randf_range(0.1,0.2)
	$AttackTime.start()
	
	if super_fast:
		$Color.play("Fast")
	else:
		$Color.play("Normal")

func _physics_process(delta):
	if state == DEAD:
		velocity = Vector2.ZERO
		return
		
	if is_falling:
		velocity = knockback_velocity
		knockback_velocity.y += gravity * delta
		move_and_slide()
		return
		
	if is_hit:
		return
		
	super._physics_process(delta)

func set_flip():
	if velocity.x == 0:
		return
	var is_flipped = true if velocity.x > 0 else false
	
	$Sprite2D.flip_h = is_flipped
	$CollisionShape2D.position.x = -1 if is_flipped else 1
	$StompDetector/CollisionShape2D.position.x = -1 if is_flipped else 1

func animation_after_attack():
	$ani.play("Idle")
	var bomb = bomb_scene.instantiate()
	bomb.position = $BombStart.position
	add_child(bomb)

func _on_Timer_timeout():
	if state == DEAD or is_hit:
		return
	$AttackTime.wait_time = randf_range(0.1,1) if super_fast else randf_range(1,3)
	$ani.play("Throw")

func hit(attacker = null):
	# Only allow hits from the player
	if attacker and not attacker.is_in_group("player"):
		return
		
	if state == DEAD or is_hit:
		return
		
	is_hit = true
	call_die()

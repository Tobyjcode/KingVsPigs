extends PigActor

@export var super_fast: bool = false
@onready var bomb_scene = load("res://scenes/Bomb.tscn")

func _ready():
	lives = 3 # Make bomber piggy take 3 hits like other piggies
	$AttackTime.wait_time = randf_range(1.0, 2.0)
	$AttackTime.start()
	if super_fast:
		$Color.play("Fast")
	else:
		$Color.play("Normal")
	
	# Check if HitTimer exists before connecting
	var hit_timer = get_node_or_null("HitTimer")
	if hit_timer:
		hit_timer.timeout.connect(_on_hit_timer_timeout)
	
	if has_node("Hitbox"):
		$Hitbox.visible = true
		$Hitbox.monitoring = true
		$Hitbox.set_deferred("monitorable", true)
		if $Hitbox.has_node("CollisionShape2D"):
			$Hitbox/CollisionShape2D.disabled = false

func _on_Timer_timeout():
	if state == DEAD or is_hit:
		return
	# Play throw animation if it exists, otherwise just throw
	if $ani.has_animation("Throw"):
		$ani.play("Throw")
	else:
		throw_bomb()
	$AttackTime.wait_time = randf_range(1.0, 2.0)
	$AttackTime.start()

func throw_bomb():
	if bomb_scene and has_node("BombStart"):
		var bomb = bomb_scene.instantiate()
		bomb.global_position = $BombStart.global_position
		var player = get_tree().get_first_node_in_group("player")
		# Flip the piggy to face the player (like set_flip)
		if player:
			var is_flipped = player.global_position.x > global_position.x
			if sprite2d:
				sprite2d.flip_h = is_flipped
			if has_node("CollisionShape2D"):
				$CollisionShape2D.position.x = -1 if is_flipped else 1
			if has_node("StompDetector/CollisionShape2D"):
				$StompDetector/CollisionShape2D.position.x = -1 if is_flipped else 1
		get_parent().add_child(bomb)
		var to_player = (player.global_position - bomb.global_position).normalized() if player else Vector2(1, 0)
		var throw_velocity = Vector2(180 * sign(to_player.x), -180)
		if bomb.has_method("set_velocity"):
			bomb.set_velocity(throw_velocity)
		elif "velocity" in bomb:
			bomb.velocity = throw_velocity

func animation_after_attack():
	throw_bomb()
	if $ani.has_animation("Idle"):
		$ani.play("Idle")

func _on_hit_timer_timeout():
	is_hit = false
	if is_falling:
		is_falling = false
		$ani.play("Idle")

func _on_ani_animation_finished(anim_name):
	if anim_name == "Hit":
		$ani.play("Idle")
		is_hit = false
	elif anim_name == "Dead":
		queue_free()

func _on_Hitbox_area_entered(area):
	hit(area)

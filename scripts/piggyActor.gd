extends CharacterBody2D
class_name PigActor

@export var flip_on_start: bool = false
@export var disable_move: bool = false
@export var run_right: bool = false
@export var body_free: bool = false
@export var disable_collision: bool = false
@export var coin_scene: PackedScene = null

@export var basic_speed: int = -185

enum {STOP, MOVING, DEAD}

var gravity = 1000
var state = MOVING
var lives := 3
var is_hit := false
var is_falling := false
var knockback_velocity := Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var sprite2d = $Sprite2D if has_node("Sprite2D") else null
@onready var ani = $ani if has_node("ani") else null
@onready var hit_timer = get_node_or_null("HitTimer")

func _ready():
	velocity = Vector2(basic_speed, 0)
	if run_right:
		velocity = Vector2(-velocity.x, velocity.y)
	if disable_move:
		state = STOP
	if disable_collision:
		$PlayerDetector.monitorable = false
		$PlayerDetector.monitoring = false
	
	if hit_timer:
		hit_timer.timeout.connect(_on_hit_timer_timeout)
	
	if is_in_group("player_attack"):
		print("WARNING: Piggy node is in 'player_attack' group! Remove it from this group in the editor.")
	for child in get_children():
		if child.is_in_group("player_attack"):
			print("WARNING: Child node '", child.name, "' is in 'player_attack' group! Remove it from this group in the editor.")

func _on_StompDetector_body_entered(body):
	var stomp_y = $StompDetector/CollisionShape2D.global_position.y + $StompDetector/CollisionShape2D.shape.extents.y
	if body.global_position.y < stomp_y:
		if body.has_method("calculate_stomp_velocity"):
			body.calculate_stomp_velocity(300)
		call_die()

func _on_PlayerDetector_body_entered(body):
	if ani:
		ani.play("Attack")
	if body.global_position.x > global_position.x:
		flip(true)
	else:
		flip(false)
	state = STOP

func _physics_process(delta):
	if state == STOP:
		return
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
	velocity.y += gravity * delta
	if is_on_wall():
		velocity.x *= -1
	set_velocity(velocity)
	set_up_direction(Vector2.UP)
	move_and_slide()
	velocity.y = velocity.y
	if state != MOVING:
		return
	set_animation()
	set_flip()

func hit(attacker = null):
	if attacker and not attacker.is_in_group("player_attack"):
		return
	if state == DEAD or is_hit:
		return
	is_hit = true
	lives -= 1
	if lives <= 0:
		call_die()
	else:
		if ani:
			ani.play("Hit")
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = sign(global_position.x - player.global_position.x)
			if dir == 0:
				dir = 1
			knockback_velocity = Vector2(150 * dir, -80)
			is_falling = true
		await get_tree().create_timer(0.3).timeout
		is_hit = false
		if is_falling:
			is_falling = false
			if ani:
				ani.play("Idle")

func _on_hit_timer_timeout():
	is_hit = false

func call_die():
	if state == DEAD:
		return
	call_deferred("die")

func run():
	state = MOVING

func check_body_free():
	if body_free:
		queue_free()

func die():
	if coin_scene != null:
		var coin_instance = coin_scene.instance()
		coin_instance.position = Vector2(5,-8)
		add_child(coin_instance)
	$PlayerDetector/CollisionShape2D.disabled = true
	$PlayerDetector.monitoring = false
	$PlayerDetector.monitorable = false
	$".".collision_layer = 0
	state = DEAD
	velocity = Vector2.ZERO
	if ani:
		ani.play("Dead")
	if has_node("Color"):
		$Color.play("Normal")

func set_animation():
	if state != MOVING:
		return
	var anim_name = "Idle"
	if velocity.x != 0:
		anim_name = "Run"
	if !is_on_floor():
		anim_name = "Jump"
	anim_play(anim_name)

func set_flip():
	if velocity.x == 0:
		return
	var is_flipped = true if velocity.x > 0 else false
	flip(is_flipped)

func flip(is_flipped):
	if sprite2d:
		sprite2d.flip_h = is_flipped
		$CollisionShape2D.position.x = -1 if is_flipped else 5
		$PlayerDetector/CollisionShape2D.position.x = -1 if is_flipped else 5
	if animated_sprite:
		animated_sprite.flip_h = is_flipped

func attack():
	pass

func anim_play(new_animation):
	if ani:
		match ani.current_animation:
			"Attack":
				return
			new_animation:
				pass
			_:
				ani.play(new_animation)
	elif animated_sprite:
		if animated_sprite.animation != new_animation:
			animated_sprite.play(new_animation)
	elif sprite2d:
		pass

func _on_ani_animation_finished(anim_name):
	if anim_name == "Dead":
		queue_free()

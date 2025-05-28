extends CharacterBody2D

enum State { IDLE, PICKING, RUN, THROWING }

var state = State.IDLE
var velocity := Vector2.ZERO
var speed := 100.0
var hit := false
var dir := Vector2.ZERO
var invincible_timer := 0.0

@onready var sprite_anchor = $SpriteAnchor

func _ready():
	change_state(State.PICKING)

func _physics_process(delta):
	match state:
		State.IDLE:
			state_idle()
		State.RUN:
			state_run()
		State.PICKING:
			state_picking()
		State.THROWING:
			state_throwing()
	move_and_slide()

func state_idle():
	handle_speed()
	if abs(velocity.x) > 4:
		change_state(State.RUN)

func state_run():
	handle_speed()
	if abs(velocity.x) < 4:
		change_state(State.IDLE)

func state_picking():
	handle_speed()

func state_throwing():
	pass

func handle_speed():
	# Add friction or acceleration if needed
	pass

func movement_handler(direction: int, factor := 1.0):
	if state in [State.PICKING, State.THROWING]:
		return
	sprite_anchor.scale = Vector2(-direction, 1)
	velocity.x = lerp(velocity.x, direction * speed * factor, 0.2)

func throw_crate():
	hit = true
	var crate_scene = preload("res://scenes/FlyingCrate.tscn")
	var crate = crate_scene.instantiate()
	crate.global_position = global_position
	get_parent().add_child(crate)
	var throw_dir = dir.normalized()
	var factor = dir.y < 0.1 ? 0.3 : 0.8
	crate.apply_central_impulse(throw_dir * crate.weight * 1.5 + Vector2.UP * crate.weight * factor)

func on_throwed():
	var pig_scene = preload("res://scenes/Pig.tscn")
	var pig = pig_scene.instantiate()
	pig.global_position = global_position
	pig.face_dir = sprite_anchor.scale.x > 0
	get_parent().add_child(pig)
	queue_free()

func on_animation_finished(anim_name: String):
	if anim_name == "picking":
		change_state(State.IDLE)
	elif anim_name == "throwing":
		on_throwed()

func _on_hitbox_area_entered(area):
	if invincible_timer <= 0 and not hit and area.is_in_group("attack_box"):
		hit = true
		var pig_scene = preload("res://scenes/Pig.tscn")
		var crate_scene = preload("res://scenes/Crate.tscn")
		var pig = pig_scene.instantiate()
		var crate = crate_scene.instantiate()
		pig.global_position = global_position
		crate.global_position = global_position
		pig.dmged = true
		pig.face_dir = sprite_anchor.scale.x < 0
		var parent = get_parent()
		parent.add_child(pig)
		parent.add_child(crate)
		queue_free()

func change_state(new_state):
	state = new_state

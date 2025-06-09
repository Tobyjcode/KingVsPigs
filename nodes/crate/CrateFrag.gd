extends RigidBody2D

var fade_time := 1.5
var fade_timer: SceneTreeTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func start_fade_timer(time: float):
	fade_time = time
	fade_timer = get_tree().create_timer(fade_time)
	fade_timer.timeout.connect(_on_fade_timeout)

func _on_fade_timeout():
	# Fade out over 0.3s
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(self, "queue_free")) 

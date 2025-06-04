extends AnimatedSprite2D

func play_idle():
	play("idle")
	visible = true

func play_hit():
	play("hit")
	# Optionally, hide the heart after the hit animation finishes
	await animation_finished
	visible = false

func reset():
	play_idle()

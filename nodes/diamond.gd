extends Area2D

@export var value: int = 1

func _ready():
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var hud = get_tree().get_first_node_in_group("ScoreUI")
		if hud and hud.has_method("add_diamond"):
			hud.add_diamond(value)
		queue_free()

extends CanvasLayer

var diamond_score: int = 0

@onready var score_ui_container: HBoxContainer = $ScoreUIContainer
@onready var score_group = $ScoreUIContainer/ScoreGroup
@onready var diamond_score_ui: Label = $ScoreUIContainer/ScoreGroup/DiamondScoreUI

func _ready():
	score_ui_container.scale = Vector2(4, 4) # Adjust as needed
	update_diamond_score()

func add_diamond(amount: int = 1):
	diamond_score += amount
	update_diamond_score()

func set_diamond_score(amount: int):
	diamond_score = amount
	update_diamond_score()

func update_diamond_score():
	diamond_score_ui.text = str(diamond_score)

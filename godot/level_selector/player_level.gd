class_name PlayerLevel
extends Node2D

@export var player_num: int = 0
@onready var _title: Label = $Title
@onready var _level: Label = $Level
@onready var _left_button: DigitButton = $LeftButton
@onready var _right_button: DigitButton = $RightButton

var ai_level: Player.AI_Level:
	get:
		return ai_level
	set(value):
		ai_level = value
		if _level.visible:
			if value == Player.AI_Level.Human:
				_level.text = "H"
			else:
				_level.text = str(value)
		_left_button.visible = value > (Player.AI_Level.Human if player_num == 0 else Player.AI_Level.Level_1)
		_right_button.visible = value < Player.AI_Level.Level_4


func _ready():
	_title.text = "PLAYER " + str(player_num) + ":"
	ai_level = Player.AI_Level.Level_1


func _on_left_button_pressed() -> void:
	if player_num == 0:
		if ai_level > Player.AI_Level.Human:
			ai_level -= 1
		return
	if ai_level > Player.AI_Level.Level_1:
		ai_level -= 1


func _on_right_button_pressed() -> void:
	if ai_level < Player.AI_Level.Level_4:
		ai_level += 1

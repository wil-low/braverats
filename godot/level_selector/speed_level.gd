class_name SpeedLevel
extends Node2D

@onready var _level: Label = $Level
@onready var _left_button: DigitButton = $LeftButton
@onready var _right_button: DigitButton = $RightButton

const _min_speed: int = 1
const _max_speed: int = 5

var level: int:
	get:
		return level
	set(value):
		level = value
		_level.text = str(level)
		_left_button.visible = value > _min_speed
		_right_button.visible = value < _max_speed


func _on_left_button_pressed() -> void:
	if level > _min_speed:
		level -= 1


func _on_right_button_pressed() -> void:
	if level < _max_speed:
		level += 1

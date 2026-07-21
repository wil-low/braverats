class_name LevelSelector
extends Node2D

signal levels_changed(levels: Array[GameState.AI_Level], speed: int)

@onready var _levels: Node2D = $Levels
@onready var _speed_level: Node2D = $SpeedLevel


func set_levels(ai_levels: Array[GameState.AI_Level], speed: int) -> void:
	for i in ai_levels.size():
		_levels.get_child(i).ai_level = ai_levels[i]
	_speed_level.level = speed
	Animator._speed = pow(2, speed)


func _on_back_button_pressed() -> void:
	var result: Array[GameState.AI_Level]
	result.resize(2)
	for level in _levels.get_children():
		result[level.player_num] = level.ai_level
	hide()
	levels_changed.emit(result, _speed_level.level)

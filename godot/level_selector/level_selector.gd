class_name LevelSelector
extends Node2D

signal levels_changed(levels: Array[GameState.AI_Level], compact: bool, speed: int)

@onready var _levels: Node2D = $Levels
@onready var _speed_level: Node2D = $SpeedLevel
@onready var _compact_value: Label = $Compact/Value

var _compact: bool = false:
	set(value):
		_compact = value
		_compact_value.text = "YES" if value else "NO"


func set_levels(ai_levels: Array[GameState.AI_Level], compact: bool, speed: int) -> void:
	for i in ai_levels.size():
		_levels.get_child(i).ai_level = ai_levels[i]
	_compact = compact
	_speed_level.level = speed
	Animator._speed = pow(2, speed)


func _on_back_button_pressed() -> void:
	var result: Array[GameState.AI_Level]
	result.resize(4)
	var player_count := 0
	for level in _levels.get_children():
		result[level.player_num] = level.ai_level
		if level.ai_level != GameState.AI_Level.Human:
			player_count += 1
	if player_count > 1:
		hide()
		levels_changed.emit(result, _compact, _speed_level.level)
	else:
		print("Too few players")


func _on_compact_button_pressed() -> void:
	_compact = not _compact

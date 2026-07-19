class_name LevelSelector
extends Node2D

signal levels_changed(levels: Array[Player.AI_Level], compact: bool, speed: int)

@onready var _levels: Node2D = $Levels
@onready var _speed_level: Node2D = $SpeedLevel
@onready var _compact_value: Label = $Compact/Value

var _compact: bool = false:
	set(value):
		_compact = value
		_compact_value.text = "YES" if value else "NO"


func set_levels(arr: Array[Player], compact: bool, speed: int) -> void:
	for i in arr.size():
		_levels.get_child(i).ai_level = arr[i].ai_level
	_compact = compact
	_speed_level.level = speed
	Animator._speed = pow(2, speed)


func _on_back_button_pressed() -> void:
	var result: Array[Player.AI_Level]
	result.resize(4)
	var player_count := 0
	for level in _levels.get_children():
		result[level.player_num] = level.ai_level
		if level.ai_level != Player.AI_Level.Disabled:
			player_count += 1
	if player_count > 1:
		hide()
		levels_changed.emit(result, _compact, _speed_level.level)
	else:
		print("Too few players")


func _on_compact_button_pressed() -> void:
	_compact = not _compact

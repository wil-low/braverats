class_name Stats
extends Node2D

signal back_pressed

const LABELS: String = "H1234"
@onready var _levels: Array[Label] = [$L_H, $L_1, $L_2, $L_3, $L_4]

var _totals_and_wins = []
var invoker: Node2D


func _on_back_button_pressed() -> void:
	hide()
	back_pressed.emit()


func _on_reset_button_pressed() -> void:
	_totals_and_wins = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	update_labels()


func update_labels() -> void:
	for i in _levels.size():
		_levels[i].text = "%5d  %s  %-5d" % [_totals_and_wins[2 * i], LABELS[i], _totals_and_wins[2 * i + 1]]

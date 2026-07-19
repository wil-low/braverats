class_name Start
extends Node2D

signal play_pressed
signal settings_pressed
signal stats_pressed
signal help_pressed


func _on_play_button_pressed() -> void:
	hide()
	play_pressed.emit()


func _on_settings_button_pressed() -> void:
	hide()
	settings_pressed.emit()


func _on_stats_button_pressed() -> void:
	hide()
	stats_pressed.emit()


func _on_help_button_pressed() -> void:
	hide()
	help_pressed.emit()

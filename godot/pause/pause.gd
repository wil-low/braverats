extends Node2D

signal resume_pressed
signal stats_pressed
signal help_pressed
signal exit_pressed

func _on_resume_button_pressed() -> void:
	hide()
	resume_pressed.emit()


func _on_stats_button_pressed() -> void:
	hide()
	stats_pressed.emit()


func _on_help_button_pressed() -> void:
	hide()
	help_pressed.emit()


func _on_exit_button_pressed() -> void:
	hide()
	exit_pressed.emit()

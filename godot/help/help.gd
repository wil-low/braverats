extends Node2D

signal back_pressed

@onready var _left_button: DigitButton = $LeftButton
@onready var _right_button: DigitButton = $RightButton
@onready var _pages: Node2D = $Pages

var _active_page: int = 0:
	set(value):
		_active_page = value
		update_pages()

var invoker: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_pages()


func _on_back_button_pressed() -> void:
	hide()
	#_active_page = 0
	back_pressed.emit()


func _on_left_button_pressed() -> void:
	if _active_page > 0:
		_active_page -= 1


func _on_right_button_pressed() -> void:
	if _active_page < _pages.get_child_count() - 1:
		_active_page += 1


func update_pages() -> void:
	_left_button.visible = _active_page > 0
	_right_button.visible = _active_page < _pages.get_child_count() - 1
	for i in _pages.get_child_count():
		_pages.get_child(i).visible = i == _active_page

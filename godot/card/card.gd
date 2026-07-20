class_name Card
extends Area2D

## Braverats card types. Frame index = power value.
enum Power {
	Jester = 0,
	Lady = 1,
	Spy = 2,
	Assassin = 3,
	Chancellor = 4,
	Magician = 5,
	General = 6,
	Prince = 7,
}

const POWER_NAMES := [
	"Jester",
	"Lady",
	"Spy",
	"Assassin",
	"Chancellor",
	"Magician",
	"General",
	"Prince",
]

@onready var _sprite: Sprite2D = $Back
@onready var _character: Sprite2D = $Character
@onready var _value_label: Label = $Value


var _power: Power = Power.Jester:
	get:
		return _power
	set(value):
		_power = value
		_update_display()

var face_up: bool = true:
	set(value):
		face_up = value
		$Facedown.visible = not value
		$Back.visible = value
		$Character.visible = value
		$Value.visible = value


## Power value (0-7). Maps directly to characters.png frame index.
var power: Power:
	get:
		return _power
	set(value):
		_power = value
		_update_display()

## Display name of this card.
var power_name: String:
	get:
		return POWER_NAMES[_power][0]

func _update_display() -> void:
	## Back border (face-up frame)
	_sprite.frame = 0
	## Character sprite (8 frames: Jester..Prince)
	_character.frame = _power
	## Label
	_value_label.text = str(_power)


func _ready() -> void:
	face_up = true
	_power = Power.Jester
	_update_display()


func set_selected(value: bool) -> void:
	_sprite.modulate = Color.DIM_GRAY if value else Color.WHITE

class_name Card
extends Area2D

## Braverats card types. Frame index = power value.
enum Power {
	Jester = 0,
	Lady = 1,
	Spy = 2,
	Assassin = 3,
	Counsellor = 4,
	Magician = 5,
	General = 6,
	Prince = 7,
}

const POWER_NAMES := [
	"Jester",
	"Lady",
	"Spy",
	"Assassin",
	"Counsellor",
	"Magician",
	"General",
	"Prince",
]

@onready var _sprite: Sprite2D = $Sprite
@onready var _value_label: Label = $Value

static var b_font: LabelSettings
static var w_font: LabelSettings

var _power: Power = Power.Jester:
	get:
		return _power
	set(value):
		_power = value
		_update_display()

var faceup: bool = true:
	get:
		return faceup
	set(value):
		faceup = value
		_update_display()

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
		return POWER_NAMES[_power] if _power < POWER_NAMES.size() else "??"

func _update_display() -> void:
	_sprite.frame = 0 if faceup else 1
	if faceup:
		_value_label.text = POWER_NAMES[_power] if _power < POWER_NAMES.size() else "?"
	else:
		_value_label.text = ""

func get_power_name() -> String:
	return POWER_NAMES[_power] if _power < POWER_NAMES.size() else "??"

func _ready() -> void:
	faceup = true
	_power = Power.Jester

func set_selected(value: bool) -> void:
	_sprite.modulate = Color.DIM_GRAY if value else Color.WHITE

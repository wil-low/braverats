@tool
extends Node2D

@onready var _card: Card = $Card
@onready var _name: Label = $Name
@onready var _description: Label = $Description

@export var card_power: Card.Power = Card.Power.Jester:
	set(value):
		card_power = value
		if Engine.is_editor_hint():
			_card._character.frame = card_power

@export var card_name: String:
	set(value):
		card_name = value
		if Engine.is_editor_hint():
			_name.text = card_name

@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "") var card_description: String:
	set(value):
		card_description = value
		if Engine.is_editor_hint():
			_description.text = card_description


func _ready() -> void:
	_card.power = card_power
	_name.text = card_name
	_description.text = card_description

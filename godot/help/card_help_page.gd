@tool
extends Node2D

@onready var _card: Sprite2D = $Card
@onready var _name: Label = $Name
@onready var _description: Label = $Description

@export var card_type: Deck.CardType = Deck.CardType.Unknown:
	set(value):
		card_type = value
		if Engine.is_editor_hint():
			_card.frame = card_type

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
	_card.frame = card_type
	_name.text = card_name
	_description.text = card_description

class_name Card extends Area2D

enum Rank {
	Ace = 0,
	Six = 1,
	Seven,
	Eight,
	Nine,
	Ten,
	Jack,
	Queen,
	King,
	Unknown
}

const RANK_NAMES := [
	"A",
	"6",
	"7",
	"8",
	"9",
	"T",
	"J",
	"Q",
	"K"
]

@onready var _sprite: Sprite2D = $Sprite
@onready var _value_label: Label = $Value

static var b_font: LabelSettings
static var w_font: LabelSettings

var rank: Card.Rank:
	get:
		return rank
	set(value):
		rank = value
		_update_display()

var faceup: bool = true:
	get:
		return faceup
	set(value):
		faceup = value
		_update_display()

func _update_display() -> void:
	_sprite.frame = 0 if faceup else 1
	if faceup:
		_value_label.text = RANK_NAMES[rank] if rank < RANK_NAMES.size() else "?"
	else:
		_value_label.text = ""

func get_rank_char() -> String:
	if rank == Card.Rank.Unknown:
		return "?"
	return RANK_NAMES[rank]

func _ready() -> void:
	faceup = true
	rank = Card.Rank.Unknown

func set_selected(value: bool) -> void:
	_sprite.modulate = Color.DIM_GRAY if value else Color.WHITE
	_value_label.label_settings = w_font if value else b_font
	var parent := get_parent()
	if parent is Deck:
		parent.card_selected(get_index(), value)

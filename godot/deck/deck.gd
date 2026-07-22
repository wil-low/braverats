class_name Deck extends Node2D

signal card_clicked(card: Card)

## Character mapping for card powers
const CARD_LETTERS := "JLSACMGP"

@export var card_scene: PackedScene
@export var columns: int = 1
@export var fan_offset: Vector2i
@export var max_show := -1 # -1 = no limit, 0..N = max fanned; extras stack under last


func clear() -> void:
	while true:
		var c := pop()
		if c:
			c.queue_free()
		else:
			break


func prepare_braverats() -> void:
	"""Prepare a Braverats deck: 8 unique cards per player (16 total).
	Each player gets one of each: Jester, Lady, Spy, Assassin,
	Chancellor, Magician, General, Prince."""
	clear()

	# Create 8 unique cards for each player (16 total)
	for p in Card.Power.values():
		for _player in range(2):
			var c = card_scene.instantiate()
			add_child(c)
			c.power = p


func pop() -> Card:
	if get_child_count() > 0:
		var c := get_child(0)
		remove_child(c)
		return c
	return null


func shift_to(idx: int) -> void:
	for i in range(idx, get_child_count()):
		var pos := Vector2(global_position.x + (i % columns) * fan_offset.x,
			global_position.y + (i / columns) * fan_offset.y)
		Animator.move_card(get_child(i), pos)


func add_card(card: Card) -> void:
	card.reparent(self)


func remove_card(card: Card) -> Card:
	var c := card
	remove_child(c)
	return c


func get_append_position() -> Vector2:
	var i := get_child_count()
	return Vector2(global_position.x + (i % columns) * fan_offset.x,
		global_position.y + int(i / columns) * fan_offset.y)


func get_card_count() -> int:
	return get_child_count()


## Create a card with the power corresponding to a hand string character.
static func make_card_from_char(ch: String) -> Card:
	var c := Card.new()
	for power in Card.Power.values():
		if Card.POWER_NAMES[power][0] == ch:
			c._power = power
			return c
	c.power = Card.Power.Jester
	return c

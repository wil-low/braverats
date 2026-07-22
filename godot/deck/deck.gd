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


func prepare_braverats(hand0: String = "", hand1: String = "") -> void:
	"""Prepare a Braverats deck: 8 unique cards per player (16 total).
	Each player gets one of each: Jester, Lady, Spy, Assassin,
	Chancellor, Magician, General, Prince.

	If hand0/hand1 are non-empty, cards are created from those strings
	instead of the default power order. Deck layout is round-robin:
	[P0-round0, P1-round0, P0-round1, P1-round1, ...]."""
	clear()

	for i in range(8):
		# P0 card: use hand0 char or default power i
		var p0_power: int = i
		if not hand0.is_empty() and i < hand0.length():
			p0_power = Deck.CARD_LETTERS.find(hand0[i])
		var c0 = card_scene.instantiate()
		add_child(c0)
		c0.power = p0_power

		# P1 card: use hand1 char or default power i
		var p1_power: int = i
		if not hand1.is_empty() and i < hand1.length():
			p1_power = Deck.CARD_LETTERS.find(hand1[i])
		var c1 = card_scene.instantiate()
		add_child(c1)
		c1.power = p1_power


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

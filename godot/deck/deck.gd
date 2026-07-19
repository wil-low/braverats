class_name Deck extends Node2D

signal card_clicked(hand: Deck, card_idx: int)

var _selected_cards: Array[int] = []
var _selected_card: int = -1

@export var card_scene: PackedScene
@export var fan_offset := 0
@export var max_show := -1  # -1 = no limit, 0..N = max fanned; extras stack under last

const NUM_RANKS := 9  # A, 6-10, J, Q, K
const RANKS_PER_TYPE := 4

## Braverats: 8 unique cards per player (one of each type)
const BRAVERATS_CARDS_PER_PLAYER := 8


func clear() -> void:
	clear_selection()
	while true:
		var c := pop()
		if c:
			c.queue_free()
		else:
			break


func prepare_cheaters() -> void:
	"""Prepare a 35-card deck: 9 ranks × 4 minus 1 random card."""
	clear()
	var card_ranks := []
	for r in range(NUM_RANKS):
		for _i in range(RANKS_PER_TYPE):
			card_ranks.append(r)
	
	# Remove 1 random card before dealing
	var remove_idx := randi() % card_ranks.size()
	card_ranks.remove_at(remove_idx)
	
	card_ranks.shuffle()
	
	for r in card_ranks:
		var c = card_scene.instantiate()
		add_child(c)
		c.rank = r


func prepare_braverats() -> void:
	"""Prepare a Braverats deck: 8 unique cards per player (16 total).
	Each player gets one of each: Jester, Lady, Spy, Assassin,
	Chancellor, Magician, General, Prince."""
	clear()
	var all_cards: Array[Card] = []
	
	# Create 8 unique cards for each player (16 total)
	for _player in range(2):
		for p in Card.Power.values():
			var c = card_scene.instantiate()
			c.set_power(p)
			all_cards.append(c)
	
	# Shuffle all cards together
	all_cards.shuffle()
	
	# Add to deck
	for c in all_cards:
		add_child(c)


func pop() -> Card:
	if get_child_count() > 0:
		var c := get_child(0)
		remove_child(c)
		return c
	return null


func shift_to(idx: int) -> void:
	for i in range(idx, get_child_count()):
		var pos := Vector2(global_position.x + i * fan_offset, global_position.y)
		Animator.move_card(get_child(i), pos)


func add_card(card: Card) -> void:
	card.reparent(self)


func remove_card(card: Card) -> Card:
	var c := card
	remove_child(c)
	return c


func card_selected(idx: int, selected: bool) -> void:
	if selected:
		if not _selected_cards.has(idx):
			_selected_cards.append(idx)
	else:
		_selected_cards.erase(idx)


func clear_selection() -> void:
	for idx in _selected_cards:
		get_child(idx).set_selected(false)
	_selected_cards.clear()


func _is_card_selected(idx: int) -> bool:
	return _selected_cards.has(idx)

## Handle click on this deck (player hand). Returns clicked card index or -1.
func _handle_click(global_pos: Vector2) -> int:
	var local_pos := to_local(global_pos)
	var card_rect := Rect2(Vector2.ZERO, Vector2(11, 17))  # Card collision size

	# Find clicked card — iterate in reverse (top cards first)
	for i in range(get_child_count() - 1, -1, -1):
		var c := get_child(i) as Card
		if c:
			var card_abs := global_position + c.position
			var card_local := to_local(card_abs)
			if card_local.x >= local_pos.x - 6 and card_local.x <= local_pos.x + 6 and \
			   card_local.y >= local_pos.y - 9 and card_local.y <= local_pos.y + 9:
				card_clicked.emit(self, i)
				return i
	return -1

## Move a card from its current position to the end of the hand.
func _move_card_to_end(card_idx: int) -> void:
	if card_idx >= get_child_count():
		return
	var card := get_child(card_idx) as Node2D
	if card == null:
		return
	remove_child(card)
	add_child(card)

## Reposition all cards in the hand for proper fan display.
func _reposition_cards() -> void:
	var total := get_child_count()
	for i in range(total):
		var c := get_child(i) as Node2D
		if c:
			c.position = Vector2(0, i * 2)


func get_selected_count() -> int:
	return _selected_cards.size()


func get_selected_cards() -> Array[Card]:
	var result: Array[Card]
	for idx in _selected_cards:
		result.append(get_child(idx))
	return result


func get_append_position() -> Vector2:
	return Vector2(global_position.x + get_child_count() * fan_offset, global_position.y)


func get_card_count() -> int:
	return get_child_count()

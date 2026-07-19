class_name Deck extends Node2D

var _selected_cards: Array[int] = []

@export var card_scene: PackedScene
@export var fan_offset := 0
@export var max_show := -1  # -1 = no limit, 0..N = max fanned; extras stack under last

const NUM_RANKS := 9  # A, 6-10, J, Q, K
const RANKS_PER_TYPE := 4


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


func get_selected_count() -> int:
	return _selected_cards.size()


func get_selected_cards() -> Array[Card]:
	var result: Array[Card]
	for idx in _selected_cards:
		result.append(get_child(idx))
	return result


func get_append_position(rank: Card.Rank) -> Vector2:
	# Stack cards under the last visible when we've reached max_show
	if max_show >= 0 and get_child_count() >= max_show:
		var last_idx := max_show - 1
		return Vector2(
			global_position.x + last_idx * fan_offset,
			global_position.y
		)
	return Vector2(global_position.x + get_child_count() * fan_offset, global_position.y)


func get_4_of_a_kind() -> Array[Card]:
	var rank_groups: Dictionary = {}
	for c in get_children():
		if c.rank != Card.Rank.Unknown:
			if !rank_groups.has(c.rank):
				rank_groups[c.rank] = []
			rank_groups[c.rank].append(c)
	
	var min_index := 999
	var cards_to_remove : Array[Card]
	for rank in rank_groups:
		var cards = rank_groups[rank]
		if cards.size() >= 4:
			print("Player " + str(get_parent().idx) + " discards 4 " + Card.RANK_NAMES[rank])
			for i in range(4):
				var card: Card = cards[i]
				if min_index > card.get_index():
					min_index = card.get_index()
				cards_to_remove.append(card)
	return cards_to_remove


func get_card_count() -> int:
	return get_child_count()

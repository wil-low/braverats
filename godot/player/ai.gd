class_name AI
extends RefCounted

# ============================================================================
# Entry point — dispatches to strategy by level
# ============================================================================

static func select_discard(
	memory: Memory,
	my_hand: Array[Node],
	ai_level: Player.AI_Level,
	table_rank: Card.Rank
) -> Move:
	match ai_level:
		Player.AI_Level.Level_1:
			return AiLevel1.select_discard(my_hand, memory, table_rank)
		Player.AI_Level.Level_2:
			return AiLevel2.select_discard(my_hand, memory, table_rank)
		Player.AI_Level.Level_3:
			return AiLevel3.select_discard(my_hand, memory, table_rank)
		Player.AI_Level.Level_4:
			return AiLevel4.select_discard(my_hand, memory, table_rank)
	assert(false)
	# Default: random discard
	return _random_discard(my_hand, table_rank)


static func should_challenge(
	memory: Memory,
	ai_level: Player.AI_Level
) -> bool:
	match ai_level:
		Player.AI_Level.Level_1:
			return AiLevel1.should_challenge(memory)
		Player.AI_Level.Level_2:
			return AiLevel2.should_challenge(memory)
		Player.AI_Level.Level_3:
			return AiLevel3.should_challenge(memory)
		Player.AI_Level.Level_4:
			return AiLevel4.should_challenge(memory)
	return false


static func _random_discard(my_hand: Array[Node], table_rank: Card.Rank) -> Move:
	if my_hand.is_empty():
		return null
	
	var hand_cards: Array[Card] = []
	for c in my_hand:
		hand_cards.append(c as Card)
	
	var count := mini(3, hand_cards.size())
	var cards: Array[Card] = hand_cards.slice(0, count)
	var action := Move.Action.Discard_1 + count - 1
	
	return Move.new(action, table_rank, cards)


static func _argmax_score(valid_moves: Array[Move]) -> Move:
	if valid_moves.is_empty():
		return null
	var best_move: Move = valid_moves[0]
	var best_score: float = -1.0
	for m in valid_moves:
		if m._score > best_score:
			best_score = m._score
			best_move = m
	return best_move

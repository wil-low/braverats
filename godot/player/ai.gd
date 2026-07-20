class_name AI
extends RefCounted

## Braverats AI for card selection.
## L1: random card.
## L2: evaluation-based (simulates all opponent card possibilities).


static func select_card(my_cards: Array[Card], opponent_known: Array[Card], player_idx: int, gs: GameState) -> Card:
	"""Select a card for the given player.
	
 Args:
	 my_cards: Array of Card objects available in this player's hand.
	 opponent_known: Known cards opponent has selected/revealed (Spy effect).
	 player_idx: 0 or 1 — which player is selecting.
	 gs: Current GameState for accessing scores, effects, etc.
	
 Returns:
	 Selected Card, or null if no cards available.
	"""
	if my_cards.is_empty():
		return null

	var level := gs.ai_levels[player_idx]

	if level == GameState.AI_Level.Level_1:
		return _level1(my_cards)
	elif level == GameState.AI_Level.Level_2:
		return _level2(my_cards, opponent_known, player_idx, gs)
	else:
		return _level1(my_cards)


static func _level1(my_cards: Array[Card]) -> Card:
	"""Level 1: Random card selection."""
	return my_cards[randi() % my_cards.size()]


static func _level2(my_cards: Array[Card], opponent_known: Array[Card], player_idx: int, gs: GameState) -> Card:
	"""Level 2: Evaluation-based selection.
	
 Simulates playing each possible card against all possible opponent cards,
 then picks the card with the highest expected value.
	"""
	var best_card: Card = null
	var best_score := -999.0

	# Build list of possible opponent cards
	var opponent_cards: Array[Card]
	if opponent_known.is_empty():
		# Opponent could have any card (not revealed by Spy)
		var opp_card: Card
		for p in Card.Power.values():
			opp_card = Card.new()
			opp_card.set_power(p)
			opponent_cards.append(opp_card)
		opp_card.free()  # Clean up last created card
	else:
		for oc in opponent_known:
			opponent_cards.append(oc)

	for my_card in my_cards:
		var total_score := 0.0
		var count := 0

		for opp_card in opponent_cards:
			var outcome := _evaluate(my_card, opp_card, player_idx, gs)
			total_score += outcome
			count += 1

		var avg_score := total_score / count if count > 0 else 0.0
		if avg_score > best_score:
			best_score = avg_score
			best_card = my_card

	return best_card


static func _evaluate(my_card: Card, opp_card: Card, player_idx: int, gs: GameState) -> float:
	"""Evaluate a single matchup. Returns expected score for the AI's perspective.
	
 Positive = good for AI, Negative = bad for AI.
	"""
	var opponent_idx := 1 - player_idx
	var result: GameState.RoundResult

	# Resolve the round using GameLogic
	result = GameLogic.resolve_round(my_card, opp_card, gs)

	var score := 0.0

	match result:
		GameState.RoundResult.PLAYER0_WINS:
			if player_idx == 0:
				score = _get_points(my_card, gs)
			else:
				score = -1.0  # AI loses
		GameState.RoundResult.PLAYER1_WINS:
			if player_idx == 1:
				score = _get_points(opp_card, gs)
			else:
				score = -1.0  # AI loses
		GameState.RoundResult.HOLD:
			score = 0.0  # Draw, no points

	# Bonus: prefer winning with higher-value cards (Chancellor = 2 pts)
	if (player_idx == 0 and result == GameState.RoundResult.PLAYER0_WINS) or \
	   (player_idx == 1 and result == GameState.RoundResult.PLAYER1_WINS):
		var winner_card := my_card if player_idx == 0 else opp_card
		if winner_card.power == Card.Power.Chancellor:
			score += 1.0  # Bonus for knowing Chancellor wins 2 pts

	# Penalize playing against a known strong opponent card
	if opponent_idx == 0 and result == GameState.RoundResult.PLAYER1_WINS:
		if opp_card.power == Card.Power.Lady:
			score += 1.5  # Lady beats Prince — good for P1
		elif opp_card.power == Card.Power.Spy:
			score += 0.3  # Spy reveals info — slightly positive (we learned)

	return score


static func _get_points(card: Card, gs: GameState) -> float:
	"""Get points awarded for winning with a given card."""
	if card.power == Card.Power.Chancellor:
		return 2.0
	return 1.0

class_name AI
extends RefCounted

## Braverats AI for card selection.
## L1: random card.
## L2: evaluation-based (simulates all opponent card possibilities).

# Card short names matching console UI
const SHORT_NAMES := ["Je", "La", "Sp", "As", "Ch", "Ma", "Ge", "Pr"]
const RESULT_NAMES := ["Player0", "Player1", "Hold",
					   "Player0_GameWon", "Player1_GameWon", "NoResult"]
const WINNER_NAMES := ["", "", "Draw", "Player0", "Player1", ""]


static func select_card(my_cards: Array[Card], opponent_hand: Array[Node],
		player_idx: int, gs: GameState) -> Card:
	"""Select a card for the given player.
	
 Args:
	 my_cards: Array of Card objects available in this player's hand.
	 opponent_hand: Array of Node objects in the opponent's hand.
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
		return _level2(my_cards, opponent_hand, player_idx, gs)
	else:
		return _level1(my_cards)


static func _level1(my_cards: Array[Card]) -> Card:
	"""Level 1: Random card selection."""
	return my_cards[randi() % my_cards.size()]


static func _level2(my_cards: Array[Card], opponent_hand: Array[Node],
		player_idx: int, gs: GameState) -> Card:
	"""Level 2: Evaluation-based selection matching the Gamebuino C++ AI.
	
 Simulates each card against all possible opponent cards, scores outcomes,
 then uses weighted random selection.
	"""
	var opponent_idx := 1 - player_idx

	# First round is random (matches C++: round_count == 0)
	if gs.round_count == 0:
		return my_cards[randi() % my_cards.size()]

	# Determine if we know opponent's card (spy)
	# In C++: bool is_spy = opponent_move != UnknownCard;
	var opponent_move: Card = null
	if player_idx == 0 and gs.held_cards1 != null:
		opponent_move = gs.held_cards1
	elif player_idx == 1 and gs.held_cards0 != null:
		opponent_move = gs.held_cards0
	var is_spy := opponent_move != null

	print("\nselect move (level2) start")
	# Count outcomes: outcome[me_card_idx][result]
	var CardCount := my_cards.size()
	var outcome := {}
	for me_idx in range(CardCount):
		outcome[me_idx] = {
			GameState.RoundResult.PLAYER0_WINS: 0,
			GameState.RoundResult.PLAYER1_WINS: 0,
			GameState.RoundResult.HOLD: 0,
			GameState.RoundResult.PLAYER0_WINS_GAME: 0,
			GameState.RoundResult.PLAYER1_WINS_GAME: 0,
			GameState.RoundResult.NO_RESULT: 0,
		}

	# Simulate each matchup (matches C++ structure: iterate hand, skip non-matching when spy)
	for me_idx in range(my_cards.size()):
		var my_card := my_cards[me_idx]
		for opp_node in opponent_hand:
			var opp_card: Card = opp_node as Card
			# C++: if (is_spy && opponent_move != opp_card) continue;
			if is_spy and opponent_move != opp_card:
				continue

			var temp_gs := _copy_gs(gs)
			var new_state := GameLogic.resolve_round(my_card, opp_card, temp_gs)
			# Call finalize_round (equivalent to C++ move_cards) to update scores
			GameLogic.finalize_round(temp_gs, my_card, opp_card, new_state.last_result)
			# Track the result
			var result := new_state.last_result
			# Check if this round ends the game (after scoring)
			result = GameLogic.check_winner(temp_gs)
			render_outcome(my_card, opp_card, new_state)
			outcome[me_idx][result] += 1

	# Evaluate each card (matches C++ scoring formula)
	var evals := []
	var min_eval := 999
	var max_eval := -999
	for me_idx in range(my_cards.size()):
		var eval := 0

		# Points for winning (round win for this player)
		var my_round_win := GameState.RoundResult.PLAYER0_WINS if player_idx == 0 else GameState.RoundResult.PLAYER1_WINS
		eval += outcome[me_idx][my_round_win]

		# Points for game win (for this player)
		var my_game_win := GameState.RoundResult.PLAYER0_WINS_GAME if player_idx == 0 else GameState.RoundResult.PLAYER1_WINS_GAME
		eval += outcome[me_idx][my_game_win]

		# Penalty for opponent winning (round loss)
		var opp_round_win := GameState.RoundResult.PLAYER1_WINS if player_idx == 0 else GameState.RoundResult.PLAYER0_WINS
		eval -= outcome[me_idx][opp_round_win]

		# Heavy penalty for opponent game win (8x)
		var opp_game_win := GameState.RoundResult.PLAYER1_WINS_GAME if player_idx == 0 else GameState.RoundResult.PLAYER0_WINS_GAME
		eval -= outcome[me_idx][opp_game_win] * 8

		# Spy bonus
		if my_cards[me_idx].power == Card.Power.Spy:
			eval += 1

		evals.append(eval)
		if eval > max_eval:
			max_eval = eval
		if eval < min_eval:
			min_eval = eval

	# Normalize evals (weighted random selection)
	var sum := 0
	for me_idx in range(my_cards.size()):
		render_eval("1 eval" + str(me_idx), my_cards[me_idx].power, evals[me_idx])
		if evals[me_idx] > 0:
			evals[me_idx] = (evals[me_idx] - min_eval) * 4 + 1
		else:
			evals[me_idx] = evals[me_idx] - min_eval + 1
		render_eval("2 eval" + str(me_idx), my_cards[me_idx].power, evals[me_idx])
		sum += evals[me_idx]

	if sum == 0:
		sum = 1

	# Scale to 0-127 range
	for me_idx in range(my_cards.size()):
		evals[me_idx] = evals[me_idx] * 127 / sum
		render_eval("3 eval" + str(me_idx), my_cards[me_idx].power, evals[me_idx])

	# Weighted random selection
	var rmove := randi() % 127
	print("sum was " + str(sum) + ", rmove = " + str(rmove))
	sum = 0
	for me_idx in range(my_cards.size()):
		sum += evals[me_idx]
		if sum >= rmove:
			return my_cards[me_idx]

	return my_cards[my_cards.size() - 1]


static func render_outcome(my_card: Card, opp_card: Card, gs) -> void:
	"""Print outcome of a simulated matchup (mirrors console render_outcome)."""
	print("Outcome my %s theirs %s: result %s" % [SHORT_NAMES[my_card.power], SHORT_NAMES[opp_card.power],
		RESULT_NAMES[gs.last_result]])


static func render_eval(label: String, card_power: int, eval_val: int) -> void:
	"""Print evaluation for a card (mirrors console render_eval)."""
	print("%s %s: %4d" % [label, SHORT_NAMES[card_power], eval_val])


static func _copy_gs(gs: GameState) -> GameState:
	"""Create a shallow copy of GameState for simulation."""
	var copy := GameState.new()
	copy.scores = gs.scores.duplicate()
	copy.unrealized = gs.unrealized.duplicate()
	copy.ai_levels = gs.ai_levels.duplicate()
	copy.round_count = gs.round_count
	copy.last_result = gs.last_result
	copy.held_cards0 = gs.held_cards0
	copy.held_cards1 = gs.held_cards1
	copy.winner = gs.winner
	copy.round_history = gs.round_history.duplicate()
	copy.held_rounds = gs.held_rounds
	copy.chancellor_points = gs.chancellor_points.duplicate()
	copy.effects = gs.effects.duplicate()
	copy.lady_beats_prince_player = gs.lady_beats_prince_player
	return copy

class_name GameLogic
extends RefCounted

## Pure game logic for Braverats — no Godot node references.
## All functions operate on Card data and return game state changes.
##
## Card class has:
##   - power: Card.Power enum (Jester=0 through Prince=7)
##   - power_name: String name of the card

# ─── Evaluation Order (faithful to original C++ core) ────────────────────────
#
# 1. General +2: Persistent strength boost to next card ONLY.
#    NOT nullifiable by Magician. Does NOT affect current comparison.
# 2. Magician nullify: Nullifies opponent's card effect (except General's +2).
# 3. Jester nullify: Nullifies opponent's card effect (overrides all effects).
#    If both play Jester → hold. Jester beats Magician.
# 4. Lady-vs-Prince: Instant win for Lady vs Prince.
# 5. Prince instant win: Wins vs all except Lady and Assassin.
# 6. Value comparison: Base power values compared (after Jester/Magician nullification).
# 7. Assassin invert: Inverts the comparison result (lowest strength wins).
#    Does NOT override Prince or Lady.
# 8. Spy effect flag: Next round, opponent reveals first (carried forward).
# 9. General effect flag: Next card gets +2 (carried forward, not nullifiable).
# 10. Chancellor: Counts as 2 points if round is won.

# ─── Core Functions ─────────────────────────────────────────────────────────

## Resolve a single round given both players' cards.
## Mirrors resolve_round() in braverats/core.cpp:
##  1. Apply General +2 to base values (from carried effect)
##  2. Clear effects immediately
##  3. Compare values
##  4. If neither card is Magician:
##     - Jester or equal values → Hold
##     - Assassin inverts comparison
##     - Spy/General set next-round effects
##     - Prince vs Lady → instant game win
static func resolve_round(card0: Card, card1: Card, gs: GameState) -> GameState:
	var new_state = gs
	# Step 1: Apply General +2 to base card power values
	var p0_value: int = card0.power
	var p1_value: int = card1.power
	if gs.effects[0] == Card.Power.General:
		p0_value += 2
	if gs.effects[1] == Card.Power.General:
		p1_value += 2

	# Step 2: Clear effects immediately (General already applied above)
	new_state.effects[0] = Card.Power.Jester
	new_state.effects[1] = Card.Power.Jester

	# Step 3: Initial result based on value comparison
	if p0_value > p1_value:
		new_state.last_result = GameState.RoundResult.PLAYER0_WINS
	elif p1_value > p0_value:
		new_state.last_result = GameState.RoundResult.PLAYER1_WINS
	else:
		new_state.last_result = GameState.RoundResult.HOLD

	# Step 4: If neither card is Magician, apply special effects
	if card0.power != Card.Power.Magician and card1.power != Card.Power.Magician:
		# Jester or equal values → Hold (overrides everything)
		if p0_value == p1_value or card0.power == Card.Power.Jester or \
		   card1.power == Card.Power.Jester:
			new_state.last_result = GameState.RoundResult.HOLD
			return new_state

		# Cards must be different for special effects below
		if card0.power != card1.power:
			# Assassin inverts comparison (lowest wins)
			if card0.power == Card.Power.Assassin or \
			   card1.power == Card.Power.Assassin:
				if p0_value < p1_value:
					new_state.last_result = GameState.RoundResult.PLAYER0_WINS
				else:
					new_state.last_result = GameState.RoundResult.PLAYER1_WINS

			# Spy: next round opponent reveals first
			if card0.power == Card.Power.Spy:
				new_state.effects[0] = Card.Power.Spy
			if card1.power == Card.Power.Spy:
				new_state.effects[1] = Card.Power.Spy

			# General: next card gets +2
			if card0.power == Card.Power.General:
				new_state.effects[0] = Card.Power.General
			if card1.power == Card.Power.General:
				new_state.effects[1] = Card.Power.General

			# Prince vs Lady: instant game win for Lady
			if card0.power == Card.Power.Prince:
				if card1.power == Card.Power.Lady:
					new_state.last_result = GameState.RoundResult.PLAYER1_WINS_GAME
				else:
					new_state.last_result = GameState.RoundResult.PLAYER0_WINS
			if card1.power == Card.Power.Prince:
				if card0.power == Card.Power.Lady:
					new_state.last_result = GameState.RoundResult.PLAYER0_WINS_GAME
				else:
					new_state.last_result = GameState.RoundResult.PLAYER1_WINS

	return new_state

## Finalize round state after resolution.
## Mirrors move_cards() in braverats/core.cpp (except card removal).
## Walks ALL rounds, resolves held rounds, applies points.
static func finalize_round(gs: GameState, card0: Card, card1: Card, result: GameState.RoundResult) -> void:
	# Record round in history
	var entry := {
		"card0": card0.power if card0 else Card.Power.Jester,
		"card1": card1.power if card1 else Card.Power.Jester,
		"points": 0,
		"result": result,
		"round": gs.round_count,
	}
	gs.round_history.append(entry)

	# Increment round counter (matches C++ move_cards)
	gs.round_count += 1

	gs.scores[0] = 0
	gs.scores[1] = 0

	if result == GameState.RoundResult.PLAYER0_WINS_GAME:
		gs.scores[0] = 99
	elif result == GameState.RoundResult.PLAYER1_WINS_GAME:
		gs.scores[1] = 99
	else:
		# Reset unrealized for held round resolution
		gs.unrealized[0] = 0
		gs.unrealized[1] = 0

		# Walk through ALL rounds — mirrors C++ move_cards loop
		for i in gs.round_history.size():
			var h := gs.round_history[i]

			# If this round was Hold, resolve it to current decisive result
			if h.result == GameState.RoundResult.HOLD:
				h.result = result

			# Determine points for this round
			h.points = 1
			match h.result:
				GameState.RoundResult.PLAYER0_WINS:
					if h.card0 == Card.Power.Chancellor and h.card1 != Card.Power.Magician:
						h.points = 2
						gs.scores[0] += 2
					else:
						gs.scores[0] += 1
				GameState.RoundResult.PLAYER1_WINS:
					if h.card1 == Card.Power.Chancellor and h.card0 != Card.Power.Magician:
						h.points = 2
						gs.scores[1] += 2
					else:
						gs.scores[1] += 1
				GameState.RoundResult.HOLD:
					# Still Hold — add to unrealized
					gs.unrealized[0] += (2 if h.card0 == Card.Power.Chancellor else 1)
					gs.unrealized[1] += (2 if h.card1 == Card.Power.Chancellor else 1)


static func check_winner(gs: GameState) -> GameState.RoundResult:
	if gs.last_result == GameState.RoundResult.PLAYER0_WINS_GAME or gs.last_result == GameState.RoundResult.PLAYER1_WINS_GAME:
		return gs.last_result
	if gs.scores[0] >= 4 or gs.scores[1] >= 4:
		if gs.scores[0] == gs.scores[1]:
			return GameState.RoundResult.HOLD
		if gs.scores[0] > gs.scores[1]:
			return GameState.RoundResult.PLAYER0_WINS_GAME
		else:
			return GameState.RoundResult.PLAYER1_WINS_GAME
	return GameState.RoundResult.HOLD if gs.round_count == GameState.MAX_ROUNDS else GameState.RoundResult.NO_RESULT


## Start a new game. Resets all state.
static func new_game(gs: GameState) -> void:
	gs.scores = [0, 0]
	gs.unrealized = [0, 0]
	gs.held_rounds = 0
	gs.chancellor_points = [0, 0]
	gs.effects = [Card.Power.Jester, Card.Power.Jester]
	gs.lady_beats_prince_player = -1
	gs.winner = GameState.RoundResult.NO_RESULT
	gs.round_count = 0
	gs.round_history.clear()
	gs.held_cards0 = null
	gs.held_cards1 = null

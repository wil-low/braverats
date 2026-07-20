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
	var points: int = 1
	var entry := {
		"card0": card0.power if card0 else Card.Power.Jester,
		"card1": card1.power if card1 else Card.Power.Jester,
		"points": points,
		"result": result,
		"round": gs.round_count,
	}
	gs.round_history.append(entry)

	gs.scores[0] = 0
	gs.scores[1] = 0

	if result == GameState.RoundResult.PLAYER0_WINS_GAME:
		gs.scores[0] = 100
	elif result == GameState.RoundResult.PLAYER1_WINS_GAME:
		gs.scores[1] = 100
	else:
		# Reset unrealized for held round resolution
		gs.unrealized[0] = 0
		gs.unrealized[1] = 0

		# Walk through ALL rounds — mirrors C++ move_cards loop
		for h in gs.round_history:
			var rr: GameState.RoundResult = h.result

			# If this round was Hold, resolve it to current decisive result
			if rr == GameState.RoundResult.HOLD:
				h["result"] = result
				rr = result

			# Determine points for this round
			match rr:
				GameState.RoundResult.PLAYER0_WINS:
					if h.card0 == Card.Power.Chancellor and h.card1 != Card.Power.Magician:
						points = 2
						gs.scores[0] += 2
					else:
						gs.scores[0] += 1
				GameState.RoundResult.PLAYER1_WINS:
					if h.card1 == Card.Power.Chancellor and h.card0 != Card.Power.Magician:
						points = 2
						gs.scores[1] += 2
					else:
						gs.scores[1] += 1
				GameState.RoundResult.HOLD:
					# Still Hold — add to unrealized
					if h.card0 == Card.Power.Chancellor:
						gs.unrealized[0] += 2
					else:
						gs.unrealized[0] += 1
					if h.card1 == Card.Power.Chancellor:
						gs.unrealized[1] += 2
					else:
						gs.unrealized[1] += 1

		# Update current round entry points
		var last: Dictionary = gs.round_history.back()
		last["points"] = points

## Check if the game has ended (someone reached target score or all rounds played).
## Returns: -1 = game ongoing, 0 = Player0 wins, 1 = Player1 wins, 2 = draw
static func check_winner(gs: GameState) -> int:
	for i in 2:
		var total_score: int = gs.scores[i] + gs.unrealized[i]
		if total_score >= GameState.TARGET_SCORE:
			return i

	# Check if all rounds are played
	if gs.round_count >= GameState.MAX_ROUNDS:
		var score0: int = gs.scores[0] + gs.unrealized[0]
		var score1: int = gs.scores[1] + gs.unrealized[1]
		if score0 > score1:
			return 0
		elif score1 > score0:
			return 1
		else:
			return 2 # Draw

	# Check for Lady vs Prince instant win (already resolved in resolve_round,
	# but flag it in GameState for the UI to handle)
	if gs.lady_beats_prince_player >= 0:
		return gs.lady_beats_prince_player

	return -1 # Game ongoing

## Start a new game. Resets all state.
static func new_game(gs: GameState) -> void:
	gs.scores = [0, 0]
	gs.unrealized = [0, 0]
	gs.held_rounds = 0
	gs.chancellor_points = [0, 0]
	gs.effects = [Card.Power.Jester, Card.Power.Jester]
	gs.lady_beats_prince_player = -1
	gs.game_over = false
	gs.round_count = 0
	gs.round_history.clear()
	gs.held_cards0 = null
	gs.held_cards1 = null

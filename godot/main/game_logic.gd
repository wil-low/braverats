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
## Returns a RoundResult.Value.
## Updates GameState with the result (called by GameState).
##
## Special interactions:
## - Both play same card → effects cancel (except Jester→hold, General→both get +2)
## - Jester nullifies opponent's effect entirely
## - Lady instant-wins only if opponent played Prince
## - General +2 applies to current card, persists, not nullifiable
## - Assassin inverts result (applies after other effects)
## - Prince wins vs all except Lady and Assassin
static func resolve_round(card0: Card, card1: Card) -> RoundResult.Value:
	# ─── Both play same card ─────────────────────────────────────────────
	if card0.power == card1.power:
		match card0.power:
			Card.Power.Jester:
				return RoundResult.Value.HOLD # Jester vs Jester → hold
			Card.Power.General:
				# Both get +2 to next card (persistent effect)
				GameState.effects[0] = Card.Power.General
				GameState.effects[1] = Card.Power.General
				# Same power = tie → Player0 wins (first to act in original)
				return RoundResult.Value.PLAYER0_WINS
			_:
				# Same card: compare strength (equal), Player0 wins ties
				return RoundResult.Value.PLAYER0_WINS

	# ─── Step 1: Magician nullifies opponent's effect (before General) ──
	# General's +2 is persistent and NOT nullifiable — it only flags for next round.
	# Magician nullifies the opponent's card EFFECT but not General's persistent +2.
	var nullified0: bool = card0.power == Card.Power.Magician
	var nullified1: bool = card1.power == Card.Power.Magician

	# ─── Step 2: Jester nullifies opponent's card (overrides all effects) ─
	# Jester beats Magician (Jester nullifies Magician's effect too).
	# Jester nullifies everything including Prince → hold.
	if card0.power == Card.Power.Jester or card1.power == Card.Power.Jester:
		return RoundResult.Value.HOLD

	# ─── Step 3: Lady vs Prince instant win (not nullifiable) ────────────
	if card0.power == Card.Power.Lady and card1.power == Card.Power.Prince:
		return RoundResult.Value.PLAYER0_WINS
	if card1.power == Card.Power.Lady and card0.power == Card.Power.Prince:
		return RoundResult.Value.PLAYER1_WINS

	# ─── Step 4: Compute effective power for comparison ──────────────────
	# General does NOT boost current card — only flags for next round.
	# Magician nullifies opponent's effect (sets their effective power to 0).
	var power0: int = card0.power
	var power1: int = card1.power
	if card0.power == Card.Power.General:
		GameState.effects[0] = Card.Power.General # Flag for next round
	if card1.power == Card.Power.General:
		GameState.effects[1] = Card.Power.General # Flag for next round

	# Apply nullification (Magician sets opponent to 0, but NOT General)
	if nullified0:
		if card0.power != Card.Power.General:
			power0 = 0
	if nullified1:
		if card1.power != Card.Power.General:
			power1 = 0

	# ─── Step 5: Base strength comparison ────────────────────────────────
	var comparison: int
	if power0 > power1:
		comparison = 1 # Player0 wins
	elif power1 > power0:
		comparison = -1 # Player1 wins
	else:
		comparison = 1 # Tie: Player0 wins (first to act in original)

	# ─── Step 6: Assassin inverts result ─────────────────────────────────
	# Lowest strength wins. Does NOT override Prince or Lady (already handled above).
	if card0.power == Card.Power.Assassin:
		comparison = - comparison
	if card1.power == Card.Power.Assassin:
		comparison = - comparison

	# Double inversion (both Assassin) → original result preserved
	if card0.power == Card.Power.Assassin and card1.power == Card.Power.Assassin:
		comparison = 1 # Tie: Player0 wins

	# ─── Step 7: Spy effect flag (carried forward to next round) ────────
	if card0.power == Card.Power.Spy:
		GameState.effects[0] = Card.Power.Spy
	if card1.power == Card.Power.Spy:
		GameState.effects[1] = Card.Power.Spy

	# ─── Step 8: Chancellor tracking ─────────────────────────────────────
	# Chancellor counts as 2 points if this player wins the round
	if comparison == 1 and card0.power == Card.Power.Chancellor:
		GameState.chancellor_points[0] += 2
	if comparison == -1 and card1.power == Card.Power.Chancellor:
		GameState.chancellor_points[1] += 2

	# ─── Return result ───────────────────────────────────────────────────
	match comparison:
		1:
			return RoundResult.Value.PLAYER0_WINS
		-1:
			return RoundResult.Value.PLAYER1_WINS
		_:
			return RoundResult.Value.HOLD

## Move cards from one collection to another.
## Used for: discard pile, draw pile, round history.
## Returns the number of cards moved.
static func move_cards(source: Array[Card], target: Array[Card]) -> int:
	var count: int = 0
	for card in source:
		target.append(card)
		count += 1
	source.clear()
	return count

## Check if the game has ended (someone reached target score or all rounds played).
## Returns: -1 = game ongoing, 0 = Player0 wins, 1 = Player1 wins, 2 = draw
static func check_winner() -> int:
	# Check if anyone reached the target score
	for i in 2:
		var total_score: int = GameState.scores[i] + GameState.unrealized[i]
		if total_score >= GameState.TARGET_SCORE:
			return i

	# Check if all rounds are played
	if GameState.round_count >= GameState.MAX_ROUNDS:
		# Determine winner by total score
		var score0: int = GameState.scores[0] + GameState.unrealized[0]
		var score1: int = GameState.scores[1] + GameState.unrealized[1]
		if score0 > score1:
			return 0
		elif score1 > score0:
			return 1
		else:
			return 2 # Draw

	# Check for Lady vs Prince instant win (already resolved in resolve_round,
	# but flag it in GameState for the UI to handle)
	if GameState.lady_beats_prince_player >= 0:
		return GameState.lady_beats_prince_player

	return -1 # Game ongoing

## Start a new game. Resets all state.
static func new_game() -> void:
	GameState.scores = [0, 0]
	GameState.unrealized = [0, 0]
	GameState.held_rounds = 0
	GameState.chancellor_points = [0, 0]
	GameState.effects = [Card.Power.Jester, Card.Power.Jester]
	GameState.lady_beats_prince_player = -1
	GameState.game_over = false
	GameState.round_count = 0
	GameState.round_history.clear()
	GameState.pending_cmd = false
	GameState.held_cards0 = null
	GameState.held_cards1 = null

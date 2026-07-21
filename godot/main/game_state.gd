class_name GameState
extends RefCounted

## Centralized game state for Braverats.
## Acts as a single source of truth for game flow.
##
## Game flow:
## 1. new_game() → initialize
## 2. Player0 selects card → hold_cards0
## 3. Player1 selects card → hold_cards1
## 4. resolve_round() → play both cards, determine result
## 5. Move cards to history, advance round
## 6. check_winner() → game over? → game_over.tscn or continue

## AI level config for both players (from level selector).
## Player 0: Human (0), L1 (1), L2 (2).  Player 1: L1 (1), L2 (2) only.
enum AI_Level {
	Human = 0,
	Level_1,
	Level_2,
	# Level_3,  # Reserved for future
	# Level_4,  # Reserved for future
}

## Result of a Braverats round resolution.
enum RoundResult {
	NO_RESULT = -1,
	PLAYER0_WINS = 0,
	PLAYER1_WINS = 1,
	HOLD = 2,  # Round nullified / on hold
	PLAYER0_WINS_GAME = 3,
	PLAYER1_WINS_GAME = 4,
}

const AI_LEVEL_NAMES := "H12"

# ─── Constants ───────────────────────────────────────────────────────────────

const MAX_ROUNDS: int = 8
const TARGET_SCORE: int = 4
const NUM_PLAYERS: int = 2

## Current AI levels for each player (set from level selector).
var ai_levels: Array[AI_Level] = [AI_Level.Human, AI_Level.Level_1]

# ─── State Variables ─────────────────────────────────────────────────────────

## Cards currently selected by each player (one card each, not yet played)
var held_cards0: Card = null
var held_cards1: Card = null

var last_result: RoundResult

## Round history: each entry is a Dictionary with keys:
##   card0, card1, result, player0_wins_round
var round_history: Array[Dictionary] = []

## Current scores (points won from resolved rounds)
var scores: Array[int] = [0, 0]

## Unrealized points from held rounds that will resolve later
var unrealized: Array[int] = [0, 0]

## Accumulated held round points (count of Jester-nullified rounds)
var held_rounds: int = 0

## Chancellor bonus points (added to score when round is won)
var chancellor_points: Array[int] = [0, 0]

## Pending effects carried between rounds (one effect per player, no stacking).
## effects[player_idx] = active Power enum, Card.Power.Jester means no effect.
## Effect types: Spy (see opponent's card), General (+2 next card).
var effects: Array[Card.Power] = [Card.Power.Jester, Card.Power.Jester]

## Round number (0-indexed, max MAX_ROUNDS-1)
var round_count: int = 0

## Player index who won via Lady vs Prince instant win (-1 = none)
var lady_beats_prince_player: int = -1

var winner: RoundResult = RoundResult.NO_RESULT

# ─── Flow Control ────────────────────────────────────────────────────────────

## Initialize a new game. Call from application or main scene.
func new_game() -> void:
	GameLogic.new_game(self)

	# Reset held cards
	held_cards0 = null
	held_cards1 = null
	round_count = 0
	lady_beats_prince_player = -1
	winner = RoundResult.NO_RESULT
	round_history.clear()

## Set the card Player 0 has selected.
func hold_card0(card: Card) -> void:
	held_cards0 = card

## Set the card Player 1 has selected.
func hold_card1(card: Card) -> void:
	held_cards1 = card

## Check if the game is over.
func is_game_over() -> bool:
	return winner != RoundResult.NO_RESULT

## Check if Spy effect is active for a player (next round reveals opponent).
func is_spy_active(player_idx: int) -> bool:
	return effects[player_idx] == Card.Power.Spy

## Check if General effect is active for a player (+2 next card).
func is_general_active(player_idx: int) -> bool:
	return effects[player_idx] == Card.Power.General

## Reset effects after they resolve (end of round).
func clear_effects() -> void:
	for i in 2:
		effects[i] = Card.Power.Jester

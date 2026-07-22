extends Node2D

## Braverats round-history tester: fixes P0 hand, iterates all 8! permutations
## of P1 hand, prints round history in the Godot GameOver format.
##
## Replicates main(), permute() and simulate_game() from cpp_test.cpp.
## Reuses GameLogic.new_game, resolve_round, finalize_round (move_cards),
## and check_winner from existing Godot code.

const CARD_SCENE := preload("res://card/card.tscn")
const CARD_LETTERS := "JLSACMGP"
const TOTAL_GAMES := 40320

var _card_cache: Array[Card]
var file: FileAccess

func _ready() -> void:
	file = FileAccess.open("/tmp/godot_result.txt", FileAccess.WRITE)
	# Pre-instantiate all 8 card types for memory-efficient reuse
	for _i in range(Card.Power.values().size()):
		var card := CARD_SCENE.instantiate()
		card._power = _i
		_card_cache.append(card)
	main()


func main() -> void:
	printerr("# Braverats: %d permutations (P0 fixed, P1 varies)", TOTAL_GAMES)
	printerr("# Format:")
	printerr("#   PLAYER message / DRAW")
	printerr("#   P0=N  P1=N  (final accumulated scores)")
	printerr("#   P1: C{mark} ...  (rounds_1, top line)")
	printerr("#   P0: C{mark} ...  (rounds_0, bottom line)")
	printerr("#")
	printerr("# Marks: ! = instant Lady-Prince win, # = 2pts, + = 1pt,   = hold\n")

	# P0 fixed to identity
	var p0_chars := "JSCPALGM"
	# P1 starts as identity
	var p1_chars := "CJPGSAML"

	var p0_hand := []
	var p1_perm := []

	for i in 8:
		var pos := CARD_LETTERS.find(p0_chars[i])
		p0_hand.append(pos)
		pos = CARD_LETTERS.find(p1_chars[i])
		p1_perm.append(pos)

	var count := [0]
	permute(p1_perm, 0, 8, p0_hand, count)
	file.close()
	printerr("\nDone: %d games", count[0])


## Recursively generate all permutations of arr[idx..n), calling simulate_game
## for each complete permutation.
func permute(arr: Array, idx: int, n: int, p0_hand: Array, count: Array) -> void:
	if idx == n:
		simulate_game(p0_hand.duplicate(), arr.duplicate(), count)
		count[0] += 1
		if count[0] % 1000 == 0:
			printerr("%d / %d (%.1f%%)\n" % [count[0], TOTAL_GAMES,
					 float(count[0]) / TOTAL_GAMES * 100.0])
		return

	# Avoid duplicate swaps
	var used := {}
	for i in range(idx, n):
		if arr[i] in used:
			continue
		used[arr[i]] = true
		var tmp = arr[idx]
		arr[idx] = arr[i]
		arr[i] = tmp
		permute(arr, idx + 1, n, p0_hand, count)
		# Backtrack
		tmp = arr[idx]
		arr[idx] = arr[i]
		arr[i] = tmp


## Run one full game given fixed P0 hand and P1 hand, print round history.
func simulate_game(p0_hand: Array, p1_hand: Array, count: Array) -> void:
	var gs := GameState.new()
	GameLogic.new_game(gs)

	var game_winner: GameState.RoundResult
	var score_log := ""

	for _round in 8:
		var c0 := _make_card(p0_hand[0])
		var c1 := _make_card(p1_hand[0])

		# Resolve round (mirrors C++ resolve_round)
		var resolved := GameLogic.resolve_round(c0, c1, gs)
		gs = resolved

		# Finalize: record round, resolve holds, apply points
		# (mirrors C++ move_cards)
		GameLogic.finalize_round(gs, c0, c1, gs.last_result)

		score_log += "%d,%d,%d,%d|" % [gs.scores[0], gs.unrealized[0], gs.scores[1], gs.unrealized[1]]

		game_winner = GameLogic.check_winner(gs)

		if game_winner != GameState.RoundResult.NO_RESULT:
			break

		# Remove played cards from hands (mirrors C++ remove_from_hand)
		p0_hand.remove_at(0)
		p1_hand.remove_at(0)

	# Output in C++ format: outcome TAB scores TAB score_log TAB p0_line TAB p1_line
	file.store_line("{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}".format([
		count[0],
		_outcome_to_string(game_winner),
		gs.scores[0], gs.scores[1],
		score_log,
		_build_line(gs.round_history, 0),
		_build_line(gs.round_history, 1)]))


func _make_card(power: int) -> Card:
	return _card_cache[power]


func _outcome_to_string(result: GameState.RoundResult) -> String:
	match result:
		GameState.RoundResult.PLAYER0_WINS_GAME: return "WIN0"
		GameState.RoundResult.PLAYER1_WINS_GAME: return "WIN1"
		GameState.RoundResult.HOLD: return "DRAW"
		_: return "NRES"


func _build_line(history: Array, player_idx: int) -> String:
	"""Build the 8-char round line for a given player (0=P0, 1=P1).
	Mirrors C++ output: card_letter + mark for each round, padded to 8 chars."""
	var line := ""
	for entry in history:
		var my_card: int = entry["card%d" % player_idx] as int
		var points: int = entry["points"] as int
		var result: GameState.RoundResult = entry["result"] as GameState.RoundResult

		var ch := CARD_LETTERS[my_card]
		var mark := " "

		match result:
			GameState.RoundResult.PLAYER0_WINS_GAME:
				if player_idx == 0:
					mark = "!"
			GameState.RoundResult.PLAYER1_WINS_GAME:
				if player_idx == 1:
					mark = "!"
			GameState.RoundResult.PLAYER0_WINS:
				if player_idx == 0:
					if points == 2:
						mark = "#"
					else:
						mark = "+"
			GameState.RoundResult.PLAYER1_WINS:
				if player_idx == 1:
					if points == 2:
						mark = "#"
					else:
						mark = "+"

		line += "%c%c" % [ch, mark]
	return line

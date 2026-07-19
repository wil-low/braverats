class_name GameOver
extends Node2D

signal play_again_pressed

@onready var message: Label = $Message
@onready var game_score: Label = $GameScore
@onready var rounds_1: Label = $Rounds1
@onready var rounds_2: Label = $Rounds2
@onready var total_score: Label = $TotalScore

var _stats: Node = null


func _on_button_pressed() -> void:
	hide()
	play_again_pressed.emit()


## Fill in all labels with game data from GameState.
## Call after adding this scene to the tree.
func show_game() -> void:
	## Winner message (replicates original C++ layout)
	var winner := GameState.get_winner()
	if winner >= 0:
		message.text = "PLAYER %d WINS!" % (1 + winner)
	elif GameState.scores[0] == GameState.scores[1]:
		message.text = "DRAW"
	else:
		message.text = "PLAYER %d WINS!" % (1 + (0 if GameState.scores[0] > GameState.scores[1] else 1))

	## Game score (current round points)
	game_score.text = "%d:%d" % [GameState.scores[0], GameState.scores[1]]

	## Round history — concatenated strings, P1 on top line, P0 on bottom line
	## Each round: "CardName" + result indicator (P0 wins → bottom, P1 wins → top)
	var p0_rounds := ""
	var p1_rounds := ""
	for entry in GameState.round_history:
		var c0 := entry["card0"] as Card
		var c1 := entry["card1"] as Card
		var r := entry["result"] as RoundResult
		## Result indicator: "!!" = Lady-Prince instant win, "+" = regular win
		var p0_mark := ""
		var p1_mark := ""
		match r.value:
			RoundResult.Value.PLAYER0_WINS:
				## Check if it was an instant Lady vs Prince
				if c0.power == Card.Power.Lady and c1.power == Card.Power.Prince:
					p0_mark = " !!"
				else:
					p0_mark = " +"
			RoundResult.Value.PLAYER1_WINS:
				if c1.power == Card.Power.Lady and c0.power == Card.Power.Prince:
					p1_mark = " !!"
				else:
					p1_mark = " +"
			RoundResult.Value.HOLD:
				p0_mark = " —"
			p1_mark = " —"
		## P1 card on top line (y=24 in original), P0 card on bottom (y=32)
		p1_rounds += c1.power_name + p1_mark + "\n"
		p0_rounds += c0.power_name + p0_mark + "\n"

	## Remove trailing newline so label doesn't add extra spacing
	if p0_rounds.ends_with("\n"):
		p0_rounds = p0_rounds.substr(0, p0_rounds.length() - 1)
	if p1_rounds.ends_with("\n"):
		p1_rounds = p1_rounds.substr(0, p1_rounds.length() - 1)

	rounds_1.text = p1_rounds if not p1_rounds.is_empty() else "—"
	rounds_2.text = p0_rounds if not p0_rounds.is_empty() else "—"

	## Career victories per mode (original: _players[x]._victory_count at y=41)
	if not _stats:
		_stats = get_node_or_null("/root/Stats")
	if _stats:
		var p0_wins := _stats._totals_and_wins[2 * int(GameState.ai_levels[0]) + 1]
		var p1_wins := _stats._totals_and_wins[2 * int(GameState.ai_levels[1]) + 1]
		total_score.text = "%d : %d" % [p0_wins, p1_wins]
	else:
		total_score.text = "— : —"

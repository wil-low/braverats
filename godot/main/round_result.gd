class_name RoundResult
extends RefCounted

## Result of a Braverats round resolution.
enum Value {
	PLAYER0_WINS = 0,
	PLAYER1_WINS = 1,
	HOLD = 2,  # Round nullified / on hold
}

var value: Value

func _init(p_value: Value = Value.HOLD) -> void:
	value = p_value

func is_player_win(player_idx: int) -> bool:
	if value == Value.HOLD:
		return false
	return value == player_idx

func is_hold() -> bool:
	return value == Value.HOLD

func winner_idx() -> int:
	if value == Value.HOLD:
		return -1
	return value

func to_string() -> String:
	match value:
		Value.PLAYER0_WINS:
			return "PLAYER0_WINS"
		Value.PLAYER1_WINS:
			return "PLAYER1_WINS"
		Value.HOLD:
			return "HOLD"
	return "UNKNOWN"

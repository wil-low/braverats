class_name Main
extends Node2D

signal menu_pressed
signal round_finished(ai_level: int)
signal save_stats

@onready var _deck: Deck = $Deck
@onready var _player_hand0: Deck = $PlayerHand0
@onready var _player_hand1: Deck = $PlayerHand1
@onready _card_scene: PackedScene = $Deck.card_scene
@onready var _animation_layer: Node2D = $AnimationLayer

@onready var _score0: Label = $Score0
@onready var _score1: Label = $Score1
@onready var _plus0: Label = $Plus0
@onready var _plus1: Label = $Plus1
@onready var _unrealized0: Label = $Unrealized0
@onready var _unrealized1: Label = $Unrealized1
@onready var _effect0: Sprite2D = $Effect0
@onready var _effect1: Sprite2D = $Effect1
@onready var _menu_button: TextureButton = $MenuButton
@onready var _round_won_audio: AudioStreamPlayer = $RoundWonAudioPlayer
@onready var _round_over_audio: AudioStreamPlayer = $RoundOverAudioPlayer
@onready var _game_over_audio: AudioStreamPlayer = $GameOverAudioPlayer

## Card positions in hand (top card = last index)
const _hand_top_offset := Vector2(66, 0)

var _p0_card: Card = null
var _p1_card: Card = null
var _round_started: bool = false
var _skip_advance: bool = false
var _advance_delay: float = 0.0
var _in_round: bool = false


func _ready() -> void:
	_menu_button.pressed.connect(_on_menu_button_pressed)


func _on_deck_card_clicked(card: Card) -> void:
	if _in_round:
		return

	var player_idx := int(_player_hand0 == card.get_parent())
	if player_idx != 0:
		return
	if GameState.ai_levels[0] != GameState.AI_Level.Human:
		return

	## Deselect previous selection
	if _p0_card:
		_p0_card.set_selected(false)
		_player_hand0._reposition_cards()

	## Move card to end (top) of hand
	var idx := _player_hand0._selected_card
	_player_hand0._move_card_to_end(idx)

	## Hold card in GameState
	_p0_card = _player_hand0.get_child(idx) as Card
	GameState.hold_card0(_p0_card)
	_p0_card.set_selected(true)

	## If AI opponent has already selected, resolve
	if _p1_card:
		_resolve_phase()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


## Called from Application._on_start_play_pressed.
func init_players(_random_seed: int, _compact: bool) -> void:
	_round_started = false
	_in_round = false
	_skip_advance = false
	_p0_card = null
	_p1_card = null
	_animation_layer.clear()

	## Reset scores
	GameState.scores = [0, 0]
	GameState.unrealized = [0, 0]
	GameState.held_rounds = 0
	GameState.counsellor_points = [0, 0]
	GameState.lady_beats_prince_player = -1
	GameState.round_count = 0
	GameState.round_history.clear()

	## Prepare and deal
	_deck.prepare_braverats()
	await _deal_cards()

	## Show scores
	_update_score_display()

	## Start selection phase
	_select_phase()


func _deal_cards() -> Signal:
	## Deal 8 cards to each player
	for _i in range(8):
		var c0 := _deck.pop()
		var c1 := _deck.pop()
		if c0:
			_player_hand0.add_card(c0)
		if c1:
			_player_hand1.add_card(c1)

	_player_hand0._reposition_cards()
	_player_hand1._reposition_cards()
	return Animator.delay(0.3)


func _update_score_display() -> void:
	## Score
	_score0.text = str(GameState.scores[0])
	_score1.text = str(GameState.scores[1])

	## Plus / Unrealized
	_plus0.visible = GameState.unrealized[0] > 0
	_plus1.visible = GameState.unrealized[1] > 0
	_unrealized0.text = str(GameState.unrealized[0])
	_unrealized1.text = str(GameState.unrealized[1])
	_unrealized0.visible = GameState.unrealized[0] > 0
	_unrealized1.visible = GameState.unrealized[1] > 0

	_update_effect_display()


func _select_phase() -> void:
	_in_round = false
	_skip_advance = false
	_update_effect_display()

	## If Player 0 is Human and hasn't selected, show selection prompt
	if GameState.ai_levels[0] == GameState.AI_Level.Human:
		## Human clicks cards in hand via Deck.input_event → _on_deck_card_clicked
		pass
	else:
		## Player 0 is AI — select immediately
		_ai_select(0)

	## If Player 1 is AI and Player 0 has already selected, trigger AI
	if _p0_card and GameState.ai_levels[1] != GameState.AI_Level.Human:
		_ai_select(1)


func _ai_select(player_idx: int) -> void:
	await Animator.delay(0.2)

	var my_hand := _player_hand0 if player_idx == 0 else _player_hand1
	var opponent_hand := _player_hand1 if player_idx == 0 else _player_hand0

	## Build list of available cards (all cards in hand)
	var available: Array[Card]
	for c in my_hand.get_children():
		available.append(c)

	## Get opponent's known info (if Spy effect is active)
	var opponent_known := []
	if player_idx == 0 and GameState.is_spy_active(0):
		## Player 0 knows Player 1's previous card (from history)
		if GameState.round_count > 0:
			var prev := GameState.round_history[-1]
			opponent_known.append(prev["card1"])

	var chosen := AI.select_card(available, opponent_known, GameState.ai_levels[player_idx])
	if not chosen:
		chosen = available[randi() % available.size()]

	if player_idx == 0:
		## Move to top of P0's hand
		var idx := my_hand._selected_card
		my_hand._move_card_to_end(idx)
		_p0_card = my_hand.get_child(idx) as Card
		GameState.hold_card0(_p0_card)
		_p0_card.set_selected(true)
	else:
		var idx := my_hand._selected_card
		my_hand._move_card_to_end(idx)
		_p1_card = my_hand.get_child(idx) as Card
		GameState.hold_card1(_p1_card)
		_p1_card.set_selected(true)

	## If both players have selected, resolve
	if _p0_card and _p1_card:
		_resolve_phase()


func _resolve_phase() -> void:
	_in_round = true

	## Clear all selection highlights
	if _p0_card:
		_p0_card.set_selected(false)
	if _p1_card:
		_p1_card.set_selected(false)

	## Set both cards face-down before reveal
	_p0_card.face_up = false
	_p1_card.face_up = false

	## Move cards to their table positions
	var p0_pos := $Played0.global_position
	var p1_pos := $Played1.global_position

	var t0 := _animation_layer.move_card(_p0_card, p0_pos, 0.5)
	var t1 := _animation_layer.move_card(_p1_card, p1_pos, 0.5)
	await Animator.all([t0, t1])

	## Flip cards face-up simultaneously
	var f0 := Animator.flip(_p0_card, true, 0.3)
	var f1 := Animator.flip(_p1_card, true, 0.3)
	await Animator.all([f0, f1])

	## Brief pause to show cards
	await Animator.delay(0.5)

	## Resolve round
	var general_active := GameState.is_general_active(0)
	var general_card := _p0_card if general_active else null

	var result: RoundResult.Value = GameState.resolve_current_round()

	## Apply General +2 if active
	if general_active and general_card:
		var orig_power := general_card.power
		if orig_power != Card.Power.General:
			var bonus := 1 if orig_power >= Card.Power.General else 0
			## General's own power doesn't change, just the +2 effect
			pass

	## Update scores
	match result:
		RoundResult.Value.PLAYER0_WINS:
			GameState.scores[0] += 1
		RoundResult.Value.PLAYER1_WINS:
			GameState.scores[1] += 1
		_:
			pass

	## Play sound
	if not _is_speed_run():
		if result == RoundResult.Value.HOLD:
			_round_over_audio.play()
		else:
			_round_won_audio.play()

	## Move cards to discard area
	await _move_cards_to_discard()

	## Clear held cards
	GameState.held_cards0 = null
	GameState.held_cards1 = null
	_p0_card = null
	_p1_card = null

	## Update UI
	_update_score_display()

	## Check for winner
	if GameState.is_game_over():
		_game_over_phase()
		return

	## Clear effects after this round resolves
	GameState.clear_effects()

	## Auto-advance to next round
	_start_advance_timer()


func _move_cards_to_discard() -> Signal:
	var discard_pos := $DiscardMarker.global_position
	var t0 := _animation_layer.move_card(_p0_card if _p0_card else _CardPlaceholder(), discard_pos, 0.3)
	var t1 := _animation_layer.move_card(_p1_card if _p1_card else _CardPlaceholder(), discard_pos, 0.3)
	return Animator.all([t0, t1])


func _CardPlaceholder() -> Node2D:
	## Temporary placeholder for animation when card is null
	var dummy := Node2D.new()
	_animation_layer.add_child(dummy)
	return dummy


func _update_effect_display() -> void:
	## Show Spy icon (frame 2) when active
	if GameState.is_spy_active(0):
		_effect0.frame = 2
		_effect0.visible = true
	else:
		_effect0.visible = false

	if GameState.is_spy_active(1):
		_effect1.frame = 2
		_effect1.visible = true
	else:
		_effect1.visible = false

	if GameState.is_general_active(0):
		_effect0.frame = 6
		_effect0.visible = true
	if GameState.is_general_active(1):
		_effect1.frame = 6
		_effect1.visible = true


func _game_over_phase() -> void:
	if not _is_speed_run():
		_game_over_audio.play()

	var app := get_node("/root/Application") as Node2D
	if app:
		var go := app.get_node("GameOver") as Node2D
		if go:
			go.show_game()
			go.show()
	else:
		push_error("GameOver: Application root not found")


func _start_advance_timer() -> void:
	var speed := pow(2, Animator._speed)
	_advance_delay = 1.0 * speed if not _skip_advance else 0.0

	if _advance_delay > 0:
		await Animator.delay(_advance_delay)

	_advance_to_next_round()


func _advance_to_next_round() -> void:
	GameState.round_count += 1
	_animation_layer.clear()

	## If both AI, auto-select immediately
	if GameState.ai_levels[0] != GameState.AI_Level.Human and GameState.ai_levels[1] != GameState.AI_Level.Human:
		_select_phase()
		return

	## Human player — wait for card selection
	if GameState.ai_levels[0] == GameState.AI_Level.Human:
		_select_phase()
		return


func _is_speed_run() -> bool:
	return Animator._speed == 0 or Animator._speed >= pow(2, 5)

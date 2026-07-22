class_name Main
extends Node2D

signal menu_pressed
signal round_finished(level: GameState.AI_Level)
signal round_won(level: GameState.AI_Level)
signal save_stats
signal game_over(winner: int)


@onready var _deck: Deck = $Deck
@onready var _player_hand0: Deck = $PlayerHand0
@onready var _player_hand1: Deck = $PlayerHand1
@onready var _animation_layer: Node2D = $AnimationLayer

@onready var _played_1: Marker2D = $Played1
@onready var _played_0: Marker2D = $Played0

@onready var _score0: Label = $Score0
@onready var _score1: Label = $Score1
@onready var _unrealized0: Label = $Unrealized0
@onready var _unrealized1: Label = $Unrealized1
@onready var _effect0: Sprite2D = $Effect0
@onready var _effect1: Sprite2D = $Effect1

@onready var _card_list1: Label = $CardList1

@onready var _menu_button: TextureButton = $MenuButton

@onready var _deal_audio: AudioStreamPlayer = $DealAudioPlayer
@onready var _round_over_audio: AudioStreamPlayer = $RoundOverAudioPlayer
@onready var _game_over_audio: AudioStreamPlayer = $GameOverAudioPlayer

var _game_state: GameState = GameState.new()
var _round_active: bool = false

## Pre-set hands for testing/debugging. Each char maps to a card.
## Passed to Deck.prepare_braverats() to populate the deck with those exact cards.
## If empty, default power order (0-7) is used for each player.
@export var hand0: String = ""
@export var hand1: String = ""


func _ready() -> void:
	_deck.clear()
	_player_hand0.clear()
	_player_hand1.clear()
	_clear_animation_layer()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


# ─── Game Loop ──────────────────────────────────────────────────────────────

## Initialize a new game: set AI levels, prepare deck, deal 8 cards each.
func init_players(_random_seed: int) -> void:
	_deck.clear()
	_player_hand0.clear()
	_player_hand1.clear()
	_clear_animation_layer()
	_clear_played_cards()

	_game_state.new_game()
	_prepare_deck()
	_update_display()
	await _deal_cards()
	_start_selection_phase()


func _prepare_deck() -> void:
	_deck.prepare_braverats(hand0, hand1)


## Deal 8 cards to each player hand with animation.
## Deck is pre-populated by prepare_braverats(hand0, hand1).
func _deal_cards() -> Signal:
	for i in range(8):
		# Deal to Player 0 (bottom)
		var c := _deck.pop()
		if c:
			var pos := _player_hand0.get_append_position()
			c.face_up = true
			c.global_position = _deck.global_position
			_player_hand0.add_child(c)
			await Animator.move_card(c, pos, 0.15)
			c.pressed.connect(_on_card_hand_clicked.bind(c))

		# Deal to Player 1 (top)
		c = _deck.pop()
		if c:
			var pos := _player_hand1.get_append_position()
			c.face_up = false
			c.global_position = _deck.global_position
			_player_hand1.add_child(c)
			c.position = Vector2.ZERO
			await Animator.move_card(c, pos, 0.15)

	return Animator._immediate()


# ─── Selection Phase ────────────────────────────────────────────────────────

## Wait for both players to select cards.
## When Spy is active, the spied-on player picks first (card shown face-up),
## then the spy-holder picks second, knowing the opponent's card.
func _start_selection_phase() -> void:
	_round_active = true
	_update_display()

	# Spy cancels if both players have it (both played Spy last round)
	var p0_has_spy = _game_state.is_spy_active(0) and not _game_state.is_spy_active(1)
	var p1_has_spy = _game_state.is_spy_active(1) and not _game_state.is_spy_active(0)

	if p0_has_spy:
		# P0 has spy: P1 picks first (blind, shown face-up), then P0 picks knowing P1's card
		if _game_state.ai_levels[1] != GameState.AI_Level.Human:
			await _ai_select(1) # AI P1 picks blind
	elif p1_has_spy:
		# P1 has spy: P0 picks first (blind, shown face-up), then P1 picks knowing P0's card
		if _game_state.ai_levels[0] != GameState.AI_Level.Human:
			await _ai_select(0) # P0 AI picks blind, then triggers P1 with card info
		# Else P0 is human, picks via _on_card_hand_clicked which triggers AI P1
	else:
		# Normal: both pick blind
		# If P0 is AI, _ai_select(0) recursively triggers P1 via opponent_held check.
		# If P0 is human, P1 picks first (then waits for P0's human input).
		if _game_state.ai_levels[0] != GameState.AI_Level.Human:
			await _ai_select(0)
		elif _game_state.ai_levels[1] != GameState.AI_Level.Human:
			await _ai_select(1)


# ─── Human Input ────────────────────────────────────────────────────────────

## Called when a card in PlayerHand is clicked (via Deck.card_clicked).
func _on_card_hand_clicked(card: Card) -> void:
	if not _round_active:
		return

	if _game_state.ai_levels[0] != GameState.AI_Level.Human:
		return

	card.pressed.disconnect(_on_card_hand_clicked)
	card.reparent(_played_0)
	card.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	await Animator.move_card(card, _played_0.global_position, 0.5)
	_game_state.hold_card0(card)

	# If P1 has spy, P0's card is flipped face-up and AI P1 picks knowing P0's card
	if _game_state.is_spy_active(1):
		await Animator.flip(card, true, 0.3)
		if _game_state.ai_levels[1] != GameState.AI_Level.Human:
			_ai_select(1, card) # AI P1 knows P0's card
	# If P0 has spy and P1 already picked, proceed to reveal
	elif _game_state.held_cards1 != null:
		_start_reveal()


# ─── AI Selection ───────────────────────────────────────────────────────────

## AI selects a card from its hand.
## If `known_opponent_card` is provided, the AI knows the opponent's card (spy effect).
func _ai_select(player_idx: int, known_opponent_card: Card = null) -> void:
	var opponent_idx := 1 - player_idx
	var my_hand: Deck = _player_hand0 if player_idx == 0 else _player_hand1
	var opp_hand: Deck = _player_hand1 if player_idx == 0 else _player_hand0

	# Build my hand array
	var my_cards: Array[Card]
	for c in my_hand.get_children():
		my_cards.append(c as Card)

	var opp_cards := [known_opponent_card] as Array[Node] if known_opponent_card else opp_hand.get_children()
	var selected: Card = AI.select_card(my_cards, opp_cards, player_idx, _game_state)
	#print("AI selected card: " + AI.SHORT_NAMES[selected.power] + "\n")
	var tgt: Marker2D
	# Store in GameState
	if player_idx == 0:
		tgt = _played_0
		_game_state.hold_card0(selected)
	else:
		tgt = _played_1
		_game_state.hold_card1(selected)

	selected.reparent(tgt)
	selected.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	await Animator.move_card(selected, tgt.global_position, 0.5)

	# If this player is being spied on, flip card face-up with animation
	if _game_state.is_spy_active(opponent_idx):
		await Animator.flip(selected, true, 0.3)

	# Check if opponent has already selected
	var opponent_held = (player_idx == 0 and _game_state.held_cards1 != null) or \
						(player_idx == 1 and _game_state.held_cards0 != null)

	if opponent_held:
		_start_reveal()
	else:
		# Trigger opponent if AI and hasn't picked yet
		if _game_state.ai_levels[opponent_idx] != GameState.AI_Level.Human:
			await Animator.delay(0.3)
			if _round_active:
				_ai_select(opponent_idx, selected if _game_state.is_spy_active(opponent_idx) else null)


# ─── Reveal Phase ───────────────────────────────────────────────────────────

## Both players have selected. Animate reveal and resolve.
func _start_reveal() -> void:
	_round_active = false

	var c0 := _game_state.held_cards0 as Card
	var c1 := _game_state.held_cards1 as Card

	# Brief pause, then reveal
	await Animator.delay(0.2)
	await Animator.flip(c0, true, 0.3)
	await Animator.flip(c1, true, 0.3)

	# Resolve round after reveal
	await Animator.delay(2)
	_resolve_round(c0, c1)


# ─── Round Resolution ───────────────────────────────────────────────────────

## Resolve the current round: apply effects, update scores, animate.
func _resolve_round(c0: Card, c1: Card) -> void:
	# Step 1: Resolve the round (determine result + effects)
	_game_state = GameLogic.resolve_round(_game_state.held_cards0, _game_state.held_cards1, _game_state)

	# Step 2: Finalize round state (update history, scores, held rounds)
	GameLogic.finalize_round(_game_state, _game_state.held_cards0, _game_state.held_cards1, _game_state.last_result)

	# Track Lady vs Prince instant win (already set in resolve_round)
	# lady_beats_prince_player is set inside resolve_round

	# Clear held cards
	_game_state.held_cards0 = null
	_game_state.held_cards1 = null

	# Step 4: Check winner
	_game_state.winner = GameLogic.check_winner(_game_state)

	# Update scores and display
	_update_display()

	# Play round sound
	if not _is_speedrun():
		_round_over_audio.play()

	# Move cards to discard pile
	var marker_pos: Vector2 = $DiscardMarker.global_position
	await Animator.move_card(c0, marker_pos, 0.3)
	await Animator.move_card(c1, marker_pos, 0.3)
	c0.queue_free()
	c1.queue_free()

	# Check for winner
	if _game_state.is_game_over():
		_handle_game_over(_game_state.winner)
	else:
		_advance_to_next_round()


## Handle game over transition.
func _handle_game_over(winner: GameState.RoundResult) -> void:
	# Play game over sound
	if not _is_speedrun():
		_game_over_audio.play()

	await Animator.delay(1.5)

	# Determine if there's a winner (PLAYER0_WINS_GAME=3, PLAYER1_WINS_GAME=4)
	var winner_idx: int = -1
	if winner == GameState.RoundResult.PLAYER0_WINS_GAME:
		round_won.emit(_game_state.ai_levels[0])
	elif winner == GameState.RoundResult.PLAYER1_WINS_GAME:
		round_won.emit(_game_state.ai_levels[1])

	# Emit round_finished for both players
	for player_idx in range(2):
		round_finished.emit(_game_state.ai_levels[player_idx])

	# Emit save_stats
	save_stats.emit()

	# Notify application to show game over screen
	game_over.emit(winner)


## Advance to next round (auto-advance).
func _advance_to_next_round() -> void:
	# Short pause before next round
	var delay_time := 1.0 if _is_speedrun() else 2.0
	await Animator.delay(delay_time)

	# If game was interrupted (pause/exit), skip
	if _game_state.is_game_over():
		return

	_round_active = true
	_update_display()
	_start_selection_phase()


# ─── Restart ────────────────────────────────────────────────────────────────

## Called by application when play-again is pressed.
func start_new_game() -> void:
	init_players(0)


# ─── UI Updates ─────────────────────────────────────────────────────────────

## Update all display labels from GameState.
func _update_display() -> void:
	# Scores
	_score0.text = str(_game_state.scores[0])
	_score1.text = str(_game_state.scores[1])

	# Plus / unrealized
	_unrealized0.text = str(_game_state.unrealized[0])
	_unrealized1.text = str(_game_state.unrealized[1])

	# Effect indicators
	_update_effect(_effect0, _game_state.is_spy_active(0), _game_state.is_general_active(0))
	_update_effect(_effect1, _game_state.is_spy_active(1), _game_state.is_general_active(1))

	# Player 1 hand display
	_card_list1.text = _build_hand_string(_player_hand1)


## Show effect indicator sprite frame.
func _update_effect(sprite: Sprite2D, is_spy: bool, is_general: bool) -> void:
	if is_spy:
		sprite.visible = true
		sprite.frame = Card.Power.Spy
	elif is_general:
		sprite.visible = true
		sprite.frame = Card.Power.General
	else:
		sprite.visible = false


# ─── Helpers ────────────────────────────────────────────────────────────────

func _clear_animation_layer() -> void:
	while _animation_layer.get_child_count() > 0:
		var ch := _animation_layer.get_child(0)
		_animation_layer.remove_child(ch)
		ch.queue_free()


func _free_all(node: Node) -> void:
	while node.get_child_count() > 0:
		var c := node.get_child(0)
		node.remove_child(c)
		c.queue_free()


func _clear_played_cards() -> void:
	_free_all(_player_hand0)
	_free_all(_player_hand1)
	_free_all(_played_0)
	_free_all(_played_1)


func _is_speedrun() -> bool:
	return Animator._speed <= 0


# ─── Hand Display ────────────────────────────────────────────────────────────

## Build a string representation of a player's hand.
## Each card is shown as its power digit (0-7).
## Space character for empty slots up to max hand size.
func _build_hand_string(hand: Deck) -> String:
	const EMPTY = "        "
	var result := EMPTY
	for card in hand.get_children():
		result[card.power] = str(card.power)
	return result

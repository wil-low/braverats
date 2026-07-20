class_name Main
extends Node2D

signal menu_pressed
signal round_finished(ai_level: int)
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

@onready var _menu_button: TextureButton = $MenuButton

@onready var _deal_audio: AudioStreamPlayer = $DealAudioPlayer
@onready var _round_over_audio: AudioStreamPlayer = $RoundOverAudioPlayer
@onready var _game_over_audio: AudioStreamPlayer = $GameOverAudioPlayer

var _game_state: GameState = GameState.new()
var _round_active: bool = false


func _ready() -> void:
	_deck.clear()
	_player_hand0.clear()
	_player_hand1.clear()
	_clear_animation_layer()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


# ─── Game Loop ──────────────────────────────────────────────────────────────

## Initialize a new game: set AI levels, prepare deck, deal 8 cards each.
func init_players(_random_seed: int, _compact: bool) -> void:
	_deck.clear()
	_player_hand0.clear()
	_player_hand1.clear()
	_clear_animation_layer()

	_game_state.new_game()
	_prepare_deck()
	await _deal_cards()
	_update_display()
	_start_selection_phase()


func _prepare_deck() -> void:
	_deck.prepare_braverats()


## Deal 8 cards to each player hand with animation.
func _deal_cards() -> Signal:
	for i in range(8):
		# Deal to Player 0 (bottom)
		var c := _deck.pop()
		if c:
			var pos := _player_hand0.get_append_position()
			c.face_up = true
			c.global_position = _deck.global_position
			_player_hand0.add_child(c)
			c.position = Vector2.ZERO
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
func _start_selection_phase() -> void:
	_round_active = true
	_update_display()

	# If P0 is human, wait for click. If AI, pick immediately.
	if _game_state.ai_levels[0] != GameState.AI_Level.Human:
		_ai_select(0)
	if _game_state.ai_levels[1] != GameState.AI_Level.Human:
		_ai_select(1)


# ─── Human Input ────────────────────────────────────────────────────────────

## Called when a card in PlayerHand is clicked (via Deck.card_clicked).
func _on_card_hand_clicked(card: Card) -> void:
	if not _round_active:
		return

	if _game_state.ai_levels[0] != GameState.AI_Level.Human:
		return

	card.pressed.disconnect(_on_card_hand_clicked)
	_played_0.add_child(card)
	card.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	await Animator.move_card(card, _played_0.global_position, 0.5)
	_game_state.hold_card0(card)

	# If P1 AI has already selected, proceed to reveal
	if _game_state.held_cards1 != null:
		_start_reveal()


# ─── AI Selection ───────────────────────────────────────────────────────────

## AI selects a card from its hand.
func _ai_select(player_idx: int) -> void:
	var opponent_idx := 1 - player_idx
	var my_hand: Deck = _player_hand0 if player_idx == 0 else _player_hand1
	var opp_hand: Deck = _player_hand1 if player_idx == 0 else _player_hand0

	# Build my hand array
	var my_cards: Array[Card]
	for c in my_hand.get_children():
		my_cards.append(c as Card)

	# Build opponent's known cards (face-down cards are unknown)
	var opp_cards: Array[Card]
	if _game_state.is_spy_active(player_idx):
		# Spy reveals opponent's held card
		if opponent_idx == 0 and _game_state.held_cards0 != null:
			opp_cards.append(_game_state.held_cards0)
		elif opponent_idx == 1 and _game_state.held_cards1 != null:
			opp_cards.append(_game_state.held_cards1)
		# Also show any face-up opponent cards (shouldn't happen normally)
		for c in opp_hand.get_children():
			var found := false
			for known in opp_cards:
				if known == c:
					found = true
					break
			if not found:
				opp_cards.append(c)
	else:
		opp_cards = []

	var selected: Card = AI.select_card(my_cards, opp_cards, player_idx, _game_state)
	
	var tgt: Marker2D
	# Store in GameState
	if player_idx == 0:
		tgt = _played_0
		_game_state.hold_card0(selected)
	else:
		tgt = _played_1
		_game_state.hold_card1(selected)

	tgt.add_child(selected)
	selected.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	await Animator.move_card(selected, tgt.global_position, 0.5)


	# If opponent already selected, proceed to reveal
	var opponent_already := (player_idx == 0 and _game_state.held_cards1 != null) or \
							(player_idx == 1 and _game_state.held_cards0 != null)
	if opponent_already:
		_start_reveal()
	else:
		# AI opponent picks after brief delay (simulates thinking time)
		await Animator.delay(0.3)
		#if _round_active:
		#	_ai_select(1 - player_idx)


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
	await Animator.delay(0.5)
	_resolve_round(c0, c1)


# ─── Round Resolution ───────────────────────────────────────────────────────

## Resolve the current round: apply effects, update scores, animate.
func _resolve_round(c0: Card, c1: Card) -> void:
	# Apply General +2 effect to held card
	if _game_state.is_general_active(0):
		c0.set_power(c0.power)  # Flag that General effect is applied
	if _game_state.is_general_active(1):
		c1.set_power(c1.power)  # Flag that General effect is applied

	# Resolve the round

	# Step 1: Resolve the round (determine result + effects)
	_game_state = GameLogic.resolve_round(_game_state.held_cards0, _game_state.held_cards1, _game_state)

	# Step 2: Finalize round state (update history, scores, held rounds)
	GameLogic.finalize_round(_game_state, _game_state.held_cards0, _game_state.held_cards1, _game_state.last_result)

	# Step 3: Increment round counter
	_game_state.round_count += 1

	# Track Lady vs Prince instant win (already set in resolve_round)
	# lady_beats_prince_player is set inside resolve_round

	# Clear held cards
	_game_state.held_cards0 = null
	_game_state.held_cards1 = null

	# Step 4: Check winner
	var winner: int = GameLogic.check_winner(_game_state)
	if winner >= 0:
		_game_state.game_over = true

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

	# Clear effects after resolution
	_game_state.clear_effects()

	# Check for winner
	if _game_state.is_game_over():
		_handle_game_over(winner)
	else:
		_advance_to_next_round()


## Handle game over transition.
func _handle_game_over(winner: int) -> void:
	# Play game over sound
	if not _is_speedrun():
		_game_over_audio.play()

	await Animator.delay(1.5)

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
	init_players(0, false)


# ─── UI Updates ─────────────────────────────────────────────────────────────

## Update all display labels from GameState.
func _update_display() -> void:
	# Scores
	_score0.text = str(_game_state.scores[0])
	_score1.text = str(_game_state.scores[1])

	# Plus / unrealized
	if _game_state.unrealized[0] > 0:
		_unrealized0.text = str(_game_state.unrealized[0])

	if _game_state.unrealized[1] > 0:
		_unrealized1.text = str(_game_state.unrealized[1])

	# Effect indicators
	_update_effect(_effect0, _game_state.is_spy_active(0), _game_state.is_general_active(0))
	_update_effect(_effect1, _game_state.is_spy_active(1), _game_state.is_general_active(1))


## Show effect indicator sprite frame.
func _update_effect(sprite: Sprite2D, is_spy: bool, is_general: bool) -> void:
	if is_spy:
		sprite.visible = true
		sprite.frame = 2  # Spy frame
	elif is_general:
		sprite.visible = true
		sprite.frame = 6  # General frame
	else:
		sprite.visible = false


# ─── Helpers ────────────────────────────────────────────────────────────────

func _clear_animation_layer() -> void:
	while _animation_layer.get_child_count() > 0:
		var ch := _animation_layer.get_child(0)
		_animation_layer.remove_child(ch)
		ch.queue_free()


func _is_speedrun() -> bool:
	return Animator._speed <= 0

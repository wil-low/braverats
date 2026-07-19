class_name Main
extends Node2D

signal menu_pressed
signal round_won(player_idx: int)
signal round_finished(player_idx: int)
signal save_stats

@export var max_games: int = 1000

var _random_seed: int = 0
var game_counter: int = 0
var interrupted: bool

var _player_count: int
var _players: Array[Player]
var _cur_player: int
var _table_rank: Card.Rank
var _last_discard_player: int = -1

var _memories: Array[Memory]


@onready var _deck: Deck = $Deck
@onready var _table: Node2D = $Table
@onready var _central_display: Deck = $Table/CentralDisplay
@onready var _last_deck: Deck = $Table/LastDeck
@onready var _animation_layer: Node2D = $AnimationLayer
@onready var _message_box: ColorRect = $MessageBox
@onready var _message_label: Label = $MessageBox/MessageLabel
@onready var _message_button: Button = $MessageBox/MessageButton
@onready var _table_rank_label: Label = $Table/TableRank
@onready var _rank_frame: Sprite2D = $Table/TableRank/RankFrame
@onready var _discard_marker: Marker2D = $DiscardMarker
@onready var _deal_audio_player: AudioStreamPlayer = $DealAudioPlayer
@onready var _rank_selector: RankSelector = $RankSelector
@onready var _play_label: Label = $Table/PlayLabel
@onready var _check_label: Label = $Table/CheckLabel


func _ready() -> void:
	_table.hide()
	_players = [$Player0, $Player1, $Player2, $Player3]
	_player_count = 0
	for p in _players:
		if p:
			_player_count += 1


func init_players(random_seed: int, compact: bool) -> void:
	_random_seed = random_seed
	_message_box.hide()
	await Animator.flash(0, [])
	for p in _players:
		if !p:
			continue
		if p.move_chosen.is_connected(_on_move_chosen):
			p.move_chosen.disconnect(_on_move_chosen)
		if !p.move_chosen.is_connected(_on_move_chosen):
			p.move_chosen.connect(_on_move_chosen)
		if p.cards_discarded.is_connected(_on_cards_discarded):
			p.cards_discarded.disconnect(_on_cards_discarded)
		if !p.cards_discarded.is_connected(_on_cards_discarded):
			p.cards_discarded.connect(_on_cards_discarded)
		p.clear_hand()
	# Recreate player 0's hand based on compact mode
	if _players[0]:
		_players[0].set_compact_mode(_players[0].is_human() and compact)
	# Connect rank selector signal
	if _rank_selector and !_rank_selector.rank_selected.is_connected(_on_rank_selected):
		_rank_selector.rank_selected.connect(_on_rank_selected)
	
	_new_game()


func _new_game() -> void:
	if _random_seed:
		seed(_random_seed)
	interrupted = false
	game_counter += 1
	if game_counter > max_games:
		push_warning("Max games count reached, stop")
	else:
		print("\n\nNew game " + str(game_counter))
		_cur_player = 0
		# One memory per player — each tracks everything they know about others
		_memories.clear()
		for p in _players:
			if p:
				p.memory = Memory.new(Card.RANK_NAMES.size())
				p.score = 0
				p.current_mark.hide()
		_new_round()


func _new_round() -> void:
	print("\n\nNEW ROUND\n")
	
	# Clear CentralDisplay and LastDeck
	_clear_deck(_central_display)
	_clear_deck(_last_deck)

	while _animation_layer.get_child_count() > 0:
		var ch := _animation_layer.get_child(0)
		_animation_layer.remove_child(ch)
		ch.queue_free()
	
	# Prepare deck (35 cards for 4 players)
	_deck.prepare_cheaters()
	
	# Deal all cards to players
	for p in _players:
		if !p:
			continue
		p.clear_hand()
	
	for _i in range(9):  # 35/4 = ~9 cards each
		for p in _players:
			if !p:
				continue
			await _deal_card(p, 0.1)
	
	# Sync all players' memories with initial hand sizes
	for p in _players:
		for other in _players:
			p.memory.get_player(other.idx).hand_size = other.hand.get_child_count()
	
	# Table rank is Unknown at start of round — first player's discard sets it
	_table_rank = Card.Rank.Unknown
	_update_table_rank_display()
	_table.show()
	
	# Start first turn
	_last_discard_player = -1
	new_turn()


func _clear_deck(deck: Deck) -> void:
	while deck.get_child_count() > 0:
		var c := deck.pop()
		if c:
			c.queue_free()


func _deal_card(p: Player, duration: float = 0.5) -> void:
	var c := _deck.pop()
	if !c:
		return
	_deal_audio_player.play()
	_animation_layer.add_child(c)
	c.faceup = p.idx == 0 
	c.global_position = _deck.global_position
	var dst: Vector2 = p.hand.get_append_position(c.rank)
	await Animator.move_card(c, dst, duration)
	p.add_card(c)
	c.position = p.hand.to_local(dst)


func _update_table_rank_display() -> void:
	if _table_rank_label:
		_table_rank_label.text = Card.RANK_NAMES[_table_rank] if _table_rank < Card.RANK_NAMES.size() else " "


func new_turn() -> void:
	if interrupted:
		return
	
	print("\nNew turn for Player " + str(_cur_player) + ", level " + str(_players[_cur_player].ai_level))
	
	# Check if current player has won
	var winner := _check_winner()
	if winner >= 0:
		_round_over(winner)
		return
	
	var p := _players[_cur_player]
	if !p:
		_cur_player = (_cur_player + 1) % _player_count
		new_turn()
		return
	
	for other in _players:
		if other:
			other.current_mark.hide()
	p.current_mark.show()
	
	_check_label.hide()
	_play_label.hide()
	
	# If previous player just discarded and has 0 cards, current player must challenge
	if _last_discard_player >= 0 and _players[_last_discard_player] and _players[_last_discard_player].is_empty():
		_state_force_challenge()
		return
	
	# Normal turn: current player discards or challenges
	_state_discard()


func _move_last_to_central() -> void:
	# Animate cards from LastDeck to CentralDisplay
	for i in range(_last_deck.get_child_count()):
		var card := _last_deck.get_child(0)
		var g = card.global_position
		card.reparent(_animation_layer)
		card.global_position = g
		var tgt := _central_display.get_append_position(card.rank)
		await Animator.move_card(card, tgt)
		card.reparent(_central_display)
		card.position = _central_display.to_local(tgt)


func _state_discard() -> void:
	var p := _players[_cur_player]
	p._state = Player.State.SELECT_DISCARD
	if _table_rank != Card.Rank.Unknown:
		p._state |= Player.State.SELECT_CHALLENGE

	if p.is_human() and (p._state & Player.State.SELECT_CHALLENGE):
		_check_label.show()
	
	_rank_frame.visible = false
	if p.is_human():
		# Clear old selection on new turn
		p.hand.clear_selection()
		_play_label.show()
		_rank_frame.visible = _last_deck.get_child_count() == 0
	else:
		await get_tree().process_frame
		# First: check if AI wants to voluntarily challenge the last discard
		if p._state & Player.State.SELECT_CHALLENGE:
			var should := true if p._state == Player.State.SELECT_CHALLENGE else AI.should_challenge(p.memory, p.ai_level)
			if should:
				_check_label.show()
				p.ai_challenge()
				return
		p.ai_discard(_table_rank)


func _state_force_challenge() -> void:
	print("Player " + str(_last_discard_player) + " has 0 cards! Player " + str(_cur_player) + " must challenge!")
	
	var p := _players[_cur_player]
	if !p:
		_cur_player = (_cur_player + 1) % _player_count
		new_turn()
		return
	
	p._state = Player.State.SELECT_CHALLENGE
	if p.is_human():
		_check_label.show()
	
	if p.is_human():
		pass  # Human clicks challenge button
	else:
		await get_tree().process_frame
		_check_label.show()
		p.ai_challenge()


# ─── Signal handlers ────────────────────────────────────────────────────────

func _on_cards_discarded(count: int, table_rank: Card.Rank, cards: Array[Card]) -> void:
	if interrupted:
		return
	
	var p := _players[_cur_player]
	if !p or (p._state & Player.State.SELECT_DISCARD) == 0:
		return
	
	p._state = Player.State.IDLE
	
	await _after_discard(table_rank, count, cards)


func _execute_discard_move(move: Move) -> void:
	await _after_discard(move._table_rank, move._cards.size(), move._cards)


func _after_discard(table_rank: Card.Rank, count: int, cards: Array[Card]) -> void:
	var p := _players[_cur_player]
	
	# Clear rank selector if it's visible (human's first discard completed)
	if _rank_selector.visible:
		_rank_selector.hide()
		_table.show()
	
	# First player to discard sets the table rank for the round
	if _table_rank == Card.Rank.Unknown:
		_table_rank = table_rank
		_update_table_rank_display()
		print("Player " + str(_cur_player) + " sets table rank to " + Card.RANK_NAMES[_table_rank])
	
	# Move LastDeck cards to CentralDisplay (previous player's discard becomes rest)
	if _last_deck.get_child_count() > 0:
		await _move_last_to_central()
	
	# Sort cards by hand index so animation proceeds in hand order
	var sorted_cards: Array[Card] = cards.duplicate()
	sorted_cards.sort_custom(func(a: Card, b: Card): return a.get_index() < b.get_index())

	# Move cards to LastDeck (face-down on table, count visible via fan)
	var min_idx := 999
	for c in sorted_cards:
		var card_idx := c.get_index()
		if min_idx > card_idx:
			min_idx = card_idx
	for c in sorted_cards:
		await _move_to_last_deck(c)
	p.hand.shift_to(min_idx)
	
	_last_discard_player = _cur_player
	
	# Update all players' memories with what they just observed
	_update_memories_after_discard(_cur_player, table_rank, count)
	
	# Sync game state: central display count, last discard count, discarding player's hand size
	for pl in _players:
		pl.memory.central_count = _central_display.get_child_count()
		pl.memory.last_discard_count = _last_deck.get_child_count()
		pl.memory.get_player(_cur_player).hand_size = pl.hand.get_child_count()
	
	# Update table_rank in all memories
	for pl in _players:
		pl.memory.table_rank = _table_rank
	
	print("Player " + str(_cur_player) + " discarded " + str(count) + " cards for " + Card.RANK_NAMES[table_rank])
	
	# Check if player is now empty
	if p.is_empty():
		print("Player " + str(_cur_player) + " has 0 cards! Next player must challenge!")
		_cur_player = (_cur_player + 1) % _player_count
		_state_force_challenge()
		return
	
	# Move to next player
	_cur_player = (_cur_player + 1) % _player_count
	new_turn()


func _move_to_last_deck(card: Card) -> void:
	card.set_selected(false)
	await Animator.flip(card, false)
	var g = card.global_position
	card.reparent(_animation_layer)
	card.global_position = g
	var tgt := _last_deck.get_append_position(card.rank)
	await Animator.move_card(card, tgt)
	card.reparent(_last_deck)
	card.position = _last_deck.to_local(tgt)


func _on_move_chosen(move: Move) -> void:
	if interrupted:
		return
	
	await Animator.delay(0.5)
	
	match move._action:
		Move.Action.Discard_1, Move.Action.Discard_2, Move.Action.Discard_3:
			assert(move._table_rank != Card.Rank.Unknown)
			await _execute_discard_move(move)
		Move.Action.Challenge:
			await _execute_challenge()


func _execute_challenge() -> void:
	print("CHALLENGE from Player " + str(_cur_player) + "!")
	
	var p_challenger := _players[_cur_player]
	var p_discarder := _players[_last_discard_player]
	
	if !p_challenger or !p_discarder:
		return
	
	# Reveal LastDeck cards
	var is_bluff := false
	var revealed_count := _last_deck.get_child_count()
	for i in range(revealed_count):
		var c := _last_deck.get_child(i)
		await Animator.flip(c, true, 0.3)
		# Check if this card matches the table rank
		if c.rank != _table_rank:
			is_bluff = true
	
	await Animator.delay(1)
	# All players now see the exact card composition of the last discard
	_update_memories_after_challenge(_last_discard_player, _last_deck.get_children(), revealed_count)
	
	if is_bluff:
		# Challenger wins! Discarder draws all cards from both decks
		print("BLUFF! Player " + str(_last_discard_player) + " caught! Cards didn't match " + Card.RANK_NAMES[_table_rank])
		await _resolve_challenge_won(_cur_player, _last_discard_player)
	else:
		# Challenger wrong! Challenger draws all cards
		print("CORRECT call Player " + str(_cur_player) + " was wrong! Cards matched " + Card.RANK_NAMES[_table_rank])
		await _resolve_challenge_won(_last_discard_player, _cur_player)


func _resolve_challenge_won(winner_idx: int, loser_idx: int) -> void:
	print("resolve_challenge_won: winner " + str(winner_idx) + ", loser " + str(loser_idx))
	var winner := _players[winner_idx]
	var loser := _players[loser_idx]
	
	if !winner or !loser:
		return
	
	# Loser draws ALL cards from both CentralDisplay and LastDeck
	await _draw_pile(loser, _central_display)
	await _draw_pile(loser, _last_deck)
	
	await _discard_4_of_a_kind(loser)
	
	# Clear decks
	_clear_deck(_central_display)
	_table_rank = Card.Rank.Unknown
	_update_table_rank_display()
	
	# Sync memories after challenge resolution
	for p in _players:
		p.memory.central_count = 0
		p.memory.last_discard_count = 0
		p.memory.table_rank = Card.Rank.Unknown
		p.memory.get_player(loser_idx).hand_size = p.hand.get_child_count()
	
	# Next starter is player left of loser
	_cur_player = (loser_idx + 1) % _player_count
	
	# Check if winner has 0 cards after their forced discard
	if winner.is_empty():
		_round_over(winner_idx)
		return
	
	new_turn()


func _draw_pile(player: Player, source_deck: Deck) -> void:
	for i in range(source_deck.get_child_count()):
		var c := source_deck.get_child(0)
		await Animator.flip(c, player.idx == 0)
		source_deck.remove_child(c)
		_animation_layer.add_child(c)
		c.global_position = source_deck.global_position
		var dst: Vector2 = player.hand.get_append_position(c.rank)
		await Animator.move_card(c, dst, 0.2)
		player.add_card(c)
		c.position = player.hand.to_local(dst)


func _discard_4_of_a_kind(player: Player) -> void:
	var cards_to_remove : Array[Card] = player.hand.get_4_of_a_kind()
	var min_index := 999
	for card in cards_to_remove:
		if min_index > card.get_index():
			min_index = card.get_index()
		card.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		await Animator.flip(card, true)
		await Animator.move_card(card, _discard_marker.global_position, 0.25)
		player.hand.remove_child(card)
		card.queue_free()
	player.hand.shift_to(min_index)


func _check_winner() -> int:
	for i in range(_player_count):
		var p := _players[i]
		if p and p.is_empty():
			return i
	return -1


# Populate all players' memories with observations from this discard.
func _update_memories_after_discard(discarding_player_idx: int, rank: Card.Rank, count: int) -> void:
	for p in _players:
		# Everyone learns: discarding player had at least `count` of `rank`,
		# so they hold at most (4 - count).
		p.memory.tighten_player(discarding_player_idx, rank, 4 - count)


# Populate all players' memories with the exact card composition revealed
# during a challenge.
func _update_memories_after_challenge(discarder_idx: int, revealed_cards: Array, _revealed_count: int) -> void:
	# Count actual cards of each rank in the revealed discard
	var rank_counts: Dictionary = {}
	for c in revealed_cards:
		if c is Card and c.rank != Card.Rank.Unknown:
			rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1
	
	for p in _players:
		# Everyone learns the exact composition of what was discarded
		for rank in rank_counts:
			p.memory.tighten_player(discarder_idx, rank, rank_counts[rank])


func _round_over(winner_idx: int) -> void:
	var winner := _players[winner_idx]
	print("\n=== ROUND OVER! Player " + str(winner_idx) + " wins! ===")
	
	for p in _players:
		if p:
			p.current_mark.hide()
			round_finished.emit(p.ai_level)
	round_won.emit(winner.ai_level)
	save_stats.emit()
	
	_message_label.text = "PLAYER " + str(winner_idx) + " WINS!"
	if !_message_button.pressed.is_connected(_on_round_over_pressed):
		_message_button.pressed.connect(_on_round_over_pressed)
	
	_table.hide()
	_message_box.show()
	if !_players[0].is_human():
		await Animator.delay(2)
		_on_round_over_pressed()

func _on_menu_button_pressed() -> void:
	menu_pressed.emit()


func _on_select_rank_pressed() -> void:
	"""Human player presses the Table Rank button."""
	var p := _players[_cur_player]
	if !p:
		return
	if _last_deck.get_child_count() == 0:
		_table.hide()
		_rank_selector.show()


func _on_discard_pressed() -> void:
	"""Human player presses the Discard button."""
	var p := _players[_cur_player]
	if !p:
		return
	if _table_rank != Card.Rank.Unknown and p._state & Player.State.SELECT_DISCARD:
		var count: int = p.hand.get_selected_count()
		if count > 0 and count <= 3:
			_play_label.hide()
			p._execute_discard()


func _on_rank_selected(rank: Card.Rank) -> void:
	"""Human selected a rank for their first discard."""
	_table_rank = rank
	_update_table_rank_display()
	
	# Hide RankSelector and show Table
	_rank_selector.hide()
	_table.show()


func _on_challenge_pressed() -> void:
	"""Human player presses the Challenge button."""
	var p := _players[_cur_player]
	if !p or (p._state & Player.State.SELECT_CHALLENGE == 0):
		return
	p._state = Player.State.IDLE
	# Emit a challenge move (table_rank always known when challenge state is active)
	var challenge_move := Move.new(Move.Action.Challenge, _table_rank)
	challenge_move._score = 100.0
	p.move_chosen.emit(challenge_move)


func _on_round_over_pressed() -> void:
	_message_box.hide()
	_new_round()

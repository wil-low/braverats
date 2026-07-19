class_name Player
extends Node2D

const _DECK_SCENE := preload("res://deck/deck.tscn")
const _MULTI_DECK_SCENE := preload("res://deck/multi_deck.tscn")

signal cards_discarded(count: int, table_rank: Card.Rank, cards: Array[Card])
signal challenge_declared
signal move_chosen(move: Move)

enum AI_Level {
	Disabled = -1,
	Human = 0,
	Level_1,
	Level_2,
	Level_3,
	Level_4,
}

# bitmask
enum State {
	IDLE = 0,
	SELECT_DISCARD = 1,
	SELECT_CHALLENGE = 2,
}

var _state: State = State.IDLE
var memory: Memory
var last_discard_rank: Card.Rank = Card.Rank.Unknown

@export var idx: int = 0
@onready var hand: Node2D = $Hand
@onready var _badge: Sprite2D = $Badge
@onready var current_mark: ColorRect = $Current

var ai_level: AI_Level = AI_Level.Level_1:
	get:
		return ai_level
	set(value):
		ai_level = value
		if ai_level > AI_Level.Human:
			_badge.frame = ai_level - 1
		_badge.visible = ai_level > AI_Level.Human

var score: int = 0

func _ready() -> void:
	Card.b_font = load("res://tres/label_settings.tres")
	Card.w_font = load("res://tres/wlabel_settings.tres")


func add_card(card: Card) -> void:
	if is_human():
		card.input_event.connect(_on_card_input_event.bind(card))
	hand.add_card(card)


func is_human() -> bool:
	return ai_level == AI_Level.Human


func is_empty() -> bool:
	return hand.get_card_count() == 0


func clear_hand() -> void:
	hand.clear()


func set_compact_mode(compact: bool) -> void:
	var old_hand := hand
	remove_child(old_hand)
	old_hand.queue_free()

	if is_human() and compact:
		hand = _MULTI_DECK_SCENE.instantiate()
		hand.position.x += 10
	else:
		hand = _DECK_SCENE.instantiate()
	hand.fan_offset = 6
	add_child(hand)

	# Reconnect card input signals
	for ch in hand.get_children():
		if ch is Card:
			ch.input_event.connect(_on_card_input_event)
		elif ch is MultiCard:
			ch._card.input_event.connect(_on_multicard_input_event.bind(ch))


# ─── Human input handler ────────────────────────────────────────────────────

func _on_card_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, card: Card) -> void:
	if _state & Player.State.SELECT_DISCARD:
		if event.is_action_pressed("left_click"):
			if _is_card_selected(card.get_index()):
				card.set_selected(false)
			elif _deck_selected_count() < 3:
				card.set_selected(true)
	elif _state & Player.State.SELECT_CHALLENGE:
		if event.is_action_pressed("left_click"):
			# For now, just accept challenge click
			pass


func _on_multicard_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, card: MultiCard) -> void:
	if _state & Player.State.SELECT_DISCARD:
		if event.is_action_pressed("left_click"):
			card.set_selected(true)
	elif _state & Player.State.SELECT_CHALLENGE:
		if event.is_action_pressed("left_click"):
			# For now, just accept challenge click
			pass


func _execute_discard() -> void:
	var selected_cards: Array[Card] = hand.get_selected_cards()
	var count := selected_cards.size()
	
	if count == 0:
		return
	
	# Human player always plays for the table rank (shown on screen)
	# The actual rank of the cards doesn't matter — that's the bluff
	var rank := selected_cards[0].rank
	
	# Emit signal with discard info
	cards_discarded.emit(count, rank, selected_cards.duplicate())
	
	# Clean up selection
	hand.clear_selection()
	_state = State.IDLE


# ─── Selection helpers (delegate to hand) ───────────────────────────────────

func _deck_selected_count() -> int:
	return hand.get_selected_count()


func _is_card_selected(index: int) -> bool:
	return hand._is_card_selected(index)


# ─── AI entry point (thin wrapper) ──────────────────────────────────────────

func ai_discard(table_rank: Card.Rank) -> void:
	# Otherwise: select a discard
	var my_move := AI.select_discard(
		memory,
		hand.get_children(),
		ai_level,
		table_rank
	)
	if my_move:
		move_chosen.emit(my_move)


func ai_challenge() -> void:
	var challenge_move := Move.new(Move.Action.Challenge, last_discard_rank)
	challenge_move._score = 100.0
	move_chosen.emit(challenge_move)

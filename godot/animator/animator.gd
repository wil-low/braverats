extends Node

var _speed: float = 2  # set to 0 for speedrun with disabled rendering and console output
var _winner_tween: Tween
var _tween_host: Node = null


func _ready() -> void:
	kill_tweens()


class _WaitAll:
	extends RefCounted
	signal finished
	var _remaining: int
	
	func _init(rem: int) -> void:
		_remaining = rem

	func dec() -> void:
		_remaining -= 1
		if _remaining == 0:
			finished.emit()


func _d(base: float) -> float:
	return base / _speed if _speed > 0 else 0.0


func delay(t: float) -> Signal:
	return get_tree().create_timer(_d(t)).timeout


func _immediate() -> Signal:
	return get_tree().create_timer(0).timeout


func all(signals: Array[Signal]) -> Signal:
	if signals.is_empty():
		return _immediate()
	var waiter = _WaitAll.new(signals.size())
	for s in signals:
		s.connect(func(): waiter.dec(), CONNECT_ONE_SHOT)
	return waiter.finished


func flip(card: Card, to_faceup: bool, duration: float = 0.3) -> Signal:
	if card.face_up != to_faceup:
		var dur = _d(duration)
		var pos = card.position
		var width = card._sprite.get_rect().size.x
		var tw = _tween_host.create_tween().set_trans(Tween.TRANS_SINE)
		tw.tween_property(card, "position:x", pos.x + width / 2, dur)
		tw.parallel().tween_property(card, "scale:x", 0, dur)
		tw.tween_callback(func (): card.face_up = to_faceup)
		tw.tween_property(card, "scale:x", 1, dur)
		tw.parallel().tween_property(card, "position:x", pos.x, dur)
		tw.finished.connect(func (): card.position = pos)
		return tw.finished
	return _immediate()


func reveal_hand(p: Player, hide_afterwards: bool = true) -> Signal:
	if p.hand.get_child_count() > 0:
		for card in p.hand.get_children():
			flip(card, true)
		await delay(1)
		if hide_afterwards:
			for card in p.hand.get_children():
				await flip(card, false)
	return _immediate()


func move_card(card: Card, to_global: Vector2, duration: float = 0.5) -> Signal:
	var tw = _tween_host.create_tween().set_trans(Tween.TRANS_QUAD)
	tw.tween_property(card, "global_position", to_global, _d(duration))
	return tw.finished


func flash(loops: int, nodes: Array[Node]) -> Signal:
	if _speed == 0:
		return _immediate()
	if _winner_tween != null and _winner_tween.is_running():
		_winner_tween.kill()
	if loops > 0 and !nodes.is_empty(): 
		var alpha: float = 0.0
		for i in loops * 2:
			_winner_tween = _tween_host.create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
			for n in nodes:
				_winner_tween.tween_property(n, "modulate:a", alpha, _d(1))
			alpha = 1 - alpha
			await _winner_tween.finished
	return _immediate()


func kill_tweens() -> void:
	"""Free and replace the tween host, killing all active tweens."""
	if _tween_host:
		var old_host = _tween_host
		old_host.queue_free()
	_tween_host = Node.new()
	add_child(_tween_host)

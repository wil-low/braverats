extends Node2D

@onready var _start: Start = $Start
@onready var _main: Main = $Main
@onready var _level_selector: LevelSelector = $LevelSelector
@onready var _stats: Stats = $Stats
@onready var _help: Node2D = $Help
@onready var _pause: Node2D = $Pause

@export var random_seed: int = 0
@export var speed_run: bool = false
@export var print_valid_moves: bool = false

const OPTIONS_FILE := "user://options.cfg"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seed(random_seed if random_seed != 0 else Time.get_ticks_usec())

	var platform := OS.get_name()
	if platform == "Android" or platform == "iOS":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Engine.print_to_stdout = false

	if speed_run:
		for i in AudioServer.bus_count:
			AudioServer.set_bus_mute(i, true)
		Animator._speed = 0
		RenderingServer.render_loop_enabled = false
		Engine.print_to_stdout = false
		_main.round_finished.disconnect(_on_round_finished)
		_main.save_stats.disconnect(save_config)
		_main.init_players(42, false)
	else:
		load_config()


func save_config() -> void:
	var config = ConfigFile.new()
	for i in _main.game_state.ai_levels.size():
		config.set_value("AI_Level", "P" + str(i), _main.game_state.ai_levels[i])
	config.set_value("Gameplay", "speed", _level_selector._speed_level.level)
	config.set_value("Gameplay", "compact", _level_selector._compact)
	config.set_value("Gameplay", "totals_and_wins", _stats._totals_and_wins)
	config.save(OPTIONS_FILE)


func load_config() -> bool:
	var config = ConfigFile.new()
	var err = config.load(OPTIONS_FILE)

	# If the file didn't load, ignore it.
	if err != OK:
		return false

	for i in 2:
		var ai_level = config.get_value("AI_Level", "P" + str(i))
		if ai_level != null:
			_main.game_state.ai_levels[i] = ai_level as GameState.AI_Level

	var speed = clamp(config.get_value("Gameplay", "speed"), SpeedLevel._min_speed, SpeedLevel._max_speed)
	var compact = config.get_value("Gameplay", "compact", false)
	_level_selector.set_levels(_main.game_state.ai_levels, compact, speed)
	_stats._totals_and_wins = config.get_value("Gameplay", "totals_and_wins", [])
	if _stats._totals_and_wins == []:
		_stats._on_reset_button_pressed()
	return true


func _on_level_selector_levels_changed(levels: Array[GameState.AI_Level], compact: bool, speed: int) -> void:
	_main.game_state.ai_levels = levels
	Animator._speed = pow(2, speed)
	save_config()
	_start.show()


func _on_main_menu_pressed() -> void:
	_main.get_tree().paused = true
	_main.hide()
	_pause.show()


func _on_start_play_pressed() -> void:
	_main.show()
	_main.init_players(random_seed if random_seed != 0 else Time.get_ticks_usec(), _level_selector._compact)


func _on_start_settings_pressed() -> void:
	_level_selector.show()
	pass


func _on_pause_resume_pressed() -> void:
	_main.get_tree().paused = false
	_main.show()


func _on_pause_exit_pressed() -> void:
	Animator.kill_tweens()
	_main.get_tree().paused = false
	_start.show()


func _on_start_stats_pressed() -> void:
	_stats.invoker = _start
	_stats.update_labels()
	_stats.show()
	pass


func _on_stats_back_pressed() -> void:
	_stats.invoker.show()
	pass


func _on_pause_stats_pressed() -> void:
	_stats.invoker = _pause
	_stats.update_labels()
	_stats.show()
	pass


func _on_start_help_pressed() -> void:
	_help.invoker = _start
	_help.show()


func _on_help_back_pressed() -> void:
	_help.invoker.show()


func _on_pause_help_pressed() -> void:
	_help.invoker = _pause
	_help.show()


func _on_round_finished(_level: int) -> void:
	_stats._totals_and_wins[2 * _level + 1] = clampi(_stats._totals_and_wins[2 * _level + 1] + 1, 0, 99999)
	pass

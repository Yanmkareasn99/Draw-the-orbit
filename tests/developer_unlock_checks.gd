extends SceneTree

const Game = preload("res://scripts/game.gd")
const Flow = preload("res://tests/screen_flow.gd")
var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func type_code(game: Node, value: String) -> void:
	for character in value:
		var key := InputEventKey.new()
		key.pressed = true
		key.unicode = character.unicode_at(0)
		game._input(key)

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.update_layout(Vector2(320, 568))
	type_code(game, "BONKDEQ")
	check(not game.developer_unlocked and not game.is_level_unlocked(5), "incorrect code does not unlock levels")
	type_code(game, "bonkdev")
	Flow.settle(game)
	check(game.developer_unlocked and game.state == "level_select", "case-insensitive secret opens unlocked selection")
	check(game.is_level_unlocked(10000) and not game.is_level_unlocked(0), "all positive levels unlock, invalid levels stay rejected")
	check(game.level_page_count() == 1 and game.level_buttons.size() == game.MAX_AVAILABLE_LEVEL, "developer map stops at currently available content")
	game.change_screen("intro", 10)
	Flow.skip_intro(game)
	check(game.level == 10 and game.boss_alive(), "developer can launch a locked boss level")
	game.level = 1
	game.unlock_next_level()
	game.register_bonk()
	check(game.highest_unlocked_level == 1 and game.highest_bonks == 0, "developer testing preserves progression and score records")
	game.state = "level_select"
	type_code(game, "BONKDEV")
	check(not game.developer_unlocked and not game.is_level_unlocked(10), "same code restores normal locks")
	game.state = "playing"
	type_code(game, "BONKDEV")
	check(not game.developer_unlocked, "typing during gameplay cannot activate developer mode")
	game.free()
	print("Developer unlock checks: 8; failures: ", failures)
	quit(failures)

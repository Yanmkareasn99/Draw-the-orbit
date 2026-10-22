extends SceneTree

const Game = preload("res://scripts/game.gd")
const Flow = preload("res://tests/screen_flow.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.highest_unlocked_level = 7
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "menu" and game.transition_phase == "close", "outgoing title stays visible while iris closes")
	game.handle_primary_press(game.start_button.get_center())
	game.advance_presentation(game.TRANSITION_TIME)
	check(game.state == "play_menu" and game.transition_phase == "reveal" and game.transition_clock == 0, "screen switches to play options at full black and begins reveal")
	game._physics_process(5.0)
	check(game.elapsed == 0 and game.hazards.is_empty(), "reveal never consumes level time or spawns enemies")
	Flow.settle(game)
	for number in range(1, 8):
		game.change_screen("intro", number)
		Flow.settle(game)
		var expected: String = ["saucer", "scout", "weaver", "brute", "brute", "dodger", "phantom"][number - 1]
		check(game.current_level() == number and game.intro_kind() == expected, "correct introduction for level %d" % number)
		check(game.introduced_ufo_kind().is_empty() == game.is_boss_level(), "boss level is separate from UFO introductions")
		game.advance_presentation(60.25)
		game._physics_process(100.0)
		check(game.state == "intro" and game.elapsed == 0 and game.health == 5 and game.hazards.is_empty(), "demo loops without gameplay consequences")
		for size in [Vector2(320, 568), Vector2(390, 844), Vector2(430, 932)]:
			game.update_layout(size)
			check(Rect2(Vector2.ZERO, size).encloses(game.skip_button), "Skip stays on screen")
		game.handle_touch_press(game.skip_button.get_center(), 0)
		check(game.transition_target == "playing" and game.transition_phase == "close", "Skip starts transition into gameplay")
		Flow.settle(game)
		var expected_time := "BOSS" if game.is_boss_level() else "01:30"
		check(game.state == "playing" and game.level_time() == expected_time and not game.drawing, "Skip begins a fresh level with no stray drawing")
	game.free()
	print("Intro checks: ", checks, "; failures: ", failures)
	quit(failures)

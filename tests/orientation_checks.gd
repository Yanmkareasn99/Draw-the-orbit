extends SceneTree

const Game = preload("res://scripts/game.gd")
const Flow = preload("res://tests/screen_flow.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ", label)
	else:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.start_button.get_center())
	Flow.skip_intro(game)
	check(game.state == "playing", "portrait touch starts play")
	game.elapsed = 42.0
	game.bonks = 6
	game.begin_sketch(Vector2(250, 150))
	game.append_sketch_point(Vector2(250, 300))
	game.update_layout(Vector2(844, 300))
	check(game.state == "paused" and game.orientation_blocked and not game.drawing, "landscape blocks play and cancels unfinished stroke")
	check(game.elapsed == 42.0 and game.bonks == 6, "rotation preserves progress")
	game._physics_process(10.0)
	game.handle_primary_press(game.start_button.get_center())
	check(game.elapsed == 42.0 and game.state == "paused" and game.transition_phase.is_empty(), "landscape blocks input and time advancement")
	game.change_screen("playing")
	game.advance_presentation(10.0)
	check(game.transition_clock == 0.0, "landscape also freezes transition clock")
	game.transition_phase = ""
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(430, 932), Vector2(600, 960)]:
		game.update_layout(size)
		check(not game.orientation_blocked, "portrait unblocks controls")
		check(game.screen_arena.size == Vector2(size.x, size.y - game.TOOLBAR_HEIGHT), "arena fills available space %s" % size)
		check(game.world_transform.x.length() == game.world_transform.y.length(), "uniform arena scale %s" % size)
		game.handle_primary_press(game.start_button.get_center())
		Flow.settle(game)
		check(game.state == "playing", "explicit Resume continues after rotation %s" % size)
		game.handle_primary_press(game.pause_button.get_center())
		Flow.settle(game)
	game.free()
	print("Orientation checks: ", checks, "; failures: ", failures)
	quit(failures)

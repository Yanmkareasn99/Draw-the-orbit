extends SceneTree

const Game = preload("res://scripts/game.gd")
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
	game.score_save_path = ""
	game.mobile_landscape_only = true
	game.update_layout(Vector2(390, 844))
	check(game.orientation_blocked and game.state == "menu", "mobile portrait blocks the title screen")
	game.handle_primary_press(game.start_button.get_center())
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	game._input(enter)
	check(game.state == "menu", "touch and keyboard cannot start in portrait")
	game.update_layout(Vector2(844, 390))
	game.handle_primary_press(game.start_button.get_center())
	check(not game.orientation_blocked and game.state == "playing", "landscape allows play")
	game.elapsed = 42.0
	game.score = 600
	game.begin_sketch(Vector2(250, 150))
	game.append_sketch_point(Vector2(250, 300))
	game.update_layout(Vector2(390, 844))
	check(game.orientation_blocked and game.state == "paused" and not game.drawing, "turning upright pauses and cancels the active stroke")
	game._physics_process(2.0)
	check(game.elapsed == 42.0 and game.score == 600 and game.hazards.is_empty(), "portrait freezes gameplay and preserves progress")
	enter.keycode = KEY_R
	game._input(enter)
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "paused" and game.elapsed == 42.0, "portrait cannot resume or restart")
	game.update_layout(Vector2(844, 390))
	check(game.state == "paused" and not game.orientation_blocked, "returning to landscape waits for Resume")
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "playing" and game.score == 600, "landscape resumes the preserved run")
	game.update_layout(Vector2(600, 600))
	check(game.orientation_blocked, "square mobile view also requires landscape")
	game.mobile_landscape_only = false
	game.update_layout(Vector2(390, 844))
	check(not game.orientation_blocked, "desktop portrait windows remain usable")
	game.free()
	print("Orientation checks: ", checks, "; failures: ", failures)
	quit(failures)

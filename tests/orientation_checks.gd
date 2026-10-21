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
	game.bonk_save_path = ""
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "playing", "portrait touch starts play")
	game.elapsed = 42.0
	game.bonks = 6
	game.begin_sketch(Vector2(250, 150))
	game.append_sketch_point(Vector2(250, 300))
	game.update_layout(Vector2(844, 300))
	check(game.state == "playing" and not game.drawing, "rotation cancels only unfinished stroke")
	check(game.elapsed == 42.0 and game.bonks == 6, "rotation preserves progress")
	for size in [Vector2(844, 300), Vector2(844, 390), Vector2(390, 844), Vector2(600, 600)]:
		game.update_layout(size)
		check(game.screen_arena.size == Vector2(size.x, size.y - game.TOOLBAR_HEIGHT), "arena fills available space %s" % size)
		check(game.world_transform.x.length() == game.world_transform.y.length(), "uniform arena scale %s" % size)
		game.handle_primary_press(game.pause_button.get_center())
		check(game.state == "paused", "pause works in either orientation %s" % size)
		game.handle_primary_press(game.start_button.get_center())
		check(game.state == "playing", "resume works in either orientation %s" % size)
	game.free()
	print("Orientation checks: ", checks, "; failures: ", failures)
	quit(failures)

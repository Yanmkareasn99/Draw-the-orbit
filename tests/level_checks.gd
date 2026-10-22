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
	game.highest_unlocked_level = 3
	game.start_round(3)
	game.bonks = 12
	game.highest_bonks = 20
	game.hits = 29
	game.elapsed = 89.99
	game.spawn_clock = 0.0
	game.drawing = true
	game.sketch = PackedVector2Array([Vector2(150, 150), Vector2(200, 150)])
	game._physics_process(0.1)
	check(game.state == "complete" and game.elapsed == 90.0 and game.level_time() == "00:00", "completion clamps simulation to ninety seconds")
	check(game.bonks == 12 and game.highest_bonks == 20 and game.hits == 29, "results preserve separate bonk, record and destruction counts")
	check(not game.drawing and game.sketch.is_empty() and game.hazards.is_empty(), "completion cancels draft and prevents a new wave")
	game._physics_process(10.0)
	check(game.elapsed == 90.0 and game.state == "complete", "completion waits indefinitely for an action")
	Flow.settle(game)
	for size in [Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(430, 932)]:
		game.update_layout(size)
		var screen := Rect2(Vector2.ZERO, size)
		check(screen.encloses(game.overlay_card), "completion card fits %s" % size)
		for button in [game.start_button, game.next_level_button, game.title_button]:
			check(game.overlay_card.encloses(button) and button.size.y >= 44, "touch action fits card %s" % size)
		check(not game.start_button.intersects(game.next_level_button) and not game.next_level_button.intersects(game.title_button), "completion actions do not overlap %s" % size)
	game.handle_touch_press(game.start_button.get_center(), 0)
	Flow.skip_intro(game)
	check(game.state == "playing" and game.current_level() == 3 and game.elapsed == 0 and game.bonks == 0 and game.hits == 0 and game.health == 5 and game.highest_bonks == 20, "Play Again resets this level and preserves record")
	game.elapsed = 89.99
	game._physics_process(0.02)
	Flow.settle(game)
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.next_level_button.get_center())
	Flow.skip_intro(game)
	check(game.current_level() == 4 and game.unlocked_ufo_types().has("brute") and game.elapsed == 0 and game.state == "playing", "Next Level advances once and unlocks Brutes")
	game.state = "paused"
	game._physics_process(100.0)
	check(game.elapsed == 0.0, "pause freezes level timer")
	game.state = "playing"
	game.health = 1
	game.elapsed = 89.99
	var fatal := game.make_ufo("saucer", game.CENTER, 0)
	fatal.warmup = 0
	game.hazards.append(fatal)
	game._physics_process(0.02)
	check(game.state == "lost", "fatal damage on the final step takes precedence over completion")
	game.start_round(4)
	game.elapsed = 89.99
	game._physics_process(0.02)
	Flow.settle(game)
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.title_button.get_center())
	Flow.settle(game)
	check(game.state == "menu" and game.hazards.is_empty() and game.highest_bonks == 20, "Return to Title clears the level and retains the record")
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.start_button.get_center())
	Flow.skip_intro(game)
	check(game.state == "playing" and game.current_level() == 1, "title Play begins level one")
	game.free()
	print("Level checks: ", checks, "; failures: ", failures)
	quit(failures)

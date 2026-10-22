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
	var path := "res://artifacts/level_progress_test_%d.cfg" % OS.get_process_id()
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = path
	game.load_level_progress()
	check(game.highest_unlocked_level == 1, "new player only has level one unlocked")
	game.update_layout(Vector2(320, 568))
	game.handle_primary_press(game.start_button.get_center())
	Flow.settle(game)
	check(game.state == "play_menu", "title Play opens the three choices")
	game.handle_primary_press(game.select_level_button.get_center())
	Flow.settle(game)
	check(game.state == "level_select", "Select Level opens level cards")
	game.handle_primary_press(game.level_buttons[2].get_center())
	check(game.transition_phase.is_empty() and game.state == "level_select", "locked level ignores clicks")
	game.change_screen("intro", 5)
	check(game.transition_phase.is_empty(), "locked level cannot bypass navigation gate")
	game.handle_primary_press(game.level_buttons[1].get_center())
	Flow.skip_intro(game)
	check(game.state == "playing" and game.level == 1, "unlocked level starts through introduction")
	game.elapsed = 89.99
	game._physics_process(0.02)
	check(game.highest_unlocked_level == 2 and game.state == "complete" and game.transition_phase.is_empty(), "win unlocks exactly the next level without automatic transition")
	var reopened := Game.new()
	reopened.progress_save_path = path
	reopened.load_level_progress()
	check(reopened.highest_unlocked_level == 2, "unlocked level persists across game instances")
	game.change_screen("play_menu")
	Flow.settle(game)
	game.handle_primary_press(game.continue_button.get_center())
	Flow.skip_intro(game)
	check(game.level == 2 and game.state == "playing", "Continue starts highest unlocked level")
	game.health = 1
	var enemy := game.make_ufo("saucer", game.CENTER, 0)
	enemy.warmup = 0
	game.hazards.append(enemy)
	game._physics_process(0.01)
	check(game.state == "lost" and game.highest_unlocked_level == 2, "loss does not unlock next level")
	game.change_screen("play_menu")
	Flow.settle(game)
	game.handle_primary_press(game.beginning_button.get_center())
	Flow.skip_intro(game)
	check(game.level == 1 and game.highest_unlocked_level == 2, "From Beginning replays level one without deleting unlocks")
	game.elapsed = 89.99
	game._physics_process(0.02)
	check(game.highest_unlocked_level == 2, "replaying cleared level cannot unlock another level")
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(430, 932)]:
		game.state = "play_menu"
		game.update_layout(size)
		var screen := Rect2(Vector2.ZERO, size)
		check(screen.encloses(game.beginning_button) and screen.encloses(game.continue_button) and screen.encloses(game.select_level_button) and not game.select_level_button.intersects(game.back_button), "play menu fits %s" % size)
		game.state = "level_select"
		game.update_layout(size)
		for rect: Rect2 in game.level_buttons.values():
			check(screen.encloses(rect) and not rect.intersects(game.back_button), "level tile fits %s" % size)
	game.highest_unlocked_level = 7
	game.level_page = 0
	game.update_layout(Vector2(320, 568))
	game.handle_primary_press(game.next_page_button.get_center())
	game.update_layout(Vector2(320, 568))
	check(game.level_page == 1 and game.level_buttons.has(7), "pagination reaches levels beyond the initial six")
	var bad := ConfigFile.new()
	bad.set_value("levels", "highest_unlocked", -3)
	bad.save(path)
	reopened.highest_unlocked_level = 1
	reopened.load_level_progress()
	check(reopened.highest_unlocked_level == 1, "invalid save cannot unlock levels")
	DirAccess.remove_absolute(path)
	reopened.free()
	game.free()
	print("Progress checks: ", checks, "; failures: ", failures)
	quit(failures)

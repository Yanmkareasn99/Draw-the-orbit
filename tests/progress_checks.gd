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
		game.level_map_scroll = 0.0
		game.update_layout(size)
		for number in game.level_buttons:
			var rect: Rect2 = game.level_buttons[number]
			if game.level_map_view.encloses(rect):
				check(screen.encloses(rect) and not rect.intersects(game.back_button), "visible level tile fits %s" % size)
		check(game.level_checkpoints[1].y > game.level_checkpoints[2].y, "mission map climbs from the first level upward: %s" % size)
		check(game.ufo_kind_for_level(1) == "saucer" and game.ufo_kind_for_level(6) == "dodger", "map checkpoints feature each level's introduced UFO")
	game.highest_unlocked_level = 7
	game.update_layout(Vector2(320, 568))
	var initial_scroll := game.level_map_scroll
	game.set_level_map_scroll(game.level_map_max_scroll())
	check(game.level_map_scroll > initial_scroll and game.level_map_view.has_point(game.upcoming_checkpoint), "scrolling reaches the final Upcoming marker after level eight")
	check(game.level_buttons.size() == game.MAX_AVAILABLE_LEVEL and game.ufo_kind_for_level(100) == "specter", "map stops at available levels without cycling UFO types")
	game.set_level_map_scroll(0.0)
	game.handle_touch_press(game.level_map_view.get_center(), 2)
	var map_drag := InputEventScreenDrag.new()
	map_drag.index = 2
	map_drag.position = game.level_map_view.get_center() + Vector2(0, 90)
	map_drag.relative = Vector2(0, 90)
	game._input(map_drag)
	game.handle_touch_release(map_drag.position, 2)
	check(game.level_map_scroll > 0.0 and game.state == "level_select", "dragging scrolls the map without opening a checkpoint")
	game.developer_unlocked = false
	game.highest_unlocked_level = game.MAX_AVAILABLE_LEVEL
	game.level = game.MAX_AVAILABLE_LEVEL
	game.unlock_next_level()
	check(game.highest_unlocked_level == game.MAX_AVAILABLE_LEVEL, "campaign progression stops at the last available UFO level")
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

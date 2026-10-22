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
	game.highest_bonks = 15
	game.start_round(7)
	game.state = "paused"
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(430, 932)]:
		game.update_layout(size)
		check(Rect2(Vector2.ZERO, size).encloses(game.overlay_card), "pause card fits viewport")
		var buttons := [game.start_button, game.restart_button, game.select_level_button, game.title_button]
		for i in range(buttons.size()):
			check(game.overlay_card.encloses(buttons[i]) and buttons[i].size.y >= 44, "pause action fits card with touch target")
			for j in range(i + 1, buttons.size()):
				check(not buttons[i].intersects(buttons[j]), "pause actions do not overlap")
	game.elapsed = 42
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "playing" and game.elapsed == 42 and game.transition_phase.is_empty(), "Resume is immediate and preserves attempt")
	game.handle_primary_press(game.pause_button.get_center())
	check(game.state == "paused" and game.transition_phase.is_empty(), "pause card appears without a transition")
	game.space_bombs = 1
	game.handle_primary_press(game.bomb_button.get_center())
	check(game.state == "paused" and game.space_bombs == 1 and game.bomb_flash == 0.0, "paused HUD is visible but cannot use its bomb control")
	game.handle_primary_press(game.pause_button.get_center())
	check(game.state == "paused", "paused HUD pause control cannot dismiss the card")
	game.state = "paused"
	game.update_layout(Vector2(320, 568))
	game.handle_touch_press(game.select_level_button.get_center(), 0)
	Flow.settle(game)
	check(game.state == "level_select" and game.level_page == 1 and game.level_buttons.has(7), "Level Select opens page containing paused level")
	check(game.elapsed == 0 and game.highest_unlocked_level == 7 and game.highest_bonks == 15, "leaving clears attempt but preserves progress and record")
	game.start_round(7)
	game.state = "paused"
	game.update_layout(Vector2(320, 568))
	game.handle_primary_press(game.title_button.get_center())
	Flow.settle(game)
	check(game.state == "menu" and game.highest_unlocked_level == 7, "Return to Title keeps unlocked levels")
	game.free()
	print("Pause menu checks: ", checks, "; failures: ", failures)
	quit(failures)

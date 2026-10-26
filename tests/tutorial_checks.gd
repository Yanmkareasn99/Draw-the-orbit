extends SceneTree

const Game = preload("res://scripts/game.gd")
const Flow = preload("res://tests/screen_flow.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.settings_save_path = ""
	game.update_layout(Vector2(390, 844))
	game.state = "play_menu"
	game.update_layout(Vector2(390, 844))

	game.handle_primary_press(game.beginning_button.get_center())
	Flow.settle(game)
	check(game.state == "playing" and game.tutorial_active, "From Beginning opens the interactive tutorial")
	check(game.level == 1 and game.tutorial_stage == 0, "tutorial starts on its detailed explanation card")

	game._physics_process(10.0)
	check(is_zero_approx(game.elapsed) and game.hazards.is_empty(), "tutorial freezes the timer and UFO spawning")
	game.handle_primary_press(game.tutorial_button.get_center())
	check(game.tutorial_stage == 1, "practice button opens the hands-on drawing step")

	game.sketch = PackedVector2Array([Vector2(250, 180), Vector2(250, 380)])
	game.drawing = true
	game.finish_sketch()
	check(game.barriers.size() == 1 and game.tutorial_stage == 2, "a valid practice barrier launches the rebound lesson")
	check(game.hazards.size() == 1, "the rebound lesson creates a real incoming UFO")
	for i in range(100):
		if game.tutorial_stage != 2:
			break
		game._physics_process(0.05)
	check(game.tutorial_stage == 3, "the real barrier collision advances the rebound and stun lesson")
	check(game.hazards.size() == 2 and game.hazards[0].redirected and game.hazards[0].recovery > 0.0,
		"the BONK lesson uses a genuinely stunned UFO and a target")

	for i in range(100):
		if game.tutorial_stage != 3:
			break
		game._physics_process(0.05)
	check(game.tutorial_stage == 4 and game.bonks == 1, "a real UFO collision teaches and records a BONK")
	check(game.space_bombs == 1 and game.hazards.size() == 3, "the fifth BONK charges a bomb and creates real blast targets")
	game.handle_primary_press(game.bomb_button.get_center())
	check(game.tutorial_stage == 5 and game.space_bombs == 0 and game.hits >= 5,
		"tapping the actual bomb control destroys the training targets")

	for i in range(100):
		if game.tutorial_stage != 5:
			break
		game._physics_process(0.05)
	check(game.tutorial_stage == 6 and game.health == game.MAX_HEALTH - 1,
		"a real UFO impact removes one planet health")
	check(not game.health_pickup.is_empty(), "planet damage creates a real health pickup lesson")
	game.handle_primary_press(game.world_transform * Vector2(game.health_pickup.pos))
	check(game.tutorial_stage == 7 and game.health == game.MAX_HEALTH,
		"tapping the real health pickup restores the planet")
	check(is_zero_approx(game.elapsed), "the level timer remains frozen throughout interactive training")

	game.handle_primary_press(game.tutorial_button.get_center())
	Flow.settle(game)
	check(game.state == "intro" and not game.tutorial_active, "Start Level 1 advances to the normal level briefing")
	game.handle_primary_press(game.skip_button.get_center())
	Flow.settle(game)
	game.advance_presentation(game.PLANET_SPIN_TIME)
	check(game.state == "playing" and is_zero_approx(game.elapsed), "level 1 starts fresh after the tutorial")
	check(game.barriers.is_empty(), "the practice barrier is cleared before the real level")

	game.free()
	print("Tutorial checks: ", checks, "; failures: ", failures)
	quit(failures)

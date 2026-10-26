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

	check(game.hazards.size() == 2, "both ships are visible before the player draws")
	var incoming: Dictionary = game.hazards[0]
	var target: Dictionary = game.hazards[1]
	var guide: PackedVector2Array = game.tutorial_guide_points()
	game.handle_touch_press(game.world_transform * guide[0], 0)
	game.append_sketch_point(guide[1])
	game.handle_touch_release(game.world_transform * guide[1], 0)
	check(game.barriers.size() == 1 and game.tutorial_stage == 2, "a valid practice barrier launches the rebound lesson")
	check(game.hazards.size() == 2 and game.hazards[0] == incoming and game.hazards[1] == target, "drawing keeps the ships already on screen")
	game.handle_primary_press(game.pause_button.get_center())
	check(game.state == "paused", "tutorial pause button works")
	var before_pause: Vector2 = incoming.pos
	var delay_before: float = game.tutorial_stage_delay
	game._physics_process(1.0)
	check(incoming.pos == before_pause and game.tutorial_stage_delay == delay_before, "pause freezes the tutorial and its delay")
	game.handle_primary_press(game.start_button.get_center())
	check(game.state == "playing", "tutorial Resume button works")
	for i in range(100):
		if game.tutorial_stage != 2:
			break
		game._physics_process(0.05)
	check(game.tutorial_stage == 3, "the real barrier collision advances the rebound and stun lesson")
	check(game.hazards.size() == 2 and game.hazards[0].redirected and game.hazards[0].recovery > 0.0,
		"the BONK lesson uses a genuinely stunned UFO and a target")
	check(game.hazards[0] == incoming and game.hazards[1] == target and game.barriers.size() == 1,
		"rebound continues into BONK without replacing the ships or barrier")

	for i in range(100):
		if game.tutorial_stage != 3:
			break
		game._physics_process(0.05)
	check(game.tutorial_stage == 4 and game.bonks == 1, "a real UFO collision teaches and records a BONK")
	check(game.highest_bonks == 0, "practice BONKs never change the real high score")
	check(game.space_bombs == 1 and game.hazards.size() == 3, "bomb lesson grants a practice charge for the next wave")
	check(game.hazards[0].warmup > 0.0, "the next wave announces its arrival with normal spawn warnings")
	for i in range(80):
		game._physics_process(0.05)
	check(game.popups.is_empty() and game.sparks.is_empty() and game.shockwaves.is_empty(), "BONK text and collision effects expire during training")
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
	game._physics_process(1.0)
	check(is_zero_approx(game.bomb_flash) and is_zero_approx(game.flash), "bomb and damage flashes clear during training")
	game.handle_primary_press(game.world_transform * Vector2(game.health_pickup.pos))
	check(game.tutorial_stage == 7 and game.health == game.MAX_HEALTH,
		"tapping the real health pickup restores the planet")
	check(game.tutorial_stage_delay > 0.0 and game.tutorial_button.size == Vector2.ZERO,
		"healed health remains visible before the completion card")
	check(game.popups.any(func(p): return p.text == "+1 HP"), "health gain displays +1 HP feedback")
	game._physics_process(0.5)
	check(game.tutorial_stage_delay > 0.0 and game.health == game.MAX_HEALTH, "health feedback is not dismissed immediately")
	game._physics_process(1.2)
	check(game.tutorial_stage_delay == 0.0 and game.tutorial_button.size.y > 0.0, "completion card appears after health feedback")
	check(is_zero_approx(game.elapsed), "the level timer remains frozen throughout interactive training")

	game.handle_primary_press(game.tutorial_button.get_center())
	Flow.settle(game)
	check(game.state == "intro" and not game.tutorial_active, "Start Level 1 advances to the normal level briefing")
	game.handle_primary_press(game.skip_button.get_center())
	Flow.settle(game)
	game.advance_presentation(game.PLANET_SPIN_TIME)
	check(game.state == "playing" and is_zero_approx(game.elapsed), "level 1 starts fresh after the tutorial")
	check(game.barriers.is_empty(), "the practice barrier is cleared before the real level")
	for size in [Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(430, 932), Vector2(600, 960), Vector2(768, 1024)]:
		game.update_layout(size)
		game.start_tutorial()
		game.handle_primary_press(game.tutorial_button.get_center())
		guide = game.tutorial_guide_points()
		game.handle_touch_press(game.world_transform * guide[0], 0)
		game.handle_touch_release(game.world_transform * guide[1], 0)
		for i in range(160):
			if game.tutorial_stage == 4:
				break
			game._physics_process(0.05)
		check(game.tutorial_stage == 4 and game.bonks == 1, "guided touch stroke reaches a real BONK at %s" % size)
		game.use_space_bomb()
		check(game.tutorial_stage == 4 and game.space_bombs == 1, "early bomb tap preserves the practice charge at %s" % size)
		for i in range(100):
			game._physics_process(0.05)
		game.use_space_bomb()
		for i in range(160):
			if game.tutorial_stage == 6:
				break
			game._physics_process(0.05)
		check(game.tutorial_stage == 6, "incoming wave reaches the health lesson at %s" % size)
		game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		game._physics_process(1.0)
		game.handle_primary_press(game.start_button.get_center())
		check(game.state == "playing" and game.tutorial_stage == 6, "focus-loss pause resumes the same lesson at %s" % size)
		game.handle_primary_press(game.world_transform * Vector2(game.health_pickup.pos))
		check(game.health == game.MAX_HEALTH and game.tutorial_stage_delay > 0.0, "health recovery stays visible at %s" % size)
	game.start_tutorial()
	game.handle_primary_press(game.tutorial_button.get_center())
	game.begin_sketch(game.screen_to_world(Vector2(50, 180)))
	game.append_sketch_point(game.screen_to_world(Vector2(50, 240)))
	game.finish_sketch()
	for i in range(160):
		game._physics_process(0.05)
	check(game.tutorial_stage == 1 and game.barriers.is_empty() and game.health == game.MAX_HEALTH, "missed practice stroke recovers to drawing without losing health")
	game.handle_primary_press(game.pause_button.get_center())
	game.handle_primary_press(game.restart_button.get_center())
	Flow.settle(game)
	check(game.tutorial_active and game.tutorial_stage == 0, "Restart restarts training instead of skipping to level 1")

	game.free()
	print("Tutorial checks: ", checks, "; failures: ", failures)
	quit(failures)

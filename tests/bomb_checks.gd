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

func add_ufo(game: Node, at: Vector2, redirected: bool = false) -> void:
	var ufo: Dictionary = game.make_ufo("saucer", at, 40.0)
	ufo.warmup = 0.0
	ufo.vel = Vector2.ZERO
	ufo.redirected = redirected
	ufo.recovery = game.UFO_RECOVERY_TIME if redirected else 0.0
	game.hazards.append(ufo)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	game.score_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.start_round()
	for i in range(5):
		add_ufo(game, Vector2(180, 180), true)
		add_ufo(game, Vector2(188, 180))
		game.step_world(0.01)
	check(game.hits == 10 and game.space_bombs == 1 and game.score == 1000, "ten collision kills award one space bomb")
	check(game.bomb_progress_text() == "x1", "ready bomb shows its stored charge")
	add_ufo(game, game.CENTER + Vector2(180, 0))
	add_ufo(game, game.CENTER + Vector2(game.BOMB_RADIUS + 40, 0))
	game.handle_primary_press(game.bomb_button.get_center())
	check(game.bomb_flash > 0.0, "ready space bomb activates from its HUD button")
	check(game.hazards.size() == 1 and game.hazards[0].pos.distance_to(game.CENTER) > game.BOMB_RADIUS, "space bomb destroys only UFOs in its area")
	check(game.space_bombs == 0 and game.hits == 11 and game.score == 1100, "blast consumes one charge and rewards its UFO destruction")
	check(not game.use_space_bomb() and game.space_bombs == 0, "unearned bomb cannot be used")
	game.register_ufo_destructions(19)
	check(game.space_bombs == 2 and game.hits == 30, "crossing later ten-kill milestones stacks bomb charges")
	game.start_round()
	check(game.hits == 0 and game.space_bombs == 0 and game.bomb_flash == 0.0, "restart clears bomb progress and effects")
	game.free()
	print("Bomb checks: ", checks, "; failures: ", failures)
	quit(failures)

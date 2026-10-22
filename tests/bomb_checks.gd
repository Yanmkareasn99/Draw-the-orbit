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

func bonk(game: Node) -> void:
	add_ufo(game, Vector2(180, 180), true)
	add_ufo(game, Vector2(188, 180))
	game.step_world(0.01)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.start_round()
	for i in range(5):
		bonk(game)
	check(game.hits == 10 and game.bonks == 5 and game.bomb_bonk_progress == 0 and game.space_bombs == 1, "five UFO-to-UFO bonks award one space bomb")
	check(game.popups.any(func(p): return p.text == "BONK!"), "UFO collision shows BONK text")
	check(game.bomb_progress_text() == "x1 0/5", "bomb control shows stored charge and bonk progress")
	add_ufo(game, game.CENTER + Vector2(180, 0))
	add_ufo(game, game.CENTER + Vector2(game.BOMB_RADIUS + 40, 0))
	game.handle_primary_press(game.bomb_button.get_center())
	check(game.bomb_flash > 0.0, "ready space bomb activates from its HUD button")
	check(game.hazards.size() == 1 and game.hazards[0].pos.distance_to(game.CENTER) > game.BOMB_RADIUS, "space bomb destroys only UFOs in its area")
	check(game.space_bombs == 0 and game.bomb_bonk_progress == 0 and game.hits == 11 and game.bonks == 5, "blast kills do not add a bonk")
	check(not game.use_space_bomb() and game.space_bombs == 0, "unearned bomb cannot be used")
	for i in range(10):
		bonk(game)
	check(game.space_bombs == 2 and game.bomb_bonk_progress == 0, "UFO bonks stack at most two bomb charges")
	for i in range(5):
		bonk(game)
	check(game.space_bombs == 2 and game.bomb_bonk_progress == 0, "bonks while two charges are full do not bank a hidden third charge")
	game.use_space_bomb()
	bonk(game)
	check(game.space_bombs == 1 and game.bomb_bonk_progress == 1 and game.bomb_progress_text() == "x1 1/5", "bonk progress starts again after a stored charge is spent")
	game.start_round()
	check(game.hits == 0 and game.bomb_bonk_progress == 0 and game.space_bombs == 0 and game.bomb_flash == 0.0, "restart clears bomb progress and effects")
	game.free()
	print("Bomb checks: ", checks, "; failures: ", failures)
	quit(failures)

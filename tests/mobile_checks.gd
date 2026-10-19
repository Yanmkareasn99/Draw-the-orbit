extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
	else:
		print("PASS: ", label)

func touch(game: Node, point: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	game._input(event)

func drag(game: Node, point: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	event.index = index
	game._input(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(844, 390), Vector2(568, 320), Vector2(768, 1024), Vector2(1024, 768), Vector2(1200, 800)]:
		game.state = "menu"
		game.update_layout(size)
		var screen := Rect2(Vector2.ZERO, size)
		check(screen.encloses(game.start_button) and screen.encloses(game.pause_button), "buttons fit %s" % size)
		touch(game, game.start_button.get_center(), true)
		touch(game, game.start_button.get_center(), false)
		check(game.state == "playing" and not game.drawing, "tap Play starts without a stray stroke %s" % size)
		game.update_layout(size)
		check(screen.encloses(game.screen_arena) and not game.screen_arena.intersects(game.pause_button), "arena fits below controls %s" % size)
		if game.compact_layout:
			check(screen.encloses(game.hud_rect) and not game.screen_arena.intersects(game.hud_rect), "HUD never covers arena %s" % size)
		var a := Vector2(250, 170)
		var b := Vector2(250, 300)
		var screen_a := game.world_transform * a
		var screen_b := game.world_transform * b
		touch(game, screen_a, true)
		drag(game, screen_b)
		touch(game, screen_b, false)
		check(game.barriers.size() == 1 and game.barriers[0].points[0].is_equal_approx(a) and game.barriers[0].points[-1].is_equal_approx(b), "touch maps to visible barrier %s" % size)
		check(is_equal_approx(game.available_ink(), game.BUDGET - 130), "ink cost stays equal across orientations %s" % size)
		touch(game, screen_a, true)
		drag(game, screen_b)
		touch(game, screen_b, false, 0, true)
		check(not game.drawing and game.barriers.size() == 1, "OS touch cancellation does not commit %s" % size)
		touch(game, screen_a, true)
		drag(game, screen_b)
		var mouse := InputEventMouseMotion.new()
		mouse.position = Vector2.ZERO
		game._input(mouse)
		check(game.sketch[-1].is_equal_approx(b), "mouse motion cannot alter finger stroke %s" % size)
		touch(game, screen_b, true, 1)
		touch(game, screen_b, false)
		touch(game, screen_b, false, 1)
		check(not game.drawing and game.barriers.size() == 1, "second finger cancels without consuming ink %s" % size)
		var emulated := InputEventMouseButton.new()
		emulated.device = InputEvent.DEVICE_ID_EMULATION
		emulated.button_index = MOUSE_BUTTON_LEFT
		emulated.pressed = true
		emulated.position = screen_a
		game._input(emulated)
		check(not game.drawing, "emulated mouse cannot duplicate touch %s" % size)
		touch(game, game.pause_button.get_center(), true)
		game.update_layout(size)
		check(game.state == "paused" and screen.encloses(game.restart_button), "pause and restart available by touch %s" % size)
		touch(game, game.start_button.get_center(), true)
		check(game.state == "playing" and game.barriers.size() == 1, "Resume preserves barriers %s" % size)
		touch(game, screen_a, true)
		drag(game, screen_b)
		game.update_layout(Vector2(size.y, size.x))
		check(not game.drawing and game.barriers.size() == 1 and game.barriers[0].points[0].is_equal_approx(a), "rotation cancels draft and preserves world %s" % size)
		game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(game.state == "paused", "backgrounding pauses play %s" % size)
		game.update_layout(size)
		touch(game, game.restart_button.get_center(), true)
		check(game.state == "playing" and game.barriers.is_empty() and game.health == 5, "touch restart resets round %s" % size)
	game.free()
	print("Mobile checks: ", checks, "; failures: ", failures)
	quit(failures)

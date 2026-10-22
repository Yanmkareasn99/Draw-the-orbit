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
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.update_layout(Vector2(844, 390))
	game.start_round()
	check(game.health_pickup_clock >= game.HEALTH_PICKUP_FIRST_MIN and game.health_pickup_clock <= game.HEALTH_PICKUP_FIRST_MAX, "new run schedules its first repair pickup after a delay")
	game.health = 4
	game.health_pickup_clock = 0.0
	game._physics_process(0.01)
	check(not game.health_pickup.is_empty(), "damaged planet receives a repair pickup when its timer is ready")
	var first_position: Vector2 = game.health_pickup.pos
	check(game.ARENA.grow(-game.HEALTH_PICKUP_RADIUS).has_point(first_position) and first_position.distance_to(game.CENTER) > 100.0, "repair pickup chooses a visible random point away from the planet")
	game.handle_primary_press(game.world_transform * first_position)
	check(game.health == 5 and game.health_pickup.is_empty() and not game.drawing, "clicking repair pickup restores one health without starting a barrier")
	check(game.health_pickup_clock >= game.HEALTH_PICKUP_REPEAT_MIN and game.health_pickup_clock <= game.HEALTH_PICKUP_REPEAT_MAX, "collecting schedules the next repair pickup")
	game.health_pickup_clock = 0.0
	game._physics_process(1.0)
	check(game.health_pickup.is_empty(), "repair pickup waits while planet health is full")
	game.health = 3
	game._physics_process(0.01)
	check(not game.health_pickup.is_empty() and not game.health_pickup.pos.is_equal_approx(first_position), "next damaged-state pickup appears at another random point")
	var remaining: float = game.health_pickup.life
	game.state = "paused"
	game._physics_process(1.0)
	check(is_equal_approx(game.health_pickup.life, remaining), "pause freezes repair pickup lifetime")
	game.state = "playing"
	game.health_pickup.life = 0.001
	game._physics_process(0.01)
	check(game.health_pickup.is_empty() and game.health == 3, "uncollected repair pickup expires without healing")
	game.hazards.clear()
	var normal_delay := game.next_spawn_delay()
	for i in range(game.CROWD_SLOWDOWN_AT):
		game.hazards.append({})
	check(is_equal_approx(game.next_spawn_delay(), normal_delay * game.CROWD_SPAWN_MULTIPLIER), "twenty active UFOs slow the next wave schedule")
	game.start_round()
	check(game.health == game.MAX_HEALTH and game.health_pickup.is_empty(), "restart restores health and clears the old pickup")
	game.free()
	print("Health pickup checks: ", checks, "; failures: ", failures)
	quit(failures)

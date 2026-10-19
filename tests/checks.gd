extends SceneTree
const Route = preload("res://scripts/route.gd")
var failures := 0
func check(condition: bool, title: String) -> void:
	if condition:
		print("PASS: ", title)
	else:
		push_error(title)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var square := PackedVector2Array([Vector2(0,0),Vector2(100,0),Vector2(100,100),Vector2(0,100),Vector2(0,0)])
	check(is_equal_approx(Route.length_of(square), 400), "route length")
	check(Route.at_distance(square, 450).is_equal_approx(Vector2(50,0)), "constant-speed wraparound")
	check(Route.nearest(square, Vector2(140,50)).point.is_equal_approx(Vector2(100,50)), "nearest transfer entry")
	check(Route.validate(square, Vector2(50,50), 20, 500) == "", "valid closed loop")
	check(Route.validate(square, Vector2(50,0), 20, 500) != "", "planet crossing rejected")
	check(Route.validate(square, Vector2(50,50), 20, 300) != "", "length budget enforced")
	var bow := PackedVector2Array([Vector2(0,0),Vector2(100,100),Vector2(0,100),Vector2(100,0),Vector2(0,0)])
	check(Route.validate(bow, Vector2(500,500), 20, 500) != "", "self crossing rejected")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_round()
	var before: Vector2 = game.drone
	game.sketch = PackedVector2Array([Vector2(650,300),Vector2(800,300),Vector2(800,500),Vector2(650,500),Vector2(650,302)])
	game.finish_sketch()
	check(game.transferring and game.drone == before, "replacement never teleports drone")
	var old_route: PackedVector2Array = game.route.duplicate()
	game.sketch = PackedVector2Array([Vector2(100,200),Vector2(150,200),Vector2(200,300)])
	game.finish_sketch()
	check(game.route == old_route, "open sketch preserves active route")
	game.start_round()
	game.hazards.append({"pos":game.drone,"vel":Vector2.ZERO,"warmup":0.0,"radius":9.0})
	game.step_world(0.001)
	check(game.hits == 1 and game.score == 100, "drone interception scores")
	game.hazards.append({"pos":game.CENTER,"vel":Vector2.ZERO,"warmup":0.0,"radius":9.0})
	game.step_world(0.001)
	check(game.health == 4, "planet collision damages integrity")
	game.transferring = true
	game.transfer_target = game.drone + Vector2(100,0)
	game.hazards.append({"pos":game.drone,"vel":Vector2.ZERO,"warmup":0.0,"radius":9.0})
	game.step_world(0.001)
	check(game.hits == 1, "transfer disables interception")
	game.start_round()
	game.elapsed = 89.99
	game._physics_process(0.02)
	check(game.state == "won", "90 second victory")
	game.start_round()
	game.health = 1
	game.hazards.append({"pos":game.CENTER,"vel":Vector2.ZERO,"warmup":0.0,"radius":9.0})
	game.step_world(0.001)
	check(game.state == "lost", "zero integrity ends round")
	game.start_round()
	game.state = "paused"
	game._physics_process(1.0)
	check(game.elapsed == 0.0, "pause freezes simulation")
	game.start_round()
	game.rng.seed = 1234
	for i in range(5400):
		if game.state != "playing":
			break
		game._physics_process(1.0 / 60.0)
	print("Simulation ended: ", game.state, " at ", game.elapsed, " seconds")
	game.free()
	print("Failures: ", failures)
	quit(failures)

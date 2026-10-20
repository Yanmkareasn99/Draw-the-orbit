extends SceneTree

const Game = preload("res://scripts/game.gd")
const Motion = preload("res://scripts/barrier_motion.gd")
const GameView = preload("res://scripts/game_view.gd")
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
	game.score_save_path = ""
	game.start_round()
	game.rng.seed = 42
	var view: Node2D = GameView.new(game)
	check(view.barrier_life_color(5.0).is_equal_approx(view.BARRIER_BLUE), "fresh barrier starts blue")
	check(view.barrier_life_color(2.5).is_equal_approx(view.GOLD), "half-life barrier turns yellow")
	check(view.barrier_life_color(0.0).is_equal_approx(view.PEACH), "expiring barrier ends red")
	for stamp in [89.99, 599.99, 3599.99, 86399.99]:
		game.elapsed = stamp
		game.spawn_clock = 0.0
		game.hazards.clear()
		game._physics_process(0.02)
		check(game.state == "playing" and not game.hazards.is_empty(), "waves continue at %s seconds" % stamp)
	check(game.survival_time() == "24:00:00", "survival clock counts past a day without wrapping")
	game.elapsed = 3661.0
	check(game.survival_time() == "1:01:01", "hour format remains readable")
	game.elapsed = 91.0
	check(game.survival_time() == "01:31", "clock reports survived time instead of countdown")
	game.elapsed = 1000000.0
	game.hazards.clear()
	for i in range(100):
		game.spawn_attack()
	var kinds := {}
	var safe_speed := true
	for h in game.hazards:
		kinds[h.type] = true
		safe_speed = safe_speed and h.vel.length() <= game.MAX_BASE_SPEED * 1.55 + 0.001
	check(game.hazards.size() == game.MAX_UFOS and safe_speed, "long-run population and speeds stay bounded")
	check(kinds.size() == 4, "late waves include all four distinct UFO types")
	for entry in [[0.0, 1], [10.0, 2], [25.0, 3], [45.0, 4]]:
		game.start_round()
		game.elapsed = entry[0]
		kinds.clear()
		for i in range(4):
			game.spawn_attack()
		for h in game.hazards:
			kinds[h.type] = true
		check(kinds.size() == entry[1], "enemy roster unlocks at %s seconds" % entry[0])
	game.start_round()
	var scout := game.make_ufo("scout", Vector2(200, 200), 50.0)
	var brute := game.make_ufo("brute", Vector2(200, 200), 50.0)
	check(scout.vel.length() > 50.0 and scout.radius < game.UFO_RADIUS, "scout is faster and smaller")
	check(brute.vel.length() < 50.0 and brute.radius > game.UFO_RADIUS, "brute is slower and larger")
	var weaver := game.make_ufo("weaver", Vector2(200, 200), 50.0)
	weaver.weave_phase = PI / 2
	var straight: Vector2 = weaver.vel
	game.steer_ufo(weaver, 0.1)
	check(absf(straight.angle_to(weaver.vel)) > 0.1 and is_equal_approx(straight.length(), weaver.vel.length()), "weaver bends its approach without changing speed")
	weaver.redirected = true
	weaver.recovery = 10.0
	straight = weaver.vel
	game.steer_ufo(weaver, 0.5)
	check(weaver.vel.is_equal_approx(straight) and is_equal_approx(weaver.recovery, 9.5), "stunned weaver stops weaving for predictable rebounds")
	game.sketch = PackedVector2Array([Vector2(250, 120), Vector2(250, 350)])
	game.finish_sketch()
	var barrier: Dictionary = game.barriers[0]
	var resting: PackedVector2Array = barrier.points.duplicate()
	var ink_before: float = game.available_ink()
	for kind in game.UFO_TYPES:
		var h := game.make_ufo(kind, Vector2(249, 230), 50.0)
		h.vel = Vector2(50, 0)
		game.reflect_hazard(h)
		check(h.vel.x < 0 and h.redirected and is_equal_approx(h.recovery, 10.0), "%s reflects and receives full stun" % kind)
	check(barrier.impacts.size() == 4, "real contacts trigger elastic animation")
	Motion.advance(barrier, 0.07)
	var flexed := Motion.points_for(barrier)
	var furthest := 0.0
	for p in flexed:
		furthest = maxf(furthest, p.x - 250.0)
	check(flexed.size() > 20 and furthest > 5.0 and furthest <= Motion.MAX_DISPLACEMENT, "a two-point stroke visibly bows in the impact direction")
	check(flexed[0] == resting[0] and flexed[-1] == resting[-1], "elastic barrier endpoints remain pinned")
	check(barrier.points == resting and game.available_ink() == ink_before, "animation preserves aiming geometry and ink budget")
	game.state = "paused"
	game._physics_process(0.5)
	check(Motion.points_for(barrier) == flexed, "pause freezes barrier flex")
	Motion.advance(barrier, 0.18)
	var spring_back := false
	for p in Motion.points_for(barrier):
		spring_back = spring_back or p.x < 249.0
	check(spring_back, "barrier springs back past its resting line")
	Motion.advance(barrier, 2.0)
	check(barrier.impacts.is_empty() and Motion.points_for(barrier) == resting, "oscillation settles completely and frees impact data")
	for i in range(40):
		Motion.impact(barrier, 100.0, Vector2.RIGHT, 100.0, 1.0)
	check(barrier.impacts.size() == Motion.MAX_IMPACTS, "repeated impacts use bounded animation storage")
	game.state = "playing"
	game.step_world(5.0)
	check(game.barriers.is_empty() and game.available_ink() == game.BUDGET, "animated barriers still expire and refund ink")
	for redirected in [false, true]:
		game.start_round()
		brute = game.make_ufo("brute", game.CENTER, 50.0)
		brute.warmup = 0.0
		brute.redirected = redirected
		game.hazards.append(brute)
		game.step_world(0.01)
		check(game.health == 3, "brute deals two damage, redirected=%s" % redirected)
	game.start_round()
	game.health = 1
	brute = game.make_ufo("brute", game.CENTER, 50.0)
	brute.warmup = 0.0
	game.hazards.append(brute)
	game.step_world(0.01)
	check(game.state == "lost" and game.health == 0, "endless run still ends at zero health without negative hearts")
	game.start_round()
	check(game.wave == 0 and game.elapsed == 0.0 and game.hazards.is_empty(), "restart clears endless progression")
	# Ten minutes of real simulation with replenished health to exercise many
	# spawn/attack cycles. Ordinary play still loses when health reaches zero.
	game.rng.seed = 5678
	var stable := true
	for i in range(36000):
		game.health = 5
		game._physics_process(1.0 / 60.0)
		stable = stable and game.state == "playing" and game.hazards.size() <= game.MAX_UFOS
	check(stable and game.elapsed > 599.0 and game.wave > 150, "ten-minute simulation continues spawning with bounded population")
	view.free()
	game.free()
	print("Endless checks: ", checks, "; failures: ", failures)
	quit(failures)

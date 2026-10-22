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
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.start_round()
	game.rng.seed = 42
	var view: Node2D = GameView.new(game)
	check(view.barrier_life_color(5.0).is_equal_approx(view.BARRIER_BLUE), "fresh barrier starts blue")
	check(view.barrier_life_color(2.5).is_equal_approx(view.GOLD), "half-life barrier turns yellow")
	check(view.barrier_life_color(0.0).is_equal_approx(view.PEACH), "expiring barrier ends red")
	game.start_round(10000)
	game.hazards.clear()
	for i in range(100):
		game.spawn_attack()
	var kinds := {}
	var safe_speed := true
	for h in game.hazards:
		kinds[h.type] = true
		safe_speed = safe_speed and h.vel.length() <= game.MAX_BASE_SPEED * 1.55 + 0.001
	check(game.hazards.size() == game.MAX_UFOS and safe_speed, "long-run population and speeds stay bounded")
	check(kinds.size() == 6, "late waves include all six distinct UFO types")
	for crowd_case in [[12, 4], [16, 3], [20, 2], [24, 1], [28, 0]]:
		game.start_round(10000)
		for i in range(crowd_case[0]):
			game.hazards.append(game.make_ufo("saucer", game.ARENA.position, 40.0))
		var before := game.hazards.size()
		game.spawn_attack()
		check(game.hazards.size() - before == crowd_case[1], "crowd of %d limits the next wave to %d" % crowd_case)
	for entry in [[1, 1], [2, 2], [3, 3], [4, 4], [5, 4], [6, 5], [7, 6]]:
		game.start_round(entry[0])
		kinds.clear()
		for i in range(4):
			game.spawn_attack()
		for h in game.hazards:
			kinds[h.type] = true
		check(kinds.size() == entry[1], "cumulative enemy roster for level %s" % entry[0])
	game.start_round()
	check(game.current_level() == 1 and game.level_time() == "01:30", "round starts at level one with ninety seconds remaining")
	game.elapsed = 89.99
	check(game.current_level() == 1 and game.level_time() == "00:01", "level one remains active until ninety seconds")
	game._physics_process(0.02)
	check(game.current_level() == 1 and game.state == "complete" and game.elapsed == 90.0, "ninety seconds completes the level without advancing")
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
		h.warmup = 0.0
		h.dodge_available = false
		h.vel = Vector2(50, 0)
		game.reflect_hazard(h)
		check(h.vel.x < 0 and h.redirected and is_equal_approx(h.recovery, 10.0), "%s reflects and receives full stun" % kind)
	check(barrier.impacts.size() == 6, "real contacts trigger elastic animation")
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
		if game.boss_alive():
			game.damage_boss(12)
		if game.state == "complete":
			game.start_round(game.current_level() + 1)
		game.health = 5
		game._physics_process(1.0 / 60.0)
		stable = stable and game.state in ["playing", "complete"] and game.hazards.size() <= game.MAX_UFOS
	check(stable and game.current_level() >= 7, "ten-minute simulation crosses separate timed and boss levels with bounded population")
	view.free()
	game.free()
	print("Endless checks: ", checks, "; failures: ", failures)
	quit(failures)

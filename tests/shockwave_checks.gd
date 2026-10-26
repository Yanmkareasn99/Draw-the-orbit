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

func inert_ufo(game: Node, pos: Vector2, bounced: bool = false) -> Dictionary:
	var h: Dictionary = game.make_ufo("saucer", pos, 40.0)
	h.warmup = 0.0
	h.vel = Vector2.ZERO
	h.redirected = bounced
	h.recovery = game.UFO_RECOVERY_TIME if bounced else 0.0
	return h

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
	check(is_equal_approx(game.REBOUND_SPEED_MULTIPLIER, 3.0), "rebound multiplier is 3.0")
	check(is_equal_approx(game.SHOCKWAVE_RADIUS, 110.0), "shockwave radius is 110")
	check(is_equal_approx(game.SHOCKWAVE_PUSH_SPEED, 85.0), "shockwave peak push is 85")
	check(is_equal_approx(game.SHOCKWAVE_STUN_TIME, 2.0), "shockwave stun is two seconds")

	game.sketch = PackedVector2Array([Vector2(250, 120), Vector2(250, 350)])
	game.finish_sketch()
	var h := game.make_ufo("saucer", Vector2(245, 200), 40.0)
	h.warmup = 0.0
	h.vel = Vector2(40, 0)
	game.reflect_hazard(h)
	check(h.redirected and h.vel.is_equal_approx(Vector2(-120, 0)), "first rebound triples cruise speed")
	h.pos = Vector2(257, 200)
	h.vel = Vector2(-120, 0)
	game.reflect_hazard(h)
	check(h.vel.is_equal_approx(Vector2(120, 0)), "second rebound cannot stack another 3.0 boost")
	check(is_equal_approx(h.recovery, game.UFO_RECOVERY_TIME), "barrier rebound retains full ten-second stun")

	game.start_round()
	var center := Vector2(180, 180)
	var at_center := inert_ufo(game, center)
	var near := inert_ufo(game, center + Vector2(20, 0))
	var far := inert_ufo(game, center + Vector2(111, 0))
	var warning := inert_ufo(game, center + Vector2(0, 20))
	warning.warmup = 1.2
	game.hazards.append_array([at_center, near, far, warning])
	game.emit_shockwave(center)
	check(is_equal_approx(at_center.vel.length(), 85.0), "shockwave peak outward velocity push is 85")
	check(near.redirected and near.vel.x > 0.0 and near.vel.length() < 85.0, "nearby UFO receives radial push with falloff")
	check(not far.redirected and far.vel.is_zero_approx(), "outside-radius UFO stays untouched")
	check(not warning.redirected and warning.vel.is_zero_approx(), "warming UFO is immune to shockwave")
	check(is_equal_approx(near.recovery, 2.0), "shockwave gives an unredirected UFO two seconds of stun")
	check(game.hazards.size() == 4 and game.bonks == 0, "shockwave alone does not destroy or score")
	for i in range(20):
		game.emit_shockwave(center)
	check(at_center.vel.length() <= game.redirected_speed_limit(at_center) + 0.001, "repeated shockwaves cannot stack speed beyond the rebound limit")
	near.recovery = 7.0
	game.emit_shockwave(center)
	check(is_equal_approx(near.recovery, 7.0), "short shockwave stun does not overwrite longer stun")

	game.start_round()
	# First pair collides; its wave arms an overlapping second pair.
	# That second pair must collide on the next physics step, not explode for free.
	game.hazards.append(inert_ufo(game, Vector2(180, 200), true))
	game.hazards.append(inert_ufo(game, Vector2(188, 200)))
	game.hazards.append(inert_ufo(game, Vector2(250, 200)))
	game.hazards.append(inert_ufo(game, Vector2(258, 200)))
	game.step_world(0.01)
	check(game.bonks == 1 and game.hazards.size() == 2, "initial BONK destroys only its colliding pair")
	check(game.hazards[0].redirected and game.hazards[1].redirected, "BONK wave primes nearby survivors for a chain")
	check(game.shockwaves.size() == 1, "actual BONK produces exactly one visible shockwave")
	game.step_world(0.01)
	check(game.bonks == 2 and game.hits == 4 and game.hazards.is_empty(), "wave-primed UFOs trigger a second physical collision")
	check(game.shockwaves.size() == 2, "chain's second BONK also emits a wave")
	game.step_world(0.01)
	check(game.bonks == 2, "already-destroyed pairs cannot score again")

	game.state = "paused"
	var remaining_life: float = game.shockwaves[0].life
	game._physics_process(0.2)
	check(is_equal_approx(game.shockwaves[0].life, remaining_life), "pausing freezes shockwave visuals")
	game.state = "playing"
	game._physics_process(0.5)
	check(game.shockwaves.is_empty(), "shockwave visuals expire after their lifetime")
	game.emit_shockwave(Vector2(100, 100))
	game.start_round()
	check(game.shockwaves.is_empty(), "restart clears shockwave visuals")
	game.free()
	print("Shockwave checks: ", checks, "; failures: ", failures)
	quit(failures)

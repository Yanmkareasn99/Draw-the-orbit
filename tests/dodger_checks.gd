extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func barrier(game: Node, x: float) -> void:
	game.sketch = PackedVector2Array([Vector2(x, 120), Vector2(x, 320)])
	game.finish_sketch()

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.start_round(5)
	barrier(game, 250)
	var h := game.make_ufo("dodger", Vector2(240, 200), 40)
	h.vel = Vector2(40, 0)
	game.reflect_hazard(h)
	check(h.dodge_available, "spawn warning does not spend dodge")
	h.warmup = 0
	game.reflect_hazard(h)
	check(not h.dodge_available and not h.redirected and h.pos == Vector2(240, 200) and h.vel == Vector2(40, 0), "first contact spends one charge without reflection, displacement, stun or speed boost")
	game.hazards.append(h)
	game.step_world(1.0)
	check(h.pos.x > 275 and not h.redirected and h.phase_barrier.is_empty(), "whole ship passes through first barrier across repeated physics steps")
	h.pos = Vector2(240, 200)
	h.vel = Vector2(40, 0)
	game.reflect_hazard(h)
	check(h.redirected and h.vel.x < 0 and h.recovery == game.UFO_RECOVERY_TIME, "return encounter with the same barrier bounces normally")
	check(not h.dodge_available, "reflection never recharges dodge")
	game.start_round(5)
	barrier(game, 250)
	barrier(game, 350)
	h = game.make_ufo("dodger", Vector2(200, 200), 40)
	h.warmup = 0
	h.vel = Vector2(1000, 0)
	game.hazards.append(h)
	game.step_world(0.1)
	check(h.pos.x > 290 and not h.redirected, "fast dodger clears first barrier without a partial bounce")
	game.step_world(0.05)
	check(h.redirected and h.vel.x < 0, "second distinct barrier reflects the spent dodger")
	var fresh := game.make_ufo("dodger", Vector2(240, 250), 40)
	fresh.warmup = 0
	game.reflect_hazard(fresh)
	check(not fresh.dodge_available and not fresh.redirected, "each new Dodger owns its own single charge")
	game.age_barriers(5.0)
	game.reflect_hazard(fresh)
	check(fresh.phase_barrier.is_empty() and not fresh.dodge_available, "barrier expiry clears passage tracking without restoring the charge")
	game.start_round(5)
	h = game.make_ufo("dodger", game.CENTER, 40)
	h.warmup = 0
	h.vel = Vector2.ZERO
	game.hazards.append(h)
	game.step_world(0.01)
	check(game.health == 4 and game.hazards.is_empty(), "unused dodge does not prevent planet damage")
	game.free()
	print("Dodger checks: ", checks, "; failures: ", failures)
	quit(failures)

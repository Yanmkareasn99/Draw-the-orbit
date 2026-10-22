extends SceneTree

const Game = preload("res://scripts/game.gd")
const Flow = preload("res://tests/screen_flow.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.start_round(7)
	var ghost := game.make_ufo("phantom", Vector2(240, 200), 40)
	ghost.cloak_clock = 3.0
	check(game.phantom_visible(ghost), "warning phantom remains visible")
	ghost.warmup = 0
	check(not game.phantom_visible(ghost), "phantom cloaks during its invisible phase")
	ghost.cloak_clock = 4.0
	check(game.phantom_visible(ghost), "phantom reappears on the next cycle")
	ghost.cloak_clock = 3.0
	ghost.vel = Vector2(40, 0)
	game.sketch = PackedVector2Array([Vector2(250, 120), Vector2(250, 320)])
	game.finish_sketch()
	game.reflect_hazard(ghost)
	check(ghost.redirected and ghost.vel.x < 0 and game.phantom_visible(ghost), "invisible phantom hits barrier and becomes visible while stunned")
	game.start_round(5)
	game.highest_unlocked_level = 5
	check(game.boss_alive() and game.boss.health == 12, "fifth level starts with a living mothership")
	game.boss.clock = 0
	game.advance_boss(0.01)
	check(game.hazards.size() == 2 and game.hazards[0].warmup > 0, "boss releases UFOs with normal spawn warnings")
	game.hazards.clear()
	game.boss.clock = 10.0
	game.spawn_clock = 0.0
	game._physics_process(0.01)
	check(not game.hazards.is_empty(), "independent edge waves continue while the boss lives")
	game.hazards.clear()
	game.elapsed = 89.99
	game._physics_process(0.02)
	check(game.state == "playing" and game.level_time() == "BOSS" and game.highest_unlocked_level == 5, "boss level has no completion timer")
	var previous_position: Vector2 = game.boss.pos
	game._physics_process(0.1)
	check(game.boss.pos.distance_to(previous_position) > 0.0, "boss travels freely during the fight")
	var missile := game.make_ufo("saucer", game.boss.pos, 0)
	missile.warmup = 0
	missile.redirected = true
	missile.recovery = 10
	game.hazards.append(missile)
	game.step_world(0.01)
	check(game.boss.health == 11 and game.hazards.is_empty() and game.bonks == 1, "redirected UFO damages boss and is consumed once")
	game.space_bombs = 1
	game.use_space_bomb()
	check(game.boss.health == 9, "nearby bomb damages boss")
	game.damage_boss(99)
	game._physics_process(0.01)
	check(game.state == "complete" and game.highest_unlocked_level == 6 and game.boss.health == 0, "defeating the boss completes and unlocks the next level")
	game.start_round(5)
	game.damage_boss(12)
	game._physics_process(0.1)
	check(game.state == "complete", "boss defeat completes immediately without a survival gate")
	game.start_round(1)
	game.state = "intro"
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.skip_button.get_center())
	Flow.settle(game)
	check(game.planet_spin_remaining == game.PLANET_SPIN_TIME, "Skip reveal starts opening planet spin")
	game._physics_process(1.0)
	check(game.elapsed == 0 and game.hazards.is_empty(), "spin freezes level timer and spawning")
	game.state = "paused"
	game.advance_presentation(1.0)
	check(game.planet_spin_remaining == game.PLANET_SPIN_TIME, "pause freezes planet spin")
	game.state = "playing"
	game.advance_presentation(game.PLANET_SPIN_TIME)
	game._physics_process(0.1)
	check(game.elapsed > 0 and game.planet_spin_remaining == 0, "gameplay begins after spin finishes")
	game.free()
	print("Phantom/boss checks: ", checks, "; failures: ", failures)
	quit(failures)

extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var path := "res://artifacts/star_progress_test_%d.cfg" % OS.get_process_id()
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = path

	check(game.calculate_level_stars(5, 81, 100) == 5, "full health and more than eighty percent destroyed awards five stars")
	check(game.calculate_level_stars(5, 80, 100) == 4, "exactly eighty percent remains a four-star result")
	check(game.calculate_level_stars(4, 100, 100) == 4, "lost health caps an otherwise perfect result")
	check(game.calculate_level_stars(5, 60, 100) == 3, "destruction percentage uses twenty-percent star bands")
	check(game.calculate_level_stars(2, 100, 100) == 2, "remaining health can cap the destruction rating")
	check(game.calculate_level_stars(5, 0, 0) == 1, "a completed level always awards at least one star")
	game.start_round(1)
	game.spawn_attack()
	check(game.total_ufos_spawned == game.hazards.size() and game.total_ufos_spawned > 0,
		"spawned UFO tracking counts every ship that appears")

	game.start_round(1)
	game.health = 5
	game.total_ufos_spawned = 10
	game.hits = 9
	game.elapsed = game.LEVEL_DURATION - 0.01
	game._physics_process(0.02)
	check(game.state == "complete" and game.earned_stars == 5, "winning records the calculated stars on the result card")
	check(game.stars_for_level(1) == 5, "winning stores the level's best star result")

	var reopened := Game.new()
	reopened.progress_save_path = path
	reopened.load_level_progress()
	check(reopened.stars_for_level(1) == 5, "level stars persist across game instances")

	game.start_round(1)
	game.health = 2
	game.total_ufos_spawned = 10
	game.hits = 5
	game.elapsed = game.LEVEL_DURATION - 0.01
	game._physics_process(0.02)
	check(game.earned_stars == 2 and game.stars_for_level(1) == 5, "replays show the new award without replacing a better saved result")

	game.start_round(2)
	game.health = 1
	game.total_ufos_spawned = 10
	game.hits = 9
	var fatal := game.make_ufo("saucer", game.CENTER, 0.0)
	fatal.warmup = 0.0
	game.hazards.append(fatal)
	game._physics_process(0.02)
	check(game.state == "lost" and game.earned_stars == 0 and game.stars_for_level(2) == 0,
		"losing never awards stars")

	DirAccess.remove_absolute(path)
	reopened.free()
	game.free()
	print("Star checks: ", checks, "; failures: ", failures)
	quit(failures)

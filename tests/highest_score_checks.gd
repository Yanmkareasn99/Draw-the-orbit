extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ", label)
	else:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var path := "user://highest_score_test_%d.cfg" % OS.get_process_id()
	var game := Game.new()
	game.score_save_path = path
	game.load_highest_score()
	check(game.highest_score == 0, "missing save starts with zero best score")
	game.start_round()
	game.award_points(200)
	check(game.score == 200 and game.highest_score == 200 and game.hud_text("best") == "BEST 200", "new record updates the gameplay HUD immediately")
	game.award_points(200)
	game.start_round()
	check(game.score == 0 and game.highest_score == 400, "restart preserves best and resets current score")
	game.award_points(200)
	check(game.highest_score == 400, "lower scoring runs do not replace the record")
	var reopened := Game.new()
	reopened.score_save_path = path
	reopened.load_highest_score()
	check(reopened.highest_score == 400, "record persists across game instances")
	reopened.award_points(600)
	game.load_highest_score()
	check(game.highest_score == 600, "higher record replaces the stored record")
	var save := ConfigFile.new()
	save.set_value("scores", "highest", "invalid")
	save.save(path)
	game.highest_score = 0
	game.load_highest_score()
	check(game.highest_score == 0, "invalid saved value is ignored safely")
	save.set_value("scores", "highest", -10)
	save.save(path)
	game.load_highest_score()
	check(game.highest_score == 0, "negative saved record is ignored")
	game.free()
	reopened.free()
	DirAccess.remove_absolute(path)
	print("Highest-score checks: ", checks, "; failures: ", failures)
	quit(failures)

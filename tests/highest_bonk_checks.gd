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
	var path := "res://artifacts/highest_bonk_test_%d.cfg" % OS.get_process_id()
	var game := Game.new()
	game.bonk_save_path = path
	game.load_highest_bonks()
	check(game.highest_bonks == 0, "missing save starts with zero highest bonks")
	game.start_round()
	game.register_bonk()
	check(game.bonks == 1 and game.highest_bonks == 1 and game.hud_text("record") == "HIGH 1", "new bonk record updates the HUD immediately")
	game.register_bonk()
	game.start_round()
	check(game.bonks == 0 and game.highest_bonks == 2, "restart preserves highest bonks and resets current bonks")
	game.register_bonk()
	check(game.highest_bonks == 2, "lower-bonk runs do not replace the record")
	var reopened := Game.new()
	reopened.bonk_save_path = path
	reopened.load_highest_bonks()
	check(reopened.highest_bonks == 2, "highest bonk count persists across game instances")
	for i in range(6):
		reopened.register_bonk()
	game.load_highest_bonks()
	check(game.highest_bonks == 6, "higher bonk record replaces the stored record")
	var save := ConfigFile.new()
	save.set_value("bonks", "highest", "invalid")
	save.save(path)
	game.highest_bonks = 0
	game.load_highest_bonks()
	check(game.highest_bonks == 0, "invalid saved value is ignored safely")
	save.set_value("bonks", "highest", -10)
	save.save(path)
	game.load_highest_bonks()
	check(game.highest_bonks == 0, "negative saved record is ignored")
	game.free()
	reopened.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Highest-bonk checks: ", checks, "; failures: ", failures)
	quit(failures)

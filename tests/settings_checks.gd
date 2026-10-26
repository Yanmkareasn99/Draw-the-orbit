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
	var game := Game.new()
	game.settings_save_path = ""
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(768, 1024)]:
		game.state = "menu"
		game.update_layout(size)
		var screen := Rect2(Vector2.ZERO, size)
		check(screen.encloses(game.settings_button), "settings button fits title screen %s" % size)
		game.handle_primary_press(game.settings_button.get_center())
		check(game.settings_open and screen.encloses(game.settings_card), "settings panel opens on screen %s" % size)
		var bgm_target := game.bgm_slider.position + Vector2(game.bgm_slider.size.x * 0.35, game.bgm_slider.size.y * 0.5)
		game.handle_primary_press(bgm_target)
		game.handle_touch_release(bgm_target, 0)
		check(is_equal_approx(game.bgm_volume, 0.35), "BGM slider adjusts music continuously")
		var effects_target := game.effects_slider.position + Vector2(game.effects_slider.size.x * 0.8, game.effects_slider.size.y * 0.5)
		game.handle_primary_press(effects_target)
		game.handle_touch_release(effects_target, 0)
		check(is_equal_approx(game.effects_volume, 0.8), "effects slider adjusts cues independently")
		game.handle_primary_press(game.mute_button.get_center())
		check(game.game_muted, "mute control disables sound")
		game.handle_primary_press(game.close_settings_button.get_center())
		check(not game.settings_open, "settings panel closes")
	game.free()
	print("Settings checks: ", checks, "; failures: ", failures)
	quit(failures)
